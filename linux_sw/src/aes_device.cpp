#include "aes_device.h"

#include "aes_soft.h"

#include <QFile>

#include <atomic>
#include <cerrno>
#include <cstdlib>
#include <memory>
#include <cstring>
#include <thread>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

namespace {

constexpr quint32 AES_REG_BASE = 0x4000;
constexpr quint32 AES_KEY_START = 0x4014;
constexpr quint32 AES_STATUS = 0x4018;
constexpr std::size_t BAR0_SIZE = 0x8000;
constexpr qint64 FILE_CHUNK_SIZE = 1024 * 1024;

void setError(QString *error, const QString &message)
{
    if (error)
        *error = message;
}

// The AXI-Stream data path uses little-endian byte order inside each AES block.
// Convert between the natural host byte order used by the rest of the GUI and
// the wire order consumed/produced by the accelerator.
void reverseAesBlocks(char *data, qint64 size)
{
    for (qint64 offset = 0; offset + 16 <= size; offset += 16) {
        char *block = data + offset;
        for (int i = 0; i < 8; ++i) {
            const char tmp = block[i];
            block[i] = block[15 - i];
            block[15 - i] = tmp;
        }
    }
}

} // namespace

AesDevice::~AesDevice()
{
    closeDma();
    closeControl();
}

bool AesDevice::openControl(QString *error)
{
    closeControl();

    int fd = ::open("/dev/bdma0_user", O_RDWR | O_SYNC);
    void *mapped = MAP_FAILED;

    if (fd >= 0) {
        mapped = ::mmap(nullptr, BAR0_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (mapped == MAP_FAILED) {
            ::close(fd);
            fd = -1;
        }
    }

    if (mapped == MAP_FAILED) {
        fd = ::open("/dev/mem", O_RDWR | O_SYNC);
        if (fd < 0) {
            setError(error, QStringLiteral("Cannot open /dev/bdma0_user or /dev/mem."));
            return false;
        }

        bool ok = false;
        const QByteArray envBase = qgetenv("AES_BAR0_PHYS");
        quint64 physicalBase = 0xf0210000ULL;
        if (!envBase.isEmpty())
            physicalBase = envBase.toULongLong(&ok, 0);
        if (!ok)
            physicalBase = 0xf0210000ULL;

        mapped = ::mmap(nullptr, BAR0_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
                        fd, static_cast<off_t>(physicalBase));
        if (mapped == MAP_FAILED) {
            ::close(fd);
            setError(error, QStringLiteral("Failed to mmap BAR0 control window."));
            return false;
        }
    }

    controlFd_ = fd;
    controlBase_ = static_cast<volatile quint8 *>(mapped);
    controlLength_ = BAR0_SIZE;
    return true;
}

void AesDevice::closeControl()
{
    if (controlBase_) {
        ::munmap(const_cast<quint8 *>(controlBase_), controlLength_);
        controlBase_ = nullptr;
    }
    if (controlFd_ >= 0) {
        ::close(controlFd_);
        controlFd_ = -1;
    }
    controlLength_ = 0;
}

bool AesDevice::isControlOpen() const
{
    return controlBase_ != nullptr;
}

bool AesDevice::openDma(QString *error)
{
    closeDma();

    h2cFd_ = ::open("/dev/bdma0_h2c_0", O_RDWR);
    if (h2cFd_ < 0) {
        setError(error, QStringLiteral("Cannot open /dev/bdma0_h2c_0."));
        return false;
    }

    c2hFd_ = ::open("/dev/bdma0_c2h_0", O_RDWR);
    if (c2hFd_ < 0) {
        ::close(h2cFd_);
        h2cFd_ = -1;
        setError(error, QStringLiteral("Cannot open /dev/bdma0_c2h_0."));
        return false;
    }
    return true;
}

void AesDevice::closeDma()
{
    if (h2cFd_ >= 0) {
        ::close(h2cFd_);
        h2cFd_ = -1;
    }
    if (c2hFd_ >= 0) {
        ::close(c2hFd_);
        c2hFd_ = -1;
    }
}

bool AesDevice::isDmaOpen() const
{
    return h2cFd_ >= 0 && c2hFd_ >= 0;
}

void AesDevice::write32(std::size_t offset, quint32 value)
{
    volatile quint32 *reg = reinterpret_cast<volatile quint32 *>(
        const_cast<quint8 *>(controlBase_) + offset);
    *reg = value;
}

quint32 AesDevice::read32(std::size_t offset) const
{
    const volatile quint32 *reg = reinterpret_cast<const volatile quint32 *>(
        controlBase_ + offset);
    return *reg;
}

bool AesDevice::setKey(const QByteArray &key16, QString *error)
{
    if (!isControlOpen() && !openControl(error))
        return false;
    if (key16.size() != 16) {
        setError(error, QStringLiteral("AES-128 key must be exactly 16 bytes."));
        return false;
    }

    for (int i = 0; i < 4; ++i) {
        const quint32 word = (static_cast<quint32>(static_cast<quint8>(key16.at(4 * i + 0))) << 24)
                           | (static_cast<quint32>(static_cast<quint8>(key16.at(4 * i + 1))) << 16)
                           | (static_cast<quint32>(static_cast<quint8>(key16.at(4 * i + 2))) << 8)
                           | (static_cast<quint32>(static_cast<quint8>(key16.at(4 * i + 3))));
        write32(AES_REG_BASE + 4 * i, word);
    }

    write32(AES_KEY_START, 1);
    for (int attempt = 0; attempt < 100; ++attempt) {
        if (read32(AES_STATUS) & 0x2)
            return true;
        ::usleep(1000);
    }

    setError(error, QStringLiteral("AES key initialization timed out."));
    return false;
}

bool AesDevice::transferChunk(const char *input, char *output, qint64 size, QString *error)
{
    if (!input || !output || size <= 0 || size % 16 != 0) {
        setError(error, QStringLiteral("Invalid AES DMA transfer size."));
        return false;
    }

    // Keep both DMA buffers page-aligned so every scatter-gather segment
    // stays a multiple of the AXI-Stream transfer granularity. QByteArray
    // allocations can start at an arbitrary page offset, which stalls the
    // BDMA streaming engines on a partial descriptor.
    std::unique_ptr<char, void (*)(void *)> writeBuf(nullptr, &std::free);
    std::unique_ptr<char, void (*)(void *)> readBuf(nullptr, &std::free);

    void *rawWrite = nullptr;
    void *rawRead = nullptr;
    if (::posix_memalign(&rawWrite, 4096, static_cast<size_t>(size)) != 0 ||
        ::posix_memalign(&rawRead, 4096, static_cast<size_t>(size)) != 0) {
        ::free(rawWrite);
        ::free(rawRead);
        setError(error, QStringLiteral("Failed to allocate aligned DMA buffers."));
        return false;
    }
    writeBuf.reset(static_cast<char *>(rawWrite));
    readBuf.reset(static_cast<char *>(rawRead));

    std::memcpy(writeBuf.get(), input, static_cast<size_t>(size));
    reverseAesBlocks(writeBuf.get(), size);

    ::lseek(h2cFd_, 0, SEEK_SET);
    ::lseek(c2hFd_, 0, SEEK_SET);

    char *readDest = readBuf.get();
    std::atomic<qint64> readDone{-1};
    std::thread reader([this, readDest, size, &readDone]() {
        qint64 done = 0;
        while (done < size) {
            const ssize_t n = ::read(c2hFd_, readDest + done,
                                     static_cast<size_t>(size - done));
            if (n <= 0)
                break;
            done += n;
        }
        readDone.store(done);
    });

    ::usleep(20000);

    const char *writeSrc = writeBuf.get();
    qint64 written = 0;
    while (written < size) {
        const ssize_t n = ::write(h2cFd_, writeSrc + written,
                                  static_cast<size_t>(size - written));
        if (n <= 0)
            break;
        written += n;
    }

    reader.join();

    if (written != size || readDone.load() != size) {
        setError(error, QStringLiteral("AES DMA transfer mismatch."));
        return false;
    }

    std::memcpy(output, readBuf.get(), static_cast<size_t>(size));
    reverseAesBlocks(output, size);
    return true;
}

QByteArray AesDevice::encryptBlocks(const QByteArray &blocks, QString *error)
{
    if (blocks.size() % 16 != 0) {
        setError(error, QStringLiteral("Input length must be a multiple of 16 bytes."));
        return {};
    }

    const bool openedHere = !isDmaOpen();
    if (openedHere && !openDma(error))
        return {};

    QByteArray output;
    output.resize(blocks.size());
    const bool ok = transferChunk(blocks.constData(), output.data(), blocks.size(), error);

    if (openedHere)
        closeDma();
    return ok ? output : QByteArray();
}

bool AesDevice::encryptFile(const QString &inputPath,
                            const QString &outputPath,
                            const QByteArray &key16,
                            QString *error,
                            const std::function<void(qint64, qint64)> &progress)
{
    if (!openControl(error) || !openDma(error) || !setKey(key16, error)) {
        closeDma();
        closeControl();
        return false;
    }

    QFile input(inputPath);
    if (!input.open(QIODevice::ReadOnly)) {
        setError(error, QStringLiteral("Cannot open input file: %1").arg(inputPath));
        closeDma();
        closeControl();
        return false;
    }

    QFile output(outputPath);
    if (!output.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        setError(error, QStringLiteral("Cannot open output file: %1").arg(outputPath));
        closeDma();
        closeControl();
        return false;
    }

    const qint64 total = input.size();
    bool ok = true;

    if (total == 0) {
        QByteArray block = AesSoft::pkcs7Pad(QByteArray());
        QByteArray encrypted;
        encrypted.resize(block.size());
        if (!transferChunk(block.constData(), encrypted.data(), block.size(), error))
            ok = false;
        else if (output.write(encrypted) != encrypted.size())
            ok = false;
    } else {
        while (!input.atEnd()) {
            QByteArray block = input.read(FILE_CHUNK_SIZE);
            const bool finalBlock = input.atEnd();
            if (finalBlock)
                block = AesSoft::pkcs7Pad(block);

            QByteArray encrypted;
            encrypted.resize(block.size());
            if (!transferChunk(block.constData(), encrypted.data(), block.size(), error)) {
                ok = false;
                break;
            }
            if (output.write(encrypted) != encrypted.size()) {
                setError(error, QStringLiteral("Failed to write output file."));
                ok = false;
                break;
            }
            if (progress)
                progress(input.pos(), total);
        }
    }

    closeDma();
    closeControl();
    return ok;
}

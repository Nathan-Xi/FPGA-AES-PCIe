#ifndef AES_DEVICE_H
#define AES_DEVICE_H

#include <QByteArray>
#include <QString>
#include <QtGlobal>

#include <cstddef>
#include <functional>

// Low-level BDMA/AES accelerator access.
//
// Encryption data flows through /dev/bdma0_h2c_0 and /dev/bdma0_c2h_0. The
// AES control registers are accessed through BAR0 at offset 0x4000.
class AesDevice
{
public:
    AesDevice() = default;
    ~AesDevice();

    AesDevice(const AesDevice &) = delete;
    AesDevice &operator=(const AesDevice &) = delete;

    bool openControl(QString *error = nullptr);
    void closeControl();
    bool isControlOpen() const;

    bool openDma(QString *error = nullptr);
    void closeDma();
    bool isDmaOpen() const;

    bool setKey(const QByteArray &key16, QString *error = nullptr);
    QByteArray encryptBlocks(const QByteArray &blocks, QString *error = nullptr);

    bool encryptFile(const QString &inputPath,
                     const QString &outputPath,
                     const QByteArray &key16,
                     QString *error = nullptr,
                     const std::function<void(qint64, qint64)> &progress = {});

private:
    void write32(std::size_t offset, quint32 value);
    quint32 read32(std::size_t offset) const;
    bool transferChunk(const char *input, char *output, qint64 size, QString *error);

    int controlFd_ = -1;
    int h2cFd_ = -1;
    int c2hFd_ = -1;
    volatile quint8 *controlBase_ = nullptr;
    std::size_t controlLength_ = 0;
};

#endif // AES_DEVICE_H

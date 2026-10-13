#include "aes_soft.h"

#include <QFile>

#include <cstring>

namespace {

constexpr quint8 SBOX[256] = {
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
};

constexpr quint8 INV_SBOX[256] = {
    0x52,0x09,0x6a,0xd5,0x30,0x36,0xa5,0x38,0xbf,0x40,0xa3,0x9e,0x81,0xf3,0xd7,0xfb,
    0x7c,0xe3,0x39,0x82,0x9b,0x2f,0xff,0x87,0x34,0x8e,0x43,0x44,0xc4,0xde,0xe9,0xcb,
    0x54,0x7b,0x94,0x32,0xa6,0xc2,0x23,0x3d,0xee,0x4c,0x95,0x0b,0x42,0xfa,0xc3,0x4e,
    0x08,0x2e,0xa1,0x66,0x28,0xd9,0x24,0xb2,0x76,0x5b,0xa2,0x49,0x6d,0x8b,0xd1,0x25,
    0x72,0xf8,0xf6,0x64,0x86,0x68,0x98,0x16,0xd4,0xa4,0x5c,0xcc,0x5d,0x65,0xb6,0x92,
    0x6c,0x70,0x48,0x50,0xfd,0xed,0xb9,0xda,0x5e,0x15,0x46,0x57,0xa7,0x8d,0x9d,0x84,
    0x90,0xd8,0xab,0x00,0x8c,0xbc,0xd3,0x0a,0xf7,0xe4,0x58,0x05,0xb8,0xb3,0x45,0x06,
    0xd0,0x2c,0x1e,0x8f,0xca,0x3f,0x0f,0x02,0xc1,0xaf,0xbd,0x03,0x01,0x13,0x8a,0x6b,
    0x3a,0x91,0x11,0x41,0x4f,0x67,0xdc,0xea,0x97,0xf2,0xcf,0xce,0xf0,0xb4,0xe6,0x73,
    0x96,0xac,0x74,0x22,0xe7,0xad,0x35,0x85,0xe2,0xf9,0x37,0xe8,0x1c,0x75,0xdf,0x6e,
    0x47,0xf1,0x1a,0x71,0x1d,0x29,0xc5,0x89,0x6f,0xb7,0x62,0x0e,0xaa,0x18,0xbe,0x1b,
    0xfc,0x56,0x3e,0x4b,0xc6,0xd2,0x79,0x20,0x9a,0xdb,0xc0,0xfe,0x78,0xcd,0x5a,0xf4,
    0x1f,0xdd,0xa8,0x33,0x88,0x07,0xc7,0x31,0xb1,0x12,0x10,0x59,0x27,0x80,0xec,0x5f,
    0x60,0x51,0x7f,0xa9,0x19,0xb5,0x4a,0x0d,0x2d,0xe5,0x7a,0x9f,0x93,0xc9,0x9c,0xef,
    0xa0,0xe0,0x3b,0x4d,0xae,0x2a,0xf5,0xb0,0xc8,0xeb,0xbb,0x3c,0x83,0x53,0x99,0x61,
    0x17,0x2b,0x04,0x7e,0xba,0x77,0xd6,0x26,0xe1,0x69,0x14,0x63,0x55,0x21,0x0c,0x7d
};

quint8 xtime(quint8 value)
{
    return static_cast<quint8>((value << 1) ^ ((value & 0x80) ? 0x1b : 0x00));
}

quint8 gmul(quint8 a, quint8 b)
{
    quint8 result = 0;
    for (int i = 0; i < 8; ++i) {
        if (b & 1)
            result ^= a;
        const quint8 high = static_cast<quint8>(a & 0x80);
        a = static_cast<quint8>(a << 1);
        if (high)
            a ^= 0x1b;
        b >>= 1;
    }
    return result;
}

void addRoundKey(quint8 state[16], const quint8 *roundKey)
{
    for (int i = 0; i < 16; ++i)
        state[i] ^= roundKey[i];
}

void subBytes(quint8 state[16])
{
    for (int i = 0; i < 16; ++i)
        state[i] = SBOX[state[i]];
}

void invSubBytes(quint8 state[16])
{
    for (int i = 0; i < 16; ++i)
        state[i] = INV_SBOX[state[i]];
}

void shiftRows(quint8 state[16])
{
    quint8 tmp[16];
    for (int r = 0; r < 4; ++r) {
        for (int c = 0; c < 4; ++c)
            tmp[4 * c + r] = state[4 * ((c + r) % 4) + r];
    }
    std::memcpy(state, tmp, 16);
}

void invShiftRows(quint8 state[16])
{
    quint8 tmp[16];
    for (int r = 0; r < 4; ++r) {
        for (int c = 0; c < 4; ++c)
            tmp[4 * c + r] = state[4 * ((c - r + 4) % 4) + r];
    }
    std::memcpy(state, tmp, 16);
}

void mixColumns(quint8 state[16])
{
    for (int c = 0; c < 4; ++c) {
        const quint8 a0 = state[4 * c + 0];
        const quint8 a1 = state[4 * c + 1];
        const quint8 a2 = state[4 * c + 2];
        const quint8 a3 = state[4 * c + 3];
        state[4 * c + 0] = xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3;
        state[4 * c + 1] = a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3;
        state[4 * c + 2] = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3);
        state[4 * c + 3] = (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3);
    }
}

void invMixColumns(quint8 state[16])
{
    for (int c = 0; c < 4; ++c) {
        const quint8 a0 = state[4 * c + 0];
        const quint8 a1 = state[4 * c + 1];
        const quint8 a2 = state[4 * c + 2];
        const quint8 a3 = state[4 * c + 3];
        state[4 * c + 0] = gmul(a0, 14) ^ gmul(a1, 11) ^ gmul(a2, 13) ^ gmul(a3, 9);
        state[4 * c + 1] = gmul(a0, 9) ^ gmul(a1, 14) ^ gmul(a2, 11) ^ gmul(a3, 13);
        state[4 * c + 2] = gmul(a0, 13) ^ gmul(a1, 9) ^ gmul(a2, 14) ^ gmul(a3, 11);
        state[4 * c + 3] = gmul(a0, 11) ^ gmul(a1, 13) ^ gmul(a2, 9) ^ gmul(a3, 14);
    }
}

} // namespace

void AesSoft::expandKey(const quint8 key[16], quint8 roundKeys[176])
{
    for (int i = 0; i < 16; ++i)
        roundKeys[i] = key[i];

    int generated = 16;
    int rcon = 1;
    quint8 temp[4];

    while (generated < 176) {
        for (int i = 0; i < 4; ++i)
            temp[i] = roundKeys[generated - 4 + i];

        if (generated % 16 == 0) {
            const quint8 t = temp[0];
            temp[0] = SBOX[temp[1]] ^ static_cast<quint8>(rcon);
            temp[1] = SBOX[temp[2]];
            temp[2] = SBOX[temp[3]];
            temp[3] = SBOX[t];
            rcon = xtime(static_cast<quint8>(rcon));
        }

        for (int i = 0; i < 4; ++i) {
            roundKeys[generated] = roundKeys[generated - 16] ^ temp[i];
            ++generated;
        }
    }
}

void AesSoft::encryptBlock(const quint8 in[16], quint8 out[16],
                           const quint8 roundKeys[176])
{
    quint8 state[16];
    std::memcpy(state, in, 16);

    addRoundKey(state, roundKeys);
    for (int round = 1; round <= 9; ++round) {
        subBytes(state);
        shiftRows(state);
        mixColumns(state);
        addRoundKey(state, roundKeys + 16 * round);
    }
    subBytes(state);
    shiftRows(state);
    addRoundKey(state, roundKeys + 160);

    std::memcpy(out, state, 16);
}

void AesSoft::decryptBlock(const quint8 in[16], quint8 out[16],
                           const quint8 roundKeys[176])
{
    quint8 state[16];
    std::memcpy(state, in, 16);

    addRoundKey(state, roundKeys + 160);
    for (int round = 9; round >= 1; --round) {
        invShiftRows(state);
        invSubBytes(state);
        addRoundKey(state, roundKeys + 16 * round);
        invMixColumns(state);
    }
    invShiftRows(state);
    invSubBytes(state);
    addRoundKey(state, roundKeys);

    std::memcpy(out, state, 16);
}

QByteArray AesSoft::encryptBlocks(const QByteArray &data,
                                  const QByteArray &key16,
                                  QString *error)
{
    if (key16.size() != 16) {
        if (error)
            *error = QStringLiteral("AES-128 key must be exactly 16 bytes.");
        return {};
    }
    if (data.size() % 16 != 0) {
        if (error)
            *error = QStringLiteral("Input length must be a multiple of 16 bytes.");
        return {};
    }

    quint8 roundKeys[176];
    expandKey(reinterpret_cast<const quint8 *>(key16.constData()), roundKeys);

    QByteArray output;
    output.resize(data.size());
    for (int offset = 0; offset < data.size(); offset += 16) {
        encryptBlock(reinterpret_cast<const quint8 *>(data.constData() + offset),
                     reinterpret_cast<quint8 *>(output.data() + offset),
                     roundKeys);
    }
    return output;
}

QByteArray AesSoft::decryptBlocks(const QByteArray &data,
                                  const QByteArray &key16,
                                  QString *error)
{
    if (key16.size() != 16) {
        if (error)
            *error = QStringLiteral("AES-128 key must be exactly 16 bytes.");
        return {};
    }
    if (data.size() % 16 != 0) {
        if (error)
            *error = QStringLiteral("Encrypted data length must be a multiple of 16 bytes.");
        return {};
    }

    quint8 roundKeys[176];
    expandKey(reinterpret_cast<const quint8 *>(key16.constData()), roundKeys);

    QByteArray output;
    output.resize(data.size());
    for (int offset = 0; offset < data.size(); offset += 16) {
        decryptBlock(reinterpret_cast<const quint8 *>(data.constData() + offset),
                     reinterpret_cast<quint8 *>(output.data() + offset),
                     roundKeys);
    }
    return output;
}

QByteArray AesSoft::pkcs7Pad(const QByteArray &data)
{
    const int pad = 16 - (data.size() % 16);
    QByteArray padded = data;
    padded.append(pad, static_cast<char>(pad));
    return padded;
}

QByteArray AesSoft::pkcs7Unpad(const QByteArray &data, QString *error)
{
    if (data.isEmpty() || data.size() % 16 != 0) {
        if (error)
            *error = QStringLiteral("Invalid padded data length.");
        return {};
    }

    const int pad = static_cast<quint8>(data.at(data.size() - 1));
    if (pad < 1 || pad > 16 || pad > data.size()) {
        if (error)
            *error = QStringLiteral("Invalid PKCS#7 padding.");
        return {};
    }

    for (int i = data.size() - pad; i < data.size(); ++i) {
        if (static_cast<quint8>(data.at(i)) != pad) {
            if (error)
                *error = QStringLiteral("Invalid PKCS#7 padding.");
            return {};
        }
    }

    return data.left(data.size() - pad);
}
bool AesSoft::encryptFile(const QString &inputPath,
                          const QString &outputPath,
                          const QByteArray &key16,
                          QString *error)
{
    QFile input(inputPath);
    if (!input.open(QIODevice::ReadOnly)) {
        if (error)
            *error = QStringLiteral("Cannot open input file: %1").arg(inputPath);
        return false;
    }

    QFile output(outputPath);
    if (!output.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (error)
            *error = QStringLiteral("Cannot open output file: %1").arg(outputPath);
        return false;
    }

    constexpr qint64 chunkSize = 1024 * 1024;

    if (input.size() == 0) {
        const QByteArray encrypted = encryptBlocks(pkcs7Pad(QByteArray()), key16, error);
        if (encrypted.isEmpty())
            return false;
        output.write(encrypted);
        return true;
    }

    while (!input.atEnd()) {
        QByteArray block = input.read(chunkSize);
        if (input.atEnd())
            block = pkcs7Pad(block);

        const QByteArray encrypted = encryptBlocks(block, key16, error);
        if (encrypted.isEmpty())
            return false;
        if (output.write(encrypted) != encrypted.size()) {
            if (error)
                *error = QStringLiteral("Failed to write output file.");
            return false;
        }
    }
    return true;
}

bool AesSoft::decryptFile(const QString &inputPath,
                          const QString &outputPath,
                          const QByteArray &key16,
                          QString *error)
{
    QFile input(inputPath);
    if (!input.open(QIODevice::ReadOnly)) {
        if (error)
            *error = QStringLiteral("Cannot open encrypted file: %1").arg(inputPath);
        return false;
    }

    QFile output(outputPath);
    if (!output.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (error)
            *error = QStringLiteral("Cannot open output file: %1").arg(outputPath);
        return false;
    }

    constexpr qint64 chunkSize = 1024 * 1024;

    if (input.size() == 0) {
        if (error)
            *error = QStringLiteral("Encrypted file is empty.");
        return false;
    }

    while (!input.atEnd()) {
        QByteArray block = input.read(chunkSize);
        QByteArray decrypted = decryptBlocks(block, key16, error);
        if (decrypted.isEmpty() && !block.isEmpty())
            return false;

        if (input.atEnd()) {
            QString unpadError;
            decrypted = pkcs7Unpad(decrypted, &unpadError);
            if (!unpadError.isEmpty()) {
                if (error)
                    *error = unpadError;
                return false;
            }
        }

        if (output.write(decrypted) != decrypted.size()) {
            if (error)
                *error = QStringLiteral("Failed to write output file.");
            return false;
        }
    }
    return true;
}

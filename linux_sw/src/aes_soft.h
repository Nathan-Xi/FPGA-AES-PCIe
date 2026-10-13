#ifndef AES_SOFT_H
#define AES_SOFT_H

#include <QByteArray>
#include <QString>
#include <QtGlobal>

// Software AES-128 implementation used for decryption fallback and for local
// operation when the FPGA accelerator is unavailable.
class AesSoft
{
public:
    static QByteArray encryptBlocks(const QByteArray &data,
                                    const QByteArray &key16,
                                    QString *error = nullptr);

    static QByteArray decryptBlocks(const QByteArray &data,
                                    const QByteArray &key16,
                                    QString *error = nullptr);

    static QByteArray pkcs7Pad(const QByteArray &data);
    static QByteArray pkcs7Unpad(const QByteArray &data, QString *error = nullptr);

    static bool encryptFile(const QString &inputPath,
                            const QString &outputPath,
                            const QByteArray &key16,
                            QString *error = nullptr);

    static bool decryptFile(const QString &inputPath,
                            const QString &outputPath,
                            const QByteArray &key16,
                            QString *error = nullptr);

private:
    static void expandKey(const quint8 key[16], quint8 roundKeys[176]);
    static void encryptBlock(const quint8 in[16], quint8 out[16],
                             const quint8 roundKeys[176]);
    static void decryptBlock(const quint8 in[16], quint8 out[16],
                             const quint8 roundKeys[176]);
};

#endif // AES_SOFT_H

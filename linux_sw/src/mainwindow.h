#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include "aes_device.h"

#include <QByteArray>
#include <QMainWindow>
#include <QtGlobal>

#include <atomic>
#include <functional>

class QFileSystemModel;
class QLabel;
class QLineEdit;
class QModelIndex;
class QPlainTextEdit;
class QPushButton;
class QTabWidget;
class QTreeView;

template <typename T> class QFutureWatcher;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private slots:
    void onFileTreeSelectionChanged(const QModelIndex &current,
                                    const QModelIndex &previous);
    void onTextKeyGenerate();
    void onTextEncrypt();
    void onTextDecrypt();
    void onFileKeyGenerate();
    void onFileEncrypt();
    void onFileDecrypt();
    void onAutomationStart();
    void onAutomationStop();
    void appendAutomationLog(const QString &line);

private:
    struct OperationResult
    {
        bool ok = false;
        QString message;
        QByteArray data;
    };

    QWidget *createTextTab();
    QWidget *createFileTab();
    QWidget *createAutomationTab();

    QString generateRandomKeyHex() const;
    QByteArray parseKeyHex(const QString &text, QString *error) const;
    QByteArray readKeyFile(const QString &path, QString *error) const;
    QString directoryOrDefault(const QString &directory,
                               const QString &fallbackDirectory) const;

    OperationResult runTextEncrypt(const QString &plainText,
                                   const QByteArray &key);
    OperationResult runTextDecrypt(const QString &hexText,
                                   const QByteArray &key);
    OperationResult runFileEncrypt(const QString &inputPath,
                                   const QString &outputPath,
                                   const QByteArray &key,
                                   const QString &keySavePath);
    OperationResult runFileDecrypt(const QString &inputPath,
                                   const QString &outputPath,
                                   const QByteArray &key);

    void startOperation(const std::function<OperationResult()> &operation,
                        QLabel *statusLabel);
    void setBusy(bool busy);
    void runAutomationLoop();
    void logAutomation(const QString &line);

    QTabWidget *tabs_ = nullptr;

    // Text tab widgets.
    QLineEdit *textKeyEdit_ = nullptr;
    QPlainTextEdit *textInput_ = nullptr;
    QPlainTextEdit *textOutput_ = nullptr;
    QLabel *textStatus_ = nullptr;

    // File tab widgets.
    QFileSystemModel *fileModel_ = nullptr;
    QTreeView *fileTree_ = nullptr;
    QLabel *selectedNameLabel_ = nullptr;
    QLabel *selectedTypeLabel_ = nullptr;
    QLabel *selectedDirectoryLabel_ = nullptr;
    QLabel *selectedSizeLabel_ = nullptr;
    QLineEdit *encryptInputFile_ = nullptr;
    QLineEdit *encryptKeyEdit_ = nullptr;
    QLineEdit *encryptOutputDir_ = nullptr;
    QLineEdit *keyOutputDir_ = nullptr;
    QLineEdit *decryptKeyFile_ = nullptr;
    QLineEdit *decryptEncryptedFile_ = nullptr;
    QLineEdit *decryptOutputDir_ = nullptr;
    QLabel *fileStatus_ = nullptr;

    // Automation tab widgets.
    QPushButton *automationStartButton_ = nullptr;
    QPushButton *automationStopButton_ = nullptr;
    QPlainTextEdit *automationLog_ = nullptr;

    AesDevice device_;
    bool busy_ = false;
    std::atomic<bool> automationRunning_{false};
    QFutureWatcher<void> *automationWatcher_ = nullptr;

    // True when the screen is taller than it is wide (panel mounted in
    // portrait), which stacks the file tab vertically.
    bool portraitLayout_ = false;
};

#endif // MAINWINDOW_H

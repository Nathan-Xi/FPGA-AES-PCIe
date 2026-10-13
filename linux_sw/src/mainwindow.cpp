#include "mainwindow.h"

#include "aes_soft.h"

#include <QDateTime>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFileSystemModel>
#include <QFormLayout>
#include <QGuiApplication>
#include <QFutureWatcher>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QItemSelectionModel>
#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QScrollBar>
#include <QScreen>
#include <QScrollArea>
#include <QSplitter>
#include <QTabWidget>
#include <QThread>
#include <QTreeView>
#include <QVBoxLayout>
#include <QtConcurrent/QtConcurrent>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setWindowTitle(tr("PCIe AES-128 Accelerator"));

    // The panel is 1024x600 in its native orientation but is often mounted
    // rotated; follow the screen the compositor gives us instead of a
    // hardcoded landscape size.
    const QScreen *screen = QGuiApplication::primaryScreen();
    const QSize screenSize = screen ? screen->geometry().size() : QSize(1024, 600);
    portraitLayout_ = screenSize.height() > screenSize.width();
    resize(screenSize);

    tabs_ = new QTabWidget(this);
    tabs_->addTab(createTextTab(), tr("Text Encryption"));
    tabs_->addTab(createFileTab(), tr("File Encryption"));
    tabs_->addTab(createAutomationTab(), tr("Test Automation"));
    setCentralWidget(tabs_);

    setBusy(false);
}

MainWindow::~MainWindow()
{
    automationRunning_.store(false);
    if (automationWatcher_ && automationWatcher_->isRunning())
        automationWatcher_->waitForFinished();
}

QWidget *MainWindow::createTextTab()
{
    auto *page = new QWidget(this);
    auto *root = new QVBoxLayout(page);

    auto *keyBox = new QGroupBox(tr("AES-128 Key"), page);
    auto *keyLayout = new QHBoxLayout(keyBox);
    textKeyEdit_ = new QLineEdit(keyBox);
    textKeyEdit_->setText(generateRandomKeyHex());
    textKeyEdit_->setPlaceholderText(tr("32 hexadecimal characters"));
    auto *generateKey = new QPushButton(tr("Generate Key"), keyBox);
    connect(generateKey, &QPushButton::clicked, this, &MainWindow::onTextKeyGenerate);
    keyLayout->addWidget(new QLabel(tr("Key:"), keyBox));
    keyLayout->addWidget(textKeyEdit_, 1);
    keyLayout->addWidget(generateKey);
    root->addWidget(keyBox);

    auto *inputBox = new QGroupBox(tr("Input"), page);
    auto *inputLayout = new QVBoxLayout(inputBox);
    textInput_ = new QPlainTextEdit(inputBox);
    textInput_->setPlaceholderText(tr("Plain text for encryption, or ciphertext hex for decryption."));
    inputLayout->addWidget(textInput_);
    root->addWidget(inputBox, 1);

    auto *buttonLayout = new QHBoxLayout;
    auto *encryptButton = new QPushButton(tr("Encrypt"), page);
    auto *decryptButton = new QPushButton(tr("Decrypt"), page);
    connect(encryptButton, &QPushButton::clicked, this, &MainWindow::onTextEncrypt);
    connect(decryptButton, &QPushButton::clicked, this, &MainWindow::onTextDecrypt);
    buttonLayout->addStretch(1);
    buttonLayout->addWidget(encryptButton);
    buttonLayout->addWidget(decryptButton);
    root->addLayout(buttonLayout);

    auto *outputBox = new QGroupBox(tr("Output"), page);
    auto *outputLayout = new QVBoxLayout(outputBox);
    textOutput_ = new QPlainTextEdit(outputBox);
    textOutput_->setReadOnly(true);
    outputLayout->addWidget(textOutput_);
    root->addWidget(outputBox, 1);

    textStatus_ = new QLabel(tr("Ready."), page);
    root->addWidget(textStatus_);

    return page;
}

QWidget *MainWindow::createFileTab()
{
    auto *page = new QWidget(this);
    auto *root = new QVBoxLayout(page);
    // Side by side in landscape; stacked in portrait, where a 600px-wide window
    // leaves too little room for both the tree and the property form.
    auto *splitter = new QSplitter(portraitLayout_ ? Qt::Vertical : Qt::Horizontal, page);

    auto *left = new QWidget(splitter);
    auto *leftLayout = new QVBoxLayout(left);
    leftLayout->addWidget(new QLabel(tr("File System"), left));

    fileModel_ = new QFileSystemModel(this);
    fileModel_->setRootPath(QDir::rootPath());
    fileModel_->setFilter(QDir::AllDirs | QDir::Files | QDir::NoDotAndDotDot);

    fileTree_ = new QTreeView(left);
    fileTree_->setModel(fileModel_);
    fileTree_->setRootIndex(fileModel_->index(QDir::rootPath()));
    fileTree_->setAnimated(false);
    fileTree_->setSortingEnabled(true);
    fileTree_->sortByColumn(0, Qt::AscendingOrder);
    fileTree_->header()->setStretchLastSection(true);
    for (int i = 1; i < fileModel_->columnCount(); ++i)
        fileTree_->hideColumn(i);

    connect(fileTree_->selectionModel(), &QItemSelectionModel::currentChanged,
            this, &MainWindow::onFileTreeSelectionChanged);

    leftLayout->addWidget(fileTree_);
    splitter->addWidget(left);

    auto *scroll = new QScrollArea(splitter);
    scroll->setWidgetResizable(true);
    auto *right = new QWidget(scroll);
    auto *rightLayout = new QVBoxLayout(right);
    scroll->setWidget(right);

    auto *propertyBox = new QGroupBox(tr("Selected File Properties"), right);
    auto *propertyForm = new QFormLayout(propertyBox);
    selectedNameLabel_ = new QLabel(tr("-"), propertyBox);
    selectedTypeLabel_ = new QLabel(tr("-"), propertyBox);
    selectedDirectoryLabel_ = new QLabel(tr("-"), propertyBox);
    selectedSizeLabel_ = new QLabel(tr("-"), propertyBox);
    propertyForm->addRow(tr("File Name:"), selectedNameLabel_);
    propertyForm->addRow(tr("File Type:"), selectedTypeLabel_);
    propertyForm->addRow(tr("Directory:"), selectedDirectoryLabel_);
    propertyForm->addRow(tr("Size:"), selectedSizeLabel_);
    rightLayout->addWidget(propertyBox);

    auto *encryptBox = new QGroupBox(tr("Encrypt File"), right);
    auto *encryptForm = new QFormLayout(encryptBox);
    encryptInputFile_ = new QLineEdit(encryptBox);
    auto *browseEncryptInput = new QPushButton(tr("Browse..."), encryptBox);
    connect(browseEncryptInput, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, tr("Select Input File"));
        if (!path.isEmpty())
            encryptInputFile_->setText(path);
    });
    auto *inputRow = new QHBoxLayout;
    inputRow->addWidget(encryptInputFile_, 1);
    inputRow->addWidget(browseEncryptInput);
    encryptForm->addRow(tr("Input File:"), inputRow);

    encryptKeyEdit_ = new QLineEdit(encryptBox);
    encryptKeyEdit_->setText(generateRandomKeyHex());
    auto *browseKeySave = new QPushButton(tr("Generate"), encryptBox);
    connect(browseKeySave, &QPushButton::clicked, this, &MainWindow::onFileKeyGenerate);
    auto *keyRow = new QHBoxLayout;
    keyRow->addWidget(encryptKeyEdit_, 1);
    keyRow->addWidget(browseKeySave);
    encryptForm->addRow(tr("Key:"), keyRow);

    encryptOutputDir_ = new QLineEdit(encryptBox);
    auto *browseEncryptOutput = new QPushButton(tr("Browse..."), encryptBox);
    connect(browseEncryptOutput, &QPushButton::clicked, this, [this]() {
        const QString dir = QFileDialog::getExistingDirectory(this, tr("Select Output Directory"));
        if (!dir.isEmpty())
            encryptOutputDir_->setText(dir);
    });
    auto *encryptOutputRow = new QHBoxLayout;
    encryptOutputRow->addWidget(encryptOutputDir_, 1);
    encryptOutputRow->addWidget(browseEncryptOutput);
    encryptForm->addRow(tr("Encrypted File Directory:"), encryptOutputRow);

    keyOutputDir_ = new QLineEdit(encryptBox);
    auto *browseKeyOutput = new QPushButton(tr("Browse..."), encryptBox);
    connect(browseKeyOutput, &QPushButton::clicked, this, [this]() {
        const QString dir = QFileDialog::getExistingDirectory(this, tr("Select Key Save Directory"));
        if (!dir.isEmpty())
            keyOutputDir_->setText(dir);
    });
    auto *keyOutputRow = new QHBoxLayout;
    keyOutputRow->addWidget(keyOutputDir_, 1);
    keyOutputRow->addWidget(browseKeyOutput);
    encryptForm->addRow(tr("Key Save Directory:"), keyOutputRow);

    auto *encryptButton = new QPushButton(tr("Encrypt File"), encryptBox);
    connect(encryptButton, &QPushButton::clicked, this, &MainWindow::onFileEncrypt);
    encryptForm->addRow(encryptButton);
    rightLayout->addWidget(encryptBox);

    auto *decryptBox = new QGroupBox(tr("Decrypt File"), right);
    auto *decryptForm = new QFormLayout(decryptBox);

    decryptKeyFile_ = new QLineEdit(decryptBox);
    auto *browseKeyFile = new QPushButton(tr("Browse..."), decryptBox);
    connect(browseKeyFile, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, tr("Select Key File"));
        if (!path.isEmpty())
            decryptKeyFile_->setText(path);
    });
    auto *decryptKeyRow = new QHBoxLayout;
    decryptKeyRow->addWidget(decryptKeyFile_, 1);
    decryptKeyRow->addWidget(browseKeyFile);
    decryptForm->addRow(tr("Key File:"), decryptKeyRow);

    decryptEncryptedFile_ = new QLineEdit(decryptBox);
    auto *browseEncryptedFile = new QPushButton(tr("Browse..."), decryptBox);
    connect(browseEncryptedFile, &QPushButton::clicked, this, [this]() {
        const QString path = QFileDialog::getOpenFileName(this, tr("Select Encrypted File"));
        if (!path.isEmpty())
            decryptEncryptedFile_->setText(path);
    });
    auto *decryptInputRow = new QHBoxLayout;
    decryptInputRow->addWidget(decryptEncryptedFile_, 1);
    decryptInputRow->addWidget(browseEncryptedFile);
    decryptForm->addRow(tr("Encrypted File:"), decryptInputRow);

    decryptOutputDir_ = new QLineEdit(decryptBox);
    auto *browseDecryptOutput = new QPushButton(tr("Browse..."), decryptBox);
    connect(browseDecryptOutput, &QPushButton::clicked, this, [this]() {
        const QString dir = QFileDialog::getExistingDirectory(this, tr("Select Output Directory"));
        if (!dir.isEmpty())
            decryptOutputDir_->setText(dir);
    });
    auto *decryptOutputRow = new QHBoxLayout;
    decryptOutputRow->addWidget(decryptOutputDir_, 1);
    decryptOutputRow->addWidget(browseDecryptOutput);
    decryptForm->addRow(tr("Decrypted File Directory:"), decryptOutputRow);

    encryptInputFile_->setText(QStringLiteral("/usr/local/assets/en/ENCRYPT_ME.jpg"));
    encryptOutputDir_->setText(QStringLiteral("/usr/local/assets/de"));
    keyOutputDir_->setText(QStringLiteral("/usr/local/assets/de"));
    decryptOutputDir_->setText(QStringLiteral("/usr/local/assets/de"));

    auto *decryptButton = new QPushButton(tr("Decrypt File"), decryptBox);
    connect(decryptButton, &QPushButton::clicked, this, &MainWindow::onFileDecrypt);
    decryptForm->addRow(decryptButton);
    rightLayout->addWidget(decryptBox);

    rightLayout->addStretch(1);
    splitter->addWidget(scroll);
    splitter->setStretchFactor(0, 2);
    splitter->setStretchFactor(1, 3);
    root->addWidget(splitter, 1);

    fileStatus_ = new QLabel(tr("Select a file from the tree to inspect its properties."), page);
    root->addWidget(fileStatus_);

    return page;
}

QWidget *MainWindow::createAutomationTab()
{
    auto *page = new QWidget(this);
    auto *root = new QVBoxLayout(page);

    auto *buttonLayout = new QHBoxLayout;
    automationStartButton_ = new QPushButton(tr("Start Automation"), page);
    automationStopButton_ = new QPushButton(tr("Stop"), page);
    automationStopButton_->setEnabled(false);
    connect(automationStartButton_, &QPushButton::clicked,
            this, &MainWindow::onAutomationStart);
    connect(automationStopButton_, &QPushButton::clicked,
            this, &MainWindow::onAutomationStop);
    buttonLayout->addStretch(1);
    buttonLayout->addWidget(automationStartButton_);
    buttonLayout->addWidget(automationStopButton_);
    root->addLayout(buttonLayout);

    auto *logBox = new QGroupBox(tr("Process Log"), page);
    auto *logLayout = new QVBoxLayout(logBox);
    automationLog_ = new QPlainTextEdit(logBox);
    automationLog_->setReadOnly(true);
    automationLog_->setLineWrapMode(QPlainTextEdit::WidgetWidth);
    // Keep the endurance log bounded: only the most recent rounds are retained.
    automationLog_->setMaximumBlockCount(2000);
    logLayout->addWidget(automationLog_);
    root->addWidget(logBox, 1);

    return page;
}

void MainWindow::onFileTreeSelectionChanged(const QModelIndex &current,
                                            const QModelIndex &previous)
{
    Q_UNUSED(previous);

    if (!current.isValid()) {
        fileStatus_->setText(tr("Select a file from the tree to inspect its properties."));
        return;
    }

    const QString path = fileModel_->filePath(current);
    const QFileInfo info(path);
    if (!info.isFile()) {
        fileStatus_->setText(tr("Selected item is not a file."));
        return;
    }

    selectedNameLabel_->setText(info.fileName());
    selectedTypeLabel_->setText(info.suffix().isEmpty()
                                    ? tr("No extension")
                                    : info.suffix().toUpper());
    selectedDirectoryLabel_->setText(info.absolutePath());
    selectedSizeLabel_->setText(QStringLiteral("%1 bytes").arg(info.size()));

    encryptInputFile_->setText(info.absoluteFilePath());
    decryptEncryptedFile_->setText(info.absoluteFilePath());

    if (encryptKeyEdit_->text().trimmed().isEmpty())
        encryptKeyEdit_->setText(generateRandomKeyHex());
    if (encryptOutputDir_->text().trimmed().isEmpty())
        encryptOutputDir_->setText(info.absolutePath());
    if (keyOutputDir_->text().trimmed().isEmpty())
        keyOutputDir_->setText(info.absolutePath());
    if (decryptOutputDir_->text().trimmed().isEmpty())
        decryptOutputDir_->setText(info.absolutePath());

    fileStatus_->setText(tr("Ready to encrypt or decrypt the selected file."));
}

void MainWindow::onTextKeyGenerate()
{
    textKeyEdit_->setText(generateRandomKeyHex());
}

void MainWindow::onFileKeyGenerate()
{
    encryptKeyEdit_->setText(generateRandomKeyHex());
}

void MainWindow::onTextEncrypt()
{
    QString error;
    const QByteArray key = parseKeyHex(textKeyEdit_->text(), &error);
    if (key.isEmpty()) {
        textStatus_->setText(error);
        return;
    }

    setBusy(true);
    textStatus_->setText(tr("Encrypting..."));

    auto *watcher = new QFutureWatcher<OperationResult>(this);
    connect(watcher, &QFutureWatcher<OperationResult>::finished, this,
            [this, watcher]() {
        const OperationResult result = watcher->result();
        setBusy(false);
        if (result.ok) {
            textOutput_->setPlainText(QString::fromLatin1(result.data.toHex()));
            textStatus_->setText(tr("Encryption finished."));
        } else {
            textStatus_->setText(result.message);
            QMessageBox::warning(this, tr("Encryption Failed"), result.message);
        }
        watcher->deleteLater();
    });

    const QString input = textInput_->toPlainText();
    watcher->setFuture(QtConcurrent::run([this, input, key]() {
        return runTextEncrypt(input, key);
    }));
}

void MainWindow::onTextDecrypt()
{
    QString error;
    const QByteArray key = parseKeyHex(textKeyEdit_->text(), &error);
    if (key.isEmpty()) {
        textStatus_->setText(error);
        return;
    }

    setBusy(true);
    textStatus_->setText(tr("Decrypting..."));

    auto *watcher = new QFutureWatcher<OperationResult>(this);
    connect(watcher, &QFutureWatcher<OperationResult>::finished, this,
            [this, watcher]() {
        const OperationResult result = watcher->result();
        setBusy(false);
        if (result.ok) {
            textOutput_->setPlainText(QString::fromUtf8(result.data));
            textStatus_->setText(tr("Decryption finished."));
        } else {
            textStatus_->setText(result.message);
            QMessageBox::warning(this, tr("Decryption Failed"), result.message);
        }
        watcher->deleteLater();
    });

    const QString input = textInput_->toPlainText();
    watcher->setFuture(QtConcurrent::run([this, input, key]() {
        return runTextDecrypt(input, key);
    }));
}

void MainWindow::onFileEncrypt()
{
    QString error;
    const QByteArray key = parseKeyHex(encryptKeyEdit_->text(), &error);
    if (key.isEmpty()) {
        fileStatus_->setText(error);
        return;
    }

    const QString inputPath = encryptInputFile_->text().trimmed();
    const QFileInfo inputInfo(inputPath);
    if (!inputInfo.isFile()) {
        fileStatus_->setText(tr("Select a valid input file."));
        return;
    }

    const QString outputDir = directoryOrDefault(encryptOutputDir_->text(),
                                                  inputInfo.absolutePath());
    const QString keyDir = directoryOrDefault(keyOutputDir_->text(),
                                               inputInfo.absolutePath());
    const QString outputPath = QDir(outputDir).filePath(inputInfo.completeBaseName() + QStringLiteral(".aes"));
    const QString keyPath = QDir(keyDir).filePath(inputInfo.completeBaseName() + QStringLiteral(".key"));

    setBusy(true);
    fileStatus_->setText(tr("Encrypting file..."));

    auto *watcher = new QFutureWatcher<OperationResult>(this);
    connect(watcher, &QFutureWatcher<OperationResult>::finished, this,
            [this, watcher]() {
        const OperationResult result = watcher->result();
        setBusy(false);
        fileStatus_->setText(result.message);
        if (!result.ok)
            QMessageBox::warning(this, tr("File Encryption Failed"), result.message);
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([this, inputPath, outputPath, key, keyPath]() {
        return runFileEncrypt(inputPath, outputPath, key, keyPath);
    }));
}

void MainWindow::onFileDecrypt()
{
    QString error;
    const QByteArray key = readKeyFile(decryptKeyFile_->text(), &error);
    if (key.isEmpty()) {
        fileStatus_->setText(error);
        return;
    }

    const QString inputPath = decryptEncryptedFile_->text().trimmed();
    const QFileInfo inputInfo(inputPath);
    if (!inputInfo.isFile()) {
        fileStatus_->setText(tr("Select a valid encrypted file."));
        return;
    }

    const QString outputDir = directoryOrDefault(decryptOutputDir_->text(),
                                                  inputInfo.absolutePath());
    const QString outputPath = QDir(outputDir).filePath(inputInfo.completeBaseName() + QStringLiteral(".dec"));

    setBusy(true);
    fileStatus_->setText(tr("Decrypting file..."));

    auto *watcher = new QFutureWatcher<OperationResult>(this);
    connect(watcher, &QFutureWatcher<OperationResult>::finished, this,
            [this, watcher]() {
        const OperationResult result = watcher->result();
        setBusy(false);
        fileStatus_->setText(result.message);
        if (!result.ok)
            QMessageBox::warning(this, tr("File Decryption Failed"), result.message);
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([this, inputPath, outputPath, key]() {
        return runFileDecrypt(inputPath, outputPath, key);
    }));
}

void MainWindow::onAutomationStart()
{
    if (automationRunning_.load() || busy_)
        return;

    const QString inputPath =
        QStringLiteral("/usr/local/assets/en/ENCRYPT_ME.jpg");
    if (!QFileInfo::exists(inputPath)) {
        appendAutomationLog(tr("Cannot start automation: input file not found: %1")
                            .arg(inputPath));
        return;
    }

    const QString outputDir = QStringLiteral("/usr/local/assets/de");
    if (!QDir().mkpath(outputDir)) {
        appendAutomationLog(tr("Cannot start automation: output directory unavailable: %1")
                            .arg(outputDir));
        return;
    }

    automationRunning_.store(true);
    automationLog_->clear();
    automationStartButton_->setEnabled(false);
    automationStopButton_->setEnabled(true);
    for (int i = 0; i < tabs_->count() - 1; ++i)
        tabs_->setTabEnabled(i, false);

    logAutomation(tr("Automation started."));

    automationWatcher_ = new QFutureWatcher<void>(this);
    connect(automationWatcher_, &QFutureWatcher<void>::finished, this, [this]() {
        automationRunning_.store(false);
        for (int i = 0; i < tabs_->count() - 1; ++i)
            tabs_->setTabEnabled(i, true);
        automationStartButton_->setEnabled(true);
        automationStopButton_->setEnabled(false);
        if (automationWatcher_) {
            automationWatcher_->deleteLater();
            automationWatcher_ = nullptr;
        }
    });
    automationWatcher_->setFuture(QtConcurrent::run([this]() {
        runAutomationLoop();
    }));
}

void MainWindow::onAutomationStop()
{
    if (!automationRunning_.load())
        return;

    automationRunning_.store(false);
    automationStopButton_->setEnabled(false);
    appendAutomationLog(tr("Stop requested; waiting for the current round to finish..."));
}

void MainWindow::appendAutomationLog(const QString &line)
{
    if (!automationLog_)
        return;

    const QString timestamp =
        QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));
    automationLog_->appendPlainText(QStringLiteral("[%1] %2").arg(timestamp, line));
    automationLog_->verticalScrollBar()->setValue(
        automationLog_->verticalScrollBar()->maximum());
}

void MainWindow::runAutomationLoop()
{
    const QString inputPath =
        QStringLiteral("/usr/local/assets/en/ENCRYPT_ME.jpg");
    const QString outputDir = QStringLiteral("/usr/local/assets/de");
    const QString cipherPath =
        QDir(outputDir).filePath(QStringLiteral("ENCRYPT_ME.aes"));
    const QString keyPath =
        QDir(outputDir).filePath(QStringLiteral("ENCRYPT_ME.key"));
    const QString decryptedPath =
        QDir(outputDir).filePath(QStringLiteral("ENCRYPT_ME.dec"));

    auto waitForFile = [this](const QString &path) {
        QElapsedTimer timer;
        timer.start();
        while (automationRunning_.load()) {
            if (QFileInfo::exists(path))
                return true;
            if (timer.elapsed() >= 10000)
                return false;
            QThread::msleep(50);
        }
        return false;
    };

    QElapsedTimer runTimer;
    runTimer.start();
    qint64 rounds = 0;
    int timeouts = 0;
    int errors = 0;

    while (automationRunning_.load()) {
        ++rounds;

        // Clear outputs from the previous round so a timeout cannot match a
        // stale file.
        QFile::remove(cipherPath);
        QFile::remove(keyPath);
        QFile::remove(decryptedPath);

        const QString keyText = generateRandomKeyHex();
        QString keyError;
        const QByteArray key = parseKeyHex(keyText, &keyError);
        if (key.isEmpty()) {
            ++errors;
            logAutomation(tr("Round %1: generated an invalid key (%2).")
                          .arg(rounds).arg(keyError));
            continue;
        }

        const OperationResult encryptResult =
            runFileEncrypt(inputPath, cipherPath, key, keyPath);
        if (!encryptResult.ok) {
            ++errors;
            logAutomation(tr("Round %1 encryption failed: %2")
                          .arg(rounds).arg(encryptResult.message));
            continue;
        }

        if (!automationRunning_.load())
            break;

        if (!waitForFile(cipherPath)) {
            if (!automationRunning_.load())
                break;
            ++timeouts;
            logAutomation(tr("Round %1 TIMEOUT: encrypted file did not appear "
                             "within 10 seconds.").arg(rounds));
            continue;
        }

        const QByteArray storedKey = readKeyFile(keyPath, &keyError);
        if (storedKey.isEmpty()) {
            ++errors;
            logAutomation(tr("Round %1: cannot read generated key file: %2")
                          .arg(rounds).arg(keyError));
            continue;
        }

        const OperationResult decryptResult =
            runFileDecrypt(cipherPath, decryptedPath, storedKey);
        if (!decryptResult.ok) {
            ++errors;
            logAutomation(tr("Round %1 decryption failed: %2")
                          .arg(rounds).arg(decryptResult.message));
            continue;
        }

        if (!automationRunning_.load())
            break;

        if (!waitForFile(decryptedPath)) {
            if (!automationRunning_.load())
                break;
            ++timeouts;
            logAutomation(tr("Round %1 TIMEOUT: decrypted file did not appear "
                             "within 10 seconds.").arg(rounds));
            continue;
        }

        logAutomation(tr("Round %1 completed.").arg(rounds));
    }

    const qint64 elapsedMs = runTimer.elapsed();
    logAutomation(tr("Automation stopped. Rounds completed: %1, runtime: %2 seconds, "
                     "timeout anomalies: %3, errors: %4.")
                  .arg(rounds)
                  .arg(elapsedMs / 1000.0, 0, 'f', 1)
                  .arg(timeouts)
                  .arg(errors));
}

void MainWindow::logAutomation(const QString &line)
{
    QMetaObject::invokeMethod(this, "appendAutomationLog", Qt::QueuedConnection,
                              Q_ARG(QString, line));
}

QString MainWindow::generateRandomKeyHex() const
{
    QByteArray key(16, 0);
    for (int i = 0; i < key.size(); ++i)
        key[i] = static_cast<char>(QRandomGenerator::system()->bounded(256));
    return QString::fromLatin1(key.toHex().toUpper());
}

QByteArray MainWindow::parseKeyHex(const QString &text, QString *error) const
{
    QString cleaned = text;
    cleaned.remove(QRegularExpression(QStringLiteral("\\s")));
    if (cleaned.size() != 32
        || !QRegularExpression(QStringLiteral("^[0-9A-Fa-f]{32}$")).match(cleaned).hasMatch()) {
        if (error)
            *error = tr("Key must contain exactly 32 hexadecimal characters.");
        return {};
    }

    const QByteArray key = QByteArray::fromHex(cleaned.toLatin1());
    if (key.size() != 16) {
        if (error)
            *error = tr("Key contains invalid hexadecimal characters.");
        return {};
    }
    return key;
}

QByteArray MainWindow::readKeyFile(const QString &path, QString *error) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        if (error)
            *error = tr("Cannot open key file: %1").arg(path);
        return {};
    }

    const QByteArray data = file.readAll();
    if (data.size() == 16)
        return data;

    QString text = QString::fromLatin1(data);
    text.remove(QRegularExpression(QStringLiteral("\\s")));
    if (text.size() == 32
        && QRegularExpression(QStringLiteral("^[0-9A-Fa-f]{32}$")).match(text).hasMatch()) {
        const QByteArray key = QByteArray::fromHex(text.toLatin1());
        if (key.size() == 16)
            return key;
    }

    if (error)
        *error = tr("Key file must contain 16 raw bytes or 32 hexadecimal characters.");
    return {};
}

QString MainWindow::directoryOrDefault(const QString &directory,
                                       const QString &fallbackDirectory) const
{
    const QString value = directory.trimmed();
    return value.isEmpty() ? fallbackDirectory : value;
}

MainWindow::OperationResult MainWindow::runTextEncrypt(const QString &plainText,
                                                       const QByteArray &key)
{
    const QByteArray padded = AesSoft::pkcs7Pad(plainText.toUtf8());
    QByteArray encrypted;
    QString error;

    if (device_.setKey(key, &error))
        encrypted = device_.encryptBlocks(padded, &error);

    if (encrypted.isEmpty()) {
        encrypted = AesSoft::encryptBlocks(padded, key, &error);
        if (encrypted.isEmpty())
            return {false, error, {}};
    }

    return {true, tr("Encryption finished."), encrypted};
}

MainWindow::OperationResult MainWindow::runTextDecrypt(const QString &hexText,
                                                       const QByteArray &key)
{
    QString cleaned = hexText;
    cleaned.remove(QRegularExpression(QStringLiteral("\\s")));
    if (cleaned.isEmpty()
        || !QRegularExpression(QStringLiteral("^[0-9A-Fa-f]+$")).match(cleaned).hasMatch())
        return {false, tr("Ciphertext must contain hexadecimal characters only."), {}};

    const QByteArray encrypted = QByteArray::fromHex(cleaned.toLatin1());
    if (encrypted.isEmpty() || encrypted.size() % 16 != 0)
        return {false, tr("Ciphertext must be non-empty hexadecimal data with a multiple of 16 bytes."), {}};

    QString error;
    QByteArray plain = AesSoft::decryptBlocks(encrypted, key, &error);
    if (plain.isEmpty())
        return {false, error, {}};

    QString unpadError;
    const QByteArray unpadded = AesSoft::pkcs7Unpad(plain, &unpadError);
    if (!unpadError.isEmpty())
        return {false, unpadError, {}};

    return {true, tr("Decryption finished."), unpadded};
}

MainWindow::OperationResult MainWindow::runFileEncrypt(const QString &inputPath,
                                                       const QString &outputPath,
                                                       const QByteArray &key,
                                                       const QString &keySavePath)
{
    if (!keySavePath.isEmpty()) {
        QFile keyFile(keySavePath);
        if (!keyFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
            return {false, tr("Cannot save key file: %1").arg(keySavePath), {}};
        keyFile.write(key.toHex().toUpper());
    }

    QString error;
    bool ok = device_.encryptFile(inputPath, outputPath, key, &error);
    if (!ok)
        ok = AesSoft::encryptFile(inputPath, outputPath, key, &error);

    if (!ok)
        return {false, error, {}};
    return {true, tr("File encryption finished."), {}};
}

MainWindow::OperationResult MainWindow::runFileDecrypt(const QString &inputPath,
                                                       const QString &outputPath,
                                                       const QByteArray &key)
{
    QString error;
    if (!AesSoft::decryptFile(inputPath, outputPath, key, &error))
        return {false, error, {}};
    return {true, tr("File decryption finished."), {}};
}

void MainWindow::startOperation(const std::function<OperationResult()> &operation,
                                QLabel *statusLabel)
{
    if (busy_ || !statusLabel)
        return;

    setBusy(true);
    statusLabel->setText(tr("Working..."));

    auto *watcher = new QFutureWatcher<OperationResult>(this);
    connect(watcher, &QFutureWatcher<OperationResult>::finished, this,
            [this, watcher, statusLabel]() {
        const OperationResult result = watcher->result();
        setBusy(false);
        statusLabel->setText(result.message);
        if (!result.ok)
            QMessageBox::warning(this, tr("Operation Failed"), result.message);
        watcher->deleteLater();
    });
    watcher->setFuture(QtConcurrent::run(operation));
}

void MainWindow::setBusy(bool busy)
{
    busy_ = busy;
    if (tabs_)
        tabs_->setEnabled(!busy);
}

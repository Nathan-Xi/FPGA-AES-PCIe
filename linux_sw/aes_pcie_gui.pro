QT += core gui widgets concurrent

TARGET = aes_pcie_gui
TEMPLATE = app

CONFIG += c++17
CONFIG -= app_bundle

SOURCES += \
    src/main.cpp \
    src/mainwindow.cpp \
    src/aes_device.cpp \
    src/aes_soft.cpp

HEADERS += \
    src/mainwindow.h \
    src/aes_device.h \
    src/aes_soft.h

INCLUDEPATH += $$PWD/src

# The application talks to /dev/mem or /dev/bdma0_user. Run it as root.

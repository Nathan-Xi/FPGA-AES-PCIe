#include "mainwindow.h"

#include <QApplication>
#include <QDebug>
#include <QEvent>
#include <QObject>
#include <QScreen>
#include <QTouchDevice>

namespace {

const char *eventName(QEvent::Type type)
{
    switch (type) {
    case QEvent::TouchBegin: return "touch begin";
    case QEvent::TouchUpdate: return "touch update";
    case QEvent::TouchEnd: return "touch end";
    case QEvent::MouseButtonPress: return "mouse press";
    case QEvent::MouseButtonRelease: return "mouse release";
    default: return "other";
    }
}

// Enabled by --trace-input: logs the touch/mouse events that actually reach the
// application, which separates "the compositor never delivered anything" from
// "the events arrived but nothing reacted".
class InputTracer : public QObject
{
public:
    bool eventFilter(QObject *object, QEvent *event) override
    {
        switch (event->type()) {
        case QEvent::TouchBegin:
        case QEvent::TouchUpdate:
        case QEvent::TouchEnd:
        case QEvent::MouseButtonPress:
        case QEvent::MouseButtonRelease:
            qInfo() << "input:" << eventName(event->type());
            break;
        default:
            break;
        }
        return QObject::eventFilter(object, event);
    }
};

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // Orientation and touch both depend on what the app is drawing through:
    // as a Wayland client it inherits the compositor's output transform and
    // input, while under eglfs it drives the display and reads /dev/input
    // itself. Print what we ended up with so a misconfigured launch is obvious
    // in the terminal.
    qInfo() << "platform plugin:" << QGuiApplication::platformName();
    if (const QScreen *screen = QGuiApplication::primaryScreen()) {
        const QRect geometry = screen->geometry();
        qInfo() << "screen:" << screen->name() << geometry
                << (geometry.height() > geometry.width() ? "(portrait)"
                                                         : "(landscape)");
    }
    // Under Wayland a touch device is only registered once the compositor
    // announces the capability, so the list reflects what the compositor
    // offered. QTouchDevice::DeviceType has TouchScreen == 0, TouchPad == 1.
    const QList<const QTouchDevice *> devices = QTouchDevice::devices();
    qInfo() << "touch devices:" << devices.size();
    for (const QTouchDevice *device : devices) {
        qInfo() << "   " << (device->name().isEmpty() ? "(unnamed)" : device->name())
                << (device->type() == QTouchDevice::TouchScreen ? "touchscreen"
                                                                : "touchpad");
    }

    static InputTracer tracer;
    if (app.arguments().contains(QStringLiteral("--trace-input"))) {
        app.installEventFilter(&tracer);
        qInfo() << "input tracing enabled - tap the screen to see the events";
    }

    MainWindow window;
    window.showFullScreen();
    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "device.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Nicominecith X11");
    app.setOrganizationName("Nicominecith");
    Device dev;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("dev", &dev);
    #if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    engine.loadFromModule("Nico", "Main");
#else
    engine.load(QUrl("qrc:/Nico/qml/Main.qml"));
#endif
    if (engine.rootObjects().isEmpty()) return -1;
    dev.refresh();
    return app.exec();
}

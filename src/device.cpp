#include "device.h"
#include <QtConcurrent>
#include <QSettings>
#include <QThread>
#ifdef Q_OS_ANDROID
#include <QJniObject>
#include <QCoreApplication>
#endif

namespace {
constexpr uint16_t kVid = 0x1d57, kPidWireless = 0xfa60, kPidWired = 0xfa55;
constexpr int kIface = 2;
const uint8_t POLL[4][2] = {{0x08,0xF7},{0x04,0xFB},{0x02,0xFD},{0x01,0xFE}}; // 125/250/500/1000 Hz
const uint8_t COLOR[4][15] = {
 {0x05,0x0F,0x01,0x10,0x01,0xA8,0,0,0x00,0x01,0x06,0x00,0xC0,0,0},
 {0x05,0x0F,0x01,0x20,0x01,0xA8,0,0,0xFF,0x01,0x06,0x01,0xCF,0,0},
 {0x05,0x0F,0x01,0x30,0x01,0xA8,0,0,0xFF,0x01,0x06,0x01,0xDF,0,0},
 {0x05,0x0F,0x01,0x40,0x01,0xA8,0,0,0xFF,0x01,0x06,0x01,0xEF,0,0}};
}

libusb_device_handle *Device::open(libusb_context *ctx)
{
#ifdef Q_OS_ANDROID
    if (m_fd < 0) return nullptr;
    libusb_device_handle *h = nullptr;
    return libusb_wrap_sys_device(ctx, m_fd, &h) == 0 ? h : nullptr;
#else
    auto *h = libusb_open_device_with_vid_pid(ctx, kVid, kPidWireless);
    return h ? h : libusb_open_device_with_vid_pid(ctx, kVid, kPidWired);
#endif
}

bool Device::send(libusb_context *ctx, uint16_t id, const uint8_t *d, int len)
{
    auto *h = open(ctx);
    if (!h) return false;
    libusb_set_auto_detach_kernel_driver(h, 1);
    libusb_claim_interface(h, kIface);
    int rc = libusb_control_transfer(h, 0x21, 0x09, id, kIface, const_cast<uint8_t*>(d), len, 200);
    libusb_release_interface(h, kIface);
    libusb_close(h);
    return rc == len || rc == LIBUSB_ERROR_TIMEOUT;
}

static libusb_context *initUsb()
{
    libusb_context *ctx = nullptr;
#ifdef Q_OS_ANDROID
    libusb_set_option(nullptr, LIBUSB_OPTION_NO_DEVICE_DISCOVERY);
#endif
    return libusb_init(&ctx) == 0 ? ctx : nullptr;
}

int Device::applyBlocking()
{
    if (m_key < 4 || m_key > 50 || m_key % 2) return -1;
    libusb_context *ctx = initUsb();
    if (!ctx) return -2;
    const uint8_t pr[9] = {0x06,0x09,0x01,POLL[m_poll][0],POLL[m_poll][1],0,0,0,0};
    bool a = send(ctx, 0x0306, pr, 9);              QThread::msleep(300);
    bool b = send(ctx, 0x0305, COLOR[m_color], 15); QThread::msleep(300);
    const uint8_t r[56] = {0x04,0x38,0x01,(uint8_t)m_angle,(uint8_t)m_ripple,0x3f,0,0,0x01,
      0x25,0x38,0x4b,0x75,0x8d,0,0,0,0,0,0,0,0x01,0,0,0x02,0xff,0,0,0,0xff,0,0,0,
      0xff,0xff,0xff,0,0,0xff,0xff,0xff,0,0xff,0xff,0x40,0,0xff,0xff,0xff,0x02,0x0f,0x34,0,0,0,0};
    bool c = send(ctx, 0x0304, r, 56);
    libusb_exit(ctx);
    return (a && b && c) ? 0 : -5;
}

int Device::readBattery()
{
    libusb_context *ctx = initUsb();
    if (!ctx) return -1;
    auto *h = open(ctx);
    if (!h) { libusb_exit(ctx); return -1; }
    libusb_set_auto_detach_kernel_driver(h, 1);
    int bat = -1;
    if (libusb_claim_interface(h, kIface) == 0) {
        for (int i = 0; i < 5 && bat < 0; ++i) {
            uint8_t buf[64] = {}; int n = 0;
            int rc = libusb_interrupt_transfer(h, 0x83, buf, 64, &n, 500);
            if (rc != 0 && rc != LIBUSB_ERROR_TIMEOUT) break;
            if (n >= 5 && buf[0]==0x03 && buf[1]==0x55 && buf[2]==0x40 && buf[3]==0x01) bat = buf[4];
        }
        if (bat < 0) bat = -2; // Interface da, aber keine Funkdaten = lädt
        libusb_release_interface(h, kIface);
    }
    libusb_close(h); libusb_exit(ctx);
    return bat;
}

void Device::setState(bool c, int b, const QString &s, bool busy)
{
    m_connected = c; m_battery = b; m_status = s; m_busy = busy;
    emit stateChanged();
}

void Device::refresh()
{
#ifdef Q_OS_ANDROID
    m_fd = QJniObject::callStaticMethod<jint>("de/nicominecith/UsbHelper", "openFd",
        "(Landroid/content/Context;)I", QNativeInterface::QAndroidApplication::context().object());
    if (m_fd < 0) { setState(false, -1, "USB-Erlaubnis erteilen, dann erneut tippen"); return; }
#endif
    setState(false, -1, "Suche Maus …", true);
    (void)QtConcurrent::run([this] {
        int b = readBattery();
        QMetaObject::invokeMethod(this, [this, b] {
            if (b == -1) setState(false, -1, "Keine Maus gefunden");
            else setState(true, b, b == -2 ? "Verbunden (lädt)" : "Verbunden");
        });
    });
}

void Device::apply()
{
    setState(m_connected, m_battery, "Übertrage …", true);
    (void)QtConcurrent::run([this] {
        int rc = applyBlocking();
        QMetaObject::invokeMethod(this, [this, rc] {
            setState(m_connected, m_battery, rc == 0 ? "Gespeichert ✓" : QString("Fehler (%1)").arg(rc));
        });
    });
}

void Device::saveProfile(int s)
{
    QSettings q; q.beginGroup(QString("profile%1").arg(s));
    q.setValue("c", m_color); q.setValue("p", m_poll); q.setValue("a", m_angle);
    q.setValue("r", m_ripple); q.setValue("k", m_key); q.setValue("s", m_sleep); q.setValue("d", m_deep);
    setState(m_connected, m_battery, QString("Profil %1 gespeichert").arg(s + 1));
}

void Device::loadProfile(int s)
{
    QSettings q; q.beginGroup(QString("profile%1").arg(s));
    if (!q.contains("c")) { setState(m_connected, m_battery, QString("Profil %1 ist leer").arg(s + 1)); return; }
    m_color = q.value("c").toInt(); m_poll = q.value("p").toInt(); m_angle = q.value("a").toBool();
    m_ripple = q.value("r").toBool(); m_key = q.value("k").toInt(); m_sleep = q.value("s").toInt();
    m_deep = q.value("d").toInt();
    emit changed();
    setState(m_connected, m_battery, QString("Profil %1 geladen").arg(s + 1));
}

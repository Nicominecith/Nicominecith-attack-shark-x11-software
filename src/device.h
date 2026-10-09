#pragma once
#include <QObject>
#include <QString>
#include <libusb.h>

class Device : public QObject {
    Q_OBJECT
    Q_PROPERTY(int colorMode MEMBER m_color NOTIFY changed)
    Q_PROPERTY(int pollingIdx MEMBER m_poll NOTIFY changed)
    Q_PROPERTY(bool angleSnap MEMBER m_angle NOTIFY changed)
    Q_PROPERTY(bool ripple MEMBER m_ripple NOTIFY changed)
    Q_PROPERTY(int keyResp MEMBER m_key NOTIFY changed)
    Q_PROPERTY(int sleepTime MEMBER m_sleep NOTIFY changed)
    Q_PROPERTY(int deepSleep MEMBER m_deep NOTIFY changed)
    Q_PROPERTY(int battery READ battery NOTIFY stateChanged)   // -1 unbekannt, -2 lädt
    Q_PROPERTY(bool connected READ connected NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
public:
    explicit Device(QObject *p = nullptr) : QObject(p) {}
    int battery() const { return m_battery; }
    bool connected() const { return m_connected; }
    bool busy() const { return m_busy; }
    QString status() const { return m_status; }
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void apply();
    Q_INVOKABLE void saveProfile(int slot);
    Q_INVOKABLE void loadProfile(int slot);
signals:
    void changed();
    void stateChanged();
private:
    libusb_device_handle *open(libusb_context *ctx);
    bool send(libusb_context *ctx, uint16_t reportId, const uint8_t *d, int len);
    int applyBlocking();
    int readBattery();
    void setState(bool connected, int battery, const QString &status, bool busy = false);
    int m_color = 1, m_poll = 3, m_key = 8, m_sleep = 2, m_deep = 10, m_battery = -1;
    bool m_angle = false, m_ripple = false, m_connected = false, m_busy = false;
    QString m_status = "Suche Maus …";
    int m_fd = -1; // Android: USB-Dateideskriptor
};

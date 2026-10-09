package de.nicominecith;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.os.Build;

public class UsbHelper {
    private static UsbDeviceConnection conn; // offen halten, sonst wird der FD ungültig

    /** Liefert den USB-Dateideskriptor der Maus oder -1 (keine Maus / Erlaubnis angefragt). */
    public static int openFd(Context ctx) {
        UsbManager mgr = (UsbManager) ctx.getSystemService(Context.USB_SERVICE);
        for (UsbDevice d : mgr.getDeviceList().values()) {
            if (d.getVendorId() != 0x1d57) continue;
            if (!mgr.hasPermission(d)) {
                int flags = Build.VERSION.SDK_INT >= 31 ? PendingIntent.FLAG_MUTABLE : 0;
                mgr.requestPermission(d, PendingIntent.getBroadcast(ctx, 0,
                        new Intent("de.nicominecith.USB_PERMISSION").setPackage(ctx.getPackageName()), flags));
                return -1;
            }
            if (conn != null) conn.close();
            conn = mgr.openDevice(d);
            return conn == null ? -1 : conn.getFileDescriptor();
        }
        return -1;
    }
}

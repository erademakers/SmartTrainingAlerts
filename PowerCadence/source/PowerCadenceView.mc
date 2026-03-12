import Toybox.System;
import Toybox.Activity;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
using Toybox.Attention;
import Toybox.Notifications;

import Settings;

//https://developer.garmin.com/connect-iq/api-docs/

class PowerCadenceView extends WatchUi.DataField {    
    var lastAlert = 0.0;
    var cadenceLowStart = null;
    var alertActive = false; // Nieuw: houdt bij of alert actief is

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Graphics.COLOR_RED;
    var popupFg = Graphics.COLOR_WHITE;
    var fCadenceTop = null;

    (:debuglog)
    function debugLogImpl(msg) {
        System.println(msg);
    }

    function debugLog(msg) {
        if (self has :debugLogImpl) {
            debugLogImpl(msg);
        }
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fCadenceTop = View.findDrawableById("cadenceTop") as Text;
    }

    function initialize() {
        DataField.initialize();
    }   

    function onUpdate(dc as Graphics.Dc) {
        var info = Activity.getActivityInfo();
        if (info == null) {return;}

        var power = info.currentPower;
        var cad   = info.currentCadence;

        var pT  = Settings.getNumber("pc_power", 300);
        var cT  = Settings.getNumber("pc_cadence", 70);
        var dur = Settings.getNumber("pc_duration", 5);
        var alertEnabled = Settings.getBool("pc_alert", true);

        // Track time with low cadence
        if (cad != null && cad < cT) {
            if (cadenceLowStart == null) {cadenceLowStart = System.getTimer();}
        } else {
            cadenceLowStart = null;
        }

        var color = Graphics.COLOR_GREEN;
        var bottom = "";

        if (power == null) {power = 0;}
        if (cad == null) {cad = 0;}

        var top = cad.format("%d");

        if (cadenceLowStart != null) {
            var elapsed = System.getTimer() - cadenceLowStart;
            color = (power > pT && elapsed >= dur) ? Graphics.COLOR_RED : Graphics.COLOR_ORANGE;
            if (power > pT && elapsed >= dur) {
                if (!alertActive) {
                    _alert(alertEnabled, "Low cadence at high power");
                    lastAlert = System.getTimer();
                    alertActive = true;
                }
            } else {
                if (alertActive) {
                    _alertEnd(alertEnabled, "Cadence OK");
                    alertActive = false;
                }
            }
        } else {
            if (alertActive) {
                _alertEnd(alertEnabled, "Cadence OK");
                alertActive = false;
            }
        }

        bottom = "Current " + power + " W • Thr " + pT + " W • Current " + cad + " rpm • Thr " + cT + " rpm";

        if (fCadenceTop != null) {
            fCadenceTop.setColor(color);
            fCadenceTop.setText(top);
        }

        debugLog("[PowerCadence] " + bottom);

        View.onUpdate(dc);

        // // draw popup if active
        // if (System.getTimer() < popupUntil && popupText != null) {
        //     UiPopup.drawPopup(dc, popupText, popupBg, popupFg);
        // }
    }

    function _alert(alertEnabled, message) {
        if (alertEnabled) {Attention.playTone(Attention.TONE_ALARM);}
        // if (alertEnabled) {
        //     Notifications.showNotification("Cadence", message, {});
        // }
    }

    function _alertEnd(alertEnabled, message) {
        if (alertEnabled) {Attention.playTone(Attention.TONE_RESET);}
        // if (alertEnabled) {
        //     Notifications.showNotification("Cadence", message, {});
        // }
    }
}
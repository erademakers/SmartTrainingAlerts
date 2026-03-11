import Toybox.System;
import Toybox.Activity;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;

import Settings;
import UiPopup;
import LayoutUtils;

//https://developer.garmin.com/connect-iq/api-docs/

class PowerCadenceView extends WatchUi.DataField {    
    var lastAlert = 0.0;
    var cadenceLowStart = null;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Graphics.COLOR_RED;
    var popupFg = Graphics.COLOR_WHITE;

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
        var rpt = Settings.getNumber("pc_repeat", 30);
        var aT  = Settings.getNumber("pc_alert", 2);

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

        var top = cad + " rpm";

        if (cadenceLowStart != null) {
            var elapsed = System.getTimer() - cadenceLowStart;
            color = (power > pT && elapsed >= dur) ? Graphics.COLOR_RED : Graphics.COLOR_ORANGE;

            // if (power > pT && elapsed >= dur) {
            //     if (System.getTimer() - lastAlert >= rpt) {
            //         _alert(aT, "Low cadence at high power");
            //         lastAlert = System.getTimer();
            //     }
            // }
        }

        bottom = power + " W • Thr " + pT + " W • Thr " + cT + " rpm";

        LayoutUtils.drawTwoLineCenter(dc, top, bottom, color);

        // draw popup if active
        if (System.getTimer() < popupUntil && popupText != null) {
            UiPopup.drawPopup(dc, popupText, popupBg, popupFg);
        }

        // View.findDrawableById("Background").setColor(getBackgroundColor());
        // var value = View.findDrawableById("value");
        // value.setColor(Graphics.COLOR_BLACK);
        // value.setText(cad.format("%.2f"));
        // View.onUpdate(dc);
    }

    function _alert(aT, message) {
        // if (aT == 0 || aT == 2) {Sys.playTone(Sys.Tone.TONE_ALERT);}
        if (aT == 1 || aT == 2) {
            popupText = message;
            popupBg = Graphics.COLOR_RED;

            popupFg = Graphics.COLOR_WHITE;
            popupUntil = System.getTimer() + 3; // show 3s
            WatchUi.requestUpdate();
        }
    }
}

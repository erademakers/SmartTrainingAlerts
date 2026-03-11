using Toybox.System as Sys;
using Toybox.Activity as Act;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;

import Settings;
import UiPopup;
import LayoutUtils;

class PowerCadenceView extends Ui.SimpleDataField {    
    var lastAlert = 0.0;
    var cadenceLowStart = null;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "SmartCadence";
    }    

    function onUpdate(dc as Gfx.Dc) {
        var info = Act.getActivityInfo();
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
            if (cadenceLowStart == null) {cadenceLowStart = Sys.getTimer();}
        } else {
            cadenceLowStart = null;
        }

        var color = Gfx.COLOR_GREEN;
        var bottom = "";

        if (power == null) {power = 0;}
        if (cad == null) {cad = 0;}

        var top = power + " W";

        if (cadenceLowStart != null) {
            var elapsed = Sys.getTimer() - cadenceLowStart;
            bottom = "Cad " + cad + " rpm • " + Lang.format("%ds", [elapsed.toNumber().toNumber()]) + " < " + cT + " rpm";
            color = (power > pT && elapsed >= dur) ? Gfx.COLOR_RED : Gfx.COLOR_ORANGE;

            if (power > pT && elapsed >= dur) {
                if (Sys.getTimer() - lastAlert >= rpt) {
                    _alert(aT, "Low cadence at high power");
                    lastAlert = Sys.getTimer();
                }
            }
        } else {
            bottom = "Cad " + cad + " rpm • Thr " + cT + " rpm";
        }

        // LayoutUtils.drawTwoLineCenter(dc, top, bottom, color);

        // draw popup if active
        if (Sys.getTimer() < popupUntil && popupText != null) {
            UiPopup.drawPopup(dc, popupText, popupBg, popupFg);
        }
    }

    function _alert(aT, message) {
        // if (aT == 0 || aT == 2) {Sys.playTone(Sys.Tone.TONE_ALERT);}
        if (aT == 1 || aT == 2) {
            popupText = message;
            popupBg = Gfx.COLOR_RED;

            popupFg = Gfx.COLOR_WHITE;
            popupUntil = Sys.getTimer() + 3; // show 3s
            Ui.requestUpdate();
        }
    }
}

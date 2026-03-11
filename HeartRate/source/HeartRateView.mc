using Toybox.System as Sys;
using Toybox.Activity as Act;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.UserProfile as Prof;
using Toybox.Lang as Lang;

import Settings;
import UiPopup;
import ZoneColors;
import LayoutUtils;

class HeartRateView extends Ui.DataField {
    var lastAlert = [0,0,0,0,0,0];
    var zoneStart = [null,null,null,null,null,null];
    var currentZone = 0;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;

    function getZone(hr as Number) as Number {
        var max = null;
        try { max = Prof.getMaxHeartRate(); } catch(e) { max = null; }
        if (max == null) max = 190; // fallback
        var p = (hr*100.0)/max;
        if (p < 60) return 1;
        if (p < 70) return 2;
        if (p < 80) return 3;
        if (p < 90) return 4;
        return 5;
    }

    function onUpdate(dc as Dc) {
        var info = Act.getCurrentActivityInfo();
        if (info == null) return;
        var hr = info.heartRate;
        if (hr == null) return;

        var zone = getZone(hr);

        // reset logic when zone decreases
        if (currentZone == 0) {
            currentZone = zone;
            zoneStart[zone] = Sys.getTimer();
        } else if (zone != currentZone) {
            if (zone < currentZone) {
                // reset timers for higher zones
                for (var i = zone+1; i <= 5; i += 1) {
                    zoneStart[i] = null;
                    lastAlert[i] = 0;
                }
            }
            currentZone = zone;
            zoneStart[zone] = Sys.getTimer();
        }

        if (zoneStart[zone] == null) zoneStart[zone] = Sys.getTimer();

        var elapsed = (Sys.getTimer() - zoneStart[zone]).toNumber().toInt();

        // settings
        var disableZ1 = Settings.getBool("hr_disable_zone1", true);
        var disableZ2 = Settings.getBool("hr_disable_zone2", true);
        var enabled = true;
        if (zone == 1 && disableZ1) enabled = false;
        if (zone == 2 && disableZ2) enabled = false;

        var maxT = Settings.getNumber("hr_zone"+zone+"_max", zone<=2?18000:300);
        var rpt  = Settings.getNumber("hr_zone"+zone+"_repeat", 30);
        var aT   = Settings.getChoice("hr_zone"+zone+"_alert", "both");

        // color by zone
        var color = ZoneColors.colorForZone(zone);

        // alert when exceeding max time in zone
        if (enabled && aT != "off" && elapsed >= maxT && (Sys.getTimer() - lastAlert[zone]) >= rpt) {
            var msg = "Zone " + zone + " max " + maxT + "s";
            _alert(aT, msg, color);
            lastAlert[zone] = Sys.getTimer();
        }

        // layout: big HR, second line zone + elapsed mm:ss
        var mm = (elapsed/60).toNumber().toInt();
        var ss = (elapsed % 60).toNumber().toInt();
        var tstr = Lang.format("%02d:%02d", [mm, ss]);
        var top = hr + " bpm";
        var bottom = "Zone " + zone + " • " + tstr;

        LayoutUtils.drawTwoLineCenter(dc, top, bottom, color);

        if (Sys.getTimer() < popupUntil && popupText != null) {
            UiPopup.drawPopup(dc, popupText, popupBg, popupFg);
        }
    }

    function _alert(aT as String, message as String, color as Number) {
        if (aT == "tone" || aT == "both") Sys.playTone(Sys.TONE_ALERT);
        if (aT == "gui" || aT == "both") {
            popupText = message;
            popupBg = color;
            popupFg = Gfx.COLOR_WHITE;
            popupUntil = Sys.getTimer() + 3; // 3 seconds
            Ui.requestUpdate();
        }
    }
}

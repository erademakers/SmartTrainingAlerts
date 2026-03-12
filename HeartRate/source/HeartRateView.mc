using Toybox.System as Sys;
using Toybox.Activity as Act;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Attention;

import Settings;
import ZoneColors;

class HeartRateView extends Ui.DataField {
    var lastAlert1 = 0.0;
    var lastAlert2 = 0.0;
    var lastAlert3 = 0.0;
    var lastAlert4 = 0.0;
    var lastAlert5 = 0.0;

    var zoneTotal1 = 0.0;
    var zoneTotal2 = 0.0;
    var zoneTotal3 = 0.0;
    var zoneTotal4 = 0.0;
    var zoneTotal5 = 0.0;
    var lastSampleTime = 0.0;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;
    var fZoneTop = null;
    var fZoneBottom = null;

    function onLayout(dc as Gfx.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fZoneTop = Ui.View.findDrawableById("zoneTop") as Ui.Text;
        fZoneBottom = Ui.View.findDrawableById("zoneBottom") as Ui.Text;
    }

    function initialize() {
        Ui.DataField.initialize();
    }

    function getZone(hr) {
        var max = 190; // fallback if no profile max is available
        var p = (hr*100.0)/max;
        if (p < 60) { return 1; }
        if (p < 70) { return 2; }
        if (p < 80) { return 3; }
        if (p < 90) { return 4; }
        return 5;
    }

    function getZoneTotal(zone) {
        if (zone == 1) { return zoneTotal1; }
        if (zone == 2) { return zoneTotal2; }
        if (zone == 3) { return zoneTotal3; }
        if (zone == 4) { return zoneTotal4; }
        return zoneTotal5;
    }

    function addZoneTotal(zone, delta) {
        if (zone == 1) { zoneTotal1 += delta; return; }
        if (zone == 2) { zoneTotal2 += delta; return; }
        if (zone == 3) { zoneTotal3 += delta; return; }
        if (zone == 4) { zoneTotal4 += delta; return; }
        zoneTotal5 += delta;
    }

    function getLastAlert(zone) {
        if (zone == 1) { return lastAlert1; }
        if (zone == 2) { return lastAlert2; }
        if (zone == 3) { return lastAlert3; }
        if (zone == 4) { return lastAlert4; }
        return lastAlert5;
    }

    function setLastAlert(zone, value) {
        if (zone == 1) { lastAlert1 = value; return; }
        if (zone == 2) { lastAlert2 = value; return; }
        if (zone == 3) { lastAlert3 = value; return; }
        if (zone == 4) { lastAlert4 = value; return; }
        lastAlert5 = value;
    }

    function onUpdate(dc as Gfx.Dc) {
        var now = Sys.getTimer();
        var info = Act.getActivityInfo();
        if (info == null) {
            return;
        }
        var hr = info.currentHeartRate;
        if (hr == null) {
            return;
        }

        var zone = getZone(hr);

        // Cumulative zone timing over full ride.
        if (lastSampleTime > 0.0) {
            var delta = (now - lastSampleTime).toNumber();
            if (delta > 0) {
                addZoneTotal(zone, delta);
            }
        }
        lastSampleTime = now;

        var elapsed = getZoneTotal(zone);

        // settings
        var maxT = Settings.getNumber("hr_zone"+zone+"_max", zone<=2?18000:300);
        var rpt  = 30;
        var alertOn = Settings.getBool("hr_zone"+zone+"_alert", true);

        // color by zone
        var color = ZoneColors.colorForZone(zone);

        // alert when exceeding max time in zone
        if (alertOn && elapsed >= maxT && (now - getLastAlert(zone)) >= rpt) {
            var msg = "Zone " + zone + " max " + maxT + "s";
            _alert(msg, color);
            setLastAlert(zone, now);
        }

        // Layout: print zone and cumulative minutes for that zone.
        var top = "Zone " + zone.format("%d");
        var minutes = (elapsed / 60).format("%d");
        var bottom = minutes + " min";

        if (fZoneTop != null) {
            fZoneTop.setColor(color);
            fZoneTop.setText(top);
        }
        if (fZoneBottom != null) {
            fZoneBottom.setColor(Gfx.COLOR_WHITE);
            fZoneBottom.setText(bottom);
        }

        Ui.View.onUpdate(dc);

    }

    function _alert(message, color) {
        Attention.playTone(Attention.TONE_ALARM);
        popupText = message;
        popupBg = color;
        popupFg = Gfx.COLOR_WHITE;
        popupUntil = Sys.getTimer() + 3; // 3 seconds
        Ui.requestUpdate();
    }
}

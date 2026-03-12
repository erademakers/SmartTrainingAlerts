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
    var lastZone = 0;
    var recoveryRefAccumSec = 0.0;
    var recoveryResetArmed = false;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;
    var fZoneTop = null;
    var fZoneBottom = null;
    var zoneMaxLogged = false;

    (:debuglog)
    function debugLogImpl(msg) {
        Sys.println(msg);
    }

    function debugLog(msg) {
        if (self has :debugLogImpl) {
            debugLogImpl(msg);
        }
    }

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

    function isRecoveryReferenceZone(zone, refZoneMax) {
        return zone <= refZoneMax;
    }

    function applyHighZoneReset(delta, activeZone, enabled, refZoneMax, minRecoverySec) {
        if (!enabled) {
            recoveryRefAccumSec = 0.0;
            recoveryResetArmed = false;
            return;
        }

        if (isRecoveryReferenceZone(activeZone, refZoneMax)) {
            recoveryRefAccumSec += delta;
            if (!recoveryResetArmed && recoveryRefAccumSec >= minRecoverySec) {
                zoneTotal4 = 0.0;
                zoneTotal5 = 0.0;
                lastAlert4 = 0.0;
                lastAlert5 = 0.0;
                recoveryResetArmed = true;
                debugLog("[HeartRate] Recovery reset: Z4/Z5 cumulative timers reset after " + recoveryRefAccumSec.format("%d") + "s in ref zone <= " + refZoneMax + ".");
            }
            return;
        }

        // Left recovery zone: require a new recovery block before next reset.
        recoveryRefAccumSec = 0.0;
        recoveryResetArmed = false;
    }

    function logZoneMaxSettings() {
        var z1 = Settings.getNumber("hr_zone1_max_time", 18000);
        var z2 = Settings.getNumber("hr_zone2_max_time", 18000);
        var z3 = Settings.getNumber("hr_zone3_max_time", 300);
        var z4 = Settings.getNumber("hr_zone4_max_time", 300);
        var z5 = Settings.getNumber("hr_zone5_max_time", 300);
        debugLog("[HeartRate] Max settings: Z1=" + z1 + "s, Z2=" + z2 + "s, Z3=" + z3 + "s, Z4=" + z4 + "s, Z5=" + z5 + "s");
    }

    function logRuntimeStatus(now, hr, zone, elapsed) {
        var z1 = Settings.getNumber("hr_zone1_max_time", 18000);
        var z2 = Settings.getNumber("hr_zone2_max_time", 18000);
        var z3 = Settings.getNumber("hr_zone3_max_time", 300);
        var z4 = Settings.getNumber("hr_zone4_max_time", 300);
        var z5 = Settings.getNumber("hr_zone5_max_time", 300);
        var resetEnabled = Settings.getBool("hr_zone4_5_reset_enabled", true);
        var resetRef = Settings.getNumber("hr_zone4_5_reset_ref_zone_max", 2);
        var resetMin = Settings.getNumber("hr_zone4_5_reset_min_ref_time", 120);

        var t1s = zoneTotal1.format("%d");
        var t2s = zoneTotal2.format("%d");
        var t3s = zoneTotal3.format("%d");
        var t4s = zoneTotal4.format("%d");
        var t5s = zoneTotal5.format("%d");

        debugLog(
            "[HeartRate] HR=" + hr +
            " | Zone=" + zone.format("%d") +
            " | Cum: Z1=" + t1s + "s, Z2=" + t2s + "s, Z3=" + t3s + "s, Z4=" + t4s + "s, Z5=" + t5s + "s" +
            " | Reset(Z4/Z5): on=" + resetEnabled + ", ref<=" + resetRef + ", min=" + resetMin + "s, acc=" + recoveryRefAccumSec.format("%d") + "s" +
            " | Max: Z1=" + z1 + "s, Z2=" + z2 + "s, Z3=" + z3 + "s, Z4=" + z4 + "s, Z5=" + z5 + "s"
        );
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

        if (!zoneMaxLogged) {
            logZoneMaxSettings();
            zoneMaxLogged = true;
        }

        var zone = getZone(hr);
        var resetEnabled = Settings.getBool("hr_zone4_5_reset_enabled", true);
        var resetRefZone = Settings.getNumber("hr_zone4_5_reset_ref_zone_max", 2);
        var resetMinRecovery = Settings.getNumber("hr_zone4_5_reset_min_ref_time", 120);

        // Cumulative zone timing over full ride.
        if (lastSampleTime > 0.0 && lastZone >= 1) {
            var delta = (now - lastSampleTime).toNumber() / 1000.0;
            if (delta > 0) {
                // Attribute elapsed interval to the previously sampled zone.
                addZoneTotal(lastZone, delta);
                applyHighZoneReset(delta, lastZone, resetEnabled, resetRefZone, resetMinRecovery);
            }
        }
        lastSampleTime = now;
        lastZone = zone;

        var elapsed = getZoneTotal(zone);

        logRuntimeStatus(now, hr, zone, elapsed);

        // settings
        var maxT = Settings.getNumber("hr_zone"+zone+"_max_time", zone<=2?18000:300);
        var rpt  = 30;
        var alertOn = Settings.getBool("hr_zone"+zone+"_alert", true);

        // color by zone
        var color = ZoneColors.colorForZone(zone);

        // alert when exceeding max time in zone
        if (alertOn && elapsed >= maxT && (now - getLastAlert(zone)) >= (rpt * 1000)) {
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

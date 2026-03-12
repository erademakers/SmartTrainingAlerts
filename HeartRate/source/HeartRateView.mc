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
    var zoneInterval4 = 0.0;
    var zoneInterval5 = 0.0;
    var lastSampleTime = 0.0;
    var lastZone = 0;
    var zone4RecoveryAccum = 0.0;
    var zone5RecoveryAccum = 0.0;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;
    var fZoneTop = null;
    var fZoneBottom = null;
    var zoneMaxLogged = false;

    function debugLog(msg) {
        Sys.println(msg);
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

    function getZoneInterval(zone) {
        if (zone == 4) { return zoneInterval4; }
        if (zone == 5) { return zoneInterval5; }
        return 0.0;
    }

    function addZoneInterval(zone, delta) {
        if (zone == 4) { zoneInterval4 += delta; return; }
        if (zone == 5) { zoneInterval5 += delta; return; }
    }

    function resetZoneInterval(zone) {
        if (zone == 4) { zoneInterval4 = 0.0; return; }
        if (zone == 5) { zoneInterval5 = 0.0; return; }
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

    function isRecoveryRefZone(zone, refZone) {
        // Recovery target means "this zone or lower".
        if (refZone == 12) {
            return (zone == 1 || zone == 2);
        }
        return zone <= refZone;
    }

    function getRecoveryNeeded(zone, ratioPct, minRefTime) {
        var interval = getZoneInterval(zone);
        if (interval <= 0.0) {
            // No completed/active interval yet, so no recovery is required.
            return 0.0;
        }
        var needed = interval * (ratioPct / 100.0);
        if (needed < minRefTime) {
            needed = minRefTime;
        }
        return needed;
    }

    function getRecoveryRemaining(zone, refZone, minRefTime, ratioPct, activeZone) {
        var needed = getRecoveryNeeded(zone, ratioPct, minRefTime);
        if (needed <= 0.0) {
            return 0.0;
        }

        var accum = (zone == 4) ? zone4RecoveryAccum : zone5RecoveryAccum;

        // Outside the reference zone no recovery is currently accumulating.
        if (!isRecoveryRefZone(activeZone, refZone)) {
            return 0.0;
        }

        var remaining = needed - accum;
        return (remaining > 0.0) ? remaining : 0.0;
    }

    function applyZoneRecoveryReset(zone, delta, activeZone, refZone, minRefTime, recoveryRatioPct) {
        var inRef = isRecoveryRefZone(activeZone, refZone);

        if (zone == 4) {
            if (!inRef) {
                zone4RecoveryAccum = 0.0;
                return;
            }

            zone4RecoveryAccum += delta;
            var needed = getRecoveryNeeded(4, recoveryRatioPct, minRefTime);

            if (zoneInterval4 > 0.0 && zone4RecoveryAccum >= needed) {
                zoneTotal4 = 0.0;
                zoneInterval4 = 0.0;
                lastAlert4 = 0.0;
                zone4RecoveryAccum = 0.0;
                debugLog("[HeartRate] Recovery reset: Z4 reset after " + needed.format("%d") + "s recovery in ref zone " + refZone + ".");
            }
            return;
        }

        if (zone == 5) {
            if (!inRef) {
                zone5RecoveryAccum = 0.0;
                return;
            }

            zone5RecoveryAccum += delta;
            var needed5 = getRecoveryNeeded(5, recoveryRatioPct, minRefTime);

            if (zoneInterval5 > 0.0 && zone5RecoveryAccum >= needed5) {
                zoneTotal5 = 0.0;
                zoneInterval5 = 0.0;
                lastAlert5 = 0.0;
                zone5RecoveryAccum = 0.0;
                debugLog("[HeartRate] Recovery reset: Z5 reset after " + needed5.format("%d") + "s recovery in ref zone " + refZone + ".");
            }
        }
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
        var z4IntMax = Settings.getNumber("hr_zone4_interval_max_time", 300);
        var z5IntMax = Settings.getNumber("hr_zone5_interval_max_time", 180);
        var z4Ref = Settings.getNumber("hr_zone4_reset_ref_zone_max", 2);
        var z5Ref = Settings.getNumber("hr_zone5_reset_ref_zone_max", 2);
        var z4Min = Settings.getNumber("hr_zone4_reset_min_ref_time", 120);
        var z5Min = Settings.getNumber("hr_zone5_reset_min_ref_time", 180);
        var z4Ratio = Settings.getNumber("hr_zone4_reset_recovery_ratio_pct", 50);
        var z5Ratio = Settings.getNumber("hr_zone5_reset_recovery_ratio_pct", 100);

        var t1s = zoneTotal1.format("%d");
        var t2s = zoneTotal2.format("%d");
        var t3s = zoneTotal3.format("%d");
        var t4s = zoneTotal4.format("%d");
        var t5s = zoneTotal5.format("%d");
        var i4s = zoneInterval4.format("%d");
        var i5s = zoneInterval5.format("%d");
        var r4s = zone4RecoveryAccum.format("%d");
        var r5s = zone5RecoveryAccum.format("%d");

        debugLog(
            "[HeartRate] HR=" + hr +
            " | Zone=" + zone.format("%d") +
            " | Cum: Z1=" + t1s + "s, Z2=" + t2s + "s, Z3=" + t3s + "s, Z4=" + t4s + "s, Z5=" + t5s + "s" +
            " | Int: Z4=" + i4s + "s/" + z4IntMax + "s, Z5=" + i5s + "s/" + z5IntMax + "s" +
            " | Rec: Z4 ref=" + z4Ref + " min=" + z4Min + "s ratio=" + z4Ratio + "% acc=" + r4s + "s, Z5 ref=" + z5Ref + " min=" + z5Min + "s ratio=" + z5Ratio + "% acc=" + r5s + "s" +
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
        var z4RefZone = Settings.getNumber("hr_zone4_reset_ref_zone_max", 2);
        var z5RefZone = Settings.getNumber("hr_zone5_reset_ref_zone_max", 2);
        var z4MinRecovery = Settings.getNumber("hr_zone4_reset_min_ref_time", 120);
        var z5MinRecovery = Settings.getNumber("hr_zone5_reset_min_ref_time", 180);
        var z4RecoveryRatio = Settings.getNumber("hr_zone4_reset_recovery_ratio_pct", 50);
        var z5RecoveryRatio = Settings.getNumber("hr_zone5_reset_recovery_ratio_pct", 100);

        // Cumulative zone timing over full ride.
        if (lastSampleTime > 0.0 && lastZone >= 1) {
            var delta = (now - lastSampleTime).toNumber() / 1000.0;
            if (delta > 0) {
                // Attribute elapsed interval to the previously sampled zone.
                addZoneTotal(lastZone, delta);
                addZoneInterval(lastZone, delta);
                applyZoneRecoveryReset(4, delta, lastZone, z4RefZone, z4MinRecovery, z4RecoveryRatio);
                applyZoneRecoveryReset(5, delta, lastZone, z5RefZone, z5MinRecovery, z5RecoveryRatio);
            }
        }
        lastSampleTime = now;
        lastZone = zone;

        var elapsed = getZoneTotal(zone);

        logRuntimeStatus(now, hr, zone, elapsed);

        // settings
        var maxT = Settings.getNumber("hr_zone"+zone+"_max_time", zone<=2?18000:300);
        var intMaxT = (zone == 4)
            ? Settings.getNumber("hr_zone4_interval_max_time", 300)
            : ((zone == 5)
                ? Settings.getNumber("hr_zone5_interval_max_time", 180)
                : 9999999);
        var rpt  = 30;
        var alertOn = Settings.getBool("hr_zone"+zone+"_alert", true);

        // alert when exceeding max time in zone
        var intervalExceeded = (zone >= 4) && (getZoneInterval(zone) >= intMaxT);
        var cumulativeExceeded = elapsed >= maxT;

        // Use red only for actual limit exceedance, not immediately on entering high zones.
        var color = ZoneColors.colorForZone(zone);
        if (zone >= 4 && !intervalExceeded && !cumulativeExceeded) {
            color = Gfx.COLOR_ORANGE;
        }
        if (intervalExceeded || cumulativeExceeded) {
            color = Gfx.COLOR_RED;
        }

        if (alertOn && (intervalExceeded || cumulativeExceeded) && (now - getLastAlert(zone)) >= (rpt * 1000)) {
            var msg = "Zone " + zone + " limit";
            if (intervalExceeded && cumulativeExceeded) {
                msg = "Zone " + zone + " interval+max";
            } else if (intervalExceeded) {
                msg = "Zone " + zone + " interval " + intMaxT + "s";
            } else {
                msg = "Zone " + zone + " max " + maxT + "s";
            }
            _alert(msg, color);
            setLastAlert(zone, now);
        }

        // Layout: print zone and next-interval countdowns for Z4/Z5.
        var top = "Zone " + zone.format("%d");
        var minutes = (elapsed / 60).format("%d");
        var z4Rem = getRecoveryRemaining(4, z4RefZone, z4MinRecovery, z4RecoveryRatio, zone);
        var z5Rem = getRecoveryRemaining(5, z5RefZone, z5MinRecovery, z5RecoveryRatio, zone);
        var bottom = minutes + "m  Z4i in " + z4Rem.format("%d") + "s  Z5i in " + z5Rem.format("%d") + "s";

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

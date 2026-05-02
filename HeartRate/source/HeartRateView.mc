using Toybox.System as Sys;
using Toybox.Activity as Act;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Attention;
using Toybox.UserProfile as UserProfile;

import Settings;
import ZoneColors;

class HeartRateView extends Ui.DataField {
    var lastAlert1 = 0.0;
    var lastAlert2 = 0.0;
    var lastAlert3 = 0.0;
    var lastAlert4 = 0.0;
    var lastAlert5 = 0.0;

    var intervalAlerted4 = false;
    var intervalAlerted5 = false;
    var cumulativeAlerted1 = false;
    var cumulativeAlerted2 = false;
    var cumulativeAlerted3 = false;
    var cumulativeAlerted4 = false;
    var cumulativeAlerted5 = false;

    var zoneTotal1 = 0.0;
    var zoneTotal2 = 0.0;
    var zoneTotal3 = 0.0;
    var zoneTotal4 = 0.0;
    var zoneTotal5 = 0.0;
    var zoneInterval4 = 0.0;
    var zoneInterval5 = 0.0;
    var lastSampleTime = 0.0;
    var lastZone = 0;
    var testStartTime = -1;
    var zone4RecoveryAccum = 0.0;
    var zone5RecoveryAccum = 0.0;
    var zone4RecoveryStartInterval = 0.0;
    var zone5RecoveryStartInterval = 0.0;
    var sessionInitialized = false;

    // popup state
    var popupUntil = 0.0;
    var popupText = null;
    var popupBg = Gfx.COLOR_RED;
    var popupFg = Gfx.COLOR_WHITE;
    var fZoneTop = null;
    var fZoneBottom = null;
    var zoneMaxLogged = false;
    var lastSettingsLogLine = null;

    // Returns a synthetic HR value based on elapsed milliseconds.
    // Sequence: Z2 warmup → Z4 interval → Z2 recovery → Z4 → Z5 spike → Z1 cooldown → loops.
    // All durations are in real seconds; TEST_TIME_SCALE compresses wall-clock time.
    function getSyntheticHr(elapsedMs) {
        var seq = [
            [10,  125],   // Z2 warmup
            // [20, 160],   // Z4 interval
            // [10, 120],   // Z2 interval
            // [30, 162],   // Z4 interval
            // [90,  120],   // Z2 recovery
            // [120, 165],   // Z4 interval again
            [20, 140],   // Z3 interval
            [20, 160],   // Z4 interval
            [30,  185],   // Z5 interval
            [30, 120],   // Z2 interval
            [10, 140],   // Z3 spike
            [10, 160],   // Z4 spike
            [10,  185],   // Z5 spike
            [120, 110],   // Z1 cooldown
        ];
        var elapsed = (elapsedMs.toFloat() * TEST_TIME_SCALE) / 1000.0;
        var totalDuration = 0.0;
        for (var i = 0; i < seq.size(); i++) {
            totalDuration += seq[i][0];
        }
        // Loop the sequence
        if (totalDuration > 0.0) {
            elapsed = elapsed - (totalDuration * (elapsed / totalDuration).toNumber().toFloat());
        }
        var t = 0.0;
        for (var i = 0; i < seq.size(); i++) {
            t += seq[i][0];
            if (elapsed < t) {
                return seq[i][1];
            }
        }
        return seq[seq.size() - 1][1];
    }

    // Reads the user's max HR from the device profile (zone 5 upper bound).
    // Falls back to 190 if unavailable.
    function getMaxHr() {
        if (TEST_SYNTHETIC_HR) {
            return TEST_MAX_HR;
        }
        try {
            var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_BIKING);
            if (zones != null && zones.size() >= 5) {
                var maxHr = zones[4];
                if (maxHr != null && maxHr > 100) {
                    return maxHr;
                }
            }
        } catch(e) {}
        return 190;
    }

    function debugLog(msg) {
        if (!DEBUG_MODE) { return; }
        Sys.println(msg);
    }

    function logSettingsIfChanged() {
        var settingsLogLine = Settings.getActiveSettingsLogLine();
        if (settingsLogLine == lastSettingsLogLine) { return; }

        lastSettingsLogLine = settingsLogLine;
        debugLog("[HeartRate] " + settingsLogLine);
    }

    function onLayout(dc as Gfx.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fZoneTop = Ui.View.findDrawableById("zoneTop") as Ui.Text;
        fZoneBottom = Ui.View.findDrawableById("zoneBottom") as Ui.Text;
    }

    function initialize() {
        Ui.DataField.initialize();
    }

    function getNumberSetting(newId, oldId, dflt) {
        var value = Settings.getNumber(newId, null);
        if (value != null) {
            return value;
        }
        return Settings.getNumber(oldId, dflt);
    }

    function getNumberSetting3(newId, oldId, legacyId, dflt) {
        var value = Settings.getNumber(newId, null);
        if (value != null) {
            return value;
        }

        value = Settings.getNumber(oldId, null);
        if (value != null) {
            return value;
        }

        return Settings.getNumber(legacyId, dflt);
    }

    function resetSessionState() {
        lastAlert1 = 0.0;
        lastAlert2 = 0.0;
        lastAlert3 = 0.0;
        lastAlert4 = 0.0;
        lastAlert5 = 0.0;

        intervalAlerted4 = false;
        intervalAlerted5 = false;
        cumulativeAlerted1 = false;
        cumulativeAlerted2 = false;
        cumulativeAlerted3 = false;
        cumulativeAlerted4 = false;
        cumulativeAlerted5 = false;

        zoneTotal1 = 0.0;
        zoneTotal2 = 0.0;
        zoneTotal3 = 0.0;
        zoneTotal4 = 0.0;
        zoneTotal5 = 0.0;

        zoneInterval4 = 0.0;
        zoneInterval5 = 0.0;
        if (TEST_CURRENT_INTERVAL_OVERRIDE) {
            zoneInterval4 = TEST_CURRENT_Z4_INTERVAL;
            zoneInterval5 = TEST_CURRENT_Z5_INTERVAL;
        }

        lastSampleTime = 0.0;
        lastZone = 0;
        zone4RecoveryAccum = 0.0;
        zone5RecoveryAccum = 0.0;
        zone4RecoveryStartInterval = 0.0;
        zone5RecoveryStartInterval = 0.0;
        zoneMaxLogged = false;
    }

    function getZone(hr) {
        var max = getMaxHr();
        var p = (hr * 100.0) / max;
        if (p < 60) { return 1; }
        if (p < 70) { return 2; }
        if (p < 80) { return 3; }
        if (p < 90) { return 4; }
        return 5;
    }

    function getZoneBottomValue(zone, hr) {
        return zone.format("%d");
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

    function getIntervalAlerted(zone) {
        if (zone == 4) { return intervalAlerted4; }
        if (zone == 5) { return intervalAlerted5; }
        return false;
    }

    function setIntervalAlerted(zone, value) {
        if (zone == 4) { intervalAlerted4 = value; return; }
        if (zone == 5) { intervalAlerted5 = value; return; }
    }

    function getCumulativeAlerted(zone) {
        if (zone == 1) { return cumulativeAlerted1; }
        if (zone == 2) { return cumulativeAlerted2; }
        if (zone == 3) { return cumulativeAlerted3; }
        if (zone == 4) { return cumulativeAlerted4; }
        if (zone == 5) { return cumulativeAlerted5; }
        return false;
    }

    function setCumulativeAlerted(zone, value) {
        if (zone == 1) { cumulativeAlerted1 = value; return; }
        if (zone == 2) { cumulativeAlerted2 = value; return; }
        if (zone == 3) { cumulativeAlerted3 = value; return; }
        if (zone == 4) { cumulativeAlerted4 = value; return; }
        if (zone == 5) { cumulativeAlerted5 = value; return; }
    }

    function isRecoveryRefZone(zone, refZone) {
        // Recovery target means "this zone or lower".
        if (refZone == 12) {
            return (zone == 1 || zone == 2);
        }
        return zone <= refZone;
    }

    function getRecoveryNeeded(zone, minRefTime) {
        var interval = getZoneInterval(zone);
        if (interval <= 0.0) {
            // No completed/active interval yet, so no recovery is required.
            return 0.0;
        }
        // Recovery time is the maximum of interval duration and minimum recovery time.
        if (interval >= minRefTime) {
            return interval;
        }
        return minRefTime;
    }

    function getRecoveryRemaining(zone, refZone, minRefTime, activeZone) {
        var needed = getRecoveryNeeded(zone, minRefTime);
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

    function getBarRatio(zone, activeZone, intervalMax, refZone, minRefTime) {
        if (intervalMax <= 0.0) { return 0.0; }
        var interval = getZoneInterval(zone);
        if (interval <= 0.0) { return 0.0; }
        var ratio = interval / intervalMax;
        if (ratio > 1.0) { ratio = 1.0; }
        return ratio;
    }

    function getIntervalLogText(zone, activeZone, intervalMax, refZone, minRefTime) {
        var interval = getZoneInterval(zone);
        return interval.format("%.1f") + "s/" + intervalMax + "s";
    }

    function drawRecoveryBar(dc as Gfx.Dc, x, y, width, height, ratio, fillColor, intervalMax, tickInterval, labelOnRight) as Void {
        if (ratio < 0.0) { ratio = 0.0; }
        if (ratio > 1.0) { ratio = 1.0; }

        var fillHeight = (height * ratio).toNumber();
        if (fillHeight < 0) {
            fillHeight = 0;
        }

        dc.setColor(0x303030, 0x303030);
        dc.fillRectangle(x, y, width, height);

        if (fillHeight > 0) {
            var fillY = y + (height - fillHeight);
            dc.setColor(fillColor, fillColor);
            dc.fillRectangle(x, fillY, width, fillHeight);
        }

        // Ensure at least 1 tick visible: cap effectiveTick to half intervalMax
        var effectiveTick = tickInterval;
        if (effectiveTick <= 0) { effectiveTick = 30; }
        if (intervalMax > 0 && effectiveTick > intervalMax / 2) {
            effectiveTick = (intervalMax / 2).toNumber();
            if (effectiveTick < 1) { effectiveTick = 1; }
        }
        if (effectiveTick > 0 && intervalMax > 0) {
            var tickFont = Gfx.FONT_XTINY;
            var fontHeight = dc.getFontHeight(tickFont);
            var t = effectiveTick;
            while (t < intervalMax) {
                var tickY = y + height - ((height * t.toFloat() / intervalMax.toFloat()).toNumber());
                if (tickY > y && tickY < y + height) {
                    dc.setColor(0x606060, 0x606060);
                    dc.fillRectangle(x + 1, tickY, width - 2, 1);
                    var labelY = tickY - (fontHeight / 2);
                    if (labelY >= y && labelY + fontHeight <= y + height) {
                        var label = t.format("%d") + "s";
                        dc.setColor(0x505050, Gfx.COLOR_TRANSPARENT);
                        if (labelOnRight) {
                            dc.drawText(x + width + 2, labelY, tickFont, label, Gfx.TEXT_JUSTIFY_LEFT);
                        } else {
                            dc.drawText(x - 2, labelY, tickFont, label, Gfx.TEXT_JUSTIFY_RIGHT);
                        }
                    }
                }
                t += effectiveTick;
            }
        }

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, width, height);
    }

    function drawRecoveryBars(dc as Gfx.Dc, activeZone, z4IntMax, z5IntMax, z4RefZone, z5RefZone, z4MinRecovery, z5MinRecovery) as Void {
        var sideMargin = 14;
        var barWidth = 18;
        var tickInterval = Settings.getNumber("hr_bar_tick_interval", 30);
        var width = dc.getWidth();
        var height = dc.getHeight();

        var inwardInset = 2;
        var maxBarHeight = height - 70;
        var barHeight = (maxBarHeight * 0.9).toNumber();
        if (barHeight < 40) {
            barHeight = 40;
        }

        var topY = ((height - barHeight) / 2).toNumber() + (height * 0.17).toNumber();
        if (topY < 0) {
            topY = 0;
        }
        if (topY + barHeight > height) {
            topY = height - barHeight;
        }

        var leftX = sideMargin + inwardInset;
        var rightX = width - sideMargin - barWidth - inwardInset;

        var z4Ratio = getBarRatio(4, activeZone, z4IntMax, z4RefZone, z4MinRecovery);
        var z5Ratio = getBarRatio(5, activeZone, z5IntMax, z5RefZone, z5MinRecovery);

        var labelFont = Gfx.FONT_TINY;
        var labelY = topY - dc.getFontHeight(labelFont) - 2;
        if (labelY < 0) {
            labelY = 0;
        }
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(leftX + (barWidth / 2), labelY, labelFont, "Z4", Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightX + (barWidth / 2), labelY, labelFont, "Z5", Gfx.TEXT_JUSTIFY_CENTER);

        drawRecoveryBar(dc, leftX, topY, barWidth, barHeight, z4Ratio, Gfx.COLOR_ORANGE, z4IntMax, tickInterval, true);
        drawRecoveryBar(dc, rightX, topY, barWidth, barHeight, z5Ratio, Gfx.COLOR_RED, z5IntMax, tickInterval, false);
    }

    function renderNoData(dc as Gfx.Dc) as Void {
        var z4IntMax = getNumberSetting("hr_zone4_interval_max_time", "hr_zone4_interval_max_seconds", 120);
        var z5IntMax = getNumberSetting("hr_zone5_interval_max_time", "hr_zone5_interval_max_seconds", 30);
        var z4RefZone = getNumberSetting3("hr_zone4_interval_recovery_ref_zone_max", "hr_zone4_recovery_ref_zone_max", "hr_zone4_reset_ref_zone_max", 3);
        var z5RefZone = getNumberSetting3("hr_zone5_interval_recovery_ref_zone_max", "hr_zone5_recovery_ref_zone_max", "hr_zone5_reset_ref_zone_max", 3);
        var z4MinRecovery = getNumberSetting3("hr_zone4_interval_recovery_min_time", "hr_zone4_interval_recovery_min_seconds", "hr_zone4_reset_min_ref_time", 120);
        var z5MinRecovery = getNumberSetting3("hr_zone5_interval_recovery_min_time", "hr_zone5_interval_recovery_min_seconds", "hr_zone5_reset_min_ref_time", 60);

        if (fZoneTop != null) {
            fZoneTop.setColor(Gfx.COLOR_WHITE);
            fZoneTop.setText("ZONE");
        }
        if (fZoneBottom != null) {
            fZoneBottom.setColor(Gfx.COLOR_DK_GRAY);
            fZoneBottom.setText("--");
        }

        Ui.View.onUpdate(dc);
        drawRecoveryBars(dc, 0, z4IntMax, z5IntMax, z4RefZone, z5RefZone, z4MinRecovery, z5MinRecovery);
    }

    function applyZoneRecoveryReset(zone, delta, activeZone, refZone, minRefTime, intervalMax) {
        var inRef = isRecoveryRefZone(activeZone, refZone);

        if (zone == 4) {
            if (!inRef) {
                zone4RecoveryAccum = 0.0;
                zone4RecoveryStartInterval = 0.0;
                return;
            }

            if (zoneInterval4 <= 0.0) {
                return;
            }

            zone4RecoveryAccum += delta;

            if (minRefTime > 0.0 && intervalMax > 0.0) {
                var rate = intervalMax.toFloat() / minRefTime.toFloat();
                zoneInterval4 -= delta * rate;
                if (zoneInterval4 < 0.0) { zoneInterval4 = 0.0; }
            }

            if (zoneInterval4 <= 0.0) {
                zoneTotal4 = 0.0;
                zoneInterval4 = 0.0;
                lastAlert4 = 0.0;
                zone4RecoveryAccum = 0.0;
                zone4RecoveryStartInterval = 0.0;
                intervalAlerted4 = false;
                cumulativeAlerted4 = false;
                debugLog("[HeartRate] Recovery reset: Z4 fully recovered in ref zone " + refZone + ".");
            }
            return;
        }

        if (zone == 5) {
            if (!inRef) {
                zone5RecoveryAccum = 0.0;
                zone5RecoveryStartInterval = 0.0;
                return;
            }

            if (zoneInterval5 <= 0.0) {
                return;
            }

            zone5RecoveryAccum += delta;

            if (minRefTime > 0.0 && intervalMax > 0.0) {
                var rate5 = intervalMax.toFloat() / minRefTime.toFloat();
                zoneInterval5 -= delta * rate5;
                if (zoneInterval5 < 0.0) { zoneInterval5 = 0.0; }
            }

            if (zoneInterval5 <= 0.0) {
                zoneTotal5 = 0.0;
                zoneInterval5 = 0.0;
                lastAlert5 = 0.0;
                zone5RecoveryAccum = 0.0;
                zone5RecoveryStartInterval = 0.0;
                intervalAlerted5 = false;
                cumulativeAlerted5 = false;
                debugLog("[HeartRate] Recovery reset: Z5 fully recovered in ref zone " + refZone + ".");
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

    function logRuntimeStatus(now, hr, zone, elapsed, intervalExceeded, cumulativeExceeded) {
        var z1 = Settings.getNumber("hr_zone1_max_time", 18000);
        var z2 = Settings.getNumber("hr_zone2_max_time", 18000);
        var z3 = Settings.getNumber("hr_zone3_max_time", 300);
        var z4 = Settings.getNumber("hr_zone4_max_time", 300);
        var z5 = Settings.getNumber("hr_zone5_max_time", 300);
        var z4IntMax = getNumberSetting("hr_zone4_interval_max_time", "hr_zone4_interval_max_seconds", 300);
        var z5IntMax = getNumberSetting("hr_zone5_interval_max_time", "hr_zone5_interval_max_seconds", 180);
        var z4Ref = getNumberSetting3("hr_zone4_interval_recovery_ref_zone_max", "hr_zone4_recovery_ref_zone_max", "hr_zone4_reset_ref_zone_max", 2);
        var z5Ref = getNumberSetting3("hr_zone5_interval_recovery_ref_zone_max", "hr_zone5_recovery_ref_zone_max", "hr_zone5_reset_ref_zone_max", 2);
        var z4Min = getNumberSetting3("hr_zone4_interval_recovery_min_time", "hr_zone4_interval_recovery_min_seconds", "hr_zone4_reset_min_ref_time", 120);
        var z5Min = getNumberSetting3("hr_zone5_interval_recovery_min_time", "hr_zone5_interval_recovery_min_seconds", "hr_zone5_reset_min_ref_time", 180);

        var t1s = zoneTotal1.format("%d");
        var t2s = zoneTotal2.format("%d");
        var t3s = zoneTotal3.format("%d");
        var t4s = zoneTotal4.format("%d");
        var t5s = zoneTotal5.format("%d");
        var i4s = getIntervalLogText(4, zone, z4IntMax, z4Ref, z4Min);
        var i5s = getIntervalLogText(5, zone, z5IntMax, z5Ref, z5Min);
        var z4Needed = (zoneInterval4 > 0.0) ? getRecoveryNeeded(4, z4Min) : z4Min;
        var z5Needed = (zoneInterval5 > 0.0) ? getRecoveryNeeded(5, z5Min) : z5Min;
        var z4Rate = z4IntMax.toFloat() / z4Min.toFloat();
        var z5Rate = z5IntMax.toFloat() / z5Min.toFloat();

        debugLog(
            "[HeartRate] HR=" + hr +
            " | Zone=" + zone.format("%d") +
            " | Cum: Z1=" + t1s + "s, Z2=" + t2s + "s, Z3=" + t3s + "s, Z4=" + t4s + "s, Z5=" + t5s + "s" +
            " | Int: Z4=" + zoneInterval4.format("%.1f") + "s/" + z4IntMax + "s, Z5=" + zoneInterval5.format("%.1f") + "s/" + z5IntMax + "s" +
            " | Bar: Z4=" + i4s + ", Z5=" + i5s +
            " | Rate: Z4=" + z4Rate.format("%.2f") + "(" + z4IntMax + "/" + z4Min + "), Z5=" + z5Rate.format("%.2f") + "(" + z5IntMax + "/" + z5Min + ")" +
            " | Exceeded: int=" + intervalExceeded + ", max=" + cumulativeExceeded +
            " | Max: Z1=" + z1 + "s, Z2=" + z2 + "s, Z3=" + z3 + "s, Z4=" + z4 + "s, Z5=" + z5 + "s"
        );
    }

    function onUpdate(dc as Gfx.Dc) {
        var now = Sys.getTimer();

        var hr;
        if (TEST_SYNTHETIC_HR) {
            if (testStartTime < 0) {
                testStartTime = now;
            }
            hr = getSyntheticHr((now - testStartTime).toFloat());
        } else {
            var info = Act.getActivityInfo();
            if (info == null) {
                renderNoData(dc);
                return;
            }
            hr = info.currentHeartRate;
            if (hr == null || hr <= 0) {
                renderNoData(dc);
                return;
            }
        }

        if (!sessionInitialized) {
            resetSessionState();
            sessionInitialized = true;
        }

        logSettingsIfChanged();

        if (!zoneMaxLogged) {
            logZoneMaxSettings();
            zoneMaxLogged = true;
        }

        var zone = getZone(hr);
        var z4RefZone = getNumberSetting3("hr_zone4_interval_recovery_ref_zone_max", "hr_zone4_recovery_ref_zone_max", "hr_zone4_reset_ref_zone_max", 2);
        var z5RefZone = getNumberSetting3("hr_zone5_interval_recovery_ref_zone_max", "hr_zone5_recovery_ref_zone_max", "hr_zone5_reset_ref_zone_max", 2);
        var z4MinRecovery = getNumberSetting3("hr_zone4_interval_recovery_min_time", "hr_zone4_interval_recovery_min_seconds", "hr_zone4_reset_min_ref_time", 120);
        var z5MinRecovery = getNumberSetting3("hr_zone5_interval_recovery_min_time", "hr_zone5_interval_recovery_min_seconds", "hr_zone5_reset_min_ref_time", 180);
        var z4IntMax = getNumberSetting("hr_zone4_interval_max_time", "hr_zone4_interval_max_seconds", 300);
        var z5IntMax = getNumberSetting("hr_zone5_interval_max_time", "hr_zone5_interval_max_seconds", 180);

        // Cumulative zone timing over full ride.
        if (lastSampleTime > 0.0 && lastZone >= 1) {
            var delta = (now - lastSampleTime).toNumber() / 1000.0;
            if (TEST_SYNTHETIC_HR) {
                delta = delta * TEST_TIME_SCALE;
            }
            if (delta > 0) {
                // Attribute elapsed interval to the previously sampled zone.
                addZoneTotal(lastZone, delta);
                addZoneInterval(lastZone, delta);
                  applyZoneRecoveryReset(4, delta, lastZone, z4RefZone, z4MinRecovery, z4IntMax);
                  applyZoneRecoveryReset(5, delta, lastZone, z5RefZone, z5MinRecovery, z5IntMax);
            }
        }
        lastSampleTime = now;
        lastZone = zone;

        var elapsed = getZoneTotal(zone);

        // settings
        var maxT = Settings.getNumber("hr_zone"+zone+"_max_time", zone<=2?18000:300);
        var intMaxT = (zone == 4) ? z4IntMax : ((zone == 5) ? z5IntMax : 9999999);
        var alertOn = Settings.getBool("hr_zone"+zone+"_alert", true);

        // alert when exceeding max time in zone
        var intervalExceeded = (zone >= 4) && (getZoneInterval(zone) >= intMaxT);
        var cumulativeExceeded = elapsed >= maxT;

        // Use red only for actual limit exceedance, not immediately on entering high zones.
        var color = ZoneColors.colorForZone(zone);
        if (zone >= 4 && !intervalExceeded && !cumulativeExceeded) {
            color = Gfx.COLOR_GREEN;
        }
        if (intervalExceeded && !cumulativeExceeded) {
            color = Gfx.COLOR_ORANGE;
        }
        if (cumulativeExceeded) {
            color = Gfx.COLOR_RED;
        }

        logRuntimeStatus(now, hr, zone, elapsed, intervalExceeded, cumulativeExceeded);

        // Single-shot alerts per overschrijding
        if (alertOn) {
            if (intervalExceeded && !getIntervalAlerted(zone)) {
                var msg = "Zone " + zone + " interval " + intMaxT + "s";
                _alert(msg, color);
                setIntervalAlerted(zone, true);
            } else if (!intervalExceeded && getIntervalAlerted(zone)) {
                setIntervalAlerted(zone, false);
            }

            if (cumulativeExceeded && !getCumulativeAlerted(zone)) {
                var msg = "Zone " + zone + " max " + maxT + "s";
                _alert(msg, color);
                setCumulativeAlerted(zone, true);
            } else if (!cumulativeExceeded && getCumulativeAlerted(zone)) {
                setCumulativeAlerted(zone, false);
            }
        }

        // Layout: top is static in XML; bottom shows current zone value.
        var bottom = getZoneBottomValue(zone, hr);
        var bottomColor = cumulativeExceeded ? Gfx.COLOR_RED : Gfx.COLOR_GREEN;

        if (fZoneTop != null) {
            fZoneTop.setColor(Gfx.COLOR_WHITE);
            fZoneTop.setText("ZONE");
        }
        if (fZoneBottom != null) {
            fZoneBottom.setColor(bottomColor);
            fZoneBottom.setText(bottom);
        }

        Ui.View.onUpdate(dc);
        drawRecoveryBars(dc, zone, z4IntMax, z5IntMax, z4RefZone, z5RefZone, z4MinRecovery, z5MinRecovery);

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

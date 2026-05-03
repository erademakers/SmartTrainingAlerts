import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Attention;

import Settings;

class PowerBalanceView extends WatchUi.DataField {
    var bikePower = null;
    var alertActive = false;
    var fBalanceTop = null;
    var lastSettingsLogLine = null;
    var testStartTime = -1;

    // Returns synthetic [leftBalance, rightBalance] based on elapsed milliseconds.
    // Sequence cycles through balanced, slight imbalance, clear imbalance, and back.
    // TEST_TIME_SCALE compresses wall-clock time (e.g. 10.0 = 10x faster).
    function getSyntheticBalance(elapsedMs) {
        // [duration_seconds, leftBalance, rightBalance]
        var seq = [
            [10, 50, 50],   // perfect balance — green
            [10, 49, 51],   // minimal bias — green
            [10, 47, 53],   // imbalance — red (below default threshold 48)
            [10, 45, 55],   // worse imbalance — red
            [10, 50, 50],   // recover to good — green
            [5,  48, 52],   // right on threshold — green
            [10, 46, 54],   // imbalance again — red
        ];
        var elapsed = (elapsedMs.toFloat() * TEST_TIME_SCALE) / 1000.0;
        var totalDuration = 0.0;
        for (var i = 0; i < seq.size(); i++) {
            totalDuration += seq[i][0];
        }
        if (totalDuration > 0.0) {
            elapsed = elapsed - (totalDuration * (elapsed / totalDuration).toNumber().toFloat());
        }
        var t = 0.0;
        for (var i = 0; i < seq.size(); i++) {
            t += seq[i][0];
            if (elapsed < t) {
                return [seq[i][1], seq[i][2]];
            }
        }
        return [seq[seq.size() - 1][1], seq[seq.size() - 1][2]];
    }

    function debugLog(msg) {
        if (!DEBUG_MODE) { return; }
        System.println(msg);
    }

    function logSettingsIfChanged() {
        var settingsLogLine = Settings.getActiveSettingsLogLine();
        if (settingsLogLine == lastSettingsLogLine) { return; }
        lastSettingsLogLine = settingsLogLine;
        debugLog("[PowerBalance] " + settingsLogLine);
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fBalanceTop = View.findDrawableById("balanceTop") as Text;
    }

    function initialize() {
        DataField.initialize();
        try { bikePower = new AntPlus.BikePower(null); } catch(e) { bikePower = null; }
    }

    function onUpdate(dc as Graphics.Dc) {
        logSettingsIfChanged();

        var threshold = Settings.getNumber("spb_balance_min", 48);
        var alertEnabled = Settings.getBool("spb_alert", true);

        var top = "--/--";
        var color = Graphics.COLOR_DK_GRAY;

        var hasBalance = false;
        var leftBalance = 0;
        var rightBalance = 0;
        var weakSide = 0;

        if (TEST_BALANCE_OVERRIDE) {
            var now = System.getTimer();
            if (testStartTime < 0) { testStartTime = now; }
            var synth = getSyntheticBalance((now - testStartTime).toFloat());
            leftBalance = synth[0];
            rightBalance = synth[1];
            if (leftBalance < 0) { leftBalance = 0; }
            if (leftBalance > 100) { leftBalance = 100; }
            if (rightBalance < 0) { rightBalance = 0; }
            if (rightBalance > 100) { rightBalance = 100; }
            weakSide = (leftBalance < rightBalance) ? leftBalance : rightBalance;
            hasBalance = true;
        } else {
            var balanceData = null;
            try {
                if (bikePower != null) {
                    balanceData = bikePower.getPedalPowerBalance();
                }
            } catch(e) {
                balanceData = null;
            }

            if (balanceData != null && balanceData.pedalPowerPercent != null && balanceData.rightPedalIndicator != null) {
                var pedalPowerPercent = balanceData.pedalPowerPercent;
                var rightPedalIndicator = balanceData.rightPedalIndicator;
                leftBalance = rightPedalIndicator ? (100 - pedalPowerPercent) : pedalPowerPercent;
                rightBalance = rightPedalIndicator ? pedalPowerPercent : (100 - pedalPowerPercent);
                weakSide = (leftBalance < rightBalance) ? leftBalance : rightBalance;
                hasBalance = true;
            }
        }

        if (hasBalance) {
            top = leftBalance.format("%d") + "/" + rightBalance.format("%d");
            color = (weakSide < threshold) ? Graphics.COLOR_RED : Graphics.COLOR_GREEN;

            if (weakSide < threshold) {
                if (!alertActive && alertEnabled) {
                    Attention.playTone(Attention.TONE_ALARM);
                }
                alertActive = true;
            } else {
                if (alertActive && alertEnabled) {
                    Attention.playTone(Attention.TONE_RESET);
                }
                alertActive = false;
            }
        } else {
            alertActive = false;
        }

        if (fBalanceTop != null) {
            fBalanceTop.setColor(color);
            fBalanceTop.setText(top);
        }

        debugLog("[PowerBalance] balance=" + top + " weak=" + weakSide + " threshold=" + threshold + " alert=" + alertActive);

        View.onUpdate(dc);
    }
}

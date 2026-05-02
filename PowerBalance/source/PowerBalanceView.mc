import Toybox.AntPlus;
import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.Attention;

import Settings;

class PowerBalanceView extends WatchUi.DataField {
    // Debug & test flags
    const DEBUG_MODE = false;  // Set to true for simulator only, false for production device
    // Simulator test override: set to true to force a fixed L/R balance value.
    const TEST_BALANCE_OVERRIDE = (DEBUG_MODE);
    const TEST_LEFT_BALANCE = 48;
    const TEST_RIGHT_BALANCE = 52;

    var bikePower = null;
    var alertActive = false;
    var fBalanceTop = null;

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fBalanceTop = View.findDrawableById("balanceTop") as Text;
    }

    function initialize() {
        DataField.initialize();
        bikePower = new AntPlus.BikePower(null);
    }

    function onUpdate(dc as Graphics.Dc) {
        var threshold = Settings.getNumber("spb_balance_min", 48);
        var alertEnabled = Settings.getBool("spb_alert", true);

        var top = "--/--";
        var color = Graphics.COLOR_DK_GRAY;

        var hasBalance = false;
        var leftBalance = 0;
        var rightBalance = 0;
        var weakSide = 0;

        if (TEST_BALANCE_OVERRIDE) {
            leftBalance = TEST_LEFT_BALANCE;
            rightBalance = TEST_RIGHT_BALANCE;
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

        View.onUpdate(dc);
    }
}

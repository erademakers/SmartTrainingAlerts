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
    var fBalanceBottom = null;

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        fBalanceTop = View.findDrawableById("balanceTop") as Text;
        fBalanceBottom = View.findDrawableById("balanceBottom") as Text;
    }

    function initialize() {
        DataField.initialize();
        bikePower = new AntPlus.BikePower(null);
    }

    function onUpdate(dc as Graphics.Dc) {
        var threshold = Settings.getNumber("spb_balance_min", 48);
        var alertEnabled = Settings.getBool("spb_alert", true);

        var top = "--/--";
        var bottom = "No balance data";
        var color = Graphics.COLOR_DK_GRAY;

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
            var leftBalance = rightPedalIndicator ? (100 - pedalPowerPercent) : pedalPowerPercent;
            var rightBalance = rightPedalIndicator ? pedalPowerPercent : (100 - pedalPowerPercent);
            var weakSide = (leftBalance < rightBalance) ? leftBalance : rightBalance;

            top = leftBalance.format("%d") + "/" + rightBalance.format("%d");
            bottom = "Min " + weakSide.format("%d") + "% • Thr " + threshold + "%";
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

        if (fBalanceBottom != null) {
            fBalanceBottom.setColor(Graphics.COLOR_WHITE);
            fBalanceBottom.setText(bottom);
        }

        View.onUpdate(dc);
    }
}
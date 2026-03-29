using Toybox.Application as App;
using Toybox.WatchUi as Ui;
import Settings;

class PowerBalanceApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
        Settings.syncSideloadDefaults();
    }

    function getInitialView() {
        return [ new PowerBalanceView() ];
    }

    function onSettingsChanged() {
        Ui.requestUpdate();
    }
}
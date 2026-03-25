using Toybox.Application as App;
using Toybox.WatchUi   as Ui;
import Settings;

class PowerCadenceApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
        Settings.syncSideloadDefaults();
    }
    function getInitialView() {
        // Lever je DataField-view
        return [ new PowerCadenceView() ];
    }
    // Reageert op settings-updates via Connect IQ
    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}


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
    // Optioneel (alleen als je iets wil doen bij settings-updates via telefoon)
    function onSettingsChanged() { }
}


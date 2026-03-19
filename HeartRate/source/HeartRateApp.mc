using Toybox.Application as App;
using Toybox.WatchUi   as Ui;
import Settings;

class HeartRateApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
        Settings.syncSideloadDefaults();
    }
    function getInitialView() { return [ new HeartRateView() ]; }
}
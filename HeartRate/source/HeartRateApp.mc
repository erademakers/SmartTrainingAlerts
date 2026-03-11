using Toybox.Application as App;
using Toybox.WatchUi   as Ui;

class HeartRateApp extends App.AppBase {
    function initialize() { App.AppBase.initialize(); }
    function getInitialView() { return [ new HeartRateView() ]; }
}
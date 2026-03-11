using Toybox.Application as App;

module Settings {
    function getNumber(id, dflt) {
        try { var v = App.getApp().getProperty(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
    function getChoice(id, dflt) {
        try { var v = App.getApp().getProperty(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
    function getBool(id, dflt) {
        try { var v = App.getApp().getProperty(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
}

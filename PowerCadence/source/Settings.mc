using Toybox.Application as App;
using Toybox.Application.Properties as AppProperties;

module Settings {
    function getNumber(id, dflt) {
        try { var v = AppProperties.getValue(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
    function getChoice(id, dflt) {
        try { var v = AppProperties.getValue(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
    function getBool(id, dflt) {
        try { var v = AppProperties.getValue(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }
}

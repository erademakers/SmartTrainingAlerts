using Toybox.Application as App;
using Toybox.Application.Properties as AppProperties;

module Settings {
    const PC_SETTINGS_SCHEMA_VERSION = 1;
    const PC_DEFAULT_POWER = 120;
    const PC_DEFAULT_CADENCE = 90;
    const PC_DEFAULT_DURATION = 5;
    const PC_DEFAULT_ALERT = true;

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

    function syncSideloadDefaults() {
        var storedVersion = getNumber("__pc_settings_schema_version", 0);
        if (storedVersion == PC_SETTINGS_SCHEMA_VERSION) { return; }

        AppProperties.setValue("pc_power", PC_DEFAULT_POWER);
        AppProperties.setValue("pc_cadence", PC_DEFAULT_CADENCE);
        AppProperties.setValue("pc_duration", PC_DEFAULT_DURATION);
        AppProperties.setValue("pc_alert", PC_DEFAULT_ALERT);
        AppProperties.setValue("__pc_settings_schema_version", PC_SETTINGS_SCHEMA_VERSION);
    }
}

using Toybox.Application.Properties as AppProperties;

module Settings {
    const SPB_SETTINGS_SCHEMA_VERSION = 1;
    const SPB_DEFAULT_BALANCE_MIN = 48;
    const SPB_DEFAULT_ALERT = true;

    function getActiveSettingsLogLine() {
        return "settings"
            + " balance_min=" + getNumber("spb_balance_min", SPB_DEFAULT_BALANCE_MIN)
            + " alert=" + getBool("spb_alert", SPB_DEFAULT_ALERT)
            + " schema=" + getNumber("__spb_settings_schema_version", 0);
    }

    function getNumber(id, dflt) {
        try { var v = AppProperties.getValue(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }

    function getBool(id, dflt) {
        try { var v = AppProperties.getValue(id); return (v == null) ? dflt : v; }
        catch(e) { return dflt; }
    }

    function syncSideloadDefaults() {
        var storedVersion = getNumber("__spb_settings_schema_version", 0);
        if (storedVersion == SPB_SETTINGS_SCHEMA_VERSION) { return; }

        AppProperties.setValue("spb_balance_min", SPB_DEFAULT_BALANCE_MIN);
        AppProperties.setValue("spb_alert", SPB_DEFAULT_ALERT);
        AppProperties.setValue("__spb_settings_schema_version", SPB_SETTINGS_SCHEMA_VERSION);
    }
}
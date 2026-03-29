using Toybox.Application as App;
using Toybox.Application.Properties as AppProperties;

module Settings {
    const HR_SETTINGS_SCHEMA_VERSION = 1;
    const HR_DEFAULT_ZONE4_INTERVAL_MAX_TIME = 300;
    const HR_DEFAULT_ZONE5_INTERVAL_MAX_TIME = 30;
    const HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_REF_ZONE_MAX = 2;
    const HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_REF_ZONE_MAX = 2;
    const HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_MIN_TIME = 30;
    const HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_MIN_TIME = 10;
    const HR_DEFAULT_ZONE1_MAX_TIME = 36000;
    const HR_DEFAULT_ZONE1_ALERT = false;
    const HR_DEFAULT_ZONE2_MAX_TIME = 36000;
    const HR_DEFAULT_ZONE2_ALERT = false;
    const HR_DEFAULT_ZONE3_MAX_TIME = 36000;
    const HR_DEFAULT_ZONE3_ALERT = false;
    const HR_DEFAULT_ZONE4_MAX_TIME = 1200;
    const HR_DEFAULT_ZONE4_ALERT = true;
    const HR_DEFAULT_ZONE5_MAX_TIME = 180;
    const HR_DEFAULT_ZONE5_ALERT = true;

    function getActiveSettingsLogLine() {
        return "settings"
            + " z4_int_max=" + getNumber("hr_zone4_interval_max_time", HR_DEFAULT_ZONE4_INTERVAL_MAX_TIME)
            + " z5_int_max=" + getNumber("hr_zone5_interval_max_time", HR_DEFAULT_ZONE5_INTERVAL_MAX_TIME)
            + " z4_ref_zone=" + getNumber("hr_zone4_interval_recovery_ref_zone_max", HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_REF_ZONE_MAX)
            + " z5_ref_zone=" + getNumber("hr_zone5_interval_recovery_ref_zone_max", HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_REF_ZONE_MAX)
            + " z4_min_recovery=" + getNumber("hr_zone4_interval_recovery_min_time", HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_MIN_TIME)
            + " z5_min_recovery=" + getNumber("hr_zone5_interval_recovery_min_time", HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_MIN_TIME)
            + " z1_max=" + getNumber("hr_zone1_max_time", HR_DEFAULT_ZONE1_MAX_TIME)
            + " z1_alert=" + getBool("hr_zone1_alert", HR_DEFAULT_ZONE1_ALERT)
            + " z2_max=" + getNumber("hr_zone2_max_time", HR_DEFAULT_ZONE2_MAX_TIME)
            + " z2_alert=" + getBool("hr_zone2_alert", HR_DEFAULT_ZONE2_ALERT)
            + " z3_max=" + getNumber("hr_zone3_max_time", HR_DEFAULT_ZONE3_MAX_TIME)
            + " z3_alert=" + getBool("hr_zone3_alert", HR_DEFAULT_ZONE3_ALERT)
            + " z4_max=" + getNumber("hr_zone4_max_time", HR_DEFAULT_ZONE4_MAX_TIME)
            + " z4_alert=" + getBool("hr_zone4_alert", HR_DEFAULT_ZONE4_ALERT)
            + " z5_max=" + getNumber("hr_zone5_max_time", HR_DEFAULT_ZONE5_MAX_TIME)
            + " z5_alert=" + getBool("hr_zone5_alert", HR_DEFAULT_ZONE5_ALERT)
            + " schema=" + getNumber("__hr_settings_schema_version", 0);
    }

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
        var storedVersion = getNumber("__hr_settings_schema_version", 0);
        if (storedVersion == HR_SETTINGS_SCHEMA_VERSION) { return; }

        AppProperties.setValue("hr_zone4_interval_max_time", HR_DEFAULT_ZONE4_INTERVAL_MAX_TIME);
        AppProperties.setValue("hr_zone5_interval_max_time", HR_DEFAULT_ZONE5_INTERVAL_MAX_TIME);
        AppProperties.setValue("hr_zone4_interval_recovery_ref_zone_max", HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_REF_ZONE_MAX);
        AppProperties.setValue("hr_zone5_interval_recovery_ref_zone_max", HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_REF_ZONE_MAX);
        AppProperties.setValue("hr_zone4_interval_recovery_min_time", HR_DEFAULT_ZONE4_INTERVAL_RECOVERY_MIN_TIME);
        AppProperties.setValue("hr_zone5_interval_recovery_min_time", HR_DEFAULT_ZONE5_INTERVAL_RECOVERY_MIN_TIME);
        AppProperties.setValue("hr_zone1_max_time", HR_DEFAULT_ZONE1_MAX_TIME);
        AppProperties.setValue("hr_zone1_alert", HR_DEFAULT_ZONE1_ALERT);
        AppProperties.setValue("hr_zone2_max_time", HR_DEFAULT_ZONE2_MAX_TIME);
        AppProperties.setValue("hr_zone2_alert", HR_DEFAULT_ZONE2_ALERT);
        AppProperties.setValue("hr_zone3_max_time", HR_DEFAULT_ZONE3_MAX_TIME);
        AppProperties.setValue("hr_zone3_alert", HR_DEFAULT_ZONE3_ALERT);
        AppProperties.setValue("hr_zone4_max_time", HR_DEFAULT_ZONE4_MAX_TIME);
        AppProperties.setValue("hr_zone4_alert", HR_DEFAULT_ZONE4_ALERT);
        AppProperties.setValue("hr_zone5_max_time", HR_DEFAULT_ZONE5_MAX_TIME);
        AppProperties.setValue("hr_zone5_alert", HR_DEFAULT_ZONE5_ALERT);
        AppProperties.setValue("__hr_settings_schema_version", HR_SETTINGS_SCHEMA_VERSION);
    }
}

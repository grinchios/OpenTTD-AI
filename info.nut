class Mungo extends AIInfo
{
    function GetAuthor()        { return "Grinchios"; }
    function GetName()          { return "Mungo"; }
    function GetDescription()   { return "Attempt at a competitive AI"; }
    function GetVersion()       { return 6; }
    function GetDate()          { return "2024-09-04"; }
    function CreateInstance()   { return "Mungo"; }
    function GetShortName()     { return "MUNG"; }
    function MinVersionToLoad() { return 3; }

    // TODO tweak and add settings
    function GetSettings()
    {
        AddSetting({
            name = "min_town_size",
            description = "The minimal size of towns to work on",
            min_value = 500,
            max_value = 2000,
            easy_value = 750,
            medium_value = 750,
            hard_value = 750,
            custom_value = 500,
            flags = 0
        });

        AddSetting({
            name = "enable_road_town_booster",
            description = "Enable the road town booster strategy",
            default_value = 1,
            easy_value = 0,
            medium_value = 0,
            hard_value = 0,
            custom_value = 0,
            flags = AICONFIG_BOOLEAN + CONFIG_INGAME
        });
    }
}

RegisterAI(Mungo());
class Mungo extends AIInfo 
{
  function GetAuthor()        { return "Grinchios"; }
  function GetName()          { return "Mungo"; }
  function GetDescription()   { return "Testing with aircrafts"; }
  function GetVersion()       { return 4; }
  function GetDate()          { return "2021-05-03"; }
  function CreateInstance()   { return "Mungo"; }
  function GetShortName()     { return "MUNG"; }
  function MinVersionToLoad() { return 3; }
  
  function GetSettings() {
  AddSetting({name = "min_town_size",
              description = "The minimal size of towns to work on",
              min_value = 100,
              max_value = 1000,
              easy_value = 500,
              medium_value = 750,
              hard_value = 1000,
              custom_value = 500,
              flags = 0});

  AddSetting({name = "town_count",
              description = "The amount of towns to build in",
              min_value = 2,
              max_value = 1000,
              easy_value = 100,
              medium_value = 50,
              hard_value = 20,
              custom_value = 100,
              flags = 0});
  }
}

RegisterAI(Mungo());
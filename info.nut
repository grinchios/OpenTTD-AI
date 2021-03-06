class Mungo extends AIInfo 
{
  function GetAuthor()        { return "Grinchios"; }
  function GetName()          { return "Mungo"; }
  function GetDescription()   { return "Attempt at a competitive AI"; }
  function GetVersion()       { return 6; }
  function GetDate()          { return "2021-05-03"; }
  function CreateInstance()   { return "Mungo"; }
  function GetShortName()     { return "MUNG"; }
  function MinVersionToLoad() { return 3; }
  
  // TODO tweak and add settings
  function GetSettings() {
  AddSetting({name = "min_town_size",
              description = "The minimal size of towns to work on",
              min_value = 500,
              max_value = 2000,
              easy_value = 750,
              medium_value = 750,
              hard_value = 750,
              custom_value = 500,
              flags = 0});
  }
}

RegisterAI(Mungo());
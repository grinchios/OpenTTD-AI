class Grinchios extends AIInfo 
{
  function GetAuthor()      { return "Callum Pritchard"; }
  function GetName()        { return "Grinchios"; }
  function GetDescription() { return "Testing with aircrafts"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2018-12-14"; }
  function CreateInstance() { return "Grinchios"; }
  function GetShortName()   { return "CHIO"; }
  
  function GetSettings() {
  AddSetting({name = "min_town_size",
              description = "The minimal size of towns to work on",
              min_value = 100,
              max_value = 1000,
              easy_value = 500,
              medium_value = 400,
              hard_value = 300,
              custom_value = 500,
              flags = 0});
  }
}

RegisterAI(Grinchios());
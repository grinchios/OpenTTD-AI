class Mungo extends AIInfo 
{
  function GetAuthor()      { return "Grinchios"; }
  function GetName()        { return "Mungo"; }
  function GetDescription() { return "Testing with aircrafts"; }
  function GetVersion()     { return 2; }
  function GetDate()        { return "2021-05-03"; }
  function CreateInstance() { return "Mungo"; }
  function GetShortName()   { return "MUNG"; }
  
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

RegisterAI(Mungo());
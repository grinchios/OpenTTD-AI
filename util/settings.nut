function LogAllSettings()
{
    Info("Minimum Town Size: " + GetSetting("min_town_size"));
}

function HandleAutoRenew()
{
    if (AIGameSettings.GetValue("difficulty.vehicle_breakdowns") != 0)
	{
		Warning("Enabling AutoRenew");
		AICompany.SetAutoRenewStatus(true);
	}
	else
	{
		Warning("Enabling AutoRenew");
		AICompany.SetAutoRenewStatus(false);
	}

	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(100000);
}

function SelectStrategies()
{
	local managers = [];
	if (GetSetting("enable_road_town_booster") == 1) { managers.append(RoadTownBoosterManager()) }
	return managers;
}
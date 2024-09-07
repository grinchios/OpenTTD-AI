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
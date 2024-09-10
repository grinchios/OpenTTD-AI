require("headers.nut");

class Mungo extends AIController
{
	name = null;
	sleepingTime = null
	vehicleToSell = {};
	vehicleToUpgrade = {};
	ticker = null;

	managers = []

	constructor() {
		this.sleepingTime = 500;  // Time to sleep between iterations
		this.ticker = 0;  // We need our local ticker, as GetTick() will skip ticks
  	}
}

function Mungo::Init()
{
	NameCompany();
	HandleAutoRenew();

	this.managers = SelectStrategies();

	// this.managers[0].UpgradeVehicles();  // Auto replace
}

function Mungo::NewRoutes()
{
	/*
	* TODO: New function in each manager to get estimated profit of a new route compared to the cost of building it
	* this will create a profitabilty score for each route and then we can select the best one
	*/
	for (local i = 0; i < this.managers.len(); i++)
	{
		if (this.managers[i].CreateNewRoute()) { return true }
	}

	if (this.ticker == 0)
	{
		// TODO: improve this to be more fault tolerant
		/* The AI failed to build a first route and is deemed a failure */
		AICompany.SetName("Failed " + AICompany.GetName(AICompany.COMPANY_SELF));
		Error("Failed to build first route, now giving up building. Repaying loan. Have a nice day!");
		AICompany.SetLoanAmount(0);
		return false;
	}
	else { return true }
}

function Mungo::HouseKeeping()
{
	/*
	* This function contains fast housekeeping tasks that need to be done every iteration
	*/
    this.HandleEvents();
    // RepayLoan();
	// StatuesInTowns();
}

function Mungo::ManageRoutes()
{
	local counterUpgraded = 0;
	local counterSold = 0;
	for (local i = 0; i < this.managers.len(); i++)
	{
		this.managers[i].SellNegativeVehicles();
		counterUpgraded += this.managers[i].ManageRoutes();
		counterSold += this.managers[i].RemoveNullStations();
	}
	if (counterUpgraded > 0) { Warning("Upgraded " + counterUpgraded + " routes"); }
	if (counterSold > 0) { Warning("Sold " + counterSold + " routes") };
}

function Mungo::Start()
{
	this.Init();

	// Let's go on for ever
	for(local i = 0; true; i++)
	{
		Warning("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");
		Warning("Starting iteration: " + i)
		Warning("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=");

		// TODO: try and except this to catch errors
		if (!this.NewRoutes())
		{
			Error(AIError.GetLastErrorString());
			return;
		}

		this.HouseKeeping();
		this.ManageRoutes();

		// Make sure we do not create infinite loops
		Sleep(this.sleepingTime);
		this.ticker += this.sleepingTime;
	}
}

function Mungo::Save()
{
	// dictionary of data to save in the savefile
	local table = {
		vehicleToSell = this.vehicleToSell,
		vehicleToUpgrade = this.vehicleToUpgrade,
		ticker = this.ticker
	};
	return table;
}

function Mungo::Load(version, data)
{
	if (data.rawin("vehicleToSell")) { this.vehicleToSell = data.rawget("vehicleToSell"); }
	if (data.rawin("vehicleToUpgrade")) { this.vehicleToUpgrade = data.rawget("vehicleToUpgrade"); }
	if (data.rawin("ticker")) { this.ticker = data.rawget("ticker"); }
}

// TODO: Move this to a new file specifically for event handling
function Mungo::HandleEvents()
{
    while (AIEventController.IsEventWaiting())
	{
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType())
		{
			case AIEvent.AI_ET_VEHICLE_CRASHED:
			{
				local ec = AIEventVehicleCrashed.Convert(e);
				local v = ec.GetVehicleID();
				local crash_reason = ec.GetCrashReason();
				Warning("We have a crashed vehicle (" + v + ")");

				if (crash_reason == AIEventVehicleCrashed.CRASH_AIRCRAFT_NO_AIRPORT)
				{
					Info("Replacing crashed plane");
					for (local i = 0; i < this.managers[ManagerTypes.PLANE_PAX].vehicle_array.len(); i++)
					{
						if (this.managers[ManagerTypes.PLANE_PAX].vehicle_array == v)
						{
							this.managers[ManagerTypes.PLANE_PAX].vehicle_array.remove(i);
							this.managers[ManagerTypes.PLANE_PAX].BuildAircraft(
								this.managers[ManagerTypes.PLANE_PAX].route_1.GetValue(v),
								this.managers[ManagerTypes.PLANE_PAX].route_2.GetValue(v)
							);
							break;
						}
					}
				}
				else if (crash_reason == AIEventVehicleCrashed.CRASH_PLANE_LANDING)
				{
					Info("Replacing crashed plane");
					for (local i = 0; i < this.managers[ManagerTypes.PLANE_PAX].vehicle_array.len(); i++)
					{
						if (this.managers[ManagerTypes.PLANE_PAX].vehicle_array == v)
						{
							this.managers[ManagerTypes.PLANE_PAX].vehicle_array.remove(i);
							this.managers[ManagerTypes.PLANE_PAX].BuildAircraft(
								this.managers[ManagerTypes.PLANE_PAX].route_1.GetValue(v),
								this.managers[ManagerTypes.PLANE_PAX].route_2.GetValue(v)
							);
							break;
						}
					}
				}
				else if (crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING)
				{
					Info("Avoiding new level crossing");
					// TODO: Avoid new level crossing
					break;
				}
				else { Info("Replacing vehicle") }
			} break;

			default:
				break;
		}
	}
}
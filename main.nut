require("headers.nut");

class Mungo extends AIController {
	name = null;
	sleepingtime = null
	vehicle_to_depot = {};
	vehicle_to_upgrade = {};
	delay_build_airport_route = 1000;
	ticker = null;

	helpers = []

	constructor() {
		this.sleepingtime = 500;

		/* We need our local ticker, as GetTick() will skip ticks */
		this.ticker = 0;
  	} 
}

function Mungo::Init() {
	NameCompany();

	// Setup Helpers
	// this.helpers.append(AirHelper());
	this.helpers.append(BusHelper());

	// Auto-renew
	if (AIGameSettings.GetValue("difficulty.vehicle_breakdowns")!= 0) {
		Warning("Enabling AutoRenew");
		AICompany.SetAutoRenewStatus(true);
	} else {
		Warning("Enabling AutoRenew");
		AICompany.SetAutoRenewStatus(false);
	}

	AICompany.SetAutoRenewMonths(0);
	AICompany.SetAutoRenewMoney(100000);

	// Auto replace
	// this.helpers[0].UpgradeVehicles();

	return true;
}

function Mungo::NewRoutes() {
	// Initial moneymaker is passenger air transport
	for (local i = 0; i < this.helpers.len(); i++) {
		if (this.helpers[i].CreateNewRoute()) {
			return true;
		}
	}
	
	if (this.ticker == 0) {
		/* The AI failed to build a first route and is deemed a failure */
		AICompany.SetName("Failed " + AICompany.GetName(AICompany.COMPANY_SELF));
		Error("Failed to build first route, now giving up building. Repaying loan. Have a nice day!");
		AICompany.SetLoanAmount(0);
		return false;
	} else {
		return true;
	}
}

function Mungo::HouseKeeping() {
    Mungo.HandleEvents();
    RepayLoan();
	StatuesInTowns();
}

function Mungo::ManageRoutes() {
	local counter_upgraded = 0
	local counter_sold = 0
	for (local i = 0; i < this.helpers.len(); i++) {
		this.helpers[i].SellNegativeVehicles();
		counter_upgraded += this.helpers[i].ManageRoutes();
		counter_sold += this.helpers[i].RemoveNullStations();
	}
	if (counter_upgraded>0) {Warning("Upgraded " + counter_upgraded + " routes");}
	if (counter_sold>0) {Warning("Sold " + counter_sold + " routes")};
}

function Mungo::Start() {
	if (!this.Init()) {return;}

	// Let's go on for ever
	for(local i = 0; true; i++) {
		Warning("Starting iteration: " + i)
		
		// if ((this.ticker % this.delay_build_airport_route == 0) && HasMoney(this.helpers[0].NewRouteCost(GetBestAirport()))) {
			if (!this.NewRoutes()) {
				// while (1==1) {
					Error(AIError.GetLastErrorString());
				// }
				return;
			}
		// }
		
		this.HouseKeeping();
		this.ManageRoutes();

		// Make sure we do not create infinite loops
		Sleep(this.sleepingtime);
		this.ticker += this.sleepingtime;
	}
}

function Mungo::Save() {
	// dictionary of data to save in the savefile
	local table =  {vehicle_to_depot  = this.vehicle_to_depot,
					vehicle_to_upgrade = this.vehicle_to_upgrade,
					ticker            = this.ticker};
	return table;
}

function Mungo::Load(version, data) {
	if (data.rawin("vehicle_to_depot"))
		this.vehicle_to_depot = data.rawget("vehicle_to_depot");

	if (data.rawin("vehicle_to_upgrade"))
		this.vehicle_to_upgrade = data.rawget("vehicle_to_upgrade");

	if (data.rawin("ticker"))
		this.ticker = data.rawget("ticker");
}

function Mungo::HandleEvents() {
    while (AIEventController.IsEventWaiting()) {
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType()) {
			case AIEvent.AI_ET_VEHICLE_CRASHED: {
				local ec = AIEventVehicleCrashed.Convert(e);
				local v = ec.GetVehicleID();
				local crash_reason = ec.GetCrashReason();
				Warning("We have a crashed vehicle (" + v + ")");
				
				if (crash_reason == AIEventVehicleCrashed.CRASH_AIRCRAFT_NO_AIRPORT) {
					Info("Replacing crashed plane");
					for (local i = 0; i < this.helpers[0].vehicle_array.len(); i++) {
						if (this.helpers[0].vehicle_array == v) {
							this.helpers[0].vehicle_array.remove(i);
							this.helpers[0].BuildAircraft(this.helpers[0].route_1.GetValue(v), this.helpers[0].route_2.GetValue(v));
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_PLANE_LANDING) {
					Info("Replacing crashed plane");
					for (local i = 0; i < this.helpers[0].vehicle_array.len(); i++) {
						if (this.helpers[0].vehicle_array == v) {
							this.helpers[0].vehicle_array.remove(i);
							this.helpers[0].BuildAircraft(this.helpers[0].route_1.GetValue(v), this.helpers[0].route_2.GetValue(v));
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING) {
					Info("Creating new level crossing");
					break;
				} else {
					Info("Replacing vehicle")
				}
			} break;

			default:
				break;
		}
	}
}
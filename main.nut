require("headers.nut");

class Mungo extends AIController {
	name = null;
	sleepingtime = null
	vehicle_to_depot = {};
	delay_build_airport_route = 1000;
	ticker = null;
	air_helper = null;

	helpers = []

	constructor() {
		this.sleepingtime = 500;

		/* We need our local ticker, as GetTick() will skip ticks */
		this.ticker = 0;

		this.helpers.append(air_helper)
  	} 
}

// TODO setup buses if air transport disabled or too early
function Mungo::MoneyMaker() {
	// Initial moneymaker is passenger air transport
	local ret = this.air_helper.CreateNewRoute();
	if (!ret && this.ticker != 0) {
		/* No more route found, delay even more before trying to find an other */
		this.delay_build_airport_route = 10000;
		return true;
	} else if (!ret && this.ticker == 0) {
		/* The AI failed to build a first airport and is deemed a failure */
		AICompany.SetName("Failed " + AICompany.GetName(AICompany.COMPANY_SELF));
		Error("Failed to build first airport route, now giving up building. Repaying loan. Have a nice day!");
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

// TODO create strategies, infrastructure costs, limits on vehicles
// TODO create vehicle groups based on what cargo they are carrying
// TODO autorenew
// TODO change reserve money based on monthly outgoings
function Mungo::Start() {
	if (!StartUp()) {return;}
	this.air_helper = AirHelper();

	// Let's go on for ever
	for(local i = 0; true; i++) {
		Warning("Starting iteration: " + i)
		
		if ((this.ticker % this.delay_build_airport_route == 0 || this.ticker == 0) && HasMoney(100000)) {
			if (!this.MoneyMaker()) {
				return
			}
		}
		
		// TODO remove negative vehicles
		// TODO add vehicles to stations when cargo is waiting
		this.HouseKeeping();

		// Manage the routes once in a while
		this.air_helper.SellNegativeVehicles();
		this.air_helper.UpgradeRoutes();

		// Make sure we do not create infinite loops
		Sleep(this.sleepingtime);
		this.ticker += this.sleepingtime;
	}
}

function Mungo::Save() {
	// dictionary of data to save in the savefile
	local table =  {vehicle_to_depot  = this.vehicle_to_depot,
					ticker            = this.ticker};
	return table;
}

function Mungo::Load(version, data) {
	if (data.rawin("vehicle_to_depot"))
		this.vehicle_to_depot = data.rawget("vehicle_to_depot");

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
					for (local i = 0; i < this.air_helper.vehicle_array.len(); i++) {
						if (this.air_helper.vehicle_array == v) {
							this.air_helper.vehicle_array.remove(i);
							this.air_helper.BuildAircraft(this.air_helper.route_1.GetValue(v), this.air_helper.route_2.GetValue(v));
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_PLANE_LANDING) {
					Info("Replacing crashed plane");
					for (local i = 0; i < this.air_helper.vehicle_array.len(); i++) {
						if (this.air_helper.vehicle_array == v) {
							this.air_helper.vehicle_array.remove(i);
							this.air_helper.BuildAircraft(this.air_helper.route_1.GetValue(v), this.air_helper.route_2.GetValue(v));
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING) {
					Info("Creating new level crossing");
					break;
				}
			} break;

			default:
				break;
		}
	}
}
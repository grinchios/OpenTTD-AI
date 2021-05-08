class Helper {
    route_1 = null;
	route_2 = null;
    vehicle_array = [];
    VEHICLETYPE = null;

    passenger_cargo_id = -1;
	mail_cargo_id = -1
};

function Helper::FindSuitableLocation(){}
function Helper::BuildNewVehicle(){}
function Helper::UpgradeRoutes(){}
function Helper::SellAirports(){}

function Helper::Init() {
    // Starting function for all helpers
    // This avoids storing as much in savefiles at the cost
    // of extra CPU cycles on setup which is fine as it's only once
    local list = AIVehicleList();
    list.Valuate(AIVehicle.GetVehicleType);
    list.KeepValue(this.VEHICLETYPE);
    local vehicle_name;
    this.route_1 = AIList();
    this.route_2 = AIList();

    for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
        this.vehicle_array.append(i.VehicleID);
        
        vehicle_name = split_message(AIVehicle.GetName(i.VehicleID), " ");
        this.route_1.append(vehicle_name[0]);
        this.route_2.append(vehicle_name[1]);
    }

    // Get the id of cargo
    local list = AICargoList();
    for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
        if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS)) {
            this.passenger_cargo_id = i;
        } else if (AICargo.HasCargoClass(i, AICargo.CC_MAIL)) {
            this.mail_cargo_id = i;
        }
    }
}

function Helper::SetDepotName(station_id, limit, depot_tile) {
    local location = AIBaseStation.GetLocation(station_id);
    while (!AIBaseStation.SetName(station_id, location + " " + limit + " " + depot_tile)) {
        Mungo.Sleep(1);
    }
    return true;
}

function Helper::SetVehicleName(vehicle_id, name) {
    while (!AIVehicle.SetName(vehicle_id, name)) {
        Mungo.Sleep(1);
    }
    return true;
}

function Helper::SellNegativeVehicles() {
    local list = AIVehicleList();
	list.Valuate(AIVehicle.GetVehicleType);
	list.KeepValue(this.VEHICLETYPE);

	list.Valuate(AIVehicle.GetAge);

	// Give the plane at least 2 years to make a difference
	list.KeepAboveValue(365 * 2);
	list.Valuate(AIVehicle.GetProfitLastYear);

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local profit = list.GetValue(i);

		// Profit last year and this year bad? Let's sell the vehicle
		if (profit < 10000 && AIVehicle.GetProfitThisYear(i) < 10000) {
			// Send the vehicle to depot if we didn't do so yet
			if (!Mungo.vehicle_to_depot.rawin(i) || Mungo.vehicle_to_depot.rawget(i) != true) {
				Info("Sending " + i + " to depot as profit is: " + profit + " / " + AIVehicle.GetProfitThisYear(i));
				AIVehicle.SendVehicleToDepot(i);
				Mungo.vehicle_to_depot.rawset(i, true);
			}
		}
		// Try to sell it over and over till it really is in the depot
		// Is the vehicle with ID i in the depot?
		if (Mungo.vehicle_to_depot.rawin(i) && Mungo.vehicle_to_depot.rawget(i) == true) {
			if (AIVehicle.SellVehicle(i)) {
				Warning("Selling " + i + " as it is finally in a depot.");
		
				// Check if we are the last one serving those airports; else sell the airports
				local list2 = AIVehicleList_Station(AIStation.GetStationID(this.route_1.GetValue(i)));
				if (list2.Count() == 0) this.SellRoute(i);
				Mungo.vehicle_to_depot.rawdelete(i);
			}
		}
	}
}

// TODO Improve this
function Helper::SellRoute(i) {
    if (this.VEHICLETYPE == AIVehicle.VT_AIR) {
        this.AirHelper.SellAirports(i);
    }
}
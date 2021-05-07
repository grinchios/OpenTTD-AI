require("headers.nut");

class Mungo extends AIController {
	name = null;
	towns_used = null;
	route_1 = null;
	route_2 = null;
	sleepingtime = null
	distance_of_route = {};
	vehicle_to_depot = {};
	vehicle_array = [];
	delay_build_airport_route = 1000;
	passenger_cargo_id = -1;
	ticker = null;
	airHelper = null;

	constructor() {
		this.towns_used = AIList();
		this.route_1 = AIList();
		this.route_2 = AIList();
		this.sleepingtime = 500;

		// Get the id of passengers
		local list = AICargoList();
		for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
			if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS)) {
				this.passenger_cargo_id = i;
				break;
			}
		}

		/* We need our local ticker, as GetTick() will skip ticks */
		this.ticker = 0;
  	} 
}

function Mungo::BuildAirportRoute() {
	// Gets the biggest airport type avaliable
	local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);

	Info("Trying to build an airport route");

	local tile_1 = this.airHelper.FindSuitableLocation(airport_type, 0);

	if (tile_1 < 0) return -1;

	local tile_2 = this.airHelper.FindSuitableLocation(airport_type, tile_1);

	if (tile_2 < 0) {
		this.towns_used.RemoveValue(tile_1);
		return -2;
	}
	
	// Get enough money to work with
	GetMoney(150000);

	// Build the airports for real
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the first airport at tile " + tile_1 + ".");
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -3;
	}

	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		Error("Although the testing told us we could build 2 airports, it still failed on the second airport at tile " + tile_2 + ".");
		AIAirport.RemoveAirport(tile_1);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -4;
	}

	local ret = this.AirHelper.BuildNewVehicle(tile_1, tile_2);
	if (ret < 0) {
		AIAirport.RemoveAirport(tile_1);
		AIAirport.RemoveAirport(tile_2);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return ret;
	} else {
		local location = AIStation.GetStationID(tile_1);
		airHelper.SetDepotName(location, 0, 0);
		
		location = AIStation.GetStationID(tile_2);
		airHelper.SetDepotName(location, 0, 0);
		Info("Done building a route");
		return ret;
	}
}

function Mungo::ManageAirRoutes() {
	local list = AIVehicleList();
	list.Valuate(AIVehicle.GetAge);

	// Give the plane at least 2 years to make a difference
	list.KeepAboveValue(365 * 2);
	list.Valuate(AIVehicle.GetProfitLastYear);

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local profit = list.GetValue(i);

		// Profit last year and this year bad? Let's sell the vehicle
		if (profit < 10000 && AIVehicle.GetProfitThisYear(i) < 10000) {
			// Send the vehicle to depot if we didn't do so yet
			if (!vehicle_to_depot.rawin(i) || vehicle_to_depot.rawget(i) != true) {
				Info("Sending " + i + " to depot as profit is: " + profit + " / " + AIVehicle.GetProfitThisYear(i));
				AIVehicle.SendVehicleToDepot(i);
				vehicle_to_depot.rawset(i, true);
			}
		}
		// Try to sell it over and over till it really is in the depot

		// Is the vehicle with ID i in the depot?
		if (vehicle_to_depot.rawin(i) && vehicle_to_depot.rawget(i) == true) {
			if (AIVehicle.SellVehicle(i)) {
				Info("Selling " + i + " as it is finally in a depot.");
		
				// Check if we are the last one serving those airports; else sell the airports
				local list2 = AIVehicleList_Station(AIStation.GetStationID(this.route_1.GetValue(i)));
				if (list2.Count() == 0) this.SellAirports(i);
				vehicle_to_depot.rawdelete(i);
			}
		}
	}

	// Don't try to add planes when we are short on cash
	if (!HasMoney(50000)) return;

	list = AIStationList(AIStation.STATION_AIRPORT);
	list.Valuate(AIStation.GetCargoWaiting, this.passenger_cargo_id);
	list.KeepAboveValue(250);

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local list2 = AIVehicleList_Station(i);
		// No vehicles going to this station, abort and sell
		if (list2.Count() == 0) {
			this.SellAirports(i);
			continue;
		};

		// Find the first vehicle that is going to this station
		local v = list2.Begin();

		list2.Valuate(AIVehicle.GetAge);

		// Do not build a new vehicle if we bought a new one in the last DISTANCE days
		if (list2.Count() != 0) continue;

		Info("Station " + i + " (" + AIStation.GetLocation(i) + ") has too much cargo, adding a new vehicle for the route.");

		// Make sure we have enough money
		GetMoney(50000);

		return this.AirHelper.BuildNewVehicle(this.route_1.GetValue(v), this.route_2.GetValue(v));
	}
}

function Mungo::CreateNewAirRoutes() {
  // Make new random routes to keep expanding if money exists

  // gets length of both route lists
  local route_len = this.route_1.Count()
  
  // gets the ID of a random route
  local route_1_rand = this.vehicle_array[AIBase.RandRangeItem(0, route_len)]
  local route_2_rand = this.vehicle_array[AIBase.RandRangeItem(0, route_len)]

  // gets the actual route info
  local tile_1 = this.route_1.GetValue(route_1_rand)
  local tile_2 = this.route_2.GetValue(route_2_rand)

  local ret = this.AirHelper.BuildNewVehicle(tile_1, tile_2);

  if (ret == 0) {
    Info("Mungo bought a new aircraft");
  } else {
    Info("Error occured whilst buying new aircraft");
  }
}

function Mungo::SellAirports(i) {
	// Sells the airports from route index i
	// Removes towns from towns_used list too

	// Remove the airports
	Info("Removing airports as nobody serves them anymore.");
	AIAirport.RemoveAirport(this.route_1.GetValue(i));
	AIAirport.RemoveAirport(this.route_2.GetValue(i));

	// Free the entries
	this.towns_used.RemoveValue(this.route_1.GetValue(i));
	this.towns_used.RemoveValue(this.route_2.GetValue(i));

	// Remove the route
	this.route_1.RemoveItem(i);
	this.route_2.RemoveItem(i);
}

function Mungo::Start() {
	if (this.passenger_cargo_id == -1) {
		Error("Mungo could not find the passenger cargo");
		return;
	}

	NameCompany();

	this.airHelper = AirHelper();

	// Let's go on for ever
	for(local i = 0; true; i++) {
		Warning("Starting iteration: " + i)
		
		/* Once in a while, with enough money, try to build something */
		if ((this.ticker % this.delay_build_airport_route == 0 || this.ticker == 0) && HasMoney(100000)) {
			local ret = this.BuildAirportRoute();
			if (ret == -1 && this.ticker != 0) {
				/* No more route found, delay even more before trying to find an other */
				this.delay_build_airport_route = 10000;
			} else if (ret < 0 && this.ticker == 0) {
				/* The AI failed to build a first airport and is deemed a failure */
				AICompany.SetName("Failed " + AICompany.GetName(AICompany.COMPANY_SELF));
				Error("Failed to build first airport route, now giving up building. Repaying loan. Have a nice day!");
				AICompany.SetLoanAmount(0);
				return;
			}
		}

		HouseKeeping();

		// Manage the routes once in a while
		if (this.ticker % 2000 == 0)
			this.ManageAirRoutes();

		// Create new airplane if money permits and ticker is running
		if (this.ticker % 2000 == 0 && BankBalance() > 175000 && this.towns_used.Count() > 2)
			this.CreateNewAirRoutes();

		// Make sure we do not create infinite loops
		Sleep(this.sleepingtime);
		this.ticker += this.sleepingtime;
	}
}

function Mungo::Save() {
	local towns_used_items_save = [];
	local towns_used_values_save = [];
	for (local i = towns_used.Begin(); towns_used.HasNext(); i = towns_used.Next()) {
		towns_used_items_save.append(i);
		towns_used_values_save.append(towns_used.GetValue(i));
	}

	local route_1_items_save = [];
	local route_1_values_save = [];
	for (local i = route_1.Begin(); route_1.HasNext(); i = route_1.Next()) {
		route_1_items_save.append(i);
		route_1_values_save.append(route_1.GetValue(i));
	}

	local route_2_items_save = [];
	local route_2_values_save = [];
	for (local i = route_2.Begin(); route_2.HasNext(); i = route_2.Next()) {
		route_2_items_save.append(i);
		route_2_values_save.append(route_2.GetValue(i));
	}

	// dictionary of data to save in the savefile
	local table =  {towns_used_items  = towns_used_items_save, 
					towns_used_values = towns_used_values_save,
					route_1_items     = route_1_items_save,
					route_1_values    = route_1_values_save,
					route_2_items     = route_2_items_save,
					route_2_values    = route_2_values_save,
					distance_of_route = this.distance_of_route,
					vehicle_to_depot  = this.vehicle_to_depot,
					vehicle_array     = this.vehicle_array,
					ticker            = this.ticker};
	return table;
}

function Mungo::Load(version, data) {
	local towns_used_items_save = [];
	local towns_used_values_save = [];
	local route_1_items_save = [];
	local route_1_values_save = [];
	local route_2_items_save = [];
	local route_2_values_save = [];

	// if the data exists in the save file then load it into the variable
	if (data.rawin("towns_used_items"))
		towns_used_items_save = data.rawget("towns_used_items");

	if (data.rawin("towns_used_values"))
		towns_used_values_save = data.rawget("towns_used_values");

	if (data.rawin("route_1_items"))
		route_1_items_save = data.rawget("route_1_items");

	if (data.rawin("route_1_values"))
		route_1_values_save = data.rawget("route_1_values");

	if (data.rawin("route_2_items"))
		route_2_items_save = data.rawget("route_2_items");

	if (data.rawin("route_2_values"))
		route_2_values_save = data.rawget("route_2_values");

	if (data.rawin("distance_of_route"))
		this.distance_of_route = data.rawget("distance_of_route");

	if (data.rawin("vehicle_to_depot"))
		this.vehicle_to_depot = data.rawget("vehicle_to_depot");

	if (data.rawin("vehicle_array"))
		this.vehicle_array = data.rawget("vehicle_array");

	if (data.rawin("ticker"))
		this.ticker = data.rawget("ticker");

	for (local i = 0; i < towns_used_items_save.len(); i++) {
		this.towns_used.AddItem(towns_used_items_save[i], towns_used_values_save[i])
	}

	for (local i = 0; i < route_1_items_save.len(); i++) {
		this.route_1.AddItem(route_1_items_save[i], route_1_values_save[i])
	}

	for (local i = 0; i < route_2_items_save.len(); i++) {
		this.route_2.AddItem(route_2_items_save[i], route_2_values_save[i])
	}
}
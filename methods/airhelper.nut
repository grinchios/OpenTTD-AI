class AirHelper extends Helper {
	towns_used = null;

	constructor() {
		this.VEHICLETYPE = AIVehicle.VT_AIR;
		this.towns_used = TownsUsedForStationType(AIStation.STATION_AIRPORT);

		this.Init();
	}
}

// TODO bigger or smaller airports
function AirHelper::CreateNewRoute() {
	// Gets the biggest airport type avaliable
	local airport_type = (AIAirport.IsValidAirportType(AIAirport.AT_LARGE) ? AIAirport.AT_LARGE : AIAirport.AT_SMALL);

	Info("Trying to build an airport route");

	local tile_1 = this.FindSuitableLocation(airport_type, 0);

	if (tile_1 < 0) return -1;

	local tile_2 = this.FindSuitableLocation(airport_type, tile_1);

	if (tile_2 < 0) {
		this.towns_used.RemoveValue(tile_1);
		return -2;
	}
	
	// Get enough money to work with
	GetMoney(150000);

	// Build the airports for real
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		Error("Failed on the first airport at tile " + tile_1 + ".");
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -3;
	}

	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		Error("Failed on the second airport at tile " + tile_2 + ".");
		AIAirport.RemoveAirport(tile_1);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return -4;
	}

	if (this.BuildNewVehicle(tile_1, tile_2, this.passenger_cargo_id)<0) {
		Error("Removing airports due to error");
		AIAirport.RemoveAirport(tile_1);
		AIAirport.RemoveAirport(tile_2);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return false;
	} else {
		local location = AIStation.GetStationID(tile_1);
		this.SetDepotName(location, 0, 0);
		
		location = AIStation.GetStationID(tile_2);
		this.SetDepotName(location, 0, 0);
		Info("Done building a route");
		return true;
	}
}

function AirHelper::CreateNewRandomRoute() {
	// Make new random routes to keep expanding if money exists

  // gets length of both route lists
  local route_len = this.route_1.Count();
  
  // gets the ID of a random route
  local route_1_rand = this.vehicle_array[AIBase.RandRangeItem(0, route_len)];
  local route_2_rand = this.vehicle_array[AIBase.RandRangeItem(0, route_len)];

  // gets the actual route info
  local tile_1 = this.route_1.GetValue(route_1_rand);
  local tile_2 = this.route_2.GetValue(route_2_rand);

  if (this.BuildNewVehicle(tile_1, tile_2, this.passenger_cargo_id)<0) {
    Info("Mungo bought a new aircraft");
  } else {
    Info("Error occured whilst buying new aircraft");
  }
}

// TODO find towns far away but not too far
function AirHelper::FindSuitableLocation(airport_type, center_tile) {
    local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

	local town_list = AITownList();

	// Remove all the towns we already used
	town_list.RemoveList(this.towns_used);

	town_list.Valuate(AITown.GetPopulation);
	town_list.KeepAboveValue(Mungo.GetSetting("min_town_size"));

	// Now find 2 suitable towns
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {
		// Don't make this a CPU hog
		Mungo.Sleep(1);

    	if (this.towns_used.HasItem(town)) continue;

		local tile = AITown.GetLocation(town);

		// Create a 30x30 grid around the core of the town and see if we can find a spot for a small airport
		local list = AITileList();

		// We assume we are more than 15 tiles away from the border!
		list.AddRectangle(tile - AIMap.GetTileIndex(15, 15), tile + AIMap.GetTileIndex(15, 15));
		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
		list.KeepValue(1);

		if (center_tile != 0) {
			// If we have a tile defined, we don't want to be within 25 tiles of this tile
			list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
			list.KeepAboveValue(625);
		}

		// Sort on acceptance, remove places that don't have acceptance
		list.Valuate(AITile.GetCargoAcceptance, this.passenger_cargo_id, airport_x, airport_y, airport_rad);
		list.RemoveBelowValue(10);

		// Couldn't find a suitable place for this town, skip to the next
		if (list.Count() == 0) continue; 

		// Walk all the tiles and see if we can build the airport at all
		{
      		local test = AITestMode();
			local good_tile = 0;

			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				Mungo.Sleep(1);
				if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) continue;
				good_tile = tile;
				break;
			}

			// Did we found a place to build the airport on?
			if (good_tile == 0) continue;
		}

		Info("Found a good spot for an airport in town " + town + " at tile " + tile);

		// Make the town as used, so we don't use it again
		this.towns_used.AddItem(town, tile);

		return tile;
	}

	Info("Couldn't find a suitable town to build an airport in");
	return -1;

}

// TODO accept a cargo type and get the biggest vehicle for this cargo
// TODO duplicate for an array of tiles for round robin
function AirHelper::BuildNewVehicle(tile_1, tile_2, cargo){
	// Build an aircraft with orders from tile_1 to tile_2.
	// The best available aircraft of that time will be bought.

	// Build an aircraft
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	local engine = null;

	local engine_list = AIEngineList(AIVehicle.VT_AIR);
	
  	// Filter planes by cargo only
	engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
	engine_list.KeepValue(1);

	// When bank balance < 300000, buy cheaper planes
	local balance = BankBalance();
	engine_list.Valuate(AIEngine.GetPrice);
	engine_list.KeepBelowValue(balance < 300000 && balance > 140000 ? 70000 : (balance < 1000000 ? 300000 : BankBalance()/4));

	// Get the biggest plane for our cargo
	engine_list.Valuate(AIEngine.GetMaxSpeed);
	engine_list.KeepTop(5);

  	// Get the biggest plane for our cargo
	engine_list.Valuate(AIVehicle.GetCapacity, cargo);
	engine_list.KeepTop(1);

	engine = engine_list.Begin();

	if (!AIEngine.IsValidEngine(engine)) {
		Error("Couldn't find a suitable engine");
		return -1;
	}
// TODO FIX
	if (!AIVehicle.RefitVehicle(engine, cargo)) {
		Error("Couldn't refit the aircraft " + AIError.GetLastErrorString());
		AIVehicle.SellVehicle(engine);
		return -1;
	}

	local vehicle = AIVehicle.BuildVehicle(hangar, engine);
	while (!AIVehicle.IsValidVehicle(vehicle)) {
		Mungo.Sleep(1);
		vehicle = AIVehicle.BuildVehicle(hangar, engine);
	}

	// Send it on it's way
	AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
	AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
	AIVehicle.StartStopVehicle(vehicle);

  	this.vehicle_array.append(vehicle);

	this.SetVehicleName(vehicle, tile_1 + " " + tile_2 + " " + vehicle);
	this.route_1.AddItem(vehicle, tile_1);
	this.route_2.AddItem(vehicle, tile_2);

	Info("Done building an aircraft #" + this.vehicle_array.len());

	return vehicle;
}

// TODO upgrade airports
function AirHelper::UpgradeRoutes() {
	local list = AIVehicleList();

	// Don't try to add planes when we are short on cash
	if (!HasMoney(250000)) return;

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

		// Do not build a new vehicle if we bought a new one in the last DISTANCE days
		local v = list2.Begin();
		list2.Valuate(AIVehicle.GetAge);
		list2.KeepBelowValue(365);
		if (list2.Count() != 0) continue;

		Info("Upgrading " + i + " (" + AIStation.GetLocation(i) + ") for passengers");

		// Make sure we have enough money
		GetMoney(250000);

		return this.BuildNewVehicle(this.route_1.GetValue(v), this.route_2.GetValue(v), this.passenger_cargo_id);
	}
}

function AirHelper::SellAirports(i) {
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

function AirHelper::UpgradeCargoDist() {
	local list = AIVehicleList();

	// Don't try to add planes when we are short on cash
	if (!HasMoney(250000)) return;

	list = AIStationList(AIStation.STATION_AIRPORT);
	list.Valuate(AIStation.GetCargoWaiting, this.mail_cargo_id);
	list.KeepAboveValue(250);
	Info("looking at mail")
	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local list2 = AIVehicleList_Station(i);

		// Do not build a new vehicle if we bought a new one in the last DISTANCE days
		local v = list2.Begin();
		list2.Valuate(AIVehicle.GetAge);
		list2.KeepBelowValue(365);
		if (list2.Count() != 0) continue;

		Info("Upgrading " + i + " (" + AIStation.GetLocation(i) + ") for mail");

		// Make sure we have enough money
		GetMoney(250000);

		local new_vehicle = this.BuildNewVehicle(this.route_1.GetValue(v), this.route_2.GetValue(v), this.mail_cargo_id);

		return true;
	}
}
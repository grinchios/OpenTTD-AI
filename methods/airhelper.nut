class AirHelper extends Helper {
	towns_used = null;

	constructor() {
		this.VEHICLETYPE = AIVehicle.VT_AIR;
		this.towns_used = TownsUsedForStationType(AIStation.STATION_AIRPORT);

		this.Init();
	}
}

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
		list.Valuate(AITile.GetCargoAcceptance, Mungo.passenger_cargo_id, airport_x, airport_y, airport_rad);
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

function AirHelper::BuildNewVehicle(tile_1, tile_2){
	// Build an aircraft with orders from tile_1 to tile_2.
	// The best available aircraft of that time will be bought.

	// Build an aircraft
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	local engine = null;

	local engine_list = AIEngineList(AIVehicle.VT_AIR);
	
  	// Filter planes by passengers only
	engine_list.Valuate(AIEngine.GetCargoType);
	engine_list.KeepValue(Mungo.passenger_cargo_id);

	// When bank balance < 300000, buy cheaper planes
	local balance = BankBalance();
	engine_list.Valuate(AIEngine.GetPrice);
	engine_list.KeepBelowValue(balance < 300000 && balance > 140000 ? 70000 : (balance < 1000000 ? 300000 : BankBalance()/4));

	// Get the biggest plane for our cargo
	engine_list.Valuate(AIEngine.GetMaxSpeed);
	engine_list.KeepTop(5);

  	// Get the biggest plane for our cargo
	engine_list.Valuate(AIEngine.GetCapacity);
	engine_list.KeepTop(1);

	engine = engine_list.Begin();

	if (!AIEngine.IsValidEngine(engine)) {
		Error("Couldn't find a suitable engine");
		return false;
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

	return true;
}

function AirHelper::UpgradeRoutes() {
	local list = AIVehicleList();

	// Don't try to add planes when we are short on cash
	if (!HasMoney(250000)) return;

	list = AIStationList(AIStation.STATION_AIRPORT);
	list.Valuate(AIStation.GetCargoWaiting, Mungo.passenger_cargo_id);
	list.KeepAboveValue(250);

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local list2 = AIVehicleList_Station(i);
		// No vehicles going to this station, abort and sell
		if (list2.Count() == 0) {
			this.air_helper.SellAirports(i);
			continue;
		};

		// Find the first vehicle that is going to this station
		local v = list2.Begin();

		list2.Valuate(AIVehicle.GetAge);

		// Do not build a new vehicle if we bought a new one in the last DISTANCE days
		if (list2.Count() != 0) continue;

		Info("Station " + i + " (" + AIStation.GetLocation(i) + ") has too much cargo, adding a new vehicle for the route.");

		// Make sure we have enough money
		GetMoney(250000);

		return this.air_helper.BuildNewVehicle(this.route_1.GetValue(v), this.route_2.GetValue(v));
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
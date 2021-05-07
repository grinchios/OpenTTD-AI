class AirHelper extends Helper {
	towns_used = null;
	passenger_cargo_id = null;
	vehicle_array = [];
	route_1 = null;
	route_2 = null;

	constructor() {
		this.towns_used = TownsUsedForStationType(AIStation.STATION_AIRPORT);

		// Get the id of passengers
		local list = AICargoList();
		for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
			if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS)) {
				this.passenger_cargo_id = i;
				break;
			}
		}

		local list = AIVehicleList();
		local vehicle_name;
		this.route_1 = [];
		this.route_2 = [];

		for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
			this.vehicle_array.append(i.VehicleID);
			
			vehicle_name = split_message(AIVehicle.GetName(i.VehicleID), " ");
			this.route_1.append(vehicle_name[0]);
			this.route_2.append(vehicle_name[1]);
		}
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

function AirHelper::BuildNewVehicle(tile_1, tile_2){
	// Build an aircraft with orders from tile_1 to tile_2.
	// The best available aircraft of that time will be bought.

	// Build an aircraft
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	local engine = null;

	local engine_list = AIEngineList(AIVehicle.VT_AIR);

	// When bank balance < 300000, buy cheaper planes
	local balance = BankBalance();
	engine_list.Valuate(AIEngine.GetPrice);
	engine_list.KeepBelowValue(balance < 300000 ? 50000 : (balance < 1000000 ? 300000 : 1000000));

  	// Filter planes by passengers only
	engine_list.Valuate(AIEngine.GetCargoType);
	engine_list.KeepValue(this.passenger_cargo_id);

  	// Get the biggest plane for our cargo
	engine_list.Valuate(AIEngine.GetCapacity);
	engine_list.KeepTop(1);

	engine = engine_list.Begin();

	if (!AIEngine.IsValidEngine(engine)) {
		Error("Couldn't find a suitable engine");
		return -5;
	}

	local vehicle = AIVehicle.BuildVehicle(hangar, engine);
	if (!AIVehicle.IsValidVehicle(vehicle)) {
		Error("Couldn't build the aircraft");
		return -6;
	}
  
	// Send it on it's way
	AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
	AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
	AIVehicle.StartStopVehicle(vehicle);
	this.distance_of_route.rawset(vehicle, AIMap.DistanceManhattan(tile_1, tile_2));

  	this.vehicle_array.append(vehicle);

	AIVehicle.SetName(vehicle, tile_1 + " " + tile_2 + " " + vehicle);
	this.route_1.AddItem(vehicle, tile_1);
	this.route_2.AddItem(vehicle, tile_2);

	Info("Done building an aircraft #" + this.vehicle_array.len());

	return 0;
}

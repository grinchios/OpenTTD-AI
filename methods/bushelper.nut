class BusHelper extends Helper {
	towns_used = null;
	pathfinder = null;
	DEBUG = true;

	constructor() {
		this.VEHICLETYPE = AIVehicle.VT_ROAD;
		this.towns_used = TownsUsedForStationType(AIStation.STATION_BUS_STOP);

		this.pathfinder = RoadPathFinder();

		this.Init();
	}
}

// TODO
function BusHelper::NewRouteCost(station_type) {
	return AIAirport.GetPrice(station_type)*2
}

// TODO
// TODO adjust max distance based on bus speed
function BusHelper::CreateNewRoute() {
	// Gets the "best" engine type avaliable
	Info("Trying to build a bus route");

	local tile_1 = this.FindSuitableLocation(0, 200);
	if (tile_1 < 0) return false;

	local tile_2 = this.FindSuitableLocation(0, 200);
	if (tile_2 < 0) {
		this.towns_used.RemoveValue(tile_1);
		return false;
	}
	
	// Get enough money to work with
	if (!HasMoney(this.NewRouteCost(airport_type))) {return false;}
	GetMoney(this.NewRouteCost(airport_type));

	// Build the airports for real
	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW)) {
		Error("Failed on the first airport at tile " + tile_1 + ".");
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		Error(AIError.GetLastErrorString());
		return false;
	}

	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW)) {
		Error("Failed on the second airport at tile " + tile_2 + ".");
		AIAirport.RemoveAirport(tile_1);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		Error(AIError.GetLastErrorString());
		return false;
	}

	local engine = this.SelectBestAircraft(airport_type, this.cargo_list[0], AITile.GetDistanceManhattanToTile(tile_1, tile_2))

	this.DebugSign(tile_1, "Distance:"+AITile.GetDistanceManhattanToTile(tile_1, tile_2));
	this.DebugSign(tile_2, "Distance:"+AITile.GetDistanceManhattanToTile(tile_1, tile_2));

	if (this.BuildNewVehicle(engine, tile_1, tile_2, this.cargo_list[0])<0) {
		Error("Removing airports due to error");
		AIAirport.RemoveAirport(tile_1);
		AIAirport.RemoveAirport(tile_2);
		this.towns_used.RemoveValue(tile_1);
		this.towns_used.RemoveValue(tile_2);
		return false;
	} else {
		local location = AIStation.GetStationID(tile_1);
		// this.SetDepotName(location, 0, 0);
		
		location = AIStation.GetStationID(tile_2);
		// this.SetDepotName(location, 0, 0);
		Info("Done building a route");
		return true;
	}
}

// TODO
// TODO test the repeated keep below cargo acceptance
// TODO use aitile and valuate for road tiles
// x and y size of bus stop is 1 and radius is 3
function BusHelper::FindSuitableLocation(center_tile=0, max_distance=INFINITY, cargo=this.cargo_list[0]) {
	local town_list = AITownList();

	// Remove all the towns we already used
	town_list.RemoveList(this.towns_used);

	// Keep large towns not too far away for the planes we have
	town_list.Valuate(AITown.GetPopulation);

	if (center_tile!=0) {
		this.KeepTopPercent(town_list, 50)
		town_list.Valuate(AITown.GetDistanceSquareToTile, center_tile);
		town_list.KeepBelowValue(max_distance);
	}

	town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	town_list.KeepTop(5);


	// Now find 2 suitable towns
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next()) {
		// Don't make this a CPU hog
		Mungo.Sleep(1);

    	if (this.towns_used.HasItem(town)) continue;

		local tile = AITown.GetLocation(town);

		local list = AITileList();

		// Sort on acceptance, remove places that don't have acceptance 
		list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
		list.RemoveBelowValue(50);
		list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
		list.RemoveBelowValue(10);

		if (center_tile != 0) {
			// If we have a tile defined, we don't want to be within 25 tiles of this tile
			list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
			list.KeepAboveValue(625);
		}

		// Sort on acceptance, remove places that don't have acceptance
		list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
		list.RemoveBelowValue(10);

		// Couldn't find a suitable place for this town, skip to the next
		if (list.Count() == 0) continue; 

		// Walk all the tiles and see if we can build the airport at all
		{
      		local test = AITestMode();
			local good_tile = 0;

			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
				Mungo.Sleep(1);
				if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) {
					this.DebugSign(tile, "tile:"+tile)
					continue;
				}
				
				good_tile = tile;
				break;
			}

			// Did we find a place to build the airport on?
			if (good_tile == 0) continue;
		}

		Info("Found a good spot for an airport in town " + town + " at tile " + tile);

		// Mark the town as used, so we don't use it again
		this.towns_used.AddItem(town, tile);
		return tile;
	}

	Info("Couldn't find a suitable town to build an airport in");
	return -1;

}

// TODO
function BusHelper::BuildNewVehicle(engine, tile_1, tile_2, cargo){
	// Build an aircraft with orders from tile_1 to tile_2.
	// The best available aircraft of that time will be bought.

	// Build an aircraft
	local hangar = AIAirport.GetHangarOfAirport(tile_1);

	// Get the shmoneys
	GetMoney(AIEngine.GetPrice(engine));
	
	local vehicle = AIVehicle.BuildVehicleWithRefit(hangar, engine, cargo);
	while (!AIVehicle.IsValidVehicle(vehicle)) {
		Mungo.Sleep(1);
		vehicle = AIVehicle.BuildVehicleWithRefit(hangar, engine, cargo);
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

// TODO
function BusHelper::ManageRoutes() {
	// Don't try to add planes when we are short on cash
	if (!CanAffordCheapestEngine()) return;

	// Upgrade routes for all cargo routes we currently service
	for (local i = this.cargo_list[0]; i < cargo_list.len() ; i++) {
		local list = AIStationList(AIStation.STATION_AIRPORT);
		list.Valuate(AIStation.GetCargoWaiting, this.cargo_list[i]);
		list.KeepAboveValue(250);

		for (local station_id = list.Begin(); list.HasNext(); station_id = list.Next()) {
			local list2 = AIVehicleList_Station(station_id);
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

			Info("Upgrading " + station_id + " (" + AIStation.GetLocation(station_id) + ") for passengers");

			local airport_type = AIAirport.GetAirportType(this.route_1.GetValue(v))
			local engine = this.SelectBestAircraft(airport_type, this.cargo_list[i], AITile.GetDistanceManhattanToTile(this.route_1.GetValue(v), this.route_2.GetValue(v)))
			
			// Make sure we have enough money
			GetMoney(AIEngine.GetPrice(engine));

			return this.BuildNewVehicle(engine, this.route_1.GetValue(v), this.route_2.GetValue(v), this.cargo_list[i]);
		}
	}
}

// TODO
function BusHelper::SellAirports(i) {
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
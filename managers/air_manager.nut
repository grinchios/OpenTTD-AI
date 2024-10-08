// // TODO find cities to build in and then create list for feeder cities
// // TODO check aircraft limits
// class AirManager extends Manager {
// 	towns_used = null;
// 	DEBUG = false;

// 	constructor() {
// 		this.VEHICLE_TYPE = AIVehicle.VT_AIR;
// 		this.STATION_TYPE = AIStation.STATION_AIRPORT;
// 		this.towns_used = TownsUsedForStationType(this.STATION_TYPE);

// 		this.Init();
// 	}
// }

// // TODO add in maximum cost to calls, used when we know the cost of airports
// function AirManager::SelectBestAircraft(airport_type, cargo, distance, maximum_cost=INFINITY)
// {
// 	if (!this.CanAffordCheapestEngine(cargo)) { return -1 }

// 	local engine_list = AIEngineList(this.VEHICLE_TYPE)

// 	// Remove big planes if we use a smaller airport type
// 	if (airport_type==AIAirport.AT_SMALL || airport_type==AIAirport.AT_COMMUTER )
// 	{
// 		engine_list.Valuate(AIEngine.GetPlaneType);
// 		engine_list.RemoveValue(AIAirport.PT_BIG_PLANE);
// 	}

// 	engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
// 	engine_list.KeepValue(1);

// 	engine_list.Valuate(AIEngine.GetMaximumOrderDistance);
// 	local tmp_engine_list = engine_list
// 	for (local engine = tmp_engine_list.Begin(); tmp_engine_list.HasNext(); engine = tmp_engine_list.Next())
// 	{
// 		if (AIEngine.GetMaximumOrderDistance(engine) < distance && AIEngine.GetMaximumOrderDistance(engine) != 0) { engine_list.RemoveItem(engine)}
// 	}

// 	engine_list.Valuate(AIEngine.GetPrice);
// 	engine_list.KeepBelowValue(MaximumBudget() / 2);

// 	engine_list.Valuate(this.EngineUse);
// 	engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
// 	engine_list.KeepTop(1);

// 	return engine_list.Begin();
// }

// function AirManager::NewRouteCost(station_type)
// {
// 	return AIAirport.GetPrice(station_type) * 2
// }

// // TODO get towns further than 200 for airports
// // TODO aiai burden style system
// function AirManager::CreateNewRoute()
// {
// 	// TODO add some variable inputs here to select the most relevant airport
// 	// Gets the "best" airport type avaliable
// 	local airport_type = GetBestAirport();
// 	if (airport_type == -1) { return -1 }

// 	Info("Trying to build an airport route");

// 	local tile_1 = this.FindSuitableLocation(airport_type);
// 	if (tile_1 < 0) { return false };

// 	local tile_2 = this.FindSuitableLocation(airport_type, tile_1);
// 	if (tile_2 < 0)
// 	{
// 		this.towns_used.RemoveValue(tile_1);
// 		return false;
// 	}

// 	// Get enough money to work with
// 	if (!HasMoney(this.NewRouteCost(airport_type))) { return false; }
// 	GetMoney(this.NewRouteCost(airport_type));

// 	// Build the airports for real
// 	if (!AIAirport.BuildAirport(tile_1, airport_type, AIStation.STATION_NEW))
// 	{
// 		Error("Failed on the first airport at tile " + tile_1 + ".");
// 		this.towns_used.RemoveValue(tile_1);
// 		this.towns_used.RemoveValue(tile_2);
// 		Error(AIError.GetLastErrorString());
// 		return false;
// 	}

// 	if (!AIAirport.BuildAirport(tile_2, airport_type, AIStation.STATION_NEW))
// 	{
// 		Error("Failed on the second airport at tile " + tile_2 + ".");
// 		AIAirport.RemoveAirport(tile_1);
// 		this.towns_used.RemoveValue(tile_1);
// 		this.towns_used.RemoveValue(tile_2);
// 		Error(AIError.GetLastErrorString());
// 		return false;
// 	}

// 	local engine = this.SelectBestAircraft(airport_type, this.cargo_list[0], AITile.GetDistanceManhattanToTile(tile_1, tile_2))

// 	if (!AIEngine.IsValidEngine(engine))
// 	{
// 		Error("Error selecting new engine");
// 		return false;
// 	}

// 	this.DebugSign(tile_1, "Distance:"+AITile.GetDistanceManhattanToTile(tile_1, tile_2));
// 	this.DebugSign(tile_2, "Distance:"+AITile.GetDistanceManhattanToTile(tile_1, tile_2));

// 	if (this.BuildNewVehicle(engine, tile_1, tile_2, this.cargo_list[0]) < 0)
// 	{
// 		Error("Removing airports due to error");
// 		AIAirport.RemoveAirport(tile_1);
// 		AIAirport.RemoveAirport(tile_2);
// 		this.towns_used.RemoveValue(tile_1);
// 		this.towns_used.RemoveValue(tile_2);
// 		return false;
// 	}
// 	else
// 	{
// 		Info("Done building a route");
// 		return true;
// 	}
// }

// // TODO only build in cities?
// // TODO terraform to make room
// // TODO add cargo selection in for cargo planes
// function AirManager::FindSuitableLocation(airport_type, center_tile=0, max_distance=INFINITY)
// {
//     local airport_x, airport_y, airport_rad;

// 	airport_x = AIAirport.GetAirportWidth(airport_type);
// 	airport_y = AIAirport.GetAirportHeight(airport_type);
// 	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

// 	local town_list = AITownList();

// 	// Remove all the towns we already used
// 	town_list.RemoveList(this.towns_used);

// 	// Keep large towns not too far away for the planes we have
// 	town_list.Valuate(AITown.GetPopulation);
// 	town_list.KeepAboveValue(Mungo.GetSetting("min_town_size"));

// 	if (center_tile!=0)
// 	{
// 		this.KeepTopPercent(town_list, 50)
// 		town_list.Valuate(AITown.GetDistanceSquareToTile, center_tile);
// 		town_list.KeepBelowValue(max_distance);
// 		town_list.KeepAboveValue(200);
// 	}

// 	town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
// 	town_list.KeepTop(5);


// 	// Now find 2 suitable towns
// 	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
// 	{
// 		// Don't make this a CPU hog
// 		Mungo.Sleep(1);

// 		local tile = AITown.GetLocation(town);

// 		// Create a 30x30 grid around the core of the town and see if we can find a spot for a small airport
// 		local list = AITileList();

// 		local span = AIMap.DistanceFromEdge(tile) <= 15 ? AIMap.DistanceFromEdge(tile) - 1 : 15;
// 		list.AddRectangle(tile - AIMap.GetTileIndex(span, span), tile + AIMap.GetTileIndex(span, span));
// 		list.Valuate(AITile.IsBuildableRectangle, airport_x, airport_y);
// 		list.KeepValue(1);

// 		// Sort on acceptance, remove places that don't have acceptance
// 		list.Valuate(AITile.GetCargoAcceptance, this.cargo_list[0], airport_x, airport_y, airport_rad);
// 		list.RemoveBelowValue(50);

// 		if (center_tile != 0)
// 		{
// 			// If we have a tile defined, we don't want to be within X tiles
// 			// Look further than 200 for planes and under 200 for buses
// 			list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
// 			list.KeepAboveValue(625);
// 		}

// 		// Couldn't find a suitable place for this town, skip to the next
// 		if (list.Count() == 0) continue;

// 		// Walk all the tiles and see if we can build the airport at all
// 		{
//       		local test = AITestMode();
// 			local good_tile = 0;

// 			for (tile = list.Begin(); list.HasNext(); tile = list.Next()) {
// 				Mungo.Sleep(1);
// 				if (!AIAirport.BuildAirport(tile, airport_type, AIStation.STATION_NEW)) {
// 					this.DebugSign(tile, "tile:"+tile)
// 					continue;
// 				}

// 				good_tile = tile;
// 				break;
// 			}

// 			// Did we find a place to build the airport on?
// 			if (good_tile == 0) continue;
// 		}

// 		Info("Found a good spot for an airport in town " + town + " at tile " + tile);

// 		// Mark the town as used, so we don't use it again
// 		this.towns_used.AddItem(town, tile);
// 		return tile;
// 	}

// 	Info("Couldn't find a suitable town to build an airport in");
// 	return -1;

// }

// // TODO duplicate for an array of tiles for round robin
// function AirManager::BuildNewVehicle(engine, tile_1, tile_2, cargo)
// {
// 	// Build an aircraft with orders from tile_1 to tile_2.
// 	// The best available aircraft of that time will be bought.

// 	// Build an aircraft
// 	local hangar = AIAirport.GetHangarOfAirport(tile_1);

// 	// Get some money
// 	if (!HasMoney(AIEngine.GetPrice(engine))) { return -1 }
// 	GetMoney(AIEngine.GetPrice(engine));

// 	local vehicle = AIVehicle.BuildVehicleWithRefit(hangar, engine, cargo);
// 	while (!AIVehicle.IsValidVehicle(vehicle))
// 	{
// 		Mungo.Sleep(1);
// 		vehicle = AIVehicle.BuildVehicleWithRefit(hangar, engine, cargo);
// 		Info(AIError.GetLastErrorString());
// 		Info(AIAirport.IsHangarTile(hangar) + " " + AIAirport.GetHangarOfAirport(hangar))
// 		Info(AIEngine.IsValidEngine(engine) + " " + AIEngine.IsBuildable(engine) + " " + AIEngine.CanRefitCargo(engine, cargo))
// 		Info(AICargo.IsValidCargo(cargo))
// 		Info(cargo)
// 	}

// 	// Send it on it's way
// 	AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
// 	AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
// 	AIVehicle.StartStopVehicle(vehicle);

//   	this.vehicle_array.append(vehicle);

// 	this.SetVehicleName(vehicle, tile_1 + " " + tile_2 + " " + vehicle);
// 	this.route_1.AddItem(vehicle, tile_1);
// 	this.route_2.AddItem(vehicle, tile_2);

// 	Info("Done building an aircraft #" + this.vehicle_array.len());

// 	return vehicle;
// }

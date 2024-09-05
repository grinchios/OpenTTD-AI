class BusHelper extends Helper
{
	towns_used = null;
	pathfinder = null;
	DEBUG = true;

	constructor()
	{
		this.VEHICLETYPE = AIVehicle.VT_ROAD;
		this.STATIONTYPE = AIStation.STATION_BUS_STOP
		this.towns_used = TownsUsedForStationType(this.STATIONTYPE);

		this.pathfinder = RoadPathFinder();

		this.Init();
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		Warning("Bus helper started!")
	}
}

function BusHelper::CleanUp(tile_1, tile_2, progress)
{
	this.towns_used.RemoveValue(tile_1);
	this.towns_used.RemoveValue(tile_2);

	if (progress==2) {
		AIRoad.RemoveRoadStation(tile_2);
	}
	return true;
}

// TODO adjust max distance based on bus speed
// TODO test mode whole path then build it
function BusHelper::CreateNewRoute()
{
	// Gets the "best" engine type avaliable
	Info("Trying to build a bus route");

	local tile_1 = this.FindSuitableLocation(this.cargo_list[0]);
	if (tile_1 < 0) { return false };

	local tile_2 = this.FindSuitableLocation(this.cargo_list[0], tile_1, 5000);
	if (tile_2 < 0)
	{
		this.towns_used.RemoveValue(tile_1);
		return false;
	}

	// this.DebugSign(tile_1, "bus stop 1");
	// this.DebugSign(tile_2, "bus stop 2");

	// Get enough money to work with
	local costs = AIAccounting();
	local pathCost = 0;
	local roadList = []
	costs.ResetCosts();

	// Test build
	{
		local test = AITestMode();
		roadList = RoadPathCreator(tile_1, tile_2);
		if (roadList.len()!=2) return false;
		pathCost = roadList[1] + AIRoad.GetBuildCost(AIRoad.ROADTYPE_ROAD, AIRoad.BT_BUS_STOP)*2
		GetMoney(pathCost)
	}

	// Check we can afford it and the path was successful
	if (!HasMoney(pathCost))
	{
		Error("Not enough money available")
		this.CleanUp(tile_1, tile_2, 1)
		return false;
	}
	else if (roadList[0]<0 && HasMoney(pathCost))
	{
		Error("Removing route due to error");
		this.CleanUp(tile_1, tile_2, 1)
		return false;
	}

	// Build the route for real
	if (!this.BuildAllAngles(tile_1))
	{
		Error("Failed on the first stop at tile " + tile_1);
		this.CleanUp(tile_1, tile_2, 1)
		return false;
	}

	if (!this.BuildAllAngles(tile_2))
	{
		Error("Failed on the second stop at tile " + tile_2);
		Athis.CleanUp(tile_1, tile_2, 1)
		return false;
	}

	// GetMoney(costs.GetCosts())
	roadList = RoadPathCreator(tile_1, tile_2);

	Info("Done building new route");

	local engine = this.SelectBestEngine(this.cargo_list[0], AITile.GetDistanceManhattanToTile(tile_1, tile_2))

	if (!this.BuildNewVehicle(engine, tile_1, tile_2, this.cargo_list[0], roadList[0]))
	{
		Error("Removing route due to error");
		Error(AIError.GetLastErrorString());
		this.CleanUp(tile_1, tile_2, 2)
		return false;
	}
	else
	{
		local location = AIStation.GetStationID(tile_1);
		this.SetDepotName(location, 0, roadList[0]);

		location = AIStation.GetStationID(tile_2);
		this.SetDepotName(location, 0, roadList[0]);
		Info("Done building a route");
		return true;
	}
}

// TODO merge with aircraft function
function BusHelper::SelectBestEngine(cargo, distance, maximum_cost=INFINITY)
{
	if (!this.CanAffordCheapestEngine(cargo)) {return -1}

	local engine_list = AIEngineList(this.VEHICLETYPE)


	engine_list.Valuate(AIEngine.GetRoadType);
	engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);

	engine_list.Valuate(AIEngine.GetPrice);
	engine_list.KeepBelowValue(CurrentFunds()/2);

	engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
	engine_list.KeepValue(1);

	engine_list.Valuate(AIEngine.GetMaximumOrderDistance);
	local tmp_engine_list = engine_list
	for (local engine = tmp_engine_list.Begin(); tmp_engine_list.HasNext(); engine = tmp_engine_list.Next())
	{
		if (AIEngine.GetMaximumOrderDistance(engine) < distance && AIEngine.GetMaximumOrderDistance(engine) != 0)
		{
			engine_list.RemoveItem(engine)
		}
	}

	engine_list.Valuate(this.EngineUse);
	engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	engine_list.KeepTop(1);

	return engine_list.Begin();

}

function BusHelper::BuildAllAngles(tile, station_type=AIStation.STATION_NEW)
{
	// this.DebugSign(tile+AIMap.GetTileIndex(0, 1), "tile:"+(tile+AIMap.GetTileIndex(0, 1)))
	if (AIRoad.BuildDriveThroughRoadStation(tile, tile+AIMap.GetTileIndex(0, 1), AIRoad.ROADVEHTYPE_BUS, station_type))
	{
		return true;
	}
	// this.DebugSign(tile+AIMap.GetTileIndex(1, 0), "tile:"+(tile+AIMap.GetTileIndex(1, 0)))
	if (AIRoad.BuildDriveThroughRoadStation(tile, tile+AIMap.GetTileIndex(1, 0), AIRoad.ROADVEHTYPE_BUS, station_type))
	{
		return true;
	}
	return false;
}

// TODO add in path finding here to make sure you can reach the location
// x and y size of bus stop is 1 and radius is 3
function BusHelper::FindSuitableLocation(cargo, center_tile=0, max_distance=INFINITY)
{
	local town_list = AITownList();

	// Remove all the towns we already used
	town_list.RemoveList(this.towns_used);

	// Keep large towns not too far away for the vehicles we have
	if (center_tile != 0)
	{
		town_list.Valuate(AITown.GetDistanceSquareToTile, center_tile);
		// if (this.DEBUG) {OutputList(town_list)}
		town_list.KeepBelowValue(max_distance);
	}

	town_list.Valuate(AITown.GetPopulation);
	town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
	town_list.KeepTop(10);

	// Now find 2 suitable towns
	for (local town = town_list.Begin(); town_list.HasNext(); town = town_list.Next())
	{
		// Don't make this a CPU hog
		Mungo.Sleep(1);

		local tile = AITown.GetLocation(town);
		// this.DebugSign(tile, "tile:" + tile)

		// Make sure the cities aren't at the edge of the map
		local list = AITileList();
		local span = AIMap.DistanceFromEdge(tile) <= 15 ? AIMap.DistanceFromEdge(tile) - 1 : 15;
		list.AddRectangle(tile - AIMap.GetTileIndex(span, span), tile + AIMap.GetTileIndex(span, span));

		// Sort on acceptance, remove places that don't have acceptance
		list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, 3);
		list.RemoveBelowValue(9);

		// Only keep roads and those without current stations for the stops
		list.Valuate(AITile.HasTransportType, AITile.TRANSPORT_ROAD);
		list.KeepValue(1);
		list.Valuate(AIRoad.IsRoadStationTile);
		list.RemoveValue(1);

		if (center_tile != 0)
		{
			// If we have a tile defined, we don't want to be within 5 tiles of this tile
			list.Valuate(AITile.GetDistanceSquareToTile, center_tile);
			list.KeepAboveValue(25);
		}

		// Couldn't find a suitable place for this town, skip to the next
		if (list.Count() == 0) { continue }
		// Walk all the tiles and see if we can build the route at all
		{
      		local test = AITestMode();
			local good_tile = 0;

			for (tile = list.Begin(); list.HasNext(); tile = list.Next())
			{
				Mungo.Sleep(1);
				// this.DebugSign(tile, "tile:"+tile);
				if (!this.BuildAllAngles(tile)) { continue }

				good_tile = tile;
				break;
			}

			// Did we find a place to build the route on?
			if (good_tile == 0) { continue }
		}

		Info("Found a good spot for a bus stop in town " + town + " at tile " + tile);

		// Mark the town as used, so we don't use it again
		this.towns_used.AddItem(town, tile);
		return tile;
	}

	Info("Couldn't find a suitable town to build a bus stop in");
	return -1;

}

function BusHelper::BuildNewVehicle(engine, tile_1, tile_2, cargo, depot)
{
	// Build an aircraft with orders from tile_1 to tile_2.
	// The best available aircraft of that time will be bought.

	if (!AIRoad.IsRoadDepotTile(depot))
	{
		Error("Invalid depot selected: " + depot);
		return false;
	}
	else if (!AIEngine.IsValidEngine(engine) || engine<=0)
	{
		Error("Invalid engine selected: " + engine);
		return false;
	}

	// Get some money
	if (!HasMoney(AIEngine.GetPrice(engine))) { return -1 }
	GetMoney(AIEngine.GetPrice(engine));

	local vehicle = AIVehicle.BuildVehicleWithRefit(depot, engine, cargo);
	while (!AIVehicle.IsValidVehicle(vehicle))
	{
		Mungo.Sleep(1);
		vehicle = AIVehicle.BuildVehicleWithRefit(depot, engine, cargo);
		Error(AIError.GetLastErrorString())
		Info("Depot: " + depot + " engine: " + engine + " cargo: " + cargo);
		Info(AIRoad.IsRoadDepotTile(depot) + " " + AIEngine.IsValidEngine(engine) + " " + AICargo.IsValidCargo(cargo))
		// this.DebugSign(depot, "depot tile: "+ depot)
	}

	// Naming
	this.SetVehicleName(vehicle, tile_1 + " " + tile_2 + " " + vehicle);
	this.route_1.AddItem(vehicle, tile_1);
	this.route_2.AddItem(vehicle, tile_2);

	// Send it on it's way
	AIOrder.AppendOrder(vehicle, tile_1, AIOrder.AIOF_NONE);
	AIOrder.AppendOrder(vehicle, tile_2, AIOrder.AIOF_NONE);
	AIVehicle.StartStopVehicle(vehicle);

  	this.vehicle_array.append(vehicle);

	Info("Done building a vehicle #" + this.vehicle_array.len());

	return true;
}
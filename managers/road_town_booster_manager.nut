class RoadTownBoosterManager extends Manager
{
	constructor()
	{
		this.VEHICLE_TYPE = AIVehicle.VT_ROAD;
		this.STATION_TYPE = AIStation.STATION_BUS_STOP
		this.towns_used = TownsUsedForStationType(this.STATION_TYPE);
        this.cargo_list = [
            AICargo.CC_PASSENGERS
        ];

		this.Init();
		AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
		Warning("Bus manager started!")
	}
}

function RoadTownBoosterManager::CleanUp(tile_1, tile_2, progress)
{
	this.towns_used.RemoveValue(tile_1);
	this.towns_used.RemoveValue(tile_2);

	if (progress == 2) {
		AIRoad.RemoveRoadStation(tile_2);
	}
	return true;
}

// TODO adjust max distance based on bus speed
// TODO test mode whole path then build it
function RoadTownBoosterManager::CreateNewRoute()
{
	// Gets the "best" engine type avaliable
	Info("Trying to build a local bus route");

	local tile_1 = this.FindSuitableLocation(this.cargo_list[0]);
	if (tile_1 < 0) { return false };

	local tile_2 = this.FindSuitableLocation(this.cargo_list[0], tile_1, 50);
	if (tile_2 < 0)
	{
		this.towns_used.RemoveValue(tile_1);
		return false;
	}

	place_sign(tile_1, "bus stop 1");
	place_sign(tile_2, "bus stop 2");

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
	local front_tile = CanBuildDriveThroughRoadStation(tile_1);
	if (!AIRoad.BuildDriveThroughRoadStation(tile_1, front_tile, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW))
	{
		Error("Failed on the first stop at tile " + tile_1);
		this.CleanUp(tile_1, tile_2, 1)
		return false;
	}

	front_tile = CanBuildDriveThroughRoadStation(tile_2);
	if (!AIRoad.BuildDriveThroughRoadStation(tile_2, front_tile, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW))
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
function RoadTownBoosterManager::SelectBestEngine(cargo, distance, maximum_cost=INFINITY)
{
	if (!this.CanAffordCheapestEngine(cargo)) {return -1}

	local engine_list = AIEngineList(this.VEHICLE_TYPE)


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


// TODO add in path finding here to make sure you can reach the location
// x and y size of bus stop is 1 and radius is 3
function RoadTownBoosterManager::FindSuitableLocation(cargo, centre_tile=0, max_distance=INFINITY)
{
    local selected_town = null;
    if (centre_tile == 0)
    {
        // If we don't have a centre tile then we have to look for a new location
        local town_list = AITownList();
        town_list.RemoveList(this.towns_used); // Remove all the towns we already used
        town_list.Valuate(AITown.IsCity); // Only keep cities
        town_list.KeepValue(1);
        if (town_list.Count() == 0) { return -1 }
        town_list.Valuate(AITown.GetPopulation); // Sort on population
        town_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
        selected_town = town_list.Begin();
    }
    else
    {
        // We need to find the currently used town for this route
        selected_town = AITile.GetClosestTown(centre_tile);
    }

    local town_centre = AITown.GetLocation(selected_town);
	place_sign(town_centre, "town centre");

    // ============================== Find a suitable location for the bus stop ==============================
    local list = AITileList();
    local span = AIMap.DistanceFromEdge(town_centre) <= 15 ? AIMap.DistanceFromEdge(town_centre) - 1 : 15; // Make sure the tiles aren't at the edge of the map
    list.AddRectangle(town_centre - AIMap.GetTileIndex(span, span), town_centre + AIMap.GetTileIndex(span, span));
	Debug("Starting to look for a suitable location for a bus stop in town " + selected_town + " with " + list.Count() + " tiles remaining");
	if (centre_tile != 0)
	{
		local station_radius = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP) * 2;
		local station_radius_tile = AIMap.GetTileIndex(station_radius, station_radius);
		list.RemoveRectangle(centre_tile - station_radius_tile, centre_tile + station_radius_tile); // Remove the area around the current station
		Debug("After removing the current station area, " + list.Count() + " tiles remaining");
	}
    // list.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP)); // Sort on acceptance, remove places that don't have acceptance
    // list.KeepAboveValue(1);
	// Debug("After removing tiles without acceptance, " + list.Count() + " tiles remaining");
	// TODO update this so we can use non drive through stations
    list.Valuate(AITile.HasTransportType, AITile.TRANSPORT_ROAD); // Only keep roads and those without current stations for the stops
    list.KeepValue(1);
	Debug("After removing tiles without roads, " + list.Count() + " tiles remaining");
    list.Valuate(AIRoad.IsRoadStationTile);
    list.RemoveValue(1);
	Debug("After removing tiles with stations, " + list.Count() + " tiles remaining");

	list.Valuate(AIMap.DistanceManhattan, town_centre); // Sort on distance to the town centre
	list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);

    // Couldn't find a suitable place for this town, skip to the next
    if (list.Count() == 0) { Error("Cannot find a suitable station to build in"); return -1 }

    // Walk all the tiles and see if we can build the route at all
	local good_tile = -1;

	for (local tile = list.Begin(); list.HasNext(); tile = list.Next())
	{
		if (CanBuildDriveThroughRoadStation(tile) > 0)
		{
		    good_tile = tile;
			break;
		}
	}

	// Did we find a place to build the route on?
	if (good_tile == -1) { return -1 }

    Info("Found a good spot for a bus stop in town " + selected_town + " at tile " + good_tile);

    // Mark the town as used, so we don't use it again
    this.towns_used.AddItem(selected_town, good_tile);
    return good_tile;
}

function RoadTownBoosterManager::BuildNewVehicle(engine, tile_1, tile_2, cargo, depot)
{
	// Build a vehicle with orders from tile_1 to tile_2.
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
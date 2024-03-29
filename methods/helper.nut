// TODO new function to check if we've built everywhere possible
// TODO replace vehicle function
// TODO new route class with estimated cost, test build and other useful things
class Helper {
    route_1 = null;
	route_2 = null;
    vehicle_array = [];
    VEHICLETYPE = null;
	STATIONTYPE = null;

    cargo_list = []
};

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
        this.route_1.AddItem(i, vehicle_name[0]);
        this.route_2.AddItem(i, vehicle_name[1]);
    }

    this.cargo_list.append(GetCargoID(AICargo.CC_PASSENGERS));
    this.cargo_list.append(GetCargoID(AICargo.CC_MAIL));
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

function Helper::UpgradeVehicles() {
    if (this.VEHICLETYPE==AIVehicle.VT_AIR) {
        local vehicle_sizes = [AIAirport.PT_SMALL_PLANE, AIAirport.PT_BIG_PLANE]
        local airport_types = [AIAirport.AT_COMMUTER, AIAirport.AT_METROPOLITAN]
        for (local i = 0; i < vehicle_sizes.len(); i++) {
            local engine_list=AIEngineList(this.VEHICLETYPE);
            engine_list.Valuate(AIEngine.GetPlaneType);
            engine_list.KeepValue(vehicle_sizes[i]);

            for(local engine_existing = engine_list.Begin(); engine_list.HasNext(); engine_existing = engine_list.Next()) {
                for (local j = this.cargo_list[0]; j < this.cargo_list.len(); j++) {
                    if (AIEngine.CanRefitCargo(engine_existing, this.cargo_list[i])) {
                        break;
                    }
                }

                if (AIEngine.IsBuildable(AIGroup.GetEngineReplacement(AIGroup.GROUP_ALL, engine_existing))==false) {
                    local engine_best = this.SelectBestAircraft(airport_types[i], this.cargo_list[0], AIEngine.GetMaximumOrderDistance(engine_existing))
                    if (engine_best != engine_existing && engine_best != null) {
                        AIGroup.SetAutoReplace(AIGroup.GROUP_ALL, engine_existing, engine_best);
                        // Info(AIEngine.GetName(engine_existing) + " will be replaced by " + AIEngine.GetName(engine_best));
                    }
                }
            }
        }
    }
}

function Helper::SellNegativeVehicles() {
    local list = AIVehicleList();
	list.Valuate(AIVehicle.GetVehicleType);
	list.KeepValue(this.VEHICLETYPE);

	// Set up thresholds for vehicle types
    local threshold;
    if (this.VEHICLETYPE==AIVehicle.VT_AIR) {threshold=10000}
    else if (this.VEHICLETYPE==AIVehicle.VT_ROAD) {threshold=2000}

	// Give the vehicle at least 2 years to make a difference
	list.Valuate(AIVehicle.GetAge);
	list.KeepAboveValue(365 * 2);
	list.Valuate(AIVehicle.GetProfitLastYear);

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		local profit = list.GetValue(i);

		// Profit last year and this year bad? Let's sell the vehicle
		if (profit < threshold && AIVehicle.GetProfitThisYear(i) < threshold) {
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

                // Check if we are the last one serving those stops; else sell the stops
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
        AIAirport.RemoveAirport(this.route_1.GetValue(i));
	    AIAirport.RemoveAirport(this.route_2.GetValue(i));
    } else if (this.VEHICLETYPE == AIVehicle.VT_ROAD) {
		local station_name = AIBaseStation.GetName(AIStation.GetStationID(this.route_1.GetValue(i)))

		Info("input " + i + " route value " + this.route_1.GetValue(i))
		Info("station name " + station_name + " station ID " + AIStation.GetStationID(this.route_1.GetValue(i)))
		OutputList(this.route_1)

		station_name = split(station_name.tostring(), " ")
		if (station_name.len()==3 && AIRoad.IsRoadDepotTile(station_name[2].tointeger())) {
			AIRoad.RemoveRoadDepot(station_name[2].tointeger());
		}
		
		Info(this.route_1.GetValue(i))
        AIRoad.RemoveRoadStation(this.route_1.GetValue(i));
	    AIRoad.RemoveRoadStation(this.route_2.GetValue(i));
    } else {
		Error("Invalid vehicle type:" + this.VEHICLETYPE);
		Error(AIError.GetLastErrorString());
	}
    this.ClearRoute(i);
}

function Helper::ClearRoute(i) {
    // Free the entries
	this.towns_used.RemoveValue(this.route_1.GetValue(i));
	this.towns_used.RemoveValue(this.route_2.GetValue(i));

	// Remove the route
	this.route_1.RemoveItem(i);
	this.route_2.RemoveItem(i);
}

function Helper::KeepTopPercent(input_list, percent) {
    input_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_DESCENDING);
    input_list.KeepTop(((input_list.Count()*10000)/100*percent)/10000);

    return input_list;
}

function Helper::CanAffordCheapestEngine(cargo) {
    return HasMoney(this.CheapestEngine(cargo));
}

function Helper::CheapestEngine(cargo) {
    local engine_list = AIEngineList(this.VEHICLETYPE)
    engine_list.Valuate(AIEngine.CanRefitCargo, cargo);
	engine_list.KeepValue(1);
    engine_list.Valuate(AIEngine.GetPrice)
	engine_list.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
    return engine_list.GetValue(engine_list.Begin());
}

function Helper::EngineUse(engine_id) {
    return AIEngine.GetCapacity(engine_id) * AIEngine.GetMaxSpeed(engine_id);
}

function Helper::GetOrderDistance(tile_1, tile_2) {
	return AIOrder.GetOrderDistance(this.VEHICLETYPE, tile_1, tile_2);
}

function Helper::DebugSign(tile, message) {
    if (this.DEBUG) {
        {
            local mode = AIExecMode();
            local debug_sign = AISign.BuildSign(tile, message);
            while (!AISign.IsValidSign(debug_sign) && AIMap.IsValidTile(tile)) {
                Mungo.Sleep(1);
                debug_sign = AISign.BuildSign(tile, message);
                Error(AIError.GetLastErrorString() + " " + tile);
            }
        }
    }
}

function Helper::RoadPathCreator(tile_1, tile_2, depot_tile=-1,) {
	local costs = AIAccounting();

    this.pathfinder.InitializePath([tile_1], [tile_2]);
    local depot_tile = -1;
	local ret = [];

	// Try to find a path.
	local path = false;
	while (path == false) {
		path = this.pathfinder.FindPath(100);
		Mungo.Sleep(1);
	}

	if (path == null) {
		// No path was found.
		Error("PathFinder Error");
        return -1;
	}

	costs.ResetCosts();
    /// If a path was found, build a road over it.
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			local last_node = path.GetTile();
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
				if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) { 
					if (depot_tile<0) {
						depot_tile = this.BuildDepotForRoute(path.GetTile())
						if (depot_tile>0) {
							local built = AIRoad.BuildRoadDepot(depot_tile, path.GetTile());
							local errors = 0
							while (!built) {
								Error("Error building new depot " + AIError.GetLastErrorString());
								Mungo.Sleep(1);
								built = AIRoad.BuildRoadDepot(depot_tile, path.GetTile());
								errors++
								if (errors>10) {
									return -1;
								}
							}
							AIRoad.BuildRoad(depot_tile, path.GetTile())
							// this.DebugSign(depot_tile, "New Depot")
						}
					}
				}
			} else {
				// Build a bridge or tunnel
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					// If it was a road tile, demolish it first. Do this to work around expended roadbits
					if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
					if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
						/* An error occured while building a tunnel. TODO: handle it. */
					}
					} else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
						bridge_list.Valuate(AIBridge.GetMaxSpeed);
						bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
							/* An error occured while building a bridge. TODO: handle it. */
						}
					}
				}
			}
		}
		path = par;
	}

	ret.append(depot_tile);
	ret.append(costs.GetCosts());
    return ret;
}

function Helper::BuildDepotForRoute(tile) {
	local list = AITileList();
	local point_towards;
	list.AddTile(tile)

	// Walk all the tiles and see if we can build the depot at all
	Mungo.Sleep(1);

	local test = AITestMode();
	{
		point_towards = tile+AIMap.GetTileIndex(0, 1);
		if (AIRoad.BuildRoadDepot(point_towards, tile) && AIRoad.BuildRoad(point_towards, tile)) {
			return point_towards;
		}

		point_towards = tile+AIMap.GetTileIndex(0, -1);
		if (AIRoad.BuildRoadDepot(point_towards, tile) && AIRoad.BuildRoad(point_towards, tile)) {
			return point_towards;
		}

		point_towards = tile+AIMap.GetTileIndex(1, 0);
		if (AIRoad.BuildRoadDepot(point_towards, tile) && AIRoad.BuildRoad(point_towards, tile)) {
			return point_towards;
		}

		point_towards = tile+AIMap.GetTileIndex(-1, 0);
		if (AIRoad.BuildRoadDepot(point_towards, tile) && AIRoad.BuildRoad(point_towards, tile)) {
			return point_towards;
		} 
	}

	return -1;
}

function Helper::RemoveNullStations() {
	local counter = 0;
	local list = AIStationList(this.STATIONTYPE);
	list.Valuate(AIBaseStation.GetLocation);

	for (local station_id = list.Begin(); list.HasNext(); station_id = list.Next()) {
		local list2 = AIVehicleList_Station(station_id);
		if (list2.Count() == 0) {
				this.SellRoute(station_id);
				counter++
				continue;
		};
	}
	return counter;
}

// TODO upgrade airports
// TODO upgrade current planes in service if they've earnt enough money
function Helper::ManageRoutes() {
	local counter = 0

	// Upgrade routes for all cargo routes we currently service
	for (local i = this.cargo_list[0]; i < cargo_list.len() ; i++) {
		local list = AIStationList(this.STATIONTYPE);
		list.Valuate(AIStation.GetCargoWaiting, this.cargo_list[i]);
		list.KeepAboveValue(250);

		for (local station_id = list.Begin(); list.HasNext(); station_id = list.Next()) {
			// Don't try to add planes when we are short on cash
			if (!this.CanAffordCheapestEngine(this.cargo_list[i])) return counter;

			local list2 = AIVehicleList_Station(station_id);
			// // No vehicles going to this station, abort and sell
			// if (list2.Count() == 0) {
			// 	this.SellRoute(station_id);
			// 	continue;
			// };

			// Do not build a new vehicle if we bought a new one in the last DISTANCE days
			local v = list2.Begin();
			list2.Valuate(AIVehicle.GetAge);
			list2.KeepBelowValue(365);
			if (list2.Count() != 0) continue;

			// Info("Upgrading " + station_id + " (" + AIStation.GetLocation(station_id) + ") for passengers");
			local engine = AIVehicle.GetEngineType(v);
			if (!AIEngine.IsValidEngine(engine)) {Error("Error selecting new engine"); return false}

			// Make sure we have enough money
			if (!HasMoney(AIEngine.GetPrice(engine))) {return counter}
			GetMoney(AIEngine.GetPrice(engine));

			local new_vehicle;

			if (this.VEHICLETYPE == AIVehicle.VT_AIR) {
				local airport_type = AIAirport.GetAirportType(this.route_1.GetValue(v))
				// local engine = this.SelectBestAircraft(airport_type, this.cargo_list[i], AITile.GetDistanceManhattanToTile(this.route_1.GetValue(v)))

				new_vehicle = AIVehicle.CloneVehicle(AIAirport.GetHangarOfAirport(AIStation.GetLocation(station_id)), v, true);
				while (!AIVehicle.IsValidVehicle(new_vehicle)) {
					Mungo.Sleep(1);
					Error("Error cloning vehicle");
					Error(AIError.GetLastErrorString());
					new_vehicle = AIVehicle.CloneVehicle(AIAirport.GetHangarOfAirport(AIStation.GetLocation(station_id)), v, true);
				}
			} else if (this.VEHICLETYPE == AIVehicle.VT_ROAD) {
				local station_name = AIBaseStation.GetName(station_id)
				station_name = split(station_name.tostring(), " ")

				new_vehicle = AIVehicle.CloneVehicle(station_name[2].tointeger(), v, true);
				while (!AIVehicle.IsValidVehicle(new_vehicle)) {
					Mungo.Sleep(1);
					Error("Error cloning vehicle");
					Error(AIError.GetLastErrorString());
					new_vehicle = AIVehicle.CloneVehicle(station_name[2].tointeger(), v, true);
				}
			}
			
			// Finalise the cloning
			this.route_1.AddItem(new_vehicle, this.route_1.GetValue(v))
			this.route_2.AddItem(new_vehicle, this.route_2.GetValue(v))

			// Comment out to check selling vehicles
			AIVehicle.StartStopVehicle(new_vehicle)
			counter++
		}
	}

	return counter;
}
function StartUp() {
	NameCompany();
	if (!CheckCargo()) {return false;}

	Mungo.air_helper = AirHelper();
}

function NameCompany() {
    // Give the boy a name
	if (!AICompany.SetName("Mungo")) {
		local i = 2;
		while (!AICompany.SetName("Mungo #" + i)) {
			i++;
		}
	}
    
    // Say hello to the user
	Info("Welcome to " + AICompany.GetName(AICompany.COMPANY_SELF));
	Info("Minimum Town Size: " + GetSetting("min_town_size"));
}

function HouseKeeping() {
    HandleEvents();
    RepayLoan();
}

function split(message, split_on) {
	local buf = "";
	local split_message = [];

	for (local i=0; i<message.len(); i++) {
		if (message[i].tochar() != split_on) {
			buf = buf + "" + message[i].tochar();
		} else {
			split_message.append(buf);
			buf = "";
		}
	}
	
	split_message.append(buf);

	return split_message
}

function TownsUsedForStationType(cargo_type) {
	local list = AIStationList(cargo_type);
	local all_towns = AITownList();
	local towns_used = AIList();

	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		for (local j = all_towns.Begin(); all_towns.HasNext(); j = all_towns.Next()) {
			if (AITown.IsWithinTownInfluence(j, i.GetLocation()))
				towns_used.Append(j);
		}
	}

	return towns_used;
}

function CheckCargo() {
	if (Mungo.passenger_cargo_id == -1) {
		Error("Cannot find passenger cargo");
	} else if (Mungo.mail_cargo_id == -1) {
		Error("Cannot find mail cargo");
	}
}

function HandleEvents() {
    while (AIEventController.IsEventWaiting()) {
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType()) {
			case AIEvent.AI_ET_VEHICLE_CRASHED: {
				local ec = AIEventVehicleCrashed.Convert(e);
				local v = ec.GetVehicleID();
				local crash_reason = ec.GetCrashReason();
				Warning("We have a crashed vehicle (" + v + ")");
				
				if (crash_reason == AIEventVehicleCrashed.CRASH_AIRCRAFT_NO_AIRPORT) {
					Info("Replacing crashed plane");
					for (local i = 0; i < this.air_helper.vehicle_array.len(); i++) {
						if (this.air_helper.vehicle_array == v) {
							this.air_helper.vehicle_array.remove(i);
							this.air_helper.BuildAircraft(this.air_helper.route_1.GetValue(v), this.air_helper.route_2.GetValue(v));
							// this.route_1.RemoveItem(v);
							// this.route_2.RemoveItem(v);
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_PLANE_LANDING) {
					Info("Replacing crashed plane");
					for (local i = 0; i < Mungo.air_helper.vehicle_array.len(); i++) {
						if (this.air_helper.vehicle_array == v) {
							this.air_helper.vehicle_array.remove(i);
							this.air_helper.BuildAircraft(this.air_helper.route_1.GetValue(v), this.air_helper.route_2.GetValue(v));
							// this.route_1.RemoveItem(v);
							// this.route_2.RemoveItem(v);
							break;
						}
					}
				} else if (crash_reason == AIEventVehicleCrashed.CRASH_RV_LEVEL_CROSSING) {
					Info("Creating new level crossing");
					break;
				}
			} break;

			default:
				break;
		}
	}
}
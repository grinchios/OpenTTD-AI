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

function HandleEvents() {
    while (AIEventController.IsEventWaiting()) {
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType()) {
			case AIEvent.AI_ET_VEHICLE_CRASHED: {
				local ec = AIEventVehicleCrashed.Convert(e);
				local v = ec.GetVehicleID();
				Info("We have a crashed vehicle (" + v + "), buying a new one as replacement");

				// removes the crashed vehicle from the vehicle array
				for (local i = 0; i < this.vehicle_array.len(); i++) {
					if (this.vehicle_array == v) {
						this.vehicle_array.remove(i);
						break
					}
				}

				this.BuildAircraft(this.route_1.GetValue(v), this.route_2.GetValue(v));
				this.route_1.RemoveItem(v);
				this.route_2.RemoveItem(v);
        
			} break;

			default:
				break;
		}
	}
}
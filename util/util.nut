// TODO 
function StartUp() {
	NameCompany();
	return true;
}

// TODO company owner picture
// TODO build HQ somewhere nice
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

// TODO improve for loop with Valuate
function TownsUsedForStationType(station_Type) {
	local list = AIStationList(station_Type);
	local all_towns = AITownList();
	local tmp_towns = all_towns
	local towns_used = AIList();

	list.Valuate(AIBaseStation.GetLocation)

	// Go through all stations we own and keep the towns the station is within
	for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
		tmp_towns.Valuate(AITown.IsWithinTownInfluence, i)
		tmp_towns.KeepValue(1);
		towns_used.AddItem(tmp_towns.Begin(), 1);
		tmp_towns = all_towns;
	}

	return towns_used;
}

function GetCargoID(cargo) {
	// Get the id of cargo
    local list = AICargoList();
	list.Valuate(AICargo.HasCargoClass, cargo)
	list.KeepValue(1);
	return list.Begin();
}

// TODO validate this works, appears to only run once
function StatuesInTowns() {
	local towns_used = TownsUsedForStationType(AIStation.STATION_AIRPORT);

	// Get 5 towns that would benefit from having a statue made
	towns_used.Valuate(AITown.HasStatue);
	towns_used.KeepValue(0);
	towns_used.Valuate(AITown.IsActionAvailable, AITown.TOWN_ACTION_BUILD_STATUE);
	towns_used.RemoveValue(0);
	towns_used.Valuate(AITown.GetLastMonthProduction, GetCargoID(AICargo.CC_PASSENGERS));
	towns_used.KeepTop(5);

	for (local i = towns_used.Begin(); towns_used.HasNext(); i = towns_used.Next()) {
		if (!HasMoney(250000)) {return;}
		if (!AITown.PerformTownAction(i, AITown.TOWN_ACTION_BUILD_STATUE)) {
			Error("Statue building failed");
		} else {
			Info("Built a super amazing statue in town: " + i);
		}
	}
}

// TODO include population into the decision
function GetBestAirport() {
	if (AIAirport.IsValidAirportType(AIAirport.AT_METROPOLITAN)) {return AIAirport.AT_METROPOLITAN}
	if (AIAirport.IsValidAirportType(AIAirport.AT_LARGE)) {return AIAirport.AT_LARGE}
	if (AIAirport.IsValidAirportType(AIAirport.AT_COMMUTER)) {return AIAirport.AT_COMMUTER}
	if (AIAirport.IsValidAirportType(AIAirport.AT_SMALL)) {return AIAirport.AT_SMALL}
}

function KeepFastest(input_list) {
	input_list.Valuate(AIEngine.GetMaxSpeed);
	local current_fastest = input_list.GetValue(input_list.Begin());
	local tmp_list = input_list;
	local element_speed = 0;
	for (local element = tmp_list.Begin(); tmp_list.HasNext(); element = tmp_list.Next()) {
		element_speed = input_list.GetValue(element);
		if (current_fastest<element_speed) {
			input_list.RemoveBelowValue(element_speed);
			current_fastest = element_speed;
			Info((1*16*256)/(74*2)*24)
		}
	}

	return input_list;
}
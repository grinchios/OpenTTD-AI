class AirHelper extends Helper {

}

function AirHelper::FindSuitableLocation(airport_type, center_tile) {
    local airport_x, airport_y, airport_rad;

	airport_x = AIAirport.GetAirportWidth(airport_type);
	airport_y = AIAirport.GetAirportHeight(airport_type);
	airport_rad = AIAirport.GetAirportCoverageRadius(airport_type);

    AIStationList(AIStation.STATION_AIRPORT);
	local town_list = AITownList();


}
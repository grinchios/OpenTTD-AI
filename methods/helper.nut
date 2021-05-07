class Helper {

};

function Helper::FindSuitableLocation(){}
function Helper::BuildNewVehicle(){}
function Helper::ManageOldRoute(){}
function Helper::BuyDepot(){}
function Helper::SellDepot(){}

function Helper::SetDepotName(station_id, limit, depot_tile) {
    local location = AIBaseStation.GetLocation(station_id);
    AIBaseStation.SetName(station_id, location + "[" + limit + "]{" + depot_tile+"}")
}
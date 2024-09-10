function CanBuildDriveThroughRoadStation(tile, station_type=AIStation.STATION_NEW)
{
	local test = AITestMode();
	if (AIRoad.IsRoadTile(tile + AIMap.GetTileIndex(0, 1)) || AIRoad.IsRoadTile(tile + AIMap.GetTileIndex(0, -1)))
	{
		if (AIRoad.BuildDriveThroughRoadStation(tile, tile + AIMap.GetTileIndex(0, 1), AIRoad.ROADVEHTYPE_BUS, station_type)) return tile + AIMap.GetTileIndex(0, 1);
	}
	else if (AIRoad.IsRoadTile(tile + AIMap.GetTileIndex(1, 0)) || AIRoad.IsRoadTile(tile + AIMap.GetTileIndex(-1, 0)))
	{
		if (AIRoad.BuildDriveThroughRoadStation(tile, tile + AIMap.GetTileIndex(1, 0), AIRoad.ROADVEHTYPE_BUS, station_type)) return tile + AIMap.GetTileIndex(1, 0);
	}

	return 0;
}
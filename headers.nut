// Constant Variables
const RESERVE_MONEY = 50000;
const INFINITY = 1000000000000;
const ERROR_LIMIT = 10;
const DEBUG = 1;

// External Imports
import("pathfinder.road", "RoadPathFinder", 4);

// External Import Reassignments


// Initial Functions


// Interal Imports
require("managers/manager.nut"); // Needs to be at the top of Internal Imports
require("util/settings.nut");
require("util/util.nut");
require("util/debug.nut");
require("util/enums.nut");
require("util/finance.nut"); // Who doesn't require money lets be honest

// Helpers
require("helpers/road_helper.nut");

// Managers
require("managers/air_manager.nut");
require("managers/road_manager.nut");
require("managers/road_town_booster_manager.nut");
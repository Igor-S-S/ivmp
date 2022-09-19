local vehicles               = {};
local createVehicle_Original = createVehicle;

function createVehicle(model, x, y, z, rx, ry, rz, c1, c2, c3, c4)
{
	local vehicleId = createVehicle_Original(model, x, y, z, rx, ry, rz, c1, c2, c3, c4);

	if(vehicleId != INVALID_VEHICLE_ID)
	{
		//log("Created a vehicle with id " + vehicleId + " (Model " + model + " (" + getVehicleName(model) + "))");
		vehicles[vehicles.len()] <- vehicleId;
	}
	return vehicleId;
}

function respawnVehicle()
{
	local zan = [];
	for(local p = 0; p < getPlayerSlots(); p++)
    {
	    if(isPlayerConnected(p)){	
	        if(isPlayerInAnyVehicle(p))
		    {
			    zan.push(getPlayerVehicleId(p));
		    }
		}
    }
	sql <- mysql("localhost", "frs", "ZHn5dvVBthH5TUjY", "frs");
	local date = sql.query_assoc("SELECT * FROM vehicles WHERE nospawn<>1");
    for (local veh = 0; veh < date.len(); veh++)
    {
		if(zan.find(veh) == null)
        {
            deleteVehicle(veh);		
            local id = createVehicle(date[veh].model.tointeger(),date[veh].x.tofloat(),date[veh].y.tofloat(),date[veh].z.tofloat(),date[veh].rx.tofloat(),date[veh].ry.tofloat(),date[veh].rz.tofloat(),checkcolor(date[veh].color1),checkcolor(date[veh].color2),checkcolor(date[veh].color3),checkcolor(date[veh].color4));
			//sql.query("UPDATE vehicles SET id = " + id + " WHERE id = " + veh);
        }
    }
	date = null;
	sql.disconnect();
	zan.clear();
}

function respawnVehicle_i(vehicleid)
{
    sql <- mysql("localhost", "frs", "ZHn5dvVBthH5TUjY", "frs");
	local vehicle = sql.query_assoc_single("SELECT * FROM vehicles WHERE id="+vehicleid);
    deleteVehicle(vehicleid);
	createVehicle(vehicle.model.tointeger(),vehicle.x.tofloat(),vehicle.y.tofloat(),vehicle.z.tofloat(),vehicle.rx.tofloat(),vehicle.ry.tofloat(),vehicle.rz.tofloat(),checkcolor(vehicle.color1),checkcolor(vehicle.color2),checkcolor(vehicle.color3),checkcolor(vehicle.color4));
	vehicle = null;
	sql.disconnect();
}

function freeVihicle(vehicleid)
{
    for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i))
		{
		    if(isPlayerInVehicle(i, vehicleid)) return false;
		}
	}
	return true;
}

function checkcolor(color){
	return ((color>=0)&&(color<=133))?color:mrand(133);
}
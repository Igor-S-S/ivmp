//foodSystemFRS.sq
local foodAction = false;


function onPlayerFoodAction(action)
{
    foodAction = action;
	return foodAction;
}
addEvent("playerFoodAction", onPlayerFoodAction);

function onKeyPress(key, status)
{
	switch(key)
	{
	    case "enter":
		    if(status == "down" && foodAction == true)
			{
			    triggerServerEvent("playerHealSystem");
			}
		break;
	}
}
addEvent("keyPress", onKeyPress);
//requstClassFRS.sq
//скрипт выбора скина
local showSkinGUIstatus = false;
local screen = guiGetScreenSize();
local headerfont = GUIFont("bankgothic", 12);
local teamOrClassis = "classis";
local teamName = array(15);
local myteam = -1;

function onShowSkinGUI(show)
{
	showSkinGUIstatus = show;
}
addEvent("showSkinGUI", onShowSkinGUI);

function onGetTeamName(id,name)
{
	teamName[id] = name;
}
addEvent("getTeamName", onGetTeamName);

function isPlayerInTeam(teamid)
{
	myteam = teamid;
}
addEvent("playerInTeam", isPlayerInTeam);

function onFrameRender()
{
	local opTeamOrClassis;
	if(teamOrClassis == "team"){ opTeamOrClassis = "[FF0000AA]Team[FFFFFFAA]: " + teamName[myteam];}
	else {opTeamOrClassis = "[FF0000AA]Classis[FFFFFFAA]: " + getPlayerModel(getLocalPlayer());}
	if(showSkinGUIstatus == true && getPlayerModel(getLocalPlayer()) != false)
	{	    
	    headerfont.drawText(screen[0]/2-80,screen[1]/2-240, opTeamOrClassis, false);
	}
}
addEvent("frameRender", onFrameRender);

function onKeyPress(key, status)
{
	switch(key)
	{
	    case "arrow_right":
		    if(status == "down" && showSkinGUIstatus == true)
			{
			    if(teamOrClassis == "team"){ triggerServerEvent("playerRequstClass", true, true);}
				else{triggerServerEvent("playerRequstClass", true, false);}
			}
		break;
		case "arrow_left":
		    if(status == "down" && showSkinGUIstatus == true)
			{
			    if(teamOrClassis == "team"){ triggerServerEvent("playerRequstClass", false, true);}
				else{triggerServerEvent("playerRequstClass", false, false);}
			}
		break;
		case "arrow_up":
		    if(status == "down" && showSkinGUIstatus == true)
			{
			    if(teamOrClassis == "team") return false;
				teamOrClassis = "team";
				if(myteam < 0) triggerServerEvent("playerRequstClass", false, true);
				myteam = 0;
			}
		break;
		case "arrow_down":
		    if(status == "down" && showSkinGUIstatus == true)
			{
			    if(teamOrClassis == "classis") return false;
				teamOrClassis = "classis";
				if(myteam >= 0) triggerServerEvent("playerRequstClass", false, false);
				myteam = -1;
			}
		break;
		case "shift":
		    if(status == "down" && showSkinGUIstatus == true)
			{
				triggerServerEvent("playerRequstClass", false, false, 1);
				showSkinGUIstatus = false;
			}
		break;
		case "f3":
		    if(status == "down" && showSkinGUIstatus == false)
			{
		        triggerServerEvent("playerRequstClass", false, false, 2);
			}
		break;
	}
}
addEvent("keyPress", onKeyPress);
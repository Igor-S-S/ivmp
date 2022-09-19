const MAX_PLAYERS = 32;
const MAX_DIATH_MESSAGE = 4;

local screen = guiGetScreenSize();
local showscoreboard = false;
local showscoreboard2 = false;
local actionWelcomMsg = true;
local a = false;
local boldfont = GUIFont("tahoma-bold");
local font = GUIFont("tahoma");
local headerfont = GUIFont("bankgothic", 12);
local welcomfount = GUIFont("MetaPro-Normal", 13);
local svrnamefount = GUIFont("EtelkaMedium", 17);
local modenamefount = GUIFont("EtelkaMedium", 15);
local afkColor = "33CCFFAA";

local SCRIPT ={}; //Все переменные скрипта
SCRIPT.deathMessage <- {};
SCRIPT.MyScore <- array(MAX_PLAYERS);
//SCRIPT.scorevewn <- array(MAX_PLAYERS);

//local MyScore = 0;
//local diadplayer = false;
SCRIPT.PlayerNameColors <- null;
SCRIPT.PlayerInTeams <- array(MAX_PLAYERS);
SCRIPT.TeamsColor <- array(15);

SCRIPT.PlayerNameColors = [
	"93AB1CFF","95BAF0FF","369976FF","18F71FFF","4B8987FF","491B9EFF","829DC7FF","BCE635FF","CEA6DFFF","20D4ADFF",
	"2D74FDFF","3C1C0DFF","12D6D4FF","48C000FF","2A51E2FF","E3AC12FF","FC42A8FF","2FC827FF","1A30BFFF","B740C2FF",
	"42ACF5FF","2FD9DEFF","FAFB71FF","05D1CDFF","C471BDFF","94436EFF","C1F7ECFF","CE79EEFF","BD1EF2FF","93B7E4FF",
	"3214AAFF","184D3BFF","AE4B99FF","7E49D7FF","4C436EFF","FA24CCFF","CE76BEFF","A04E0AFF","9F945CFF","DCDE3DFF",
	"10C9C5FF","70524DFF","0BE472FF","8A2CD7FF","6152C2FF","CF72A9FF","E59338FF","EEDC2DFF","D8C762FF","3FE65CFF",
	"FF8C13FF","C715FFFF","20B2AAFF","DC143CFF","6495EDFF","F0E68CFF","778899FF","FF1493FF","F4A460FF","EE82EEFF",
	"FFD720FF","8B4513FF","4949A0FF","148B8BFF","14FF7FFF","556B2FFF","0FD9FAFF","10DC29FF","534081FF","0495CDFF",
	"EF6CE8FF","BD34DAFF","247C1BFF","0C8E5DFF","635B03FF","CB7ED3FF","65ADEBFF","5C1ACCFF","F2F853FF","11F891FF",
	"7B39AAFF","53EB10FF","54137DFF","275222FF","F09F5BFF","3D0A4FFF","22F767FF","D63034FF","9A6980FF","DFB935FF",
	"3793FAFF","90239DFF","E9AB2FFF","AF2FF3FF","057F94FF","B98519FF","388EEAFF","028151FF","A55043FF","0DE018FF"
];

function onWelcomMsg(action)
{   
	actionWelcomMsg = action;
}
addEvent("welcomMsg", onWelcomMsg);

function OnPlayerScore(id,score=0)
{   
	SCRIPT.MyScore[id] = score;
}
addEvent("playerScore", OnPlayerScore);

function OnSendDeathMessage(killerid,playerid,reason)
{   
	local msg = "",color,color2;
	color = (SCRIPT.PlayerInTeams[playerid] >= 0)?SCRIPT.TeamsColor[SCRIPT.PlayerInTeams[playerid]]:SCRIPT.PlayerNameColors[playerid];
	if(killerid != INVALID_PLAYER_ID && killerid != playerid)
	{
	    color2 = (SCRIPT.PlayerInTeams[killerid] >= 0)?SCRIPT.TeamsColor[SCRIPT.PlayerInTeams[killerid]]:SCRIPT.PlayerNameColors[killerid];
		if(SCRIPT.deathMessage.len() < MAX_DIATH_MESSAGE)
		{
		    msg=format("[%s] %s [FF0000AA][[FFFFFFFF]%s[FF0000AA]][%s] %s",color2,getPlayerName(killerid),reason,color,getPlayerName(playerid));
			SCRIPT.deathMessage[SCRIPT.deathMessage.len()] <- msg;
		}else{
		   msg=format("[%s] %s [FF0000AA][[FFFFFFFF]%s[FF0000AA]][%s] %s",color2,getPlayerName(killerid),reason,color,getPlayerName(playerid));
		   SCRIPT.deathMessage[0] <- SCRIPT.deathMessage[1];
		   SCRIPT.deathMessage[1] <- SCRIPT.deathMessage[2];
		   SCRIPT.deathMessage[2] <- SCRIPT.deathMessage[3];
		   SCRIPT.deathMessage[3] <- msg;
		}
		SCRIPT.MyScore[playerid] = SCRIPT.MyScore[playerid] - 1;
		SCRIPT.MyScore[killerid] = SCRIPT.MyScore[killerid] + 1;
	}else{
	    if(SCRIPT.deathMessage.len() < MAX_DIATH_MESSAGE)
		{
		    msg=format("[%s]%s [FF0000AA][[FFFFFFFF]died[FF0000AA]]",color,getPlayerName(playerid));
			SCRIPT.deathMessage[SCRIPT.deathMessage.len()] <- msg;
		}else{
		    msg=format("[%s]%s [FF0000AA][[FFFFFFFF]died[FF0000AA]]",color,getPlayerName(playerid));
		    SCRIPT.deathMessage[0] <- SCRIPT.deathMessage[1];
		    SCRIPT.deathMessage[1] <- SCRIPT.deathMessage[2];
		    SCRIPT.deathMessage[2] <- SCRIPT.deathMessage[3];
		    SCRIPT.deathMessage[3] <- msg;
		}
		SCRIPT.MyScore[playerid] = SCRIPT.MyScore[playerid] - 1;
	}
}
addEvent("sendDeathMessage", OnSendDeathMessage);

function onTeamsColors(num,color)
{
    SCRIPT.TeamsColor[num] = color;
}
addEvent("teamsColors", onTeamsColors);

function onGetPlayerTeam(playerid,teamid)
{
    SCRIPT.PlayerInTeams[playerid] = teamid;
}
addEvent("getPlayerTeam", onGetPlayerTeam);

function onFrameRender()
{
	if(showscoreboard == true)
	{
		local y = screen[1]/2-240;
		guiDrawRectangle(screen[0]/2-320, y, 640.0, 15.0, 0x50505080, false);
		y = y+15;
		guiDrawRectangle(screen[0]/2-320, y, 640.0, 465.0, 0x00000080, false);
		boldfont.drawText(screen[0]/2-320+1, y,"ID", false);
		boldfont.drawText(screen[0]/2-320+50, y,"Name", false);
		boldfont.drawText(screen[0]/2-320+250, y,"Score", false);
		boldfont.drawText(screen[0]/2-320+450, y,"Ping", false);
		boldfont.drawText(screen[0]/2-320+600, y,"HP", false);
		//guiDrawRectangle(screen[0]/2-320, y, 640.0, 15.0, 0x00000080, false);
		y = y+15;
		local players = 0;
		local nameColors = (SCRIPT.PlayerInTeams[getLocalPlayer()] >= 0 && SCRIPT.PlayerInTeams[getLocalPlayer()] != 1000 && SCRIPT.PlayerInTeams[getLocalPlayer()] != 500)?SCRIPT.TeamsColor[SCRIPT.PlayerInTeams[getLocalPlayer()]]:SCRIPT.PlayerNameColors[getLocalPlayer()];
		nameColors = (SCRIPT.PlayerInTeams[getLocalPlayer()] == 1000)?"FFFFFFAA":nameColors;
		nameColors = (SCRIPT.PlayerInTeams[getLocalPlayer()] == 500)?afkColor:nameColors;
		font.drawText(screen[0]/2-320+1, y, "[" + nameColors + "]" + getLocalPlayer().tostring(), false);
		font.drawText(screen[0]/2-320+50, y, "[" + nameColors + "]" + getPlayerName(getLocalPlayer()), false);
		local myhp = getPlayerHealth(getLocalPlayer());
		myhp = (myhp < 0)?0:myhp;
		font.drawText(screen[0]/2-320+600, y, myhp.tostring(), false);
		local ping = getPlayerPing(getLocalPlayer());
		if (ping < 100) {
			font.drawText(screen[0]/2-320+450, y, "[00FF33FF]"+ping.tostring(), false);
		} else if (ping < 200){
			font.drawText(screen[0]/2-320+450, y, "[FF7D40FF]"+ping.tostring(), false);
		}else{
			font.drawText(screen[0]/2-320+450, y, "[CD0000FF]"+ping.tostring(), false);
		}
		font.drawText(screen[0]/2-320+250, y, "[" + nameColors + "]" +  SCRIPT.MyScore[getLocalPlayer()].tostring(), false);
		y = y+13;
		for(local ply = 0; ply < 32; ply++)
		{
			if(isPlayerConnected(ply) && ply != getLocalPlayer())
			{
				local nameColors = (SCRIPT.PlayerInTeams[ply] >= 0 && SCRIPT.PlayerInTeams[ply] != 1000 && SCRIPT.PlayerInTeams[ply] != 500)?SCRIPT.TeamsColor[SCRIPT.PlayerInTeams[ply]]:SCRIPT.PlayerNameColors[ply];
				nameColors = (SCRIPT.PlayerInTeams[ply] == 1000)?"FFFFFFAA":nameColors;
		        nameColors = (SCRIPT.PlayerInTeams[ply] == 500)?afkColor:nameColors;
				font.drawText(screen[0]/2-320+1, y, "[" + nameColors + "]" + ply.tostring(), false);
				font.drawText(screen[0]/2-320+50, y, "[" + nameColors + "]" + getPlayerName(ply), false);
				local ping = getPlayerPing(ply);
				if (ping < 100) {
					font.drawText(screen[0]/2-320+450, y, "[00FF33FF]"+ping.tostring(), false);
				} else if (ping < 200){
					font.drawText(screen[0]/2-320+450, y, "[FF7D40FF]"+ping.tostring(), false);
				}else{
					font.drawText(screen[0]/2-320+450, y, "[CD0000FF]"+ping.tostring(), false);
				}
				font.drawText(screen[0]/2-320+250, y, "[" + nameColors + "]" +  SCRIPT.MyScore[ply].tostring(), false);
				local hp = getPlayerHealth(ply);
				hp = (hp < 0)?0:hp;
				font.drawText(screen[0]/2-320+600, y, hp.tostring(), false);
				y = y+13;
				players++;
			}
		}
		headerfont.drawText(screen[0]/2-320+1,screen[1]/2-240, "FIRST RUS SERVER | Players online: "+(players+1).tostring(), false);
	}
	if(actionWelcomMsg)
	{
	    //welcomfount.drawText(screen[0]/2-160, screen[1]/2-85, "Добро пожаловать", false);
	}
    boldfont.drawText(0.8, 0.94, "FIRST RUS SERVER [IVMP.RU]", true);
	boldfont.drawText(0.84, 0.96, "frs.ivmp.ru:9999", true);
	boldfont.drawText(0.87, 0.02, "www.ivmp.ru", true);
	local shag;
	if(SCRIPT.deathMessage.len() > 0)
	{
	    for(local i = 0; i < SCRIPT.deathMessage.len(); i++)
        {
	        shag=format("0.0%d",i);
		    shag=(shag.tofloat())*2;
	        boldfont.drawText(0.75, 0.52+shag, SCRIPT.deathMessage[i], true);		   
        }
		//addChatMessage("Выводдддд дд!", 0x0099FFFF);
		//addChatMessage("четкак так: " + SCRIPT.deathMessage.len(), 0x0099FFFF);
	}
}
addEvent("frameRender", onFrameRender);

local pressCount=0;
function onKeyPress(key, status)
{    
	if(key == "tab")
	{
		if (status == "down")
		{
			toggleChatWindow(false);
			showscoreboard = true;
		}else{
			toggleChatWindow(true);
			showscoreboard = false;
		}
	}
	if(key == "f7")
	{	    
	    if(status == "down")
		{
		    if(pressCount == 0)
			{
			    toggleChatWindow(false);
				pressCount++;
			}else{
			    toggleChatWindow(true);
				pressCount=0;
			
			}
		}
	}
	if(key == "f8")
	{
		if (status == "down")
		{
			showscoreboard2 = true;
		}else{
			showscoreboard2 = false;
		}
	}	
}
addEvent("keyPress", onKeyPress);
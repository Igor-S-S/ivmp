//localPlayerGommands.sq
function onPlayerCommand(command)
{
    local cmd = split(command, " ");
	local cmds = cmd[0].slice(1,cmd[0].len());
	switch(cmds)
	{
	    case "help":
		    sendPlayerMessage(playerid,MODE_NANE + " v." + MODE_VERSION + " [FFFFFFAA]create by IVMP.RU_team",0xCDCDCDAA,true);
			sendPlayerMessage(playerid,"Покупка оружия /w[eaponlist] - список оружия и /b[uy] - покупка",HelpMsgColor);
			sendPlayerMessage(playerid,"Если ты обнаружил читера пиши админам используя команду /report",HelpMsgColor);
			sendPlayerMessage(playerid,"Список доступных команд /c[ommands]",HelpMsgColor);
		break;
	}
}
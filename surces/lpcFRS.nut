//localPlayerGommands.sq
function onPlayerCommand(command)
{
    local cmd = split(command, " ");
	local cmds = cmd[0].slice(1,cmd[0].len());
	switch(cmds)
	{
	    case "help":
		    sendPlayerMessage(playerid,MODE_NANE + " v." + MODE_VERSION + " [FFFFFFAA]create by IVMP.RU_team",0xCDCDCDAA,true);
			sendPlayerMessage(playerid,"������� ������ /w[eaponlist] - ������ ������ � /b[uy] - �������",HelpMsgColor);
			sendPlayerMessage(playerid,"���� �� ��������� ������ ���� ������� ��������� ������� /report",HelpMsgColor);
			sendPlayerMessage(playerid,"������ ��������� ������ /c[ommands]",HelpMsgColor);
		break;
	}
}
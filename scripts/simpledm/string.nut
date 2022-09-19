//Работа со строками
function strsplit(number,string){
    local jstr = "";
    for(local s=number; s<string.len(); s++){
	    jstr = jstr + " " + string[s];
	}
	//log("Result: " + jstr);
	return jstr;
}

function strsubs(string,n=-1,mn=0){
    local dstr = split(string, " ");
	local hstr = "";
	if(n==-1){ hstr = ""; return hstr;}
	if(mn==0){ mn=dstr.len();}
	for(local r = n; r < mn; r++){
	    hstr = hstr + " " + dstr[r];
	}
	return hstr;
}

//Кодируем имя игрока для экранирования спец. символов
function encodeName(playername)
{
    local str = playername.tolower();
	local out="";
	local ex = regexp("[a-z0-9]");
	local tmp="";
	foreach(id,val in str){		
		tmp=val.tochar();
		if(ex.match(tmp)){
		    out+=val.tochar();
		}
		else
		{
		    out+="("+val+")";
		}
		tmp="";
	}
	return out;
}

function strreplace(str, find_v, replace = "")
{
    local a,b,e;
    if(!find_v || !str){ return 0;}
	if(str.len() == find_v.len()){ return str;}
    a = str.find(find_v);
    if(a == null){ return str;}
    while(a != null){    
       b = str.slice(0,a);
       e = str.slice(a + find_v.len());
       str = b + replace + e;
       a = str.find(find_v);
    }
    return str;
}

function PrintToChat(text,playerid=INVALID_PLAYER,color=SystemMsgColor) {
	local z=date(time());
	local str;
	local m = z.min;
	local h = z.hour;
	local s = z.sec;
	/*if(m < 10) m = format("0%d",m);
	if(h < 10) h = format("0%d",h);
	if(s < 10) s = format("0%d",s);*/
	str=format("[%d:%d:%d] %s",h,m,s,text);
	if(playerid != INVALID_PLAYER_ID && isPlayerConnected(playerid))
	{
	    sendPlayerMessage(playerid,str,color);
	}
	else {
	    sendMessageToAll(str,color);
	}
}
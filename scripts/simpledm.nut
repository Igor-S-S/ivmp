dofile("scripts/mysql.nut");
dofile("scripts/simpledm/vehicle.nut");
dofile("scripts/simpledm/players.nut");
dofile("scripts/simpledm/string.nut");
dofile("scripts/simpledm/logic.nut");
dofile("scripts/simpledm/files.nut");
dofile("scripts/simpledm/hash.nut");
dofile("scripts/simpledm/function.nut");
const PrivateMsgColor = 0x00FF00AA;
const AdminChatColor  = 0xFF8000AA;
const SystemMsgColor  = 0xFFFF00AA;
const ErrorMsgColor   = 0xFF0000AA;
const HelpMsgColor    = 0x00FF00AA;
const FreezeMsgColor  = 0xFF0000AA;
const MuteMsgColor    = 0xFF0000AA;
const KickMsgColor    = 0xFF0000AA;
const BanMsgColor     = 0xFF0000AA;
const AdminSayColor   = 0x2587ceAA;
const ConnectMsgColor = 0xC0C0C0AA;
const COLOR_LIGHTBLUE = 0x33CCFFAA;

const MAX_PLAYERS     = 32;
const MAX_VEHICLES    = 500;
const MAX_CLASSIS     = 337;
const INVALID_PLAYER  = 2500;
const INVALID_VEHICLE = 5000;

//Настройки мода
const MODE_NANE            = "SimpleDM";
const MODE_VERSION         = "0.2.7";
const MODE_BONUS_TIME      = 10; //Время, между добавлениями пользователям денег (минуты)
const MODE_BONUS_MONEY     = 10; //Количество денег для добавки
const MODE_STARTMONEY      = 500; // сумма при поделючение
const MODE_KILL_GETMONEY   = 50; //за убийство
const MODE_NAME_CHECK      = 1; //Проверка имени 1-да 0-нет
const MODE_NAME_CHECK_MODE = 2; //Тип проверки 1 - a-zA-Z (пример "alex") 2- a-zA-Z0-9 (пример "clon1") 3- (a-zA-Z)_(a-zA-Z) (пример Kirill_Mahoni)
const MODE_NAME_CHECK_HELP = "Use: a-zA-Z _ ('alex' or etc. )";//Сообщение при кике за плохой ник
const MODE_HASH_TYPE       = 1; //1- Adler-32 хеш (http://ru.wikipedia.org/wiki/Adler-32), md5 хеш (http://ru.wikipedia.org/wiki/Md5)

const cdLimit     = 25.0; //лимит команды countdown (на каком растоянии от игрока видет обратный отчет)

//Файлы системы
const SysDir      = "simpledm";
const LogFile     = "simpledm.log";
const BanLogFile  = "ban.log";
const KickLogFile = "kick.log";
const MaxLogSize  = 10;

const AdminLevelToIgnorePunishment = 6;
const IdleTimeToKick = 20;
const IdleTimeToAfk = 5;
//Настройки антифлуда
const FloodInterval = 2;
const FloodLines = 3;

//Глобальные переменные
local setColor = 0; //Переключатель цвета админа
local sql = mysql("localhost", "igor", "Xc5yKqD4KW3wvNzs", "frs");

//Время и погода
local clockmode = 1;  //Переключатель
local vewnClock = 0;  //Переключатель вывода внутреигрового времени (0 - выкл, 1 - вкл)
local vewnClockPos;  //Хранит положение индикатора внутриигрового времени
local weatherMod = 1;  //Переключатель смены погоды (0 - выкл, 1 - вкл)
local blokClock = false;  //Запрет вывода внутри игрового времени

local MODE        = {}; //Все переменные мода
MODE.vhGets       <- null; //Доступные id (модели) ТС для вызова
MODE.teams        <-null;
MODE.food        <-null;
MODE.teamsClassis <-null;
local lockVehicles = [];
MODE.pl           <- array(MAX_PLAYERS); //Информация об игроке
MODE.DPColors     <- array(MAX_PLAYERS); //цвет ника по умолчанию
MODE.DPColorsForm <- array(MAX_PLAYERS);
MODE.classis      <- array(MAX_CLASSIS);
MODE.w            <- null; //Все оружия
MODE.wsell        <- null; //Все оружия доступные для покупки
MODE.wname        <- {}; //название оружия
MODE.ws           <- null;//Наборы оружия
MODE.freeColor    <- null; //Цвета для чата игроков
MODE.loc          <- null; //точки телепорта
MODE.diedMessage  <- {}; // Массив с сообщениями об смерти персонажей
MODE.weather      <- array(10); //погода
MODE.svrStartTime <- 0; //время старта сервера
MODE.vehicleCount <-0;
//Даступная погода (id)
MODE.weather = [
    [1,50,"Cолнечно"],
	[2,50,"Cолнечно"],
	[3,50,"Солнечно и ветрено"],
	[4,50,"Облачно"],
	[5,50,"Дождливо"],
	[6,50,"Дождь"],
	[7,35,"Туманно"],
	[8,40,"Гроза"],
	[9,25,"Cолнечно"],
	[10,45,"Солнечно и ветрено 2"]
];

//Конфигурации
/* Транспорт */

MODE.riservName <- array(getPlayerSlots()+1);
local h = 0;
for(h = 0; h < getPlayerSlots()+1; h++){
    MODE.riservName[h] = "FRS_Guest_" + h;
}

function searchInArray(value,i_array){
    foreach(val in i_array){
	    if(val == value) return true;
	}
	local out = value.find("FRS_Guest");
	if(out != null){
	    return true;
	}
	return false;
}

function searchInName(value){
    local out = value.find("FRS_Guest");
	return out;
}

MODE.vhGets = [
      0,2,3,6,11,12,13,15,21,23,30,31,32,34,37,39,40,46,49,51,54,55,57,60,
	  66,71,73,77,79,83,87,90,91,94,95,98,99,100,102,104,106,108,110,113,
	  121,122,123
];
	
/* Оружие */
// ["Название",(цена патронов),(boolean разрешено или нет (true|false)),(boolean необходимы патроны или нет (true|false))]
// !!!!!!!!!!!! Не удалять строки !!!!!!!!!!!!!
MODE.w=[
	["Неопределено",0,false,true],
	["Бита",0,true,false],
	["Кий",1000,true,false],
	["Нож",0,true,false],
	["Граната(ы)",200,true,true],
	["Молотов",50,true,true],
	["РПГ",0,false,true],
	["Пистолет",10,true,true],
	["десерт игл",20,true,true],
	["Винчестер",15,true,true],
	["Беретта",15,true,true],
	["УЗИ",5,true,true],
	["MP5",8,true,true],
	["Ак-47",7,true,true],
	["M4",12,true,true],
	["Снайперская винтовка",40,true,true],
	["M40A1",50,true,true],
	["Неопределено",0,false,true],
	["Неопределено",0,false,true],
	["Неопределено",0,false,true]
]
/* Оружейные наборы */
// [[Ид оружия, патроны],...]
MODE.ws=[
	[[9,29],[11,39],[14,59]],
	[[9,29],[11,39],[14,59]]
];

MODE.wname = [
      "","Бита","Кий","Нож","Граната","Молотов",
	  "РПГ","9мм","","Дазет игл","Винчестер","Беретта",
	  "УЗИ","MP5","Ак-47","M4","СнаЙп. винтовка","M40A1",
	  "","",""
];

//[id,группа,макс_патронов,цена,]
MODE.wsell = [
	[1,0,1,1500,true],//бита
	[2,0,1,2000,true],//кий
	[3,0,1,1000,true],//нож
	[7,1,500,50,false],//9мм
	[9,1,500,92,false],//дигл
	[10,2,1000,103,false],//шотган
	[11,2,1000,10000,false],//беретта
	[13,3,1000,97,false],//СМГ
	[14,4,1000,133,false],//AK-47
	[15,4,1000,140,false],//M4
	[16,5,1000,1500,false] //Снапа
];
/* Команды */
// ["Название команды",x,y,z,поворот,оружейный набор,цвет]
/*MODE.teams=[
	["Groove street",-1229.34,1853.47,6.483,0.0,0,0xFF6347AA],
	["Ballas",0.00,0.00,10.00,0.0,1,0x9ACD32AA]
];*/

MODE.loc = [
    ["Аэропорт",2615.841797,438.105255,5.298936],
	["Остров свободы",-627.462036,-842.378357,4.748219],
    ["Небоскреб",-269.885223,-100.096191,342.154694],
	["Центральный парк",-170.153061,1082.893433,6.379406],
	["Мост",47.744446,1011.675598,66.960167],
	["Бохан: Склады",909.018372, 1684.376709, 16.984806],
	["Бохан: Станция метро",741.801514,1485.461792,14.192192,8.699298],
	["Бохан: Высотка",432.989258,1391.931519,89.782082],
	["Бохан: Стадион",711.778992,1919.448364,27.072422],
	["Star Junstion",-179.634308,585.368835,126.750610]
]

/* Команды */
// ["Название команды",x,y,z,поворот,оружейный набор,цвет]
MODE.teams=[
	["Dealers",-359.795105,1785.776367,8.658103,108.261665,0,"FF6347AA",178],//Dealers
	["Hobos",-471.238739,1761.621338,8.755116,113.468262,1,"9ACD32AA",266],//Hobos
	["Medics",980.762634,1822.263916,20.590059,88.973824,0,"18e294AA",127],//Medics
	["Builders",487.006165,1272.827271,4.957572,272.208893,0,"02359EAA",60],//Builders
	["Nigga",789.766418,1644.717896,17.019138,224.069427,0,"BAE218AA",64],//Nigga
	["Jamaicans",943.967651,1545.028198,16.852964,225.875717,0,"c818e2AA",78],//Jamaicans
	["Bikers",-128.638412,1606.958130,20.531120,14.602288,0,"948A72AA",31],//Bikers
	["Cops",93.765762,1212.391968,14.737937,9.390777,0,"000099AA",173],//Cops
	["Gansters",458.276978,1736.146118,15.808690,318.443268,0,"A010F0AA",87],//Gansters
	["Street racers",79.511047,1418.550781,3.324267,145.583664,0,"30D5C8AA",194]//Street racers
];

MODE.teamsClassis = [
   [175,176,294,295,296,331,332],//Dealers
   [122,126,143,266,267],//Hobos
   [109,118,127,128,129,195],//Medics
   [60],//Builders
   [37,53,62,64,313,314,318,319],//Nigga
   [79,80,81,82,83],//Jamaicans
   [31,70,71,72,73,74,75,164],//Bikers
   [123,124,133,201,173,174,190],//Cops
   [63,65,86,87,88,89,204,309,310,311],//Gansters
   [194]//Street racers
];

MODE.classis = [
	2,2,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
	40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,
	77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,
	110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,
	138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,
	166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,
	194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,
	222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,
	250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,
	278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,
	306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,
	334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,
	362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,
	390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,
	418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433
];

MODE.DPColors = [
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
//log("Configuration completed");

//Цвет, код
MODE.freeColor = [
    ["FF0000AA","*1"],//красный
	["FF8000AA","*2"],//оранжевый
	["FFFF00AA","*3"],//желтый
	["00FF00AA","*4"],//зеленый
	["0000FFFF","*5"],//голубой
	["000099AA","*6"],//синий
	["9900FFAA","*7"]//оранжевый
];

function IdleCheck(){
	local str;
	for (local i = 0; i < getPlayerSlots(); i++){
		if (isPlayerConnected(i) && MODE.pl[i].jailsec == 0 && MODE.pl[i].ingame) {
			local pos = getPlayerCoordinates(i);
			if (pos[0] == MODE.pl[i].LastPosX && pos[1] == MODE.pl[i].LastPosY && pos[2] == MODE.pl[i].LastPosZ && getPlayerState(i) != STATE_TYPE_DISCONNECT) {
				MODE.pl[i].IdleTime++;
				if (IdleTimeToKick-1 == MODE.pl[i].IdleTime) {
					str = format("Ты бездействуешь уже %d минут! Чтобы тебя не викинули с сервера, нужно перемещатся.",MODE.pl[i].IdleTime);
					PrintToChat(str,i,ErrorMsgColor);
				}
				if (IdleTimeToKick <= MODE.pl[i].IdleTime) KickPlayer(i,"длительное бездействие");
			}
			else {
				MODE.pl[i].IdleTime = 0;
				MODE.pl[i].LastPosX = pos[0];
				MODE.pl[i].LastPosY = pos[1];
				MODE.pl[i].LastPosZ = pos[2];
			}
		}
	}
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
		//log(str);
	}
	else {
	    sendMessageToAll(str,color);
		//log(str);
	}
}

function PrintToAdmin(text)
{
    for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i) && MODE.pl[i].adminlvl)
		{
		    sendPlayerMessage(i,text,AdminChatColor, true);
		}
	}
    return 1;
}

function KickPlayer(playerid, reason, kicker = "сервером"){
	if(!isPlayerConnected(playerid) || MODE.pl[playerid].adminlvl >= AdminLevelToIgnorePunishment) return;
	local str;
	str = format("Игрок %s (id: %d) кикнут %s. Причина: %s",MODE.pl[playerid].name,playerid,kicker,reason);
	PrintToChat(str,INVALID_PLAYER_ID,KickMsgColor);
	kickPlayer(playerid, false)
}

function BanPlayer(playerid, reason, theTime = 0, banner = "сервером") {
	if (!isPlayerConnected(playerid) || MODE.pl[playerid].adminlvl >= AdminLevelToIgnorePunishment) return;
	local str;
	str = format("Игрок %s (id: %d) забанен %s. Причина: %s",MODE.pl[playerid].name,playerid,banner,reason);
	PrintToChat(str,INVALID_PLAYER_ID,BanMsgColor);
	local user_id = -1,user_Nick = MODE.pl[playerid].name, user_HDD = getPlayerSerial(playerid), user_IP = getPlayerIp(playerid), date_of_Ban = time(), term_of_ban = (theTime != 0)?(theTime*3600+time()):theTime;
	if(sql.query_affected_rows("SELECT * FROM players WHERE nick='" + MODE.pl[playerid].name + "'") > 0)
	{
	    local u_id = sql.query_assoc_single("SELECT uid FROM players WHERE nick='" + MODE.pl[playerid].name + "'");
		log("u_id.len() = " + u_id.len());
		user_id = u_id.uid;
	}
	sql.query("INSERT INTO banlist (uid,user_nick,user_ip,user_hdd,date_of_ban,term_of_ban,reason,on_ip,on_hdd,permanent) VALUES(" + user_id + ",'" + user_Nick + "','" + user_IP + "','" + user_HDD + "'," + date_of_Ban + "," + term_of_ban + ",'" + reason + "',1,1,1)");
	banPlayer(playerid, theTime);
}
	

function unMutePlayer(playerid)
{
    local i_time = time();
	if(i_time == MODE.pl[playerid].mute)
	{        
        PrintToChat("Игроку " + MODE.pl[playerid].name + " (id: " + playerid + ") разрешено писать в чат",INVALID_PLAYER,MuteMsgColor);
	    MODE.pl[playerid].mutesec = 0;
		saveplayer(playerid);
	}
	return true;
}

function unJailPlayer(playerid)
{
	local i_time = time();
	printTimer2(MODE.pl[playerid].jailsec,"~r~UnJail: ",playerid);
	if(i_time == MODE.pl[playerid].jail)
	{
	    PrintToChat("Игрок " + MODE.pl[playerid].name + " (id: " + playerid + ") освободился из тюрьмы",INVALID_PLAYER,MuteMsgColor);
	    MODE.pl[playerid].jailsec = 0;
	    setPlayerCoordinates(playerid,435.072998,1592.097412,17.352976);
		MODE.pl[playerid].freeze = false;
		saveplayer(playerid);
	}
}

function onPlayerHealSystem(playerid)
{
	if(MODE.pl[playerid].food >= 0)
	{
	    if(MODE.pl[playerid].money < MODE.food[MODE.pl[playerid].food][3]){ sendPlayerMessage(playerid,"Не достаточно денег.",ErrorMsgColor); return false;}
		local phealth = getPlayerHealth(playerid);
		if(phealth < 100)
		{
		    MODE.pl[playerid].money = MODE.pl[playerid].money - MODE.food[MODE.pl[playerid].food][3];
		    setPlayerMoney(playerid, MODE.pl[playerid].money);
		    phealth = phealth + MODE.food[MODE.pl[playerid].food][4];
			setPlayerHealth(playerid, phealth);
			sendPlayerMessage(playerid,"Спасибо за покупку!");
		}
		else
		{
		    sendPlayerMessage(playerid,"Вы сыты!",ErrorMsgColor);
		}			
	}
	else 
	{
	    sendPlayerMessage(playerid,"Необходимо быть рядом с точной общепита (автомат или забигаловка)",ErrorMsgColor); return false;
	}
}
addEvent("playerHealSystem", onPlayerHealSystem);

function loadVehicle()
{    
	local gf = sql.query_assoc("SELECT * FROM vehicles WHERE nospawn<>1");
	//log("gf.len() = " + gf.len());
	for(local i = 0; i < gf.len(); ++i)
	{
	    local id = createVehicle(gf[i].model.tointeger(),gf[i].x.tofloat(),gf[i].y.tofloat(),gf[i].z.tofloat(),gf[i].rx.tofloat(),gf[i].ry.tofloat(),gf[i].rz.tofloat(),checkcolor(gf[i].color1),checkcolor(gf[i].color2),checkcolor(gf[i].color3),checkcolor(gf[i].color4));
		MODE.vehicleCount++;
		//log("id = " + id);
		if(gf[i].lockvh == 1)
		{
		    lockVehicles.push(id);
			log("Add lock vehicle id: " + id);
		}
		sql.query("UPDATE vehicles SET id = " + id + " WHERE vid = " + gf[i].vid);
		//log("i = " + i);
	}
	gf = null;
	return true;
}

function checkLockVehicle()
{
    for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i))
		{
		    if(isPlayerInAnyVehicle(i) && lockVehicles.find(getPlayerVehicleId(i)))
			{
			    respawnVehicle_i(getPlayerVehicleId(i));
			}
		}
	}
}

function loadALL(){
	//Загрузка ТС
	loadVehicle();
}

// =====> Работа с аккаунтами <=======

//Загрузка профиля игрока
function loadplayer(playerid)
{
	setPlayerName(playerid, "FRS_Guest_" + playerid);
	MODE.pl[playerid] = {};
	MODE.pl[playerid].name <- getPlayerName(playerid)
	MODE.pl[playerid].register <- false;
	MODE.pl[playerid].pass <- "";
	MODE.pl[playerid].money <- 0;
	MODE.pl[playerid].suicides <- 0;
	MODE.pl[playerid].score <- 0;
	MODE.pl[playerid].antidb <- 0;
	MODE.pl[playerid].MaxKillsForLife <- 0;
	MODE.pl[playerid].TMaxKillsForLifeT <- 0;
	MODE.pl[playerid].IgnoreInWebList <- false;
	MODE.pl[playerid].godmode <- false;
	MODE.pl[playerid].ingame <- false;
	MODE.pl[playerid].WeaponIDs <- null;
	MODE.pl[playerid].WeaponIDs = [];
	MODE.pl[playerid].WeaponAmmos <- null;
	MODE.pl[playerid].WeaponAmmos = [];
	MODE.pl[playerid].deaths <- 0;
	MODE.pl[playerid].model <- false;
	MODE.pl[playerid].getsvh <- false;
	MODE.pl[playerid].loginerrors <- 0;
	MODE.pl[playerid].login <- false;
	MODE.pl[playerid].food <- (-1);
	MODE.pl[playerid].afk <- false;
	MODE.pl[playerid].IdleTime <- 0;
	MODE.pl[playerid].LastPosX <- 0.0;
	MODE.pl[playerid].LastPosY <- 0.0;
	MODE.pl[playerid].LastPosZ <- 0.0;
	MODE.pl[playerid].messages <- 0;
	MODE.pl[playerid].query <- (-1);
	MODE.pl[playerid].freeze <- false;
	MODE.pl[playerid].stopTimer <- 0;
	MODE.pl[playerid].sec <- 0;
	MODE.pl[playerid].TimerOut <- 0;
	MODE.pl[playerid].color <- "";
	MODE.pl[playerid].color2 <- 0; //хранит оригинальный цвет игрока при юзании /acolor
	MODE.pl[playerid].team <- (-1);
	MODE.pl[playerid].adminlvl <- 0;
	MODE.pl[playerid].jailsec <- 0;
	MODE.pl[playerid].mutesec <- 0;
	MODE.pl[playerid].mute <- null;
	MODE.pl[playerid].jail <- null;
	MODE.pl[playerid].timerout <- null;
	MODE.pl[playerid].lastmessage <- 0;
	MODE.pl[playerid].ignore <- null;
	MODE.pl[playerid].ignore =  array(getPlayerSlots()) //список игнорируемых
	local pl_reg = sql.query_assoc_single("SELECT password FROM players WHERE nick='" + MODE.pl[playerid].name + "' LIMIT 1");
	MODE.pl[playerid].register = (!pl_reg)?false:true;
	MODE.pl[playerid].pass = (pl_reg)?pl_reg.password:MODE.pl[playerid].pass;
	MODE.pl[playerid].color = MODE.DPColors[playerid];
	for(local w = 0; w < MODE.ws[0].len(); w++)
	{    
	    MODE.pl[playerid].WeaponIDs.push(MODE.ws[0][w][0]);
	    MODE.pl[playerid].WeaponAmmos.push(MODE.ws[0][w][1]);
	}
}

//Перезагрузка данных игрока
function reloadplayer(playerid)
{
    local pData = sql.query_assoc_single("SELECT * FROM players WHERE nick='" + MODE.pl[playerid].name + "'");
	MODE.pl[playerid].adminlvl = pData.adminlvl;
	MODE.pl[playerid].model = pData.model;
	MODE.pl[playerid].mutesec = pData.mute;
	MODE.pl[playerid].jailsec = pData.jail;
	MODE.pl[playerid].money = pData.money;
	MODE.pl[playerid].score = pData.score;
	MODE.pl[playerid].deaths = pData.deaths;
	MODE.pl[playerid].suicides = pData.suicides;
	MODE.pl[playerid].MaxKillsForLife = pData.MaxKillsForLife;
	pData = null;
}
//Сохранение данных игрока
function saveplayer(playerid)
{
    if(MODE.pl[playerid].login == true)
	{
	    sql.query("UPDATE players SET nick='" + MODE.pl[playerid].name + "', password='" + MODE.pl[playerid].pass + "', adminlvl=" + MODE.pl[playerid].adminlvl + ", model=" + MODE.pl[playerid].model +", mute=" + MODE.pl[playerid].mutesec +", jail=" + MODE.pl[playerid].jailsec +", money=" + MODE.pl[playerid].money +", score=" + MODE.pl[playerid].score +", deaths=" + MODE.pl[playerid].deaths +", suicides=" + MODE.pl[playerid].suicides + ", MaxKillsForLife=" + MODE.pl[playerid].MaxKillsForLife + " WHERE nick='" + MODE.pl[playerid].name + "' LIMIT 1");
	}
	//Сохранение происходит только если игрок вошел в свой аккаунт
}

//Очистка переменных игрока
function clearplayer(playerid)
{
    if(MODE.pl[playerid].getsvh) deleteVehicle(MODE.pl[playerid].getsvh);
	MODE.pl[playerid].clear();
}

//Сохраняем данные всех подключенных пользователей
function saveAllPlayers()
{
    for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i))
		{
	        saveplayer(i);
		    sendPlayerMessage(i,"Игровой процеcс сохранен.",SystemMsgColor);
		    log("Save All Complited.");
		}
	}
}

function bonus(){
	for(local i = 0; i < MAX_PLAYERS; i++)
    {	   
        if (isPlayerConnected(i))
		{
		    moneyCheck(i);
			MODE.pl[i].money+=MODE_BONUS_MONEY;
			givePlayerMoney(i,MODE_BONUS_MONEY);
		}
    }
	return 1;
}

function moneyCheck(playerid)
{
    local money = getPlayerMoney(playerid);
	if(money > MODE.pl[playerid].money)
	{
	    setPlayerMoney(playerid, MODE.pl[playerid].money);
		//log("mod_moneyChek started");
	}
}


function FloodCheck(){
    for(local i = 0; i < MAX_PLAYERS; i++)
    {
	    if (isPlayerConnected(i))
		{
		    MODE.pl[i].messages = 0;
		}
	}
}

function updateMode()
{
	local z=date(time());
	if(z.sec == 0)
	{
	    IdleCheck();
	}
	if(z.sec % 2)
	{
	    FloodCheck();
	}
	if((z.min == 0 || z.min == 30) && z.sec == 0)
	{
	    saveAllPlayers();
		respawnVehicle();
	}
	if((z.min == 0 || z.min == 15 || z.min == 30 || z.min == 45) && z.sec == 0)
	{
	    bonus();
		//setOnline();
	}
	if((z.min == 10 || z.min == 20 || z.min == 40 || z.min == 50) && z.sec == 0)
	{
	    respawnVehicle();
		//setOnline();
	}/*
	if((z.min == 5 || z.min == 25 || z.min == 35 || z.min == 55) && z.sec == 0)
	{
	    setOnline();
	}*/
	for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i))
		{
		    if(MODE.pl[i].jailsec > 0) unJailPlayer(i);
			if(MODE.pl[i].mutesec > 0) unMutePlayer(i);
			togglePlayerFrozen(i, MODE.pl[i].freeze);
			if((MODE.pl[i].freeze == true && getPlayerHealth(i) < 200) || (MODE.pl[i].godmode == true)){ setPlayerHealth(i, 200);}
		}
	}
	//checkLockVehicle();
}

//Погода
local h=0,m=0,oldWeather = 0;
function syncInGameTime()
{    
	m++;
	h = (h > 23)?0:h;
	h = (m > 59)?h+1:h;
	m = (m > 59)?0:m;	
	setTime(h,m);
	//log("InGameTime = " + h + ":" + m);
	if(vewnClock == 1)
	{
	    for(local i = 0; i < getPlayerSlots(); i++)
	    {
	        if(isPlayerConnected(i))
		    {
	            local m1 = (m < 10)?"0" + m:m;
				if(MODE.pl[i].jailsec == 0 && blokClock == false)
				{
		    	    displayPlayerText(i, 0.11,0.68, h + ":" + m1, getMinuteDuration());
				}
		    }
	    }
	}
	if(weatherMod == 1)
	{
	    if((h== 6 || h == 12 || h == 18 || h == 0) && m == 0)
	    {
	       local a = random(0,9);
	       oldWeather = getWeather();
	       timer(syncInGameWeather,(MODE.weather[a][1]+a*10)*getMinuteDuration(),1,oldWeather);
	       setWeather(MODE.weather[a][0]);
	    }
	}
}
function syncInGameWeather(oldweather)
{
    setWeather(oldweather);
	//log("old weather set");
}
function blokedClock()
{
    blokClock = false;
    return blokClock;
}

//обмен данными с клиентским скриптом
function onFreezePlayer(playerid,trg)
{
    //togglePlayerControls(playerid,trg);
	MODE.pl[playerid].freeze = trg;
}
addEvent("freezePlayer", onFreezePlayer);

function getVehicleSpeed(playerid,vehicleid)
{
    local velocity = getVehicleVelocity(getPlayerVehicleId(playerid));
    local x = velocity[0];
    local y = velocity[1];
    local v = sqrt(x*x + y*y);
    v = v*10/1.65;
    return v.tointeger();
}
addEvent("vehicleSpeed", getVehicleSpeed);

function onTheDataToClient(playerid,cmd,otherplaeyid)
{
    return MODE.pl[otherplaeyid].team;
}
addEvent("theDateToClient", onTheDataToClient);

//x,y,z,cost,hp
MODE.food = [
    [745.882996,1502.605225,27.651072,5,7,"Кола"],
	[746.073364,1474.531616,27.675053,5,7,"Кола"],
	[449.693115,1505.997437,16.320717,30,25,"Гамбургер"],
	[1109.899536,1587.275146,16.912519,30,25,"Гамбургер"],
	[487.113068,1656.390747,19.180866,13,9,"Сосиська"]
];

//старт мода
function onScriptInit()
{
	log(_version_);
	local config = getConfig();
	log("Port = " + config["port"]);
	log("---------------------");
	log(MODE_NANE + "" + MODE_VERSION + " by [IVMP.RU] team" + " loaded");
	log("---------------------");
	//log("Load Vehicle.....");
	loadALL();
	//log("Load Vehicle complited.");
	timer(updateMode,1000,-1);
	if(clockmode == 1)
	{
	    h=10;
		setTime(h,0);
	    timer(syncInGameTime,getMinuteDuration(),-1);
	}
	local z=date();
	local d2,m2,h2,min2,s2;
	d2 = (z.day < 10)?"0"+z.day:z.day;
	m2 = (z.month < 10)?"0"+z.month:z.month;
	h2 = (z.hour < 10)?"0"+z.hour:z.hour;
	min2 = (z.min < 10)?"0"+z.min:z.min;
	s2 = (z.sec < 10)?"0"+z.sec:z.sec;
	log("");
	local txt = "Mode started in: "+d2+"-"+m2+"-"+z.year+" "+h2+":"+min2+":"+s2;
	log(txt);
	log("");
	//PrintToLog("Gamemode started...");
	MODE.svrStartTime = time();
	for(local check = 0; check < MODE.food.len(); check++)
	{
	    createCheckpoint(8,MODE.food[check][0],MODE.food[check][1],MODE.food[check][2],MODE.food[check][0],MODE.food[check][1],MODE.food[check][2],0.05);
	}
	/*local actorid = createActor(111,0.0,0.0,7.0,0.0);
	setActorCoordinates (actorid, 451.321259,1503.325684,16.372467);
	setActorHeading (actorid,36.452969)*/
	//createActor(111,1112.137451,1585.217041,16.959343,42.138042);
	createActor(179,485.993927,1654.261719,19.004232,336.585083);
	return 1;
}
addEvent("scriptInit", onScriptInit);

function printTimer2(time,name,playerid)
{
	local full_sec = time*60;
	local sec1;
	local timeOut
	MODE.pl[playerid].stopTimer++;
	//MODE.pl[playerid].TimerOut
	if(MODE.pl[playerid].stopTimer < full_sec)
	{
	    if(MODE.pl[playerid].sec <= 0){
		   MODE.pl[playerid].sec = 59;
		   //time--;
		   MODE.pl[playerid].TimerOut--;
		}
		if(time < 0){ return 0;}
		sec1 = (MODE.pl[playerid].sec < 10)?"0" + MODE.pl[playerid].sec:MODE.pl[playerid].sec.tostring();
	    //timeOut = format("%s~w~%d:%s",name,(time-1),sec1);
		timeOut = format("%s~w~%d:%s",name,MODE.pl[playerid].TimerOut,sec1);
		displayPlayerText(playerid, 0.5, 0.8, timeOut, 1000);
		if(MODE.pl[playerid].sec > 0) { MODE.pl[playerid].sec--;}
	}
	else {
	    MODE.pl[playerid].stopTimer = 0;
		//MODE.pl[playerid].sec = 0;
	}
}

function onScriptExit()
{	
	//PrintToLog("Gamemode exit...");
	for(local i = 0; i < vehicles.len(); i++)
	{
		deleteVehicle(vehicles[i]);
	}
	MODE.clear();
	
	return 1;
}
addEvent("scriptExit", onScriptExit);

function onPlayerConnect(playerid)
{
    loadplayer(playerid);
	setPlayerCoordinates(playerid,-267.387268,215.439133,222.592590);	
    /*if(!checkname(MODE.pl[playerid].name))
	{
		//sendMessageToAll("[SEVER] " + MODE.pl[playerid].name + " kiked the server. Reason: Bad nickname",ErrorMsgColor);
		sendPlayerMessage("[SEVER] " + MODE.pl[playerid].name + " kiked the server. Reason: Bad nickname",ErrorMsgColor);
	    sendPlayerMessage(playerid,MODE_NAME_CHECK_HELP,ErrorMsgColor);	    
	    //timer(kickPlayer,100,1,playerid,false);
		return 0;
    }*/
	local ps = getPlayerSerial(playerid), pip = getPlayerIp(playerid);
	local gf = sql.query_affected_rows("SELECT * FROM banlist WHERE user_hdd = '" + ps + "' OR user_ip = '" + pip + "'");
	if(gf > 0)
	{
	    /*sendPlayerMessage(playerid,"You are banned on this server!",ErrorMsgColor);
	    timer(banPlayer,100,1,playerid,0);*/
		log("[BanPlayers] " + MODE.pl[playerid].name + " baned the server. Reason: bypass ban.");
		BanPlayer(playerid, "Обход бана", 0, "сервером");
		return 0;
	}	
	for(local col = 0; col < MODE.teams.len(); col++)
	{
	    triggerClientEvent(playerid,"teamsColors",col,MODE.teams[col][6]);
	}
	for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(!isPlayerConnected(i)) continue;
		triggerClientEvent(i,"playerScore",playerid,MODE.pl[playerid].score);
		if(playerid != i)
		{
		    triggerClientEvent(playerid,"playerScore",i,MODE.pl[i].score);
			triggerClientEvent(playerid,"getPlayerTeam",i,MODE.pl[i].team);
			//sendPlayerMessage(i,"[FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") подключился к серверу.",0xC0C0C0AA,true);
		}
	}
	sendPlayerMessage(playerid, "Добро пожаловать [FFFFFFAA]на [FF8000AA]FIRST RUS SERVER [FF0000AA][[FFFFFFAA]IVMP.RU[FF0000AA]]", HelpMsgColor,true);
	sendPlayerMessage(playerid, MODE_NANE + " v." + MODE_VERSION + " [FFFFFFAA]by IVMP.RU_team", HelpMsgColor,true);
	setPlayerColor(playerid,("0x" + MODE.pl[playerid].color).tointeger());
	local gf = sql.query_assoc_single("SELECT x,y,z FROM vehicles JOIN (SELECT CEIL(RAND() * (SELECT MAX(vid) FROM vehicles WHERE pspawn<>0)) AS vid) AS r2 USING (vid)");
	setPlayerCoordinates(playerid, gf.x.tofloat()+2, gf.y.tofloat()+2, gf.z.tofloat());
	//setOnline();
	/*local pData = sql.query_assoc_single("SELECT * FROM players WHERE nick='" + MODE.pl[playerid].name + "'");
	if(pData.ban == 1)
	{
	    sendPlayerMessage(playerid,"You are banned on this server!",ErrorMsgColor);
	    timer(kickPlayer,100,1,playerid,0);
	}*/
	return true;
}
addEvent("playerConnect", onPlayerConnect);

function RespawnPlayer(playerid)
{    
	if(MODE.pl[playerid].jailsec > 0)
	{
	    setPlayerCoordinates(playerid,-1075.474976,-461.862152,2.262325);
		MODE.pl[playerid].jail = MODE.pl[playerid].jailsec * 60 + time();
		MODE.pl[playerid].stopTimer=0;
		MODE.pl[playerid].sec=0;
		MODE.pl[playerid].TimerOut = MODE.pl[playerid].jailsec;
		printTimer2(MODE.pl[playerid].jailsec,"~r~UnJail: ",playerid);
		MODE.pl[playerid].freeze = true;
		return false;
	}
	if(MODE.pl[playerid].mutesec > 0)
	{
		MODE.pl[playerid].mute = MODE.pl[playerid].mutesec * 60 + time();
	}
	if(MODE.pl[playerid].team == -1){
		local gf = sql.query_assoc_single("SELECT x,y,z FROM vehicles JOIN (SELECT CEIL(RAND() * (SELECT MAX(vid) FROM vehicles WHERE pspawn<>0)) AS vid) AS r2 USING (vid)");
	    setPlayerCoordinates(playerid, gf.x.tofloat()+2, gf.y.tofloat()+2, gf.z.tofloat());
		removePlayerWeapons(playerid);
		for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){		    
            givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	    }
		return true;
	}
	if(MODE.pl[playerid].team >= 0){
		removePlayerWeapons(playerid);
		for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){		    
            givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	    }
        setPlayerCoordinates(playerid,MODE.teams[MODE.pl[playerid].team][1], MODE.teams[MODE.pl[playerid].team][2],MODE.teams[MODE.pl[playerid].team][3]);
		return true;
	}
	return false;
}

function onPlayerLogin(playerid, playerName, password, login)
{
	if(!checkname(playerName)){
	    sendPlayerMessage(playerid,"В указанном вами имени пользователя имеются запрещенные символы.",ErrorMsgColor);
		sendPlayerMessage(playerid,"Имя пользователя может состоять только из заглавных и строчных букв",HelpMsgColor);
		sendPlayerMessage(playerid,"английского алфавита, а также цифр и знака подчеркивания (пример: Alex, Alex98, Alex_125, Alex_Ivanov)",HelpMsgColor);
		sendPlayerMessage(playerid,"Использование тегов клана запрещено. Для создания клана перейдите на сайт сервера.",ErrorMsgColor);
		if(login) triggerClientEvent(playerid, "showLogin", true, true);
		else triggerClientEvent(playerid, "showLogin", true, false);
		return;
	}
	if(searchInArray(playerName,MODE.riservName)){
	    sendPlayerMessage(playerid,"ВНИМАНИЕ! Имя (" + playerName + ") под которым ты пытаешься зайти или зарегистрироваться является зарезервированным на сервере.",ErrorMsgColor);
		sendPlayerMessage(playerid,"Пожалуйста, выбери себе другое имя.",ErrorMsgColor);
		if(login) triggerClientEvent(playerid, "showLogin", true, true);
		else triggerClientEvent(playerid, "showLogin", true, false);
		return;
	}
	local pl_reg = sql.query_assoc_single("SELECT password FROM players WHERE nick='" + playerName + "' LIMIT 1");
	MODE.pl[playerid].register = (!pl_reg)?false:true;
	MODE.pl[playerid].pass = (pl_reg)?pl_reg.password:MODE.pl[playerid].pass;
	MODE.pl[playerid].name = (pl_reg)?playerName:MODE.pl[playerid].name;
	
	if(login)
	{		
		if(!MODE.pl[playerid].register){
		    sendPlayerMessage(playerid,"Игрок с именем " + playerName + " не зарегистрирован на сервере",ErrorMsgColor);
			triggerClientEvent(playerid, "showLogin", true, false);
			return;
		}
		
		if(MODE.pl[playerid].loginerrors > 3)
		{
		    triggerClientEvent(playerid, "showLogin", false, true);
			sendMessageToAll(MODE.pl[playerid].name + " kicked the server. Reason: BRUTUS DETECTED",ErrorMsgColor);
			timer(KickPlayer,100,1,playerid,"BRUTUS DETECTED");
			return 1;
		}
		if(MODE.pl[playerid].register == true && (MODE.pl[playerid].pass.tostring() == (hash(password)).tostring() || MODE.pl[playerid].pass.tostring() == (md5(password)).tostring()))
		{
			if(MODE.pl[playerid].pass.tostring() == (hash(password)).tostring())
			{
			    MODE.pl[playerid].pass = md5(password);
				sql.query("UPDATE players SET password='" + MODE.pl[playerid].pass + "' WHERE nick='" + MODE.pl[playerid].name + "' LIMIT 1");
			}
			MODE.pl[playerid].login = true;
			MODE.pl[playerid].ingame = true;
			for(local p = 0; p < getPlayerSlots(); p++)
	        {
	            if(!isPlayerConnected(p)) continue;
	            triggerClientEvent(p,"playerScore",playerid,MODE.pl[playerid].score);
	        }					
			sendPlayerMessage(playerid,"[009900AA]Пароль принят.",0xFFFFFFAA,true);
			/*sendPlayerMessage(playerid,"[0298CFAA]Для выбора персонажа и/или банды используйте клавиши управления курсором",0xFFFFFFAA,true);
			sendPlayerMessage(playerid,"[0298CFAA]Подтвердить выбор можно клавишей [FF0000AA]Shift",0xFFFFFFAA,true);*/
			reloadplayer(playerid);
			setPlayerModel(playerid, MODE.classis[MODE.pl[playerid].model]);
			for(local p = 0; p < getPlayerSlots(); p++)
			{
			    if(!isPlayerConnected(p)) continue;
				triggerClientEvent(p,"playerScore",playerid,MODE.pl[playerid].score);
			}				
			setPlayerMoney(playerid,MODE.pl[playerid].money);
			triggerClientEvent(playerid, "showLogin", false, false, true);
			//triggerClientEvent(playerid, "showSkinGUI", true);
			togglePlayerControls(playerid, true);
			MODE.pl[playerid].freeze = false;
			for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){			    
                givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	        }
			setPlayerName(playerid, MODE.pl[playerid].name);
			sendMessageToAll("[FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") присоеденился к игре.",0xC0C0C0AA,true);
			return;
		}
		else
		{
			MODE.pl[playerid].loginerrors++;
			triggerClientEvent(playerid, "alert","Ошибка","OK","Не верный пароль, еще "+(4-MODE.pl[playerid].loginerrors)+" попытки.",true);
			triggerClientEvent(playerid, "showLogin", false, true);
			return;
		}
	}
	else //игрок не зарегистрирован
	{
		if(MODE.pl[playerid].register){
		    sendPlayerMessage(playerid,"Игрок с именем " + playerName + " зарегистрирован на сервере",ErrorMsgColor);
			triggerClientEvent(playerid, "showLogin", true, true);
			return;
		}
		
		if(playerName.len() < 3){
		    sendPlayerMessage(playerid,"Логин должен состоять минимум из 3х символов.",ErrorMsgColor);
			triggerClientEvent(playerid, "showLogin", true, false);
			return;
		}
		
		if(password.len() < 6){
		    sendPlayerMessage(playerid,"Пароль не может быть короче 6 символов",ErrorMsgColor);
			triggerClientEvent(playerid, "showLogin", true, false);
			return;
		}
		MODE.pl[playerid].name = playerName;
		MODE.pl[playerid].pass=md5(password);
		MODE.pl[playerid].login=true;
		MODE.pl[playerid].register = true;
		MODE.pl[playerid].ingame = true;
		sql.query("INSERT INTO players (nick,password,lastconnecthdd,lastconnectip,lastconnecttime,regDate) VALUES('" + MODE.pl[playerid].name + "','" + MODE.pl[playerid].pass + "','" + getPlayerSerial(playerid) + "','" + getPlayerIp(playerid) + "'," + time() + "," + time() + ")");
		sendPlayerMessage(playerid,"[009900AA]Ты зарегестрировался и вошел(а).",0xFFFFFFAA,true);					
		togglePlayerControls(playerid,true);
		MODE.pl[playerid].freeze = false;
		reloadplayer(playerid);
		setPlayerName(playerid, MODE.pl[playerid].name);
		//triggerClientEvent(playerid, "showLogin", true, true);
		triggerClientEvent(playerid, "showLogin", false, false, true);
		for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){			    
            givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	    }
		sendMessageToAll("[FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") присоеденился к игре.",0xC0C0C0AA,true);
	}
}
addEvent("playerLogin", onPlayerLogin);

function onPlayerDisconnect(playerid, reason)
{    
	local strreason = "Выход";
    local str;
	strreason = (reason == 1)?"Вылет":strreason;
	for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(playerid != i && isPlayerConnected(i)) sendPlayerMessage(i,"[FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") покинул сервер (" + strreason + ").",0xFFFFFFAA,true);
	}
	saveplayer(playerid);
	clearplayer(playerid);
	return true;
}
addEvent("playerDisconnect", onPlayerDisconnect);

function onPlayerSpawn( playerid )
{
	if (!MODE.pl[playerid].login){
	    setPlayerModel(playerid, 4);
		//if(MODE.pl[playerid].register == true){			
			MODE.pl[playerid].freeze = true;
			togglePlayerControls(playerid, false);
			//sendPlayerMessage(playerid,"Этот ник зарегистрирован [FFFFFFAA]" + MODE.pl[playerid].name,ErrorMsgColor,true);
		    //sendPlayerMessage(playerid,"Если Вы являетесь владельцем аккаунта - идентифицируйтесь, используя свой пароль.",0xFFFF00AA);
		    //sendPlayerMessage(playerid,"В противном случае, выберете другой псевдоним(Ник-нейм) или свяжитесь с администратором сервера",0xFFFF00AA);
			//sendPlayerMessage(playerid,"(если вы забыли свой пароль)",0xFFFF00AA);			
			//sendPlayerMessage(playerid,"По всем вопросам связанными с сервером, а так же разбаном",ConnectMsgColor);
			//sendPlayerMessage(playerid,"обращайтесь на сайт сервера (форум): [00FF00AA]frs.ivmp.ru",ConnectMsgColor,true);
			
			//sendPlayerMessage(playerid,"Чтобы залогиниться, введите [FF0000AA]/[FFFFFFAA]login [FF0000AA]<[FFFFFFAA]пароль[FF0000AA]>[FFFF00AA].",0xFFFF00AA,true);
			
			if(getPlayerMoney(playerid) > 0) givePlayerMoney(playerid,-getPlayerMoney(playerid));
			removePlayerWeapons(playerid);
			triggerClientEvent(playerid, "showLogin", true, true);
		/*}
		else
		{*/
		    //sendPlayerMessage(playerid,"Вы не зарегистрированы! Рекомендуем зарегистрировать аккаунт.", 0xFFFF00AA);
			//sendPlayerMessage(playerid,"После регистрации вы получаете доступ к фунциям сервера, помощь /help", 0xFFFF00AA);
			//sendPlayerMessage(playerid,"У вас будет персональная статистика убийств, сохранения денег и многое другое", 0xFFFF00AA);
			
			//sendPlayerMessage(playerid,"Чтобы зарегистрировать аккаунт на этом сервера, наберите /register <пароль>.",SystemMsgColor);
			
			/*removePlayerWeapons(playerid);
			callEvent("playerLogin",playerid, "", false);
			removePlayerWeapons(playerid);*/
			/*for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){			    
                givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	        }*/
			/*MODE.pl[playerid].freeze = true;
			togglePlayerControls(playerid, false);
			triggerClientEvent(playerid, "showLogin", true, false);
			
		}*/
		
	}
	RespawnPlayer(playerid);
    return true;
}
addEvent("playerSpawn", onPlayerSpawn);

function isPlayerIgnore(playerid, targetid)
{
    if(MODE.pl[playerid].ignore == null){ return false;}
	if(MODE.pl[playerid].ignore.find(targetid)){ return true;}
	return false;
}

local Editor = 0;
local CountDown;
local CountDownNum = 0;

function countDown(playerid)
{
    CountDownNum = (CountDownNum < 0)?0:CountDownNum;
	if(CountDownNum != 0)
	{
	    CountDownNum--;
	    timer(countDown,1000,1,playerid);
	}
	if(CountDownNum == 0)
	{
        CountDown = false;
	}
	local playerpos = getPlayerCoordinates(playerid);
	local CountDownNumColor = (CountDownNum == 1)?"~r~":"~b~";
	CountDownNumColor = (CountDownNum == 2 || CountDownNum == 3)?"~g~":CountDownNumColor;
	for(local i = 0; i < getPlayerSlots(); i++){
	    if(isPlayerConnected(i))
		{
	        local otherplayerpos = getPlayerCoordinates(i);
			if(isPointInBall(playerpos[0], playerpos[1], playerpos[2], otherplayerpos[0], otherplayerpos[1], otherplayerpos[2], cdLimit))
			{			
			    if(CountDownNum == 0){ displayPlayerText(i, 0.5, 0.5, "~r~GO!", 3000);}
				else { displayPlayerText(i, 0.5, 0.5, CountDownNumColor + CountDownNum, 1000);}
			}
		}
	}
	
}

function onPlayerCommand(playerid, command)
{
	local cmd = split(command, " ");
	
	if(cmd[0]=="/help"){
	    sendPlayerMessage(playerid,MODE_NANE + " v." + MODE_VERSION + " [FFFFFFAA]create by IVMP.RU_team",0xCDCDCDAA,true);
		sendPlayerMessage(playerid,"Покупка оружия /w[eaponlist] - список оружия и /b[uy] - покупка",HelpMsgColor);
	    sendPlayerMessage(playerid,"Если ты обнаружил читера пиши админам используя команду /report",HelpMsgColor);
	    sendPlayerMessage(playerid,"Список доступных команд /c[ommands]",HelpMsgColor);
	}
	else if(cmd[0]=="/commands" || cmd[0]=="/c"){
	    sendPlayerMessage(playerid,"Доступные команды:",0xCDCDCDAA);
	    sendPlayerMessage(playerid,"Аккунант: [FF0000AA]/[FFFFFFAA]changepassword",HelpMsgColor,true);
		sendPlayerMessage(playerid,"[FF0000AA]/[FFFFFFAA]s[tats] [FF0000AA]/[FFFFFFAA]model",HelpMsgColor,true);
	    sendPlayerMessage(playerid,"Общение: [FF0000AA]/[FFFFFFAA]pm [FF0000AA]/[FFFFFFAA]hi [FF0000AA]/[FFFFFFAA]bb [FF0000AA]/[FFFFFFAA]query",HelpMsgColor,true);
		sendPlayerMessage(playerid,"[FF0000AA]/[FFFFFFAA]ignore [FF0000AA]/[FFFFFFAA]colors",HelpMsgColor,true);
		sendPlayerMessage(playerid,"Банды: [FF0000AA]/[FFFFFFAA]team [FF0000AA]/[FFFFFFAA]free",HelpMsgColor,true);
	    sendPlayerMessage(playerid,"Пакупка оружия: [FF0000AA]/[FFFFFFAA]w[eaponlist] [FF0000AA]/[FFFFFFAA]b[uy]",HelpMsgColor,true);
		sendPlayerMessage(playerid,"Транспорт: [FF0000AA]/[FFFFFFAA]carcolor",HelpMsgColor,true);
	    sendPlayerMessage(playerid,"Другие: [FF0000AA]/[FFFFFFAA]k[ill] [FF0000AA]/[FFFFFFAA]send [FF0000AA]/[FFFFFFAA]report [FF0000AA]/[FFFFFFAA]countdown",HelpMsgColor,true);
		sendPlayerMessage(playerid,"[FF0000AA]/[FFFFFFAA]time [FF0000AA]/[FFFFFFAA]afk [FF0000AA]/[FFFFFFAA]back",HelpMsgColor,true);
	}	
	
	else if(cmd[0] == "/changepassword"){
	    if(MODE.pl[playerid].pass!="" && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"[FF8000AA]FRS_Police [FFFFFFAA](id: 902): Необходимо войти в аккаунт",ErrorMsgColor,true); return 0;}
	    if(!isPlayerConnected(playerid)){ sendPlayerMessage(playerid,"Ты отключен от сервера",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].pass==""){ sendPlayerMessage(playerid,"[FF8000AA]FRS_Police [FFFFFFAA](id: 902): Ты не зарегестрирован.",ErrorMsgColor,true); return false;}
	    if(cmd.len()==3){
		    if (MODE.pl[playerid].pass.tointeger()==hash(cmd[1]) || MODE.pl[playerid].pass.tointeger()==md5(cmd[1])){
			    MODE.pl[playerid].pass=md5(cmd[2]);
				saveplayer(playerid);
				sendPlayerMessage(playerid,"Пароль успешно изменен на: [1E90FFAA]" + cmd[2],HelpMsgColor,true);				
			}
			else sendPlayerMessage(playerid,"Не верный старый пароль",ErrorMsgColor);
		}
		else sendPlayerMessage(playerid,"Используй: [FF0000AA]/[FFFFFFAA]changepassword [FF0000AA]<[FFFFFFAA]старый пароль[FF0000AA]> <[FFFFFFAA]новый пароль[FF0000AA]>",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/hi")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    local count = 0;
		if(count == 1) return 0;
		else sendMessageToAll("*** [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [00FF00AA]приветствует всех! ***",HelpMsgColor,true);
		count++;
	}
	
	else if(cmd[0] == "/bb")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    local count = 0;
		if(count == 1) return 0;
		else sendMessageToAll("*** [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [960018AA]прощается со всеми! ***",0x960018AA,true);
		count++;
	}
	
	else if(cmd[0] == "/afk")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным.",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].afk == true){ sendPlayerMessage(playerid,"Вы уже находитесь в afk. Используйте /back чтобы вновь приступить к игре.",ErrorMsgColor); return false;}
		MODE.pl[playerid].afk = true;
		MODE.pl[playerid].freeze = true;
		sendMessageToAll("*** " + MODE.pl[playerid].name + " отошел(afk).",0x33CCFFAA);
		sendPlayerMessage(playerid,"Чтобы вернутся используйте /back.",HelpMsgColor);
		for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,500);}}
	}
	
	else if(cmd[0] == "/back")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным.",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].afk == false){ sendPlayerMessage(playerid,"Вы не находитесь в afk.",ErrorMsgColor); return false;}
		MODE.pl[playerid].afk = false;
		MODE.pl[playerid].freeze = false;
		sendMessageToAll("*** " + MODE.pl[playerid].name + " вернулся.",0x33CCFFAA);
		for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,MODE.pl[playerid].team);}}
	}
	
	else if(cmd[0] == "/ignore")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(cmd.len() == 2)
		{
		    if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Использейте /ignore <id_игрока>",ErrorMsgColor); return false;}
			local id = cmd[1].tointeger();
			if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключен к серверу",ErrorMsgColor,true); return;}
		    if(isPlayerIgnore(playerid,id))
			{
			    foreach(idx, val in MODE.pl[playerid].ignore)
				{
				    if(val == id)
					{
					    MODE.pl[playerid].ignore.remove(idx);
						sendPlayerMessage(playerid,"Вы удалили " + MODE.pl[id].name + " (id: " + id + ") из своего списка игнорируемых в чате игроков.",SystemMsgColor,true);
						return true;
					}
				}
			}
			else {
			    MODE.pl[playerid].ignore.push(id);
				sendPlayerMessage(playerid,"Вы внесли " + MODE.pl[id].name + " (id: " + id + ") в свой список игнорируемых в чате игроков.",SystemMsgColor,true);
				sendPlayerMessage(playerid,"Что бы удалить игрока из списка игнорируемых повторно используйте [/ignore <id_игрока>.",0xCDCDCDAA,true);
			}
		}
	}
	else if(cmd[0] == "/colors")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    sendPlayerMessage(playerid,"Список доступных [" + MODE.freeColor[0][0] + "]ц[" + MODE.freeColor[1][0] + "]в[" + MODE.freeColor[2][0] + "]е[" + MODE.freeColor[3][0] + "]т[" + MODE.freeColor[4][0] + "]о[" + MODE.freeColor[6][0] + "]в [FFFFFFAA]для чата",0xFFFFFFFF);
	    for(local t = 0; t < MODE.freeColor.len(); t++)
		{
		    local n = t+1;
		    sendPlayerMessage(playerid,"[" + MODE.freeColor[t][0] + "]" + n + ". [FFFFFFAA]Цвет: [" + MODE.freeColor[t][0] + "]Образец[FFFFFFAA]. Код: " + MODE.freeColor[t][1],0xFFFFFFFF,true);
			
		}
		return 0;
	}
	
	else if(cmd[0] == "/stats" || cmd[0] == "/s")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    sendPlayerMessage(playerid,"Статистика " + MODE.pl[playerid].name + " (id: " + playerid + "):",SystemMsgColor);
		sendPlayerMessage(playerid,"Денег: [00AA00AA]$" + MODE.pl[playerid].money,HelpMsgColor,true);
		sendPlayerMessage(playerid,"Убийств: " + MODE.pl[playerid].score,HelpMsgColor);
		sendPlayerMessage(playerid,"Максимум убийств за жизнь: " + MODE.pl[playerid].MaxKillsForLife,HelpMsgColor);
		sendPlayerMessage(playerid,"Смертей: " + MODE.pl[playerid].deaths,HelpMsgColor);
		sendPlayerMessage(playerid,"Самоубийств: " + MODE.pl[playerid].suicides,HelpMsgColor);
		if(MODE.pl[playerid].deaths > 0) {
		    local res;
		    //local str;
		    res = MODE.pl[playerid].score.tofloat()/(MODE.pl[playerid].deaths.tofloat() + MODE.pl[playerid].suicides.tofloat());
		    //log("res1 = " + res);
		    //log("res = " + res.tofloat());
		    sendPlayerMessage(playerid,"Соотношение убийство/смерть: " + roundingoff(res),HelpMsgColor);
		}
		sendPlayerMessage(playerid,"=====================",SystemMsgColor);
	}	
	else if(cmd[0] == "/weaponlist" || cmd[0] == "/w")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    sendPlayerMessage(playerid,"Доступное оружие:",SystemMsgColor);
		MODE.tmp <- {};
		local str;
		MODE.tmp[0] <- "Ручное: ";
		str=format("%s%s(id: 0), %s(id: 1), %s(id: 2)",MODE.tmp[0],MODE.wname[1],MODE.wname[2],MODE.wname[3]);
		MODE.tmp[0]<-str;
		MODE.tmp[1] <- "Пистолеты: ";
		str=format("%s%s(id: 3), %s(id: 4)",MODE.tmp[1],MODE.wname[7],MODE.wname[9]);
		MODE.tmp[1]<-str;
		MODE.tmp[2] <- "Ружья: ";
		str=format("%s%s(id: 5), %s(id: 6)",MODE.tmp[2],MODE.wname[10],MODE.wname[11]);
		MODE.tmp[2]<-str;
		MODE.tmp[3] <- "СМГ: ";
		str=format("%s%s(id: 7)",MODE.tmp[3],MODE.wname[13]);
		MODE.tmp[3]<-str;
		MODE.tmp[4] <- "Автоматы: ";
		str=format("%s%s(id: 8), %s(id: 9)",MODE.tmp[4],MODE.wname[14],MODE.wname[15]);
		MODE.tmp[4]<-str;
		MODE.tmp[5] <- "Винтовки: ";
		str=format("%s%s(id: 10)",MODE.tmp[5],MODE.wname[16]);
		MODE.tmp[5]<-str;
		for(local i=0; i<MODE.tmp.len(); i++)
		{
		    sendPlayerMessage(playerid,MODE.tmp[i],HelpMsgColor);		
		}
		return 1;
	}
	else if(cmd[0] == "/b"|| cmd[0] == "/buy")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		local cost;
		local wid;		
		if(cmd.len() == 3)
        {
		    if(!is_int(cmd[1]) || !is_int(cmd[2])){ sendPlayerMessage(playerid,"Используйте: /buy <id_оружия> <патроны>. (Пример: " + cmd[0] + " 1 1)",ErrorMsgColor); return false;}
	        wid=cmd[1].tointeger();						
			if(wid < 0 || wid > MODE.wsell.len()-1)
			{
			    sendPlayerMessage(playerid, "Ошибочный id оружия (" + cmd[1].tointeger() + "), он не может быть отрецательным и более " + MODE.wsell.len(),0xFF0000AA,true);
				return;
			}
			cost = MODE.wsell[wid][3]*cmd[2].tointeger();
			if(getPlayerMoney(playerid) < cost)
			{
			    sendPlayerMessage(playerid, "У тебя не достаточно денег для покупки этого оружия (цена: [009900AA]$" + cost + "[FF0000AA]).",0xFF0000AA,true);
			}
			else {
			    givePlayerWeapon(playerid, MODE.wsell[wid][0], cmd[2].tointeger());
				MODE.pl[playerid].WeaponIDs.push(MODE.wsell[wid][0]);
				MODE.pl[playerid].WeaponAmmos.push(cmd[2].tointeger());
				sendPlayerMessage(playerid, "Ты купил \"" + MODE.wname[MODE.wsell[wid][0]] + "\"(id: " + cmd[1].tointeger() + ") за [009900AA]$" + cost,0xFFFF00AA,true);
				givePlayerMoney(playerid,-cost);
			}
        }
		else sendPlayerMessage(playerid,"Используй: [FF0000AA]/[FFFFFFAA]b [FF0000AA]<[FFFFFFAA]id_оружия[FF0000AA]> <[FFFFFFAA]патроны[FF0000AA]>.",ErrorMsgColor,true);		
	}	
	else if(cmd[0] == "/kill" || cmd[0] == "/k")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		setPlayerHealth(playerid, -1);
		return 1;
	}
    else if(cmd[0]=="/send")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(cmd.len()==3){
		    if(!is_int(cmd[1]) || !is_int(cmd[2])){ sendPlayerMessage(playerid,"Используйте: /send <id_оппонента> <сумма>.(Пример: /send 0 100)",0xFF0000AA); return false;}
		    if(cmd[1].tointeger() == playerid){ sendPlayerMessage(playerid,"[FF0000AA]Нельзя переводить самому себе",0xFFFFFFAA,true); return false;}
			if(!isPlayerConnected(cmd[1].tointeger())){ sendPlayerMessage(playerid,"[FF0000AA]Игрок с id " + cmd[1].tointeger() + " не подключен к серверу.",0xFFFFFFAA,true); return false;}
			if(cmd[2].tointeger() < 0){ sendPlayerMessage(playerid,"[FF0000AA]Нельзя перевести такую сумму: [009900AA]$" + cmd[2].tointeger(),0xFFFFFFAA,true); return false;}
			if(cmd[2].tointeger() > getPlayerMoney(playerid)){ sendPlayerMessage(playerid,"У тебя нет столько денег ([009900AA]$" + cmd[2].tointeger() + "[FFFFFFAA])",0xFFFFFFAA,true); return false;}
			sendPlayerMessage(playerid,"С твоего счета списано [009900AA]$" + cmd[2].tointeger() + " [FFFFFFAA]в пользу [FF0000AA]" + MODE.pl[cmd[1].tointeger()].name + " [FFFFFFAA](id: " + cmd[1].tointeger() + ").",0xFFFFFFAA,true);
			sendPlayerMessage(cmd[1].tointeger(),"На твой счет поступили средства в размере [009900AA]$" + cmd[2].tointeger() + " [FFFFFFAA]от [FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ").",0xFFFFFFAA,true);
			givePlayerMoney(playerid,-cmd[2].tointeger());
			givePlayerMoney(cmd[1].tointeger(),cmd[2].tointeger());
		}
		else sendPlayerMessage(playerid,"Используй: [FF0000AA]/[FFFFFFAA]send [FF0000AA]<[FFFFFFAA]id_оппонента[FF0000AA]> <[FFFFFFAA]сумма[FF0000AA]>[FFFFFFAA].",0xFF0000AA,true);
	}
	else if(cmd[0] == "/model" || cmd[0] == "/skin")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].team >= 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна игрокам присоеденившимся к команде.",ErrorMsgColor); return false;}
		if(cmd.len() == 2)
		{
			if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Используйте /" + cmd[0] + " <id_скина>. (Пример: /" + cmd[0] + " 4)",ErrorMsgColor);return false;}
			if(cmd[1].tointeger() <= MODE.classis.len())
			{
			    local phealth = getPlayerHealth(playerid);
				setPlayerModel(playerid, MODE.classis[cmd[1].tointeger()]);
				setPlayerHealth(playerid, phealth);
				sendPlayerMessage(playerid, "Model set to " + MODE.classis[cmd[1].tointeger()], 0xFFFFFFAA);
				MODE.pl[playerid].model<-cmd[1].tointeger();
				for(local w = 0; w < MODE.pl[playerid].WeaponIDs.len(); w++){
                    givePlayerWeapon(playerid,MODE.pl[playerid].WeaponIDs[w],MODE.pl[playerid].WeaponAmmos[w]);
	            }
			}
			else
			{
			    sendPlayerMessage(playerid,"[FF0000AA]Такого id модели (" + cmd[1] + ") не существует.",0xFFFFFFAA,true);
			}
		}

		return 1;
	}
	else if(cmd[0] == "/pm")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(cmd.len() >= 3){
		    if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Запрошенный вами id(" + cmd[1] + ") не найден.",ErrorMsgColor);return false;}
		    local id = cmd[1].tointeger();
			if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключен к серверу.",0xFF0000AA); return;}
			if(id == playerid){ sendPlayerMessage(playerid,"Нельзя отправлять ПМ самому себе.",0xFF0000AA); return;}
			sendPlayerMessage(id,"ПМ от [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + "): " + strsplit(2,cmd),PrivateMsgColor,true);
			sendPlayerMessage(playerid,"ПМ для [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + "): " + strsplit(2,cmd) + " ([55CC55AA]Доставлено[FFFFFFAA])",SystemMsgColor,true);
		}
	}
	else if(cmd[0] == "/report")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(cmd.len() >= 3){
			if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Запрошенный вами id(" + cmd[1] + ") не найден.",ErrorMsgColor);return false;}
			local id = cmd[1].tointeger();
		    if(!isPlayerConnected(id)) { sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключен к серверу.",0xFFFFFFAA); return;}
			if(id == playerid || MODE.pl[id].adminlvl > 0){ sendPlayerMessage(playerid,"Нельзя жаловаться на себя или админа",0xFF0000AA); return;}
			sendPlayerMessage(playerid," [FFFF00AA]Твоя жалоба на [FF0000AA]" + MODE.pl[id].name + " [FFFF00AA](id: " + id + ") отправлена администраторам.",0xFFFFFFAA,true);
		    PrintToAdmin(" [REPORT] Игрок " + MODE.pl[playerid].name + " (id: " + playerid + ") жалуется на " + MODE.pl[id].name + " (id: " + id + "). Жалоба: " + strsplit(2,cmd));
		}
		else sendPlayerMessage(playerid,"Используй:  [FF0000AA]/[FFFFFFAA]report [FF0000AA]<[FFFFFFAA]playerid[FF0000AA]> <[FFFFFFAA]текст[FF0000AA]>[FFFFFFAA].",0xFFFFFFAA,true);
	}
	else if(cmd[0] == "/query")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(cmd.len() == 2){
		    if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Запрошенный вами id(" + cmd[1] + ") не найден.",ErrorMsgColor);return false;}
		    local id = cmd[1].tointeger();
			if(!isPlayerConnected(id)) { sendPlayerMessage(playerid,"[FF0000AA]Игрок с id: " + id + " не подключен к серверу.",0xFFFFFFAA,true); return;}
			if(id == playerid){ sendPlayerMessage(playerid,"[FF0000AA]Эту команду нельзя применить к себе.",0xFFFFFFAA,true); return;}
			MODE.pl[playerid].query = id;
			sendPlayerMessage(playerid,"Теперь ты можешь писать ПМ для [FF0000AA]" + MODE.pl[id].name + " [FFFF00AA](id: " + id + ") используя \"[FF0000AA]![FFFF00AA]\" перед текстом.",0xFFFF00AA,true);
		}
		return 1;
	}
	else if(cmd[0] == "/time")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(cmd.len() == 1){
		    local z=date(time());
			local str,h,m,hl,ml;
			h = z.hour;
			m = z.min;
			hl = (h < 10)?"0" + h:h.tostring();
			ml = (m < 10)?"0" + m:m.tostring();
		    str=format("~g~Time: ~w~%s~r~:~w~%s",hl,ml);
			displayPlayerText(playerid, 0.8, 0.8, str, 3000);
		}
		else return false;

		return 1;
	}
	
	else if(cmd[0] == "/team")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].team != -1){ sendPlayerMessage(playerid,"Ты уже состоишь в команде " + MODE.teams[MODE.pl[playerid].team][0] + ". Чтобы сменить команду сначало нужно выйти иэ этой (/free).",ErrorMsgColor); return false;}
	    if(cmd.len() == 2){
			local health = getPlayerHealth(playerid);
		    if(cmd[1] == "info" || cmd[1] == "help"){
			    sendPlayerMessage(playerid,"Информация о доступных группировках:",HelpMsgColor);
				sendPlayerMessage(playerid,"Dealers (Нарко дилеры) id 0, оружие: Дигл(70) / Ак-47(250) / Ружьё(50)",ConnectMsgColor);
				sendPlayerMessage(playerid,"Hobos (Бомжи) id 1, оружие: Дигл(70) / Ак-47(250) / Ружьё(50)",ConnectMsgColor);
			}
			else if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Не действительный параметр: " + cmd[1] + "; допустимые значения: info,help и id команд 0-" + (MODE.teams.len()-1) + ".",ErrorMsgColor);return false;}			
			else if(cmd[1].tointeger() < 0 || cmd[1].tointeger() > (MODE.teams.len() - 1)){sendPlayerMessage(playerid,"Используйте: [FF0000AA]/[FFFFFFAA]team [FF0000AA]<[FFFFFFAA]info[FF0000AA]> [FFFFFFAA]- чтоб посмотреть список банд",ErrorMsgColor);return false;}
			else if(MODE.pl[playerid].team == -1 || MODE.pl[playerid].team != cmd[1].tointeger()){
			    MODE.pl[playerid].team = cmd[1].tointeger();
				setPlayerModel(playerid,MODE.teams[MODE.pl[playerid].team][7]);
				for(local w = 0; w < MODE.ws[MODE.teams[MODE.pl[playerid].team][5]].len(); w++){
				    givePlayerWeapon(playerid,MODE.ws[MODE.teams[MODE.pl[playerid].team][5]][w][0],MODE.ws[MODE.teams[MODE.pl[playerid].team][5]][w][1]);
				}
				local color = "0x" + MODE.teams[MODE.pl[playerid].team][6];
				setPlayerHealth(playerid, health);
				setPlayerColor(playerid,color.tointeger());
				//setPlayerCoordinates(playerid, MODE.teams[MODE.pl[playerid].team][1],MODE.teams[MODE.pl[playerid].team][2],MODE.teams[MODE.pl[playerid].team][3]);
				sendPlayerMessage(playerid,"Ты присоеденился к команде [FF0000AA]" + MODE.teams[MODE.pl[playerid].team][0] + "[FFFFFFAA]. Исользуй \"[FF0000AA]/[FFFFFFAA]free\" чтобы вернуться в свободный режим.",0xFFFFFFAA,true);
				//sendPlayerMessage(playerid,"Используй \"[FF0000AA]/[FFFFFFAA]free\" чтобы вернуться в свободный режим.",0xFFFFFFAA,true);
				for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p) && p != playerid){ sendPlayerMessage(p,"[FF0000AA]" + MODE.pl[playerid].name + " [C0C0C0AA](id: " + playerid + ") присоеденился к команде [009900AA]" + MODE.teams[MODE.pl[playerid].team][0] + ".",0xFFFFFFAA,true);}}
				displayPlayerText(playerid, 0.5, 0.9, "~r~Team: ~w~" + MODE.teams[MODE.pl[playerid].team][0], 6000);
				for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,MODE.pl[playerid].team);}}
				return MODE.pl[playerid].team;
			}
			else sendPlayerMessage(playerid,"[FF0000AA]Ошибка: Вы уже присоеденились к этой банде.",0xFFFFFFAA,true);
	    }
		else sendPlayerMessage(playerid,"Используй: [FF0000AA]/[FFFFFFAA]team [FF0000AA]<[FFFFFFAA]info[FF0000AA]> [FFFFFFAA]- чтоб посмотреть список банд, или [FF0000AA]/[FFFFFFAA]team [FF0000AA]<[FFFFFFAA]id[FF0000AA]> [FFFFFFAA]что б присоедениться.",0xFFFFFFAA,true);
	}
	
	else if(cmd[0]=="/free")
	{
	    if(MODE.pl[playerid].register && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return false;}
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(MODE.pl[playerid].team == -1){ sendPlayerMessage(playerid,"Ты не состоишь в банде.",0xFF0000AA,true); return false;}
		sendPlayerMessage(playerid,"Ты выйдишь из банды после очередного спавна.",0xFFFF00AA,true);
		MODE.pl[playerid].team = -1;
		setPlayerColor(playerid,("0x" + MODE.DPColors[playerid]).tointeger());
		for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,MODE.pl[playerid].team);}}
	    return MODE.pl[playerid].team;
	}
	
	else if(cmd[0]=="/countdown"){
	    if(MODE.pl[playerid].jailsec > 0){ sendPlayerMessage(playerid,"Команда " + cmd[0] + " не доступна заключенным",ErrorMsgColor); return false;}
		if(CountDown){ sendPlayerMessage(playerid,"Обратный отчет уже запущен.",ErrorMsgColor); return;}
		CountDown = true;
		local id = (MODE.pl[playerid].adminlvl > 0 && cmd.len() == 2 && is_int(cmd[1]))?(cmd[1].tointeger()):playerid;
		local playerpos = getPlayerCoordinates(id);
		for(local i = 0; i < getPlayerSlots(); i++){
		    if(isPlayerConnected(i))
			{
		        local otherplayerpos = getPlayerCoordinates(i);
				if(isPointInBall(playerpos[0], playerpos[1], playerpos[2], otherplayerpos[0], otherplayerpos[1], otherplayerpos[2], cdLimit))
				{			
				    displayPlayerText(i, 0.5, 0.5, "~r~READY!", 1000);
				}
			}
		}
		CountDownNum = 6;
		timer(countDown,1000,1,id);
		return 1;
	}
	
	else if(cmd[0] == "/carcolor")
	{
	    if(!isPlayerInAnyVehicle(playerid)){ PrintToChat("Нужно находиться в ТС, чтобы красить его.",playerid,ErrorMsgColor); return false;}
		if(cmd.len() >= 2 && cmd.len() <= 5){
		    for(local i = 1; i<cmd.len();i++){
		        //log("cmd[" + i + "]");
				if(!is_int(cmd[i])){return false;}
		        if(cmd[i].tointeger()<0 || cmd[i].tointeger() > 133){
		            return false;
		        }
		    }
		    local ca=0; local cb=0; local cc=0; local cd=0; ca = cmd[1].tointeger();
		    if(cmd.len() == 2){ cb=cc=cd=ca;}
		    else if(cmd.len() == 3){ cc=cd=ca; cb=cmd[2].tointeger();}
		    else if(cmd.len() == 4){ cd=ca; cb=cmd[2].tointeger(); cc=cmd[3].tointeger();}
		    else { cb=cmd[2].tointeger(); cc=cmd[3].tointeger(); cd=cmd[4].tointeger();}
		    setVehicleColor(getPlayerVehicleId(playerid),ca,cb,cc,cd);
		    sendPlayerMessage(playerid,"Цвет сменен",SystemMsgColor);
		}
		else PrintToChat("Используй: /carcolor <цвет1> <цвет2> <цвет3> <цвет4>",playerid,ErrorMsgColor);		
	}
	
	//админка
	else if(cmd[0]=="/ahelp")
	{
	    if(MODE.pl[playerid].adminlvl > 0)
		{
		    sendPlayerMessage(playerid,"[FF0000AA]Меню админа [FFFFFFFF]" + MODE.pl[playerid].adminlvl + " [FF0000AA]уровня:",0xFFFFFFAA,true);
			sendPlayerMessage(playerid,"[CCCCCCAA]/ahelp /acolor /mute /unmute",0xFFFFFFAA,true);
		}
		if(MODE.pl[playerid].adminlvl > 1){ sendPlayerMessage(playerid,"[CCCCCCAA]/jail /unjail /vr /flip /slap",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 2){ sendPlayerMessage(playerid,"[CCCCCCAA]/kick /say /settime /weather /freeze /unfreeze",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 3){ sendPlayerMessage(playerid,"[CCCCCCAA]/ban /goto /gethere /out",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 5){ sendPlayerMessage(playerid,"[CCCCCCAA]/v /hall /h",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 6){ sendPlayerMessage(playerid,"[CCCCCCAA]/rape /anounce",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 7){ sendPlayerMessage(playerid,"[CCCCCCAA]/desarm /readpm ",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 8){ sendPlayerMessage(playerid,"[CCCCCCAA]/money /setmoney /resetmoney",0xFFFFFFAA,true);}
		if(MODE.pl[playerid].adminlvl > 9){ sendPlayerMessage(playerid,"[CCCCCCAA]/alevel /vh /gm /saveall",0xFFFFFFAA,true);}
	}
	
	else if(cmd[0] == "/acolor")
	{
	    if(MODE.pl[playerid].adminlvl > 0)
		{
		if(MODE.pl[playerid].jailsec > 0)
	    {
		    sendPlayerMessage(playerid,"Вы не можите использовать эту команду находясь в тюрьме",0xFF0000AA);
			return;
		}
		if(setColor == 0)
		{
		    setColor = 1;
		    MODE.pl[playerid].color2 = getPlayerColor(playerid);
		    setPlayerColor(playerid, 0xFFFFFFAA);
			MODE.pl[playerid].color <- "FFFFFFAA";
		    sendPlayerMessage(playerid,"Ты вступили в тиму админов",0x00FF00AA);
			for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,1000);}}
		}
		else
		{
		    setColor = 0;
			MODE.pl[playerid].color<-MODE.DPColorsForm[playerid];
		    setPlayerColor(playerid, MODE.pl[playerid].color2);
		    sendPlayerMessage(playerid,"Ты вышел из тимы админов",0x00FF00AA);
			for(local p = 0; p < getPlayerSlots(); p++){ if(isPlayerConnected(p)){ triggerClientEvent(p,"getPlayerTeam",playerid,MODE.pl[playerid].team);}}
		}
		}
		return 1;		
	}
	else if(cmd[0] == "/say")
	{
	   	if(MODE.pl[playerid].adminlvl > 0)
		{
		    if(cmd.len() >= 2)
		    {
	    	    sendMessageToAll("Admin " + MODE.pl[playerid].name + " (id: " + playerid + "): " + strsplit(1,cmd),AdminSayColor);
		    }
		    else { sendPlayerMessage(playerid,"Используйте: /[FFFFFFAA]say [FF0000AA]<[FFFFFFAA]text[FF0000AA]>",0xFF0000AA,true); return 1;}
		}
	}
	
	else if(cmd[0] == "/mute")
	{
	    if(MODE.pl[playerid].adminlvl > 0){
		    if(cmd.len() >= 3)
		    {
				if(!is_int(cmd[1]) || !is_int(cmd[2])){ PrintToChat("Используй /mute <id> <время> <Причина>.",playerid,ErrorMsgColor); return 0;}
				local reason = "";
			    local id = cmd[1].tointeger();
				if(MODE.pl[id].pass!="" && !MODE.pl[id].login){ sendPlayerMessage(playerid,"Игрок [FF0000AA]" + MODE.pl[id].name + "[FFFFFFAA] (id: " + id + ") не вошел в свой аккаунт.",0xFFFFFFAA,true); return 0;}
				local mutetime = cmd[2].tointeger();
			    if(mutetime < 0){ PrintToChat("Время мута не может быть меньше 0.",playerid,ErrorMsgColor); return 0;}
				if(!isPlayerConnected(id)){ PrintToChat("Игрок с id " + id + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
				//if(id == playerid){ PrintToChat("Ты не можешь запретить писать в чат самому себе.",playerid,ErrorMsgColor); return 0;}
				if(MODE.pl[id].adminlvl > MODE.pl[playerid].adminlvl){ PrintToChat("Ты не можешь запретить писать в чат администратору " + MODE.pl[id] + " (id: " + id + ").",playerid,ErrorMsgColor); return 0;}
				if(cmd.len() > 3){ reason = format(" Причина: %s",strsplit(3,cmd));}
				if(mutetime == 0 || mutetime < 0){ mutetime = 1;}
				//if(MODE.pl[id].mutesec > 0 && MODE.pl[id].mute.isActive()) { MODE.pl[id].mute.kill();}
				PrintToChat("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") запретил писать в чат " + MODE.pl[id].name + " (id: " + id + ") на " + mutetime + "мин." + reason,INVALID_PLAYER,MuteMsgColor);
				MODE.pl[id].mutesec = MODE.pl[id].mutesec + mutetime;
				MODE.pl[id].mute = MODE.pl[id].mutesec * 60 + time();
				saveplayer(id);
		    }
			else { PrintToChat("Используй /mute <id> <время> <Причина>.",playerid,ErrorMsgColor); return 0;}
        }
		return 1;
	}
	
	else if(cmd[0] == "/unmute")
	{
	    if(MODE.pl[playerid].adminlvl > 0){
		    if(cmd.len() >= 2)
		    {
				if(!is_int(cmd[1])){ PrintToChat("Используй /unmute <id> <Причина>.",playerid,ErrorMsgColor); return 0;}
				local reason = "";
			    local id = cmd[1].tointeger();
			    if(!isPlayerConnected(id)){ PrintToChat("Игрок с id " + id + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
				//if(id == playerid && MODE.pl[playerid].adminlvl < 9){ PrintToChat("Ты не можешь выпустить себя.",playerid,ErrorMsgColor); return 0;}
				if(MODE.pl[id].mutesec == 0){ PrintToChat("Игрок " + MODE.pl[id].name + " (id: " + id + ") и так может писать в чат.",playerid,ErrorMsgColor); return 0;}
				if(cmd.len() > 2){
				    reason = format(" Причина: %s",strsplit(2,cmd));
				}
				PrintToChat("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") разрешил писать в чат " + MODE.pl[id].name + " (id: " + id + ")." + reason,INVALID_PLAYER,MuteMsgColor);
				//if(MODE.pl[id].mutesec > 0 && MODE.pl[id].mute.isActive()) { MODE.pl[id].mute.kill();}
				MODE.pl[id].mute = 0;
				MODE.pl[id].mutesec = 0;
				saveplayer(id);
		    }
			else { PrintToChat("Используй /unmute <id> <Причина>.",playerid,ErrorMsgColor); return 0;}
        }
		return 1;
	}
	
	else if(cmd[0] == "/jail")
	{
	    if(MODE.pl[playerid].adminlvl > 1){
		    if(cmd.len() >= 3)
		    {
			    if(!is_int(cmd[1]) || !is_int(cmd[2])){ sendPlayerMessage(playerid,"Используй /jail <id> <время> <Причина>.",ErrorMsgColor); return 0;}
				local id = cmd[1].tointeger();
				if(MODE.pl[id].pass!="" && !MODE.pl[id].login){ sendPlayerMessage(playerid,"Игрок [FF0000AA]" + MODE.pl[id].name + "[FFFFFFAA] (id: " + id + ") не вошел в свой аккаунт.",0xFFFFFFAA,true); return 0;}
				local reason = "";
				local jailtime = cmd[2].tointeger();
				if(jailtime < 0){ PrintToChat("Время заключения не может быть меньше 0.",playerid,ErrorMsgColor); return 0;}
			    if(!isPlayerConnected(id)){ PrintToChat("Игрок с id " + id + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
				if(MODE.pl[id].adminlvl > MODE.pl[playerid].adminlvl){ PrintToChat("Ты не можешь посадить в тюрьму администратора " + MODE.pl[id] + " (id: " + id + ").",playerid,ErrorMsgColor); return 0;}
				if(cmd.len() > 3){ reason = format(" Причина: %s",strsplit(3,cmd));}
				if(jailtime == 0){ jailtime = 1;}
				MODE.pl[id].stopTimer=0;
		        MODE.pl[id].sec=0;
				MODE.pl[id].jailsec = MODE.pl[id].jailsec + jailtime;
				PrintToChat("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") посадил в тюрьму " + MODE.pl[id].name + " (id: " + id + ") на " + MODE.pl[id].jailsec + "мин." + reason,INVALID_PLAYER,MuteMsgColor);
				setPlayerCoordinates(id,-1075.474976,-461.862152,2.262325);				
				MODE.pl[id].jail = MODE.pl[id].jailsec * 60 + time();
		        MODE.pl[playerid].TimerOut = MODE.pl[id].jailsec;
				printTimer2(MODE.pl[id].jailsec,"~r~UnJail: ",id);
				MODE.pl[id].freeze = true;
				saveplayer(id);
		    }
			else { sendPlayerMessage(playerid,"Используй /jail <id> <время> <Причина>.",ErrorMsgColor); return 0;}
        }
		return 1;
	}
	
	else if(cmd[0] == "/unjail")
	{
	    if(MODE.pl[playerid].pass!="" && !MODE.pl[playerid].login){ sendPlayerMessage(playerid,"Необходимо войти в аккаунт",ErrorMsgColor); return 0;}
	    if(MODE.pl[playerid].adminlvl > 1){
		    if(cmd.len() >= 2)
		    {
			    if(!is_int(cmd[1])){ PrintToChat("Используй /unjail <id> <Причина>.",playerid,ErrorMsgColor); return 0;}
				local id = cmd[1].tointeger();
				local reason = "";
			    if(!isPlayerConnected(id)){ PrintToChat("Игрок с id " + id + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
				if(MODE.pl[id].jailsec == 0){ PrintToChat("Игрок " + MODE.pl[id].name + " (id: " + id + ") находится на свободе.",playerid,ErrorMsgColor); return 0;}
				if(cmd.len() > 2){
				    reason = format(" Причина: %s",strsplit(2,cmd));
				}
				PrintToChat("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") выпустил из тюрьмы " + MODE.pl[id].name + " (id: " + id + ")." + reason,INVALID_PLAYER,MuteMsgColor);
				MODE.pl[id].jailsec = 0;
				setPlayerCoordinates(id,435.072998,1592.097412,17.352976);
				MODE.pl[id].jail = 0;
		        MODE.pl[id].stopTimer = 0;
		        MODE.pl[id].sec = 0;
				MODE.pl[playerid].TimerOut = 0;
				MODE.pl[id].freeze = false;
				saveplayer(id);
		    }
			else { PrintToChat("Используй /unjail <id> <Причина>.",playerid,ErrorMsgColor); return 0;}
        }
		return 1;
	}
	
	else if(cmd[0] == "/delete" || cmd[0] == "/del")
	{
		if(MODE.pl[playerid].adminlvl > 1){
	    	for(local t = 0; t < 44; t++)
			{
			    sendMessageToAll(" ",0xFFFFFFFF);
			}
			sendMessageToAll("Admin " + MODE.pl[playerid].name + " (id: " + playerid + ") очистил чат...",0xFFFF00AA);
			return 1;
		}
	}
	
	else if(cmd[0] == "/vr")
	{
	    if(MODE.pl[playerid].adminlvl > 1){
		    if(cmd.len() == 1){
			    if(isPlayerInAnyVehicle(playerid)){
				    setVehicleEngineHealth(getPlayerVehicleId(playerid), 1000);
					PrintToChat("Ты отремонтировал свое авто.",playerid);
					PrintToAdmin("[ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") отремонтировал свое авто.");
				}
				else{ PrintToChat("Для того чтобы отремонтировать ТС нужно находится в нем.",playerid,ErrorMsgColor); return 0;}
		    }
			else{ PrintToChat("Используй \"/vr\" чтоб отремантировать свое авто.",playerid,ErrorMsgColor); return 0;}
		}
		return 1;
	}
	
	else if(cmd[0] == "/freeze")
	{
	    if(MODE.pl[playerid].adminlvl > 2){
		    if(cmd.len() == 2)
			{
			    if(!is_int(cmd[1])){sendPlayerMessage(playerid,"Используй: /[FFFFFFAA]freeze [FF0000AA]<[FFFFFFAA]id[FF0000AA]>",0xFF0000AA,true); return 0;}
				local id = cmd[1].tointeger();
			    if(!isPlayerConnected(id)){ sendPlayerMessage("Игрок с id " + id + " не подключен к серверу.",playerid,0xFF0000AA); return 0;}
				//if(id == playerid || MODE.pl[playerid].admin == true){ sendPlayerMessage(playerid,"Вы не можите заморозить себя или админа.",0xFF0000AA); return 0;}
				MODE.pl[id].freeze = true;
				sendMessageToAll("Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FF0000AA]заморозил [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ")[FF0000AA].",0xFF0000AA,true);
			
			}
			else sendPlayerMessage(playerid,"Используй: /[FFFFFFAA]freeze [FF0000AA]<[FFFFFFAA]id[FF0000AA]>",0xFF0000AA,true); return 0;
		} else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true); return 0;
	}
		
	else if(cmd[0] == "/unfreeze")
	{
		if(MODE.pl[playerid].adminlvl > 2){
		    if(cmd.len() == 2)
			{
			    if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Используйте: /[FFFFFFAA]unfreeze [FF0000AA]<[FFFFFFAA]id[FF0000AA]>",0xFF0000AA,true); return 0;}
				local id = cmd[1].tointeger();
				if(MODE.pl[id].jailsec > 0){ sendPlayerMessage(playerid,"Нельзя разморозить заключенного.",ErrorMsgColor); return false;}
			    if(!isPlayerConnected(id)){ sendPlayerMessage("Игрок с id " + id + " не подключен к серверу.",playerid,0xFF0000AA); return 0;}
				if(id == playerid){ sendPlayerMessage(playerid,"Вы не можите разморозить себя.",0xFF0000AA); return 0;}
				//togglePlayerControls(id, true);
				MODE.pl[id].freeze = false;
				sendMessageToAll("Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FF0000AA]разморозил [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ")[FF0000AA].",0xFF0000AA,true);
			
			}
			else sendPlayerMessage(playerid,"Используйте: /[FFFFFFAA]unfreeze [FF0000AA]<[FFFFFFAA]id[FF0000AA]>",0xFF0000AA,true); return 0;
		} else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true); return 0;
	}
	   
	else if(cmd[0] == "/kick")
	{
	   if(MODE.pl[playerid].adminlvl > 2)
		{
		    if(cmd.len() >= 3)
		    {
		        local str;
				if(!is_int(cmd[1])){ PrintToChat("Чтобы выкинуть игрока из игры используй \"/kick id <причина>\"",playerid,ErrorMsgColor);}
		        if(!isPlayerConnected(cmd[1].tointeger())){ PrintToChat("Игрок с id " + cmd[1].tointeger() + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
			    else {
			        str = format("Администратор %s (id: %d) выкинул %s (id: %d) из игры. Причина: %s",MODE.pl[playerid].name,playerid,MODE.pl[cmd[1].tointeger()].name,cmd[1].tointeger(),strsplit(2,cmd));
                    for(local i=0; i<getPlayerSlots(); i++)
					{
			            if(isPlayerConnected(i)){
				            PrintToChat(str,i,KickMsgColor);
					    }
                    }
					timer(kickPlayer,100,1,cmd[1].tointeger(),false);
		            //return kickPlayer(cmd[1].tointeger(), false);
			    }
		    }		
		    else { PrintToChat("Чтобы выкинуть игрока из игры используй \"/kick id <причина>\"",playerid,ErrorMsgColor);}
		}
	}
	
	else if(cmd[0] == "/settime")
	{
	    if(MODE.pl[playerid].adminlvl > 2)
		{
	        if(cmd.len() == 2){
			    if(!is_int(cmd[1])){ PrintToChat("Используй /settime <time>",playerid,ErrorMsgColor); return 0;}
		        local time = cmd[1].tointeger();
			    for(local i = 0; i < getPlayerSlots(); i++)
			    {
			        if(isPlayerConnected(i))
				    {
		                setTime(time,m);
						h = time;
						m = 0;
					    sendPlayerMessage(i,"Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") изменил игровое время на " + time + ":00.",0xFFFF00AA,true);
				    }
			    }
		    }
		    else { PrintToChat("Используй /settime <time>",playerid,ErrorMsgColor); return 0;}
		}
	}
	
	else if(cmd[0] == "/weather")
	{
	    if(MODE.pl[playerid].adminlvl > 2)
		{
	        if(cmd.len() == 2){		        
				if(!is_int(cmd[1])){ sendPlayerMessage(playerid,"Не верный id погоды, допустимо целое число от 0 до 9",ErrorMsgColor); return 0;}
				local weather_id = cmd[1].tointeger();
				if(weather_id < 0 || weather_id > 9){ sendPlayerMessage(playerid,"Не верный id погоды, допустимо целое число от 0 до 9",ErrorMsgColor); return 0;}
			    setWeather(weather_id);
				sendMessageToAll("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") изменил погоду в игре на " + MODE.weather[weather_id][2] + ".",0xFFFF00AA);
			}
		    else
			{
			    sendPlayerMessage(playerid,"Используй /weather <weather_id>, где weather_id целое число от 0 до 9",ErrorMsgColor);
				local str = ""; for(local i = 0; i < MODE.weather.len(); i++){ str += MODE.weather[i][2] + "(" + i + ")";}
				sendPlayerMessage(playerid,str,ConnectMsgColor);
				return 0;
			}
		}
	}
	
	else if(cmd[0] == "/flip")
	{
	    if(MODE.pl[playerid].adminlvl > 2)
		{
		    if(isPlayerInAnyVehicle(playerid))
	    	{
			    local rot = getVehicleRotation(getPlayerVehicleId(playerid));
				local pos = getVehicleCoordinates(getPlayerVehicleId(playerid));
				setVehicleCoordinates(getPlayerVehicleId(playerid), pos[0], pos[1], pos[2]+2);
				setVehicleRotation(getPlayerVehicleId(playerid), rot[0], rot[1]-180, rot[2]);
	    		for(local i = 0; i < getPlayerSlots(); i++){ if(isPlayerConnected(i) && MODE.pl[i].adminlvl > 0){ sendPlayerMessage(i, "[ADMIN] [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + "): перевернул свое авто.",0xFF8000AA,true);}}
				setVehicleCoordinates(getPlayerVehicleId(playerid), pos[0], pos[1], pos[2]+1);
			}
			else sendPlayerMessage(playerid,"Что бы переворачивать ТС, нужно находится в нем",0xFF0000AA); return 0;
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FFFFFFAA]\" не существует.",ErrorMsgColor,true); return 0;
	}
	
	else if(cmd[0] == "/ban")
	{
		if(MODE.pl[playerid].adminlvl > 3){
	    	if(cmd.len() >= 3)
			{
			    local str;
				local id = cmd[1].tointeger();
				local reason = "";
				local time = cmd[2].tointeger();
				local timestr = " навсегда";
				if(time > 0) timestr = " на " + time + " час(ов)";
				if(cmd.len() > 3){ reason = format(" Причина: %s",strsplit(3,cmd));}
			    if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id " + id + " не подключен к серверу.",0xFF0000AA); return 0;}
			    else {
		    	    //str = format("Admin %s (id: %d) забанил игрока %s (id: %d)%s.%s",MODE.pl[playerid].name,playerid,MODE.pl[id].name,id,timestr,reason);
            	    //sendMessageToAll(str,0xFF0000AA);
					time = time*3600000;
	        	    BanPlayer(id, reason, time, MODE.pl[playerid].name + " (id: " + playerid + ")");
					return 0;
		    	}
			}		
			else { sendPlayerMessage(playerid,"Используйте: /ban <id> <time> <reason>",0xFF0000AA);}
		}
	}
	
	else if(cmd[0] == "/goto")
	{
	    if(MODE.pl[playerid].adminlvl > 3){
		    if(cmd.len() == 2)
		    {
			    local toPlayerId = cmd[1].tointeger();

			    if(!isPlayerConnected(toPlayerId))
			    {
				    sendPlayerMessage(playerid, "That player is not connected.");
				    return 1;
			    }

			    local pos;
			    if(isPlayerInAnyVehicle(toPlayerId))
				    pos = getVehicleCoordinates(getPlayerVehicleId(toPlayerId));
			    else
				    pos = getPlayerCoordinates(toPlayerId);

			    if(isPlayerInAnyVehicle(playerid))
				    setVehicleCoordinates(getPlayerVehicleId(playerid), pos[0]+1, pos[1]+2, pos[2]);
			    else
				    setPlayerCoordinates(playerid, pos[0]+1, pos[1]+2, pos[2]);
			
			    sendPlayerMessage(playerid, "Ты переместился к " + MODE.pl[toPlayerId].name + " (id: " + toPlayerId + ").");
			    PrintToAdmin(" [ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") переместился к " + MODE.pl[toPlayerId].name + " (id: " + toPlayerId +").");
		    }else sendPlayerMessage(playerid,"[FFFF00AA]Используй [FF0000AA]/[FFFFFFAA]goto [FF0000AA]<[FFFFFFAA]id[FF0000AA]> [FFFF00AA]что бы переместится к игроку.",0xFFFFFFAA,true); return 0;
		}
		else sendPlayerMessage(playerid,"[FF0000AA]Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",0xFFFFFFAA,true); return 0;

		return 1;
	}
	else if(cmd[0] == "/gethere")
	{
	    if(MODE.pl[playerid].adminlvl > 3)
		{
	        if(cmd.len() == 2)
		    {
		        local id = cmd[1].tointeger();
				local pos;
				if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключен к серверу.",ErrorMsgColor); return 0;}
				pos = getPlayerCoordinates(playerid);
				if(isPlayerInAnyVehicle(id))
				{
				    setVehicleCoordinates(getPlayerVehicleId(id), pos[0]+1, pos[1]+2, pos[2]);
				}
			    else
				{
				    setPlayerCoordinates(id, pos[0]+1, pos[1]+2, pos[2]);
				}
				PrintToAdmin(" [ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") переместил " + MODE.pl[id].name + " (id: " + id +") к себе.");
		    }
			else sendPlayerMessage(playerid,"[FFFF00AA]Используй [FF0000AA]/[FFFFFFAA]gethere [FF0000AA]<[FFFFFFAA]id[FF0000AA]> [FFFF00AA]что бы переместить игрока к себе.",0xFFFFFFAA,true); return 0;
		}
		else sendPlayerMessage(playerid,"[FF0000AA]Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",0xFFFFFFAA,true); return 0;
	}
	
	else if(cmd[0] == "/out")
	{
	    if(MODE.pl[playerid].adminlvl > 3)
		{
		    if(cmd.len() == 2)
			{
			    local id = cmd[1].tointeger();
				if(MODE.pl[playerid].adminlvl < MODE.pl[id].adminlvl){ return 0;}
				if(!isPlayerConnected(id)){ PrintToChat("Игрок с id: " + id + " не подключен к серверу.",playerid,ErrorMsgColor)}				
		        PrintToChat(MODE.pl[playerid].name + " (id: " + playerid + ") выкинул тебя из ТС.",id);
		        PrintToAdmin(MODE.pl[playerid].name + " (id: " + playerid + ") выкинул из ТС " + MODE.pl[id].name + " (id: " + id + ").");
		        removePlayerFromVehicle(id);
		    }
		}
	}
	
	else if(cmd[0] == "/locations" || cmd[0] == "/loc")
	{
	    if(MODE.pl[playerid].adminlvl > 4)
		{
	        for(local l = 0; l < MODE.loc.len(); l++)
		    {
		        sendPlayerMessage(playerid,l + ". " + MODE.loc[l][0],0xCDCDCDAA);
		    }
		}
	}
	else if(cmd[0] == "/teleport" || cmd[0] == "/tp")
	{
	    if(MODE.pl[playerid].adminlvl > 4)
		{
	        local loc = cmd[1].tointeger()
	        if(cmd.len() == 3)
	        {	      
		        local id = cmd[2].tointeger();
		        if(!isPlayerConnected(id)){ PrintToChat("Игрок с id: " + id + " не подключен к серверу.",playerid,ErrorMsgColor); return 0;}
		        if(loc <= MODE.loc.len())
		        {
				    if(isPlayerInAnyVehicle(id))
				    {
				        setVehicleCoordinates(getPlayerVehicleId(id),MODE.loc[loc][1],MODE.loc[loc][2],MODE.loc[loc][3]);
				    }
			        else
				    {
				        setPlayerCoordinates(id, MODE.loc[loc][1],MODE.loc[loc][2],MODE.loc[loc][3]);
				    }
			        PrintToAdmin("[ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") переместил " + MODE.pl[id].name + " (id: " + id + "). Локация: " + MODE.loc[loc][0] + " (" + loc + ")");
		        }
		  
	        }
	        else if(cmd.len() == 2)
	        {
	            if(loc <= MODE.loc.len())
		        {
				    if(isPlayerInAnyVehicle(playerid))
				    {
				        setVehicleCoordinates(getPlayerVehicleId(playerid),MODE.loc[loc][1],MODE.loc[loc][2],MODE.loc[loc][3]);
				    }
			        else
				    {
				        setPlayerCoordinates(playerid, MODE.loc[loc][1],MODE.loc[loc][2],MODE.loc[loc][3]);
				    }
			        PrintToAdmin("[ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") перемеcтился. Локация: " + MODE.loc[loc][0] + " (" + loc + ")");
		        }
	        }
	        else{ PrintToChat("Используй /teleport <location> <id>",playerid,ErrorMsgColor); return 0;}
		}
	}
	
	else if(cmd[0] == "/gotov")
	{
	    if(MODE.pl[playerid].adminlvl > 4){
		    if(cmd.len() == 2)
		    {
			    if(is_int(cmd[1]))
				{
				    local vehicleid = cmd[1].tointeger();
					local vehicleName = getVehicleName(getVehicleModel(vehicleid));
					if(vehicleid < 0 || vehicleid > MODE.vehicleCount){ sendPlayerMessage(playerid,"Используй: /gotov <vehicleid>",ErrorMsgColor);return;}
					local pos = getVehicleCoordinates(vehicleid);
					setPlayerCoordinates(playerid, pos[0],pos[1]+2,pos[2]);
					PrintToAdmin(MODE.pl[playerid].name + "(id: " + playerid + ") переместился к транспортному средству (" + vehicleName + " [id: " + vehicleid + "]).");
				} else { sendPlayerMessage(playerid,"Используй: /gotov <vehicleid>",ErrorMsgColor);return;}
			}
			if(cmd.len() == 3)
		    {
			    if(is_int(cmd[1]) && is_int(cmd[2]))
				{
				    local vehicleid = cmd[1].tointeger();
					local vehicleName = getVehicleName(getVehicleModel(vehicleid));
					local targetid = cmd[2].tointeger();
					if(vehicleid < 0 || vehicleid > MODE.vehicleCount){ sendPlayerMessage(playerid,"Используй: /gotov <vehicleid> <playerid>",ErrorMsgColor);return;}
					if(!isPlayerConnected(targetid)){ sendPlayerMessage(playerid,"Игрок, которого ты пытаешься переместить, не подключен к серверу.",ErrorMsgColor);return;}
					local pos = getVehicleCoordinates(vehicleid);
					setPlayerCoordinates(targetid, pos[0],pos[1]+2,pos[2]);
					sendPlayerMessage(targetid,"Админ [FF0000AA]" + MODE.pl[playerid].name + "[FFFFFFAA](id: " + playerid + ") переместил тебя к транспортному средству (" + vehicleName + ").",0xFFFFFFAA,true);
					PrintToAdmin(MODE.pl[playerid].name + "(id: " + playerid + ") переместил игрока " + MODE.pl[targetid].name + "(id: " + targetid + ") к транспортному средству (" + vehicleName + " [id: " + vehicleid + "]).");
				} else{ sendPlayerMessage(playerid,"Используй: /gotov <vehicleid> <playerid>",ErrorMsgColor);return;}
			} else{ sendPlayerMessage(playerid,"Используй: /gotov <vehicleid>[ <playerid>]",ErrorMsgColor);return;}
		} else { PrintToChat("Команды \"" + cmd[0] + "\" не существует.",playerid,ErrorMsgColor);return 0;}
	}
	
	else if(cmd[0] == "/getv")
	{
	    if(MODE.pl[playerid].adminlvl > 5){
		    if(cmd.len() == 2)
		    {
			    if(is_int(cmd[1]))
				{
			        local vehicleid = cmd[1].tointeger();
					local vehicleName = getVehicleName(getVehicleModel(vehicleid));
				    if(vehicleid < 0 || vehicleid > MODE.vehicleCount){ sendPlayerMessage(playerid,"Используй: /getv <vehicleid>",ErrorMsgColor);return;}
					if(!freeVihicle(vehicleid)){ sendPlayerMessage(playerid,"Вы не можите переместить к себе ТС с id: " + vehicleid + " так как оно используется другим игроком.",ErrorMsgColor);return;}
					local pos = getPlayerCoordinates(playerid);
					setVehicleCoordinates(vehicleid,pos[0],pos[1],pos[2]-1);
					warpPlayerIntoVehicle(playerid, vehicleid);
					PrintToAdmin(MODE.pl[playerid].name + "(id: " + playerid + ") переместил к себе транспортное средство (" + vehicleName + " [id: " + vehicleid + "]).");
				} else { sendPlayerMessage(playerid,"Используй: /getv <vehicleid>",ErrorMsgColor);return;}
			}
			if(cmd.len() == 3)
		    {
			    if(is_int(cmd[1]) && is_int(cmd[2]))
				{
			        local vehicleid = cmd[1].tointeger();
					local vehicleName = getVehicleName(getVehicleModel(vehicleid));
					local targetid = cmd[2].tointeger();
					if(vehicleid < 0 || vehicleid > MODE.vehicleCount){ sendPlayerMessage(playerid,"Используй: /gotov <vehicleid> <playerid>",ErrorMsgColor);return;}
					if(!freeVihicle(vehicleid)){ sendPlayerMessage(playerid,"Вы не можите переместить к игроку ТС с id: " + vehicleid + " так как оно используется другим игроком.",ErrorMsgColor);return;}
					if(!isPlayerConnected(targetid)){ sendPlayerMessage(playerid,"Игрок, которого ты пытаешься переместить, не подключен к серверу.",ErrorMsgColor);return;}
					local pos = getPlayerCoordinates(targetid);
					setVehicleCoordinates(vehicleid,pos[0],pos[1],pos[2]-1);
					warpPlayerIntoVehicle(targetid, vehicleid);
					sendPlayerMessage(targetid,"Админ [FF0000AA]" + MODE.pl[playerid].name + "[FFFFFFAA](id: " + playerid + ") переместил к тебе транспортное средство (" + vehicleName + ").",0xFFFFFFAA,true);
					PrintToAdmin(MODE.pl[playerid].name + "(id: " + playerid + ") переместил к игроку " + MODE.pl[targetid].name + "(id: " + targetid + ") транспортное средство (" + vehicleName + " [id: " + vehicleid + "]).");
				} else{ sendPlayerMessage(playerid,"Используй: /getv <vehicleid> <playerid>",ErrorMsgColor);return;}
			}
			else
			{
			}
		} else { PrintToChat("Команды \"" + cmd[0] + "\" не существует.",playerid,ErrorMsgColor);return 0;}
	}
	
	else if(cmd[0] == "/v")
	{
	    if(MODE.pl[playerid].adminlvl > 4){
		if(cmd.len() == 2)
		{
		    if(!is_int(cmd[1])){sendPlayerMessage(playerid,"Для вызова ТС используй /v id.",ErrorMsgColor);return false;}
			local model = cmd[1].tointeger();
			local pos;
			if(model < 0 || model > MODE.vhGets.len()){ PrintToChat("Для вызова ТС используй /v id. Чтобы просмотреть id исользуй /vehid",playerid); return false;}
			if(isPlayerInAnyVehicle(playerid))
				pos = getVehicleCoordinates(getPlayerVehicleId(playerid));
			else
				pos = getPlayerCoordinates(playerid);
			local heading = getPlayerHeading(playerid);
			local veh = createVehicle(MODE.vhGets[model], pos[0], pos[1], pos[2], 0.0, 0.0, heading, checkcolor(-1), checkcolor(-1), checkcolor(-1), checkcolor(-1));
			if(MODE.pl[playerid].getsvh!=false) deleteVehicle(MODE.pl[playerid].getsvh);
			MODE.pl[playerid].getsvh<-veh;
			if(veh != INVALID_VEHICLE_ID)
			{
				warpPlayerIntoVehicle(playerid, veh);
				PrintToChat(getVehicleName(MODE.vhGets[model]) + " spawned at your position (ID " + veh + ").",playerid);
				PrintToAdmin(" [ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") вызвал ТС.");
			}
		}
		else PrintToChat("Для вызова ТС используй /v id. Чтобы просмотреть id исользуй /vehid",playerid,ErrorMsgColor);
		}
		else PrintToChat("Команды \"" + cmd[0] + "\" не существует.",playerid,ErrorMsgColor); return 0;

		return 1;
	}
	
	else if(cmd[0] == "/heal" || cmd[0] == "/h")
		{
		if(MODE.pl[playerid].adminlvl > 5){
		    if(cmd.len() == 2)
			{
			    local id = cmd[1].tointeger();
			    if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id " + id + " не подключен к серверу.",0xFF0000AA); return 0;}
				if(getPlayerHealth(id) < 100){ setPlayerHealth(id, 100);	sendMessageToAll("Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FF0000AA]востановил здоровье игрока [" + MODE.pl[playerid].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ")[FF0000AA].",0xFF0000AA,true);}
				else {sendPlayerMessage(playerid,"Игрок [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id +") [FF0000AA]и так здоров.",0xFF0000AA,true);}
				
			}
			else
			{
			    if(getPlayerHealth(playerid) < 200) setPlayerHealth(playerid, 200);
				sendPlayerMessage(playerid,"Вы выличили себя.",0xFFFF00AA);
			}
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/healall" || cmd[0] == "/hall")
	{
		if(MODE.pl[playerid].adminlvl > 5){
		    for(local i = 0; i < getPlayerSlots(); i++)
			{
			    if(isPlayerConnected(i)){
				    if(getPlayerHealth(i) < 100)
					{
					    setPlayerHealth(i, 100);
					}
				}
                
			}
			sendMessageToAll("Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FF0000AA]востановил здоровье всем",0xFF0000AA,true);
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/rape")
	{
		if(MODE.pl[playerid].adminlvl > 6){
		    if(cmd.len() == 2)
			{
			    local id = cmd[1].tointeger();
				if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключен к серверу.",0xFF0000AA);}
				//if(id == playerid || MODE.pl[playerid].admin == true){ sendPlayerMessage(playerid,"Вы не можите казнить себя или админа.",0xFF0000AA); return 0;}				
				sendMessageToAll("Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FFFF00AA]казнил [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ")[FFFF00AA].",0xFFFF00AA,true);	        		    
				setPlayerHealth(id, -1);
			}
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/rapeall")
	{
		if(MODE.pl[playerid].adminlvl > 6){
		    for(local i = 0; i < getPlayerSlots(); i++){
				if(isPlayerConnected(i) && i != playerid && MODE.pl[i].adminlvl == 0)
				{		    
				    setPlayerHealth(i, -1);
				}
			}
			sendMessageToAll("Админ " + MODE.pl[playerid].name + " (id: " + playerid + ") казнил почти всех.",0xFFFF00AA);
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);		
	}
	
	else if(cmd[0] == "/money")
	{
	    if(MODE.pl[playerid].adminlvl > 8){
		    if(cmd.len() == 2)
		    {
			    setPlayerMoney(playerid, cmd[1].tointeger());
			    MODE.pl[playerid].money<-cmd[1].tointeger();
			    sendPlayerMessage(playerid, "Money set", 0xFFFFFFAA);
		    }
		    else sendPlayerMessage(playerid,"Используй: /[FFFFFFAA]money [FF0000AA]<[FFFFFFAA]сумма[FF0000AA]>",0xFF0000AA,true);
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/setmoney")
	{
		if(MODE.pl[playerid].adminlvl > 8){
		    if(cmd.len() == 3)
		    {
			    local id = cmd[1].tointeger();
				local money = cmd[2].tointeger();
	    	    if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id " + id + " не подключен к серверу.",0xFF0000AA); return 0;}
				if(money < 0){ sendPlayerMessage(playerid,"Сумма не может быть меньше 0.",0xFF0000AA); return 0;}
				MODE.pl[id].money = money;
				setPlayerMoney(id, money);
				sendPlayerMessage(id,"Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FFFF00AA]установил вам сумму денег [009900AA]$" + money,0xFFFF00AA,true);
				sendPlayerMessage(playerid,"Вы установили сумму денег [009900AA]$" + money + " [FFFF00AA]игроку [" + MODE.pl[id].color + "]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ")",0xFFFF00AA,true);
				
	    	}
			else sendPlayerMessage(playerid,"Используйте: [FF0000AA]/[FFFFFFAA]setmoney [FF0000AA]<[FFFFFFAA]id[FF0000AA]> <[FFFFFFAA]amour[FF0000AA]>",0xFF0000AA,true); return 0;
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}
	
	else if(cmd[0] == "/resetmoney")
	{
		if(MODE.pl[playerid].adminlvl > 8){
		    if(cmd.len() == 2)
		    {
			    local id = cmd[1].tointeger();
	    	    if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id " + id + " не подключен к серверу.",0xFF0000AA); return 0;}			
				MODE.pl[id].money = 0;
				resetPlayerMoney(id);
				sendPlayerMessage(id,"Админ [" + MODE.pl[playerid].color + "]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") [FFFF00AA]забрал у тебя деньги",0xFFFF00AA,true);
				sendPlayerMessage(playerid,"Вы отобрали деньги у игрока [" + MODE.pl[playerid].color + "]" + MODE.pl[id].name + " ([FFFFFFAA]id: " + id + ")",0xFFFF00AA,true);
			
		    }
			else sendPlayerMessage(playerid,"Используйте: /resetmoney <id>",0xFF0000AA); return 0;
		}
		else sendPlayerMessage(playerid,"Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",ErrorMsgColor,true);
	}	
	else if(cmd[0] == "/gm")
	{
	   if(MODE.pl[playerid].adminlvl > 9)
		{
		    setPlayerHealth(playerid, 20000);
		    return 1;
		}
	}
	
	else if(cmd[0] == "/vh")
	{
	    if(MODE.pl[playerid].adminlvl > 9){
		    if(cmd.len() == 2)
		    {
			    if(isPlayerInAnyVehicle(playerid))
			    {
				    local vehicleid = getPlayerVehicleId(playerid);
				    local oldhealth = getVehicleEngineHealth(vehicleid);
				    local health = cmd[1].tointeger();
				    setVehicleEngineHealth(vehicleid, health);
				    sendPlayerMessage(playerid, "Vehicle health set from " + oldhealth + " to " + health);
					PrintToAdmin("[ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") отремонтировал свое авто.");
			    }
		    }
		}
		else sendPlayerMessage(playerid,"[FF0000AA]Команды [FFFFFFAA]\"" + cmd[0] + "\" [FF0000AA]не существует.",playerid,ErrorMsgColor); return 0;
	}
	else if(cmd[0] == "/saveall")
	{
	    if(MODE.pl[playerid].adminlvl > 9){
		    saveAllPlayers();
			sendMessageToAll("Администратор " + MODE.pl[playerid].name + " [id: " + playerid + "] сохранил данные всех игроков.",SystemMsgColor);
			return true;
		}
	}
    else if(cmd[0]=="/alevel")
    {
	    if(MODE.pl[playerid].adminlvl > 10){
		    if(cmd.len() == 3){
			    local id = cmd[1].tointeger();
				local lvl = cmd[2].tointeger();
			    if(!isPlayerConnected(id)){ sendPlayerMessage(playerid,"Игрок с id: " + id + " не подключем к серверу.",ErrorMsgColor); return 0;}
				if(!MODE.pl[id].login){ sendPlayerMessage(playerid,MODE.pl[id].name + " (id: " + id + ") не зарегестрирован, либо не залогинелся.",ErrorMsgColor); return 0;}
				if(lvl > 10){ sendPlayerMessage(playerid,"Уровень админа не может быть больше 10",ErrorMsgColor); return 0;}
				MODE.pl[id].adminlvl = lvl;
				saveplayer(id);
				sendMessageToAll("[FFFFFFAA]Админ [FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA](id: " + playerid + ") назначил админом [00FF00AA]" + MODE.pl[id].name + " [FFFFFFAA](id: " + id + ").",0xFFFFFFAA,true);
			}
			else sendPlayerMessage(playerid,"Используй [FF0000AA]/[FFFFFFAA]alevel [FF0000AA]<[FFFFFFAA]id[FF0000AA]> <[FFFFFFAA]level[FF0000AA]>[FFFFFFAA], чтобы посветить игрока в админы.",0xFFFFFFAA,true); return 0;
		}
		else sendPlayerMessage(playerid,"[FF0000AA]Команды \"[FFFFFFAA]" + cmd[0] + "[FF0000AA]\" не существует.",0xFFFFFFAA,true); return 0;
	}
	else if(cmd[0] == "/godmode")
	{
	    if(MODE.pl[playerid].adminlvl > 10){
		    local id;
			if(cmd.len() > 1){
			    id = cmd[1].tointeger();
			} else {
			    id = playerid;
			}
			if(MODE.pl[id].godmode == true){ MODE.pl[id].godmode = false;}
			else { MODE.pl[id].godmode = true;}
			PrintToAdmin(" [ADMIN] " + MODE.pl[playerid].name + " (id: " + playerid + ") дал/забрал бесмертие игроку " + MODE.pl[id].name);
		}
	}
	else if(cmd[0] == "/editor")
	{
	    if(MODE.pl[playerid].adminlvl > 10){
		    if(cmd.len() > 1)
			{
			    switch(cmd[1])
				{
				    case "on":
					    if(Editor == 0)
						{
						    sendPlayerMessage(playerid,"Включен редактор мода",HelpMsgColor);
							Editor=1;
						}
						else
						{
						    sendPlayerMessage(playerid,"Редактор уже включен, для отключения используйте дерективу off",ErrorMsgColor);
						}
					break;
					case "off":
					    if(Editor == 1)
						{
						    sendPlayerMessage(playerid,"Редактор мода выключен",HelpMsgColor);
							Editor=0;
						}
						else
						{
						    sendPlayerMessage(playerid,"Редактор уже выключен, для включения используйте дерективу on",ErrorMsgColor);
						}
					break;
					case "cvh":
					    if(cmd.len() == 3)
						{
					        if(isPlayerInAnyVehicle(playerid)){	sendPlayerMessage(playerid,"Свали из тачки!"ErrorMsgColor);return;}
						    local pos = getPlayerCoordinates(playerid);
							local heading = getPlayerHeading(playerid);
							local veh = createVehicle(cmd[2].tointeger(),pos[0],pos[1],pos[2],0.0,0.0,heading,checkcolor(-1),checkcolor(-1),checkcolor(-1),checkcolor(-1));
						    sendPlayerMessage(playerid,"veh = " + veh);
							warpPlayerIntoVehicle(playerid, veh);
							sendPlayerMessage(playerid,"Береги её!"ErrorMsgColor);
						    
						}
						//log((vehicles.find(1)).tostring());
					break;
					case "svh":
					    if(!isPlayerInAnyVehicle(playerid)){ sendPlayerMessage(playerid,"Ошибочнй id. Сохранение невозможно. Вы должны находится в ТС."ErrorMsgColor);return;}
						local veh = getPlayerVehicleId(playerid);
						local pos = getVehicleCoordinates(veh);
						local color = getVehicleColor(veh);//
						color[0] = (-1);color[1] = (-1);color[2] = (-1);color[3] = (-1);
						local rotation = getVehicleRotation(veh);
						local modelid = getVehicleModel(veh);
						local lock=0,pspawn=1;
						if(cmd.len() == 3)
						{
						    local param = split(cmd[2], ",");
							//ключи: -l закрытие авто; -spw запрет спавна; -с цвет транспорта или -ci цвет транспорта у казанием цвета
							pspawn = (param.find("-spw") == null)?1:(param[param.find("-spw")+1]);
							lock = (param.find("-l") == null)?0:(param[param.find("-l")+1]);
							if(param.find("-c") != null) {local color1 = getVehicleColor(veh);color[0] = color1[0];color[1] = color1[1];color[2] = color1[2];color[3] = color1[3];}
							if(param.find("-ci") != null) {color[0] = param[param.find("-ci")+1];color[1] = param[param.find("-ci")+2];color[2] = param[param.find("-ci")+3];}
						}
						sendPlayerMessage(playerid,"Данные для отправки в бд: NULL, " + modelid + ", " + pos[0] + ", " + pos[1] + ", " + pos[2] + ", " + rotation[0] + ", " + rotation[1] + ", " + rotation[2] + ", " + color[0] + ", " + color[1] + ", " + color[2] + ", " + color[3] + ", " + lock + ", " + pspawn);
                        local rows = sql.query_affected_rows("SELECT * FROM vehicles WHERE id=" + veh);
						if(rows != 0)
						{
						    //"UPDETE vehicles SET model=" + modelid + ", x='', y='', z='', rx='', ry='" + rotation[1] + "', rz='" + rotation[2] + "', color1=" + color[0] + ", color2=" + color[1] + ", color3=" + color[2] + ", color4=" + color[3] + ", lockvh=" + lock + ", pspawn=" + pspawn + " WHERE id=" + veh);
							sql.query("UPDATE `vehicles` SET `model` = '" + modelid + "',`x` = '" + pos[0] + "',`y` = '" + pos[1] + "',`z` = '" + pos[2] + "',`rx` = '" + rotation[0] + "',`ry` = '" + rotation[1] + "',`rz` = '" + rotation[2] + "',`color1` = '" + color[0] + "',`color2` = '" + color[1] + "',`color3` = '" + color[2] + "',`color4` = '" + color[3] + "', `lockvh` = '" + lock + "', `pspawn` = '" + pspawn + "' WHERE `id` = '" + veh + "'");
						}
						else
						{
						    sql.query("INSERT INTO vehicles (id,model,x,y,z,rx,ry,rz,color1,color2,color3,color4,lockvh,pspawn) VALUES (" + veh + ", " + modelid + ", '" + pos[0] + "', '" + pos[1] + "', '" + pos[2] + "', '" + rotation[0] + "', '" + rotation[1] + "', '" + rotation[2] + "', " + color[0] + ", " + color[1] + ", " + color[2] + ", " + color[3] + ", " + lock + ", " + pspawn + ")");
							//id 	model 	x 	y 	z 	rx 	ry 	rz 	color1 	color2 	color3 	color4 	lock 	pspawn
						}
					break;
					case "dvh":
					    if(!isPlayerInAnyVehicle(playerid)){ sendPlayerMessage(playerid,"Ошибочнй id. Удаление невозможно. Вы должны находится в ТС."ErrorMsgColor);return;}
						deleteVehicle(getPlayerVehicleId(playerid));
						sendPlayerMessage(playerid,"ТС удалено."ErrorMsgColor);
					break;
					case "createactor":
					    if(cmd.len() == 3)
						{
					    local pos = getPlayerCoordinates(playerid);
						local rot = getPlayerHeading(playerid);
						setPlayerCoordinates(playerid, pos[0]+1, pos[1]+1, pos[2]);
						local actor = createActor(cmd[2].tointeger(), pos[0], pos[1], pos[2], rot);
						sendPlayerMessage(playerid,"Actor id: " + actor);
						}
					break;
					case "deleteactor":
					    if(cmd.len() == 3)
						{
					        deleteActor(cmd[2].tointeger());
						    sendPlayerMessage(playerid,"Actor id: " + cmd[2].tointeger() + " deleted");
						}
					break;
				}
			}
			else
			{
			    sendPlayerMessage(playerid,"Редактор мода " + MODE_NANE + " v." + MODE_VERSION + ":",HelpMsgColor);
				sendPlayerMessage(playerid,"on - включить редактор",ConnectMsgColor);
				sendPlayerMessage(playerid,"off - отключить редактор",ConnectMsgColor);
			}
		}
	}
}
addEvent("playerCommand", onPlayerCommand);

function onPlayerDeath(playerid, killerid, killervehicle)
{
    setPlayerCoordinates(playerid,509.400085,333.814026,8.597934);
    local msg,colors,colors2,reason;
	colors = (MODE.pl[playerid].team >= 0)?MODE.teams[MODE.pl[playerid].team][6]:colors = MODE.pl[playerid].color;
	if(killerid != INVALID_PLAYER_ID && killerid != playerid) {
	    colors2 =(MODE.pl[killerid].team >= 0)?MODE.teams[MODE.pl[killerid].team][6]:MODE.pl[killerid].color;
		local hg = true;
		if(MODE.pl[killerid].team == MODE.pl[playerid].team && MODE.pl[killerid].team != -1)
		{
			MODE.pl[killerid].stopTimer=0;
		    MODE.pl[killerid].sec=0;
			MODE.pl[killerid].jailsec = 5;
			PrintToChat(MODE.pl[killerid].name + " (id: " + killerid + ") посажен в тюрьму сервером. Причина: убийство игрока своей команды",INVALID_PLAYER,MuteMsgColor);
			setPlayerCoordinates(killerid,-1075.474976,-461.862152,2.262325);				
			MODE.pl[killerid].jail = MODE.pl[killerid].jailsec * 60 + time();
		    MODE.pl[killerid].TimerOut = MODE.pl[killerid].jailsec;
			printTimer2(MODE.pl[killerid].jailsec,"~r~UnJail: ",killerid);
			MODE.pl[killerid].freeze = true;
			saveplayer(killerid);
		}
		if(isPlayerInAnyVehicle(killerid))
		{
		    local vehmodel = getVehicleModel(getPlayerVehicleId(killerid));
			reason = (vehmodel > 111 && vehmodel < 116)?"DBfly":"DBauto";
			hg = false;
		}
		if(!isPlayerInAnyVehicle(killerid)) { reason = MODE.wname[getPlayerWeapon(killerid)];}
		sendMessageToAll("[" + colors + "]" + MODE.pl[playerid].name + " [FFFFFFFF](" + playerid + ") was killed by [" + colors2 + "]" + MODE.pl[killerid].name + " [FFFFFFFF](" + killerid + "). [" + reason + "]", 0xFFFFFFAA, true);
		if(hg == false)
		{
		    if(MODE.pl[killerid].antidb == 1)
			{
		        setPlayerHealth(killerid,-1);
				//MODE.pl[killerid].antidb = 0;
			}
			else
			{
			    MODE.pl[killerid].antidb = 1;
			}
			sendPlayerMessage(killerid,"На сервере запрещено умышленно сбивать других игроков (Stop Drive-By!).",ErrorMsgColor);
			
		}
		if(hg != false)
		{
		    sendPlayerMessage(playerid,"Тебя убил [FF0000AA]" + MODE.pl[killerid].name + " [FFFFFFAA](id: " + killerid +") из [FFFF00AA]" + reason +"[FFFFFFAA]. У него осталось [FF0000AA]" + getPlayerHealth(killerid) + "хп[FFFFFFAA].",0xFFFFFFAA,true);
		    MODE.pl[killerid].score++;
		    MODE.pl[killerid].TMaxKillsForLifeT++;
		    MODE.pl[killerid].money <- MODE.pl[killerid].money + MODE_KILL_GETMONEY;
		    setPlayerMoney(killerid,MODE.pl[killerid].money);
		    MODE.pl[playerid].deaths++;
		    if(MODE.pl[playerid].MaxKillsForLife < MODE.pl[playerid].TMaxKillsForLifeT){ MODE.pl[playerid].MaxKillsForLife = MODE.pl[playerid].TMaxKillsForLifeT;}
		    MODE.pl[playerid].TMaxKillsForLifeT =0;
		}
	}
	else{
		sendMessageToAll("[FF0000AA]" + MODE.pl[playerid].name + " [FFFFFFAA]умер",0xFFFFFFAA,true);
		MODE.pl[playerid].suicides++;
		if(MODE.pl[playerid].MaxKillsForLife < MODE.pl[playerid].TMaxKillsForLifeT){ MODE.pl[playerid].MaxKillsForLife = MODE.pl[playerid].TMaxKillsForLifeT;}
		MODE.pl[playerid].TMaxKillsForLifeT =0;
		MODE.pl[playerid].suicides<-MODE.pl[playerid].suicides+1;
        MODE.pl[playerid].score<-MODE.pl[playerid].score-1;
		MODE.pl[playerid].money<-MODE.pl[playerid].money-500;
		setPlayerMoney(playerid,MODE.pl[playerid].money);
		
		
    }
	for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(!isPlayerConnected(i)) continue;
	    triggerClientEvent(i,"sendDeathMessage",killerid,playerid,reason);
	}
	return true;
}
addEvent("playerDeath", onPlayerDeath);

function isPlayerInGameAdmin(playerid)
{
    if(MODE.pl[playerid].adminlvl > 0) return true;
	else return false;
}

function onPlayerText(playerid,text)
{
    local str;
	local str1;
	local colors;
	local txt = split(text, " ");
	if(txt.len() == 0){ return 0;}
	if(MODE.pl[playerid].team >= 0 && MODE.pl[playerid].team != 3600){ colors = (MODE.pl[playerid].team == 1000)?"FFFFFFFF":MODE.teams[MODE.pl[playerid].team][6];}
	else { colors = MODE.pl[playerid].color;}
        if(MODE.pl[playerid].mutesec > 0){ PrintToChat("Тебе запрещено писать в чат.",playerid,ErrorMsgColor); return 0;}
	if(MODE.pl[playerid].jailsec > 0)
	{
	    for(local i = 0; i < getPlayerSlots(); i++)
		{
		    if(isPlayerConnected(i) && MODE.pl[i].jailsec > 0)
			{
			    sendPlayerMessage(i,"[JAIL] " + MODE.pl[playerid].name + " (id: " + playerid + "): " + text,0xFFFFFFFF);
			}			
		}
		return 0;						
	}
	if (MODE.pl[playerid].adminlvl < AdminLevelToIgnorePunishment) {
	   	MODE.pl[playerid].messages++;
	   	if (MODE.pl[playerid].messages > FloodLines) {
	  	    MODE.pl[playerid].messages = 0;
			KickPlayer(playerid,"Стоп Флуд!");
	        return 0;
	   	}
	}
    if(MODE.pl[playerid].afk){
	   str = format("*AFK* %s (id: %d): %s",MODE.pl[playerid].name,playerid,text);
	   sendMessageToAll(str, COLOR_LIGHTBLUE);
	   return 0;
	}    
	if(txt[0] == "!" && MODE.pl[playerid].query >=0){
	    sendPlayerMessage(MODE.pl[playerid].query,"ПМ от " + MODE.pl[playerid].name + " (id: " + playerid + "): " + strsplit(1,txt),PrivateMsgColor);
		sendPlayerMessage(playerid,"ПМ для " + MODE.pl[MODE.pl[playerid].query].name + " (id: " + MODE.pl[playerid].query + "): " + strsplit(1,txt),SystemMsgColor);
		return 0;
	}
	if(txt[0] == "+" && isPlayerInGameAdmin(playerid)){
	    for(local i = 0; i < getPlayerSlots(); i++)
	    {
	        if(isPlayerConnected(i) && MODE.pl[i].adminlvl)
		    {
		        sendPlayerMessage(i,"[toAdmins] " + MODE.pl[playerid].name + "(id: " + playerid + "): [FFFFFFFF]" + strsplit(1,txt),AdminChatColor, true);
		    }
	    }
		return 0;
	}
	if(txt[0] == "*"){
	    if(MODE.pl[playerid].team >= 0){	    	    
		    for(local p = 0; p < getPlayerSlots(); p++){
			    if(isPlayerConnected(p) && MODE.pl[playerid].team == MODE.pl[p].team){
				   str1 = format("[%s][TEAM] %s [FFFFFFFF](id: %d): %s",colors,MODE.pl[playerid].name,playerid,strsplit(1,txt));
                   sendPlayerMessage(p,str1, 0xFFFFFFFF, true);
				}
			}
			return 0;
		    
		}		
	}
	local color2 = "FFFFFFAA";
	local text2 = text;
	for(local t = 0; t < MODE.freeColor.len(); t++)
	{
	    if(txt[0] == MODE.freeColor[t][1])
		{		    
			color2 = MODE.freeColor[t][0];
			text2 = strsplit(1,txt);
		}
	}
        local hgpb="";
        if(text2.len() > 128) {text2 = text2.slice(0,128);}
	for(local v = 0; v < MODE.freeColor.len(); v++){
	    text2 = strreplace(text2, MODE.freeColor[v][1], "["+MODE.freeColor[v][0]+"]");
	}
	if(text.len() > 64){
	//text2 = text2.slice(128);
	local hgpa = text.slice(0,64);
	hgpb = text.slice(64);
	str = format("[%s]%s [FFFFFFFF](id: %d): [%s]%s",colors,MODE.pl[playerid].name,playerid,color2,hgpa);
	}
	if(hgpb ==""){
	str = format("[%s]%s [FFFFFFFF](id: %d): [%s]%s",colors,MODE.pl[playerid].name,playerid,color2,text2);}
        for(local i = 0; i < getPlayerSlots(); i++)
	{
	    if(isPlayerConnected(i) && !isPlayerIgnore(i, playerid))
		{		    
		    sendPlayerMessage(i, str, 0xFFFFFFFF, true);
		    if(text.len() > 64) {sendPlayerMessage(i, hgpb, 0xFFFFFFFF, true);}
		}
	}
	log("[Chat] " + MODE.pl[playerid].name + " (" + playerid + "): " + text);
	return 0;
}
addEvent("playerText", onPlayerText);

function onPlayerEnterVehicle( playerid, vehicleid, seatid )
{
    if(lockVehicles.find(vehicleid) != null){ sendPlayerMessage(playerid,"Музейный экспонат, запрещено трогать руками!",ErrorMsgColor); return 0;}
	if(MODE.pl[playerid].adminlvl > 10 && Editor == 1)
	{
	    local s_vehid = getPlayerVehicleId(playerid);
		local s_pos = getVehicleCoordinates(s_vehid);
		local s_modelid = getVehicleModel(s_vehid);
		local s_vname = getVehicleName(s_modelid);
		local s_color = getVehicleColor(s_vehid);
		sendPlayerMessage(playerid,"Данные на сервере: ("+s_vname+") vid = " + s_vehid + ", model = " + s_modelid + ", x = " + s_pos[0] + ", y = " + s_pos[1] + ", z = " + s_pos[2] + ", colors: " + s_color[0] + ", " + s_color[1] + ", " + s_color[2] + ", " + s_color[3],0x009900AA);
		local db_vid = s_vehid;
		local rows = sql.query_affected_rows("SELECT * FROM vehicles WHERE id=" + db_vid);
		    if(rows == 1)
			{
			    local vhData = sql.query_assoc_single("SELECT * FROM vehicles WHERE id=" + db_vid);
				sendPlayerMessage(playerid,"Данные в базе: (" + getVehicleName(vhData.model) + ") vid = " + vhData.vid + ", id = " + vhData.id + ", model = " + vhData.model + ", x = " + vhData.x + ", y = " + vhData.y +", z = " + vhData.z,0x000099AA);
			}
			else
			{
			    sendPlayerMessage(playerid,"Это ТС не найдено в БД",ErrorMsgColor);
			}	
	}
    return 1;
}
addEvent("playerEnterVehicle", onPlayerEnterVehicle);

function onPlayerEnterCheckpoint(playerid, checkpointId)
{
	sendPlayerMessage(playerid,MODE.food[checkpointId][5] + ": $" + MODE.food[checkpointId][3]);
	MODE.pl[playerid].food = checkpointId;
	triggerClientEvent(playerid, "playerFoodAction", true);
    return 1;
}
addEvent("playerEnterCheckpoint", onPlayerEnterCheckpoint);

function onPlayerLeaveCheckpoint( playerid, checkpointId )
{
    MODE.pl[playerid].food = -1;
	triggerClientEvent(playerid, "playerFoodAction", false);
	return 1;
}
addEvent("playerLeaveCheckpoint", onPlayerLeaveCheckpoint);
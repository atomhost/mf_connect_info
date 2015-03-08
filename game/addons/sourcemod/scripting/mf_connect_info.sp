#pragma semicolon 1
#include <sourcemod>
#include <socket>
#include <sdktools> 
#include <morecolors> 


public Plugin:myinfo = {name = "ConnectInfo",author = "merk26",description = "Кириллическая информация о подключившемся игроке",version = "1.4.0.0",url = "атомхост.рф"}


Handle	h_CI_COldHide,h_CI_DOldHide,h_CI_Enable,g_CI_PTimer,g_CI_ShowStatusID,g_CI_ShowGeo,g_CI_ShowDistrict,g_CI_Log,h_CI_IPShow,g_CI_WelcomeSound,h_CI_StemIDShow,g_CI_ShowLines,h_CI_DisconnectMsg,
		g_CI_EnterSound,g_CI_ExitSound, g_CI_ShowRealName, g_CI_ShowStatusVACBan, g_CI_ShowCountVACBans;


		
bool p_CI_coldhide,p_CI_doldhide,Enabled,p_CI_showstatussteam,p_CI_showgeoinfo,p_CI_showdistrict,p_CI_writelog,p_CI_showlines,Enabled_ip,p_CI_exitmsg, p_CI_realname,
		p_CI_banned, p_CI_countvacbans;
		
int Enabled_steamid;

char g_IP[MAXPLAYERS + 1][25],s_CI_welcomesoung[128],s_CI_entersoung[128],s_CI_exitsoung[128];

public OnPluginStart()
{
	
	h_CI_COldHide 			= CreateConVar("mf_coldhide", 			"1",	"Скрыть стандартное сообщение о подключении", _, true, 0.0, true, 1.0);
	h_CI_DOldHide 			= CreateConVar("mf_doldhide", 			"1",	"Скрыть стандартное сообщение об отключении", _, true, 0.0, true, 1.0);
	h_CI_DisconnectMsg 		= CreateConVar("mf_exitmsg", 			"1",	"Показывать новое сообщение об отключении", _, true, 0.0, true, 1.0);
	h_CI_IPShow				= CreateConVar("mf_showip",				"0",	"Показывать IP адрес игрока", _, true, 0.0, true, 1.0);
	h_CI_StemIDShow			= CreateConVar("mf_showstemid",			"1",	"Показывать SteamID игрока: 0 - выкл; 1 - STEAM_0:0:00000000; 2 - 00000000000000000; 3 - оба", _, true, 0.0, true, 3.0);
	h_CI_Enable 			= CreateConVar("mf_enable",				"1",	"Вкл/Выкл плагин", _, true, 0.0, true, 1.0);
	g_CI_ShowLines 			= CreateConVar("mf_showlines",			"1",	"Отделять информационный блок линиями", _, true, 0.0, true, 1.0);
	g_CI_PTimer 			= CreateConVar("mf_ptimer",				"30.0",	"Время через которое (после старта карты) начнут отображаться сообщения (для защиты от перегрузок при массовом реконнекте)", _, true, 15.0, true, 120.0);
	g_CI_ShowStatusID 		= CreateConVar("mf_showstatussteam", 	"1",	"Показывать информации о статусе лицензии Steam/No-steam", _, true, 0.0, true, 1.0);
	g_CI_ShowRealName 		= CreateConVar("mf_showrealname", 		"1",	"Показывать настоящще имя игрока (если указано в Steam)", _, true, 0.0, true, 1.0);
	g_CI_ShowStatusVACBan	= CreateConVar("mf_showbannedstatus", 	"1",	"Показывать наличие VAC бана (при активного бана у игроков Steam)", _, true, 0.0, true, 1.0);
	g_CI_ShowCountVACBans 	= CreateConVar("mf_showcountvacdans", 	"1",	"Показывать общее количество vac банов (у игроков Steam при наличии хотя бы одного бана)", _, true, 0.0, true, 1.0);
	g_CI_ShowGeo 			= CreateConVar("mf_showgeoinfo",		"1",	"Показывать информацию о стране + городе + регионе игрока", _, true, 0.0, true, 1.0);
	g_CI_ShowDistrict 		= CreateConVar("mf_showdistrict",		"1",	"Показывать информации о дистрикте игрока", _, true, 0.0, true, 1.0);
	g_CI_Log 				= CreateConVar("mf_writelog",			"1",	"Запись подключений в лог файл", _, true, 0.0, true, 1.0);
	g_CI_WelcomeSound		= CreateConVar("mf_welcomesound",		"atomhost/hello.mp3",	"Звук приветствия для ВОШЕДШЕГО игрока; \"off\" - выкл");
	g_CI_EnterSound			= CreateConVar("mf_entersound",			"atomhost/enter.mp3",	"Звук уведомления для ВСЕХ игроков о подключении нового игрока; \"off\" - выкл");
	g_CI_ExitSound			= CreateConVar("mf_exitsound",			"atomhost/exit.mp3",	"Звук уведомления для ВСЕХ игроков при отключении игрока; \"off\" - выкл");
	
	AutoExecConfig(true, "mf_conect_info");
	LoadTranslations("mf_conect_info.phrases"); 
	
	//отлавливаем изменение cvar's
	HookConVarChange(h_CI_COldHide, OnConVarChanged);
	HookConVarChange(h_CI_DOldHide, OnConVarChanged);
	HookConVarChange(h_CI_Enable, OnConVarChanged);
	HookConVarChange(g_CI_ShowLines, OnConVarChanged);
	HookConVarChange(g_CI_ShowStatusID, OnConVarChanged);
	HookConVarChange(g_CI_ShowRealName, OnConVarChanged);
	HookConVarChange(g_CI_ShowStatusVACBan, OnConVarChanged);
	HookConVarChange(g_CI_ShowCountVACBans, OnConVarChanged);
	HookConVarChange(g_CI_ShowGeo, OnConVarChanged);
	HookConVarChange(g_CI_ShowDistrict, OnConVarChanged);
	HookConVarChange(g_CI_Log, OnConVarChanged);
	HookConVarChange(h_CI_IPShow, OnConVarChanged);
	HookConVarChange(h_CI_StemIDShow, OnConVarChanged);
	HookConVarChange(h_CI_DisconnectMsg, OnConVarChanged);
	
	
	// перехват событий
	HookEvent("player_connect",		player_connect,		EventHookMode_Pre);
	HookEvent("player_disconnect",	player_disconnect,	EventHookMode_Pre);
	
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_CI_COldHide)
		p_CI_coldhide = GetConVarBool(convar);
	else if (convar == h_CI_DOldHide)
		p_CI_doldhide = GetConVarBool(convar);
	else if (convar == h_CI_Enable)
		Enabled = GetConVarBool(convar);
	else if (convar == g_CI_ShowLines)
		p_CI_showlines = GetConVarBool(convar);
	else if (convar == g_CI_ShowStatusID)
		p_CI_showstatussteam = GetConVarBool(convar);
	else if (convar == g_CI_ShowGeo)
		p_CI_showgeoinfo = GetConVarBool(convar);
	else if (convar == g_CI_ShowDistrict)
		p_CI_showdistrict = GetConVarBool(convar);
	else if (convar == g_CI_Log)
		p_CI_writelog = GetConVarBool(convar);
	else if (convar == h_CI_IPShow)
		Enabled_ip = GetConVarBool(convar);
	else if (convar == h_CI_StemIDShow)
		Enabled_steamid	= GetConVarInt(convar);
	else if (convar == h_CI_DisconnectMsg) 
		p_CI_exitmsg = GetConVarBool(convar);
	else if (convar == g_CI_ShowRealName) 
		p_CI_realname = GetConVarBool(convar);
	else if (convar == g_CI_ShowStatusVACBan) 
		p_CI_banned = GetConVarBool(convar);
	else if (convar == g_CI_ShowCountVACBans) 
		p_CI_countvacbans = GetConVarBool(convar);
}

//загружаем конфиги из файла
public OnConfigsExecuted()
{
	GetConVarString(g_CI_WelcomeSound, s_CI_welcomesoung, sizeof(s_CI_welcomesoung));
	GetConVarString(g_CI_EnterSound, s_CI_entersoung, sizeof(s_CI_entersoung));
	GetConVarString(g_CI_ExitSound, s_CI_exitsoung, sizeof(s_CI_exitsoung));
	
	char buf[128];
	if(!StrEqual(s_CI_welcomesoung, "off", false))
	{
		//decl String:buf[128];
		Format(buf, 128, "sound/%s", s_CI_welcomesoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_CI_welcomesoung, true);
	}	
	if(!StrEqual(s_CI_entersoung, "off", false))
	{
		//decl String:buf[128];
		Format(buf, 128, "sound/%s", s_CI_entersoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_CI_entersoung, true);
	}	
	if(!StrEqual(s_CI_exitsoung, "off", false))
	{
		//decl String:buf[128];
		Format(buf, 128, "sound/%s", s_CI_exitsoung);
		AddFileToDownloadsTable(buf);
		PrecacheSound(s_CI_exitsoung, true);
	}
	
	p_CI_coldhide 			= GetConVarBool(h_CI_COldHide);
	p_CI_doldhide 			= GetConVarBool(h_CI_DOldHide);
	p_CI_showlines 			= GetConVarBool(g_CI_ShowLines);
	p_CI_showstatussteam 	= GetConVarBool(g_CI_ShowStatusID);
	p_CI_showgeoinfo 		= GetConVarBool(g_CI_ShowGeo);
	p_CI_showdistrict 		= GetConVarBool(g_CI_ShowDistrict);
	p_CI_writelog 			= GetConVarBool(g_CI_Log);
	p_CI_exitmsg 			= GetConVarBool(h_CI_DisconnectMsg);
	Enabled_ip			= GetConVarBool(h_CI_IPShow);
	Enabled_steamid		= GetConVarInt(h_CI_StemIDShow);
	p_CI_realname 			= GetConVarBool(g_CI_ShowRealName);
	p_CI_banned				= GetConVarBool(g_CI_ShowStatusVACBan);
	p_CI_countvacbans		= GetConVarBool(g_CI_ShowCountVACBans);
}


public void OnMapStart()
{
	//выключаем клагин, чтобы он не засыпал сервер запросами при массовом коннекте, а затем включам по таймеру
	Enabled = false;
	CreateTimer(GetConVarFloat(g_CI_PTimer), t_star_connect_info);	
}

// включаем плагин обратно, если он был включен
public Action:t_star_connect_info(Handle:timer)
{
	if(GetConVarBool(h_CI_Enable)) 
		Enabled = true;
	return Plugin_Stop;
}

// игрок приконнектился
public Action:player_connect(Handle:event, const String:name[], bool:silent)
{
    if (p_CI_coldhide)
    {
        decl String:sSteam[64], String:sName[64], String:sAddress[32];
        GetEventString(event, "name", sName, sizeof(sName));
        GetEventString(event, "networkid", sSteam, sizeof(sSteam));
        GetEventString(event, "address", sAddress, sizeof(sAddress));
        LogToGame("\"%s<%i><%s><>\" connected, address \"%s\"", sName, GetEventInt(event, "userid"), sSteam, sAddress);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}  

public Action:player_disconnect(Handle:event, const String:name[], bool:silent)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)//вложеный IF специально!!!
	{
		if(!IsFakeClient(client)){
			if(p_CI_exitmsg) 
			CPrintToChatAll("%t", "player disconnect", client); //показываем сообщение об отключении
			
			if(!StrEqual(s_CI_exitsoung, "off", false))
				EmitSoundToAll(s_CI_exitsoung); // играем звук выхода
		}
	}
	if(p_CI_doldhide) {
		return Plugin_Handled;
	/*дописать код LogToGame*/
	}
	else 
		return Plugin_Continue;
}

public void OnClientPutInServer(client){		
	// глушим недоразумения в зачатке
	if(!Enabled || IsFakeClient(client) || !GetClientIP(client, g_IP[client], 25)) 
		return;
	
	// играем приветствие
	if(!StrEqual(s_CI_welcomesoung, "off", false) && IsClientInGame(client)){
			EmitSoundToClient(client, s_CI_welcomesoung);
	}
	
	// играем уведомление для игроков
	if(!StrEqual(s_CI_entersoung, "off", false))
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && i!=client)
				EmitSoundToClient(i, s_CI_entersoung);
				
		}
	}
		
	//открываем соединенее с сервером и храним хендл
	new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(socket, GetClientUserId(client));
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "xn--e1ajbkae6a.xn--80ayfbpcev.xn--p1ai", 80);
} 


// отправка запроса
public OnSocketConnected(Handle:socket, any:id)
{
	int client = GetClientOfUserId(id);
	
	if (!client)
		return;
	
	char steamid[20], _GET[300];
	GetClientAuthId(client, AuthId_SteamID64, steamid, 25);
	
	//формируем тело запроса
	Format(_GET, 300, "GET /get_xml.php?ip=%s&id=%s HTTP/1.0\r\nHost: xn--e1ajbkae6a.xn--80ayfbpcev.xn--p1ai\r\nConnection: close\r\n\r\n", g_IP[client], steamid);
	//посылаем
	SocketSend(socket, _GET);
}

// обрабатываем р-ат запроса
public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:id)
{
	CloseHandle(socket); // прикрываем дырочку
	int client = GetClientOfUserId(id);
	
	if(!client)
		return;

	char result[12][255];

	/* return
1	;76561197994596381 - steamid64
2	;1 - lic status
3	;Андрей - real name
4	;Россия - county
5	;Сибирский федеральный округ - district
6	;Красноярский край - region
7	;Красноярск - city
8	;unknown - provider
9	;1 - bannes
10	;2 - count vac bans
	*/

	if ((ExplodeString(receiveData, ";", result, 12, 255)) > 1)
	{
		char steamid[25],i_country[25],i_city[35],i_region[50];
		GetClientAuthId(client, AuthId_Steam2, steamid, 20);
		
		// печатаем верхнюю границу, если нужно
		if(p_CI_showlines) 
			CPrintToChatAll("%t", "line");
		
		// печатаем стим и статус лицензии если нужно
		if (p_CI_showstatussteam){
			if(StringToInt(result[2])>0) 
				CPrintToChatAll("%t", "enter steam", client);
			else 
				CPrintToChatAll("%t", "enter nosteam", client);
		}
		else 
			CPrintToChatAll("%t", "enter", client);	
		//name
		if (p_CI_realname && !StrEqual(result[3], "-", false)){
			CPrintToChatAll("%t", "user_name", result[3]);
		}
		
		// печатаем стимид
		switch (Enabled_steamid)
		{
		   case 1:
			 CPrintToChatAll("%t", "steamid", steamid);
		   case 2:
			  CPrintToChatAll("%t", "steamid", result[1]);
		   case 3:
			 CPrintToChatAll("%t %t", "steamid", steamid,  "steamid64", result[1]);
		}
		
		//ип
		if(Enabled_ip) 
			CPrintToChatAll("%t", "ip", g_IP[client]);
		
		//VAC
		if(p_CI_banned && StringToInt(result[9])>0)
		{
			if(p_CI_countvacbans && StringToInt(result[10])>0)	
				CPrintToChatAll("%t, %t", "vac_banned", "vac_bans_cont", StringToInt(result[10]));
			else
				CPrintToChatAll("%t", "vac_banned");
		}
		else if(p_CI_countvacbans && StringToInt(result[10])>0)	
				CPrintToChatAll("%t", "vac_bans_cont", StringToInt(result[10]));
		
			
		
		if (p_CI_showgeoinfo)
		{
			//country 
			if (!StrEqual(result[4], "-", false))
			{
				Format(i_country, 25, "%s", result[4]); 
				
				if (!StrEqual(result[7], "-", false))
				{
					//city
					Format(i_city, 35, "%s", result[7]);
					//region
					Format(i_region, 50, "%s", result[6]);
					CPrintToChatAll("%t%t%t", "country", i_country, "city", i_city, "region" ,i_region);	
				}
				else
					CPrintToChatAll("%t", "country", i_country);
			}	
		}
		//district
		if(p_CI_showdistrict && !StrEqual(result[5], "-", false)){
			CPrintToChatAll("%t", "district", result[5]);
		}
		
		// печатаем нижнюю границу, если нужно
		if(p_CI_showlines) 
			CPrintToChatAll("%t", "line");
		
		//лог
		if (p_CI_writelog) 
		{
			char date[21], file[PLATFORM_MAX_PATH];
			FormatTime(date, sizeof(date), "%d%m%y", -1);
			BuildPath(Path_SM, file, sizeof(file), "logs/connect_info_%s.log", date); 
			LogToFileEx(file, "%s - %s (%s) - %N - %s - %s", g_IP[client],  steamid, result[1], client, i_country, i_city);
		}
	}
}

public OnSocketDisconnected(Handle:socket, any:id)
{
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:id)
{
	CloseHandle(socket);
	if(errorType !=3) LogError("Ошибка сокета (errno %d)", errorNum);
}

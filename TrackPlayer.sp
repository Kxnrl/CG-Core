#include <csgogamers>
#include <kylestock>
#pragma newdecls required //let`s go! new syntax!!!
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define Build 436
#define PLUGIN_VERSION " 7.8.8 - 2017/06/14 20:11 "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "
#define TRANSDATASIZE 12695

//////////////////////////////
//		GLOBAL VARIABLES	//
//////////////////////////////
//enum
Clients g_eClient[MAXPLAYERS+1][Clients];
Handles g_eHandle[Handles];
Forward g_Forward[Forward];
hEvents g_eEvents[hEvents];
TextHud g_TextHud[MAX_CHANNEL][TextHud];

//全部变量
int g_iServerId;
int g_iConnect_csgo;
int g_iConnect_discuz;
int g_iNowDate;
bool g_bLateLoad;
char g_szIP[32];
char g_szRconPwd[32];
char g_szHostName[256];
char g_szLogFile[128];
char g_szTempFile[128];
EngineVersion g_eGame;

//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "playertrack/apis.sp"
#include "playertrack/auth.sp"
#include "playertrack/cmds.sp"
#include "playertrack/event.sp"
#include "playertrack/init.sp"
#include "playertrack/lily.sp"
#include "playertrack/misc.sp"
#include "playertrack/sign.sp"
#include "playertrack/sqlcb.sp"
#include "playertrack/track.sp"

//////////////////////////////
//		PLUGIN DEFINITION	//
//////////////////////////////
public Plugin myinfo = 
{
	name		= "CSGOGAMERS.COM - Core",
	author		= "Kyle",
	description = "Player Tracker System",
	version		= PLUGIN_VERSION,
	url			= "http://steamcommunity.com/id/_xQy_/"
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//Mark native
	MarkNative();

	//创建API
	InitNative();
	
	//创建全局Forward
	InitForward();

	//Late load?
	g_bLateLoad = late;

	//注册函数库
	RegPluginLibrary("csgogamers");

	//Fix Plugin Load
	SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
	Format(g_szRconPwd, 32, "%d", GetRandomInt(10000000, 99999999));
	SetConVarString(FindConVar("rcon_password"), g_szRconPwd); 

	return APLRes_Success;
}

public void OnPluginStart()
{
	//建立Log文件
	InitLogFile();
	
	//初始化日期
	InitDate();

	//读取服务器IP地址
	InitServerIP();

	//连接到数据库
	SQL_TConnect_csgo();
	SQL_TConnect_discuz();
	
	//初始化翻译数据
	LoadTranstion();

	//监听控制台命令
	InitCommands();

	//获取所有Event
	InitEvents();
	
	//获取游戏模式
	InitGame();
	
	//初始化论坛数据
	InitDiscuz();
	
	//通用Timer
	CreateTimer(1.0, Timer_GlobalTimer, _, TIMER_REPEAT);
	
	//注册Timer
	CreateTimer(90.0, Timer_GotoRegister, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	//保存所有玩家数据
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public void OnMapStart()
{
	for(int channel = 0; channel < MAX_CHANNEL; ++channel)
	{
		g_TextHud[channel][iEntRef] = INVALID_ENT_REFERENCE;
		g_TextHud[channel][fHolded] = GetGameTime();
		g_TextHud[channel][hTimer] = INVALID_HANDLE;
		g_TextHud[channel][szPosX][0] = '\0';
		g_TextHud[channel][szPosY][0] = '\0';
	}
}

public void OnConfigsExecuted()
{
	//Lock Cvars
	SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
	SetConVarInt(FindConVar("sv_disable_motd"), 0);
	SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
	SetConVarString(FindConVar("rcon_password"), g_szRconPwd, false, false);
}

//////////////////////////////
//		ON CLIENT EVENT		//
//////////////////////////////
public void OnClientConnected(int client)
{
	//初始化Client数据
	InitClient(client);
	CreateTimer(0.1, Timer_AuthorizedClient, client, TIMER_REPEAT);
}

public Action Timer_AuthorizedClient(Handle timer, int client)
{
	if(!IsClientConnected(client))
		return Plugin_Stop;

	if(IsFakeClient(client))
	{
		OnClientVipChecked(client);
		return Plugin_Stop;
	}

	char FriendID[32];
	if(!GetClientAuthId(client, AuthId_SteamID64, FriendID, 32, true))
		return Plugin_Continue;
	
	if(StrContains(FriendID, "765") != 0)
		return Plugin_Continue;

	LoadClientDiscuzData(client, FriendID);
	OnClientVipChecked(client);

	return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client))
	{
		OnClientDataLoaded(client);
		return;
	}

	//从数据库查询初始数据
	//如果连不上数据库直接就跳过了
	if(g_eHandle[DB_Game] == INVALID_HANDLE)
	{
		LogToFileEx(g_szLogFile, "Query Client[%N] Failed:  Database is not avaliable!", client);
		LogError("Query Client[%N] Failed:  Database is not avaliable!", client);
		SQL_TConnect_csgo();
		CreateTimer(5.0, Timer_ReLoadClient, GetClientUserId(client));
		return;
	}

	GetClientIP(client, g_eClient[client][szIP], 32);

	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT id, onlines, lasttime, number, signature, signnumber, signtime, groupid, groupname, lilyid, lilydate, active, daytime, flags FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetClientStat, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void OnClientDisconnect(int client)
{
	//玩家还没加入到游戏就断线了
	if(!IsClientInGame(client) || IsFakeClient(client))
		return;

	//检查CP在线情况
	CheckingCP(client);

	//杀掉签到Timer
	if(g_eClient[client][hSignTimer] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hSignTimer]);
		g_eClient[client][hSignTimer] = INVALID_HANDLE;
	}

	if(g_eClient[client][hListener] != INVALID_HANDLE)
	{
		KillTimer(g_eClient[client][hListener]);
		g_eClient[client][hListener] = INVALID_HANDLE;
	}

	//如果客户没有成功INSERT ANALYTICS
	if(g_eClient[client][iAnalyticsId] <= 0 || !g_eClient[client][iConnectTime])
	{
		g_eClient[client][iConnectTime] = 0;
		return;
	}

	//执行回写数据
	//数据库不可用或没加载成功就不用了
	if(g_eHandle[DB_Game] != INVALID_HANDLE && g_eClient[client][bLoaded])
	{
		//保存数据
		SaveClient(client);
	}
}
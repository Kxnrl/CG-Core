#include <csgogamers>
#pragma newdecls required //let`s go! new syntax!!!
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define Build 385
#define PLUGIN_VERSION " 7.0.2 - 2017/02/03 20:17 "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "
#define TRANSDATASIZE 12577

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
//enum
Clients g_eClient[MAXPLAYERS+1][Clients];
Handles g_eHandle[Handles];
Forward g_Forward[Forward];
hEvents g_eEvents[hEvents];

//全部变量
int g_iServerId = -1;
int g_iConnect_csgo;
int g_iConnect_discuz;
int g_iNowDate;
bool g_bLateLoad;
char g_szIP[32];
char g_szHostName[256];
char g_szLogFile[128];
char g_szTempFile[128];

//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "playertrack/apis.sp"
#include "playertrack/auth.sp"
#include "playertrack/cmds.sp"
#include "playertrack/event.sp"
#include "playertrack/lily.sp"
#include "playertrack/misc.sp"
#include "playertrack/sign.sp"
#include "playertrack/sqlcb.sp"
#include "playertrack/stock.sp"
#include "playertrack/track.sp"

//////////////////////////////
//		PLUGIN DEFINITION	//
//////////////////////////////
public Plugin myinfo = 
{
	name		= "[CG] - Core",
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
	//创建API
	InitNative();
	
	//创建全局Forward
	InitForward();

	g_bLateLoad = late;

	//注册函数库
	RegPluginLibrary("csgogamers");

	return APLRes_Success;
}

public void OnPluginStart()
{
	//建立Log文件
	BuildPath(Path_SM, g_szLogFile, 128, "logs/Core.log");
	
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
	
	//建立监听Timer
	CreateTimer(1.0, Timer_Tracking, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	//保存所有玩家数据
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			OnClientDisconnect(i);
}

public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
	if(g_szHostName[0] != '\0')
		SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
}

//////////////////////////////
//		ON CLIENT EVENT		//
//////////////////////////////
public void OnClientConnected(int client)
{
	//初始化Client数据
	InitClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	//过滤BOT和FakeClient
	g_eClient[client][bIsBot] = false;

	if(!IsValidClient(client, true))
	{
		g_eClient[client][bIsBot] = true;
		OnClientDataLoaded(client);
		OnClientVipChecked(client);
		return;
	}

	//re fixed
	InitClient(client);

	//从数据库查询初始数据
	//如果连不上数据库直接就跳过了
	if(g_eHandle[DB_Game] == INVALID_HANDLE)
	{
		//Call Forward让其它程序也执行
		OnClientDataLoaded(client);
		OnClientVipChecked(client);
		LogToFileEx(g_szLogFile, "Query Client[%N] Failed:  Database is not avaliable!", client);
		LogError("Query Client[%N] Failed:  Database is not avaliable!", client);
		SQL_TConnect_csgo();
		//CreateTimer(5.0, Timer_ReLoadClient, GetClientUserId(client));
		return;
	}

	GetClientIP(client, g_eClient[client][szIP], 32);

	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT id, onlines, lasttime, number, signature, signnumber, signtime, groupid, groupname, lilyid, lilydate, active FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
	MySQL_Query(g_eHandle[DB_Game], SQLCallback_GetClientStat, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void OnClientDisconnect(int client)
{
	//Bot直接返回
	if(g_eClient[client][bIsBot])
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
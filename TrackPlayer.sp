#pragma newdecls required //let`s go! new syntax!!!
//Build 365
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define PLUGIN_VERSION " 6.1.2 - 2016/12/16 07:53 "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "
#define TRANSDATASIZE 11023

//////////////////////////////
//			INCLUDES		//
//////////////////////////////
#include <sourcemod>
#include <cg_core>

//////////////////////////////
//			ENUMS			// 
//////////////////////////////
//玩家数据
enum Clients
{
	iUserId,
	iUID,
	iGetShare,
	iSignNum,
	iSignTime,
	iConnectTime,
	iPlayerId,
	iNumber,
	iOnline,
	iVitality,
	iLastseen,
	iDataRetry,
	iAnalyticsId,
	iGroupId,
	iVipType,
	iCPId,
	iCPDate,
	bool:bLoaded,
	bool:bIsBot,
	bool:bListener,
	bool:bAllowLogin,
	bool:bTwiceLogin,
	bool:bLoginProc,
	String:szIP[32],
	String:szGroupName[64],
	String:szSignature[256],
	String:szDiscuzName[128],
	String:szAdminFlags[64],
	String:szInsertData[512],
	String:szUpdateData[512],
	String:szNewSignature[256],
	Handle:hSignTimer,
	Handle:hListener,
}

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
//Handles
Handle g_hDB_csgo;
Handle g_hDB_discuz;
Handle g_hCVAR;
Handle g_hKeyValue;

//Forwards
Handle g_fwdOnServerLoaded;
Handle g_fwdOnClientDailySign;
Handle g_fwdOnClientDataLoaded;
Handle g_fwdOnClientAuthLoaded;
Handle g_fwdOnAPIStoreSetCredits;
Handle g_fwdOnAPIStoreGetCredits;
Handle g_fwdOnClientOnClientVipChecked;
Handle g_fwdOnCPCouple;
Handle g_fwdOnCPDivorce;
Handle g_fwqOnNewDay;
Handle g_fwqOnCheckAuthTerm;

//enum
Clients g_eClient[MAXPLAYERS+1][Clients];

//全部变量
int g_iServerId = -1;
int g_iConnect_csgo;
int g_iConnect_discuz;
int g_iNewDayLeft;
int g_iNowDate;
bool g_bLateLoad;
char g_szIP[64];
char g_szHostName[256];
char g_szLogFile[128];
char g_szTempFile[128];

//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "playertrack/auth.sp"
#include "playertrack/cmds.sp"
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
	name		= " [CG] - Core ",
	author		= "Kyle",
	description = "Player Tracker System",
	version		= PLUGIN_VERSION,
	url			= "http://steamcommunity.com/id/_xQy_/"
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public void OnPluginStart()
{
	//检查日期
	GetNowDate();
	
	//建立Log文件
	BuildPath(Path_SM, g_szLogFile, 128, "logs/Core.log");
	
	//建立临时储存文件
	BuildTempLogFile();

	//锁定ConVar
	g_hCVAR = FindConVar("sv_hibernate_when_empty");
	SetConVarInt(g_hCVAR, 0);
	HookConVarChange(g_hCVAR, OnSettingChanged);

	//连接到数据库
	SQL_TConnect_csgo();
	SQL_TConnect_discuz();
	
	//初始化游戏数据
	LoadTranstion();

	//监听控制台命令
	RegConsoleCmd("sm_sign", Command_Login);
	RegConsoleCmd("sm_qiandao", Command_Login);
	RegConsoleCmd("sm_online", Command_Online);
	RegConsoleCmd("sm_track", Command_Track);
	RegConsoleCmd("sm_rz", Command_GetAuth);
	RegConsoleCmd("sm_cp", Command_CP);
	RegConsoleCmd("sm_lily", Command_CP);
	RegConsoleCmd("sm_cg", Command_Menu);
	RegConsoleCmd("sm_qm", Command_Signature);

	//创建管理员命令
	RegAdminCmd("sm_reloadadv", Command_ReloadAdv, ADMFLAG_BAN);

	//创建全局Forward
	g_fwdOnServerLoaded = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore, Param_Cell);
	g_fwdOnAPIStoreSetCredits = CreateGlobalForward("CG_APIStoreSetCredits", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_fwdOnAPIStoreGetCredits = CreateGlobalForward("CG_APIStoreGetCredits", ET_Event, Param_Cell);
	g_fwdOnClientDailySign = CreateGlobalForward("CG_OnClientDailySign", ET_Ignore, Param_Cell);
	g_fwdOnClientDataLoaded = CreateGlobalForward("CG_OnClientLoaded", ET_Ignore, Param_Cell);
	g_fwdOnClientAuthLoaded = CreateGlobalForward("PA_OnClientLoaded", ET_Ignore, Param_Cell);
	g_fwdOnCPCouple = CreateGlobalForward("CP_OnCPCouple", ET_Ignore, Param_Cell, Param_Cell);
	g_fwdOnCPDivorce = CreateGlobalForward("CP_OnCPDivorce", ET_Ignore, Param_Cell, Param_Cell);
	g_fwqOnNewDay = CreateGlobalForward("CG_OnNewDay", ET_Ignore, Param_Cell);
	g_fwqOnCheckAuthTerm = CreateGlobalForward("CG_OnCheckAuthTerm", ET_Event, Param_Cell, Param_Cell);
	
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

//////////////////////////////
//		Creat Native		//
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//创建API
	CreateNative("CG_GetServerID", Native_GetServerID);
	CreateNative("CG_GetOnlines", Native_GetOnlines);
	CreateNative("CG_GetVitality", Native_GetVitality);
	CreateNative("CG_GetLastseen", Native_GetLastseen);
	CreateNative("CG_GetPlayerID", Native_GetPlayerID);
	CreateNative("CG_GetSignature", Native_GetSingature);
	CreateNative("CG_GetDiscuzUID", Native_GetDiscuzUID);
	CreateNative("CG_GetDiscuzName", Native_GetDiscuzName);
	CreateNative("CG_GetGameDatabase", Native_GetGameDatabase);
	CreateNative("CG_GetDiscuzDatabase", Native_GetDiscuzDatabase);
	CreateNative("CG_SaveDatabase", Native_SaveDatabase);
	CreateNative("CG_SaveForumData", Native_SaveForumData);
	CreateNative("VIP_IsClientVIP", Native_IsClientVIP);
	CreateNative("VIP_SetClientVIP", Native_SetClientVIP);
	CreateNative("VIP_GetVipType", Native_GetVipType);
	CreateNative("PA_GetGroupID", Native_GetGroupID);
	CreateNative("PA_GetGroupName", Native_GetGroupName);
	CreateNative("CP_GetPartner", Native_GetCPPartner);
	CreateNative("CP_GetDate", Native_GetCPDate);
	CreateNative("CG_ShowNormalMotd", Native_ShowNormalMotd);
	CreateNative("CG_ShowHiddenMotd", Native_ShowHiddenMotd);
	CreateNative("CG_RemoveMotd", Native_RemoveMotd);

	g_fwdOnClientOnClientVipChecked = CreateForward(ET_Ignore, Param_Cell);
	CreateNative("HookClientVIPChecked", Native_HookClientOnClientVipChecked);

	//读取服务器IP地址
	int ip = GetConVarInt(FindConVar("hostip"));
	Format(g_szIP, 64, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

	g_bLateLoad = late;

	//注册函数库
	RegPluginLibrary("csgogamers");

	return APLRes_Success;
}

void OnServerLoadSuccess()
{
	//Call Forward
	Call_StartForward(g_fwdOnServerLoaded);
	Call_Finish();
}

void OnClientSignSucessed(int client)
{
	//Call Forward
	Call_StartForward(g_fwdOnClientDailySign);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientDataLoaded(int client)
{
	//输出控制台数据
	PrintConsoleInfo(client);

	//Call Forward
	Call_StartForward(g_fwdOnClientDataLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientAuthLoaded(int client)
{
	//Call Forward
	Call_StartForward(g_fwdOnClientAuthLoaded);
	Call_PushCell(client);
	Call_Finish();
}

void OnClientVipChecked(int client)
{
	//Check Flags
	GetClientFlags(client);

	//Call Forward
	Call_StartForward(g_fwdOnClientOnClientVipChecked);
	Call_PushCell(client);
	Call_Finish();
}

bool OnAPIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
	bool result;

	//Call Forward
	Call_StartForward(g_fwdOnAPIStoreSetCredits);
	Call_PushCell(client);
	Call_PushCell(credits);
	Call_PushString(reason);
	Call_PushCell(immed);
	Call_Finish(result);
	
	return result;
}

int OnAPIStoreGetCredits(int client) 
{
	int result;
	
	//Call Forward
	Call_StartForward(g_fwdOnAPIStoreGetCredits);
	Call_PushCell(client);
	Call_Finish(result);

	return result;
}

bool OnCheckAuthTerm(int client, int AuthId) 
{
	bool result;
	
	//Call Forward
	Call_StartForward(g_fwqOnCheckAuthTerm);
	Call_PushCell(client);
	Call_PushCell(AuthId);
	Call_Finish(result);

	return result;
}

void OnNewDay()
{
	char m_szDate[32];
	FormatTime(m_szDate, 64, "%Y%m%d", GetTime());
	g_iNowDate = StringToInt(m_szDate);
	LogMessage("CG Server: On New Date %s", m_szDate);
	
	//Call Forward
	Call_StartForward(g_fwqOnNewDay);
	Call_PushCell(g_iNowDate);
	Call_Finish();
}

public int Native_GetServerID(Handle plugin, int numParams)
{
	return g_iServerId;
}

public int Native_GetOnlines(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iOnline];
}

public int Native_GetVitality(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVitality];
}

public int Native_GetLastseen(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iLastseen];
}

public int Native_GetPlayerID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iPlayerId];
}

public int Native_GetDiscuzUID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iUID];
}

public int Native_GetDiscuzName(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szDiscuzName], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Forum name.");
	}
}

public int Native_GetSingature(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szSignature], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Singature.");
	}
}

public int Native_IsClientVIP(Handle plugin, int numParams)
{
	if(!g_eClient[GetNativeCell(1)][iVipType])
		return false;
	else
		return true;
}

public int Native_SetClientVIP(Handle plugin, int numParams)
{
	SetClientVIP(GetNativeCell(1), 1);
}

public int Native_GetVipType(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iVipType];
}

public int Native_HookClientOnClientVipChecked(Handle plugin, int numParams)
{
	AddToForward(g_fwdOnClientOnClientVipChecked, plugin, GetNativeCell(1));
}

public int Native_SaveDatabase(Handle plugin, int numParams)
{
	if(g_hDB_csgo != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 0);
			ResetPack(data);
			MySQL_Query(g_hDB_csgo, SQLCallback_SaveDatabase, m_szQuery, data);
		}
	}
}

public int Native_SaveForumData(Handle plugin, int numParams)
{
	if(g_hDB_discuz != INVALID_HANDLE)
	{
		char m_szQuery[512];
		if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
		{
			Handle data = CreateDataPack();
			WritePackString(data, m_szQuery);
			WritePackCell(data, 1);
			ResetPack(data);
			MySQL_Query(g_hDB_discuz, SQLCallback_SaveDatabase, m_szQuery, data);
		}
	}
}

public int Native_GetGroupID(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iGroupId];
}

public int Native_GetGroupName(Handle plugin, int numParams)
{
	if(SetNativeString(2, g_eClient[GetNativeCell(1)][szGroupName], GetNativeCell(3)) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Group Name.");
	}
}

public int Native_GetCPPartner(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iCPId];
}

public int Native_GetCPDate(Handle plugin, int numParams)
{
	return g_eClient[GetNativeCell(1)][iCPDate];
}

public int Native_GetGameDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_hDB_csgo);
}

public int Native_GetDiscuzDatabase(Handle plugin, int numParams)
{
	return view_as<int>(g_hDB_discuz);
}

public int Native_ShowNormalMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	int width = GetNativeCell(2)-12;
	int height = GetNativeCell(3)-80;
	char m_szUrl[192];
	if(GetNativeString(4, m_szUrl, 192) == SP_ERROR_NONE)
	{
		PrepareUrl(width, height, m_szUrl);
		ShowMOTDPanel(client, "CSGOGAMERS Motd", m_szUrl, MOTDPANEL_TYPE_URL);
		return true;
	}
	else
	{
		ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
		return false;
	}
}

public int Native_ShowHiddenMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);

	char m_szUrl[192];
	if(GetNativeString(4, m_szUrl, 192) == SP_ERROR_NONE)
		return false;
	else
		ShowHiddenMOTDPanel(client, m_szUrl, MOTDPANEL_TYPE_URL);
	
	return true;
}

public int Native_RemoveMotd(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
	ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
	return true;
}

//////////////////////////////
//			HOOK CONVAR		//
//////////////////////////////
public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	//锁定ConVar
	SetConVarInt(g_hCVAR, 0);
}

//////////////////////////////
//		ON CLIENT EVENT		//
//////////////////////////////
public void OnClientConnected(int client)
{
	//初始化Client数据
	InitializingClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	//过滤BOT和FakeClient
	g_eClient[client][bIsBot] = false;

	if(!IsValidClient(client, true))
	{
		g_eClient[client][bIsBot] = true;
		OnClientDataLoaded(client);
		OnClientAuthLoaded(client);
		OnClientVipChecked(client);
		return;
	}

	//re fixed
	InitializingClient(client);

	//从数据库查询初始数据
	//如果连不上数据库直接就跳过了
	if(g_hDB_csgo == INVALID_HANDLE)
	{
		//Call Forward让其它程序也执行
		OnClientAuthLoaded(client);
		OnClientDataLoaded(client);
		OnClientVipChecked(client);
		LogToFileEx(g_szLogFile, "Query Client[%N] Failed:  Database is not avaliable!", client);
		SQL_TConnect_csgo();
		CreateTimer(5.0, Timer_ReLoadClient, GetClientUserId(client));
		return;
	}

	GetClientIP(client, g_eClient[client][szIP], 32);

	char m_szAuth[32], m_szQuery[256];
	GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
	Format(m_szQuery, 256, "SELECT id, onlines, lasttime, number, signature, signnumber, signtime, groupid, groupname, lilyid, lilydate, active FROM playertrack_player WHERE steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
	MySQL_Query(g_hDB_csgo, SQLCallback_GetClientStat, m_szQuery, g_eClient[client][iUserId], DBPrio_High);
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
	if(g_eClient[client][iAnalyticsId] <= 0 || g_eClient[client][iConnectTime] == 0)
	{
		g_eClient[client][iConnectTime] = 0;
		return;
	}

	//执行回写数据
	//数据库不可用或没加载成功就不用了
	if(g_hDB_csgo != INVALID_HANDLE && g_eClient[client][bLoaded])
	{
		//保存数据
		SaveClient(client);
	}
}

public void InitializingClient(int client)
{
	g_eClient[client][bLoaded] = false;
	g_eClient[client][bListener] = false;
	g_eClient[client][bLoginProc] = false;
	g_eClient[client][bAllowLogin] = false;
	g_eClient[client][bTwiceLogin] = false;
	g_eClient[client][iUserId] = GetClientUserId(client);
	g_eClient[client][iUID] = -1;
	g_eClient[client][iSignNum] = 0;
	g_eClient[client][iSignTime] = 0;
	g_eClient[client][iConnectTime] = GetTime();
	g_eClient[client][iPlayerId] = 0;
	g_eClient[client][iNumber] = 0;
	g_eClient[client][iOnline] = 0;
	g_eClient[client][iVitality] = 0
	g_eClient[client][iLastseen] = 0;
	g_eClient[client][iDataRetry] = 0;
	g_eClient[client][iAnalyticsId] = -1;
	g_eClient[client][iVipType] = 0;
	g_eClient[client][iGroupId] = 0;
	g_eClient[client][iCPId] = -2;
	g_eClient[client][iCPDate] = 0;

	strcopy(g_eClient[client][szIP], 32, "127.0.0.1");
	strcopy(g_eClient[client][szSignature], 256, "数据读取中...");
	strcopy(g_eClient[client][szDiscuzName], 256, "未注册");
	strcopy(g_eClient[client][szAdminFlags], 64, "Unknown");
	strcopy(g_eClient[client][szInsertData], 512, "");
	strcopy(g_eClient[client][szUpdateData], 512, "");
	strcopy(g_eClient[client][szGroupName], 64, "未认证");
	strcopy(g_eClient[client][szNewSignature], 256, "");
}

public Action Timer_ReLoadClient(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		OnClientPostAdminCheck(client);
}
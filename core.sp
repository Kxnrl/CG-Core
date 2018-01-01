#include <kylestock>

#pragma semicolon 1
#pragma newdecls required //let`s go! new syntax!!!

#define PLUGIN_VERSION " 10.2.<commit_num> - <commit_date> "

enum Clients
{
    iPId,       //Player ID
    iUId,       //Discuz UID
    iGId,       //AuthGroup ID
    iTId,       //TrackAnalytics ID
    iNumber,    //Connect number
    iOnline,    //Online time total
    iGrowth,    //Grouwth
    iVitality,  //Vitality
    iDaily,
    iLastseen,
    iConnectTime,
    bool:bVip,
    bool:bLoaded,
    bool:bInGroup,
    bool:bRealName,
    String:szIP[32],
    String:szGroupName[16],
    String:szForumName[32],
    String:szSignature[256]
}
int g_ClientGlobal[MAXPLAYERS+1][Clients];

int g_iServerId;
int g_iNowDate;
char g_szIP[32];
char g_szRconPwd[32];
char g_szHostName[256];

Handle g_dbForum;
Handle g_dbGames;

#include "core/auth.sp"
#include "core/cache.sp"
#include "core/client.sp"
#include "core/couples.sp"
#include "core/dailysign.sp"
#include "core/database.sp"
#include "core/girlsfrontline.sp" // Girls Frontline
#include "core/globalapi.sp"
#include "core/hud.sp"
#include "core/menucmds.sp"
#include "core/signature.sp"
#include "core/server.sp"

//////////////////////////////
//     PLUGIN DEFINITION    //
//////////////////////////////
public Plugin myinfo = 
{
    name        = "CSGOGAMERS.COM - Core [Girls Frontline Edition]",
    author      = "~Kyle feat. UMP45~",
    description = "Player Tracker System",
    version     = PLUGIN_VERSION,
    url         = "https://ump45.moe"
};

//////////////////////////////
//      PLUGIN FORWARDS     //
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    AuthGroup_OnAskPluginLoad2();
    Client_OnAskPluginLoad2();
    Server_OnAskPluginLoad2();
    Couples_OnAskPluginLoad2();
    Database_OnAskPluginLoad2();
    GirlsFL_OnAskPluginLoad2();
    GlobalApi_OnAskPluginLoad2();
    HUD_OnAskPluginLoad2();

    RegPluginLibrary("core");

    return APLRes_Success;
}

public void OnPluginStart()
{
    AuthGroup_OnPluginStart();
    Cache_OnPluginStart();
    Couples_OnPluginStart();
    Client_OnPluginStart();
    Database_OnPluginStart();
    DailySign_OnPluginStart();
    GirlsFL_OnPluginStart();
    GlobalApi_OnPluginStart();
    MenuCmds_OnPluginStart();
    Signature_OnPluginStart();
    Server_OnPluginStart();
    HUD_OnPluginStart();
    
    CreateTimer(1.0, Timer_GlobalTimer, _, TIMER_REPEAT);
}

public void OnMapStart()
{
    GlobalApi_OnMapStart();
}

public void OnMapEnd()
{
    GlobalApi_OnMapStart();
}

public void OnConfigsExecuted()
{
    SetConVarString(FindConVar("host_name_store", "1", false, false);
    SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
    SetConVarString(FindConVar("rcon_password"), g_szRconPwd, false, false);
}

public Action Timer_GlobalTimer(Handle timer)
{
    GlobalApi_Forward_OnGlobalTimer();

    for(int client = 1; client <= MaxClients; ++client)
    {
        if(!IsClientInGame(client))
            continue;
        
        if(IsFakeClient(client))
            continue;
        
        HUD_OnGlobalTimer(client);
        
        if(!g_ClientGlobal[client][bLoaded])
            continue;

        if(g_ClientGlobal[client][iTId] < 1)
            continue;

        DailySign_OnGlobalTimer(client);
        Client_OnGlobalTimer(client);
        Couples_OnGlobalTimer(client);
    }

    Cache_OnGlobalTimer();
    Server_OnGlobalTimer();

    return Plugin_Continue;
}

public void OnClientConnected(int client)
{
    AuthGroup_OnClientConnected(client);
    Client_OnClientConnected(client);
    Couples_OnClientConnected(client);
    DailySign_OnClientConnected(client);
    Signature_OnClientConnected(client);
    GirlsFL_OnClientConnected(client);
    HUD_OnClientConnected(client);

    CreateTimer(0.1, OnClientAuthorizedPost, client, TIMER_REPEAT);
}

public Action OnClientAuthorizedPost(Handle timer, int client)
{
    if(!IsClientConnected(client))
        return Plugin_Stop;

    if(IsFakeClient(client))
    {
        GlobalApi_Forward_OnClientVipChecked(client);
        return Plugin_Stop;
    }

    char FriendID[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, FriendID, 32, true))
        return Plugin_Continue;

    Cache_LoadClientDiscuzData(client, FriendID);
    GlobalApi_Forward_OnClientVipChecked(client);

    return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
    {
        Client_Forward_OnClientLoaded(client);
        return;
    }

    Client_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
    if(!IsClientInGame(client) || IsFakeClient(client))
        return;

    AuthGroup_OnClientDisconnect(client);
    Cache_OnClientDisconnect(client);
    Couples_OnClientDisconnect(client);
    Signature_OnClientDisconnect(client);
    DailySign_OnClientDisconnect(client);
    Client_OnClientDisconnect(client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(!IsValidClient(client))
        return Plugin_Continue;

    if(Couples_OnClientSay(client, sArgs) >= Plugin_Handled)
        return Plugin_Stop;

    if(Signature_OnClientSay(client, sArgs) >= Plugin_Handled)
        return Plugin_Stop;

    if(sArgs[0] != '@')
        return Plugin_Continue;

    if(strcmp(command, "say", false) == 0)
    {
        if(!CheckCommandAccess(client, "sm_reloadadv", ADMFLAG_BAN))
            return Plugin_Continue;

        UTIL_SendChatToAll(client, sArgs[1]);
        LogAction(client, -1, "\"%L\" 管理员频道喊话 [%s]", client, sArgs[1]);

        return Plugin_Stop;
    }
    else if(strcmp(command, "say_team", false) == 0 || strcmp(command, "say_squad", false) == 0)
    {
        UTIL_SendChatToAdmins(client, sArgs[1]);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

void UTIL_LogError(const char[] module, const char[] error, any ...)
{
    char buffer[1024];
    VFormat(buffer, 1024, error, 3);
    LogToFileEx("addons/sourcemod/logs/Core.log", "%s -> %s", module, buffer);
}

void UTIL_SendChatToAll(int client, const char[] message)
{
    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;

        ClientCommand(target, "play buttons/button18.wav");
        PrintToChat(target, "[\x10管理员频道\x01] \x0C%N\x01 :\x07  %s", client, message);
    }

    char fmt[256];
    Format(fmt, 256, "[管理员频道] %N\n %s", client, message);
    GlobalApi_ShowGameText(INVALID_HANDLE, fmt, 10.0, "233 0 0", "-1.0", "0.32", 0);
}

void UTIL_SendChatToAdmins(int client, const char[] message)
{
    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;
        
        if(!CheckCommandAccess(target, "sm_reloadadv", ADMFLAG_BAN) && target != client)
            continue;

        PrintToChat(target, "[\x0A发送至管理员\x01] \x05%N\x01 :\x07  %s", client, message);
    }
}

void UTIL_PrintWelcomeMessage(int client)
{
    int timeleft;
    GetMapTimeLeft(timeleft);
    if(timeleft < 60)
        return;

    char szTimeleft[32], szMap[128];
    Format(szTimeleft, 32, "%d:%02d", timeleft / 60, timeleft % 60);
    GetCurrentMap(szMap, 128);

    PrintToConsole(client, "-----------------------------------------------------------------------------------------------");
    PrintToConsole(client, "                                                                                               ");
    PrintToConsole(client, "                                     欢迎来到[CG]游戏社区                                      ");    
    PrintToConsole(client, "                                                                                               ");
    PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %d.0   -   主程序版本: %s", g_szHostName, RoundToNearest(1.0 / GetTickInterval()), PLUGIN_VERSION);
    PrintToConsole(client, " ");
    PrintToConsole(client, "论坛地址: https://csgogamers.com  官方QQ群: 107421770  官方YY: 497416");
    PrintToConsole(client, "当前地图: %s   剩余时间: %s", szMap, szTimeleft);
    PrintToConsole(client, "                                                                                               ");
    PrintToConsole(client, "服务器基础命令:");
    PrintToConsole(client, "核心命令： !cg    [核心菜单]");
    PrintToConsole(client, "商店相关： !store [打开商店]  !credits  [显示余额]      !inv       [查看库存]");
    PrintToConsole(client, "地图相关： !rtv   [滚动投票]  !revote   [重新选择]      !nominate  [预定地图]");
    PrintToConsole(client, "娱乐相关： !music [点歌菜单]  !mapmusic [停止地图音乐]  !dj        [停止点播歌曲]");
    PrintToConsole(client, "其他命令： !sign  [每日签到]  !hide     [屏蔽足迹霓虹]  !tp/!seeme [第三人称视角]");
    PrintToConsole(client, "玩家认证： !track [查询认证]  !rz       [申请认证]");
    PrintToConsole(client, "搞基系统： !cp    [功能菜单]");
    PrintToConsole(client, "天赋系统： !talent[功能菜单]");
    PrintToConsole(client, "                                                                                               ");
    PrintToConsole(client, "-----------------------------------------------------------------------------------------------");        
    PrintToConsole(client, "                                                                                               ");
}

void UTIL_TQuery(Handle database, SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
    if(database == INVALID_HANDLE)
    {
        if(database == g_dbGames)
            Database_SQLCallback_ConnectToGames();
        else if(database == g_dbForum)
            Database_SQLCallback_ConnectToForum();
        
        UTIL_LogError("UTIL_TQuery", "Query To DB[%s] is INVALID_HANDLE -> %s", database == g_dbForum ? "discuz" : "csgo", query);
        return;
    }

    SQL_TQuery(database, callback, query, data, prio);
}

void UTIL_SQLTVoid(Handle database, const char[] query, DBPriority prio = DBPrio_Normal)
{
    DataPack data = new DataPack();
    data.WriteString(query);
    data.WriteCell(database == g_dbGames ? 0 : 1);
    data.Reset();
    UTIL_TQuery(database, Database_SQLCallback_Void, query, data, prio);
}

bool UTIL_GetEscapeName(int client, char[] buffer, int maxLen)
{
    char name[32];
    GetClientName(client, name, 32);
    SQL_EscapeString(g_dbGames, name, buffer, maxLen);
}

int UTIL_CalculatLevelByExp(int exp)
{
    int level = 0;
    int nexts = 1000;
    while(exp > nexts)
    {
        exp -= nexts;
        level++;
        nexts = level * 1000;
    }
    return level;
}
#include <kylestock>

#pragma newdecls required //let`s go! new syntax!!!

#define PLUGIN_VERSION " 8.21.469 - 2017/08/11 06:46 "

enum Clients
{
    iPId,
    iUId,
    iGId,
    iTId,
    iNumber,
    iOnline,
    iGrowth,
    iVitality,
    iDaily,
    iLastseen,
    iConnectTime,
    bool:bVip,
    bool:bLoaded,
    bool:bInGroup,
    bool:bRealName,
    String:szIP[32],
    String:szGroupName[32],
    String:szForumName[32],
    String:szGamesName[32],
    String:szSignature[256]
}
Clients g_ClientGlobal[MAXPLAYERS+1][Clients];

enum Handles
{
    Handle:KV_Local,
    Handle:Array_Groups,
    Handle:Array_Discuz
}
Handles g_GlobalHandle[Handles];

enum Discuz_Data
{
    iUId,
    iExpTime,
    iGrowths,
    bool:bIsRealName,
    String:szDName[24],
    String:szSteamId64[32]
}

//全部变量
int g_iServerId;
int g_iNowDate;
char g_szIP[32];
char g_szRconPwd[32];
char g_szHostName[256];

#include "core/authgroup.sp"
#include "core/clientdata.sp"
#include "core/couples.sp"
#include "core/dailysign.sp"
#include "core/database.sp"
#include "core/globalapi.sp"
#include "core/menucmds.sp"
#include "core/signature.sp"

//////////////////////////////
//        PLUGIN DEFINITION    //
//////////////////////////////
public Plugin myinfo = 
{
    name        = "CSGOGAMERS.COM - Core",
    author      = "Kyle",
    description = "Player Tracker System",
    version     = PLUGIN_VERSION,
    url         = "http://steamcommunity.com/id/_xQy_/"
};

//////////////////////////////
//      PLUGIN FORWARDS     //
//////////////////////////////
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    //Mark native
    Couples_OnAskPluginLoad2();
    Database_OnAskPluginLoad2();
    GlobalApi_OnAskPluginLoad2();

    //注册函数库
    RegPluginLibrary("csgogamers");

    //Fix Plugin Load
    SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
    FormatEx(g_szRconPwd, 32, "%d", GetRandomInt(10000000, 99999999));
    SetConVarString(FindConVar("rcon_password"), g_szRconPwd); 

    return APLRes_Success;
}

public void OnPluginStart()
{
    //Init date
    char m_szDate[32];
    FormatTime(m_szDate, 64, "%Y%m%d", GetTime());
    g_iNowDate = StringToInt(m_szDate);

    //Get server IP
    int ip = GetConVarInt(FindConVar("hostip"));
    FormatEx(g_szIP, 32, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    //Global timer
    CreateTimer(1.0, Timer_GlobalTimer, _, TIMER_REPEAT);

    //Create cache array
    g_GlobalHandle[Array_Discuz] = CreateArray(view_as<int>(Discuz_Data));
    g_GlobalHandle[Array_Groups] = CreateArray(ByteCountToCells(32));

    //Forward To Modules
    AuthGroup_OnPluginStart();
    Couples_OnPluginStart();
    Database_OnPluginStart();
    DailySign_OnPluginStart();
    GlobalApi_OnPluginStart();
    MenuCmds_OnPluginStart();
    Signature_OnPluginStart();
}

public void OnMapStart()
{
    //Forward To Modules
    GlobalApi_OnMapStart();
}

public void OnMapEnd()
{
    //Forward To Modules
    GlobalApi_OnMapStart();
}

public void OnConfigsExecuted()
{
    //Locked Cvars
    SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
    SetConVarInt(FindConVar("sv_disable_motd"), 1);
    SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
    SetConVarString(FindConVar("rcon_password"), g_szRconPwd, false, false);
}

public Action Timer_GlobalTimer(Handle timer)
{
    //Get Now time
    int unix_timestamp = GetTime();
    if(unix_timestamp % 3600 == 0)
    {
        char m_szDate[32];
        FormatTime(m_szDate, 32, "%H", unix_timestamp);
        OnNowTimeForward(StringToInt(m_szDate));
        FormatTime(m_szDate, 32, "%Y%m%d", unix_timestamp);
        int iDate = StringToInt(m_szDate);
        if(iDate > g_iNowDate)
        {
            OnNewDayForward(iDate);

            for(int client = 1; client <= MaxClients; ++client)
                g_ClientGlobal[client][iDaily] = 0;
        }
    }

    //Tracking
    if(g_GlobalHandle[KV_Local] != INVALID_HANDLE)
    {
        for(int client = 1; client <= MaxClients; ++client)
        {
            if(!IsClientInGame(client))
                continue;
            
            if(IsFakeClient(client))
                continue;
            
            if(!g_ClientGlobal[client][bLoaded])
                continue;

            if(g_ClientGlobal[client][iTId] < 1)
                continue;

            g_ClientGlobal[client][iDaily]++;
            
            DailySign_OnGlobalTimer(client);
            ClientData_OnGlobalTimer(client);
        }

        KeyValuesToFile(g_GlobalHandle[KV_Local], "addons/sourcemod/data/core.track.kv.txt");
    }

    OnGlobalTimer();

    return Plugin_Continue;
}

public void OnClientConnected(int client)
{
    //初始化Client数据
    ClientData_OnClientConnected(client);
    Couples_OnClientConnected(client);
    DailySign_OnClientConnected(client);
    Signature_OnClientConnected(client);

    CreateTimer(0.1, OnClientAuthorizedPost, client, TIMER_REPEAT);
}

public Action OnClientAuthorizedPost(Handle timer, int client)
{
    if(!IsClientConnected(client) || IsFakeClient(client))
        return Plugin_Stop;

    if(IsFakeClient(client))
    {
        OnClientVipChecked(client);
        return Plugin_Stop;
    }

    char FriendID[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, FriendID, 32, true))
    {
        OnClientVipChecked(client);
        return Plugin_Continue;
    }

    LoadClientDiscuzData(client, FriendID);
    OnClientVipChecked(client);

    return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
    if(!IsValidClient(client))
    {
        GlobalApi_OnClientLoaded(client);
        return;
    }

    GetClientIP(client, g_ClientGlobal[client][szIP], 32);

    char m_szAuth[32], m_szQuery[512];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
    Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.lasttime, a.number, a.signature, a.signnumber, a.signtime, a.groupid, a.groupname, a.lilyid, a.lilydate, a.active, a.daytime, b.name FROM playertrack_player a LEFT JOIN playertrack_player b ON a.lilyid = b.id WHERE a.steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
    MySQL_Query(false, Database_SQLCallback_GetClientBaseData, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void OnClientDisconnect(int client)
{
    //玩家还没加入到游戏就断线了
    if(!IsClientInGame(client) || IsFakeClient(client))
        return;

    //检查CP在线情况
    Couples_OnClientDisconnect(client);

    if(Signature_Data_Client[client][hListener] != INVALID_HANDLE)
    {
        KillTimer(Signature_Data_Client[client][hListener]);
        Signature_Data_Client[client][hListener] = INVALID_HANDLE;
    }

    if(DailySign_Data_Client[client][hSignTimer] != INVALID_HANDLE)
    {
        KillTimer(DailySign_Data_Client[client][hSignTimer]);
        DailySign_Data_Client[client][hSignTimer] = INVALID_HANDLE;
    }
    
    ClientData_OnClientDisconnect(client);
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

void UTIL_OnServerLoaded()
{
    //Cache server advertisment
    char m_szQuery[512];
    Format(m_szQuery, 512, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
    MySQL_Query(false, SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);

    //Update local data if server was crashed
    if(g_GlobalHandle[KV_Local] != INVALID_HANDLE)
        CloseHandle(g_GlobalHandle[KV_Local]);

    g_GlobalHandle[KV_Local] = CreateKeyValues("core_track", "", "");

    FileToKeyValues(g_GlobalHandle[KV_Local], "addons/sourcemod/data/core.track.kv.txt");
    
    while(KvGotoFirstSubKey(g_GlobalHandle[KV_Local], true))
    {
        char m_szAuthId[32], m_szIp[16];
        KvGetSectionName(g_GlobalHandle[KV_Local], m_szAuthId, 32);

        int m_iPlayerId = KvGetNum(g_GlobalHandle[KV_Local], "PlayerId", 0);
        int m_iConnect = KvGetNum(g_GlobalHandle[KV_Local], "Connect", 0);
        int m_iTrackId = KvGetNum(g_GlobalHandle[KV_Local], "TrackID", 0);
        KvGetString(g_GlobalHandle[KV_Local], "IP", m_szIp, 16, "127.0.0.1");
        int m_iLastTime = KvGetNum(g_GlobalHandle[KV_Local], "LastTime", 0);
        int m_iDaily = KvGetNum(g_GlobalHandle[KV_Local], "DayTime", 0);
        Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_iConnect, m_szIp, m_iLastTime, m_iDaily, m_iConnect, m_iPlayerId, m_iTrackId, m_szAuthId, m_iPlayerId);
        Handle data = CreateDataPack();
        WritePackString(data, m_szQuery);
        WritePackString(data, m_szAuthId);
        WritePackCell(data, m_iPlayerId);
        WritePackCell(data, m_iConnect);
        WritePackCell(data, m_iTrackId);
        WritePackString(data, m_szIp);
        WritePackCell(data, m_iLastTime);
        ResetPack(data);

        MySQL_Query(false, SQLCallback_SaveTempLog, m_szQuery, data);

        if(KvDeleteThis(g_GlobalHandle[KV_Local]))
        {
            char m_szAfter[32];
            KvGetSectionName(g_GlobalHandle[KV_Local], m_szAfter, 32);
            if(StrContains(m_szAfter, "STEAM", false) != -1)
                KvGoBack(g_GlobalHandle[KV_Local]);
        }
    }

    KvRewind(g_GlobalHandle[KV_Local]);
    KeyValuesToFile(g_GlobalHandle[KV_Local], "addons/sourcemod/data/core.track.kv.txt");

    //If lateload
    for(int client = 1; client <= MaxClients; ++client)
    {
        if(IsClientConnected(client))
        {
            OnClientConnected(client);

            if(IsClientInGame(client))
                OnClientPutInServer(client);
        }
    }
}

void UTIL_SendChatToAll(int client, const char[] message)
{
    for(int target = 1; target <= MaxClients; ++target)
    {
        if(!IsClientInGame(target) || IsFakeClient(target))
            continue;

        PrintToChat(target, "[\x10管理员频道\x01] \x0C%N\x01 :\x07  %s", client, message);
    }

    char fmt[256];
    Format(fmt, 256, "[管理员频道] %N\n %s", client, message);
    GlobalApi_ShowGameText(INVALID_HANDLE, fmt, 10.0, "233 0 0", -1.0, 0.32);

    EmitSoundToAll("buttons/button18.wav");
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
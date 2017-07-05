#include <kylestock>

#pragma newdecls required //let`s go! new syntax!!!

#define Build 453
#define PLUGIN_VERSION " 8.04 - 2017/07/04 07:58 "

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
    String:szFlags[32],
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
#include "core/couples.sp"
#include "core/dailysign.sp"
#include "core/database.sp"
#include "core/globalapi.sp"
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
    Format(g_szRconPwd, 32, "%d", GetRandomInt(10000000, 99999999));
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
    Format(g_szIP, 32, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    //Create console command
    RegConsoleCmd("sm_online",       Command_Online);
    RegConsoleCmd("sm_track",        Command_Track);
    RegConsoleCmd("sm_cg",           Command_Menu);

    //Createe admin command
    RegAdminCmd("sm_reloadadv",      Command_ReloadAdv,   ADMFLAG_ROOT);
    RegAdminCmd("sm_reloadcache",    Command_ReloadCache, ADMFLAG_ROOT);

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
    Signature_OnPluginStart();
}

public void OnConfigsExecuted()
{
    //Locked Cvars
    SetConVarInt(FindConVar("sv_hibernate_when_empty"), 0);
    SetConVarInt(FindConVar("sv_disable_motd"), 1);
    SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
    SetConVarString(FindConVar("rcon_password"), g_szRconPwd, false, false);

    //Forward To Modules
    GlobalApi_OnConfigsExecuted();
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

            char m_szAuth[32];
            GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

            KvJumpToKey(g_GlobalHandle[KV_Local], m_szAuth, true);

            KvSetNum(g_GlobalHandle[KV_Local], "PlayerId", g_ClientGlobal[client][iPId]);
            KvSetNum(g_GlobalHandle[KV_Local], "Connect", ++g_ClientGlobal[client][iConnectTime]);
            KvSetNum(g_GlobalHandle[KV_Local], "TrackID", g_ClientGlobal[client][iTId]);
            KvSetString(g_GlobalHandle[KV_Local], "IP", g_ClientGlobal[client][szIP]);
            KvSetNum(g_GlobalHandle[KV_Local], "LastTime", GetTime());
            KvSetNum(g_GlobalHandle[KV_Local], "DayTime", g_ClientGlobal[client][iDaily]);

            KvRewind(g_GlobalHandle[KV_Local]);
        }
        
        KeyValuesToFile(g_GlobalHandle[KV_Local], "addons/sourcemod/data/core.track.kv.txt");
    }

    OnGlobalTimer();

    return Plugin_Continue;
}

public void OnClientConnected(int client)
{
    //初始化Client数据
    g_ClientGlobal[client][iPId]            = 0;
    g_ClientGlobal[client][iUId]            = 0;
    g_ClientGlobal[client][iGId]            = 0;
    g_ClientGlobal[client][iTId]            = 0;
    g_ClientGlobal[client][iNumber]         = 0;
    g_ClientGlobal[client][iOnline]         = 0;
    g_ClientGlobal[client][iGrowth]         = 0;
    g_ClientGlobal[client][iVitality]       = 0;
    g_ClientGlobal[client][iDaily]          = 0;
    g_ClientGlobal[client][iLastseen]       = 0;
    g_ClientGlobal[client][iConnectTime]    = 0;
    g_ClientGlobal[client][bVip]            = false;
    g_ClientGlobal[client][bLoaded]         = false;
    g_ClientGlobal[client][bInGroup]        = false;
    g_ClientGlobal[client][bRealName]       = false;
    g_ClientGlobal[client][szIP][0]         = '\0';
    g_ClientGlobal[client][szFlags][0]      = '\0';
    g_ClientGlobal[client][szGroupName][0]  = '\0';
    g_ClientGlobal[client][szForumName][0]  = '\0';
    g_ClientGlobal[client][szGamesName][0]  = '\0';
    g_ClientGlobal[client][szSignature][0]  = '\0';

    Couples_OnClientConnected(client);
    DailySign_OnClientConnected(client);
    Signature_OnClientConnected(client);

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

    UTIL_LoadClientDiscuzData(client, FriendID);
    OnClientVipChecked(client);

    return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
    if(!IsValidClient(client))
    {
        GlobalApi_OnClientLoaded(client);
        return;
    }

    GetClientIP(client, g_ClientGlobal[client][szIP], 32);

    char m_szAuth[32], m_szQuery[512];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
    Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.lasttime, a.number, a.signature, a.signnumber, a.signtime, a.groupid, a.groupname, a.lilyid, a.lilydate, a.active, a.daytime, a.flags, b.name FROM playertrack_player a LEFT JOIN playertrack_player b ON a.lilyid = b.id WHERE a.steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
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

    //如果客户没有成功INSERT ANALYTICS
    if(g_ClientGlobal[client][iTId] <= 0 || !g_ClientGlobal[client][iConnectTime])
        return;

    if(Database_DBHandle_Games == INVALID_HANDLE || !g_ClientGlobal[client][bLoaded])
        return;

    if(g_ClientGlobal[client][iTId] == -1 || g_ClientGlobal[client][iPId] == 0)
        return;

    //获得客户名字
    char username[64], m_szAuth[32];
    GetClientName(client, username, 64);
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);    

    //开始SQL查询操作
    char m_szBuffer[128], m_szQuery[512];
    SQL_EscapeString(Database_DBHandle_Games, username, m_szBuffer, 128);    
    Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lastip = '%s', a.lasttime = '%d', a.number = a.number+1, a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_szBuffer, g_ClientGlobal[client][iConnectTime], g_ClientGlobal[client][szIP], GetTime(), g_ClientGlobal[client][iDaily], g_ClientGlobal[client][iConnectTime], g_ClientGlobal[client][iPId], g_ClientGlobal[client][iTId], m_szAuth, g_ClientGlobal[client][iPId]);
    Handle data = CreateDataPack();
    WritePackString(data, m_szQuery);
    WritePackCell(data, 0);
    ResetPack(data);
    MySQL_Query(false, Database_SQLCallback_SaveDatabase, m_szQuery, data, DBPrio_High);

    if(KvJumpToKey(g_GlobalHandle[KV_Local], m_szAuth))
    {
        KvDeleteThis(g_GlobalHandle[KV_Local]);
        KvRewind(g_GlobalHandle[KV_Local]);
        KeyValuesToFile(g_GlobalHandle[KV_Local], "addons/sourcemod/data/core.track.kv.txt");
    }
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
                OnClientPostAdminCheck(client);
        }
    }
}

public Action Command_ReloadAdv(int client, int args)
{
    //Re-build server advertisment cache
    char m_szQuery[128];
    Format(m_szQuery, 128, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
    MySQL_Query(false, SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);
    return Plugin_Handled;
}

public Action Command_ReloadCache(int client, int args)
{
    //Re-build server forum data cache
    CreateTimer(2.0, Timer_RefreshData);
    return Plugin_Handled;
}

public Action Command_Online(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    int m_iHours = g_ClientGlobal[client][iOnline] / 3600;
    int m_iMins = g_ClientGlobal[client][iOnline] % 3600;
    PrintToChat(client, "[\x0CCG\x01]   尊贵的CG玩家\x04%N\x01,你已经在CG社区进行了\x0C%d\x01小时\x0C%d\x01分钟的游戏(\x02%d\x01次连线)", client, m_iHours, m_iMins/60, g_ClientGlobal[client][iNumber]);

    return Plugin_Handled;
}

public Action Command_Track(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;

    char szItem[512], szAuth32[32], szAuth64[64];
    Format(szItem, 512,"#PlayerId   玩家姓名    UID   论坛名称   steam32   steam64    认证    VIP\n========================================================================================");
    PrintToConsole(client, szItem);
    
    int connected, ingame;

    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            connected++;
            
            if(IsClientInGame(i))
            {
                ingame++;

                GetClientAuthId(i, AuthId_Steam2, szAuth32, 32, true);
                GetClientAuthId(i, AuthId_SteamID64, szAuth64, 64, true);
                Format(szItem, 512, " %d    %N    %d    %s    %s    %s    %s    %s", g_ClientGlobal[i][iPId], i, g_ClientGlobal[i][iUId], g_ClientGlobal[i][szForumName], szAuth32, szAuth64, g_ClientGlobal[i][szGroupName], g_ClientGlobal[i][bVip] ? "Y" : "N");
                PrintToConsole(client, szItem);
            }
        }
    }
    
    PrintToChat(client, "[\x0CCG\x01]   请查看控制台输出");
    PrintToChat(client, "[\x0CCG\x01]   当前已在服务器内\x04%d\x01人,已建立连接的玩家\x02%d\x01人", ingame, connected);

    return Plugin_Handled;
}

public Action Command_Menu(int client, int args)
{
    Handle menu = CreateMenu(MenuHandler_CGMainMenu);
    SetMenuTitleEx(menu, "[CG]  主菜单");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "store",  "打开商店菜单[购买皮肤/名字颜色/翅膀等道具]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "talent", "打开天赋菜单[选择/分配你的天赋]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lily",   "打开CP菜单[进行CP配对/加成等功能]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "sign",   "进行每日签到[签到可以获得相应的奖励]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "auth",   "打开认证菜单[申请玩家认证]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "vip",    "打开VIP菜单[年费/永久VIP可用]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "rule",   "查看规则[当前服务器规则]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "group",  "官方组[查看组页面]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "forum",  "官方论坛[https://csgogamers.com]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "music",  "音乐菜单[点歌/听歌]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "online", "在线时间[显示你的在线统计]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "setrp",  "分辨率[设置游戏内浏览器分辨率]");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "lang",   "选择你的语言");

    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
    
    return Plugin_Handled;
}

public int MenuHandler_CGMainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        if(!strcmp(info, "store"))
            FakeClientCommand(client, "sm_store");
        else if(!strcmp(info, "lily"))
            Command_Couples(client, 0);
        else if(!strcmp(info, "talent"))
            FakeClientCommand(client, "sm_talent");
        else if(!strcmp(info, "sign"))
            Command_Login(client, 0);
        else if(!strcmp(info, "auth"))
            Command_GetAuth(client, 0);
        else if(!strcmp(info, "vip"))
            FakeClientCommand(client, "sm_vip");
        else if(!strcmp(info, "rule"))
            FakeClientCommand(client, "sm_rules");
        else if(!strcmp(info, "group"))
            FakeClientCommand(client, "sm_group");
        else if(!strcmp(info, "forum"))
            FakeClientCommand(client, "sm_forum");
        else if(!strcmp(info, "music"))
            FakeClientCommand(client, "sm_music");
        else if(!strcmp(info, "online"))
            Command_Online(client, 0);
        else if(!strcmp(info, "setrp"))
            FakeClientCommand(client, "sm_setrp");
        else if(!strcmp(info, "lang"))
        {
            switch(GetClientLanguage(client))
            {
                case 0:
                {
                    SetClientLanguage(client, 23);
                    PrintToChat(client, "[\x0CCG\x01]   你的语言已切换为\x04简体中文");
                }
                case 23:
                {
                    SetClientLanguage(client, 27);
                    PrintToChat(client, "[\x0CCG\x01]   你的語言已經切換到\x04繁體中文");
                }
                case 27:
                {
                    SetClientLanguage(client, 0);
                    PrintToChat(client, "[\x0CCG\x01]   you language has been changed to \x04English");
                }
            }
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void UTIL_LoadClientDiscuzData(int client, const char[] FriendID)
{
    int array_size = GetArraySize(g_GlobalHandle[Array_Discuz]);
    Discuz_Data data[Discuz_Data];

    for(int i = 0; i < array_size; i++)
    {
        GetArrayArray(g_GlobalHandle[Array_Discuz], i, data[0], view_as<int>(Discuz_Data));
        
        if(!StrEqual(FriendID, data[szSteamId64]))
            continue;

        g_ClientGlobal[client][bVip] = (data[iExpTime] > GetTime());
        g_ClientGlobal[client][iUId] = data[iUId];
        g_ClientGlobal[client][iGrowth] = data[iGrowths];
        g_ClientGlobal[client][bRealName] = data[bIsRealName];
        strcopy(g_ClientGlobal[client][szForumName], 24, data[szDName]);
        break;
    }

    if(FindStringInArray(g_GlobalHandle[Array_Groups], FriendID) != -1)
        g_ClientGlobal[client][bInGroup] = true;
}

public Action Timer_CheckJoinGame(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!IsValidClient(client) || GetClientTeam(client) >= 1)
        return Plugin_Stop;

    RequestFrame(Frame_KickDelay, client);

    return Plugin_Stop;
}

void Frame_KickDelay(int client)
{
    if(!IsClientConnected(client))
        return;

    char fmt[256];
    Format(fmt, 256, "你因为太久没有激活游戏,已被踢出游戏.\nYou have been AFK too long");
    KickClient(client, fmt);
}
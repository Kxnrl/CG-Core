Handle Database_DBHandle_Games;
Handle Database_DBHandle_Forum;
Handle Database_Forward_OnServerLoaded;

void Database_OnAskPluginLoad2()
{
    CreateNative("CG_DatabaseSaveGames", Native_Database_SaveGames);
    CreateNative("CG_DatabaseSaveForum", Native_Database_SaveForum);
    CreateNative("CG_DatabaseGetGames",  Native_Database_GetGames);
    CreateNative("CG_DatabaseGetForum",  Native_Database_GetForum);
}

public int Native_Database_SaveGames(Handle plugin, int numParams)
{
    char m_szQuery[512];
    if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
    {
        Handle data = CreateDataPack();
        WritePackString(data, m_szQuery);
        WritePackCell(data, 0);
        ResetPack(data);
        MySQL_Query(false, Database_SQLCallback_SaveDatabase, m_szQuery, data);
    }
}

public int Native_Database_SaveForum(Handle plugin, int numParams)
{
    char m_szQuery[512];
    if(GetNativeString(1, m_szQuery, 512) == SP_ERROR_NONE)
    {
        Handle data = CreateDataPack();
        WritePackString(data, m_szQuery);
        WritePackCell(data, 1);
        ResetPack(data);
        MySQL_Query(true, Database_SQLCallback_SaveDatabase, m_szQuery, data);
    }
}

public int Native_Database_GetGames(Handle plugin, int numParams)
{
    return view_as<int>(Database_DBHandle_Games);
}

public int Native_Database_GetForum(Handle plugin, int numParams)
{
    return view_as<int>(Database_DBHandle_Forum);
}

bool MySQL_Query(bool toForum, SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
    Handle database = toForum ? Database_DBHandle_Forum : Database_DBHandle_Games;
 
    if(database == INVALID_HANDLE)
    {
        if(database == Database_DBHandle_Games)
            Database_SQLCallback_ConnectToGames();
        else if(database == Database_DBHandle_Forum)
            Database_SQLCallback_ConnectToForum();
        
        UTIL_LogError("MySQL_Query", "Query To DB[%s] is INVALID_HANDLE -> %s", toForum ? "discuz" : "csgo", query);

        return false;
    }

    SQL_TQuery(database, callback, query, data, prio);

    return true;
}

bool Database_EscapeName(int client, char[] buffer, int maxLen)
{
    char name[32];
    GetClientName(client, name, 32);
    SQL_EscapeString(Database_DBHandle_Games, name, buffer, maxLen);
}

void Database_OnPluginStart()
{
    Database_Forward_OnServerLoaded = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore);

    Database_SQLCallback_ConnectToGames();
    Database_SQLCallback_ConnectToForum();

    CreateTimer(600.0, Timer_RefreshData, _, TIMER_REPEAT);
}

public Action Timer_RefreshData(Handle timer)
{
    MySQL_Query(true, SQLCallback_LoadDiscuzData, "SELECT b.uid,a.steamID64,b.username,c.exptime,d.growth,e.issm FROM dz_steam_users a LEFT JOIN dz_common_member b ON a.uid=b.uid LEFT JOIN dz_dc_vip c ON a.uid=c.uid LEFT JOIN dz_pay_growth d ON a.uid=d.uid LEFT JOIN dz_lev_user_sm e ON a.uid=e.uid ORDER by b.uid ASC", _, DBPrio_Low);
    MySQL_Query(false, SQLCallback_OfficalGroup, "SELECT * FROM playertrack_officalgroup", _, DBPrio_Low);
    return Plugin_Continue;
}

void Database_SQLCallback_ConnectToGames()
{
    if(Database_DBHandle_Games != INVALID_HANDLE)
        return;
  
    if(SQL_CheckConfig("csgo"))
        SQL_TConnect(SQL_TConnect_Callback_csgo, "csgo");
    else
        SetFailState("Connect to Database Failed! Error: no config entry found for 'csgo' in databases.cfg");
}

void Database_SQLCallback_ConnectToForum()
{
    if(Database_DBHandle_Forum != INVALID_HANDLE)
        return;

    if(SQL_CheckConfig("discuz"))
        SQL_TConnect(SQL_TConnect_Callback_discuz, "discuz");
    else
        SetFailState("Connect to Database Failed! Error: no config entry found for 'discuz' in databases.cfg");
}

public void SQL_TConnect_Callback_csgo(Handle owner, Handle hndl, const char[] error, any data)
{
    if(Database_DBHandle_Games != INVALID_HANDLE)
    {
        if(Database_DBHandle_Games != hndl)
            CloseHandle(hndl);

        return;
    }

    static int m_iConnect;

    if(hndl == INVALID_HANDLE)
    {
        m_iConnect++;

        UTIL_LogError("SQL_TConnect_Callback_csgo", "Connection to SQL database 'csgo' has failed, Try %d, Reason: %s", m_iConnect, error);

        if(m_iConnect >= 100) 
        {
            UTIL_LogError("SQL_TConnect_Callback_csgo", " Too much errors. Restart your server for a new try. ");
            SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'csgo', retry 100! - PLUGIN STOPPED");
        }
        else if(m_iConnect > 5) 
            CreateTimer(5.0, Timer_ReConnect_csgo);
        else if(m_iConnect > 3)
            CreateTimer(3.0, Timer_ReConnect_csgo);
        else
            CreateTimer(1.0, Timer_ReConnect_csgo);

        return;
    }

    Database_DBHandle_Games = CloneHandle(hndl);

    SQL_SetCharset(Database_DBHandle_Games, "utf8");

    PrintToServer("[Core] Connection to database 'csgo' successful!");

    char m_szQuery[256];

    Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
    MySQL_Query(false, Database_SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);

    Format(m_szQuery, 256, "DELETE FROM `playertrack_analytics` WHERE connect_time < %d and duration = -1", GetTime()-18000);
    MySQL_Query(false, Database_SQLCallback_NoResults, m_szQuery, 1, DBPrio_Low);

    Format(m_szQuery, 256, "SELECT * FROM playertrack_officalgroup");
    MySQL_Query(false, SQLCallback_OfficalGroup, m_szQuery, _, DBPrio_High);

    m_iConnect = 1;
}

public void SQL_TConnect_Callback_discuz(Handle owner, Handle hndl, const char[] error, any data)
{
    if(Database_DBHandle_Forum != INVALID_HANDLE)
    {
        if(Database_DBHandle_Forum != hndl)
            CloseHandle(hndl);

        return;
    } 

    static int m_iConnect;

    if(hndl == INVALID_HANDLE)
    {
        m_iConnect++;

        UTIL_LogError("SQL_TConnect_Callback_discuz", "Connection to SQL database 'discuz' has failed, Try %d, Reason: %s", m_iConnect, error);

        if(m_iConnect >= 100) 
        {
            UTIL_LogError("SQL_TConnect_Callback_discuz", " Too much errors. Restart your server for a new try. ");
            SetFailState("PLUGIN STOPPED - Reason: can not connect to database 'discuz', retry 100! - PLUGIN STOPPED");
        }
        else if(m_iConnect > 5) 
            CreateTimer(5.0, Timer_ReConnect_discuz);
        else if(m_iConnect > 3)
            CreateTimer(3.0, Timer_ReConnect_discuz);
        else
            CreateTimer(1.0, Timer_ReConnect_discuz);

        return;
    }

    Database_DBHandle_Forum = CloneHandle(hndl);

    SQL_SetCharset(Database_DBHandle_Forum, "utf8");

    PrintToServer("[Core] Connection to database 'discuz' successful!");

    MySQL_Query(true, SQLCallback_LoadDiscuzData, "SELECT b.uid,a.steamID64,b.username,c.exptime,d.growth,e.issm FROM dz_steam_users a LEFT JOIN dz_common_member b ON a.uid=b.uid LEFT JOIN dz_dc_vip c ON a.uid=c.uid LEFT JOIN dz_pay_growth d ON a.uid=d.uid LEFT JOIN dz_lev_user_sm e ON a.uid=e.uid ORDER by b.uid ASC", _, DBPrio_High);

    m_iConnect = 1;
}

public Action Timer_ReConnect_csgo(Handle timer)
{
    Database_SQLCallback_ConnectToGames();
    return Plugin_Stop;
}

public Action Timer_ReConnect_discuz(Handle timer)
{
    Database_SQLCallback_ConnectToForum();
    return Plugin_Stop;
}

public void Database_SQLCallback_SaveDatabase(Handle owner, Handle hndl, const char[] error, Handle data)
{
    if(hndl == INVALID_HANDLE)
    {
        char m_szQuery[512];
        ReadPackString(data, m_szQuery, 512);
        int database = ReadPackCell(data);
        ResetPack(data);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "==========================================================");
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "Native SaveDatabase[%s].  Error: %s", database == 0 ? "csgo" : "discuz", error);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "Query: %s", m_szQuery);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "==========================================================");
    }
    CloseHandle(data);
}

public void Database_SQLCallback_NoResults(Handle owner, Handle hndl, const char[] error, int type)
{
    if(hndl == INVALID_HANDLE)
    {
        switch(type)
        {
            case 0: UTIL_LogError("Database_SQLCallback_NoResults", "Update rcon password failed :  %s", error);
            case 1: UTIL_LogError("Database_SQLCallback_NoResults", "Delete on connected failed :  %s", error);
        }
    }
}

public void Database_SQLCallback_GetServerIP(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE) 
    {
        UTIL_LogError("Database_SQLCallback_GetServerIP", "Query server ID Failed! Reason: %s", error);

        if(StrContains(error, "lost connection", false) != -1)
        {
            char m_szQuery[256];
            Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
            MySQL_Query(false, Database_SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);
        }

        return;
    }

    if(SQL_FetchRow(hndl))
    {
        g_iServerId = SQL_FetchInt(hndl, 0);
        SQL_FetchString(hndl, 1, g_szHostName, 256);
        SetConVarString(FindConVar("hostname"), g_szHostName, false, false);

        UTIL_OnServerLoaded();
        Call_StartForward(Database_Forward_OnServerLoaded);
        Call_Finish();

        int ip = GetConVarInt(FindConVar("hostip"));
        char IPadr[32], m_szQuery[128];
        Format(IPadr, 32, "%d.%d.%d.%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF);
        Format(m_szQuery, 128, "UPDATE sb_servers SET rcon = '%s' WHERE ip = '%s' and port = '%d'", g_szRconPwd, IPadr, GetConVarInt(FindConVar("hostport")));
        MySQL_Query(false, Database_SQLCallback_NoResults, m_szQuery, 0, DBPrio_High);
    }
    else
    {
        char m_szQuery[256];
        Format(m_szQuery, 256, "INSERT INTO playertrack_server (servername, serverip) VALUES ('NewServer', '%s')", g_szIP);
        Format(g_szHostName, 128, "【CG社区】NewServer!");
        SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
        UTIL_LogError("Database_SQLCallback_GetServerIP", "Not Found this server in playertrack_server , now Register this!  %s", m_szQuery);
        MySQL_Query(false, Database_SQLCallback_InsertServerIP, m_szQuery, _, DBPrio_High);
    }
}

public void Database_SQLCallback_InsertServerIP(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Database_SQLCallback_InsertServerIP", "INSERT server ID Failed! Reason: %s", error);
        return;
    }

    g_iServerId = SQL_GetInsertId(hndl);

    UTIL_OnServerLoaded();
    Call_StartForward(Database_Forward_OnServerLoaded);
    Call_Finish();
}

public void SQLCallback_GetAdvData(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == INVALID_HANDLE)
        return;

    if(SQL_GetRowCount(hndl))
    {
        Handle kv = CreateKeyValues("ServerAdvertisement", "", "");

        int Count = 0;
        while(SQL_FetchRow(hndl))
        {
            char m_szType[4], m_szCount[4], m_szText_EN[256], m_szText_CN[256], m_szText_HUD[256];
            SQL_FetchString(hndl, 2,  m_szType,       4);
            SQL_FetchString(hndl, 3,  m_szText_EN,  256);  // 0=ID 1=SID 2=TYPE 3=EN 4=CN
            SQL_FetchString(hndl, 4,  m_szText_CN,  256);
            SQL_FetchString(hndl, 5,  m_szText_HUD, 256);

            IntToString(Count, m_szCount, 4);
            if(KvJumpToKey(kv, "Messages", true))
            {
                if(KvJumpToKey(kv, m_szCount, true))
                {
                    Count++;
                    KvSetString(kv, "default", m_szText_EN);
                    KvSetString(kv, "trans", m_szText_CN);
                    KvSetString(kv, "hud", m_szText_HUD);
                    KvSetString(kv, "type", m_szType);
                    KvRewind(kv);
                }
            }
        }

        KeyValuesToFile(kv, "addons/sourcemod/configs/ServerAdvertisement.cfg");
        ServerCommand("sm_reloadsadvert");
        CloseHandle(kv);
    }
}

public void SQLCallback_SaveTempLog(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == INVALID_HANDLE)
    {
        char m_szAuthId[32], m_szQuery[512], m_szIp[16];
        ReadPackString(data, m_szQuery, 512);
        ReadPackString(data, m_szAuthId, 32);
        int m_iPlayerId = ReadPackCell(data);
        int m_iConnect = ReadPackCell(data);
        int m_iTrackId = ReadPackCell(data);
        ReadPackString(data, m_szIp, 32);
        int m_iLastTime = ReadPackCell(data);

        UTIL_LogError("SQLCallback_SaveTempLog", " \n------------------------------------------------------------------------------\nAuthId: %s\nPlayerId: %d\nConnect: %d\nTrackId: %d\nIP: %s\nLastTime: %d\nQuery: %s\n------------------------------------------------------------------------------", m_szAuthId, m_iPlayerId, m_iConnect, m_iTrackId, m_szIp, m_iLastTime, m_szQuery);
    }
}

public void SQLCallback_OfficalGroup(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("SQLCallback_OfficalGroup", "Load Offical Group List failed. Error happened: %s", error);
        return;
    }

    if(SQL_GetRowCount(hndl) < 1)
        return;

    ClearArray(g_GlobalHandle[Array_Groups]);

    char FriendID[32];

    while(SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, FriendID, 32);
        PushArrayString(g_GlobalHandle[Array_Groups], FriendID);
    }

    for(int client = 1; client <= MaxClients; ++client)
    {
        g_ClientGlobal[client][bInGroup] = false;

        if(!IsClientConnected(client) || !IsClientAuthorized(client) || IsFakeClient(client))
            continue;

        if(!GetClientAuthId(client, AuthId_SteamID64, FriendID, 32, true))
            continue;

        if(StrContains(FriendID, "765") != 0)
            continue;

        if(FindStringInArray(g_GlobalHandle[Array_Groups], FriendID) == -1)
            continue;

        g_ClientGlobal[client][bInGroup] = true;
    }
}

public void SQLCallback_LoadDiscuzData(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("SQLCallback_LoadDiscuzData", "Load VIP failed. Error happened: %s", error);
        return;
    }

    if(SQL_GetRowCount(hndl) < 1)
        return;

    ClearArray(g_GlobalHandle[Array_Discuz]);

    Discuz_Data data[Discuz_Data];

    while(SQL_FetchRow(hndl))
    {
        data[iUId] = SQL_FetchInt(hndl, 0);
        SQL_FetchString(hndl, 1, data[szSteamId64], 32);
        SQL_FetchString(hndl, 2, data[szDName], 24);
        data[iExpTime] = SQL_FetchInt(hndl, 3);
        data[iGrowths] = SQL_FetchInt(hndl, 4);
        data[bIsRealName] = (SQL_FetchInt(hndl, 5) == 99);
        PushArrayArray(g_GlobalHandle[Array_Discuz], data[0], view_as<int>(Discuz_Data));
    }

    for(int client = 1; client <= MaxClients; ++client)
    {
        if(!IsClientConnected(client) || !IsClientAuthorized(client) || IsFakeClient(client))
            continue;

        char FriendID[32];
        if(!GetClientAuthId(client, AuthId_SteamID64, FriendID, 32, true))
            continue;

        if(StrContains(FriendID, "765611") != 0)
            continue;

        LoadClientDiscuzData(client, FriendID);
    }
}

public void Database_SQLCallback_GetClientBaseData(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            UTIL_LogError("Database_SQLCallback_GetClientBaseData", "Query Client Stats Failed! Client:\"%L\" Error Happened: %s", client, error);
            GlobalApi_OnClientLoaded(client);
            return;
        }

        char m_szAuth[32], m_szQuery[512];
        GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
        Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.lasttime, a.number, a.signature, a.signnumber, a.signtime, a.groupid, a.groupname, a.lilyid, a.lilydate, a.active, a.daytime, b.name FROM playertrack_player a LEFT JOIN playertrack_player b ON a.lilyid = b.id WHERE a.steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
        MySQL_Query(false, Database_SQLCallback_GetClientBaseData, m_szQuery, GetClientUserId(client), DBPrio_High);
        return;
    }

    if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
    {
        g_ClientGlobal[client][iPId]      = SQL_FetchInt(hndl, 0);
        g_ClientGlobal[client][iOnline]   = SQL_FetchInt(hndl, 1);
        g_ClientGlobal[client][iLastseen] = SQL_FetchInt(hndl, 2);
        g_ClientGlobal[client][iNumber]   = SQL_FetchInt(hndl, 3);
        g_ClientGlobal[client][iGId]      = SQL_FetchInt(hndl, 7);
        g_ClientGlobal[client][iVitality] = SQL_FetchInt(hndl, 11);
        g_ClientGlobal[client][iDaily]    = SQL_FetchInt(hndl, 12);

        SQL_FetchString(hndl,  8, g_ClientGlobal[client][szGroupName],  16);
        SQL_FetchString(hndl,  4, g_ClientGlobal[client][szSignature], 256);

        char cpname[32];
        SQL_FetchString(hndl, 13, cpname, 32);
        Couples_InitializeCouplesData(client, SQL_FetchInt(hndl, 9), SQL_FetchInt(hndl, 10), cpname);
        DailySign_InitializeSignData(client, SQL_FetchInt(hndl, 5), SQL_FetchInt(hndl, 6));

        g_ClientGlobal[client][bLoaded] = true;

        GlobalApi_OnClientLoaded(client);

        char date[64], map[128], m_szQuery[512];
        FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());
        GetCurrentMap(map, 128);
        Format(m_szQuery, 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `ip`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s')", g_ClientGlobal[client][iPId], GetTime(), date, g_iServerId, map, g_ClientGlobal[client][szIP]);
        MySQL_Query(false, Database_SQLCallback_InsertClientStats, m_szQuery, GetClientUserId(client));
    }
    else
    {
        char m_szAuth[32], EscapeName[64], m_szQuery[512];
        GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
        Database_EscapeName(client, EscapeName, 64);
        Format(m_szQuery, 512, "INSERT INTO playertrack_player (name, steamid, onlines, lastip, firsttime, lasttime, number, signature) VALUES ('%s', '%s', '0', '%s', '%d', '0', '0', DEFAULT)", EscapeName, m_szAuth, g_ClientGlobal[client][szIP], GetTime());
        MySQL_Query(false, Database_SQLCallback_InsertClientBaseData, m_szQuery, GetClientUserId(client));
    }
}

public void Database_SQLCallback_InsertClientBaseData(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            UTIL_LogError("Database_SQLCallback_InsertClientBaseData", "INSERT playertrack_player Failed! Client:\"%L\" Error Happened: %s", client, error);
            GlobalApi_OnClientLoaded(client);
            return;
        }

        char m_szAuth[32], m_szQuery[512];
        GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
        Format(m_szQuery, 512, "SELECT a.id, a.onlines, a.lasttime, a.number, a.signature, a.signnumber, a.signtime, a.groupid, a.groupname, a.lilyid, a.lilydate, a.active, a.daytime, b.name FROM playertrack_player a LEFT JOIN playertrack_player b ON a.lilyid = b.id WHERE a.steamid = '%s' ORDER BY id ASC LIMIT 1;", m_szAuth);
        MySQL_Query(false, Database_SQLCallback_GetClientBaseData, m_szQuery, GetClientUserId(client), DBPrio_High);

        return;
    }

    g_ClientGlobal[client][iPId] = SQL_GetInsertId(hndl);
    g_ClientGlobal[client][bLoaded] = true;
    GlobalApi_OnClientLoaded(client);
    
    char date[64], map[128], m_szQuery[512];
    FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());
    GetCurrentMap(map, 128);
    Format(m_szQuery, 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `ip`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s')", g_ClientGlobal[client][iPId], GetTime(), date, g_iServerId, map, g_ClientGlobal[client][szIP]);
    MySQL_Query(false, Database_SQLCallback_InsertClientStats, m_szQuery, GetClientUserId(client));
}

public void Database_SQLCallback_InsertClientStats(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Database_SQLCallback_InsertClientStats", "INSERT playertrack_analytics Failed!   Player:\"%L\" Error Happened:%s", client, error);
        return;
    }

    g_ClientGlobal[client][iTId] = SQL_GetInsertId(hndl);
}
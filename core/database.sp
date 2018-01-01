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
        UTIL_TQuery(g_dbGames, Database_SQLCallback_SaveDatabase, m_szQuery, data);
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
        UTIL_TQuery(g_dbForum, Database_SQLCallback_SaveDatabase, m_szQuery, data);
    }
}

public int Native_Database_GetGames(Handle plugin, int numParams)
{
    return view_as<int>(g_dbGames);
}

public int Native_Database_GetForum(Handle plugin, int numParams)
{
    return view_as<int>(g_dbForum);
}

void Database_OnPluginStart()
{
    Database_SQLCallback_ConnectToGames();
    Database_SQLCallback_ConnectToForum();

    CreateTimer(600.0, Timer_RefreshData, _, TIMER_REPEAT);
}

public Action Timer_RefreshData(Handle timer)
{
    Cache_RefreshCache();
    Couples_RefreshRank();
    return Plugin_Continue;
}

void Database_SQLCallback_ConnectToGames()
{
    if(g_dbGames != INVALID_HANDLE)
        return;

    if(SQL_CheckConfig("csgo"))
        SQL_TConnect(SQL_TConnect_Callback_csgo, "csgo");
    else
        SetFailState("Connect to Database Failed! Error: no config entry found for 'csgo' in databases.cfg");
}

void Database_SQLCallback_ConnectToForum()
{
    if(g_dbForum != INVALID_HANDLE)
        return;

    if(SQL_CheckConfig("discuz"))
        SQL_TConnect(SQL_TConnect_Callback_discuz, "discuz");
    else
        SetFailState("Connect to Database Failed! Error: no config entry found for 'discuz' in databases.cfg");
}

public void SQL_TConnect_Callback_csgo(Handle owner, Handle hndl, const char[] error, any data)
{
    if(g_dbGames != INVALID_HANDLE)
    {
        if(g_dbGames != hndl)
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

    g_dbGames = CloneHandle(hndl);

    SQL_SetCharset(g_dbGames, "utf8");

    PrintToServer("[Core] Connection to database 'csgo' successful!");

    char m_szQuery[256];
    Format(m_szQuery, 256, "SELECT `id`,`servername` FROM playertrack_server WHERE serverip = '%s'", g_szIP);
    UTIL_TQuery(g_dbGames, Database_SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);

    m_iConnect = 1;
}

public void SQL_TConnect_Callback_discuz(Handle owner, Handle hndl, const char[] error, any data)
{
    if(g_dbForum != INVALID_HANDLE)
    {
        if(g_dbForum != hndl)
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

    g_dbForum = CloneHandle(hndl);

    SQL_SetCharset(g_dbForum, "utf8");

    PrintToServer("[Core] Connection to database 'discuz' successful!");

    UTIL_TQuery(g_dbForum, Cache_SQLCallback_LoadDiscuzData, "SELECT b.uid,a.steamID64,b.username,c.exptime,d.growth,e.issm FROM dz_steam_users a LEFT JOIN dz_common_member b ON a.uid=b.uid LEFT JOIN dz_dc_vip c ON a.uid=c.uid LEFT JOIN dz_pay_growth d ON a.uid=d.uid LEFT JOIN dz_lev_user_sm e ON a.uid=e.uid ORDER by b.uid ASC", _, DBPrio_High);

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

public void Database_SQLCallback_SaveDatabase(Handle owner, Handle hndl, const char[] error, DataPack data)
{
    if(hndl == INVALID_HANDLE)
    {
        char m_szQuery[512];
        data.ReadString(m_szQuery, 512);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "==========================================================");
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "Native SaveDatabase[%s].  Error: %s", ReadPackCell(data) == 0 ? "csgo" : "discuz", error);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "Query: %s", m_szQuery);
        UTIL_LogError("Database_SQLCallback_SaveDatabase", "==========================================================");
    }
    delete data;
}

public void Database_SQLCallback_Void(Handle owner, Handle hndl, const char[] error, DataPack data)
{
    if(hndl == INVALID_HANDLE)
    {
        char m_szQuery[512];
        data.ReadString(m_szQuery, 512);
        UTIL_LogError("Database_SQLCallback_Void", "==========================================================");
        UTIL_LogError("Database_SQLCallback_Void", "Database[%s].  Error: %s", ReadPackCell(data) == 0 ? "csgo" : "discuz", error);
        UTIL_LogError("Database_SQLCallback_Void", "Query: %s", m_szQuery);
        UTIL_LogError("Database_SQLCallback_Void", "==========================================================");
    }
    delete data;
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
            UTIL_TQuery(g_dbGames, Database_SQLCallback_GetServerIP, m_szQuery, _, DBPrio_High);
        }

        return;
    }

    if(SQL_FetchRow(hndl))
    {
        g_iServerId = SQL_FetchInt(hndl, 0);
        SQL_FetchString(hndl, 1, g_szHostName, 256);
        SetConVarString(FindConVar("host_name_store"), "1", false, false);
        SetConVarString(FindConVar("hostname"), g_szHostName, false, false);

        Server_Forward_OnServerLoaded();

        int ip = GetConVarInt(FindConVar("hostip"));
        char IPadr[32], m_szQuery[128];
        Format(IPadr, 32, "%d.%d.%d.%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF);
        Format(m_szQuery, 128, "UPDATE sb_servers SET rcon = '%s' WHERE ip = '%s' and port = '%d'", g_szRconPwd, IPadr, GetConVarInt(FindConVar("hostport")));
        UTIL_SQLTVoid(g_dbGames, m_szQuery, DBPrio_High);
    }
    else
    {
        char m_szQuery[256];
        Format(m_szQuery, 256, "INSERT INTO playertrack_server (servername, serverip) VALUES ('NewServer', '%s')", g_szIP);
        Format(g_szHostName, 128, "【CG社区】NewServer!");
        SetConVarString(FindConVar("host_name_store"), "1", false, false);
        SetConVarString(FindConVar("hostname"), g_szHostName, false, false);
        UTIL_LogError("Database_SQLCallback_GetServerIP", "Not Found this server in playertrack_server , now Register this!  %s", m_szQuery);
        UTIL_TQuery(g_dbGames, Database_SQLCallback_InsertServerIP, m_szQuery, _, DBPrio_High);
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

    Server_Forward_OnServerLoaded();
}
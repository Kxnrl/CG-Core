void Client_LoadBaseData(int client)
{
    char m_szAuth[32], m_szQuery[1024];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
    Format(m_szQuery, 1024, "SELECT a.id, a.onlines, a.lasttime, a.number, a.signature, a.signnumber, a.signtime, a.active, a.daytime, b.index, b.name, b.exp, b.date, b.expired, c.date, c.exp, c.together, c.luv, d.id, d.name, e.weapon, e.useTimes, e.kills, e.deaths, e.bloodied, e.headshots, e.damage, e.tendresse FROM playertrack_player a LEFT JOIN playertrack_authgroup b ON a.id = b.pid  LEFT JOIN playertrack_couples c ON (a.id = c.source_id OR a.id = c.target_id) LEFT JOIN  playertrack_player d ON d.id=(IF(a.id=c.source_id, c.target_id, c.source_id)) LEFT JOIN playertrack_gungirls e ON a.id = e.pid WHERE a.steamid = '%s' ORDER BY a.id ASC LIMIT 1;", m_szAuth);
    UTIL_TQuery(g_dbGames, Client_SQLCallback_GetClientBaseData, m_szQuery, GetClientUserId(client), DBPrio_High);
}

public void Client_SQLCallback_GetClientBaseData(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            UTIL_LogError("Client_SQLCallback_GetClientBaseData", "Query Client Stats Failed! Client:\"%L\" Error Happened: %s", client, error);
            Client_Forward_OnClientLoaded(client);
            return;
        }

        Client_LoadBaseData(client);
        return;
    }

    if(SQL_FetchRow(hndl))
    {
        // 0.id,         1.onlines,       2.lasttime,     3.number,       4.signature,    5.signnumber,   6.signtime,
        // 7.active,     8.daytime,       9.index,       10.groupname,   11.exp,         12.date         13.expired,
        //14.cpdate,    15.cpexp,        16.together,    17.luv,         18.id,          19.name         20.weapon
        //21.useTimes   22.kills,        23.deaths,      24.bloodied,    25.headshots,   26.damage,      27.tendresse
        g_ClientGlobal[client][iPId]      = SQL_FetchInt(hndl, 0);
        g_ClientGlobal[client][iOnline]   = SQL_FetchInt(hndl, 1);
        g_ClientGlobal[client][iLastseen] = SQL_FetchInt(hndl, 2);
        g_ClientGlobal[client][iNumber]   = SQL_FetchInt(hndl, 3);
        g_ClientGlobal[client][iVitality] = SQL_FetchInt(hndl, 7);
        g_ClientGlobal[client][iDaily]    = SQL_FetchInt(hndl, 8);

        SQL_FetchString(hndl,  4, g_ClientGlobal[client][szSignature], 256);

        char groupname[16];
        if(!SQL_IsFieldNull(hndl, 10))
            SQL_FetchString(hndl, 10, groupname,  16);
        else
            strcopy(groupname, 16, "未认证");

        AuthGroup_InitializeAuthData(client, SQL_IsFieldNull(hndl, 9) ? 0 : SQL_FetchInt(hndl, 9), SQL_IsFieldNull(hndl, 11) ? 0 : SQL_FetchInt(hndl, 11), SQL_IsFieldNull(hndl, 12) ? 0 : SQL_FetchInt(hndl, 12), SQL_IsFieldNull(hndl, 13) ? 0 : SQL_FetchInt(hndl, 13), groupname);
        DailySign_InitializeSignData(client, SQL_FetchInt(hndl,  5), SQL_FetchInt(hndl,  6));

        char cpname[32];
        if(!SQL_IsFieldNull(hndl, 19))
            SQL_FetchString(hndl, 19, cpname, 32);
        else
            strcopy(cpname, 32, "单身狗");
        Couples_InitializeCouplesData(client, SQL_IsFieldNull(hndl, 18) ? -2 : SQL_FetchInt(hndl, 18), SQL_IsFieldNull(hndl, 14) ? 0 : SQL_FetchInt(hndl, 14), SQL_IsFieldNull(hndl, 15) ? 0 : SQL_FetchInt(hndl, 15), SQL_IsFieldNull(hndl, 16) ? 0 : SQL_FetchInt(hndl, 16), SQL_IsFieldNull(hndl, 17) ? 0 : SQL_FetchInt(hndl, 17), cpname);

        char weapon[32];
        if(!SQL_IsFieldNull(hndl, 20))
            SQL_FetchString(hndl, 20, weapon,  32);
        else
            strcopy(weapon, 32, "INVALID_WEAPON");
        GirlsFL_InitializeGFLData(client, weapon, SQL_IsFieldNull(hndl, 21) ? 0 : SQL_FetchInt(hndl, 21), SQL_IsFieldNull(hndl, 22) ? 0 : SQL_FetchInt(hndl, 22), SQL_IsFieldNull(hndl, 23) ? 0 : SQL_FetchInt(hndl, 23), SQL_IsFieldNull(hndl, 24) ? 0 : SQL_FetchInt(hndl, 24), SQL_IsFieldNull(hndl, 25) ? 0 : SQL_FetchInt(hndl, 25), SQL_IsFieldNull(hndl, 26) ? 0 : SQL_FetchInt(hndl, 26), SQL_IsFieldNull(hndl, 27) ? 0 : SQL_FetchInt(hndl, 27));
        
        g_ClientGlobal[client][bLoaded] = true;

        Client_Forward_OnClientLoaded(client);

        char date[64], map[128], m_szQuery[512];
        FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());
        GetCurrentMap(map, 128);
        Format(m_szQuery, 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `ip`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s')", g_ClientGlobal[client][iPId], GetTime(), date, g_iServerId, map, g_ClientGlobal[client][szIP]);
        UTIL_TQuery(g_dbGames, Client_SQLCallback_InsertClientStats, m_szQuery, GetClientUserId(client));
    }
    else
    {
        char m_szAuth[32], EscapeName[64], m_szQuery[512];
        GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
        UTIL_GetEscapeName(client, EscapeName, 64);
        Format(m_szQuery, 512, "INSERT INTO playertrack_player (name, steamid, onlines, firsttime, lasttime, number, signature) VALUES ('%s', '%s', '0', '%d', '0', '0', DEFAULT)", EscapeName, m_szAuth, GetTime());
        UTIL_TQuery(g_dbGames, Client_SQLCallback_InsertClientBaseData, m_szQuery, GetClientUserId(client));
    }
}

public void Client_SQLCallback_InsertClientStats(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Client_SQLCallback_InsertClientStats", "INSERT playertrack_analytics Failed!   Player:\"%L\" Error Happened:%s", client, error);
        return;
    }

    g_ClientGlobal[client][iTId] = SQL_GetInsertId(hndl);
}

public void Client_SQLCallback_InsertClientBaseData(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        if(StrContains(error, "lost connection", false) == -1)
        {
            UTIL_LogError("Client_SQLCallback_InsertClientBaseData", "INSERT playertrack_player Failed! Client:\"%L\" Error Happened: %s", client, error);
            Client_Forward_OnClientLoaded(client);
            return;
        }

        Client_LoadBaseData(client);
        return;
    }

    g_ClientGlobal[client][iPId] = SQL_GetInsertId(hndl);
    g_ClientGlobal[client][bLoaded] = true;
    Client_Forward_OnClientLoaded(client);

    char date[64], map[128], m_szQuery[512];
    FormatTime(date, 64, "%Y/%m/%d %H:%M:%S", GetTime());
    GetCurrentMap(map, 128);
    Format(m_szQuery, 512, "INSERT INTO `playertrack_analytics` (`playerid`, `connect_time`, `connect_date`, `serverid`, `map`, `ip`) VALUES ('%d', '%d', '%s', '%d', '%s', '%s')", g_ClientGlobal[client][iPId], GetTime(), date, g_iServerId, map, g_ClientGlobal[client][szIP]);
    UTIL_TQuery(g_dbGames, Client_SQLCallback_InsertClientStats, m_szQuery, GetClientUserId(client));
}

public void Client_SQLCallback_NativeGetTermOnline(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
    int userid = pack.ReadCell();
    int start  = pack.ReadCell();
    int end    = pack.ReadCell();
    Function callback = pack.ReadFunction();
    Handle plugin = pack.ReadCell();
    delete pack;

    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Client_SQLCallback_NativeGetTermOnline", "Get duration Failed! Client:\"%L\" Error Happened: %s", client, error);
        return;
    }
    
    int onlines = 0;
    
    if(SQL_FetchRow(hndl))
        if(!SQL_IsFieldNull(hndl, 0))
            onlines = SQL_FetchInt(hndl, 0);
        
    Call_StartFunction(plugin, callback);
    Call_PushCell(client);
    Call_PushCell(start);
    Call_PushCell(end);
    Call_PushCell(onlines);
    Call_Finish();
}
StringMap sm_DiscuzDataCache;
ArrayList al_OfficalGroupListCache;
KeyValues kv_ClientTrackingDataCache;

enum Discuz_Data
{
    iUId,
    iExpTime,
    iGrowths,
    bool:bIsRealName,
    String:szDName[24],
    String:szSteamId64[32]
}

void Cache_OnPluginStart()
{
    sm_DiscuzDataCache = new StringMap();
    al_OfficalGroupListCache = new ArrayList(ByteCountToCells(32));
}

void Cache_OnGlobalTimer()
{
    kv_ClientTrackingDataCache.ExportToFile("addons/sourcemod/data/core.track.kv.txt");
}

void Cache_OnServerLoaded()
{
    char m_szQuery[512];

    if(kv_ClientTrackingDataCache != INVALID_HANDLE)
        delete kv_ClientTrackingDataCache;

    kv_ClientTrackingDataCache = new KeyValues("core_track", "", "");

    kv_ClientTrackingDataCache.ImportFromFile("addons/sourcemod/data/core.track.kv.txt");

    while(kv_ClientTrackingDataCache.GotoFirstSubKey(true))
    {
        char m_szAuthId[32];
        kv_ClientTrackingDataCache.GetSectionName(m_szAuthId, 32);

        int m_iPlayerId = kv_ClientTrackingDataCache.GetNum("PlayerId", 0);
        int m_iConnect = kv_ClientTrackingDataCache.GetNum("Connect", 0);
        int m_iTrackId = kv_ClientTrackingDataCache.GetNum("TrackID", 0);
        int m_iLastTime = kv_ClientTrackingDataCache.GetNum("LastTime", 0);
        int m_iDaily = kv_ClientTrackingDataCache.GetNum("DayTime", 0);

        Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.onlines = a.onlines+%d, a.lasttime = '%d', a.number = a.number+1, a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_iConnect, m_iLastTime, m_iDaily, m_iConnect, m_iPlayerId, m_iTrackId, m_szAuthId, m_iPlayerId);
        UTIL_SQLTVoid(g_dbGames, m_szQuery);

        if(kv_ClientTrackingDataCache.DeleteThis())
        {
            char m_szAfter[32];
            kv_ClientTrackingDataCache.GetSectionName(m_szAfter, 32);
            if(StrContains(m_szAfter, "STEAM", false) != -1)
                kv_ClientTrackingDataCache.GoBack();
        }
    }

    kv_ClientTrackingDataCache.Rewind();
    kv_ClientTrackingDataCache.ExportToFile("addons/sourcemod/data/core.track.kv.txt");

    Format(m_szQuery, 512, "DELETE FROM `playertrack_analytics` WHERE connect_time < %d and duration = -1", GetTime()-18000);
    UTIL_SQLTVoid(g_dbGames, m_szQuery, DBPrio_Low);

    Format(m_szQuery, 512, "SELECT * FROM playertrack_officalgroup");
    UTIL_TQuery(g_dbGames, Cache_SQLCallback_OfficalGroup, m_szQuery, _, DBPrio_High);

    Couples_RefreshRank();
}

void Cache_UpdateClientData(int client, int pid, int ctime, int tid, int daily)
{
    char m_szAuth[32];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);

    kv_ClientTrackingDataCache.JumpToKey(m_szAuth, true);

    kv_ClientTrackingDataCache.SetNum("PlayerId", pid);
    kv_ClientTrackingDataCache.SetNum("Connect",  ctime);
    kv_ClientTrackingDataCache.SetNum("TrackID",  tid);
    kv_ClientTrackingDataCache.SetNum("LastTime", GetTime());
    kv_ClientTrackingDataCache.SetNum("DayTime",  daily);

    kv_ClientTrackingDataCache.Rewind();
}

void Cache_RefreshCache()
{
    UTIL_TQuery(g_dbForum, Cache_SQLCallback_LoadDiscuzData, "SELECT b.uid,a.steamID64,b.username,c.exptime,d.growth,e.issm FROM dz_steam_users a LEFT JOIN dz_common_member b ON a.uid=b.uid LEFT JOIN dz_dc_vip c ON a.uid=c.uid LEFT JOIN dz_pay_growth d ON a.uid=d.uid LEFT JOIN dz_lev_user_sm e ON a.uid=e.uid ORDER by b.uid ASC", _, DBPrio_Low);
    UTIL_TQuery(g_dbGames, Cache_SQLCallback_OfficalGroup, "SELECT * FROM playertrack_officalgroup", _, DBPrio_Low);
}

public void Cache_SQLCallback_LoadDiscuzData(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Cache_SQLCallback_LoadDiscuzData", "Load VIP failed. Error happened: %s", error);
        return;
    }

    if(SQL_GetRowCount(hndl) < 1)
        return;

    sm_DiscuzDataCache.Clear();

    int data[Discuz_Data];

    while(SQL_FetchRow(hndl))
    {
        data[iUId] = SQL_FetchInt(hndl, 0);
        SQL_FetchString(hndl, 1, data[szSteamId64], 32);
        SQL_FetchString(hndl, 2, data[szDName], 24);
        data[iExpTime] = SQL_FetchInt(hndl, 3);
        data[iGrowths] = SQL_FetchInt(hndl, 4);
        data[bIsRealName] = (SQL_FetchInt(hndl, 5) == 99);
        sm_DiscuzDataCache.SetArray(data[szSteamId64], data[0], view_as<int>(Discuz_Data));
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

        Cache_LoadClientDiscuzData(client, FriendID);
    }
}

public void Cache_SQLCallback_OfficalGroup(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("SQLCallback_OfficalGroup", "Load Offical Group List failed. Error happened: %s", error);
        return;
    }

    if(SQL_GetRowCount(hndl) < 1)
        return;

    al_OfficalGroupListCache.Clear();

    char FriendID[32];

    while(SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 0, FriendID, 32);
        al_OfficalGroupListCache.PushString(FriendID);
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

        if(al_OfficalGroupListCache.FindString(FriendID) == -1)
            continue;

        g_ClientGlobal[client][bInGroup] = true;
    }
}

void Cache_OnClientDisconnect(int client)
{
    char m_szAuth[32];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
    
    if(kv_ClientTrackingDataCache.JumpToKey(m_szAuth, false))
    {
        kv_ClientTrackingDataCache.DeleteThis();
        kv_ClientTrackingDataCache.Rewind();
        kv_ClientTrackingDataCache.ExportToFile("addons/sourcemod/data/core.track.kv.txt");
    }
}

void Cache_LoadClientDiscuzData(int client, const char[] FriendID)
{
    int data[Discuz_Data];

    if(!sm_DiscuzDataCache.GetArray(FriendID, data[0], view_as<int>(Discuz_Data)))
        return;

    g_ClientGlobal[client][bVip] = (data[iExpTime] > GetTime());
    g_ClientGlobal[client][iUId] = data[iUId];
    g_ClientGlobal[client][iGrowth] = data[iGrowths];
    g_ClientGlobal[client][bRealName] = data[bIsRealName];
    strcopy(g_ClientGlobal[client][szForumName], 24, data[szDName]);

    if(al_OfficalGroupListCache.FindString(FriendID) != -1)
        g_ClientGlobal[client][bInGroup] = true;
}
void ClientData_OnClientConnected(int client)
{
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
    g_ClientGlobal[client][szGroupName][0]  = '\0';
    g_ClientGlobal[client][szForumName][0]  = '\0';
    g_ClientGlobal[client][szGamesName][0]  = '\0';
    g_ClientGlobal[client][szSignature][0]  = '\0';
}

void LoadClientDiscuzData(int client, const char[] FriendID)
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

void ClientData_OnClientDisconnect(int client)
{
    //如果客户没有成功INSERT ANALYTICS
    if(g_ClientGlobal[client][iTId] <= 0 || !g_ClientGlobal[client][iConnectTime])
        return;

    if(!g_ClientGlobal[client][bLoaded])
        return;

    if(g_ClientGlobal[client][iTId] == -1 || g_ClientGlobal[client][iPId] == 0)
        return;

    //获得客户名字
    char m_szAuth[32];
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);    

    //开始SQL查询操作
    char m_szBuffer[64], m_szQuery[512];
    Database_EscapeName(client, m_szBuffer, 64);
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

void ClientData_OnGlobalTimer(int client)
{
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
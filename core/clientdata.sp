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

void ReCheckClientName(int client)
{
    if(g_ClientGlobal[client][iUId] > 0)
    {
        strcopy(g_ClientGlobal[client][szGamesName], 32, g_ClientGlobal[client][szForumName]);
        if(g_ClientGlobal[client][iUId] != 1) RemoveCharFromName(g_ClientGlobal[client][szGamesName], 32);
        if(strlen(g_ClientGlobal[client][szGamesName]) < 3) Format(g_ClientGlobal[client][szGamesName], 32, "[E#%06d] unnamed", g_ClientGlobal[client][iPId]);
    }
    else
    {
        GetClientName(client, g_ClientGlobal[client][szGamesName], 32);
        RemoveCharFromName(g_ClientGlobal[client][szGamesName], 32);
        Format(g_ClientGlobal[client][szGamesName], 32, "[V#%06d] %s", g_ClientGlobal[client][iPId], g_ClientGlobal[client][szGamesName]);
    }

    Frame_CheckClientName(client);
}

void Frame_CheckClientName(int client)
{
    if(IsFakeClient(client))
        return;

    char name[32];
    GetClientName(client, name, 32);

    if(StrEqual(name, g_ClientGlobal[client][szGamesName]))
        return;

    SetClientName(client, g_ClientGlobal[client][szGamesName]);
}

void PrintWelcomeMessage(int client)
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
    PrintToConsole(client, "                                                                                               ")
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
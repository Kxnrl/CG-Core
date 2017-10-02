Handle Client_Forwards_OnClientLoad;

#include "core/client/native.sp"
#include "core/client/sql.sp"

void Client_OnClientConnected(int client)
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
    g_ClientGlobal[client][szSignature][0]  = '\0';
    
    strcopy(g_ClientGlobal[client][szForumName], 32, "未注册");
}

void Client_OnClientPutInServer(int client)
{
    GetClientIP(client, g_ClientGlobal[client][szIP], 32);

    Client_LoadBaseData(client);
}

void Client_OnClientDisconnect(int client)
{
    if(!g_ClientGlobal[client][bLoaded])
        return;

    //如果客户没有成功INSERT ANALYTICS
    if(g_ClientGlobal[client][iTId] <= 0 || g_ClientGlobal[client][iConnectTime] <= 0 || g_ClientGlobal[client][iPId] == 0)
        return;

    //开始SQL查询操作
    char m_szAuth[32], m_szName[64], m_szQuery[512];
    UTIL_GetEscapeName(client, m_szName, 64);
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);    
    Format(m_szQuery, 512, "UPDATE playertrack_player AS a, playertrack_analytics AS b SET a.name = '%s', a.onlines = a.onlines+%d, a.lasttime = '%d', a.number = a.number+1, a.daytime = '%d', b.duration = '%d' WHERE a.id = '%d' AND b.id = '%d' AND a.steamid = '%s' AND b.playerid = '%d'", m_szName, g_ClientGlobal[client][iConnectTime], GetTime(), g_ClientGlobal[client][iDaily], g_ClientGlobal[client][iConnectTime], g_ClientGlobal[client][iPId], g_ClientGlobal[client][iTId], m_szAuth, g_ClientGlobal[client][iPId]);
    UTIL_SQLTVoid(g_dbGames, m_szQuery, DBPrio_High);
}

void Client_OnGlobalTimer(int client)
{
    g_ClientGlobal[client][iDaily]++;
    g_ClientGlobal[client][iConnectTime]++;

    Cache_UpdateClientData(client, g_ClientGlobal[client][iPId], g_ClientGlobal[client][iConnectTime], g_ClientGlobal[client][iTId], g_ClientGlobal[client][iDaily]);
}
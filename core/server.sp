Handle Server_Forwards_OnServerLoaded;

void Server_OnAskPluginLoad2()
{
    //Random Rcon password
    FormatEx(g_szRconPwd, 32, "%d", GetRandomInt(10000000, 99999999));
    SetConVarString(FindConVar("rcon_password"), g_szRconPwd); 
}

void Server_OnPluginStart()
{
    //Init date
    char m_szDate[32];
    FormatTime(m_szDate, 64, "%Y%m%d", GetTime());
    g_iNowDate = StringToInt(m_szDate);
    
    //Get server IP
    int ip = GetConVarInt(FindConVar("hostip"));
    FormatEx(g_szIP, 32, "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    Server_Forwards_OnServerLoaded = CreateGlobalForward("CG_OnServerLoaded", ET_Ignore);
}

void Server_OnGlobalTimer()
{
    int unix_timestamp = GetTime();
    if(unix_timestamp % 3600 == 0)
    {
        char m_szDate[32];
        FormatTime(m_szDate, 32, "%H", unix_timestamp);
        GlobalApi_Forward_OnNowTime(StringToInt(m_szDate));
        FormatTime(m_szDate, 32, "%Y%m%d", unix_timestamp);
        int date = StringToInt(m_szDate);
        if(date > g_iNowDate)
        {
            GlobalApi_Forward_OnNewDay(date);

            for(int client = 1; client <= MaxClients; ++client)
                g_ClientGlobal[client][iDaily] = 0;
        }
    }
}

void Server_Forward_OnServerLoaded()
{
    Call_StartForward(Server_Forwards_OnServerLoaded);
    Call_Finish();

    Server_LoadAdvertisement();

    //Update local data if server was crashed
    Cache_OnServerLoaded();

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

void Server_LoadAdvertisement()
{
    char m_szQuery[512];
    Format(m_szQuery, 512, "SELECT * FROM playertrack_adv WHERE sid = '%i' OR sid = '0'", g_iServerId);
    UTIL_TQuery(g_dbGames, Server_SQLCallback_GetAdvData, m_szQuery, _, DBPrio_High);
}

public void Server_SQLCallback_GetAdvData(Handle owner, Handle hndl, const char[] error, any data)
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
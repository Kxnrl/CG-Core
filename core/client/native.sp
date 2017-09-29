void Client_OnAskPluginLoad2()
{
    CreateNative("CG_ClientGetOnlines",     Client_Native_ClientGetOnlines);
    CreateNative("CG_ClientGetGrowth",      Client_Native_ClientGetGrowth);
    CreateNative("CG_ClientGetVitality",    Client_Native_ClientGetVitality);
    CreateNative("CG_ClientGetDailyTime",   Client_Native_ClientGetDailyTime);
    CreateNative("CG_ClientGetLastseen",    Client_Native_ClientGetLastseen);
    CreateNative("CG_ClientGetPId",         Client_Native_ClientGetPID);
    CreateNative("CG_ClientGetUId",         Client_Native_ClientGetUID);
    CreateNative("CG_ClientGetGId",         Client_Native_ClientGetGID);
    CreateNative("CG_ClientIsVIP",          Client_Native_ClientIsVIP);
    CreateNative("CG_ClientInGroup",        Client_Native_ClientInGroup);
    CreateNative("CG_ClientIsRealName",     Client_Native_ClientIsRealName);
    CreateNative("CG_ClientSetVIP",         Client_Native_ClientSetVIP);
    CreateNative("CG_ClientGetForumName",   Client_Native_ClientGetForumName);
    CreateNative("CG_ClientGetGroupName",   Client_Native_ClientGetGroupName);
    CreateNative("CG_ClientGetSignature",   Client_Native_ClientGetSingature);
    
    //test
    CreateNative("CG_ClientGetTermOnline",  Client_Native_ClientGetTermOnline);
}

void Client_OnPluginStart()
{
    Client_Forwards_OnClientLoad = CreateGlobalForward("CG_OnClientLoaded", ET_Ignore, Param_Cell);
}

public int Client_Native_ClientGetOnlines(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iOnline];
}

public int Client_Native_ClientGetGrowth(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iGrowth];
}

public int Client_Native_ClientGetVitality(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iVitality];
}

public int Client_Native_ClientGetDailyTime(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iDaily];
}

public int Client_Native_ClientGetLastseen(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iLastseen];
}

public int Client_Native_ClientGetPID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iPId];
}

public int Client_Native_ClientGetUID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iUId];
}

public int Client_Native_ClientGetGID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iGId];
}

public int Client_Native_ClientIsVIP(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bVip];
}

public int Client_Native_ClientInGroup(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bInGroup];
}

public int Client_Native_ClientIsRealName(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bRealName];
}

public int Client_Native_ClientSetVIP(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(!g_ClientGlobal[client][bLoaded])
        return;

    g_ClientGlobal[client][bVip] = true;
}

public int Client_Native_ClientGetForumName(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szForumName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Forum name.");
}

public int Client_Native_ClientGetGroupName(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szGroupName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Group Name.");
}

public int Client_Native_ClientGetSingature(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szSignature], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Singature.");
}

public int Client_Native_ClientGetTermOnline(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int start  = GetNativeCell(2);
    int end    = GetNativeCell(3);
    Function callback = GetNativeCell(4);
    
    if(!g_ClientGlobal[client][bLoaded])
        return;
    
    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(start);
    pack.WriteCell(end);
    pack.WriteFunction(callback);
    pack.WriteCell(plugin);
    pack.Reset();

    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "SELECT sum(duration) as onlines FROM playertrack_analytics WHERE playerid = '%d' AND connect_time >= '%d' AND connect_time <= '%d' ;", g_ClientGlobal[client][iPId], start, end);
    UTIL_TQuery(g_dbGames, Client_SQLCallback_NativeGetTermOnline, m_szQuery, pack, DBPrio_High);
}

void Client_Forward_OnClientLoaded(int client)
{
    if(!IsFakeClient(client))
    {
        //Colsole print
        UTIL_PrintWelcomeMessage(client);
    }

    //Call Forward
    Call_StartForward(Client_Forwards_OnClientLoad);
    Call_PushCell(client);
    Call_Finish();
}
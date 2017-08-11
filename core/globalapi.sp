#define MAX_CHANNEL 6

enum Forwards
{
    //Global
    Handle:ClientLoaded,
    Handle:VipChecked,
    Handle:APIGetCredits,
    Handle:APISetCredits,
    Handle:OnNewDay,
    Handle:OnNowTime,
    Handle:GlobalTimer,

    //Event
    Handle:round_start,
    Handle:round_end,
    Handle:player_spawn,
    Handle:player_death,
    Handle:player_hurt,
    Handle:player_team,
    Handle:player_jump,
    Handle:weapon_fire,
    Handle:player_name
}

enum TextHud
{
    Float:fHold,
    Float:fX,
    Float:fY,
    Handle:hTimer
}

Handle GlobalApi_Forwards[Forwards];

TextHud GlobalApi_Data_TextHud[MAX_CHANNEL][TextHud];

void GlobalApi_OnAskPluginLoad2()
{
    CreateNative("CG_GetServerId",        GlobalApi_Native_GetServerID);

    CreateNative("CG_ShowGameText",       GlobalApi_Native_ShowGameText);
    CreateNative("CG_ShowGameTextAll",    GlobalApi_Native_ShowGameTextAll);
    CreateNative("CG_ShowNormalMotd",     GlobalApi_Native_ShowNormalMotd);
    CreateNative("CG_ShowHiddenMotd",     GlobalApi_Native_ShowHiddenMotd);
    CreateNative("CG_RemoveMotd",         GlobalApi_Native_RemoveMotd);

    CreateNative("HookClientVIPChecked",  GlobalApi_Native_HookVipChecked);

    CreateNative("CG_ClientGetOnlines",   GlobalApi_Native_ClientGetOnlines);
    CreateNative("CG_ClientGetGrowth",    GlobalApi_Native_ClientGetGrowth);
    CreateNative("CG_ClientGetVitality",  GlobalApi_Native_ClientGetVitality);
    CreateNative("CG_ClientGetDailyTime", GlobalApi_Native_ClientGetDailyTime);
    CreateNative("CG_ClientGetLastseen",  GlobalApi_Native_ClientGetLastseen);
    CreateNative("CG_ClientGetPId",       GlobalApi_Native_ClientGetPID);
    CreateNative("CG_ClientGetUId",       GlobalApi_Native_ClientGetUID);
    CreateNative("CG_ClientGetGId",       GlobalApi_Native_ClientGetGID);
    CreateNative("CG_ClientIsVIP",        GlobalApi_Native_ClientIsVIP);
    CreateNative("CG_ClientInGroup",      GlobalApi_Native_ClientInGroup);
    CreateNative("CG_ClientIsRealName",   GlobalApi_Native_ClientIsRealName);
    CreateNative("CG_ClientSetVIP",       GlobalApi_Native_ClientSetVIP);
    CreateNative("CG_ClientGetForumName", GlobalApi_Native_ClientGetForumName);
    CreateNative("CG_ClientGetGroupName", GlobalApi_Native_ClientGetGroupName);
    CreateNative("CG_ClientGetSignature", GlobalApi_Native_ClientGetSingature);
}

public int GlobalApi_Native_GetServerID(Handle plugin, int numParams)
{
    return g_iServerId;
}

public int GlobalApi_Native_ClientGetOnlines(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iOnline];
}

public int GlobalApi_Native_ClientGetGrowth(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iGrowth];
}

public int GlobalApi_Native_ClientGetVitality(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iVitality];
}

public int GlobalApi_Native_ClientGetDailyTime(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iDaily];
}

public int GlobalApi_Native_ClientGetLastseen(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iLastseen];
}

public int GlobalApi_Native_ClientGetPID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iPId];
}

public int GlobalApi_Native_ClientGetUID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iUId];
}

public int GlobalApi_Native_ClientGetGID(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][iGId];
}

public int GlobalApi_Native_ClientIsVIP(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bVip];
}

public int GlobalApi_Native_ClientInGroup(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bInGroup];
}

public int GlobalApi_Native_ClientIsRealName(Handle plugin, int numParams)
{
    return g_ClientGlobal[GetNativeCell(1)][bRealName];
}

public int GlobalApi_Native_ClientSetVIP(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(!g_ClientGlobal[client][bLoaded])
        return;

    g_ClientGlobal[client][bVip] = true;
}

public int GlobalApi_Native_ClientGetForumName(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szForumName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Forum name.");
}

public int GlobalApi_Native_ClientGetGroupName(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szGroupName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Group Name.");
}

public int GlobalApi_Native_ClientGetSingature(Handle plugin, int numParams)
{
    if(SetNativeString(2, g_ClientGlobal[GetNativeCell(1)][szSignature], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Singature.");
}

public int GlobalApi_Native_HookVipChecked(Handle plugin, int numParams)
{
    return AddToForward(GlobalApi_Forwards[VipChecked], plugin, GetNativeCell(1));
}

public int GlobalApi_Native_ShowNormalMotd(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(!IsValidClient(client))
        return false;

    QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);
    int width = GetNativeCell(2)-12;
    int height = GetNativeCell(3)-80;
    char m_szUrl[192];

    if(GetNativeString(4, m_szUrl, 192) != SP_ERROR_NONE)
    {
        UTIL_LogError("GlobalApi_Native_ShowNormalMotd", "\"%L\" -> Native_ShowNormalMotd -> %s", client, m_szUrl);
        return false;
    }

    return GlobalApi_UrlToWebInterface(client, width, height, m_szUrl, true);
}

public int GlobalApi_Native_ShowHiddenMotd(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(!IsValidClient(client))
        return false;

    QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(OnGetClientCVAR), client);

    char m_szUrl[192];
    if(GetNativeString(2, m_szUrl, 192) != SP_ERROR_NONE)
        return false;

    return GlobalApi_UrlToWebInterface(client, 0, 0, m_szUrl, false);
}

public int GlobalApi_Native_RemoveMotd(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(!IsValidClient(client))
        return false;

    return GlobalApi_UrlToWebInterface(client, 0, 0, "https://csgogamers.com/", false);
}

public int GlobalApi_Native_ShowGameText(Handle plugin, int numParams)
{
    char color[32], message[1024], holdtime[16], szX[16], szY[16];
    if
    (
        GetNativeString(1, message, 1024) != SP_ERROR_NONE ||
        GetNativeString(2, holdtime,  16) != SP_ERROR_NONE ||
        GetNativeString(3, color,     32) != SP_ERROR_NONE ||
        GetNativeString(4, szX,       16) != SP_ERROR_NONE ||
        GetNativeString(5, szY,       16) != SP_ERROR_NONE
    )
        return false;

    ArrayList array_client = GetNativeCell(6);

    if(array_client == INVALID_HANDLE)
        return false;

    if(GetArraySize(array_client) < 1)
        return false;

    return GlobalApi_ShowGameText(array_client, message, StringToFloat(holdtime), color, StringToFloat(szX), StringToFloat(szY));
}

public int GlobalApi_Native_ShowGameTextAll(Handle plugin, int numParams)
{
    char color[32], message[1024], holdtime[16], szX[16], szY[16];
    if
    (
        GetNativeString(1, message, 1024) != SP_ERROR_NONE ||
        GetNativeString(2, holdtime,  16) != SP_ERROR_NONE ||
        GetNativeString(3, color,     32) != SP_ERROR_NONE ||
        GetNativeString(4, szX,       16) != SP_ERROR_NONE ||
        GetNativeString(5, szY,       16) != SP_ERROR_NONE
    )
        return false;

    return GlobalApi_ShowGameText(INVALID_HANDLE, message, StringToFloat(holdtime), color, StringToFloat(szX), StringToFloat(szY));
}

bool GlobalApi_ShowGameText(Handle array_client, const char[] message, const float holdtime, const char[] color, const float x, const float y)
{
    int channel = GlobalApi_GetFreelyChannel(x, y);

    if(channel < 0 || channel >= MAX_CHANNEL)
    {
        UTIL_LogError("GlobalApi_ShowGameText", "Can not find free channel -> [%f,%f]", x, y);
        return false;
    }

    char szColor[3][4];
    ExplodeString(color, " ", szColor, 3, 4);
    int r = StringToInt(szColor[0]);
    int g = StringToInt(szColor[1]);
    int b = StringToInt(szColor[2]);

    SetHudTextParams(x, y, holdtime, r, g, b, 255, 0, 30.0, 0.0, 0.0);

    if(GlobalApi_Data_TextHud[channel][hTimer] != INVALID_HANDLE)
        KillTimer(GlobalApi_Data_TextHud[channel][hTimer]);

    GlobalApi_Data_TextHud[channel][fHold] = GetGameTime()+holdtime;
    GlobalApi_Data_TextHud[channel][hTimer] = CreateTimer(holdtime, Timer_ResetChannel, channel, TIMER_FLAG_NO_MAPCHANGE);
    GlobalApi_Data_TextHud[channel][fX] = x;
    GlobalApi_Data_TextHud[channel][fY] = y;
    
    channel += 4;

    if(array_client != INVALID_HANDLE)
    {
        int arraysize = GetArraySize(array_client);
        for(int index = 0; index < arraysize; ++index)
            ShowHudText(GetArrayCell(array_client, index), channel, message);
    }
    else
    {
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client) && !IsFakeClient(client))
                ShowHudText(client, channel, message);
    }

    return true;
}

void GlobalApi_OnPluginStart()
{
    //Global
    GlobalApi_Forwards[APISetCredits] = CreateGlobalForward("CG_APIStoreSetCredits", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);
    GlobalApi_Forwards[APIGetCredits] = CreateGlobalForward("CG_APIStoreGetCredits", ET_Event, Param_Cell);
    GlobalApi_Forwards[ClientLoaded]  = CreateGlobalForward("CG_OnClientLoaded",     ET_Ignore, Param_Cell);
    GlobalApi_Forwards[OnNewDay]      = CreateGlobalForward("CG_OnNewDay",           ET_Ignore, Param_Cell);
    GlobalApi_Forwards[OnNowTime]     = CreateGlobalForward("CG_OnNowTime",          ET_Ignore, Param_Cell);
    GlobalApi_Forwards[GlobalTimer]   = CreateGlobalForward("CG_OnGlobalTimer",      ET_Ignore);

    GlobalApi_Forwards[VipChecked]    = CreateForward(ET_Ignore, Param_Cell);

    //Event
    GlobalApi_Forwards[round_start]   = CreateGlobalForward("CG_OnRoundStart",       ET_Ignore);
    GlobalApi_Forwards[round_end]     = CreateGlobalForward("CG_OnRoundEnd",         ET_Ignore, Param_Cell);
    GlobalApi_Forwards[player_spawn]  = CreateGlobalForward("CG_OnClientSpawn",      ET_Ignore, Param_Cell);
    GlobalApi_Forwards[player_death]  = CreateGlobalForward("CG_OnClientDeath",      ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
    GlobalApi_Forwards[player_hurt]   = CreateGlobalForward("CG_OnClientHurted",     ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
    GlobalApi_Forwards[player_team]   = CreateGlobalForward("CG_OnClientTeam",       ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    GlobalApi_Forwards[player_jump]   = CreateGlobalForward("CG_OnClientJump",       ET_Ignore, Param_Cell);
    GlobalApi_Forwards[weapon_fire]   = CreateGlobalForward("CG_OnClientFire",       ET_Ignore, Param_Cell, Param_String);
    GlobalApi_Forwards[player_name]   = CreateGlobalForward("CG_OnClientName",       ET_Ignore, Param_Cell, Param_String, Param_String);

    //Hook 回合开始
    if(!HookEventEx("round_start", Event_RoundStart, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"round_start\" Failed");

    //Hook 回合结束
    if(!HookEventEx("round_end", Event_RoundEnd, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"round_end\" Failed");

    //Hook 玩家出生
    if(!HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_spawn\" Failed");

    //Hook 玩家死亡
    if(!HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_death\" Failed");

    //Hook 玩家受伤
    if(!HookEventEx("player_hurt", Event_PlayerHurts, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_hurt\" Failed");

    //Hook 玩家队伍
    if(!HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Pre))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_team\" Failed");

    //Hook 玩家跳跃
    if(!HookEventEx("player_jump", Event_PlayerJump, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_jump\" Failed");

    //Hook 武器射击
    if(!HookEventEx("weapon_fire", Event_WeaponFire, EventHookMode_Post))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"weapon_fire\" Failed");

    //Hook 玩家改名
    if(!HookEventEx("player_changename", Event_PlayerName, EventHookMode_Pre))
        UTIL_LogError("GlobalApi_OnPluginStart", "Hook Event \"player_changename\" Failed");
}

void GlobalApi_OnClientLoaded(int client)
{
    if(IsFakeClient(client))
    {
        //Call Forward
        Call_StartForward(GlobalApi_Forwards[ClientLoaded]);
        Call_PushCell(client);
        Call_Finish();
        return;
    }

    //Check join game.
    CreateTimer(45.0, Timer_CheckJoinGame, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    //Format Name
    ReCheckClientName(client);

    //Colsole print
    PrintWelcomeMessage(client);

    //Call Forward
    Call_StartForward(GlobalApi_Forwards[ClientLoaded]);
    Call_PushCell(client);
    Call_Finish();
}

void OnClientVipChecked(int client)
{
    //Call Forward
    Call_StartForward(GlobalApi_Forwards[VipChecked]);
    Call_PushCell(client);
    Call_Finish();
}

bool OnAPIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
    bool result;

    //Call Forward
    Call_StartForward(GlobalApi_Forwards[APISetCredits]);
    Call_PushCell(client);
    Call_PushCell(credits);
    Call_PushString(reason);
    Call_PushCell(immed);
    Call_Finish(result);

    return result;
}

int OnAPIStoreGetCredits(int client) 
{
    int result;

    //Call Forward
    Call_StartForward(GlobalApi_Forwards[APIGetCredits]);
    Call_PushCell(client);
    Call_Finish(result);

    return result;
}


void OnNewDayForward(int iDate)
{
    g_iNowDate = iDate;

    //Call Forward
    Call_StartForward(GlobalApi_Forwards[OnNewDay]);
    Call_PushCell(g_iNowDate);
    Call_Finish();
}

void OnNowTimeForward(int oclock)
{
    //Call Forward
    Call_StartForward(GlobalApi_Forwards[OnNowTime]);
    Call_PushCell(oclock);
    Call_Finish();
}

void OnGlobalTimer()
{
    //Call Forward
    Call_StartForward(GlobalApi_Forwards[GlobalTimer]);
    Call_Finish();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[round_start]);
    Call_Finish();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[round_end]);
    Call_PushCell(GetEventInt(event, "winner"));
    Call_Finish();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[player_spawn]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    Call_Finish();
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[player_death]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "attacker")));
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "assister")));
    Call_PushCell(GetEventBool(event, "headshot"));
    char weapon[32];
    GetEventString(event, "weapon", weapon, 32, "");
    Call_PushString(weapon);
    Call_Finish();
}

public void Event_PlayerHurts(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[player_hurt]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "attacker")));
    Call_PushCell(GetEventInt(event, "dmg_health"));
    Call_PushCell(GetEventInt(event, "hitgroup"));
    char weapon[32];
    GetEventString(event, "weapon", weapon, 32, "");
    Call_PushString(weapon);
    Call_Finish();
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    SetEventBroadcast(event, true);

    Call_StartForward(GlobalApi_Forwards[player_team]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    Call_PushCell(GetEventInt(event, "oldteam"));
    Call_PushCell(GetEventInt(event, "team"));
    Call_Finish();

    return Plugin_Changed;
}

public void Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[player_jump]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    Call_Finish();
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
    Call_StartForward(GlobalApi_Forwards[weapon_fire]);
    Call_PushCell(GetClientOfUserId(GetEventInt(event, "userid")));
    char weapon[32];
    GetEventString(event, "weapon", weapon, 32, "");
    Call_PushString(weapon);
    Call_Finish();
}

public Action Event_PlayerName(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"))

    Call_StartForward(GlobalApi_Forwards[player_name]);
    Call_PushCell(client);
    char oldname[32];
    GetEventString(event, "oldname", oldname, 32, "");
    Call_PushString(oldname);
    char newname[32];
    GetEventString(event, "newname", newname, 32, "");
    Call_PushString(newname);
    Call_Finish();

    RequestFrame(Frame_CheckClientName, client);

    SetEventBroadcast(event, true);

    return Plugin_Changed;
}

void GlobalApi_OnMapStart()
{
    for(int channel = 0; channel < MAX_CHANNEL; ++channel)
    {
        GlobalApi_Data_TextHud[channel][fHold] = GetGameTime();
        GlobalApi_Data_TextHud[channel][hTimer] = INVALID_HANDLE;
        GlobalApi_Data_TextHud[channel][fX] = 0.0;
        GlobalApi_Data_TextHud[channel][fY] = 0.0;
    }
}

bool GlobalApi_UrlToWebInterface(int client, int width, int height, const char[] url, bool show)
{
    if(!g_ClientGlobal[client][bLoaded])
        return false;

    char m_szQuery[512], m_szEscape[256];
    SQL_EscapeString(Database_DBHandle_Games, url, m_szEscape, 256);
    Format(m_szQuery, 512, "INSERT INTO `playertrack_webinterface` (`playerid`, `show`, `width`, `height`, `url`) VALUES (%d, %b, %d, %d, '%s') ON DUPLICATE KEY UPDATE `url` = VALUES(`url`), `show`=%b, `width`=%d, `height`=%d", g_ClientGlobal[client][iPId], show, width, height, m_szEscape, show, width, height);
    return MySQL_Query(false, GlobalApi_SQLCallback_WebInterface, m_szQuery, client | (view_as<int>(show) << 7), DBPrio_High);
}

void GlobalApi_ShowMOTDPanelEx(int client, bool show = true)
{
    char url[192];
    Format(url, 192, "https://csgogamers.com/webplugin.php?id=%d", g_ClientGlobal[client][iPId]);

    Handle m_hKv = CreateKeyValues("data");
    KvSetString(m_hKv, "title", "CSGOGAMERS.COM");
    KvSetNum(m_hKv, "type", MOTDPANEL_TYPE_URL);
    KvSetString(m_hKv, "msg", url);
    KvSetNum(m_hKv, "cmd", 0);
    ShowVGUIPanel(client, "info", m_hKv, show);
    CloseHandle(m_hKv);
}

public void GlobalApi_SQLCallback_WebInterface(Handle owner, Handle hndl, const char[] error, int data)
{
    int client = data & 0x7f;
    bool show = (data >> 7) == 1;

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("GlobalApi_SQLCallback_WebInterface", "GlobalApi_UrlToWebInterface: client:%N ERROR:%s", client, error);
        return;
    }

    GlobalApi_ShowMOTDPanelEx(client, show);
}

int GlobalApi_GetFreelyChannel(const float x, const float y)
{
    for(int channel = 0; channel < MAX_CHANNEL; ++channel)
        if(GlobalApi_Data_TextHud[channel][fX] == x && GlobalApi_Data_TextHud[channel][fY] == y)
            return channel;

    for(int channel = 0; channel < MAX_CHANNEL; ++channel)
        if(GlobalApi_Data_TextHud[channel][fHold] <= GetGameTime())
            return channel;

    return -1;
}

public Action Timer_ResetChannel(Handle timer, int channel)
{
    GlobalApi_Data_TextHud[channel][hTimer] = INVALID_HANDLE;
    GlobalApi_Data_TextHud[channel][fX] = 0.0;
    GlobalApi_Data_TextHud[channel][fY] = 0.0;

    return Plugin_Stop;
}

public void OnGetClientCVAR(QueryCookie cookie, int client, ConVarQueryResult result, char[] cvarName, char[] cvarValue)
{
    if(StringToInt(cvarValue) > 0)
        PrintToChat(client, " 请在控制台中输入:   \x04cl_disablehtmlmotd 0");
}
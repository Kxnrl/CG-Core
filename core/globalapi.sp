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
    iEntRef,
    Float:fHolded,
    String:szPosX[16],
    String:szPosY[16],
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
    CreateNative("CG_ClientGetForumName",     GlobalApi_Native_ClientGetForumName);
    CreateNative("CG_ClientGetGroupName",     GlobalApi_Native_ClientGetGroupName);
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
    char color[32], message[256], holdtime[16], szX[16], szY[160];
    if
    (
        GetNativeString(1, message, 256) != SP_ERROR_NONE ||
        GetNativeString(2, holdtime, 16) != SP_ERROR_NONE ||
        GetNativeString(3, color,    32) != SP_ERROR_NONE ||
        GetNativeString(4, szX,      16) != SP_ERROR_NONE ||
        GetNativeString(5, szY,      16) != SP_ERROR_NONE
    )
        return false;

    int channel = GlobalApi_GetFreelyChannel(szX, szY);

    if(channel < 0 || channel >= MAX_CHANNEL)
        return false;

    ArrayList array_client = GetNativeCell(6);

    if(array_client == INVALID_HANDLE)
        return false;

    int arraysize = GetArraySize(array_client);

    if(arraysize < 1)
        return false;

    if(GlobalApi_Data_TextHud[channel][hTimer] != INVALID_HANDLE)
        KillTimer(GlobalApi_Data_TextHud[channel][hTimer]);

    float hold = StringToFloat(holdtime);

    GlobalApi_Data_TextHud[channel][fHolded] = GetGameTime()+hold;
    GlobalApi_Data_TextHud[channel][hTimer] = CreateTimer(hold, Timer_ResetChannel, channel, TIMER_FLAG_NO_MAPCHANGE);
    strcopy(GlobalApi_Data_TextHud[channel][szPosX], 16, szX);
    strcopy(GlobalApi_Data_TextHud[channel][szPosY], 16, szY);

    int entity = -1;
    if(!IsValidEntity(GlobalApi_Data_TextHud[channel][iEntRef]))
    {
        entity = CreateEntityByName("game_text");
        GlobalApi_Data_TextHud[channel][iEntRef] = EntIndexToEntRef(entity);

        char tname[32]
        Format(tname, 32, "game_text_%i", entity);
        DispatchKeyValue(entity,"targetname", tname);
    }
    else
        entity = EntRefToEntIndex(GlobalApi_Data_TextHud[channel][iEntRef]);

    char szChannel[4];
    IntToString(channel+4, szChannel, 4);
    
    DispatchKeyValue(entity, "message", message);
    DispatchKeyValue(entity, "spawnflags", "0");
    DispatchKeyValue(entity, "channel", szChannel);
    DispatchKeyValue(entity, "holdtime", holdtime);
    DispatchKeyValue(entity, "fxtime", "99.9");
    DispatchKeyValue(entity, "fadeout", "0");
    DispatchKeyValue(entity, "fadein", "0");
    DispatchKeyValue(entity, "x", szX);
    DispatchKeyValue(entity, "y", szY);
    DispatchKeyValue(entity, "color", color);
    DispatchKeyValue(entity, "color2", color);
    DispatchKeyValue(entity, "effect", "0");

    DispatchSpawn(entity);

    for(int x = 0; x < arraysize; ++x)
        AcceptEntityInput(entity, "Display", GetArrayCell(array_client, x));

    return true;
}

public int GlobalApi_Native_ShowGameTextAll(Handle plugin, int numParams)
{
    char color[32], message[256], holdtime[16], szX[16], szY[160];
    if
    (
        GetNativeString(1, message, 256) != SP_ERROR_NONE ||
        GetNativeString(2, holdtime, 16) != SP_ERROR_NONE ||
        GetNativeString(3, color,    32) != SP_ERROR_NONE ||
        GetNativeString(4, szX,      16) != SP_ERROR_NONE ||
        GetNativeString(5, szY,      16) != SP_ERROR_NONE
    )
        return false;

    int channel = GlobalApi_GetFreelyChannel(szX, szY);

    if(channel < 0 || channel >= MAX_CHANNEL)
        return false;

    if(GlobalApi_Data_TextHud[channel][hTimer] != INVALID_HANDLE)
        KillTimer(GlobalApi_Data_TextHud[channel][hTimer]);

    float hold = StringToFloat(holdtime);

    GlobalApi_Data_TextHud[channel][fHolded] = GetGameTime()+hold;
    GlobalApi_Data_TextHud[channel][hTimer] = CreateTimer(hold, Timer_ResetChannel, channel, TIMER_FLAG_NO_MAPCHANGE);
    strcopy(GlobalApi_Data_TextHud[channel][szPosX], 16, szX);
    strcopy(GlobalApi_Data_TextHud[channel][szPosY], 16, szY);

    int entity = -1;
    if(!IsValidEntity(GlobalApi_Data_TextHud[channel][iEntRef]))
    {
        entity = CreateEntityByName("game_text");
        GlobalApi_Data_TextHud[channel][iEntRef] = EntIndexToEntRef(entity);

        char tname[32]
        Format(tname, 32, "game_text_%i", entity);
        DispatchKeyValue(entity,"targetname", tname);
    }
    else
        entity = EntRefToEntIndex(GlobalApi_Data_TextHud[channel][iEntRef]);

    char szChannel[4];
    IntToString(channel+4, szChannel, 4);

    DispatchKeyValue(entity, "message", message);
    DispatchKeyValue(entity, "spawnflags", "1");
    DispatchKeyValue(entity, "channel", szChannel);
    DispatchKeyValue(entity, "holdtime", holdtime);
    DispatchKeyValue(entity, "fxtime", "99.9");
    DispatchKeyValue(entity, "fadeout", "0");
    DispatchKeyValue(entity, "fadein", "0");
    DispatchKeyValue(entity, "x", szX);
    DispatchKeyValue(entity, "y", szY);
    DispatchKeyValue(entity, "color", color);
    DispatchKeyValue(entity, "color2", color);
    DispatchKeyValue(entity, "effect", "0");

    DispatchSpawn(entity);

    AcceptEntityInput(entity, "Display");

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
    //Call Forward
    Call_StartForward(GlobalApi_Forwards[ClientLoaded]);
    Call_PushCell(client);
    Call_Finish();

    if(IsFakeClient(client))
        return;

    //Check join game.
    CreateTimer(45.0, Timer_CheckJoinGame, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    //Format Name
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

    SetClientName(client, g_ClientGlobal[client][szGamesName]);

    //Colsole print
    int timeleft;
    GetMapTimeLeft(timeleft);
    if(timeleft > 30)
    {
        char szTimeleft[32], szMap[128], szHostname[128];
        Format(szTimeleft, 32, "%d:%02d", timeleft / 60, timeleft % 60);
        GetCurrentMap(szMap, 128);
        GetConVarString(FindConVar("hostname"), szHostname, 128);

        PrintToConsole(client, "-----------------------------------------------------------------------------------------------");
        PrintToConsole(client, "                                                                                               ");
        PrintToConsole(client, "                                     欢迎来到[CG]游戏社区                                      ");    
        PrintToConsole(client, "                                                                                               ");
        PrintToConsole(client, "当前服务器:  %s   -   Tickrate: %d.0   -   主程序版本: %s - Build %d", szHostname, RoundToNearest(1.0 / GetTickInterval()), PLUGIN_VERSION, Build);
        PrintToConsole(client, " ");
        PrintToConsole(client, "论坛地址: https://csgogamers.com  官方QQ群: 107421770");
        PrintToConsole(client, "当前地图: %s   剩余时间: %s", szMap, szTimeleft);
        PrintToConsole(client, "                                                                                               ");
        PrintToConsole(client, "服务器基础命令:");
        PrintToConsole(client, "核心命令:  !cg    [核心菜单]");
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

    //Check Flags
    if(StrEqual(g_ClientGlobal[client][szFlags], "OP+VIP") && g_ClientGlobal[client][bVip])
        return;

    if(StrEqual(g_ClientGlobal[client][szFlags], "OP") && !(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP))
        return;

    char newflags[16];

    if(g_ClientGlobal[client][iGId] >= 9990)
        strcopy(newflags, 16, "Admin");
    else if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP)
        strcopy(newflags, 16, g_ClientGlobal[client][bVip] ? "OP+VIP" : "OP");
    else if(g_ClientGlobal[client][bVip])
        strcopy(newflags, 16, "VIP"); //SVIP
    else
        strcopy(newflags, 16, "荣誉会员");

    if(StrEqual(g_ClientGlobal[client][szFlags], newflags))
        return;

    strcopy(g_ClientGlobal[client][szFlags], 16, newflags);

    char m_szQuery[128];
    Format(m_szQuery, 128, "UPDATE `playertrack_player` SET `flags` = '%s' WHERE `id` = '%d'", g_ClientGlobal[client][szFlags], g_ClientGlobal[client][iPId]);
    MySQL_Query(false, Database_SQLCallback_NoResults, m_szQuery, 1);

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
        GlobalApi_Data_TextHud[channel][iEntRef] = INVALID_ENT_REFERENCE;
        GlobalApi_Data_TextHud[channel][fHolded] = GetGameTime();
        GlobalApi_Data_TextHud[channel][hTimer] = INVALID_HANDLE;
        GlobalApi_Data_TextHud[channel][szPosX][0] = '\0';
        GlobalApi_Data_TextHud[channel][szPosY][0] = '\0';
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

int GlobalApi_GetFreelyChannel(const char[] szX, const char[] szY)
{
    for(int channel = 0; channel < MAX_CHANNEL; ++channel)
        if(StrEqual(GlobalApi_Data_TextHud[channel][szPosX], szX) && StrEqual(GlobalApi_Data_TextHud[channel][szPosY], szY))
            return channel;

    for(int channel = 0; channel < MAX_CHANNEL; ++channel)
        if(GlobalApi_Data_TextHud[channel][fHolded] <= GetGameTime())
            return channel;

    return -1;
}

public Action Timer_ResetChannel(Handle timer, int channel)
{
    GlobalApi_Data_TextHud[channel][hTimer] = INVALID_HANDLE;
    GlobalApi_Data_TextHud[channel][szPosX][0] = '\0';
    GlobalApi_Data_TextHud[channel][szPosY][0] = '\0';

    return Plugin_Stop;
}

public void OnGetClientCVAR(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
    if(StringToInt(cvarValue) > 0)
        PrintToChat(client, " 请在控制台中输入:   \x04cl_disablehtmlmotd 0");
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
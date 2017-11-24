int HUD_iLastTarget[MAXPLAYERS+1];
Handle HUD_hSync;
char HUD_szTag[MAXPLAYERS+1][32];
char HUD_szMsg[MAXPLAYERS+1][256];
char HUD_szSignature[MAXPLAYERS+1][128];

void HUD_OnAskPluginLoad2()
{
    CreateNative("CG_HUDFormatClientTag", Native_HUD_FormatClientTag);
    CreateNative("CG_HUDFormatClientMsg", Native_HUD_FormatClientMsg);
}

public int Native_HUD_FormatClientTag(Handle plugin, int numParams)
{
    char tag[32];
    GetNativeString(2, tag, 32);
    FormatEx(HUD_szTag[GetNativeCell(1)], 32, "【%s】", tag);
}

public int Native_HUD_FormatClientMsg(Handle plugin, int numParams)
{
    char msg[256];
    GetNativeString(2, msg, 256);
    FormatEx(HUD_szMsg[GetNativeCell(1)], 256, "\n%s", msg);
}

void HUD_OnPluginStart()
{
    HUD_hSync = CreateHudSynchronizer();
}

void HUD_OnGlobalTimer(int client)
{
    if(IsPlayerAlive(client))
        return;
    
    HUD_UpdateClientSpecTarget(client);
}

void HUD_OnClientConnected(int client)
{
    HUD_iLastTarget[client] = 0;
    HUD_szMsg[client][0] = '\0';
    HUD_szTag[client][0] = '\0';
    HUD_szSignature[client][0] = '\0';
}

void HUD_OnClientLoaded(int client)
{
    strcopy(HUD_szSignature[client], 128, g_ClientGlobal[client][szSignature]);
    ReplaceString(HUD_szSignature[client], 512, "{白}", "");
    ReplaceString(HUD_szSignature[client], 512, "{红}", "");
    ReplaceString(HUD_szSignature[client], 512, "{粉}", "");
    ReplaceString(HUD_szSignature[client], 512, "{绿}", "");
    ReplaceString(HUD_szSignature[client], 512, "{黄}", "");
    ReplaceString(HUD_szSignature[client], 512, "{亮绿}", "");
    ReplaceString(HUD_szSignature[client], 512, "{亮红}", "");
    ReplaceString(HUD_szSignature[client], 512, "{灰}", "");
    ReplaceString(HUD_szSignature[client], 512, "{褐}", "");
    ReplaceString(HUD_szSignature[client], 512, "{橙}", "");
    ReplaceString(HUD_szSignature[client], 512, "{紫}", "");
    ReplaceString(HUD_szSignature[client], 512, "{亮蓝}", "");
    ReplaceString(HUD_szSignature[client], 512, "{蓝}", "");
}

void HUD_OnClientSpawn(int client)
{
    HUD_iLastTarget[client] = 0;
    ClearSyncHud(client, HUD_hSync);
}

void HUD_UpdateClientSpecTarget(int client)
{
    if(GetClientMenu(client, INVALID_HANDLE) != MenuSource_None)
    {
        HUD_iLastTarget[client] = 0;
        ClearSyncHud(client, HUD_hSync);
        return;
    }

    if(!(4 <= GetEntProp(client, Prop_Send, "m_iObserverMode") <= 5)) // 4 = FirstPerson, 5 = ThirdPerson
    {
        HUD_iLastTarget[client] = 0;
        ClearSyncHud(client, HUD_hSync);
        return;
    }
 
    int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
    
    if(HUD_iLastTarget[client] == target || !IsValidClient(target))
        return;

    HUD_iLastTarget[client] = target;

    char grils[32], message[512];
    UpperString(GFL_Client_Data[client][szWeapon], grils, 32);
    FormatEx(message, 512, "%s%N%s\n论坛: %s\n认证: %s\n伴侣: %s\n枪娘: %s\n签名: %s", HUD_szTag[target], target, HUD_szMsg[target], g_ClientGlobal[target][szForumName], g_ClientGlobal[target][szGroupName], Couples_Client_Data[target][szPartnerName], grils, HUD_szSignature[target]);

    SetHudTextParamsEx(0.01, 0.35, 200.0, {255,130,171,255}, {255,165,0,255}, 0, 10.0, 5.0, 5.0);
    ShowSyncHudText(client, HUD_hSync, message);
}

void UpperString(const char[] input, char[] output, int size)
{
    size--;

    int x = 0;
    while(input[x] != '\0' && x < size)
    {
        output[x] = CharToUpper(input[x]);
        x++;
    }

    output[x] = '\0';
}
// table playertrack_couples
// filed cpid, source_id, target_id, date, exp, together

enum Couples
{
    iPartnerIndex,
    iPartnerPlayerId,
    iWeddingDate,
    iCPExp,
    iCPLvl,
    iCPEarnExp,
    iTogether,
    iTogetherPlay,
    String:szPartnerName[32]
}
enum Couples_Ranking
{
    iWeddingDay,
    iCouplesExp,
    iSource_PId,
    iTarget_Pid,
    iCouplesRank,
    iCouplesTogether,
    String:szSource_Name[32],
    String:szTarget_Name[32]
}

///////////////////////////////////
//                               //
//          Global Config        //
//                               //
bool Couples_Enabled = false;

int Couples_Data_Client_ProposeTargetUserId[MAXPLAYERS+1];
int Couples_Data_Client_ProposeSelectUserId[MAXPLAYERS+1];
int Couples_Data_Client_ProposeSelectedTime[MAXPLAYERS+1];

int Couples_Client_Data[MAXPLAYERS+1][Couples];

Handle Couples_Forward_OnWedding;
Handle Couples_Forward_OnDivorce;
Handle Couples_Menu_Ranking;
Panel Couples_Panel_About;

StringMap Couples_Cache_Ranking;

void Couples_OnAskPluginLoad2()
{
    CreateNative("CG_CouplesGetPartnerIndex",    Native_Couples_GetPartnerIndex);
    CreateNative("CG_CouplesGetPartnerPlayerId", Native_Couples_GetPartnerPlayerId);
    CreateNative("CG_CouplesGetWeddingDate",     Native_Couples_GetWeddingDate);
    CreateNative("CG_CouplesGetPartnerName",     Native_Couples_GetPartnerName);
    CreateNative("CG_CouplesEarnExp",            Native_Couples_EarnExp);
    CreateNative("CG_CouplesLoseExp",            Native_Couples_LoseExp);
    CreateNative("CG_CouplesGetExp",             Native_Couples_GetExp);
    CreateNative("CG_CouplesSetExp",             Native_Couples_SetExp);
    CreateNative("CG_CouplesGetLevel",           Native_Couples_GetLevel);
    CreateNative("CG_CouplesGetTogether",        Native_Couples_GetTogetherTime);
}

public int Native_Couples_GetPartnerIndex(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iPartnerIndex];
}

public int Native_Couples_GetPartnerPlayerId(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iPartnerPlayerId];
}

public int Native_Couples_GetWeddingDate(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iWeddingDate];
}

public int Native_Couples_GetPartnerName(Handle plugin, int numParams)
{
    if(SetNativeString(2, Couples_Client_Data[GetNativeCell(1)][szPartnerName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player partner name.");
}

public int Native_Couples_GetExp(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iCPExp];
}

public int Native_Couples_GetLevel(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iCPLvl];
}

public int Native_Couples_GetTogetherTime(Handle plugin, int numParams)
{
    return Couples_Client_Data[GetNativeCell(1)][iTogether];
}

public int Native_Couples_SetExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    Couples_Client_Data[client][iCPEarnExp] = exps - Couples_Client_Data[client][iCPExp];
    Couples_Client_Data[client][iCPExp] = exps;
    
    return true;
}

public int Native_Couples_EarnExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    Couples_Client_Data[client][iCPEarnExp] += exps;
    Couples_Client_Data[client][iCPExp] += exps;

    return true;
}

public int Native_Couples_LoseExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    Couples_Client_Data[client][iCPEarnExp] -= exps;
    Couples_Client_Data[client][iCPExp] -= exps;

    return true;
}

void Couples_OnPluginStart()
{
    Couples_Forward_OnWedding = CreateGlobalForward("CG_OnCouplesWedding", ET_Ignore, Param_Cell, Param_Cell);
    Couples_Forward_OnDivorce = CreateGlobalForward("CG_OnCouplesDivorce", ET_Ignore, Param_Cell);
    
    RegConsoleCmd("sm_cp",      Command_Couples);
    RegConsoleCmd("sm_couples", Command_Couples);
    RegConsoleCmd("sm_propose", Command_Propose);

    Couples_Cache_Ranking = new StringMap();
    
    Couples_CreateAboutMenu();
}

public Action Command_Couples(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    Couples_DisplayMainMenu(client);

    return Plugin_Handled;
}

public Action Command_Propose(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    Couples_DisplayProposeMenu(client);

    return Plugin_Handled;
}

void Couples_OnClientConnected(int client)
{
    Couples_Client_Data[client][iPartnerIndex]    =  -2;
    Couples_Client_Data[client][iPartnerPlayerId] =   0;
    Couples_Client_Data[client][iWeddingDate]     =   0;
    Couples_Client_Data[client][iCPExp]           =   0;
    Couples_Client_Data[client][iCPLvl]           =   0;
    Couples_Client_Data[client][iCPEarnExp]       =   0;
    Couples_Client_Data[client][iTogether]        =   0;
    Couples_Client_Data[client][iTogetherPlay]    =   0;
    Couples_Client_Data[client][szPartnerName][0] ='\0';
}

void Couples_OnClientDisconnect(int client)
{
    if(Couples_Client_Data[client][iPartnerPlayerId] > -1 && (Couples_Client_Data[client][iTogetherPlay] > 0 || Couples_Client_Data[client][iCPEarnExp] > 0))
    {
        char m_szQuery[256];
        FormatEx(m_szQuery, 256, "UPDATE playertrack_couples SET exp=exp+%d, together=together+%d WHERE source_id = %d OR target_id = %d", Couples_Client_Data[client][iCPEarnExp], Couples_Client_Data[client][iTogetherPlay], g_ClientGlobal[client][iPId], g_ClientGlobal[client][iPId]);
        UTIL_SQLTVoid(g_dbGames, m_szQuery);
    }
    
    Couples_Data_Client_ProposeTargetUserId[client] = 0;
    Couples_Data_Client_ProposeSelectedTime[client] = 0;

    int target = Couples_Client_Data[client][iPartnerIndex];

    if(target < 1)
        return;

    Couples_Client_Data[target][iPartnerIndex] = -1;
}

void Couples_InitializeCouplesData(int client, int CP_PlayerId, int CP_WeddingDate, int CP_Exp, int CP_Together, const char[] CP_PartnerName)
{
    if(!Couples_Enabled)
        return;
    
    Couples_Client_Data[client][iWeddingDate]     = CP_WeddingDate;
    Couples_Client_Data[client][iPartnerPlayerId] = CP_PlayerId;
    Couples_Client_Data[client][iCPExp]           = CP_Exp;
    Couples_Client_Data[client][iTogether]        = CP_Together;

    if(CP_PlayerId < 1)
    {
        Couples_Client_Data[client][iPartnerIndex] = -2;
        Couples_Client_Data[client][iPartnerPlayerId] = 0;
        strcopy(Couples_Client_Data[client][szPartnerName], 32, "单身狗");
        return;
    }

    Couples_Client_Data[client][iCPLvl] = UTIL_CalculatLevelByExp(CP_Exp);

    strcopy(Couples_Client_Data[client][szPartnerName], 32, CP_PartnerName);

    int m_iPartner = FindClientByPlayerId(CP_PlayerId);

    Couples_Client_Data[client][iPartnerIndex] = m_iPartner;

    if(IsValidClient(m_iPartner))
    {
        Couples_Client_Data[m_iPartner][iPartnerIndex] = client;
        PrintToChat(m_iPartner, "[\x0CCG\x01]   \x0E你的CP已经登陆游戏...");
        PrintToChat(client, "[\x0CCG\x01]   \x0E你的CP当前在线哦...");
    }
}

void Couples_DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_CouplesMainMenu);

    SetMenuExitButton(menu, true);
    SetMenuExitBackButton(menu, true);

    char date[64];
    FormatTime(date, 64, "%Y.%m.%d", Couples_Client_Data[client][iWeddingDate]);
    
    if(Couples_Enabled)
    {
        if(Couples_Client_Data[client][iPartnerPlayerId])
            SetMenuTitleEx(menu, "[CP]  主菜单 \n \n对象: %s\n日期: %s\n持久: %d天\n等级: Lv.%d(%dXP)\n共枕: %dh%dm", Couples_Client_Data[client][szPartnerName], date, (GetTime()-Couples_Client_Data[client][iWeddingDate])/86400, Couples_Client_Data[client][iCPLvl], Couples_Client_Data[client][iCPExp]+Couples_Client_Data[client][iCPEarnExp], (Couples_Client_Data[client][iTogether]+Couples_Client_Data[client][iTogetherPlay])/3600, ((Couples_Client_Data[client][iTogether]+Couples_Client_Data[client][iTogetherPlay])%3600)/60);
        else
            SetMenuTitleEx(menu, "[CP]  主菜单 \n \n对象: %s", Couples_Client_Data[client][szPartnerName]);

        AddMenuItemEx(menu, Couples_Client_Data[client][iPartnerPlayerId] == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "receive", "求婚列表");
        AddMenuItemEx(menu, Couples_Client_Data[client][iPartnerPlayerId] == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "propose", "发起求婚");
        AddMenuItemEx(menu, Couples_Client_Data[client][iPartnerPlayerId] != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "divorce", "发起离婚");
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "ranking", "登记列表");
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "aboutcp", "功能介绍");
    }
    else
    {
        SetMenuTitleEx(menu, "[CP]  主菜单 \n \n对象: 单身狗");
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "CP系统已经下线.");
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "也许永远都不会在恢复了.");
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "愿你安好.");
    }

    DisplayMenu(menu, client, 20);
}

public int MenuHandler_CouplesMainMenu(Menu menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(itemNum, info, 32);
            if(StrEqual(info, "receive"))       Couples_DisplayProposeMenu(client);
            else if(StrEqual(info, "propose"))  Couples_DisplaySeleteMenu(client);
            else if(StrEqual(info, "divorce"))  Couples_DisplayDivorceMenu(client);
            else if(StrEqual(info, "ranking"))  DisplayMenu(Couples_Menu_Ranking, client, 0);
            else if(StrEqual(info, "aboutcp"))  Couples_Panel_About.Send(client, MenuHandler_CouplesAboutCPPanel, 15);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Command_Menu(client, 0);
    }
}

void Couples_DisplaySeleteMenu(int client)
{
    int num = Couples_Client_Data[client][iWeddingDate] - GetTime();
    if(num > 0)
    {
        PrintToChat(client, "[\x0CCG\x01]   你还有\x04%d\x01秒才能再次组成CP", num);
        return;
    }

    num = Couples_Data_Client_ProposeSelectedTime[client] > GetTime()+60;
    if(num > 0)
    {
        PrintToChat(client, "[\x0CCG\x01]   请勿频繁发起请求,请等待\x04%d\x01秒后再试", num);
        return;
    }

    Handle menu = CreateMenu(MenuHandler_CouplesSelectMenu)

    char m_szId[8];
    for(int target = 1; target <= MaxClients; ++target)
    {
        // Current in game              self?               not loading?                    forum member?                       has partner?
        if(!IsClientInGame(target) || target == client || !g_ClientGlobal[target][bLoaded] || g_ClientGlobal[target][iUId] <= 0 || Couples_Client_Data[target][iPartnerPlayerId] != 0)
            continue;

        FormatEx(m_szId, 8, "%d", GetClientUserId(target));
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szId, "%N", target);
    }

    if(GetMenuItemCount(menu) < 1)
    {
        PrintToChat(client, "[\x0CCG\x01]   当前服务器内没有玩家能跟你组CP...");
        CloseHandle(menu);
        Couples_DisplayMainMenu(client);
        return;
    }

    SetMenuTitleEx(menu, "[CP]  选择CP对象");
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_CouplesSelectMenu(Menu menu, MenuAction action, int source, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(itemNum, info, 32);
            
            int userid = StringToInt(info);
            int target = GetClientOfUserId(userid);

            if(!IsValidClient(target) || Couples_Client_Data[target][iPartnerPlayerId] != 0)
            {
                PrintToChat(source, "[\x0CCG\x01]   你选择的对象目前不可用#03");
                Couples_DisplayMainMenu(source);
                return;
            }

            Couples_Data_Client_ProposeTargetUserId[source] = userid;
            Couples_Data_Client_ProposeSelectedTime[source] = GetTime();
            Couples_DisplayProposeMenu(target);

            PrintToChat(source, "[\x0CCG\x01]   已将你的CP请求发送至\x0E%N", target);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Couples_DisplayMainMenu(source);
    }
}

void Couples_DisplayProposeMenu(int target)
{
    Handle menu = CreateMenu(MenuHandler_CouplesProposeMenu);
    
    int userid = GetClientUserId(target);
    
    char m_szId[8];
    for(int source = 1; source <= MaxClients; ++source)
    {
        // Current in game              self?               not loading?                    forum member?                       has partner?
        if(!IsClientInGame(source) || source == target || !g_ClientGlobal[source][bLoaded] || g_ClientGlobal[source][iUId] <= 0 || Couples_Client_Data[source][iPartnerPlayerId] != 0 || Couples_Data_Client_ProposeTargetUserId[source] != userid)
            continue;

        FormatEx(m_szId, 8, "%d", GetClientUserId(source));
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szId, "%N", source);
    }

    if(GetMenuItemCount(menu) < 1)
    {
        PrintToChat(target, "[\x0CCG\x01]   别自恋了,没人跟你求婚...");
        CloseHandle(menu);
        Couples_DisplayMainMenu(target);
        return;
    }

    SetMenuTitleEx(menu, "[CP]  求婚列表");
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, target, 0);
}

public int MenuHandler_CouplesProposeMenu(Menu menu, MenuAction action, int target, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(itemNum, info, 32);
            
            int userid = StringToInt(info);
            int source = GetClientOfUserId(userid);

            if(!IsValidClient(source) || Couples_Client_Data[source][iPartnerPlayerId] != 0)
            {
                PrintToChat(target, "[\x0CCG\x01]   你选择的对象目前不可用#01");
                Couples_DisplayMainMenu(target);
                return;
            }

            Couples_Data_Client_ProposeSelectUserId[target] = userid;
            Couples_DisplayConfrimMenu(target, source);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Couples_DisplayProposeMenu(target);
    }
}

void Couples_DisplayConfrimMenu(int target, int source)
{
    Handle menu = CreateMenu(MenuHandler_CouplesConfirmMenu);
    SetMenuTitleEx(menu, "[CP]  结婚登记");

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你收到了一个来自 %N 的CP邀请", source);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "组成CP后14天内不能申请解除");
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "组成CP后可以享受多种福利");
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你确定要接受这个邀请吗");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "accept", "接受请求");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "refuse", "拒绝请求");

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, target, 0);
}

public int MenuHandler_CouplesConfirmMenu(Menu menu, MenuAction action, int target, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        menu.GetItem(itemNum, info, 32);
        
        int source = GetClientOfUserId(Couples_Data_Client_ProposeSelectUserId[target]);
        
        Couples_Data_Client_ProposeSelectUserId[source] = 0;
        Couples_Data_Client_ProposeSelectUserId[target] = 0;
        Couples_Data_Client_ProposeTargetUserId[source] = 0;
        Couples_Data_Client_ProposeTargetUserId[target] = 0;

        //accept?
        if(StrEqual(info, "accept"))
        {
            if(!IsValidClient(source) || Couples_Client_Data[source][iPartnerPlayerId] > 0)
            {
                PrintToChat(target, "[\x0CCG\x01]   你选择的对象目前不可用#02->%d.%d", source, Couples_Client_Data[source][iPartnerPlayerId]);
                Couples_DisplaySeleteMenu(target);
                return;
            }

            Couples_GetMarried(source, target);
        }
        //refuse?
        else
        {
            if(!IsValidClient(source))
                return;

            PrintToChat(target, "[\x0CCG\x01]   你拒绝了\x0E%N\x01的CP邀请", source);
            PrintToChat(source, "[\x0CCG\x01]   \x0E%N\x01拒绝了你的CP邀请", target);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void Couples_GetMarried(int source, int target)
{
    //her -> target
    //if(g_ClientGlobal[target][iPId] == 167606 && g_ClientGlobal[source][iPId] != 1)
    //{
    //    char cmd_callbacl[128];
    //    ServerCommandEx(cmd_callbacl, 128 , "sm_ban #%d 0 \"CAT: 你想干嘛?\"", GetClientUserId(source));
    //    UTIL_LogError("Couples_GetMarried", "Auto ban %s permanent: %s", g_ClientGlobal[source][szGamesName], cmd_callbacl);
    //    return;
    //}

    //her -> source
    //if(g_ClientGlobal[source][iPId] == 167606 && g_ClientGlobal[target][iPId] != 1)
    //{
    //    PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#33");
    //    PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#33");
    //    Couples_DisplayMainMenu(source);
    //    return;
    //}

    DataPack m_hPack = new DataPack();
    m_hPack.WriteCell(GetClientUserId(source));
    m_hPack.WriteCell(GetClientUserId(target));
    m_hPack.WriteCell(g_ClientGlobal[source][iPId]);
    m_hPack.WriteCell(g_ClientGlobal[target][iPId]);
    m_hPack.Reset();

    //SQL CALL
    char m_szQuery[128];
    Format(m_szQuery, 128, "INSERT INTO playertrack_couples VALUES (default, %d, %d, %d, 0, 0);", g_ClientGlobal[source][iPId], g_ClientGlobal[target][iPId], GetTime());
    UTIL_TQuery(g_dbGames, Couples_SQLCallback_UpdateCP, m_szQuery, m_hPack);
}

public void Couples_SQLCallback_UpdateCP(Handle owner, Handle hndl, const char[] error, DataPack pack)
{
    int source = GetClientOfUserId(pack.ReadCell());
    int target = GetClientOfUserId(pack.ReadCell());
    int srcpid = pack.ReadCell();
    int tgrpid = pack.ReadCell();
    CloseHandle(pack);

    bool SourceValid = IsValidClient(source);
    bool TargetValid = IsValidClient(target);

    if(hndl == INVALID_HANDLE)
    {
        if(TargetValid)
            PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#02");

        if(SourceValid)
            PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#02");

        UTIL_LogError("Couples_SQLCallback_UpdateCP", "UpdateCP->hndl [%d] <-> [%d] error: %s", srcpid, tgrpid, error);

        return;
    }

    if(!SQL_GetAffectedRows(hndl))
    {
        if(TargetValid)
            PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#03");

        if(SourceValid)
            PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#03");

        UTIL_LogError("Couples_SQLCallback_UpdateCP", "UpdateCP->Affected [%d] <-> [%d]", srcpid, tgrpid);

        return;
    }

    if(SourceValid && TargetValid)
    {
        Couples_Client_Data[source][iPartnerIndex] = target;
        Couples_Client_Data[source][iPartnerPlayerId] = g_ClientGlobal[target][iPId];
        Couples_Client_Data[source][iWeddingDate] = GetTime();
        Couples_Client_Data[target][iPartnerIndex] = source;
        Couples_Client_Data[target][iPartnerPlayerId] = g_ClientGlobal[source][iPId];
        Couples_Client_Data[target][iWeddingDate] = GetTime();
        FormatEx(Couples_Client_Data[source][szPartnerName], 32, "%N", target);
        FormatEx(Couples_Client_Data[target][szPartnerName], 32, "%N", source);

        Call_StartForward(Couples_Forward_OnWedding);
        Call_PushCell(source);
        Call_PushCell(target);
        Call_Finish();

        PrintToChatAll("[\x0CCG\x01]   \x10恭喜\x0E%N\x10和\x0E%N\x10结成CP.", source, target);
        Couples_DisplayMainMenu(source);
        Couples_DisplayMainMenu(target);
    }
    else if(SourceValid && !TargetValid)
    {
        Couples_Client_Data[source][iPartnerIndex] = -1;
        Couples_Client_Data[source][iPartnerPlayerId] = tgrpid;
        Couples_Client_Data[source][iWeddingDate] = GetTime();
        strcopy(Couples_Client_Data[source][szPartnerName], 32, "未知");

        PrintToChat(source, "系统已保存你们的数据,但是你CP当前离线,你不能享受新婚祝福");
        Couples_DisplayMainMenu(source);
    }
    else if(!SourceValid && TargetValid)
    {
        Couples_Client_Data[target][iPartnerIndex] = -1;
        Couples_Client_Data[target][iPartnerPlayerId] = srcpid;
        Couples_Client_Data[target][iWeddingDate] = GetTime();
        strcopy(Couples_Client_Data[target][szPartnerName], 32, "未知");

        PrintToChat(target, "[\x0CCG\x01]   系统已保存你们的数据,但是你CP当前离线,你不能享受新婚祝福");
        Couples_DisplayMainMenu(target);
    }
}

void Couples_DisplayDivorceMenu(int client)
{
    if((GetTime() - Couples_Client_Data[client][iWeddingDate]) < 1209600)
    {
        PrintToChat(client, "[\x0CCG\x01]   新组成CP之后14天内不能申请解除...");
        Couples_DisplayMainMenu(client);
        return;
    }

    Handle menu = CreateMenu(MenuHandler_CouplesDivorceMenu);
    SetMenuTitleEx(menu, "[CP]  离婚登记台");

    char date[64];
    FormatTime(date, 64, "%Y.%m.%d %H:%M:%S", Couples_Client_Data[client][iWeddingDate]);

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你当前配偶 %s", Couples_Client_Data[client][szPartnerName]);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你们结合于 %s", date);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你们已结合 %d 天", (GetTime()-Couples_Client_Data[client][iWeddingDate])/86400);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "离婚手续费 %d 信用点\n公式: (180-天数)*500\n ", (180-((GetTime()-Couples_Client_Data[client][iWeddingDate])/86400))*500);

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "accept", "我已经不爱TA了");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "refuse", "我还是很爱TA的");

    SetMenuExitBackButton(menu, false);
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_CouplesDivorceMenu(Menu menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[128];
            menu.GetItem(itemNum, info, 128);
            
            if(StrEqual(info, "refuse", false))
            {
                Couples_DisplayMainMenu(client);
                return;
            }
            
            int credits = (180-((GetTime()-Couples_Client_Data[client][iWeddingDate])/86400))*500*-1;

            if(credits > 0)
            {
                PrintToChat(client, "[\x0CCG\x01]   发生未知错误");
                Couples_DisplayMainMenu(client);
                return;
            }

            if(!GlobalApi_Forward_OnAPIStoreSetCredits(client, credits, "离婚手续费", true))
            {
                PrintToChat(client, "[\x0CCG\x01]   \x07你的信用点不足以办理离婚手续");
                return;
            }

            char m_szQuery[256];
            Format(m_szQuery, 256, "DELETE FROM playertrack_couples WHERE source_id = %d or target_id = %d", g_ClientGlobal[client][iPId], g_ClientGlobal[client][iPId]);
            UTIL_TQuery(g_dbGames, SQLCallback_UpdateDivorce, m_szQuery, GetClientUserId(client));
        }
        case MenuAction_End: CloseHandle(menu);
    }
}

public void SQLCallback_UpdateDivorce(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        PrintToChat(client, "[\x0CCG\x01]   系统错误 \x02CP#06");
        UTIL_LogError("SQLCallback_UpdateDivorce", "UpdateDivorce %L error: %s", client, error);
        return;
    }

    PrintToChatAll("[\x0CCG\x01]   \x10%N\x05解除了和\x10%s\x05的CP,他们的关系维持了\x02%d\x05天", client, Couples_Client_Data[client][szPartnerName], (GetTime()-Couples_Client_Data[client][iWeddingDate])/86400);

    Call_StartForward(Couples_Forward_OnDivorce);
    Call_PushCell(client);
    Call_Finish();

    int target = Couples_Client_Data[client][iPartnerIndex];
    if(target > 0)
    {
        Couples_OnClientConnected(target);
        Couples_Client_Data[target][iWeddingDate] = GetTime()+1209600;
    }

    Couples_OnClientConnected(client);
    Couples_Client_Data[client][iWeddingDate] = GetTime()+1209600;
    Couples_DisplayMainMenu(client);
}

void Couples_CreateAboutMenu()
{
    Couples_Panel_About = new Panel();

    Couples_Panel_About.DrawText("[CP]  系统说明");
    Couples_Panel_About.DrawText(" ");
    Couples_Panel_About.DrawText("组成CP需要两厢情愿,无法单方面组CP");
    Couples_Panel_About.DrawText("发起请求之后需要对方确认才能配对");
    Couples_Panel_About.DrawText("组成CP后14天内不能解除");
    Couples_Panel_About.DrawText("解除CP后14天内不能再组");
    Couples_Panel_About.DrawText("CP能为你提供一定的加成(道具商店,天赋等)");
    Couples_Panel_About.DrawText("按Y输入[/内容]可以发送CP频道");
    Couples_Panel_About.DrawText("还有更多的功能正在开发中...");
    Couples_Panel_About.DrawText("希望你和你的另1半在服务器里玩得开心");
    Couples_Panel_About.DrawText(" ");
    Couples_Panel_About.DrawText(" ");

    Couples_Panel_About.DrawItem("返回");
}

public int MenuHandler_CouplesAboutCPPanel(Menu menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
        Couples_DisplayMainMenu(client);
}

int FindClientByPlayerId(int playerid)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && g_ClientGlobal[client][bLoaded])
            if(g_ClientGlobal[client][iPId] == playerid)
                return client;

    return -1;
}

Action Couples_OnClientSay(int client, const char[] message)
{
    if(message[0] != '/')
        return Plugin_Continue;

    int target = Couples_Client_Data[client][iPartnerIndex];
    if(target == -2)
    {
        PrintToChat(client, "[\x0ECP频道\x01]  \x07你没有CP,发什么发");
        return Plugin_Stop;
    }
    else if(target == -1)
    {
        PrintToChat(client, "[\x0ECP频道\x01]  \x05你的CP \x0E%s \x05当前已经离线", Couples_Client_Data[client][szPartnerName]);
        return Plugin_Stop;
    }
    else if(!IsValidClient(target))
        return Plugin_Stop;
    
    ClientCommand(client, "play buttons/bell1.wav");
    ClientCommand(target, "play buttons/bell1.wav");

    PrintToChat(target, "[\x0ECP频道\x01]  \x0E%N\x01 :  \x10%s", client, message[1]);
    PrintToChat(client, "[\x0ECP频道\x01]  \x0E%N\x01 :  \x10%s", client, message[1]);

    return Plugin_Stop;
}

public int MenuHandler_CouplesRanking(Menu menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[16];
        menu.GetItem(itemNum, info, 16);
        
        Couples_DisplayCPsDetails(client, StringToInt(info));
    }
    else if(action == MenuAction_Cancel)
        if(itemNum == MenuCancel_ExitBack)
            Couples_DisplayMainMenu(client);
}

void Couples_DisplayCPsDetails(int client, int index)
{
    int data[Couples_Ranking];
    char key[16];
    IntToString(index, key, 16);
    Couples_Cache_Ranking.GetArray(key, data[0], view_as<int>(Couples_Ranking), _);

    char date[64];
    FormatTime(date, 64, "%Y.%m.%d", data[iWeddingDay]);

    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ Couples Details ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "%s", data[szSource_Name]);
    DrawPanelTextEx(panel, "♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥♥");
    DrawPanelTextEx(panel, "%s", data[szTarget_Name]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "日期:  %s", date);
    DrawPanelTextEx(panel, "天数:  %d", (GetTime()-data[iWeddingDay])/86400);
    DrawPanelTextEx(panel, "排名:  No.%d", data[iCouplesRank]);
    DrawPanelTextEx(panel, "等级:  Lv.%d", UTIL_CalculatLevelByExp(data[iCouplesExp]));
    DrawPanelTextEx(panel, "共枕:  %dh%dm", data[iCouplesTogether]/3600, (data[iCouplesTogether]%3600)/60);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");

    DrawPanelItem(panel, "返回");
    DrawPanelItem(panel, "退出");
    
    SendPanelToClient(panel, client, Couples_CPsDetailesPanel, 30);
}

public int Couples_CPsDetailesPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        if(itemNum==1)
            DisplayMenu(Couples_Menu_Ranking, client, 0);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void Couples_RefreshRank()
{
    UTIL_TQuery(g_dbGames, Couples_SQLCallback_BuildCPRank, "SELECT a.id,a.date,a.exp,a.together,b.id,b.name,c.id,c.name FROM playertrack_couples a LEFT JOIN playertrack_player b ON a.source_id = b.id LEFT JOIN playertrack_player c ON a.target_id = c.id ORDER BY a.exp DESC", _, DBPrio_Low);
}

public void Couples_SQLCallback_BuildCPRank(Handle owner, Handle hndl, const char[] error, any unuse)
{
    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("Couples_SQLCallback_BuildCPRank", "Load Couples List failed. Error happened: %s", error);
        return;
    }
    
    Couples_Cache_Ranking.Clear();
    
    if(Couples_Menu_Ranking != INVALID_HANDLE)
        CloseHandle(Couples_Menu_Ranking);
    
    Couples_Menu_Ranking = CreateMenu(MenuHandler_CouplesRanking);

    char key[16];
    int index, rank = 1;
    int data[Couples_Ranking];

    while(SQL_FetchRow(hndl))
    {
        index                   = SQL_FetchInt(hndl, 0);
        data[iWeddingDay]       = SQL_FetchInt(hndl, 1);
        data[iCouplesExp]       = SQL_FetchInt(hndl, 2);
        data[iCouplesTogether]  = SQL_FetchInt(hndl, 3);
        data[iSource_PId]       = SQL_FetchInt(hndl, 4);
        data[iTarget_Pid]       = SQL_FetchInt(hndl, 6);

        SQL_FetchString(hndl, 5, data[szSource_Name], 32);
        SQL_FetchString(hndl, 7, data[szTarget_Name], 32);
        
        data[iCouplesRank] = rank;

        IntToString(index, key, 16);
        
        Couples_Cache_Ranking.SetArray(key, data[0], view_as<int>(Couples_Ranking));
        
        AddMenuItemEx(Couples_Menu_Ranking, ITEMDRAW_DEFAULT, key, "[%s] ♥ [%s]", data[szSource_Name], data[szTarget_Name]);

        rank++;
    }

    SetMenuTitleEx(Couples_Menu_Ranking, "[CP]  登记列表 (%d对)", GetTrieSize(Couples_Cache_Ranking));
    SetMenuExitButton(Couples_Menu_Ranking, true);
    SetMenuExitBackButton(Couples_Menu_Ranking, true);
}

void Couples_OnGlobalTimer(int client)
{
    if(!IsValidClient(Couples_Client_Data[client][iPartnerIndex]))
        return;
    
    Couples_Client_Data[client][iTogether]++;
    Couples_Client_Data[client][iTogetherPlay]++;
}
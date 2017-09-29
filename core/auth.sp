enum AuthGroup
{
    iTmp,
    iExp,
    iLvl,
    iDate,
    iExpired,
    iEarnExp,
}
int AuthGroup_Client_Data[MAXPLAYERS+1][AuthGroup];

Handle AuthGroup_Forward_AuthTerm;
Menu AuthGroup_Menu_Handle;

void AuthGroup_OnAskPluginLoad2()
{
    CreateNative("CG_AuthGroupEarnExp",    Native_AuthGroup_EarnExp);
    CreateNative("CG_AuthGroupLoseExp",    Native_AuthGroup_LoseExp);
    CreateNative("CG_AuthGroupGetExp",     Native_AuthGroup_GetExp);
    CreateNative("CG_AuthGroupSetExp",     Native_AuthGroup_SetExp);
    CreateNative("CG_AuthGroupGetLevel",   Native_AuthGroup_GetLevel);
    CreateNative("CG_AuthGroupGetExpired", Native_AuthGroup_GetExpiredTime);
}

public int Native_AuthGroup_GetExp(Handle plugin, int numParams)
{
    return AuthGroup_Client_Data[GetNativeCell(1)][iExp];
}

public int Native_AuthGroup_GetLevel(Handle plugin, int numParams)
{
    return AuthGroup_Client_Data[GetNativeCell(1)][iLvl];
}

public int Native_AuthGroup_GetExpiredTime(Handle plugin, int numParams)
{
    return AuthGroup_Client_Data[GetNativeCell(1)][iExpired];
}

public int Native_AuthGroup_SetExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    AuthGroup_Client_Data[client][iEarnExp] = exps - AuthGroup_Client_Data[client][iExp];
    AuthGroup_Client_Data[client][iExp] = exps;
    
    return true;
}

public int Native_AuthGroup_EarnExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    AuthGroup_Client_Data[client][iEarnExp] += exps;
    AuthGroup_Client_Data[client][iExp] += exps;

    return true;
}

public int Native_AuthGroup_LoseExp(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    
    if(!g_ClientGlobal[client][bLoaded])
        return false;
    
    if(!g_ClientGlobal[client][iGId])
        return false;
    
    int exps = GetNativeCell(2);
    AuthGroup_Client_Data[client][iEarnExp] -= exps;
    AuthGroup_Client_Data[client][iExp] -= exps;

    return true;
}

void AuthGroup_OnPluginStart()
{
    AuthGroup_Forward_AuthTerm = CreateGlobalForward("CG_OnCheckAuthTerm", ET_Event, Param_Cell, Param_Cell);
    
    InitAuthMenu();

    RegConsoleCmd("sm_rz",   Command_GetAuth);
    RegConsoleCmd("sm_auth", Command_GetAuth);
}

void InitAuthMenu()
{
    AuthGroup_Menu_Handle = new Menu(MenuHandler_GetAuth);
    
    AuthGroup_Menu_Handle.SetTitle("[CG]  认证菜单\n ");

    AuthGroup_Menu_Handle.AddItem(   "1", "[僵尸逃跑] 断后达人");
    AuthGroup_Menu_Handle.AddItem(   "2", "[僵尸逃跑] 指挥大佬");
    AuthGroup_Menu_Handle.AddItem(   "3", "[僵尸逃跑] 僵尸克星");
    AuthGroup_Menu_Handle.AddItem(   "4", "[僵尸逃跑] 丢雷楼谋");
    AuthGroup_Menu_Handle.AddItem(   "5", "[僵尸逃跑] 破点大神");

    AuthGroup_Menu_Handle.AddItem( "101", "[匪镇谍影] 职业侦探");
    AuthGroup_Menu_Handle.AddItem( "102", "[匪镇谍影]   心机婊");
    AuthGroup_Menu_Handle.AddItem( "103", "[匪镇谍影]  TTT影帝");
    AuthGroup_Menu_Handle.AddItem( "104", "[匪镇谍影] 赌命狂魔");
    AuthGroup_Menu_Handle.AddItem( "105", "[匪镇谍影] 杰出公民");

    AuthGroup_Menu_Handle.AddItem( "201", "[娱乐休闲] 娱乐挂壁");

    AuthGroup_Menu_Handle.AddItem( "301", "[混战休闲] 首杀无敌");
    AuthGroup_Menu_Handle.AddItem( "302", "[混战休闲] 混战指挥");
    AuthGroup_Menu_Handle.AddItem( "303", "[混战休闲] 爆头狂魔");
    AuthGroup_Menu_Handle.AddItem( "304", "[混战休闲] 助攻之神");

    AuthGroup_Menu_Handle.AddItem( "501", "[越狱搞基] 暴动狂魔");
    AuthGroup_Menu_Handle.AddItem( "502", "[越狱搞基] 暴乱领袖");
    AuthGroup_Menu_Handle.AddItem( "503", "[越狱搞基] 模范狱长");
    AuthGroup_Menu_Handle.AddItem( "504", "[越狱搞基] 防暴警察");

    AuthGroup_Menu_Handle.AddItem("9901", "[全服认证] CG地图组");
    AuthGroup_Menu_Handle.AddItem("9902", "[全服认证] CG测试组");
    AuthGroup_Menu_Handle.AddItem("9903", "[全服认证] CG技术组");

    SetMenuExitBackButton(AuthGroup_Menu_Handle, true);
    SetMenuExitButton(AuthGroup_Menu_Handle, true);
}

public Action Command_GetAuth(int client, int args)
{
    if(!g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    if(g_ClientGlobal[client][iGId] > 0)
    {
        AuthGroup_DisplayMenu(client);
        return Plugin_Handled;
    }

    AuthGroup_Menu_Handle.Display(client, 0);

    return Plugin_Handled;
}

public int MenuHandler_GetAuth(Menu menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            menu.GetItem(itemNum, info, 32);
            AuthGroup_CheckClientAuthTerm(client, StringToInt(info));
        }
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Command_Menu(client, 0);
    }
}

bool OnCheckAuthTerm(int client, int AuthId) 
{
    bool result = false;

    //Call Forward
    Call_StartForward(AuthGroup_Forward_AuthTerm);
    Call_PushCell(client);
    Call_PushCell(AuthId);
    Call_Finish(result);

    return result;
}

void AuthGroup_CheckClientAuthTerm(int client, int AuthId)
{
    if(1 < AuthId < 100 && !FindPluginByFile("zombiereloaded.smx"))
    {
        PrintToChat(client, "[\x0CCG\x01]   请到[\x0C僵尸逃跑\x01]服务器中申请此认证");
        return;
    }

    if(100 < AuthId < 200 && !FindPluginByFile("ct.smx"))
    {
        PrintToChat(client, "[\x0CCG\x01]   请到[\x0C匪镇谍影\x01]服务器中申请此认证");
        return;
    }

    if(200 < AuthId < 300 && !FindPluginByFile("mg_stats.smx"))
    {
        PrintToChat(client, "[\x0CCG\x01]   请到[\x0C娱乐休闲\x01]服务器中申请此认证");
        return;
    }

    if(300 < AuthId < 400 && !FindPluginByFile("public_ext.smx"))
    {
        PrintToChat(client, "[\x0CCG\x01]   请到[\x0C混战休闲\x01]服务器中申请此认证");
        return;
    }
    
    if(500 < AuthId < 600 && !FindPluginByFile("jb_stats.smx"))
    {
        PrintToChat(client, "[\x0CCG\x01]   请到[\x0C越狱搞基\x01]服务器中申请此认证");
        return;
    }

    if(1000 < AuthId)
    {
        PrintToChat(client, "[\x0CCG\x01]   \x07此认证需要猫灵手动发放...");
        return;
    }

    PrintToChat(client, "\x04正在查询...");

    if(!OnCheckAuthTerm(client, AuthId))
    {
        PrintToChat(client, "[\x0CCG\x01]   \x07很抱歉噢,你没有达到该认证的要求...");
        return;
    }

    if(AuthGroup_Client_Data[client][iTmp] > 0 && AuthGroup_Client_Data[client][iTmp] != AuthId)
    {
        PrintToChat(client, "[\x0CCG\x01]   \x07你的认证过期了,只能重新申请原有的认证");
        return;
    }

    g_ClientGlobal[client][iGId] = AuthId;
    char m_szQuery[256], m_szAuthId[32];
    GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
    AuthGroup_GetClientAuthName(client, g_ClientGlobal[client][szGroupName], 16);
    Format(m_szQuery, 256, "REPLACE INTO `playertrack_authgroup` (`pid`, `index`, `name`, `date`, `expired`) VALUES (%d, %d, '%s', %d, %d);", g_ClientGlobal[client][iPId], AuthId, g_ClientGlobal[client][szGroupName], GetTime(), GetTime()+259200);
    UTIL_TQuery(g_dbGames, AuthGroup_SQLCallback_GiveAuth, m_szQuery, GetClientUserId(client));
    PrintToChat(client, "[\x0CCG\x01]   \x0C正在同步数据库...");
}

public void AuthGroup_SQLCallback_GiveAuth(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client)
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("AuthGroup_SQLCallback_GiveAuth", "UPDATE auth Failed: client:%N ERROR:%s", client, error);
        PrintToChat(client, "[\x0CCG\x01]   系统中闪光弹了,请重试!  错误:\x02 x99");
        g_ClientGlobal[client][iGId] = 0;
        return;
    }

    PrintToChatAll("[\x0CCG\x01]   \x0C%N\x04获得了新的认证", client);
}

void AuthGroup_GetClientAuthName(int client, char[] buffer, int maxLen)
{
    switch(g_ClientGlobal[client][iGId])
    {
        case    0: strcopy(buffer, maxLen, "未认证");
        case    1: strcopy(buffer, maxLen, "断后达人");
        case    2: strcopy(buffer, maxLen, "指挥大佬");
        case    3: strcopy(buffer, maxLen, "僵尸克星");
        case    4: strcopy(buffer, maxLen, "丢雷楼谋");
        case    5: strcopy(buffer, maxLen, "破点大神");
        case  101: strcopy(buffer, maxLen, "职业侦探");
        case  102: strcopy(buffer, maxLen, "心机婊");
        case  103: strcopy(buffer, maxLen, "TTT影帝");
        case  104: strcopy(buffer, maxLen, "赌命狂魔");
        case  105: strcopy(buffer, maxLen, "杰出公民");
        case  201: strcopy(buffer, maxLen, "娱乐挂壁");
        case  301: strcopy(buffer, maxLen, "首杀无敌");
        case  302: strcopy(buffer, maxLen, "混战指挥");
        case  303: strcopy(buffer, maxLen, "爆头狂魔");
        case  304: strcopy(buffer, maxLen, "助攻之神");
        case  501: strcopy(buffer, maxLen, "暴动狂魔");
        case  502: strcopy(buffer, maxLen, "暴乱领袖");
        case  503: strcopy(buffer, maxLen, "模范狱长");
        case  504: strcopy(buffer, maxLen, "防暴警察");
        default  : strcopy(buffer, maxLen, "未知错误");
    }
}

void AuthGroup_OnClientConnected(int client)
{
    AuthGroup_Client_Data[client][iTmp]     = 0;
    AuthGroup_Client_Data[client][iExp]     = 0;
    AuthGroup_Client_Data[client][iLvl]     = 0;
    AuthGroup_Client_Data[client][iDate]    = 0;
    AuthGroup_Client_Data[client][iExpired] = 0;
    AuthGroup_Client_Data[client][iEarnExp] = 0;
}

void AuthGroup_InitializeAuthData(int client, int index, int exp, int date, int expired, const char[] name)
{
    g_ClientGlobal[client][iGId]            = index;
    AuthGroup_Client_Data[client][iExp]     = exp;
    AuthGroup_Client_Data[client][iLvl]     = UTIL_CalculatLevelByExp(exp);
    AuthGroup_Client_Data[client][iDate]    = date;
    AuthGroup_Client_Data[client][iExpired] = expired;
    strcopy(g_ClientGlobal[client][szGroupName], 16, name);

    if(expired != 0 && expired < GetTime())
    {
        AuthGroup_Client_Data[client][iTmp] = index;
        g_ClientGlobal[client][iGId]        = 0;
        strcopy(g_ClientGlobal[client][szGroupName], 16, "未认证");
    }
}

void AuthGroup_DisplayMenu(int client)
{
    Handle panel = CreatePanel();
    
    char date[2][64];
    FormatTime(date[0], 64, "%Y.%m.%d", AuthGroup_Client_Data[client][iDate]);
    if(AuthGroup_Client_Data[client][iEarnExp] == 0)
        FormatEx(date[1], 64, "*永久*");
    else
        FormatTime(date[1], 64, "%Y.%m.%d", AuthGroup_Client_Data[client][iEarnExp]);

    DrawPanelTextEx(panel, "▽ Authorized Details ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "认证:  %s", g_ClientGlobal[client][szGroupName]);
    DrawPanelTextEx(panel, "日期:  %s", date[0]);
    DrawPanelTextEx(panel, "到期:  %s", date[1]);
    DrawPanelTextEx(panel, "等级:  Lv.%d", AuthGroup_Client_Data[client][iLvl]);
    DrawPanelTextEx(panel, "经验:  %dXP", AuthGroup_Client_Data[client][iExp]+AuthGroup_Client_Data[client][iEarnExp]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");

    DrawPanelItem(panel, "返回");
    DrawPanelItem(panel, "退出");
    
    SendPanelToClient(panel, client, AuthGroup_AuthDetailesPanel, 30);
}

public int AuthGroup_AuthDetailesPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        if(itemNum==1)
            Command_Menu(client, 0);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void AuthGroup_OnClientDisconnect(int client)
{
    if(g_ClientGlobal[client][iGId] > 0 && AuthGroup_Client_Data[client][iEarnExp] > 0)
    {
        char m_szQuery[256];
        FormatEx(m_szQuery, 256, "UPDATE playertrack_authgroup SET exp=exp+%d WHERE pid = %d", AuthGroup_Client_Data[client][iEarnExp], g_ClientGlobal[client][iPId]);
        UTIL_SQLTVoid(g_dbGames, m_szQuery);
    }
}
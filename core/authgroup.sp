Handle AuthGroup_Forward_AuthTerm;

void AuthGroup_OnPluginStart()
{
    AuthGroup_Forward_AuthTerm = CreateGlobalForward("CG_OnCheckAuthTerm", ET_Event, Param_Cell, Param_Cell);

    RegConsoleCmd("sm_rz",   Command_GetAuth);
    RegConsoleCmd("sm_auth", Command_GetAuth);
}

public Action Command_GetAuth(int client, int args)
{
    if(!g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    if(g_ClientGlobal[client][iGId] > 0)
    {
        PrintToChat(client, "\x04你已经有认证了");
        return Plugin_Handled;
    }

    //创建CG玩家主菜单
    Handle menu = CreateMenu(MenuHandler_GetAuth);
    SetMenuTitleEx(menu, "[CG]  认证菜单");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "1", "[僵尸逃跑] 断后达人");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "2", "[僵尸逃跑] 指挥大佬");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "3", "[僵尸逃跑] 僵尸克星");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "4", "[僵尸逃跑] 丢雷楼谋");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,    "5", "[僵尸逃跑] 破点大神");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "101", "[匪镇谍影] 职业侦探");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "102", "[匪镇谍影]   心机婊");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "103", "[匪镇谍影]  TTT影帝");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "104", "[匪镇谍影] 赌命狂魔");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "105", "[匪镇谍影] 杰出公民");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "201", "[娱乐休闲] 娱乐挂壁");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "301", "[混战休闲] 首杀无敌");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "302", "[混战休闲] 混战指挥");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "303", "[混战休闲] 爆头狂魔");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "304", "[混战休闲] 助攻之神");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "501", "[越狱搞基] 暴动狂魔");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "502", "[越狱搞基] 暴乱领袖");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "503", "[越狱搞基] 模范狱长");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "504", "[越狱搞基] 防暴警察");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT,  "505", "[越狱搞基] 单挑达人");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9901", "[全服认证] CG地图组");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9902", "[全服认证] CG测试组");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "9903", "[全服认证] CG技术组");

    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);

    return Plugin_Handled;
}

public int MenuHandler_GetAuth(Handle menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, itemNum, info, 32);
            AuthGroup_CheckClientAuthTerm(client, StringToInt(info));
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Command_Menu(client, 0);
    }
}

bool OnCheckAuthTerm(int client, int AuthId) 
{
    bool result;

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
        PrintToChat(client, "请到[\x0C僵尸逃跑\x01]服务器中申请此认证");
        return;
    }

    if(100 < AuthId < 200 && !FindPluginByFile("ct.smx"))
    {
        PrintToChat(client, "请到[\x0C匪镇谍影\x01]服务器中申请此认证");
        return;
    }

    if(200 < AuthId < 300 && !FindPluginByFile("mg_stats.smx"))
    {
        PrintToChat(client, "请到[\x0C娱乐休闲\x01]服务器中申请此认证");
        return;
    }

    if(300 < AuthId < 400 && !FindPluginByFile("public_ext.smx"))
    {
        PrintToChat(client, "请到[\x0C混战休闲\x01]服务器中申请此认证");
        return;
    }
    
    if(500 < AuthId < 600)
    {
        PrintToChat(client, "[\x0C越狱搞基\x01]服务器认证当前正在建设中...");
        return;
    }

    if(1000 < AuthId)
    {
        PrintToChat(client, "\x07此认证需要猫灵手动发放...");
        return;
    }

    PrintToChat(client, "\x04正在查询...");

    if(!OnCheckAuthTerm(client, AuthId))
    {
        PrintToChat(client, "\x07很抱歉噢,你没有达到该认证的要求...");
        return;
    }

    g_ClientGlobal[client][iGId] = AuthId;
    char m_szQuery[256], m_szAuthId[32];
    GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
    AuthGroup_GetClientAuthName(client, g_ClientGlobal[client][szGroupName], 16);
    Format(m_szQuery, 256, "UPDATE `playertrack_player` SET `groupid` = '%d', `groupname` = '%s' WHERE `id` = '%d' and `steamid` = '%s';", AuthId, g_ClientGlobal[client][szGroupName], g_ClientGlobal[client][iPId], m_szAuthId);
    MySQL_Query(false, AuthGroup_SQLCallback_GiveAuth, m_szQuery, GetClientUserId(client));
    PrintToChat(client, "\x0C正在同步数据库...");
}

public void AuthGroup_SQLCallback_GiveAuth(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        UTIL_LogError("AuthGroup_SQLCallback_GiveAuth", "UPDATE auth Failed: client:%N ERROR:%s", client, error);
        PrintToChat(client, "系统中闪光弹了,请重试!  错误:\x02 x99");
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
    }
}
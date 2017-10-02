#include <huodong>
#include <store>
#include <kylestock>

#define PREFIX "[\x0ECG②周年\x01]  "

#define PLAYER_NRL 0
#define PLAYER_OLD 1
#define PLAYER_NEW 2

Handle g_hDatabase;
int g_iTeam[MAXPLAYERS+1];
int g_iType[MAXPLAYERS+1];
int g_iKeepDay[MAXPLAYERS+1];
int g_iSignDay[MAXPLAYERS+1];
int g_iOnlines[MAXPLAYERS+1];
int g_iSession[MAXPLAYERS+1];
int g_iPatch[MAXPLAYERS+1][Patch_Type];
bool g_bILoaded[MAXPLAYERS+1];
bool g_bPackage[MAXPLAYERS+1];
bool g_bTypePkg[MAXPLAYERS+1];

bool g_bLateLoad;

public Plugin myinfo = 
{
    name        = "CSGOGAMERS.COM - 2nd Year",
    author      = "Kyle",
    description = "",
    version     = "1.0",
    url         = "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("CG_GiveClientPatch",  Native_GiveClientPatch);
    CreateNative("CG_GetPlayerType",    Native_GetPlayerType);

    g_bLateLoad = late;

    return APLRes_Success;
}

public int Native_GetPlayerType(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return g_bILoaded[client] ? g_iType[client] : -1;
}

public int Native_GiveClientPatch(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    Patch_Type patch = GetNativeCell(2);
    
    if(!g_bILoaded[client])
        return false;

    GiveClientPatch(client, patch);

    return true;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_hd", Command_Main);
    RegConsoleCmd("sm_huodong", Command_Main);

    if(g_bLateLoad)
        CG_OnServerLoaded();
}

public Action Command_Main(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    DisplayMainMenu(client);
    
    return Plugin_Handled;
}

public void CG_OnServerLoaded()
{
    g_hDatabase = CG_DatabaseGetGames();
    if(g_hDatabase == INVALID_HANDLE)
        SetFailState("Databasae is not available!");

    if(g_bLateLoad)
    {
        g_bLateLoad = false;
        for(int client = 1; client <= MaxClients; ++client)
            if(IsClientInGame(client))
            {
                OnClientConnected(client);
                CG_OnClientLoaded(client);
            }
    }
}

public void OnClientConnected(int client)
{
    g_iTeam[client] = 0;
    g_iType[client] = PLAYER_NRL;
    g_iKeepDay[client] = 0;
    g_iSignDay[client] = 0;
    g_iSession[client] = 0;
    g_iOnlines[client] = 0;
    
    g_bILoaded[client] = false;
    g_bPackage[client] = false;
    g_bTypePkg[client] = false;
    
    for(int x = 0; x < 5; ++x)
        g_iPatch[client][x] = 0;
}

public void CG_OnClientLoaded(int client)
{
    int pid = CG_ClientGetPId(client);
    
    if(pid < 1)
        return;
    
    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "SELECT * FROM playertrack_huodong WHERE pid = '%d'", pid);
    SQL_TQuery(g_hDatabase, SQLCallback_LoadClient, m_szQuery, GetClientUserId(client));
}

public void CG_OnClientTeam(int client, int oldteam, int newteam)
{
    g_iTeam[client] = newteam;
    if(oldteam <= 1)
        CreateTimer(30.0, Timer_DisplayMainMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayMainMenu(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return Plugin_Stop;
    
    DisplayMainMenu(client);
    
    return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
    int pid = CG_ClientGetPId(client);
    
    if(pid < 1 || g_iSession[client] <= 60)
        return;
    
    char m_szQuery[256];
    FormatEx(m_szQuery, 256, "UPDATE playertrack_huodong SET onlines=onlines+%d WHERE pid = '%d'", g_iSession[client], pid);
    CG_DatabaseSaveGames(m_szQuery);
}

public void SQLCallback_LoadClient(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Load \"%L\" failed -> %s", client, error);
        return;
    }
    
    if(SQL_FetchRow(hndl))
    {
        for(int x = 0; x < 5; ++x)
            g_iPatch[client][x] = SQL_FetchInt(hndl, x+1);

        g_iType[client] = SQL_FetchInt(hndl, 6);
        g_iOnlines[client] = SQL_FetchInt(hndl, 7);
        g_iKeepDay[client] = SQL_FetchInt(hndl, 8);
        g_iSignDay[client] = SQL_FetchInt(hndl, 9);
        g_bPackage[client] = (SQL_FetchInt(hndl, 10) == 1) ? true : false;
        g_bTypePkg[client] = (SQL_FetchInt(hndl, 11) == 1) ? true : false;

        g_bILoaded[client] = true;
    }
    else
    {
        int onlines = CG_ClientGetOnlines(client);
        if(onlines < 180000)
        {
            g_iType[client] = PLAYER_NEW;
            char m_szQuery[256];
            FormatEx(m_szQuery, 256, "INSERT INTO playertrack_huodong (`pid`, `ptype`, `package`, `typepkg`) VALUES (%d, 2, 1, 1);", CG_ClientGetPId(client));
            SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, userid);
        }
        else
            CG_ClientGetTermOnline(client, 1501516799, 1506787199, CG_OnGetTermOnline);
    }
}

public void CG_OnGetTermOnline(int client, int start, int end, int onlines)
{
    char m_szQuery[256];
    if(onlines > 108000)
    {
        FormatEx(m_szQuery, 256, "INSERT INTO playertrack_huodong (`pid`, `ptype`, `package`, `typepkg`) VALUES (%d, 0, 1, 1);", CG_ClientGetPId(client));
        SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, GetClientUserId(client));
    }
    else
    {
        g_iType[client] = PLAYER_OLD;
        FormatEx(m_szQuery, 256, "INSERT INTO playertrack_huodong (`pid`, `ptype`, `package`, `typepkg`) VALUES (%d, 1, 1, 1);", CG_ClientGetPId(client));
        SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, GetClientUserId(client));
    }
}

public void SQLCallback_InsertClient(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Load \"%L\" failed -> %s", client, error);
        return;
    }
    
    g_bPackage[client] = true;
    g_bTypePkg[client] = true;
    g_bILoaded[client] = true;
}

public void CG_OnGlobalTimer()
{
    char fmt[32];
    FormatTime(fmt, 32, "%H", GetTime());
    int oclock = StringToInt(fmt);
    if(oclock > 24 || oclock < 0 || 3 <= oclock <= 8)
        return;

    if(GetClientCount(true) < 6)
        return;

    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && g_bILoaded[client] && g_iTeam[client] > 1)
        {
            g_iOnlines[client]++;
            g_iSession[client]++;
        }
}

public void CG_OnDailySigned(int client, int numers)
{
    if(!g_bILoaded[client])
        return;

    char m_szQuery[128];
    FormatEx(m_szQuery, 256, "UPDATE playertrack_huodong SET signday=signday+1, keepday=keepday+1 WHERE pid = '%d';", CG_ClientGetPId(client));
    SQL_TQuery(g_hDatabase, SQLCallback_DailySign, m_szQuery, GetClientUserId(client));
}

public void SQLCallback_DailySign(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Sign \"%L\" failed -> %s", client, error);
        return;
    }
    
    g_iSignDay[client]++;
    g_iKeepDay[client]++;

    PrintToChat(client, "%s  \x0F您已完成每日签到\x01.(\x05连续签到\x04%d\x05天\x0A|\x05活动签到\x04%d\x05天)", PREFIX, g_iKeepDay[client], g_iSignDay[client]);

    GiveClientPatch(client, view_as<Patch_Type>(UTIL_GetRandomInt(0, 4)));

    if(g_iKeepDay[client] == 7)
    {
        int itemid[3];
        bool result;
        UTIL_GetItemId(client, itemid[0], itemid[1], itemid[2]);
        for(int item = 0; item < 3; item++)
            if(Store_HasClientItem(client, itemid[item]))
            {
                result = true;
                Store_ExtClientItem(client, itemid[item], 0);
            }
            else
                PrintToChat(client, "%s  \x04您还没有领取②周年礼包,按Y输入!hd即可", PREFIX);
            
        if(result)
            PrintToChat(client, "%s 恭喜您,您的皮肤和足迹已成长为永久物品", PREFIX);
    }
    else if(g_iKeepDay[client] >= 2)
    {
        int itemid[3], exttime = 3600*24*10*(g_iKeepDay[client]-1);
        bool result;
        UTIL_GetItemId(client, itemid[0], itemid[1], itemid[2]);
        for(int item = 0; item < 3; item++)
            if(Store_HasClientItem(client, itemid[item]))
            {
                result = true;
                Store_ExtClientItem(client, itemid[item], exttime);
            }
            else
                PrintToChat(client, "%s  您还没有领取②周年礼包,按Y输入!hd即可", PREFIX);
            
        if(result)
            PrintToChat(client, "%s  \x04恭喜您,您的皮肤和足迹已成长,时长已经送达您的库存", PREFIX);
    }
}

void GiveClientPatch(int client, Patch_Type patch)
{
    char patch_type[16];
    switch(patch)
    {
        case Patch_A: strcopy(patch_type, 16, "patch_a");
        case Patch_B: strcopy(patch_type, 16, "patch_b");
        case Patch_C: strcopy(patch_type, 16, "patch_c");
        case Patch_D: strcopy(patch_type, 16, "patch_d");
        case Patch_E: strcopy(patch_type, 16, "patch_e");
        default: return;
    }

    g_iPatch[client][patch]++;
    DisplayNewPMenu(client, patch);

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "UPDATE playertrack_huodong SET %s=%s+1 WHERE pid = '%d'", patch_type, patch_type, CG_ClientGetPId(client));
    SQL_TQuery(g_hDatabase, SQLCallback_GivePatch, m_szQuery, GetClientUserId(client));
}

void DisplayNewPMenu(int client, Patch_Type patch)
{
    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ 您获得了新的碎片 ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "░░░░░░░░░░░░░░░░░░");
    DrawPanelTextEx(panel, "░░░░░░░░░░░░░░░░░░");
    DrawPanelTextEx(panel, " ");
    switch(patch)
    {
        case Patch_A: DrawPanelTextEx(panel, "    碎片A    ");
        case Patch_B: DrawPanelTextEx(panel, "    碎片B    ");
        case Patch_C: DrawPanelTextEx(panel, "    碎片C    ");
        case Patch_D: DrawPanelTextEx(panel, "    碎片D    ");
        case Patch_E: DrawPanelTextEx(panel, "    碎片E    ");
    }
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "░░░░░░░░░░░░░░░░░░");
    DrawPanelTextEx(panel, "░░░░░░░░░░░░░░░░░░");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "查看已有碎片");
    DrawPanelItem(panel, "返回上级菜单");

    SendPanelToClient(panel, client, MenuHandler_NewPatchPanel, 30);
}

public int MenuHandler_NewPatchPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        switch(itemNum)
        {
            case 1: DisplayKeysMenu(client);
            case 2: Command_Main(client, 0);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public void SQLCallback_GivePatch(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Give \"%L\" failed -> %s", client, error);
        g_bILoaded[client] = false;
        PrintToChat(client, "%s 服务器出错了,请稍后再试...", PREFIX);
        return;
    }
    
    PrintToChat(client, "%s 已经将你的碎片保存至数据库!", PREFIX);
}

void DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_MainMenu);
    
    char title[128];
    FormatEx(title, 128, "[CG]  ②周年\n \n在线时长: %dh%dm\n活动签到: %d天\n连续签到: %d天", (g_iOnlines[client]+g_iSession[client])/3600, ((g_iOnlines[client]+g_iSession[client])%3600)/60, g_iSignDay[client], g_iKeepDay[client]);

    switch(g_iType[client])
    {
        case PLAYER_OLD: Format(title, 128, "%s\nStatus: 老玩家回流", title);
        case PLAYER_NEW: Format(title, 128, "%s\nStatus: 新玩家入驻", title);
        case PLAYER_NRL: Format(title, 128, "%s\nStatus: 死忠狂欢节", title);
        default        : Format(title, 128, "%s\nStatus: 死忠狂欢节", title);
    }

    SetMenuTitleEx(menu, title);

    
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "4", "领取活动礼包");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "3", "进行每日签到");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "查看钥匙碎片");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "合成钥匙碎片");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "0", "查看活动细则");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "5", "重载我的数据");

    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_End)
        CloseHandle(menu);
    else if(action == MenuAction_Cancel)
    {
        if(itemNum == MenuCancel_ExitBack)
            FakeClientCommand(client, "sm_cg");
    }
    else if(action == MenuAction_Select) 
    {
        char info[16];
        GetMenuItem(menu, itemNum, info, 16);
        switch(StringToInt(info))
        {
            case 0: DisplayRuleMenu(client);
            case 1: DisplayKeysMenu(client);
            case 2: DisplayCompMenu(client);
            case 3: FakeClientCommand(client, "sm_sign");
            case 4: DisplayPkgsMenu(client);
            case 5:
            {
                if(g_bILoaded[client])
                    return;
                
                OnClientConnected(client);
                CG_OnClientLoaded(client);
            }
        }
    }
}

void DisplayRuleMenu(int client)
{
    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ 活动细则 ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "▲集齐五个碎片可以合成1把CSGO钥匙");
    DrawPanelTextEx(panel, "┕完成每日签到即可获得钥匙碎片掉落");
    DrawPanelTextEx(panel, "▲通过签到可以不断升级礼包物品的时长");
    DrawPanelTextEx(panel, "┕连续签到天数*10天(连续签到7天即为永久");
    DrawPanelTextEx(panel, "▲充值信用点送信用点且首充双倍");
    DrawPanelTextEx(panel, "┕充100送20(依此类推)不与双倍冲突");
    DrawPanelTextEx(panel, "▲狂欢节在线时长兑换商店人物皮肤");
    DrawPanelTextEx(panel, "┕在线50小时: 任意商店在售模型(永久)");
    DrawPanelTextEx(panel, "┕在线99小时: 任意皮肤箱内模型(永久)");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "单服活动");
    DrawPanelItem(panel, "上级菜单");

    SendPanelToClient(panel, client, MenuHandler_MainDetailesPanel, 30);
}

public int MenuHandler_MainDetailesPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        switch(itemNum)
        {
            case 1: DisplaySrvRMenu(client);
            case 2: Command_Main(client, 0);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplaySrvRMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_SrvRMenu);
    SetMenuTitleEx(menu, "选择你要查看的服务器");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "0", "僵尸逃跑");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "1", "匪镇谍影");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "2", "越狱搞基");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "3", "娱乐休闲");
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_SrvRMenu(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char info[16];
        GetMenuItem(menu, itemNum, info, 16);
        DisplaySrvPanel(client, StringToInt(info));
    }
    else if(action == MenuAction_Cancel)
    {
        if(itemNum == MenuCancel_ExitBack)
            DisplayRuleMenu(client);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplaySrvPanel(int client, int srvid)
{
    Handle panel = CreatePanel();

    switch(srvid)
    {
        case 0:
        {
            DrawPanelTextEx(panel, "▽ 僵尸逃跑 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "▲人类成功通关");
            DrawPanelTextEx(panel, "┕存活玩家->ROLL任意时长活动皮肤");
            DrawPanelTextEx(panel, "┕在线玩家->ROLL任意时长任意皮肤");
            DrawPanelTextEx(panel, "┕在线玩家->抽钥匙碎片");
            DrawPanelTextEx(panel, "┕累计通关->兑换特定物品");
            DrawPanelTextEx(panel, "▲僵尸感染人类");
            DrawPanelTextEx(panel, "┕1幅地图感染20人类->兑换物品");
            DrawPanelTextEx(panel, "┕活动时间累计感染1000人类->兑换活动皮肤");
            DrawPanelTextEx(panel, "┕感染人类获得信用点加倍");
            DrawPanelTextEx(panel, "▲指挥/断后");
            DrawPanelTextEx(panel, "┕指挥带图->掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕断后随机->掉落钥匙碎片");
        }
        case 1:
        {
            DrawPanelTextEx(panel, "▽ 匪镇谍影 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "▲萌新专属");
            DrawPanelTextEx(panel, "┕50正确击杀->8888信用点");
            DrawPanelTextEx(panel, "┕150正确击杀->随机足迹30天");
            DrawPanelTextEx(panel, "┕300正确击杀->龙神剑皮肤90天");
            DrawPanelTextEx(panel, "▲全体都有");
            DrawPanelTextEx(panel, "┕正确击杀信用点加倍");
            DrawPanelTextEx(panel, "┕道具正确击杀->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕侦探枪验明叛徒身份->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕使用道具三杀以上->掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕600正确击杀玩家->内测限定皮肤犬走椛[永久]");
            DrawPanelTextEx(panel, "┕玩家认证成功后加入TTT官方组->弱音[永久]");
        }
        case 2:
        {
            DrawPanelTextEx(panel, "▽ 越狱搞基 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "▲暴动");
            DrawPanelTextEx(panel, "┕拿到1血->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕使用道具五杀以上->掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕3分钟内杀死所有CT->囚犯ROLL任意时长皮肤");
            DrawPanelTextEx(panel, "┕击杀50个狱警->龙神剑[90天]");
            DrawPanelTextEx(panel, "┕击杀150个狱警->普通皮肤[90天]");
            DrawPanelTextEx(panel, "┕击杀300个狱警->二周年皮肤[随机时长]");
            DrawPanelTextEx(panel, "▲监管");
            DrawPanelTextEx(panel, "┕击杀1血囚犯->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕狱长整局且CT死亡人数小于3->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕狱警胜利且存活率过半->狱警ROLL钥匙碎片");
        }
        case 3:
        {
            DrawPanelTextEx(panel, "▽ 娱乐休闲 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "▲杀杀人吹吹比跳跳舞");
            DrawPanelTextEx(panel, "┕使用电鸡枪杀敌->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕使用手雷双杀以上->随机任意时长(1天-1年)活动皮肤");
            DrawPanelTextEx(panel, "┕使用烟雾弹/诱饵雷砸死人->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕爆头击杀->随机活动随机数量信用点");
            DrawPanelTextEx(panel, "┕EndGame中1V1获胜的玩家->随机掉落钥匙碎片");
            DrawPanelTextEx(panel, "┕杀敌信用点奖励双倍");
        }
    }

    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "返回");
    
    SendPanelToClient(panel, client, MenuHandler_SrvRPanel, 30);
}

public int MenuHandler_SrvRPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
        DisplaySrvRMenu(client);
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplayKeysMenu(int client)
{
    if(!g_bILoaded[client])
    {
        PrintToChat(client, "%s \x04请等待你的数据加载完毕", PREFIX);
        DisplayMainMenu(client);
        return;
    }
    
    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ 钥匙碎片 ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "钥匙碎片A: %d", g_iPatch[client][Patch_A]);
    DrawPanelTextEx(panel, "钥匙碎片B: %d", g_iPatch[client][Patch_B]);
    DrawPanelTextEx(panel, "钥匙碎片C: %d", g_iPatch[client][Patch_C]);
    DrawPanelTextEx(panel, "钥匙碎片D: %d", g_iPatch[client][Patch_D]);
    DrawPanelTextEx(panel, "钥匙碎片E: %d", g_iPatch[client][Patch_E]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "合成");
    DrawPanelItem(panel, "返回");
    DrawPanelItem(panel, "退出");

    SendPanelToClient(panel, client, MenuHandler_KeysDetailesPanel, 30);
}

public int MenuHandler_KeysDetailesPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        switch(itemNum)
        {
            case 1: DisplayCompMenu(client);
            case 2: Command_Main(client, 0);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void DisplayCompMenu(int client)
{
    if(!g_bILoaded[client])
    {
        PrintToChat(client, "%s \x04请等待你的数据加载完毕", PREFIX);
        DisplayMainMenu(client);
        return;
    }
    
    if(!HasEnoughPatch(client))
    {
        PrintToChat(client, "%s \x04你没有足够的碎片来合成钥匙", PREFIX);
        return;
    }
    
    if(CG_ClientGetUId(client) < 1)
    {
        PrintToChat(client, "%s \x04你需要将steam账户与论坛账户绑定才能合成", PREFIX);
        return;
    }
    
    Handle menu = CreateMenu(MenuHandler_CompMenu);
    SetMenuTitleEx(menu, "您要使用1组碎片来合成钥匙吗");

    AddMenuItemEx(menu, ITEMDRAW_SPACER, " ", " ");
    AddMenuItemEx(menu, ITEMDRAW_SPACER, " ", " ");
    AddMenuItemEx(menu, ITEMDRAW_SPACER, " ", " ");
    AddMenuItemEx(menu, ITEMDRAW_SPACER, " ", " ");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "yes", "确定");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "000", "退出");

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 0);
}

bool HasEnoughPatch(int client)
{
    for(int x = 0; x < 5; ++x)
        if(g_iPatch[client][x] < 1)
            return false;
        
    return true;
}

public int MenuHandler_CompMenu(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        char info[16];
        GetMenuItem(menu, itemNum, info, 16);
        if(strcmp(info, "yes") == 0)
        {
            char m_szQuery[256];
            FormatEx(m_szQuery, 256, "UPDATE playertrack_huodong SET patch_a=patch_a-1, patch_b=patch_b-1, patch_c=patch_c-1, patch_d=patch_d-1, patch_e=patch_e-1 WHERE pid = '%d';", CG_ClientGetPId(client));
            SQL_TQuery(g_hDatabase, SQLCallback_CheckPatch, m_szQuery, GetClientUserId(client));
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

public void SQLCallback_CheckPatch(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Check \"%L\" failed -> %s", client, error);
        PrintToChat(client, "%s 服务器出错了,请稍后再试...", PREFIX);
        return;
    }
    
    for(int x = 0; x < 5; ++x)
        g_iPatch[client][x]--;
    
    char m_szQuery[256], m_szAuth[32], date[32];
    FormatTime(date, 32, "%Y%m%d", GetTime());
    GetClientAuthId(client, AuthId_Steam2, m_szAuth, 32, true);
    FormatEx(m_szQuery, 256, "INSERT INTO `playertrack_keys` (`playerid`, `dzid`, `steamid`, `date`, `time`) VALUES ('%d', '%d', '%s', '%s', '%d');", CG_ClientGetPId(client), CG_ClientGetUId(client), m_szAuth, date, GetTime());
    SQL_TQuery(g_hDatabase, SQLCallback_GiveKeys, m_szQuery, userid);
}

public void SQLCallback_GiveKeys(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Keys \"%L\" failed -> %s", client, error);
        PrintToChat(client, "%s 服务器出错了,请稍后再试...", PREFIX);
        return;
    }
    
    PrintToChat(client, "%s \x04合成成功!你需要到论坛填写Steam交易报价链接才能收到钥匙!", PREFIX);
    PrintToChat(client, "%s \x04请讲Steam库存设置成公开,否则交易机器人无法发送交易报价!", PREFIX);
    
    DisplayMainMenu(client);
}

void DisplayPkgsMenu(int client)
{
    if(!g_bILoaded[client])
    {
        PrintToChat(client, "%s \x04请等待你的数据加载完毕", PREFIX);
        DisplayMainMenu(client);
        return;
    }

    Handle menu = CreateMenu(MenuHandler_PkgsMenu);
    SetMenuTitleEx(menu, "②周年礼包中心");

    AddMenuItemEx(menu, (g_iType[client] == PLAYER_OLD && g_bTypePkg[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "0", "领取老鸟回归礼包");
    AddMenuItemEx(menu, (g_iType[client] == PLAYER_NEW && g_bTypePkg[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "1", "领取新手入驻礼包");
    AddMenuItemEx(menu, (g_iType[client] == PLAYER_NRL && g_bTypePkg[client]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "2", "领取死忠狂欢礼包");
    AddMenuItemEx(menu,  g_bPackage[client] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "3", "领取每日登录礼包");

    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_PkgsMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_End)
        CloseHandle(menu);
    else if(action == MenuAction_Cancel)
    {
        if(itemNum == MenuCancel_ExitBack)
            Command_Main(client, 0);
    }
    else if(action == MenuAction_Select) 
    {
        if(!g_bILoaded[client])
        {
            PrintToChat(client, "%s \x04请等待你的数据加载完毕", PREFIX);
            return;
        }

        char info[16];
        GetMenuItem(menu, itemNum, info, 16);
        GiveClientPackages(client, StringToInt(info));
    }
}

void GiveClientPackages(int client, int type)
{
    if(type == 3)
    {
        if(UTIL_GetRandomInt(1, 100) > 80)
            GiveClientPatch(client, view_as<Patch_Type>(UTIL_GetRandomInt(0, 4)));
        else
            GiveClientCredits(client, UTIL_GetRandomInt(100, 500), "领取了每日礼包");
        
        g_bPackage[client] = false;
        
        char m_szQuery[128];
        FormatEx(m_szQuery, 128, "UPDATE playertrack_huodong SET package = 0 WHERE pid = '%d'", CG_ClientGetPId(client));
        CG_DatabaseSaveGames(m_szQuery);

        return;
    }

    char m_szQuery[128];
    FormatEx(m_szQuery, 128, "UPDATE playertrack_huodong SET typepkg = 0 WHERE pid = '%d'", CG_ClientGetPId(client));
    SQL_TQuery(g_hDatabase, SQLCallback_GivePackage, m_szQuery, GetClientUserId(client));
}

void GiveClientCredits(int client, int credits, const char[] reason)
{
    Store_SetClientCredits(client, Store_GetClientCredits(client)+credits, reason);
    PrintToChatAll("%s \x0C%N\x05%s\x01,\x05获得了\x10%d信用点", PREFIX, client, reason, credits);
}

public void SQLCallback_GivePackage(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client =  GetClientOfUserId(userid);
    
    if(!client)
        return;
    
    if(hndl == INVALID_HANDLE)
    {
        LogError("Package \"%L\" failed -> %s", client, error);
        PrintToChat(client, "%s 服务器出错了,请稍后再试...", PREFIX);
        return;
    }
    
    g_bTypePkg[client] = false;
    
    DisplayTpkgMenu(client);
}

void DisplayTpkgMenu(int client)
{
    Handle panel = CreatePanel();
    
    switch(g_iType[client])
    {
        case PLAYER_NEW:
        {
            DrawPanelTextEx(panel, "▽ 新玩家入驻礼包 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "Hi! 欢迎加入CG大家庭!");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "信用点: 6666", g_iPatch[client][Patch_A]);
            DrawPanelTextEx(panel, "普通足迹: 滑稽足迹[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[CT]: 神崎兰子[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[TE]: 滑稽害怕[7天] (可成长为永久)");
            
            GiveClientCredits(client, 6666, "领取了新玩家入驻礼包");
            PrintToChatAll("%s \x0C%N\x05获得了足迹[\x10滑稽足迹\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10神崎兰子\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10滑稽害怕\x05]", PREFIX, client);
        }
        case PLAYER_OLD:
        {
            DrawPanelTextEx(panel, "▽ 老玩家回归礼包 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "Hey! 欢迎回家!");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "信用点: 6666", g_iPatch[client][Patch_A]);
            DrawPanelTextEx(panel, "普通足迹: 皇冠足迹[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[TE]: IA(TDA)[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[CT]: Peter28[7天] (可成长为永久)");
            
            GiveClientCredits(client, 6666, "领取了老玩家回归礼包");
            PrintToChatAll("%s \x0C%N\x05获得了足迹[\x10皇冠足迹\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10IA(TDA)\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10Peter28\x05]", PREFIX, client);
        }
        case PLAYER_NRL:
        {
            DrawPanelTextEx(panel, "▽ 死忠狂欢礼包 ▽");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "aha! CG一路走来感谢有你!");
            DrawPanelTextEx(panel, " ");
            DrawPanelTextEx(panel, "信用点: 6666", g_iPatch[client][Patch_A]);
            DrawPanelTextEx(panel, "普通足迹: 太极足迹[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[TE]: Seulbi.Agent[7天] (可成长为永久)");
            DrawPanelTextEx(panel, "人物皮肤[CT]: 夕立[7天] (可成长为永久)");

            GiveClientCredits(client, 6666, "领取了死忠狂欢礼包");
            PrintToChatAll("%s \x0C%N\x05获得了足迹[\x10太极足迹\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10Seulbi\x05]", PREFIX, client);
            PrintToChatAll("%s \x0C%N\x05获得了皮肤[\x10夕立改\x05]", PREFIX, client);
        }
    }

    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");
    DrawPanelItem(panel, "OK");
    SendPanelToClient(panel, client, MenuHandler_PackagePanel, 30);
    
    int itemid[3];
    UTIL_GetItemId(client, itemid[0], itemid[1], itemid[2]);

    if(itemid[0] >= 0)
    {
        if(Store_HasClientItem(client, itemid[0]))
            Store_ExtClientItem(client, itemid[0], 604800);
        else
            Store_GiveItem(client, itemid[0], GetTime(), GetTime()+604800, 1001);
    }
    
    if(itemid[1] >= 0)
    {
        if(Store_HasClientItem(client, itemid[1]))
            Store_ExtClientItem(client, itemid[1], 604800);
        else
            Store_GiveItem(client, itemid[1], GetTime(), GetTime()+604800, 1001);
    }
    
    if(itemid[2] >= 0)
    {
        if(Store_HasClientItem(client, itemid[2]))
            Store_ExtClientItem(client, itemid[2], 604800);
        else
            Store_GiveItem(client, itemid[2], GetTime(), GetTime()+604800, 1001);
    }
}

void UTIL_GetItemId(int client, int &trails, int &skin_1, int &skin_2)
{
    switch(g_iType[client])
    {
        case PLAYER_NEW:
        {
            trails = Store_GetItemId("trail", "materials/maoling/trails/huaji.vmt");
            skin_1 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/idolm@ster/kanzaki_ranko/kanzaki.mdl");
            skin_2 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl");
        }
        case PLAYER_OLD:
        {            
            trails = Store_GetItemId("trail", "materials/sprites/store/trails/crown.vmt");
            skin_1 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/vocaloid/ia/ia.mdl");
            skin_2 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/misc/peter/peter_v2.mdl");
        }
        case PLAYER_NRL:
        {
            trails = Store_GetItemId("trail", "materials/sprites/store/trails/yingyang2.vmt");
            skin_1 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/closeronline/seulbi/seulbi.mdl");
            skin_2 = Store_GetItemId("playerskin", "models/player/custom_player/maoling/kantai_collection/yuudachi/yuudachi.mdl");
        }
    }
}

public int MenuHandler_PackagePanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        FakeClientCommand(client, "sm_store");
        PrintToChat(client, "%s 皮肤/足迹时长增长请查看活动细则", PREFIX);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}
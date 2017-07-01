enum DailySign
{
    iNumbers,
    iLastSign,
    bool:bSigned,
    Handle:hSignTimer
}

DailySign DailySign_Data_Client[MAXPLAYERS+1][DailySign];

Handle DailySign_Forward_OnDailySigned;

void DailySign_OnPluginStart()
{
    DailySign_Forward_OnDailySigned = CreateGlobalForward("CG_OnDailySigned", ET_Ignore, Param_Cell, Param_Cell);

    RegConsoleCmd("sm_sign",    Command_Login);
    RegConsoleCmd("sm_qiandao", Command_Login);
}

void DailySign_OnClientConnected(int client)
{
    DailySign_Data_Client[client][iNumbers]   = 0;
    DailySign_Data_Client[client][iLastSign]  = 0;
    DailySign_Data_Client[client][bSigned]    = false;
    DailySign_Data_Client[client][hSignTimer] = INVALID_HANDLE;
}

void DailySign_OnGlobalTimer(int client)
{
    if(!DailySign_Data_Client[client][bSigned] && g_ClientGlobal[client][iDaily] >= 900 && DailySign_Data_Client[client][hSignTimer] == INVALID_HANDLE)
    {
        PrintToChat(client, "\x04你现在可以签到了,按Y输入\x07!sign\x04来签到!");
        DailySign_Data_Client[client][hSignTimer] = CreateTimer(30.0, Timer_NotifySign, client, TIMER_REPEAT);
    }
}

public Action Timer_NotifySign(Handle timer, int client)
{
    DailySign_Data_Client[client][hSignTimer] = INVALID_HANDLE;
    if(IsValidClient(client) && g_ClientGlobal[client][bLoaded] && !DailySign_Data_Client[client][bSigned] && g_ClientGlobal[client][iDaily] >= 900)
        PrintToChat(client, "\x04你现在可以签到了,按Y输入\x07!sign\x04来签到!");
    return Plugin_Stop;
}

void DailySign_InitializeSignData(int client, int numbers, int lasttime)
{
    DailySign_Data_Client[client][iNumbers]   = numbers;
    DailySign_Data_Client[client][iLastSign]  = lasttime;
    DailySign_Data_Client[client][bSigned]    = (lasttime > 0);
}

public Action Command_Login(int client, int args) 
{
    if(DailySign_Data_Client[client][bSigned])
    {
        PrintToChat(client, "每天只能签到1次!");
        return Plugin_Handled;
    }

    if(g_ClientGlobal[client][iDaily] < 900) 
    {
        PrintToChat(client, "你还需要在线\x04%d\x01秒才能签到!", 900 - g_ClientGlobal[client][iDaily]);
        return Plugin_Handled;
    }

    DailySign_Data_Client[client][bSigned] = true;

    char m_szQuery[256];
    Format(m_szQuery, 256, "UPDATE playertrack_player SET signnumber = signnumber+1, signtime = '%d' WHERE id = '%d' ", GetTime(), g_ClientGlobal[client][iPId]);
    MySQL_Query(false, DailySign_SQLCallback_ProcessingSign, m_szQuery, GetClientUserId(client));

    return Plugin_Handled;
}

public void DailySign_SQLCallback_ProcessingSign(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        PrintToChat(client, "\x02未知错误,请重试!");
        DailySign_Data_Client[client][bSigned] = false;
        UTIL_LogError("DailySign_SQLCallback_ProcessingSign", "UPDATE Client Sign Failed! Client:%L Query:%s", client, error);
        return;
    }

    DailySign_Data_Client[client][iNumbers]++;
    DailySign_Data_Client[client][iLastSign] = GetTime();
    DailySign_Data_Client[client][bSigned] = true;

    PrintToChat(client, "签到成功,你已累计签到\x0C%d\x01天!", DailySign_Data_Client[client][iNumbers]);

    Call_StartForward(DailySign_Forward_OnDailySigned);
    Call_PushCell(client);
    Call_PushCell(DailySign_Data_Client[client][iNumbers]);
    Call_Finish();
}
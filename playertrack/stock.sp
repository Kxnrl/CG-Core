stock bool MySQL_Query(Handle database, SQLTCallback callback, const char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
	if(database == INVALID_HANDLE)
	{
		if(database == g_eHandle[DB_Game])
		{
			SQL_TConnect_csgo();
		}
		else if(database == g_eHandle[DB_Discuz])
		{
			SQL_TConnect_discuz();
		}
		return false;
	}
	
	SQL_TQuery(database, callback, query, data, prio);

	return true;
}

stock void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, fmt, 3);
	
	if(g_eGame == Engine_CSGO)
		Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
	else
	{
		ReplaceString(m_szBuffer, 256, "\n \n", " - ");
		ReplaceString(m_szBuffer, 256, "\n", " - ");
	}

	SetMenuTitle(menu, m_szBuffer);
}

stock bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);

	if(g_eGame != Engine_CSGO)
		ReplaceString(m_szBuffer, 256, "\n", " - ");

	return AddMenuItem(menu, info, m_szBuffer, style);
}

stock bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients))
		return false;

	if(!IsClientInGame(client))
		return false;

	if(IsFakeClient(client))
		return false;

	return true;
}

stock int FindClientByPlayerId(int PlayerId)
{
	if(PlayerId < 0)
		return -2;

	for(int client = 1; client <= MaxClients; ++client)
	{
		if(IsClientInGame(client))
		{
			if(g_eClient[client][bLoaded] && g_eClient[client][iPlayerId] == PlayerId)
			{
				return client;
			}
		}
	}

	return -1;
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
	char szBuffer[256];
	VFormat(szBuffer, 256, szMessage, 3);
	ReplaceColorsCode(szBuffer, 256);
	PrintToChat(client, szBuffer);
}

stock bool TalentAvailable()
{
	if(FindPluginByFile("talent.smx"))
		return true;

	return false;
}

stock void PrepareUrl(int width, int height, char[] m_szUrl)
{
	Format(m_szUrl, 192, "https://csgogamers.com/webplugin.php?width=%d&height=%d&url=%s", width, height, m_szUrl);
}

stock void ShowMOTDPanelEx(int client, const char[] title = "CSGOGAMERS.COM", const char[] url, int type = MOTDPANEL_TYPE_INDEX, int cmd = MOTDPANEL_CMD_NONE, bool show = true)
{
	Handle m_hKv = CreateKeyValues("data");
	KvSetString(m_hKv, "title", "CSGOGAMERS.COM");
	KvSetNum(m_hKv, "type", type);
	KvSetString(m_hKv, "msg", url);
	KvSetNum(m_hKv, "cmd", cmd);
	ShowVGUIPanel(client, "info", m_hKv, show);
	CloseHandle(m_hKv);
}

stock void ReplaceColorsCode(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "{normal}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{darkred}", "\x02", false);
	ReplaceString(message, maxLen, "{teamcolor}", "\x03", false);
	ReplaceString(message, maxLen, "{pink}", "\x03", false);
	ReplaceString(message, maxLen, "{green}", "\x04", false);
	ReplaceString(message, maxLen, "{highlight}", "\x04", false);
	ReplaceString(message, maxLen, "{yellow}", "\x05", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x05", false);
	ReplaceString(message, maxLen, "{lime}", "\x06", false);
	ReplaceString(message, maxLen, "{lightred}", "\x07", false);
	ReplaceString(message, maxLen, "{red}", "\x07", false);
	ReplaceString(message, maxLen, "{gray}", "\x08", false);
	ReplaceString(message, maxLen, "{grey}", "\x08", false);
	ReplaceString(message, maxLen, "{olive}", "\x09", false);
	ReplaceString(message, maxLen, "{orange}", "\x10", false);
	ReplaceString(message, maxLen, "{silver}", "\x0A", false);
	ReplaceString(message, maxLen, "{lightblue}", "\x0B", false);
	ReplaceString(message, maxLen, "{blue}", "\x0C", false);
	ReplaceString(message, maxLen, "{purple}", "\x0E", false);
	ReplaceString(message, maxLen, "{darkorange}", "\x0F", false);
}

stock void GetClientAuthName(int client, char[] buffer, int maxLen)
{
	switch(g_eClient[client][iGroupId])
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

stock void TranslationToFile(const char[] m_szPath)
{
	Handle file = OpenFile(m_szPath, "w");
	WriteFileLine(file, "\"Phrases\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"signature title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Signature setup \\n500Credits per setup[Free for first time]\"");
	WriteFileLine(file, "\"chi\"	\"签名设置  \\n设置签名需要500信用点[首次免费]\"");
	WriteFileLine(file, "\"zho\"	\"簽名設置　\\n設定簽名需要500個點數[第一次免費]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature now you can type\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Input your signature in chat \\n\"");
	WriteFileLine(file, "\"chi\"	\"你现在可以按Y输入签名了 \\n \"");
	WriteFileLine(file, "\"zho\"	\"你現在可以按Y輸入簽名了 \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature color codes\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Useable color codes:\\n {lightred} {yellow} {blue} {green} {orange} {purple} {pink} \\n\"");
	WriteFileLine(file, "\"chi\"	\"可用颜色代码\\n {亮红} {黄} {蓝} {绿} {橙} {紫} {粉} \\n \"");
	WriteFileLine(file, "\"zho\"	\"可用顏色代碼\\n {亮红} {黄} {蓝} {绿} {橙} {紫} {粉} \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature example\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"EXAMPLE: (blue)E{yellow}X{lightred}A{green}M{orange}P{purple}L{pink}E\"");
	WriteFileLine(file, "\"chi\"	\"例如: {蓝}陈{红}抄{黄}封{紫}不{粉}要{绿}脸 \\n \"");
	WriteFileLine(file, "\"zho\"	\"比如: {蓝}陈{红}抄{黄}封{紫}不{粉}要{绿}脸 \\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature input preview\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Inputed: \\n {1}\\n \"");
	WriteFileLine(file, "\"chi\"	\"你当前已输入: \\n {1}\\n \"");
	WriteFileLine(file, "\"zho\"	\"你當前已輸入: \\n {1}\\n \"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature input\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Inputed: {1}\"");
	WriteFileLine(file, "\"chi\"	\"您输入了: {1}\"");
	WriteFileLine(file, "\"zho\"	\"你輸入了: {1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature item preview\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Preview signature\"");
	WriteFileLine(file, "\"chi\"	\"查看预览\"");
	WriteFileLine(file, "\"zho\"	\"查看預覽\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature item ok\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Complete\"");
	WriteFileLine(file, "\"chi\"	\"我写好了\"");
	WriteFileLine(file, "\"zho\"	\"我寫完了\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature you have not enough credits\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Insufficient credits\"");
	WriteFileLine(file, "\"chi\"	\"信用点不足,不能设置签名\"");
	WriteFileLine(file, "\"zho\"	\"點數不夠,不能設定簽名\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature set successful\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Signature sucessfully setup\"");
	WriteFileLine(file, "\"chi\"	\"已成功设置您的签名,花费了{green}500信用点\"");
	WriteFileLine(file, "\"zho\"	\"已經設定了你的簽名,花了{green}500個點數\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature yours\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Your signature\"");
	WriteFileLine(file, "\"chi\"	\"您的签名\"");
	WriteFileLine(file, "\"zho\"	\"你的簽名\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"signature free first\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Free for first set-up\"");
	WriteFileLine(file, "\"chi\"	\"首次设置签名免费!\"");
	WriteFileLine(file, "\"zho\"	\"第一次設定簽名免費\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign allow sign\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"{green}You can sign now - Type{lightred} !sign{green} in chat to sign\"");
	WriteFileLine(file, "\"chi\"	\"{green}你现在可以签到了,按Y输入{lightred}!sign{green}来签到!\"");
	WriteFileLine(file, "\"zho\"	\"{green}你現在可以簽到了,按Y輸入{lightred}!sign{green}來簽到!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign twice sign\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"You can only sign once each day!\"");
	WriteFileLine(file, "\"chi\"	\"每天只能签到1次!\"");
	WriteFileLine(file, "\"zho\"	\"每天只能簽到1次!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign no time\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"{green}{1}{default} more second for sign-up!\"");
	WriteFileLine(file, "\"chi\"	\"你还需要在线{green}{1}{default}秒才能签到!\"");
	WriteFileLine(file, "\"zho\"	\"你還需要在綫{green}{1}{default}秒才能簽到!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign error\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"{darkred}Sign error - try again later\"");
	WriteFileLine(file, "\"chi\"	\"{darkred}未知错误,请重试!\"");
	WriteFileLine(file, "\"zho\"	\"{darkred}未知錯誤,請重試!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"sign successful\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"{default}You had signed up today. Total signed up for {blue}{1}{default} day(s)!\"");
	WriteFileLine(file, "\"chi\"	\"{default}签到成功,你已累计签到{blue}{1}{default}天!\"");
	WriteFileLine(file, "\"zho\"	\"{default}簽到成功,你已經簽到了{blue}{1}{default}天!\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"system error\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"An error occupied - try again later:\"");
	WriteFileLine(file, "\"chi\"	\"系统中闪光弹了,请重试!  错误:\"");
	WriteFileLine(file, "\"zho\"	\"系統出錯,請重試!  錯誤:\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp married\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s},{2:s}\"");
	WriteFileLine(file, "\"en\"	\"{orange}Congraulates {purple}{1}{orange} and {purple}{2}{orange} made a couple.\"");
	WriteFileLine(file, "\"chi\"	\"{orange}恭喜{purple}{1}{orange}和{purple}{2}{orange}结成CP.\"");
	WriteFileLine(file, "\"zho\"	\"{orange}恭喜{purple}{1}{orange}和{purple}{2}{orange}組成CP.\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp married offline\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Data saved - Awards unaviliable\"");
	WriteFileLine(file, "\"chi\"	\"系统已保存你们的数据,但是你老婆当前离线,你不能享受新婚祝福\"");
	WriteFileLine(file, "\"zho\"	\"系統已保存你們的檔案,但是你老婆現在離綫,你不能接受新婚祝福\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N},{2:s},{3:d}\"");
	WriteFileLine(file, "\"en\"	\"{orange}{1}{yellow} terminated couple relationship with {orange}{2}{yellow} - Their relationship existed for{red}{3}{yellow}days\"");
	WriteFileLine(file, "\"chi\"	\"{orange}{1}{yellow}解除了和{orange}{2}{yellow}的CP,他们的关系维持了{red}{3}{yellow}天\"");
	WriteFileLine(file, "\"zho\"	\"{orange}{1}{yellow}解除了和{orange}{2}{yellow}的CP,他們搞基了{red}{3}{yellow}天\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp find\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Find couple\"");
	WriteFileLine(file, "\"chi\"	\"寻找CP\"");
	WriteFileLine(file, "\"zho\"	\"尋找CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp out\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Dissolute couple\"");
	WriteFileLine(file, "\"chi\"	\"解除CP\"");
	WriteFileLine(file, "\"zho\"	\"解除CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp about\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"About\"");
	WriteFileLine(file, "\"chi\"	\"关于CP\"");
	WriteFileLine(file, "\"zho\"	\"關於CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp no target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"No one can receive request now\"");
	WriteFileLine(file, "\"chi\"	\"当前服务器内没有人能跟你搞基\"");
	WriteFileLine(file, "\"zho\"	\"當前服務器裏面沒有人能跟你CP\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp invalid target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Invalid request target\"");
	WriteFileLine(file, "\"chi\"	\"你选择的对象目前不可用\"");
	WriteFileLine(file, "\"zho\"	\"你選擇的對象不正確\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp send\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"{purple}{1}{normal} received your request\"");
	WriteFileLine(file, "\"chi\"	\"已将你的CP请求发送至{purple}{1}\"");
	WriteFileLine(file, "\"zho\"	\"已經將你的CP請求發送給{purple}{1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp request\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Received a couple request\"");
	WriteFileLine(file, "\"chi\"	\"您有一个CP请求\"");
	WriteFileLine(file, "\"zho\"	\"你有一個CP請求\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp request item target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"Received couple request from {1}\"");
	WriteFileLine(file, "\"chi\"	\"你收到了一个来自 {1} 的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"你收到了一個來自 {1} 的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp 7days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot terminate relationship in 7 days\"");
	WriteFileLine(file, "\"chi\"	\"组成CP后7天内不能申请解除\"");
	WriteFileLine(file, "\"zho\"	\"組成CP後7天內不能申請解開\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp buff\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Spec awards for couples\"");
	WriteFileLine(file, "\"chi\"	\"组成CP后可以享受多种福利\"");
	WriteFileLine(file, "\"zho\"	\"組成CP可以想說一些福利\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp confirm\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Accept this request?\"");
	WriteFileLine(file, "\"chi\"	\"你确定要接受这个邀请吗\"");
	WriteFileLine(file, "\"zho\"	\"你確定要接受這個邀請嗎\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp accept\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Yes\"");
	WriteFileLine(file, "\"chi\"	\"我接受\"");
	WriteFileLine(file, "\"zho\"	\"我接受\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Nope\"");
	WriteFileLine(file, "\"chi\"	\"我拒绝\"");
	WriteFileLine(file, "\"zho\"	\"我拒絕\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse target\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"You rejected {orange}{1}{default}'s couple request\"");
	WriteFileLine(file, "\"chi\"	\"你拒绝了{orange}{1}{default}的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"你拒絕了{orange}{1}{default}的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp refuse client\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N}\"");
	WriteFileLine(file, "\"en\"	\"{orange}{1}{default} had rejected your request\"");
	WriteFileLine(file, "\"chi\"	\"{orange}{1}{default}拒绝了你的CP邀请\"");
	WriteFileLine(file, "\"zho\"	\"{orange}{1}{default}拒絕了你的CP邀請\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp can divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot terminate relationship in week once you make new couple\"");
	WriteFileLine(file, "\"chi\"	\"新组成CP之后7天内不能申请解除\"");
	WriteFileLine(file, "\"zho\"	\"新組成CP之後7天內不能申請解開\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp your cp\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:s}\"");
	WriteFileLine(file, "\"en\"	\"Your couple is {1}\"");
	WriteFileLine(file, "\"chi\"	\"你当前的CP伴侣为 {1}\"");
	WriteFileLine(file, "\"zho\"	\"你現在的CP伴侶为 {1}\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp your days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d}\"");
	WriteFileLine(file, "\"en\"	\"Relationship exists for {1} days\"");
	WriteFileLine(file, "\"chi\"	\"你们已组成CP {1} 天\"");
	WriteFileLine(file, "\"zho\"	\"你們已經搞基 {1} 天\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp confirm divorce\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Terminate couple relationship?\"");
	WriteFileLine(file, "\"chi\"	\"你确定要解除CP组合吗\"");
	WriteFileLine(file, "\"zho\"	\"你確定要解開CP配對嗎\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp help title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Help\"");
	WriteFileLine(file, "\"chi\"	\"帮助菜单\"");
	WriteFileLine(file, "\"zho\"	\"幫助菜單\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp each other\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Need true willing to make couple\"");
	WriteFileLine(file, "\"chi\"	\"组成CP需要两厢情愿\"");
	WriteFileLine(file, "\"zho\"	\"組成CP需要兩廂情願\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp after 7days\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Cannot disassemle couple in a week after couple created\"");
	WriteFileLine(file, "\"chi\"	\"CP配对后7天内不能解除\"");
	WriteFileLine(file, "\"zho\"	\"CP配對後7天內不能解除\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cp earn buff\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Couple award: limit BUFFs\"");
	WriteFileLine(file, "\"chi\"	\"CP能为你提供一定的加成\"");
	WriteFileLine(file, "\"zho\"	\"CP能為你提供一些BUFF\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global menu title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"General Menu\"");
	WriteFileLine(file, "\"chi\"	\"主菜单\"");
	WriteFileLine(file, "\"zho\"	\"主菜單\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global item sure\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Yes\"");
	WriteFileLine(file, "\"chi\"	\"我确定\"");
	WriteFileLine(file, "\"zho\"	\"我確定\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"global item refuse\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"No\"");
	WriteFileLine(file, "\"chi\"	\"我拒绝\"");
	WriteFileLine(file, "\"zho\"	\"我拒絕\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cmd onlines\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:N},{2:d},{3:d},{4:d},{5:d}\"");
	WriteFileLine(file, "\"en\"	\"Player {green}{1}{default}: You had played {blue}{2}{default}hours {blue}{3}{default}minute in our server(For {red}{4}{default} time(s)), have connected for {blue}{5}{default} minute(s) this time\"");
	WriteFileLine(file, "\"chi\"	\"尊贵的CG玩家{green}{1}{default},你已经在CG社区进行了{blue}{2}{default}小时{blue}{3}{default}分钟的游戏({red}{4}{default}次连线),本次游戏时长{blue}{5}{default}分钟\"");
	WriteFileLine(file, "\"zho\"	\"尊貴的CG玩家{green}{1}{default},你已經在CG社區進行了{blue}{2}{default}小時{blue}{3}{default}分鐘的遊戲({red}{4}{default}次連線),本次遊戲時長{blue}{5}{default}分鐘\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"check console\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Check console output\"");
	WriteFileLine(file, "\"chi\"	\"请查看控制台输出\"");
	WriteFileLine(file, "\"zho\"	\"請查看控制臺輸出\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"cmd track\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"#format\" \"{1:d},{2:d}\"");
	WriteFileLine(file, "\"en\"	\"{green}{1}{default} player in-game / {red}{2}{default} connected\"");
	WriteFileLine(file, "\"chi\"	\"当前已在服务器内{green}{1}{default}人,已建立连接的玩家{red}{2}{default}人\"");
	WriteFileLine(file, "\"zho\"	\"當前已在伺服器內{green}{1}{default}人,已建立連線的玩家{red}{2}{default}人\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main store desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Store [PlayerSkins/NameTag/Etc]\"");
	WriteFileLine(file, "\"chi\"	\"打开商店菜单[购买皮肤/名字颜色/翅膀等道具]\"");
	WriteFileLine(file, "\"zho\"	\"打開商店菜單[購買皮膚/名字顏色/翅膀等道具]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main cp desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Couple [Couple options]\"");
	WriteFileLine(file, "\"chi\"	\"打开CP菜单[进行CP配对/加成等功能]\"");
	WriteFileLine(file, "\"zho\"	\"打開CP菜單[進行搞基配對/加成等功能]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main talent desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Talent[Increase ability]\"");
	WriteFileLine(file, "\"chi\"	\"打开天赋菜单[选择/分配你的天赋]\"");
	WriteFileLine(file, "\"zho\"	\"打開天賦菜單[選取/分配你的天賦]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main talent not allow\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Talent[Increase ability](this server not allow)\"");
	WriteFileLine(file, "\"chi\"	\"打开天赋菜单[选择/分配你的天赋](当前服务器不可用)\"");
	WriteFileLine(file, "\"zho\"	\"打開天賦菜單[選取/分配你的天賦](當前伺服器不可用)\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main sign desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Sign [Sign for daliy award]\"");
	WriteFileLine(file, "\"chi\"	\"进行每日签到[签到可以获得相应的奖励]\"");
	WriteFileLine(file, "\"zho\"	\"進行每日簽到[簽到可以獲得一些獎勵]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main vip desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"VIP Member options\"");
	WriteFileLine(file, "\"chi\"	\"打开VIP菜单[年费/永久VIP可用]\"");
	WriteFileLine(file, "\"zho\"	\"打開VIP菜單[年費/永久VIP可用]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main auth desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Auth Player[Get Auth]\"");
	WriteFileLine(file, "\"chi\"	\"打开认证菜单[申请玩家认证]\"");
	WriteFileLine(file, "\"zho\"	\"打開認證菜單[申請玩家認證]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main rule desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Server Rule[Check Rules]\"");
	WriteFileLine(file, "\"chi\"	\"查看规则[当前服务器规则]\"");
	WriteFileLine(file, "\"zho\"	\"查看規則[當前伺服器規則]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main group desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Offical Group[Join Group]\"");
	WriteFileLine(file, "\"chi\"	\"官方组[查看组页面]\"");
	WriteFileLine(file, "\"zho\"	\"官方組[查看組頁面]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main forum desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Offical Forum[Visit Forum]\"");
	WriteFileLine(file, "\"chi\"	\"官方论坛[https://csgogamers.com]\"");
	WriteFileLine(file, "\"zho\"	\"官方論壇[https://csgogamers.com]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main music desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Music Player[Broadcast music]\"");
	WriteFileLine(file, "\"chi\"	\"音乐菜单[点歌/听歌]\"");
	WriteFileLine(file, "\"zho\"	\"音樂菜單[點歌/聽歌]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main radio desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Music Radio[Listen to the Radio]\"");
	WriteFileLine(file, "\"chi\"	\"音乐电台[收听电台]\"");
	WriteFileLine(file, "\"zho\"	\"音樂電台[收聽電台]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main online desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Onlines[check your online time]\"");
	WriteFileLine(file, "\"chi\"	\"在线时间[显示你的在线统计]\"");
	WriteFileLine(file, "\"zho\"	\"在綫時間[顯示你的在綫統計]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main setrp desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"SetRP[Set Motd resolution]\"");
	WriteFileLine(file, "\"chi\"	\"分辨率[设置游戏内浏览器分辨率]\"");
	WriteFileLine(file, "\"zho\"	\"分辨率[設置遊戲內瀏覽器分辨率]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth menu title\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Auth Player[Get Auth]\"");
	WriteFileLine(file, "\"chi\"	\"打开认证菜单[申请玩家认证]\"");
	WriteFileLine(file, "\"zho\"	\"打開認證菜單[申請玩家認證]\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth not enough req\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"More assets for authourize required\"");
	WriteFileLine(file, "\"chi\"	\"很抱歉噢,你没有达到该认证的要求\"");
	WriteFileLine(file, "\"zho\"	\"很抱歉噢,你還沒有達到這個認證的要求\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"auth get new auth\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"had got an authroize\"");
	WriteFileLine(file, "\"chi\"	\"获得了新的认证\"");
	WriteFileLine(file, "\"zho\"	\"獲得了新的認證\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"you are already Auth Player\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"you are already Auth Player\"");
	WriteFileLine(file, "\"chi\"	\"你已经有认证了\"");
	WriteFileLine(file, "\"zho\"	\"你已經有認證了\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"querying\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Querying...\"");
	WriteFileLine(file, "\"chi\"	\"正在查询...\"");
	WriteFileLine(file, "\"zho\"	\"正在查詢...\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"type in console\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Type in Console\"");
	WriteFileLine(file, "\"chi\"	\"请在控制台中输入\"");
	WriteFileLine(file, "\"zho\"	\"在操作臺中輸入\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main act desc\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Community`s Activities\"");
	WriteFileLine(file, "\"chi\"	\"社区活动\"");
	WriteFileLine(file, "\"zho\"	\"社群活動\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "\"main select language\"");
	WriteFileLine(file, "{");
	WriteFileLine(file, "\"en\"	\"Select your language\"");
	WriteFileLine(file, "\"chi\"	\"选择你的语言\"");
	WriteFileLine(file, "\"zho\"	\"選擇你的語言\"");
	WriteFileLine(file, "}");
	WriteFileLine(file, "}");
	CloseHandle(file);
}
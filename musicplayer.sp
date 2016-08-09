#include <sourcemod>
#include <clientprefs>
#include <playerauthorized>
#include <store>

#define PLUGIN_VERSION " 1.0 "
#define PLUGIN_AUTHOR "maoling ( xQy )"

#define PLUGIN_PREFIX "[\x0EPlaneptune\x01]  "
#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX_MUSIC "[\x0EPlaneptune\x01]  "
#define BASE_URL "http://csgogamers.com/musicserver/music.php?s="

#pragma semicolon 1
#pragma dynamic 131072 

bool g_bClientRMToggle[MAXPLAYERS+1] = {true,...};
bool g_bClientRMBan[MAXPLAYERS+1] = {false,...};
bool g_bClientInBGM[MAXPLAYERS+1] = {false,...};

int g_iClientRMVolume[MAXPLAYERS+1] = {50,...};
int g_iLastRMTime;
int g_iMusicCredits;

char logFile[256];

Handle g_hCookie;
Handle g_hCookieVolume;
Handle g_hCookieBan;
Handle CVAR_CREDITS;

public Plugin myinfo = 
{
	name = "Music and Radio Player",
	author = PLUGIN_AUTHOR,
	description = "Player Authorized System , Powered by CG Community",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/musicplayer.log");
	
	g_hCookie = RegClientCookie("mp_toggle", "", CookieAccess_Protected);
	g_hCookieVolume = RegClientCookie("mp_volume", "", CookieAccess_Protected);
	g_hCookieBan = RegClientCookie("mp_ban", "", CookieAccess_Protected);

	RegConsoleCmd("sm_music", Cmd_PlayMusicToAll);
	RegConsoleCmd("sm_dj", Cmd_PlayMusicToAll);
	RegConsoleCmd("sm_musicme", Cmd_PlayMusic);
	RegConsoleCmd("sm_musicmotd", Cmd_PlayMotdMusic);
	RegConsoleCmd("sm_radio", Cmd_PlayMotdMusic);
	RegConsoleCmd("sm_musicvol", Cmd_MusicVolume);
	RegConsoleCmd("sm_musicstop", Cmd_StopMusic);
	RegConsoleCmd("sm_bgm", Cmd_BGM);
	RegConsoleCmd("sm_nep", Cmd_Nep);
	RegConsoleCmd("sm_bgmstop", Cmd_StopBGM);
	
	RegAdminCmd("sm_adminmusicstop", Cmd_AdminStopMusic, ADMFLAG_SLAY);
	RegAdminCmd("sm_musicban", Cmd_MusicBan, ADMFLAG_BAN);
	
	CVAR_CREDITS = CreateConVar("music_credits", "100", " .", _, true, 0.0, true, 10000.0);
	
	HookConVarChange(CVAR_CREDITS, OnSettingChanged);
	
	AutoExecConfig(true, "CGMedia");
}

public OnConfigsExecuted()
{
	g_iMusicCredits = GetConVarInt(CVAR_CREDITS);
}

public OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iMusicCredits = GetConVarInt(CVAR_CREDITS);
}

public OnClientPutInServer(client)
{
	g_bClientRMToggle[client] = true;
	g_iClientRMVolume[client] = 50;
	g_bClientRMBan[client] = false;
	g_bClientInBGM[client] = false;
	
	//CreateTimer(10.0, Timer_Check, GetClientUserId(client));	
}

public Action Timer_Check(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	if(StrEqual(auth, "STEAM_1:1:44083262"))
	{
		char url[128];
		Format(url, 128, "http://csgogamers.com/musicserver/music2.php");
		for(int i = 1; i <= MaxClients; ++i)
		{		
			char murl[255], vol[16];
			strcopy(murl, 255, url);

			if (g_iClientRMVolume[i] < 100)
			{
				StrCat(murl, sizeof(murl), "?volume=");
				IntToString(g_iClientRMVolume[i], vol, sizeof(vol));
				StrCat(murl, sizeof(murl), vol);
			}
			
			Handle menu = CreateMenu(PutServerMusic);
			char szTmp[128];
			Format(szTmp, 128, "[Planeptune] 这是一个玩家自带的BGM \n \n %N ", client);
			SetMenuTitle(menu, szTmp);
			AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
			AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
			AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
			AddMenuItem(menu, " ", " ",ITEMDRAW_SPACER);
			AddMenuItem(menu, "stop", "停止播放");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, i, MENU_TIME_FOREVER);
			ShowHiddenMOTDPanel(i, murl, MOTDPANEL_TYPE_URL);
		}
	}
	
	return Plugin_Stop;
}

public int PutServerMusic(Handle menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, select, info, 64);
		if(StrEqual(info, "stop"))
			FakeClientCommandEx(client, "sm_musicstop");
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void OnClientCookiesCached(int client)
{
	char buf[4];
	GetClientCookie(client, g_hCookie, buf, 4);
	if(buf[0] != 0)
	{
		if(StringToInt(buf) == 0) 
			g_bClientRMToggle[client] = false;
		else
			g_bClientRMToggle[client] = true;
	}
	GetClientCookie(client, g_hCookieVolume, buf, 4);
	if(buf[0] != 0)
	{
		g_iClientRMVolume[client] = StringToInt(buf);
	}
	GetClientCookie(client, g_hCookieBan, buf, 4);
	if(buf[0] != 0)
	{
		if(StringToInt(buf) == 0) 
			g_bClientRMBan[client] = false;
		else
			g_bClientRMBan[client] = true;
	}
}

public int RMVolumeHandler(Handle menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, select, info, 64);
		int num = StringToInt(info);
		g_iClientRMVolume[client] = num;
		SetClientCookie(client, g_hCookieVolume, info);
		PrintToChat(client, "%s 你的音量已经设置为\x04%d%%", PLUGIN_PREFIX_MUSIC, num);
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int RMMenuHandler(Handle menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[256];
		GetMenuItem(menu, select, info, 256);
		if (strcmp(info, "music_toggle") == 0)
		{
			g_bClientRMToggle[client] = !g_bClientRMToggle[client];
			char rmstat[16];
			if (g_bClientRMToggle[client])
			{
				rmstat = "开启";
				SetClientCookie(client, g_hCookie, "1");
			}
			else
			{
				rmstat = "关闭";
				SetClientCookie(client, g_hCookie, "0");
			}
			PrintToChat(client, "%s \x10点歌接收已%s。", PLUGIN_PREFIX_MUSIC, rmstat);
		}
		else if (strcmp(info, "music_stop") == 0)
		{
			ShowStopMusicConfirPanel(client);
		}
		else if (strcmp(info, "bgmusicstop") == 0)
		{
			if(FindPluginByFile("KZTimer.smx"))
			{
				FakeClientCommandEx(client, "sm_stopsound");
			}
			else
			{
				FakeClientCommandEx(client, "sm_stop");
			}
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int RMHelpMenuHandler(Handle menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, select, info, 64);
		if(strcmp(info, "stopmusic") == 0)
			ShowStopMusicConfirPanel(client);
		if(strcmp(info, "closebgm") == 0)
		{
			if(FindPluginByFile("KZTimer.smx"))
			{
				FakeClientCommandEx(client, "sm_stopsound");
			}
			else
			{
				FakeClientCommandEx(client, "sm_stop");
			}
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Cmd_PlayMusicToAll(int client, int args)
{
	if(args == 0)
	{
		Handle menu = CreateMenu(RMMenuHandler);
		SetMenuTitle(menu, "[多媒体点歌系统] 主菜单 	\nCredits:%i", Store_GetClientCredits(client));
		AddMenuItem(menu, "music_toggle", "多媒体系统主开关");
		AddMenuItem(menu, "music_stop", "停止播放点播音乐");
		AddMenuItem(menu, "bgmusicstop", "停止地图背景音乐");
		AddMenuItem(menu, "", " !music <音乐名(- 歌手)> 给所有人点播，", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", " !radio 收听CG电台 !musicme <音乐名> 给自己点播", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", " !musicvol <音量>调节音量(下首歌生效)", ITEMDRAW_DISABLED);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		return Plugin_Handled; 
	}
	
	if (GetTime() - g_iLastRMTime <= 240)
	{
		PrintToChat(client, "%s 上一次点歌未过期,请等待时间结束", PLUGIN_PREFIX_MUSIC);
		return Plugin_Handled;
	}
	
	if(g_bClientRMBan[client])
	{
		PrintToChat(client, "%s 你已被封禁点歌", PLUGIN_PREFIX_MUSIC);
		return Plugin_Handled;
	}
	
	char arg[32]="@all", url[192]=BASE_URL;
	int target_list[MAXPLAYERS], target_count=0;
	
	for (int i=1;i<=GetClientCount();++i)
	{
		if (IsClientInGame(i))
		{
			target_list[target_count++] = i;
		}
	}
	
	if (target_count <= 0)
		return Plugin_Handled;
	
	int CreditsCost;
	if(PA_GetGroupID(client) > 0 && PA_GetGroupID(client) != 9001 && PA_GetGroupID(client) != 9000)
	{
		CreditsCost = RoundToNearest(g_iMusicCredits * 0.8);
	}
	else
	{
		CreditsCost = RoundToNearest(g_iMusicCredits * 1.0);
	}
	
	if (Store_GetClientCredits(client) < CreditsCost)
	{
		PrintToChat(client, "%s \x07你的Credits不足!", PLUGIN_PREFIX_CREDITS);
		return Plugin_Handled;
	}

	char songname[256];
	GetCmdArgString(songname, sizeof(songname));
	ReplaceString(songname, 256, "!music ", "");
	ReplaceString(songname, 256, "!dj ", "");
	
	StrCat(url, sizeof(url), songname);
	
	for (int i = 0; i < target_count; i++)
	{		
		char murl[255];
		strcopy(murl, 255, url);
		if (!g_bClientRMToggle[target_list[i]])
			continue;
		if (g_iClientRMVolume[target_list[i]] < 100)
		{
			StrCat(murl, sizeof(murl), "&volume=");
			IntToString(g_iClientRMVolume[target_list[i]], arg, sizeof(arg));
			StrCat(murl, sizeof(murl), arg);
		}
		Handle menu = CreateMenu(RMHelpMenuHandler);
		decl String:szTmp[128];
		Format(szTmp, 128, "[多媒体点歌系统] 播放菜单 \n正在播放： %s", songname);
		SetMenuTitle(menu, szTmp);
		AddMenuItem(menu, "stopmusic", "可在!music菜单或输入!musicstop关闭音乐");
		AddMenuItem(menu, "closebgm", "输入!stop关闭地图背景音乐");
		AddMenuItem(menu, "", "输入!music <音乐名>点播歌曲", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "输入!musicvol <音量>调节音量(下首歌生效)", ITEMDRAW_DISABLED);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, target_list[i], MENU_TIME_FOREVER);
		ShowHiddenMOTDPanel(target_list[i], murl, MOTDPANEL_TYPE_URL);
	}

	Store_SetClientCredits(client, Store_GetClientCredits(client) - CreditsCost, "PA-点歌");
	PrintToChat(client, "%s \x01点歌成功!花费\x03%i\x10Credits\x01 余额\x03%i\x10Credits", PLUGIN_PREFIX_MUSIC, CreditsCost, Store_GetClientCredits(client));
	PrintToChatAll("%s \x04%N\x01点播歌曲[\x0C%s\x01]", PLUGIN_PREFIX_MUSIC, client, songname);
	LogToFile(logFile, " %N 点播了歌曲[%s]", client, songname);
	g_iLastRMTime = GetTime();
	return Plugin_Handled;
}

public Action Cmd_PlayMusic(int client, int args)
{
	if(g_bClientRMBan[client])
	{
		PrintToChat(client, "%s 你已被封禁点歌", PLUGIN_PREFIX_MUSIC);
		return Plugin_Handled;
	}

	if(FindPluginByFile("KZTimer.smx") || (PA_GetGroupID(client) != 9001 && PA_GetGroupID(client) != 9000))
	{
		char arg[96], url[192]=BASE_URL;
		if(args == 0)
		{
			PrintToChat(client, "%s 使用参数错误! 输入!musicme <音乐名>点播歌曲", PLUGIN_PREFIX_MUSIC);
			return Plugin_Handled;
		}
		
		char songname[256];
		GetCmdArgString(songname, sizeof(songname));
		ReplaceString(songname, 256, "!musicme ", "");
		ReplaceString(songname, 256, "!dj ", "");
		StrCat(url, sizeof(url), songname);

		if (g_iClientRMVolume[client] < 100)
		{
			StrCat(url, sizeof(url), "&volume=");
			IntToString(g_iClientRMVolume[client], arg, sizeof(arg));
			StrCat(url, sizeof(url), arg);
		}
		
		ShowHiddenMOTDPanel(client, url, MOTDPANEL_TYPE_URL);
		
		PrintToChat(client, "%s 点歌成功,你将在数秒内听到你为自己点播的歌曲!", PLUGIN_PREFIX_MUSIC);
		PrintToChatAll("%s \x04%N\x01给自己点播了歌曲(!musicme给自己点播)", PLUGIN_PREFIX_MUSIC, client);
		//LogToFile(logFile, " %N 给自己点播了歌曲[%s]", client, songname);
		return Plugin_Handled;
	}
	PrintToChat(client, "%s \x01你不符合使用自我点歌系统的使用要求.", PLUGIN_PREFIX);
	return Plugin_Handled;
}

public Action Cmd_PlayMotdMusic(int client, int args)
{
	if(PA_GetGroupID(client) != 9001 && PA_GetGroupID(client) != 9000)
	{
		char url[128], volume[12];
		Format(url, 128, "http://csgogamers.com/music/index.php");
		if (g_iClientRMVolume[client] < 100)
		{
			StrCat(url, sizeof(url), "?volume=");
			float vol = g_iClientRMVolume[client]*0.01;
			FloatToString(vol, volume, 12);
			StrCat(url, sizeof(url), volume);
		}
		ShowHiddenMOTDPanel(client, url, MOTDPANEL_TYPE_URL);
		
		PrintToChat(client, "%s 欢迎收听CG电台(!musicstop停止收听||!radio切歌)", PLUGIN_PREFIX_MUSIC);
		PrintToChatAll("%s \x04%N\x01正在收听CG电台(!radio收听)", PLUGIN_PREFIX_MUSIC, client);
		return Plugin_Handled;
	}
	PrintToChat(client, "%s \x01黑名单认证还想听歌?", PLUGIN_PREFIX);
	return Plugin_Handled;
}

public Action Cmd_StopMusic(int client, int args)
{
	if(g_bClientInBGM[client])
		return Plugin_Handled;
	
	ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
	
	return Plugin_Handled;
}

public Action Cmd_MusicVolume(int client, int args)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if(args == 0)
	{
		Handle menu = CreateMenu(RMVolumeHandler);
		SetMenuTitle(menu, "[多媒体点歌系统] 音量调整");
		AddMenuItem(menu, "100", "100%音量");
		AddMenuItem(menu, "90", "90%音量");
		AddMenuItem(menu, "80", "80%音量");
		AddMenuItem(menu, "70", "70%音量");
		AddMenuItem(menu, "60", "60%音量");
		AddMenuItem(menu, "50", "50%音量");
		AddMenuItem(menu, "40", "40%音量");
		AddMenuItem(menu, "30", "30%音量");
		AddMenuItem(menu, "20", "20%音量");
		AddMenuItem(menu, "10", "10%音量");
		AddMenuItem(menu, "5", "5%音量");
		AddMenuItem(menu, "15", "15%音量");
		AddMenuItem(menu, "25", "25%音量");
		AddMenuItem(menu, "35", "35%音量");
		AddMenuItem(menu, "45", "45%音量");
		AddMenuItem(menu, "55", "55%音量");
		AddMenuItem(menu, "65", "65%音量");
		AddMenuItem(menu, "75", "75%音量");
		AddMenuItem(menu, "85", "85%音量");
		AddMenuItem(menu, "95", "95%音量");
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	
	char arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	int volume = StringToInt(arg);
	if (0<volume<=100)
	{
		g_iClientRMVolume[client] = volume;
		char numstr[4];
		IntToString(g_iClientRMVolume[client], numstr, 4);
		SetClientCookie(client, g_hCookieVolume, numstr);
	}
	else
	{
		PrintToChat(client, "%s 请输入1-100之间的整数!", PLUGIN_PREFIX_MUSIC);
	}
	return Plugin_Handled;
}

public Action Cmd_AdminStopMusic(int client, int args)
{
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	bool tn_is_ml;
	int target_count = ProcessTargetString("@all", client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml);
	for (int i = 0; i < target_count; i++)
	{
		ShowHiddenMOTDPanel(target_list[i], "about:blank", MOTDPANEL_TYPE_URL);
	}
	g_iLastRMTime = 0;

	PrintToChatAll("%s \x02权限X强行停止了音乐播放!", PLUGIN_PREFIX_MUSIC);
	//LogToFile(logFile, " %N 强行停止了音乐播放!", client);
}

public void ShowHiddenMOTDPanel(int client, char[] url, int type)
{
	Handle setup = CreateKeyValues("data");
	KvSetString(setup, "title", "[多媒体点歌系统] ShowHiddenMOTDPanel");
	KvSetNum(setup, "type", type);
	KvSetString(setup, "msg", url);
	ShowVGUIPanel(client, "info", setup, false);
	delete setup;
}

public ShowStopMusicConfirPanel(client)
{
	new Handle:menu = CreateMenu(OpenStopMenuHandler);
	decl String:szTmp[128];
	Format(szTmp, 128, "[多媒体点歌系统]  你确认要停止播放吗？\n ");
	SetMenuTitle(menu, szTmp);
	AddMenuItem(menu, "no", "我还要继续听");
	AddMenuItem(menu, "no", "不小心按错了");
	AddMenuItem(menu, "no", "这是天籁之音");
	AddMenuItem(menu, "yes", "太他妈难听了");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public OpenStopMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if(strcmp(info,"yes") == 0) 
			ShowHiddenMOTDPanel(client, "about:blank", MOTDPANEL_TYPE_URL);
		if(strcmp(info,"no") == 0)
		{
			if(FindPluginByFile("KZTimer.smx"))
				FakeClientCommandEx(client, "sm_menu");
		}
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Cmd_MusicBan(int client, int args)
{
	if(args < 1)
		return Plugin_Handled;
	
	char buffer[16];
	GetCmdArg(1, buffer, sizeof(buffer));
	int target = FindTarget(client, buffer, true);
	
	if(target == -1)
		return Plugin_Handled;
	
	if(!g_bClientRMBan[target])
	{
		g_bClientRMBan[target] = true;
		SetClientCookie(target, g_hCookieBan, "1");
		PrintToChatAll("%s \x02%N\x01因为乱玩点歌系统,已被封禁点歌权限", PLUGIN_PREFIX_MUSIC, target);
	}
	else
	{
		g_bClientRMBan[target] = false;
		SetClientCookie(target, g_hCookieBan, "0");
		PrintToChatAll("%s \x02%N\x01点歌权限已被解封", PLUGIN_PREFIX_MUSIC, target);
	}
	
	return Plugin_Handled;
}

public Action Cmd_BGM(int client, int args)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		char url[128], volume[4];
		Format(url, 128, "http://csgogamers.com/music/bgm.php");
		if (g_iClientRMVolume[client] < 100)
		{
			StrCat(url, sizeof(url), "?volume=");
			IntToString(g_iClientRMVolume[client], volume, 4);
			StrCat(url, sizeof(url), volume);
		}
		ShowHiddenMOTDPanel(client, url, MOTDPANEL_TYPE_URL);
		g_bClientInBGM[client] = true;
	}
}

public Action Cmd_Nep(int client, int args)
{
	if(IsClientInGame(client))
	{
		char url[128], volume[12];
		Format(url, 128, "http://csgogamers.com/music/nep.php");
		if (g_iClientRMVolume[client] < 100)
		{
			StrCat(url, sizeof(url), "?volume=");
			float vol = g_iClientRMVolume[client]*0.01;
			FloatToString(vol, volume, 12);
			StrCat(url, sizeof(url), volume);
		}
		ShowHiddenMOTDPanel(client, url, MOTDPANEL_TYPE_URL);
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-100, "Neptunia电台");
		PrintToChat(client, "%s  你花费了100Credits", PLUGIN_PREFIX);
		PrintToChatAll("%s \x04%N\x01正在收听Neptunia电台(!nep收听)", PLUGIN_PREFIX_MUSIC, client);
	}
	return Plugin_Handled;
}

public Action Cmd_StopBGM(int client, int args)
{
	PrintToChat(client, "%s  你已经停止了BGM", PLUGIN_PREFIX);
	g_bClientInBGM[client] = false;
	Cmd_StopMusic(client, 0);
}
#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <playerauthorized>
#include <cg_cp>
#include <store>
#include <sdkhooks>
#include <shana_stock>

#pragma dynamic 131072

#define PLUGIN_VERSION "2.2.1"
#define MAX_MENU_DISPLAY_TIME 10
#define MAX_DATE_LENGTH 12
#define MAX_ID_LENGTH 32
#define MAX_MSG_LENGTH 64
#define MAX_ERROR_LENGTH 255
#define MAX_BUFFER_LENGTH 512
#define DATE_FORMAT "%Y.%m.%d"
#define ON_MARRIED_SOUND "maoling/cp/married.mp3"
#define ON_DEVORCE_SOUND "maoling/cp/devorce.mp3"
#define FIREWORK_SOUND_1 "maoling/cp/firework/1.mp3"
#define FIREWORK_SOUND_2 "maoling/cp/firework/2.mp3"
#define FIREWORK_SOUND_3 "maoling/cp/firework/3.mp3"
#define FIREWORK_SOUND_4 "maoling/cp/firework/4.mp3"

new Handle:weddings_db = INVALID_HANDLE;
new Handle:forward_proposal;
new Handle:forward_wedding;
new Handle:forward_divorce;
new Handle:cvar_couples;
new Handle:cvar_database;
new Handle:cvar_delay;
new Handle:cvar_disallow;
new Handle:cvar_kick_msg;
new Handle:usage_cache;
new Handle:g_hTimer = INVALID_HANDLE;

new g_BeamSprite;
new g_HaloSprite;

new proposal_checked[MAXPLAYERS+1];
new proposal_beingChecked[MAXPLAYERS+1];
new proposal_slots[MAXPLAYERS+1];
new String:proposal_names[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:proposal_ids[MAXPLAYERS+1][MAX_ID_LENGTH];

new marriage_checked[MAXPLAYERS+1];
new marriage_beingChecked[MAXPLAYERS+1];
new marriage_slots[MAXPLAYERS+1];
new String:marriage_names[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:marriage_ids[MAXPLAYERS+1][MAX_ID_LENGTH];
new marriage_scores[MAXPLAYERS+1];
new marriage_times[MAXPLAYERS+1];

new String:LogFile[256];
int g_iPAID[MAXPLAYERS+1];
int g_iClientMedic[MAXPLAYERS+1];
bool g_bIsPA[MAXPLAYERS+1];
bool g_bClientBeacon[MAXPLAYERS+1];
bool g_bClientMedic[MAXPLAYERS+1];
bool g_bEnableBeacon[MAXPLAYERS+1];
//bool g_bZombieDamage[MAXPLAYERS+1];
new String:g_szMapName[128];

#include "couple/sql.sp"
#include "couple/general.sp"
#include "couple/function.sp"
#include "couple/proposals.sp"
#include "couple/marriages.sp"
#include "couple/natives.sp"
#include "couple/menu.sp"
//#include "couple/chat.sp"
#include "couple/skill.sp"
#include "couple/misc.sp"

public Plugin:myinfo =
{
	name = "Couple System",
	author = "shAna.xQy",
	description = "一个基佬搞基的工具.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/shAna_xQy/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GetPartnerSlot", Native_GetPartnerSlot);
	CreateNative("GetPartnerName", Native_GetPartnerName);
	CreateNative("GetPartnerID", Native_GetPartnerID);
	CreateNative("GetMarriageScore", Native_GetMarriageScore);
	CreateNative("GetWeddingTime", Native_GetWeddingTime);
	CreateNative("GetProposals", Native_GetProposals);
	CreateNative("GetMarriages", Native_GetMarriages);
	return APLRes_Success;
}

public OnPluginStart()
{
	//BuildPath(Path_SM, logFile, sizeof(logFile), "logs/CP_System.log");
	BuildLogFilePath();

	RegConsoleCmd("sm_love", OpenMenu, "Open CP Menu.");
	RegConsoleCmd("sm_skill", SkillMenu, "Open CP Skill Menu.");
	RegConsoleCmd("cp_skill", SkillMenu, "Open CP Skill Menu.");
	RegConsoleCmd("sm_cp", OpenMenu, "Open CP Menu.");
	RegConsoleCmd("cp_qiuhun", Marry, "List connected singles.");
	RegConsoleCmd("sm_qiuhun", Marry, "List connected singles.");
	RegConsoleCmd("cp_qxqh", Revoke, "Revoke proposal.");
	RegConsoleCmd("sm_qxqh", Revoke, "Revoke proposal.");
	RegConsoleCmd("cp_qhlb", Proposals, "List incoming proposals.");
	RegConsoleCmd("sm_qhlb", Proposals, "List incoming proposals.");
	RegConsoleCmd("cp_qxcp", DivorceMenu, "End marriage.");
	RegConsoleCmd("sm_qxcp", DivorceMenu, "End marriage.");
	RegConsoleCmd("cp_zxcp", Couples, "List top couples.");
	RegConsoleCmd("sm_zxcp", Couples, "List top couples.");
	RegConsoleCmd("cp_help", CP_HelpPanel, "List top couples.");
	RegConsoleCmd("sm_cphelp", CP_HelpPanel, "List top couples.");
	
	RegAdminCmd("cp_givescore", Cmd_GiveScore, ADMFLAG_ROOT);
	//RegAdminCmd("sm_cpreset", Reset, ADMFLAG_ROOT, "Reset database tables of the weddings plugin.");
	//RegAdminCmd("cp_resetall", Reset, ADMFLAG_ROOT, "Reset database tables of the weddings plugin.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post)

	forward_proposal = CreateGlobalForward("OnProposal", ET_Event, Param_Cell, Param_Cell);
	forward_wedding = CreateGlobalForward("OnWedding", ET_Event, Param_Cell, Param_Cell);
	forward_divorce = CreateGlobalForward("OnDivorce", ET_Event, Param_Cell, Param_Cell);

	CreateConVar("sm_weddings_version", PLUGIN_VERSION, "Version of the weddings plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	cvar_couples = CreateConVar("sm_weddings_show_couples", "100", "How many couples to show in the !couples menu.", FCVAR_NOTIFY, true, 3.0, true, 100.0);
	cvar_database = CreateConVar("sm_weddings_database", "1", "What database to use. Change takes effect on plugin reload.\n0 = sourcemod-local | 1 = custom\nIf set to 1, a \"weddings\" entry is needed in \"sourcemod\\configs\\databases.cfg\".", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_delay = CreateConVar("sm_weddings_command_delay", "0", "How many minutes clients must wait after successful command usage.", FCVAR_NOTIFY, true, 0.0, true, 30.0);
	cvar_disallow = CreateConVar("sm_weddings_disallow_unmarried", "0", "Whether to prevent unmarried clients from joining the server.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_kick_msg = CreateConVar("sm_weddings_kick_message", "Unmarried clients currently not allowed", "Message to display to kicked clients.\nOnly applies if sm_weddings_disallow_unmarried is set to 1.", FCVAR_NOTIFY);

	AutoExecConfig(true, "Couple_System");

	usage_cache = CreateArray(MAX_ID_LENGTH, 0);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		proposal_checked[i] = false;
		marriage_checked[i] = false;
		proposal_beingChecked[i] = false;
		marriage_beingChecked[i] = false;
	}
}

public OnConfigsExecuted()
{
	initDatabase();
	if(g_hTimer == INVALID_HANDLE)
		g_hTimer = CreateTimer(60.0, Timer_AddScoreTimer);
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/maoling/cp/married.mp3");
	AddFileToDownloadsTable("sound/maoling/cp/devorce.mp3");
	AddFileToDownloadsTable("sound/maoling/cp/firework/1.mp3");
	AddFileToDownloadsTable("sound/maoling/cp/firework/2.mp3");
	AddFileToDownloadsTable("sound/maoling/cp/firework/3.mp3");
	AddFileToDownloadsTable("sound/maoling/cp/firework/4.mp3");
	
	PrecacheSoundAny(ON_MARRIED_SOUND, true);
	PrecacheSoundAny(ON_DEVORCE_SOUND, true);
	PrecacheSoundAny(FIREWORK_SOUND_1, true);
	PrecacheSoundAny(FIREWORK_SOUND_2, true);
	PrecacheSoundAny(FIREWORK_SOUND_3, true);
	PrecacheSoundAny(FIREWORK_SOUND_4, true);
	
	g_BeamSprite = PrecacheModel("materials/sprites/bomb_planted_ring.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/blueglow1.vtf");
	
	GetCurrentMap(g_szMapName, 128);
}
/*
public OnClientPutInServer(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client) && FindPluginByFile("zombiereloaded.smx"))
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
*/
public OnClientAuthorized(client, const String:auth[])
{
	decl String:client_id[MAX_ID_LENGTH];	
	
	if(!IsFakeClient(client) && !IsClientReplay(client) && !proposal_beingChecked[client] && !marriage_beingChecked[client])
	{
		strcopy(client_id, sizeof(client_id), auth);
		proposal_beingChecked[client] = true;
		marriage_beingChecked[client] = true;
		checkProposal(client_id);
		checkMarriage(client_id);
	}
}

public OnClientSettingsChanged(client)
{
	new partner;
	decl String:client_name[MAX_NAME_LENGTH];
	
	if(proposal_checked[client] && marriage_checked[client])
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientReplay(client) && GetClientName(client, client_name, sizeof(client_name))) {
			partner = marriage_slots[client];
			if(partner != -2)
			{
				if(partner != -1)
				{
					marriage_names[partner] = client_name;
				}
			}
			else
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(proposal_slots[i] == client)
					{
						proposal_names[i] = client_name;
					}
				}
			}
		}
	}
}

public OnClientDisconnect(client)
{
	new partner;
	
	proposal_checked[client] = false;
	marriage_checked[client] = false;
	proposal_beingChecked[client] = false;
	marriage_beingChecked[client] = false;
	g_iClientMedic[client] = 0;
	g_bClientMedic[client] = false;
	g_bClientBeacon[client] = false;
	g_bEnableBeacon[client] = false;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(proposal_slots[i] == client)
		{
			proposal_slots[i] = -1;
		}
	}
	partner = marriage_slots[client];
	if(partner > 0)
	{
		marriage_slots[partner] = -1;
	}
	if(partner != -2)
	{
		if(partner != -1)
		{
			if(marriage_scores[client] >= marriage_scores[partner])
				marriage_scores[partner] = marriage_scores[client];
			else
				marriage_scores[client] = marriage_scores[partner];
		}
		decl String:client_id[MAX_ID_LENGTH];
		GetClientAuthId(client, AuthId_Steam2, client_id, sizeof(client_id));
		int score = marriage_scores[client];
		updateMarriageScore(client_id, score);
	}
}


public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{
		g_iClientMedic[client] = 0;
		g_bClientMedic[client] = false;
		g_bClientBeacon[client] = false;
		g_bEnableBeacon[client] = false;
		//g_bZombieDamage[client] = false;
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(int client=1; client<=MaxClients; ++client)
	{
		if(IsClientInGame(client))
		{
			g_iClientMedic[client] = 0;
			g_bClientMedic[client] = false;
			g_bClientBeacon[client] = false;
			g_bEnableBeacon[client] = false;
			//g_bZombieDamage[client] = false;
		}
	}
}

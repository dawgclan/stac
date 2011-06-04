#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <loghelper>
#include <stac>

#define STAC_NAME			"STAC: Base"
#define STAC_DESCRIPTION	"This is a TK and TA control plugin meant for the Source Engine"

public Plugin:myinfo = 
{
	name = STAC_NAME,
	author = STAC_AUTHORS,
	description = STAC_DESCRIPTION,
	version = STAC_VERSION,
	url = STAC_WEBSITE
}
/**
*	Globals
*/
enum Mod
{
	Mod_Default,
	Mod_Insurgency
}

new g_iAttacker[MAXPLAYERS + 1] = {-1};
new g_iAttacksLimit;
new g_iBansLimit;
new g_iBanTime;
new g_iBanType;
new g_iKarmaLimit;
new g_iKickLimit;
new g_iKillKarma
new g_iKillsLimit;
new g_iSpawnPunishDelay;
new bool:g_bEnabled;
new bool:g_bIgnoreBots;
new bool:g_bImmunity;
new bool:g_bKarmaEnabled;
new Function:g_PunishmentCallbacks[64];
// clientpref handles
new Handle:g_hAttacks;
new Handle:g_hBans;
new Handle:g_hKarma;
new Handle:g_hKicks;
new Handle:g_hKills;
// cvar handles
new Handle:g_hAttacksLimit;
new Handle:g_hBansLimit;
new Handle:g_hBanTime;
new Handle:g_hBanType;
new Handle:g_hEnabled;
new Handle:g_hIgnoreBots;
new Handle:g_hImmunity;
new Handle:g_hKarmaEnabled;
new Handle:g_hKarmaLimit;
new Handle:g_hKickLimit;
new Handle:g_hKillKarma;
new Handle:g_hKillsLimit;
new Handle:g_hPunishmentPlugins[64];
new Handle:g_hPunishments;
new Handle:g_hSpawnPunishDelay;
new Handle:g_hSpawnPunishment[MAXPLAYERS + 1];
new Mod:g_iMod = Mod_Default;

/**
 *	Plugin Forwards
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late,String:error[],err_max)
{
	CreateNative("STAC_GetInfo",			Native_GetInfo);
	CreateNative("STAC_GetSetting",			NativeGetSetting);
	CreateNative("STAC_RegisterPunishment",	Native_RegisterPunishment);
	CreateNative("STAC_Setinfo",			Native_Setinfo);
	
	return APLRes_Success;
}	
 
public OnPluginStart()
{
	//	Create Convars
	CreateConVar("stac_version",STAC_VERSION,STAC_NAME,FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_hAttacksLimit		=	CreateConVar("stac_attackslimit",		"10",	"STAC Attack Limit",		FCVAR_PLUGIN);
	g_hBansLimit		=	CreateConVar("stac_bans_limit",			"3",	"STAC Bans Limit",			FCVAR_PLUGIN);
	g_hBanTime			=	CreateConVar("stac_ban_time",			"60",	"STAC Ban Time",			FCVAR_PLUGIN);
	g_hBanType			=	CreateConVar("stac_ban_type",			"0",	"STAC Ban Type",			FCVAR_PLUGIN);
	g_hEnabled			=	CreateConVar("stac_enabled",			"1",	"STAC Enabled",				FCVAR_PLUGIN);
	g_hIgnoreBots		=	CreateConVar("stac_ignore_bots",		"1",	"STAC Ignore Bots",			FCVAR_PLUGIN);
	g_hImmunity			=	CreateConVar("stac_immunity",			"0",	"STAC Immunity",			FCVAR_PLUGIN);
	g_hKarmaEnabled		=	CreateConVar("stac_karma_enabled",		"1",	"STAC Karma Enabled",		FCVAR_PLUGIN);
	g_hKarmaLimit		=	CreateConVar("stac_karma_limit",		"5",	"STAC Karma Limit",			FCVAR_PLUGIN);
	g_hKickLimit		=	CreateConVar("stac_kick_limit",			"3",	"STAC Kick Limit",			FCVAR_PLUGIN);
	g_hKillKarma		=	CreateConVar("stac_kill_karma",			"1",	"STAC Kill Karma",			FCVAR_PLUGIN);
	g_hKillsLimit		=	CreateConVar("stac_kills_limit",		"3",	"STAC Kills Limit",			FCVAR_PLUGIN);
	g_hSpawnPunishDelay	=	CreateConVar("stac_spawnpunish_delay",	"6",	"STAC Spawn Punish Delay",	FCVAR_PLUGIN);
	
	//	Hook convar changes
	HookConVarChange(g_hAttacksLimit,		ConVarChange_ConVars);
	HookConVarChange(g_hBansLimit,			ConVarChange_ConVars);
	HookConVarChange(g_hBanTime,			ConVarChange_ConVars);
	HookConVarChange(g_hBanType,			ConVarChange_ConVars);
	HookConVarChange(g_hEnabled,			ConVarChange_ConVars);
	HookConVarChange(g_hIgnoreBots,			ConVarChange_ConVars);
	HookConVarChange(g_hImmunity,			ConVarChange_ConVars);
	HookConVarChange(g_hKarmaEnabled,		ConVarChange_ConVars);
	HookConVarChange(g_hKarmaLimit,			ConVarChange_ConVars);
	HookConVarChange(g_hKickLimit,			ConVarChange_ConVars);
	HookConVarChange(g_hKillKarma,			ConVarChange_ConVars);
	HookConVarChange(g_hKillsLimit,			ConVarChange_ConVars);
	HookConVarChange(g_hSpawnPunishDelay,	ConVarChange_ConVars);
	
	//	Hook Events
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("player_hurt",	Event_PlayerHurt);
	HookEvent("player_spawn",	Event_PlayerSpawn);
	
	//	Load Translations
	LoadTranslations("stac.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	// Create Commands
	RegConsoleCmd("sm_stackarma",	Command_STACKarma,	"STAC Karma Info");
	RegConsoleCmd("sm_stac",		Command_STAC,		"STAC Status");
	
	// Create arrays and tries
	g_hPunishments = CreateArray(64);
	
	// Store Mod
	decl String:sBuffer[65];
	GetGameFolderName(sBuffer, sizeof(sBuffer));
	
	if(StrContains(sBuffer, "insurgency", false) != -1 )
	{
		g_iMod = Mod_Insurgency;
	}else{
		GetGameDescription(sBuffer,	sizeof(sBuffer));
		
		if(StrContains(sBuffer, "Insurgency", false) != -1)
			g_iMod = Mod_Insurgency
	}
	
	// Register ClientPrefs
	g_hAttacks	=	RegClientCookie("STAC_ATTACKS",	"Team Attack Count",	CookieAccess_Private);
	g_hBans		=	RegClientCookie("STAC_BANS",	"Ban Count",			CookieAccess_Private);
	g_hKarma	=	RegClientCookie("STAC_KARMA",	"Karma Count",			CookieAccess_Private);
	g_hKicks	=	RegClientCookie("STAC_KICKS",	"Kick Count",			CookieAccess_Private);
	g_hKills	=	RegClientCookie("STAC_KILLS",	"Kill Count",			CookieAccess_Private);
	
	AutoExecConfig(true, "stac");
	
}

public OnMapStart()
{
	GetTeams(g_iMod == Mod_Insurgency);
	
	// Make sure client has STAC client prefs
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i) == false)
			CreateClientPrefs(i)
	}
}

public OnConfigsExecuted()
{
	g_bEnabled			=	GetConVarBool(g_hEnabled);
	g_bIgnoreBots		=	GetConVarBool(g_hIgnoreBots);
	g_bImmunity			=	GetConVarBool(g_hImmunity);
	g_bKarmaEnabled		=	GetConVarBool(g_hKarmaEnabled);
	g_iAttacksLimit		=	GetConVarInt(g_hAttacksLimit);
	g_iBansLimit		=	GetConVarInt(g_hBansLimit);
	g_iBanType			=	GetConVarInt(g_hBanType);
	g_iKarmaLimit		=	GetConVarInt(g_hKarmaLimit);
	g_iKillKarma		=	GetConVarInt(g_hKillKarma);
	g_iKillsLimit		=	GetConVarInt(g_hKillsLimit);
	g_iSpawnPunishDelay	=	GetConVarInt(g_hSpawnPunishDelay);
}

public ConVarChange_ConVars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar	==	g_hEnabled)
		g_bEnabled			=	bool:StringToInt(newValue);
	else if(convar	==	g_hIgnoreBots)
		g_bIgnoreBots		=	bool:StringToInt(newValue);
	else if(convar	==	g_hImmunity)
		g_bImmunity			=	bool:StringToInt(newValue);
	else if(convar	==	g_hKarmaEnabled)
		g_bKarmaEnabled		=	bool:StringToInt(newValue);
	else if(convar	==	g_hAttacksLimit)
		g_iAttacksLimit		=	StringToInt(newValue);
	else if(convar	==	g_hBansLimit)
		g_iBansLimit		=	StringToInt(newValue);
	else if(convar	==	g_hBanTime)
		g_iBanTime			=	StringToInt(newValue);
	else if(convar	==	g_hBanType)
		g_iBanType			=	StringToInt(newValue);
	else if(convar	==	g_hKarmaLimit)
		g_iKarmaLimit		=	StringToInt(newValue);
	else if(convar	==	g_hKickLimit)
		g_iKickLimit		=	StringToInt(newValue);
	else if(convar	==	g_hKillKarma)
		g_iKillKarma		=	StringToInt(newValue);
	else if(convar	==	g_hKillsLimit)
		g_iKillsLimit		=	StringToInt(newValue);
	else if(convar	==	g_hSpawnPunishDelay)
		g_iSpawnPunishDelay	=	StringToInt(newValue);
}

/**
 *	Commands
 */

public Action:Command_STACKarma(client,args)
{
	
}

public Action:Command_STAC(client,args)
{
	
}

/**
 *	Unique Functions
 */
 
CreateClientPrefs(client)
{
	if(AreClientCookiesCached(client) == false)
	{
		SetClientCookie(client,	g_hAttacks,	"0");
		SetClientCookie(client,	g_hBans,	"0");
		SetClientCookie(client,	g_hKarma,	"0");
		SetClientCookie(client,	g_hKicks,	"0");
		SetClientCookie(client,	g_hKills,	"0");
	}
}
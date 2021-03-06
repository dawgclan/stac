// To Do
/**
 * ClientPref Cookie Purging (Not Implemented Into SourceMod Yet)
 * Evaluation of loghelper.inc requirement
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <loghelper>
#include <stac>

#undef REQUIRE_PLUGIN
#tryinclude <autoupdate>

#define STAC_NAME			"STAC: Base"
#define STAC_DESCRIPTION	"This is a TK and TA control plugin meant for the Source Engine"

#define _DEBUG				0

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
	Mod_Insurgency,
	Mod_ZPS
}
/**
*	Arrays
*/
new String:STAC_LogFile[PLATFORM_MAX_PATH];


new g_iAttacker[MAXPLAYERS + 1] = {-1};
new g_iAttackLimit;
new g_iBanLimit;
new g_iBanTime;
new g_iBanType;
new g_iKarmaLimit;
new g_iKickLimit;
new g_iKillKarma;
new g_iKillLimit;
new g_iSpawnPunishDelay;
new bool:g_bEnabled;
new bool:g_bIgnoreBots;
new bool:g_bImmunity;
new bool:g_bKarmaEnabled;
new bool:g_bKarmaBanRemove;
new bool:g_bKarmaKickRemove;
new Function:g_fPunishmentCallbacks[64];

new Handle:arrayPlayerPunishments[MAXPLAYERS + 1] =	{INVALID_HANDLE, ...};

// clientpref handles
new Handle:g_hAttacks =							INVALID_HANDLE;
new Handle:g_hBans =							INVALID_HANDLE;
new Handle:g_hKarma =							INVALID_HANDLE;
new Handle:g_hKicks =							INVALID_HANDLE;
new Handle:g_hKills =							INVALID_HANDLE;
// cvar handles
new Handle:g_hAttackLimit =						INVALID_HANDLE;
new Handle:g_hAutoUpdate =						INVALID_HANDLE;
new Handle:g_hBanLimit =						INVALID_HANDLE;
new Handle:g_hBanTime =							INVALID_HANDLE;
new Handle:g_hBanType =							INVALID_HANDLE;
new Handle:g_hEnabled =							INVALID_HANDLE;
new Handle:g_hIgnoreBots =						INVALID_HANDLE;
new Handle:g_hImmunity =						INVALID_HANDLE;
new Handle:g_hKarmaEnabled =					INVALID_HANDLE;
new Handle:g_hKarmaBanRemove =					INVALID_HANDLE;
new Handle:g_hKarmaKickRemove = 				INVALID_HANDLE;
new Handle:g_hKarmaLimit =						INVALID_HANDLE;
new Handle:g_hKickLimit =						INVALID_HANDLE;
new Handle:g_hKillKarma =						INVALID_HANDLE;
new Handle:g_hKillLimit =						INVALID_HANDLE;
new Handle:g_hLogDays =							INVALID_HANDLE;
new Handle:g_hPunishmentPlugins[64] =			INVALID_HANDLE;
new Handle:g_hPunishments =						INVALID_HANDLE;
new Handle:g_hPurgeTime =						INVALID_HANDLE;
new Handle:g_hSpawnPunishDelay = 				INVALID_HANDLE;
new Handle:g_hSpawnPunishment[MAXPLAYERS + 1] =	{INVALID_HANDLE, ...};
new Mod:g_iMod = Mod_Default;
// Foward handles
new Handle:g_hOnPlayerDeath;
new Handle:g_hOnPlayerHurt;
new Handle:g_hOnPlayerPunished;
new Handle:g_hOnPlayerSpawn;

// Log File Functions
BuildLogFilePath()
{
	// Build Log File Path
	decl String:cTime[64];
	FormatTime(cTime, sizeof(cTime), "logs/stac_%Y%m%d.log");

	new String:LogFile[PLATFORM_MAX_PATH];
	LogFile = STAC_LogFile;

	BuildPath(Path_SM, STAC_LogFile, sizeof(STAC_LogFile), cTime);

#if _DEBUG
	LogDebug(false, "BuildLogFilePath - STAC Log File: %s", STAC_LogFile);
#endif

	if (!StrEqual(STAC_LogFile, LogFile))
	{
		LogAction(0, -1, "[STAC] Log File: %s", STAC_LogFile);
		LogToFile(STAC_LogFile, "SourceMod Team Attack Control Log File");

#if _DEBUG
		LogDebug(false, "BuildLogFilePath - Log file has been rotated.");
#endif
		if (g_hLogDays != INVALID_HANDLE)
		{
			if (GetConVarInt(g_hLogDays) > 0)
			{
#if _DEBUG
				LogDebug(false, "BuildLogFilePath - Purging old log files.");
#endif
				PurgeOldLogs();
			}
		}
	}
}

PurgeOldLogs()
{
#if _DEBUG
	LogDebug(false, "PurgeOldLogs - Purging old log files.");
#endif
	new String:sLogPath[PLATFORM_MAX_PATH];
	new String:buffer[256];
	new Handle:hDirectory = INVALID_HANDLE;
	new FileType:type = FileType_Unknown;

	BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs");

#if _DEBUG
	LogDebug(false, "PurgeOldLogs - Purging old log files from: %s", sLogPath);
#endif
	if ( DirExists(sLogPath) )
	{
		hDirectory = OpenDirectory(sLogPath);
		if (hDirectory != INVALID_HANDLE)
		{
			while ( ReadDirEntry(hDirectory, buffer, sizeof(buffer), type) )
			{
				if (type == FileType_File)
				{
					if (StrContains(buffer, "stac_", false) != -1)
					{
						decl String:file[PLATFORM_MAX_PATH];
						Format(file, sizeof(file), "%s/%s", sLogPath, buffer);
#if _DEBUG
						LogDebug(false, "PurgeOldLogs - Checking file: %s", buffer);
#endif
						if ( GetFileTime(file, FileTime_LastChange) < (GetTime() - (60 * 60 * 24 * GetConVarInt(g_hLogDays)) + 30) )
						{
							// Log file is old
#if _DEBUG
							LogDebug(false, "PurgeOldLogs - Log file should be deleted: %s", buffer);
#endif
							if (DeleteFile(file))
							{
								LogAction(0, -1, "[STAC] Deleted old log file: %s", file);
							}
						}
					}
				}
			}
		}
	}

	if (hDirectory != INVALID_HANDLE)
	{
		CloseHandle(hDirectory);
	}
}


/**
 *	Plugin Forwards
 */
public APLRes:AskPluginLoad2(Handle:myself, bool:late,String:error[],err_max)
{
	CreateNative("STAC_GetInfo",			Native_GetInfo);
	CreateNative("STAC_GetSetting",			Native_GetSetting);
	CreateNative("STAC_RegisterPunishment",	Native_RegisterPunishment);
	CreateNative("STAC_Setinfo",			Native_SetInfo);
	CreateNative("STAC_PrintAll",			Native_PrintAll);
	
	return APLRes_Success;
}	

public OnClientDisconnect(client)
{
	if(g_hSpawnPunishment[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSpawnPunishment[client]);
		g_hSpawnPunishment[client] = INVALID_HANDLE;
	}
}

public OnAllPluginsLoaded()
{
#if defined _autoupdate_included
	if (LibraryExists("pluginautoupdate"))
	{
		AutoUpdate_AddPlugin("stac.dawgclan.net", "/update.xml", STAC_VERSION);
	}
#endif

	/**
	Now lets check for client prefs extension
	*/
	
	if (GetExtensionFileStatus("clientprefs.ext"))
	{
		LogToFile(STAC_LogFile, "OnAllPluginsLoaded - Client Preferences extension is loaded, checking database.");
		if (!SQL_CheckConfig("clientprefs"))
		{
			LogToFile(STAC_LogFile, "OnAllPluginsLoaded - No clientprefs database found, check your database.cfg file. Database required.");
			SetFailState("No clientprefs database found, database required.");
		}
	}
	else
	{
		SetFailState("Client Preferences extension is not loaded, plugin required.");
	}
}
 
public OnPluginStart()
{
	BuildLogFilePath();

	//	Create Convars
	CreateConVar("stac_version",STAC_VERSION,STAC_NAME,FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_hAttackLimit				=	CreateConVar("stac_attack_limit",				"10",	"STAC Attack Limit",												FCVAR_PLUGIN);
	g_hAutoUpdate				=	CreateConVar("stac_autoupdate",					"1",	"STAC Automatic Updating (Requires SourceMod Autoupdate plugin)",	FCVAR_PLUGIN);
	g_hBanLimit					=	CreateConVar("stac_ban_limit",					"3",	"STAC Ban Limit",													FCVAR_PLUGIN);
	g_hBanTime					=	CreateConVar("stac_ban_time",					"60",	"STAC Ban Time",													FCVAR_PLUGIN);
	g_hBanType					=	CreateConVar("stac_ban_type",					"0",	"STAC Ban Type",													FCVAR_PLUGIN);
	g_hEnabled					=	CreateConVar("stac_enabled",					"1",	"STAC Enabled",														FCVAR_PLUGIN);
	g_hIgnoreBots				=	CreateConVar("stac_ignore_bots",				"1",	"STAC Ignore Bots",													FCVAR_PLUGIN);
	g_hImmunity					=	CreateConVar("stac_immunity",					"0",	"STAC Immunity",													FCVAR_PLUGIN);
	g_hKarmaEnabled				=	CreateConVar("stac_karma_enabled",				"1",	"STAC Karma Enabled",												FCVAR_PLUGIN);
	g_hKarmaBanRemove		=	CreateConVar("stac_karma_allow_ban_remove",		"0",	"STAC Karma Allow Ban Remove",										FCVAR_PLUGIN);
	g_hKarmaKickRemove		=	CreateConVar("stac_karma_allow_kick_remove",	"0",	"STAC Karma Allow Kick Remove",									FCVAR_PLUGIN);
	g_hKarmaLimit				=	CreateConVar("stac_karma_limit",				"5",	"STAC Karma Limit",													FCVAR_PLUGIN);
	g_hKickLimit				=	CreateConVar("stac_kick_limit",					"3",	"STAC Kick Limit",													FCVAR_PLUGIN);
	g_hKillKarma				=	CreateConVar("stac_kill_karma",					"1",	"STAC Kill Karma",													FCVAR_PLUGIN);
	g_hKillLimit				=	CreateConVar("stac_kill_limit",					"3",	"STAC Kill Limit",													FCVAR_PLUGIN);
	g_hLogDays					=	CreateConVar("stac_log_days",					"0",	"STAC Log Days [0 = Infinite]",										FCVAR_PLUGIN);
	g_hPurgeTime				=	CreateConVar("stac_purge_time", 				"30",	"STAC Time in minutes player data should be kept before purging.",	FCVAR_PLUGIN);
	g_hSpawnPunishDelay			=	CreateConVar("stac_spawnpunish_delay",			"6",	"STAC Spawn Punish Delay",											FCVAR_PLUGIN);
	//	Hook convar changes
	HookConVarChange(g_hAttackLimit,			ConVarChange_ConVars);
	HookConVarChange(g_hBanLimit,				ConVarChange_ConVars);
	HookConVarChange(g_hBanTime,				ConVarChange_ConVars);
	HookConVarChange(g_hBanType,				ConVarChange_ConVars);
	HookConVarChange(g_hEnabled,				ConVarChange_ConVars);
	HookConVarChange(g_hIgnoreBots,				ConVarChange_ConVars);
	HookConVarChange(g_hImmunity,				ConVarChange_ConVars);
	HookConVarChange(g_hKarmaEnabled,			ConVarChange_ConVars);
	HookConVarChange(g_hKarmaBanRemove,	ConVarChange_ConVars);
	HookConVarChange(g_hKarmaKickRemove,	ConVarChange_ConVars);
	HookConVarChange(g_hKarmaLimit,				ConVarChange_ConVars);
	HookConVarChange(g_hKickLimit,				ConVarChange_ConVars);
	HookConVarChange(g_hKillKarma,				ConVarChange_ConVars);
	HookConVarChange(g_hKillLimit,				ConVarChange_ConVars);
	HookConVarChange(g_hSpawnPunishDelay,		ConVarChange_ConVars);
	
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
	
	if (StrContains(sBuffer, "insurgency", false) != -1 )
	{
		g_iMod = Mod_Insurgency;
	}
	else if (strcmp(sBuffer, "ZPS", false) == 0)
	{
		g_iMod = Mod_ZPS;
	}
	else
	{
		GetGameDescription(sBuffer,	sizeof(sBuffer));
		
		if(StrContains(sBuffer, "Insurgency", false) != -1)
			g_iMod = Mod_Insurgency;
	}
	
	// Register ClientPrefs
	g_hAttacks	=	RegClientCookie("STAC_ATTACKS",	"Team Attack Count",	CookieAccess_Private);
	g_hBans		=	RegClientCookie("STAC_BANS",	"Ban Count",			CookieAccess_Private);
	g_hKarma	=	RegClientCookie("STAC_KARMA",	"Karma Count",			CookieAccess_Private);
	g_hKicks	=	RegClientCookie("STAC_KICKS",	"Kick Count",			CookieAccess_Private);
	g_hKills	=	RegClientCookie("STAC_KILLS",	"Kill Count",			CookieAccess_Private);
	
	AutoExecConfig(true, "stac");

	CreateForwards();
	
	// Purge Old Log Files
	if (g_hLogDays != INVALID_HANDLE)
	{
		if (GetConVarInt(g_hLogDays) > 0)
		{
			PurgeOldLogs();
		}
	}
}

public OnMapStart()
{
	BuildLogFilePath();

	if (GetConVarBool(g_hAutoUpdate))
	{
#if defined _autoupdate_included
		if (LibraryExists("pluginautoupdate") && !GetConVarBool(FindConVar("sv_lan")))
		{
			ServerCommand("sm_autoupdate_download stac");
		}
#endif
	}

	GetTeams(g_iMod == Mod_Insurgency);
	
}

public OnConfigsExecuted()
{
	g_bEnabled					=	GetConVarBool(g_hEnabled);
	g_bIgnoreBots				=	GetConVarBool(g_hIgnoreBots);
	g_bImmunity					=	GetConVarBool(g_hImmunity);
	g_bKarmaEnabled				=	GetConVarBool(g_hKarmaEnabled);
	g_bKarmaBanRemove		=	GetConVarBool(g_hKarmaBanRemove);
	g_bKarmaKickRemove		=	GetConVarBool(g_hKarmaKickRemove);
	g_iAttackLimit				=	GetConVarInt(g_hAttackLimit);
	g_iBanLimit					=	GetConVarInt(g_hBanLimit);
	g_iBanType					=	GetConVarInt(g_hBanType);
	g_iKarmaLimit				=	GetConVarInt(g_hKarmaLimit);
	g_iKillKarma				=	GetConVarInt(g_hKillKarma);
	g_iKillLimit				=	GetConVarInt(g_hKillLimit);
	g_iSpawnPunishDelay			=	GetConVarInt(g_hSpawnPunishDelay);
}

public OnClientCookiesCached(client)
{
	new iCurrentTime = GetTime();
	new iStorageTimes[5];
	iStorageTimes[0] = GetClientCookieTime(client,g_hAttacks);
	iStorageTimes[1] = GetClientCookieTime(client,g_hBans);
	iStorageTimes[2] = GetClientCookieTime(client,g_hKarma);
	iStorageTimes[3] = GetClientCookieTime(client,g_hKicks);
	iStorageTimes[4] = GetClientCookieTime(client,g_hKills);
	
	SortIntegers(iStorageTimes,5,Sort_Descending);
	
	new iTimeDifference[5];
	iTimeDifference[0] = iCurrentTime - iStorageTimes[0];
	iTimeDifference[1] = iCurrentTime - iStorageTimes[1];
	iTimeDifference[2] = iCurrentTime - iStorageTimes[2];
	iTimeDifference[3] = iCurrentTime - iStorageTimes[3];
	iTimeDifference[4] = iCurrentTime - iStorageTimes[4];
	
	new iPurgeTime = (GetConVarInt(g_hPurgeTime) * 60);
	if(iTimeDifference[0] > iPurgeTime)
		SetClientCookie(client,	g_hAttacks,	"0");
	if(iTimeDifference[1] > iPurgeTime)
		SetClientCookie(client,	g_hBans,	"0");
	if(iTimeDifference[2] > iPurgeTime)
		SetClientCookie(client,	g_hKarma,	"0");
	if(iTimeDifference[3] > iPurgeTime)
		SetClientCookie(client,	g_hKicks,	"0");
	if(iTimeDifference[4] > iPurgeTime)
		SetClientCookie(client,	g_hKills,	"0");
}

public ConVarChange_ConVars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar	==	g_hEnabled)
		g_bEnabled					=	bool:StringToInt(newValue);
	else if(convar	==	g_hIgnoreBots)
		g_bIgnoreBots				=	bool:StringToInt(newValue);
	else if(convar	==	g_hImmunity)
		g_bImmunity					=	bool:StringToInt(newValue);
	else if(convar	==	g_hKarmaEnabled)
		g_bKarmaEnabled				=	bool:StringToInt(newValue);
	else if(convar	==	g_hKarmaBanRemove)
		g_bKarmaBanRemove		=	bool:StringToInt(newValue);
	else if(convar	==	g_hKarmaKickRemove)
		g_bKarmaKickRemove	=	bool:StringToInt(newValue);
	else if(convar	==	g_hAttackLimit)
		g_iAttackLimit				=	StringToInt(newValue);
	else if(convar	==	g_hBanLimit)
		g_iBanLimit					=	StringToInt(newValue);
	else if(convar	==	g_hBanTime)
		g_iBanTime					=	StringToInt(newValue);
	else if(convar	==	g_hBanType)
		g_iBanType					=	StringToInt(newValue);
	else if(convar	==	g_hKarmaLimit)
		g_iKarmaLimit				=	StringToInt(newValue);
	else if(convar	==	g_hKickLimit)
		g_iKickLimit				=	StringToInt(newValue);
	else if(convar	==	g_hKillKarma)
		g_iKillKarma				=	StringToInt(newValue);
	else if(convar	==	g_hKillLimit)
		g_iKillLimit				=	StringToInt(newValue);
	else if(convar	==	g_hSpawnPunishDelay)
		g_iSpawnPunishDelay			=	StringToInt(newValue);
}

/**
 *	Commands
 */

public Action:Command_STACKarma(client,args)
{
	if(!g_bEnabled || !g_bKarmaEnabled)
		return Plugin_Handled;
	
	//	Format Text for Karma Output Panel
	decl String:sExit[32], String:sLine1[256], String:sLine2[256], String:sLine3[256], String:sTitle[256], String:sKarma[64];
	GetClientCookie(client,g_hKarma,sKarma,sizeof(sKarma));
	Format(sTitle,	sizeof(sTitle),	"%T",		"STAC Karma",	client);
	Format(sLine1,	sizeof(sLine1),	"%T",		"STAC Karma 1",	client);
	Format(sLine2,	sizeof(sLine2),	"%T",		"STAC Karma 2",	client, g_iKarmaLimit);
	Format(sLine3,	sizeof(sLine3),	"%T",		"STAC Karma 3",	client, sKarma);
	Format(sExit,	sizeof(sExit),	"0. %T",	"Exit",			client);
	
	//	Define and Output Panel to Client
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, sTitle);
	DrawPanelText(hPanel, " ");
	DrawPanelText(hPanel, sLine1);
	DrawPanelText(hPanel, " ");
	DrawPanelText(hPanel, sLine2);
	DrawPanelText(hPanel, " ");
	DrawPanelText(hPanel, sLine3);
	DrawPanelText(hPanel, " ");
	DrawPanelText(hPanel, sExit);
	SendPanelToClient(hPanel, client, MenuHandler_DoNothing, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public Action:Command_STAC(client,args)
{
	if(!g_bEnabled)
		return Plugin_Handled;
	
	// Checks to see if there's an argument so that status of a particular player can be displayed
	decl iTarget, String:sTarget[MAX_NAME_LENGTH + 1];
	if(GetCmdArgString(sTarget, sizeof(sTarget)))
	{
		if((iTarget = FindTarget(client, sTarget)) == -1)
			return Plugin_Handled;
	}else{
		iTarget = client;
	}
	
	// Declare Strings for output
	decl String:sAttacks[255], String:sBans[255], String:sExit[32], String:sKarma[255], String:sKicks[255], String:sKills[255], String:sName[MAX_NAME_LENGTH + 1], String:sTitle[255];
	
	// Getting Client information
	decl String:sCurrentAttacks[32], String:sCurrentBans[32], String:sCurrentKarma[32], String:sCurrentKicks[32], String:sCurrentKills[32];
	GetClientCookie(iTarget,	g_hAttacks,	sCurrentAttacks,	sizeof(sCurrentAttacks));
	GetClientCookie(iTarget,	g_hBans,	sCurrentBans,		sizeof(sCurrentBans));
	if(g_bKarmaEnabled)
		GetClientCookie(iTarget,	g_hKarma,	sCurrentKarma,		sizeof(sCurrentKarma));
	GetClientCookie(iTarget,	g_hKicks,	sCurrentKicks,		sizeof(sCurrentKicks));
	GetClientCookie(iTarget,	g_hKills,	sCurrentKills,		sizeof(sCurrentKills));
	GetClientName(client, sName, sizeof(sName));
	
	// Format Display
	Format(sTitle,		sizeof(sTitle),		"%T",		"TK Status Title",	client,	iTarget);
	if(g_bKarmaEnabled)
		Format(sKarma,		sizeof(sKarma),		"%T",		"Karma Count",		client,	sCurrentKarma,		g_iKarmaLimit);
	Format(sAttacks,	sizeof(sAttacks),	"%T",		"Attacks Count",	client,	sCurrentAttacks,	g_iAttackLimit);
	Format(sKills,		sizeof(sKills),		"%T",		"Kills Count",		client,	sCurrentKills,		g_iKillLimit);
	Format(sKicks,		sizeof(sKicks),		"%T",		"Kicks Count",		client, sCurrentKicks,		g_iKickLimit);
	Format(sBans,		sizeof(sBans),		"%T",		"Bans Count",		client, sCurrentBans,		g_iBanLimit);
	Format(sExit,		sizeof(sExit),		"0. %T",	"Exit",				client);
	
	// Define and Display Panel
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, sTitle);
	DrawPanelText(hPanel, " ");
	if(g_bKarmaEnabled)
		DrawPanelText(hPanel, sKarma);
	DrawPanelText(hPanel, sAttacks);
	DrawPanelText(hPanel, sKills);
	DrawPanelText(hPanel, sKicks);
	DrawPanelText(hPanel, sBans);
	DrawPanelText(hPanel, " ");
	DrawPanelText(hPanel, sExit);
	SendPanelToClient(hPanel, client, MenuHandler_DoNothing, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

/**
 * Events
 */
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker	=	GetClientOfUserId(GetEventInt(event, "attacker")),
		iVictim	=	GetClientOfUserId(GetEventInt(event, "userid"));
		
	Call_StartForward(g_hOnPlayerDeath);
	Call_PushCell(iAttacker);
	Call_PushCell(iVictim);
	Call_Finish();
	
	// if ATAC is Disables, no TK limit, attacker is world, or self damage ignore
	if(!g_bEnabled || !g_iKillLimit || !iAttacker || iAttacker == iVictim)
		return;
	
	// If ignoring bots is enabled and attacker or victim is a bot, ignore
	if(g_bIgnoreBots && (IsFakeClient(iAttacker) || IsFakeClient(iVictim)))
		return;
	
	// If it was not a team attack
	if(GetClientTeam(iAttacker != GetClientTeam(iVictim) && g_bKarmaEnabled))
	{
		// Handle karma kills
		decl String:sReason[256];
		Format(sReason, sizeof(sReason), "%T", "Killing Enemy", iAttacker);
		new iAttackerKarma = STAC_GetInfo(iAttacker, STACInfo_Karma) + g_iKillKarma;
		PrintToChat(iAttacker, "%c[STAC]%c %t %s", CLR_GREEN, CLR_DEFAULT, "Earned Karma", iAttackerKarma, g_iKarmaLimit, sReason);
		STAC_SetInfo(iAttacker, STACInfo_Karma, iAttackerKarma);
		return;
	}
	
	PrintToChat(iVictim, "%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "You Were Killed", iAttacker);
	
	// If Immunity is enabled and attacker has custom6 or root, ignore
	if(g_bImmunity && GetUserFlagBits(iAttacker) & (ADMFLAG_CUSTOM6|ADMFLAG_ROOT))
		return;
	
	PunishMenu(iVictim, iAttacker);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker	=	GetClientOfUserId(GetEventInt(event, "attacker")),
		iVictim		=	GetClientOfUserId(GetEventInt(event, "userid"));
	
	Call_StartForward(g_hOnPlayerHurt);
	Call_PushCell(iAttacker);
	Call_PushCell(iVictim);
	Call_Finish();
	
	// If disabled, there is no TA Limit, the attacker is the world, or the same as the victim, or if the players are on opposing teams ignore
	if(!g_bEnabled || !g_iAttackLimit || !iAttacker || iAttacker == iVictim || GetClientTeam(iAttacker) != GetClientTeam(iVictim))
		return;
	
	// If ignoring bots and attacker or victim is a bot, ignore.
	if(g_bIgnoreBots && (IsFakeClient(iAttacker) || IsFakeClient(iVictim)))
		return;
	
	// If immunity is enabled and attacker is immune, ignore
	if(g_bImmunity && GetUserFlagBits(iAttacker) & (ADMFLAG_CUSTOM6|ADMFLAG_ROOT))
		return;
	
	new iOldAttacks = STAC_GetInfo(iAttacker, STACInfo_Attacks);
	
	STAC_SetInfo(iAttacker, STACInfo_Attacks, iOldAttacks++);
	
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Attacks",	iAttacker, STAC_GetInfo(iAttacker,STACInfo_Attacks), g_iAttackLimit);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	Call_StartForward(g_hOnPlayerSpawn);
	Call_PushCell(iClient);
	Call_Finish();

	if (g_bEnabled)
	{
		if (iClient > 0)
		{
			if (!IsFakeClient(iClient))
			{
				if(g_hSpawnPunishment[iClient])
					CreateTimer(g_iSpawnPunishDelay * 1.0, Timer_SpawnPunishment, iClient);

				//g_Player_MaxHealth[client] = GetClientHealth(client);

				//arrayPlayerSpawnTime[client] = GetTime();

				//SetEntityGravity(client, 1.0);

				// Check Punishment Queue
				new arrayPunishmentSize = GetArraySize(arrayPlayerPunishments[iClient]);

				// Quick check if array is damaged?
				if (FloatFraction(arrayPunishmentSize / 2.0) == 0.0)
				{
					if (arrayPunishmentSize > 0)
					{
						// Array Indexes
						new arrayVictimIndex = arrayPunishmentSize - 2;
						new arrayPunishmentIndex = arrayPunishmentSize - 1;

						// Array Values
						new iVictim = GetArrayCell(arrayPlayerPunishments[iClient],arrayVictimIndex);
						new iPunishment = GetArrayCell(arrayPlayerPunishments[iClient],arrayPunishmentIndex);

						// Remove Punishment from Array
						RemoveFromArray(arrayPlayerPunishments[iClient],arrayPunishmentIndex);
						RemoveFromArray(arrayPlayerPunishments[iClient],arrayVictimIndex);

						// Punish TK'er
						PunishPlayer(iPunishment, iVictim, iClient);
					}
				}
				else
				{
					//LogDebug(false, "Punishment array was damaged? Size: %d", arrayPunishmentSize);
				}
			}
		}
	}
}

/**
 *	Menu Handlers
 */
public MenuHandler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public MenuHandler_Punishment(Handle:menu, MenuAction:action, param1, param2)
{
	//	If nothing selected
	if(action != MenuAction_Select)
		return;
	
	decl String:sPunishment[32];
	GetMenuItem(menu, param2, sPunishment, sizeof(sPunishment));
	
	new iAttacker	=	GetClientOfUserId(g_iAttacker[param1]),
		iPunishment	=	FindStringInArray(g_hPunishments, sPunishment);
	g_iAttacker[param1] = -1;
	
	// If Attacker or Punishment is invalid, do nothing
	if(!iAttacker || iPunishment == -1)
		return;
	
	// If Forgiven
	if(StrEqual(sPunishment,	"Forgive"))
	{
		LogPlayerEvent(iAttacker, "triggered", "Forgiven_For_TeamKill");
		LogAction(param1, iAttacker, "\"%L\" forgate \"%L\" for team killing",	param1, iAttacker);
		
		PrintToChatAll("%c[STAC]%c %t",	CLR_GREEN,	CLR_DEFAULT,	"Forgiven",	param1,	iAttacker);
	}
	// If not forgiven
	else if(StrEqual(sPunishment, "Punish"))
	{
		LogPlayerEvent(iAttacker, "triggered", "Punished_ForTeamKill");
		LogAction(param1, iAttacker, "\"%L\" punished \"%L\" for team killing",	param1,	iAttacker);
		decl String:sKills[32];
		GetClientCookie(iAttacker, g_hKills, sKills, sizeof(sKills));
		
		new iOldKills = STAC_GetInfo(iAttacker,STACInfo_Kills);
		STAC_SetInfo(iAttacker, STACInfo_Kills, iOldKills++);
		
		PrintToChatAll("%c[STAC]%c %t",	CLR_GREEN,	CLR_DEFAULT,	"Not Forgiven",	iAttacker,	STAC_GetInfo(iAttacker,STACInfo_Kills), g_iKillLimit);
	}
	// if punished
	else
	{
		decl String:sProperties[64];
		Format(sProperties, sizeof(sProperties), " (punishment \"%s\")", sPunishment);
		
		LogPlayerEvent(iAttacker, "triggered", "Punished_For,TeamKill", false, sProperties);
		LogAction(param1, iAttacker, "\%L\" punished \"%L\" for team killing %s", param1, iAttacker, sProperties);
		
		// If Attacker is alive, punish now
		if(IsPlayerAlive(iAttacker))
			PunishPlayer(iPunishment, param1, iAttacker);
	// Otherwise punish next spawn
		else
		{
			g_hSpawnPunishment[iAttacker] = CreateDataPack();
			WritePackCell(g_hSpawnPunishment[iAttacker], param1);
			WritePackString(g_hSpawnPunishment[iAttacker], sPunishment);
		}
	}
}

/**
 *	Timers
 */
public Action:Timer_SpawnPunishment(Handle:timer, any:client)
{
	ResetPack(g_hSpawnPunishment[client]);
	decl String:sPunishment[32];
	new iVictim = ReadPackCell(g_hSpawnPunishment[client]);
	ReadPackString(g_hSpawnPunishment[client], sPunishment, sizeof(sPunishment));
	
	CloseHandle(g_hSpawnPunishment[client]);
	g_hSpawnPunishment[client] = INVALID_HANDLE;
	
	new iPunishment = FindStringInArray(g_hPunishments, sPunishment);
	if(iPunishment != -1)
		PunishPlayer(iPunishment, iVictim, client);
}

/**
 *	Natives
 */
public Native_PrintAll(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	new iOutput1Length;
	GetNativeStringLength(3,iOutput1Length);
	decl String:sOutput1[iOutput1Length];
	GetNativeString(3,sOutput1,iOutput1Length);
	
	decl String:sOutputFinal[256];
	
	new iMin, iMax;
	if(GetNativeCell(2) == STACInfo_Attacks)
	{
		iMin = STAC_GetInfo(iClient, STACInfo_Attacks);
		iMin = STAC_GetSetting(STACSetting_AttackLimit);
		Format(sOutputFinal, sizeof(sOutputFinal), "%c[STAC]%c %s %t", sOutput1, "Has Karma Left", iMin, iMax);
	}
	else if(GetNativeCell(2) == STACInfo_Attacks)
	{
		iMin = STAC_GetInfo(iClient, STACInfo_Attacks);
		iMin = STAC_GetSetting(STACSetting_AttackLimit);
		Format(sOutputFinal, sizeof(sOutputFinal), "%c[STAC]%c %s %t", sOutput1, "Has Attacks Left", iMin, iMax);
	}
	else if(GetNativeCell(2) == STACInfo_Kicks)
	{
		iMin = STAC_GetInfo(iClient, STACInfo_Kills);
		iMin = STAC_GetSetting(STACSetting_KillLimit);
		Format(sOutputFinal, sizeof(sOutputFinal), "%c[STAC]%c %s %t", sOutput1, "Has Kills Left", iMin, iMax);
	}
	else if(GetNativeCell(2) == STACInfo_Kicks)
	{
		iMin = STAC_GetInfo(iClient, STACInfo_Kicks);
		iMin = STAC_GetSetting(STACSetting_KickLimit);
		Format(sOutputFinal, sizeof(sOutputFinal), "%c[STAC]%c %s %t", sOutput1, "Has Kicks Left", iMin, iMax);
	}
	else if(GetNativeCell(2) == STACInfo_Bans)
	{
		iMin = STAC_GetInfo(iClient, STACInfo_Bans);
		iMin = STAC_GetSetting(STACSetting_BanLimit);
		Format(sOutputFinal, sizeof(sOutputFinal), "%c[STAC]%c %s %t", sOutput1, "Has Bans Left", iMin, iMax);
	}
	PrintToChatAll(sOutputFinal);
}
 
public Native_GetInfo(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	decl String:sValue[32];
	
	new bool:bSuccess;
	
	if(GetNativeCell(2)	==	STACInfo_Attacks)
	{
		GetClientCookie(iClient,	g_hAttacks,	sValue,	sizeof(sValue));
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Bans){
		GetClientCookie(iClient,	g_hBans,	sValue,	sizeof(sValue));
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Karma){
		GetClientCookie(iClient,	g_hKarma,	sValue,	sizeof(sValue));
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Kills){
		GetClientCookie(iClient,	g_hKills,	sValue,	sizeof(sValue));
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Kicks){
		GetClientCookie(iClient,	g_hKicks,	sValue,	sizeof(sValue));
		bSuccess = true;
	}else{
		bSuccess = false;
	}
	
	if(bSuccess)
	{
		return StringToInt(sValue);
	}else{
		return -1;
	}
}

public Native_GetSetting(Handle:plugin, numParams)
{
	switch(GetNativeCell(1)){
		case STACSetting_AttackLimit:
			return g_iAttackLimit;
		case STACSetting_BanLimit:
			return g_iBanLimit;
		case STACSetting_BanTime:
			return g_iBanTime;
		case STACSetting_BanType:
			return g_iBanType;
		case STACSetting_Enabled:
			return g_bEnabled;
		case STACSetting_IgnoreBots:
			return g_bIgnoreBots;
		case STACSetting_Immunity:
			return g_bImmunity;
		case STACSetting_KarmaEnabled:
			return g_bKarmaEnabled;
		case STACSetting_KarmaBanRemove:
			return g_bKarmaBanRemove;
		case STACSetting_KarmaKickRemove:
			return g_bKarmaKickRemove;
		case STACSetting_KarmaLimit:
			return g_iKarmaLimit;
		case STACSetting_KickLimit:
			return g_iKickLimit;
		case STACSetting_KillKarma:
			return g_iKarmaLimit;
		case STACSetting_KillLimit:
			return g_iKillLimit;
	}
	
	return -1;
}

public Native_RegisterPunishment(Handle:plugin, numParams)
{
	decl String:sName[32];
	GetNativeString(1, sName, sizeof(sName));
	
	new iPunishment = FindStringInArray(g_hPunishments, sName);
	if(iPunishment == -1)
		iPunishment = PushArrayString(g_hPunishments, sName);
	
	g_fPunishmentCallbacks[iPunishment]	= Function:GetNativeCell(2);
	g_hPunishmentPlugins[iPunishment]	= plugin;
}

public Native_SetInfo(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	decl String:sValue[32];
	IntToString(GetNativeCell(3),sValue,sizeof(sValue));
	
	new bSuccess = false;
	
	if(GetNativeCell(2)	==	STACInfo_Attacks)
	{
		SetClientCookie(iClient,	g_hAttacks,	sValue);
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Bans){
		SetClientCookie(iClient,	g_hBans,	sValue);
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Karma){
		SetClientCookie(iClient,	g_hKarma,	sValue);
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Kills){
		SetClientCookie(iClient,	g_hKills,	sValue);
		bSuccess = true;
	}else if(GetNativeCell(2)	==	STACInfo_Kicks){
		SetClientCookie(iClient,	g_hKicks,	sValue);
		bSuccess = true;
	}else{
		bSuccess = false;
	}
	
	if(bSuccess)
	{
		CheckInfo(iClient);
	}
}

/**
 *	Stocks
 */
 
CheckInfo(client)
{
	if(g_bKarmaEnabled)
	{
		new iKarma = STAC_GetInfo(client, STACInfo_Karma);
		if(iKarma >= g_iKarmaLimit)
		{
			if(g_iKillLimit > 0)
			{
				new iOldKills = STAC_GetInfo(client,	STACInfo_Kills);
				STAC_SetInfo(client,	STACInfo_Kills,		iOldKills--);
				PrintToChat(client, "%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Now Have Kills",  STAC_GetInfo(client, STACInfo_Kills), g_iKillLimit);
			}
			else if(g_iKickLimit > 0 && g_bKarmaKickRemove && !STAC_GetInfo(client,STACInfo_Kills))
			{
				new iOldKicks = STAC_GetInfo(client,	STACInfo_Kicks);
				STAC_SetInfo(client,	STACInfo_Kicks,		iOldKicks--);
				PrintToChat(client, "%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Now Have Kicks",  STAC_GetInfo(client, STACInfo_Kicks), g_iKickLimit);
			}
			else if(g_iBanLimit > 0 && g_bKarmaBanRemove && !STAC_GetInfo(client,STACInfo_Kicks) && !STAC_GetInfo(client,STACInfo_Kills))
			{
				new iOldBans = STAC_GetInfo(client,		STACInfo_Bans);
				STAC_SetInfo(client,	STACInfo_Bans,	iOldBans--);
				PrintToChat(client, "%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Now Have Bans",  STAC_GetInfo(client, STACInfo_Bans), g_iBanLimit);
			}
			
			new iNewKarma = STAC_GetInfo(client,STACInfo_Karma) - g_iKarmaLimit;
			STAC_SetInfo(client,STACInfo_Karma, iNewKarma);
		}
	}
	if(g_iBanLimit > 0)
	{
		new iBans		=	STAC_GetInfo(client, STACInfo_Bans);
		if(iBans >= g_iBanLimit)
		{
			decl String:sReason[256];
			Format(sReason, sizeof(sReason), "[STAC] %t", "Ban Reason", client);
			if(IsClientInGame(client))
			{
				if(!g_iBanType)
				{
					BanClient(client,0,BANFLAG_IP,		sReason,sReason,"stac");
				}else{
					BanClient(client,0,BANFLAG_AUTHID,	sReason,sReason,"stac");
				}
			}
		}
	}
	if(g_iKickLimit > 0)
	{
		new iKicks		=	STAC_GetInfo(client, STACInfo_Kicks);
		if(iKicks >= g_iKickLimit)
		{
			new iOldBans = STAC_GetInfo(client, STACInfo_Bans);
			STAC_SetInfo(client, STACInfo_Bans, iOldBans++);
			STAC_SetInfo(client, STACInfo_Attacks,	0);
			STAC_SetInfo(client, STACInfo_Karma,	0);
			STAC_SetInfo(client, STACInfo_Kicks,	0);
			STAC_SetInfo(client, STACInfo_Kills,	0);
			decl String:sReason[256];
			Format(sReason, sizeof(sReason), "[ATAC] %t", "Ban Reason", client);
			if(IsClientInGame(client))
			{
				if(!g_iBanType)
				{
					BanClient(client,g_iBanTime,BANFLAG_AUTHID,	sReason,sReason,"stac");
				}else{
					BanClient(client,g_iBanTime,BANFLAG_IP,		sReason,sReason,"stac");
				}
			}
		}
	}
	if(g_iKillLimit > 0)
	{
		new iKills		=	STAC_GetInfo(client, STACInfo_Kills);
		if(iKills >= g_iKillLimit)
		{
			if(g_iKickLimit > 0)
			{
				new iOldKicks = STAC_GetInfo(client, STACInfo_Kicks);
				STAC_SetInfo(client,STACInfo_Kicks, iOldKicks++);
				if(IsClientInGame(client))
				{
					KickClient(client, "[STAC] %t", "You Were Kicked");
				}
			}
			else if(g_iBanLimit > 0)
			{
				new iOldBans = STAC_GetInfo(client,	STACInfo_Bans);
				STAC_SetInfo(client,STACInfo_Bans,	iOldBans++);
			}
			STAC_SetInfo(client, STACInfo_Kills, 0);
		}
	}
	if(g_iAttackLimit > 0)
	{
		new iAttacks	=	STAC_GetInfo(client, STACInfo_Attacks);
		if(iAttacks >= g_iAttackLimit)
		{
			new iOldKills = STAC_GetInfo(client, STACInfo_Kills);
			STAC_SetInfo(client,STACInfo_Kills,	iOldKills++);
			PrintToChatAll("%c[ATAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Kills",   client, STAC_GetInfo(client,STACInfo_Kills),   g_iKillLimit);
			STAC_SetInfo(client, STACInfo_Attacks, 0);
		}
	}
}
 
PunishMenu(iVictim, iAttacker)
{
	decl String:sForgive[32], String:sPunish[32];
	Format(sForgive,	sizeof(sForgive),	"%T",	"Forgive",			iVictim);
	Format(sPunish,		sizeof(sPunish),	"%T",	"Do Not Forgive",	iVictim);
	g_iAttacker[iVictim] = GetClientUserId(iAttacker);
	
	new Handle:hMenu	=	CreateMenu(MenuHandler_Punishment);
	SetMenuExitButton(hMenu,	false);
	SetMenuTitle(hMenu,			"[STAC] %T",	"You Were Killed",	iVictim, iAttacker);
	AddMenuItem(hMenu,			"Forgive",		sForgive);
	AddMenuItem(hMenu,			"Punish",		sPunish);
	
	
	// If immunity is disabled, or victim can target attacker, add punishments
	if(!g_bImmunity || CanAdminTarget(GetUserAdmin(iVictim), GetUserAdmin(iAttacker)))
	{
		decl String:sPunishment[32];
		for(new i = 0, iSize = GetArraySize(g_hPunishments); i < iSize; i++)
		{
			// If callback is invalid, remove punishment
			if(g_fPunishmentCallbacks[i] == INVALID_FUNCTION)
			{
				RemoveFromArray(g_hPunishments, i);
				continue;
			}
			
			GetArrayString(g_hPunishments, i, sPunishment, sizeof(sPunishment));
			AddMenuItem(hMenu, sPunishment, sPunishment);
		}
	}
	
	DisplayMenu(hMenu, iVictim, MENU_TIME_FOREVER);
}

 
PunishPlayer(punishment, victim, attacker)
{
	Call_StartFunction(g_hPunishmentPlugins[punishment], g_fPunishmentCallbacks[punishment]);
	Call_PushCell(victim);
	Call_PushCell(attacker);
	Call_Finish();
	Call_StartForward(g_hOnPlayerPunished);
	Call_PushCell(punishment);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();
}


QueuePunishment(punishment, victim, attacker)
{
	PushArrayCell(arrayPlayerPunishments[attacker], victim);
	PushArrayCell(arrayPlayerPunishments[attacker], punishment);
}
 
ResetClientPrefs(client)
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

CreateForwards()
{
	g_hOnPlayerDeath		= 	CreateGlobalForward("STAC_OnPlayerDeath",		ET_Ignore,Param_Cell);
	g_hOnPlayerHurt			=	CreateGlobalForward("STAC_OnPlayerHurt",		ET_Ignore,Param_Cell);
	g_hOnPlayerPunished		=	CreateGlobalForward("STAC_OnPlayerPunished",	ET_Ignore,Param_Cell);
	g_hOnPlayerSpawn		=	CreateGlobalForward("STAC_OnPlayerSpawn",		ET_Ignore,Param_Cell);
}
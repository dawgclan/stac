#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stac>

public Plugin:myinfo	=
{
	name				=	"STAC: Counter-Strike Module",
	author				=	STAC_AUTHORS,
	description			=	"STAC: Counter-Strike Module",
	version				=	STAC_VERSION,
	url					=	STAC_WEBSITE
};

/**
 *	Globals
 */
new g_iExplosionModel;
new g_iLightningModel;
new g_iSmokeModel;
new Handle:g_hBombDefusedKarma;
new Handle:g_hBombExplodedKarma;
new Handle:g_hBombPlantedKarma;
new Handle:g_hHealDamage;
new Handle:g_hHostageRescuedKarma;
new Handle:g_hMirrorDamage;
new Handle:g_hMirrorDamageSlap;
new Handle:g_hRoundWinKarma;
new Handle:g_hSpawnProtectTime;

/**
 *	Plugin Forwards
 */
public OnPluginStart()
{
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir,sizeof(sGameDir));
	if(!StrEqual(sGameDir, "cstrike"))
		SetFailState("This plugin will only work for Counter-Strike: Source.");
	
	// Create Convars
	g_hBombDefusedKarma		=	CreateConVar("stac_bombdefused_karma",		"3",	"STAC Bomb Defused Karma",		FCVAR_PLUGIN);
	g_hBombExplodedKarma	=	CreateConVar("stac_bombexploded_karma",		"2",	"STAC Bomb Exploded Karma", 	FCVAR_PLUGIN);
	g_hBombPlantedKarma		=	CreateConVar("stac_bombplanted_karma",		"1",	"STAC Bomb Planted Karma",		FCVAR_PLUGIN);
	g_hHealDamage			=	CreateConVar("stac_heal_damage",			"0",	"STAC Heal Damage",				FCVAR_PLUGIN);
	g_hHostageRescuedKarma	=	CreateConVar("stac_hostagerescued_karma",	"1",	"STAC Hostage Rescued Karma",	FCVAR_PLUGIN);
	g_hMirrorDamage			=	CreateConVar("stac_mirrordamage",			"1",	"STAC Mirror Damage",			FCVAR_PLUGIN);
	g_hMirrorDamageSlap		=	CreateConVar("stac_mirrordamage_slap",		"0",	"STAC Mirror Damage Slap",		FCVAR_PLUGIN);
	g_hRoundWinKarma		=	CreateConVar("stac_roundwin_karma",			"2",	"STAC Round Win Karma",			FCVAR_PLUGIN);
	g_hSpawnProtectTime		=	CreateConVar("stac_spawnprotect_time",		"10",	"STAC Spawn Protect Time",		FCVAR_PLUGIN);
	
	// Hook Events
	HookEvent("bomb_defused",		Event_BombDefused);
	HookEvent("bomb_exploded",		Event_BombExploded);
	HookEvent("bomb_planted",		Event_BombPlanted);
	HookEvent("hostage_rescued",	Event_HostageRescued);
	HookEvent("player_hurt",		Event_PlayerHurt);
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("round_end",			Event_RoundEnd);
	
	// Load translations
	LoadTranslations("stac-cstrike.phrases);
}

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iLightningModel = PrecacheModel("materials/sprites/tp_beam001.vmt");
	g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");

	PrecacheSound("ambient/explosions/explode_8.wav");
}

/**
 *	Events
 */
public Event_BombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!STAC_GetSetting(STACSetting_Enabled) || !STAC_GetSetting(STACSetting_KarmaEnabled))
		return;
	
	decl String:sReason[256];
	new iClient = GetClientOfUserId(GetEventInt(event,"userid"));
	
	Format(sReason, sizeof(sReason), "%T",	"Defusing Bomb", iClient);
	new iOldKarma = STAC_GetInfo(iClient, STACInfo_Karma);
	STAC_SetInfo(iClient,STACInfo_Karma,iOldKarma++);
}
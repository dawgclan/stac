#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stac>
#include <stac_effect>

public Plugin:myInfo =
{
	name		= "STAC: Slay",
	author		= STAC_AUTHORS,
	description	= "STAC: Slay",
	version		= STAC_VERSION,
	url			= STAC_WEBSITE
};

#define SOUND_EXPLODE	"ambient/explosions/explode_8.wav"

/**
*	Globals
*/
enum Mod
{
	Mod_Default,
	Mod_Insurgency,
	Mod_ZPS
}

// Explosion
new g_iExplosionModel;
new g_iLightningModel;
new g_iSmokeModel;

new Mod:g_iMod = Mod_Default;

/**
 *	Plugin Forwards
 */
public OnPluginStart()
{
	// Load Translations
	LoadTranslations("stac-exploded.phrases");
	
	if(LibraryExists("stac"))
		OnLibraryAdded("stac");
	
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
}

public OnMapStart()
{
	g_iExplosionModel = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_iLightningModel = PrecacheModel("materials/sprites/tp_beam001.vmt");
	g_iSmokeModel     = PrecacheModel("materials/effects/fire_cloud2.vmt");
	
	PrecacheSound(SOUND_EXPLODE, true);
}

public OnLibraryAdded(const String:name[])
{
	if(!StrEqual(name, "stac"))
		return;
	
	decl String:sName[32];
	Format(sName, sizeof(sName), "%T", "Explode", LANG_SERVER);
	STAC_RegisterPunishment(sName, STACPunishment_Explode);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("stac-explode");
	CreateNative("STACEffect_Explode", Native_STACEffect_Explode);
	return APLRes_Success;
}

/**
 * Natives
 */
public Native_STACEffect_Explode(Handle:plugin, numParams)
{
	new iClient = GetNativeCell(1);
	if(IsClientInGame(iClient))
	{
		PerformExplode(iClient);
	}
}

/**
 *	STAC Punishments
 */
public STACPunishment_Explode(victim, attacker)
{
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Blew Up", STAC_GetInfo(attacker, STACInfo_Kills), STAC_GetSetting(STACSetting_KillLimit));

	PerformExplode(attacker);
}

// Explode
PerformExplode(client)
{
	decl Float:flEnd[3], Float:flSparkDir[3], Float:flSparkPos[3], Float:flStart[3];
	// Get player position to use as ending coords
	GetClientAbsOrigin(client, flEnd);
	
	// Se starting coords
	flSparkDir		=	flEnd;
	flSparkPos		=	flEnd;
	flStart			=	flEnd;
	
	flSparkDir[2]	+=	23;
	flSparkPos[2]	+=	13;
	flStart[2]		+=	1000;
	
	// create lightning effects, sparks, and explosion
	
	TE_SetupBeamPoints(flStart, flEnd, g_iLightningModel, g_iLightningModel, 0, 1, 2.0, 5.0, 5.0, 1, 1.0, {255, 255, 255, 255}, 250);
	TE_SendToAll();
	
	TE_SetupExplosion(flEnd,			g_iExplosionModel,	10.0,	10,	TE_EXPLFLAG_NONE,	200,	255);
	TE_SendToAll();
	
	TE_SetupSmoke(flEnd,				g_iExplosionModel,		50.0,	2);
	TE_SendToAll();
	
	TE_SetupSmoke(flEnd,				g_iSmokeModel,		50.0,	2);
	TE_SendToAll();
	
	TE_SetupMetalSparks(flSparkPos,	flSparkDir);
	TE_SendToAll();
	
	EmitAmbientSound(SOUND_EXPLODE,	flEnd, SOUND_FROM_WORLD,	SNDLEVEL_NORMAL,	SND_NOFLAGS,	1.0,	SNDPITCH_NORMAL,	0.0);

	if (g_iMod == Mod_ZPS)
	{
		// Custom slay function from Rawr of the Vortex ZPS server (Fix for instant death in ZPS)
		decl String:dName[32], Entity;
		Format(dName, sizeof(dName), "pd_%d", client);

		Entity = CreateEntityByName("env_entity_dissolver");

		if (Entity)
		{
			DispatchKeyValue(client, "targetname", dName);
			DispatchKeyValue(Entity, "target", dName);
			AcceptEntityInput(Entity, "Dissolve");
			AcceptEntityInput(Entity, "kill");
		}
	}
	else
	{
		ForcePlayerSuicide(client);
	}
}
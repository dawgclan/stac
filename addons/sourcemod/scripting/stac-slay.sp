#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <stac>

public Plugin:myInfo =
{
	name		= "STAC: Slay",
	author		= STAC_AUTHORS,
	description	= "STAC: Slay",
	version		= STAC_VERSION,
	url			= STAC_WEBSITE
};


/**
*	Globals
*/
enum Mod
{
	Mod_Default,
	Mod_Insurgency,
	Mod_ZPS
}

new Mod:g_iMod = Mod_Default;

/**
 *	Plugin Forwards
 */
public OnPluginStart()
{
	// Load Translations
	LoadTranslations("stac-slay.phrases");
	
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

public OnLibraryAdded(const String:name[])
{
	if(!StrEqual(name, "stac"))
		return;
	
	decl String:sName[32];
	Format(sName, sizeof(sName), "%T", "Slay", LANG_SERVER);
	STAC_RegisterPunishment(sName, STACPunishment_Slay);
}

/**
 *	STAC Punishments
 */
public STACPunishment_Slay(victim, attacker)
{
	PrintToChatAll("%c[STAC]%c %t", CLR_GREEN, CLR_DEFAULT, "Slayed", STAC_GetInfo(attacker, STACInfo_Kills), STAC_GetSetting(STACSetting_KillLimit));

	if (g_iMod == Mod_ZPS)
	{
		// Custom slay function from Rawr of the Vortex ZPS server (Fix for instant death in ZPS)
		decl String:dName[32], Entity;
		Format(dName, sizeof(dName), "pd_%d", attacker);

		Entity = CreateEntityByName("env_entity_dissolver");

		if (Entity)
		{
			DispatchKeyValue(attacker, "targetname", dName);
			DispatchKeyValue(Entity, "target", dName);
			AcceptEntityInput(Entity, "Dissolve");
			AcceptEntityInput(Entity, "kill");
		}
	}
	else
	{
		ForcePlayerSuicide(attacker);
	}
}
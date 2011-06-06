#if defined _stac_included_
  #endinput
#endif
#define _stac_included_

#define CLR_DEFAULT		1
#define CLR_LIGHTGREEN	3
#define CLR_GREEN		4
#define CLR_DARKGREEN	5

#define STEAM_BAN_TYPE	0
#define IP_BAN_TYPE		1

#define STAC_VERSION	"0.5.0"
#define STAC_AUTHORS	"Rothgar, Tsunami, FlyingMongoose"
#define STAC_WEBSITE	"http://dawgclan.github.com/stac"

enum STACInfo
{
	STACInfo_Attacks,
	STACInfo_Bans,
	STACInfo_Karma,
	STACInfo_Kills,
	STACInfo_Kicks
}

enum STACSetting
{
	STACSetting_AttackLimit,
	STACSetting_BanLimit,
	STACSetting_BanTime,
	STACSetting_BanType,
	STACSetting_Enabled,
	STACSetting_IgnoreBots,
	STACSetting_Immunity,
	STACSetting_KarmaEnabled,
	STACSetting_KarmaBanRemove,
	STACSetting_KarmaKickRemove,
	STACSetting_KarmaLimit,
	STACSetting_KickLimit,
	STACSetting_KillKarma,
	STACSetting_KillLimit
}

functag public STACPunishment(victim, attacker);


/**
 * Retrieves client information from STAC
 *
 * @param	 client		Player index
 * @param	 type		STACInfo type
 * @return Value of client's information type
 */
native STAC_GetInfo(client, STACInfo:type);

/**
 * Retrieves a setting's value
 *
 * @param	 type		STACSetting type
 * @return Value of setting
 */
native STAC_GetSetting(STACSetting:type);

/**
 * Registers an STAC punishment
 *
 * @param	name		Name of the punishment
 * @param	callback	Command callback
 * @noreturn
 */
native STAC_RegisterPunishment(const String:name[], STACPunishment:callback);

/**
 * Stores client information
 *
 * @param	client	Player index
 * @param	type		STACInfo type
 * @param	value		The value to store
 * @noreturn
 */
native STAC_SetInfo(client, STACInfo:type, value);

/**
 * When a player dies
 *
 */
forward STAC_OnPlayerDeath(attacker,victim);

/**
 * When a player is hurt
 *
 */
forward STAC_OnPlayerHurt(attacker,victim);

/**
 * When a player spawns
 *
 */
forward STAC_OnPlayerSpawn(client);

public SharedPlugin:__pl_stac = 
{
	name = "stac",
	file = "stac.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

public __pl_stac_SetNTVOptional()
{
	MarkNativeAsOptional("STAC_GetInfo");
	MarkNativeAsOptional("STAC_GetSetting");
	MarkNativeAsOptional("STAC_RegisterPunishment");
	MarkNativeAsOptional("STAC_SetInfo");
}
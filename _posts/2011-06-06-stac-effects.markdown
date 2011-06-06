---
layout: default
title: STAC Effects Implemented
---

One thing that made ATAC, and it's alternatives (such as Rothgar's Simple Anti-TK) unique was the fact that you had "fun" ways of punishing those who wronged you?

Well, STAC is no different, while we have yet to actually write the plugins that provide these "fun" options, I have been hard at work porting some of the functionality over.

With STAC we are attempting to be as dynamic and versatile as possible, doing so means utilizing a lot of natives. That being the case I have taken the time to build a special include file that can be used by any plugin meant to work with ATAC.

While a number of these functionalities do not work in all mods, we will do our best to update to make them do so, the nice thing I have done here is made just **ONE** function, with a list of enumerations as the effect option.

Here is that list of Enumerations.
* STACEffect_Beacon
* STACEffect_Blind
* STACEffect_Burn
* STACEffect_Drug
* STACEffect_Explode
* STACEffect_FireBomb
* STACEffect_Freeze
* STACEffect_FreezeBomb
* STACEffect_TimeBomb

	/**
	 * Executes an explosion effect on the client
	 *
	 * @param	client		Player index
	 * @param	type		STACEffects_Type
	 * @param	radius		Optional param that allows a Float to be passed
	 * 						for radii of functions (such as bombs and beacon)
	 *						Default = 375.0
	 * @param	ticks		Optional param that allows an int to be passed for customizable timers
	 * 						such as in FireBomb, and TimeBomb.
	 *						Default = 10
	 * @param	targetmode	Optional param that allows you to set the mode of a bomb
	 *						0 = Target Only
	 *						1 = Target Team Mates and Target
	 *						2 = Everyone
	 * @param	duration	Optional param that allows an amount of time before an effect wears off
	 *						such as "Freeze", "FreezeBomb", and "Burn"
	 *						Default = 20.0
	 *
	 * @noreturn
	 * @error				Client not in game.
	 */
	native STAC_Effect(client,STACEffect_Type:type,Float:radius=375.0,ticks=10,targetmode=0,Float:duration=20.0);
	
Assuming I've placed *#include <stac>* and *#include <stac_effects>* into my plugin I'm good to go.
So, lets say I want to FireBomb a player. It's easy!
	// Client = player index
	STAC_Effect(client, STACEffect_FireBomb);
See? Wasn't that easy, but wait, I want the bomb to affect a larger radius, lets say 600, and only want it to burn for 10 seconds, and affect EVERYONE. Simple.
	// Client = player index
	STAC_Effect(client, STACEffect_FireBomb, 600.0,10,2,10.0);
See? Wasn't that easy? The 600.0 is the radius, the 10 is the number of seconds that it takes for the bomb to "go off" this is optional you can leave it "empty" and it will default to 10 anyway, the 2 is the target mode (allowing it to burn everyone within the 600 radius), and the 10.0 is how long the burn will last (on each player).

With this advent it will make building the punishment plugins (and a couple of the mod-plugins) go a LOT faster.
	
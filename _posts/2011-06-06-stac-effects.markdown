---
layout: default
title: STAC Effects Implemented
author: FlyingMongoose
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
	native STAC_Effect(client,STACEffect_Type:type,Float:radius=375.0,ticks=10,targetmode=0,Float:duration=20.0);
Assuming I've placed #include <stac> and #include <stac_effects> into my plugin I'm good to go.
So, lets say I want to FireBomb a player. It's easy!
	STAC_Effect(client, STACEffect_FireBomb);
See? Wasn't that easy, but wait, I want the bomb to affect a larger radius, lets say 600, and only want it to burn for 10 seconds, and affect EVERYONE. Simple.
	STAC_Effect(client, STACEffect_FireBomb, 600.0,10,2,10.0);
See? Wasn't that easy? The 600.0 is the radius, the 10 is the number of seconds that it takes for the bomb to "go off" this is optional you can leave it "empty" and it will default to 10 anyway, the 2 is the target mode (allowing it to burn everyone within the 600 radius), and the 10.0 is how long the burn will last (on each player).

With this advent it will make building the punishment plugins (and a couple of the mod-plugins) go a LOT faster.

I'm sure some of you are wondering "Where is Uber-Slap?" well that particular function is rather touchy, however it's not going to go in until we're done with all the other punishments. At which point it will be added to the enums available above and I also intend to build an "UberSlap Bomb".
	
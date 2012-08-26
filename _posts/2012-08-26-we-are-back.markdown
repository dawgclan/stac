---
layout: post
title: We Are Back
author: FlyingMongoose
---

Well, at least I, FlyingMongoose, am back. Thanks to my newfound interest in Counter-Strike: Global Offensive, I have yet again taken up the reigns of maintaining STAC. I have yet to hear from Rothgar, but I assume he will probably get his interest piqued seeing I'm doing things again.

So, as of my latest commit and current status of the plugin here are recent changes.

* Client's data will no longer clear altogether, it will now be based on the most recent application of whatever data may be.
> * Based on default settings (30 minutes), if the player has a 2 of 3 team kills and he does not do anything, the next time he loads (this could be a disconnect or map change) it will reset those kills to 0, but if he had a team attack within 15 minutes, that won't get reset until the additional 15 minutes is up.
* stac-cstrike plugin now supports both Counter-Strike: Source and Counter-Strike: Global Offensive
* The slay plugin had a couple of bugs in it, these have been fixed.

As stated before, STAC is a full rewrite of ATAC with inspiration and methods from 2 other sources, the rewrite of ATAC from Tsunami, and the third party similar functionality of tk-punish from Rothgar, and our goals still remain the same, newer, more efficient code, and a far smoother plugin.
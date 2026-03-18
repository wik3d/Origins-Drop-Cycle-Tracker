# Origins Drop Cycle Tracker (Plutonium BO2)

A lightweight Plutonium GSC mod for Black Ops 2 Origins that shows your current power-up drop cycle at the top of the screen.

It tracks the normal BO2 Origins cycle:

* Max Ammo
* Insta-Kill
* Double Points
* Nuke
* Zombie Blood

The tracker updates automatically in-game and is designed to ignore scripted or non-cycle drops, such as reward drops that do not come from normal zombie kills.

## Features

* Top-screen drop cycle HUD
* Automatic tracking
* Built for BO2 Origins on Plutonium
* Ignores non-cycle reward drops as much as possible by only counting drops that appear near recent zombie deaths
* Optional Fire Sale support

## Installation

Put the files in your Plutonium BO2 scripts folder:

`%localappdata%\Plutonium\storage\t6\scripts\zm`

You should have:

* `origins_drop_cycle_tracker.gsc`
* your modified `ranked.gsc`

## ranked.gsc setup

At the top of `ranked.gsc`, add:

```c
#include scripts\zm\origins_drop_cycle_tracker;
```

Then inside `init()`, add:

```c
level thread origins_drop_cycle_tracker::init();
```

## Example

### Includes

```c
#include scripts\zm\origins_drop_cycle_tracker;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
```

### Inside `init()`

```c
init()
{
	if ( GetDvarInt( "scr_disablePlutoniumFixes" ) )
	{
		return;
	}

	level thread origins_drop_cycle_tracker::init();

	level.player_too_many_players_check = false;

	if ( isDedicated() )
	{
		level thread upload_stats_on_round_end();
		level thread upload_stats_on_game_end();
		level thread upload_stats_on_player_connect();

		level.allow_teamchange = getgametypesetting( "allowInGameTeamChange" ) + "";
		SetDvar( "ui_allow_teamchange", level.allow_teamchange );
	}

	level thread watch_all_zombies();
}
```

## Fire Sale support

By default, Fire Sale is disabled because it only joins the drop cycle if the box has moved from its original location.

If you want to track Fire Sale too, open `origins_drop_cycle_tracker.gsc` and change:

```c
level.odc_include_fire_sale = false;
```

to:

```c
level.odc_include_fire_sale = true;
```

You will also need to make sure Fire Sale is included in the tracked cycle list. In the `init()` setup, add it to `level.odc_powerups`.

Example:

```c
level.odc_powerups = [];
level.odc_powerups[0] = "max_ammo";
level.odc_powerups[1] = "insta_kill";
level.odc_powerups[2] = "double_points";
level.odc_powerups[3] = "nuke";
level.odc_powerups[4] = "zombie_blood";
level.odc_powerups[5] = "fire_sale";
```

## Notes

* This mod is made specifically for BO2 Origins
* BO2 Origins does not use Carpenter in the normal drop cycle, so Carpenter is not tracked
* Fire Sale should only be enabled if the box has been moved from its original spawn
* Detection is based on live entity tracking and nearby zombie deaths, so it is designed for normal gameplay drops rather than scripted map rewards

## Credits

Created for the Plutonium BO2 community.

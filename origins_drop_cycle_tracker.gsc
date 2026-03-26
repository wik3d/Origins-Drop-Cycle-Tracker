#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

main()
{
}

init()
{
	level endon("end_game");

	if ( isDefined(level.odc_init) && level.odc_init )
		return;

	level.odc_init = true;
	level.odc_cycle_number = 1;
	level.odc_cycle_complete_waiting_for_next = false;
	level.odc_include_fire_sale = false;

	level.odc_powerups = [];
	level.odc_powerups[0] = "max_ammo";
	level.odc_powerups[1] = "insta_kill";
	level.odc_powerups[2] = "double_points";
	level.odc_powerups[3] = "nuke";
	level.odc_powerups[4] = "zombie_blood";
	// Uncomment the line below to include fire sales
	// level.odc_powerups[5] = "fire_sale";

	/*
	Distinguises between powerups dropped by zombies and ones dug or recieved by reward box
	*/
	level.odc_recent_deaths = [];
	level.odc_recent_death_max = 24;
	level.odc_recent_death_lifetime = 3.0; // seconds
	level.odc_death_match_radius = 220;    // distance from zombie death to drop spawn

	odc_reset_seen();

	level thread odc_watch_existing_players();
	level thread odc_watch_players();
	level thread odc_watch_zombies();
	level thread odc_watch_powerup_entities();
}

odc_watch_existing_players()
{
	level endon("end_game");

	wait 0.2;

	players = GetPlayers();
	foreach (player in players)
	{
		if ( isDefined(player) )
			player thread odc_create_hud();
	}
}

odc_watch_players()
{
	level endon("end_game");

	for (;;)
	{
		level waittill("connected", player);
		player thread odc_create_hud();
	}
}

odc_create_hud()
{
	self endon("disconnect");
	level endon("end_game");

	wait 0.25;

	if ( isDefined(self.odc_title) )
		return;

	self.odc_title = newClientHudElem(self);
	self.odc_title.x = 0;
	self.odc_title.y = 14;
	self.odc_title.horzAlign = "center_safearea";
	self.odc_title.vertAlign = "top";
	self.odc_title.alignX = "center";
	self.odc_title.alignY = "top";
	self.odc_title.fontScale = 1.5;
	self.odc_title.archived = false;
	self.odc_title.hideWhenInMenu = true;
	self.odc_title.sort = 1000;

	self.odc_line = newClientHudElem(self);
	self.odc_line.x = 0;
	self.odc_line.y = 32;
	self.odc_line.horzAlign = "center_safearea";
	self.odc_line.vertAlign = "top";
	self.odc_line.alignX = "center";
	self.odc_line.alignY = "top";
	self.odc_line.fontScale = 1.25;
	self.odc_line.archived = false;
	self.odc_line.hideWhenInMenu = true;
	self.odc_line.sort = 1001;

	self.odc_status = newClientHudElem(self);
	self.odc_status.x = 0;
	self.odc_status.y = 48;
	self.odc_status.horzAlign = "center_safearea";
	self.odc_status.vertAlign = "top";
	self.odc_status.alignX = "center";
	self.odc_status.alignY = "top";
	self.odc_status.fontScale = 1.1;
	self.odc_status.archived = false;
	self.odc_status.hideWhenInMenu = true;
	self.odc_status.sort = 1002;

	odc_update_hud_for_player(self);
}

odc_watch_zombies()
{
	level endon("end_game");

	for (;;)
	{
		zombies = getaiarray(level.zombie_team);

		foreach (zombie in zombies)
		{
			if ( !isDefined(zombie) )
				continue;

			if ( isDefined(zombie.odc_watched) )
				continue;

			zombie.odc_watched = true;
			zombie thread odc_track_zombie_death();
		}

		wait 0.05;
	}
}

odc_track_zombie_death()
{
	self waittill("death");

	if ( !odc_is_cycle_eligible_zombie(self) )
		return;

	if ( isDefined(self.origin) )
		odc_add_recent_death(self.origin);
}

odc_is_cycle_eligible_zombie(zombie)
{
	text = "";

	if ( isDefined(zombie.targetname) )
		text += " " + toLower(zombie.targetname);

	if ( isDefined(zombie.script_noteworthy) )
		text += " " + toLower(zombie.script_noteworthy);

	if ( isDefined(zombie.classname) )
		text += " " + toLower(zombie.classname);

	if ( isDefined(zombie.animname) )
		text += " " + toLower(zombie.animname);

	if ( isDefined(zombie.script_linkname) )
		text += " " + toLower(zombie.script_linkname);

	if ( isDefined(zombie.model) )
		text += " " + toLower(zombie.model);

	// Ignore only generator-capture zombies
	if ( isSubStr(text, "capture_zombie") )
		return false;

	if ( isSubStr(text, "zone_capture") )
		return false;

	return true;
}

odc_add_recent_death(pos)
{
	entry = spawnstruct();
	entry.origin = pos;
	entry.time = gettime();

	level.odc_recent_deaths[level.odc_recent_deaths.size] = entry;

	while ( level.odc_recent_deaths.size > level.odc_recent_death_max )
		arrayremovevalue(level.odc_recent_deaths, level.odc_recent_deaths[0]);
}

odc_cleanup_recent_deaths()
{
	now = gettime();
	i = 0;

	while ( i < level.odc_recent_deaths.size )
	{
		entry = level.odc_recent_deaths[i];

		if ( !isDefined(entry) || !isDefined(entry.time) || ((now - entry.time) > (level.odc_recent_death_lifetime * 1000)) )
		{
			arrayremovevalue(level.odc_recent_deaths, entry);
			i = 0;
			continue;
		}

		i++;
	}
}

odc_is_near_recent_death(pos)
{
	odc_cleanup_recent_deaths();

	foreach (entry in level.odc_recent_deaths)
	{
		if ( !isDefined(entry) || !isDefined(entry.origin) )
			continue;

		if ( distance(pos, entry.origin) <= level.odc_death_match_radius )
			return true;
	}

	return false;
}

odc_watch_powerup_entities()
{
	level endon("end_game");

	for (;;)
	{
		odc_scan_powerup_array(GetEntArray("script_model", "classname"));
		odc_scan_powerup_array(GetEntArray("powerup", "targetname"));
		odc_scan_powerup_array(GetEntArray("zombie_powerup", "targetname"));
		odc_scan_powerup_array(GetEntArray("powerup", "classname"));
		odc_scan_powerup_array(GetEntArray("zombie_powerup", "classname"));

		wait 0.01;
	}
}

odc_scan_powerup_array(arr)
{
	if ( !isDefined(arr) || !arr.size )
		return;

	foreach (ent in arr)
	{
		if ( !isDefined(ent) )
			continue;

		if ( isDefined(ent.odc_scanned) )
			continue;

		ent.odc_scanned = true;

		text = "";

		if ( isDefined(ent.targetname) )
			text += " targetname=" + ent.targetname;

		if ( isDefined(ent.script_noteworthy) )
			text += " noteworthy=" + ent.script_noteworthy;

		if ( isDefined(ent.classname) )
			text += " classname=" + ent.classname;

		if ( isDefined(ent.model) )
			text += " model=" + ent.model;

		if ( isDefined(ent.script_linkname) )
			text += " linkname=" + ent.script_linkname;

		name = odc_guess_powerup_name_from_ent(ent);

		if ( name == "" )
			continue;

		if ( !isDefined(ent.origin) )
			continue;

		if ( !odc_is_near_recent_death(ent.origin) )
			continue;

		level thread odc_on_powerup_detected(name);
	}
}

odc_guess_powerup_name_from_ent(ent)
{
	text = "";

	if ( isDefined(ent.targetname) )
		text += " " + toLower(ent.targetname);

	if ( isDefined(ent.script_noteworthy) )
		text += " " + toLower(ent.script_noteworthy);

	if ( isDefined(ent.classname) )
		text += " " + toLower(ent.classname);

	if ( isDefined(ent.model) )
		text += " " + toLower(ent.model);

	if ( isDefined(ent.script_linkname) )
		text += " " + toLower(ent.script_linkname);

	if ( isSubStr(text, "zombie_skull") || isSubStr(text, "insta_kill") || isSubStr(text, "instakill") )
		return "insta_kill";

	if ( isSubStr(text, "zombie_x2_icon") || isSubStr(text, "double_points") || isSubStr(text, "doublepoints") )
		return "double_points";

	if ( isSubStr(text, "zombie_ammocan") || isSubStr(text, "max_ammo") || isSubStr(text, "maxammo") || isSubStr(text, "zombie_max_ammo") || isSubStr(text, "zombie_maxammo") )
		return "max_ammo";

	if ( isSubStr(text, "zombie_bomb") || isSubStr(text, "nuke") || isSubStr(text, "zombie_nuke") )
		return "nuke";

	if ( isSubStr(text, "zombie_blood") || isSubStr(text, "zombieblood") || isSubStr(text, "blood") )
		return "zombie_blood";

	if ( isSubStr(text, "fire_sale") || isSubStr(text, "firesale") )
		return "fire_sale";

	return "";
}

odc_reset_seen()
{
	level.odc_seen = [];
	level.odc_seen["max_ammo"] = false;
	level.odc_seen["insta_kill"] = false;
	level.odc_seen["double_points"] = false;
	level.odc_seen["nuke"] = false;
	level.odc_seen["zombie_blood"] = false;
	level.odc_seen["fire_sale"] = false;
}

odc_on_powerup_detected(powerup)
{
	if ( powerup == "fire_sale" && !level.odc_include_fire_sale )
		return;

	if ( !odc_is_tracked_powerup(powerup) )
		return;

	if ( level.odc_cycle_complete_waiting_for_next )
	{
		level.odc_cycle_number++;
		level.odc_cycle_complete_waiting_for_next = false;
		odc_reset_seen();
	}

	if ( !level.odc_seen[powerup] )
	{
		level.odc_seen[powerup] = true;

		if ( odc_is_cycle_complete() )
			level.odc_cycle_complete_waiting_for_next = true;

		odc_update_hud_all();
	}
}

odc_is_tracked_powerup(name)
{
	foreach (p in level.odc_powerups)
	{
		if ( p == name )
			return true;
	}

	if ( level.odc_include_fire_sale && name == "fire_sale" )
		return true;

	return false;
}

odc_is_cycle_complete()
{
	foreach (p in level.odc_powerups)
	{
		if ( !level.odc_seen[p] )
			return false;
	}

	return true;
}

odc_count_seen()
{
	count = 0;

	foreach (p in level.odc_powerups)
	{
		if ( level.odc_seen[p] )
			count++;
	}

	return count;
}

odc_friendly_name(name)
{
	switch (name)
	{
		case "max_ammo":
			return "Max";
		case "insta_kill":
			return "Insta";
		case "double_points":
			return "Double";
		case "nuke":
			return "Nuke";
		case "zombie_blood":
			return "Blood";
		case "fire_sale":
			return "Sale";
	}

	return name;
}

odc_checkbox(name)
{
	if ( level.odc_seen[name] )
		return "^2[x]^7";

	return "^1[ ]^7";
}

odc_build_line()
{
	text = "";

	for (i = 0; i < level.odc_powerups.size; i++)
	{
		name = level.odc_powerups[i];
		text += odc_checkbox(name) + " " + odc_friendly_name(name);

		if ( i < level.odc_powerups.size - 1 )
			text += "   ";
	}

	return text;
}

odc_update_hud_all()
{
	players = GetPlayers();

	foreach (player in players)
	{
		if ( isDefined(player) )
			odc_update_hud_for_player(player);
	}
}

odc_update_hud_for_player(player)
{
	if ( !isDefined(player.odc_title) || !isDefined(player.odc_line) || !isDefined(player.odc_status) )
		return;

	player.odc_title setText("^5Origins Drop Cycle ^7| Cycle #" + level.odc_cycle_number);
	player.odc_line setText(odc_build_line());

	if ( odc_is_cycle_complete() )
		player.odc_status setText("^2Cycle complete^7 - next valid drop starts a new cycle");
	else
		player.odc_status setText("^7Seen: " + odc_count_seen() + "/" + level.odc_powerups.size);
}
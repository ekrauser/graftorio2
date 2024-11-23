require("train")
require("yarm")
require("events")
require("power")
require("research")

bucket_settings = train_buckets(settings.startup["graftorio-train-histogram-buckets"].value)
nth_tick = settings.startup["graftorio-nth-tick"].value
server_save = settings.startup["graftorio-server-save"].value
disable_train_stats = settings.startup["graftorio-disable-train-stats"].value


script.on_init(function()
	if game.active_mods["YARM"] then
		global.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
		script.on_event(global.yarm_on_site_update_event_id, handleYARM)
	end

	on_power_init()

	script.on_nth_tick(nth_tick, register_events)

	script.on_event(defines.events.on_player_joined_game, register_events_players)
	script.on_event(defines.events.on_player_left_game, register_events_players)
	script.on_event(defines.events.on_player_removed, register_events_players)
	script.on_event(defines.events.on_player_kicked, register_events_players)
	script.on_event(defines.events.on_player_banned, register_events_players)

	-- train envents
	if not disable_train_stats then
		script.on_event(defines.events.on_train_changed_state, register_events_train)
	end

	-- power events
	script.on_event(defines.events.on_built_entity, on_power_build)
	script.on_event(defines.events.on_robot_built_entity, on_power_build)
	script.on_event(defines.events.script_raised_built, on_power_build)
	script.on_event(defines.events.on_player_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_entity_died, on_power_destroy)
	script.on_event(defines.events.script_raised_destroy, on_power_destroy)

	-- research events
	script.on_event(defines.events.on_research_finished, on_research_finished)
end)

script.on_load(function()
	if global.yarm_on_site_update_event_id then
		if script.get_event_handler(global.yarm_on_site_update_event_id) then
			script.on_event(global.yarm_on_site_update_event_id, handleYARM)
		end
	end

	on_power_load()

	script.on_nth_tick(nth_tick, register_events)

	script.on_event(defines.events.on_player_joined_game, register_events_players)
	script.on_event(defines.events.on_player_left_game, register_events_players)
	script.on_event(defines.events.on_player_removed, register_events_players)
	script.on_event(defines.events.on_player_kicked, register_events_players)
	script.on_event(defines.events.on_player_banned, register_events_players)

	-- train events
	if not disable_train_stats then
		script.on_event(defines.events.on_train_changed_state, register_events_train)
	end

	-- power events
	script.on_event(defines.events.on_built_entity, on_power_build)
	script.on_event(defines.events.on_robot_built_entity, on_power_build)
	script.on_event(defines.events.script_raised_built, on_power_build)
	script.on_event(defines.events.on_player_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_robot_mined_entity, on_power_destroy)
	script.on_event(defines.events.on_entity_died, on_power_destroy)
	script.on_event(defines.events.script_raised_destroy, on_power_destroy)

	-- research events
	script.on_event(defines.events.on_research_finished, on_research_finished)
end)

script.on_configuration_changed(function(event)
	if game.active_mods["YARM"] then
		global.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
		script.on_event(global.yarm_on_site_update_event_id, handleYARM)
	end
end)

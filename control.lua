-- Required modules and settings
require("train")
require("yarm")
require("events")
require("power")
require("research")

bucket_settings = train_buckets(settings.startup["graftorio-train-histogram-buckets"].value)
nth_tick = settings.startup["graftorio-nth-tick"].value or (60 * 15) -- Defaults to every 15 seconds
server_save = settings.startup["graftorio-server-save"].value
disable_train_stats = settings.startup["graftorio-disable-train-stats"].value

-- Write JSON to file
function write_json_to_file(data, filename)
    local json = game.table_to_json(data, true) -- Convert table to formatted JSON
    game.write_file(filename, json .. "\n", false) -- Overwrite file each tick
end

-- Collect production and consumption data
function get_prod_cons(production_statistics, prototypes)
    local production = {}
    local consumption = {}

    for name, prototype in pairs(prototypes) do
        production[name] = production_statistics.get_input_count(name)
        consumption[name] = production_statistics.get_output_count(name)
    end

    return production, consumption
end

-- Gather data for a force
function get_force_data(force)
    local item_production, item_consumption = get_prod_cons(force.item_production_statistics, game.item_prototypes)
    local fluid_production, fluid_consumption = get_prod_cons(force.fluid_production_statistics, game.fluid_prototypes)

    return {
        ["item_production"] = item_production,
        ["item_consumption"] = item_consumption,
        ["fluid_production"] = fluid_production,
        ["fluid_consumption"] = fluid_consumption,
    }
end

-- Gather research data for a force
function get_research_data(force)
    return {
        current_research = force.current_research and force.current_research.name or nil,
        progress = force.current_research and force.current_research.progress or nil,
    }
end

-- Collect pollution data
function get_pollution_data(surface)
    return surface.get_pollution({0, 0}) -- Adjust coordinates for specific areas if needed
end

-- Tick handler for periodic metric collection
function tick_handler(tick_event)
    local tick = tick_event.tick
    local data = {
        ["tick"] = tick,
        ["time_seconds"] = tick / 60,
        ["forces"] = {},
        ["pollution"] = get_pollution_data(game.surfaces["nauvis"]),
    }

    -- Collect data for each force
    for _, force in pairs(game.forces) do
        data["forces"][force.name] = {
            production = get_force_data(force),
            research = get_research_data(force),
        }
    end

    -- Write data to JSON file
    write_json_to_file(data, "graftorio_stats.json")
end

-- Initialization
script.on_init(function()
    if game.active_mods["YARM"] then
        global.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
        script.on_event(global.yarm_on_site_update_event_id, handleYARM)
    end

    on_power_init()

    -- Set periodic tick handler
    script.on_nth_tick(nth_tick, tick_handler)

    -- Register other events
    script.on_event(defines.events.on_player_joined_game, register_events_players)
    script.on_event(defines.events.on_player_left_game, register_events_players)

    if not disable_train_stats then
        script.on_event(defines.events.on_train_changed_state, register_events_train)
    end
end)

-- Handle mod reloads
script.on_load(function()
    if global.yarm_on_site_update_event_id then
        if script.get_event_handler(global.yarm_on_site_update_event_id) then
            script.on_event(global.yarm_on_site_update_event_id, handleYARM)
        end
    end

    on_power_load()

    -- Reset periodic tick handler
    script.on_nth_tick(nth_tick, tick_handler)

    -- Re-register events
    script.on_event(defines.events.on_player_joined_game, register_events_players)
    script.on_event(defines.events.on_player_left_game, register_events_players)

    if not disable_train_stats then
        script.on_event(defines.events.on_train_changed_state, register_events_train)
    end
end)

-- Handle configuration changes
script.on_configuration_changed(function(event)
    if game.active_mods["YARM"] then
        global.yarm_on_site_update_event_id = remote.call("YARM", "get_on_site_updated_event_id")
        script.on_event(global.yarm_on_site_update_event_id, handleYARM)
    end
end)

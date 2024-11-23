function register_events(event)
    local data = {
        tick = game.tick,
        surfaces = {},
        mods = {},
        players = {},
    }

    -- Add surface data
    for _, surface in pairs(game.surfaces) do
        table.insert(data.surfaces, { name = surface.name, seed = surface.map_gen_settings.seed })
    end

    -- Add mod data
    for name, version in pairs(game.active_mods) do
        table.insert(data.mods, { name = name, version = version })
    end

    -- Add player data
    for _, player in pairs(game.players) do
        local player_data = {
            force_name = player.force.name,
            item_production = player.force.item_production_statistics.input_counts,
            item_consumption = player.force.item_production_statistics.output_counts,
            fluid_production = player.force.fluid_production_statistics.input_counts,
            fluid_consumption = player.force.fluid_production_statistics.output_counts,
            evolution = {
                total = player.force.evolution_factor,
                by_pollution = player.force.evolution_factor_by_pollution,
                by_time = player.force.evolution_factor_by_time,
                by_killing_spawners = player.force.evolution_factor_by_killing_spawners,
            },
            items_launched = player.force.items_launched,
        }

        table.insert(data.players, player_data)
    end

    -- Write data as JSON
    local json = game.table_to_json(data)
    game.write_file("graftorio_stats.json", json .. "\n", false)
end

function register_events_players(event)
    local player_counts = {
        connected = #game.connected_players,
        total = #game.players,
    }

    local json = game.table_to_json(player_counts)
    game.write_file("graftorio_player_stats.json", json .. "\n", false)
end

-- Write JSON stats to file
function write_tick(json)
    local filename = "graftorio_stats.json"
    game.write_file(filename, json .. "\n", false) -- Overwrite the file
end

-- Collect production and consumption stats
function get_prod_cons(production_statistics, prototypes)
    local production = {}
    local consumption = {}

    for name, _ in pairs(prototypes) do
        production[name] = production_statistics.get_input_count(name) or 0
        consumption[name] = production_statistics.get_output_count(name) or 0
    end

    return production, consumption
end

-- Gather power data for a specific surface
function get_power_data(surface)
    local power_data = {
        production = 0,
        consumption = 0,
    }

    for _, entity in pairs(surface.find_entities_filtered({type = {"electric-energy-interface", "generator", "solar-panel"}})) do
        if entity.valid and entity.energy_production_statistics then
            power_data.production = power_data.production + (entity.energy_production_statistics.get_input_count("electric-energy") or 0)
        end
    end

    for _, entity in pairs(surface.find_entities_filtered({type = {"electric-energy-interface", "accumulator", "lamp"}})) do
        if entity.valid and entity.energy_production_statistics then
            power_data.consumption = power_data.consumption + (entity.energy_production_statistics.get_output_count("electric-energy") or 0)
        end
    end

    return power_data
end

-- Gather force data for a specific surface (defaulting to "nauvis")
function get_force_data(force, surface_name)
    if not force or not force.valid then
        return nil -- Ensure the force is valid
    end

    local surface = game.surfaces[surface_name or "nauvis"]
    if not surface then
        return nil -- Ensure the surface exists
    end

    -- Collect item production and consumption stats
    local item_production, item_consumption = get_prod_cons(force.get_item_production_statistics(surface), game.item_prototypes)

    -- Collect fluid production and consumption stats
    local fluid_production, fluid_consumption = get_prod_cons(force.get_fluid_production_statistics(surface), game.fluid_prototypes)

    -- Collect power production and consumption stats
    local power_stats = get_power_data(surface)

    return {
        ["item_production"] = item_production,
        ["item_consumption"] = item_consumption,
        ["fluid_production"] = fluid_production,
        ["fluid_consumption"] = fluid_consumption,
        ["power_production"] = power_stats.production,
        ["power_consumption"] = power_stats.consumption,
    }
end

-- Tick handler for periodic stats collection
function tick_handler(event)
    local data = {}
    local player_force = game.forces["player"]

    if player_force then
        data["player"] = get_force_data(player_force, "nauvis")
    end

    -- Add a timestamp for Node-RED
    data["timestamp"] = game.tick / 60 -- Convert ticks to seconds

    -- Convert the data to JSON and write it to the file
    local json = game.table_to_json(data, true)
    write_tick(json)
end

-- Run the tick handler every 15 seconds (60 ticks * 15)
script.on_nth_tick(60 * 15, tick_handler)

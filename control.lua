-- Initialize necessary helpers
local function collect_statistics_forces()
    local production_data = {} -- Container for all collected data
    local surface_errors = {}  -- Tracks errors per surface for summary logging

    log("Starting production statistics collection...")

    -- Iterate over all valid surfaces
    for _, surface in pairs(game.surfaces) do
        if surface and surface.valid then
            log("Processing surface: " .. surface.name)

            local surface_error_count = 0 -- Reset error count for the surface

            -- Iterate over all valid forces
            for _, force in pairs(game.forces) do
                if force and force.valid then
                    -- Collect item production statistics for the surface
                    local success_items, err_items = pcall(function()
                        local item_stats = force.get_item_production_statistics(surface)
                        if item_stats then
                            for item, count in pairs(item_stats.input_counts or {}) do
                                table.insert(production_data, {
                                    surface = surface.name,
                                    type = "item",
                                    action = "produced",
                                    force = force.name,
                                    name = item,
                                    count = count
                                })
                            end
                            for item, count in pairs(item_stats.output_counts or {}) do
                                table.insert(production_data, {
                                    surface = surface.name,
                                    type = "item",
                                    action = "consumed",
                                    force = force.name,
                                    name = item,
                                    count = count
                                })
                            end
                        end
                    end)
                    if not success_items then
                        surface_error_count = surface_error_count + 1
                    end

                    -- Collect fluid production statistics for the surface
                    local success_fluids, err_fluids = pcall(function()
                        local fluid_stats = force.get_fluid_production_statistics(surface)
                        if fluid_stats then
                            for fluid, count in pairs(fluid_stats.input_counts or {}) do
                                table.insert(production_data, {
                                    surface = surface.name,
                                    type = "fluid",
                                    action = "produced",
                                    force = force.name,
                                    name = fluid,
                                    count = count
                                })
                            end
                            for fluid, count in pairs(fluid_stats.output_counts or {}) do
                                table.insert(production_data, {
                                    surface = surface.name,
                                    type = "fluid",
                                    action = "consumed",
                                    force = force.name,
                                    name = fluid,
                                    count = count
                                })
                            end
                        end
                    end)
                    if not success_fluids then
                        surface_error_count = surface_error_count + 1
                    end
                end
            end

            -- Collect electric network statistics
            local satisfaction = 0
            local production = 0
            local accumulator_charge = 0

            local unique_networks = {}
            for _, pole in pairs(surface.find_entities_filtered({type = "electric-pole"})) do
                if pole and pole.valid then
                    local stats = pole.electric_network_statistics
                    if stats and not unique_networks[stats] then
                        unique_networks[stats] = true -- Process unique networks
                        local success, err = pcall(function()
                            satisfaction = satisfaction + (stats.get_flow_count{
                                category = "satisfaction",
                                precision_index = defines.flow_precision_index.one_minute
                            } or 0)
                            production = production + (stats.get_flow_count{
                                category = "production",
                                precision_index = defines.flow_precision_index.one_minute
                            } or 0)
                        end)
                        if not success then
                            surface_error_count = surface_error_count + 1
                        end
                    end
                else
                    surface_error_count = surface_error_count + 1
                end
            end

            -- Accumulate energy stored in accumulators
            for _, accumulator in pairs(surface.find_entities_filtered({type = "accumulator"})) do
                if accumulator and accumulator.valid then
                    accumulator_charge = accumulator_charge + (accumulator.energy or 0)
                end
            end

            -- Add electric statistics to production data
            table.insert(production_data, {
                surface = surface.name,
                type = "electricity",
                action = "satisfaction",
                force = nil,
                name = "electric-network",
                count = math.floor((satisfaction / 1e3) * 100) / 100 -- Convert to kW, round to 2 decimals
            })
            table.insert(production_data, {
                surface = surface.name,
                type = "electricity",
                action = "production",
                force = nil,
                name = "electric-network",
                count = math.floor((production / 1e3) * 100) / 100 -- Convert to kW, round to 2 decimals
            })
            table.insert(production_data, {
                surface = surface.name,
                type = "electricity",
                action = "accumulator_charge",
                force = nil,
                name = "electric-network",
                count = math.floor((accumulator_charge / 1e6) * 100) / 100 -- Convert to MJ, round to 2 decimals
            })

            -- Store errors for the surface
            surface_errors[surface.name] = surface_error_count
        else
            log("Invalid or missing surface encountered.")
        end
    end

    -- Log aggregated errors per surface
    for surface_name, error_count in pairs(surface_errors) do
        if error_count > 0 then
            log("Errors encountered on surface '" .. surface_name .. "': " .. error_count)
        end
    end

    -- Convert the production data to JSON
    local json_data = helpers.table_to_json(production_data)

    -- Write the JSON data to the output file
    local filename = "graftorio-kraus/production_stats.json"
    local success_write, err_write = pcall(function()
        helpers.write_file(filename, json_data, false)
    end)

    if success_write then
        log("Production statistics successfully written to file: " .. filename)
    else
        log("Failed to write production statistics to file: " .. (err_write or "unknown error"))
    end
end

-- Register the function to execute every 900 ticks
script.on_nth_tick(900, collect_statistics_forces)

inf = basics.inf
str_xyz = basics.str_xyz


bumps = {
    north = { 0,  0, -1},
    south = { 0,  0,  1},
    east  = { 1,  0,  0},
    west  = {-1,  0,  0},
}

left_shift = {
    north = 'west',
    south = 'east',
    east  = 'north',
    west  = 'south',
}

right_shift = {
    north = 'east',
    south = 'west',
    east  = 'south',
    west  = 'north',
}

reverse_shift = {
    north = 'south',
    south = 'north',
    east  = 'west',
    west  = 'east',
}

move = {
    forward = turtle.forward,
    up      = turtle.up,
    down    = turtle.down,
    back    = turtle.back,
    left    = turtle.turnLeft,
    right   = turtle.turnRight
}

detect = {
    forward = turtle.detect,
    up      = turtle.detectUp,
    down    = turtle.detectDown
}

inspect = {
    forward = turtle.inspect,
    up      = turtle.inspectUp,
    down    = turtle.inspectDown
}

dig = {
    forward = turtle.dig,
    up      = turtle.digUp,
    down    = turtle.digDown
}

attack = {
    forward = turtle.attack,
    up      = turtle.attackUp,
    down    = turtle.attackDown
}

getblock = {
    up = function(pos, fac)
        if not pos then pos = state.location end
        return {x = pos.x, y = pos.y + 1, z = pos.z}
    end,
    down = function(pos, fac)
        if not pos then pos = state.location end
        return {x = pos.x, y = pos.y - 1, z = pos.z}
    end,
    forward = function(pos, fac)
        if not pos then pos = state.location end
        if not fac then fac = state.orientation end
        local bump = bumps[fac]
        return {x = pos.x + bump[1], y = pos.y + bump[2], z = pos.z + bump[3]}
    end,
    back = function(pos, fac)
        if not pos then pos = state.location end
        if not fac then fac = state.orientation end
        local bump = bumps[fac]
        return {x = pos.x - bump[1], y = pos.y - bump[2], z = pos.z - bump[3]}
    end,
    left = function(pos, fac)
        if not pos then pos = state.location end
        if not fac then fac = state.orientation end
        local bump = bumps[left_shift[fac]]
        return {x = pos.x + bump[1], y = pos.y + bump[2], z = pos.z + bump[3]}
    end,
    right = function(pos, fac)
        if not pos then pos = state.location end
        if not fac then fac = state.orientation end
        local bump = bumps[right_shift[fac]]
        return {x = pos.x + bump[1], y = pos.y + bump[2], z = pos.z + bump[3]}
    end,
}


function digblock(direction) dig[direction]() return true end
function delay(duration) sleep(duration) return true end
function up() return go('up') end
function forward() return go('forward') end
function down() return go('down') end
function back() return go('back') end
function left() return go('left') end
function right() return go('right') end


function follow_route(route)
    for step in route:gmatch'.' do
        if step == 'u' then     if not go('up')      then return false end
        elseif step == 'f' then if not go('forward') then return false end
        elseif step == 'd' then if not go('down')    then return false end
        elseif step == 'b' then if not go('back')    then return false end
        elseif step == 'l' then if not go('left')    then return false end
        elseif step == 'r' then if not go('right')   then return false end
        end
    end
    return true
end


function face(orientation)
    if state.orientation == orientation then return true
    elseif right_shift[state.orientation] == orientation then
        if not go('right') then return false end
    elseif left_shift[state.orientation] == orientation then
        if not go('left') then return false end
    elseif right_shift[right_shift[state.orientation]] == orientation then
        if not go('right') then return false end
        if not go('right') then return false end
    else return false end
    return true
end


function log_movement(direction)
    if direction == 'up' then
        state.location.y = state.location.y + 1
    elseif direction == 'down' then
        state.location.y = state.location.y - 1
    elseif direction == 'forward' then
        local bump = bumps[state.orientation]
        state.location = {x = state.location.x + bump[1], y = state.location.y + bump[2], z = state.location.z + bump[3]}
    elseif direction == 'back' then
        local bump = bumps[state.orientation]
        state.location = {x = state.location.x - bump[1], y = state.location.y - bump[2], z = state.location.z - bump[3]}
    elseif direction == 'left' then
        state.orientation = left_shift[state.orientation]
    elseif direction == 'right' then
        state.orientation = right_shift[state.orientation]
    end
    return true
end


function go(direction, nodig)
    if not nodig then
        if detect[direction] and detect[direction]() then
            safedig(direction)
        end
    end
    if not move[direction] then return false end
    if not move[direction]() then
        if attack[direction] then attack[direction]() end
        return false
    end
    log_movement(direction)
    return true
end


function go_to_axis(axis, coordinate, nodig)
    local delta = coordinate - state.location[axis]
    if delta == 0 then return true end
    if axis == 'x' then
        if delta > 0 then if not face('east') then return false end
        else if not face('west') then return false end end
    elseif axis == 'z' then
        if delta > 0 then if not face('south') then return false end
        else if not face('north') then return false end end
    end
    for i = 1, math.abs(delta) do
        if axis == 'y' then
            if delta > 0 then if not go('up', nodig) then return false end
            else if not go('down', nodig) then return false end end
        else
            if not go('forward', nodig) then return false end
        end
    end
    return true
end


function go_to(end_location, end_orientation, path, nodig)
    if path then
        for axis in path:gmatch'.' do
            if not go_to_axis(axis, end_location[axis], nodig) then return false end
        end
    elseif end_location.path then
        for axis in end_location.path:gmatch'.' do
            if not go_to_axis(axis, end_location[axis], nodig) then return false end
        end
    else return false end
    if end_orientation then
        if not face(end_orientation) then return false end
    elseif end_location.orientation then
        if not face(end_location.orientation) then return false end
    end
    return true
end


function go_route(route, xyzo)
    local xyz_string
    if xyzo then xyz_string = str_xyz(xyzo) end
    local location_str = basics.str_xyz(state.location)
    while route[location_str] and location_str ~= xyz_string do
        if not go_to(route[location_str], nil, 'xyz') then return false end
        location_str = basics.str_xyz(state.location)
    end
    if xyzo then
        if location_str ~= xyz_string then return false end
        if xyzo.orientation then if not face(xyzo.orientation) then return false end end
    end
    return true
end


function go_to_home()
    state.updated_not_home = nil
    if basics.in_area(state.location, config.locations.home_area) then return true
    elseif basics.in_area(state.location, config.locations.greater_home_area) then
        if not go_to_home_exit() then return false end
    elseif basics.in_area(state.location, config.locations.waiting_room_area) then
        if not go_to(config.locations.mine_exit, nil, config.paths.waiting_room_to_mine_exit, true) then return false end
    elseif state.location.y < config.locations.mine_enter.y then return false end
    if config.locations.main_loop_route[basics.str_xyz(state.location)] then
        if not go_route(config.locations.main_loop_route, config.locations.home_enter) then return false end
    elseif basics.in_area(state.location, config.locations.control_room_area) then
        if not go_to(config.locations.home_enter, nil, config.paths.control_room_to_home_enter, true) then return false end
    else return false end
    if not forward() then return false end
    while detect.down() do if not forward() then return false end end
    if not down() then return false end
    if not right() then return false end
    if not right() then return false end
    return true
end


function go_to_home_exit()
    if basics.in_area(state.location, config.locations.greater_home_area) then
        if not go_to(config.locations.home_exit, nil, config.paths.home_to_home_exit) then return false end
    elseif config.locations.main_loop_route[basics.str_xyz(state.location)] then
        if not go_route(config.locations.main_loop_route, config.locations.home_exit) then return false end
    else return false end
    return true
end


function go_to_item_drop()
    if not config.locations.main_loop_route[basics.str_xyz(state.location)] then
        if not go_to_home() then return false end
        if not go_to_home_exit() then return false end
    end
    if not go_route(config.locations.main_loop_route, config.locations.item_drop) then return false end
    return true
end


function go_to_refuel()
    if not config.locations.main_loop_route[basics.str_xyz(state.location)] then
        if not go_to_home() then return false end
        if not go_to_home_exit() then return false end
    end
    if not go_route(config.locations.main_loop_route, config.locations.refuel) then return false end
    return true
end


function go_to_waiting_room()
    if not basics.in_area(state.location, config.locations.waiting_room_line_area) then
        if not go_to_home() then return false end
    end
    if not go_to(config.locations.waiting_room, nil, config.paths.home_to_waiting_room) then return false end
    return true
end


function go_to_mine_enter()
    if not go_route(config.locations.waiting_room_to_mine_enter_route) then return false end
    return true
end


function go_to_quadrant(assignment)
    -- Navigate to the top of the turtle's 4x4 quadrant
    local target = {
        x = assignment.quad_x,
        y = assignment.y_current,
        z = assignment.quad_z,
    }
    if state.location.y >= config.locations.mine_enter.y or basics.in_location(state.location, config.locations.mine_enter) then
        if not go_to(target, nil, config.paths.mine_enter_to_quadrant) then return false end
    else
        if not go_to(target, nil, 'yxz') then return false end
    end
    return true
end


function go_to_mine_exit(assignment)
    if state.location.y < config.locations.mine_enter.y or (state.location.x == config.locations.mine_exit.x and state.location.z == config.locations.mine_exit.z) then
        if state.location.x == config.locations.mine_enter.x and state.location.z == config.locations.mine_enter.z then
            if not go_to_axis('z', config.locations.mine_exit.z) then return false end
        elseif state.location.x ~= config.locations.mine_exit.x or state.location.z ~= config.locations.mine_exit.z then
            if not go_to_axis('y', config.locations.mine_enter.y - 2) then return false end
            if not go_to_axis('x', config.locations.mine_exit.x) then return false end
            if not go_to_axis('z', config.locations.mine_exit.z) then return false end
        end
        if not go_to(config.locations.mine_exit, nil, 'xzy') then return false end
        return true
    end
end


function safedig(direction)
    if not direction then direction = 'forward' end
    local block_name = ({inspect[direction]()})[2].name
    if block_name then
        for _, word in pairs(config.dig_disallow) do
            if string.find(string.lower(block_name), word) then return false end
        end
        return dig[direction]()
    end
    return true
end


function dump_items(omit)
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 and ((not omit) or (not omit[turtle.getItemDetail(slot).name])) then
            turtle.select(slot)
            if not turtle.drop() then return false end
        end
    end
    return true
end


function prepare(min_fuel_amount)
    if state.item_count > 0 then
        if not go_to_item_drop() then return false end
        if not dump_items(config.fuelnames) then return false end
    end
    min_fuel_amount = min_fuel_amount + config.fuel_padding
    if not go_to_refuel() then return false end
    if not dump_items() then return false end
    turtle.select(1)
    if turtle.getFuelLevel() ~= 'unlimited' then
        while turtle.getFuelLevel() < min_fuel_amount do
            if not turtle.suck(math.min(64, math.ceil(min_fuel_amount / config.fuel_per_unit))) then return false end
            turtle.refuel()
        end
    end
    return true
end


function calibrate()
    local sx, sy, sz = gps.locate()
    if not sx or not sy or not sz then return false end
    for i = 1, 4 do
        if not turtle.detect() then break end
        if not turtle.turnRight() then return false end
    end
    if turtle.detect() then
        for i = 1, 4 do
            safedig('forward')
            if not turtle.detect() then break end
            if not turtle.turnRight() then return false end
        end
        if turtle.detect() then return false end
    end
    if not turtle.forward() then return false end
    local nx, ny, nz = gps.locate()
    if nx == sx + 1 then state.orientation = 'east'
    elseif nx == sx - 1 then state.orientation = 'west'
    elseif nz == sz + 1 then state.orientation = 'south'
    elseif nz == sz - 1 then state.orientation = 'north'
    else return false end
    state.location = {x = nx, y = ny, z = nz}
    print('Calibrated to ' .. str_xyz(state.location, state.orientation))
    back()
    if basics.in_area(state.location, config.locations.home_area) then
        face(left_shift[left_shift[config.locations.homes.increment]])
    end
    return true
end


function initialize(session_id, config_values)
    state.session_id = session_id
    for k, v in pairs(config_values) do config[k] = v end
    state.peripheral_left = peripheral.getType('left')
    state.peripheral_right = peripheral.getType('right')
    if state.peripheral_left == 'chunkLoader' or state.peripheral_right == 'chunkLoader' or state.peripheral_left == 'chunky' or state.peripheral_right == 'chunky' then
        state.type = 'chunky'
        for k, v in pairs(config.chunky_turtle_locations) do config.locations[k] = v end
    else
        state.type = 'mining'
        for k, v in pairs(config.mining_turtle_locations) do config.locations[k] = v end
        if state.peripheral_left == 'modem' then state.peripheral_right = 'pick'
        else state.peripheral_left = 'pick' end
    end
    state.request_id = 1
    state.initialized = true
    return true
end


function getcwd()
    local running_program = shell.getRunningProgram()
    local program_name = fs.getName(running_program)
    return "/" .. running_program:sub(1, #running_program - #program_name)
end

function pass() return true end

function dump(direction)
    if not face(direction) then return false end
    if ({inspect.forward()})[2].name ~= 'computercraft:turtle_advanced' then return false end
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            turtle.drop()
        end
    end
    return true
end


---============================================---
---     4x4 QUADRANT MINING                    ---
---============================================---


function drop_junk()
    if config.filter_items and config.skip_blocks then
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                local detail = turtle.getItemDetail(slot)
                if detail and config.skip_blocks[detail.name] then
                    turtle.select(slot)
                    turtle.dropDown()
                end
            end
        end
        turtle.select(1)
    end
    return true
end


function inventory_full()
    local empty = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then empty = empty + 1 end
    end
    return empty <= 1
end


function mine_4x4_layer()
    -- Mine a single 4x4 layer at current Y.
    -- Serpentine pattern: east 3, step south, west 3, step south, ...
    -- Also digs up to clear the block above.
    
    local qs = config.quadrant_size or 4
    
    if not face('east') then return false end
    
    for row = 0, qs - 1 do
        -- Mine row: 3 forward moves (4 blocks including start pos)
        for col = 1, qs - 1 do
            safedig('up')
            safedig('forward')
            if not go('forward') then
                safedig('forward')
                if not go('forward') then return false end
            end
            if inventory_full() then drop_junk() end
        end
        
        -- Dig above at end of row
        safedig('up')
        
        -- Step to next row
        if row < qs - 1 then
            if not face('south') then return false end
            safedig('forward')
            if not go('forward') then
                safedig('forward')
                if not go('forward') then return false end
            end
            -- Reverse direction
            if row % 2 == 0 then
                if not face('west') then return false end
            else
                if not face('east') then return false end
            end
        end
    end
    
    return true
end


function mine_quadrant(assignment)
    -- Mine the turtle's assigned 4x4 column from y_current down to y_bottom.
    -- Each layer pass covers 2 Y-levels (current + above via digUp).
    -- Returns to surface when inventory full or fuel low.
    --
    -- assignment = {quad_x, quad_z, y_current, y_bottom}
    
    local quad_x = assignment.quad_x
    local quad_z = assignment.quad_z
    local y = assignment.y_current
    local y_bottom = assignment.y_bottom
    
    print('Mining 4x4 at ' .. quad_x .. ',' .. quad_z .. ' from Y=' .. y)
    
    while y >= y_bottom do
        
        -- Check fuel: enough for layer + return?
        local fuel_for_return = math.abs(y - config.locations.mine_enter.y)
                              + math.abs(quad_x - config.locations.mine_enter.x)
                              + math.abs(quad_z - config.locations.mine_enter.z)
                              + config.fuel_padding
        local fuel_for_layer = (config.quadrant_size or 4) * (config.quadrant_size or 4) * 3
        
        if turtle.getFuelLevel() ~= 'unlimited' and turtle.getFuelLevel() < (fuel_for_return + fuel_for_layer) then
            print('Fuel niedrig, kehre um bei Y=' .. y)
            break
        end
        
        -- Check inventory
        if inventory_full() then
            drop_junk()
            if inventory_full() then
                print('Inventar voll bei Y=' .. y)
                break
            end
        end
        
        -- Navigate to layer start (corner of our 4x4)
        if not go_to_axis('x', quad_x) then break end
        if not go_to_axis('z', quad_z) then break end
        if not go_to_axis('y', y) then break end
        
        -- Mine the 4x4 layer
        if not mine_4x4_layer() then
            print('Layer-Mining fehlgeschlagen bei Y=' .. y)
            break
        end
        
        drop_junk()
        
        -- Move down 2 for next layer
        y = y - 2
        
        if y >= y_bottom then
            -- Go back to corner and down
            if not go_to_axis('x', quad_x) then break end
            if not go_to_axis('z', quad_z) then break end
            if not go_to_axis('y', y) then break end
        end
    end
    
    -- Report progress
    state.quadrant_y_progress = y
    
    -- Navigate back to quadrant column for clean exit
    if not go_to_axis('x', quad_x) then return false end
    if not go_to_axis('z', quad_z) then return false end
    
    return true
end

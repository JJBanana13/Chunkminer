inf = basics.inf
str_xyz = basics.str_xyz

reverse_shift = {
    north = 'south',
    south = 'north',
    east  = 'west',
    west  = 'east',
}


function load_mine()
    state.mine_dir_path = '/mine/' .. config.locations.mine_enter.x .. ',' .. config.locations.mine_enter.z .. '/'
    state.chunks = {}
    state.current_chunk = nil

    if not fs.exists(state.mine_dir_path) then fs.makeDir(state.mine_dir_path) end
    if fs.exists(state.mine_dir_path .. 'on') then state.on = true end

    -- Load chunk history
    local chunks_dir = state.mine_dir_path .. 'chunks/'
    if not fs.exists(chunks_dir) then
        fs.makeDir(chunks_dir)
    else
        for _, fn in pairs(fs.list(chunks_dir)) do
            if fn:sub(1,1) ~= '.' then
                local f = fs.open(chunks_dir .. fn, 'r')
                if f then
                    local parts = string.gmatch(f.readAll(), '[^,]+')
                    f.close()
                    state.chunks[fn] = {
                        y_current = tonumber(parts()),
                        done = (parts() == 'true'),
                    }
                end
            end
        end
    end

    -- Load current chunk
    if fs.exists(state.mine_dir_path .. 'current_chunk') then
        local f = fs.open(state.mine_dir_path .. 'current_chunk', 'r')
        if f then
            local parts = string.gmatch(f.readAll(), '[^,]+')
            f.close()
            local cx, cz, yt, yc = tonumber(parts()), tonumber(parts()), tonumber(parts()), tonumber(parts())
            if cx and cz and yt and yc then
                state.current_chunk = {chunk_x=cx, chunk_z=cz, y_top=yt, y_current=yc, y_bottom=config.mine_y_bottom}
                local key = get_chunk_key(cx, cz)
                if state.chunks[key] and state.chunks[key].done then state.current_chunk = nil end
            end
        end
    end

    -- Load turtles
    state.turtles_dir_path = state.mine_dir_path .. 'turtles/'
    if not fs.exists(state.turtles_dir_path) then fs.makeDir(state.turtles_dir_path) end

    for _, tid in pairs(fs.list(state.turtles_dir_path)) do
        if tid:sub(1,1) ~= '.' then
            local turtle_id = tonumber(tid)
            local t = {id = turtle_id}
            state.turtles[turtle_id] = t
            local tdir = state.turtles_dir_path .. turtle_id .. '/'

            if fs.exists(tdir .. 'quadrant') then
                local f = fs.open(tdir .. 'quadrant', 'r')
                if f then
                    local parts = string.gmatch(f.readAll(), '[^,]+')
                    f.close()
                    t.chunk_assignment = {
                        quad_x = tonumber(parts()),
                        quad_z = tonumber(parts()),
                        y_current = tonumber(parts()),
                        y_bottom = tonumber(parts()),
                        slot = tonumber(parts()),
                    }
                    if fs.exists(tdir .. 'deployed') then t.deployed = true end
                end
            end
            if fs.exists(tdir .. 'halt') then t.state = 'halt' end
        end
    end
end


function get_chunk_key(cx, cz) return cx .. '_' .. cz end


function save_chunk_progress(cx, cz, yc, done)
    local f = fs.open(state.mine_dir_path .. 'chunks/' .. get_chunk_key(cx,cz), 'w')
    f.write(yc .. ',' .. tostring(done or false))
    f.close()
    state.chunks[get_chunk_key(cx,cz)] = {y_current=yc, done=done or false}
end


function save_current_chunk()
    if state.current_chunk then
        local cc = state.current_chunk
        local f = fs.open(state.mine_dir_path .. 'current_chunk', 'w')
        f.write(cc.chunk_x..','..cc.chunk_z..','..cc.y_top..','..cc.y_current)
        f.close()
    else
        fs.delete(state.mine_dir_path .. 'current_chunk')
    end
end


function write_turtle_quadrant(turtle)
    local a = turtle.chunk_assignment
    local f = fs.open(state.turtles_dir_path .. turtle.id .. '/quadrant', 'w')
    f.write(a.quad_x..','..a.quad_z..','..a.y_current..','..a.y_bottom..','..a.slot)
    f.close()
end


function halt(turtle)
    add_task(turtle, {action = 'pass', end_state = 'halt'})
    fs.open(state.turtles_dir_path .. turtle.id .. '/halt', 'w').close()
end

function unhalt(turtle)
    fs.delete(state.turtles_dir_path .. turtle.id .. '/halt', 'w')
end


function get_next_chunk()
    local cs = config.chunk_size or 16
    local base_cx = math.floor(config.locations.mine_enter.x / cs) * cs
    local base_cz = math.floor(config.locations.mine_enter.z / cs) * cs
    local dx, dz, dir = 0, 0, 0
    local steps_in_dir, steps_taken, turns = 1, 0, 0

    for i = 1, 400 do
        local cx = base_cx + dx * cs
        local cz = base_cz + dz * cs
        local key = get_chunk_key(cx, cz)
        local cs_state = state.chunks[key]

        if not (cs_state and cs_state.done) then
            local y_start = config.mine_y_top
            if cs_state and cs_state.y_current then y_start = cs_state.y_current end
            if y_start >= config.mine_y_bottom then
                return {chunk_x=cx, chunk_z=cz, y_top=y_start, y_current=y_start, y_bottom=config.mine_y_bottom}
            end
        end

        if dir == 0 then dx = dx+1 elseif dir == 1 then dz = dz+1
        elseif dir == 2 then dx = dx-1 elseif dir == 3 then dz = dz-1 end
        steps_taken = steps_taken + 1
        if steps_taken >= steps_in_dir then
            steps_taken = 0
            dir = (dir + 1) % 4
            turns = turns + 1
            if turns % 2 == 0 then steps_in_dir = steps_in_dir + 1 end
        end
    end
    return nil
end


function ensure_current_chunk()
    if state.current_chunk then
        if state.current_chunk.y_current < config.mine_y_bottom then
            save_chunk_progress(state.current_chunk.chunk_x, state.current_chunk.chunk_z, state.current_chunk.y_current, true)
            print('>>> Chunk ' .. state.current_chunk.chunk_x .. ',' .. state.current_chunk.chunk_z .. ' FERTIG! <<<')
            state.current_chunk = nil
        end
    end
    if not state.current_chunk then
        state.current_chunk = get_next_chunk()
        if state.current_chunk then
            print('Neuer Chunk: ' .. state.current_chunk.chunk_x .. ',' .. state.current_chunk.chunk_z)
            save_current_chunk()
        end
    end
    return state.current_chunk ~= nil
end


function get_free_quadrant_slot()
    -- Find a quadrant slot (0-15) not currently assigned to any deployed turtle
    if not state.current_chunk then return nil end
    local used = {}
    for _, t in pairs(state.turtles) do
        if t.deployed and t.chunk_assignment and t.chunk_assignment.slot then
            used[t.chunk_assignment.slot] = true
        end
    end
    for slot = 0, 15 do
        if not used[slot] then return slot end
    end
    return nil
end


function assign_turtle(turtle)
    if not ensure_current_chunk() then return nil end
    local slot = get_free_quadrant_slot()
    if slot == nil then return nil end

    local qm = config.quadrant_map[slot]
    local assignment = {
        quad_x = state.current_chunk.chunk_x + qm.x_offset,
        quad_z = state.current_chunk.chunk_z + qm.z_offset,
        y_current = state.current_chunk.y_current,
        y_bottom = config.mine_y_bottom,
        slot = slot,
    }
    return assignment
end


function update_chunk_progress_from_turtle(turtle)
    if not turtle.chunk_assignment then return end
    -- Update turtle's own y progress
    if turtle.data and turtle.data.quadrant_y_progress then
        turtle.chunk_assignment.y_current = turtle.data.quadrant_y_progress
        write_turtle_quadrant(turtle)
    end
    -- Update global chunk progress: the highest y_current among all deployed turtles
    -- (chunk is only "done" when ALL quadrants are done)
    if state.current_chunk then
        local worst_y = -999
        local any_deployed = false
        for _, t in pairs(state.turtles) do
            if t.deployed and t.chunk_assignment then
                any_deployed = true
                if t.chunk_assignment.y_current > worst_y then
                    worst_y = t.chunk_assignment.y_current
                end
            end
        end
        if not any_deployed then
            -- Nobody mining -> update based on this returning turtle
            worst_y = turtle.chunk_assignment.y_current
        end
        if worst_y < state.current_chunk.y_current then
            state.current_chunk.y_current = worst_y
            save_current_chunk()
            save_chunk_progress(state.current_chunk.chunk_x, state.current_chunk.chunk_z, worst_y, worst_y < config.mine_y_bottom)
        end
    end
end


function good_on_fuel(mining_turtle, chunky_turtle)
    local needed = config.fuel_padding * 2
    if mining_turtle.data and mining_turtle.data.location then
        needed = math.ceil(basics.distance(mining_turtle.data.location, config.locations.mine_exit) * 1.5) + config.fuel_padding
    end
    local ok = (mining_turtle.data.fuel_level == "unlimited" or mining_turtle.data.fuel_level > needed)
    if config.use_chunky_turtles and chunky_turtle then
        ok = ok and (chunky_turtle.data.fuel_level == "unlimited" or chunky_turtle.data.fuel_level > needed)
    end
    return ok
end


function calc_min_fuel()
    if state.current_chunk then
        local dist = basics.distance(
            {x=state.current_chunk.chunk_x, y=state.current_chunk.y_current, z=state.current_chunk.chunk_z},
            config.locations.mine_enter)
        return (dist + 4*4* math.abs(state.current_chunk.y_current - config.mine_y_bottom) * 2) * 2
    end
    return config.fuel_padding * 4
end


function follow_to_quadrant(chunky_turtle)
    add_task(chunky_turtle, {
        action = 'go_to_quadrant', data = {chunky_turtle.chunk_assignment}, end_state = 'wait',
    })
end


function go_mine_quadrant(mining_turtle)
    add_task(mining_turtle, {
        action = 'mine_quadrant', data = {mining_turtle.chunk_assignment}, end_state = 'wait',
    })
end


function free_turtle(turtle)
    if turtle.deployed then
        update_chunk_progress_from_turtle(turtle)
        fs.delete(state.turtles_dir_path .. turtle.id .. '/deployed')
        turtle.deployed = nil
    end
    if turtle.pair then
        if turtle.pair.deployed then
            update_chunk_progress_from_turtle(turtle.pair)
            fs.delete(state.turtles_dir_path .. turtle.pair.id .. '/deployed')
            turtle.pair.deployed = nil
        end
        turtle.pair.pair = nil
        turtle.pair = nil
    end
    turtle.chunk_assignment = nil
end


function pair_turtles_finish() state.pair_hold = nil end

function pair_turtles_send(chunky_turtle)
    add_task(chunky_turtle, {action='go_to_mine_enter', end_function=pair_turtles_finish})
    add_task(chunky_turtle, {action='go_to_quadrant', data={chunky_turtle.chunk_assignment}, end_state='wait'})
end


function pair_turtles_begin(t1, t2)
    local mt, ct
    if t1.data.turtle_type == 'mining' then mt, ct = t1, t2
    else mt, ct = t2, t1 end

    local assignment = assign_turtle(mt)
    if not assignment then
        add_task(mt, {action='pass', end_state='idle'})
        add_task(ct, {action='pass', end_state='idle'})
        return
    end

    print('Paar '..mt.id..'+'..ct.id..' -> Slot '..assignment.slot..' ('..assignment.quad_x..','..assignment.quad_z..')')

    mt.pair, ct.pair = ct, mt
    state.pair_hold = {mt, ct}

    mt.chunk_assignment = assignment
    ct.chunk_assignment = assignment
    mt.deployed, ct.deployed = true, true

    write_turtle_quadrant(mt)
    write_turtle_quadrant(ct)
    fs.open(state.turtles_dir_path .. ct.id .. '/deployed', 'w').close()
    fs.open(state.turtles_dir_path .. mt.id .. '/deployed', 'w').close()

    add_task(mt, {action='pass', end_state='trip'})
    add_task(ct, {action='pass', end_state='trip'})
    add_task(mt, {action='go_to_mine_enter', end_function=pair_turtles_send, end_function_args={ct}})
    add_task(mt, {action='go_to_quadrant', data={mt.chunk_assignment}, end_state='wait'})
end


function solo_turtle_begin(turtle)
    local assignment = assign_turtle(turtle)
    if not assignment then
        add_task(turtle, {action='pass', end_state='idle'})
        return
    end

    print('Turtle '..turtle.id..' -> Slot '..assignment.slot..' ('..assignment.quad_x..','..assignment.quad_z..')')

    turtle.chunk_assignment = assignment
    turtle.deployed = true
    write_turtle_quadrant(turtle)
    fs.open(state.turtles_dir_path .. turtle.id .. '/deployed', 'w').close()

    add_task(turtle, {action='pass', end_state='trip'})
    add_task(turtle, {action='go_to_mine_enter'})
    add_task(turtle, {action='go_to_quadrant', data={turtle.chunk_assignment}, end_state='wait'})
end


function check_pair_fuel(turtle)
    local min_fuel = calc_min_fuel()
    if turtle.data.fuel_level ~= "unlimited" and turtle.data.fuel_level <= min_fuel then
        add_task(turtle, {action='prepare', data={min_fuel}})
    else
        add_task(turtle, {action='pass', end_state='pair'})
    end
end


function send_turtle_up(turtle)
    if turtle.data.location.y < config.locations.mine_enter.y then
        add_task(turtle, {action='go_to_mine_exit', data={turtle.chunk_assignment}})
    end
end


function initialize_turtle(turtle)
    if turtle.state ~= 'halt' then turtle.state = 'lost' end
    turtle.task_id = 2
    turtle.tasks = {}
    add_task(turtle, {action='initialize', data={session_id, config}})
end


function add_task(turtle, task)
    if not task.data then task.data = {} end
    table.insert(turtle.tasks, task)
end


function send_tasks(turtle)
    local task = turtle.tasks[1]
    if not task then return end
    local td = turtle.data
    if td.request_id == turtle.task_id and td.session_id == session_id then
        if td.success then
            if task.end_state then
                if turtle.state == 'halt' and task.end_state ~= 'halt' then unhalt(turtle) end
                turtle.state = task.end_state
            end
            if task.end_function then
                if task.end_function_args then task.end_function(unpack(task.end_function_args))
                else task.end_function() end
            end
            table.remove(turtle.tasks, 1)
        end
        turtle.task_id = turtle.task_id + 1
    elseif (not td.busy) and ((not task.epoch) or (task.epoch > os.clock()) or (task.epoch + config.task_timeout < os.clock())) then
        task.epoch = os.clock()
        print(string.format('-> %s an T%d', task.action, turtle.id))
        rednet.send(turtle.id, {action=task.action, data=task.data, request_id=td.request_id}, 'mastermine')
    end
end


function user_input()
    while #state.user_input > 0 do
        local input = table.remove(state.user_input, 1)
        local nw = string.gmatch(input, '%S+')
        local cmd = nw()
        local tid_str = nw()
        local turtles = {}
        if tid_str and tid_str ~= '*' then
            local tid = tonumber(tid_str)
            if state.turtles[tid] then turtles = {state.turtles[tid]} end
        else
            turtles = state.turtles
        end

        if cmd == 'turtle' then
            local action = nw()
            local data = {}
            for a in nw do table.insert(data, a) end
            for _, t in pairs(turtles) do halt(t); add_task(t, {action=action, data=data}) end
        elseif cmd == 'clear' then
            for _, t in pairs(turtles) do t.tasks = {}; add_task(t, {action='pass'}) end
        elseif cmd == 'shutdown' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); rednet.send(t.id,{action='shutdown'},'mastermine') end
        elseif cmd == 'reboot' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); rednet.send(t.id,{action='reboot'},'mastermine') end
        elseif cmd == 'update' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); rednet.send(t.id,{action='update'},'mastermine') end
        elseif cmd == 'return' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); halt(t); send_turtle_up(t); add_task(t,{action='go_to_home'}) end
        elseif cmd == 'halt' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); halt(t) end
        elseif cmd == 'reset' then
            for _, t in pairs(turtles) do t.tasks={}; add_task(t,{action='pass'}); add_task(t,{action='pass',end_state='lost'}) end
        elseif cmd == 'on' or cmd == 'go' then
            if not tid_str then
                for _, t in pairs(state.turtles) do t.tasks={}; add_task(t,{action='pass'}) end
                state.on = true
                fs.open(state.mine_dir_path .. 'on', 'w').close()
            end
        elseif cmd == 'off' or cmd == 'stop' then
            if not tid_str then
                for _, t in pairs(state.turtles) do t.tasks={}; add_task(t,{action='pass'}); free_turtle(t) end
                state.on = nil; fs.delete(state.mine_dir_path .. 'on')
            end
        elseif cmd == 'hubshutdown' then if not tid_str then os.shutdown() end
        elseif cmd == 'hubreboot'   then if not tid_str then os.reboot() end
        elseif cmd == 'hubupdate'   then if not tid_str then os.run({}, '/update') end
        elseif cmd == 'status' then
            print('=== ChunkMine Status ===')
            local done_n, active_n, total_n = 0, 0, 0
            for _, c in pairs(state.chunks) do if c.done then done_n = done_n+1 end end
            for _, t in pairs(state.turtles) do
                total_n = total_n + 1
                if t.deployed then active_n = active_n + 1 end
            end
            print('Turtles: ' .. active_n .. '/' .. total_n .. ' aktiv')
            print('Chunks fertig: ' .. done_n)
            if state.current_chunk then
                local cc = state.current_chunk
                print('Chunk: ' .. cc.chunk_x .. ',' .. cc.chunk_z)
                print('  Y: ' .. cc.y_current .. ' -> ' .. config.mine_y_bottom)
                -- Show quadrant assignment
                for _, t in pairs(state.turtles) do
                    if t.deployed and t.chunk_assignment then
                        print('  T' .. t.id .. ' -> Slot ' .. t.chunk_assignment.slot .. ' Y=' .. t.chunk_assignment.y_current)
                    end
                end
            else
                print('Kein aktiver Chunk')
            end
        end
    end
end


function command_turtles()
    local turtles_for_pair = {}
    ensure_current_chunk()

    for _, turtle in pairs(state.turtles) do
        if turtle.data then

            if turtle.data.session_id ~= session_id then
                if (not turtle.tasks) or (not turtle.tasks[1]) or (turtle.tasks[1].action ~= 'initialize') then
                    initialize_turtle(turtle)
                end
            end

            if #turtle.tasks > 0 then
                send_tasks(turtle)

            elseif not turtle.data.location then
                add_task(turtle, {action='calibrate'})

            elseif turtle.state ~= 'halt' then

                if turtle.state == 'park' then
                    if state.on and (not config.use_chunky_turtles or turtle.data.turtle_type == 'mining' or turtle.data.turtle_type == 'chunky') then
                        add_task(turtle, {action='pass', end_state='idle'})
                    end

                elseif not state.on and turtle.state ~= 'idle' then
                    add_task(turtle, {action='pass', end_state='idle'})

                elseif turtle.state == 'lost' then
                    if turtle.data.location.y < config.locations.mine_enter.y and turtle.chunk_assignment then
                        add_task(turtle, {action='pass', end_state='trip'})
                        add_task(turtle, {action='go_to_quadrant', data={turtle.chunk_assignment}, end_state='wait'})
                    else
                        add_task(turtle, {action='pass', end_state='idle'})
                    end

                elseif turtle.state == 'idle' then
                    free_turtle(turtle)
                    if turtle.data.location.y < config.locations.mine_enter.y then
                        send_turtle_up(turtle)
                    elseif not basics.in_area(turtle.data.location, config.locations.control_room_area) then
                        halt(turtle)
                    elseif turtle.data.item_count > 0 or (turtle.data.fuel_level ~= "unlimited" and turtle.data.fuel_level < config.fuel_per_unit) then
                        add_task(turtle, {action='prepare', data={config.fuel_per_unit}})
                    elseif state.on then
                        add_task(turtle, {action='go_to_waiting_room', end_function=check_pair_fuel, end_function_args={turtle}})
                    else
                        add_task(turtle, {action='go_to_home', end_state='park'})
                    end

                elseif turtle.state == 'pair' then
                    if config.use_chunky_turtles then
                        if not state.pair_hold then
                            if not turtle.pair then table.insert(turtles_for_pair, turtle) end
                        else
                            if not (state.pair_hold[1].pair and state.pair_hold[2].pair) then state.pair_hold = nil end
                        end
                    else
                        solo_turtle_begin(turtle)
                    end

                elseif turtle.state == 'wait' then
                    if turtle.pair then
                        if turtle.data.turtle_type == 'mining' and turtle.pair.state == 'wait' then
                            local a = turtle.chunk_assignment
                            local done = a and a.y_current and a.y_current < a.y_bottom

                            if done or (turtle.data.empty_slot_count == 0 and turtle.pair.data.empty_slot_count == 0) or not good_on_fuel(turtle, turtle.pair) then
                                update_chunk_progress_from_turtle(turtle)
                                add_task(turtle, {action='pass', end_state='idle'})
                                add_task(turtle.pair, {action='pass', end_state='idle'})
                            elseif turtle.data.empty_slot_count == 0 then
                                add_task(turtle, {action='dump', data={reverse_shift[turtle.data.orientation or 'north']}})
                            else
                                add_task(turtle, {action='pass', end_state='mine'})
                                add_task(turtle.pair, {action='pass', end_state='mine'})
                                go_mine_quadrant(turtle)
                                follow_to_quadrant(turtle.pair)
                            end
                        end
                    elseif not config.use_chunky_turtles then
                        local a = turtle.chunk_assignment
                        local done = a and a.y_current and a.y_current < a.y_bottom

                        if done or turtle.data.empty_slot_count == 0 or not good_on_fuel(turtle) then
                            update_chunk_progress_from_turtle(turtle)
                            add_task(turtle, {action='pass', end_state='idle'})
                        else
                            add_task(turtle, {action='pass', end_state='mine'})
                            go_mine_quadrant(turtle)
                        end
                    else
                        add_task(turtle, {action='pass', end_state='idle'})
                    end

                elseif turtle.state == 'mine' then
                    if config.use_chunky_turtles and not turtle.pair then
                        add_task(turtle, {action='pass', end_state='idle'})
                    end
                end
            end
        end
    end

    if #turtles_for_pair == 2 then
        pair_turtles_begin(turtles_for_pair[1], turtles_for_pair[2])
    end
end


function main()
    if fs.exists('/session_id') then
        session_id = tonumber(fs.open('/session_id', 'r').readAll()) + 1
    else session_id = 1 end
    local f = fs.open('/session_id', 'w'); f.write(session_id); f.close()

    load_mine()
    ensure_current_chunk()

    local cycle = 0
    while true do
        print('Cycle: ' .. cycle)
        user_input()
        command_turtles()
        sleep(0.1)
        cycle = cycle + 1
    end
end

main()

inf = 999999

---==[ CHUNKMINE - ATM10 Mining Dimension ]==---
-- 16 Turtles pro Chunk, jede baut ein 4x4 Quadrat
-- von oben nach unten komplett ab.
--
--  Chunk 16x16 Aufteilung:
--
--   +----+----+----+----+
--   | T1 | T2 | T3 | T4 |   z+0..3
--   +----+----+----+----+
--   | T5 | T6 | T7 | T8 |   z+4..7
--   +----+----+----+----+
--   | T9 |T10 |T11 |T12 |   z+8..11
--   +----+----+----+----+
--   |T13 |T14 |T15 |T16 |   z+12..15
--   +----+----+----+----+
--    x+0  x+4  x+8  x+12
--


-- LOCATION OF THE CENTER OF THE MINE
--     y = 1 above surface
mine_entrance = {x = 104, y = 76, z = 215}
c = mine_entrance


-- CHUNKY TURTLES (Chunk Loader Peripherals)
--     set false if not using Advanced Peripherals
use_chunky_turtles = false


-- CHUNK SIZE (don't change)
chunk_size = 16


-- QUADRANT SIZE PER TURTLE (don't change)
quadrant_size = 4


-- NUMBER OF TURTLES
num_turtles = 16


-- MINING DIMENSION Y RANGE
mine_y_top = 64
mine_y_bottom = 5


-- FUEL
fuel_padding = 100
fuel_per_unit = 80


-- TIMEOUTS
turtle_timeout = 5
pocket_timeout = 5
task_timeout = 0.5


-- BLOCKS NOT TO DIG
dig_disallow = {
    'computer',
    'chest',
    'turtle',
}


-- BLOCKS TO THROW AWAY (saves inventory space)
skip_blocks = {
    ['minecraft:stone'] = true,
    ['minecraft:cobblestone'] = true,
    ['minecraft:cobbled_deepslate'] = true,
    ['minecraft:dirt'] = true,
    ['minecraft:gravel'] = true,
    ['minecraft:sand'] = true,
    ['minecraft:sandstone'] = true,
    ['minecraft:netherrack'] = true,
    ['minecraft:granite'] = true,
    ['minecraft:diorite'] = true,
    ['minecraft:andesite'] = true,
    ['minecraft:deepslate'] = true,
    ['minecraft:tuff'] = true,
    ['minecraft:calcite'] = true,
    ['minecraft:smooth_basalt'] = true,
    ['minecraft:basalt'] = true,
    ['minecraft:blackstone'] = true,
    ['minecraft:end_stone'] = true,
}

filter_items = true


-- FUEL ITEMS
fuelnames = {
    ['minecraft:coal'] = true,
    ['minecraft:charcoal'] = true,
}


---==[ QUADRANT MAP ]==---
-- Maps slot 0-15 to x/z offsets within the chunk.
-- Slot 0 = top-left 4x4, slot 15 = bottom-right 4x4
-- Each entry: {x_offset, z_offset}
quadrant_map = {}
for row = 0, 3 do
    for col = 0, 3 do
        quadrant_map[row * 4 + col] = {
            x_offset = col * 4,
            z_offset = row * 4,
        }
    end
end


---==[ PATHS / LOCATIONS ]==---

paths = {
    home_to_home_exit          = 'zyx',
    control_room_to_home_enter = 'yzx',
    home_to_waiting_room       = 'zyx',
    waiting_room_to_mine_exit  = 'yzx',
    mine_enter_to_quadrant     = 'yxz',
}


locations = {
    mine_enter = {x = c.x+0, y = c.y+0, z = c.z+0},
    mine_exit = {x = c.x+0, y = c.y+1, z = c.z+1},
    item_drop = {x = c.x+2, y = c.y+1, z = c.z+1, orientation = 'east'},
    refuel = {x = c.x+2, y = c.y+1, z = c.z+0, orientation = 'east'},

    greater_home_area = {
        min_x = -inf, max_x = c.x-3,
        min_y = c.y+0, max_y = c.y+1,
        min_z = c.z-1, max_z = c.z+2
    },
    control_room_area = {
        min_x = c.x-16, max_x = c.x+8,
        min_y = c.y+0, max_y = c.y+8,
        min_z = c.z-8, max_z = c.z+8
    },
    waiting_room_line_area = {
        min_x = -inf, max_x = c.x-2,
        min_y = c.y+0, max_y = c.y+0,
        min_z = c.z+0, max_z = c.z+1
    },
    waiting_room_area = {
        min_x = c.x-2, max_x = c.x+0,
        min_y = c.y+0, max_y = c.y+0,
        min_z = c.z+0, max_z = c.z+1
    },

    main_loop_route = {
        [c.x-1 .. ',' .. c.y+1 .. ',' .. c.z-1] = {x = c.x-2, y = c.y+1, z = c.z-1},
        [c.x-2 .. ',' .. c.y+1 .. ',' .. c.z-1] = {x = c.x-2, y = c.y+1, z = c.z+0},
        [c.x-2 .. ',' .. c.y+1 .. ',' .. c.z+0] = {x = c.x-2, y = c.y+1, z = c.z+1},
        [c.x-2 .. ',' .. c.y+1 .. ',' .. c.z+1] = {x = c.x-2, y = c.y+1, z = c.z+2},
        [c.x-2 .. ',' .. c.y+1 .. ',' .. c.z+2] = {x = c.x-1, y = c.y+1, z = c.z+2},
        [c.x-1 .. ',' .. c.y+1 .. ',' .. c.z+2] = {x = c.x+0, y = c.y+1, z = c.z+2},
        [c.x+0 .. ',' .. c.y+1 .. ',' .. c.z+2] = {x = c.x+0, y = c.y+1, z = c.z+1},
        [c.x+0 .. ',' .. c.y+1 .. ',' .. c.z+1] = {x = c.x+1, y = c.y+1, z = c.z+1},
        [c.x+1 .. ',' .. c.y+1 .. ',' .. c.z+1] = {x = c.x+2, y = c.y+1, z = c.z+1},
        [c.x+2 .. ',' .. c.y+1 .. ',' .. c.z+1] = {x = c.x+2, y = c.y+1, z = c.z+0},
        [c.x+2 .. ',' .. c.y+1 .. ',' .. c.z+0] = {x = c.x+2, y = c.y+1, z = c.z-1},
        [c.x+2 .. ',' .. c.y+1 .. ',' .. c.z-1] = {x = c.x+1, y = c.y+1, z = c.z-1},
        [c.x+1 .. ',' .. c.y+1 .. ',' .. c.z-1] = {x = c.x+0, y = c.y+1, z = c.z-1},
        [c.x+0 .. ',' .. c.y+1 .. ',' .. c.z-1] = {x = c.x-1, y = c.y+1, z = c.z-1},
    },
}


mining_turtle_locations = {
    homes = {x = c.x-3, y = c.y+0, z = c.z-3, increment = 'west'},
    home_area = {
        min_x = -inf, max_x = c.x-3,
        min_y = c.y+0, max_y = c.y+0,
        min_z = c.z-1, max_z = c.z-1
    },
    home_enter = {x = c.x-2, y = c.y+1, z = c.z-1, orientation = 'west'},
    home_exit = {x = c.x-2, y = c.y+1, z = c.z+0},
    waiting_room = {x = c.x-2, y = c.y+0, z = c.z+0},
    waiting_room_to_mine_enter_route = {
        [c.x-2 .. ',' .. c.y+0 .. ',' .. c.z+0] = {x = c.x-1, y = c.y+0, z = c.z+0},
        [c.x-1 .. ',' .. c.y+0 .. ',' .. c.z+0] = {x = c.x+0, y = c.y+0, z = c.z+0},
    }
}


chunky_turtle_locations = {
    homes = {x = c.x-3, y = c.y+0, z = c.z+2, increment = 'west'},
    home_area = {
        min_x = -inf, max_x = c.x-3,
        min_y = c.y+0, max_y = c.y+0,
        min_z = c.z+2, max_z = c.z+2
    },
    home_enter = {x = c.x-2, y = c.y+1, z = c.z+2, orientation = 'west'},
    home_exit = {x = c.x-2, y = c.y+1, z = c.z+1},
    waiting_room = {x = c.x-2, y = c.y+0, z = c.z+1},
    waiting_room_to_mine_enter_route = {
        [c.x-2 .. ',' .. c.y+0 .. ',' .. c.z+1] = {x = c.x-1, y = c.y+0, z = c.z+1},
        [c.x-1 .. ',' .. c.y+0 .. ',' .. c.z+1] = {x = c.x-1, y = c.y+0, z = c.z+0},
        [c.x-1 .. ',' .. c.y+0 .. ',' .. c.z+0] = {x = c.x+0, y = c.y+0, z = c.z+0},
    }
}


---==[ SCREEN ]==---

monitor_max_zoom_level = 5
default_monitor_zoom_level = 0
default_monitor_location = {x = c.x, z = c.z}

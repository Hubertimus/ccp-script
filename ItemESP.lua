-- Natives
util.require_natives("natives-1663599433")

local menu_root = menu.my_root()

local screenX = memory.alloc(4)
local screenY = memory.alloc(4)

local function world_to_screen(pos)
    GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(pos.x, pos.y, pos.z - 0.1, screenX, screenY)
    return memory.read_float(screenX), memory.read_float(screenY)
end

menu_root:toggle_loop("Draw Pickups", {}, "", function ()
   
    local player_pos = players.get_position(players.user())

    local pickups = entities.get_all_pickups_as_pointers()

    for _, pointer in pairs(pickups) do
        local pos = entities.get_position(pointer)

        local renderX, renderY = world_to_screen(pos)

        local distance = player_pos:distance(pos)

        -- Render Label
        if renderX ~= -1 and renderY ~= -1 then
            local model_name = util.reverse_joaat(entities.get_model_hash(pointer))
            local label = model_name .. " [" .. tostring(math.floor(distance)) .. "]"
            
            local scale = 1/3

            local opacity = math.max(0.2, (255 - distance) / 255)

            directx.draw_text(renderX, renderY, label, ALIGN_CENTRE, scale, {r=1.0, g=1.0, b=1.0, a=opacity})
        end

    end
    
end)

util.keep_running()
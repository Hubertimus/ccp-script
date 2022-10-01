-- Natives
util.require_natives("natives-1663599433")

------------------- Queue Stuff
-- Queue Linked List
Queue = {}

function Queue.new()
    return {first = 0, last = -1, data = {}}
end

-- Grab last value in Queue
function Queue.push(q, value)
    q.last = q.last + 1
    q.data[q.last] = value
end

function Queue.peek(q)
    if (Queue.empty(q)) then return nil end

    return q.data[q.first]
end

-- Grab first value in Queue
function Queue.pop(q)
    if (Queue.empty(q)) then error("Queue is empty") end

    local value = q.data[q.first]

    -- Clear value
    q.data[q.first] = nil

    -- Increment
    q.first = q.first + 1

    return value
end

-- Returns size of queue
function Queue.size(q)
    return (q.last - q.first) + 1
end

-- Goes through all values and sets to nil
function Queue.clear(q)
    while not Queue.empty(q) do
        Queue.pop(q) -- Ignore return value since we're clearing
    end
end

function Queue.empty(q)
    return q.first > q.last
end
------------------- Queue Stuff






------------ Constants ------------

local NULL <const> = 0

local BLOCK_CMD <const> = "timeout"

------------ Variables ------------

Config = {
    [0] = {enabled = false, cleanup = false, radius = 10, threshold = 10, time_limit = 3000}, -- Obj
    {enabled = false, cleanup = false, radius = 10, threshold = 10, time_limit = 3000}, -- Ped
    {enabled = false, cleanup = false, radius = 10, threshold = 10, time_limit = 3000} -- Veh
}

local seen_entities = {}

local throttler_list = {}

local was_connected = false

local last_ran_ms = 0

local timeout_time = 30000

PlayerThrottler = {}

function PlayerThrottler.new()
    return {pid = -1, throttling = false, throttle_time = 0, vehq = Queue.new(), pedq = Queue.new(), objq = Queue.new()}
end

for i=0, 31 do
    throttler_list[i] = PlayerThrottler.new()
    throttler_list[i].pid = i
end

Entity = {handle = NULL, time=0}

function Entity.new()
    return {handle=NULL, time=0}
end

------------ Functions ------------

-- Smaller Function name
function util.now()
    return util.current_time_millis()
end

-- Gets ID of who owns entity
local function entity_owner_from_pointer(entityPointer)
    local net_object = memory.read_long(entityPointer + 0xD0)
    local owner_id = net_object ~= 0 ? memory.read_byte(net_object + 0x49) : -1
    return owner_id
end

-- Check if the player is loaded in an online session
local function is_connected()
    return util.is_session_started() and not util.is_session_transition_active()
end

local function block_syncs(pid, should_block)
    menu.trigger_commands(BLOCK_CMD .. players.get_name(pid) .. (should_block ? " on" : " off"))
end

local function check_list(entities_list, now, type, handles)
    local can_track = now - last_ran_ms > 5000

    local player = players.user()

    local pos = players.get_position(players.user())

    -- Check for all vehicles made by player
    for _, ent in ipairs(entities_list) do
        local obj_ptr = handles ? entities.handle_to_pointer(ent) : ent

        -- Check if we own object
        local owner_id = entity_owner_from_pointer(obj_ptr)

        if owner_id == -1 or owner_id == player then
            continue
        end

        local obj_handle = handles ? ent : entities.pointer_to_handle(obj_ptr)

        -- Ignore player modele
        if obj_handle == PLAYER.GET_PLAYER_PED(owner_id) then
            continue
        end

        if not table.contains(seen_entities, obj_handle) then
            table.insert(seen_entities, obj_handle)
            
            local distance = pos:distance(entities.get_position(obj_ptr))

            if can_track and distance <= Config[type].radius then

                if type == 2 then
                    local has_ped = false
                    for i=-1, VEHICLE.GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(obj_handle) - 1 do
                        if VEHICLE.GET_PED_IN_VEHICLE_SEAT(obj_handle, i, false) ~= 0 then
                            has_ped = true
                        end
                    end
                    if has_ped then continue end
                end

                local node = Entity.new()

                node.handle = obj_handle
                node.time = now
                
                local throttler = throttler_list[owner_id]

                local q = type == 0 ? throttler.objq : type == 1 ? throttler.pedq : throttler.vehq

                Queue.push(q, node)
            end
        end
    end
end

local function cleanup_seen()
    local temp = {}

    -- Cache indexes of old entities
    for i, ent in ipairs(seen_entities) do
        if not ENTITY.DOES_ENTITY_EXIST(ent) then
            table.insert(temp, i)
        end
    end

    -- Remove old entities from Right to Left (prevent index shifting errors)
    for i=#temp, 1, -1 do
        table.remove(seen_entities, temp[i])
    end

    temp = nil
end

local function check_queue(now)

    for pid=0, 31 do
        if not players.exists(pid) or pid == players.user() then
            continue
        end

        local sizes = {0,0,0}

        for type=0, 2 do
            local throttler = throttler_list[pid]

            local q = type == 0 ? throttler.objq : type == 1 ? throttler.pedq : throttler.vehq
    
            local throttle_type = type == 0 ? "Object" : type == 1 ? "Ped" : "Vehicle"
            
            local node = Queue.peek(q)
            while node ~= nil and (now - node.time >= Config[type].time_limit) do
                Queue.pop(q)
                node = Queue.peek(q)
            end

            local size = Queue.size(q)

            sizes[type + 1] = size
    
            -- local sync_state = menu.ref_by_rel_path(menu.player_root(pid), "Incoming Syncs>Block")
    
            -- util.draw_debug_text(players.get_name(pid) .. " (" .. size .. ") " .. tostring(sync_state.value))

            if not throttler.throttling then
                if size > Config[type].threshold then
                    throttler.throttling = true
                    throttler.throttle_time = now
                    util.toast(throttle_type .. " Throttling " .. players.get_name(pid))
                    block_syncs(pid, true)

                    if Config[type].cleanup then
                        node = Queue.peek(q)
                        while node ~= nil do
                            local obj_handle = Queue.pop(q)
                            entities.delete_by_handle(obj_handle.handle)
                            node = Queue.peek(q)
                        end
                    end

                    break
                end
            elseif now - throttler.throttle_time > timeout_time then
                util.toast("Stopped Throttling " .. players.get_name(pid))
                throttler.throttling = false
                block_syncs(pid, false)
            end
        end

        util.draw_debug_text(players.get_name(pid) .. "(" .. tostring(sizes[1]) .. "/" .. tostring(sizes[2]) .. "/" .. tostring(sizes[3]) .. ")")
    end
end

------------ Menu Setup ------------ 
menu.toggle_loop(menu.my_root(), "Throttle Objects", {}, "Throttles Objects owned by other players.", 
function ()
    -- Check if we're online and connected
    if not is_connected() then 
        if was_connected then
            seen_entities = {}
        end

        was_connected = false
        return 
    end

    if not was_connected then
        last_ran_ms = util.now()
    end

    was_connected = true

    local now = util.now()

    -- 5 Second Grace Period
    check_list(entities.get_all_objects_as_pointers(), now, 0)
    check_list(entities.get_all_peds_as_pointers(), now, 1)
    check_list(entities.get_all_vehicles_as_handles(), now, 2, true)

    cleanup_seen()

    -- Go through player Entity Queues
    check_queue(now)
end, 
function()
    seen_entities = {}
    for i=0, 31 do
        local p_throttler = throttler_list[i]
        Queue.clear(p_throttler.objq)
        Queue.clear(p_throttler.pedq)
        Queue.clear(p_throttler.vehq)
        p_throttler.throttling = false
        p_throttler.throttle_time = 0
    end
end)

menu.slider(menu.my_root(), "Timeout Time", {}, "How long Syncs should be blocked from the player.", 1, 60, 30, 1, function (value)
    timeout_time = (value * 1000)
end)

for type=0, 2 do
    local is_focused = false

    local throttle_type = type == 0 ? "Objects" : type == 1 ? "Peds" : "Vehicles"

    local config = Config[type]

    local type_root = menu.list(menu.my_root(), "Throttle " .. throttle_type)

    menu.toggle(type_root, "Enabled", {}, "", function (enabled)
        config.enabled = enabled
    end)

    menu.toggle(type_root, "Cleanup", {}, "Delets spammed entities.", function (enabled)
        config.cleanup = enabled
    end)

    local rad_slider = menu.slider(type_root, "Radius", {}, "", 1, 50, 10, 1, function (value, prev_value, click_type)
        config.radius = value
    end)
    
    menu.slider(type_root, "Threshold", {}, "How many entities within the time limit", 1, 100, 10, 1, function (value, prev_value, click_type) 
        config.threshold = value
    end)

    menu.slider(type_root, "Time Limit", {}, "", 1, 10, 3, 1, function (value, prev_value, click_type) 
        config.time_limit = (value * 1000)
    end)

    menu.on_focus(rad_slider, function ()
        if not is_focused then
            is_focused = true
            util.create_tick_handler(function ()
                if is_focused then
                    local r = config.radius
            
                    local factor = 10
            
                    for i=1, 360 / factor do
                        local cos = math.cos(math.rad(i * factor))
                        local sin = math.sin(math.rad(i * factor))
                
                        local startX = r * cos
                        local startY = r * sin
                
                        local pedpos = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                
                        local pos1 = v3.new(pedpos.x + startX, pedpos.y + startY, pedpos.z - 1)
                
                        local cos2 = math.cos(math.rad((i + 1) * factor))
                        local sin2 = math.sin(math.rad((i + 1) * factor))
                
                        local endX = r * cos2
                        local endY = r * sin2
                
                        local dx = startX - endX
                        local dy = startY - endY
                
                        local length = math.sqrt(dx * dx + dy * dy)
                
                        util.draw_box(pos1, v3.new(0,0,90 + (i * factor)), v3.new(length,0,30), 255, 0, 0, 100)
                    end
                else return false
                end
            end)
        end
    end)
    
    menu.on_blur(rad_slider, function ()
        is_focused = false
    end)
end

util.keep_running()

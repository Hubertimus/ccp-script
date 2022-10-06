-- Natives
util.require_natives("natives-1660775568")

-- Version 2.0

-- TODO: Move all player iterations to a single iterator

-- Auto Update
local auto_update_source_url = "https://raw.githubusercontent.com/Hubertimus/ccp-script/main/Zhong-Xina-CCP-Removals.lua"
local status, lib = pcall(require, "auto-updater")
if not status then
    async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
        function(result, headers, status_code) local error_prefix = "Error downloading auto-updater: "
            if status_code ~= 200 then util.toast(error_prefix..status_code) return false end
            if not result or result == "" then util.toast(error_prefix.."Found empty file.") return false end
            local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
            if file == nil then util.toast(error_prefix.."Could not open file for writing.") return false end
            file:write(result) file:close() util.toast("Successfully installed auto-updater lib")
        end, function() util.toast("Error downloading auto-updater lib. Update failed to download.") end)
    async_http.dispatch() util.yield(3000) require("auto-updater")
end
run_auto_update({source_url=auto_update_source_url, script_relpath=SCRIPT_RELPATH, verify_file_begins_with="--"})

-- Stand Versions
local BROKE = 0
local BASIC = 1
local REGULAR = 2
local ULTIMATE = 3





------------ Commands ------------

-- Stand Commands
local SMART_KICK = "kick"
local BREAKUP_KICK = "breakup"
local ELEGANT_CRASH = "crash"
local NEXT_GEN_CRASH = "ngcrash"
local BKFL_CRASH = "footlettuce"
local VEHICLE_CRASH = "slaughter"
local TELEPORT_TO = "tp"
local BLOCK_JOIN = "historyblock"

local SPECTATE_NINJA = "Spectate>Ninja Method"

-- Script Commands
local JINX_GLITCH_VEHICLE = "glitchvehicle"
local JINX_TP_TO_CAYO = "tpcayo"
local JINX_KICK_FROM_CAYO = "cayokick"
local JS_ENTITY_STORM = "jsentitystorm"

-- local JINX_LINUS_CRASH = "Jinx Script>Player Removals>Crashes>Linus Crash Tips"
local JINX_GLITCH_PLAYER_DELAY = "Jinx Script>Trolling & Griefing>Glitch Player>Spawn Delay"
local JINX_GLITCH_PLAYER = "Jinx Script>Trolling & Griefing>Glitch Player>Glitch Player"
local JINX_KILL_GODMODER = "Jinx Script>Anti-Modder>Kill Godmode Player>Squish"
local JINX_REMOVE_GODMODE = "Jinx Script>Anti-Modder>Remove Player Godmode"

local WIRI_HOSTILE_CARS = "Trolling & Griefing>Hostile Traffic"

------------ End Commands ------------






------------ Variables ------------

Integer = {MIN_VALUE = -2147483648, MAX_VALUE = 2147483647}

local WEAPON_STUNGUN <const> = 1171102963
local WEAPON_RAYPISTOL <const> = -1355376991
NULL = 0

local shadow_root = menu.shadow_root()

local block_joins = false

-- Jinx
local interior_stuff = {0, 233985, 169473, 169729, 169985, 170241, 177665, 177409, 185089, 184833, 184577, 163585, 167425, 167169}

local ghosted_table = {}

local xenophobia_enabled
local note_player

local languages <const> = {
    [0] = { lang = "English", block = false },
    [1] = { lang = "French", block = false },
    [2] = { lang = "German", block = false },
    [3] = { lang = "Italian", block = false },
    [4] = { lang = "Spanish", block = false },
    [5] = { lang = "Brazilian", block = true },
    [6] = { lang = "Polish", block = true },
    [7] = { lang = "Russian", block = true },
    [8] = { lang = "Korean", block = false },
    [9] = { lang = "Chinese (Traditional)", block = true },
    [10] = { lang = "Japanese", block = false },
    [11] = { lang = "Mexican", block = false },
    [12] = { lang = "Chinese (Simplified)", block = true }
}

local show_notification = false
local anti_stun_gun = false
local anti_atomizer = false
local in_timeout = {}

local menu_root = menu.my_root()
local xeno_root = menu_root:list("Xenophobia")
local list = xeno_root:list("Kick Languages")
local kicked_players_menu = xeno_root:list("Kicked players", {}, "List of players you've kicked")
local kicked_players = {}

------------ End Variables ------------





------------ Functions ------------

-- Gets ID of who owns entity
local function entity_owner_from_pointer(entityPointer)
    local net_object = memory.read_long(entityPointer + 0xD0)
    local owner_id = net_object ~= NULL and memory.read_byte(net_object + 0x49) or -1
    return owner_id
end

local function get_entity_owner(entityHandle)
    return entity_owner_from_pointer(entities.handle_to_pointer(entityHandle))
end

-- Check if the player is loaded in an online session
local function is_connected()
    return util.is_session_started() and not util.is_session_transition_active()
end

-- Jinx Function
local function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return root:toggle_loop(menu_name, command_names, help_text, function()
        if (not is_connected() or not players.exists(pid)) then util.stop_thread() end
        callback()
    end)
end

-- Jinx Function
local function request_model(hash, timeout)
    timeout = timeout or 3
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + timeout
    repeat
        util.yield()
    until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
    return STREAMING.HAS_MODEL_LOADED(hash)
end

-- Jinx Function
local function get_transition_state(pid)
    return memory.read_int(memory.script_global(((0x2908D3 + 1) + (pid * 0x1C5)) + 230))
end

-- Jinx Function
local function get_interior_player_is_in(pid)
    return memory.read_int(memory.script_global(((0x2908D3 + 1) + (pid * 0x1C5)) + 243)) 
end

-- Jinx Linus Crash Tips
local function linux_crash_tips(pid)
    local int_min = Integer.MIN_VALUE
    local int_max = Integer.MAX_VALUE

    for i = 1, 150 do
        util.trigger_script_event(1 << pid, {2765370640, pid, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max), 
        math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
        math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
    end
    util.yield()
    for i = 1, 15 do
        util.trigger_script_event(1 << pid, {1348481963, pid, math.random(int_min, int_max)})
    end
    menu.trigger_commands("givesh " .. players.get_name(pid))
    util.yield(100)
    util.trigger_script_event(1 << pid, {495813132, pid, 0, 0, -12988, -99097, 0})
    util.trigger_script_event(1 << pid, {495813132, pid, -4640169, 0, 0, 0, -36565476, -53105203})
    util.trigger_script_event(1 << pid, {495813132, pid,  0, 1, 23135423, 3, 3, 4, 827870001, 5, 2022580431, 6, -918761645, 7, 1754244778, 8, 827870001, 9, 17})
end

-- Adds Block Join reaction to player_id
local function block_player(player_id, force)
    if (block_joins or force) and not table.contains(players.list(false, true, false), player_id) then
        util.toast("Blacklisted Player")

        menu.trigger_commands(BLOCK_JOIN .. players.get_name(player_id))
    end
end

-- Checks if you're aiming at an entity
local function is_aiming_at_entity(player_id, target_entity, player_entity, optional_fov)
	if player_entity and optional_fov then
		return PLAYER.IS_PLAYER_FREE_AIMING(player_id) and PED.IS_PED_FACING_PED(player_entity, target_entity, optional_fov)
	else
		return PLAYER.IS_PLAYER_FREE_AIMING_AT_ENTITY(player_id, target_entity)
	end
end

local function toast(...)
	if show_notification then
		return util.toast(...)
	end
end

local function player_handler(player_id)
    local name = players.get_name(player_id)
    local player_lang = languages[players.get_language(player_id)] or {}

    if not player_lang.block then
        return
    end

    if note_player then
        menu.trigger_commands("historynote" .. name .. " " .. "3rd worlders")
    end

    block_player(player_id, false)
    util.toast("Kicking " .. player_lang.lang .. " Player " .. name)
    menu.trigger_commands(SMART_KICK .. name)

    kicked_players[name] = {
        lang = player_lang.lang,
        menu = kicked_players_menu:action(name, {}, string.format("Language: %s\nStill In Lobby?: Yes", player_lang.lang), function() end)
    }
end

local function player_leave_handler(player_id, name)
    local player = kicked_players[name]

    if not player then
        return
    end

    menu.set_help_text(player.menu, string.format("Language: %s\nStill In Lobby?: No", player.lang))
end

-- Script Setup Functions
local function setup_utils(utils, player_id)
    local player_root = menu.player_root(player_id)

    -- Spectate Toggle Shortcut
    utils:action("Toggle Spectate", {}, "Toggles Ninja Method Spectate", function ()
        local cmd = menu.ref_by_rel_path(player_root, SPECTATE_NINJA)
        menu.trigger_command(cmd, "")
    end)

    -- Teleport Shortcut
    utils:action("Teleport to Player", {}, "Teleports", function ()
        menu.trigger_commands(TELEPORT_TO .. players.get_name(player_id))
    end)

    -- Blacklist on Join
    utils:action("Blacklist Player", {}, "", function()
        block_player(player_id, true)
    end)

    utils:action("Remove Ghost", {}, "", function ()
        NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, false)
        ghosted_table[player_id] = false
    end)

    -- Removals Shortcut
    utils:action("Go To Removals", {}, "", function()
        menu.trigger_command(menu.ref_by_rel_path(player_root, "Uyghur Muslim Removals"))
    end)
end

-- Shortcuts to commonly used commands
local function setup_trolling(utils, player_id)
    local player_root = menu.player_root(player_id)

    -- Trolling Shortcuts
    local trolling = utils:list("Troll/Grief Shortcuts")

    -- Entity Storm
    trolling:action("Toggle Entity Storm", {}, "", function()
        menu.trigger_commands(JS_ENTITY_STORM .. players.get_name(player_id))
    end)
    
    -- Glitch Player
    trolling:action("Toggle Glitch Player", {}, "", function()
        local delay = menu.ref_by_rel_path(player_root, JINX_GLITCH_PLAYER_DELAY)
        local cmd = menu.ref_by_rel_path(player_root, JINX_GLITCH_PLAYER)
        menu.trigger_command(delay, "0")
        menu.trigger_command(cmd, "")
    end)

    -- Glitch Vehicle
    trolling:action("Toggle Glitch Vehicle", {}, "", function()
        menu.trigger_commands(JINX_GLITCH_VEHICLE .. players.get_name(player_id))
    end)

    -- Jinx Buggy Movement
    player_toggle_loop(trolling, player_id, "Buggy Movement", {}, "", function()
        local glitch_hash = util.joaat("prop_shuttering03")
        request_model(glitch_hash)
        local dumb_object_front = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(player_id), 0, 1, 0))
        local dumb_object_back = entities.create_object(glitch_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(player_id), 0, 0, 0))
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_front, false)
        ENTITY.SET_ENTITY_VISIBLE(dumb_object_back, false)
        util.yield()
        entities.delete_by_handle(dumb_object_front)
        entities.delete_by_handle(dumb_object_back)
        util.yield()    
    end)

    -- Hostile Cars
    trolling:action("Toggle Hostile Cars", {}, "", function()
        local cmd = menu.ref_by_rel_path(player_root, WIRI_HOSTILE_CARS)
        menu.trigger_command(cmd, "")
    end)

    -- Remove God
    trolling:action("Remove Godmode", {}, "", function ()
        local cmd = menu.ref_by_rel_path(player_root, JINX_REMOVE_GODMODE)
        menu.trigger_command(cmd)
    end)

    -- Kill God Mode
    trolling:action("Kill Godmode Squish", {}, "", function()
        local cmd = menu.ref_by_rel_path(player_root, JINX_KILL_GODMODER)
        menu.trigger_command(cmd, "Khanjali")
    end)

    -- Teleport to Cayo
    trolling:action("Teleport to Cayo", {}, "Even better if you hold down key", function()
        menu.trigger_commands(JINX_TP_TO_CAYO .. players.get_name(player_id))
    end)

    -- Kicked from Cayo
    trolling:action("Kick from Cayo", {}, "", function()
        menu.trigger_commands(JINX_KICK_FROM_CAYO .. players.get_name(player_id))
    end)
end

-- Shortcuts to player removals
local function setup_removals(anchor, player_id)
    -- Check if the user is Zack
    local is_broke = menu.get_edition() < REGULAR

    -- local player_root = menu.player_root(player_id)

    -- Check if Jinx Script Linus crash exists
    local root = anchor:attach_before(shadow_root:list("Uyghur Muslim Removals"))

    -- Add the option to explicitly Breakup Kick
    if not is_broke then
        root:action("Breakup Kick", {}, "You're not broke!", function() 
            block_player(player_id, false)
            menu.trigger_commands(BREAKUP_KICK .. players.get_name(player_id))
        end)
    end

    -- Use Stand Smart Kick
    root:action("Smart Kick", {}, "Stands Built-in Smart kick.", function ()
        block_player(player_id, false)
        menu.trigger_commands(SMART_KICK .. players.get_name(player_id))
    end)

    -- Crashes 
    root:action("Smart Crash", {}, "Uses Vehicle Manslaughter if they are in a vehicle.", function ()
        local player_name = players.get_name(player_id)
        block_player(player_id, false)

        linux_crash_tips(player_id)
        local in_vehicle = players.get_vehicle_model(player_id) ~= NULL

        local crash_cmd = in_vehicle ? VEHICLE_CRASH : ELEGANT_CRASH

        local toast = (in_vehicle ? "Vehicle Crashing " : "Crashing ") .. player_name 
        
        util.toast(toast)

        menu.trigger_commands(crash_cmd .. player_name)
    end)

    -- Jinx Linus Crash
    root:action("Linus Crash", {}, "", function ()
        linux_crash_tips(player_id)
    end)

    -- Crash then Kick the player to guarantee removal
    root:action("By Any Means Neccessary", {}, "Attempts to Crash the player then Kick.\n(Note) This may backfire on good menus.", function() 
        local player_name = players.get_name(player_id)
        util.toast("Attempting to remove " .. player_name)
        block_player(player_id, true)

        linux_crash_tips(player_id)
        menu.trigger_commands(ELEGANT_CRASH .. player_name)
        menu.trigger_commands(NEXT_GEN_CRASH .. player_name)
        menu.trigger_commands(BKFL_CRASH .. player_name)

        if players.get_vehicle_model(player_id) ~= NULL then
            menu.trigger_commands(VEHICLE_CRASH .. player_name)
        end

        util.yield(4000)

        -- Check if the player hasn't been removed yet
        if table.contains(players.list(false, true, true), player_id) then
            -- Smart Kick player
            menu.trigger_commands(SMART_KICK .. player_name)
        end
    end)
end

-- on_join callback
On_join = function(player_id)
    -- If not ourselves, construct options
    if player_id ~= players.user() then
        if xenophobia_enabled then player_handler(player_id) end

        local player_root = menu.player_root(player_id)

        -- Create a Divider
        local anchor = menu.ref_by_rel_path(player_root, "Information")

        setup_removals(anchor, player_id)

        local utils = shadow_root:list("Player Shortcuts")
        utils = anchor:attach_before(utils)

        setup_utils(utils, player_id)

        setup_trolling(utils, player_id)

        anchor:attach_before(shadow_root:divider(players.get_name(player_id)))
    end
end

On_leave = function (player_id)
    if xenophobia_enabled then player_leave_handler(player_id) end

    ghosted_table[player_id] = false
end
------------ End Functions ------------





------------ Script Menu Setup ------------

-- Shortcut to Players Tab
menu_root:action("Players Tab", {}, "Goes to players tab", function()
    menu.trigger_command(menu.ref_by_path("Players"))
end)

-- Auto Block Join
menu_root:toggle("Auto Join Reaction", {}, "Automatically sets block join reaction when you kick/crash.", function (on, click_type)
    block_joins = on
end)

local protections_tab = menu_root:list("Protections")

-- Anti Invisible Entity
protections_tab:toggle_loop("Show Invisible Entities", {}, "Makes invisible entities transparent instead.", function (on, click_type)
    if is_connected() then
        for _, pointer in ipairs(entities.get_all_objects_as_pointers()) do
            local owner_id = entity_owner_from_pointer(pointer)

            if owner_id == -1 or owner_id == players.user() then
                continue
            end

            local h_entity = entities.pointer_to_handle(pointer)

            -- Ignore our own networked entities
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(h_entity) then
                continue
            end

            if not ENTITY.IS_ENTITY_VISIBLE(h_entity) then
                ENTITY.SET_ENTITY_VISIBLE(h_entity, true, false)
                ENTITY.SET_ENTITY_ALPHA(h_entity, 55, false)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(h_entity, true, false)

                if ENTITY.IS_ENTITY_TOUCHING_ENTITY(players.user(), h_entity) then
                    entities.delete_by_handle(h_entity)
                end

                if owner_id ~= -1 then
                    local model_name = util.reverse_joaat(entities.get_model_hash(pointer))
                    util.toast("Invisible Object from " .. players.get_name(owner_id) .. " (" .. model_name .. ")")
                    util.draw_ar_beacon(entities.get_position(pointer))
                end
            end
        end

        for _, pointer in ipairs(entities.get_all_vehicles_as_pointers()) do
            -- Ignore our own networked entities
            local owner_id = entity_owner_from_pointer(pointer)

            if  owner_id == -1 or owner_id == players.user() then
                continue
            end

            local h_vehicle = entities.pointer_to_handle(pointer)
            -- Ignore our own networked entities
            if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(h_vehicle) then
                continue
            end

            if not ENTITY.IS_ENTITY_VISIBLE(h_vehicle) then
                ENTITY.SET_ENTITY_VISIBLE(h_vehicle, true, false)
                ENTITY.SET_ENTITY_ALPHA(h_vehicle, 55, false)
                ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(h_vehicle, true, false)

                if ENTITY.IS_ENTITY_TOUCHING_ENTITY(players.user(), h_vehicle) then
                    entities.delete_by_handle(h_vehicle)
                end

                if owner_id ~= -1 then
                    util.toast("Invisible Vehicle from " .. players.get_name(owner_id))
                end
            end
        end
    end
end)

-- Set everyone as not ghosted
for i=0, 31 do
    ghosted_table[i] = false
end

-- Auto Ghost Godemoder but better
protections_tab:toggle_loop("Auto Ghost Godmoders", {}, "Better than Jinx", 
-- on_tick
function()
    if is_connected() then
        for _, player_id in ipairs(players.list(false, true, true)) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
            for i, interior in ipairs(interior_stuff) do
                local is_ghosted = ghosted_table[player_id]

                if (players.is_godmode(player_id) or not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(ped)) then
                    local should_be_vul = not NETWORK.NETWORK_IS_PLAYER_FADING(player_id) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(player_id) ~= 0 and get_interior_player_is_in(player_id) == interior
                    if should_be_vul then
                        NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, true)
                        if not is_ghosted then
                            ghosted_table[player_id] = true
                            -- util.toast("Ghosted Godmoder " .. players.get_name(player_id))
                        end
                        break
                    end
                elseif is_ghosted then
                    NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, false)
                    ghosted_table[player_id] = false
                    -- util.toast("Un-Ghosted " .. players.get_name(player_id))
                end

            end
        end 
    end
end,
-- on_stop
function ()
    if is_connected() then
        for _, player_id in ipairs(players.list(false, true, true)) do
            if ghosted_table[player_id] then
                NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, false)
                ghosted_table[player_id] = false
            end
        end
    end
end)

-- Zack Moment
local anti_taser = protections_tab:list("Anti Stunomizer")

anti_taser:toggle("Show Notification", {}, "Shows notification of when the player gets event blocked", function(state)
	show_notification = state
end)

anti_taser:toggle("Anti Stun Gun", {"antitaser"}, "Stops players from stunning you with the stun gun", function(state)
	anti_stun_gun = state
end)

anti_taser:toggle("Anti Up-N-Atomizer", {"antiupnatomizer"}, "Stops players from shooting you with the Up-N-Atomizer", function(state)
	anti_atomizer = state
end)

anti_taser:toggle_loop("Enable", {}, "", function()
	if not anti_stun_gun and not anti_atomizer then
		return -- If you don't have the features enabled, stop here
	end

	local lp_id = players.user()
	local lp_ped = players.user_ped()
	local lp_pos = players.get_position(lp_id)

	for _, player_id in players.list(false) do
		local player_ped = PLAYER.GET_PLAYER_PED(player_id)
		local player_name = players.get_name(player_id)

		if in_timeout[player_name] then
			continue
		end

		-- Get the hash of the player's current weapon
		local current_weapon = WEAPON.GET_SELECTED_PED_WEAPON(player_ped)

		if anti_stun_gun and current_weapon == WEAPON_STUNGUN then
			if not is_aiming_at_entity(player_id, lp_ped) then
				continue
			end

		elseif anti_atomizer and current_weapon == WEAPON_RAYPISTOL then
			if not is_aiming_at_entity(player_id, lp_ped, player_ped, 10) then
				continue
			end
		else
			continue
		end

		local player_pos = players.get_position(player_id)
		local distance = player_pos:distance(lp_pos)
		local timeout_delay = 500 + math.floor(distance * 0.015 * 1000) -- if dist is 13.4128, timeout length = 401ms

		in_timeout[player_name] = 1
		NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, true)
        -- menu.trigger_commands("ignore" .. player_name .. " on")
		toast("Ignoring network events from: " .. player_name .. " for " .. timeout_delay .. "ms")

		util.create_thread(function()
			util.yield(timeout_delay)
			NETWORK._SET_RELATIONSHIP_TO_PLAYER(player_id, false)
            -- menu.trigger_commands("ignore" .. player_name .. " off")
			in_timeout[player_name] = nil
		end)
	end

	if PED.IS_PED_BEING_STUNNED(lp_ped, 0) then
		TASK.CLEAR_PED_TASKS_IMMEDIATELY(lp_ped)
		util.toast("You are getting stunned lmao")
	end
end)

for i=0, #languages do
    local lang = languages[i]
    list:toggle(lang.lang, {}, "", function(state)
        lang.block = state
    end, lang.block)
end

xeno_root:toggle("Add note", {}, "Notes player as '3rd worlder'", function(state)
    note_player = state
end)

xeno_root:toggle("Enable", {}, "Kicks Players based off of Language settings\n(On Join)", function(state)
    xenophobia_enabled = state
end)

local check_lobby;
check_lobby = xeno_root:action("Check Lobby", {}, "Checks each players language in the current lobby and kicks them if its a blocked language", function()
    for _, pid in ipairs(players.list(false, false)) do
        player_handler(pid)
    end

    check_lobby:delete()
end)
------------ End Script Menu Setup ------------





-- Register callback
players.on_join(On_join)
players.on_leave(On_leave)
players.dispatch_on_join()

-- Keep script from closing immediately
util.keep_running()
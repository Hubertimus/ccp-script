-- Natives
util.require_natives("natives-1660775568")

-- Auto Update
local auto_update_source_url = "https://raw.githubusercontent.com/Hubertimus/ccp-script/main/Zhong%20Xina%20CCP%20Removals.lua"
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
local BREAKDOWN_KICK = "breakdown"
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

local JINX_LINUS_CRASH = "Jinx Script>Player Removals>Crashes>Linus Crash Tips"
local JINX_GLITCH_PLAYER = "Jinx Script>Trolling & Griefing>Glitch Player>Glitch Player"
local JINX_KILL_GODMODER = "Jinx Script>Anti-Modder>Kill Godmode Player>Squish"

------------ End Commands ------------






------------ Variables ------------

local block_joins = false

------------ End Variables ------------





------------ Script Menu Setup ------------

-- Shortcut to Players Tab
local players_tab = menu.ref_by_path("Players")
menu.action(menu.my_root(), "Players Tab", {}, "Goes to players tab", function()
    menu.trigger_command(players_tab)
end)

-- Auto Block Join
menu.toggle(menu.my_root(), "Auto Join Reaction", {}, "Automatically sets block join reaction when you kick/crash.", function (on, click_type)
    block_joins = on
end)

-- menu.toggle(menu.my_root(), "Auto Script Host", {"ccpautosh"}, "Automatically sets you as script host.", function(on, click_type)
--     if players.get_script_host() ~= players.user() then
--     end
-- end)
------------ End Script Menu Setup ------------





------------ Functions ------------

-- Adds Block Join reaction to player_id
local function block_player(player_id, force)
    if (block_joins or force) and not table.contains(players.list(false, true, false), player_id) then
        util.toast("Blacklisted Player")

        menu.trigger_commands(BLOCK_JOIN .. players.get_name(player_id))
    end
end

-- Shortcuts to commonly used commands
local function setup_trolling(utils, player_id)
    local player_root = menu.player_root(player_id)

    -- Trolling Shortcuts
    local trolling = menu.list(utils, "Troll/Grief Shortcuts")

    -- Entity Storm
    menu.action(trolling, "Toggle Entity Storm", {}, "", function()
        menu.trigger_commands(JS_ENTITY_STORM .. players.get_name(player_id))
    end)
    
    -- Glitch Player
    menu.action(trolling, "Toggle Glitch Player", {}, "", function()
        local cmd = menu.ref_by_rel_path(player_root, JINX_GLITCH_PLAYER)
        menu.trigger_command(cmd, "")
    end)

    -- Glitch Vehicle
    menu.action(trolling, "Toggle Glitch Vehicle", {}, "", function()
        menu.trigger_commands(JINX_GLITCH_VEHICLE .. players.get_name(player_id))
    end)
    -- Remove God

    -- Kill God Mode
    menu.action(trolling, "Kill Godmode Squish", {}, "", function()
        local cmd = menu.ref_by_rel_path(player_root, JINX_KILL_GODMODER)
        menu.trigger_command(cmd, "Khanjali")
    end)

    -- Teleport to Cayo
    menu.action(trolling, "Teleport to Cayo", {}, "Even better if you hold down key", function()
        menu.trigger_commands(JINX_TP_TO_CAYO .. players.get_name(player_id))
    end)

    -- Kicked from Cayo
    menu.action(trolling, "Kick from Cayo", {}, "", function()
        menu.trigger_commands(JINX_KICK_FROM_CAYO .. players.get_name(player_id))
    end)
end

-- Shortcuts to player removals
local function setup_removals(player_id)
    -- Check if the user is Zack
    local is_broke = menu.get_edition() < REGULAR

    local player_root = menu.player_root(player_id)
    
    -- Check if Jinx Script Linus crash exists
    local linus_exists, linus = pcall(function()
        return menu.ref_by_rel_path(player_root, JINX_LINUS_CRASH)
    end)

    local root = menu.list(player_root, "Uyghur Muslim Removals")

    -- Add the option to explicitly Breakdown Kick
    if not is_broke then
        menu.action(root, "Breakdown Kick", {}, "You're not broke!", function() 
            block_player(player_id, false)
            menu.trigger_commands(BREAKDOWN_KICK .. players.get_name(player_id))
        end)
    end

    -- Use Stand Smart Kick
    menu.action(root, "Smart Kick", {}, "Stands Built-in Smart kick.", function ()
        block_player(player_id, false)
        menu.trigger_commands(SMART_KICK .. players.get_name(player_id))
    end)

    -- Crashes 
    menu.action(root, "Smart Crash", {}, "Uses Vehicle Manslaughter if they are in a vehicle.", function ()
        local player_name = players.get_name(player_id)
        block_player(player_id, false)

        if linus_exists then
            util.toast("Linus Crashing " .. player_name)

            menu.trigger_command(linus, "")
        else
            local in_vehicle = players.get_vehicle_model(player_id) ~= 0

            local crash_cmd = in_vehicle and VEHICLE_CRASH or ELEGANT_CRASH

            local toast = (in_vehicle and "Vehicle Crashing " or "Crashing ") .. player_name 
            
            util.toast(toast)

            menu.trigger_commands(crash_cmd .. player_name)
        end
    end)

    -- Crash then Kick the player to guarantee removal
    menu.action(root, "By Any Means Neccessary", {}, "Attempts to Crash the player then Kick.\n(Note) This may backfire on good menus.", function() 
        local player_name = players.get_name(player_id)
        util.toast("Attempting to remove " .. player_name)
        block_player(player_id, true)

        -- Use best crash commands
        if linus_exists then
            menu.trigger_command(linus, "")
        else 
            menu.trigger_commands(ELEGANT_CRASH .. player_name)
            menu.trigger_commands(NEXT_GEN_CRASH .. player_name)
            menu.trigger_commands(BKFL_CRASH .. player_name)

            if players.get_vehicle_model(player_id) ~= 0 then
                menu.trigger_commands(VEHICLE_CRASH .. player_name)
            end
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
        local player_root = menu.player_root(player_id)

        -- Create a Divider
        menu.divider(player_root, "Zhong Xina CCP Removals")

        local utils = menu.list(player_root, "Player Shortcuts")

        -- Spectate Toggle Shortcut
        menu.action(utils, "Toggle Spectate", {}, "Toggles Ninja Method Spectate", function ()
            local cmd = menu.ref_by_rel_path(player_root, SPECTATE_NINJA)
            menu.trigger_command(cmd, "")
        end)

        -- Teleport Shortcut
        menu.action(utils, "Teleport to Player", {}, "Teleports", function ()
            menu.trigger_commands(TELEPORT_TO .. players.get_name(player_id))
        end)

        -- Blacklist on Join
        menu.action(utils, "Blacklist Player", {}, "", function()
            block_player(player_id, true)
        end)

        setup_trolling(utils, player_id)

        setup_removals(player_id)
    end
end
------------ End Functions ------------





-- Register callback
players.on_join(On_join)
players.dispatch_on_join()

-- Keep script from closing immediately
util.keep_running()
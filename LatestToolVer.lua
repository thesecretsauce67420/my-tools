-- Variables:
local currentPrefix = "/"
local targetClass = "npc_grenade_bugbait"
local ver = "4.69"
local oldAngles
local function log(str)
    local prefix = "[Socrates Toolz " .. "v" .. ver .. "] "
    chat.AddText(
        Color(100, 100, 255), prefix,
        Color(100, 255, 100), str
    )
    hook.Run("AddNotify", prefix .. "" .. str, NOTIFY_GENERIC, 5)
end
function Initalize()

local function RetryLoop(attempt)
    log("WARNING: a game crash is about to happen, ABORT SHIP AND RETRY NOW!")
    RunConsoleCommand("retry")
end

local function EntityExists()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local nearby = ents.FindInSphere(ply:GetPos(), 20)
    local count = 0

    for _, ent in ipairs(nearby) do
        if ent:GetClass() == targetClass then
            count = count + 1
            if count > 50 then
                return true
            end
        end
    end

    return false
end

-- Start watching
hook.Add("Think", "EntityRetryWatcher", function()
    if EntityExists() then
        RetryLoop()
        hook.Remove("Think", "EntityRetryWatcher") -- run only once
    end
end)

local function SetChatPrefix(newPrefix)
    currentPrefix = newPrefix
    log("Chat Command Prefix is now: " .. newPrefix)
end

local function GetPlayerEntIndexByName(name)
    name = string.lower(name)

    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), name, 1, true) then
            return ply:EntIndex()
        end
    end

    return nil -- not found
end

local function GetPlayerEnt(name)
    name = string.lower(name)

    for _, ply in ipairs(player.GetAll()) do
        if string.find(string.lower(ply:Nick()), name, 1, true) then
            return ply
        end
    end

    return nil -- not found
end

local function GetAllPlayerNames()
    local names = {}

    for _, ply in ipairs(player.GetAll()) do
        table.insert(names, ply:Nick())
    end

    return names
end

local ChatCommands = {
    ["setprefix"] = function(args)
    	SetChatPrefix(string.lower(args[1]))
    end,
    
    ["cleanup"] = function(args)
    	log("Removed all entities")
    	for _,entity in ents.Iterator() do 
    	local entClass = entity:GetClass()
    	if entClass == "viewmodel" or entClass == "env_tonemap_contoller" or entClass == "sky_camera" or entClass == "env_skypaint" then else
	    	    RunConsoleCommand('ent_remove',entity:EntIndex()) 
	    	    RunConsoleCommand('ent_remove_all',entity:GetClass())
	    	    end
	    	end
    end,
    
    ["bring"] = function(args)
    local plyerName = string.lower(args[1])

    if args[1] == nil then
        log("Invalid Player name: " .. tostring(plyerName) .. "!")
        return
    end

    local plyerIndex

    if plyerName ~= "others" or plyerName ~= "self" then
        plyerIndex = GetPlayerEntIndexByName(plyerName)
    end

    if plyerIndex == nil and plyerName ~= "others" then
        log("Player " .. plyerName .. " Doesnt exist, or player entity is NULL somehow")
        return
    else
        local function TeleportEntityAndSeat(ply)
            local entIndex = GetPlayerEntIndexByName(ply:Nick())

            -- Teleport the player
            RunConsoleCommand("ent_teleport", tostring(entIndex))

            -- If player is in a vehicle (seat), teleport the vehicle too
            if ply:InVehicle() then
                local veh = ply:GetVehicle()
                if IsValid(veh) then
                    RunConsoleCommand("ent_teleport", tostring(veh:EntIndex()))
                end
            end

            log("Player " .. ply:Nick() .. " Has been teleported!")
        end

        if plyerName ~= "others" then
            local ply = GetPlayerEnt(plyerName)
            TeleportEntityAndSeat(ply)
        else
            log("Teleporting every other player")
            for _, ply in ipairs(player.GetAll()) do
                if ply ~= LocalPlayer() then
                    TeleportEntityAndSeat(ply)
                end
            end
        end
    end
end,
    
    ["goto"] = function(args)
    	local plyerName = string.lower(args[1])
    	if args[1] == nil then
    	    log("Invalid Player name: " .. plyerName .. "!")
    	end
    	local plyerPos = GetPlayerEnt(plyerName):GetPos()
    	RunConsoleCommand("setpos",
    	    plyerPos.x,
    	    plyerPos.y,
    	    plyerPos.z - 3
    	)
    	log("Teleported to " .. GetPlayerEnt(plyerName):Nick())
    end,
    
    ["heal"] = function(args)
    log("Healing local player..")

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local oldAngles = ply:EyeAngles()
    local delay = 0.05

    local function waitForGround()
        if not IsValid(ply) then return end

        if ply:IsOnGround() then
            local maxHP = ply:GetMaxHealth()
            local currentHP = ply:Health()

            -- Calculate how much healing is needed
            local missingHP = math.max(maxHP - currentHP, 0)

            -- Each health kit = 25 HP
            local kitsNeeded = math.ceil(missingHP / 25)

            -- Run the logic once per kit
            for i = 1, kitsNeeded do
                ply:SetEyeAngles(Angle(90, 0, 0))
                RunConsoleCommand("ent_create", "item_healthkit")
            end

            -- Snap back to original view angles
            timer.Simple((delay + 1) * kitsNeeded + 2, function()
                if IsValid(ply) then
                    ply:SetEyeAngles(oldAngles)
                end
            end)

            return
        end

        -- Keep checking until grounded
        timer.Simple(delay, waitForGround)
    end

    waitForGround()
end,

["nuke"] = function(args)
    if not args or not args[1] then
        log("Usage: nuke <count> [repeat_count]")
        return
    end

    local count = tonumber(args[1]) or 1
    local repeatCount = tonumber(args[2]) or 1

    log("BOOM BOOM BOOM BOOM BOOM!")

    for i = 1, count do
        RunConsoleCommand("ent_create", "grenade_ar2")
    end

    timer.Create("SpamBomb", 0.1, repeatCount, function()
        for i = 1, count do
            RunConsoleCommand("ent_create", "grenade_ar2")
        end
    end)
end,

["kill"] = function(args)
    if not args[1] then
        log("Invalid Player name!")
        return
    end

    local plyerName = table.concat(args, " ")

    if plyerName == "others" then
        log("Killing every other player")
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= LocalPlayer() then
                RunConsoleCommand("kill", ply:Nick()) -- client kill (or use proper server method)
            end
        end
    elseif plyerName == "eye" then
        log("Killing player you are looking at")
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local tr = util.TraceLine(util.GetPlayerTrace(ply))

        if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
            local target = tr.Entity

            if target ~= LocalPlayer() then
                RunConsoleCommand("kill", target:Nick())
            end
        end
    else
        log("Killing player " .. GetPlayerEnt(plyerName):Nick())
        RunConsoleCommand("kill", plyerName)
    end
end,

["killme"] = function(args)
    for i=0,LocalPlayer():Health() do
        RunConsoleCommand("hurtme", "")
    end
end,

["reconnect"] = function(args)
    RunConsoleCommand("retry", "")
end,

["lag_all"] = function(args)
    log("Lagging everyone")
    for i=0,500 do
        RunConsoleCommand("lagflare")
        RunConsoleCommand("lagflare")
    end
end,

["c4_crash_all"] = function(args)
    log("BETA: Attempting to use c4's to crash.")
    for i=0,300 do
        RunConsoleCommand("c4spam")
    end
end,

["bloodtrail_all"] = function(args)
    log("BETA: Attempting to make everyone have a trail of blood.")
    RunConsoleCommand("bloodtrailall")
end,

["unbloodtrail_all"] = function(args)
    log("BETA: Removing all trails of blood..")
    RunConsoleCommand("ent_remove_all", "point_hurt")
end
}

ChatCommands["help"] = function(args)
    log("Commands:")
    for cmd in pairs(ChatCommands) do
        log(cmd)
    end
end

hook.Add("OnPlayerChat", "DynamicPrefixChatCommands", function(ply, text)
    if ply ~= LocalPlayer() then return end
    if not string.StartWith(text, currentPrefix) then return end
    local withoutPrefix = string.sub(text, #currentPrefix + 1)
    local parts = string.Explode(" ", withoutPrefix)
    local command = string.lower(parts[1])
    table.remove(parts, 1)
    if ChatCommands[command] then
        ChatCommands[command](parts)
        return true
    else
    	log("Command " .. command .. " Is invalid!")
    end
    return true
end)
log("Initalized!")
RunConsoleCommand("play", "friends/friend_join.wav")
timer.Simple(1,function()
    hook.Run("AddNotify", "Type " .. currentPrefix .. "help In chat to get started!", NOTIFY_GENERIC, 5)
    timer.Simple(1,function()
    hook.Run("AddNotify", "Please run the commands printed in console BEFORE using some commands (lag_all)", NOTIFY_GENERIC, 5)
    print('alias lagflare "ent_create env_flare modelscale 0 scale 10000"')
    print('alias c4spam "ent_create swcs_planted_c4 modelscale 0"')
    print('alias bloodtrailall "ent_create point_hurt enabled 1 spawnflags 1 damageradius 30000000000000000000000000 DamageType 2097152 damage 0"')
end)
end)
end

if gui.IsGameUIVisible() then
   gui.HideGameUI()
end

log("Fetching latest ver...")
http.Fetch("https://github.com/thesecretsauce67420/my-tools/raw/refs/heads/main/version.txt", function(version)
     version = version
     if tonumber(version) > tonumber(ver) then
         log("Your version is out of date! retrieving latest version...")
         http.Fetch("https://github.com/thesecretsauce67420/my-tools/raw/refs/heads/main/LatestToolVer.lua", function(code)
              log("Retrieved latest ver, saving to a file and running in 2 seconds..")
              file.Write( "LatestToolz.txt", code )
              RunConsoleCommand("play", "hl1/fvox/bell.wav")
              timer.Simple(2,function() RunString(code) end)
         end, 
         function(err) timer.Simple(2,function() log("Failed to get latest version. Error: " .. err) RunConsoleCommand("play", "hl1/fvox/fuzz.wav") end) end)
     elseif tonumber(version) < tonumber(ver) then
         log("Your version is somehow more up to date? Please make a github issue to report this issue, he mightve forgotten to update version.txt")
         log("Initalizing in 2 seconds..")
         timer.Simple(2,function() Initalize() end)
     else
         log("Your version is up to date! initalizing in 2 seconds...")
         timer.Simple(2,function() Initalize() end)
     end
end)

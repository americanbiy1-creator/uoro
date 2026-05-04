-- please skidders stop looking at my code
-- btw if someone is complaining i did this in fucking 10 hours and i should call this beta since im not done tbh

local badExecutors = { Xeno = true, Solara = true, JJsploit = true }
local executor = identifyexecutor()
if badExecutors[executor] then
    game:GetService("Players").LocalPlayer:Kick("use a better executor")
end

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/americanbiy1-creator/uoro/main/modbucket.lua"))()

local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localplayer = PlayerService.LocalPlayer
local character = localplayer.Character or localplayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidrootpart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local Blink = require(ReplicatedStorage.Blink.Client)
local Entity = require(ReplicatedStorage.Modules.Entity)
local Knit = require(ReplicatedStorage.Modules.Knit.Client)

local storedHitboxes = {}

local IsHoldingBow = false
local ChargeStartTime = 0
local HasBowEquipped = false
local IsAutoShooting = false
local ActiveMouseButton = 0

local killAuraCooldownActive = false
local autoPlaceLastTime = 0
local autoPlaceRayParams = RaycastParams.new()
autoPlaceRayParams.FilterType = Enum.RaycastFilterType.Exclude

local flyBodyVelocity = nil
local flyBodyGyro = nil

local FallDamageRemote = nil
local OriginalFallDamageFire = nil

local Gravity = workspace.Gravity
local TrajectoryPointCount = 50
local TimeStep = 0.03
local TrajectoryLines = {}
local TrajectoryOutlines = {}

local espCache = {}
local espConnections = {}
local chamsCache = {}

local originalMouseIcon = UserInputService.MouseIcon

-- forward declarations for functions used in Unload callback
local ClearTrajectory
local StopFly
local StartFly
local CleanupESP
local CleanupChams
local UpdateChams

for i = 1, TrajectoryPointCount do
    local outline = Drawing.new("Line")
    outline.Color = Color3.fromRGB(0, 0, 0)
    outline.Thickness = 3
    outline.Visible = false
    outline.ZIndex = 1

    local line = Drawing.new("Line")
    line.Color = Color3.fromRGB(255, 255, 255)
    line.Thickness = 1
    line.Visible = false
    line.ZIndex = 2

    TrajectoryOutlines[i] = outline
    TrajectoryLines[i] = line
end

local FOVOutline = Drawing.new("Circle")
FOVOutline.Thickness = 2.5
FOVOutline.Filled = false
FOVOutline.Color = Color3.fromRGB(0, 0, 0)
FOVOutline.Visible = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false

-- bracket ui setup (using modbucket - modified bracket v34 with branding removed)
local Window = Bracket:Window({
    Name = "uoro",
    Enabled = true,
    Color = Color3.fromRGB(255, 128, 64),
    Size = UDim2.new(0, 600, 0, 500),
    Position = UDim2.new(0.5, -300, 0.5, -250),
    Blur = true,
})

local Watermark = Window:Watermark({
    Title = "uoro",
    Flag = "UI/Watermark/Position",
    Enabled = true,
})

local function getFlag(flag) return Window.Flags[flag] end

-- set custom cursor (pink cursor/crosshair)
UserInputService.MouseIcon = "rbxassetid://11720549778"

-- tabs
local Tabs = {
    ESP = Window:Tab({Name = "ESP"}),
    Aimbot = Window:Tab({Name = "Aimbot"}),
    Combat = Window:Tab({Name = "Combat"}),
    Movement = Window:Tab({Name = "Movement"}),
    Misc = Window:Tab({Name = "Misc"}),
    Settings = Window:Tab({Name = "Settings"}),
}

-- esp ui
local espGroup = Tabs.ESP:Section({Name = "ESP Settings", Side = "Left"})
local espFeaturesGroup = Tabs.ESP:Section({Name = "ESP Features", Side = "Right"})
local espChamsGroup = Tabs.ESP:Section({Name = "Chams", Side = "Right"})

espGroup:Toggle({Name = "Enable ESP", Flag = "EspEnabled", Value = false}):Tooltip("toggles esp")

local espBoxToggle = espFeaturesGroup:Toggle({Name = "Box ESP", Flag = "EspBoxEnabled", Value = false})
espBoxToggle:Tooltip("shows a box around players")
espBoxToggle:Colorpicker({Flag = "EspBoxColor", Value = {0, 0, 1, 0, false}, Callback = function() end})

local espNameToggle = espFeaturesGroup:Toggle({Name = "Name ESP", Flag = "EspNameEnabled", Value = false})
espNameToggle:Tooltip("shows player names above their box")
espNameToggle:Colorpicker({Flag = "EspNameColor", Value = {0, 0, 1, 0, false}, Callback = function() end})

espFeaturesGroup:Toggle({Name = "Health Bar", Flag = "EspHealthBarEnabled", Value = false}):Tooltip("shows health bar next to the box")
espFeaturesGroup:Toggle({Name = "Health Text", Flag = "EspHealthTextEnabled", Value = false}):Tooltip("shows health numbers next to the box")

local espDistToggle = espFeaturesGroup:Toggle({Name = "Distance", Flag = "EspDistanceEnabled", Value = false})
espDistToggle:Tooltip("shows distance in studs below the box")
espDistToggle:Colorpicker({Flag = "EspDistanceColor", Value = {0, 0, 1, 0, false}, Callback = function() end})

local espChamsToggle = espChamsGroup:Toggle({Name = "Enable Chams", Flag = "EspChamsEnabled", Value = false})
espChamsToggle:Tooltip("shows BoxHandleAdornment highlights on players")
espChamsToggle:Colorpicker({Flag = "EspChamsColor", Value = {0.08, 1, 1, 0.5, false}, Callback = function() end})

espChamsGroup:Slider({Name = "Chams Transparency", Flag = "EspChamsTransparency", Min = 0, Max = 10, Value = 5, Precise = 0}):Tooltip("0 = opaque, 10 = invisible")

-- aimbot ui
local swordGroup = Tabs.Aimbot:Section({Name = "Sword Aimbot", Side = "Left"})
local bowGroup = Tabs.Aimbot:Section({Name = "Bow Aimbot", Side = "Right"})
local fovGroup = Tabs.Aimbot:Section({Name = "FOV Circle", Side = "Left"})

local swordAimbotToggle = swordGroup:Toggle({Name = "Sword Aimbot", Flag = "SwordAimbotEnabled", Value = false})
swordAimbotToggle:Tooltip("aims at nearest enemy when having sword equipped")
swordAimbotToggle:Keybind({Flag = "SwordAimbotKey", Value = "LeftAlt"})

swordGroup:Toggle({Name = "Wall Check", Flag = "SwordWallcheck", Value = false}):Tooltip("only aims at players not behind walls")
swordGroup:Toggle({Name = "Smoothness", Flag = "SwordSmoothnessEnabled", Value = false}):Tooltip("adds smoothness to the aimbot")
swordGroup:Slider({Name = "Smoothness Value", Flag = "SwordSmoothness", Min = 1, Max = 10, Value = 1, Precise = 0}):Tooltip("higher = smoother but slower")
swordGroup:Slider({Name = "FOV Radius", Flag = "SwordFOV", Min = 10, Max = 500, Value = 200, Precise = 0}):Tooltip("radius of the FOV circle for sword aimbot")

local bowAimbotToggle = bowGroup:Toggle({Name = "Bow Aimbot", Flag = "BowAimbotEnabled", Value = false})
bowAimbotToggle:Tooltip("aims at nearest enemy when having bow equipped")
bowAimbotToggle:Keybind({Flag = "BowAimbotKey", Value = "MouseButton2", Mouse = true})

bowGroup:Toggle({Name = "Wall Check", Flag = "BowWallcheck", Value = false}):Tooltip("only aims at players not behind wall")
bowGroup:Toggle({Name = "Smoothness", Flag = "BowSmoothnessEnabled", Value = false}):Tooltip("makes aimbot smoother")
bowGroup:Slider({Name = "Smoothness Value", Flag = "BowSmoothness", Min = 1, Max = 10, Value = 1, Precise = 0}):Tooltip("higher = smoother but slower")
bowGroup:Slider({Name = "FOV Radius", Flag = "BowFOV", Min = 10, Max = 500, Value = 200, Precise = 0}):Tooltip("radius of the FOV circle for bow aimbot")

fovGroup:Toggle({Name = "Show FOV Circle", Flag = "ShowFOV", Value = false}):Tooltip("displays the FOV circle on screen")

-- combat ui
local combatGroup = Tabs.Combat:Section({Name = "Hitbox Expander", Side = "Left"})
local autoClickGroup = Tabs.Combat:Section({Name = "Auto Clicker", Side = "Right"})
local killAuraGroup = Tabs.Combat:Section({Name = "Kill Aura", Side = "Left"})

combatGroup:Toggle({Name = "Enable Hitbox Expander", Flag = "HitboxExpander", Value = false}):Tooltip("expands enemy hitboxes (doesn't act as infinite reach tho)")
combatGroup:Slider({Name = "Hitbox Size", Flag = "HitboxSize", Min = 1, Max = 200, Value = 50, Precise = 0}):Tooltip("size of expanded hitboxes")
combatGroup:Slider({Name = "Hitbox Transparency", Flag = "HitboxTransparency", Min = 0, Max = 10, Value = 10, Precise = 0}):Tooltip("Transparency of expanded hitboxes (10 = invisible)")

local autoClickToggle = autoClickGroup:Toggle({Name = "Auto Clicker", Flag = "AutoClicker", Value = false})
autoClickToggle:Tooltip("auto clicks for you")
autoClickToggle:Keybind({Flag = "AutoClickerKey", Value = "Q"})

autoClickGroup:Slider({Name = "Min CPS", Flag = "MinCPS", Min = 1, Max = 30, Value = 12, Precise = 0}):Tooltip("minimum clicks per second")
autoClickGroup:Slider({Name = "Max CPS", Flag = "MaxCPS", Min = 1, Max = 30, Value = 16, Precise = 0}):Tooltip("maximum clicks per second")

local killAuraToggle = killAuraGroup:Toggle({Name = "Kill Aura", Flag = "KillAura", Value = false})
killAuraToggle:Tooltip("automatically attacks nearby players")
killAuraToggle:Keybind({Flag = "KillAuraKey", Value = "K"})

killAuraGroup:Slider({Name = "Radius", Flag = "KillAuraRadius", Min = 5, Max = 200, Value = 10, Precise = 0}):Tooltip("distance in studs to detect targets")
killAuraGroup:Slider({Name = "Attack Cooldown", Flag = "KillAuraCooldown", Min = 1, Max = 20, Value = 1, Precise = 0}):Tooltip("cooldown between attacks (1 = 0.1s, 10 = 1s)")

-- movement ui
local movementGroup = Tabs.Movement:Section({Name = "Movement", Side = "Left"})
local flyGroup = Tabs.Movement:Section({Name = "Fly", Side = "Right"})

movementGroup:Toggle({Name = "Speed Hack", Flag = "Speedhack", Value = false}):Tooltip("makes you faster")
movementGroup:Slider({Name = "Walk Speed", Flag = "SpeedhackValue", Min = 1, Max = 50, Value = 25, Precise = 0}):Tooltip("modified walkspeed value (be careful a high one might bug you out)")
movementGroup:Toggle({Name = "No Fall Damage", Flag = "NoFallDamage", Value = false}):Tooltip("you have no fall damage")

local noclipToggle = movementGroup:Toggle({Name = "Noclip", Flag = "Noclip", Value = false})
noclipToggle:Tooltip("walk through walls")
noclipToggle:Keybind({Flag = "NoclipKey", Value = "N"})

flyGroup:Toggle({Name = "Fly", Flag = "Fly", Value = false}):Tooltip("lets you fly")

local flyKeybind = flyGroup:Keybind({
    Name = "Fly Key",
    Flag = "FlyKey",
    Value = "V",
    Callback = function(_key, pressed, _toggled)
        if pressed then
            Window:SetValue("Fly", not getFlag("Fly"))
        end
    end,
})
flyKeybind:Tooltip("Fly key")

flyGroup:Slider({Name = "Fly Speed", Flag = "FlySpeed", Min = 1, Max = 200, Value = 20, Precise = 0}):Tooltip("how fast you fly")

-- misc ui
local miscGroup = Tabs.Misc:Section({Name = "Bow Utilities", Side = "Left"})
local autoPlaceGroup = Tabs.Misc:Section({Name = "Auto Place", Side = "Right"})
local mapGroup = Tabs.Misc:Section({Name = "Map", Side = "Left"})

miscGroup:Toggle({Name = "Bow Trajectory", Flag = "BowTrajectory", Value = false}):Tooltip("shows the predicted arrow path when charging bow")
miscGroup:Toggle({Name = "Auto Shoot", Flag = "AutoShoot", Value = false}):Tooltip("automatically releases bow when trajectory hits a player (a bit broken)")

local autoPlaceToggle = autoPlaceGroup:Toggle({Name = "Auto Place", Flag = "AutoPlace", Value = false})
autoPlaceToggle:Tooltip("automatically places blocks while moving")
autoPlaceToggle:Keybind({Flag = "AutoPlaceKey", Value = "P"})

local showMapToggle = mapGroup:Toggle({Name = "Show Map", Flag = "ShowMap", Value = false})
showMapToggle:Tooltip("shows the in-game map")
showMapToggle:Keybind({Flag = "ShowMapKey", Value = "M"})

-- settings tab
local menuSection = Tabs.Settings:Section({Name = "Menu", Side = "Left"})

local UIToggle = menuSection:Toggle({
    Name = "UI Enabled",
    Flag = "UI/Enabled",
    Value = Window.Enabled,
    Callback = function(value) Window.Enabled = value end,
})
UIToggle:Keybind({
    Flag = "UI/Keybind",
    Value = "RightShift",
    DoNotClear = true,
})
UIToggle:Colorpicker({
    Flag = "UI/Color",
    Value = {15/360, 0.75, 1, 0, false},
    Callback = function(_hsvar, color) Window.Color = color end,
})

menuSection:Toggle({Name = "Open On Load", Flag = "UI/OOL", Value = true})

local watermarkToggle = menuSection:Toggle({
    Name = "Watermark",
    Flag = "UI/Watermark/Enabled",
    Value = true,
    Callback = function(value) Watermark.Enabled = value end,
})
watermarkToggle:Keybind({Flag = "UI/Watermark/Keybind"})

menuSection:Button({
    Name = "Unload",
    Callback = function()
        Window.Enabled = false
        Watermark.Enabled = false

        ClearTrajectory()
        for i = 1, TrajectoryPointCount do
            pcall(function() TrajectoryLines[i]:Remove() end)
            pcall(function() TrajectoryOutlines[i]:Remove() end)
        end

        FOVOutline:Remove()
        FOVCircle:Remove()

        StopFly(localplayer.Character)

        for player, original in pairs(storedHitboxes) do
            if player and player.Character then
                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    targetHRP.Size = original.Size
                    targetHRP.Transparency = original.Transparency
                    targetHRP.CanCollide = original.CanCollide
                end
            end
        end
        storedHitboxes = {}

        for player, _ in pairs(espCache) do
            CleanupESP(player)
        end

        for player, _ in pairs(chamsCache) do
            CleanupChams(player)
        end

        if FallDamageRemote and OriginalFallDamageFire then
            FallDamageRemote.fire = OriginalFallDamageFire
        end

        UserInputService.MouseIcon = originalMouseIcon

        if Bracket and Bracket.Screen then
            pcall(function() Bracket.Screen:Destroy() end)
        end
    end,
})

Tabs.Settings:AddConfigSection("uoro", "Left")

local backgroundSection = Tabs.Settings:Section({Name = "Background", Side = "Right"})

backgroundSection:Colorpicker({
    Name = "Color",
    Flag = "Background/Color",
    Value = {1, 1, 0, 0, false},
    Callback = function(hsvar, color)
        Window.Background.ImageColor3 = color
        Window.Background.ImageTransparency = hsvar[4]
    end,
})

backgroundSection:Textbox({
    HideName = true,
    Flag = "Background/CustomImage",
    Placeholder = "rbxassetid://ImageId",
    Callback = function(text, enterPressed)
        if enterPressed then Window.Background.Image = text end
    end,
})

backgroundSection:Dropdown({HideName = true, Flag = "Background/Image", List = {
    {Name = "None", Mode = "Button", Value = true, Callback = function()
        Window.Background.Image = ""
        Window.Flags["Background/CustomImage"] = ""
    end},
    {Name = "Floral", Mode = "Button", Callback = function()
        Window.Background.Image = "rbxassetid://5553946656"
        Window.Flags["Background/CustomImage"] = ""
    end},
    {Name = "Hearts", Mode = "Button", Callback = function()
        Window.Background.Image = "rbxassetid://6073763717"
        Window.Flags["Background/CustomImage"] = ""
    end},
    {Name = "Abstract", Mode = "Button", Callback = function()
        Window.Background.Image = "rbxassetid://6073743871"
        Window.Flags["Background/CustomImage"] = ""
    end},
    {Name = "Hexagon", Mode = "Button", Callback = function()
        Window.Background.Image = "rbxassetid://6073628839"
        Window.Flags["Background/CustomImage"] = ""
    end},
    {Name = "Circles", Mode = "Button", Callback = function()
        Window.Background.Image = "rbxassetid://6071579801"
        Window.Flags["Background/CustomImage"] = ""
    end},
}})

backgroundSection:Slider({
    Name = "Tile Offset",
    Flag = "Background/Offset",
    Min = 74,
    Max = 296,
    Value = 74,
    Precise = 0,
    Callback = function(value)
        Window.Background.TileSize = UDim2.fromOffset(value, value)
    end,
})

-- set defaults: no background image, blur on
Window.Background.Image = ""
Window:SetValue("Background/Offset", 74)
Window:AutoLoadConfig("uoro")
Window:SetValue("UI/Enabled", getFlag("UI/OOL"))

-- helper functions
local function isBlockTool(tool)
    if not tool then return false end
    return tool.Name == "Blocks" or tool.Name:sub(-5) == "Block" or tool.Name:find("Block") ~= nil
end

local function isSwordTool(tool)
    if not tool then return false end
    local n = tool.Name
    return n:sub(-5) == "Sword" or n:sub(-3) == "Axe" or n:sub(-4) == "Mace" or n:sub(-5) == "Knife" or n:sub(-5) == "Spear"
end

local function SnapToGrid(v)
    local S = 3
    return Vector3.new(math.round(v.X / S) * S, math.round(v.Y / S) * S, math.round(v.Z / S) * S)
end

local function WallCheck(origin, targetHRP, targetCharacter)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character, targetCharacter }

    local direction = targetHRP.Position - origin
    local result = workspace:Raycast(origin, direction.Unit * direction.Magnitude, rayParams)

    if not result then return true end

    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and hitModel == targetCharacter then return true end

    return false
end

local function GetClosestPlayer(fovRadius, useWallcheck)
    local closestPlayer = nil
    local shortestDist = fovRadius
    local mousePos = UserInputService:GetMouseLocation()
    local camPos = camera.CFrame.Position

    for _, player in pairs(PlayerService:GetPlayers()) do
        if player == localplayer then continue end

        local playerChar = player.Character
        if not playerChar then continue end

        local targetHRP = playerChar:FindFirstChild("HumanoidRootPart")
        local targetHum = playerChar:FindFirstChildOfClass("Humanoid")
        if not targetHRP or not targetHum or targetHum.Health <= 0 then continue end

        local screenPos, onScreen = camera:WorldToViewportPoint(targetHRP.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist >= shortestDist then continue end

        if useWallcheck then
            if WallCheck(camPos, targetHRP, playerChar) then
                closestPlayer = player
                shortestDist = dist
            end
        else
            closestPlayer = player
            shortestDist = dist
        end
    end

    return closestPlayer
end

local function GetKillAuraTarget()
    local char = localplayer.Character
    if not char or not char.PrimaryPart then return nil end

    local bestDist = math.huge
    local bestChar = nil
    local radius = getFlag("KillAuraRadius")

    for _, player in pairs(PlayerService:GetPlayers()) do
        if player == localplayer then continue end

        local playerChar = player.Character
        if not playerChar then continue end

        local targetHRP = playerChar:FindFirstChild("HumanoidRootPart")
        local targetHum = playerChar:FindFirstChildOfClass("Humanoid")
        if not targetHRP or not targetHum or targetHum.Health <= 0 then continue end

        local dist = (char.PrimaryPart.Position - targetHRP.Position).Magnitude
        if dist <= radius and dist < bestDist then
            bestDist = dist
            bestChar = playerChar
        end
    end

    return bestChar
end

local function TryKillAuraAttack(targetChar, weaponName)
    local char = localplayer.Character
    if not char or not char.PrimaryPart then return false end
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return false end

    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return false end

    local dist = (char.PrimaryPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
    if dist > getFlag("KillAuraRadius") then return false end

    local targetEntity = Entity.FindByCharacter(targetChar)
    if not targetEntity then return false end

    local isCrit = char.PrimaryPart.AssemblyLinearVelocity.Y < 0

    pcall(function()
        Blink.item_action.attack_entity.fire({
            target_entity_id = targetEntity.Id,
            is_crit = isCrit,
            weapon_name = weaponName,
            extra = { rizz = "Bro.", owo = "What's this? OwO ", those = workspace.Name == "Ok" }
        })
    end)

    return true
end

-- fly functions
StopFly = function(char)
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end

    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

StartFly = function(char)
    StopFly(char)

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.P = 1e4
    flyBodyVelocity.Parent = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
    flyBodyGyro.P = 2e4
    flyBodyGyro.D = 1e3
    flyBodyGyro.CFrame = CFrame.new(root.Position)
    flyBodyGyro.Parent = root
end

-- find fall damage remote
local function FindFallDamageRemote()
    for _, closure in pairs(getgc()) do
        if type(closure) == "table" then
            local playerState = rawget(closure, "player_state")
            if playerState and type(playerState) == "table" then
                local fallDamage = rawget(playerState, "take_fall_damage")
                if fallDamage and type(fallDamage) == "table" then
                    if type(rawget(fallDamage, "fire")) == "function" then
                        return fallDamage
                    end
                end
            end
        end
    end

    for _, closure in pairs(getgc()) do
        if type(closure) == "function" and islclosure(closure) then
            local info = debug.getinfo(closure)
            if info and info.source and info.source:find("MovementController") then
                for _, upvalue in pairs(debug.getupvalues(closure)) do
                    if type(upvalue) == "table" then
                        local playerState = rawget(upvalue, "player_state")
                        if playerState and type(playerState) == "table" then
                            local fallDamage = rawget(playerState, "take_fall_damage")
                            if fallDamage and type(fallDamage) == "table" then
                                if type(rawget(fallDamage, "fire")) == "function" then
                                    return fallDamage
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

FallDamageRemote = FindFallDamageRemote()
if FallDamageRemote then
    OriginalFallDamageFire = FallDamageRemote.fire
    FallDamageRemote.fire = newcclosure(function(damage)
        if getFlag("NoFallDamage") then return end
        return OriginalFallDamageFire(damage)
    end)
end

-- speedhack hook
local OldIndex = nil
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and key == "WalkSpeed" and getFlag("Speedhack") then
        local ok, result = pcall(function() return self:IsA("Humanoid") end)
        if ok and result then
            return getFlag("SpeedhackValue")
        end
    end
    return OldIndex(self, key)
end))

-- esp functions
local function HideAllESP(drawings)
    for _, drawing in pairs(drawings) do
        drawing.Visible = false
    end
end

local function RemoveAllESP(drawings)
    for _, drawing in pairs(drawings) do
        pcall(function() drawing:Remove() end)
    end
end

local function GetHealthColor(healthPercent)
    local r = math.clamp((1 - healthPercent) * 2, 0, 1)
    local g = math.clamp(healthPercent * 2, 0, 1)
    return Color3.new(r, g, 0)
end

local function GetFlagColor(flagName)
    local hsvar = getFlag(flagName)
    if type(hsvar) == "table" then
        return Color3.fromHSV(hsvar[1], hsvar[2], hsvar[3])
    end
    return Color3.fromRGB(255, 255, 255)
end

-- chams functions
CleanupChams = function(player)
    if chamsCache[player] then
        for _, adornment in pairs(chamsCache[player]) do
            pcall(function() adornment:Destroy() end)
        end
        chamsCache[player] = nil
    end
end

UpdateChams = function(player)
    local playerChar = player.Character
    if not playerChar then
        CleanupChams(player)
        return
    end

    if not getFlag("EspEnabled") or not getFlag("EspChamsEnabled") then
        CleanupChams(player)
        return
    end

    local chamsColor = GetFlagColor("EspChamsColor")
    local chamsTransparency = getFlag("EspChamsTransparency") / 10

    if not chamsCache[player] then
        chamsCache[player] = {}
    end

    local existingParts = {}
    for _, adornment in pairs(chamsCache[player]) do
        if adornment.Adornee then
            existingParts[adornment.Adornee] = adornment
        end
    end

    local newAdornments = {}
    for _, part in pairs(playerChar:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local existing = existingParts[part]
            if existing then
                existing.Color3 = chamsColor
                existing.Transparency = chamsTransparency
                existing.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
                existing.Visible = true
                newAdornments[#newAdornments + 1] = existing
                existingParts[part] = nil
            else
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = part
                box.AlwaysOnTop = true
                box.ZIndex = 5
                box.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
                box.Color3 = chamsColor
                box.Transparency = chamsTransparency
                box.Parent = part
                newAdornments[#newAdornments + 1] = box
            end
        end
    end

    for _, adornment in pairs(existingParts) do
        pcall(function() adornment:Destroy() end)
    end

    chamsCache[player] = newAdornments
end

CleanupESP = function(player)
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
    if espCache[player] then
        RemoveAllESP(espCache[player])
        espCache[player] = nil
    end
    CleanupChams(player)
end

local function SetupESP(player)
    local Drawings = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBarOutline = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }

    Drawings.BoxOutline.ZIndex = 1
    Drawings.Box.ZIndex = 3
    Drawings.Name.ZIndex = 4
    Drawings.HealthBarOutline.ZIndex = 1
    Drawings.HealthBar.ZIndex = 2
    Drawings.HealthText.ZIndex = 4
    Drawings.Distance.ZIndex = 4

    Drawings.Box.Filled = false
    Drawings.Box.Thickness = 1

    Drawings.BoxOutline.Filled = false
    Drawings.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    Drawings.BoxOutline.Thickness = 2.4

    Drawings.Name.Size = 13
    Drawings.Name.Font = Drawing.Fonts.System
    Drawings.Name.Center = true
    Drawings.Name.Outline = true
    Drawings.Name.OutlineColor = Color3.fromRGB(0, 0, 0)

    Drawings.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    Drawings.HealthBarOutline.Thickness = 1
    Drawings.HealthBarOutline.Filled = false

    Drawings.HealthBar.Thickness = 1
    Drawings.HealthBar.Filled = true

    Drawings.HealthText.Size = 12
    Drawings.HealthText.Font = Drawing.Fonts.System
    Drawings.HealthText.Center = false
    Drawings.HealthText.Outline = true
    Drawings.HealthText.OutlineColor = Color3.fromRGB(0, 0, 0)

    Drawings.Distance.Size = 13
    Drawings.Distance.Font = Drawing.Fonts.System
    Drawings.Distance.Center = true
    Drawings.Distance.Outline = true
    Drawings.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)

    espCache[player] = Drawings

    local conn = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            HideAllESP(Drawings)
            return
        end

        if not getFlag("EspEnabled") then
            HideAllESP(Drawings)
            return
        end

        local playerChar = player.Character
        if not playerChar then HideAllESP(Drawings) return end

        local playerHRP = playerChar:FindFirstChild("HumanoidRootPart")
        local playerHum = playerChar:FindFirstChildOfClass("Humanoid")
        if not playerHRP or not playerHum then HideAllESP(Drawings) return end

        local localHRP = character and character:FindFirstChild("HumanoidRootPart")
        if not localHRP then HideAllESP(Drawings) return end

        local screenPos, onScreen = camera:WorldToViewportPoint(playerHRP.Position)
        if not onScreen then HideAllESP(Drawings) return end

        local scale = 1 / (screenPos.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
        local width = math.floor(4.5 * scale)
        local height = math.floor(6 * scale)
        local x = math.floor(screenPos.X)
        local y = math.floor(screenPos.Y)
        local xPos = math.floor(x - width * 0.5)
        local yPos = math.floor((y - height * 0.5) + (0.5 * scale))

        if getFlag("EspBoxEnabled") then
            Drawings.Box.Color = GetFlagColor("EspBoxColor")
            Drawings.Box.Size = Vector2.new(width, height)
            Drawings.Box.Position = Vector2.new(xPos, yPos)
            Drawings.Box.Visible = true

            Drawings.BoxOutline.Size = Vector2.new(width, height)
            Drawings.BoxOutline.Position = Vector2.new(xPos, yPos)
            Drawings.BoxOutline.Visible = true
        else
            Drawings.Box.Visible = false
            Drawings.BoxOutline.Visible = false
        end

        if getFlag("EspNameEnabled") then
            Drawings.Name.Color = GetFlagColor("EspNameColor")
            Drawings.Name.Text = player.Name
            Drawings.Name.Position = Vector2.new(xPos + (width * 0.5), yPos - 15)
            Drawings.Name.Visible = true
        else
            Drawings.Name.Visible = false
        end

        if getFlag("EspHealthBarEnabled") then
            local healthPercent = math.clamp(playerHum.Health / playerHum.MaxHealth, 0, 1)
            local healthHeight = math.floor(height * healthPercent)

            Drawings.HealthBarOutline.Size = Vector2.new(3, height)
            Drawings.HealthBarOutline.Position = Vector2.new(xPos - 5, yPos)
            Drawings.HealthBarOutline.Visible = true

            Drawings.HealthBar.Size = Vector2.new(3, healthHeight)
            Drawings.HealthBar.Position = Vector2.new(xPos - 5, yPos + (height - healthHeight))
            Drawings.HealthBar.Color = GetHealthColor(healthPercent)
            Drawings.HealthBar.Visible = true
        else
            Drawings.HealthBarOutline.Visible = false
            Drawings.HealthBar.Visible = false
        end

        if getFlag("EspHealthTextEnabled") then
            Drawings.HealthText.Text = string.format("%d/%d", math.floor(playerHum.Health), math.floor(playerHum.MaxHealth))
            local healthPercent = math.clamp(playerHum.Health / playerHum.MaxHealth, 0, 1)
            Drawings.HealthText.Color = GetHealthColor(healthPercent)
            Drawings.HealthText.Position = Vector2.new(xPos - 40, yPos)
            Drawings.HealthText.Visible = true
        else
            Drawings.HealthText.Visible = false
        end

        if getFlag("EspDistanceEnabled") then
            Drawings.Distance.Color = GetFlagColor("EspDistanceColor")
            local dist = math.floor((localHRP.Position - playerHRP.Position).Magnitude)
            Drawings.Distance.Text = string.format("%d studs", dist)
            Drawings.Distance.Position = Vector2.new(xPos + (width * 0.5), yPos + height + 2)
            Drawings.Distance.Visible = true
        else
            Drawings.Distance.Visible = false
        end

        UpdateChams(player)
    end)

    espConnections[player] = conn
end

-- esp for existing players
for _, v in pairs(PlayerService:GetPlayers()) do
    if v ~= localplayer then
        coroutine.wrap(SetupESP)(v)
    end
end

PlayerService.PlayerAdded:Connect(function(v)
    task.delay(1, function()
        coroutine.wrap(SetupESP)(v)
    end)
end)

PlayerService.PlayerRemoving:Connect(function(v)
    CleanupESP(v)
end)

-- auto clicker thread
local AutoClickerThread = coroutine.create(function()
    while true do
        if getFlag("AutoClicker") then
            local cps = math.random(getFlag("MinCPS"), getFlag("MaxCPS"))
            mouse1click()
            task.wait(1 / cps)
        else
            task.wait(0.01)
        end
    end
end)
coroutine.resume(AutoClickerThread)

-- show map loop
RunService.RenderStepped:Connect(function()
    local mainGui = localplayer.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then return end
    local map = mainGui:FindFirstChild("Map") or mainGui:FindFirstChild("Minimap") or mainGui:FindFirstChild("MapFrame")
    if not map then return end
    map.Visible = getFlag("ShowMap")
end)

-- noclip loop
RunService.Stepped:Connect(function()
    if not getFlag("Noclip") then return end

    local char = localplayer.Character
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- fly update loop
RunService.RenderStepped:Connect(function()
    local char = localplayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if getFlag("Fly") then
        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            StartFly(char)
        end

        if flyBodyVelocity and flyBodyVelocity.Parent and flyBodyGyro and flyBodyGyro.Parent then
            local cf = camera.CFrame
            local dir = Vector3.zero

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

            flyBodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * getFlag("FlySpeed") or Vector3.zero

            local flatLook = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
            if flatLook.Magnitude > 0.01 then
                flyBodyGyro.CFrame = CFrame.new(root.Position, root.Position + flatLook)
            end
        end
    else
        if flyBodyVelocity and flyBodyVelocity.Parent then
            StopFly(char)
        end
    end
end)

-- auto place and kill aura loop
RunService.Heartbeat:Connect(function()
    -- auto place logic
    if getFlag("AutoPlace") then
        if os.clock() - autoPlaceLastTime >= 0.1 then
            local char = localplayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and root and hum and hum.MoveDirection.Magnitude > 0 then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and isBlockTool(tool) then
                    local ok, ctrl = pcall(function() return Knit.GetController("BlockPlacementController") end)
                    if ok and ctrl then
                        local blockName = tool.Name == "Blocks" and "Clay" or tool.Name:sub(1, -6)
                        local moveDir = hum.MoveDirection
                        local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)

                        if flatDir.Magnitude > 0.01 then
                            flatDir = flatDir.Unit
                            autoPlaceRayParams.FilterDescendantsInstances = { char }

                            for i = 0, 1 do
                                local origin = Vector3.new(
                                    root.Position.X + flatDir.X * (i * 3),
                                    root.Position.Y,
                                    root.Position.Z + flatDir.Z * (i * 3)
                                )
                                local hit = workspace:Raycast(origin, Vector3.new(0, -6, 0), autoPlaceRayParams)
                                if not hit then
                                    pcall(function()
                                        ctrl:PlaceBlock(SnapToGrid(origin - Vector3.new(0, 4.5, 0)), blockName)
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            autoPlaceLastTime = os.clock()
        end
    end

    -- kill aura logic
    if getFlag("KillAura") and not killAuraCooldownActive then
        local char = localplayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if char and root and hum then
            local target = GetKillAuraTarget()
            if target then
                local tool = char:FindFirstChildOfClass("Tool")
                local hasSword = tool and isSwordTool(tool)

                if not hasSword then
                    for _, t in pairs(localplayer.Backpack:GetChildren()) do
                        if t:IsA("Tool") and isSwordTool(t) then
                            hum:EquipTool(t)
                            break
                        end
                    end
                else
                    killAuraCooldownActive = true
                    TryKillAuraAttack(target, tool.Name)

                    task.spawn(function()
                        task.wait(getFlag("KillAuraCooldown") / 10)
                        killAuraCooldownActive = false
                    end)
                end
            end
        end
    end
end)

-- main aimbot and hitbox expander loop
RunService.RenderStepped:Connect(function()
    local char = localplayer.Character
    if not char then return end

    local equippedTool = char:FindFirstChildOfClass("Tool")
    local isSword = equippedTool and (string.find(equippedTool.Name:lower(), "sword") or CollectionService:HasTag(equippedTool, "Sword"))
    local isBow = equippedTool and (equippedTool.Name == "Bow" or CollectionService:HasTag(equippedTool, "Bow"))

    -- hitbox expander
    if getFlag("HitboxExpander") then
        local hitboxSize = getFlag("HitboxSize")
        local hitboxTransparency = getFlag("HitboxTransparency") / 10

        for _, player in pairs(PlayerService:GetPlayers()) do
            if player == localplayer then continue end

            local playerChar = player.Character
            if not playerChar then continue end

            local targetHRP = playerChar:FindFirstChild("HumanoidRootPart")
            if not targetHRP then continue end

            if not storedHitboxes[player] then
                storedHitboxes[player] = {
                    Size = targetHRP.Size,
                    Transparency = targetHRP.Transparency,
                    CanCollide = targetHRP.CanCollide
                }
            end

            targetHRP.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            targetHRP.Transparency = hitboxTransparency
            targetHRP.CanCollide = false
        end
    else
        for player, original in pairs(storedHitboxes) do
            if player and player.Character then
                local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    targetHRP.Size = original.Size
                    targetHRP.Transparency = original.Transparency
                    targetHRP.CanCollide = original.CanCollide
                end
            end
            storedHitboxes[player] = nil
        end
    end

    -- aimbot uses toggle value directly (keybind controls toggle via ToggleKeybind)
    local doSwordAimbot = getFlag("SwordAimbotEnabled") and isSword
    local doBowAimbot = getFlag("BowAimbotEnabled") and isBow

    local aimTarget = nil
    local currentFov = getFlag("SwordFOV")

    if doSwordAimbot then
        currentFov = getFlag("SwordFOV")
        aimTarget = GetClosestPlayer(getFlag("SwordFOV"), getFlag("SwordWallcheck"))
    elseif doBowAimbot then
        currentFov = getFlag("BowFOV")
        aimTarget = GetClosestPlayer(getFlag("BowFOV"), getFlag("BowWallcheck"))
    end

    -- apply aimbot
    if aimTarget and aimTarget.Character then
        local targetHRP = aimTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local targetScreen, onScreen = camera:WorldToViewportPoint(targetHRP.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local smooth = 1

                if doSwordAimbot and getFlag("SwordSmoothnessEnabled") then
                    smooth = math.clamp(getFlag("SwordSmoothness") / 10, 0.01, 1)
                elseif doBowAimbot and getFlag("BowSmoothnessEnabled") then
                    smooth = math.clamp(getFlag("BowSmoothness") / 10, 0.01, 1)
                end

                local deltaX = (targetScreen.X - mousePos.X) * smooth
                local deltaY = (targetScreen.Y - mousePos.Y) * smooth
                mousemoverel(deltaX, deltaY)
            end
        end
    end

    -- fov circle
    if getFlag("ShowFOV") then
        local cx = camera.ViewportSize.X / 2
        local cy = camera.ViewportSize.Y / 2

        FOVOutline.Position = Vector2.new(cx, cy)
        FOVOutline.Radius = currentFov
        FOVOutline.Visible = true

        FOVCircle.Position = Vector2.new(cx, cy)
        FOVCircle.Radius = currentFov
        FOVCircle.Visible = true
    else
        FOVOutline.Visible = false
        FOVCircle.Visible = false
    end

    -- speedhack
    if getFlag("Speedhack") and humanoid then
        humanoid.WalkSpeed = getFlag("SpeedhackValue")
    end
end)

-- bow trajectory
local sharedRayParams = RaycastParams.new()
sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude

ClearTrajectory = function()
    for i = 1, TrajectoryPointCount do
        TrajectoryLines[i].Visible = false
        TrajectoryOutlines[i].Visible = false
    end
end

local function GetEquippedBow()
    local currentChar = localplayer.Character
    if not currentChar then return nil end

    for _, tool in pairs(currentChar:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name == "Bow" or CollectionService:HasTag(tool, "Bow")) then
            return tool
        end
    end
    return nil
end

local function UpdateBowState()
    HasBowEquipped = GetEquippedBow() ~= nil
    if not HasBowEquipped then
        IsHoldingBow = false
        ClearTrajectory()
    end
end

local function GetCrosshairPosition()
    local mainGui = localplayer.PlayerGui:FindFirstChild("MainGui")
    if mainGui then
        local crosshair = mainGui:FindFirstChild("Crosshair")
        if crosshair then
            local absPos = crosshair.AbsolutePosition
            local absSize = crosshair.AbsoluteSize
            return Vector2.new(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2)
        end
    end

    local vp = camera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

local function GetAimPosition()
    local currentChar = localplayer.Character
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filterList = currentChar and { currentChar } or {}

    if workspace:FindFirstChild("Misc") then
        local pvpArena = workspace.Misc:FindFirstChild("PVPArena")
        if pvpArena then table.insert(filterList, pvpArena) end
    end

    for _, cage in pairs(CollectionService:GetTagged("CageHitbox")) do
        table.insert(filterList, cage.Parent)
    end

    rayParams.FilterDescendantsInstances = filterList
    local crossPos = GetCrosshairPosition()
    local unitRay = camera:ScreenPointToRay(crossPos.X, crossPos.Y, 0)
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)

    if result then return result.Position end
    return unitRay.Origin + unitRay.Direction * 1000
end

local function GetFireOrigin()
    local currentChar = localplayer.Character
    if not currentChar then return nil end

    local root = currentChar:FindFirstChild("HumanoidRootPart")
    if root then return root.Position + Vector3.new(0, 1.5, 0) end

    return camera.CFrame.Position
end

local function GetSpeedFromCharge(elapsed)
    if elapsed < 0.1 then return 35 + (elapsed / 0.1) * 25
    elseif elapsed < 0.5 then return 60 + ((elapsed - 0.1) / 0.4) * 50
    else return 110 + ((math.min(elapsed, 0.7) - 0.5) / 0.2) * 50 end
end

local function SimulateTrajectory(origin, aimPos, arrowSpeed)
    local currentChar = localplayer.Character
    local filterList = currentChar and { currentChar } or {}

    if workspace:FindFirstChild("Misc") then
        local pvpArena = workspace.Misc:FindFirstChild("PVPArena")
        if pvpArena then table.insert(filterList, pvpArena) end
    end

    for _, cage in pairs(CollectionService:GetTagged("CageHitbox")) do
        table.insert(filterList, cage.Parent)
    end

    sharedRayParams.FilterDescendantsInstances = filterList
    local direction = (aimPos - origin).Unit
    local velocity = direction * arrowSpeed
    local positions = {}
    local currentPos = origin
    local hitPlayer = false

    for i = 1, TrajectoryPointCount do
        local t = i * TimeStep
        local nextPos = origin + velocity * t + Vector3.new(0, -0.5 * Gravity * t * t, 0)
        local hit = workspace:Raycast(currentPos, nextPos - currentPos, sharedRayParams)

        if hit then
            table.insert(positions, hit.Position)
            local hitModel = hit.Instance:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel:FindFirstChildOfClass("Humanoid") then
                hitPlayer = true
            end
            break
        end

        currentPos = nextPos
        table.insert(positions, nextPos)
    end

    return positions, hitPlayer
end

-- bow state tracking
if localplayer.Character then
    UpdateBowState()

    localplayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.wait(0.05) UpdateBowState() end
    end)

    localplayer.Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then task.wait(0.05) UpdateBowState() end
    end)
end

localplayer.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    humanoidrootpart = newCharacter:WaitForChild("HumanoidRootPart")

    flyBodyVelocity = nil
    flyBodyGyro = nil
    IsHoldingBow = false
    ClearTrajectory()

    task.wait(0.1)
    UpdateBowState()

    newCharacter.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.wait(0.05) UpdateBowState() end
    end)

    newCharacter.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then task.wait(0.05) UpdateBowState() end
    end)
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then camera = workspace.CurrentCamera end
end)

-- bow input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if getFlag("BowTrajectory") and HasBowEquipped and not IsAutoShooting then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsHoldingBow = true
            ActiveMouseButton = 1
            ChargeStartTime = tick()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            IsHoldingBow = true
            ActiveMouseButton = 2
            ChargeStartTime = tick()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not IsAutoShooting then
        if input.UserInputType == Enum.UserInputType.MouseButton1 and ActiveMouseButton == 1 then
            IsHoldingBow = false
            ActiveMouseButton = 0
            ClearTrajectory()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 and ActiveMouseButton == 2 then
            IsHoldingBow = false
            ActiveMouseButton = 0
            ClearTrajectory()
        end
    end
end)

-- trajectory rendering
RunService.RenderStepped:Connect(function()
    if not getFlag("BowTrajectory") or not HasBowEquipped or not IsHoldingBow then
        ClearTrajectory()
        return
    end

    local elapsed = tick() - ChargeStartTime
    local arrowSpeed = GetSpeedFromCharge(elapsed)
    local origin = GetFireOrigin()
    local aimPos = GetAimPosition()

    if not origin then ClearTrajectory() return end

    local positions, hitPlayer = SimulateTrajectory(origin, aimPos, arrowSpeed)

    -- auto shoot check
    if getFlag("AutoShoot") and hitPlayer and IsHoldingBow and elapsed >= 0.7 then
        IsAutoShooting = true

        if ActiveMouseButton == 1 then mouse1release()
        elseif ActiveMouseButton == 2 then mouse2release() end

        task.wait(0.1)
        IsHoldingBow = false
        ActiveMouseButton = 0
        ClearTrajectory()
        task.wait(0.1)
        IsAutoShooting = false
        return
    end

    local posCount = #positions
    for i = 1, posCount - 1 do
        local currentScreen, currentOnScreen = camera:WorldToViewportPoint(positions[i])
        local nextScreen, nextOnScreen = camera:WorldToViewportPoint(positions[i + 1])

        if currentOnScreen and nextOnScreen then
            local from = Vector2.new(currentScreen.X, currentScreen.Y)
            local to = Vector2.new(nextScreen.X, nextScreen.Y)

            TrajectoryOutlines[i].From = from
            TrajectoryOutlines[i].To = to
            TrajectoryOutlines[i].Visible = true

            TrajectoryLines[i].From = from
            TrajectoryLines[i].To = to
            TrajectoryLines[i].Visible = true
        else
            TrajectoryOutlines[i].Visible = false
            TrajectoryLines[i].Visible = false
        end
    end

    for i = posCount, TrajectoryPointCount do
        TrajectoryOutlines[i].Visible = false
        TrajectoryLines[i].Visible = false
    end
end)

-- watermark
local frameTimer = tick()
local frameCounter = 0
local fps = 60
local GetPing = function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end
local canDoPing = pcall(function() return GetPing() end)

RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1

    if (tick() - frameTimer) >= 1 then
        fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
    end

    if canDoPing then
        Watermark.Title = ("uoro | %d fps | %d ms"):format(math.floor(fps), GetPing())
    else
        Watermark.Title = ("uoro | %d fps"):format(math.floor(fps))
    end
end)

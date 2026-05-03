-- please skidders stop looking at my code 😭😭
-- btw if someone is complaining i did this in fucking 10 hours and i should call this beta since im not done tbh

local executor = identifyexecutor()
if executor == "Xeno" or executor == "Solara" or executor == "JJsploit" then
    localplayer:Kick("use a better executor")
end

local repo = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/" -- prob worst ui library i could choose please dm me on discord for a better ui library @the_zylang

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

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
local storedOriginalSizes = {}

local SwordAimbotToggled = false
local BowAimbotToggled = false
local AutoPlaceToggled = false
local ShowMapToggled = false

local clicking = false
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

-- here if you want you can change trajectory color i should have put an option for it to be honest but im too lazy
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
-- same thing as before for this
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

local Window = Library:CreateWindow({
    Title = "uoro", -- who is putting those names
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    UnlockMouseWhileOpen = true,
    NotifySide = "Left",
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    ESP = Window:AddTab("ESP"),
    Aimbot = Window:AddTab("Aimbot"),
    Combat = Window:AddTab("Combat"),
    Movement = Window:AddTab("Movement"),
    Misc = Window:AddTab("Misc"),
    ["UI Settings"] = Window:AddTab("UI Settings"),
}

local espGroup = Tabs.ESP:AddLeftGroupbox("ESP Settings")
local espFeaturesGroup = Tabs.ESP:AddRightGroupbox("ESP Features")

espGroup:AddToggle("EspEnabled", {
    Text = "Enable ESP",
    Default = false,
    Tooltip = "toggles esp"
})

espFeaturesGroup:AddToggle("EspBoxEnabled", {
    Text = "Box ESP",
    Default = false,
    Tooltip = "shows a box around players"
})

espFeaturesGroup:AddToggle("EspNameEnabled", {
    Text = "Name ESP",
    Default = false,
    Tooltip = "shows player names above their box"
})

espFeaturesGroup:AddToggle("EspHealthBarEnabled", {
    Text = "Health Bar",
    Default = false,
    Tooltip = "shows health bar next to the box"
})

espFeaturesGroup:AddToggle("EspHealthTextEnabled", {
    Text = "Health Text",
    Default = false,
    Tooltip = "shows health numbers and a bar that goes from green to red based on health next to the box"
})

espFeaturesGroup:AddToggle("EspDistanceEnabled", {
    Text = "Distance",
    Default = false,
    Tooltip = "shows distance in studs below the box"
})

local swordGroup = Tabs.Aimbot:AddLeftGroupbox("Sword Aimbot")
local bowGroup = Tabs.Aimbot:AddRightGroupbox("Bow Aimbot")
local fovGroup = Tabs.Aimbot:AddLeftGroupbox("FOV Circle")

swordGroup:AddToggle("SwordAimbotEnabled", {
    Text = "Enable Sword Aimbot",
    Default = false,
    Tooltip = "aims at nearest enemy when having sword equipped"
})

swordGroup:AddDropdown("SwordAimbotMode", {
    Text = "Aimbot Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 2,
    Tooltip = "how the sword aimbot activates"
})

swordGroup:AddLabel("Sword Aimbot Key"):AddKeyPicker("SwordAimbotKey", {
    Default = "LeftAlt",
    Mode = "Hold",
    Text = "Sword Aimbot key",
    NoUI = false
})

swordGroup:AddToggle("SwordWallcheck", {
    Text = "Wall Check",
    Default = false,
    Tooltip = "only aims at players not behind walls"
})

swordGroup:AddToggle("SwordSmoothnessEnabled", {
    Text = "Smoothness",
    Default = false,
    Tooltip = "adds smoothness to the aimbot"
})

swordGroup:AddSlider("SwordSmoothness", {
    Text = "Smoothness Value",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Tooltip = "higher = smoother but slower"
})

swordGroup:AddSlider("SwordFOV", {
    Text = "FOV Radius",
    Default = 200,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Tooltip = "radius of the FOV circle for sword aimbot"
})

bowGroup:AddToggle("BowAimbotEnabled", {
    Text = "Enable Bow Aimbot",
    Default = false,
    Tooltip = "aims at nearest enemy when having bow equipped"
})

bowGroup:AddDropdown("BowAimbotMode", {
    Text = "Aimbot Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 3,
    Tooltip = "how the bow aimbot activates"
})

bowGroup:AddLabel("Bow Aimbot Key"):AddKeyPicker("BowAimbotKey", {
    Default = "MB2",
    Mode = "Hold",
    Text = "Bow Aimbot key",
    NoUI = false
})

bowGroup:AddToggle("BowWallcheck", {
    Text = "Wall Check",
    Default = false,
    Tooltip = "only aims at players not behind wall"
})

bowGroup:AddToggle("BowSmoothnessEnabled", {
    Text = "Smoothness",
    Default = false,
    Tooltip = "makes aimbot smoother"
})

bowGroup:AddSlider("BowSmoothness", {
    Text = "Smoothness Value",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Tooltip = "higher = smoother but slower"
})

bowGroup:AddSlider("BowFOV", {
    Text = "FOV Radius",
    Default = 200,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Tooltip = "radius of the FOV circle for bow aimbot"
})

fovGroup:AddToggle("ShowFOV", {
    Text = "Show FOV Circle",
    Default = false,
    Tooltip = "displays the FOV circle on screen"
})

local combatGroup = Tabs.Combat:AddLeftGroupbox("Hitbox Expander")
local autoClickGroup = Tabs.Combat:AddRightGroupbox("Auto Clicker")
local killAuraGroup = Tabs.Combat:AddLeftGroupbox("Kill Aura")

combatGroup:AddToggle("HitboxExpander", {
    Text = "Enable Hitbox Expander",
    Default = false,
    Tooltip = "expands enemy hitboxes (doesn't act as a infinite reach tho"
})

combatGroup:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Tooltip = "size of expanded hitboxes"
})

combatGroup:AddSlider("HitboxTransparency", {
    Text = "Hitbox Transparency",
    Default = 10,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Tooltip = "Transparency of expanded hitboxes (10 = invisible)"
})

autoClickGroup:AddToggle("AutoClicker", {
    Text = "Enable Auto Clicker",
    Default = false,
    Tooltip = "auto clicks for you ❤️"
})

autoClickGroup:AddLabel("Auto Clicker Key"):AddKeyPicker("AutoClickerKey", {
    Default = "Q",
    Mode = "Hold",
    Text = "Auto Clicker key",
    NoUI = false
})

autoClickGroup:AddSlider("MinCPS", {
    Text = "Min CPS",
    Default = 12,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Tooltip = "minimum clicks per second"
})

autoClickGroup:AddSlider("MaxCPS", {
    Text = "Max CPS",
    Default = 16,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Tooltip = "maximum clicks per second"
})

killAuraGroup:AddToggle("KillAura", {
    Text = "Enable Kill Aura",
    Default = false,
    Tooltip = "automatically attacks nearby players"
})

killAuraGroup:AddDropdown("KillAuraMode", {
    Text = "Kill Aura Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 2,
    Tooltip = "How kill aura activates"
})

killAuraGroup:AddLabel("Kill Aura Key"):AddKeyPicker("KillAuraKey", {
    Default = "K",
    Mode = "Toggle",
    Text = "Kill Aura key",
    NoUI = false
})

killAuraGroup:AddSlider("KillAuraRadius", {
    Text = "Radius",
    Default = 10,
    Min = 5,
    Max = 200,
    Rounding = 0,
    Tooltip = "distance in studs to detect targets"
})

killAuraGroup:AddSlider("KillAuraCooldown", {
    Text = "Attack Cooldown",
    Default = 1,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Tooltip = "cooldown between attacks (1 = 0.1s, 10 = 1s)"
})

-- movement stuff
local movementGroup = Tabs.Movement:AddLeftGroupbox("Movement")
local flyGroup = Tabs.Movement:AddRightGroupbox("Fly")

movementGroup:AddToggle("Speedhack", {
    Text = "Speed Hack",
    Default = false,
    Tooltip = "makes you faster"
})

movementGroup:AddSlider("SpeedhackValue", {
    Text = "Walk Speed",
    Default = 25,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Tooltip = "modified walkspeed value (be careful a high one might bug you out)"
})

movementGroup:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false,
    Tooltip = "you have no fall damage"
})

movementGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Tooltip = "walk through walls"
})

movementGroup:AddDropdown("NoclipMode", {
    Text = "Noclip Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 2,
    Tooltip = "how noclip activates"
})

movementGroup:AddLabel("Noclip Key"):AddKeyPicker("NoclipKey", {
    Default = "N",
    Mode = "Toggle",
    Text = "Noclip key",
    NoUI = false
})

flyGroup:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Tooltip = "lets you fly"
})

flyGroup:AddLabel("Fly Key"):AddKeyPicker("FlyKey", {
    Default = "V",
    Mode = "Toggle",
    Text = "Fly key",
    NoUI = false
})

flyGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 20,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Tooltip = "how fast you fly"
})

local miscGroup = Tabs.Misc:AddLeftGroupbox("Bow Utilities")
local autoPlaceGroup = Tabs.Misc:AddRightGroupbox("Auto Place")
local mapGroup = Tabs.Misc:AddLeftGroupbox("Map")

miscGroup:AddToggle("BowTrajectory", {
    Text = "Bow Trajectory",
    Default = false,
    Tooltip = "shows the predicted arrow path when charging bow"
})

miscGroup:AddToggle("AutoShoot", {
    Text = "Auto Shoot",
    Default = false,
    Tooltip = "automatically releases bow when trajectory hits a player (a bit broken)"
})

autoPlaceGroup:AddToggle("AutoPlace", {
    Text = "Auto Place",
    Default = false,
    Tooltip = "automatically places blocks while moving"
})

autoPlaceGroup:AddDropdown("AutoPlaceMode", {
    Text = "Auto Place Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 1,
    Tooltip = "how autoplace activates"
})

autoPlaceGroup:AddLabel("Auto Place Key"):AddKeyPicker("AutoPlaceKey", {
    Default = "P",
    Mode = "Hold",
    Text = "Auto Place key",
    NoUI = false
})

mapGroup:AddToggle("ShowMap", {
    Text = "Show Map",
    Default = false,
    Tooltip = "shows the in-game map"
})

mapGroup:AddDropdown("ShowMapMode", {
    Text = "Show Map Mode",
    Values = { "Always", "Toggle", "Hold" },
    Default = 2,
    Tooltip = "how show map activates"
})

mapGroup:AddLabel("Show Map Key"):AddKeyPicker("ShowMapKey", {
    Default = "M",
    Mode = "Toggle",
    Text = "Show Map key",
    NoUI = false
})

-- ui settings that i pasted basically from the example on linoria github page
local menuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

menuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end
})

menuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(value)
        Library.ShowCustomCursor = value
    end
})

menuGroup:AddDivider()

menuGroup:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})

menuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
    Tooltip = "Unloads the cheat"
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("uoro")
SaveManager:SetFolder("uoro/game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

-- main theme hope it doesn't brake
task.wait(0.02)
ThemeManager:ApplyTheme("BBot")

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
    local radius = Options.KillAuraRadius.Value
    
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
    if dist > Options.KillAuraRadius.Value then return false end
    
    local targetEntity = Entity.FindByCharacter(targetChar)
    if not targetEntity then return false end
    
    local isCrit = char.PrimaryPart.AssemblyLinearVelocity.Y < 0
    
    pcall(function()
        Blink.item_action.attack_entity.fire({
            target_entity_id = targetEntity.Id,
            is_crit = isCrit,
            weapon_name = weaponName,
            extra = { rizz = "Bro.", owo = "What's this? OwO ", those = workspace.Name == "Ok" } -- bridge duel devs, personallly, this is not tuff 😞
        })
    end)
    
    return true
end

-- fly functions
local function StopFly(char)
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function StartFly(char)
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
        if Toggles.NoFallDamage.Value then return end
        return OriginalFallDamageFire(damage)
    end)
end

-- speedhack hook
local OldIndex = nil
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() and key == "WalkSpeed" and Toggles.Speedhack.Value then
        local ok, result = pcall(function() return self:IsA("Humanoid") end)
        if ok and result then
            return Options.SpeedhackValue.Value
        end
    end
    return OldIndex(self, key)
end))

-- esp functions (best esp so far i made tbh)
local function HideAllESP(drawings)
    for _, drawing in pairs(drawings) do
        drawing.Visible = false
    end
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
    Drawings.Box.Color = Color3.fromRGB(255, 255, 255)
    Drawings.Box.Thickness = 1
    
    Drawings.BoxOutline.Filled = false
    Drawings.BoxOutline.Color = Color3.fromRGB(0, 0, 0)
    Drawings.BoxOutline.Thickness = 2.4
    
    Drawings.Name.Size = 13
    Drawings.Name.Font = Drawing.Fonts.System
    Drawings.Name.Center = true
    Drawings.Name.Outline = true
    Drawings.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    Drawings.Name.Color = Color3.fromRGB(255, 255, 255)
    
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
    Drawings.HealthText.Color = Color3.fromRGB(255, 255, 255)
    
    Drawings.Distance.Size = 13
    Drawings.Distance.Font = Drawing.Fonts.System
    Drawings.Distance.Center = true
    Drawings.Distance.Outline = true
    Drawings.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    Drawings.Distance.Color = Color3.fromRGB(255, 255, 255)

    RunService.RenderStepped:Connect(function()
        if not Toggles.EspEnabled.Value then
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
        -- if you are asking me what is this, don't ask me i always paste this shi from internet
        local scale = 1 / (screenPos.Z * math.tan(math.rad(camera.FieldOfView * 0.5)) * 2) * 1000
        local width = math.floor(4.5 * scale)
        local height = math.floor(6 * scale)
        local x = math.floor(screenPos.X)
        local y = math.floor(screenPos.Y)
        local xPos = math.floor(x - width * 0.5)
        local yPos = math.floor((y - height * 0.5) + (0.5 * scale))

        if Toggles.EspBoxEnabled.Value then
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

        if Toggles.EspNameEnabled.Value then
            Drawings.Name.Text = player.Name
            Drawings.Name.Position = Vector2.new(xPos + (width * 0.5), yPos - 15)
            Drawings.Name.Visible = true
        else
            Drawings.Name.Visible = false
        end

        if Toggles.EspHealthBarEnabled.Value then
            local healthPercent = math.clamp(playerHum.Health / playerHum.MaxHealth, 0, 1)
            local healthHeight = math.floor(height * healthPercent)
            
            Drawings.HealthBarOutline.Size = Vector2.new(3, height)
            Drawings.HealthBarOutline.Position = Vector2.new(xPos - 5, yPos)
            Drawings.HealthBarOutline.Visible = true
            
            Drawings.HealthBar.Size = Vector2.new(3, healthHeight)
            Drawings.HealthBar.Position = Vector2.new(xPos - 5, yPos + (height - healthHeight))
            
            if healthPercent > 0.5 then
                Drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.25 then
                Drawings.HealthBar.Color = Color3.fromRGB(255, 255, 0)
            else
                Drawings.HealthBar.Color = Color3.fromRGB(255, 0, 0)
            end
            Drawings.HealthBar.Visible = true
        else
            Drawings.HealthBarOutline.Visible = false
            Drawings.HealthBar.Visible = false
        end

        if Toggles.EspHealthTextEnabled.Value then
            Drawings.HealthText.Text = string.format("%d/%d", math.floor(playerHum.Health), math.floor(playerHum.MaxHealth))
            Drawings.HealthText.Position = Vector2.new(xPos - 40, yPos)
            Drawings.HealthText.Visible = true
        else
            Drawings.HealthText.Visible = false
        end

        if Toggles.EspDistanceEnabled.Value then
            local dist = math.floor((localHRP.Position - playerHRP.Position).Magnitude)
            Drawings.Distance.Text = string.format("%d studs", dist)
            Drawings.Distance.Position = Vector2.new(xPos + (width * 0.5), yPos + height + 2)
            Drawings.Distance.Visible = true
        else
            Drawings.Distance.Visible = false
        end
    end)
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

-- auto clicker thread
local AutoClickerThread = coroutine.create(function()
    while true do
        if Toggles.AutoClicker.Value and Options.AutoClickerKey:GetState() then
            local cps = math.random(Options.MinCPS.Value, Options.MaxCPS.Value)
            mouse1click()
            task.wait(1 / cps)
        else
            task.wait(0.01)
        end
    end
end)
coroutine.resume(AutoClickerThread)

-- checking functions
local function IsNoclipActive()
    if not Toggles.Noclip.Value then return false end
    
    local mode = Options.NoclipMode.Value
    if mode == "Always" then return true end
    if mode == "Toggle" then return Options.NoclipKey:GetState() end
    if mode == "Hold" then return Options.NoclipKey:GetState() end
    
    return false
end

local function IsAutoPlaceActive()
    if not Toggles.AutoPlace.Value then return false end
    
    local mode = Options.AutoPlaceMode.Value
    if mode == "Always" then return true end
    if mode == "Toggle" then return AutoPlaceToggled end
    if mode == "Hold" then return Options.AutoPlaceKey:GetState() end
    
    return false
end

local function IsKillAuraActive()
    if not Toggles.KillAura.Value then return false end
    
    local mode = Options.KillAuraMode.Value
    if mode == "Always" then return true end
    if mode == "Toggle" then return Options.KillAuraKey:GetState() end
    if mode == "Hold" then return Options.KillAuraKey:GetState() end
    
    return false
end

local function IsShowMapActive()
    if not Toggles.ShowMap.Value then return false end
    
    local mode = Options.ShowMapMode.Value
    if mode == "Always" then return true end
    if mode == "Toggle" then return ShowMapToggled end
    if mode == "Hold" then return Options.ShowMapKey:GetState() end
    
    return false
end

-- changed callbacks
Options.NoclipMode:OnChanged(function()
    if Options.NoclipMode.Value == "Toggle" then
        Options.NoclipKey.Mode = "Toggle"
    elseif Options.NoclipMode.Value == "Hold" then
        Options.NoclipKey.Mode = "Hold"
    end
end)

Options.AutoPlaceMode:OnChanged(function()
    AutoPlaceToggled = false
end)

Options.AutoPlaceKey:OnClick(function()
    if Options.AutoPlaceMode.Value == "Toggle" then
        AutoPlaceToggled = not AutoPlaceToggled
    end
end)

Options.ShowMapMode:OnChanged(function()
    ShowMapToggled = false
    
    local mode = Options.ShowMapMode.Value
    if mode == "Hold" then
        Options.ShowMapKey:SetValue({ Options.ShowMapKey.Value, "Hold" })
    elseif mode == "Toggle" then
        Options.ShowMapKey:SetValue({ Options.ShowMapKey.Value, "Toggle" })
    elseif mode == "Always" then
        Options.ShowMapKey:SetValue({ Options.ShowMapKey.Value, "Toggle" })
        ShowMapToggled = false
    end
end)

Options.ShowMapKey:OnClick(function()
    if Options.ShowMapMode.Value == "Toggle" then
        ShowMapToggled = not ShowMapToggled
    end
end)

-- show map loop
RunService.RenderStepped:Connect(function()
    local mapActive = IsShowMapActive()
    local mainGui = localplayer.PlayerGui:FindFirstChild("MainGui")
    if mainGui then
        local map = mainGui:FindFirstChild("Map") or mainGui:FindFirstChild("Minimap") or mainGui:FindFirstChild("MapFrame")
        if map then
            map.Visible = mapActive
        end
    end
end)

-- noclip loop
RunService.Stepped:Connect(function()
    if not IsNoclipActive() then return end
    
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

    if Toggles.Fly.Value then
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
            
            flyBodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.zero
            
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

Toggles.Fly:OnChanged(function()
    local char = localplayer.Character
    if not char then return end
    
    if Toggles.Fly.Value then
        StartFly(char)
    else
        StopFly(char)
    end
end)

Options.FlyKey:OnClick(function()
    Toggles.Fly:SetValue(not Toggles.Fly.Value)
end)

-- auto place and kill aura loop
RunService.Heartbeat:Connect(function()
    -- auto place logic
    if IsAutoPlaceActive() then
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
    if IsKillAuraActive() and not killAuraCooldownActive then
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
                        task.wait(Options.KillAuraCooldown.Value / 10)
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
    if Toggles.HitboxExpander.Value then
        local hitboxSize = Options.HitboxSize.Value
        local hitboxTransparency = Options.HitboxTransparency.Value / 10
        
        for _, player in pairs(PlayerService:GetPlayers()) do
            if player == localplayer then continue end
            
            local playerChar = player.Character
            if not playerChar then continue end
            
            local targetHRP = playerChar:FindFirstChild("HumanoidRootPart")
            if not targetHRP then continue end
            
            if not storedHitboxes[player] then
                storedOriginalSizes[player] = targetHRP.Size
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
            storedOriginalSizes[player] = nil
        end
    end

    local doSwordAimbot = false
    local doBowAimbot = false

    -- check sword aimbot
    if Toggles.SwordAimbotEnabled.Value and isSword then
        local mode = Options.SwordAimbotMode.Value
        if mode == "Always" then
            doSwordAimbot = true
        elseif mode == "Toggle" then
            doSwordAimbot = SwordAimbotToggled
        elseif mode == "Hold" then
            doSwordAimbot = Options.SwordAimbotKey:GetState()
        end
    end

    -- check bow aimbot
    if Toggles.BowAimbotEnabled.Value and isBow then
        local mode = Options.BowAimbotMode.Value
        if mode == "Always" then
            doBowAimbot = true
        elseif mode == "Toggle" then
            doBowAimbot = BowAimbotToggled
        elseif mode == "Hold" then
            doBowAimbot = Options.BowAimbotKey:GetState()
        end
    end

    local aimTarget = nil
    local currentFov = Options.SwordFOV.Value

    if doSwordAimbot then
        currentFov = Options.SwordFOV.Value
        aimTarget = GetClosestPlayer(Options.SwordFOV.Value, Toggles.SwordWallcheck.Value)
    elseif doBowAimbot then
        currentFov = Options.BowFOV.Value
        aimTarget = GetClosestPlayer(Options.BowFOV.Value, Toggles.BowWallcheck.Value)
    end

    -- apply aimbot
    if aimTarget and aimTarget.Character then
        local targetHRP = aimTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local targetScreen, onScreen = camera:WorldToViewportPoint(targetHRP.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local smooth = 1
                
                if doSwordAimbot and Toggles.SwordSmoothnessEnabled.Value then
                    smooth = math.clamp(Options.SwordSmoothness.Value / 10, 0.01, 1)
                elseif doBowAimbot and Toggles.BowSmoothnessEnabled.Value then
                    smooth = math.clamp(Options.BowSmoothness.Value / 10, 0.01, 1)
                end
                
                local deltaX = (targetScreen.X - mousePos.X) * smooth
                local deltaY = (targetScreen.Y - mousePos.Y) * smooth
                mousemoverel(deltaX, deltaY)
            end
        end
    end

    -- fov circle
    if Toggles.ShowFOV.Value then
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
    if Toggles.Speedhack.Value and humanoid then
        humanoid.WalkSpeed = Options.SpeedhackValue.Value
    end
end)

-- aimbot key callbacks
Options.SwordAimbotKey:OnClick(function()
    local mode = Options.SwordAimbotMode.Value
    if mode == "Toggle" then
        SwordAimbotToggled = not SwordAimbotToggled
    end
end)

Options.SwordAimbotMode:OnChanged(function()
    SwordAimbotToggled = false
    
    local mode = Options.SwordAimbotMode.Value
    if mode == "Hold" then
        Options.SwordAimbotKey:SetValue({ Options.SwordAimbotKey.Value, "Hold" })
    elseif mode == "Toggle" then
        Options.SwordAimbotKey:SetValue({ Options.SwordAimbotKey.Value, "Toggle" })
    elseif mode == "Always" then
        Options.SwordAimbotKey:SetValue({ Options.SwordAimbotKey.Value, "Toggle" })
        SwordAimbotToggled = false
    end
end)

Options.BowAimbotKey:OnClick(function()
    local mode = Options.BowAimbotMode.Value
    if mode == "Toggle" then
        BowAimbotToggled = not BowAimbotToggled
    end
end)

Options.BowAimbotMode:OnChanged(function()
    BowAimbotToggled = false
    
    local mode = Options.BowAimbotMode.Value
    if mode == "Hold" then
        Options.BowAimbotKey:SetValue({ Options.BowAimbotKey.Value, "Hold" })
    elseif mode == "Toggle" then
        Options.BowAimbotKey:SetValue({ Options.BowAimbotKey.Value, "Toggle" })
    elseif mode == "Always" then
        Options.BowAimbotKey:SetValue({ Options.BowAimbotKey.Value, "Toggle" })
        BowAimbotToggled = false
    end
end)

-- bow trajectory that i def not asked gemini for the math
local sharedRayParams = RaycastParams.new()
sharedRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function ClearTrajectory()
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
    
    if Toggles.BowTrajectory.Value and HasBowEquipped and not IsAutoShooting then
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
    if not Toggles.BowTrajectory.Value or not HasBowEquipped or not IsHoldingBow then
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
    if Toggles.AutoShoot.Value and hitPlayer and IsHoldingBow and elapsed >= 0.7 then
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

Library:SetWatermarkVisibility(true)

local watermarkConnection = RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1
    
    if (tick() - frameTimer) >= 1 then
        fps = frameCounter
        frameTimer = tick()
        frameCounter = 0
    end
    
    if canDoPing then
        Library:SetWatermark(("uoro | %d fps | %d ms"):format(math.floor(fps), GetPing()))
    else
        Library:SetWatermark(("uoro | %d fps"):format(math.floor(fps)))
    end
end)

-- unload handler
Library:OnUnload(function()
    watermarkConnection:Disconnect()
    ClearTrajectory()
    FOVOutline:Remove()
    FOVCircle:Remove()
    StopFly(localplayer.Character)
    Library.Unloaded = true
end)

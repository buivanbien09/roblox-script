local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "28th6",
    SubTitle = "Author Bien",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Player",     Icon = ""      }),
    ESP      = Window:AddTab({ Title = "ESP",      Icon = ""      }),
    Combat   = Window:AddTab({ Title = "Combat",   Icon = ""   }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = ""   }),
    Misc     = Window:AddTab({ Title = "Misc",     Icon = ""    }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "" })
}

local Options = Fluent.Options

-- ================================================================
--  SERVICES
-- ================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ================================================================
--  HELPERS
-- ================================================================
local function getCharacter()  return LocalPlayer.Character end
local function getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRootPart()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getPlayerCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char and char:IsDescendantOf(workspace) then
        return char
    end
    -- Fallback: Search workspace manually in case player.Character is unset but model exists
    local fallback = workspace:FindFirstChild(player.Name)
    if fallback and fallback:IsA("Model") and fallback:FindFirstChildOfClass("Humanoid") then
        return fallback
    end
    return nil
end

-- ================================================================
--  MAIN TAB – Speed Boost, NoClip, Fly
-- ================================================================
do
    local noclipConn      = nil
    local flyConn         = nil
    local flyLV, flyAO, flyAttach = nil, nil, nil
    local currentMode  = "WalkSpeed"
    local currentSpeed = 50

    -- ────── Speed Boost ──────────────────────────────────────────

    Tabs.Main:AddDropdown("SpeedMode", {
        Title = "Select Mode",
        Values = { "WalkSpeed", "Velocity", "CFrame" }, Multi = false, Default = "WalkSpeed",
    }):OnChanged(function(Value) currentMode = Value end)

    Tabs.Main:AddSlider("SpeedValue", {
        Title = "Speed", Default = 50, Min = 0, Max = 500, Rounding = 0,
        Callback = function(Value) currentSpeed = Value end
    })

    RunService.Heartbeat:Connect(function()
        if not Options.SpeedBoostToggle or not Options.SpeedBoostToggle.Value then return end
        local root = getRootPart()
        local hum = getHumanoid()
        if not root or not hum then return end
        
        if currentMode == "WalkSpeed" then
            hum.WalkSpeed = currentSpeed
        elseif currentMode == "Velocity" then
            if hum.MoveDirection.Magnitude > 0 then
                local v = hum.MoveDirection * currentSpeed
                root.AssemblyLinearVelocity = Vector3.new(v.X, root.AssemblyLinearVelocity.Y, v.Z)
            end
        elseif currentMode == "CFrame" then
            if hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (currentSpeed * 0.01))
            end
        end
    end)

    Tabs.Main:AddToggle("SpeedBoostToggle", {
        Title = "Speed Boost", Default = false
    }):OnChanged(function()
        local enabled = Options.SpeedBoostToggle.Value
        if enabled then
            Fluent:Notify({ Title = "Speed Boost", Content = "Enabled: " .. currentMode, Duration = 3 })
        else
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
            Fluent:Notify({ Title = "Speed Boost", Content = "Disabled.", Duration = 3 })
        end
    end)

    -- ────── NoClip ───────────────────────────────────────────────

    local PhysicsService = game:GetService("PhysicsService")
    local NC_GROUP = "NoClipGroup"; local NC_DEFAULT = "Default"; local ncGroupCreated = false

    Tabs.Main:AddToggle("NoClipToggle", {
        Title = "No Clip", Default = false
    }):OnChanged(function()
        if Options.NoClipToggle.Value then
            if noclipConn then noclipConn:Disconnect() end
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end)
            Fluent:Notify({ Title = "No Clip", Content = "Enabled! (Stealth)", Duration = 3 })
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        if p.Name == "HumanoidRootPart" or p.Name == "Head" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso" then
                            p.CanCollide = true
                        end
                    end
                end
            end
            Fluent:Notify({ Title = "No Clip", Content = "Disabled.", Duration = 3 })
        end
    end)

    Tabs.Main:AddKeybind("NoClipKeybind", {
        Title = "No Clip Hotkey",
        Default = "N",
        Callback = function()
            if Options.NoClipToggle then
                Options.NoClipToggle:SetValue(not Options.NoClipToggle.Value)
            end
        end
    })

    -- ────── Fly ──────────────────────────────────────────────────

    Tabs.Main:AddSlider("FlySpeed", { Title = "Fly Speed", Default = 50, Min = 5, Max = 300, Rounding = 0, Callback = function(_) end })

    Tabs.Main:AddToggle("FlyToggle", { Title = "Fly", Default = false }):OnChanged(function()
        if Options.FlyToggle.Value then
            if flyConn then flyConn:Disconnect() end
            flyConn = RunService.RenderStepped:Connect(function(deltaTime)
                Camera = workspace.CurrentCamera or Camera
                local root = getRootPart()
                local hum = getHumanoid()
                if not root or not hum then return end
                
                -- Stealth Fly: Nullify gravity and set position directly via CFrame. No instances created.
                root.AssemblyLinearVelocity = Vector3.zero
                hum:ChangeState(Enum.HumanoidStateType.Physics) -- Optional state to prevent weird leg animations

                local dir = Vector3.zero
                local cf = Camera.CFrame
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

                if dir.Magnitude > 0 then
                    root.CFrame = CFrame.new(root.Position + (dir.Unit * Options.FlySpeed.Value * deltaTime), root.Position + (dir.Unit * Options.FlySpeed.Value * deltaTime) + cf.LookVector)
                else
                    root.CFrame = CFrame.new(root.Position, root.Position + cf.LookVector)
                end
            end)
            Fluent:Notify({ Title = "Fly", Content = "Enabled! (Stealth CFrame)", Duration = 3 })
        else
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            local hum = getHumanoid()
            if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            Fluent:Notify({ Title = "Fly", Content = "Disabled.", Duration = 3 })
        end
    end)

    Tabs.Main:AddKeybind("FlyKeybind", {
        Title = "Fly Hotkey",
        Default = "F",
        Callback = function()
            if Options.FlyToggle then
                Options.FlyToggle:SetValue(not Options.FlyToggle.Value)
            end
        end
    })

    -- ────── Spinbot ──────────────────────────────────────────────
    local spinbotEnabled = false
    local spinbotSpeed = 50

    Tabs.Main:AddToggle("SpinbotEnabled", {
        Title = "Enable Spinbot", Default = false
    }):OnChanged(function()
        spinbotEnabled = Options.SpinbotEnabled.Value
        if not spinbotEnabled then
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myHum then myHum.AutoRotate = true end
        end
    end)

    Tabs.Main:AddSlider("SpinbotSpeed", {
        Title = "Spin Speed", Default = 50, Min = 1, Max = 100, Rounding = 0
    }):OnChanged(function() 
        spinbotSpeed = Options.SpinbotSpeed.Value 
    end)

    RunService.RenderStepped:Connect(function(deltaTime)
        if spinbotEnabled then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myRoot and myHum and myHum.Health > 0 then
                myHum.AutoRotate = false
                myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed * deltaTime * 60), 0)
            end
        end
    end)

    -- ────── Float ────────────────────────────────────────────────
    local floatEnabled = false
    local floatConn = nil

    Tabs.Main:AddToggle("FloatToggle", {
        Title = "Float", Default = false
    }):OnChanged(function()
        floatEnabled = Options.FloatToggle.Value
        if floatEnabled then
            if not floatConn then
                floatConn = RunService.Heartbeat:Connect(function()
                    local root = getRootPart()
                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
                    end
                end)
            end
        else
            if floatConn then floatConn:Disconnect(); floatConn = nil end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        Options.FlyToggle:SetValue(false)
        Options.NoClipToggle:SetValue(false)
        Options.FloatToggle:SetValue(false)
    end)
end

-- ================================================================
--  ESP TAB
-- ================================================================
do
    local S = {
        Enabled   = true,
        Boxes     = true,
        Names     = true,
        Distance  = true,
        Health    = true,
        Tracers   = true,
        Chams     = true,
        Skeleton  = false,
        Weapon    = false,
        TeamCheck = false,
        TeamCheckMode = "Auto Detect",
        EnemyColor = Color3.fromRGB(255, 50, 50),
        MaxDist   = 1000,
    }

    local ESP_Cache  = {}
    local TeamCheckState = {
        detectedTeamCheckMode = nil,
        lastDetectedTeamCheckMode = nil,
        lastTeamCheckScanTime = 0,
        teamCheckScanInterval = 5,
        lastESPScanTime = 0,
    }

    -- ── Helper: get team value from player ───────────────────────
    local function getTeamValue(plr)
        local ls = plr:FindFirstChild("leaderstats")
        if ls then
            for _, v in ipairs(ls:GetChildren()) do
                local n = string.lower(v.Name)
                if n == "team" or n == "side" or n == "faction" or n == "class" then
                    if v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue") then
                        return v.Value
                    end
                end
            end
        end
        for _, name in ipairs({"Side", "Faction", "Class", "Team", "Squad"}) do
            local v = plr:FindFirstChild(name)
            if v and (v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("ObjectValue")) then
                return v.Value
            end
        end
        local char = plr.Character
        if char then
            for _, name in ipairs({"Side", "Faction", "Class", "Team"}) do
                local v = char:FindFirstChild(name)
                if v and (v:IsA("StringValue") or v:IsA("IntValue")) then
                    return v.Value
                end
            end
        end
        return nil
    end

    local function getAvailableTeamCheckMode()
        local myChar = LocalPlayer.Character
        if not myChar then return nil end

        local otherPlayers = Players:GetPlayers()
        local enemies = {}
        for _, p in ipairs(otherPlayers) do
            if p ~= LocalPlayer and p.Character then
                table.insert(enemies, p)
            end
        end
        if #enemies == 0 then return nil end

        local methods = {
            {
                name = "Roblox Teams",
                priority = 100,
                check = function(p) return LocalPlayer.Team ~= nil and p.Team ~= nil end,
                same = function(p) return LocalPlayer.Team == p.Team end
            },
            {
                name = "TeamColor",
                priority = 90,
                check = function(p) return LocalPlayer.TeamColor ~= nil and p.TeamColor ~= nil end,
                same = function(p) return LocalPlayer.TeamColor == p.TeamColor end
            },
            {
                name = "FactionType Attribute",
                priority = 85,
                check = function(p)
                    local a = myChar:GetAttribute("FactionType")
                    local b = p.Character and p.Character:GetAttribute("FactionType")
                    return a ~= nil and b ~= nil
                end,
                same = function(p)
                    local a = myChar:GetAttribute("FactionType")
                    local b = p.Character and p.Character:GetAttribute("FactionType")
                    return a == b
                end
            },
            {
                name = "Team Attribute",
                priority = 80,
                check = function(p)
                    local a = myChar:GetAttribute("Team") or LocalPlayer:GetAttribute("Team")
                    local b = p.Character and (p.Character:GetAttribute("Team") or p:GetAttribute("Team"))
                    return a ~= nil and b ~= nil
                end,
                same = function(p)
                    local a = myChar:GetAttribute("Team") or LocalPlayer:GetAttribute("Team")
                    local b = p.Character and (p.Character:GetAttribute("Team") or p:GetAttribute("Team"))
                    return a == b
                end
            },
            {
                name = "Role Attribute",
                priority = 75,
                check = function(p)
                    local a = myChar:GetAttribute("Role") or LocalPlayer:GetAttribute("Role")
                    local b = p.Character and (p.Character:GetAttribute("Role") or p:GetAttribute("Role"))
                    return a ~= nil and b ~= nil
                end,
                same = function(p)
                    local a = myChar:GetAttribute("Role") or LocalPlayer:GetAttribute("Role")
                    local b = p.Character and (p.Character:GetAttribute("Role") or p:GetAttribute("Role"))
                    return a == b
                end
            },
            {
                name = "Crew / Guild Tag",
                priority = 70,
                check = function(p)
                    local a = LocalPlayer:GetAttribute("Crew") or LocalPlayer:GetAttribute("Guild")
                    local b = p:GetAttribute("Crew") or p:GetAttribute("Guild")
                    return a ~= nil and b ~= nil
                end,
                same = function(p)
                    local a = LocalPlayer:GetAttribute("Crew") or LocalPlayer:GetAttribute("Guild")
                    local b = p:GetAttribute("Crew") or p:GetAttribute("Guild")
                    return a == b
                end
            },
            {
                name = "IntValue (Team)",
                priority = 60,
                check = function(p)
                    local va = myChar:FindFirstChild("Team") or LocalPlayer:FindFirstChild("Team")
                    local vb = p.Character and (p.Character:FindFirstChild("Team") or p:FindFirstChild("Team"))
                    return va and va:IsA("IntValue") and vb and vb:IsA("IntValue")
                end,
                same = function(p)
                    local va = myChar:FindFirstChild("Team") or LocalPlayer:FindFirstChild("Team")
                    local vb = p.Character and (p.Character:FindFirstChild("Team") or p:FindFirstChild("Team"))
                    if va and vb then return va.Value == vb.Value end
                    return false
                end
            },
            {
                name = "StringValue (Team)",
                priority = 60,
                check = function(p)
                    local va = myChar:FindFirstChild("Team") or LocalPlayer:FindFirstChild("Team")
                    local vb = p.Character and (p.Character:FindFirstChild("Team") or p:FindFirstChild("Team"))
                    return va and va:IsA("StringValue") and vb and vb:IsA("StringValue") and va.Value ~= ""
                end,
                same = function(p)
                    local va = myChar:FindFirstChild("Team") or LocalPlayer:FindFirstChild("Team")
                    local vb = p.Character and (p.Character:FindFirstChild("Team") or p:FindFirstChild("Team"))
                    if va and vb then return va.Value == vb.Value end
                    return false
                end
            },
            {
                name = "Shirt Template",
                priority = 30,
                check = function(p)
                    local a = myChar:FindFirstChildOfClass("Shirt")
                    local b = p.Character and p.Character:FindFirstChildOfClass("Shirt")
                    return a and b and a.ShirtTemplate ~= "" and b.ShirtTemplate ~= ""
                end,
                same = function(p)
                    local a = myChar:FindFirstChildOfClass("Shirt")
                    local b = p.Character and p.Character:FindFirstChildOfClass("Shirt")
                    if a and b then return a.ShirtTemplate == b.ShirtTemplate end
                    return false
                end
            },
            {
                name = "Leaderstats / Side",
                priority = 65,
                check = function(p)
                    return getTeamValue(LocalPlayer) ~= nil and getTeamValue(p) ~= nil
                end,
                same = function(p)
                    return getTeamValue(LocalPlayer) == getTeamValue(p)
                end
            },
        }

        local bestMethod = nil
        local bestScore  = -1
        for _, m in ipairs(methods) do
            local validCount   = 0
            local sameCount    = 0
            local diffCount    = 0
            for _, p in ipairs(enemies) do
                if p.Character then
                    pcall(function()
                        if m.check(p) then
                            validCount = validCount + 1
                            if m.same(p) then
                                sameCount = sameCount + 1
                            else
                                diffCount = diffCount + 1
                            end
                        end
                    end)
                end
            end

            if validCount > 0 then
                local discriminationBonus = 0
                if sameCount > 0 and diffCount > 0 then
                    discriminationBonus = 50
                elseif diffCount > 0 then
                    discriminationBonus = 20
                end
                local score = m.priority + discriminationBonus
                if score > bestScore then
                    bestScore  = score
                    bestMethod = m.name
                end
            end
        end
        return bestMethod
    end

    local function isSameTeam(player)
        if not S.TeamCheck then return false end

        local myChar = LocalPlayer.Character
        local theirChar = player.Character
        if not myChar or not theirChar then return false end

        local mode = S.TeamCheckMode
        if mode == "Auto Detect" then
            local now = tick()
            if now - TeamCheckState.lastTeamCheckScanTime > TeamCheckState.teamCheckScanInterval then
                TeamCheckState.lastTeamCheckScanTime = now
                local detected = getAvailableTeamCheckMode()
                if detected ~= TeamCheckState.detectedTeamCheckMode then
                    TeamCheckState.detectedTeamCheckMode = detected
                    if detected then
                        Fluent:Notify({ Title = "Team Check", Content = "Auto detect: " .. detected, Duration = 4 })
                    else
                        Fluent:Notify({ Title = "Team Check", Content = "Auto detect: Cannot find suitable method", Duration = 4 })
                    end
                end
                TeamCheckState.lastDetectedTeamCheckMode = TeamCheckState.detectedTeamCheckMode
            end
            mode = TeamCheckState.detectedTeamCheckMode or "Auto (Try All)"
        else
            TeamCheckState.detectedTeamCheckMode = nil
            TeamCheckState.lastDetectedTeamCheckMode = nil
            TeamCheckState.lastTeamCheckScanTime = 0
        end

        local function checkRobloxTeam()
            if LocalPlayer.Team and player.Team then
                if LocalPlayer.Team == player.Team then return true end
                if LocalPlayer.Team.Name == player.Team.Name then return true end
            end
            return false
        end

        local function checkFactionType()
            local a = myChar:GetAttribute("FactionType")
            local b = theirChar:GetAttribute("FactionType")
            if a ~= nil and b ~= nil then return a == b end
            return false
        end

        local function checkTeamAttribute()
            local a = myChar:GetAttribute("Team") or LocalPlayer:GetAttribute("Team")
            local b = theirChar:GetAttribute("Team") or player:GetAttribute("Team")
            if a ~= nil and b ~= nil then return a == b end
            return false
        end

        local function checkIntValue()
            local function getInt(char, plr)
                local v = char:FindFirstChild("Team") or plr:FindFirstChild("Team")
                if v and v:IsA("IntValue") then return v.Value end
                return nil
            end
            local a = getInt(myChar, LocalPlayer)
            local b = getInt(theirChar, player)
            if a ~= nil and b ~= nil then return a == b end
            return false
        end

        local function checkStringValue()
            local function getStr(char, plr)
                local v = char:FindFirstChild("Team") or plr:FindFirstChild("Team")
                if v and v:IsA("StringValue") then return v.Value end
                return nil
            end
            local a = getStr(myChar, LocalPlayer)
            local b = getStr(theirChar, player)
            if a ~= nil and b ~= nil and a ~= "" then return a == b end
            return false
        end

        local function checkTeamColor()
            if LocalPlayer.TeamColor and player.TeamColor then
                return LocalPlayer.TeamColor == player.TeamColor
            end
            return false
        end
        
        local function checkRoleAttribute()
            local a = myChar:GetAttribute("Role") or LocalPlayer:GetAttribute("Role")
            local b = theirChar:GetAttribute("Role") or player:GetAttribute("Role")
            if a ~= nil and b ~= nil then return a == b end
            return false
        end
        
        local function checkCrewTag()
            local a = LocalPlayer:GetAttribute("Crew") or LocalPlayer:GetAttribute("Guild")
            local b = player:GetAttribute("Crew") or player:GetAttribute("Guild")
            if a ~= nil and b ~= nil then return a == b end
            return false
        end
        
        local function checkDisplayNameColor()
            local a = myChar:FindFirstChild("Head") and myChar.Head:FindFirstChildOfClass("BillboardGui")
            local b = theirChar:FindFirstChild("Head") and theirChar.Head:FindFirstChildOfClass("BillboardGui")
            if a and b then
                local tL_A = a:FindFirstChildOfClass("TextLabel", true)
                local tL_B = b:FindFirstChildOfClass("TextLabel", true)
                if tL_A and tL_B then
                    return tL_A.TextColor3 == tL_B.TextColor3
                end
            end
            return false
        end
        
        local function checkShirtTemplate()
            local a = myChar:FindFirstChildOfClass("Shirt")
            local b = theirChar:FindFirstChildOfClass("Shirt")
            if a and b and a.ShirtTemplate ~= "" and b.ShirtTemplate ~= "" then
                return a.ShirtTemplate == b.ShirtTemplate
            end
            return false
        end

        local function checkLeaderstats()
            local a = getTeamValue(LocalPlayer)
            local b = getTeamValue(player)
            if a ~= nil and b ~= nil then return a == b end
            return false
        end

        if mode == "Roblox Teams" then return checkRobloxTeam()
        elseif mode == "FactionType Attribute" then return checkFactionType()
        elseif mode == "Team Attribute" then return checkTeamAttribute()
        elseif mode == "IntValue (Team)" then return checkIntValue()
        elseif mode == "StringValue (Team)" then return checkStringValue()
        elseif mode == "TeamColor" then return checkTeamColor()
        elseif mode == "Role Attribute" then return checkRoleAttribute()
        elseif mode == "Crew / Guild Tag" then return checkCrewTag()
        elseif mode == "Display Name Color" then return checkDisplayNameColor()
        elseif mode == "Shirt Template" then return checkShirtTemplate()
        elseif mode == "Leaderstats / Side" then return checkLeaderstats()
        elseif mode == "Auto (Try All)" then
            if checkRobloxTeam() then return true end
            if checkFactionType() then return true end
            if checkTeamAttribute() then return true end
            if checkLeaderstats() then return true end
            if checkIntValue() then return true end
            if checkStringValue() then return true end
            if checkTeamColor() then return true end
            if checkRoleAttribute() then return true end
            if checkCrewTag() then return true end
            if checkShirtTemplate() then return true end
        end
        return false
    end

    local function createSkeletonLine()
        local line = Drawing.new("Line")
        line.Color = S.EnemyColor
        line.Thickness = 1.5
        line.Visible = false
        line.ZIndex = 2
        return line
    end

    local function getSkeletonPoint(char, partName)
        local part = char and char:FindFirstChild(partName)
        if not part or not part:IsA("BasePart") then return nil end
        local position, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then return nil end
        return Vector2.new(position.X, position.Y)
    end

    local function setSkeletonLine(line, fromPoint, toPoint)
        if line and fromPoint and toPoint then
            line.From = fromPoint; line.To = toPoint; line.Visible = true
        elseif line then
            line.Visible = false
        end
    end

    local function hideSkeletonLines(skeletonLines)
        if not skeletonLines then return end
        for _, line in pairs(skeletonLines) do
            if line then line.Visible = false end
        end
    end

    local function getCharacterWeaponName(char)
        if not char then return nil end
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and tool.Name and tool.Name ~= "" then return tool.Name end
        return nil
    end

    local function updateSkeletonESP(char, esp)
        if not esp or not esp.SkeletonLines then return end
        if not S.Skeleton then
            hideSkeletonLines(esp.SkeletonLines)
            return
        end

        local myRoot = getRootPart()
        local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot and targetRoot then
            local distance = (myRoot.Position - targetRoot.Position).Magnitude
            if distance > 250 then
                hideSkeletonLines(esp.SkeletonLines)
                return
            end
        end

        local head = getSkeletonPoint(char, "Head")
        local upperTorso = getSkeletonPoint(char, "UpperTorso") or getSkeletonPoint(char, "Torso")
        local lowerTorso = getSkeletonPoint(char, "LowerTorso") or upperTorso
        local leftUpperArm = getSkeletonPoint(char, "LeftUpperArm") or getSkeletonPoint(char, "Left Arm")
        local leftLowerArm = getSkeletonPoint(char, "LeftLowerArm")
        local leftHand = getSkeletonPoint(char, "LeftHand")
        local rightUpperArm = getSkeletonPoint(char, "RightUpperArm") or getSkeletonPoint(char, "Right Arm")
        local rightLowerArm = getSkeletonPoint(char, "RightLowerArm")
        local rightHand = getSkeletonPoint(char, "RightHand")
        local leftUpperLeg = getSkeletonPoint(char, "LeftUpperLeg") or getSkeletonPoint(char, "Left Leg")
        local leftLowerLeg = getSkeletonPoint(char, "LeftLowerLeg")
        local leftFoot = getSkeletonPoint(char, "LeftFoot")
        local rightUpperLeg = getSkeletonPoint(char, "RightUpperLeg") or getSkeletonPoint(char, "Right Leg")
        local rightLowerLeg = getSkeletonPoint(char, "RightLowerLeg")
        local rightFoot = getSkeletonPoint(char, "RightFoot")

        if not head or not upperTorso then
            hideSkeletonLines(esp.SkeletonLines)
            return
        end

        local neckPoint = Vector2.new((head.X + upperTorso.X) / 2, (head.Y + upperTorso.Y) / 2)

        setSkeletonLine(esp.SkeletonLines.HeadToTorso, head, neckPoint)
        setSkeletonLine(esp.SkeletonLines.UpperToLowerTorso, upperTorso, lowerTorso)
        setSkeletonLine(esp.SkeletonLines.LeftUpperArm, upperTorso, leftUpperArm)
        setSkeletonLine(esp.SkeletonLines.LeftLowerArm, leftUpperArm, leftLowerArm or leftHand)
        setSkeletonLine(esp.SkeletonLines.LeftHand, leftLowerArm, leftHand)
        setSkeletonLine(esp.SkeletonLines.RightUpperArm, upperTorso, rightUpperArm)
        setSkeletonLine(esp.SkeletonLines.RightLowerArm, rightUpperArm, rightLowerArm or rightHand)
        setSkeletonLine(esp.SkeletonLines.RightHand, rightLowerArm, rightHand)
        setSkeletonLine(esp.SkeletonLines.LeftUpperLeg, lowerTorso, leftUpperLeg)
        setSkeletonLine(esp.SkeletonLines.LeftLowerLeg, leftUpperLeg, leftLowerLeg or leftFoot)
        setSkeletonLine(esp.SkeletonLines.LeftFoot, leftLowerLeg, leftFoot)
        setSkeletonLine(esp.SkeletonLines.RightUpperLeg, lowerTorso, rightUpperLeg)
        setSkeletonLine(esp.SkeletonLines.RightLowerLeg, rightUpperLeg, rightLowerLeg or rightFoot)
        setSkeletonLine(esp.SkeletonLines.RightFoot, rightLowerLeg, rightFoot)
    end

    local function CreateESP(char)
        local esp = {
            Box = Drawing.new("Square"),
            BoxOutline = Drawing.new("Square"),
            HealthBar = Drawing.new("Square"),
            HealthBarOutline = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
            Weapon = Drawing.new("Text"),
            Tracer = Drawing.new("Line"),
            Highlight = nil,
            SkeletonLines = {
                HeadToTorso = createSkeletonLine(), UpperToLowerTorso = createSkeletonLine(),
                LeftUpperArm = createSkeletonLine(), LeftLowerArm = createSkeletonLine(), LeftHand = createSkeletonLine(),
                RightUpperArm = createSkeletonLine(), RightLowerArm = createSkeletonLine(), RightHand = createSkeletonLine(),
                LeftUpperLeg = createSkeletonLine(), LeftLowerLeg = createSkeletonLine(), LeftFoot = createSkeletonLine(),
                RightUpperLeg = createSkeletonLine(), RightLowerLeg = createSkeletonLine(), RightFoot = createSkeletonLine()
            }
        }
        
        esp.Box.Color = S.EnemyColor; esp.Box.Thickness = 1; esp.Box.Filled = false; esp.Box.ZIndex = 2
        esp.BoxOutline.Color = Color3.new(0, 0, 0); esp.BoxOutline.Thickness = 3; esp.BoxOutline.Filled = false; esp.BoxOutline.ZIndex = 1
        esp.HealthBar.Color = Color3.new(0, 1, 0); esp.HealthBar.Thickness = 1; esp.HealthBar.Filled = true; esp.HealthBar.ZIndex = 2
        esp.HealthBarOutline.Color = Color3.new(0, 0, 0); esp.HealthBarOutline.Thickness = 1; esp.HealthBarOutline.Filled = true; esp.HealthBarOutline.ZIndex = 1
        esp.Name.Color = Color3.new(1, 1, 1); esp.Name.Size = 16; esp.Name.Center = true; esp.Name.Outline = true; esp.Name.ZIndex = 3
        esp.Distance.Color = Color3.new(1, 1, 1); esp.Distance.Size = 14; esp.Distance.Center = true; esp.Distance.Outline = true; esp.Distance.ZIndex = 3
        esp.Weapon.Color = Color3.new(1, 1, 1); esp.Weapon.Size = 14; esp.Weapon.Center = true; esp.Weapon.Outline = true; esp.Weapon.ZIndex = 3
        esp.Tracer.Color = S.EnemyColor; esp.Tracer.Thickness = 1; esp.Tracer.ZIndex = 1
        
        ESP_Cache[char] = esp
    end

    local function RemoveESP(char)
        if ESP_Cache[char] then
            for k, v in pairs(ESP_Cache[char]) do
                if k == "Highlight" and v then
                    pcall(function() v:Destroy() end)
                elseif k == "SkeletonLines" and v then
                    for _, line in pairs(v) do pcall(function() line.Visible = false; line:Remove() end) end
                else
                    pcall(function() v.Visible = false; v:Remove() end)
                end
            end
            ESP_Cache[char] = nil
        end
    end

    workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") and ESP_Cache[desc] then RemoveESP(desc) end
    end)

    RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera or Camera
        if not Camera then return end

        for char, esp in pairs(ESP_Cache) do
            local isModelValid = char and char.Parent and char:IsDescendantOf(workspace)
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hasRoot = char and char:FindFirstChild("HumanoidRootPart")
            if not isModelValid or not hum or hum.Health <= 0 or not hasRoot or hum:GetState() == Enum.HumanoidStateType.Dead then
                RemoveESP(char)
            end
        end

        local now = tick()
        if S.Enabled and now - TeamCheckState.lastESPScanTime > 0.5 then
            TeamCheckState.lastESPScanTime = now
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and char ~= LocalPlayer.Character then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                        if not ESP_Cache[char] then CreateESP(char) end
                    end
                end
            end
        end

        for char, esp in pairs(ESP_Cache) do
            if char:IsA("Model") and char ~= LocalPlayer.Character then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")

                if hum and hum.Health > 0 and root and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                    local head = char:FindFirstChild("Head")
                    local isAlive = root and hum.Health > 0
                    
                    local plr = Players:GetPlayerFromCharacter(char)
                    local isTeammate = S.TeamCheck and plr and isSameTeam(plr) or false
                    
                    local myRoot = getRootPart()
                    local dist = myRoot and math.floor((myRoot.Position - root.Position).Magnitude) or 0
                    local inRange = dist <= S.MaxDist
                    
                    local shouldShow = S.Enabled and isAlive and not isTeammate and inRange
                    
                    if shouldShow then
                        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        local headPartPos = head and head.Position or (root.Position + Vector3.new(0, 1.5, 0))
                        local headPos = Camera:WorldToViewportPoint(headPartPos + Vector3.new(0, 0.5, 0))
                        local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                        
                        if onScreen then
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height / 2
                            
                            if S.Boxes then
                                esp.Box.Color = S.EnemyColor; esp.Box.Size = Vector2.new(width, height)
                                esp.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                                esp.Box.Visible = true; esp.BoxOutline.Size = esp.Box.Size
                                esp.BoxOutline.Position = esp.Box.Position; esp.BoxOutline.Visible = true
                            else
                                esp.Box.Visible = false; esp.BoxOutline.Visible = false
                            end
                            
                            if S.Health then
                                local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                local healthHeight = height * healthPercent
                                esp.HealthBarOutline.Size = Vector2.new(4, height + 2)
                                esp.HealthBarOutline.Position = Vector2.new(rootPos.X - width / 2 - 6, rootPos.Y - height / 2 - 1)
                                esp.HealthBarOutline.Visible = true
                                esp.HealthBar.Size = Vector2.new(2, healthHeight)
                                esp.HealthBar.Position = Vector2.new(rootPos.X - width / 2 - 5, rootPos.Y + height / 2 - healthHeight)
                                esp.HealthBar.Color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
                                esp.HealthBar.Visible = true
                            else
                                esp.HealthBar.Visible = false; esp.HealthBarOutline.Visible = false
                            end
                            
                            if S.Names then
                                local pName = plr and (plr.DisplayName or plr.Name) or ("[Bot] " .. char.Name)
                                esp.Name.Text = pName; esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 18)
                                esp.Name.Visible = true
                            else
                                esp.Name.Visible = false
                            end
                            
                            if S.Distance then
                                esp.Distance.Text = "[" .. tostring(dist) .. "m]"
                                esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + height / 2 + 2)
                                esp.Distance.Visible = true
                            else
                                esp.Distance.Visible = false
                            end

                            if S.Weapon then
                                local weaponName = getCharacterWeaponName(char)
                                if weaponName then
                                    esp.Weapon.Text = weaponName
                                    esp.Weapon.Position = Vector2.new(rootPos.X, rootPos.Y + height / 2 + (S.Distance and 18 or 2))
                                    esp.Weapon.Visible = true
                                else
                                    esp.Weapon.Visible = false
                                end
                            else
                                esp.Weapon.Visible = false
                            end
                            
                            if S.Tracers then
                                esp.Tracer.Color = S.EnemyColor; esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + height / 2); esp.Tracer.Visible = true
                            else
                                esp.Tracer.Visible = false
                            end

                            updateSkeletonESP(char, esp)
                        else
                            esp.Box.Visible = false; esp.BoxOutline.Visible = false
                            esp.HealthBar.Visible = false; esp.HealthBarOutline.Visible = false
                            esp.Name.Visible = false; esp.Distance.Visible = false; esp.Weapon.Visible = false; esp.Tracer.Visible = false
                            hideSkeletonLines(esp.SkeletonLines)
                        end
                        
                        if S.Chams then
                            if not esp.Highlight or esp.Highlight.Parent ~= char then
                                if esp.Highlight then pcall(function() esp.Highlight:Destroy() end) end
                                local hl = Instance.new("Highlight")
                                hl.Name = "ESPCham"
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = char
                                esp.Highlight = hl
                            end
                            esp.Highlight.FillColor = S.EnemyColor
                            esp.Highlight.OutlineColor = Color3.new(1, 1, 1)
                        else
                            if esp.Highlight then pcall(function() esp.Highlight:Destroy() end); esp.Highlight = nil end
                        end
                        
                    else
                        esp.Box.Visible = false; esp.BoxOutline.Visible = false
                        esp.HealthBar.Visible = false; esp.HealthBarOutline.Visible = false
                        esp.Name.Visible = false; esp.Distance.Visible = false; esp.Weapon.Visible = false; esp.Tracer.Visible = false
                        hideSkeletonLines(esp.SkeletonLines)
                        if esp.Highlight then pcall(function() esp.Highlight:Destroy() end); esp.Highlight = nil end
                    end
                end
            end
        end
    end)

    -- ── UI Controls ──────────────────────────────────────────────

    Tabs.ESP:AddToggle("ESPMaster",   { Title = "Enable ESP",             Default = true }):OnChanged(function() S.Enabled   = Options.ESPMaster.Value   end)
    Tabs.ESP:AddToggle("ESPBoxes",    { Title = "Show Boxes",             Default = true  }):OnChanged(function() S.Boxes     = Options.ESPBoxes.Value    end)
    Tabs.ESP:AddToggle("ESPNames",    { Title = "Show Names",             Default = true  }):OnChanged(function() S.Names     = Options.ESPNames.Value    end)
    Tabs.ESP:AddToggle("ESPDist",     { Title = "Show Distance",          Default = true  }):OnChanged(function() S.Distance  = Options.ESPDist.Value     end)
    Tabs.ESP:AddToggle("ESPHealth",   { Title = "Show Health Bar",        Default = true  }):OnChanged(function() S.Health    = Options.ESPHealth.Value   end)
    Tabs.ESP:AddToggle("ESPTracers",  { Title = "Show Tracers",           Default = true  }):OnChanged(function() S.Tracers   = Options.ESPTracers.Value  end)
    Tabs.ESP:AddToggle("ESPChams",    { Title = "Show Chams",             Default = false }):OnChanged(function() S.Chams     = Options.ESPChams.Value    end)
    Tabs.ESP:AddToggle("ESPSkeleton", { Title = "Show Skeleton",          Default = false }):OnChanged(function() S.Skeleton  = Options.ESPSkeleton.Value end)
    Tabs.ESP:AddToggle("ESPWeapon",   { Title = "Show Weapon Name",       Default = false }):OnChanged(function() S.Weapon    = Options.ESPWeapon.Value   end)
    Tabs.ESP:AddToggle("ESPTeamCheck", { Title = "Team Check (Skip Teammates)", Default = false }):OnChanged(function() S.TeamCheck = Options.ESPTeamCheck.Value end)
    
    Tabs.ESP:AddDropdown("TeamCheckMode", {
        Title = "Team Check Mode",
        Values = {
            "Auto Detect", "Auto (Try All)", "Roblox Teams", "FactionType Attribute",
            "Team Attribute", "IntValue (Team)", "StringValue (Team)", "TeamColor",
            "Role Attribute", "Crew / Guild Tag", "Display Name Color", "Shirt Template",
            "Leaderstats / Side"
        },
        Default = 1
    }):OnChanged(function(value) S.TeamCheckMode = value end)

    Tabs.ESP:AddSlider("ESPMaxDist", {
        Title = "Max Distance", Default = 1000, Min = 50, Max = 5000, Rounding = 0,
        Callback = function(v) S.MaxDist = v end
    })

    Tabs.ESP:AddColorpicker("ESPEnemyColor", { Title = "Enemy Color", Default = Color3.fromRGB(255, 50, 50) }):OnChanged(function()
        S.EnemyColor = Options.ESPEnemyColor.Value
    end)

end

-- ================================================================
--  COMBAT TAB – Aimbot
-- ================================================================
do
    -- ── Combat State ─────────────────────────────────────────────
    local CS = {
        aimbotEnabled      = false,
        aimbotHoldEnabled  = true,   -- true = must hold RMB to aim
        aimbotHeadRate     = 100,
        aimbotFov          = 180,
        aimbotSmoothness   = 0.18,
        aimbotTarget       = nil,
        aimbotVisibleOnly  = true,
        aimbotLockTarget   = false,
        aimbotShowFov      = true,
        aimbotShowInfo     = true,
        aimbotShowDist     = true,
        noRecoilEnabled    = false,
        lastScanTime       = 0,
        -- Kill Aura
        killAuraEnabled    = false,
        killAuraMethod     = "WeaponHit (Game 1)",
        killAuraRadius     = 150,
        killAuraDelay      = 0.1,
        killAuraPart       = "Head",
        killAuraWallCheck  = false,
        lastKillAuraTime   = 0,
    }

    -- ── Drawing objects ───────────────────────────────────────────
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color       = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness   = 1
    fovCircle.Filled      = false
    fovCircle.Transparency = 1
    fovCircle.Visible     = false

    local targetText = Drawing.new("Text")
    targetText.Color   = Color3.fromRGB(255, 220, 50)
    targetText.Size    = 16
    targetText.Center  = true
    targetText.Outline = true
    targetText.Visible = false

    -- ── Helpers ───────────────────────────────────────────────────

    -- Check line-of-sight from camera to part
    local function isVisible(targetPart)
        if not Camera or not targetPart then return false end
        local origin    = Camera.CFrame.Position
        local direction = targetPart.Position - origin
        if direction.Magnitude <= 0 then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude  -- FIX: Blacklist renamed to Exclude
        local excludeList = {Camera}
        if LocalPlayer.Character then table.insert(excludeList, LocalPlayer.Character) end
        params.FilterDescendantsInstances = excludeList
        local result = workspace:Raycast(origin, direction, params)
        return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
    end

    -- Check whether a target character is valid
    local function isValidTarget(char)
        if not char or char == LocalPlayer.Character or not char.Parent then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0.1 then return false end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
        
        -- ForceField check for spawn protection
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("ForceField") or string.lower(child.Name):find("forcefield") then
                return false
            end
        end
        
        return true
    end

    -- Get the aim part on the target character
    local function getAimPart(char)
        if not isValidTarget(char) then return nil end
        
        -- Default to 100% headshot if not set
        local headRate = CS.aimbotHeadRate or 100 
        local isHeadshot = (math.random(1, 100) <= headRate)
        local targetPartName = isHeadshot and "Head" or "HumanoidRootPart"
        
        local part = char:FindFirstChild(targetPartName)
        if part and part:IsA("BasePart") then return part end
        
        -- fallback if requested part doesn't exist
        for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso", "Torso"}) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then return p end
        end
        return nil
    end

    -- Find the closest target to the mouse within the FOV radius
    local function getBestTarget()
        if not Camera then return nil end
        local mousePos  = UserInputService:GetMouseLocation()
        local bestChar  = nil
        local bestDist  = CS.aimbotFov

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and isValidTarget(player.Character) then
                local part = getAimPart(player.Character)
                if part then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and sp.Z > 0 then
                        local screenDist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if screenDist <= bestDist then
                            if not CS.aimbotVisibleOnly or isVisible(part) then
                                bestDist = screenDist
                                bestChar = player.Character
                            end
                        end
                    end
                end
            end
        end
        return bestChar
    end

    -- ── UI Controls ───────────────────────────────────────────────
    local AimbotGroup = Tabs.Combat:AddSection("Aimbot")

    AimbotGroup:AddToggle("AimbotEnabled", {
        Title = "Enable Aimbot", Default = false
    }):OnChanged(function()
        CS.aimbotEnabled = Options.AimbotEnabled.Value
        if not CS.aimbotEnabled then
            CS.aimbotTarget = nil
            fovCircle.Visible = false
            targetText.Visible = false
        end
    end)

    AimbotGroup:AddToggle("AimbotHold", {
        Title = "Require RMB Hold", Default = true
    }):OnChanged(function()
        CS.aimbotHoldEnabled = Options.AimbotHold.Value
    end)

    AimbotGroup:AddSlider("AimbotHeadRate", {
        Title = "Headshot Chance (%)", Default = 100, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) 
            CS.aimbotHeadRate = v 
            CS.aimbotTarget = nil -- Reset target when headshot rate changes
        end
    })

    AimbotGroup:AddSlider("AimbotFov", {
        Title = "FOV Radius", Default = 180, Min = 25, Max = 600, Rounding = 0,
        Callback = function(v) CS.aimbotFov = v end
    })

    AimbotGroup:AddSlider("AimbotSmooth", {
        Title = "Smoothness", Default = 18, Min = 1, Max = 100, Rounding = 0,
        Callback = function(v) CS.aimbotSmoothness = v / 100 end
    })

    AimbotGroup:AddToggle("AimbotVisOnly", {
        Title = "Visible Only", Default = true
    }):OnChanged(function()
        CS.aimbotVisibleOnly = Options.AimbotVisOnly.Value
        CS.aimbotTarget = nil
    end)

    AimbotGroup:AddToggle("AimbotLock", {
        Title = "Lock Target", Default = false
    }):OnChanged(function()
        CS.aimbotLockTarget = Options.AimbotLock.Value
        CS.aimbotTarget = nil
    end)

    AimbotGroup:AddToggle("AimbotFovVis", {
        Title = "Show FOV Circle", Default = true
    }):OnChanged(function()
        CS.aimbotShowFov = Options.AimbotFovVis.Value
    end)

    AimbotGroup:AddToggle("AimbotInfoVis", {
        Title = "Show Target Info", Default = true
    }):OnChanged(function()
        CS.aimbotShowInfo = Options.AimbotInfoVis.Value
    end)

    AimbotGroup:AddToggle("AimbotDistVis", {
        Title = "Show Target Distance", Default = true
    }):OnChanged(function()
        CS.aimbotShowDist = Options.AimbotDistVis.Value
    end)

    -- ================================================================
    --  WEAPON MODS
    -- ================================================================
    local WeaponGroup = Tabs.Combat:AddSection("Weapon Mods")

    -- Toggle states
    CS.noSpreadEnabled    = false
    CS.infiniteAmmoEnabled = false
    CS.rapidFireEnabled   = false

    -- Table storing original values for restoration when features are disabled
    local patchedValues = {}  -- [object] = { key = originalValue }

    -- ── Helper: save original value (only on first patch) ──────────
    local function rememberValue(obj, key)
        if not obj then return end
        if not patchedValues[obj] then patchedValues[obj] = {} end
        if patchedValues[obj][key] == nil then
            local ok, val = pcall(function() return obj[key] end)
            if ok and type(val) == "number" then
                patchedValues[obj][key] = val
            end
        end
    end

    -- ── Helper: safely set a value ──────────────────────────────────
    local function safeSet(obj, key, val)
        if not obj then return end
        rememberValue(obj, key)
        pcall(function() obj[key] = val end)
    end

    -- ── Helper: restore original values ──────────────────────────────
    local function restoreAllValues()
        for obj, keys in pairs(patchedValues) do
            for key, original in pairs(keys) do
                pcall(function() obj[key] = original end)
            end
        end
        patchedValues = {}
    end

    -- ── Scan tool descendants and patch matching keyword values ──────
    local function patchTool(tool, keywordSets)
        if not tool or not tool:IsA("Tool") then return end
        for _, desc in ipairs(tool:GetDescendants()) do
            local lname = string.lower(desc.Name)
            if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                for _, ks in ipairs(keywordSets) do
                    for _, kw in ipairs(ks.keywords) do
                        if lname:find(kw, 1, true) then
                            safeSet(desc, "Value", ks.value)
                            break
                        end
                    end
                end
            elseif desc:IsA("ModuleScript") then
                pcall(function()
                    local m = require(desc)
                    if type(m) ~= "table" then return end
                    for k, v in pairs(m) do
                        if type(v) == "number" then
                            local lk = string.lower(tostring(k))
                            for _, ks in ipairs(keywordSets) do
                                for _, kw in ipairs(ks.keywords) do
                                    if lk:find(kw, 1, true) then
                                        rememberValue(m, k)
                                        m[k] = ks.value
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    -- ── No Spread ──────────────────────────────────────────────────
    WeaponGroup:AddToggle("NoSpread", {
        Title = "No Spread", Default = false
    }):OnChanged(function()
        CS.noSpreadEnabled = Options.NoSpread.Value
        if not CS.noSpreadEnabled then
            restoreAllValues()
        end
        Fluent:Notify({
            Title   = "No Spread",
            Content = CS.noSpreadEnabled and "Enabled!" or "Disabled.",
            Duration = 2
        })
    end)

    -- ── Infinite Ammo ──────────────────────────────────────────────
    WeaponGroup:AddToggle("InfiniteAmmo", {
        Title = "Infinite Ammo", Default = false
    }):OnChanged(function()
        CS.infiniteAmmoEnabled = Options.InfiniteAmmo.Value
        if not CS.infiniteAmmoEnabled then
            restoreAllValues()
        end
        Fluent:Notify({
            Title   = "Infinite Ammo",
            Content = CS.infiniteAmmoEnabled and "Enabled!" or "Disabled.",
            Duration = 2
        })
    end)

    -- ── Fast Fire (Rapid Fire) ──────────────────────────────────────
    WeaponGroup:AddToggle("FastFire", {
        Title = "Fast Fire", Default = false
    }):OnChanged(function()
        CS.rapidFireEnabled = Options.FastFire.Value
        if not CS.rapidFireEnabled then
            restoreAllValues()
        end
        Fluent:Notify({
            Title   = "Fast Fire",
            Content = CS.rapidFireEnabled and "Enabled!" or "Disabled.",
            Duration = 2
        })
    end)

    -- ── Heartbeat: apply patches every frame while a tool is equipped ──
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local tool = char:FindFirstChildOfClass("Tool")

        -- No Spread
        if CS.noSpreadEnabled and tool then
            patchTool(tool, {
                { keywords = {"spread","spreadradius","spread_radius","accuracy","inaccuracy"}, value = 0 },
                { keywords = {"recoil","recoilamount","recoil_amount"},                          value = 0 },
            })
        end

        -- Infinite Ammo
        if CS.infiniteAmmoEnabled and tool then
            patchTool(tool, {
                { keywords = {"ammo","magazine","clip","bullet","reserve","maxammo","maxbullet"}, value = 9999 },
            })
            -- Force-write every frame to prevent the game from resetting ammo
            for _, desc in ipairs(tool:GetDescendants()) do
                local lname = string.lower(desc.Name)
                if desc:IsA("NumberValue") or desc:IsA("IntValue") then
                    if lname:find("ammo",1,true) or lname:find("magazine",1,true)
                    or lname:find("clip",1,true) or lname:find("bullet",1,true)
                    or lname:find("reserve",1,true) then
                        pcall(function() desc.Value = 9999 end)
                    end
                end
            end
        end

        -- Fast Fire
        if CS.rapidFireEnabled and tool then
            patchTool(tool, {
                { keywords = {"firerate","fire_rate","firedelay","fire_delay","shotdelay",
                              "shot_delay","delay","cooldown","rpm","rate"}, value = 0 },
            })
        end

        -- Cleanup when no tool is equipped
        if not tool then
            patchedValues = {}
        end
    end)

    -- ── FOV Circle + Target Info render (RenderStepped) ───────────
    RunService.RenderStepped:Connect(function()
        if not CS.aimbotEnabled or not Camera then
            fovCircle.Visible = false
            targetText.Visible = false
            return
        end

        -- Draw the FOV circle at the current mouse position
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position    = Vector2.new(mouse.X, mouse.Y)
        fovCircle.Radius      = CS.aimbotFov
        fovCircle.Visible     = CS.aimbotShowFov

        -- Display target name and distance
        local showInfo = CS.aimbotShowInfo
            and CS.aimbotTarget
            and isValidTarget(CS.aimbotTarget)
        if showInfo then
            local part = getAimPart(CS.aimbotTarget)
            if part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and sp.Z > 0 then
                    local dist = math.floor((Camera.CFrame.Position - part.Position).Magnitude)
                    local txt  = CS.aimbotTarget.Name
                    if CS.aimbotShowDist then
                        txt = string.format("%s  [%d studs]", txt, dist)
                    end
                    targetText.Text     = txt
                    targetText.Position = Vector2.new(sp.X, sp.Y + 22)
                    targetText.Visible  = true
                else
                    targetText.Visible = false
                end
            else
                targetText.Visible = false
            end
        else
            targetText.Visible = false
        end
    end)

    -- ── Aimbot camera override – runs AFTER Roblox camera module ────
    RunService:BindToRenderStep(
        "AimbotCamOverride",
        Enum.RenderPriority.Camera.Value + 1,
        function()
            if not CS.aimbotEnabled or not Camera then return end

            -- Check RMB hold condition
            local shouldAim = true
            if CS.aimbotHoldEnabled then
                shouldAim = UserInputService:IsMouseButtonPressed(
                    Enum.UserInputType.MouseButton2
                )
            end
            if not shouldAim then
                CS.aimbotTarget = nil
                return
            end

            -- Scan for target every 0.1s (throttled)
            local now = tick()
            if now - CS.lastScanTime > 0.1 then
                CS.lastScanTime = now
                local currentPart = CS.aimbotTarget and getAimPart(CS.aimbotTarget)
                local currentValid = currentPart
                    and isValidTarget(CS.aimbotTarget)
                    and (not CS.aimbotVisibleOnly or isVisible(currentPart))

                -- No target yet, target became invalid, or lock is disabled
                if not currentValid or not CS.aimbotLockTarget then
                    CS.aimbotTarget = getBestTarget()
                end
            end

            if not CS.aimbotTarget then return end

            local part = getAimPart(CS.aimbotTarget)
            if not part or not isValidTarget(CS.aimbotTarget) then
                CS.aimbotTarget = nil
                return
            end
            if CS.aimbotVisibleOnly and not isVisible(part) then return end

            -- Lerp camera toward target
            local origin  = Camera.CFrame.Position
            local aimCF   = CFrame.new(origin, part.Position)
            local alpha   = math.clamp(CS.aimbotSmoothness, 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, alpha)
        end
    )

    Fluent:Notify({
        Title   = "Combat",
        Content = "Aimbot ready! Enable the toggle to activate.",
        Duration = 4
    })

    -- ================================================================
    --  KILL AURA
    -- ================================================================
    local KillAuraGroup = Tabs.Combat:AddSection("Kill Aura")

    KillAuraGroup:AddToggle("KillAuraEnabled", {
        Title = "Enable Kill Aura", Default = false
    }):OnChanged(function()
        CS.killAuraEnabled = Options.KillAuraEnabled.Value
        if not CS.killAuraEnabled then CS.lastKillAuraTime = 0 end
    end)

    KillAuraGroup:AddDropdown("KillAuraMethod", {
        Title = "Method",
        Values = {
            "WeaponHit (Game 1)",
            "RequestActionSync (Game 2)",
            "GunRemote (Game 3)",
            "WeaponsSystem (Game 4)",
            "FireWeapon (Game 5)",
            "Shoot (Game 6)",
            "Crossbow (Game 7)",
            "Routers (Game 8)"
        },
        Multi = false, Default = "WeaponHit (Game 1)"
    }):OnChanged(function(v) CS.killAuraMethod = v end)

    KillAuraGroup:AddSlider("KillAuraRadius", {
        Title = "Aura Range", Default = 250, Min = 10, Max = 1000, Rounding = 0
    }):OnChanged(function() CS.killAuraRadius = Options.KillAuraRadius.Value end)

    KillAuraGroup:AddSlider("KillAuraDelay", {
        Title = "Attack Delay (s)", Default = 0.05, Min = 0.001, Max = 1, Rounding = 3
    }):OnChanged(function() CS.killAuraDelay = Options.KillAuraDelay.Value end)

    KillAuraGroup:AddSlider("KillAuraHeadRate", {
        Title = "Headshot Chance (%)", Default = 100, Min = 0, Max = 100, Rounding = 0
    }):OnChanged(function() CS.killAuraHeadRate = Options.KillAuraHeadRate.Value end)

    KillAuraGroup:AddToggle("KillAuraWallCheck", {
        Title = "Wall Check (visible only)", Default = false
    }):OnChanged(function() CS.killAuraWallCheck = Options.KillAuraWallCheck.Value end)

    -- ── Kill Aura Heartbeat ───────────────────────────────────────
    RunService.Heartbeat:Connect(function()
        if not CS.killAuraEnabled then return end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        local now = tick()
        if now - CS.lastKillAuraTime < CS.killAuraDelay then return end
        CS.lastKillAuraTime = now

        local weapon = myChar:FindFirstChildOfClass("Tool")

        -- Build target list
        local targets = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local pChar = getPlayerCharacter(player)
                if isValidTarget(pChar) then
                    local tRoot = pChar:FindFirstChild("HumanoidRootPart")
                    local tHum  = pChar:FindFirstChildOfClass("Humanoid")
                    local dist = (myRoot.Position - tRoot.Position).Magnitude
                    if dist <= CS.killAuraRadius then
                        local headRate = CS.killAuraHeadRate or 100
                        local isHeadshot = (math.random(1, 100) <= headRate)
                        local partName = isHeadshot and "Head" or "HumanoidRootPart"
                        local targetPart = pChar:FindFirstChild(partName) or tRoot
                        local canSee = true
                        if CS.killAuraWallCheck then
                            canSee = isVisible(targetPart)
                        end
                        if canSee then
                            table.insert(targets, {
                                player    = player,
                                character = pChar,
                                root      = tRoot,
                                humanoid  = tHum,
                                targetPart = targetPart,
                                distance  = dist
                            })
                        end
                    end
                end
            end
        end

        for _, t in ipairs(targets) do
            local targetPart = t.targetPart
            pcall(function()
                local RS = game:GetService("ReplicatedStorage")
                local dir = (targetPart.Position - myRoot.Position).Unit

                if CS.killAuraMethod == "WeaponHit (Game 1)" then
                    local eventos = RS:FindFirstChild("Eventos")
                    if not eventos then return end
                    local weaponFired = eventos:FindFirstChild("WeaponFired")
                    local weaponHit   = eventos:FindFirstChild("WeaponHit")
                    if not weaponFired or not weaponHit then return end
                    local sid = math.random(1, 10)
                    weaponFired:FireServer(weapon, { id=sid, charge=0, origin=myRoot.Position, dir=dir })
                    weaponHit:FireServer(weapon, {
                        p=targetPart.Position, pid=1, part=targetPart,
                        d=t.distance, maxDist=t.distance+1, h=t.humanoid,
                        m=Enum.Material.Plastic, n=Vector3.yAxis, t=0.1, sid=sid
                    })

                elseif CS.killAuraMethod == "RequestActionSync (Game 2)" then
                    local sysRes  = RS:FindFirstChild("SystemResources")
                    local bufCache= sysRes and sysRes:FindFirstChild("BufferCache")
                    local ras     = bufCache and bufCache:FindFirstChild("RequestActionSync")
                    local events  = RS:FindFirstChild("Events")
                    local rEvts   = events and events:FindFirstChild("RemoteEvents")
                    local fakeBullet = rEvts and rEvts:FindFirstChild("ReplicateFakeBullet")
                    local muzzle     = rEvts and rEvts:FindFirstChild("CharacterMuzzleFlash")
                    if not ras then return end
                    ras:FireServer({
                        direction=dir, hitPosition=targetPart.Position,
                        origin=myRoot.Position, hitInstance=targetPart,
                        hitHumanoid=t.humanoid,
                        IsHeadshot = (targetPart.Name == "Head")
                    })
                    if fakeBullet then fakeBullet:FireServer(CFrame.new(myRoot.Position, targetPart.Position), dir) end
                    if muzzle     then muzzle:FireServer() end

                elseif CS.killAuraMethod == "GunRemote (Game 3)" then
                    local remotes   = RS:FindFirstChild("Remotes")
                    local gunRemote = remotes and remotes:FindFirstChild("GunRemote")
                    if not gunRemote then return end
                    gunRemote:FireServer(1, weapon, targetPart.Position, Vector3.yAxis, targetPart)

                elseif CS.killAuraMethod == "WeaponsSystem (Game 4)" then
                    local ws  = RS:FindFirstChild("WeaponsSystem")
                    local net = ws and ws:FindFirstChild("Network")
                    local wFired = net and net:FindFirstChild("WeaponFired")
                    local wHit   = net and net:FindFirstChild("WeaponHit")
                    if not wFired or not wHit then return end
                    local cur = weapon or myChar:FindFirstChildOfClass("Tool")
                    if not cur then return end
                    local sid = math.random(10, 100)
                    wFired:FireServer(cur, { id=sid, charge=0, origin=myRoot.Position, dir=dir })
                    wHit:FireServer(cur, {
                        p=targetPart.Position, pid=1, part=targetPart,
                        d=t.distance, maxDist=t.distance+1, h=t.humanoid,
                        m=Enum.Material.Plastic, n=Vector3.yAxis, t=0.1, sid=sid
                    })

                elseif CS.killAuraMethod == "FireWeapon (Game 5)" then
                    local events    = RS:FindFirstChild("Events")
                    local fireWeapon= events and events:FindFirstChild("FireWeapon")
                    if not fireWeapon then return end
                    local origin = myRoot.Position + Vector3.new(0, 1.5, 0)
                    local fDir   = (targetPart.Position - origin).Unit
                    local hitboxPart = targetPart
                    local hitboxHandler = t.character:FindFirstChild("HitboxHandler")
                    if hitboxHandler then
                        local pName = (targetPart.Name == "Head") and "Hitbox_Head" or "Hitbox_Torso"
                        hitboxPart = hitboxHandler:FindFirstChild(pName)
                            or hitboxHandler:FindFirstChildOfClass("BasePart")
                            or targetPart
                    end
                    fireWeapon:FireServer("Main", origin, fDir, {
                        [1] = { Normal=Vector3.yAxis, Direction=fDir,
                                Position=hitboxPart.Position, Hit=hitboxPart,
                                Bounce=0, Origin=origin }
                    })

                elseif CS.killAuraMethod == "Shoot (Game 6)" then
                    local func     = RS:FindFirstChild("Function")
                    local gameplay = func and func:FindFirstChild("Gameplay")
                    local shoot    = gameplay and gameplay:FindFirstChild("Shoot")
                    local ping     = func and func:FindFirstChild("Ping")
                    if not shoot or not ping then return end
                    local headshot = (targetPart.Name == "Head")
                    local hitInst  = t.character:FindFirstChild(targetPart.Name) or targetPart
                    shoot:InvokeServer(
                        Camera.CFrame, 6, 1, 2, tick(),
                        {{ normal=Vector3.yAxis, victimCha=t.character, victimHum=t.humanoid,
                           instance=hitInst, finalPosition=targetPart.Position,
                           headshot=headshot, bulletDirection=dir }},
                        tick() - workspace.DistributedGameTime,
                        { Max={Y=0.5,X=0.5}, Min={Y=-0.5,X=-0.5} }
                    )
                    ping:InvokeServer()

                elseif CS.killAuraMethod == "Crossbow (Game 7)" then
                    local ws  = RS:FindFirstChild("WeaponsSystem")
                    local net = ws and ws:FindFirstChild("Network")
                    local wFired = net and net:FindFirstChild("WeaponFired")
                    local wHit   = net and net:FindFirstChild("WeaponHit")
                    local cur = weapon or myChar:FindFirstChildOfClass("Tool")
                    if not cur or not wFired or not wHit then return end
                    local sid = math.random(10, 100)
                    local hitInst = t.character:FindFirstChild(targetPart.Name) or targetPart
                    wFired:FireServer(cur, { id=sid, charge=1, origin=myRoot.Position, dir=dir })
                    wHit:FireServer(cur, {
                        p=targetPart.Position, pid=1, part=hitInst,
                        d=t.distance, maxDist=t.distance, h=t.humanoid,
                        m=Enum.Material.Plastic, n=Vector3.yAxis, t=0.1, sid=sid
                    })
                elseif CS.killAuraMethod == "Routers (Game 8)" then
                    local routers = RS:FindFirstChild("Routers")
                    if routers then
                        local weaponSystemRemotes = routers:FindFirstChild("WeaponSystemRemotes")
                        local notifyRemotes = routers:FindFirstChild("NotifyRemotes")
                        
                        local fireRemote = weaponSystemRemotes and weaponSystemRemotes:FindFirstChild("Fire")
                        local hitRemote = weaponSystemRemotes and weaponSystemRemotes:FindFirstChild("Hit")
                        local specRemote = notifyRemotes and notifyRemotes:FindFirstChild("SpectatorDamage")
                        
                        local currentWeapon = weapon or myChar:FindFirstChildOfClass("Tool")
                        
                        if currentWeapon and fireRemote and hitRemote then
                            local hitInstance = t.character:FindFirstChild(targetPart.Name) or targetPart
                            local sid = math.random(1, 100)
                            
                            -- 1. SpectatorDamage
                            if specRemote then
                                pcall(function()
                                    specRemote:FireServer(18, targetPart.Position, false)
                                end)
                            end
                            
                            -- 2. Fire
                            pcall(function()
                                fireRemote:FireServer(currentWeapon, {
                                    ["id"] = sid,
                                    ["charge"] = 0,
                                    ["origin"] = myRoot.Position,
                                    ["dir"] = dir
                                })
                            end)
                            
                            -- 3. Hit
                            pcall(function()
                                hitRemote:FireServer(currentWeapon, {
                                    ["p"] = targetPart.Position,
                                    ["pid"] = 1,
                                    ["part"] = hitInstance,
                                    ["d"] = t.distance,
                                    ["maxDist"] = t.distance + 1,
                                    ["h"] = hitInstance,
                                    ["m"] = Enum.Material.Sand,
                                    ["n"] = Vector3.yAxis,
                                    ["t"] = 0.737,
                                    ["sid"] = sid
                                })
                            end)
                        end
                    end
                end
            end)
        end
    end)


end

-- ================================================================
--  TELEPORT TAB
-- ================================================================
do
    local TweenService = game:GetService("TweenService")
    local teleportTarget = nil
    local teleportMode = "Instant"
    local tweenSpeed = 50
    local activeTweenFly = nil

    local function doTweenFly(targetCFrame)
        local myRoot = getRootPart()
        local myHum = getHumanoid()
        if not myRoot or not myHum then return end

        if activeTweenFly then activeTweenFly:Disconnect() end

        local dist = (myRoot.Position - targetCFrame.Position).Magnitude
        if dist < 0.1 then return end
        
        local timeToTravel = dist / tweenSpeed
        local elapsedTime = 0
        local startCFrame = myRoot.CFrame

        myHum:ChangeState(Enum.HumanoidStateType.Physics)

        activeTweenFly = RunService.RenderStepped:Connect(function(deltaTime)
            elapsedTime = elapsedTime + deltaTime
            local alpha = math.clamp(elapsedTime / timeToTravel, 0, 1)
            
            -- Keep stealth physics (no gravity, no momentum)
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.CFrame = startCFrame:Lerp(targetCFrame, alpha)
            
            if alpha >= 1 then
                if activeTweenFly then activeTweenFly:Disconnect(); activeTweenFly = nil end
                myHum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end

    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(names, p.Name)
            end
        end
        return names
    end

    local PlayerDropdown = Tabs.Teleport:AddDropdown("TeleportPlayer", {
        Title = "Select Player",
        Values = getPlayerNames(),
        Multi = false,
        Default = nil
    })

    PlayerDropdown:OnChanged(function(Value)
        teleportTarget = Value
    end)

    Tabs.Teleport:AddButton({
        Title = "Refresh Players",
        Callback = function()
            PlayerDropdown:SetValues(getPlayerNames())
        end
    })

    Tabs.Teleport:AddDropdown("TeleportMode", {
        Title = "Teleport Mode",
        Values = { "Instant", "Tween" },
        Multi = false,
        Default = "Instant"
    }):OnChanged(function(Value)
        teleportMode = Value
    end)

    Tabs.Teleport:AddSlider("TweenSpeed", {
        Title = "Tween Speed", Default = 50, Min = 10, Max = 300, Rounding = 0
    }):OnChanged(function(Value) 
        tweenSpeed = Value 
    end)

    Tabs.Teleport:AddButton({
        Title = "Teleport",
        Callback = function()
            if not teleportTarget then 
                Fluent:Notify({ Title = "Teleport", Content = "Please select a player first!", Duration = 3 })
                return 
            end

            local targetPlayer = Players:FindFirstChild(teleportTarget)
            if not targetPlayer then
                Fluent:Notify({ Title = "Teleport", Content = "Player not found!", Duration = 3 })
                return
            end

            local targetChar = getPlayerCharacter(targetPlayer)
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                Fluent:Notify({ Title = "Teleport", Content = "Player character not found!", Duration = 3 })
                return
            end

            local myRoot = getRootPart()
            if not myRoot then return end

            -- Teleport slightly behind the target
            local targetCFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)

            if teleportMode == "Instant" then
                myRoot.CFrame = targetCFrame
                Fluent:Notify({ Title = "Teleport", Content = "Teleported Instantly!", Duration = 2 })
            elseif teleportMode == "Tween" then
                local dist = (myRoot.Position - targetCFrame.Position).Magnitude
                local time = dist / tweenSpeed
                doTweenFly(targetCFrame)
                Fluent:Notify({ Title = "Teleport", Content = ("Tweening... (%.1fs)"):format(time), Duration = 2 })
            end
        end
    })

    -- ────── Click Teleport ───────────────────────────────────────
    local clickTpEnabled = false
    local clickTpConn = nil
    
    Tabs.Teleport:AddToggle("ClickTpToggle", {
        Title = "Click Teleport", Default = false
    }):OnChanged(function()
        clickTpEnabled = Options.ClickTpToggle.Value
        if clickTpEnabled then
            if not clickTpConn then
                local mouse = LocalPlayer:GetMouse()
                clickTpConn = UserInputService.InputBegan:Connect(function(input, gpe)
                    if gpe then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local myRoot = getRootPart()
                        if not myRoot then return end

                        local targetPos = nil
                        if input.UserInputType == Enum.UserInputType.Touch then
                            local cam = workspace.CurrentCamera
                            local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = {LocalPlayer.Character}
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
                            if result then targetPos = result.Position end
                        else
                            if mouse.Hit then targetPos = mouse.Hit.Position end
                        end

                        if targetPos then
                            local targetCFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                            if teleportMode == "Instant" then
                                myRoot.CFrame = targetCFrame
                            elseif teleportMode == "Tween" then
                                doTweenFly(targetCFrame)
                            end
                        end
                    end
                end)
            end
            Fluent:Notify({ Title = "Click Teleport", Content = "Click/Tap anywhere to teleport!", Duration = 3 })
        else
            if clickTpConn then clickTpConn:Disconnect(); clickTpConn = nil end
        end
    end)
end

-- ================================================================
--  MISC TAB
-- ================================================================
do
    local TeleportService = game:GetService("TeleportService")
    local HttpService     = game:GetService("HttpService")
    local placeId         = game.PlaceId


    Tabs.Misc:AddButton({
        Title = "Rejoin Server",
        Callback = function()
            Fluent:Notify({ Title = "Rejoin", Content = "Rejoining...", Duration = 3 })
            task.wait(1)
            TeleportService:Teleport(placeId, LocalPlayer)
        end
    })

    Tabs.Misc:AddButton({
        Title = "Server Hop",
        Callback = function()
            Fluent:Notify({ Title = "Server Hop", Content = "Searching for server...", Duration = 3 })
            task.spawn(function()
                local cur = game.JobId
                local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
                local ok, resp = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
                if not ok or not resp or not resp.data then
                    Fluent:Notify({ Title = "Server Hop", Content = "Failed to fetch server list!", Duration = 4 }); return
                end
                for _, sv in ipairs(resp.data) do
                    if sv.id ~= cur and sv.playing < sv.maxPlayers then
                        Fluent:Notify({ Title = "Server Hop", Content = "Found! Transferring...", Duration = 3 })
                        task.wait(1); TeleportService:TeleportToPlaceInstance(placeId, sv.id, LocalPlayer); return
                    end
                end
                Fluent:Notify({ Title = "Server Hop", Content = "No other server found.", Duration = 4 })
            end)
        end
    })

    -- ================================================================
    --  UTILITIES (ANTI AFK & FORCE TIME)
    -- ================================================================
    local MiscUtilsGroup = Tabs.Misc:AddSection("Utilities")
    
    local antiAfkConn = nil
    MiscUtilsGroup:AddToggle("AntiAFK", {
        Title = "Anti AFK", Default = false
    }):OnChanged(function()
        if Options.AntiAFK.Value then
            if not antiAfkConn then
                local VirtualUser = game:GetService("VirtualUser")
                antiAfkConn = LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                    Fluent:Notify({ Title = "Anti AFK", Content = "Prevented idle disconnect.", Duration = 2 })
                end)
                -- Also try to disable default idled connections if executor supports it
                pcall(function()
                    if getconnections then
                        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                            if conn.Disable then conn:Disable() end
                        end
                    end
                end)
            end
            Fluent:Notify({ Title = "Anti AFK", Content = "Enabled! You won't be kicked for idling.", Duration = 3 })
        else
            if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
        end
    end)

    local forceTimeEnabled = false
    local forceTimeValue = 12
    local forceTimeConns = {}
    
    local function clearForceTime()
        for _, conn in ipairs(forceTimeConns) do
            if conn then conn:Disconnect() end
        end
        table.clear(forceTimeConns)
    end

    MiscUtilsGroup:AddToggle("ForceTimeToggle", {
        Title = "Force Time of Day", Default = false
    }):OnChanged(function()
        forceTimeEnabled = Options.ForceTimeToggle.Value
        local Lighting = game:GetService("Lighting")
        
        clearForceTime()
        
        if forceTimeEnabled then
            Lighting.ClockTime = forceTimeValue
            
            local changing = false
            local function enforceTime()
                if not changing and forceTimeEnabled then
                    if Lighting.ClockTime ~= forceTimeValue then
                        changing = true
                        Lighting.ClockTime = forceTimeValue
                        changing = false
                    end
                end
            end
            
            -- Đánh chặn mọi nỗ lực đổi giờ của game ở mọi mặt trận
            table.insert(forceTimeConns, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(enforceTime))
            table.insert(forceTimeConns, Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(enforceTime))
            table.insert(forceTimeConns, RunService.RenderStepped:Connect(enforceTime))
            table.insert(forceTimeConns, RunService.Heartbeat:Connect(enforceTime))
            table.insert(forceTimeConns, RunService.Stepped:Connect(enforceTime))
        end
    end)
    
    MiscUtilsGroup:AddSlider("ForceTimeSlider", {
        Title = "Time", Default = 12, Min = 0, Max = 24, Rounding = 1
    }):OnChanged(function(Value)
        forceTimeValue = Value
    end)

    -- ================================================================
    --  BANG PLAYER
    -- ================================================================
    local BangGroup = Tabs.Misc:AddSection("Bang Player")
    
    local bangState = {
        targetPlayer = nil,
        speed = 3,
        anim = nil,
        track = nil,
        connection = nil
    }

    local bangDropdown = BangGroup:AddDropdown("BangPlayerDropdown", {
        Title = "Select Player",
        Values = {},
        Multi = false,
        Default = 1
    })

    bangDropdown:OnChanged(function(Value)
        bangState.targetPlayer = Value
    end)

    BangGroup:AddSlider("BangSpeedSlider", {
        Title = "Animation Speed", Default = 3, Min = 1, Max = 10, Rounding = 1,
        Callback = function(Value)
            bangState.speed = Value
            if bangState.track then
                pcall(function() bangState.track:AdjustSpeed(bangState.speed) end)
            end
        end
    })

    local function refreshBangPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        bangDropdown:SetValues(list)
    end

    local function unbangPlayer()
        if bangState.connection then
            bangState.connection:Disconnect()
            bangState.connection = nil
        end
        if bangState.track then
            pcall(function() bangState.track:Stop() end)
            bangState.track = nil
        end
        if bangState.anim then
            bangState.anim:Destroy()
            bangState.anim = nil
        end
    end

    local function bangSelectedPlayer()
        unbangPlayer()
        if not bangState.targetPlayer then return end
        
        local target = Players:FindFirstChild(bangState.targetPlayer)
        if not target then return end
        
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHum or not myRoot then return end

        bangState.anim = Instance.new("Animation")
        -- Detect R15 or R6
        if myHum.RigType == Enum.HumanoidRigType.R15 then
            bangState.anim.AnimationId = "rbxassetid://5918726674"
        else
            bangState.anim.AnimationId = "rbxassetid://148840371"
        end

        local animator = myHum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = myHum
        end
        
        local track = animator:LoadAnimation(bangState.anim)
        bangState.track = track
        track:Play()
        track:AdjustSpeed(bangState.speed)

        bangState.connection = RunService.Stepped:Connect(function()
            local tChar = target.Character
            local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if tRoot and myRoot then
                myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 1.1)
            else
                unbangPlayer()
            end
        end)
    end

    BangGroup:AddButton({ Title = "Bang Player", Callback = function() bangSelectedPlayer() end })
    BangGroup:AddButton({ Title = "Unbang Player", Callback = function() unbangPlayer() end })
    BangGroup:AddButton({ Title = "Refresh List", Callback = function() refreshBangPlayerList() end })

    refreshBangPlayerList()
    Players.PlayerAdded:Connect(refreshBangPlayerList)
    Players.PlayerRemoving:Connect(refreshBangPlayerList)

    -- ================================================================
    --  JERK TOOL
    -- ================================================================
    local JerkGroup = Tabs.Misc:AddSection("Troll Tools")
    
    local jorkinLoop = nil
    
    JerkGroup:AddButton({
        Title = "Give Jerk Tool",
        Callback = function()
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if not backpack or not myHum then
                Fluent:Notify({ Title = "Jerk Tool", Content = "Failed to give tool. Character/Backpack not found.", Duration = 3 })
                return 
            end

            local tool = Instance.new("Tool")
            tool.Name = "Jerk Off"
            tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
            tool.RequiresHandle = false
            tool.Parent = backpack

            local jorkin = false
            local track = nil

            local function stopTomfoolery()
                jorkin = false
                if track then
                    track:Stop()
                    track = nil
                end
                if jorkinLoop then
                    task.cancel(jorkinLoop)
                    jorkinLoop = nil
                end
            end

            tool.Equipped:Connect(function() 
                jorkin = true 
                jorkinLoop = task.spawn(function()
                    while jorkin and task.wait() do
                        if not myHum or not myHum.Parent then break end
                        local isR15 = myHum.RigType == Enum.HumanoidRigType.R15
                        
                        if not track then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = not isR15 and "rbxassetid://72042024" or "rbxassetid://698251653"
                            
                            local animator = myHum:FindFirstChildOfClass("Animator")
                            if not animator then
                                animator = Instance.new("Animator")
                                animator.Parent = myHum
                            end
                            track = animator:LoadAnimation(anim)
                        end

                        track:Play()
                        track:AdjustSpeed(isR15 and 0.7 or 0.65)
                        track.TimePosition = 0.6
                        
                        task.wait(0.1)
                        local targetTime = not isR15 and 0.65 or 0.7
                        while track and track.TimePosition < targetTime do 
                            task.wait(0.1) 
                        end
                        
                        if track then
                            track:Stop()
                            track = nil
                        end
                    end
                end)
            end)
            
            tool.Unequipped:Connect(stopTomfoolery)
            myHum.Died:Connect(stopTomfoolery)
            
            Fluent:Notify({ Title = "Jerk Tool", Content = "Tool added to backpack!", Duration = 3 })
        end
    })

end

-- ================================================================
--  SETTINGS TAB
-- ================================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("28th6Hub")
SaveManager:SetFolder("28th6Hub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({ Title = "28th6", Content = "Loaded successfully! ⚡", Duration = 5 })

SaveManager:LoadAutoloadConfig()

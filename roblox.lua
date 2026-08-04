local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Script Hub",
    SubTitle = "by user",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",     Icon = "zap"      }),
    ESP      = Window:AddTab({ Title = "ESP",      Icon = "eye"      }),
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "shield"   }),
    Misc     = Window:AddTab({ Title = "Misc",     Icon = "globe"    }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
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
-- Get a player's character, including nil-instance fallback for anti-cheat games
local function getPlayerCharacter(player)
    if not player then return nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then return char end
    end
    if getnilinstances then
        for _, v in ipairs(getnilinstances()) do
            if v.ClassName == "Model" and v.Name == player.Name then
                local hum = v:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then return v end
            end
        end
    end
    return char
end

-- ================================================================
--  MAIN TAB – Speed Boost, NoClip, Fly
-- ================================================================
do
    local boostConnection = nil
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
        Callback = function(Value)
            currentSpeed = Value
            if Options.SpeedBoostToggle and Options.SpeedBoostToggle.Value and currentMode == "WalkSpeed" then
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = Value end
            end
        end
    })

    Tabs.Main:AddToggle("SpeedBoostToggle", {
        Title = "Speed Boost", Default = false
    }):OnChanged(function()
        local enabled = Options.SpeedBoostToggle.Value
        if boostConnection then boostConnection:Disconnect(); boostConnection = nil end
        if enabled then
            if currentMode == "WalkSpeed" then
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = currentSpeed end
                boostConnection = LocalPlayer.CharacterAdded:Connect(function(c)
                    if Options.SpeedBoostToggle.Value then
                        c:WaitForChild("Humanoid").WalkSpeed = Options.SpeedValue.Value
                    end
                end)
            elseif currentMode == "Velocity" then
                boostConnection = RunService.Heartbeat:Connect(function()
                    local root = getRootPart()
                    if root then root.AssemblyLinearVelocity = root.CFrame.LookVector * Options.SpeedValue.Value end
                end)
            elseif currentMode == "CFrame" then
                boostConnection = RunService.Heartbeat:Connect(function()
                    local root = getRootPart()
                    if root then root.CFrame = root.CFrame * CFrame.new(0, 0, -(Options.SpeedValue.Value * 0.05)) end
                end)
            end
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

    local function setupNoClipGroup()
        if ncGroupCreated then return end
        pcall(function()
            PhysicsService:RegisterCollisionGroup(NC_GROUP)
            PhysicsService:CollisionGroupSetCollidable(NC_GROUP, NC_DEFAULT, false)
            PhysicsService:CollisionGroupSetCollidable(NC_GROUP, NC_GROUP, true)
        end); ncGroupCreated = true
    end
    local function setCharGroup(char, group)
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CollisionGroup = group end) end
        end
    end

    Tabs.Main:AddToggle("NoClipToggle", {
        Title = "No Clip", Default = false
    }):OnChanged(function()
        if Options.NoClipToggle.Value then
            setupNoClipGroup(); setCharGroup(LocalPlayer.Character, NC_GROUP)
            noclipConn = LocalPlayer.CharacterAdded:Connect(function(c)
                if Options.NoClipToggle.Value then task.wait(); setCharGroup(c, NC_GROUP) end
            end)
            Fluent:Notify({ Title = "No Clip", Content = "Enabled!", Duration = 3 })
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            setCharGroup(LocalPlayer.Character, NC_DEFAULT)
            Fluent:Notify({ Title = "No Clip", Content = "Disabled.", Duration = 3 })
        end
    end)

    -- ────── Fly ──────────────────────────────────────────────────

    Tabs.Main:AddSlider("FlySpeed", { Title = "Fly Speed", Default = 50, Min = 5, Max = 300, Rounding = 0, Callback = function(_) end })

    local function startFly()
        local root = getRootPart(); if not root then return end
        local hum = getHumanoid(); if hum then hum.PlatformStand = true end
        flyAttach = Instance.new("Attachment"); flyAttach.Name = "_FlyAtt"; flyAttach.Parent = root
        flyLV = Instance.new("LinearVelocity"); flyLV.Name = "_FlyLV"; flyLV.Attachment0 = flyAttach
        flyLV.MaxForce = 1e5; flyLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        flyLV.VectorVelocity = Vector3.zero; flyLV.RelativeTo = Enum.ActuatorRelativeTo.World; flyLV.Parent = root
        flyAO = Instance.new("AlignOrientation"); flyAO.Name = "_FlyAO"; flyAO.Attachment0 = flyAttach
        flyAO.Mode = Enum.OrientationAlignmentMode.OneAttachment; flyAO.MaxTorque = 1e5
        flyAO.MaxAngularVelocity = math.huge; flyAO.Responsiveness = 50; flyAO.CFrame = root.CFrame; flyAO.Parent = root
    end
    local function stopFly()
        local hum = getHumanoid(); if hum then hum.PlatformStand = false end
        for _, n in ipairs({"_FlyAtt","_FlyLV","_FlyAO"}) do
            local root = getRootPart(); local o = root and root:FindFirstChild(n)
            if o then o:Destroy() end
        end
        flyLV = nil; flyAO = nil; flyAttach = nil
        if flyConn then flyConn:Disconnect(); flyConn = nil end
    end

    Tabs.Main:AddToggle("FlyToggle", { Title = "Fly", Default = false }):OnChanged(function()
        if Options.FlyToggle.Value then
            startFly()
            flyConn = RunService.RenderStepped:Connect(function()
                Camera = workspace.CurrentCamera or Camera
                local root = getRootPart(); if not root then return end
                local hum2 = getHumanoid()
                if hum2 then hum2.PlatformStand = true end
                local dir = Vector3.zero
                local cf = Camera.CFrame
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
                local speed = Options.FlySpeed.Value
                local v = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
                local lv = root:FindFirstChild("_FlyLV")
                local ao = root:FindFirstChild("_FlyAO")
                if lv then lv.VectorVelocity = v end
                if ao and dir.Magnitude > 0 then ao.CFrame = CFrame.lookAt(Vector3.zero, dir) end
            end)
            Fluent:Notify({ Title = "Fly", Content = "Enabled! (LinearVelocity)", Duration = 3 })
        else
            stopFly()
            local hum = getHumanoid()
            if hum then hum.AutoRotate = true; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            Fluent:Notify({ Title = "Fly", Content = "Disabled.", Duration = 3 })
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        Options.FlyToggle:SetValue(false)
        Options.NoClipToggle:SetValue(false)
    end)
end

-- ================================================================
--  ESP TAB – Ported from 28th6 Hub (LinoriaLib)
-- ================================================================
do
    -- ── Settings ─────────────────────────────────────────────────
    local S = {
        Enabled   = false,
        Boxes     = true,
        Names     = true,
        Distance  = true,
        Health    = true,
        Tracers   = true,
        Chams     = true,
        Skeleton  = false,
        Weapon    = false,
        TeamCheck = true,
        EnemyColor = Color3.fromRGB(255, 50, 50),
        MaxDist   = 1000,
    }

    -- ── ESP Cache (char → drawings table) ────────────────────────
    local ESP_Cache  = {}
    local lastScanT  = 0

    -- ── Team check ───────────────────────────────────────────────
    local function isSameTeam(player)
        if not S.TeamCheck then return false end
        if LocalPlayer.Team and player.Team then
            return LocalPlayer.Team == player.Team
        end
        return false
    end

    -- ── Skeleton helper ──────────────────────────────────────────
    local function newSkelLine()
        local ln = Drawing.new("Line")
        ln.Color = S.EnemyColor; ln.Thickness = 1.5
        ln.Visible = false; ln.ZIndex = 2
        return ln
    end

    local function skelPoint(char, partName)
        local part = char and char:FindFirstChild(partName)
        if not part or not part:IsA("BasePart") then return nil end
        local p, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen or p.Z <= 0 then return nil end
        return Vector2.new(p.X, p.Y)
    end

    local function setSkelLine(ln, from, to)
        if ln and from and to then ln.From = from; ln.To = to; ln.Visible = true
        elseif ln then ln.Visible = false end
    end

    local function hideSkelLines(skel)
        if not skel then return end
        for _, ln in pairs(skel) do if ln then ln.Visible = false end end
    end

    local function updateSkeleton(char, esp)
        if not esp or not esp.Skel then return end
        if not S.Skeleton then hideSkelLines(esp.Skel); return end

        local myRoot = getRootPart()
        local tRoot  = char and char:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude > S.MaxDist then
            hideSkelLines(esp.Skel); return
        end

        local head        = skelPoint(char, "Head")
        local upTorso     = skelPoint(char, "UpperTorso") or skelPoint(char, "Torso")
        local loTorso     = skelPoint(char, "LowerTorso") or upTorso
        local lUA         = skelPoint(char, "LeftUpperArm")  or skelPoint(char, "Left Arm")
        local lLA         = skelPoint(char, "LeftLowerArm")
        local lH          = skelPoint(char, "LeftHand")
        local rUA         = skelPoint(char, "RightUpperArm") or skelPoint(char, "Right Arm")
        local rLA         = skelPoint(char, "RightLowerArm")
        local rH          = skelPoint(char, "RightHand")
        local lUL         = skelPoint(char, "LeftUpperLeg")  or skelPoint(char, "Left Leg")
        local lLL         = skelPoint(char, "LeftLowerLeg")
        local lF          = skelPoint(char, "LeftFoot")
        local rUL         = skelPoint(char, "RightUpperLeg") or skelPoint(char, "Right Leg")
        local rLL         = skelPoint(char, "RightLowerLeg")
        local rF          = skelPoint(char, "RightFoot")

        if not head or not upTorso then hideSkelLines(esp.Skel); return end
        local neck = Vector2.new((head.X + upTorso.X) / 2, (head.Y + upTorso.Y) / 2)

        local sk = esp.Skel
        setSkelLine(sk.H2T,  head,   neck)
        setSkelLine(sk.U2L,  upTorso, loTorso)
        setSkelLine(sk.LUA,  upTorso, lUA)
        setSkelLine(sk.LLA,  lUA,    lLA or lH)
        setSkelLine(sk.LH,   lLA,    lH)
        setSkelLine(sk.RUA,  upTorso, rUA)
        setSkelLine(sk.RLA,  rUA,    rLA or rH)
        setSkelLine(sk.RH,   rLA,    rH)
        setSkelLine(sk.LULg, loTorso, lUL)
        setSkelLine(sk.LLL,  lUL,    lLL or lF)
        setSkelLine(sk.LF,   lLL,    lF)
        setSkelLine(sk.RULg, loTorso, rUL)
        setSkelLine(sk.RLL,  rUL,    rLL or rF)
        setSkelLine(sk.RF,   rLL,    rF)
    end

    -- ── Create ESP for a character ────────────────────────────────
    local function CreateESP(char)
        if ESP_Cache[char] then return end

        local e = {}

        -- Box + outline
        e.Box           = Drawing.new("Square")
        e.Box.Filled    = false; e.Box.ZIndex = 2; e.Box.Thickness = 1
        e.Box.Color     = S.EnemyColor

        e.BoxOut        = Drawing.new("Square")
        e.BoxOut.Filled = false; e.BoxOut.ZIndex = 1; e.BoxOut.Thickness = 3
        e.BoxOut.Color  = Color3.new(0,0,0)

        -- Health bar + outline
        e.HPOut           = Drawing.new("Square")
        e.HPOut.Filled    = true; e.HPOut.ZIndex = 1; e.HPOut.Thickness = 1
        e.HPOut.Color     = Color3.new(0,0,0)

        e.HP              = Drawing.new("Square")
        e.HP.Filled       = true; e.HP.ZIndex = 2; e.HP.Thickness = 1
        e.HP.Color        = Color3.new(0,1,0)

        -- Name
        e.Name            = Drawing.new("Text")
        e.Name.Size       = 16; e.Name.Center = true
        e.Name.Outline    = true; e.Name.ZIndex = 3
        e.Name.Color      = Color3.new(1,1,1)

        -- Distance
        e.Dist            = Drawing.new("Text")
        e.Dist.Size       = 14; e.Dist.Center = true
        e.Dist.Outline    = true; e.Dist.ZIndex = 3
        e.Dist.Color      = Color3.new(1,1,1)

        -- Weapon
        e.Weapon          = Drawing.new("Text")
        e.Weapon.Size     = 14; e.Weapon.Center = true
        e.Weapon.Outline  = true; e.Weapon.ZIndex = 3
        e.Weapon.Color    = Color3.new(1,1,1)

        -- Tracer
        e.Tracer          = Drawing.new("Line")
        e.Tracer.Thickness= 1; e.Tracer.ZIndex = 1
        e.Tracer.Color    = S.EnemyColor

        -- Highlight (Chams – Instance, not Drawing)
        e.Highlight       = nil

        -- Skeleton lines
        e.Skel = {
            H2T  = newSkelLine(), U2L  = newSkelLine(),
            LUA  = newSkelLine(), LLA  = newSkelLine(), LH   = newSkelLine(),
            RUA  = newSkelLine(), RLA  = newSkelLine(), RH   = newSkelLine(),
            LULg = newSkelLine(), LLL  = newSkelLine(), LF   = newSkelLine(),
            RULg = newSkelLine(), RLL  = newSkelLine(), RF   = newSkelLine(),
        }

        -- All invisible by default
        for _, v in pairs(e) do
            if type(v) == "userdata" and v ~= e.Skel then
                pcall(function() v.Visible = false end)
            end
        end

        ESP_Cache[char] = e
    end

    local function RemoveESP(char)
        local e = ESP_Cache[char]
        if not e then return end
        for k, v in pairs(e) do
            if k == "Highlight" and v then
                pcall(function() v:Destroy() end)
            elseif k == "Skel" and type(v) == "table" then
                for _, ln in pairs(v) do
                    pcall(function() ln.Visible = false; ln:Remove() end)
                end
            elseif type(v) == "userdata" then
                pcall(function() v.Visible = false; v:Remove() end)
            end
        end
        ESP_Cache[char] = nil
    end

    local function hideAll(e)
        e.Box.Visible = false; e.BoxOut.Visible = false
        e.HP.Visible  = false; e.HPOut.Visible  = false
        e.Name.Visible = false; e.Dist.Visible = false
        e.Weapon.Visible = false; e.Tracer.Visible = false
        hideSkelLines(e.Skel)
        if e.Highlight then e.Highlight:Destroy(); e.Highlight = nil end
    end

    -- ── Cleanup when model removed ────────────────────────────────
    workspace.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Model") and ESP_Cache[desc] then RemoveESP(desc) end
    end)

    -- ── Main render loop ─────────────────────────────────────────
    RunService.RenderStepped:Connect(function()
        Camera = workspace.CurrentCamera or Camera
        if not Camera then return end

        -- Scan new characters every 0.5s
        -- FIX: Use Players:GetPlayers() instead of workspace:GetChildren()
        -- so characters inside subfolders are never missed
        local now = tick()
        if now - lastScanT > 0.5 then
            lastScanT = now
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if player ~= LocalPlayer and char then
                    local hum  = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root
                        and hum:GetState() ~= Enum.HumanoidStateType.Dead
                        and not ESP_Cache[char]
                    then
                        CreateESP(char)
                    end
                end
            end

            -- Remove dead/gone
            for char in pairs(ESP_Cache) do
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not char.Parent
                    or not hum
                    or hum.Health <= 0
                    or hum:GetState() == Enum.HumanoidStateType.Dead
                then
                    RemoveESP(char)
                end
            end
        end

        -- Update each cached character
        for char, e in pairs(ESP_Cache) do
            if char:IsA("Model") and char ~= LocalPlayer.Character then
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")

                if not hum or not root or not head or hum.Health <= 0
                    or hum:GetState() == Enum.HumanoidStateType.Dead
                then
                    hideAll(e)
                else
                    -- Team check
                    local plr = Players:GetPlayerFromCharacter(char)
                    local isTeammate = plr and isSameTeam(plr) or false

                    -- Distance check
                    local myRoot = getRootPart()
                    local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0

                    if not S.Enabled or isTeammate or dist > S.MaxDist then
                        hideAll(e); 
                    else
                        -- Project to screen
                        local rootP, onScreen = Camera:WorldToViewportPoint(root.Position)
                        local headP           = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local legP            = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                        if not onScreen or rootP.Z <= 0 then
                            hideAll(e)
                        else
                            local height = math.max(math.abs(headP.Y - legP.Y), 1)
                            local width  = math.max(height / 2, 1)
                            local bX     = rootP.X - width  / 2
                            local bY     = rootP.Y - height / 2

                            -- Box
                            if S.Boxes then
                                e.Box.Size = Vector2.new(width, height)
                                e.Box.Position = Vector2.new(bX, bY)
                                e.Box.Color = S.EnemyColor
                                e.Box.Visible = true
                                e.BoxOut.Size = e.Box.Size
                                e.BoxOut.Position = e.Box.Position
                                e.BoxOut.Visible = true
                            else
                                e.Box.Visible = false; e.BoxOut.Visible = false
                            end

                            -- Health bar (left side)
                            if S.Health then
                                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                                local barH = height * pct
                                e.HPOut.Size     = Vector2.new(4, height + 2)
                                e.HPOut.Position = Vector2.new(bX - 6, bY - 1)
                                e.HPOut.Visible  = true
                                e.HP.Size        = Vector2.new(2, math.max(barH, 1))
                                e.HP.Position    = Vector2.new(bX - 5, bY + height - barH)
                                e.HP.Color       = Color3.fromHSV(pct * 0.3, 1, 1)
                                e.HP.Visible     = true
                            else
                                e.HP.Visible = false; e.HPOut.Visible = false
                            end

                            -- Name
                            if S.Names then
                                e.Name.Text     = plr and plr.Name or ("[Bot] " .. char.Name)
                                e.Name.Position = Vector2.new(rootP.X, bY - 18)
                                e.Name.Visible  = true
                            else
                                e.Name.Visible = false
                            end

                            -- Distance
                            if S.Distance then
                                e.Dist.Text     = "[" .. math.floor(dist) .. "m]"
                                e.Dist.Position = Vector2.new(rootP.X, bY + height + 2)
                                e.Dist.Visible  = true
                            else
                                e.Dist.Visible = false
                            end

                            -- Weapon
                            if S.Weapon then
                                local tool = char:FindFirstChildOfClass("Tool")
                                if tool then
                                    local yOffset = bY + height + (S.Distance and 18 or 2)
                                    e.Weapon.Text     = tool.Name
                                    e.Weapon.Position = Vector2.new(rootP.X, yOffset)
                                    e.Weapon.Visible  = true
                                else
                                    e.Weapon.Visible = false
                                end
                            else
                                e.Weapon.Visible = false
                            end

                            -- Tracer (from bottom center of screen)
                            if S.Tracers then
                                e.Tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                e.Tracer.To      = Vector2.new(rootP.X, rootP.Y + height / 2)
                                e.Tracer.Color   = S.EnemyColor
                                e.Tracer.Visible = true
                            else
                                e.Tracer.Visible = false
                            end

                            -- Skeleton
                            updateSkeleton(char, e)

                            -- Chams (Highlight instance)
                            if S.Chams then
                                if not e.Highlight or not e.Highlight.Parent then
                                    if e.Highlight then pcall(function() e.Highlight:Destroy() end) end
                                    local hl = Instance.new("Highlight")
                                    hl.Name = "ESPCham"
                                    hl.FillTransparency    = 0.5
                                    hl.OutlineTransparency = 0
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    hl.Parent = char
                                    e.Highlight = hl
                                end
                                e.Highlight.FillColor    = S.EnemyColor
                                e.Highlight.OutlineColor = Color3.new(1,1,1)
                            else
                                if e.Highlight then pcall(function() e.Highlight:Destroy() end); e.Highlight = nil end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ── UI Controls ──────────────────────────────────────────────

    Tabs.ESP:AddToggle("ESPMaster",   { Title = "Enable ESP",             Default = false }):OnChanged(function() S.Enabled   = Options.ESPMaster.Value   end)
    Tabs.ESP:AddToggle("ESPBoxes",    { Title = "Show Boxes",             Default = true  }):OnChanged(function() S.Boxes     = Options.ESPBoxes.Value    end)
    Tabs.ESP:AddToggle("ESPNames",    { Title = "Show Names",             Default = true  }):OnChanged(function() S.Names     = Options.ESPNames.Value    end)
    Tabs.ESP:AddToggle("ESPDist",     { Title = "Show Distance",          Default = true  }):OnChanged(function() S.Distance  = Options.ESPDist.Value     end)
    Tabs.ESP:AddToggle("ESPHealth",   { Title = "Show Health Bar",        Default = true  }):OnChanged(function() S.Health    = Options.ESPHealth.Value   end)
    Tabs.ESP:AddToggle("ESPTracers",  { Title = "Show Tracers",           Default = true  }):OnChanged(function() S.Tracers   = Options.ESPTracers.Value  end)
    Tabs.ESP:AddToggle("ESPChams",    { Title = "Show Chams",             Default = false }):OnChanged(function() S.Chams     = Options.ESPChams.Value    end)
    Tabs.ESP:AddToggle("ESPSkeleton", { Title = "Show Skeleton",          Default = false }):OnChanged(function() S.Skeleton  = Options.ESPSkeleton.Value end)
    Tabs.ESP:AddToggle("ESPWeapon",   { Title = "Show Weapon Name",       Default = false }):OnChanged(function() S.Weapon    = Options.ESPWeapon.Value   end)

    Tabs.ESP:AddSlider("ESPMaxDist", {
        Title = "Max Distance", Default = 1000, Min = 50, Max = 5000, Rounding = 0,
        Callback = function(v) S.MaxDist = v end
    })

    Tabs.ESP:AddColorpicker("ESPEnemyColor", { Title = "Enemy Color", Default = Color3.fromRGB(255, 50, 50) }):OnChanged(function()
        S.EnemyColor = Options.ESPEnemyColor.Value
    end)

    Tabs.ESP:AddToggle("ESPTeamCheck", { Title = "Team Check", Default = true }):OnChanged(function()
        S.TeamCheck = Options.ESPTeamCheck.Value
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
        aimbotAimPart      = "Head",
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
        if not char or char == LocalPlayer.Character then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return false end
        if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
        return true
    end

    -- Get the aim part on the target character
    local function getAimPart(char)
        if not isValidTarget(char) then return nil end
        local part = char:FindFirstChild(CS.aimbotAimPart)
        if part and part:IsA("BasePart") then return part end
        -- fallback
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

    AimbotGroup:AddDropdown("AimbotAimPart", {
        Title = "Aim Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso", "Torso"},
        Multi = false, Default = "Head"
    }):OnChanged(function(v)
        CS.aimbotAimPart = v
        CS.aimbotTarget  = nil   -- reset so a new target is selected
    end)

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
    local function restoreValues(obj)
        if not obj or not patchedValues[obj] then return end
        for key, original in pairs(patchedValues[obj]) do
            pcall(function() obj[key] = original end)
        end
        patchedValues[obj] = nil
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
                                        rememberValue(desc, k)
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
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then restoreValues(tool) end
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
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then restoreValues(tool) end
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
            "Crossbow (Game 7)"
        },
        Multi = false, Default = "WeaponHit (Game 1)"
    }):OnChanged(function(v) CS.killAuraMethod = v end)

    KillAuraGroup:AddSlider("KillAuraRadius", {
        Title = "Aura Range", Default = 150, Min = 10, Max = 500, Rounding = 0
    }):OnChanged(function() CS.killAuraRadius = Options.KillAuraRadius.Value end)

    KillAuraGroup:AddSlider("KillAuraDelay", {
        Title = "Attack Delay (ms)", Default = 10, Min = 1, Max = 100, Rounding = 0
    }):OnChanged(function() CS.killAuraDelay = Options.KillAuraDelay.Value / 100 end)

    KillAuraGroup:AddDropdown("KillAuraPart", {
        Title = "Target Part",
        Values = { "Head", "UpperTorso", "Torso", "HumanoidRootPart" },
        Multi = false, Default = "Head"
    }):OnChanged(function(v) CS.killAuraPart = v end)

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
                if pChar then
                    local tRoot = pChar:FindFirstChild("HumanoidRootPart")
                    local tHum  = pChar:FindFirstChildOfClass("Humanoid")
                    if tRoot and tHum and tHum.Health > 0 then
                        local dist = (myRoot.Position - tRoot.Position).Magnitude
                        if dist <= CS.killAuraRadius then
                            local targetPart = pChar:FindFirstChild(CS.killAuraPart) or tRoot
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
        end

        for _, t in ipairs(targets) do
            local targetPart = t.targetPart
            pcall(function()
                local RS = game:GetService("ReplicatedStorage")
                local dir = (targetPart.Position - myRoot.Position).Unit

                if CS.killAuraMethod == "WeaponHit (Game 1)" then
                    local eventos = RS:WaitForChild("Eventos", 1)
                    if not eventos then return end
                    local weaponFired = eventos:WaitForChild("WeaponFired", 1)
                    local weaponHit   = eventos:WaitForChild("WeaponHit", 1)
                    if not weaponFired or not weaponHit then return end
                    local sid = math.random(1, 10)
                    weaponFired:FireServer(weapon, { id=sid, charge=0, origin=myRoot.Position, dir=dir })
                    weaponHit:FireServer(weapon, {
                        p=targetPart.Position, pid=1, part=targetPart,
                        d=t.distance, maxDist=t.distance+1, h=t.humanoid,
                        m=Enum.Material.Plastic, n=Vector3.yAxis, t=0.1, sid=sid
                    })

                elseif CS.killAuraMethod == "RequestActionSync (Game 2)" then
                    local sysRes  = RS:WaitForChild("SystemResources", 1)
                    local bufCache= sysRes and sysRes:WaitForChild("BufferCache", 1)
                    local ras     = bufCache and bufCache:WaitForChild("RequestActionSync", 1)
                    local events  = RS:WaitForChild("Events", 1)
                    local rEvts   = events and events:WaitForChild("RemoteEvents", 1)
                    local fakeBullet = rEvts and rEvts:WaitForChild("ReplicateFakeBullet", 1)
                    local muzzle     = rEvts and rEvts:WaitForChild("CharacterMuzzleFlash", 1)
                    if not ras then return end
                    ras:FireServer({
                        direction=dir, hitPosition=targetPart.Position,
                        origin=myRoot.Position, hitInstance=targetPart,
                        hitHumanoid=t.humanoid,
                        IsHeadshot = (CS.killAuraPart == "Head")
                    })
                    if fakeBullet then fakeBullet:FireServer(CFrame.new(myRoot.Position, targetPart.Position), dir) end
                    if muzzle     then muzzle:FireServer() end

                elseif CS.killAuraMethod == "GunRemote (Game 3)" then
                    local remotes   = RS:WaitForChild("Remotes", 1)
                    local gunRemote = remotes and remotes:WaitForChild("GunRemote", 1)
                    if not gunRemote then return end
                    gunRemote:FireServer(1, weapon, targetPart.Position, Vector3.yAxis, targetPart)

                elseif CS.killAuraMethod == "WeaponsSystem (Game 4)" then
                    local ws  = RS:WaitForChild("WeaponsSystem", 1)
                    local net = ws and ws:WaitForChild("Network", 1)
                    local wFired = net and net:WaitForChild("WeaponFired", 1)
                    local wHit   = net and net:WaitForChild("WeaponHit", 1)
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
                        local pName = (CS.killAuraPart == "Head") and "Hitbox_Head" or "Hitbox_Torso"
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
                    local headshot = (CS.killAuraPart == "Head")
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
                end
            end)
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
end

-- ================================================================
--  SETTINGS TAB
-- ================================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({ Title = "Script Hub", Content = "Loaded successfully! ⚡", Duration = 5 })

SaveManager:LoadAutoloadConfig()
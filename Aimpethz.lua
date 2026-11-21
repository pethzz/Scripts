--[[
    Pethz Hub — v20.0 (Final Edition - Bypass Visual + R6 Support)
    Otimizado para Delta Mobile
]]

print("[Pethz Hub] Iniciando v20.0...")
if not game:IsLoaded() then game.Loaded:Wait() end

-- ============================================================
-- 0. BYPASS VISUAL (APENAS NOTIFICAÇÃO, SEM KICK)
-- ============================================================
local AntiKickVisual = true -- Apenas para exibir a notificação

-- ============================================================
-- 1. CONFIGURAÇÕES E TEMAS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local Themes = {
    ["Rosa Anime"] = Color3.fromRGB(255, 60, 120),
    ["Roxo Neon"] = Color3.fromRGB(170, 80, 255),
    ["Azul Frio"] = Color3.fromRGB(0, 191, 255),
    ["Ciano"] = Color3.fromRGB(0, 255, 204),
    ["Vermelho Sangue"] = Color3.fromRGB(220, 30, 40),
    ["Branco Puro"] = Color3.fromRGB(240, 240, 240),
    ["Dourado Real"] = Color3.fromRGB(255, 215, 0),
    ["Lilás"] = Color3.fromRGB(200, 160, 255),
    ["Lava"] = Color3.fromRGB(255, 100, 0),
    ["Matrix"] = Color3.fromRGB(0, 255, 0),
    ["RGB Gamer"] = Color3.fromRGB(255, 0, 0)
}

local CurrentTheme = "Rosa Anime"
local ThemeColor = Themes[CurrentTheme]
local ThemeColorDark = Color3.fromRGB(ThemeColor.R * 150, ThemeColor.G * 150, ThemeColor.B * 150)
local IsRGB = false

local Aim = { Enabled = false, Part = "Head", FOV = 150, ShowFOV = true, TeamCheck = true, WallCheck = true, Smooth = 0.1, Prediction = 0.15 }
local ESP = { Enabled = false, Line = false, Box = false, Health = false, Skeleton = false, Name = false, Chams = false, Pos = "Top", TeamCheck = true, Objs = {}, ChamsObjs = {} }
local Mov = { Spin = false, SpinSpeed = 15, Speed = false, SpeedVal = 16, Jump = false, JumpVal = 50, Noclip = false, Bhop = false }
local NoRecoil = false
local NoSpread = false
local AutoReload = false
local NoTexture = false
local CarFly = false
local Respawn = { Enabled = false, LastCFrame = nil }
local CameraFOV = 70

local hiddenTextures = {}
local originalMaterials = {}

-- ============================================================
-- 2. NOTIFICAÇÃO CINEMATOGRÁFICA
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "PethzNotification"
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 2147483647
notifGui.Parent = LP:WaitForChild("PlayerGui")

local function showNotification(title, text, duration, color, icon)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 70)
    frame.Position = UDim2.new(1, 300, 1, -90)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = color; stroke.Thickness = 2; stroke.Parent = frame
    
    local sideBar = Instance.new("Frame")
    sideBar.Size = UDim2.new(0, 5, 1, 0); sideBar.BackgroundColor3 = color; sideBar.BorderSizePixel = 0; sideBar.Parent = frame
    local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 5); sbCorner.Parent = sideBar
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 40, 0, 40); iconLabel.Position = UDim2.new(0, 12, 0, 15)
    iconLabel.BackgroundTransparency = 1; iconLabel.Text = icon; iconLabel.TextColor3 = color; iconLabel.Font = Enum.Font.GothamBold; iconLabel.TextSize = 24; iconLabel.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 22); titleLabel.Position = UDim2.new(0, 60, 0, 10)
    titleLabel.BackgroundTransparency = 1; titleLabel.Text = title; titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255); titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 14; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -60, 0, 20); textLabel.Position = UDim2.new(0, 60, 0, 35)
    textLabel.BackgroundTransparency = 1; textLabel.Text = text; textLabel.TextColor3 = Color3.fromRGB(180, 180, 190); textLabel.Font = Enum.Font.Gotham; textLabel.TextSize = 11; textLabel.TextXAlignment = Enum.TextXAlignment.Left; textLabel.Parent = frame
    
    TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -300, 1, -90)}):Play()
    
    task.delay(duration, function()
        local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 300, 1, -90)})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        frame:Destroy()
    end)
end

showNotification("Pethz Bypass", "Proteção Anti-Kick Ativada (Visual)", 2.5, Color3.fromRGB(0, 255, 204), "🛡️")
task.wait(2.8)
showNotification("Script Loading", "Injetando funcionalidades...", 2.5, Color3.fromRGB(170, 80, 255), "⚙️")
task.wait(2.8)
showNotification("Script By Pethz", "Hub carregado com sucesso!", 3, Color3.fromRGB(255, 60, 120), "✨")
task.wait(3.2)
notifGui:Destroy()

-- ============================================================
-- 3. UTILITÁRIOS
-- ============================================================
local function getHum(p) local c = p and p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function isAlive(p) local h = getHum(p); return h and h.Health > 0 end
local function getPart(p, n) local c = p and p.Character; return c and (c:FindFirstChild(n) or c:FindFirstChild("HumanoidRootPart")) end
local function sameTeam(p) if not Aim.TeamCheck then return false end; return p.Team and LP.Team and p.Team == LP.Team end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isVisible(part)
    if not Aim.WallCheck then return true end
    if not part then return false end
    rayParams.FilterDescendantsInstances = {LP.Character, Cam}
    local origin = Cam.CFrame.Position
    local dir = (part.Position - origin)
    local r = workspace:Raycast(origin, dir, rayParams)
    if r then return r.Instance:IsDescendantOf(part.Parent) end
    return true
end

-- ============================================================
-- 4. CAR FLY
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not CarFly then return end
    local char = LP.Character
    local hum = getHum(LP)
    if not char or not hum then return end
    local seat = hum.SeatPart
    if seat then
        local vehicle = seat.Parent
        local rootPart = vehicle:FindFirstChild("Chassis") or vehicle:FindFirstChild("Base") or vehicle:FindFirstChild("Body") or seat
        if rootPart and rootPart:IsA("BasePart") then
            local moveDir = hum.MoveDirection
            local up = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space) then up = 1 elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then up = -1 end
            if moveDir.Magnitude > 0.1 or up ~= 0 then
                local speed = 80
                local targetPos = rootPart.Position + (moveDir * speed * dt) + Vector3.new(0, up * speed * dt, 0)
                local targetCFrame = CFrame.new(targetPos, targetPos + Cam.CFrame.LookVector)
                rootPart.CFrame = rootPart.CFrame:Lerp(targetCFrame, 0.3)
                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

-- ============================================================
-- 5. NO TEXTURE
-- ============================================================
local function toggleTextures(remove)
    if remove then
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                local isPlayerPart = false
                local parent = obj.Parent
                while parent do
                    if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then isPlayerPart = true; break end
                    parent = parent.Parent
                end
                if not isPlayerPart then
                    if obj:IsA("BasePart") then
                        if not originalMaterials[obj] then originalMaterials[obj] = { Material = obj.Material, Color = obj.Color } end
                        pcall(function() obj.Material = Enum.Material.SmoothPlastic; obj.Color = Color3.fromRGB(200, 200, 200) end)
                    end
                    if obj:IsA("Decal") or obj:IsA("Texture") then
                        if not hiddenTextures[obj] then hiddenTextures[obj] = { Transparency = obj.Transparency } end
                        pcall(function() obj.Transparency = 1 end)
                    end
                end
                task.wait(0.005)
            end
        end)
    else
        task.spawn(function()
            for obj, data in pairs(originalMaterials) do
                if obj and obj.Parent then pcall(function() obj.Material = data.Material; obj.Color = data.Color end) end
                task.wait(0.005)
            end
            originalMaterials = {}
            for obj, data in pairs(hiddenTextures) do
                if obj and obj.Parent then pcall(function() obj.Transparency = data.Transparency end) end
                task.wait(0.005)
            end
            hiddenTextures = {}
        end)
    end
end

-- ============================================================
-- 6. SISTEMAS
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not AutoReload then return end
    local char = LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, v in pairs(tool:GetDescendants()) do
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            local name = v.Name:lower()
            if name:find("ammo") or name:find("clip") then
                if v.Value <= 0 then
                    pcall(function()
                        if tool:FindFirstChild("Reload") then tool.Reload:FireServer()
                        elseif tool:FindFirstChild("ReloadEvent") then tool.ReloadEvent:FireServer()
                        else
                            local VirtualInputManager = game:GetService("VirtualInputManager")
                            VirtualInputManager:SendKeyEvent(true, "R", false, game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false, "R", false, game)
                        end
                    end)
                    task.wait(0.5)
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if NoSpread then
        local char = LP.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                for _, v in pairs(tool:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        local name = v.Name:lower()
                        if name:find("spread") or name:find("accuracy") or name:find("recoil") then pcall(function() v.Value = 0 end) end
                    end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Cam and Cam.FieldOfView ~= CameraFOV then Cam.FieldOfView = CameraFOV end
end)

RunService.RenderStepped:Connect(function()
    if NoRecoil and not Aim.Enabled then
        local currentLook = Cam.CFrame.LookVector
        if currentLook.Y > 0.01 then
            local newCFrame = CFrame.new(Cam.CFrame.Position) * CFrame.Angles(0, math.atan2(-currentLook.X, -currentLook.Z), 0) * CFrame.Angles(math.asin(currentLook.Y) - 0.01, 0, 0)
            Cam.CFrame = newCFrame
        end
    end
end)

local bhopCooldown = false
RunService.Heartbeat:Connect(function()
    if not Mov.Bhop then return end
    local char = LP.Character
    local hum = getHum(LP)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 and not bhopCooldown then
            bhopCooldown = true
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 50, root.AssemblyLinearVelocity.Z)
            if hum.WalkSpeed < 35 then hum.WalkSpeed = 35 end
            task.wait(0.2)
            bhopCooldown = false
        end
    end
end)

local function checkBhop()
    local hum = getHum(LP)
    if not hum then return end
    if not Mov.Bhop and not Mov.Speed then hum.WalkSpeed = 16 end
end

local function setupRespawn()
    local char = LP.Character
    if not char then return end
    local hum = getHum(LP)
    if not hum then return end
    hum.Died:Connect(function()
        if Respawn.Enabled and char and char:FindFirstChild("HumanoidRootPart") then Respawn.LastCFrame = char.HumanoidRootPart.CFrame end
    end)
end
setupRespawn()
LP.CharacterAdded:Connect(function()
    task.wait(0.5); setupRespawn()
    if Respawn.Enabled and Respawn.LastCFrame then
        task.wait(0.2)
        local char = LP.Character
        if char and char:FindFirstChild("HumanoidRootPart") then char.HumanoidRootPart.CFrame = Respawn.LastCFrame; Respawn.LastCFrame = nil end
    end
end)

-- ============================================================
-- 7. AIMBOT
-- ============================================================
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 2; fovCircle.NumSides = 48; fovCircle.Filled = false; fovCircle.Visible = false
end)

local function getTarget()
    local best, bestD = nil, math.huge
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isAlive(p) and not sameTeam(p) then
            local part = getPart(p, Aim.Part)
            if part and isVisible(part) then
                local sp, on = Cam:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= Aim.FOV / 2 and d < bestD then bestD = d; best = p end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
        fovCircle.Radius = Aim.FOV / 2; fovCircle.Color = ThemeColor; fovCircle.Visible = Aim.Enabled and Aim.ShowFOV
    end
    if not Aim.Enabled then return end
    local target = getTarget()
    if target then
        local part = getPart(target, Aim.Part)
        if part then
            local predictedPos = part.Position + (part.AssemblyLinearVelocity * Aim.Prediction)
            local targetCF = CFrame.new(Cam.CFrame.Position, predictedPos)
            if Aim.Smooth > 0 then Cam.CFrame = Cam.CFrame:Lerp(targetCF, 1 - Aim.Smooth) else Cam.CFrame = targetCF end
        end
    end
end)

-- ============================================================
-- 8. ESP E CHAMS (SUPORTE R6/R15 + FUNDO NO NAME)
-- ============================================================
local function mk(kind) if not Drawing or not Drawing.new then return nil end; local o; pcall(function() o = Drawing.new(kind) end); return o end

-- Pares de ossos para R15
local BONES_R15 = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}}
-- Pares de ossos para R6
local BONES_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function createESP(p)
    if p == LP then return end
    if not ESP.Objs[p] then
        local o = {}
        o.BT, o.BB, o.BL, o.BR = mk("Line"), mk("Line"), mk("Line"), mk("Line")
        o.Name = mk("Text"); if o.Name then o.Name.Size=13; o.Name.Center=true; o.Name.Outline=true end
        o.HBg = mk("Line"); if o.HBg then o.HBg.Color=Color3.fromRGB(30,30,30); o.HBg.Thickness=4 end
        o.HBar = mk("Line"); if o.HBar then o.HBar.Thickness=4 end
        o.Snap = mk("Line"); if o.Snap then o.Snap.Thickness=1.5 end
        o.Skel = {}
        -- Cria 10 linhas fixas pro Esqueleto (máximo do R15). No R6 a gente usa só as 5 primeiras.
        for i=1,#BONES_R15 do local l = mk("Line"); if l then l.Thickness = 1 end; o.Skel[i] = l end
        ESP.Objs[p] = o
    end
    if not ESP.ChamsObjs[p] then
        local hl = Instance.new("Highlight")
        hl.Name = "PethzChams"; hl.FillTransparency = 0.4; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = p.Character
        ESP.ChamsObjs[p] = hl
    end
end

local function hideAll(o)
    for _, v in pairs(o) do
        if type(v)=="table" then for _, s in pairs(v) do if s then pcall(function() s.Visible=false end) end end
        elseif v then pcall(function() v.Visible=false end) end
    end
end

local function renderESP()
    if not ESP.Enabled then for _, o in pairs(ESP.Objs) do hideAll(o) end; for _, hl in pairs(ESP.ChamsObjs) do hl.Enabled = false end; return end
    for p, o in pairs(ESP.Objs) do
        local isTeam = ESP.TeamCheck and p.Team and LP.Team and p.Team == LP.Team
        if p == LP or not isAlive(p) or isTeam then hideAll(o); if ESP.ChamsObjs[p] then ESP.ChamsObjs[p].Enabled = false end
        else
            if ESP.ChamsObjs[p] then ESP.ChamsObjs[p].Enabled = ESP.Chams; ESP.ChamsObjs[p].FillColor = ThemeColor; ESP.ChamsObjs[p].OutlineColor = Color3.fromRGB(255, 255, 255) end
            local c = p.Character
            local head, root, hum = c and c:FindFirstChild("Head"), c and c:FindFirstChild("HumanoidRootPart"), getHum(p)
            if not (head and root and hum) then hideAll(o)
            else
                local hs, hon = Cam:WorldToViewportPoint(head.Position)
                local rs, ron = Cam:WorldToViewportPoint(root.Position)
                if not (hon and ron) then hideAll(o)
                else
                    local hp, rp = Vector2.new(hs.X, hs.Y), Vector2.new(rs.X, rs.Y)
                    local height = (hp - rp).Magnitude * 1.6
                    local width = height * 0.45
                    local top, bot = hp.Y - height*0.3, rp.Y + height*0.3
                    local lft, rgt = rp.X - width/2, rp.X + width/2
                    
                    -- BOX
                    if ESP.Box and o.BT then
                        o.BT.Color = ThemeColor; o.BB.Color = ThemeColor; o.BL.Color = ThemeColor; o.BR.Color = ThemeColor
                        o.BT.From=Vector2.new(lft,top); o.BT.To=Vector2.new(rgt,top)
                        o.BB.From=Vector2.new(lft,bot); o.BB.To=Vector2.new(rgt,bot)
                        o.BL.From=Vector2.new(lft,top); o.BL.To=Vector2.new(lft,bot)
                        o.BR.From=Vector2.new(rgt,top); o.BR.To=Vector2.new(rgt,bot)
                        for _, l in pairs({o.BT,o.BB,o.BL,o.BR}) do l.Visible=true end
                    else for _, l in pairs({o.BT,o.BB,o.BL,o.BR}) do if l then l.Visible=false end end end
                    
                    -- NAME (Co

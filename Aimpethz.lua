--[[
    Pethz Aim — Painel Roblox
    Biblioteca: Rayfield
    Tema: Escuro (#111214) + Roxo Neon (#9b59b6)
    Abas: AIM | ESP | PLAYER/MISC
    Compatível: Delta, Arceus X, Fluxus, etc.
]]

-- ============================================================
-- 1. CARREGAMENTO DA BIBLIOTECA RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- 2. TEMA CUSTOMIZADO (ROXO / ESCURO)
-- ============================================================
local PethzTheme = {
    TextColor = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(17, 18, 20),        -- #111214
    Topbar = Color3.fromRGB(17, 18, 20),
    Shadow = Color3.fromRGB(80, 40, 120),
    NotificationBackground = Color3.fromRGB(17, 18, 20),
    NotificationActionsBackground = Color3.fromRGB(155, 89, 182),
    TabBackground = Color3.fromRGB(25, 26, 30),
    TabStroke = Color3.fromRGB(60, 40, 80),
    TabBackgroundSelected = Color3.fromRGB(155, 89, 182),
    TabTextColor = Color3.fromRGB(180, 180, 180),
    SelectedTabTextColor = Color3.fromRGB(255, 255, 255),
    ElementBackground = Color3.fromRGB(25, 26, 30),
    ElementBackgroundHover = Color3.fromRGB(45, 30, 60),
    SecondaryElementBackground = Color3.fromRGB(20, 21, 25),
    ElementStroke = Color3.fromRGB(155, 89, 182),
    SecondaryElementStroke = Color3.fromRGB(100, 60, 130),
    SliderBackground = Color3.fromRGB(40, 40, 45),
    SliderProgress = Color3.fromRGB(155, 89, 182),
    SliderStroke = Color3.fromRGB(155, 89, 182),
    ToggleBackground = Color3.fromRGB(40, 40, 45),
    ToggleEnabled = Color3.fromRGB(155, 89, 182),
    ToggleDisabled = Color3.fromRGB(80, 80, 80),
    ToggleEnabledStroke = Color3.fromRGB(180, 120, 210),
    ToggleDisabledStroke = Color3.fromRGB(80, 80, 80),
    ToggleEnabledOuterStroke = Color3.fromRGB(200, 150, 230),
    ToggleDisabledOuterStroke = Color3.fromRGB(100, 100, 100),
    DropdownSelected = Color3.fromRGB(155, 89, 182),
    DropdownUnselected = Color3.fromRGB(40, 40, 45),
    InputBackground = Color3.fromRGB(25, 26, 30),
    InputStroke = Color3.fromRGB(155, 89, 182),
    PlaceholderColor = Color3.fromRGB(120, 120, 120),
}

-- ============================================================
-- 3. SERVIÇOS E VARIÁVEIS GLOBAIS
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Estado do Aimbot
local AimState = {
    Enabled = false,
    TargetPart = "Head",      -- "Head" ou "HumanoidRootPart"
    FOV = 120,
    Smoothing = 0.25,         -- 0 = instantâneo, 1 = muito suave
    CurrentTarget = nil,
}

-- Estado do ESP
local ESPState = {
    Enabled = false,
    Box = false,
    Skeleton = false,
    Name = false,
    Health = false,
    Snaplines = false,
    SnaplinePosition = "Bottom", -- "Bottom" | "Center" | "Top"
    Objects = {},                -- Armazena Drawing objects por jogador
}

-- Estado do Player/Misc
local PlayerState = {
    Spinbot = false,
    SpeedEnabled = false,
    SpeedValue = 16,
    HighJump = false,
    JumpPower = 50,
    Noclip = false,
}

-- ============================================================
-- 4. CRIAÇÃO DA JANELA PRINCIPAL
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Pethz Aim",
    LoadingTitle = "Pethz Aim",
    LoadingSubtitle = "Carregando...",
    Theme = "Default", -- Aplicamos o tema customizado depois
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "PethzAimConfig"
    },
    KeySystem = false,
})

-- Aplicar tema customizado (Rayfield permite sobrescrever via Flag ou Theme table)
-- Nota: Rayfield usa Theme = "Default" por padrão; para custom completo,
-- recomenda-se usar a API de tema se disponível na versão carregada.
-- Abaixo aplicamos override nos elementos principais via loop (fallback seguro).
for _, obj in ipairs(Window:GetDescendants()) do
    if obj:IsA("Frame") or obj:IsA("TextLabel") or obj:IsA("TextButton") then
        -- Aplicação básica de cor de fundo/texto; a biblioteca pode ter seus próprios hooks.
        -- Para customização completa, consulte docs.sirius.menu
    end
end

-- ============================================================
-- 5. UTILITÁRIOS GERAIS
-- ============================================================
local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local hum = getHumanoid(player)
    return hum and hum.Health > 0
end

local function getPart(player, partName)
    local char = getCharacter(player)
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

-- Distância 2D do centro da tela até um ponto de tela
local function screenDistanceFromCenter(screenPos)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - center).Magnitude
end

-- ============================================================
-- 6. SISTEMA DE AIMBOT
-- ============================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(155, 89, 182)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Radius = AimState.FOV / 2
FOVCircle.Filled = false
FOVCircle.Visible = false

local function updateFOVCircle()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = AimState.FOV / 2
    FOVCircle.Visible = AimState.Enabled
end

-- Encontra o jogador mais próximo dentro do FOV
local function getClosestTarget()
    local closest = nil
    local shortestDist = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not isAlive(player) then continue end

        local part = getPart(player, AimState.TargetPart)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = screenDistanceFromCenter(Vector2.new(screenPos.X, screenPos.Y))
        if dist <= AimState.FOV / 2 and dist < shortestDist then
            shortestDist = dist
            closest = player
        end
    end

    return closest
end

-- Loop principal do aimbot com smoothing
RunService.RenderStepped:Connect(function()
    updateFOVCircle()

    if not AimState.Enabled then
        AimState.CurrentTarget = nil
        return
    end

    local target = getClosestTarget()
    AimState.CurrentTarget = target

    if target then
        local part = getPart(target, AimState.TargetPart)
        if part then
            -- CFrame lookAt com interpolação para smoothing
            local targetCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
            if AimState.Smoothing > 0 and AimState.Smoothing < 1 then
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - AimState.Smoothing)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end
end)

-- ============================================================
-- 7. SISTEMA DE ESP (DRAWING API)
-- ============================================================
-- Estrutura por jogador: { box, name, healthBar, healthBg, snapline, skeletonLines = {} }

local function createESPForPlayer(player)
    if player == LocalPlayer then return end
    if ESPState.Objects[player] then return end

    local objs = {}

    -- Box ESP (4 linhas formando retângulo)
    objs.BoxTop = Drawing.new("Line")
    objs.BoxBottom = Drawing.new("Line")
    objs.BoxLeft = Drawing.new("Line")
    objs.BoxRight = Drawing.new("Line")
    for _, line in pairs({objs.BoxTop, objs.BoxBottom, objs.BoxLeft, objs.BoxRight}) do
        line.Color = Color3.fromRGB(155, 89, 182)
        line.Thickness = 1.5
        line.Visible = false
    end

    -- Name ESP
    objs.Name = Drawing.new("Text")
    objs.Name.Size = 14
    objs.Name.Center = true
    objs.Name.Outline = true
    objs.Name.Color = Color3.fromRGB(255, 255, 255)
    objs.Name.Visible = false

    -- Health Bar (fundo + barra)
    objs.HealthBg = Drawing.new("Line")
    objs.HealthBg.Color = Color3.fromRGB(40, 40, 40)
    objs.HealthBg.Thickness = 4
    objs.HealthBg.Visible = false

    objs.HealthBar = Drawing.new("Line")
    objs.HealthBar.Color = Color3.fromRGB(50, 220, 80)
    objs.HealthBar.Thickness = 4
    objs.HealthBar.Visible = false

    -- Snapline
    objs.Snapline = Drawing.new("Line")
    objs.Snapline.Color = Color3.fromRGB(155, 89, 182)
    objs.Snapline.Thickness = 1
    objs.Snapline.Visible = false

    -- Skeleton (linhas entre articulações)
    local bonePairs = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"},
    }
    objs.SkeletonLines = {}
    for i = 1, #bonePairs do
        local line = Drawing.new("Line")
        line.Color = Color3.fromRGB(200, 150, 230)
        line.Thickness = 1
        line.Visible = false
        table.insert(objs.SkeletonLines, line)
    end
    objs.BonePairs = bonePairs

    ESPState.Objects[player] = objs
end

local function removeESPForPlayer(player)
    local objs = ESPState.Objects[player]
    if not objs then return end
    for _, obj in pairs(objs) do
        if typeof(obj) == "Instance" and obj.Remove then
            obj:Remove()
        elseif typeof(obj) == "table" then
            for _, sub in pairs(obj) do
                if typeof(sub) == "Instance" and sub.Remove then
                    sub:Remove()
                end
            end
        end
    end
    ESPState.Objects[player] = nil
end

local function updateESP()
    if not ESPState.Enabled then
        -- Esconder todos
        for _, objs in pairs(ESPState.Objects) do
            for _, obj in pairs(objs) do
                if typeof(obj) == "Instance" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif typeof(obj) == "table" then
                    for _, sub in pairs(obj) do
                        if typeof(sub) == "Instance" and sub.Visible ~= nil then
                            sub.Visible = false
                        end
                    end
                end
            end
        end
        return
    end

    for player, objs in pairs(ESPState.Objects) do
        if player == LocalPlayer or not isAlive(player) then
            -- Esconder
            for _, obj in pairs(objs) do
                if typeof(obj) == "Instance" and obj.Visible ~= nil then obj.Visible = false end
                if typeof(obj) == "table" then
                    for _, sub in pairs(obj) do
                        if typeof(sub) == "Instance" and sub.Visible ~= nil then sub.Visible = false end
                    end
                end
            end
            continue
        end

        local char = getCharacter(player)
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = getHumanoid(player)

        if not (head and root and hum) then
            for _, obj in pairs(objs) do
                if typeof(obj) == "Instance" and obj.Visible ~= nil then obj.Visible = false end
                if typeof(obj) == "table" then
                    for _, sub in pairs(obj) do
                        if typeof(sub) == "Instance" and sub.Visible ~= nil then sub.Visible = false end
                    end
                end
            end
            continue
        end

        local headScreen, headOn = Camera:WorldToViewportPoint(head.Position)
        local rootScreen, rootOn = Camera:WorldToViewportPoint(root.Position)

        if not (headOn and rootOn) then
            -- Fora da tela: esconder tudo
            for _, obj in pairs(objs) do
                if typeof(obj) == "Instance" and obj.Visible ~= nil then obj.Visible = false end
                if typeof(obj) == "table" then
                    for _, sub in pairs(obj) do
                        if typeof(sub) == "Instance" and sub.Visible ~= nil then sub.Visible = false end
                    end
                end
            end
            continue
        end

        local headPos = Vector2.new(headScreen.X, headScreen.Y)
        local rootPos = Vector2.new(rootScreen.X, rootScreen.Y)
        local height = (headPos - rootPos).Magnitude * 1.6
        local width = height * 0.45

        -- Box
        if ESPState.Box then
            local top = headPos.Y - height * 0.3
            local bottom = rootPos.Y + height * 0.3
            local left = rootPos.X - width / 2
            local right = rootPos.X + width / 2

            objs.BoxTop.From = Vector2.new(left, top); objs.BoxTop.To = Vector2.new(right, top)
            objs.BoxBottom.From = Vector2.new(left, bottom); objs.BoxBottom.To = Vector2.new(right, bottom)
            objs.BoxLeft.From = Vector2.new(left, top); objs.BoxLeft.To = Vector2.new(left, bottom)
            objs.BoxRight.From = Vector2.new(right, top); objs.BoxRight.To = Vector2.new(right, bottom)
            for _, l in pairs({objs.BoxTop, objs.BoxBottom, objs.BoxLeft, objs.BoxRight}) do l.Visible = true end
        else
            for _, l in pairs({objs.BoxTop, objs.BoxBottom, objs.BoxLeft, objs.BoxRight}) do l.Visible = false end
        end

        -- Name
        if ESPState.Name then
            local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
            objs.Name.Text = player.Name .. " [" .. dist .. "m]"
            objs.Name.Position = Vector2.new(rootPos.X, headPos.Y - height * 0.5 - 18)
            objs.Name.Visible = true
        else
            objs.Name.Visible = false
        end

        -- Health Bar
        if ESPState.Health then
            local hpPct = hum.Health / hum.MaxHealth
            local barTop = headPos.Y - height * 0.3
            local barBottom = rootPos.Y + height * 0.3
            local barX = rootPos.X + width / 2 + 8

            objs.HealthBg.From = Vector2.new(barX, barTop)
            objs.HealthBg.To = Vector2.new(barX, barBottom)
            objs.HealthBg.Visible = true

            objs.HealthBar.From = Vector2.new(barX, barBottom - (barBottom - barTop) * hpPct)
            objs.HealthBar.To = Vector2.new(barX, barBottom)
            objs.HealthBar.Color = hpPct > 0.5 and Color3.fromRGB(50, 220, 80)
                or hpPct > 0.25 and Color3.fromRGB(220, 200, 50)
                or Color3.fromRGB(220, 60, 60)
            objs.HealthBar.Visible = true
        else
            objs.HealthBg.Visible = false
            objs.HealthBar.Visible = false
        end

        -- Snaplines
        if ESPState.Snaplines then
            local screenH = Camera.ViewportSize.Y
            local fromY
            if ESPState.SnaplinePosition == "Bottom" then fromY = screenH
            elseif ESPState.SnaplinePosition == "Top" then fromY = 0
            else fromY = screenH / 2 end

            objs.Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, fromY)
            objs.Snapline.To = Vector2.new(rootPos.X, rootPos.Y)
            objs.Snapline.Visible = true
        else
            objs.Snapline.Visible = false
        end

        -- Skeleton
        if ESPState.Skeleton then
            for i, pair in ipairs(objs.BonePairs) do
                local partA = char:FindFirstChild(pair[1])
                local partB = char:FindFirstChild(pair[2])
                local line = objs.SkeletonLines[i]
                if partA and partB then
                    local aScreen, aOn = Camera:WorldToViewportPoint(partA.Position)
                    local bScreen, bOn = Camera:WorldToViewportPoint(partB.Position)
                    if aOn and bOn then
                        line.From = Vector2.new(aScreen.X, aScreen.Y)
                        line.To = Vector2.new(bScreen.X, bScreen.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(objs.SkeletonLines) do line.Visible = false end
        end
    end
end

-- Loop do ESP
RunService.RenderStepped:Connect(updateESP)

-- Gerenciamento de entrada/saída de jogadores
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        createESPForPlayer(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPForPlayer(player)
end)

-- Criar para jogadores existentes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPForPlayer(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            createESPForPlayer(player)
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    -- Recriar ESP de todos ao respawnar localmente
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            removeESPForPlayer(player)
            task.wait(0.3)
            createESPForPlayer(player)
        end
    end
end)

-- ============================================================
-- 8. SISTEMA DE PLAYER/MISC (SPINBOT, SPEED, HIGH JUMP, NOCLIP)
-- ============================================================
-- Spinbot
RunService.Heartbeat:Connect(function()
    if not PlayerState.Spinbot then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(15), 0)
    end
end)

-- Speed Hack
RunService.Heartbeat:Connect(function()
    local hum = getHumanoid(LocalPlayer)
    if not hum then return end
    if PlayerState.SpeedEnabled then
        hum.WalkSpeed = PlayerState.SpeedValue
    else
        hum.WalkSpeed = 16 -- padrão
    end
end)

-- High Jump
RunService.Heartbeat:Connect(function()
    local hum = getHumanoid(LocalPlayer)
    if not hum then return end
    if PlayerState.HighJump then
        hum.JumpPower = PlayerState.JumpPower
        hum.UseJumpPower = true
    else
        hum.JumpPower = 50
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if not PlayerState.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- Resetar CanCollide quando noclip desligar
local function resetCollision()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

-- ============================================================
-- 9. CONSTRUÇÃO DA INTERFACE (ABAS E CONTROLES)
-- ============================================================

-- ========== ABA AIM ==========
local AimTab = Window:CreateTab("AIM", 4483345998)

local AimSection = AimTab:CreateSection("Configurações de Aimbot")

AimTab

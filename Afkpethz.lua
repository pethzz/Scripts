-- ==========================================================
-- Anti-AFK System - Mobile Edition v9
-- Desenvolvido por: Pethz
-- ==========================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================================
-- CONFIGURAÇÕES
-- ==========================================================
local CONFIG = {
    MoveDistance    = 15,
    MoveInterval    = 1.5,

    ChatMinInterval = 8,
    ChatMaxInterval = 15,

    FallCheckRate   = 0.5,
    FallOffset      = 100,
}

-- ==========================================================
-- ESTADO
-- ==========================================================
local AntiAFKAtivo         = false
local ChatLoopRodando      = false
local MovementLoopRodando  = false
local FallCheckLoopRodando = false
local AntiKickLoopRodando  = false
local TimerInicio          = nil
local TimerLabel           = nil
local TimerConexao         = nil
local SpawnY               = nil

-- ==========================================================
-- FALAS ALEATÓRIAS
-- ==========================================================
local FalasNPC = {
    "afk", "voltei", "tô aqui", "só um minuto", "já volto",
    "Hmm?", "Oi?", "Alguém aí?", "Que foi?", "Fala aí",
    "Tô de boa", "Deixa eu pensar...", "Interessante...", "Legal isso",
    "Boa!", "Verdade", "É mesmo?", "Nossa", "Pois é", "Entendi",
    "Tô ouvindo", "Continua", "Aham", "Tá bom", "Beleza",
    "Já fui um aventureiro como você... até levar uma flechada no joelho.",
    "Deixa eu adivinhar: alguém roubou seu doce.",
    "Meu primo tá lutando contra dragões e eu fico aqui de guarda.",
    "Você deveria ter vindo aqui antes.",
    "Deve ter sido o vento.",
    "Espera, eu te conheço.",
    "O que foi?",
    "Tô de guarda, não posso conversar.",
    "Não devia ter vindo aqui.",
    "Mais um dia, mais um tédio.",
    "Alguém tem comida?", "Tô entediado", "Que mapa é esse?",
    "Bora fazer algo?", "Quem tá online?", "Alguém quer jogar?",
    "Tô com sono", "Que horas são?", "Já volto galera", "Fui",
    "Aqui é top", "Bom demais", "Legal aqui", "Gostei",
    "kkkk", "rsrs", "boaa", "que isso", "vish",
}

-- ==========================================================
-- AUXILIARES
-- ==========================================================
local function obterPersonagem()
    local character = LocalPlayer.Character
    if not character or not character.Parent then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return nil end
    return character, humanoid, hrp
end

local function obterSpawn()
    if LocalPlayer.RespawnLocation then return LocalPlayer.RespawnLocation end
    local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawnLocation then return spawnLocation end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then return obj end
    end
    return nil
end

local function atualizarSpawnY()
    local spawn = obterSpawn()
    if spawn then SpawnY = spawn.Position.Y end
end

local function teleportarParaSpawn()
    local character, humanoid, hrp = obterPersonagem()
    if not character or not hrp then return end
    local spawn = obterSpawn()
    if not spawn then return end
    hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
end

-- ==========================================================
-- CHAT (envio com fallback)
-- ==========================================================
local function enviarMensagemChat(mensagem)
    local sucesso1 = pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            if channels then
                local general = channels:FindFirstChild("RBXGeneral")
                if general then general:SendAsync(mensagem); return true end
                for _, ch in ipairs(channels:GetChildren()) do
                    if ch:IsA("TextChannel") then ch:SendAsync(mensagem); return true end
                end
            end
        end
        return false
    end)
    if sucesso1 then return true end

    local sucesso2 = pcall(function()
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents then
            local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
            if sayRequest then sayRequest:FireServer(mensagem, "All"); return true end
        end
        return false
    end)
    if sucesso2 then return true end

    pcall(function()
        game:GetService("Chat"):Chat(LocalPlayer.Character, mensagem)
    end)
    return false
end

-- ==========================================================
-- ANTI-KICK
-- ==========================================================
local function loopAntiKick()
    while AntiAFKAtivo and AntiKickLoopRodando do
        task.wait(30)
        if not AntiAFKAtivo or not AntiKickLoopRodando then break end
        if not LocalPlayer.Parent then break end
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end
        end)
    end
end

-- ==========================================================
-- LOOPS
-- ==========================================================
local function loopMovimentacao()
    local direcoes = {
        Vector3.new(0, 0, -1),
        Vector3.new(1, 0, 0),
        Vector3.new(0, 0, 1),
        Vector3.new(-1, 0, 0),
    }
    while AntiAFKAtivo and MovementLoopRodando do
        local character, humanoid, hrp = obterPersonagem()
        if character and humanoid and hrp then
            local dir = direcoes[math.random(1, #direcoes)]
            local destino = hrp.Position + (dir * CONFIG.MoveDistance)
            humanoid:MoveTo(destino)
            task.wait(CONFIG.MoveInterval)
            if (hrp.Position - destino).Magnitude > 3 then
                humanoid:MoveTo(destino)
                task.wait(CONFIG.MoveInterval * 0.5)
            end
        else
            task.wait(1)
        end
    end
end

local function loopChat()
    while AntiAFKAtivo and ChatLoopRodando do
        local espera = math.random(CONFIG.ChatMinInterval, CONFIG.ChatMaxInterval)
        task.wait(espera)
        if not AntiAFKAtivo or not ChatLoopRodando then break end
        local character, humanoid = obterPersonagem()
        if character and humanoid and humanoid.Health > 0 then
            enviarMensagemChat(FalasNPC[math.random(1, #FalasNPC)])
        end
    end
end

local function loopAntiQueda()
    while AntiAFKAtivo and FallCheckLoopRodando do
        task.wait(CONFIG.FallCheckRate)
        if not AntiAFKAtivo or not FallCheckLoopRodando then break end
        local character, humanoid, hrp = obterPersonagem()
        if character and humanoid and hrp then
            if not SpawnY then atualizarSpawnY() end
            if SpawnY and hrp.Position.Y < (SpawnY - CONFIG.FallOffset) then
                teleportarParaSpawn()
                task.wait(2)
            end
        end
    end
end

-- ==========================================================
-- TIMER (compatível com Rayfield e UI nativa)
-- ==========================================================
local function formatarTempo(s)
    return string.format("%02d:%02d:%02d",
        math.floor(s / 3600), math.floor((s % 3600) / 60), math.floor(s % 60))
end

local function iniciarTimer()
    TimerInicio = tick()
    if TimerConexao then TimerConexao:Disconnect() end

    TimerConexao = RunService.Heartbeat:Connect(function()
        if not AntiAFKAtivo or not TimerLabel or not TimerInicio then return end
        local texto = "Tempo AFK: " .. formatarTempo(tick() - TimerInicio)

        pcall(function() TimerLabel:Set(texto) end)
        pcall(function()
            if TimerLabel.Text ~= nil then TimerLabel.Text = texto end
        end)
    end)
end

local function pararTimer()
    if TimerConexao then TimerConexao:Disconnect(); TimerConexao = nil end
    TimerInicio = nil
    if TimerLabel then
        pcall(function() TimerLabel:Set("Tempo AFK: 00:00:00") end)
        pcall(function()
            if TimerLabel.Text ~= nil then TimerLabel.Text = "Tempo AFK: 00:00:00" end
        end)
    end
end

-- ==========================================================
-- GERENCIAMENTO
-- ==========================================================
local function pararTodosOsLoops()
    ChatLoopRodando = false
    MovementLoopRodando = false
    FallCheckLoopRodando = false
    AntiKickLoopRodando = false
    pararTimer()
end

local function iniciarTodosOsLoops()
    pararTodosOsLoops()
    atualizarSpawnY()

    ChatLoopRodando = true
    MovementLoopRodando = true
    FallCheckLoopRodando = true
    AntiKickLoopRodando = true

    task.spawn(loopMovimentacao)
    task.spawn(loopChat)
    task.spawn(loopAntiQueda)
    task.spawn(loopAntiKick)

    iniciarTimer()
end

-- ==========================================================
-- UI NATIVA
-- ==========================================================
local function criarUINativa()
    local parentGui
    local ok, result = pcall(function() return gethui() end)
    if ok and result then parentGui = result else parentGui = LocalPlayer:WaitForChild("PlayerGui") end

    local antiga = parentGui:FindFirstChild("AntiAFK_UI")
    if antiga then antiga:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFK_UI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = parentGui

    local botao = Instance.new("TextButton")
    botao.Size = UDim2.new(0, 70, 0, 70)
    botao.Position = UDim2.new(0, 20, 0.5, -35)
    botao.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    botao.TextColor3 = Color3.fromRGB(255, 255, 255)
    botao.Text = "AFK"
    botao.TextScaled = true
    botao.Font = Enum.Font.GothamBold
    botao.BorderSizePixel = 0
    botao.Draggable = true
    botao.Parent = screenGui

    local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1, 0); c1.Parent = botao
    local s1 = Instance.new("UIStroke"); s1.Color = Color3.fromRGB(0, 170, 255); s1.Thickness = 2; s1.Parent = botao

    local painel = Instance.new("Frame")
    painel.Size = UDim2.new(0, 320, 0, 320)
    painel.Position = UDim2.new(0.5, -160, 0.5, -160)
    painel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    painel.BorderSizePixel = 0
    painel.Visible = false
    painel.Draggable = true
    painel.Parent = screenGui

    local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 12); c2.Parent = painel
    local s2 = Instance.new("UIStroke"); s2.Color = Color3.fromRGB(0, 170, 255); s2.Thickness = 2; s2.Parent = painel

    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 40)
    titulo.BackgroundTransparency = 1
    titulo.Text = "Anti-AFK System"
    titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 20
    titulo.Parent = painel

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0, 35)
    sub.BackgroundTransparency = 1
    sub.Text = "Mobile Edition"
    sub.TextColor3 = Color3.fromRGB(150, 200, 255)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.Parent = painel

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 260, 0, 55)
    toggle.Position = UDim2.new(0.5, -130, 0, 75)
    toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Text = "Ativar Anti-AFK: DESLIGADO"
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.BorderSizePixel = 0
    toggle.Parent = painel

    local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0, 8); c3.Parent = toggle

    TimerLabel = Instance.new("TextLabel")
    TimerLabel.Size = UDim2.new(1, 0, 0, 40)
    TimerLabel.Position = UDim2.new(0, 0, 0, 145)
    TimerLabel.BackgroundTransparency = 1
    TimerLabel.Text = "Tempo AFK: 00:00:00"
    TimerLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
    TimerLabel.Font = Enum.Font.GothamBold
    TimerLabel.TextSize = 16
    TimerLabel.Parent = painel

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 60)
    info.Position = UDim2.new(0, 0, 0, 190)
    info.BackgroundTransparency = 1
    info.Text = "Falas: " .. #FalasNPC .. "\nFala a cada: " .. CONFIG.ChatMinInterval .. "-" .. CONFIG.ChatMaxInterval .. "s\nMovimento: 4 direções"
    info.TextColor3 = Color3.fromRGB(150, 150, 160)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.Parent = painel

    local cred = Instance.new("TextLabel")
    cred.Size = UDim2.new(1, 0, 0, 25)
    cred.Position = UDim2.new(0, 0, 1, -30)
    cred.BackgroundTransparency = 1
    cred.Text = "Desenvolvido por: Pethz"
    cred.TextColor3 = Color3.fromRGB(180, 180, 180)
    cred.Font = Enum.Font.Gotham
    cred.TextSize = 13
    cred.Parent = painel

    local fechar = Instance.new("TextButton")
    fechar.Size = UDim2.new(0, 30, 0, 30)
    fechar.Position = UDim2.new(1, -38, 0, 8)
    fechar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    fechar.TextColor3 = Color3.fromRGB(255, 255, 255)
    fechar.Text = "X"
    fechar.Font = Enum.Font.GothamBold
    fechar.TextSize = 16
    fechar.BorderSizePixel = 0
    fechar.Parent = painel

    local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(0, 6); c4.Parent = fechar

    botao.MouseButton1Click:Connect(function() painel.Visible = not painel.Visible end)
    fechar.MouseButton1Click:Connect(function() painel.Visible = false end)

    toggle.MouseButton1Click:Connect(function()
        AntiAFKAtivo = not AntiAFKAtivo
        if AntiAFKAtivo then
            toggle.Text = "Ativar Anti-AFK: LIGADO"
            toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
            iniciarTodosOsLoops()
        else
            toggle.Text = "Ativar Anti-AFK: DESLIGADO"
            toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
            pararTodosOsLoops()
        end
    end)
end

-- ==========================================================
-- RAYFIELD (com fallback)
-- ==========================================================
local function tentarRayfield()
    local urls = {
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        "https://raw.githubusercontent.com/SirMalloy/Rayfield/main/source.lua",
    }
    for _, url in ipairs(urls) do
        local ok, r = pcall(function() return loadstring(game:HttpGet(url))() end)
        if ok and type(r) == "table" then return r end
    end
    return nil
end

local Rayfield = tentarRayfield()

if Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "Anti-AFK System",
        LoadingTitle = "Anti-AFK System",
        LoadingSubtitle = "Mobile Edition",
        ShowText = "Anti-AFK",
        ToggleUIKeybind = "K",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local AbaPrincipal = Window:CreateTab("Principal", 4483362458)
    AbaPrincipal:CreateSection("Controle")

    AbaPrincipal:CreateToggle({
        Name = "Ativar Anti-AFK",
        CurrentValue = false,
        Flag = "AntiAFKToggle",
        Callback = function(v)
            AntiAFKAtivo = v
            if v then iniciarTodosOsLoops() else pararTodosOsLoops() end
        end,
    })

    AbaPrincipal:CreateSection("Status")
    TimerLabel = AbaPrincipal:CreateLabel("Tempo AFK: 00:00:00")
    AbaPrincipal:CreateLabel("Falas disponíveis: " .. #FalasNPC)
    AbaPrincipal:CreateLabel("Fala a cada: " .. CONFIG.ChatMinInterval .. "-" .. CONFIG.ChatMaxInterval .. "s")
    AbaPrincipal:CreateLabel("Movimento: 4 direções")

    local AbaCred = Window:CreateTab("Créditos", 4483362458)
    AbaCred:CreateSection("Informações")
    AbaCred:CreateLabel("Desenvolvido por: Pethz")
else
    warn("[Anti-AFK] Rayfield falhou, usando UI nativa.")
    criarUINativa()
end

-- ==========================================================
-- RESPAWN
-- ==========================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    atualizarSpawnY()
    if AntiAFKAtivo then iniciarTodosOsLoops() end
end)

print("[Anti-AFK System v9] Carregado. Desenvolvido por: Pethz")

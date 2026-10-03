-- ==========================================================
-- Anti-AFK System - Mobile Edition v3
-- Desenvolvido por: Pethz
-- Compatível com Delta, Fluxus, Codex, Hydrogen, Arceus X
-- ==========================================================

-- Referências
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================================
-- CONFIGURAÇÕES
-- ==========================================================
local CONFIG = {
    -- Movimento
    MoveDistance    = 20,       -- Distância de cada passo (studs)
    MoveInterval    = 1.8,      -- Tempo entre cada passo (segundos)
    DirectionChange = 3,        -- Segundos entre mudança de direção

    -- Chat (NPC style)
    ChatMinInterval = 25,       -- Intervalo MÍNIMO entre falas (segundos)
    ChatMaxInterval = 45,       -- Intervalo MÁXIMO entre falas (segundos)

    -- Anti-Queda
    FallThreshold   = -50,      -- Se Y cair abaixo disso, teleporta de volta
    FallCheckRate   = 0.5,      -- Verificação a cada 0.5s

    -- Anti-Kick (Anti-Inatividade)
    KickBypassRate  = 60,       -- Simular input a cada 60s (o Roblox kicka em 20min)
}

-- ==========================================================
-- ESTADO GLOBAL
-- ==========================================================
local AntiAFKAtivo        = false
local ChatLoopRodando     = false
local MovementLoopRodando = false
local FallCheckLoopRodando = false
local KickBypassRodando   = false
local TimerInicio         = nil
local TimerLabel          = nil
local TimerConexao        = nil

-- ==========================================================
-- FALAS DO NPC (variedade)
-- ==========================================================
local FalasNPC = {
    -- AFK clássico
    "afk",
    "voltei",
    "tô aqui",
    "só um minuto",
    "já volto",

    -- NPC style
    "Hmm?",
    "Oi?",
    "Alguém aí?",
    "Que foi?",
    "Fala aí",
    "Tô de boa",
    "Deixa eu pensar...",
    "Interessante...",
    "Legal isso",
    "Boa!",
    "Verdade",
    "É mesmo?",
    "Nossa",
    "Pois é",
    "Entendi",
    "Tô ouvindo",
    "Continua",
    "Aham",
    "Tá bom",
    "Beleza",

    -- Skyrim NPC style
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

    -- Random
    "Alguém tem comida?",
    "Tô entediado",
    "Que mapa é esse?",
    "Bora fazer algo?",
    "Quem tá online?",
    "Alguém quer jogar?",
    "Tô com sono",
    "Que horas são?",
    "Já volto galera",
    "Fui",
    "Aqui é top",
    "Bom demais",
    "Legal aqui",
    "Gostei",
    "kkkk",
    "rsrs",
    "boaa",
    "tmnc kkkk",
    "que isso",
    "vish",
}

-- ==========================================================
-- FUNÇÕES AUXILIARES
-- ==========================================================
local function obterPersonagem()
    local character = LocalPlayer.Character
    if not character or not character.Parent then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp      = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return nil end
    return character, humanoid, hrp
end

local function obterSpawn()
    if LocalPlayer.RespawnLocation then
        return LocalPlayer.RespawnLocation
    end
    local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawnLocation then return spawnLocation end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then return obj end
    end
    return nil
end

local function teleportarParaSpawn()
    local character, humanoid, hrp = obterPersonagem()
    if not character or not hrp then return end
    local spawn = obterSpawn()
    if not spawn then
        warn("[Anti-AFK] Nenhum SpawnLocation encontrado.")
        return
    end
    hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
end

-- ==========================================================
-- SISTEMA DE CHAT
-- ==========================================================
local function enviarMensagemChat(mensagem)
    local sucesso = pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local general = TextChatService:FindFirstChild("TextChannels")
                and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if general then
                general:SendAsync(mensagem)
                return true
            end
            for _, ch in ipairs(TextChatService:GetChildren()) do
                if ch:IsA("TextChannel") then
                    ch:SendAsync(mensagem)
                    return true
                end
            end
        end
        return false
    end)

    if not sucesso then
        pcall(function()
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents then
                local sayRequest = chatEvents:FindFirstChild("SayMessageRequest")
                if sayRequest then
                    sayRequest:FireServer(mensagem, "All")
                end
            end
        end)
    end
end

-- ==========================================================
-- ANTI-KICK (Simula input real no cliente)
-- ==========================================================
-- Isso é CRUCIAL: o Roblox kicka por inatividade baseado em Idled events.
-- MoveTo e chat NÃO contam como input real. Precisamos simular
-- teclas ou toques reais via VirtualInputManager/VirtualUser.
-- ==========================================================
local function simularInputReal()
    local sucesso = pcall(function()
        -- Tenta usar VirtualUser (comum em executores mobile)
        if VirtualUser and VirtualUser.KeyPress then
            VirtualUser:KeyPress(Enum.KeyCode.Space)
            task.wait(0.05)
            VirtualUser:KeyRelease(Enum.KeyCode.Space)
            return
        end

        -- Fallback: VirtualInputManager
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)

    if not sucesso then
        -- Último fallback: simular clique de mouse (menos confiável)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                0, 0, 0, true, game, 0
            )
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(
                0, 0, 0, false, game, 0
            )
        end)
    end
end

local function loopKickBypass()
    while AntiAFKAtivo and KickBypassRodando do
        task.wait(CONFIG.KickBypassRate)
        if not AntiAFKAtivo or not KickBypassRodando then break end
        simularInputReal()
    end
end

-- ==========================================================
-- LOOPS
-- ==========================================================
local function loopMovimentacao()
    local direcao = 1 -- 1 = frente, -1 = trás
    local tempoDirecao = 0

    while AntiAFKAtivo and MovementLoopRodando do
        local character, humanoid, hrp = obterPersonagem()
        if character and humanoid and hrp then
            -- Movimento variado: frente/trás + pequenas variações laterais
            local offset = Vector3.new(
                direcao * CONFIG.MoveDistance,
                0,
                (direcao % 2 == 0) and CONFIG.MoveDistance * 0.5 or -CONFIG.MoveDistance * 0.5
            )
            local destino = hrp.CFrame * CFrame.new(offset)
            humanoid:MoveTo(destino.Position)

            task.wait(CONFIG.MoveInterval)

            -- Troca direção periodicamente
            tempoDirecao = tempoDirecao + CONFIG.MoveInterval
            if tempoDirecao >= CONFIG.DirectionChange then
                direcao = -direcao
                tempoDirecao = 0
            end
        else
            task.wait(1)
        end
    end
end

local function loopChat()
    while AntiAFKAtivo and ChatLoopRodando do
        -- Intervalo aleatório entre as falas
        local espera = math.random(CONFIG.ChatMinInterval, CONFIG.ChatMaxInterval)
        task.wait(espera)

        if not AntiAFKAtivo or not ChatLoopRodando then break end

        local character, humanoid = obterPersonagem()
        if character and humanoid and humanoid.Health > 0 then
            local falaAleatoria = FalasNPC[math.random(1, #FalasNPC)]
            enviarMensagemChat(falaAleatoria)
        end
    end
end

local function loopAntiQueda()
    while AntiAFKAtivo and FallCheckLoopRodando do
        task.wait(CONFIG.FallCheckRate)
        if not AntiAFKAtivo or not FallCheckLoopRodando then break end

        local character, humanoid, hrp = obterPersonagem()
        if character and humanoid and hrp then
            if hrp.Position.Y < CONFIG.FallThreshold then
                teleportarParaSpawn()
                task.wait(1)
            end
        end
    end
end

-- ==========================================================
-- TIMER (contador de tempo AFK)
-- ==========================================================
local function formatarTempo(segundos)
    local h = math.floor(segundos / 3600)
    local m = math.floor((segundos % 3600) / 60)
    local s = math.floor(segundos % 60)
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function iniciarTimer()
    TimerInicio = tick()

    if TimerConexao then
        TimerConexao:Disconnect()
        TimerConexao = nil
    end

    TimerConexao = RunService.Heartbeat:Connect(function()
        if not AntiAFKAtivo or not TimerLabel then return end
        local decorrido = tick() - (TimerInicio or tick())
        pcall(function()
            TimerLabel:Set("Tempo AFK: " .. formatarTempo(decorrido))
        end)
    end)
end

local function pararTimer()
    if TimerConexao then
        TimerConexao:Disconnect()
        TimerConexao = nil
    end
    TimerInicio = nil
    if TimerLabel then
        pcall(function()
            TimerLabel:Set("Tempo AFK: 00:00:00")
        end)
    end
end

-- ==========================================================
-- GERENCIAMENTO DE LOOPS
-- ==========================================================
local function pararTodosOsLoops()
    ChatLoopRodando     = false
    MovementLoopRodando = false
    FallCheckLoopRodando = false
    KickBypassRodando   = false
    pararTimer()
end

local function iniciarTodosOsLoops()
    pararTodosOsLoops()

    ChatLoopRodando     = true
    MovementLoopRodando = true
    FallCheckLoopRodando = true
    KickBypassRodando   = true

    task.spawn(loopMovimentacao)
    task.spawn(loopChat)
    task.spawn(loopAntiQueda)
    task.spawn(loopKickBypass)

    iniciarTimer()
end

-- ==========================================================
-- UI NATIVA (FALLBACK)
-- ==========================================================
local function criarUINativa()
    local parentGui = (gethui and gethui()) or CoreGui
    local antiga = parentGui:FindFirstChild("AntiAFK_UI_Nativa")
    if antiga then antiga:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFK_UI_Nativa"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parentGui

    -- Botão flutuante
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

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = botao

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 2
    stroke.Parent = botao

    -- Painel
    local painel = Instance.new("Frame")
    painel.Size = UDim2.new(0, 320, 0, 320)
    painel.Position = UDim2.new(0.5, -160, 0.5, -160)
    painel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    painel.BorderSizePixel = 0
    painel.Visible = false
    painel.Draggable = true
    painel.Parent = screenGui

    local cornerP = Instance.new("UICorner")
    cornerP.CornerRadius = UDim.new(0, 12)
    cornerP.Parent = painel

    local strokeP = Instance.new("UIStroke")
    strokeP.Color = Color3.fromRGB(0, 170, 255)
    strokeP.Thickness = 2
    strokeP.Parent = painel

    -- Título
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 40)
    titulo.BackgroundTransparency = 1
    titulo.Text = "Anti-AFK System"
    titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
    titulo.Font = Enum.Font.GothamBold
    titulo.TextSize = 20
    titulo.Parent = painel

    local subtitulo = Instance.new("TextLabel")
    subtitulo.Size = UDim2.new(1, 0, 0, 20)
    subtitulo.Position = UDim2.new(0, 0, 0, 35)
    subtitulo.BackgroundTransparency = 1
    subtitulo.Text = "Mobile Edition"
    subtitulo.TextColor3 = Color3.fromRGB(150, 200, 255)
    subtitulo.Font = Enum.Font.Gotham
    subtitulo.TextSize = 12
    subtitulo.Parent = painel

    -- Toggle
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

    local cornerT = Instance.new("UICorner")
    cornerT.CornerRadius = UDim.new(0, 8)
    cornerT.Parent = toggle

    -- Timer (contador de tempo AFK)
    TimerLabel = Instance.new("TextLabel")
    TimerLabel.Size = UDim2.new(1, 0, 0, 40)
    TimerLabel.Position = UDim2.new(0, 0, 0, 145)
    TimerLabel.BackgroundTransparency = 1
    TimerLabel.Text = "Tempo AFK: 00:00:00"
    TimerLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
    TimerLabel.Font = Enum.Font.GothamBold
    TimerLabel.TextSize = 16
    TimerLabel.Parent = painel

    -- Info extra
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 60)
    info.Position = UDim2.new(0, 0, 0, 190)
    info.BackgroundTransparency = 1
    info.Text = "Falas: " .. #FalasNPC .. " opções\nAnti-Kick: ATIVO\nMovimento: Variado"
    info.TextColor3 = Color3.fromRGB(150, 150, 160)
    info.Font = Enum.Font.Gotham
    info.TextSize = 12
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = painel

    -- Créditos
    local creditos = Instance.new("TextLabel")
    creditos.Size = UDim2.new(1, 0, 0, 25)
    creditos.Position = UDim2.new(0, 0, 1, -30)
    creditos.BackgroundTransparency = 1
    creditos.Text = "Desenvolvido por: Pethz"
    creditos.TextColor3 = Color3.fromRGB(180, 180, 180)
    creditos.Font = Enum.Font.Gotham
    creditos.TextSize = 13
    creditos.Parent = painel

    -- Fechar
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

    local cornerF = Instance.new("UICorner")
    cornerF.CornerRadius = UDim.new(0, 6)
    cornerF.Parent = fechar

    -- Callbacks
    botao.MouseButton1Click:Connect(function()
        painel.Visible = not painel.Visible
    end)

    fechar.MouseButton1Click:Connect(function()
        painel.Visible = false
    end)

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

    print("[Anti-AFK] UI nativa carregada.")
end

-- ==========================================================
-- TENTATIVA DE CARREGAR RAYFIELD
-- ==========================================================
local function tentarCarregarRayfield()
    local urls = {
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
        "https://raw.githubusercontent.com/SirMalloy/Rayfield/main/source.lua",
    }
    for _, url in ipairs(urls) do
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(result) == "table" then
            return result
        end
    end
    return nil
end

local Rayfield = tentarCarregarRayfield()

if Rayfield then
    -- ============================================
    -- UI via Rayfield
    -- ============================================
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
    AbaPrincipal:CreateSection("Controle do Sistema")

    AbaPrincipal:CreateToggle({
        Name = "Ativar Anti-AFK",
        CurrentValue = false,
        Flag = "AntiAFKToggle",
        Callback = function(Value)
            AntiAFKAtivo = Value
            if Value then
                iniciarTodosOsLoops()
            else
                pararTodosOsLoops()
            end
        end,
    })

    AbaPrincipal:CreateSection("Status")

    TimerLabel = AbaPrincipal:CreateLabel("Tempo AFK: 00:00:00")

    AbaPrincipal:CreateLabel("Falas disponíveis: " .. #FalasNPC)
    AbaPrincipal:CreateLabel("Anti-Kick: ATIVO")
    AbaPrincipal:CreateLabel("Movimento: Variado")

    local AbaCreditos = Window:CreateTab("Créditos", 4483362458)
    AbaCreditos:CreateSection("Informações")
    AbaCreditos:CreateLabel("Desenvolvido por: Pethz")
    AbaCreditos:CreateLabel("Anti-Kick incluído (evita ban por inatividade)")

    print("[Anti-AFK] Rayfield carregada.")
else
    warn("[Anti-AFK] Rayfield não carregou. Usando UI nativa.")
    criarUINativa()
end

-- ==========================================================
-- ANTI-KICK GLOBAL (Bloqueia Kick do LocalPlayer)
-- ==========================================================
-- Intercepta a função Kick para evitar ban por inatividade.
-- Isso é um bypass básico que funciona na maioria dos casos.
-- ==========================================================
pcall(function()
    local oldKick = LocalPlayer.Kick
    if hookfunction then
        hookfunction(oldKick, newcclosure(function(self, ...)
            if self == LocalPlayer then
                warn("[Anti-AFK] Kick bloqueado!")
                return
            end
            re

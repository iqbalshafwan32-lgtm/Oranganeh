-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Theme Colors
local BG_BLACK = Color3.fromRGB(10, 10, 15)
local BG_DARK = Color3.fromRGB(18, 22, 35)
local BG_BUTTON = Color3.fromRGB(25, 32, 50)
local BORDER_BLUE = Color3.fromRGB(60, 120, 255)
local ACCENT_BLUE = Color3.fromRGB(70, 130, 255)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(150, 160, 180)
local GREEN = Color3.fromRGB(80, 220, 120)
local RED = Color3.fromRGB(255, 80, 80)
local ON_COLOR = Color3.fromRGB(40, 80, 40)

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
end

local function stroke(o, color, t)
    local s = Instance.new("UIStroke")
    s.Color = color or BORDER_BLUE
    s.Thickness = t or 2
    s.Parent = o
    return s
end

local function newLabel(parent, text, size, font, color, pos, sz, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.Font = font
    l.TextColor3 = color
    l.Position = pos
    l.Size = sz
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function getHumanoid()
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- ScreenGui
local old = player:WaitForChild("PlayerGui"):FindFirstChild("AllMapHubGui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AllMapHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- ==================== FLY CONTROL BUTTONS (TRANSPARAN) ====================
local flyControlFrame = Instance.new("Frame")
flyControlFrame.Name = "FlyControls"
flyControlFrame.Size = UDim2.new(0, 40, 0, 86)
flyControlFrame.Position = UDim2.new(1, -50, 0.5, -43)
flyControlFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
flyControlFrame.BackgroundTransparency = 1
flyControlFrame.BorderSizePixel = 0
flyControlFrame.Visible = false
flyControlFrame.Parent = screenGui
corner(flyControlFrame, 10)

local function makeFlyArrow(text, yPos)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.Position = UDim2.new(0, 0, 0, yPos)
    b.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    b.BackgroundTransparency = 0.88
    b.Text = text
    b.TextSize = 20
    b.TextTransparency = 0.35
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = flyControlFrame
    corner(b, 8)
    return b
end

local flyUpBtn = makeFlyArrow("↑", 0)
local flyDownBtn = makeFlyArrow("↓", 46)

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 235, 0, 330)
mainFrame.BackgroundColor3 = BG_BLACK
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
corner(mainFrame, 14)
stroke(mainFrame, BORDER_BLUE, 2)

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = BG_BLACK
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
corner(topBar, 14)

local globeIcon = Instance.new("TextLabel")
globeIcon.Size = UDim2.new(0, 22, 0, 22)
globeIcon.Position = UDim2.new(0, 10, 0, 10)
globeIcon.BackgroundTransparency = 1
globeIcon.Text = "🌐"
globeIcon.TextSize = 18
globeIcon.Font = Enum.Font.GothamBold
globeIcon.TextColor3 = WHITE
globeIcon.Parent = topBar

newLabel(topBar, "ALL MAP HUB", 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 36, 0, 8), UDim2.new(1, -80, 0, 20), Enum.TextXAlignment.Left)
newLabel(topBar, "Universal Player Hub", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 28), UDim2.new(1, -80, 0, 12), Enum.TextXAlignment.Left)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 10, 0, 44)
statusDot.BackgroundColor3 = GREEN
statusDot.BorderSizePixel = 0
statusDot.Parent = topBar
corner(statusDot, 3)

newLabel(topBar, "ONLINE", 8, Enum.Font.GothamBold, GREEN, UDim2.new(0, 20, 0, 40), UDim2.new(0, 50, 0, 12), Enum.TextXAlignment.Left)

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -60, 0, 10)
minBtn.BackgroundColor3 = BG_BUTTON
minBtn.Text = "−"
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = WHITE
minBtn.AutoButtonColor = false
minBtn.Parent = topBar
corner(minBtn, 6)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Close Button (cleanup semua fitur)
local cleanupFns = {}

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
closeBtn.Text = "✕"
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = RED
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar
corner(closeBtn, 6)

closeBtn.MouseButton1Click:Connect(function()
    for _, fn in ipairs(cleanupFns) do pcall(fn) end
    screenGui:Destroy()
end)

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -16, 0, 28)
tabContainer.Position = UDim2.new(0, 8, 0, 54)
tabContainer.BackgroundColor3 = BG_DARK
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame
corner(tabContainer, 8)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabContainer

-- Pages
local pages = {}
local tabButtons = {}

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -140)
    page.Position = UDim2.new(0, 8, 0, 88)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = ACCENT_BLUE
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = mainFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingBottom = UDim.new(0, 8)
    padding.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    pages[name] = page
    return page
end

local farmPage = makePage("FARM")
local serverPage = makePage("SERVER")
local playerPage = makePage("PLAYER")

local function makeTabButton(name, icon, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33, -2, 1, 0)
    btn.BackgroundColor3 = BG_BUTTON
    btn.Text = icon .. " " .. text
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = GREY
    btn.AutoButtonColor = false
    btn.Parent = tabContainer
    corner(btn, 6)

    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        for n, b in pairs(tabButtons) do
            if n == name then
                b.BackgroundColor3 = ACCENT_BLUE
                b.TextColor3 = WHITE
                pages[n].Visible = true
            else
                b.BackgroundColor3 = BG_BUTTON
                b.TextColor3 = GREY
                pages[n].Visible = false
            end
        end
    end)
end

makeTabButton("FARM", "🌾", "FARM")
makeTabButton("SERVER", "🖥️", "SERVER")
makeTabButton("PLAYER", "👤", "PLAYER")

tabButtons["FARM"].BackgroundColor3 = ACCENT_BLUE
tabButtons["FARM"].TextColor3 = WHITE
pages["FARM"].Visible = true

-- ==================== FARM PAGE ====================
local function makeButton(parent, text, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = BG_BUTTON
    btn.Text = text
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = WHITE
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 8)
    return btn
end

local function makeFarmButton(text, order)
    return makeButton(farmPage, text, order)
end

newLabel(farmPage, " FARM / MOVEMENT", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 0

-- SPEED
local speedFrame = Instance.new("Frame")
speedFrame.LayoutOrder = 1
speedFrame.Size = UDim2.new(1, 0, 0, 52)
speedFrame.BackgroundColor3 = BG_DARK
speedFrame.BorderSizePixel = 0
speedFrame.Parent = farmPage
corner(speedFrame, 8)

newLabel(speedFrame, "🏃 SPEED", 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), Enum.TextXAlignment.Left)

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(1, -16, 0, 24)
speedInput.Position = UDim2.new(0, 8, 0, 22)
speedInput.BackgroundColor3 = BG_BUTTON
speedInput.Text = "100"
speedInput.TextSize = 12
speedInput.Font = Enum.Font.GothamBold
speedInput.TextColor3 = WHITE
speedInput.ClearTextOnFocus = false
speedInput.Parent = speedFrame
corner(speedInput, 6)

local speedBtn = makeFarmButton("🏃 SPEED • OFF", 2)
local speedOn = false
local speedValue = 100

local function applySpeed()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = speedOn and speedValue or 16
    end
end

speedInput.FocusLost:Connect(function()
    local val = tonumber(speedInput.Text)
    if val and val > 0 then
        speedValue = val
        if speedOn then applySpeed() end
    else
        speedInput.Text = tostring(speedValue)
    end
end)

speedBtn.MouseButton1Click:Connect(function()
    speedOn = not speedOn
    speedBtn.Text = speedOn and "🏃 SPEED • ON" or "🏃 SPEED • OFF"
    speedBtn.BackgroundColor3 = speedOn and ON_COLOR or BG_BUTTON
    applySpeed()
end)

-- ==================== FLY (DIPERBAIKI) ====================
-- Arah terbang mengikuti kamera + joystick/WASD, naik/turun pakai tombol ↑ ↓
-- (atau Space / Shift di PC)
local flyFrame = Instance.new("Frame")
flyFrame.LayoutOrder = 3
flyFrame.Size = UDim2.new(1, 0, 0, 52)
flyFrame.BackgroundColor3 = BG_DARK
flyFrame.BorderSizePixel = 0
flyFrame.Parent = farmPage
corner(flyFrame, 8)

newLabel(flyFrame, "✈️ FLY SPEED", 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), Enum.TextXAlignment.Left)

local flyInput = Instance.new("TextBox")
flyInput.Size = UDim2.new(1, -16, 0, 24)
flyInput.Position = UDim2.new(0, 8, 0, 22)
flyInput.BackgroundColor3 = BG_BUTTON
flyInput.Text = "70"
flyInput.TextSize = 12
flyInput.Font = Enum.Font.GothamBold
flyInput.TextColor3 = WHITE
flyInput.ClearTextOnFocus = false
flyInput.Parent = flyFrame
corner(flyInput, 6)

local flyBtn = makeFarmButton("✈️ FLY • OFF", 4)
local flyOn = false
local flyBV, flyBG, flyConn
local flyUp, flyDown = false, false

local function stopFly()
    flyOn = false
    flyUp, flyDown = false, false
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local hum = getHumanoid()
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    flyControlFrame.Visible = false
    flyBtn.Text = "✈️ FLY • OFF"
    flyBtn.BackgroundColor3 = BG_BUTTON
end

local function startFly()
    local hrp, hum = getHRP(), getHumanoid()
    if not hrp or not hum then return end

    flyOn = true
    flyControlFrame.Visible = true
    flyBtn.Text = "✈️ FLY • ON"
    flyBtn.BackgroundColor3 = ON_COLOR

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 9000
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp

    hum.PlatformStand = true

    flyConn = RunService.RenderStepped:Connect(function()
        local root, h = getHRP(), getHumanoid()
        if not root or not h or not flyBV or not flyBG then
            stopFly()
            return
        end

        local cam = workspace.CurrentCamera
        local speed = tonumber(flyInput.Text) or 70
        local look = cam.CFrame.LookVector
        local dir = h.MoveDirection -- dunia, dari joystick/WASD
        local vel = dir * speed

        -- Kalau maju sambil menghadap atas/bawah, ikut naik/turun
        if dir.Magnitude > 0 then
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0 then
                local forward = dir:Dot(flat.Unit)
                vel = vel + Vector3.new(0, look.Y * forward * speed, 0)
            end
        end

        if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vel = vel + Vector3.new(0, speed, 0)
        end
        if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            vel = vel - Vector3.new(0, speed, 0)
        end

        flyBV.Velocity = vel

        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then
            flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
        end
    end)
end

flyBtn.MouseButton1Click:Connect(function()
    if flyOn then
        stopFly()
    else
        startFly()
    end
end)

local function bindHold(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.MouseLeave:Connect(function() setter(false) end)
end

bindHold(flyUpBtn, function(v) flyUp = v end)
bindHold(flyDownBtn, function(v) flyDown = v end)

table.insert(cleanupFns, function()
    if flyOn then stopFly() end
end)

-- NOCLIP
local noclipBtn = makeFarmButton("🚫 NOCLIP • OFF", 5)
local noclipOn = false
local noclipConnection

noclipBtn.MouseButton1Click:Connect(function()
    noclipOn = not noclipOn
    noclipBtn.Text = noclipOn and "🚫 NOCLIP • ON" or "🚫 NOCLIP • OFF"
    noclipBtn.BackgroundColor3 = noclipOn and ON_COLOR or BG_BUTTON

    if noclipOn then
        noclipConnection = RunService.Stepped:Connect(function()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
    end
end)

table.insert(cleanupFns, function()
    if noclipConnection then noclipConnection:Disconnect() end
end)

-- INF JUMP (pakai JumpRequest, lebih ringan dari loop)
local infJumpBtn = makeFarmButton("🦘 INF JUMP • OFF", 6)
local infJumpOn = false

infJumpBtn.MouseButton1Click:Connect(function()
    infJumpOn = not infJumpOn
    infJumpBtn.Text = infJumpOn and "🦘 INF JUMP • ON" or "🦘 INF JUMP • OFF"
    infJumpBtn.BackgroundColor3 = infJumpOn and ON_COLOR or BG_BUTTON
end)

local jumpConn = UserInputService.JumpRequest:Connect(function()
    if infJumpOn and not flyOn then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
table.insert(cleanupFns, function() jumpConn:Disconnect() end)

-- ESP
local espBtn = makeFarmButton("👁️ ESP • OFF", 7)
local espOn = false
local espHighlights = {}

local function removeESP(p)
    if espHighlights[p] then
        espHighlights[p]:Destroy()
        espHighlights[p] = nil
    end
end

local function addESP(p)
    if p == player or not p.Character then return end
    removeESP(p)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.Parent = p.Character
    espHighlights[p] = highlight
end

espBtn.MouseButton1Click:Connect(function()
    espOn = not espOn
    espBtn.Text = espOn and "👁️ ESP • ON" or "👁️ ESP • OFF"
    espBtn.BackgroundColor3 = espOn and ON_COLOR or BG_BUTTON

    if espOn then
        for _, p in ipairs(Players:GetPlayers()) do
            addESP(p)
        end
    else
        for p in pairs(espHighlights) do removeESP(p) end
    end
end)

local function hookPlayerESP(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espOn then addESP(p) end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then hookPlayerESP(p) end
end
Players.PlayerAdded:Connect(hookPlayerESP)
Players.PlayerRemoving:Connect(removeESP)

-- ==================== SERVER PAGE ====================
newLabel(serverPage, "🖥️ SERVER TOOLS", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 0

-- ANTI LAG: matikan efek berat saat ON
local antiLagBtn = makeButton(serverPage, "⚡ ANTI LAG • OFF", 1)
local antiLagOn = false
antiLagBtn.MouseButton1Click:Connect(function()
    antiLagOn = not antiLagOn
    antiLagBtn.Text = antiLagOn and "⚡ ANTI LAG • ON" or "⚡ ANTI LAG • OFF"
    antiLagBtn.BackgroundColor3 = antiLagOn and ON_COLOR or BG_BUTTON

    if antiLagOn then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end
end)

-- ANTI AFK
local antiAfkBtn = makeButton(serverPage, "💤 ANTI AFK • OFF", 2)
local antiAfkOn = false
antiAfkBtn.MouseButton1Click:Connect(function()
    antiAfkOn = not antiAfkOn
    antiAfkBtn.Text = antiAfkOn and "💤 ANTI AFK • ON" or "💤 ANTI AFK • OFF"
    antiAfkBtn.BackgroundColor3 = antiAfkOn and ON_COLOR or BG_BUTTON
end)

local afkConn = player.Idled:Connect(function()
    if antiAfkOn then
        local ok, vu = pcall(function() return game:GetService("VirtualUser") end)
        if ok and vu then
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end
    end
end)
table.insert(cleanupFns, function() afkConn:Disconnect() end)

local rejoinBtn = makeButton(serverPage, "🔄 REJOIN SERVER", 3)
rejoinBtn.MouseButton1Click:Connect(function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

local hopBtn = makeButton(serverPage, "🌐 SERVER HOP", 4)
hopBtn.MouseButton1Click:Connect(function()
    hopBtn.Text = "⏳ Hopping..."
    local servers = {}
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and result and result.data then
        for _, s in ipairs(result.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
    else
        hopBtn.Text = "⚠️ TIDAK ADA SERVER"
        task.delay(1.5, function() hopBtn.Text = "🌐 SERVER HOP" end)
    end
end)

-- ==================== PLAYER PAGE ====================
local function makePlayerButton(text, order)
    return makeButton(playerPage, text, order)
end

newLabel(playerPage, "👤 PLAYER TOOLS", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 0

local savedPos = nil
local savePosBtn = makePlayerButton("💾 SAVE POSITION", 1)
savePosBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if hrp then
        savedPos = hrp.CFrame
        savePosBtn.Text = "✅ SAVED!"
        task.delay(1.5, function()
            savePosBtn.Text = "💾 SAVE POSITION"
        end)
    end
end)

local tpSavedBtn = makePlayerButton("📍 TELEPORT SAVED", 2)
tpSavedBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if hrp and savedPos then
        hrp.CFrame = savedPos
        tpSavedBtn.Text = "✅ TP!"
        task.delay(1.5, function()
            tpSavedBtn.Text = "📍 TELEPORT SAVED"
        end)
    end
end)

local resetBtn = makePlayerButton("💀 RESET CHARACTER", 3)
resetBtn.MouseButton1Click:Connect(function()
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
end)

-- ==================== SELECT PLAYER (DIPERBAIKI) ====================
-- Bug lama: row adalah Frame, Frame tidak punya MouseButton1Click.
-- Sekarang row adalah TextButton, pilih 1 player, ada tombol teleport.
local selectPlayerBtn = makePlayerButton("🎯 SELECT PLAYER", 4)
local selectPlayerOpen = false
local selectedPlayer = nil

local selectPlayerFrame = Instance.new("Frame")
selectPlayerFrame.LayoutOrder = 5
selectPlayerFrame.Size = UDim2.new(1, 0, 0, 120)
selectPlayerFrame.BackgroundColor3 = BG_DARK
selectPlayerFrame.BorderSizePixel = 0
selectPlayerFrame.Visible = false
selectPlayerFrame.Parent = playerPage
corner(selectPlayerFrame, 8)
stroke(selectPlayerFrame, BORDER_BLUE, 1)

local spTitle = newLabel(selectPlayerFrame, "Pilih player (klik untuk pilih)", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), Enum.TextXAlignment.Left)

local spScroll = Instance.new("ScrollingFrame")
spScroll.Size = UDim2.new(1, -8, 1, -24)
spScroll.Position = UDim2.new(0, 4, 0, 22)
spScroll.BackgroundTransparency = 1
spScroll.BorderSizePixel = 0
spScroll.ScrollBarThickness = 3
spScroll.ScrollBarImageColor3 = ACCENT_BLUE
spScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
spScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
spScroll.Parent = selectPlayerFrame

local spLayout = Instance.new("UIListLayout")
spLayout.Padding = UDim.new(0, 3)
spLayout.SortOrder = Enum.SortOrder.Name
spLayout.Parent = spScroll

local tpPlayerBtn = makePlayerButton("🚀 TELEPORT PLAYER", 6)

local function updateSelectedUI()
    if selectedPlayer then
        spTitle.Text = "Dipilih: " .. selectedPlayer.DisplayName
        tpPlayerBtn.Text = "🚀 TP KE " .. string.upper(selectedPlayer.DisplayName)
    else
        spTitle.Text = "Pilih player (klik untuk pilih)"
        tpPlayerBtn.Text = "🚀 TELEPORT PLAYER"
    end
end

local function refreshSelectList()
    for _, child in ipairs(spScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- kalau player yang dipilih sudah keluar
    if selectedPlayer and selectedPlayer.Parent ~= Players then
        selectedPlayer = nil
        updateSelectedUI()
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local isSelected = (selectedPlayer == p)

            local row = Instance.new("TextButton")
            row.Name = p.Name
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = isSelected and ON_COLOR or BG_BUTTON
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = spScroll
            corner(row, 6)

            local avFrame = Instance.new("Frame")
            avFrame.Size = UDim2.new(0, 24, 0, 24)
            avFrame.Position = UDim2.new(0, 4, 0.5, -12)
            avFrame.BackgroundColor3 = BG_DARK
            avFrame.Parent = row
            corner(avFrame, 12)

            local avImg = Instance.new("ImageLabel")
            avImg.Size = UDim2.new(1, -2, 1, -2)
            avImg.Position = UDim2.new(0, 1, 0, 1)
            avImg.BackgroundTransparency = 1
            avImg.ScaleType = Enum.ScaleType.Crop
            avImg.Parent = avFrame
            corner(avImg, 11)

            task.spawn(function()
                local ok, thumb = pcall(function()
                    return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok then avImg.Image = thumb end
            end)

            newLabel(row, p.DisplayName, 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 34, 0, 0), UDim2.new(1, -64, 1, 0), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd

            local checkMark = Instance.new("TextLabel")
            checkMark.Size = UDim2.new(0, 20, 1, 0)
            checkMark.Position = UDim2.new(1, -24, 0, 0)
            checkMark.BackgroundTransparency = 1
            checkMark.Text = "✓"
            checkMark.TextSize = 14
            checkMark.Font = Enum.Font.GothamBold
            checkMark.TextColor3 = GREEN
            checkMark.Visible = isSelected
            checkMark.Parent = row

            row.MouseButton1Click:Connect(function()
                if selectedPlayer == p then
                    selectedPlayer = nil -- klik lagi = batal pilih
                else
                    selectedPlayer = p
                end
                updateSelectedUI()
                refreshSelectList()
            end)
        end
    end
end

selectPlayerBtn.MouseButton1Click:Connect(function()
    selectPlayerOpen = not selectPlayerOpen
    selectPlayerFrame.Visible = selectPlayerOpen

    if selectPlayerOpen then
        selectPlayerBtn.Text = "🎯 CLOSE SELECT"
        refreshSelectList()
    else
        selectPlayerBtn.Text = "🎯 SELECT PLAYER"
    end
end)

-- Auto refresh saat ada player masuk/keluar
Players.PlayerAdded:Connect(function()
    if selectPlayerOpen then refreshSelectList() end
end)
Players.PlayerRemoving:Connect(function(p)
    if selectedPlayer == p then
        selectedPlayer = nil
        updateSelectedUI()
    end
    task.defer(function()
        if selectPlayerOpen then refreshSelectList() end
    end)
end)

-- TELEPORT PLAYER
tpPlayerBtn.MouseButton1Click:Connect(function()
    local function flash(text, color)
        tpPlayerBtn.Text = text
        tpPlayerBtn.BackgroundColor3 = color
        task.delay(1.5, function()
            tpPlayerBtn.BackgroundColor3 = BG_BUTTON
            updateSelectedUI()
        end)
    end

    if not selectedPlayer then
        flash("⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40))
        return
    end

    local targetHrp = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = getHRP()

    if targetHrp and myHrp then
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
        flash("✅ TELEPORTED!", ON_COLOR)
    else
        flash("⚠️ PLAYER BELUM SPAWN", Color3.fromRGB(80, 40, 40))
    end
end)

-- ==================== USER PROFILE ====================
local userBox = Instance.new("Frame")
userBox.Size = UDim2.new(1, -16, 0, 38)
userBox.Position = UDim2.new(0, 8, 1, -44)
userBox.BackgroundColor3 = BG_DARK
userBox.BorderSizePixel = 0
userBox.Parent = mainFrame
corner(userBox, 8)
stroke(userBox, BORDER_BLUE, 1)

local userAvatarFrame = Instance.new("Frame")
userAvatarFrame.Size = UDim2.new(0, 28, 0, 28)
userAvatarFrame.Position = UDim2.new(0, 6, 0.5, -14)
userAvatarFrame.BackgroundColor3 = BG_BLACK
userAvatarFrame.Parent = userBox
corner(userAvatarFrame, 14)
stroke(userAvatarFrame, ACCENT_BLUE, 1)

local userAvatarImg = Instance.new("ImageLabel")
userAvatarImg.Size = UDim2.new(1, -4, 1, -4)
userAvatarImg.Position = UDim2.new(0, 2, 0, 2)
userAvatarImg.BackgroundTransparency = 1
userAvatarImg.ScaleType = Enum.ScaleType.Crop
userAvatarImg.Parent = userAvatarFrame
corner(userAvatarImg, 12)

task.spawn(function()
    local ok, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok then userAvatarImg.Image = thumb end
end)

newLabel(userBox, player.DisplayName, 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 40, 0, 3), UDim2.new(1, -46, 0, 16), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd
newLabel(userBox, "@" .. player.Name, 8, Enum.Font.Gotham, GREY, UDim2.new(0, 40, 0, 19), UDim2.new(1, -46, 0, 14), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd

-- ==================== CHARACTER RESPAWN ====================
player.CharacterAdded:Connect(function(c)
    character = c
    -- matikan fly (BodyMover lama ikut hilang bersama karakter)
    if flyConn then flyConn:Disconnect() flyConn = nil end
    flyBV, flyBG = nil, nil
    flyOn, flyUp, flyDown = false, false, false
    flyControlFrame.Visible = false
    flyBtn.Text = "✈️ FLY • OFF"
    flyBtn.BackgroundColor3 = BG_BUTTON

    c:WaitForChild("Humanoid")
    if speedOn then applySpeed() end
end)

-- ==================== DRAGGABLE (mouse + touch) ====================
local dragging = false
local dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

local dragConn = UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
table.insert(cleanupFns, function() dragConn:Disconnect() end)

-- Logo Button
local logoBtn = Instance.new("TextButton")
logoBtn.Size = UDim2.new(0, 44, 0, 44)
logoBtn.Position = UDim2.new(0, 15, 0.5, -22)
logoBtn.BackgroundColor3 = BG_BLACK
logoBtn.Text = "$"
logoBtn.TextSize = 20
logoBtn.Font = Enum.Font.GothamBlack
logoBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
logoBtn.Parent = screenGui
corner(logoBtn, 22)
stroke(logoBtn, Color3.fromRGB(255, 215, 0), 2)

logoBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

print("✅ ALL MAP HUB Loaded!")

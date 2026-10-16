local __ok, __err = xpcall(function()
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
screenGui.IgnoreGuiInset = true
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
mainFrame.Size = UDim2.new(0, 265, 0, 375)
mainFrame.BackgroundColor3 = BG_BLACK
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
corner(mainFrame, 14)
stroke(mainFrame, BORDER_BLUE, 2)

-- Background image
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "Background"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxassetid://134262192520482"
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ImageTransparency = 0
bgImage.ZIndex = 0
bgImage.Parent = mainFrame
corner(bgImage, 12)

local BG_ASSET_ID = "134262192520482"
task.spawn(function()
    -- Kalau ID itu ternyata Decal, ambil ID gambar aslinya lewat GetObjects (executor)
    local ok, objs = pcall(function()
        return game:GetObjects("rbxassetid://" .. BG_ASSET_ID)
    end)
    if ok and objs and objs[1] then
        local o = objs[1]
        local d = (o:IsA("Decal") or o:IsA("Texture")) and o or o:FindFirstChildWhichIsA("Decal", true) or o:FindFirstChildWhichIsA("Texture", true)
        if d and d.Texture and d.Texture ~= "" then
            bgImage.Image = d.Texture
        end
    end
end)

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

newLabel(topBar, "UNIVERSAL", 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 36, 0, 8), UDim2.new(1, -80, 0, 20), Enum.TextXAlignment.Left)
newLabel(topBar, "Player Hub", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 28), UDim2.new(1, -80, 0, 12), Enum.TextXAlignment.Left)

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

do
-- ==================== INFO BAR (FPS / PING / PLAYER / MEMORI) — paling atas layar ====================
local Stats = game:GetService("Stats")

local infoBar = Instance.new("Frame")
infoBar.Name = "InfoBar"
infoBar.Size = UDim2.new(0, 290, 0, 20)
infoBar.Position = UDim2.new(0.5, -145, 0, 2)
infoBar.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
infoBar.BackgroundTransparency = 0.35
infoBar.BorderSizePixel = 0
infoBar.ZIndex = 50
infoBar.Parent = screenGui
corner(infoBar, 10)
stroke(infoBar, ACCENT_BLUE, 1)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -8, 1, 0)
infoLabel.Position = UDim2.new(0, 4, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "📊 FPS --  |  📶 --ms"
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextColor3 = GREEN
infoLabel.ZIndex = 51
infoLabel.Parent = infoBar

local infoFrames, infoAcc = 0, 0
local infoConn = RunService.RenderStepped:Connect(function(dt)
    infoFrames = infoFrames + 1
    infoAcc = infoAcc + dt
    if infoAcc >= 0.5 then
        local fps = math.floor(infoFrames / infoAcc + 0.5)
        infoFrames, infoAcc = 0, 0

        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        local mem = 0
        pcall(function()
            mem = math.floor(Stats:GetTotalMemoryUsageMb())
        end)

        infoLabel.Text = string.format("📊 FPS %d  |  📶 %dms  |  👥 %d  |  💾 %dMB", fps, ping, #Players:GetPlayers(), mem)
        infoLabel.TextColor3 = (ping < 100 and GREEN) or (ping < 200 and Color3.fromRGB(250, 204, 21)) or RED
    end
end)
table.insert(cleanupFns, function() infoConn:Disconnect() end)
end


local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
closeBtn.Text = "X"
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
local teleportPage = makePage("TELEPORT")

local function makeTabButton(name, icon, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -3, 1, 0)
    btn.BackgroundColor3 = BG_BUTTON
    btn.Text = icon .. " " .. text
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = GREY
    btn.AutoButtonColor = false
    btn.Parent = tabContainer
    corner(btn, 6)
    btn.TextScaled = true
    local tabLimit = Instance.new("UITextSizeConstraint")
    tabLimit.MaxTextSize = 9
    tabLimit.Parent = btn

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
makeTabButton("TELEPORT", "📍", "TELEPORT")

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

-- GODMODE (auto-heal saat kena hit)
local godBtn = makeFarmButton("🛡️ GODMODE • OFF", 8)
local godOn = false
local godConn

local function hookGod()
    if godConn then godConn:Disconnect() godConn = nil end
    local hum = getHumanoid()
    if not hum or not godOn then return end
    hum.Health = hum.MaxHealth
    godConn = hum.HealthChanged:Connect(function(hp)
        if godOn and hp > 0 and hp < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
end

godBtn.MouseButton1Click:Connect(function()
    godOn = not godOn
    godBtn.Text = godOn and "🛡️ GODMODE • ON" or "🛡️ GODMODE • OFF"
    godBtn.BackgroundColor3 = godOn and ON_COLOR or BG_BUTTON
    hookGod()
end)

table.insert(cleanupFns, function()
    if godConn then godConn:Disconnect() end
end)

-- INVISIBLE (client-side)
local invisBtn = makeFarmButton("👻 INVISIBLE • OFF", 9)
local invisOn = false
local invisOriginal = {}
local invisConn
local origDisplayType

local function setInvisible(obj)
    if (obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart") or obj:IsA("Decal") then
        if invisOriginal[obj] == nil then invisOriginal[obj] = obj.Transparency end
        obj.Transparency = 1
    end
end

local function clearInvisible()
    if invisConn then invisConn:Disconnect() invisConn = nil end
    for obj, t in pairs(invisOriginal) do
        if obj and obj.Parent then obj.Transparency = t end
    end
    invisOriginal = {}
    local hum = getHumanoid()
    if hum and origDisplayType then
        hum.DisplayDistanceType = origDisplayType
        origDisplayType = nil
    end
end

local function applyInvisible()
    clearInvisible()
    if not invisOn or not character then return end
    local hum = getHumanoid()
    if hum then
        origDisplayType = hum.DisplayDistanceType
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    for _, d in ipairs(character:GetDescendants()) do setInvisible(d) end
    invisConn = character.DescendantAdded:Connect(function(d)
        if invisOn then setInvisible(d) end
    end)
end

invisBtn.MouseButton1Click:Connect(function()
    invisOn = not invisOn
    invisBtn.Text = invisOn and "👻 INVISIBLE • ON" or "👻 INVISIBLE • OFF"
    invisBtn.BackgroundColor3 = invisOn and ON_COLOR or BG_BUTTON
    applyInvisible()
end)

table.insert(cleanupFns, function()
    if invisOn then invisOn = false clearInvisible() end
end)

do
-- WALK ON AIR: papan tak terlihat di bawah kaki yang ikut kamu. Lompat = naik 4 stud.
local airBtn = makeFarmButton("🌊 WALK ON AIR • OFF", 10)
local airOn = false
local airPart, airConn, airJumpConn
local airY = 0

local function stopAir()
    airOn = false
    if airConn then airConn:Disconnect() airConn = nil end
    if airJumpConn then airJumpConn:Disconnect() airJumpConn = nil end
    if airPart then airPart:Destroy() airPart = nil end
    airBtn.Text = "🌊 WALK ON AIR • OFF"
    airBtn.BackgroundColor3 = BG_BUTTON
end

airBtn.MouseButton1Click:Connect(function()
    if airOn then
        stopAir()
        return
    end

    local hrp, hum = getHRP(), getHumanoid()
    if not hrp then return end

    airOn = true
    airBtn.Text = "🌊 WALK ON AIR • ON"
    airBtn.BackgroundColor3 = ON_COLOR

    -- posisi telapak kaki sekarang
    local feetOffset = (hrp.Size.Y / 2) + (hum and hum.HipHeight or 2)
    airY = hrp.Position.Y - feetOffset - 0.5

    airPart = Instance.new("Part")
    airPart.Name = "_AirWalk"
    airPart.Size = Vector3.new(8, 1, 8)
    airPart.Transparency = 1
    airPart.Anchored = true
    airPart.CanCollide = true
    airPart.CanQuery = false
    airPart.CanTouch = false
    airPart.Parent = workspace

    airConn = RunService.Heartbeat:Connect(function()
        local r = getHRP()
        if not (r and airPart) then return end
        airPart.CFrame = CFrame.new(r.Position.X, airY, r.Position.Z)
    end)

    airJumpConn = UserInputService.JumpRequest:Connect(function()
        if airOn then airY = airY + 4 end
    end)
end)

table.insert(cleanupFns, function() if airOn then stopAir() end end)
player.CharacterAdded:Connect(function() if airOn then stopAir() end end)
end


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

-- ==================== SERVER HOP PANEL ====================
local STATUS_GREY = Color3.fromRGB(150, 160, 180)
local TEAL = Color3.fromRGB(0, 150, 170)

newLabel(serverPage, "🚀 SERVER HOP PANEL", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 4

-- Max players input
local maxFrame = Instance.new("Frame")
maxFrame.LayoutOrder = 5
maxFrame.Size = UDim2.new(1, 0, 0, 54)
maxFrame.BackgroundColor3 = BG_DARK
maxFrame.BorderSizePixel = 0
maxFrame.Parent = serverPage
corner(maxFrame, 8)

newLabel(maxFrame, "👥 MAX PLAYERS (for Hop)", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), Enum.TextXAlignment.Left)

local maxInput = Instance.new("TextBox")
maxInput.Size = UDim2.new(1, -16, 0, 24)
maxInput.Position = UDim2.new(0, 8, 0, 24)
maxInput.BackgroundColor3 = BG_BUTTON
maxInput.Text = "5"
maxInput.TextSize = 13
maxInput.Font = Enum.Font.GothamBold
maxInput.TextColor3 = WHITE
maxInput.ClearTextOnFocus = false
maxInput.Parent = maxFrame
corner(maxInput, 6)

maxInput.FocusLost:Connect(function()
    local v = tonumber(maxInput.Text)
    if v and v >= 1 then
        maxInput.Text = tostring(math.floor(v))
    else
        maxInput.Text = "5"
    end
end)

local hopBtn = makeButton(serverPage, "🚀 HOP SERVER", 6)
hopBtn.BackgroundColor3 = ACCENT_BLUE
local rejoinBtn = makeButton(serverPage, "🔄 REJOIN SERVER", 7)
local randomBtn = makeButton(serverPage, "🎲 RANDOM SERVER", 8)

local statusLabel = newLabel(serverPage, "Status: Ready 💡", 10, Enum.Font.GothamBold, GREEN, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Left)
statusLabel.LayoutOrder = 9

local function setStatus(text, color)
    statusLabel.Text = "Status: " .. text
    statusLabel.TextColor3 = color or GREEN
end

-- HTTP helper (works with executors that provide HttpGet or request)
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    local req = (typeof(request) == "function" and request) or (typeof(http_request) == "function" and http_request) or (syn and syn.request)
    if req then
        local ok2, r = pcall(function() return req({Url = url, Method = "GET"}) end)
        if ok2 and r and r.Body then return r.Body end
    end
    return nil
end

local function fetchServers()
    local body = httpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100")
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data or not data.data then return nil end
    local list = {}
    for _, s in ipairs(data.data) do
        if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
            table.insert(list, {id = s.id, playing = s.playing, maxPlayers = s.maxPlayers})
        end
    end
    return list
end

local function joinServer(id)
    setStatus("Teleporting... 🚀", GREEN)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player)
    end)
    if not ok then setStatus("Teleport failed ❌", RED) end
end

local busy = false
local function hopTo(mode)
    if busy then return end
    busy = true
    setStatus("Searching for servers... 🔎", STATUS_GREY)
    local servers = fetchServers()
    if not servers then
        setStatus("Could not load servers ❌", RED)
        busy = false
        return
    end
    local maxP = tonumber(maxInput.Text) or 5
    local pool = {}
    for _, s in ipairs(servers) do
        if mode == "random" or s.playing <= maxP then
            table.insert(pool, s)
        end
    end
    if #pool == 0 then
        setStatus("No matching server found ⚠️", Color3.fromRGB(255, 190, 70))
        busy = false
        return
    end
    local pick = pool[math.random(1, #pool)]
    busy = false
    joinServer(pick.id)
end

hopBtn.MouseButton1Click:Connect(function() hopTo("hop") end)
randomBtn.MouseButton1Click:Connect(function() hopTo("random") end)
rejoinBtn.MouseButton1Click:Connect(function()
    joinServer(game.JobId)
end)

-- Filter: Few / Medium / Many
local filterFrame = Instance.new("Frame")
filterFrame.LayoutOrder = 10
filterFrame.Size = UDim2.new(1, 0, 0, 50)
filterFrame.BackgroundColor3 = BG_DARK
filterFrame.BorderSizePixel = 0
filterFrame.Parent = serverPage
corner(filterFrame, 8)

newLabel(filterFrame, "🔎 FILTER BY POPULATION", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 3), UDim2.new(1, -16, 0, 16), Enum.TextXAlignment.Left)

local filterRow = Instance.new("Frame")
filterRow.Size = UDim2.new(1, -16, 0, 24)
filterRow.Position = UDim2.new(0, 8, 0, 21)
filterRow.BackgroundTransparency = 1
filterRow.Parent = filterFrame

local filterLayout = Instance.new("UIListLayout")
filterLayout.FillDirection = Enum.FillDirection.Horizontal
filterLayout.Padding = UDim.new(0, 4)
filterLayout.Parent = filterRow

local activeFilter = nil -- nil = show all
local filterButtons = {}
local renderList -- forward declaration

local function makeFilterButton(key, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1/3, -3, 1, 0)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = filterRow
    corner(b, 6)
    filterButtons[key] = b
    b.MouseButton1Click:Connect(function()
        activeFilter = (activeFilter == key) and nil or key -- tap again to clear
        for k, btn in pairs(filterButtons) do
            btn.BackgroundColor3 = (k == activeFilter) and ACCENT_BLUE or BG_BUTTON
        end
        if renderList then renderList() end
    end)
end

makeFilterButton("few", "🟢 Few")
makeFilterButton("medium", "🟡 Medium")
makeFilterButton("many", "🔴 Many")

-- Refresh button + server list
local refreshBtn = makeButton(serverPage, "⚡ REFRESH SERVER LIST", 11)
refreshBtn.BackgroundColor3 = TEAL

local listFrame = Instance.new("ScrollingFrame")
listFrame.LayoutOrder = 12
listFrame.Size = UDim2.new(1, 0, 0, 130)
listFrame.BackgroundColor3 = BG_DARK
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 3
listFrame.ScrollBarImageColor3 = ACCENT_BLUE
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = serverPage
corner(listFrame, 8)

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local serverCache = {}

local function matchesFilter(s)
    if not activeFilter then return true end
    local ratio = s.playing / s.maxPlayers
    if activeFilter == "few" then return ratio <= 0.34 end
    if activeFilter == "medium" then return ratio > 0.34 and ratio <= 0.67 end
    return ratio > 0.67
end

renderList = function()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local shown = 0
    for i, s in ipairs(serverCache) do
        if matchesFilter(s) then
            shown = shown + 1
            local row = Instance.new("TextButton")
            row.LayoutOrder = i
            row.Size = UDim2.new(1, 0, 0, 28)
            row.BackgroundColor3 = BG_BUTTON
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = listFrame
            corner(row, 6)

            newLabel(row, string.format("👥 %d/%d players", s.playing, s.maxPlayers), 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(0.65, 0, 1, 0), Enum.TextXAlignment.Left)
            newLabel(row, "JOIN ▶", 9, Enum.Font.GothamBold, GREEN, UDim2.new(0.65, 0, 0, 0), UDim2.new(0.35, -8, 1, 0), Enum.TextXAlignment.Right)

            row.MouseButton1Click:Connect(function()
                joinServer(s.id)
            end)
        end
    end

    if shown == 0 then
        local empty = newLabel(listFrame, #serverCache == 0 and "Tap refresh to load servers" or "No servers match this filter", 10, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), Enum.TextXAlignment.Center)
        empty.LayoutOrder = 1
    end
end

refreshBtn.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    refreshBtn.Text = "⏳ Loading..."
    setStatus("Loading server list... 🔎", STATUS_GREY)
    local servers = fetchServers()
    busy = false
    refreshBtn.Text = "⚡ REFRESH SERVER LIST"
    if not servers then
        setStatus("Could not load servers ❌", RED)
        return
    end
    serverCache = servers
    renderList()
    setStatus("Found " .. #servers .. " servers ✅", GREEN)
end)

renderList()

-- ==================== VERIFIED BUNDLE: ADMIN (visual, hanya terlihat di layar kamu) ====================
-- Bundle: display name + @username kamu di atas kepala (tanpa centang), mengikuti akun yang menjalankan script.
local TextChatService = game:GetService("TextChatService")
local StarterGuiSvc = game:GetService("StarterGui")

local adminOn = false
local adminGui

local adminOrigDisplay = nil

local function removeAdminBadge()
    if adminGui then adminGui:Destroy() adminGui = nil end

    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum and adminOrigDisplay then
        hum.DisplayDistanceType = adminOrigDisplay
    end
    adminOrigDisplay = nil
end

local function applyAdminBadge()
    removeAdminBadge()
    if not adminOn or not character then return end
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then return end

    -- sembunyikan nama bawaan supaya tidak dobel dengan tag kita
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        adminOrigDisplay = hum.DisplayDistanceType
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "VerifiedAdminBadge"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 170, 0, 38)
    gui.StudsOffset = Vector3.new(0, 2.6, 0)
    gui.AlwaysOnTop = true
    gui.Parent = screenGui

    -- baris atas: display name akun yang menjalankan script (tanpa centang)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 22)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = player.DisplayName
    nameLbl.TextColor3 = WHITE
    nameLbl.TextSize = 16
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.Parent = gui

    -- baris bawah: @username
    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size = UDim2.new(1, 0, 0, 14)
    roleLbl.Position = UDim2.new(0, 0, 0, 22)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Text = "@" .. player.Name
    roleLbl.TextColor3 = Color3.fromRGB(190, 205, 225)
    roleLbl.TextSize = 11
    roleLbl.Font = Enum.Font.GothamBold
    roleLbl.TextStrokeTransparency = 0.5
    roleLbl.Parent = gui

    adminGui = gui
end

local function adminNotice(text)
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local ch = TextChatService:FindFirstChild("TextChannels")
            local general = ch and ch:FindFirstChild("RBXGeneral")
            if general then general:DisplaySystemMessage(text) end
        else
            StarterGuiSvc:SetCore("ChatMakeSystemMessage", {
                Text = text,
                Color = Color3.fromRGB(59, 156, 255),
                Font = Enum.Font.GothamBold,
            })
        end
    end)
end

newLabel(serverPage, "✔ VERIFIED BUNDLE", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = -2 -- paling atas di tab SERVER

local adminBtn = makeButton(serverPage, "✔ VERIFIED • ADMIN • OFF", -1)
adminBtn.MouseButton1Click:Connect(function()
    adminOn = not adminOn
    adminBtn.Text = adminOn and "✔ VERIFIED • ADMIN • ON" or "✔ VERIFIED • ADMIN • OFF"
    adminBtn.BackgroundColor3 = adminOn and ON_COLOR or BG_BUTTON
    applyAdminBadge()
    if adminOn then
        adminNotice(player.DisplayName .. " (@" .. player.Name .. ") tag aktif (hanya terlihat olehmu)")
    end
end)

do
-- FREE CAM (HP: analog = gerak, tombol ↑ ↓ = naik/turun | PC: WASD + E/Q)
local fcOn = false
local fcPart, fcConn
local fcSaved = {}

local fcBtn = makeButton(serverPage, "🎥 FREE CAM • OFF", 3)

local function setFreeCam(on)
    local cam = workspace.CurrentCamera
    fcOn = on
    fcBtn.Text = on and "🎥 FREE CAM • ON" or "🎥 FREE CAM • OFF"
    fcBtn.BackgroundColor3 = on and ON_COLOR or BG_BUTTON

    if on then
        local hrp = getHRP()
        if hrp then
            fcSaved.anchored = hrp.Anchored
            hrp.Anchored = true
        end

        fcPart = Instance.new("Part")
        fcPart.Name = "_FreeCam"
        fcPart.Transparency = 1
        fcPart.Anchored = true
        fcPart.CanCollide = false
        fcPart.CanQuery = false
        fcPart.CanTouch = false
        fcPart.Size = Vector3.new(1, 1, 1)
        fcPart.CFrame = cam.CFrame
        fcPart.Parent = workspace

        fcSaved.minZ = player.CameraMinZoomDistance
        fcSaved.maxZ = player.CameraMaxZoomDistance
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 0.5

        cam.CameraSubject = fcPart
        flyControlFrame.Visible = true -- tombol ↑ ↓ dipakai untuk naik/turun

        fcConn = RunService.RenderStepped:Connect(function(dt)
            if not fcPart then return end
            if cam.CameraSubject ~= fcPart then cam.CameraSubject = fcPart end

            local hum = getHumanoid()
            local move = hum and hum.MoveDirection or Vector3.zero

            local up = 0
            if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.E) then up = up + 1 end
            if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.Q) then up = up - 1 end

            fcPart.CFrame = fcPart.CFrame + (move * 60 + Vector3.new(0, up * 60, 0)) * dt
        end)
    else
        if fcConn then fcConn:Disconnect() fcConn = nil end
        if fcPart then fcPart:Destroy() fcPart = nil end

        if fcSaved.minZ then player.CameraMinZoomDistance = fcSaved.minZ end
        if fcSaved.maxZ then player.CameraMaxZoomDistance = fcSaved.maxZ end

        local hrp = getHRP()
        if hrp and fcSaved.anchored ~= nil then hrp.Anchored = fcSaved.anchored end

        local hum = getHumanoid()
        if hum then cam.CameraSubject = hum end

        flyControlFrame.Visible = flyOn
        fcSaved = {}
    end
end

fcBtn.MouseButton1Click:Connect(function()
    setFreeCam(not fcOn)
end)

table.insert(cleanupFns, function() if fcOn then setFreeCam(false) end end)
player.CharacterAdded:Connect(function() if fcOn then setFreeCam(false) end end)
end


-- ==================== PLAYER PAGE ====================
local function makePlayerButton(text, order)
    return makeButton(playerPage, text, order)
end

newLabel(playerPage, "👤 PLAYER TOOLS", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 0

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

do
-- ==================== COPY AVATAR (SELECT COPY sendiri, terpisah dari SELECT PLAYER) ====================
-- Script Avatar Copier (dari file Copyava) ditanam di sini sebagai teks, lalu dijalankan
-- dengan TargetUsername = player yang kamu pilih.
local COPYAVA_SRC = [=====[
local Config = {
TargetUsername="brockkodile", CopyAvatarHD=false, CopyAvatar=true, DoorsCameraFix=false, SpoofGameEvents=true,
CopyAnimation=false, RestoreYourTagAfterRespawn=true, EnableFreeCam=true, FreeCamKey=Enum.KeyCode.V,
FreeCamSpeed=1.5, DualWieldKey=Enum.KeyCode.R, EditClothesKey=Enum.KeyCode.L, ToggleHeadKey=Enum.KeyCode.H,
ToolsGiverKey=Enum.KeyCode.P, HideUIKey=Enum.KeyCode.K, SecretChatKey=Enum.KeyCode.LeftAlt
}
_G.CEID=(_G.CEID or 0)+1; local MSID=_G.CEID
local function IA() return _G.CEID==MSID end
local g=function(s) return game:GetService(s) end
local Plrs,RS,UIS,SG,HS,US,TS=g("Players"),g("RunService"),g("UserInputService"),g("StarterGui"),g("HttpService"),g("UserService"),g("TweenService")
local lp=Plrs.LocalPlayer; local isM=UIS.TouchEnabled and not UIS.KeyboardEnabled
if _G.CConn then for _,c in ipairs(_G.CConn) do pcall(function() c:Disconnect() end) end end
_G.CConn={}
local function RC(c) table.insert(_G.CConn,c); return c end
pcall(function() RS:UnbindFromRenderStep("CFCam") end)
pcall(function() local pg=lp:FindFirstChild("PlayerGui") if pg then for _,n in ipairs({"CMC","CCUI","CTUI","CopierChatUI"}) do local u=pg:FindFirstChild(n) if u then u:Destroy() end end end end)
_G.CTID=nil; _G.TGA=false; _G.LTC=nil; _G.CSHI=_G.CSHI or {}; _G.CHH=_G.CHH or false; _G.CCM=false
local tL=Config.TargetUsername:lower()

if tL=="restore" or tL=="stop" then
local cam=workspace.CurrentCamera; local ch=lp.Character
if cam and ch then cam.CameraType=Enum.CameraType.Custom; cam.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch:FindFirstChild("Head"); local hrp=ch:FindFirstChild("HumanoidRootPart") if hrp then hrp.Anchored=false end end
pcall(function() SG:SetCore("TopbarEnabled",true); SG:SetCoreGuiEnabled(Enum.CoreGuiType.All,true) end)
pcall(function() local function rE(p) if not p then return end for _,v in ipairs(p:GetChildren()) do if v:IsA("LayerCollector") and v:GetAttribute("CWE")~=nil then v.Enabled=v:GetAttribute("CWE"); v:SetAttribute("CWE",nil) end end end; rE(g("CoreGui")); rE(lp:FindFirstChild("PlayerGui")) end)
if ch then local hm=ch:FindFirstChildOfClass("Humanoid") if hm then hm.Health=0 end end
return end

local S={cD=nil,cU=nil,tN="",tD="",fvOn=false,hdOn=false,hdN="",cDesc=nil,cLA=false,lCS=nil,lCT=nil,sCS={},sCE=0,aC=nil,cRT=nil,fCA=false,fCP=nil,sHRPA=false,sMZ=nil,sMaZ=nil,sZ=nil,oT={},hSOT=false,lC={},tWC=nil,BD={},R15M={}}
local L={"Head","UpperTorso","LowerTorso","LeftFoot","LeftLowerLeg","LeftUpperLeg","RightFoot","RightLowerLeg","RightUpperLeg","LeftHand","LeftLowerArm","LeftUpperArm","RightHand","RightLowerArm","RightUpperArm","Torso","Left Arm","Right Arm","Left Leg","Right Leg","HumanoidRootPart"}
for _,v in ipairs(L) do S.BD[v]=1; pcall(function() S.R15M[v]=Enum.BodyPartR15[v] end) end
local S_PT={}; local F={}; local UIS_State={offX=0,offY=0,offZ=0,scale=1}
_G.CSUI=false; _G.CGUI=true

local function Enc(s) local r="" for i=1,#s do r=r..string.format("%02X",string.byte(s,i)) end return r end
local function Dec(s) local r="" for i=1,#s,2 do pcall(function() r=r..string.char(tonumber(s:sub(i,i+1),16)) end) end return r end
local function SendChat(txt)
    if txt=="" then return end
    local enc="/e c!"..Enc(txt)
    local tcs=g("TextChatService")
    if tcs and tcs.ChatVersion==Enum.ChatVersion.TextChatService then
        local ch=tcs.TextChannels:FindFirstChild("RBXGeneral") if ch then pcall(function() ch:SendAsync(enc) end) end
    else
        local rep=g("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        if rep then local smr=rep:FindFirstChild("SayMessageRequest") if smr then pcall(function() smr:FireServer(enc,"All") end) end end
    end
end

local function SpawnBubble(plr,txt)
    local ch=plr.Character if not ch then return end
    local hd=ch:FindFirstChild("Head") if not hd then return end
    for _,v in ipairs(hd:GetChildren()) do if v.Name=="CopierBubble" then v:Destroy() end end
    local bg=Instance.new("BillboardGui")
    bg.Name="CopierBubble"; bg.Adornee=hd; bg.Size=UDim2.new(0,250,0,60); bg.StudsOffset=Vector3.new(0,3,0)
    bg.AlwaysOnTop=true; bg.MaxDistance=150; bg.ResetOnSpawn=false; bg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    local f=Instance.new("Frame",bg); f.Size=UDim2.new(0,0,0,0); f.AnchorPoint=Vector2.new(0.5,0.5); f.Position=UDim2.new(0.5,0,0.5,0); f.BackgroundTransparency=1
    local tl=Instance.new("TextLabel",f); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundColor3=Color3.new(0,0,0)
    tl.BackgroundTransparency=0.4; tl.TextColor3=Color3.new(1,1,1); tl.TextScaled=true
    tl.Font=Enum.Font.GothamBold; tl.Text=txt; Instance.new("UICorner",tl).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",tl).Color=Color3.new(1,1,1)
    bg.Parent=hd
    TS:Create(f,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,1,0)}):Play()
    task.delay(6,function()
        if bg and bg.Parent then
            local tw=TS:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0)})
            tw:Play(); task.wait(0.3); if bg then bg:Destroy() end
        end
    end)
end

-- CMD Handler via Chat
local function HandleCMD(msg, sender)
    if sender ~= lp then return end
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args > 0 then
        local cmd = args[1]:lower()
        if cmd == "/e" and args[2] then
            local subCmd = args[2]:lower()
            if subCmd == "copy" or subCmd == "c" then
                if args[3] then
                    local targetName = args[3]
                    Config.TargetUsername = targetName
                    local tL_input = targetName:lower()
                    if tL_input == lp.Name:lower() or tL_input == lp.DisplayName:lower() then
                        F.handleOwnName()
                    else
                        S.hdOn = false
                        S.tN = targetName
                        S.fvOn = true
                        local ch = lp.Character
                        if ch then S.cU = nil; F.dC(S.tN, false, ch) end
                    end
                end
            elseif subCmd == "hd" then
                if args[3] then
                    local targetName = args[3]
                    Config.TargetUsername = targetName
                    S.hdN = targetName
                    S.hdOn = true
                    local ch = lp.Character
                    if ch then F.dHDC(S.hdN, ch) end
                end
            elseif subCmd == "fcam" then
                if Config.EnableFreeCam then
                    if S.fCA then F.dFC() else F.eFC() end
                end
            elseif subCmd == "tc" then
                F.TC()
            elseif subCmd == "head" then
                if _G.CTH then _G.CTH() end
            elseif subCmd == "tools" then
                if _G.TGT then _G.TGT() end
            elseif subCmd == "hideui" then
                F.TGUI()
            end
        end
    end
end

local function SetupChatListener(p)
    RC(p.Chatted:Connect(function(msg) 
        if msg:sub(1,5)=="/e c!" then 
            SpawnBubble(p,Dec(msg:sub(6))) 
        else
            HandleCMD(msg, p)
        end 
    end))
end
for _,p in ipairs(Plrs:GetPlayers()) do SetupChatListener(p) end
RC(Plrs.PlayerAdded:Connect(SetupChatListener))

F.handleOwnName = function()
    if not isfile or not writefile or not readfile then return end
    local f = "C_S_A.json"
    local dS = pcall(readfile, f) and readfile(f) or ""
    local d
    pcall(function() d = HS:JSONDecode(dS) end)
    
    if d and d.UL > 0 then
        d.UL = d.UL - 1
        if d.UL <= 0 then
            pcall(delfile, f)
            pcall(function() SG:SetCore("SendNotification", {Title="Avatar Copier", Text="Loaded Saved Avatar! (0 uses left, file deleted)", Duration=5}) end)
        else
            pcall(writefile, f, HS:JSONEncode(d))
            pcall(function() SG:SetCore("SendNotification", {Title="Avatar Copier", Text="Loaded Saved Avatar! ("..d.UL.." uses left)", Duration=5}) end)
        end
        S.tN = "SavedAvatar"; S.fvOn = true; S.cU = "SAVED"
        local nD = Instance.new("HumanoidDescription")
        for k,v in pairs(d.AD) do pcall(function() nD[k] = v end) end
        S.cDesc = nD
        if lp.Character then F.dC("SavedAvatar", false, lp.Character) end
    else
        local ch = lp.Character if not ch then return end
        local hm = ch:FindFirstChildOfClass("Humanoid") if not hm then return end
        local cD = hm:GetAppliedDescription()
        local aD = {}
        for _,p in ipairs({"Face","Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg","Shirt","Pants","GraphicTShirt","HatAccessory","HairAccessory","FaceAccessory","NeckAccessory","ShouldersAccessory","FrontAccessory","BackAccessory","WaistAccessory","ClimbAnimation","FallAnimation","IdleAnimation","JumpAnimation","RunAnimation","SwimAnimation","WalkAnimation"}) do 
            pcall(function() aD[p] = cD[p] end)
        end
        pcall(writefile, f, HS:JSONEncode({UL=5, AD=aD}))
        pcall(function() SG:SetCore("SendNotification", {Title="Avatar Copier", Text="Current Avatar Saved! (5 uses available)", Duration=5}) end)
    end
end

F.TGUI=function() _G.CGUI=not _G.CGUI; local pg=lp:FindFirstChild("PlayerGui"); local GS=g("GuiService")
local function sLC(p,st) if not p then return end for _,v in ipairs(p:GetChildren()) do if v:IsA("LayerCollector") and not string.find(v.Name,"Copier") and v.Name~="TouchGui" and v.Name~="CMC" and v.Name~="CCUI" and v.Name~="CopierChatUI" then if not st then if v:GetAttribute("CWE")==nil then v:SetAttribute("CWE",v.Enabled) end; v.Enabled=false else if v:GetAttribute("CWE")~=nil then v.Enabled=v:GetAttribute("CWE"); v:SetAttribute("CWE",nil) else v.Enabled=true end end end end end
if not _G.CGUI then pcall(function() _G.CCS=SG:GetCoreGuiEnabled(Enum.CoreGuiType.Chat); _G.CBS=SG:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack); _G.CPL=SG:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList); SG:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end); pcall(function() GS:SetMenuIsOpen(false) end); pcall(function() sLC(pg,false) end) else pcall(function() GS:SetMenuIsOpen(false) end); pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.All,true); if _G.CCS~=nil then SG:SetCoreGuiEnabled(Enum.CoreGuiType.Chat,_G.CCS) end; SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,true); if _G.CPL~=nil then SG:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,_G.CPL) end end); pcall(function() sLC(pg,true) end); task.spawn(function() for i=1,5 do task.wait(0.2); pcall(function() GS:SetMenuIsOpen(false); SG:SetCore("ChatActive",false) end) end end) end end

local function mBtn(t) local b=Instance.new("TextButton"); b.Text=t; b.BackgroundColor3=Color3.new(0.2,0.2,0.2); b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; Instance.new("UICorner",b).CornerRadius=UDim.new(0,4); return b end
local function mRow(f,y,lt,k,s,cb) local l=Instance.new("TextLabel",f); l.Position=UDim2.new(0,10,0,y); l.Size=UDim2.new(0,60,0,30); l.Text=lt; l.TextColor3=Color3.new(1,1,1); l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold; local b1=mBtn("-"); b1.Parent=f; b1.Position=UDim2.new(0,80,0,y+5); b1.Size=UDim2.new(0,30,0,20); local v=Instance.new("TextLabel",f); v.Position=UDim2.new(0,115,0,y); v.Size=UDim2.new(0,40,0,30); v.Name=k.."_Val"; v.Text=string.format("%.2f",UIS_State[k]); v.TextColor3=Color3.new(1,1,1); v.BackgroundTransparency=1; local b2=mBtn("+"); b2.Parent=f; b2.Position=UDim2.new(0,160,0,y+5); b2.Size=UDim2.new(0,30,0,20); b1.MouseButton1Click:Connect(function() UIS_State[k]=UIS_State[k]-s; v.Text=string.format("%.2f",UIS_State[k]); cb() end); b2.MouseButton1Click:Connect(function() UIS_State[k]=UIS_State[k]+s; v.Text=string.format("%.2f",UIS_State[k]); cb() end) end

F.aC=function() local ch=lp.Character; if not ch then return end for _,a in ipairs(ch:GetChildren()) do if a:GetAttribute("CCI") then local h=(a:IsA("Accessory") and a:FindFirstChild("Handle")) or (a:IsA("BasePart") and a) or nil; if h then local aN=h:GetAttribute("AttName") or ""; if not (aN:find("Hair") or aN:find("Hat") or aN:find("Face") or aN:find("Neck")) then local m=h:FindFirstChildWhichIsA("SpecialMesh") or h:FindFirstChildWhichIsA("DataModelMesh"); if m then if not m:GetAttribute("OS") then m:SetAttribute("OS",m.Scale) end; m.Scale=m:GetAttribute("OS")*UIS_State.scale elseif h:IsA("MeshPart") then if not h:GetAttribute("OS") then h:SetAttribute("OS",h.Size) end; h.Size=h:GetAttribute("OS")*UIS_State.scale end; local w=h:FindFirstChild("AccWeld") or h:FindFirstChild("AccessoryWeld"); if w and w:IsA("Weld") then if not w:GetAttribute("OC0") then w:SetAttribute("OC0",w.C0) end; w.C0=w:GetAttribute("OC0")*CFrame.new(UIS_State.offX,UIS_State.offY,UIS_State.offZ) end; local wl=h:FindFirstChildWhichIsA("WrapLayer",true); if wl then local att=h:FindFirstChildWhichIsA("Attachment"); if att then if not att:GetAttribute("OP") then att:SetAttribute("OP",att.Position) end; att.Position=att:GetAttribute("OP")+Vector3.new(UIS_State.offX,UIS_State.offY,UIS_State.offZ) end; if not wl:GetAttribute("OPf") then wl:SetAttribute("OPf",wl.Puffiness) end; wl.Puffiness=wl:GetAttribute("OPf")+(UIS_State.scale-1) end end end end end end
F.TC=function() local pg=lp:WaitForChild("PlayerGui"); if pg:FindFirstChild("CCUI") then pg.CCUI:Destroy(); _G.CCM=false; return end; _G.CCM=true; local sg=Instance.new("ScreenGui",pg); sg.Name="CCUI"; sg.ResetOnSpawn=false; local f=Instance.new("Frame",sg); f.Size=UDim2.new(0,240,0,220); f.Position=UDim2.new(0.5,-120,0.5,-110); f.BackgroundColor3=Color3.new(0.1,0.1,0.1); f.BackgroundTransparency=0.1; Instance.new("UICorner",f).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",f).Color=Color3.new(1,1,1); local tl=Instance.new("TextLabel",f); tl.Size=UDim2.new(1,0,0,30); tl.BackgroundTransparency=1; tl.Text="Adjust 3D Clothes"; tl.TextColor3=Color3.new(1,1,1); tl.Font=Enum.Font.GothamBold; local bc=Instance.new("TextButton",f); bc.Size=UDim2.new(0,30,0,30); bc.Position=UDim2.new(1,-30,0,0); bc.Text="X"; bc.TextColor3=Color3.new(1,0.3,0.3); bc.BackgroundTransparency=1; bc.Font=Enum.Font.GothamBold; bc.MouseButton1Click:Connect(function() sg:Destroy(); _G.CCM=false end); mRow(f,40,"Pos X (O/P)","offX",0.1,F.aC); mRow(f,80,"Pos Y (I/J)","offY",0.1,F.aC); mRow(f,120,"Pos Z","offZ",0.1,F.aC); mRow(f,160,"Scale","scale",0.05,F.aC) end

F.AHS=function() local ch=lp.Character; if not ch then return end local hd=ch:FindFirstChild("Head"); local fH=ch:FindFirstChild("CopierFakeHead"); local tH={}; if hd then table.insert(tH,hd) end; if fH then table.insert(tH,fH) end
if _G.CHH then for _,t in ipairs(tH) do if not t:GetAttribute("OT") then t:SetAttribute("OT",t.Transparency) end; t.Transparency=1; for _,v in ipairs(t:GetChildren()) do if v:IsA("Decal") then if not v:GetAttribute("OT") then v:SetAttribute("OT",v.Transparency) end; v.Transparency=1 elseif v:IsA("SurfaceAppearance") or v:IsA("FaceControls") then if v.Parent==t then table.insert(_G.CSHI,{item=v,parent=t}); pcall(function() v.Parent=nil end) end elseif v:IsA("SpecialMesh") or v:IsA("DataModelMesh") then if not v:GetAttribute("OS") then v:SetAttribute("OS",v.Scale) end; v.Scale=Vector3.zero end end end else for _,t in ipairs(tH) do if t:GetAttribute("OT") then t.Transparency=t:GetAttribute("OT") end; for _,v in ipairs(t:GetChildren()) do if v:IsA("Decal") and v:GetAttribute("OT") then v.Transparency=v:GetAttribute("OT") elseif (v:IsA("SpecialMesh") or v:IsA("DataModelMesh")) and v:GetAttribute("OS") then v.Scale=v:GetAttribute("OS") end end end; for _,d in ipairs(_G.CSHI) do pcall(function() d.item.Parent=d.parent end) end; table.clear(_G.CSHI) end end
_G.CTH=function() _G.CHH=not _G.CHH; F.AHS() end
_G.TGT=function() if not IA() then return end task.spawn(function() _G.TGA=not _G.TGA; if _G.TGA then F.sTGL() end end) end
F.sTGL=function() task.spawn(function() while _G.TGA and IA() do local bp=lp:FindFirstChild("Backpack"); local ch=lp.Character; if bp then pcall(function() for _,o in ipairs(workspace:GetChildren()) do if o:IsA("Tool") or o:IsA("HopperBin") then if not bp:FindFirstChild(o.Name) and not (ch and ch:FindFirstChild(o.Name)) then local hrp=ch and ch:FindFirstChild("HumanoidRootPart"); local h=o:FindFirstChild("Handle") or o:FindFirstChildWhichIsA("BasePart"); if hrp and h and firetouchinterest then pcall(function() firetouchinterest(hrp,h,0); task.wait(); firetouchinterest(hrp,h,1) end) end; pcall(function() o:Clone().Parent=bp end) end end end end) end; task.wait(2.5) end end) end
F.sE=function(n,f) local s,e=pcall(f); if not s then warn("[Copier] Error in "..n..":",e) end; return s end
F.pI=function(i) if not i then return end S_PT[i]=true; for _,d in ipairs(i:GetDescendants()) do S_PT[d]=true end; RC(i.DescendantAdded:Connect(function(d) S_PT[d]=true end)) end
F.cPT=function() bypassProtection=true; for t,_ in pairs(S_PT) do pcall(function() if t and t.Parent then t:Destroy() end end) end; table.clear(S_PT); bypassProtection=false end
F.gTRT=function(ch) if not ch then return nil end if ch:FindFirstChild("UpperTorso") then return Enum.HumanoidRigType.R15 elseif ch:FindFirstChild("Torso") then return Enum.HumanoidRigType.R6 else local hm=ch:FindFirstChildOfClass("Humanoid") return hm and hm.RigType or nil end end
F.sD=function(desc,rt) local d=desc:Clone(); if rt==Enum.HumanoidRigType.R6 then pcall(function() d.DepthScale=1;d.HeadScale=1;d.HeightScale=1;d.ProportionScale=1;d.WidthScale=1 end) end; if Config.DoorsCameraFix then pcall(function() d.Head=0 end) end; return d,false end
F.mD=function(uid,rt) local d; pcall(function() local desc=(uid=="SAVED" and S.cDesc) or Plrs:GetHumanoidDescriptionFromUserId(uid); if desc then local sD=F.sD(desc,rt); d=Plrs:CreateHumanoidModelFromDescription(sD,rt); if d then local dh=d:FindFirstChild("Head"); if dh then local dyn=dh:FindFirstChildOfClass("SurfaceAppearance") or dh:FindFirstChildOfClass("FaceControls"); if not dyn and not dh:IsA("MeshPart") and not dh:FindFirstChildOfClass("Decal") then local f=Instance.new("Decal",dh); f.Name="face"; f.Texture="rbxasset://textures/face.png" end end end end end); if d then d.Archivable=true end; return d end
F.eD=function(rt) if not S.cD or not S.cD:FindFirstChild("Humanoid") or S.cD.Humanoid.RigType~=rt then if S.cU then S.cD=F.mD(S.cU,rt) end end; return S.cD~=nil end
F.cNA=function(ch,uid) if not Config.CopyAnimation or not uid or uid=="SAVED" then return end task.spawn(function() local s,a=pcall(function() return Plrs:GetCharacterAppearanceAsync(uid) end); if s and a and IA() then local tA=a:FindFirstChild("Animate"); if tA then local mA=ch:FindFirstChild("Animate"); if mA then mA:Destroy() end; local nA=tA:Clone(); nA.Parent=ch; nA.Enabled=false; task.wait(); if ch.Parent then nA.Enabled=true end end; a:Destroy() end end) end
F.aAc=function(ch,ac) local h=ac:FindFirstChild("Handle"); if not h then return end for _,v in ipairs(ac:GetDescendants()) do if v:IsA("BasePart") then v.Anchored=false; v.CanCollide=false; v.Massless=true elseif v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end end; for _,v in ipairs(h:GetChildren()) do if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Motor6D") then v:Destroy() end end; local at=h:FindFirstChildOfClass("Attachment"); local tP,tA; if at then for _,p in ipairs(ch:GetChildren()) do if p:IsA("BasePart") then local f=p:FindFirstChild(at.Name); if f and f:IsA("Attachment") then tP=p; tA=f; break end end end end; h.Name=ac.Name; h:SetAttribute("CCI",true); if at then h:SetAttribute("AttName",at.Name) end; if tP and tA then h.Parent=ch; h.CFrame=tP.CFrame*tA.CFrame*at.CFrame:Inverse(); local w=Instance.new("Weld",h); w.Name="AccWeld"; w.Part0=tP; w.Part1=h; w.C0=tA.CFrame; w.C1=at.CFrame else h.Parent=ch; local hd=ch:FindFirstChild("Head") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso"); if hd then h.CFrame=hd.CFrame; local w=Instance.new("Weld",h); w.Name="AccWeld"; w.Part0=hd; w.Part1=h end end; pcall(function() ac:Destroy() end) end

F.rD=function(u,f) if u=="SAVED" then return "Custom Avatar" end; local ok,i=pcall(function() return US:GetUserInfosByUserIdsAsync({u}) end); return (ok and i and i[1] and i[1].DisplayName~="") and i[1].DisplayName or f end
F.sGE=function(ch) if not Config.SpoofGameEvents or not getconnections then return end pcall(function() for _,c in ipairs(getconnections(lp.CharacterAdded)) do if type(c.Function)=="function" then task.spawn(c.Function,ch) end end end); pcall(function() for _,c in ipairs(getconnections(lp.CharacterAppearanceLoaded)) do if type(c.Function)=="function" then task.spawn(c.Function,ch) end end end) end
F.uNS=function() local ch=lp.Character; local hm=ch and ch:FindFirstChildOfClass("Humanoid"); if hm and hm.DisplayName~=lp.DisplayName then pcall(function() hm.DisplayName=lp.DisplayName end) end end
F.eTV=function(ch) if not ch then return end for _,g in ipairs(ch:GetDescendants()) do if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then g.Enabled=true; for _,c in ipairs(g:GetDescendants()) do if c:IsA("TextLabel") or c:IsA("TextBox") then c.Visible=true; c.TextTransparency=0; if c.BackgroundTransparency~=1 then c.BackgroundTransparency=0 end elseif c:IsA("ImageLabel") then c.Visible=true; c.ImageTransparency=0 end end end end end
F.sYOT=function(ch) if S.hSOT or not ch then return end table.clear(S.oT); local f=false; for _,c in ipairs(ch:GetDescendants()) do if c:IsA("BillboardGui") or c:IsA("SurfaceGui") then pcall(function() c.Archivable=true; local cl=c:Clone(); if c:IsA("BillboardGui") and c.Adornee then cl:SetAttribute("OA",c.Adornee.Name) end; table.insert(S.oT,cl); f=true end) end end; if f then S.hSOT=true end end
F.eOTS=function(ch) if S.hSOT or not ch then return end F.sYOT(ch); if not S.hSOT then local c; c=ch.DescendantAdded:Connect(function(k) if k:IsA("BillboardGui") or k:IsA("SurfaceGui") then task.wait(0.1); if not S.hSOT and ch.Parent then F.sYOT(ch); if S.hSOT and c then c:Disconnect() end end end end); RC(c); task.delay(3,function() if c then c:Disconnect() end end) end end
F.fN=function(v) local f=tostring(v); local k; while true do f,k=string.gsub(f,"^(-?%d+)(%d%d%d)",'%1,%2'); if k==0 then break end end; return f end
F.bTTL=function(ch) if not ch then return end for _,c in ipairs(S.lC) do pcall(function() c:Disconnect() end) end; S.lC={}; local ls=lp:FindFirstChild("leaderstats"); if not ls then return end local kw={"price","cost","raised","donated","value","cash","money","robux","points","coins","level","lvl","stage"}; for _,g in ipairs(ch:GetDescendants()) do if g:IsA("BillboardGui") or g:IsA("SurfaceGui") then for _,l in ipairs(g:GetDescendants()) do if l:IsA("TextLabel") or l:IsA("TextBox") then local txt=tostring(l.Text); local tl=txt:lower(); if txt:match("%d+") then local f=false; for _,w in ipairs(kw) do if tl:find(w) then f=true; break end end; if f then local mS; for _,s in ipairs(ls:GetChildren()) do if s:IsA("ValueObject") and tl:find(s.Name:lower()) then mS=s; break end end; if not mS then for _,s in ipairs(ls:GetChildren()) do if s:IsA("IntValue") or s:IsA("NumberValue") then mS=s; break end end end; if mS then local sP,eP=txt:find("%d[%d%s,%.]*"); if sP and eP then local pfx=txt:sub(1,sP-1); local sfx=txt:sub(eP+1); local function uL() pcall(function() l.Text=pfx..F.fN(mS.Value)..sfx end) end; uL(); table.insert(S.lC,RC(mS.Changed:Connect(uL))) end end end end end end end end end
F.aPT=function(ch) if not Config.RestoreYourTagAfterRespawn or #S.oT==0 then return end local hd=ch:WaitForChild("Head",5); if not hd then return end for _,c in ipairs(ch:GetDescendants()) do if c:IsA("BillboardGui") or c:IsA("SurfaceGui") then pcall(function() c:Destroy() end) end end; for _,t in ipairs(S.oT) do pcall(function() local r=t:Clone(); r.Parent=hd; if r:IsA("BillboardGui") then local tA=hd; local oA=r:GetAttribute("OA"); if oA then local fA=ch:FindFirstChild(oA,true); if fA then tA=fA end end; r.Adornee=tA end end) end; F.eTV(ch); F.uNS(); task.spawn(function() task.wait(0.2); F.bTTL(ch) end) end
F.eTD=function(ch) if S.tWC then pcall(function() S.tWC:Disconnect() end); S.tWC=nil end; S.tWC=RC(ch.DescendantRemoving:Connect(function(c) if c:IsA("BillboardGui") or c:IsA("SurfaceGui") then task.wait(0.1); if ch.Parent and IA() then F.aPT(ch) end end end)); task.spawn(function() while ch and ch.Parent and IA() do F.eTV(ch); F.uNS(); task.wait(2) end end) end

F.aAv=function(ch,dm) local fD=Instance.new("Folder"); local hm=ch:FindFirstChildOfClass("Humanoid"); if hm and ch==lp.Character then pcall(function() hm:UnequipTools() end) end; local iR=(F.gTRT(ch)==Enum.HumanoidRigType.R15); local gM={Head=false,RLeg=false,LLeg=false,Auras={}}; if Config.DoorsCameraFix then gM.Head=true end; local hd=ch:FindFirstChild("Head"); if hd then if hd.Transparency>=0.9 then gM.Head=true end; local sm=hd:FindFirstChildOfClass("SpecialMesh"); if sm and (sm.Scale.X<=0.1 or tostring(sm.MeshId)=="" or tostring(sm.MeshId):find("134082") or tostring(sm.MeshId):find("201777376")) then gM.Head=true end else gM.Head=true end
for _,t in ipairs(ch:GetChildren()) do if t:IsA("CharacterMesh") then if t.BodyPart==Enum.BodyPart.RightLeg and (tostring(t.MeshId):find("90296") or tostring(t.MeshId):find("139607")) then gM.RLeg=true end; if t.BodyPart==Enum.BodyPart.LeftLeg and (tostring(t.MeshId):find("90296") or tostring(t.MeshId):find("139607")) then gM.LLeg=true end end end
if iR then local function ck(n) local l=ch:FindFirstChild(n); if not l then return true end; local m=l:FindFirstChildOfClass("SpecialMesh"); if m and (tostring(m.MeshId):find("139607") or m.Scale.Y<0.5) then return true end; if l:IsA("MeshPart") and (tostring(l.MeshId):find("139607") or l.Size.Y<0.6) then return true end return false end; gM.RLeg=ck("RightLowerLeg"); gM.LLeg=ck("LeftLowerLeg") else gM.RLeg=not ch:FindFirstChild("Right Leg"); gM.LLeg=not ch:FindFirstChild("Left Leg") end
local sA={}; for _,d in ipairs(ch:GetDescendants()) do if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Light") then local acc=d:FindFirstAncestorOfClass("Accessory"); local t=d:FindFirstAncestorOfClass("Tool"); if acc then gM.Auras[acc]=true elseif not t then local p=d:FindFirstAncestorOfClass("BasePart"); if p and p.Parent==ch then local pn=d.Parent; if pn:IsA("Attachment") then if not sA[pn] then sA[pn]={i=pn,tP=p.Name}; pcall(function() pn.Parent=fD end) end else if not sA[d] then sA[d]={i=d,tP=p.Name}; pcall(function() d.Parent=fD end) end end end end end end
local cI={}; local cJ={}; if iR then local cP={HumanoidRootPart=true}; for k,_ in pairs(S.R15M) do cP[k]=true end; for ln,_ in pairs(S.R15M) do local l=ch:FindFirstChild(ln); if l then for _,c in ipairs(l:GetChildren()) do if not c:IsA("Attachment") and not c:IsA("JointInstance") and not c:IsA("WeldConstraint") and not c:IsA("SurfaceAppearance") and not c:IsA("Decal") and not c:IsA("FaceControls") and not c:IsA("WrapTarget") and not c:IsA("SpecialMesh") and not c:IsA("Motor6D") and not c:IsA("Script") and not c:IsA("LocalScript") then table.insert(cI,{i=c,pL=ln}); pcall(function() c.Parent=fD end) end end end end; for _,o in ipairs(ch:GetDescendants()) do if o:IsA("JointInstance") or o:IsA("WeldConstraint") then local p0,p1=o.Part0,o.Part1; if p0 and p1 then local p0C=cP[p0.Name] and p0.Parent==ch; local p1C=cP[p1.Name] and p1.Parent==ch; if (p0C and not p1C) or (not p0C and p1C) then table.insert(cJ,{cN=o.ClassName,n=o.Name,p0N=p0.Name,p1N=p1.Name,p0I=p0,p1I=p1,pN=o.Parent and o.Parent.Name or "",c0=o:IsA("JointInstance") and o.C0 or nil,c1=o:IsA("JointInstance") and o.C1 or nil}) end end end end end
ch.Archivable=true; dm.Archivable=true; local d=dm:Clone(); d.Parent=workspace; local dHm=d:FindFirstChildOfClass("Humanoid"); local sT={}
for _,o in ipairs(ch:GetDescendants()) do if o:IsA("BillboardGui") or o:IsA("SurfaceGui") then if Config.RestoreYourTagAfterRespawn then o.Parent=ch; table.insert(sT,o) else o:Destroy() end end end

for _,t in ipairs(ch:GetChildren()) do 
    if t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then 
        t:Destroy() 
    elseif t:IsA("BasePart") and t:GetAttribute("CCI") then 
        t:Destroy() 
    elseif t:IsA("CharacterMesh") then 
        local s=false; if gM.RLeg and t.BodyPart==Enum.BodyPart.RightLeg then s=true end; if gM.LLeg and t.BodyPart==Enum.BodyPart.LeftLeg then s=true end; if not s then t:Destroy() end 
    elseif t:IsA("Accessory") and not t:FindFirstChildOfClass("Script") and not t:FindFirstChildOfClass("LocalScript") then 
        if not gM.Auras[t] then t:Destroy() end 
    end 
end

if iR then local oR=hm.RequiresNeck; hm.RequiresNeck=false; for _,dp in ipairs(d:GetChildren()) do if S.R15M[dp.Name] then local s=false; local dn=tostring(dp.Name); if gM.RLeg and (dn:find("RightFoot") or dn:find("RightLowerLeg") or dn:find("RightUpperLeg")) then s=true end; if gM.LLeg and (dn:find("LeftFoot") or dn:find("LeftLowerLeg") or dn:find("LeftUpperLeg")) then s=true end; if gM.Head and dn=="Head" then s=true end; if not s then pcall(function() hm:ReplaceBodyPartR15(S.R15M[dp.Name],dp:Clone()) end) end end end; task.delay(0.5,function() if hm and hm.Parent then pcall(function() hm.RequiresNeck=oR end) end end)
for _,iD in ipairs(cI) do local tL=ch:FindFirstChild(iD.pL); if tL and iD.i then pcall(function() iD.i.Parent=tL end) end end; local cP={HumanoidRootPart=true}; for k,_ in pairs(S.R15M) do cP[k]=true end; for _,jD in ipairs(cJ) do local tP0=(cP[jD.p0N] and ch:FindFirstChild(jD.p0N)) or jD.p0I; local tP1=(cP[jD.p1N] and ch:FindFirstChild(jD.p1N)) or jD.p1I; if tP0 and tP1 then local nJ=Instance.new(jD.cN); nJ.Name=jD.n; nJ.Part0=tP0; nJ.Part1=tP1; if nJ:IsA("JointInstance") then nJ.C0=jD.c0; nJ.C1=jD.c1 end; local nP=ch; if cP[jD.pN] then nP=ch:FindFirstChild(jD.pN) or ch end; nJ.Parent=nP end end else
local tM={}; for _,t in ipairs(d:GetChildren()) do if t:IsA("CharacterMesh") then table.insert(tM,t:Clone()) end end; for _,dp in ipairs(d:GetChildren()) do if dp.Name=="Torso" or dp.Name=="Left Arm" or dp.Name=="Right Arm" or dp.Name=="Left Leg" or dp.Name=="Right Leg" then local s=false; if gM.RLeg and dp.Name=="Right Leg" then s=true end; if gM.LLeg and dp.Name=="Left Leg" then s=true end; if not s then local m=ch:FindFirstChild(dp.Name); if m and m:IsA("BasePart") then pcall(function() m.Color=dp.Color; if dp:IsA("MeshPart") and m:IsA("MeshPart") then m.MeshId=dp.MeshId end end); for _,o in ipairs(m:GetChildren()) do if o:IsA("DataModelMesh") or o:IsA("SpecialMesh") or o:IsA("BlockMesh") or o:IsA("CylinderMesh") then o:Destroy() end end; for _,o in ipairs(dp:GetChildren()) do if o:IsA("DataModelMesh") or o:IsA("SpecialMesh") or o:IsA("BlockMesh") or o:IsA("CylinderMesh") then o:Clone().Parent=m end end end end end end
local mH=ch:FindFirstChild("Head"); local dH=d:FindFirstChild("Head"); if mH and dH and not gM.Head then local nH=dH:Clone(); nH.Name="Head"; nH.CFrame=mH.CFrame; local torso=ch:FindFirstChild("Torso"); if torso then local neck=torso:FindFirstChild("Neck"); if neck then local nNeck=neck:Clone(); nNeck.Part0=torso; nNeck.Part1=nH; nNeck.Parent=torso; neck:Destroy() end end; nH.Parent=ch; mH:Destroy() end
for _,cm in ipairs(ch:GetChildren()) do if cm:IsA("CharacterMesh") then local s=false; if gM.RLeg and cm.BodyPart==Enum.BodyPart.RightLeg then s=true end; if gM.LLeg and cm.BodyPart==Enum.BodyPart.LeftLeg then s=true end; if not s then cm:Destroy() end end end; for _,tm in ipairs(tM) do local s=false; if gM.RLeg and tm.BodyPart==Enum.BodyPart.RightLeg then s=true end; if gM.LLeg and tm.BodyPart==Enum.BodyPart.LeftLeg then s=true end; if not s then tm:Clone().Parent=ch end end end
if hm and dHm then local s={"BodyDepthScale","BodyHeightScale","BodyWidthScale","HeadScale","BodyProportionScale","BodyTypeScale"}; for _,sv in ipairs(s) do local dS=dHm:FindFirstChild(sv); if dS and dS:IsA("NumberValue") then local mS=hm:FindFirstChild(sv); if mS and mS:IsA("NumberValue") then mS.Value=dS.Value else dS:Clone().Parent=hm end end end end
task.wait(0.25); if Config.RestoreYourTagAfterRespawn then local nH=ch:WaitForChild("Head",2); if nH then for _,tg in ipairs(sT) do tg.Parent=nH; if tg:IsA("BillboardGui") then tg.Adornee=nH end end end end
if not iR then for _,t in ipairs(d:GetDescendants()) do pcall(function() if t:IsA("WrapTarget") then local pStr=t.Parent and tostring(t.Parent.Name) or ""; local s=false; if gM.RLeg and (pStr=="Right Leg" or pStr:find("RightFoot") or pStr:find("RightLowerLeg") or pStr:find("RightUpperLeg")) then s=true end; if gM.LLeg and (pStr=="Left Leg" or pStr:find("LeftFoot") or pStr:find("LeftLowerLeg") or pStr:find("LeftUpperLeg")) then s=true end; if gM.Head and pStr=="Head" then s=true end; if not s then local m=ch:FindFirstChild(pStr); if m then for _,oO in ipairs(m:GetChildren()) do if oO:IsA("WrapTarget") then oO:Destroy() end end; t:Clone().Parent=m end end end end) end end
for _,t in ipairs(d:GetChildren()) do pcall(function() if t:IsA("Accessory") then local cl=t:Clone(); F.aAc(ch,cl) elseif t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then local cl=t:Clone(); cl:SetAttribute("CCI",true); cl.Parent=ch end end) end
for _,data in pairs(sA) do local tL=ch:FindFirstChild(data.tP); if tL then pcall(function() data.i.Parent=tL end) else pcall(function() data.i.Parent=ch end) end end
if Config.DoorsCameraFix then local rH=ch:FindFirstChild("Head"); local duH=d:FindFirstChild("Head"); if rH and duH then rH.Transparency=1; for _,v in ipairs(rH:GetChildren()) do if v:IsA("Decal") then v.Transparency=1 end end; local oF=ch:FindFirstChild("CopierFakeHead"); if oF then oF:Destroy() end; local fH=duH:Clone(); fH.Name="CopierFakeHead"; fH.CanCollide=false; fH.Massless=true; fH.Anchored=false; for _,v in ipairs(fH:GetChildren()) do if v:IsA("Attachment") or v:IsA("JointInstance") or v:IsA("Motor6D") then v:Destroy() end end; fH.CFrame=rH.CFrame; fH.Parent=ch; local wc=Instance.new("WeldConstraint"); wc.Part0=rH; wc.Part1=fH; wc.Parent=fH end end
pcall(function() fD:Destroy() end); d:Destroy(); task.delay(0.5,F.aC); task.delay(0.6,F.AHS) end
F.rA=function(ch) local a=ch:FindFirstChild("Animate"); if not a then return end task.spawn(function() a.Enabled=false; task.wait(0.05); if ch.Parent and a.Parent then a.Enabled=true end end) end
F.sHD=function(ch,uid) local hm=ch:FindFirstChildOfClass("Humanoid"); if not hm then return end local d; local ok=pcall(function() d=Plrs:GetHumanoidDescriptionFromUserId(uid) end); if ok and d then for _,v in ipairs(hm:GetChildren()) do if v:IsA("HumanoidDescription") then v:Destroy() end end; local nD=d:Clone(); nD.Name="HumanoidDescription"; nD.Parent=hm end end

F.eFC=function() local ch=lp.Character; if ch then local hrp=ch:FindFirstChild("HumanoidRootPart"); if hrp then S.sHRPA=hrp.Anchored; hrp.Anchored=true end end
local cm=workspace.CurrentCamera; S.fCP=Instance.new("Part"); S.fCP.Transparency=1; S.fCP.Anchored=true; S.fCP.CanCollide=false; S.fCP.Massless=true; S.fCP.Size=Vector3.new(1,1,1); S.fCP.CFrame=cm.CFrame; S.fCP.Parent=workspace
pcall(function() S.sZ=(cm.CFrame.Position-cm.Focus.Position).Magnitude end); S.sMZ=lp.CameraMinZoomDistance; S.sMaZ=lp.CameraMaxZoomDistance; lp.CameraMinZoomDistance=0.5; lp.CameraMaxZoomDistance=0.5; cm.CameraSubject=S.fCP; S.fCA=true
RS:BindToRenderStep("CFCam",Enum.RenderPriority.Camera.Value-1,function(dt) if not S.fCA or not S.fCP then return end if cm.CameraSubject~=S.fCP then cm.CameraSubject=S.fCP end; if cm.CameraType~=Enum.CameraType.Custom then cm.CameraType=Enum.CameraType.Custom end
local mV=Vector3.zero
if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.Up) then mV+=Vector3.new(0,0,-1) end
if UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.Down) then mV+=Vector3.new(0,0,1) end
if UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.Left) then mV+=Vector3.new(-1,0,0) end
if UIS:IsKeyDown(Enum.KeyCode.D) or UIS:IsKeyDown(Enum.KeyCode.Right) then mV+=Vector3.new(1,0,0) end
if UIS:IsKeyDown(Enum.KeyCode.E) then mV+=Vector3.new(0,1,0) end
if UIS:IsKeyDown(Enum.KeyCode.Q) then mV+=Vector3.new(0,-1,0) end
if mV.Magnitude>0 then local mD=(cm.CFrame.LookVector*mV.Z)+(cm.CFrame.RightVector*mV.X)+(cm.CFrame.UpVector*mV.Y); if mD.Magnitude>0 then mD=mD.Unit end; S.fCP.CFrame=S.fCP.CFrame+(mD*(Config.FreeCamSpeed*60*dt)) end
local cP=lp.Character; if cP then for _,v in ipairs(cP:GetDescendants()) do if v:IsA("BasePart") or v:IsA("Decal") then v.LocalTransparencyModifier=0 end end end end); print("[FCam] Spectator active.") end
F.dFC=function() S.fCA=false; pcall(function() RS:UnbindFromRenderStep("CFCam") end); if S.sMaZ then lp.CameraMaxZoomDistance=S.sMaZ end; if S.sZ and S.sZ>0.6 then pcall(function() lp.CameraMinZoomDistance=S.sZ end); task.wait(0.05) end; if S.sMZ then pcall(function() lp.CameraMinZoomDistance=S.sMZ end) end; if S.fCP then S.fCP:Destroy(); S.fCP=nil end; local ch=lp.Character; if ch then local hrp=ch:FindFirstChild("HumanoidRootPart"); if hrp and S.sHRPA~=nil then hrp.Anchored=S.sHRPA end end; local cm=workspace.CurrentCamera; if cm and ch then cm.CameraSubject=ch:FindFirstChildOfClass("Humanoid") or ch:FindFirstChild("Head") end; print("[FCam] Spectator inactive.") end

F.gCS=function() local s={}; local function ck(v) if v:IsA("LocalScript") then local n=tostring(v.Name):lower(); if n:find("camera") or n:find("cam") then table.insert(s,v) end end end; if lp.Character then for _,v in ipairs(lp.Character:GetDescendants()) do ck(v) end end return s end
F.sCS=function() if Config.DoorsCameraFix then return end table.clear(S.sCS); pcall(function() for _,s in ipairs(F.gCS()) do if s.Enabled then s.Enabled=false; table.insert(S.sCS,s) end end end) end
F.rCS=function() for _,s in ipairs(S.sCS) do pcall(function() s.Enabled=true end) end; table.clear(S.sCS) end
F.lC=function(sub,cT) if Config.DoorsCameraFix then return end S.lCS=sub; S.lCT=cT or Enum.CameraType.Custom; S.cLA=true; local c=workspace.CurrentCamera; if c then pcall(function() c.CameraType=S.lCT; c.CameraSubject=S.lCS end) end end
F.uC=function() S.cLA=false; S.lCS=nil; S.lCT=nil end
RC(RS.RenderStepped:Connect(function() if S.cLA and S.lCS then local c=workspace.CurrentCamera; if c then pcall(function() if c.CameraSubject~=S.lCS then c.CameraSubject=S.lCS end; if c.CameraType~=S.lCT then c.CameraType=S.lCT end end) end end end))
F.fC=function() if Config.DoorsCameraFix then return end local cm=workspace.CurrentCamera; local ch=lp.Character; if not cm or not ch then return end local hm=ch:FindFirstChildOfClass("Humanoid"); local hrp=ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"); if not hrp then return end local s=false; if not cm.CameraSubject or not cm.CameraSubject:IsDescendantOf(workspace) then s=true end; if cm.CameraSubject~=hm and cm.CameraSubject~=hrp then s=true end; if (cm.CFrame.Position-hrp.Position).Magnitude>100 then s=true end; if cm.CFrame.X~=cm.CFrame.X then s=true end; if not s then S.sCE=0; return end; pcall(function() S.sCE=os.clock()+0.5; cm.CameraType=Enum.CameraType.Custom; cm.CameraSubject=hm or hrp; if hm then hm.CameraOffset=Vector3.zero end; local ld=hrp.CFrame.LookVector; cm.CFrame=CFrame.lookAt(hrp.Position-(ld*12)+Vector3.new(0,5,0),hrp.Position) end) end

pcall(function() RS:UnbindFromRenderStep("CopierFirstPerson") end)
RS:BindToRenderStep("CopierFirstPerson", Enum.RenderPriority.Camera.Value+1, function() if not IA() then pcall(function() RS:UnbindFromRenderStep("CopierFirstPerson") end); return end; local cam=workspace.CurrentCamera; local ch=lp.Character; if not cam or not ch then return end; local hd=ch:FindFirstChild("Head") or ch:FindFirstChild("CopierFakeHead"); if not hd then return end; local dist=(cam.CFrame.Position-hd.Position).Magnitude; local isFP=dist<1.5; for _,v in ipairs(ch:GetChildren()) do if v:IsA("BasePart") and v:GetAttribute("CCI") then local aN=v:GetAttribute("AttName") or ""; if aN:find("Hair") or aN:find("Hat") or aN:find("Face") or aN:find("Neck") or aN=="" then v.LocalTransparencyModifier=isFP and 1 or 0 end elseif v:IsA("Accessory") then local h=v:FindFirstChild("Handle"); if h then local at=h:FindFirstChildOfClass("Attachment"); local aN=at and at.Name or ""; if aN:find("Hair") or aN:find("Hat") or aN:find("Face") or aN:find("Neck") or aN=="" then h.LocalTransparencyModifier=isFP and 1 or 0 end end end end end)

RC(UIS.InputBegan:Connect(function(i,p) if p then return end if _G.CCM then local m=false; local sX,sY,uF,stX,stY=0.1,0.1,F.aC,"offX","offY"
if i.KeyCode==Enum.KeyCode.I then UIS_State[stY]=UIS_State[stY]+sY; m=true elseif i.KeyCode==Enum.KeyCode.J then UIS_State[stY]=UIS_State[stY]-sY; m=true elseif i.KeyCode==Enum.KeyCode.O then UIS_State[stX]=UIS_State[stX]-sX; m=true elseif i.KeyCode==Enum.KeyCode.P then UIS_State[stX]=UIS_State[stX]+sX; m=true end
if m then uF(); local pg=lp:FindFirstChild("PlayerGui"); if pg and pg:FindFirstChild("CCUI") then local f=pg.CCUI:FindFirstChildWhichIsA("Frame"); if f then local lX=f:FindFirstChild(stX.."_Val"); if lX then lX.Text=string.format("%.2f",UIS_State[stX]) end; local lY=f:FindFirstChild(stY.."_Val"); if lY then lY.Text=string.format("%.2f",UIS_State[stY]) end end end; return end end
if i.KeyCode==Config.ToolsGiverKey then if _G.TGT then _G.TGT() end end; if i.KeyCode==Config.EditClothesKey then F.TC() end; if i.KeyCode==Config.ToggleHeadKey then if _G.CTH then _G.CTH() end end
if i.KeyCode==Config.HideUIKey then F.TGUI() end 
if i.KeyCode==Config.SecretChatKey then F.ToggleChatUI() end
if i.KeyCode==Config.DualWieldKey then local ch=lp.Character; if ch then if _G.LTC and _G.LTC.Parent then _G.LTC:Destroy(); _G.LTC=nil else local rT=ch:FindFirstChildOfClass("Tool"); if rT then local h=rT:FindFirstChild("Handle"); if h then local lH=ch:FindFirstChild("LeftHand") or ch:FindFirstChild("Left Arm"); if lH then _G.LTC=Instance.new("Model"); _G.LTC.Name=rT.Name.."_LW"; local fH=h:Clone(); for _,v in ipairs(fH:GetDescendants()) do if v:IsA("Script") or v:IsA("LocalScript") then v:Destroy() end end; fH.Parent=_G.LTC; _G.LTC.Parent=ch; fH.CFrame=lH.CFrame; local w=Instance.new("WeldConstraint"); w.Part0=lH; w.Part1=fH; w.Parent=fH end end end end end end
if i.KeyCode==Config.FreeCamKey then if Config.EnableFreeCam then if S.fCA then F.dFC() else F.eFC() end end end end))
RC(lp.CharacterRemoving:Connect(function() if S.fCA then F.dFC() end end))
F.dC=function(nm,isR,pCh) if not IA() then return false end local s=false; F.sE("NCCore",function() local ch=pCh or lp.Character; if not ch then return end local hm=ch:FindFirstChildOfClass("Humanoid"); if not hm then return end local rt=F.gTRT(ch) or hm.RigType; local uid
if isR then uid=S.cU; if not F.eD(rt) then return end else if nm=="SavedAvatar" then uid="SAVED"; S.cU=uid; S.tD="Saved Custom Avatar"; S.cD=F.mD(uid,rt); _G.CTID=nil else local tU=tonumber(nm); if not tU then local tP=Plrs:FindFirstChild(nm); if tP then tU=tP.UserId else pcall(function() tU=Plrs:GetUserIdFromNameAsync(nm) end) end end; if not tU then return end; uid=tU; S.cU=uid; S.tD=F.rD(uid,nm); S.cD=F.mD(uid,rt); _G.CTID=uid end end
if not S.cD then return end F.cPT(); F.sCS(); F.lC(hm or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")); local hrpA=false; local hrp=ch:FindFirstChild("HumanoidRootPart"); if hrp then hrpA=hrp.Anchored end; F.aAv(ch,S.cD); local tD=nil; pcall(function() tD=(uid=="SAVED" and S.cDesc) or Plrs:GetHumanoidDescriptionFromUserId(uid) end); if tD then pcall(function() hm:SetEmotes(tD:GetEmotes()); hm:SetEquippedEmotes(tD:GetEquippedEmotes()) end); F.cNA(ch,uid) end
if S.cU and S.cU~="SAVED" then F.sHD(ch,S.cU) end; F.rA(ch); if hrp then hrp.Anchored=hrpA end; if hm then pcall(function() hm:ChangeState(Enum.HumanoidStateType.GettingUp) end) end; F.sGE(ch); task.delay(0.5,function() F.uC(); F.rCS(); F.fC() end); s=true end); return s end
F.dHDC=function(nm,pCh) if not IA() then return false end local s=false; F.sE("HDC",function() local ch=pCh or lp.Character; if not ch then return end local hm=ch:FindFirstChildOfClass("Humanoid"); if not hm then return end local uid=tonumber(nm); if not uid then pcall(function() uid=Plrs:GetUserIdFromNameAsync(nm) end) end; if not uid then return end; S.hdUser=uid; S.hdN=nm; local d; pcall(function() d=Plrs:GetHumanoidDescriptionFromUserId(uid) end); if not d then return end; _G.CTID=uid; local rt=F.gTRT(ch) or hm.RigType; local sHD,bad=F.sD(d,rt); sHD.Name="HumanoidDescription"; sHD.Parent=hm; local md=Plrs:CreateHumanoidModelFromDescription(sHD,rt); md.Name="LocalHDDummy"; md.Archivable=true
if bad and md then local dh=md:FindFirstChild("Head"); if dh then local dyn=dh:FindFirstChildOfClass("SurfaceAppearance") or dh:FindFirstChildOfClass("FaceControls"); if not dyn and not dh:IsA("MeshPart") and not dh:FindFirstChildOfClass("Decal") then local f=Instance.new("Decal",dh); f.Name="face"; f.Texture="rbxasset://textures/face.png" end end end; F.cPT(); F.sCS(); F.lC(hm or ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")); for _,v in ipairs(hm:GetChildren()) do if v:IsA("HumanoidDescription") then v:Destroy() end end
local hrpA=false; local hrp=ch:FindFirstChild("HumanoidRootPart"); if hrp then hrpA=hrp.Anchored end; F.aAv(ch,md); if Config.CopyAnimation and d then F.cNA(ch,uid) end; if hrp then hrp.Anchored=hrpA end; pcall(function() md:Destroy() end); F.rA(ch); pcall(function() hm:ChangeState(Enum.HumanoidStateType.GettingUp) end); F.sGE(ch); task.delay(0.5,function() F.uC(); F.rCS(); F.fC() end); s=true end); return s end
local function eIR(nC) if not IA() or S.aC==nC then return end if not nC:FindFirstChildOfClass("Humanoid") then return end; S.aC=nC; if S.hdOn and S.hdN~="" then F.dHDC(S.hdN,nC) elseif S.fvOn and S.tN~="" then F.dC(S.tN,S.cU~=nil,nC) end end
local function iPC(m) if not m or m==lp.Character or not m:IsA("Model") or not m:FindFirstChildOfClass("Humanoid") then return false end; local n=m.Name; return n==lp.Name or n==lp.DisplayName or n:find(lp.Name) or n:find(lp.DisplayName) or n=="Clone" end
local function aTIG(cm) if not S.fvOn or not S.cU then return end if not cm:WaitForChild("Humanoid",3) then return end; task.wait(0.1); local rt=F.gTRT(cm); local dU=S.cD; if rt~=S.cRT then dU=F.mD(S.cU,rt) end; if dU then F.aAv(cm,dU); if dU~=S.cD then pcall(function() dU:Destroy() end) end end end
RC(workspace.DescendantAdded:Connect(function(d) if d:IsA("Humanoid") and d.Parent and d.Parent:IsA("Model") then local m=d.Parent; task.delay(0.5,function() if iPC(m) and not m:GetAttribute("CCP") then m:SetAttribute("CCP",true); task.spawn(aTIG,m) end end) elseif d:IsA("Model") then task.delay(0.5,function() if iPC(d) and not d:GetAttribute("CCP") then d:SetAttribute("CCP",true); task.spawn(aTIG,d) end end) end end))
local function oCR(char) if not IA() or char:GetAttribute("CP") then return end; char:SetAttribute("CP",true); if not (char:WaitForChild("Humanoid",10) and char:WaitForChild("HumanoidRootPart",10) and char:WaitForChild("Head",10)) then char:SetAttribute("CP",false); return end
if not S.cD and not lp:HasAppearanceLoaded() then local l=false; local c=lp.CharacterAppearanceLoaded:Connect(function(ch) if ch==char then l=true end end); local sW=os.clock(); while not l and os.clock()-sW<5 do task.wait(0.1); if not char.Parent or not IA() then if c then c:Disconnect() end; return end end; if c then c:Disconnect() end end
task.wait(0.05); if S.aC==char then return end; S.cRT=F.gTRT(char); if Config.RestoreYourTagAfterRespawn then F.eOTS(char) end; if char.Parent and IA() then eIR(char) end end
task.spawn(function() while IA() do task.wait(1.5); local ch=lp.Character; if ch and ch.Parent then if ch~=S.lC then S.lC=ch; task.spawn(oCR,ch) end end end end)
RC(lp.CharacterAdded:Connect(function(nC) if IA() then task.spawn(oCR,nC) end end))

local function SHC() 
    local t = Config.TargetUsername; if t=="" then return end; 
    local tL_input = t:lower()
    if tL_input == lp.Name:lower() or tL_input == lp.DisplayName:lower() then
        F.handleOwnName()
    else
        local ch = lp.Character; 
        if Config.CopyAvatarHD then S.hdN=t; S.hdOn=true elseif Config.CopyAvatar then S.tN=t; S.fvOn=true end; 
        if ch then task.spawn(oCR,ch) end 
    end
end
task.spawn(SHC)
]=====]

local function runCopier(target)
    local code = (COPYAVA_SRC:gsub('TargetUsername="brockkodile"', function()
        return 'TargetUsername="' .. target .. '"'
    end))

    if typeof(loadstring) ~= "function" then
        return false, "executor tidak punya loadstring"
    end

    local fn, err = loadstring(code)
    if not fn then return false, err end

    task.spawn(fn)
    return true
end

-- ===== SELECT COPY: daftar username sendiri (terpisah dari SELECT PLAYER untuk teleport) =====
local AVA_ERR = Color3.fromRGB(80, 40, 40)
local copyTarget = nil
local selectCopyOpen = false

local selectCopyBtn = makePlayerButton("🎯 SELECT COPY", 7)

local selectCopyFrame = Instance.new("Frame")
selectCopyFrame.LayoutOrder = 8
selectCopyFrame.Size = UDim2.new(1, 0, 0, 130)
selectCopyFrame.BackgroundColor3 = BG_DARK
selectCopyFrame.BorderSizePixel = 0
selectCopyFrame.Visible = false
selectCopyFrame.Parent = playerPage
corner(selectCopyFrame, 8)
stroke(selectCopyFrame, BORDER_BLUE, 1)

local scTitle = newLabel(selectCopyFrame, "Pilih username (klik untuk pilih)", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), Enum.TextXAlignment.Left)
scTitle.TextTruncate = Enum.TextTruncate.AtEnd

local scScroll = Instance.new("ScrollingFrame")
scScroll.Size = UDim2.new(1, -8, 1, -24)
scScroll.Position = UDim2.new(0, 4, 0, 22)
scScroll.BackgroundTransparency = 1
scScroll.BorderSizePixel = 0
scScroll.ScrollBarThickness = 3
scScroll.ScrollBarImageColor3 = ACCENT_BLUE
scScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scScroll.Parent = selectCopyFrame

local scLayout = Instance.new("UIListLayout")
scLayout.Padding = UDim.new(0, 3)
scLayout.SortOrder = Enum.SortOrder.Name
scLayout.Parent = scScroll

-- tombol di bawah daftar
local copyAvaBtn = makePlayerButton("🎭 COPY AVATAR", 9)
local restoreAvaBtn = makePlayerButton("♻️ RESTORE AVATAR", 11)

local function updateCopyUI()
    if copyTarget then
        scTitle.Text = "Dipilih: @" .. copyTarget.Name
        copyAvaBtn.Text = "🎭 COPY AVATAR @" .. copyTarget.Name
    else
        scTitle.Text = "Pilih username (klik untuk pilih)"
        copyAvaBtn.Text = "🎭 COPY AVATAR"
    end
    restoreAvaBtn.Text = "♻️ RESTORE AVATAR"
end

local function avaFlash(btn, text, color)
    btn.Text = text
    btn.BackgroundColor3 = color
    task.delay(1.5, function()
        btn.BackgroundColor3 = BG_BUTTON
        updateCopyUI()
    end)
end

local function refreshCopyList()
    for _, child in ipairs(scScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    -- kalau player yang dipilih sudah keluar
    if copyTarget and copyTarget.Parent ~= Players then
        copyTarget = nil
        updateCopyUI()
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local isSelected = (copyTarget == p)

            local row = Instance.new("TextButton")
            row.Name = p.Name
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = isSelected and ON_COLOR or BG_BUTTON
            row.BorderSizePixel = 0
            row.Text = ""
            row.AutoButtonColor = false
            row.Parent = scScroll
            corner(row, 6)

            local avFrame = Instance.new("Frame")
            avFrame.Size = UDim2.new(0, 26, 0, 26)
            avFrame.Position = UDim2.new(0, 4, 0.5, -13)
            avFrame.BackgroundColor3 = BG_DARK
            avFrame.Parent = row
            corner(avFrame, 13)

            local avImg = Instance.new("ImageLabel")
            avImg.Size = UDim2.new(1, -2, 1, -2)
            avImg.Position = UDim2.new(0, 1, 0, 1)
            avImg.BackgroundTransparency = 1
            avImg.ScaleType = Enum.ScaleType.Crop
            avImg.Parent = avFrame
            corner(avImg, 12)

            task.spawn(function()
                local ok, thumb = pcall(function()
                    return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok then avImg.Image = thumb end
            end)

            newLabel(row, p.DisplayName, 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 36, 0, 3), UDim2.new(1, -66, 0, 15), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd
            newLabel(row, "@" .. p.Name, 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 18), UDim2.new(1, -66, 0, 13), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd

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
                if copyTarget == p then
                    copyTarget = nil -- klik lagi = batal pilih
                else
                    copyTarget = p
                end
                updateCopyUI()
                refreshCopyList()
            end)
        end
    end
end

selectCopyBtn.MouseButton1Click:Connect(function()
    selectCopyOpen = not selectCopyOpen
    selectCopyFrame.Visible = selectCopyOpen

    if selectCopyOpen then
        selectCopyBtn.Text = "🎯 CLOSE SELECT COPY"
        refreshCopyList()
    else
        selectCopyBtn.Text = "🎯 SELECT COPY"
    end
end)

Players.PlayerAdded:Connect(function()
    if selectCopyOpen then refreshCopyList() end
end)
Players.PlayerRemoving:Connect(function(p)
    if copyTarget == p then
        copyTarget = nil
        updateCopyUI()
    end
    task.defer(function()
        if selectCopyOpen then refreshCopyList() end
    end)
end)

copyAvaBtn.MouseButton1Click:Connect(function()
    if not copyTarget then
        avaFlash(copyAvaBtn, "⚠️ PILIH USERNAME DULU!", AVA_ERR)
        return
    end

    local ok, err = runCopier(copyTarget.Name)
    if ok then
        avaFlash(copyAvaBtn, "✅ COPYING @" .. copyTarget.Name, ON_COLOR)
    else
        warn("Copy avatar gagal: " .. tostring(err))
        avaFlash(copyAvaBtn, "⚠️ GAGAL", AVA_ERR)
    end
end)

restoreAvaBtn.MouseButton1Click:Connect(function()
    local ok, err = runCopier("restore")
    if ok then
        avaFlash(restoreAvaBtn, "✅ RESTORED", ON_COLOR)
    else
        warn("Restore avatar gagal: " .. tostring(err))
        avaFlash(restoreAvaBtn, "⚠️ GAGAL", AVA_ERR)
    end
end)
end

do
-- ==================== FOLLOW / HIDE ALL / SPECTATE (memakai SELECT PLAYER) ====================
local function uFlash(btn, text, color, original)
    btn.Text = text
    btn.BackgroundColor3 = color
    task.delay(1.5, function()
        btn.Text = original
        btn.BackgroundColor3 = BG_BUTTON
    end)
end

-- FOLLOW
local followBtn = makePlayerButton("🎯 FOLLOW • OFF", 12)
local followOn = false
local followConn

followBtn.MouseButton1Click:Connect(function()
    if followOn then
        followOn = false
        if followConn then followConn:Disconnect() followConn = nil end
        followBtn.Text = "🎯 FOLLOW • OFF"
        followBtn.BackgroundColor3 = BG_BUTTON
        return
    end

    if not selectedPlayer then
        uFlash(followBtn, "⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40), "🎯 FOLLOW • OFF")
        return
    end

    followOn = true
    followBtn.Text = "🎯 FOLLOW • ON"
    followBtn.BackgroundColor3 = ON_COLOR

    followConn = RunService.Heartbeat:Connect(function()
        if not (followOn and selectedPlayer) then return end
        local th = selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local mh = getHRP()
        if th and mh then
            mh.CFrame = mh.CFrame:Lerp(th.CFrame * CFrame.new(0, 0, 3), 0.15)
        end
    end)
end)

table.insert(cleanupFns, function()
    followOn = false
    if followConn then followConn:Disconnect() end
end)

-- HIDE ALL (sembunyikan pemain lain di layar kamu)
local hideBtn = makePlayerButton("🚫 HIDE ALL • OFF", 13)
local hideOn = false
local hideConn
local hideStore = {}

local function hideCharacter(c)
    if not c or c == character then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            if hideStore[d] == nil then hideStore[d] = d.Transparency end
            d.Transparency = 1
        end
    end
end

local function restoreHidden()
    for o, t in pairs(hideStore) do
        if o and o.Parent then o.Transparency = t end
    end
    hideStore = {}
end

hideBtn.MouseButton1Click:Connect(function()
    hideOn = not hideOn
    hideBtn.Text = hideOn and "🚫 HIDE ALL • ON" or "🚫 HIDE ALL • OFF"
    hideBtn.BackgroundColor3 = hideOn and ON_COLOR or BG_BUTTON

    if hideOn then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then hideCharacter(p.Character) end
        end

        hideConn = workspace.DescendantAdded:Connect(function(d)
            if not hideOn then return end
            local m = d:FindFirstAncestorOfClass("Model")
            if m and m ~= character and Players:GetPlayerFromCharacter(m) then
                task.wait(0.1)
                hideCharacter(m)
            end
        end)
    else
        if hideConn then hideConn:Disconnect() hideConn = nil end
        restoreHidden()
    end
end)

table.insert(cleanupFns, function()
    hideOn = false
    if hideConn then hideConn:Disconnect() end
    restoreHidden()
end)

-- SPECTATE
local specBtn = makePlayerButton("👀 SPECTATE • OFF", 14)
local specOn = false
local specConn
local specAnchored

local function stopSpectate()
    specOn = false
    if specConn then specConn:Disconnect() specConn = nil end

    local hrp = getHRP()
    if hrp and specAnchored ~= nil then hrp.Anchored = specAnchored end
    specAnchored = nil

    local hum = getHumanoid()
    local cam = workspace.CurrentCamera
    if hum and cam then cam.CameraSubject = hum end

    specBtn.Text = "👀 SPECTATE • OFF"
    specBtn.BackgroundColor3 = BG_BUTTON
end

specBtn.MouseButton1Click:Connect(function()
    if specOn then
        stopSpectate()
        return
    end

    if not selectedPlayer then
        uFlash(specBtn, "⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40), "👀 SPECTATE • OFF")
        return
    end

    specOn = true
    specBtn.Text = "👀 SPECTATE @" .. selectedPlayer.Name
    specBtn.BackgroundColor3 = ON_COLOR

    local hrp = getHRP()
    if hrp then
        specAnchored = hrp.Anchored
        hrp.Anchored = true
    end

    specConn = RunService.Heartbeat:Connect(function()
        if not specOn then return end

        -- target keluar dari game -> berhenti
        if not selectedPlayer or selectedPlayer.Parent ~= Players then
            stopSpectate()
            return
        end

        local th = selectedPlayer.Character and selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        if th and cam and cam.CameraSubject ~= th then
            cam.CameraSubject = th
            cam.CameraType = Enum.CameraType.Custom
        end
    end)
end)

table.insert(cleanupFns, function() if specOn then stopSpectate() end end)
player.CharacterAdded:Connect(function() if specOn then stopSpectate() end end)
end


do
-- ==================== TELEPORT PAGE (10 SLOT) ====================
-- Berdiri di tempat yang mau disimpan, tekan SAVE. Tekan GO untuk teleport ke sana.
newLabel(teleportPage, "📍 TELEPORT SLOTS (10)", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), Enum.TextXAlignment.Left).LayoutOrder = 0

local teleportSlots = {} -- [i] = CFrame

local function makeTeleportSlot(i)
    local row = Instance.new("Frame")
    row.LayoutOrder = i
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = BG_DARK
    row.BorderSizePixel = 0
    row.Parent = teleportPage
    corner(row, 8)

    newLabel(row, "SLOT " .. i, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 3), UDim2.new(1, -124, 0, 18), Enum.TextXAlignment.Left)
    local sub = newLabel(row, "Empty", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 8, 0, 20), UDim2.new(1, -124, 0, 14), Enum.TextXAlignment.Left)
    sub.TextTruncate = Enum.TextTruncate.AtEnd

    local function slotButton(text, xOff)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 52, 0, 26)
        b.Position = UDim2.new(1, xOff, 0.5, -13)
        b.BackgroundColor3 = BG_BUTTON
        b.Text = text
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = WHITE
        b.AutoButtonColor = false
        b.Parent = row
        corner(b, 6)
        return b
    end

    local saveBtn = slotButton("💾 SAVE", -114)
    local goBtn = slotButton("🚀 GO", -58)

    local function flash(btn, text, color, original)
        btn.Text = text
        btn.BackgroundColor3 = color
        task.delay(1.2, function()
            btn.Text = original
            btn.BackgroundColor3 = BG_BUTTON
        end)
    end

    saveBtn.MouseButton1Click:Connect(function()
        local hrp = getHRP()
        if not hrp then
            flash(saveBtn, "⚠️", Color3.fromRGB(80, 40, 40), "💾 SAVE")
            return
        end
        teleportSlots[i] = hrp.CFrame
        local p = hrp.Position
        sub.Text = string.format("Saved (%d, %d, %d)", p.X, p.Y, p.Z)
        sub.TextColor3 = GREEN
        flash(saveBtn, "✅ SAVED", ON_COLOR, "💾 SAVE")
    end)

    goBtn.MouseButton1Click:Connect(function()
        local hrp = getHRP()
        if hrp and teleportSlots[i] then
            hrp.CFrame = teleportSlots[i]
            flash(goBtn, "✅ TP!", ON_COLOR, "🚀 GO")
        else
            flash(goBtn, "⚠️ EMPTY", Color3.fromRGB(80, 40, 40), "🚀 GO")
        end
    end)
end

for i = 1, 10 do
    makeTeleportSlot(i)
end
end

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
    hookGod()
    applyInvisible()
    applyAdminBadge()
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
logoBtn.TextSize = 18
logoBtn.Font = Enum.Font.GothamMedium
logoBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
logoBtn.Parent = screenGui
corner(logoBtn, 22)
stroke(logoBtn, Color3.fromRGB(255, 215, 0), 1.5)

-- Logo bisa digeser: geser lebih dari ~8 px = drag, tap biasa = buka/tutup menu
local logoDragging, logoMoved = false, false
local logoStart, logoStartPos

logoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        logoDragging = true
        logoMoved = false
        logoStart = input.Position
        logoStartPos = logoBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                logoDragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not logoDragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local d = input.Position - logoStart
    if not logoMoved and d.Magnitude < 8 then return end
    logoMoved = true
    logoBtn.Position = UDim2.new(
        logoStartPos.X.Scale, logoStartPos.X.Offset + d.X,
        logoStartPos.Y.Scale, logoStartPos.Y.Offset + d.Y
    )
end)

logoBtn.MouseButton1Click:Connect(function()
    if logoMoved then
        logoMoved = false -- habis di-drag, jangan toggle menu
        return
    end
    mainFrame.Visible = not mainFrame.Visible
end)

-- Bikin panel semi-transparan supaya background foto kelihatan
local function softenUI(o)
    if o == bgImage then return end
    if (o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox") or o:IsA("ScrollingFrame"))
        and o.BackgroundTransparency == 0 then
        o.BackgroundTransparency = 0.5
    end
end
for _, o in ipairs(mainFrame:GetDescendants()) do softenUI(o) end
mainFrame.DescendantAdded:Connect(softenUI)

print("✅ UNIVERSAL Loaded!")

end, function(e)
    return tostring(e)
end)

if __ok then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "UNIVERSAL",
            Text = "Script loaded ✔",
            Duration = 4,
        })
    end)
else
    warn("UNIVERSAL error: " .. tostring(__err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "UNIVERSAL error",
            Text = tostring(__err):sub(1, 200),
            Duration = 20,
        })
    end)
end

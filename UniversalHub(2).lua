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

-- Tombol ↑ ↓ dipakai bareng oleh FLY, FREE CAM, dan WALK ON AIR.
-- Tiap fitur set attribute-nya sendiri, panel tampil kalau salah satunya aktif.
flyControlFrame.AttributeChanged:Connect(function()
    flyControlFrame.Visible = (flyControlFrame:GetAttribute("fly") == true)
        or (flyControlFrame:GetAttribute("free") == true)
        or (flyControlFrame:GetAttribute("air") == true)
end)

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
    flyControlFrame:SetAttribute("fly", false)
    flyBtn.Text = "✈️ FLY • OFF"
    flyBtn.BackgroundColor3 = BG_BUTTON
end

local function startFly()
    local hrp, hum = getHRP(), getHumanoid()
    if not hrp or not hum then return end

    flyOn = true
    flyControlFrame:SetAttribute("fly", true)
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
-- WALK ON AIR (DIPERBAIKI)
-- Papan tak terlihat di bawah kaki yang ikut kamu jalan, jadi bisa jalan/lari bebas di udara.
-- Naik/turun: tombol ↑ ↓ di kanan layar (HP) atau E / Q (PC). Lompat tetap lompat biasa.
-- Penyebab lama tidak jalan: papan pakai CanQuery=false, padahal Humanoid mencari lantai lewat raycast,
-- jadi papan "tidak dianggap lantai". Papan juga telat ngikutin saat lari kencang.
local airBtn = makeFarmButton("🌊 WALK ON AIR • OFF", 10)
local airOn = false
local airPart, airConn
local airY = 0
local AIR_VSPEED = 25 -- stud/detik naik / turun
local AIR_SIZE = 16   -- lebar papan

local function stopAir()
    airOn = false
    if airConn then airConn:Disconnect() airConn = nil end
    if airPart then airPart:Destroy() airPart = nil end
    flyControlFrame:SetAttribute("air", false)
    airBtn.Text = "🌊 WALK ON AIR • OFF"
    airBtn.BackgroundColor3 = BG_BUTTON
end

airBtn.MouseButton1Click:Connect(function()
    if airOn then
        stopAir()
        return
    end

    local hrp, hum = getHRP(), getHumanoid()
    if not (hrp and hum) then return end

    airOn = true
    airBtn.Text = "🌊 WALK ON AIR • ON"
    airBtn.BackgroundColor3 = ON_COLOR

    -- jarak HRP ke telapak kaki (R6 beda dengan R15)
    local feet
    if hum.RigType == Enum.HumanoidRigType.R6 then
        feet = 3
    else
        feet = hrp.Size.Y / 2 + hum.HipHeight
    end
    airY = hrp.Position.Y - feet - 0.5 -- permukaan papan pas di telapak kaki

    airPart = Instance.new("Part")
    airPart.Name = "_AirWalk"
    airPart.Size = Vector3.new(AIR_SIZE, 1, AIR_SIZE)
    airPart.Transparency = 1
    airPart.Anchored = true
    airPart.CanCollide = true
    airPart.CanQuery = true  -- WAJIB true supaya Humanoid mendeteksi papan sebagai lantai
    airPart.CanTouch = false
    airPart.CastShadow = false
    airPart.CFrame = CFrame.new(hrp.Position.X, airY, hrp.Position.Z)
    airPart.Parent = workspace

    flyControlFrame:SetAttribute("air", true)

    -- Stepped = sebelum physics jalan, papan digeser sedikit ke depan sesuai kecepatan
    -- supaya tidak ketinggalan waktu lari kencang
    airConn = RunService.Stepped:Connect(function(_, dt)
        local r = getHRP()
        if not (r and airPart and airPart.Parent) then return end

        local up = 0
        if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.E) then up = up + 1 end
        if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.Q) then up = up - 1 end
        airY = airY + up * AIR_VSPEED * dt

        local v = r.AssemblyLinearVelocity
        local lead = Vector3.new(v.X, 0, v.Z) * dt * 2
        airPart.CFrame = CFrame.new(r.Position.X + lead.X, airY, r.Position.Z + lead.Z)
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
        flyControlFrame:SetAttribute("free", true) -- tombol ↑ ↓ dipakai untuk naik/turun

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

        flyControlFrame:SetAttribute("free", false)
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

-- Judul tiap bagian di tab PLAYER (TELEPORT / COPY / HIDE / FOLLOW / SPECTATE) biar tidak tercampur
local function sectionHeader(text, order)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = BG_DARK
    f.BorderSizePixel = 0
    f.Parent = playerPage
    corner(f, 6)
    stroke(f, ACCENT_BLUE, 1)
    newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), Enum.TextXAlignment.Left)
    return f
end

-- ===== PICKER: daftar player + kolom cari, dipakai TELEPORT, COPY, FOLLOW, SPECTATE (masing-masing SELECT sendiri) =====
local function makePicker(opts)
    local P = { selected = nil, open = false }
    P.btn = makePlayerButton(opts.btnText, opts.btnOrder)

    local frame = Instance.new("Frame")
    frame.LayoutOrder = opts.frameOrder
    frame.Size = UDim2.new(1, 0, 0, 150)
    frame.BackgroundColor3 = BG_DARK
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = playerPage
    corner(frame, 8)
    stroke(frame, BORDER_BLUE, 1)

    local title = newLabel(frame, "Pilih player (klik untuk pilih)", 10, Enum.Font.GothamBold, WHITE,
        UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 16), Enum.TextXAlignment.Left)
    title.TextTruncate = Enum.TextTruncate.AtEnd

    local search = Instance.new("TextBox")
    search.Size = UDim2.new(1, -16, 0, 22)
    search.Position = UDim2.new(0, 8, 0, 22)
    search.BackgroundColor3 = BG_BUTTON
    search.PlaceholderText = "🔍 cari nama..."
    search.PlaceholderColor3 = GREY
    search.Text = ""
    search.TextSize = 10
    search.Font = Enum.Font.GothamBold
    search.TextColor3 = WHITE
    search.ClearTextOnFocus = false
    search.Parent = frame
    corner(search, 6)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -52)
    scroll.Position = UDim2.new(0, 4, 0, 48)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = ACCENT_BLUE
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = scroll

    function P.refresh()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        if P.selected and P.selected.Parent ~= Players then
            P.selected = nil
            title.Text = "Pilih player (klik untuk pilih)"
        end

        local q = string.lower(search.Text or "")
        local shown = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local hay = string.lower(p.Name .. " " .. p.DisplayName)
                if q == "" or string.find(hay, q, 1, true) then
                    shown = shown + 1
                    local isSel = (P.selected == p)

                    local row = Instance.new("TextButton")
                    row.Name = p.Name
                    row.Size = UDim2.new(1, 0, 0, 28)
                    row.BackgroundColor3 = isSel and ON_COLOR or BG_BUTTON
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.AutoButtonColor = false
                    row.Parent = scroll
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
                        if ok and avImg.Parent then avImg.Image = thumb end
                    end)

                    newLabel(row, p.DisplayName .. "  @" .. p.Name, 10, Enum.Font.GothamBold, WHITE,
                        UDim2.new(0, 34, 0, 0), UDim2.new(1, -64, 1, 0), Enum.TextXAlignment.Left).TextTruncate = Enum.TextTruncate.AtEnd

                    local check = Instance.new("TextLabel")
                    check.Size = UDim2.new(0, 20, 1, 0)
                    check.Position = UDim2.new(1, -24, 0, 0)
                    check.BackgroundTransparency = 1
                    check.Text = "✓"
                    check.TextSize = 14
                    check.Font = Enum.Font.GothamBold
                    check.TextColor3 = GREEN
                    check.Visible = isSel
                    check.Parent = row

                    row.MouseButton1Click:Connect(function()
                        if P.selected == p then
                            P.set(nil) -- klik lagi = batal pilih
                        else
                            P.set(p)
                        end
                    end)
                end
            end
        end

        if shown == 0 then
            local empty = Instance.new("TextButton")
            empty.Name = "_empty"
            empty.Size = UDim2.new(1, 0, 0, 24)
            empty.BackgroundTransparency = 1
            empty.Text = (q == "") and "Belum ada player lain" or "Tidak ditemukan"
            empty.TextSize = 10
            empty.Font = Enum.Font.Gotham
            empty.TextColor3 = GREY
            empty.AutoButtonColor = false
            empty.Parent = scroll
        end
    end

    function P.set(p)
        P.selected = p
        if p then
            title.Text = "Dipilih: " .. p.DisplayName .. " (@" .. p.Name .. ")"
        else
            title.Text = "Pilih player (klik untuk pilih)"
        end
        if opts.onChange then opts.onChange(p) end
        P.refresh()
    end

    search:GetPropertyChangedSignal("Text"):Connect(function()
        if P.open then P.refresh() end
    end)

    P.btn.MouseButton1Click:Connect(function()
        P.open = not P.open
        frame.Visible = P.open
        P.btn.Text = P.open and opts.closeText or opts.btnText
        if P.open then P.refresh() end
    end)

    Players.PlayerAdded:Connect(function()
        if P.open then P.refresh() end
    end)
    Players.PlayerRemoving:Connect(function(p)
        if P.selected == p then P.set(nil) end
        task.defer(function()
            if P.open then P.refresh() end
        end)
    end)

    return P
end

-- ==================== TELEPORT KE PLAYER (SELECT TELEPORT sendiri) ====================
sectionHeader("🚀 TELEPORT PLAYER", 10)
local tpPick
local tpPlayerBtn = makePlayerButton("🚀 TELEPORT PLAYER", 13)

tpPick = makePicker({
    btnText = "🎯 SELECT TELEPORT",
    closeText = "🎯 CLOSE SELECT",
    btnOrder = 11,
    frameOrder = 12,
    onChange = function(p)
        if p then
            tpPlayerBtn.Text = "🚀 TP KE " .. string.upper(p.DisplayName)
        else
            tpPlayerBtn.Text = "🚀 TELEPORT PLAYER"
        end
    end,
})

tpPlayerBtn.MouseButton1Click:Connect(function()
    local function flash(text, color)
        tpPlayerBtn.Text = text
        tpPlayerBtn.BackgroundColor3 = color
        task.delay(1.5, function()
            tpPlayerBtn.BackgroundColor3 = BG_BUTTON
            local sel = tpPick.selected
            tpPlayerBtn.Text = sel and ("🚀 TP KE " .. string.upper(sel.DisplayName)) or "🚀 TELEPORT PLAYER"
        end)
    end

    local sel = tpPick.selected
    if not sel then
        flash("⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40))
        return
    end

    local targetHrp = sel.Character and sel.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = getHRP()

    if targetHrp and myHrp then
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
        flash("✅ TELEPORTED!", ON_COLOR)
    else
        flash("⚠️ PLAYER BELUM SPAWN", Color3.fromRGB(80, 40, 40))
    end
end)

do
-- ==================== COPY AVATAR (SELECT COPY sendiri) ====================
-- Menyalin SELURUH avatar target: baju, aksesori, warna badan, wajah, ukuran badan, DAN animasi
-- (idle / walk / run / jump / fall / climb / swim).
-- Kalau target tidak punya animasi tertentu -> animasi kamu kembali ke yang biasa (bawaan game).
-- Catatan: ini client-side, biasanya cuma kelihatan di layarmu sendiri.
sectionHeader("🎭 COPY AVATAR", 20)

local AVA_ERR = Color3.fromRGB(80, 40, 40)
local CS = { desc = nil, active = false, busy = false, orig = nil, origChar = nil }
local copyPick

local copyAvaBtn = makePlayerButton("🎭 COPY AVATAR", 23)
local restoreAvaBtn = makePlayerButton("♻️ RESTORE AVATAR", 24)

-- slot animasi di script "Animate" bawaan Roblox
local ANIM_SLOTS = {
    { prop = "IdleAnimation",  folder = "idle",  kids = { "Animation1", "Animation2" } },
    { prop = "WalkAnimation",  folder = "walk",  kids = { "WalkAnim" } },
    { prop = "RunAnimation",   folder = "run",   kids = { "RunAnim" } },
    { prop = "JumpAnimation",  folder = "jump",  kids = { "JumpAnim" } },
    { prop = "FallAnimation",  folder = "fall",  kids = { "FallAnim" } },
    { prop = "ClimbAnimation", folder = "climb", kids = { "ClimbAnim" } },
    { prop = "SwimAnimation",  folder = "swim",  kids = { "Swim" } },
}

local function updateCopyUI()
    local sel = copyPick and copyPick.selected
    copyAvaBtn.Text = sel and ("🎭 COPY AVATAR @" .. sel.Name) or "🎭 COPY AVATAR"
    restoreAvaBtn.Text = "♻️ RESTORE AVATAR"
end

copyPick = makePicker({
    btnText = "🎯 SELECT COPY",
    closeText = "🎯 CLOSE SELECT COPY",
    btnOrder = 21,
    frameOrder = 22,
    onChange = function() updateCopyUI() end,
})

local function avaFlash(btn, text, color)
    btn.Text = text
    btn.BackgroundColor3 = color
    task.delay(2, function()
        btn.BackgroundColor3 = BG_BUTTON
        updateCopyUI()
    end)
end

-- simpan avatar + animasi ASLI milikmu (sekali per karakter) buat RESTORE dan buat animasi "biasa"
local function captureOriginal(char, hum)
    if CS.origChar == char then return end
    local o = { desc = nil, anim = {} }
    pcall(function() o.desc = hum:GetAppliedDescription() end)

    local animate = char:FindFirstChild("Animate")
    if animate then
        for _, slot in ipairs(ANIM_SLOTS) do
            local folder = animate:FindFirstChild(slot.folder)
            if folder then
                for _, kid in ipairs(slot.kids) do
                    local a = folder:FindFirstChild(kid)
                    if a and a:IsA("Animation") then
                        o.anim[slot.folder .. "/" .. kid] = a.AnimationId
                    end
                end
            end
        end
    end
    CS.orig = o
    CS.origChar = char
end

-- samakan animasi dengan target
local function syncAnimations(char, desc)
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return end
    local o = CS.orig

    for _, slot in ipairs(ANIM_SLOTS) do
        local id = 0
        pcall(function() id = desc[slot.prop] or 0 end)
        local folder = animate:FindFirstChild(slot.folder)
        if folder then
            if id == 0 then
                -- target tidak punya animasi ini -> balik ke animasi biasa
                for _, kid in ipairs(slot.kids) do
                    local a = folder:FindFirstChild(kid)
                    local saved = o and o.anim[slot.folder .. "/" .. kid]
                    if a and saved and a.AnimationId ~= saved then a.AnimationId = saved end
                end
            else
                -- target punya animasi -> pastikan benar-benar terpasang
                local a = folder:FindFirstChild(slot.kids[1])
                if a and not string.find(a.AnimationId, tostring(id), 1, true) then
                    a.AnimationId = "rbxassetid://" .. tostring(id)
                end
            end
        end
    end
end

local function applyDescription(char, hum, desc)
    local ok, err = pcall(function() hum:ApplyDescription(desc) end)
    if not ok then return false, err end
    task.wait(0.25)
    pcall(syncAnimations, char, desc)
    return true
end

-- ambil avatar target dari profilnya (lengkap + animasi); cadangan: yang sedang dipakai di karakternya
local function getTargetDesc(target)
    local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(target.UserId) end)
    if ok and desc then return desc end

    local tc = target.Character
    local th = tc and tc:FindFirstChildOfClass("Humanoid")
    if th then
        local ok2, d2 = pcall(function() return th:GetAppliedDescription() end)
        if ok2 and d2 then return d2 end
    end
    return nil
end

local function runBusy(fn)
    CS.busy = true
    local ok, a, b = pcall(fn)
    CS.busy = false
    if not ok then return false, tostring(a) end
    return a, b
end

local function doCopy(target)
    if CS.busy then return false, "masih diproses" end
    return runBusy(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false, "karakter belum siap" end

        local desc = getTargetDesc(target)
        if not desc then return false, "avatar target tidak bisa diambil" end

        captureOriginal(char, hum)
        local ok, err = applyDescription(char, hum, desc)
        if not ok then return false, tostring(err) end

        CS.desc = desc
        CS.active = true
        return true
    end)
end

local function doRestore()
    if CS.busy then return false, "masih diproses" end
    if not CS.active then return false, "tidak sedang copy" end
    return runBusy(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false, "karakter belum siap" end

        local o = CS.orig
        local desc = o and o.desc
        if not desc then
            local ok, d = pcall(function() return Players:GetHumanoidDescriptionFromUserId(player.UserId) end)
            if ok then desc = d end
        end
        if not desc then return false, "avatar asli tidak ditemukan" end

        local ok, err = pcall(function() hum:ApplyDescription(desc) end)
        if not ok then return false, tostring(err) end
        task.wait(0.25)

        -- kembalikan animasi asli
        local animate = char:FindFirstChild("Animate")
        if animate and o then
            for key, saved in pairs(o.anim) do
                local f, k = string.match(key, "^(.-)/(.+)$")
                local folder = f and animate:FindFirstChild(f)
                local a = folder and folder:FindFirstChild(k)
                if a and a.AnimationId ~= saved then a.AnimationId = saved end
            end
        end

        CS.active = false
        CS.desc = nil
        return true
    end)
end

copyAvaBtn.MouseButton1Click:Connect(function()
    local target = copyPick.selected
    if not target then
        avaFlash(copyAvaBtn, "⚠️ PILIH PLAYER DULU!", AVA_ERR)
        return
    end
    if CS.busy then return end

    copyAvaBtn.Text = "⏳ MENYALIN @" .. target.Name .. "..."
    task.spawn(function()
        local ok, err = doCopy(target)
        if ok then
            avaFlash(copyAvaBtn, "✅ COPIED @" .. target.Name, ON_COLOR)
        else
            warn("Copy avatar gagal: " .. tostring(err))
            avaFlash(copyAvaBtn, "⚠️ GAGAL: " .. string.sub(tostring(err), 1, 22), AVA_ERR)
        end
    end)
end)

restoreAvaBtn.MouseButton1Click:Connect(function()
    if CS.busy then return end
    restoreAvaBtn.Text = "⏳ MENGEMBALIKAN..."
    task.spawn(function()
        local ok, err = doRestore()
        if ok then
            avaFlash(restoreAvaBtn, "✅ RESTORED", ON_COLOR)
        else
            warn("Restore avatar gagal: " .. tostring(err))
            avaFlash(restoreAvaBtn, "⚠️ " .. string.sub(tostring(err), 1, 26), AVA_ERR)
        end
    end)
end)

-- respawn: kalau masih mode copy, pasang lagi avatar hasil copy
player.CharacterAdded:Connect(function(c)
    if not (CS.active and CS.desc) then return end
    task.spawn(function()
        local hum = c:WaitForChild("Humanoid", 10)
        if not hum then return end
        c:WaitForChild("Animate", 5)
        task.wait(1.5)
        if not (CS.active and CS.desc) or player.Character ~= c then return end
        runBusy(function()
            captureOriginal(c, hum)
            applyDescription(c, hum, CS.desc)
            return true
        end)
    end)
end)
end

do
-- ==================== FOLLOW / HIDE ALL / SPECTATE (masing-masing punya SELECT sendiri) ====================
local function uFlash(btn, text, color, original)
    btn.Text = text
    btn.BackgroundColor3 = color
    task.delay(1.5, function()
        btn.Text = original
        btn.BackgroundColor3 = BG_BUTTON
    end)
end


-- ===== FOLLOW =====
--  Kamu selalu MELUNCUR (glide): badan bergeser mulus ikut target tanpa animasi jalan = diam tapi jalan.
--  AUTO TP • ON  : mulai follow langsung TELEPORT ke belakang target, dan kalau target menjauh
--                  lebih dari batas "TP kalau lebih jauh" -> langsung TELEPORT lagi ke jarak yang diatur.
--  AUTO TP • OFF : tidak pernah teleport, cuma meluncur (nyusul cepat kalau ketinggalan).
--  Target jalan biasa (dalam batas) -> tidak teleport, kamu meluncur ikut dari belakang.
do
sectionHeader("🚶 FOLLOW PLAYER", 40)

local FS = { on = false, conn = nil, chasing = false, snap = false, autoTp = true }
local followPick, followBtn, stopFollow

followBtn = makePlayerButton("🚶 FOLLOW • OFF", 43)

local tpToggle = makePlayerButton("🚀 AUTO TP • ON", 44)
tpToggle.BackgroundColor3 = ON_COLOR
tpToggle.MouseButton1Click:Connect(function()
    FS.autoTp = not FS.autoTp
    tpToggle.Text = FS.autoTp and "🚀 AUTO TP • ON" or "🚀 AUTO TP • OFF"
    tpToggle.BackgroundColor3 = FS.autoTp and ON_COLOR or BG_BUTTON
end)

local function numRow(order, text, default, lo, hi)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 30)
    f.BackgroundColor3 = BG_DARK
    f.BorderSizePixel = 0
    f.Parent = playerPage
    corner(f, 8)
    newLabel(f, text, 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -76, 1, 0), Enum.TextXAlignment.Left)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 56, 0, 22)
    box.Position = UDim2.new(1, -62, 0.5, -11)
    box.BackgroundColor3 = BG_BUTTON
    box.Text = tostring(default)
    box.TextSize = 12
    box.Font = Enum.Font.GothamBold
    box.TextColor3 = WHITE
    box.ClearTextOnFocus = false
    box.Parent = f
    corner(box, 6)

    box.FocusLost:Connect(function()
        local v = tonumber(box.Text) or default
        box.Text = tostring(math.clamp(v, lo, hi))
    end)
    return box
end

local distBox = numRow(45, "📏 JARAK DI BELAKANG (stud)", 4, 2, 30)
local tpBox = numRow(46, "🚀 TP KALAU LEBIH JAUH (stud)", 12, 5, 500)

-- jarak HRP ke telapak kaki (R6 beda dengan R15), supaya tinggi kita sejajar dengan target
local function feetOff(hum, root)
    if hum and hum.RigType == Enum.HumanoidRigType.R6 then return 3 end
    return root.Size.Y / 2 + (hum and hum.HipHeight or 2)
end

-- teleport ke belakang target, menghadap dia
local function snapBehind(mh, mHum, th, tHum, d, flatLook)
    local y = th.Position.Y - feetOff(tHum, th) + feetOff(mHum, mh) + 0.3
    local pos = Vector3.new(th.Position.X - flatLook.X * d, y, th.Position.Z - flatLook.Z * d)
    mh.CFrame = CFrame.new(pos, Vector3.new(th.Position.X, y, th.Position.Z))
    mh.AssemblyLinearVelocity = Vector3.zero
end

followPick = makePicker({
    btnText = "🎯 SELECT FOLLOW",
    closeText = "🎯 CLOSE SELECT",
    btnOrder = 41,
    frameOrder = 42,
    onChange = function(p)
        if FS.on and p then
            followBtn.Text = "🚶 FOLLOWING @" .. p.Name
            FS.snap = true -- ganti target -> (kalau AUTO TP ON) langsung TP ke target baru
        end
    end,
})

stopFollow = function()
    FS.on = false
    FS.chasing = false
    FS.snap = false
    if FS.conn then FS.conn:Disconnect() FS.conn = nil end
    followBtn.Text = "🚶 FOLLOW • OFF"
    followBtn.BackgroundColor3 = BG_BUTTON
end

followBtn.MouseButton1Click:Connect(function()
    if FS.on then
        stopFollow()
        return
    end

    local target = followPick.selected
    if not target then
        uFlash(followBtn, "⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40), "🚶 FOLLOW • OFF")
        return
    end
    if not getHumanoid() then return end

    FS.on = true
    FS.chasing = false
    FS.snap = true -- begitu aktif (AUTO TP ON) langsung TP ke belakang target
    followBtn.Text = "🚶 FOLLOWING @" .. target.Name
    followBtn.BackgroundColor3 = ON_COLOR

    FS.conn = RunService.Heartbeat:Connect(function(dt)
        local t = followPick.selected
        if not t or t.Parent ~= Players then
            stopFollow() -- target keluar / batal pilih
            return
        end

        local tc = t.Character
        local th = tc and tc:FindFirstChild("HumanoidRootPart")
        local tHum = tc and tc:FindFirstChildOfClass("Humanoid")
        local mh, mHum = getHRP(), getHumanoid()
        if not (th and tHum and mh and mHum) or mHum.Health <= 0 then return end

        local d = math.clamp(tonumber(distBox.Text) or 4, 2, 30)
        local tpD = math.max(tonumber(tpBox.Text) or 12, d + 3)

        local gap = Vector3.new(th.Position.X - mh.Position.X, 0, th.Position.Z - mh.Position.Z)
        local gapDist = gap.Magnitude

        local look = th.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
        flatLook = flatLook.Unit

        local tv = th.AssemblyLinearVelocity
        local tFlatSpeed = Vector3.new(tv.X, 0, tv.Z).Magnitude
        local tMoving = tFlatSpeed > 1.5

        -- AUTO TP ON: baru mulai / ganti target / target menjauh melebihi batas -> teleport langsung
        if FS.autoTp and (FS.snap or gapDist > tpD) then
            FS.snap = false
            FS.chasing = false
            snapBehind(mh, mHum, th, tHum, d, flatLook)
            return
        end
        FS.snap = false

        -- titik tujuan: target jalan -> tepat di belakangnya; target diam -> di jarak d dari sisi kita
        local dest
        if tMoving then
            dest = th.Position - flatLook * d
        else
            local dir = (gapDist > 0.01) and gap.Unit or flatLook
            dest = th.Position - dir * d
        end
        local delta = Vector3.new(dest.X - mh.Position.X, 0, dest.Z - mh.Position.Z)
        local dl = delta.Magnitude

        -- diam kalau sudah pas di jarak (hysteresis supaya tidak gerak-berhenti terus)
        local wantMove
        if FS.chasing then
            wantMove = dl > 0.25
        else
            wantMove = dl > (tMoving and 0.4 or 1.5)
        end
        FS.chasing = wantMove

        -- GLIDE: geser CFrame, Humanoid tidak diperintah jalan -> animasi tetap diam
        local mpos = mh.Position
        local nx, nz = mpos.X, mpos.Z
        if wantMove then
            local speed = math.min(tFlatSpeed + dl * 8, 150) -- makin jauh makin cepat nyusul, tetap mulus
            local step = math.min(dl, speed * dt)
            local u = delta.Unit
            nx = nx + u.X * step
            nz = nz + u.Z * step
        end

        -- naik kalau target naik/loncat; turun diurus gravitasi
        local ny = mpos.Y
        local vy = mh.AssemblyLinearVelocity.Y
        local wantY = th.Position.Y - feetOff(tHum, th) + feetOff(mHum, mh)
        if wantY > ny + 0.3 then
            ny = ny + math.min(wantY - ny, 70 * dt)
            vy = 0
        end

        local newPos = Vector3.new(nx, ny, nz)
        local faceTo = Vector3.new(th.Position.X, ny, th.Position.Z)
        if (faceTo - newPos).Magnitude > 0.05 then
            mh.CFrame = CFrame.new(newPos, faceTo) -- selalu menghadap target
        else
            mh.CFrame = CFrame.new(newPos) * mh.CFrame.Rotation
        end
        mh.AssemblyLinearVelocity = Vector3.new(0, vy, 0)
    end)
end)

table.insert(cleanupFns, function() if FS.on then stopFollow() end end)
end

-- HIDE ALL (sembunyikan pemain lain di layar kamu)
sectionHeader("🙈 HIDE ALL", 30)
local hideBtn = makePlayerButton("🚫 HIDE ALL • OFF", 31)
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

-- SPECTATE: lihat dari sudut pandang player lain. SELECT sendiri (terpisah dari SELECT PLAYER / FOLLOW).
--  ◀ ▶  = pindah ke player sebelumnya / berikutnya
--  👁 POV = kamera pas di mata target (benar-benar lihat apa yang dia lihat), kepala target disembunyikan
do
sectionHeader("👀 SPECTATE PLAYER", 60)

local SP = { on = false, conn = nil, anchored = nil, fp = false, hid = {}, acc = 0 }
local specPick, specBtn, specBar, specInfo, stopSpectate, restoreHeads

specBtn = makePlayerButton("👀 SPECTATE • OFF", 63)

-- baris tombol ◀ ▶ 👁 (muncul saat spectate aktif)
specBar = Instance.new("Frame")
specBar.LayoutOrder = 64
specBar.Size = UDim2.new(1, 0, 0, 28)
specBar.BackgroundTransparency = 1
specBar.Visible = false
specBar.Parent = playerPage

local function specSmallBtn(text, idx)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -4, 1, 0)
    b.Position = UDim2.new((idx - 1) / 3, 2, 0, 0)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = specBar
    corner(b, 8)
    return b
end
local prevBtn = specSmallBtn("◀ PREV", 1)
local povBtn = specSmallBtn("👁 POV • OFF", 2)
local nextBtn = specSmallBtn("NEXT ▶", 3)

specInfo = Instance.new("TextLabel")
specInfo.LayoutOrder = 65
specInfo.Size = UDim2.new(1, 0, 0, 18)
specInfo.BackgroundTransparency = 1
specInfo.Text = ""
specInfo.TextSize = 10
specInfo.Font = Enum.Font.GothamBold
specInfo.TextColor3 = GREEN
specInfo.TextTruncate = Enum.TextTruncate.AtEnd
specInfo.Visible = false
specInfo.Parent = playerPage

-- kepala + aksesori target disembunyikan (cuma di layar kamu) supaya mode POV tidak terhalang
local function hideHeads(tc)
    if not tc then return end
    for _, d in ipairs(tc:GetDescendants()) do
        if d:IsA("BasePart") and (d.Name == "Head" or d:FindFirstAncestorOfClass("Accessory")) then
            d.LocalTransparencyModifier = 1
            SP.hid[d] = true
        end
    end
end

restoreHeads = function()
    for d in pairs(SP.hid) do
        if d and d.Parent then d.LocalTransparencyModifier = 0 end
    end
    SP.hid = {}
end

local function setPov(on)
    SP.fp = on
    povBtn.Text = on and "👁 POV • ON" or "👁 POV • OFF"
    povBtn.BackgroundColor3 = on and ON_COLOR or BG_BUTTON
    restoreHeads()
    if not on then
        -- balik ke kamera biasa mengikuti target
        local cam = workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end
    end
    SP.acc = 1 -- paksa update di frame berikutnya
end

local function specStep(dt)
    local t = specPick.selected
    if not t or t.Parent ~= Players then
        stopSpectate()
        return
    end

    local cam = workspace.CurrentCamera
    local tc = t.Character
    local tHum = tc and tc:FindFirstChildOfClass("Humanoid")
    local head = tc and tc:FindFirstChild("Head")

    if cam and tHum then
        if SP.fp and head then
            -- POV: kamera di mata target
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = head.CFrame * CFrame.new(0, 0.1, -0.6)
        else
            if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
            if cam.CameraSubject ~= tHum then cam.CameraSubject = tHum end
        end
    end

    -- update info + sembunyikan kepala (kena respawn/aksesori baru) tiap ~0.4 detik
    SP.acc = SP.acc + dt
    if SP.acc >= 0.4 then
        SP.acc = 0
        if SP.fp then hideHeads(tc) end

        local th = tc and tc:FindFirstChild("HumanoidRootPart")
        local mh = getHRP()
        local hpText = tHum and string.format("❤ %d/%d", math.floor(tHum.Health + 0.5), math.floor(tHum.MaxHealth + 0.5)) or "💀 belum spawn"
        local distText = (th and mh) and string.format("📏 %d stud", math.floor((th.Position - mh.Position).Magnitude + 0.5)) or ""
        specInfo.Text = "👀 " .. t.DisplayName .. " (@" .. t.Name .. ")  " .. hpText .. "  " .. distText
    end
end

stopSpectate = function()
    SP.on = false
    SP.fp = false
    if SP.conn then SP.conn:Disconnect() SP.conn = nil end
    restoreHeads()

    local hrp = getHRP()
    if hrp and SP.anchored ~= nil then hrp.Anchored = SP.anchored end
    SP.anchored = nil

    local hum = getHumanoid()
    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        if hum then cam.CameraSubject = hum end
    end

    povBtn.Text = "👁 POV • OFF"
    povBtn.BackgroundColor3 = BG_BUTTON
    specBtn.Text = "👀 SPECTATE • OFF"
    specBtn.BackgroundColor3 = BG_BUTTON
    specBar.Visible = false
    specInfo.Visible = false
end

specPick = makePicker({
    btnText = "🎯 SELECT SPECTATE",
    closeText = "🎯 CLOSE SELECT",
    btnOrder = 61,
    frameOrder = 62,
    onChange = function(p)
        if not SP.on then return end
        restoreHeads()
        if p then
            specBtn.Text = "👀 SPECTATE @" .. p.Name
            SP.acc = 1
        else
            stopSpectate()
        end
    end,
})

local function cycle(dir)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p) end
    end
    table.sort(list, function(a, b) return string.lower(a.Name) < string.lower(b.Name) end)
    if #list == 0 then return end

    local idx = 0
    for i, p in ipairs(list) do
        if p == specPick.selected then idx = i break end
    end
    if idx == 0 then
        idx = 1
        if dir > 0 then dir = 0 end
    end
    idx = ((idx - 1 + dir) % #list) + 1
    specPick.set(list[idx])
end

prevBtn.MouseButton1Click:Connect(function() cycle(-1) end)
nextBtn.MouseButton1Click:Connect(function() cycle(1) end)
povBtn.MouseButton1Click:Connect(function() setPov(not SP.fp) end)

specBtn.MouseButton1Click:Connect(function()
    if SP.on then
        stopSpectate()
        return
    end

    local t = specPick.selected
    if not t then
        uFlash(specBtn, "⚠️ PILIH PLAYER DULU!", Color3.fromRGB(80, 40, 40), "👀 SPECTATE • OFF")
        return
    end

    SP.on = true
    SP.acc = 1
    specBtn.Text = "👀 SPECTATE @" .. t.Name
    specBtn.BackgroundColor3 = ON_COLOR
    specBar.Visible = true
    specInfo.Visible = true
    specInfo.Text = "👀 memuat..."

    -- karakter kamu dikunci supaya tidak jalan/kena apa-apa saat nonton
    local hrp = getHRP()
    if hrp then
        SP.anchored = hrp.Anchored
        hrp.Anchored = true
    end

    SP.conn = RunService.RenderStepped:Connect(specStep)
end)

table.insert(cleanupFns, function() if SP.on then stopSpectate() end end)
player.CharacterAdded:Connect(function() if SP.on then stopSpectate() end end)
end
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
    flyControlFrame:SetAttribute("fly", false)
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

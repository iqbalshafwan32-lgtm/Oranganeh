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
-- ===== INFO GAME (tap bar ini untuk buka / tutup) =====
local MarketplaceSvc = game:GetService("MarketplaceService")
local infoPanel = Instance.new("Frame")
infoPanel.Name = "InfoPanel"
infoPanel.Size = UDim2.new(0, 290, 0, 112)
infoPanel.Position = UDim2.new(0.5, -145, 0, 25)
infoPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
infoPanel.BackgroundTransparency = 0.15
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 50
infoPanel.Visible = false
infoPanel.Parent = screenGui
corner(infoPanel, 10)
stroke(infoPanel, ACCENT_BLUE, 1)

local gameName = "Memuat..."
task.spawn(function()
    local ok, info = pcall(function() return MarketplaceSvc:GetProductInfo(game.PlaceId) end)
    gameName = (ok and info and info.Name) or ("Place " .. tostring(game.PlaceId))
end)

local infoText = Instance.new("TextLabel")
infoText.BackgroundTransparency = 1
infoText.Position = UDim2.new(0, 8, 0, 4)
infoText.Size = UDim2.new(1, -16, 0, 56)
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.TextSize = 10
infoText.Font = Enum.Font.GothamBold
infoText.TextColor3 = WHITE
infoText.ZIndex = 51
infoText.Parent = infoPanel

local function infoCopyBtn(text, xs, xo, getter)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(xs, xo, 1, -44)
    b.Size = UDim2.new(0.5, -12, 0, 36)
    b.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
    b.Text = text
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.ZIndex = 51
    b.Parent = infoPanel
    corner(b, 8)
    b.MouseButton1Click:Connect(function()
        local ok = false
        if setclipboard then ok = pcall(setclipboard, tostring(getter())) end
        b.Text = ok and "✅ TERSALIN" or "⚠️ TIDAK SUPPORT"
        task.delay(1.5, function() b.Text = text end)
    end)
end
infoCopyBtn("📋 SALIN PLACE ID", 0, 8, function() return game.PlaceId end)
infoCopyBtn("📋 SALIN JOB ID", 0.5, 4, function() return game.JobId end)

local function refreshInfoPanel()
    infoText.Text = string.format("🎮 %s\n🆔 Place ID: %s\n🧩 Job ID: %s\n👥 Player: %d / %d",
        tostring(gameName), tostring(game.PlaceId), (game.JobId ~= "" and game.JobId or "-"),
        #Players:GetPlayers(), Players.MaxPlayers)
end

local infoTap = Instance.new("TextButton")
infoTap.Size = UDim2.new(1, 0, 1, 0)
infoTap.BackgroundTransparency = 1
infoTap.Text = ""
infoTap.ZIndex = 52
infoTap.Parent = infoBar
infoTap.MouseButton1Click:Connect(function()
    infoPanel.Visible = not infoPanel.Visible
    if infoPanel.Visible then refreshInfoPanel() end
end)
task.spawn(function()
    while infoPanel.Parent do
        task.wait(1)
        if infoPanel.Visible then refreshInfoPanel() end
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
-- Tab bisa digeser kiri/kanan (geser dengan jari / scroll mouse)
local tabContainer = Instance.new("ScrollingFrame")
tabContainer.Size = UDim2.new(1, -16, 0, 28)
tabContainer.Position = UDim2.new(0, 8, 0, 54)
tabContainer.BackgroundColor3 = BG_DARK
tabContainer.BorderSizePixel = 0
tabContainer.ScrollingDirection = Enum.ScrollingDirection.X
tabContainer.ScrollBarThickness = 0
tabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
tabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
tabContainer.ElasticBehavior = Enum.ElasticBehavior.Always
tabContainer.ScrollingEnabled = true
tabContainer.Parent = mainFrame
corner(tabContainer, 8)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabContainer

-- Pages
local pages = {}
local tabButtons = {}

-- Header section dengan efek pinggir (UIStroke) — dipakai di SEMUA tab (FARM, SERVER, PLAYER, TELEPORT).
-- Ditaruh di tabel `pages` supaya tidak menambah jumlah variabel local (batas Lua 200).
function pages.header(parent, text, order)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = BG_DARK
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 6)
    stroke(f, ACCENT_BLUE, 1)
    newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), Enum.TextXAlignment.Left)
    return f
end

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
makePage("ANIMASI") -- diakses lewat pages.ANIMASI (hemat variabel local)
makePage("TEMA") -- diakses lewat pages.TEMA

local function makeTabButton(name, icon, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 78, 1, 0)
    btn.BackgroundColor3 = BG_BUTTON
    btn.Text = icon .. " " .. text
    btn.TextSize = 10
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
                -- geser bar tab supaya tab yang dipilih ada di tengah
                pcall(function()
                    local target = b.AbsolutePosition.X - tabContainer.AbsolutePosition.X + tabContainer.CanvasPosition.X
                        - (tabContainer.AbsoluteSize.X - b.AbsoluteSize.X) / 2
                    tabContainer.CanvasPosition = Vector2.new(math.max(0, target), 0)
                end)
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
makeTabButton("ANIMASI", "🎬", "ANIMASI")
makeTabButton("TEMA", "🎨", "TEMA")

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

pages.header(farmPage, "🌾 FARM / MOVEMENT", 0)

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

-- ==================== ESP (pindah ke tab PLAYER) ====================
-- ESP PLAYER / BOX 2D / TRACER / FPS BOOST MAX. Semua state ditaruh di tabel X
-- supaya tidak menambah variabel local (batas Lua 200).
do
local X = {
    espOn = false, boxOn = false, tracerOn = false, fpsOn = false,
    hl = {}, overlays = {}, saved = {}, conn = nil, addConn = nil, quality = nil,
}
pages.header(playerPage, "👁️ ESP", 4)
X.espBtn = makeButton(playerPage, "👁️ ESP PLAYER • OFF", 5)
X.boxBtn = makeButton(playerPage, "⬜ BOX 2D • OFF", 6)
X.tracerBtn = makeButton(playerPage, "📏 TRACER • OFF", 7)
X.fpsBtn = makeButton(playerPage, "🚀 FPS BOOST MAX • OFF", 8)

function X.setBtn(btn, label, on)
    btn.Text = label .. (on and " • ON" or " • OFF")
    btn.BackgroundColor3 = on and ON_COLOR or BG_BUTTON
end

-- ---------- ESP PLAYER (highlight) ----------
function X.removeESP(p)
    if X.hl[p] then
        X.hl[p]:Destroy()
        X.hl[p] = nil
    end
end

function X.addESP(p)
    if p == player or not p.Character then return end
    X.removeESP(p)
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.7
    h.OutlineTransparency = 0
    h.Parent = p.Character
    X.hl[p] = h
end

X.espBtn.MouseButton1Click:Connect(function()
    X.espOn = not X.espOn
    X.setBtn(X.espBtn, "👁️ ESP PLAYER", X.espOn)
    if X.espOn then
        for _, p in ipairs(Players:GetPlayers()) do X.addESP(p) end
    else
        for p in pairs(X.hl) do X.removeESP(p) end
    end
    X.refreshLoop()
end)

function X.hookPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if X.espOn then X.addESP(p) end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then X.hookPlayer(p) end
end
Players.PlayerAdded:Connect(X.hookPlayer)

-- ---------- BOX 2D + TRACER (digambar pakai Frame, jalan di semua executor/HP) ----------
X.folder = Instance.new("Folder")
X.folder.Name = "ESPOverlay"
X.folder.Parent = screenGui

function X.getOverlay(p)
    local o = X.overlays[p]
    if o then return o end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = X.folder
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 60, 60)
    s.Thickness = 1.5
    s.Parent = box

    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BackgroundColor3 = Color3.fromRGB(255, 60, 200)
    line.BorderSizePixel = 0
    line.Visible = false
    line.Parent = X.folder

    -- nama + darah + jarak (muncul di atas kepala selama fitur ESP apa pun aktif)
    local info = Instance.new("TextLabel")
    info.AnchorPoint = Vector2.new(0.5, 1)
    info.Size = UDim2.fromOffset(170, 28)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.GothamBold
    info.TextSize = 11
    info.TextColor3 = WHITE
    info.TextStrokeTransparency = 0.3
    info.Visible = false
    info.Parent = X.folder

    -- bar darah di sisi kiri box
    local barBg = Instance.new("Frame")
    barBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    barBg.BackgroundTransparency = 0.4
    barBg.BorderSizePixel = 0
    barBg.Visible = false
    barBg.Parent = X.folder
    local bar = Instance.new("Frame")
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0, 0, 1, 0)
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BorderSizePixel = 0
    bar.Parent = barBg

    o = { box = box, line = line, info = info, barBg = barBg, bar = bar }
    X.overlays[p] = o
    return o
end

function X.hideOverlay(o)
    o.box.Visible = false
    o.line.Visible = false
    o.info.Visible = false
    o.barBg.Visible = false
end

function X.destroyOverlay(o)
    o.box:Destroy()
    o.line:Destroy()
    o.info:Destroy()
    o.barBg:Destroy()
end

function X.step()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local myHrp = getHRP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local o = X.getOverlay(p)
            local ch = p.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local top = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bot = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                if top.Z > 0 and bot.Z > 0 then
                    local h = math.abs(bot.Y - top.Y)
                    local w = h * 0.6
                    local maxHp = math.max(hum.MaxHealth, 1)
                    local frac = math.clamp(hum.Health / maxHp, 0, 1)
                    local dist = myHrp and math.floor((hrp.Position - myHrp.Position).Magnitude) or 0

                    -- nama + darah + jarak
                    o.info.Text = string.format("%s\n❤ %d/%d • %dm", p.DisplayName ~= "" and p.DisplayName or p.Name,
                        math.floor(hum.Health), math.floor(maxHp), dist)
                    o.info.Position = UDim2.fromOffset(top.X, top.Y - 3)
                    o.info.Visible = true

                    if X.boxOn then
                        o.box.Size = UDim2.fromOffset(w, h)
                        o.box.Position = UDim2.fromOffset(top.X - w / 2, top.Y)
                        o.box.Visible = true
                        o.barBg.Size = UDim2.fromOffset(3, h)
                        o.barBg.Position = UDim2.fromOffset(top.X - w / 2 - 6, top.Y)
                        o.bar.Size = UDim2.new(1, 0, frac, 0)
                        o.bar.BackgroundColor3 = Color3.fromHSV(frac * 0.33, 1, 1)
                        o.barBg.Visible = true
                    else
                        o.box.Visible = false
                        o.barBg.Visible = false
                    end
                    if X.tracerOn then
                        local a = Vector2.new(vp.X / 2, vp.Y)
                        local b = Vector2.new(bot.X, bot.Y)
                        local d = b - a
                        o.line.Size = UDim2.fromOffset(d.Magnitude, 1.5)
                        o.line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
                        o.line.Rotation = math.deg(math.atan2(d.Y, d.X))
                        o.line.Visible = true
                    else
                        o.line.Visible = false
                    end
                else
                    X.hideOverlay(o)
                end
            else
                X.hideOverlay(o)
            end
        end
    end
end

function X.refreshLoop()
    local need = X.espOn or X.boxOn or X.tracerOn
    if need and not X.conn then
        X.conn = RunService.RenderStepped:Connect(X.step)
    elseif not need and X.conn then
        X.conn:Disconnect()
        X.conn = nil
        for _, o in pairs(X.overlays) do X.hideOverlay(o) end
    end
end

X.boxBtn.MouseButton1Click:Connect(function()
    X.boxOn = not X.boxOn
    X.setBtn(X.boxBtn, "⬜ BOX 2D", X.boxOn)
    X.refreshLoop()
end)

X.tracerBtn.MouseButton1Click:Connect(function()
    X.tracerOn = not X.tracerOn
    X.setBtn(X.tracerBtn, "📏 TRACER", X.tracerOn)
    X.refreshLoop()
end)

Players.PlayerRemoving:Connect(function(p)
    X.removeESP(p)
    local o = X.overlays[p]
    if o then
        X.destroyOverlay(o)
        X.overlays[p] = nil
    end
end)

-- ---------- FPS BOOST MAX ----------
-- Matikan efek berat + sederhanakan material. Semua nilai asli disimpan, jadi OFF = balik seperti semula.
-- Karakter pemain tidak disentuh (supaya avatar / Copy Avatar tetap normal).
function X.save(inst, prop)
    local t = X.saved[inst]
    if not t then
        t = {}
        X.saved[inst] = t
    end
    if t[prop] == nil then t[prop] = inst[prop] end
end

function X.isCharacterPart(v)
    local m = v:FindFirstAncestorOfClass("Model")
    return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

function X.boost(v)
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire")
            or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("PostEffect") then
            X.save(v, "Enabled")
            v.Enabled = false
        elseif v:IsA("BasePart") then
            if X.isCharacterPart(v) then return end
            X.save(v, "Material")
            X.save(v, "Reflectance")
            X.save(v, "CastShadow")
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            if X.isCharacterPart(v) then return end
            X.save(v, "Transparency")
            v.Transparency = 1
        end
    end)
end

function X.fpsOnApply()
    local Lighting = game:GetService("Lighting")
    pcall(function()
        X.save(Lighting, "GlobalShadows")
        X.save(Lighting, "FogEnd")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    end)
    pcall(function()
        local t = workspace.Terrain
        X.save(t, "WaterWaveSize")
        X.save(t, "WaterWaveSpeed")
        X.save(t, "WaterReflectance")
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
    end)
    pcall(function()
        X.quality = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    for _, v in ipairs(Lighting:GetChildren()) do X.boost(v) end

    X.addConn = workspace.DescendantAdded:Connect(function(v)
        if X.fpsOn then X.boost(v) end
    end)

    task.spawn(function()
        local n = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if not X.fpsOn then return end
            X.boost(v)
            n = n + 1
            if n % 400 == 0 then task.wait() end
        end
    end)
end

function X.fpsOffRestore()
    if X.addConn then
        X.addConn:Disconnect()
        X.addConn = nil
    end
    for inst, props in pairs(X.saved) do
        if inst and inst.Parent then
            for prop, val in pairs(props) do
                pcall(function() inst[prop] = val end)
            end
        end
    end
    X.saved = {}
    if X.quality then
        pcall(function() settings().Rendering.QualityLevel = X.quality end)
        X.quality = nil
    end
end

X.fpsBtn.MouseButton1Click:Connect(function()
    X.fpsOn = not X.fpsOn
    X.setBtn(X.fpsBtn, "🚀 FPS BOOST MAX", X.fpsOn)
    if X.fpsOn then X.fpsOnApply() else X.fpsOffRestore() end
end)

table.insert(cleanupFns, function()
    if X.conn then X.conn:Disconnect() X.conn = nil end
    for p in pairs(X.hl) do X.removeESP(p) end
    if X.fpsOn then X.fpsOn = false X.fpsOffRestore() end
end)
end

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
pages.header(serverPage, "🖥️ SERVER TOOLS", 0)

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

pages.header(serverPage, "🚀 SERVER HOP PANEL", 4)

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

-- ==================== TITLE (bisa dipakai SEMUA orang • visual di layarmu) ====================
-- Title + centang verified (opsional) di atas kepala, ada pengaturan warna (rainbow dll) yang bisa dibuka/tutup.
-- Pengaturan tersimpan otomatis (kalau executor support writefile).
do
local TT = {
    on = false, text = "Member", badge = true, color = "blue", open = false, shineSel = true,
    gui = nil, swatches = {}, grads = setmetatable({}, { __mode = "k" }),
    file = "UniversalHub_Title_" .. tostring(player.UserId) .. ".json",
}
pages.TT = TT
local TT_FONT = Font.new("rbxassetid://12187365977", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local function c3(t) return Color3.fromRGB(t[1], t[2], t[3]) end
local function shiny(e, m, s)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, c3(e)), ColorSequenceKeypoint.new(0.30, c3(m)),
        ColorSequenceKeypoint.new(0.50, c3(s)),
        ColorSequenceKeypoint.new(0.70, c3(m)), ColorSequenceKeypoint.new(1.00, c3(e)),
    })
end
local function multi(list)
    local kps = {}
    for i, c in ipairs(list) do kps[i] = ColorSequenceKeypoint.new((i - 1) / (#list - 1), c3(c)) end
    return ColorSequence.new(kps)
end

TT.themes = {
    { name = "rainbow", label = "RAINBOW", shine = false, seq = multi({ {255,0,0},{255,200,0},{0,220,60},{0,200,255},{80,80,255},{220,0,255},{255,0,0} }) },
    { name = "blue",    label = "BLUE",    shine = true, seq = shiny({0,110,255}, {50,160,255}, {230,250,255}) },
    { name = "red",     label = "RED",     shine = true, seq = shiny({255,0,0}, {255,70,70}, {255,240,240}) },
    { name = "green",   label = "GREEN",   shine = true, seq = shiny({0,200,50}, {60,230,110}, {230,255,240}) },
    { name = "purple",  label = "PURPLE",  shine = true, seq = shiny({150,0,255}, {185,70,255}, {245,230,255}) },
    { name = "gold",    label = "GOLD",    shine = true, seq = shiny({200,150,0}, {240,190,60}, {255,255,220}) },
    { name = "orange",  label = "ORANGE",  shine = true, seq = shiny({255,100,0}, {255,150,60}, {255,240,220}) },
    { name = "pink",    label = "PINK",    shine = true, seq = shiny({255,50,150}, {255,110,185}, {255,230,245}) },
    { name = "cyan",    label = "CYAN",    shine = true, seq = shiny({0,180,255}, {60,215,255}, {230,250,255}) },
    { name = "magenta", label = "MAGENTA", shine = true, seq = shiny({200,0,200}, {230,70,230}, {255,220,255}) },
    { name = "lime",    label = "LIME",    shine = true, seq = shiny({120,220,0}, {170,255,50}, {245,255,220}) },
    { name = "teal",    label = "TEAL",    shine = true, seq = shiny({0,150,140}, {40,200,190}, {220,255,252}) },
    { name = "brown",   label = "BROWN",   shine = true, seq = shiny({120,60,20}, {170,100,55}, {240,210,180}) },
    { name = "grey",    label = "GREY",    shine = true, seq = shiny({100,100,100}, {160,160,160}, {240,240,240}) },
    { name = "white",   label = "WHITE",   shine = true, seq = shiny({180,180,180}, {225,225,225}, {255,255,255}) },
    { name = "dark",    label = "DARK",    shine = true, seq = shiny({20,20,20}, {70,70,70}, {180,180,180}) },
    { name = "sunset",  label = "SUNSET",  shine = false, seq = multi({ {255,160,0},{255,60,110},{150,50,255} }) },
    { name = "ocean",   label = "OCEAN",   shine = false, seq = multi({ {0,230,255},{0,110,255},{90,0,210} }) },
    { name = "fire",    label = "FIRE",    shine = false, seq = multi({ {255,235,0},{255,120,0},{220,20,0} }) },
    { name = "ice",     label = "ICE",     shine = false, seq = multi({ {255,255,255},{150,220,255},{60,140,255} }) },
    { name = "neon",    label = "NEON",    shine = false, seq = multi({ {0,255,150},{0,200,255},{200,0,255} }) },
    { name = "galaxy",  label = "GALAXY",  shine = false, seq = multi({ {80,0,160},{210,60,210},{60,110,255} }) },
    { name = "candy",   label = "CANDY",   shine = false, seq = multi({ {255,150,200},{255,255,255},{150,220,255} }) },
    { name = "toxic",   label = "TOXIC",   shine = false, seq = multi({ {190,255,0},{0,255,100},{0,130,70} }) },
}
function TT.find(name)
    for _, e in ipairs(TT.themes) do if e.name == name then return e end end
end

function TT.save()
    if not writefile then return end
    pcall(function()
        writefile(TT.file, HttpService:JSONEncode({ on = TT.on, text = TT.text, badge = TT.badge, color = TT.color }))
    end)
end
function TT.load()
    if not (readfile and isfile) then return end
    pcall(function()
        if isfile(TT.file) then
            local d = HttpService:JSONDecode(readfile(TT.file))
            if type(d) == "table" then
                if type(d.text) == "string" and d.text ~= "" then TT.text = d.text end
                if type(d.badge) == "boolean" then TT.badge = d.badge end
                if type(d.color) == "string" and TT.find(d.color) then TT.color = d.color end
                TT.on = (d.on == true)
            end
        end
    end)
end
TT.load()
do local e = TT.find(TT.color) TT.shineSel = e and e.shine or false end

function TT.rainbowSeq(t)
    local kps = {}
    for i = 0, 6 do
        kps[i + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((t * 0.2 + i / 6) % 1, 1, 1))
    end
    return ColorSequence.new(kps)
end

function TT.paintOne(g)
    local e = TT.find(TT.color)
    if not e then return end
    if e.name == "rainbow" then
        g.Color = TT.rainbowSeq(os.clock())
        g.Offset = Vector2.new(0, 0)
    else
        g.Color = e.seq
        if not e.shine then g.Offset = Vector2.new(0, 0) end
    end
end

-- satu loop animasi untuk semua gradient title (billboard + preview)
RunService.RenderStepped:Connect(function()
    local t = os.clock()
    for g in pairs(TT.grads) do
        if g.Parent then
            if TT.color == "rainbow" then
                g.Color = TT.rainbowSeq(t)
            elseif TT.shineSel then
                g.Offset = Vector2.new((t * 0.3 % 2) - 1, 0)
            end
        else
            TT.grads[g] = nil
        end
    end
end)

-- satu baris: teks title (gradient) + centang verified
function TT.makeRow(parent, size)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 1, 0)
    row.Parent = parent

    local lay = Instance.new("UIListLayout")
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.VerticalAlignment = Enum.VerticalAlignment.Center
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 2)
    lay.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Name = "T"
    lbl.BackgroundTransparency = 1
    lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Size = UDim2.new(0, 0, 1, 0)
    lbl.Font = Enum.Font.GothamBold
    pcall(function() lbl.FontFace = TT_FONT end)
    lbl.TextSize = size
    lbl.TextColor3 = WHITE
    lbl.Text = TT.text
    lbl.LayoutOrder = 1
    lbl.Parent = row
    local st = Instance.new("UIStroke")
    st.Thickness = 2
    st.Color = Color3.new(0, 0, 0)
    st.Parent = lbl
    local g = Instance.new("UIGradient")
    g.Parent = lbl
    TT.grads[g] = true
    TT.paintOne(g)

    local b = Instance.new("TextLabel")
    b.Name = "B"
    b.BackgroundTransparency = 1
    b.Size = UDim2.new(0, size + 2, 1, 0)
    b.Font = Enum.Font.GothamBold
    pcall(function() b.FontFace = TT_FONT end)
    b.TextSize = size
    b.TextColor3 = Color3.fromRGB(0, 162, 255)
    b.Text = utf8.char(0xE000)
    b.Visible = TT.badge
    b.LayoutOrder = 2
    b.Parent = row
    local bs = Instance.new("UIStroke")
    bs.Thickness = 2
    bs.Color = Color3.new(0, 0, 0)
    bs.Parent = b
    return row
end

function TT.remove()
    if TT.gui then TT.gui:Destroy() TT.gui = nil end
end

function TT.apply()
    TT.remove()
    if not TT.on or not character then return end
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "UHTitle"
    gui.Adornee = head
    gui.Size = UDim2.new(0, 260, 0, 36)
    gui.StudsOffset = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 150
    gui.Parent = screenGui
    TT.makeRow(gui, 20)
    TT.gui = gui
end
pages.applyTitle = TT.apply

function TT.refreshAll()
    for g in pairs(TT.grads) do
        if g.Parent then
            TT.paintOne(g)
            local lbl = g.Parent
            lbl.Text = TT.text
            local b = lbl.Parent and lbl.Parent:FindFirstChild("B")
            if b then b.Visible = TT.badge end
        end
    end
end

-- ===== UI (tab SERVER, paling atas) =====
pages.header(serverPage, "🏷 TITLE", -9)

-- kartu preview: foto avatar + title
local card = Instance.new("Frame")
card.LayoutOrder = -8
card.Size = UDim2.new(1, 0, 0, 58)
card.BackgroundColor3 = BG_BUTTON
card.BorderSizePixel = 0
card.Parent = serverPage
corner(card, 8)
stroke(card, ACCENT_BLUE, 1)

local photo = Instance.new("ImageLabel")
photo.Position = UDim2.new(0, 6, 0, 6)
photo.Size = UDim2.new(0, 46, 0, 46)
photo.BackgroundColor3 = BG_DARK
photo.BorderSizePixel = 0
photo.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
photo.Parent = card
corner(photo, 23)

local prevHolder = Instance.new("Frame")
prevHolder.BackgroundTransparency = 1
prevHolder.Position = UDim2.new(0, 58, 0, 5)
prevHolder.Size = UDim2.new(1, -64, 0, 32)
prevHolder.Parent = card
TT.makeRow(prevHolder, 18)
newLabel(card, player.DisplayName .. " (@" .. player.Name .. ")", 9, Enum.Font.GothamBold, GREY,
    UDim2.new(0, 58, 0, 38), UDim2.new(1, -64, 0, 16), Enum.TextXAlignment.Center).TextTruncate = Enum.TextTruncate.AtEnd

local onBtn = makeButton(serverPage, "", -7)
local function updOn()
    onBtn.Text = TT.on and "🏷 TITLE • ON" or "🏷 TITLE • OFF"
    onBtn.BackgroundColor3 = TT.on and ON_COLOR or BG_BUTTON
end
updOn()
onBtn.MouseButton1Click:Connect(function()
    TT.on = not TT.on
    updOn()
    TT.apply()
    TT.save()
end)

local box = Instance.new("TextBox")
box.LayoutOrder = -6
box.Size = UDim2.new(1, 0, 0, 30)
box.BackgroundColor3 = BG_BUTTON
box.Text = TT.text
box.PlaceholderText = "✏️ Tulis title kamu..."
box.PlaceholderColor3 = GREY
box.TextSize = 12
box.Font = Enum.Font.GothamBold
box.TextColor3 = WHITE
box.ClearTextOnFocus = false
box.Parent = serverPage
corner(box, 8)
box.FocusLost:Connect(function()
    local txt = (box.Text or ""):match("^%s*(.-)%s*$")
    if txt == "" then box.Text = TT.text return end
    txt = txt:sub(1, 24)
    box.Text = txt
    TT.text = txt
    TT.refreshAll()
    if not TT.on then TT.on = true updOn() TT.apply() end -- ganti title = langsung aktif
    TT.save()
end)

local badgeBtn = makeButton(serverPage, "", -5)
local function updBadge()
    badgeBtn.Text = TT.badge and "✔ CENTANG VERIFIED • ON" or "✔ CENTANG VERIFIED • OFF"
    badgeBtn.BackgroundColor3 = TT.badge and ON_COLOR or BG_BUTTON
end
updBadge()
badgeBtn.MouseButton1Click:Connect(function()
    TT.badge = not TT.badge
    updBadge()
    TT.refreshAll()
    TT.save()
end)

-- SELECT COLOR (buka / tutup)
local colorBtn = makeButton(serverPage, "", -4)
local panel = Instance.new("Frame")
panel.LayoutOrder = -3
panel.BackgroundTransparency = 1
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Size = UDim2.new(1, 0, 0, 0)
panel.Visible = false
panel.Parent = serverPage
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.333, -4, 0, 52)
grid.CellPadding = UDim2.new(0, 6, 0, 6)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = panel

local function updColorBtn()
    local e = TT.find(TT.color)
    local nm = e and e.label or "?"
    colorBtn.Text = (TT.open and "🎨 TUTUP COLOR ▲  •  " or "🎨 SELECT COLOR ▼  •  ") .. nm
end
updColorBtn()
colorBtn.MouseButton1Click:Connect(function()
    TT.open = not TT.open
    panel.Visible = TT.open
    updColorBtn()
end)

local function markSwatches()
    for name, s in pairs(TT.swatches) do
        local sel = (name == TT.color)
        s.stroke.Color = sel and GREEN or Color3.fromRGB(60, 70, 95)
        s.stroke.Thickness = sel and 2 or 1
    end
end

for i, e in ipairs(TT.themes) do
    local b = Instance.new("TextButton")
    b.LayoutOrder = i
    b.BackgroundColor3 = BG_BUTTON
    b.Text = ""
    b.AutoButtonColor = false
    b.Parent = panel
    corner(b, 8)
    local st = stroke(b, Color3.fromRGB(60, 70, 95), 1)

    local fill = Instance.new("Frame") -- "foto" warna
    fill.Position = UDim2.new(0, 4, 0, 4)
    fill.Size = UDim2.new(1, -8, 1, -24)
    fill.BackgroundColor3 = WHITE
    fill.BorderSizePixel = 0
    fill.Parent = b
    corner(fill, 6)
    local g = Instance.new("UIGradient")
    g.Color = e.seq
    g.Parent = fill

    newLabel(b, e.label, 9, Enum.Font.GothamBold, WHITE,
        UDim2.new(0, 0, 1, -18), UDim2.new(1, 0, 0, 16))

    TT.swatches[e.name] = { btn = b, stroke = st }
    b.MouseButton1Click:Connect(function()
        TT.color = e.name
        TT.shineSel = e.shine
        TT.refreshAll()
        markSwatches()
        updColorBtn()
        TT.save()
    end)
end
markSwatches()

if TT.on then task.delay(0.6, TT.apply) end
end

-- ==================== KALKULATOR (tab SERVER) — gaya kalkulator ilmiah Google ====================
do
pages.header(serverPage, "🧮 KALKULATOR", 100)

local CB_FN   = Color3.fromRGB(193, 228, 255) -- tombol fungsi (biru muda)
local CT_FN   = Color3.fromRGB(0, 66, 115)
local CB_NUM  = Color3.fromRGB(221, 227, 236) -- tombol angka (abu muda)
local CT_NUM  = Color3.fromRGB(28, 32, 42)
local CB_AC   = Color3.fromRGB(211, 227, 253)
local CT_AC   = Color3.fromRGB(0, 56, 140)
local CB_EQ   = Color3.fromRGB(20, 108, 48)   -- tombol "=" (hijau)

-- layar
local disp = Instance.new("Frame")
disp.LayoutOrder = 101
disp.Size = UDim2.new(1, 0, 0, 66)
disp.BackgroundColor3 = Color3.fromRGB(246, 249, 253)
disp.BorderSizePixel = 0
disp.Parent = serverPage
corner(disp, 14)

local exprLbl = Instance.new("TextLabel")
exprLbl.BackgroundTransparency = 1
exprLbl.Position = UDim2.new(0, 10, 0, 6)
exprLbl.Size = UDim2.new(1, -20, 0, 30)
exprLbl.Text = ""
exprLbl.TextSize = 22
exprLbl.Font = Enum.Font.GothamMedium
exprLbl.TextColor3 = Color3.fromRGB(25, 28, 36)
exprLbl.TextXAlignment = Enum.TextXAlignment.Right
exprLbl.Parent = disp

local prevLbl = Instance.new("TextLabel")
prevLbl.BackgroundTransparency = 1
prevLbl.Position = UDim2.new(0, 10, 0, 38)
prevLbl.Size = UDim2.new(1, -20, 0, 22)
prevLbl.Text = ""
prevLbl.TextSize = 15
prevLbl.Font = Enum.Font.Gotham
prevLbl.TextColor3 = Color3.fromRGB(100, 110, 125)
prevLbl.TextXAlignment = Enum.TextXAlignment.Right
prevLbl.Parent = disp

-- tombol buka/tutup baris fungsi ilmiah
local colBtn = Instance.new("TextButton")
colBtn.LayoutOrder = 102
colBtn.Size = UDim2.new(1, 0, 0, 22)
colBtn.BackgroundColor3 = BG_BUTTON
colBtn.Text = "⌃ TUTUP FUNGSI ILMIAH"
colBtn.TextSize = 9
colBtn.Font = Enum.Font.GothamBold
colBtn.TextColor3 = GREY
colBtn.AutoButtonColor = false
colBtn.Parent = serverPage
corner(colBtn, 11)

local keys = Instance.new("Frame")
keys.LayoutOrder = 103
keys.BackgroundTransparency = 1
keys.AutomaticSize = Enum.AutomaticSize.Y
keys.Size = UDim2.new(1, 0, 0, 0)
keys.Parent = serverPage
local kg = Instance.new("UIGridLayout")
kg.CellSize = UDim2.new(0.25, -5, 0, 32)
kg.CellPadding = UDim2.new(0, 6, 0, 6)
kg.SortOrder = Enum.SortOrder.LayoutOrder
kg.Parent = keys

-- ===== mesin hitung (parser sendiri, tanpa loadstring) =====
local K = { toks = {}, done = false, inv = false, deg = true }
local FUNCS = { "sin(", "cos(", "tan(", "asin(", "acos(", "atan(", "ln(", "log(", "√(" }
local isFunc = {}
for _, f in ipairs(FUNCS) do isFunc[f] = true end

local function tr(x) -- hasil trig yang harusnya 0
    if math.abs(x) < 1e-12 then return 0 end
    return x
end
local function applyFn(f, x)
    local deg = K.deg
    if f == "sin(" then return tr(math.sin(deg and math.rad(x) or x))
    elseif f == "cos(" then return tr(math.cos(deg and math.rad(x) or x))
    elseif f == "tan(" then
        if deg and math.abs(x % 180) == 90 then error("tan") end
        return tr(math.tan(deg and math.rad(x) or x))
    elseif f == "asin(" then
        if x < -1 or x > 1 then error("asin") end
        local r = math.asin(x) return deg and math.deg(r) or r
    elseif f == "acos(" then
        if x < -1 or x > 1 then error("acos") end
        local r = math.acos(x) return deg and math.deg(r) or r
    elseif f == "atan(" then
        local r = math.atan(x) return deg and math.deg(r) or r
    elseif f == "ln(" then
        if x <= 0 then error("ln") end
        return math.log(x)
    elseif f == "log(" then
        if x <= 0 then error("log") end
        return math.log(x) / math.log(10)
    elseif f == "√(" then
        if x < 0 then error("sqrt") end
        return math.sqrt(x)
    end
    error("fn")
end
local function fact(x)
    if x < 0 or x ~= math.floor(x) or x > 170 then error("fact") end
    local r = 1
    for i = 2, x do r = r * i end
    return r
end

local function isNumTok(t) return t ~= nil and t:match("^[%d%.]") ~= nil end
local function startsValue(t)
    return t ~= nil and (isNumTok(t) or t == "π" or t == "e" or t == "(" or isFunc[t])
end

local function evalToks(toks)
    local pos, n = 1, #toks
    local expr, unary
    local function peek() return toks[pos] end
    local function primary()
        local t = toks[pos]
        if t == nil then error("end") end
        if isNumTok(t) then
            pos = pos + 1
            local v = tonumber(t)
            if not v then error("num") end
            return v
        elseif t == "π" then pos = pos + 1 return math.pi
        elseif t == "e" then pos = pos + 1 return math.exp(1)
        elseif t == "(" then
            pos = pos + 1
            local v = expr()
            if toks[pos] == ")" then pos = pos + 1 end
            return v
        elseif isFunc[t] then
            pos = pos + 1
            local v = expr()
            if toks[pos] == ")" then pos = pos + 1 end
            return applyFn(t, v)
        end
        error("syntax")
    end
    local function postfix()
        local v = primary()
        while true do
            local t = toks[pos]
            if t == "!" then pos = pos + 1 v = fact(v)
            elseif t == "%" then pos = pos + 1 v = v / 100
            else break end
        end
        return v
    end
    local function power()
        local b = postfix()
        if toks[pos] == "^" then
            pos = pos + 1
            local e = unary()
            local r = b ^ e
            if r ~= r then error("pow") end
            return r
        end
        return b
    end
    function unary()
        local t = toks[pos]
        if t == "−" then pos = pos + 1 return -unary()
        elseif t == "+" then pos = pos + 1 return unary() end
        return power()
    end
    local function term()
        local v = unary()
        while true do
            local t = toks[pos]
            if t == "×" then pos = pos + 1 v = v * unary()
            elseif t == "÷" then
                pos = pos + 1
                local d = unary()
                if d == 0 then error("div0") end
                v = v / d
            elseif startsValue(t) then v = v * unary() -- perkalian tersirat: 2π, 3(4+1)
            else break end
        end
        return v
    end
    function expr()
        local v = term()
        while true do
            local t = toks[pos]
            if t == "+" then pos = pos + 1 v = v + term()
            elseif t == "−" then pos = pos + 1 v = v - term()
            else break end
        end
        return v
    end
    local v = expr()
    if pos <= n then error("syntax") end
    return v
end

local function fmtNum(v)
    if v ~= v or v == math.huge or v == -math.huge then return nil end
    if math.abs(v) < 1e-12 then v = 0 end
    return string.format("%.10g", v)
end
local function pretty(s) return (s:gsub("%.", ",")) end

local function show()
    local s = table.concat(K.toks)
    local len = utf8.len(s) or #s
    if len > 17 then s = "…" .. s:sub(utf8.offset(s, len - 15)) end
    exprLbl.Text = pretty(s)
end
local function preview()
    if K.done or #K.toks == 0 then return end
    local ok, v = pcall(evalToks, K.toks)
    local f = ok and fmtNum(v)
    if f then prevLbl.Text = pretty((f:gsub("^%-", "−"))) else prevLbl.Text = "" end
end
local function refresh() show() preview() end

local function fresh(valueStart)
    if K.done then
        if valueStart then K.toks = {} end
        K.done = false
        prevLbl.Text = ""
    end
end
local function last() return K.toks[#K.toks] end
local function push(t) table.insert(K.toks, t) end

local function keyDigit(d)
    fresh(true)
    local l = last()
    if l and l:match("^[%d%.]+$") and #l < 15 then
        K.toks[#K.toks] = l .. d
    else
        push(d)
    end
    refresh()
end
local function keyDot()
    fresh(true)
    local l = last()
    if l and l:match("^[%d%.]+$") then
        if not l:find("%.") then K.toks[#K.toks] = l .. "." end
    else
        push("0.")
    end
    refresh()
end
local function keyOp(sym)
    fresh(false)
    local l = last()
    if not l then
        if sym == "−" then push(sym) end
    elseif l == "+" or l == "−" or l == "×" or l == "÷" or l == "^" then
        K.toks[#K.toks] = sym
    elseif isFunc[l] or l == "(" then
        if sym == "−" then push(sym) end
    else
        push(sym)
    end
    refresh()
end
local function keyTok(t) -- konstanta / fungsi / kurung buka
    fresh(true)
    push(t)
    refresh()
end
local function keyPostfix(t)
    fresh(false)
    local l = last()
    if l and (isNumTok(l) or l == ")" or l == "π" or l == "e" or l == "!" or l == "%") then push(t) end
    refresh()
end
local function keyParen()
    fresh(false)
    local open, close = 0, 0
    for _, t in ipairs(K.toks) do
        if t == "(" or isFunc[t] then open = open + 1 elseif t == ")" then close = close + 1 end
    end
    local l = last()
    local canClose = l and (isNumTok(l) or l == ")" or l == "π" or l == "e" or l == "!" or l == "%")
    if open > close and canClose then push(")") else
        if K.done == false and l == nil then push("(") else push("(") end
    end
    refresh()
end
local function keyBack()
    fresh(false)
    local l = last()
    if l then
        if #l > 1 and isNumTok(l) then K.toks[#K.toks] = l:sub(1, -2) else K.toks[#K.toks] = nil end
    end
    prevLbl.Text = ""
    refresh()
end
local function keyClear()
    K.toks, K.done = {}, false
    exprLbl.Text, prevLbl.Text = "", ""
end
local function keyEq()
    if #K.toks == 0 or K.done then return end
    local old = table.concat(K.toks)
    local ok, v = pcall(evalToks, K.toks)
    local f = ok and fmtNum(v)
    if not f then
        prevLbl.Text = "Format salah / tidak valid"
        return
    end
    K.toks = {}
    if f:sub(1, 1) == "-" then push("−") f = f:sub(2) end
    push(f)
    K.done = true
    show()
    prevLbl.Text = pretty(old) .. " ="
end

-- ===== tombol =====
local btn = {}
local function mk(id, label, order, bg, fg, fn)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.BackgroundColor3 = bg
    b.Text = label
    b.TextSize = 16
    b.Font = Enum.Font.GothamMedium
    b.TextColor3 = fg
    b.AutoButtonColor = false
    b.Parent = keys
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.5, 0) -- bentuk pil
    c.Parent = b
    b.MouseButton1Click:Connect(fn)
    btn[id] = b
    return b
end

-- baris ilmiah (1-12) bisa disembunyikan
mk("sqrt", "√", 1, CB_FN, CT_FN, function()
    if K.inv then keyOp("^") if last() == "^" then keyTok("2") end else keyTok("√(") end
end)
mk("pi", "π", 2, CB_FN, CT_FN, function() keyTok("π") end)
mk("pow", "^", 3, CB_FN, CT_FN, function() keyOp("^") end)
mk("fact", "!", 4, CB_FN, CT_FN, function() keyPostfix("!") end)

mk("deg", "Deg", 5, CB_FN, CT_FN, function()
    K.deg = not K.deg
    btn.deg.Text = K.deg and "Deg" or "Rad"
    preview()
end)
mk("sin", "sin", 6, CB_FN, CT_FN, function() keyTok(K.inv and "asin(" or "sin(") end)
mk("cos", "cos", 7, CB_FN, CT_FN, function() keyTok(K.inv and "acos(" or "cos(") end)
mk("tan", "tan", 8, CB_FN, CT_FN, function() keyTok(K.inv and "atan(" or "tan(") end)

mk("inv", "Inv", 9, CB_FN, CT_FN, function()
    K.inv = not K.inv
    btn.inv.BackgroundColor3 = K.inv and Color3.fromRGB(120, 180, 240) or CB_FN
    btn.sqrt.Text = K.inv and "x²" or "√"
    btn.sin.Text = K.inv and "sin⁻¹" or "sin"
    btn.cos.Text = K.inv and "cos⁻¹" or "cos"
    btn.tan.Text = K.inv and "tan⁻¹" or "tan"
    btn.ln.Text = K.inv and "eˣ" or "ln"
    btn.log.Text = K.inv and "10ˣ" or "log"
end)
mk("e", "e", 10, CB_FN, CT_FN, function() keyTok("e") end)
mk("ln", "ln", 11, CB_FN, CT_FN, function()
    if K.inv then keyTok("e") keyOp("^") keyTok("(") else keyTok("ln(") end
end)
mk("log", "log", 12, CB_FN, CT_FN, function()
    if K.inv then keyTok("10") keyOp("^") keyTok("(") else keyTok("log(") end
end)

-- baris utama (13-32)
mk("ac", "AC", 13, CB_AC, CT_AC, keyClear)
mk("par", "( )", 14, CB_FN, CT_FN, keyParen)
mk("pct", "%", 15, CB_FN, CT_FN, function() keyPostfix("%") end)
mk("div", "÷", 16, CB_FN, CT_FN, function() keyOp("÷") end)

mk("7", "7", 17, CB_NUM, CT_NUM, function() keyDigit("7") end)
mk("8", "8", 18, CB_NUM, CT_NUM, function() keyDigit("8") end)
mk("9", "9", 19, CB_NUM, CT_NUM, function() keyDigit("9") end)
mk("mul", "×", 20, CB_FN, CT_FN, function() keyOp("×") end)

mk("4", "4", 21, CB_NUM, CT_NUM, function() keyDigit("4") end)
mk("5", "5", 22, CB_NUM, CT_NUM, function() keyDigit("5") end)
mk("6", "6", 23, CB_NUM, CT_NUM, function() keyDigit("6") end)
mk("sub", "−", 24, CB_FN, CT_FN, function() keyOp("−") end)

mk("1", "1", 25, CB_NUM, CT_NUM, function() keyDigit("1") end)
mk("2", "2", 26, CB_NUM, CT_NUM, function() keyDigit("2") end)
mk("3", "3", 27, CB_NUM, CT_NUM, function() keyDigit("3") end)
mk("add", "+", 28, CB_FN, CT_FN, function() keyOp("+") end)

mk("0", "0", 29, CB_NUM, CT_NUM, function() keyDigit("0") end)
mk("dot", ",", 30, CB_NUM, CT_NUM, keyDot)
mk("back", "⌫", 31, CB_NUM, CT_NUM, keyBack)
mk("eq", "=", 32, CB_EQ, WHITE, keyEq)

local sciIds = { "sqrt", "pi", "pow", "fact", "deg", "sin", "cos", "tan", "inv", "e", "ln", "log" }
local sciOpen = true
colBtn.MouseButton1Click:Connect(function()
    sciOpen = not sciOpen
    for _, id in ipairs(sciIds) do btn[id].Visible = sciOpen end
    colBtn.Text = sciOpen and "⌃ TUTUP FUNGSI ILMIAH" or "⌄ BUKA FUNGSI ILMIAH"
end)
end

-- ==================== FULLBRIGHT (tab SERVER) ====================
do
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
pages.header(serverPage, "🔆 FULLBRIGHT", 110)

local FB = { on = false, lockTime = nil, orig = nil }
local PROPS = { "Brightness", "ClockTime", "FogEnd", "FogStart", "GlobalShadows", "Ambient", "OutdoorAmbient", "ExposureCompensation" }

local fbBtn = makeButton(serverPage, "🔆 FULLBRIGHT • OFF", 111)

local function saveOrig()
    if FB.orig then return end
    FB.orig = {}
    for _, p in ipairs(PROPS) do FB.orig[p] = Lighting[p] end
end

-- jam
local timeBox = Instance.new("Frame")
timeBox.LayoutOrder = 112
timeBox.Size = UDim2.new(1, 0, 0, 52)
timeBox.BackgroundColor3 = BG_BUTTON
timeBox.BorderSizePixel = 0
timeBox.Parent = serverPage
corner(timeBox, 8)

local timeLbl = newLabel(timeBox, "🕒 JAM: AUTO (bawaan game)", 10, Enum.Font.GothamBold, WHITE,
    UDim2.new(0, 8, 0, 3), UDim2.new(1, -16, 0, 18), Enum.TextXAlignment.Left)

local bar = Instance.new("Frame")
bar.Position = UDim2.new(0, 12, 0, 32)
bar.Size = UDim2.new(1, -24, 0, 8)
bar.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
bar.BorderSizePixel = 0
bar.Parent = timeBox
corner(bar, 4)
local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = ACCENT_BLUE
fill.BorderSizePixel = 0
fill.Parent = bar
corner(fill, 4)
local knob = Instance.new("Frame")
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.Position = UDim2.new(0, 0, 0.5, 0)
knob.Size = UDim2.new(0, 18, 0, 18)
knob.BackgroundColor3 = WHITE
knob.BorderSizePixel = 0
knob.Parent = bar
corner(knob, 9)

local function fmtTime(h)
    local hh = math.floor(h) % 24
    local mm = math.floor((h - math.floor(h)) * 60)
    return string.format("%02d:%02d", hh, mm)
end
local function setSlider(h)
    local a = math.clamp(h / 24, 0, 1)
    fill.Size = UDim2.new(a, 0, 1, 0)
    knob.Position = UDim2.new(a, 0, 0.5, 0)
end
local function setTime(h)
    saveOrig()
    FB.lockTime = math.clamp(h, 0, 24)
    Lighting.ClockTime = FB.lockTime
    setSlider(FB.lockTime)
    timeLbl.Text = "🕒 JAM: " .. fmtTime(FB.lockTime) .. " (dikunci)"
end

local dragging = false
local function fromX(x)
    local w = bar.AbsoluteSize.X
    if w <= 0 then return end
    setTime(math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1) * 24)
end
local function startDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        fromX(input.Position.X)
    end
end
bar.InputBegan:Connect(startDrag)
knob.InputBegan:Connect(startDrag)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        fromX(input.Position.X)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local autoTime = makeButton(serverPage, "🕒 LEPAS KUNCI JAM (AUTO)", 113)
autoTime.MouseButton1Click:Connect(function()
    FB.lockTime = nil
    if FB.orig then pcall(function() Lighting.ClockTime = FB.orig.ClockTime end) end
    timeLbl.Text = "🕒 JAM: AUTO (bawaan game)"
end)

local function applyBright()
    Lighting.Brightness = 2
    Lighting.FogEnd = 1e6
    Lighting.FogStart = 1e6
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.ExposureCompensation = 0
end

fbBtn.MouseButton1Click:Connect(function()
    FB.on = not FB.on
    fbBtn.Text = FB.on and "🔆 FULLBRIGHT • ON" or "🔆 FULLBRIGHT • OFF"
    fbBtn.BackgroundColor3 = FB.on and ON_COLOR or BG_BUTTON
    if FB.on then
        saveOrig()
        applyBright()
        if not FB.lockTime then setTime(14) end
    elseif FB.orig then
        for _, p in ipairs(PROPS) do
            if p ~= "ClockTime" or not FB.lockTime then pcall(function() Lighting[p] = FB.orig[p] end) end
        end
    end
end)

-- game sering menimpa lighting -> jaga terus selama aktif / jam dikunci
local fbConn = RunService.RenderStepped:Connect(function()
    if FB.on then applyBright() end
    if FB.lockTime and Lighting.ClockTime ~= FB.lockTime then Lighting.ClockTime = FB.lockTime end
end)
table.insert(cleanupFns, function()
    fbConn:Disconnect()
    if FB.orig then for _, p in ipairs(PROPS) do pcall(function() Lighting[p] = FB.orig[p] end) end end
end)
end

-- ==================== FARM CLICK (tab FARM) ====================
do
local VIM = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local GuiSvc = game:GetService("GuiService")

local FC = { on = false, cps = 10, point = nil, setting = false }
pages.header(farmPage, "🖱 FARM CLICK", 40)

local fcBtn = makeButton(farmPage, "🖱 FARM CLICK • OFF", 41)

local cpsFrame = Instance.new("Frame")
cpsFrame.LayoutOrder = 42
cpsFrame.Size = UDim2.new(1, 0, 0, 30)
cpsFrame.BackgroundColor3 = BG_BUTTON
cpsFrame.BorderSizePixel = 0
cpsFrame.Parent = farmPage
corner(cpsFrame, 8)
newLabel(cpsFrame, "⚡ KLIK / DETIK", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(0.6, 0, 1, 0), Enum.TextXAlignment.Left)
local cpsBox = Instance.new("TextBox")
cpsBox.Size = UDim2.new(0.4, -12, 1, -8)
cpsBox.Position = UDim2.new(0.6, 4, 0, 4)
cpsBox.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
cpsBox.Text = tostring(FC.cps)
cpsBox.TextSize = 12
cpsBox.Font = Enum.Font.GothamBold
cpsBox.TextColor3 = WHITE
cpsBox.ClearTextOnFocus = false
cpsBox.Parent = cpsFrame
corner(cpsBox, 6)
cpsBox.FocusLost:Connect(function()
    local v = tonumber(cpsBox.Text)
    FC.cps = v and math.clamp(v, 1, 50) or FC.cps
    cpsBox.Text = tostring(FC.cps)
end)

local ptBtn = makeButton(farmPage, "📍 ATUR TITIK KLIK (tengah layar)", 43)

local function inHub(p)
    local mp, ms = mainFrame.AbsolutePosition, mainFrame.AbsoluteSize
    return mainFrame.Visible and p.X >= mp.X and p.X <= mp.X + ms.X and p.Y >= mp.Y and p.Y <= mp.Y + ms.Y
end
local function clickPoint()
    if FC.point and not inHub(FC.point) then return FC.point end
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(800, 600)
    -- cari titik di luar jendela hub supaya klik tidak kena tombol hub
    for _, c in ipairs({ Vector2.new(0.5, 0.5), Vector2.new(0.8, 0.5), Vector2.new(0.5, 0.85), Vector2.new(0.9, 0.7), Vector2.new(0.5, 0.15) }) do
        local p = Vector2.new(vs.X * c.X, vs.Y * c.Y)
        if not inHub(p) then return p end
    end
    return Vector2.new(vs.X * 0.5, vs.Y * 0.5)
end

local function clickOnce()
    local p = clickPoint()
    local ok = pcall(function()
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    if not ok and mouse1click then pcall(mouse1click) end
end

ptBtn.MouseButton1Click:Connect(function()
    FC.setting = true
    ptBtn.Text = "👆 TAP DI LAYAR GAME (luar hub)..."
    ptBtn.BackgroundColor3 = Color3.fromRGB(110, 80, 20)
end)
local setConn = UIS.InputBegan:Connect(function(input, processed)
    if not FC.setting or processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local ins = GuiSvc:GetGuiInset()
        FC.point = Vector2.new(input.Position.X, input.Position.Y + ins.Y)
        FC.setting = false
        ptBtn.Text = string.format("📍 TITIK: %d, %d (tap lagi untuk ganti)", FC.point.X, FC.point.Y)
        ptBtn.BackgroundColor3 = BG_BUTTON
    end
end)

fcBtn.MouseButton1Click:Connect(function()
    FC.on = not FC.on
    fcBtn.Text = FC.on and "🖱 FARM CLICK • ON" or "🖱 FARM CLICK • OFF"
    fcBtn.BackgroundColor3 = FC.on and ON_COLOR or BG_BUTTON
    if FC.on then
        task.spawn(function()
            while FC.on do
                clickOnce()
                task.wait(1 / FC.cps)
            end
        end)
    end
end)
table.insert(cleanupFns, function() FC.on = false setConn:Disconnect() end)
end

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

pages.header(playerPage, "👤 PLAYER TOOLS", 0)

local resetBtn = makePlayerButton("💀 RESET CHARACTER", 3)
resetBtn.MouseButton1Click:Connect(function()
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
end)

-- Judul tiap bagian di tab PLAYER (TELEPORT / COPY / HIDE / FOLLOW / SPECTATE) biar tidak tercampur
local function sectionHeader(text, order)
    return pages.header(playerPage, text, order)
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
pages.CS = CS
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
    if CS.active and CS.orig and CS.orig.desc then
        o.desc = CS.orig.desc -- sedang mode copy (respawn): pertahankan avatar ASLI, jangan avatar hasil copy
    else
        pcall(function() o.desc = hum:GetAppliedDescription() end)
    end

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

-- ===== ENGINE COPY (diport dari script Copyava yang sudah jalan) =====
-- Bukan lagi Humanoid:ApplyDescription (sering gagal/tidak kelihatan kalau dipanggil dari client).
-- Cara kerja: bikin "dummy" dari HumanoidDescription target, lalu body part / baju / warna kulit /
-- aksesori / ukuran badan dummy dipasang ke karakter kamu sendiri.
local AV = {}
local R15_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}
local R6_PARTS = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local SCALE_NAMES = { "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale", "BodyProportionScale", "BodyTypeScale" }

-- isi part yang BUKAN bagian avatar (tag nama, efek dari game, dll) diselamatkan dulu, lalu dipasang lagi
local function stashExtras(part, folder)
    local list = {}
    if not part then return list end
    for _, c in ipairs(part:GetChildren()) do
        if not (c:IsA("Attachment") or c:IsA("JointInstance") or c:IsA("WeldConstraint")
            or c:IsA("SurfaceAppearance") or c:IsA("Decal") or c:IsA("FaceControls")
            or c:IsA("WrapTarget") or c:IsA("WrapLayer") or c:IsA("SpecialMesh")
            or c:IsA("Script") or c:IsA("LocalScript")) then
            table.insert(list, c)
            pcall(function() c.Parent = folder end)
        end
    end
    return list
end

local function unstashExtras(list, part)
    if not part then return end
    for _, c in ipairs(list) do
        pcall(function()
            c.Parent = part
            if c:IsA("BillboardGui") then c.Adornee = part end
        end)
    end
end

-- Port PERSIS dari Copyava asli (F.aAc / F.aAv / F.mD / F.sHD / F.fC): akses accessory manual (Weld), ganti body part
-- lewat ReplaceBodyPartR15 dengan dummy yang ditaruh di workspace, joint non-avatar diselamatkan & dibuat ulang,
-- RequiresNeck dikembalikan 0.5 detik kemudian, HumanoidDescription di Humanoid disamakan, kamera dijaga.
AV.R15M = {}
for _, n in ipairs(R15_PARTS) do
    pcall(function() AV.R15M[n] = Enum.BodyPartR15[n] end)
end

function AV.addAccessory(char, ac, preferNative)
    local h = ac:FindFirstChild("Handle")
    if not h then return end
    for _, v in ipairs(ac:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = false
            v.CanCollide = false
            v.Massless = true
        elseif v:IsA("Script") or v:IsA("LocalScript") then
            v:Destroy()
        end
    end
    -- cara resmi Roblox (Humanoid:AddAccessory): wajib buat baju 3D / layered clothing, bagus juga buat aksesori biasa
    local hum0 = char:FindFirstChildOfClass("Humanoid")
    if hum0 and (preferNative or h:FindFirstChildOfClass("WrapLayer")) then
        local cat = h:GetAttribute("UHCat")
        h:SetAttribute("CCI", true)
        h:SetAttribute("UHAcc", true)
        ac:SetAttribute("CCI", true)
        ac:SetAttribute("UHAcc", true)
        if cat then ac:SetAttribute("UHCat", cat) end
        local okN = pcall(function() hum0:AddAccessory(ac) end)
        if okN and ac.Parent == char then return end
        if ac.Parent == char then pcall(function() ac.Parent = nil end) end
    end
    for _, v in ipairs(h:GetChildren()) do
        if v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Motor6D") then v:Destroy() end
    end
    local at = h:FindFirstChildOfClass("Attachment")
    local tP, tA
    if at then
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") then
                local f = p:FindFirstChild(at.Name)
                if f and f:IsA("Attachment") then tP, tA = p, f break end
            end
        end
    end
    h.Name = ac.Name
    h:SetAttribute("CCI", true)
    h:SetAttribute("UHAcc", true) -- tanda: aksesori hasil copy / katalog
    if at then h:SetAttribute("AttName", at.Name) end
    if tP and tA then
        h.Parent = char
        h.CFrame = tP.CFrame * tA.CFrame * at.CFrame:Inverse()
        local w = Instance.new("Weld")
        w.Name = "AccWeld"
        w.Part0 = tP
        w.Part1 = h
        w.C0 = tA.CFrame
        w.C1 = at.CFrame
        w.Parent = h
    else
        h.Parent = char
        local hd = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if hd then
            h.CFrame = hd.CFrame
            local w = Instance.new("Weld")
            w.Name = "AccWeld"
            w.Part0 = hd
            w.Part1 = h
            w.Parent = h
        end
    end
    pcall(function() ac:Destroy() end)
end

-- catat Accessory/Shirt/Pants/BodyColors yang ada sekarang (dipakai penjaga untuk mendeteksi avatar yang ditimpa game)
function AV.snapshot(char)
    CS.known = {}
    CS.expect = {} -- item hasil copy yang HARUS tetap ada (kalau hilang -> dipasang ulang)
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Accessory") or t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then
            CS.known[t] = true
            if t:GetAttribute("CCI") and not t:GetAttribute("UHCat") then CS.expect[t] = true end
        elseif t:IsA("BasePart") and t:GetAttribute("CCI") and not t:GetAttribute("UHCat") then
            CS.expect[t] = true
        end
    end
end

function AV.fixCamera()
    local cm = workspace.CurrentCamera
    local ch = player.Character
    if not cm or not ch then return end
    local hm = ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head")
    if not hrp then return end
    local s = false
    if not cm.CameraSubject or not cm.CameraSubject:IsDescendantOf(workspace) then s = true end
    if cm.CameraSubject ~= hm and cm.CameraSubject ~= hrp then s = true end
    if (cm.CFrame.Position - hrp.Position).Magnitude > 100 then s = true end
    if cm.CFrame.X ~= cm.CFrame.X then s = true end
    if not s then return end
    pcall(function()
        cm.CameraType = Enum.CameraType.Custom
        cm.CameraSubject = hm or hrp
        if hm then hm.CameraOffset = Vector3.zero end
        local ld = hrp.CFrame.LookVector
        cm.CFrame = CFrame.lookAt(hrp.Position - (ld * 12) + Vector3.new(0, 5, 0), hrp.Position)
    end)
end

function AV.isMesh(o)
    return o:IsA("DataModelMesh") or o:IsA("SpecialMesh") or o:IsA("BlockMesh") or o:IsA("CylinderMesh")
end

-- inti penggantian avatar (= F.aAv di Copyava). ch = karakter kamu, dm = dummy dari HumanoidDescription target
function AV.core(ch, dm, hm)
    local fD = Instance.new("Folder")
    if hm and ch == player.Character then pcall(function() hm:UnequipTools() end) end
    local iR = ch:FindFirstChild("UpperTorso") ~= nil

    -- deteksi game dengan kepala / kaki khusus (jangan ditimpa)
    local gM = { Head = false, RLeg = false, LLeg = false, Auras = {} }
    local hd = ch:FindFirstChild("Head")
    if hd then
        if hd.Transparency >= 0.9 then gM.Head = true end
        local sm = hd:FindFirstChildOfClass("SpecialMesh")
        if sm and (sm.Scale.X <= 0.1 or tostring(sm.MeshId) == "" or tostring(sm.MeshId):find("134082") or tostring(sm.MeshId):find("201777376")) then
            gM.Head = true
        end
    else
        gM.Head = true
    end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("CharacterMesh") then
            if t.BodyPart == Enum.BodyPart.RightLeg and (tostring(t.MeshId):find("90296") or tostring(t.MeshId):find("139607")) then gM.RLeg = true end
            if t.BodyPart == Enum.BodyPart.LeftLeg and (tostring(t.MeshId):find("90296") or tostring(t.MeshId):find("139607")) then gM.LLeg = true end
        end
    end
    if iR then
        local function ck(n)
            local l = ch:FindFirstChild(n)
            if not l then return true end
            local m = l:FindFirstChildOfClass("SpecialMesh")
            if m and (tostring(m.MeshId):find("139607") or m.Scale.Y < 0.5) then return true end
            if l:IsA("MeshPart") and (tostring(l.MeshId):find("139607") or l.Size.Y < 0.6) then return true end
            return false
        end
        gM.RLeg = ck("RightLowerLeg")
        gM.LLeg = ck("LeftLowerLeg")
    else
        gM.RLeg = not ch:FindFirstChild("Right Leg")
        gM.LLeg = not ch:FindFirstChild("Left Leg")
    end

    -- efek (partikel, trail, dll) di badan diselamatkan dulu
    local sA = {}
    for _, d in ipairs(ch:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Light") then
            local acc = d:FindFirstAncestorOfClass("Accessory")
            local tl = d:FindFirstAncestorOfClass("Tool")
            if acc then
                gM.Auras[acc] = true
            elseif not tl then
                local p = d:FindFirstAncestorOfClass("BasePart")
                if p and p.Parent == ch then
                    local pn = d.Parent
                    if pn:IsA("Attachment") then
                        if not sA[pn] then
                            sA[pn] = { i = pn, tP = p.Name }
                            pcall(function() pn.Parent = fD end)
                        end
                    else
                        if not sA[d] then
                            sA[d] = { i = d, tP = p.Name }
                            pcall(function() d.Parent = fD end)
                        end
                    end
                end
            end
        end
    end

    -- isi body part yang bukan bagian avatar (cI) + joint yang menghubungkan avatar <-> non-avatar (cJ)
    local cI, cJ = {}, {}
    if iR then
        local cP = { HumanoidRootPart = true }
        for k, _ in pairs(AV.R15M) do cP[k] = true end
        for ln, _ in pairs(AV.R15M) do
            local l = ch:FindFirstChild(ln)
            if l then
                for _, c in ipairs(l:GetChildren()) do
                    if not c:IsA("Attachment") and not c:IsA("JointInstance") and not c:IsA("WeldConstraint")
                        and not c:IsA("SurfaceAppearance") and not c:IsA("Decal") and not c:IsA("FaceControls")
                        and not c:IsA("WrapTarget") and not c:IsA("SpecialMesh") and not c:IsA("Motor6D")
                        and not c:IsA("Script") and not c:IsA("LocalScript") then
                        table.insert(cI, { i = c, pL = ln })
                        pcall(function() c.Parent = fD end)
                    end
                end
            end
        end
        for _, o in ipairs(ch:GetDescendants()) do
            if o:IsA("JointInstance") or o:IsA("WeldConstraint") then
                local p0, p1 = o.Part0, o.Part1
                if p0 and p1 then
                    local p0C = cP[p0.Name] and p0.Parent == ch
                    local p1C = cP[p1.Name] and p1.Parent == ch
                    if (p0C and not p1C) or (not p0C and p1C) then
                        table.insert(cJ, {
                            cN = o.ClassName, n = o.Name, p0N = p0.Name, p1N = p1.Name, p0I = p0, p1I = p1,
                            pN = o.Parent and o.Parent.Name or "",
                            c0 = o:IsA("JointInstance") and o.C0 or nil,
                            c1 = o:IsA("JointInstance") and o.C1 or nil,
                        })
                    end
                end
            end
        end
    end

    -- dummy ditaruh di workspace (jauh di atas) supaya skala badan ikut diterapkan engine
    ch.Archivable = true
    dm.Archivable = true
    local d = dm:Clone()
    pcall(function() d:PivotTo(CFrame.new(0, 6000, 0)) end)
    d.Parent = workspace
    local dHm = d:FindFirstChildOfClass("Humanoid")

    -- tag / nametag di badan diselamatkan, nanti dipasang ke kepala baru
    local sT = {}
    for _, o in ipairs(ch:GetDescendants()) do
        if o:IsA("BillboardGui") or o:IsA("SurfaceGui") then
            o.Parent = ch
            table.insert(sT, o)
        end
    end

    -- bersihkan avatar lama
    for _, t in ipairs(ch:GetChildren()) do
        local isCat = t:GetAttribute("UHCat") -- item dari katalog: tetap dipakai
        if t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then
            if not isCat then t:Destroy() end
        elseif t:IsA("BasePart") and t:GetAttribute("CCI") and not isCat then
            t:Destroy()
        elseif t:IsA("CharacterMesh") then
            local s = false
            if gM.RLeg and t.BodyPart == Enum.BodyPart.RightLeg then s = true end
            if gM.LLeg and t.BodyPart == Enum.BodyPart.LeftLeg then s = true end
            if not s then t:Destroy() end
        elseif t:IsA("Accessory") and not isCat
            and not t:FindFirstChildOfClass("Script")
            and not t:FindFirstChildOfClass("LocalScript") then
            if not gM.Auras[t] then t:Destroy() end
        end
    end

    if iR then
        local oR = hm.RequiresNeck
        hm.RequiresNeck = false
        for _, dp in ipairs(d:GetChildren()) do
            if AV.R15M[dp.Name] then
                local s = false
                local dn = tostring(dp.Name)
                if gM.RLeg and (dn:find("RightFoot") or dn:find("RightLowerLeg") or dn:find("RightUpperLeg")) then s = true end
                if gM.LLeg and (dn:find("LeftFoot") or dn:find("LeftLowerLeg") or dn:find("LeftUpperLeg")) then s = true end
                if gM.Head and dn == "Head" then s = true end
                if not s then
                    pcall(function() hm:ReplaceBodyPartR15(AV.R15M[dp.Name], dp:Clone()) end)
                end
            end
        end
        task.delay(1.5, function()
            if not (hm and hm.Parent) then return end
            local okNeck = true
            if oR then
                local h2, ut = ch:FindFirstChild("Head"), ch:FindFirstChild("UpperTorso")
                okNeck = h2 ~= nil and ut ~= nil and h2.Parent == ch and ut:FindFirstChild("Neck") ~= nil
            end
            if okNeck then pcall(function() hm.RequiresNeck = oR end) end
        end)
        for _, iD in ipairs(cI) do
            local tL = ch:FindFirstChild(iD.pL)
            if tL and iD.i then pcall(function() iD.i.Parent = tL end) end
        end
        local cP = { HumanoidRootPart = true }
        for k, _ in pairs(AV.R15M) do cP[k] = true end
        for _, jD in ipairs(cJ) do
            pcall(function()
                local tP0 = (cP[jD.p0N] and ch:FindFirstChild(jD.p0N)) or jD.p0I
                local tP1 = (cP[jD.p1N] and ch:FindFirstChild(jD.p1N)) or jD.p1I
                if tP0 and tP1 and tP0.Parent and tP1.Parent then
                    local nJ = Instance.new(jD.cN)
                    nJ.Name = jD.n
                    nJ.Part0 = tP0
                    nJ.Part1 = tP1
                    if nJ:IsA("JointInstance") then
                        nJ.C0 = jD.c0
                        nJ.C1 = jD.c1
                    end
                    local nP = ch
                    if cP[jD.pN] then nP = ch:FindFirstChild(jD.pN) or ch end
                    nJ.Parent = nP
                end
            end)
        end
    else
        local tM = {}
        for _, t in ipairs(d:GetChildren()) do
            if t:IsA("CharacterMesh") then table.insert(tM, t:Clone()) end
        end
        for _, dp in ipairs(d:GetChildren()) do
            if dp.Name == "Torso" or dp.Name == "Left Arm" or dp.Name == "Right Arm" or dp.Name == "Left Leg" or dp.Name == "Right Leg" then
                local s = false
                if gM.RLeg and dp.Name == "Right Leg" then s = true end
                if gM.LLeg and dp.Name == "Left Leg" then s = true end
                if not s then
                    local m = ch:FindFirstChild(dp.Name)
                    if m and m:IsA("BasePart") then
                        pcall(function()
                            m.Color = dp.Color
                            if dp:IsA("MeshPart") and m:IsA("MeshPart") then m.MeshId = dp.MeshId end
                        end)
                        for _, o in ipairs(m:GetChildren()) do
                            if AV.isMesh(o) then o:Destroy() end
                        end
                        for _, o in ipairs(dp:GetChildren()) do
                            if AV.isMesh(o) then o:Clone().Parent = m end
                        end
                    end
                end
            end
        end
        local mH = ch:FindFirstChild("Head")
        local dH = d:FindFirstChild("Head")
        if mH and dH and not gM.Head then
            local nH = dH:Clone()
            nH.Name = "Head"
            nH.CFrame = mH.CFrame
            local torso = ch:FindFirstChild("Torso")
            if torso then
                local neck = torso:FindFirstChild("Neck")
                if neck then
                    local nNeck = neck:Clone()
                    nNeck.Part0 = torso
                    nNeck.Part1 = nH
                    nNeck.Parent = torso
                    neck:Destroy()
                end
            end
            nH.Parent = ch
            mH:Destroy()
        end
        for _, cm in ipairs(ch:GetChildren()) do
            if cm:IsA("CharacterMesh") then
                local s = false
                if gM.RLeg and cm.BodyPart == Enum.BodyPart.RightLeg then s = true end
                if gM.LLeg and cm.BodyPart == Enum.BodyPart.LeftLeg then s = true end
                if not s then cm:Destroy() end
            end
        end
        for _, tm in ipairs(tM) do
            local s = false
            if gM.RLeg and tm.BodyPart == Enum.BodyPart.RightLeg then s = true end
            if gM.LLeg and tm.BodyPart == Enum.BodyPart.LeftLeg then s = true end
            if not s then tm:Clone().Parent = ch end
        end
    end

    -- ukuran badan
    if hm and dHm then
        for _, sv in ipairs(SCALE_NAMES) do
            local dS = dHm:FindFirstChild(sv)
            if dS and dS:IsA("NumberValue") then
                local mS = hm:FindFirstChild(sv)
                if mS and mS:IsA("NumberValue") then mS.Value = dS.Value else dS:Clone().Parent = hm end
            end
        end
    end

    task.wait(0.25)
    local nH2 = ch:WaitForChild("Head", 2)
    if nH2 then
        for _, tg in ipairs(sT) do
            tg.Parent = nH2
            if tg:IsA("BillboardGui") then tg.Adornee = nH2 end
        end
    end

    if not iR then
        for _, t in ipairs(d:GetDescendants()) do
            pcall(function()
                if t:IsA("WrapTarget") then
                    local pStr = t.Parent and tostring(t.Parent.Name) or ""
                    local s = false
                    if gM.RLeg and (pStr == "Right Leg" or pStr:find("RightFoot") or pStr:find("RightLowerLeg") or pStr:find("RightUpperLeg")) then s = true end
                    if gM.LLeg and (pStr == "Left Leg" or pStr:find("LeftFoot") or pStr:find("LeftLowerLeg") or pStr:find("LeftUpperLeg")) then s = true end
                    if gM.Head and pStr == "Head" then s = true end
                    if not s then
                        local m = ch:FindFirstChild(pStr)
                        if m then
                            for _, oO in ipairs(m:GetChildren()) do
                                if oO:IsA("WrapTarget") then oO:Destroy() end
                            end
                            t:Clone().Parent = m
                        end
                    end
                end
            end)
        end
    end

    -- aksesori, baju, celana, warna kulit dari dummy
    for _, t in ipairs(d:GetChildren()) do
        pcall(function()
            if t:IsA("Accessory") then
                AV.addAccessory(ch, t:Clone())
            elseif t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then
                local clash = false
                for _, o in ipairs(ch:GetChildren()) do
                    if o.ClassName == t.ClassName and o:GetAttribute("UHCat") then clash = true break end
                end
                if not clash then
                    local cl = t:Clone()
                    cl:SetAttribute("CCI", true)
                    cl.Parent = ch
                end
            end
        end)
    end

    for _, data in pairs(sA) do
        local tL = ch:FindFirstChild(data.tP)
        if tL then
            pcall(function() data.i.Parent = tL end)
        else
            pcall(function() data.i.Parent = ch end)
        end
    end

    pcall(function() fD:Destroy() end)
    d:Destroy()
end

-- cegah karakter mati selama / sesaat setelah proses ganti avatar (penyebab avatar balik ke asli + layar merah)
function AV.protect(hm, secs)
    if not hm then return end
    local oldDead, oldBJ = true, true
    pcall(function() oldDead = hm:GetStateEnabled(Enum.HumanoidStateType.Dead) end)
    pcall(function() oldBJ = hm.BreakJointsOnDeath end)
    local keep = 0
    pcall(function() keep = hm.Health end)
    pcall(function() hm:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    pcall(function() hm.BreakJointsOnDeath = false end)
    local conn
    pcall(function()
        conn = hm.HealthChanged:Connect(function(hp)
            if hp < keep and hm.Parent then pcall(function() hm.Health = keep end) end
        end)
    end)
    task.delay(secs or 3, function()
        if conn then conn:Disconnect() end
        if hm and hm.Parent then
            pcall(function() hm:SetStateEnabled(Enum.HumanoidStateType.Dead, oldDead) end)
            pcall(function() hm.BreakJointsOnDeath = oldBJ end)
        end
    end)
end

function AV.apply(char, hum, desc)
    if hum and char == player.Character then AV.protect(hum, 5) end
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local rig = isR15 and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6

    local d = desc:Clone()
    if not isR15 then
        pcall(function()
            d.DepthScale = 1; d.HeadScale = 1; d.HeightScale = 1; d.ProportionScale = 1; d.WidthScale = 1
        end)
    end

    local okD, dummy = pcall(function() return Players:CreateHumanoidModelFromDescription(d, rig) end)
    if not okD or not dummy then
        local ok2 = pcall(function() hum:ApplyDescription(d) end)
        if not ok2 then return false, "dummy gagal: " .. tostring(dummy) end
        return true
    end
    dummy.Archivable = true

    -- wajah default kalau kepala dummy tidak punya wajah sama sekali
    local dh = dummy:FindFirstChild("Head")
    if dh then
        local dyn = dh:FindFirstChildOfClass("SurfaceAppearance") or dh:FindFirstChildOfClass("FaceControls")
        if not dyn and not dh:IsA("MeshPart") and not dh:FindFirstChildOfClass("Decal") then
            local f = Instance.new("Decal")
            f.Name = "face"
            f.Texture = "rbxasset://textures/face.png"
            f.Parent = dh
        end
    end

    -- kunci kamera selama proses (hanya kalau kamera memang sedang mengikuti karaktermu)
    local cam = workspace.CurrentCamera
    local sub0 = cam and cam.CameraSubject
    local lockCam = cam ~= nil and char == player.Character
        and (sub0 == nil or sub0 == hum or sub0 == char:FindFirstChild("HumanoidRootPart") or sub0 == char:FindFirstChild("Head"))
    local lockConn
    if lockCam then
        lockConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                if cam.CameraSubject ~= hum then cam.CameraSubject = hum end
                if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
            end)
        end)
    end

    local okA, errA = pcall(AV.core, char, dummy, hum)
    pcall(function() dummy:Destroy() end)
    if not okA then
        if lockConn then lockConn:Disconnect() end
        return false, tostring(errA)
    end

    -- samakan HumanoidDescription di Humanoid + emote (seperti Copyava)
    pcall(function()
        for _, v in ipairs(hum:GetChildren()) do
            if v:IsA("HumanoidDescription") then v:Destroy() end
        end
        local nD = d:Clone()
        nD.Name = "HumanoidDescription"
        nD.Parent = hum
    end)
    pcall(function()
        hum:SetEmotes(d:GetEmotes())
        hum:SetEquippedEmotes(d:GetEquippedEmotes())
    end)

    -- restart Animate biar animasi ikut karakter baru
    local a = char:FindFirstChild("Animate")
    if a then
        task.spawn(function()
            a.Enabled = false
            task.wait(0.05)
            if char.Parent and a.Parent then a.Enabled = true end
        end)
    end
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)

    task.delay(0.5, function()
        if lockConn then lockConn:Disconnect() end
        if lockCam then AV.fixCamera() end
    end)
    AV.snapshot(char)
    return true
end

local function applyDescription(char, hum, desc)
    local ok, err = AV.apply(char, hum, desc)
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

-- penjaga: kalau game menyelipkan item asing (aksesori/baju bawaan game) -> cukup DIHAPUS, avatar TIDAK dibangun ulang.
-- Bangun ulang total hanya kalau item hasil copy benar-benar hilang (maks 2x per 60 detik) -> tidak ada loop reset lagi.
function AV.watch()
    CS.watchToken = (CS.watchToken or 0) + 1
    local tk = CS.watchToken
    task.spawn(function()
        local hits, strikes = {}, 0
        while CS.active and CS.watchToken == tk do
            task.wait(0.6)
            local c = player.Character
            local hm = c and c:FindFirstChildOfClass("Humanoid")
            if c and c.Parent and hm and hm.Health > 0 and not CS.busy and CS.desc and CS.known then
                -- (1) buang item asing
                for _, t in ipairs(c:GetChildren()) do
                    if (t:IsA("Accessory") or t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors"))
                        and not CS.known[t] and not t:GetAttribute("CCI") and not t:GetAttribute("UHCat")
                        and not t:FindFirstChildOfClass("Script") and not t:FindFirstChildOfClass("LocalScript") then
                        pcall(function() t:Destroy() end)
                    end
                end
                -- (2) item hasil copy hilang -> pasang ulang, tapi dibatasi
                local missing = false
                if CS.expect then
                    for inst in pairs(CS.expect) do
                        if not inst.Parent or not inst:IsDescendantOf(c) then missing = true break end
                    end
                end
                if missing then
                    strikes = strikes + 1 -- harus hilang 2x cek berturut-turut (bukan kedip sesaat)
                else
                    strikes = 0
                end
                if strikes >= 2 then
                    strikes = 0
                    local now, keep = os.clock(), {}
                    for _, h in ipairs(hits) do
                        if now - h < 60 then table.insert(keep, h) end
                    end
                    hits = keep
                    if #hits < 2 then
                        table.insert(hits, now)
                        if CS.active and CS.watchToken == tk and not CS.busy and player.Character == c and c.Parent then
                            runBusy(function()
                                applyDescription(c, hm, CS.desc)
                                return true
                            end)
                            local Cc = pages.C
                            if Cc and Cc.reapply then pcall(Cc.reapply) end
                        end
                    end
                end
            end
        end
    end)
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
        local prevDesc, prevActive = CS.desc, CS.active
        CS.desc = desc
        CS.active = true
        local ok, err = applyDescription(char, hum, desc)
        if not ok then
            local dead = player.Character ~= char or not hum.Parent or hum.Health <= 0
            if not dead then CS.desc, CS.active = prevDesc, prevActive end
            return false, tostring(err)
        end

        pcall(function()
            hum.Died:Connect(function()
                warn("[UniversalHub] karakter mati setelah copy avatar -> avatar akan dipasang ulang saat respawn")
            end)
        end)
        if pages.C and pages.C.reapply then pcall(pages.C.reapply) end

        AV.watch()
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

        local wasDesc = CS.desc
        CS.active = false
        CS.watchToken = (CS.watchToken or 0) + 1
        local ok, err = AV.apply(char, hum, desc)
        if not ok then
            CS.active, CS.desc = true, wasDesc
            AV.watch()
            return false, tostring(err)
        end
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
        CS.watchToken = (CS.watchToken or 0) + 1
        if pages.C and pages.C.reapply then pcall(pages.C.reapply) end
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
        c:WaitForChild("HumanoidRootPart", 10)
        c:WaitForChild("Head", 10)
        local t0 = os.clock()
        while not player:HasAppearanceLoaded() and os.clock() - t0 < 5 do task.wait(0.1) end
        task.wait(0.3)
        local w0 = os.clock()
        while CS.busy and os.clock() - w0 < 8 do task.wait(0.1) end
        if not (CS.active and CS.desc) or player.Character ~= c then return end
        runBusy(function()
            captureOriginal(c, hum)
            applyDescription(c, hum, CS.desc)
            return true
        end)
        if pages.C and pages.C.reapply then pcall(pages.C.reapply) end
        AV.watch()
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
pages.header(teleportPage, "📍 TELEPORT SLOTS (10)", 0)

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

-- ==================== TAB ANIMASI & EMOTE (dipisah, bisa dicari, ada foto) ====================
-- EMOTE   = gerakan sekali pakai (dance, wave, dll) -> klik untuk memainkan.
-- ANIMASI = paket animasi karakter (idle / jalan / lari / lompat, dll) -> klik untuk dipakai, RESET untuk balik normal.
-- Daftar diambil online (sumber sama dengan script Emote). Foto diambil dari thumbnail Roblox.
do
local A = {
    mode = "emote",
    D = {
        emote = { items = {}, results = {}, shown = 0, q = "" },
        anim  = { items = {}, results = {}, shown = 0, q = "" },
    },
    perPage = 20, rows = {}, active = {}, btn = nil, track = nil, walkOk = false,
    cache = {}, mapCache = {}, searchToken = 0, playToken = 0, lastBundle = nil,
    origAnimate = nil, origChar = nil,
}
A.page = pages.ANIMASI
pages.header(A.page, "🎬 ANIMASI & EMOTE", 0)

-- pilih mode: EMOTE | ANIMASI
A.modeFrame = Instance.new("Frame")
A.modeFrame.LayoutOrder = 1
A.modeFrame.Size = UDim2.new(1, 0, 0, 30)
A.modeFrame.BackgroundTransparency = 1
A.modeFrame.BorderSizePixel = 0
A.modeFrame.Parent = A.page

local function modeButton(text, xScale, xOff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -3, 1, 0)
    b.Position = UDim2.new(xScale, xOff, 0, 0)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = A.modeFrame
    corner(b, 8)
    return b
end
A.emoteTab = modeButton("💃 EMOTE", 0, 0)
A.animTab = modeButton("🏃 ANIMASI", 0.5, 3)

-- kolom cari
A.searchFrame = Instance.new("Frame")
A.searchFrame.LayoutOrder = 2
A.searchFrame.Size = UDim2.new(1, 0, 0, 34)
A.searchFrame.BackgroundColor3 = BG_DARK
A.searchFrame.BorderSizePixel = 0
A.searchFrame.Parent = A.page
corner(A.searchFrame, 8)

A.search = Instance.new("TextBox")
A.search.Size = UDim2.new(1, -16, 0, 24)
A.search.Position = UDim2.new(0, 8, 0, 5)
A.search.BackgroundColor3 = BG_BUTTON
A.search.Text = ""
A.search.PlaceholderText = "🔍 Cari nama..."
A.search.PlaceholderColor3 = GREY
A.search.TextSize = 11
A.search.Font = Enum.Font.GothamBold
A.search.TextColor3 = WHITE
A.search.ClearTextOnFocus = false
A.search.Parent = A.searchFrame
corner(A.search, 6)

A.status = newLabel(A.page, "Memuat daftar... ⏳", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Left)
A.status.LayoutOrder = 3
A.status.TextTruncate = Enum.TextTruncate.AtEnd

A.stopBtn = makeButton(A.page, "⏹ STOP EMOTE", 4)
A.walkBtn = makeButton(A.page, "🚶 TETAP MAIN SAAT JALAN • OFF", 5)

A.list = Instance.new("Frame")
A.list.LayoutOrder = 6
A.list.Size = UDim2.new(1, 0, 0, 0)
A.list.AutomaticSize = Enum.AutomaticSize.Y
A.list.BackgroundTransparency = 1
A.list.BorderSizePixel = 0
A.list.Parent = A.page
A.listLayout = Instance.new("UIListLayout")
A.listLayout.Padding = UDim.new(0, 4)
A.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
A.listLayout.Parent = A.list

A.moreBtn = makeButton(A.page, "⬇ TAMPILKAN LEBIH", 7)
A.moreBtn.Visible = false

function A.setStatus(text, color)
    A.status.Text = text
    A.status.TextColor3 = color or GREY
end

function A.cur() return A.D[A.mode] end

-- ---------- EMOTE ----------
function A.stop()
    A.playToken = A.playToken + 1
    if A.track then
        pcall(function() A.track:Stop(0.2) end)
        pcall(function() A.track:Destroy() end)
        A.track = nil
    end
    if A.mode == "emote" then
        A.active.emote = nil
        if A.btn then
            pcall(function() A.btn.BackgroundColor3 = BG_BUTTON end)
            A.btn = nil
        end
    end
end

function A.resolveEmote(id)
    if A.cache[id] then return A.cache[id] end
    local result = "rbxassetid://" .. tostring(id)
    for _, url in ipairs({ "rbxassetid://" .. tostring(id), "http://www.roblox.com/asset/?id=" .. tostring(id) }) do
        local ok, objs = pcall(function() return game:GetObjects(url) end)
        if ok and type(objs) == "table" and #objs > 0 then
            local found
            for _, o in ipairs(objs) do
                if not found then
                    if o:IsA("Animation") then
                        found = o.AnimationId
                    else
                        local an = o:FindFirstChildWhichIsA("Animation", true)
                        if an then found = an.AnimationId end
                    end
                end
                pcall(function() o:Destroy() end)
            end
            if found and found ~= "" then
                result = found
                break
            end
        end
    end
    A.cache[id] = result
    return result
end

function A.playEmote(item, btn)
    local hum = getHumanoid()
    if not hum then
        A.setStatus("Karakter belum siap ⚠️", RED)
        return
    end
    A.stop()
    local myToken = A.playToken
    A.btn = btn
    A.active.emote = item.id
    btn.BackgroundColor3 = ON_COLOR
    A.setStatus("⏳ Memuat: " .. item.name, GREY)

    task.spawn(function()
        local animId = A.resolveEmote(item.id)
        if myToken ~= A.playToken then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not track then
            A.setStatus("Gagal memuat emote ❌", RED)
            if A.btn == btn then
                btn.BackgroundColor3 = BG_BUTTON
                A.btn = nil
                A.active.emote = nil
            end
            return
        end
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        track:Play()
        A.track = track
        A.setStatus("▶ " .. item.name, GREEN)
    end)
end

-- ---------- ANIMASI (paket animasi karakter lewat script "Animate") ----------
function A.collectIds(t, out)
    if type(t) == "table" then
        for _, v in pairs(t) do A.collectIds(v, out) end
    elseif tonumber(t) then
        table.insert(out, tonumber(t))
    end
end

function A.walk(parent, maps)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Animation") then
            local weights = {}
            for _, w in ipairs(child:GetChildren()) do
                if w:IsA("NumberValue") and w.Name == "Weight" then table.insert(weights, w.Value) end
            end
            table.insert(maps, { category = parent.Name, name = child.Name, animationId = child.AnimationId, weights = weights })
        elseif #child:GetChildren() > 0 then
            A.walk(child, maps)
        end
    end
end

function A.resolveMaps(item)
    if A.mapCache[item.id] then return A.mapCache[item.id] end
    local ids = {}
    A.collectIds(item.bundled, ids)
    local maps = {}
    for _, assetId in ipairs(ids) do
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. assetId) end)
        if ok and type(objs) == "table" then
            for _, o in ipairs(objs) do
                if o:IsA("Animation") then
                    table.insert(maps, { category = (o.Parent and o.Parent.Name) or "idle", name = o.Name, animationId = o.AnimationId, weights = {} })
                else
                    pcall(A.walk, o, maps)
                end
                pcall(function() o:Destroy() end)
            end
        end
    end
    if #maps > 0 then A.mapCache[item.id] = maps end
    return maps
end

function A.writeMaps(char, hum, maps)
    local animate = char:FindFirstChild("Animate")
    if not animate then return false end

    -- simpan Animate asli (sekali per karakter) buat tombol RESET
    if A.origChar ~= char then
        pcall(function() A.origAnimate = animate:Clone() end)
        A.origChar = char
    end

    for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() tr:Stop() end) end

    local byCat = {}
    for _, m in ipairs(maps) do
        local c = string.lower(m.category)
        byCat[c] = byCat[c] or {}
        byCat[c][string.lower(m.name)] = m
    end

    for _, folder in ipairs(animate:GetChildren()) do
        local items = byCat[string.lower(folder.Name)]
        if items then
            local pending = {}
            for k, m in pairs(items) do pending[k] = m end
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Animation") then
                    local key = string.lower(obj.Name)
                    local m = pending[key]
                    if m then
                        pending[key] = nil
                        obj.AnimationId = m.animationId
                        for _, c in ipairs(obj:GetChildren()) do
                            if c:IsA("NumberValue") and c.Name == "Weight" then c:Destroy() end
                        end
                        for _, wv in ipairs(m.weights or {}) do
                            local w = Instance.new("NumberValue")
                            w.Name = "Weight"
                            w.Value = wv
                            w.Parent = obj
                        end
                    else
                        obj:Destroy()
                    end
                end
            end
            for _, m in pairs(pending) do
                local obj = Instance.new("Animation")
                obj.Name = m.name
                obj.AnimationId = m.animationId
                for _, wv in ipairs(m.weights or {}) do
                    local w = Instance.new("NumberValue")
                    w.Name = "Weight"
                    w.Value = wv
                    w.Parent = obj
                end
                obj.Parent = folder
            end
        end
    end

    -- restart script Animate supaya animasi baru langsung dipakai
    animate.Enabled = false
    task.wait(0.05)
    if animate.Parent then animate.Enabled = true end
    return true
end

function A.applyBundle(item, btn)
    local char = player.Character
    local hum = getHumanoid()
    if not (char and hum and char:FindFirstChild("Animate")) then
        A.setStatus("Script Animate tidak ditemukan ❌", RED)
        return
    end
    if not item.bundled then
        A.setStatus("Data animasi ini kosong ❌", RED)
        return
    end
    A.playToken = A.playToken + 1
    local myToken = A.playToken
    if A.btn then pcall(function() A.btn.BackgroundColor3 = BG_BUTTON end) end
    A.btn = btn
    btn.BackgroundColor3 = ON_COLOR
    A.setStatus("⏳ Memuat animasi: " .. item.name, GREY)

    task.spawn(function()
        local maps = A.resolveMaps(item)
        if myToken ~= A.playToken then return end
        if #maps == 0 then
            A.setStatus("Animasi tidak bisa dimuat ❌", RED)
            if A.btn == btn then btn.BackgroundColor3 = BG_BUTTON A.btn = nil end
            return
        end
        local ok = A.writeMaps(char, hum, maps)
        if ok then
            A.active.anim = item.id
            A.lastBundle = item
            A.setStatus("✅ Animasi dipakai: " .. item.name, GREEN)
        else
            A.setStatus("Gagal memasang animasi ❌", RED)
        end
    end)
end

function A.resetAnim()
    local char = player.Character
    if char and A.origAnimate and A.origChar == char then
        local cur = char:FindFirstChild("Animate")
        if cur then cur:Destroy() end
        local n = A.origAnimate:Clone()
        n.Parent = char
        A.origChar = nil -- ambil snapshot baru kalau pasang animasi lagi
        A.setStatus("♻️ Animasi dikembalikan ke normal", GREY)
    else
        A.setStatus("Belum ada animasi yang dipasang", GREY)
    end
    A.active.anim = nil
    A.lastBundle = nil
    if A.mode == "anim" then A.render(false) end
end

-- ---------- DAFTAR + FOTO ----------
function A.thumb(item)
    if A.mode == "emote" then
        return "rbxthumb://type=Asset&id=" .. tostring(item.id) .. "&w=150&h=150"
    end
    return "rbxthumb://type=BundleThumbnail&id=" .. tostring(item.id) .. "&w=150&h=150"
end

function A.render(append)
    local d = A.cur()
    if not append then
        for _, r in ipairs(A.rows) do r:Destroy() end
        A.rows = {}
        d.shown = 0
        A.btn = nil
    end
    local mode = A.mode
    local last = math.min(d.shown + A.perPage, #d.results)
    for i = d.shown + 1, last do
        local item = d.results[i]
        local b = Instance.new("TextButton")
        b.LayoutOrder = i
        b.Size = UDim2.new(1, 0, 0, 44)
        b.BackgroundColor3 = (A.active[mode] == item.id) and ON_COLOR or BG_BUTTON
        b.Text = ""
        b.AutoButtonColor = false
        b.Parent = A.list
        corner(b, 8)

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromOffset(36, 36)
        img.Position = UDim2.new(0, 4, 0.5, -18)
        img.BackgroundColor3 = BG_BLACK
        img.BackgroundTransparency = 0.3
        img.BorderSizePixel = 0
        img.ScaleType = Enum.ScaleType.Crop
        img.Image = A.thumb(item)
        img.Parent = b
        corner(img, 6)

        local lbl = newLabel(b, item.name, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 46, 0, 0), UDim2.new(1, -52, 1, 0), Enum.TextXAlignment.Left)
        lbl.TextWrapped = true
        lbl.TextTruncate = Enum.TextTruncate.AtEnd

        if A.active[mode] == item.id then A.btn = b end
        b.MouseButton1Click:Connect(function()
            if mode == "emote" then A.playEmote(item, b) else A.applyBundle(item, b) end
        end)
        table.insert(A.rows, b)
    end
    d.shown = last
    A.moreBtn.Visible = d.shown < #d.results
    A.moreBtn.Text = "⬇ TAMPILKAN LEBIH (" .. d.shown .. "/" .. #d.results .. ")"
    if #d.items > 0 then
        A.setStatus(#d.items .. (mode == "emote" and " emote" or " animasi") .. " • hasil: " .. #d.results, GREY)
    end
end

function A.filter()
    local d = A.cur()
    local q = string.lower(d.q or "")
    q = q:gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then
        d.results = d.items
    else
        local words = {}
        for w in q:gmatch("%S+") do table.insert(words, w) end
        local res = {}
        for _, it in ipairs(d.items) do
            local okAll = true
            for _, w in ipairs(words) do
                if not string.find(it.lname, w, 1, true) then okAll = false break end
            end
            if okAll then table.insert(res, it) end
        end
        d.results = res
    end
    A.render(false)
end

function A.setMode(m)
    A.mode = m
    A.emoteTab.BackgroundColor3 = (m == "emote") and ACCENT_BLUE or BG_BUTTON
    A.animTab.BackgroundColor3 = (m == "anim") and ACCENT_BLUE or BG_BUTTON
    A.stopBtn.Text = (m == "emote") and "⏹ STOP EMOTE" or "♻️ RESET ANIMASI (KEMBALI NORMAL)"
    A.walkBtn.Visible = (m == "emote")
    A.search.Text = A.D[m].q
    A.filter()
end

A.emoteTab.MouseButton1Click:Connect(function() A.setMode("emote") end)
A.animTab.MouseButton1Click:Connect(function() A.setMode("anim") end)

A.search:GetPropertyChangedSignal("Text"):Connect(function()
    A.cur().q = A.search.Text
    A.searchToken = A.searchToken + 1
    local t = A.searchToken
    task.delay(0.25, function()
        if t == A.searchToken then A.filter() end
    end)
end)

A.moreBtn.MouseButton1Click:Connect(function() A.render(true) end)
A.stopBtn.MouseButton1Click:Connect(function()
    if A.mode == "emote" then
        A.stop()
        A.setStatus("Emote dihentikan ⏹", GREY)
    else
        A.resetAnim()
    end
end)
A.walkBtn.MouseButton1Click:Connect(function()
    A.walkOk = not A.walkOk
    A.walkBtn.Text = A.walkOk and "🚶 TETAP MAIN SAAT JALAN • ON" or "🚶 TETAP MAIN SAAT JALAN • OFF"
    A.walkBtn.BackgroundColor3 = A.walkOk and ON_COLOR or BG_BUTTON
end)

-- emote berhenti otomatis kalau karakter jalan (kecuali toggle ON)
A.moveConn = RunService.Heartbeat:Connect(function()
    if A.track and not A.walkOk then
        local hum = getHumanoid()
        if hum and hum.MoveDirection.Magnitude > 0 then
            local wasEmote = (A.mode == "emote")
            A.stop()
            if wasEmote then A.setStatus("Emote berhenti karena jalan 🚶", GREY) end
        end
    end
end)
table.insert(cleanupFns, function()
    A.moveConn:Disconnect()
    A.stop()
end)

-- respawn: game bikin script Animate baru -> pasang lagi animasi yang terakhir dipilih
player.CharacterAdded:Connect(function(c)
    A.stop()
    A.origChar = nil
    A.origAnimate = nil
    local item = A.lastBundle
    if not item then return end
    task.spawn(function()
        local hum = c:WaitForChild("Humanoid", 10)
        c:WaitForChild("Animate", 10)
        task.wait(1.5)
        if pages.CS and pages.CS.active then return end -- mode copy aktif: animasi dipasang oleh copy
        if hum and player.Character == c and A.lastBundle == item then
            local maps = A.resolveMaps(item)
            if #maps > 0 then pcall(A.writeMaps, c, hum, maps) end
        end
    end)
end)

-- ---------- MUAT DAFTAR ONLINE ----------
A.EMOTE_URL = "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json"
A.ANIM_URLS = {
    "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json",
    "https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniperoffsale.json",
}

function A.setItems(kind, list)
    local d = A.D[kind]
    local seen, items = {}, {}
    for _, it in ipairs(list) do
        local id = tonumber(it.id)
        if id and id > 0 and not seen[id] then
            seen[id] = true
            local name = tostring(it.name or ((kind == "emote" and "Emote_" or "Animation_") .. id))
            table.insert(items, { id = id, name = name, lname = string.lower(name), bundled = it.bundledItems })
        end
    end
    d.items = items
    if A.mode == kind then A.filter() end
end

function A.fetchList(url)
    local body = httpGet(url)
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return nil end
    local list = data.data or data
    if type(list) ~= "table" then return nil end
    return list
end

A.setItems("emote", {
    { id = 3360686498, name = "Stadium" }, { id = 3360692915, name = "Tilt" },
    { id = 3576968026, name = "Shrug" }, { id = 3360689775, name = "Salute" },
})

task.spawn(function()
    local list = A.fetchList(A.EMOTE_URL)
    if list and #list > 0 then
        A.setItems("emote", list)
    elseif A.mode == "emote" then
        A.setStatus("Gagal ambil daftar online, pakai daftar kecil ⚠️", Color3.fromRGB(255, 190, 70))
    end
end)

task.spawn(function()
    local all = {}
    for _, url in ipairs(A.ANIM_URLS) do
        local list = A.fetchList(url)
        if list then
            for _, it in ipairs(list) do table.insert(all, it) end
        end
    end
    if #all > 0 then
        A.setItems("anim", all)
    elseif A.mode == "anim" then
        A.setStatus("Gagal ambil daftar animasi ⚠️", Color3.fromRGB(255, 190, 70))
    end
end)

A.setMode("emote")
end

-- ==================== KATALOG AVATAR (tombol di tab ANIMASI, paling atas) ====================
-- Cari item lewat nama (API katalog Roblox) atau pakai langsung lewat ID / link.
-- Semua item bisa dipakai (visual, client-side): aksesori, rambut, baju, celana, wajah, badan, bundle.
do
local C = {
    cat = "all", sub = "all", q = "", items = {}, cursor = nil, token = 0, loading = false,
    fav = {}, worn = {}, showWorn = false, rotY = 0, rows = {}, vpModel = nil,
}
pages.C = C
C.PUR_BG = Color3.fromRGB(45, 22, 62)
C.PUR_PANEL = Color3.fromRGB(68, 34, 88)
C.PUR_CARD = Color3.fromRGB(52, 26, 72)
C.PUR_BTN = Color3.fromRGB(125, 100, 215)
C.ORG_BTN = Color3.fromRGB(205, 115, 75)
C.ORG_TXT = Color3.fromRGB(255, 190, 90)

-- tipe aset -> kelompok
C.ACC = { [8]=1,[41]=1,[42]=1,[43]=1,[44]=1,[45]=1,[46]=1,[47]=1,[57]=1,[58]=1,[64]=1,[65]=1,[66]=1,[67]=1,[68]=1,[69]=1,[70]=1,[71]=1,[72]=1 }
C.CATS = {
    { "SEMUA", "all" }, { "FAVORIT", "fav" }, { "AKSESORIS", "acc" }, { "RAMBUT", "hair" },
    { "BAJU", "shirt" }, { "CELANA", "pants" }, { "WAJAH", "face" }, { "BADAN", "body" }, { "BUNDLE", "bundle" },
}
C.SUBS = {
    { "SEMUA", "all" }, { "KEPALA", 8 }, { "BELAKANG", 46 }, { "PINGGANG", 47 },
    { "BAHU", 44 }, { "DEPAN", 45 }, { "LEHER", 43 }, { "WAJAH", 42 },
}
C.SETS = {
    hair  = { [41]=1, [57]=1, [58]=1 },
    shirt = { [11]=1, [2]=1, [64]=1, [65]=1, [67]=1, [68]=1 },
    pants = { [12]=1, [66]=1, [69]=1, [70]=1, [71]=1, [72]=1 },
    face  = { [18]=1, [79]=1 },
    body  = { [17]=1, [27]=1, [28]=1, [29]=1, [30]=1, [31]=1, [78]=1 },
}
C.BODYDESC = { [17]="Head", [27]="Torso", [28]="RightArm", [29]="LeftArm", [30]="LeftLeg", [31]="RightLeg" }

function C.char() return player.Character end
function C.hum() local c = player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- ---------- UI ----------
C.gui = Instance.new("Frame")
C.gui.Name = "CatalogWindow"
C.gui.AnchorPoint = Vector2.new(0.5, 0.5)
C.gui.Position = UDim2.new(0.5, 0, 0.5, 0)
C.gui.Size = UDim2.new(0.92, 0, 0.86, 0)
C.gui.BackgroundColor3 = C.PUR_BG
C.gui.BorderSizePixel = 0
C.gui.Visible = false
C.gui.ZIndex = 50
C.gui.Active = true
C.gui.Parent = screenGui
corner(C.gui, 14)
stroke(C.gui, Color3.fromRGB(150, 110, 220), 2)
do
    local sc = Instance.new("UISizeConstraint")
    sc.MaxSize = Vector2.new(620, 340)
    sc.MinSize = Vector2.new(300, 200)
    sc.Parent = C.gui
end

function C.pnl(parent, pos, size, color)
    local f = Instance.new("Frame")
    f.Position = pos
    f.Size = size
    f.BackgroundColor3 = color or C.PUR_PANEL
    f.BorderSizePixel = 0
    f.ZIndex = 51
    f.Parent = parent
    corner(f, 10)
    return f
end

function C.btn(parent, text, pos, size, color, ts)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = color
    b.Text = text
    b.TextSize = ts or 9
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = true
    b.ZIndex = 53
    b.Parent = parent
    corner(b, 10)
    return b
end

-- kiri: preview avatar
C.left = C.pnl(C.gui, UDim2.new(0, 6, 0, 6), UDim2.new(0.30, -9, 1, -12))
C.vp = Instance.new("ViewportFrame")
C.vp.Position = UDim2.new(0, 4, 0, 4)
C.vp.Size = UDim2.new(1, -8, 1, -108)
C.vp.BackgroundColor3 = C.PUR_PANEL
C.vp.BackgroundTransparency = 1
C.vp.BorderSizePixel = 0
C.vp.ZIndex = 52
C.vp.Active = true
C.vp.Parent = C.left
C.cam = Instance.new("Camera")
C.cam.FieldOfView = 40
C.cam.Parent = C.vp
C.vp.CurrentCamera = C.cam
newLabel(C.left, "Geser untuk memutar", 7, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 1, -104), UDim2.new(1, 0, 0, 10)).ZIndex = 53

C.btnTake = C.btn(C.left, "LEPAS BAWAAN", UDim2.new(0, 4, 1, -90), UDim2.new(1, -8, 0, 22), C.ORG_BTN, 9)
C.btnSet = C.btn(C.left, "ATUR", UDim2.new(0, 4, 1, -64), UDim2.new(0.30, -4, 0, 22), C.ORG_BTN, 8)
C.btnAll = C.btn(C.left, "LEPAS SEMUA", UDim2.new(0.30, 2, 1, -64), UDim2.new(0.40, -4, 0, 22), C.PUR_BTN, 8)
C.btnPrev = C.btn(C.left, "PREVIEW", UDim2.new(0.70, 0, 1, -64), UDim2.new(0.30, -4, 0, 22), C.PUR_BTN, 8)
C.slots = Instance.new("Frame")
C.slots.Position = UDim2.new(0, 4, 1, -38)
C.slots.Size = UDim2.new(1, -8, 0, 32)
C.slots.BackgroundTransparency = 1
C.slots.ZIndex = 52
C.slots.Parent = C.left
do
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 3)
    l.Parent = C.slots
end

-- kanan
C.right = Instance.new("Frame")
C.right.Position = UDim2.new(0.30, 3, 0, 6)
C.right.Size = UDim2.new(0.70, -9, 1, -12)
C.right.BackgroundTransparency = 1
C.right.ZIndex = 51
C.right.Parent = C.gui

C.search = Instance.new("TextBox")
C.search.Position = UDim2.new(0, 0, 0, 0)
C.search.Size = UDim2.new(1, -150, 0, 24)
C.search.BackgroundColor3 = C.PUR_PANEL
C.search.Text = ""
C.search.PlaceholderText = "Cari nama item..."
C.search.PlaceholderColor3 = GREY
C.search.TextSize = 10
C.search.Font = Enum.Font.GothamBold
C.search.TextColor3 = WHITE
C.search.ClearTextOnFocus = false
C.search.TextXAlignment = Enum.TextXAlignment.Left
C.search.ZIndex = 53
C.search.Parent = C.right
corner(C.search, 12)
do
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 8)
    p.Parent = C.search
end
C.btnOfficial = C.btn(C.right, "RESMI ROBLOX", UDim2.new(1, -146, 0, 0), UDim2.new(0, 68, 0, 24), C.PUR_BTN, 7)
C.btnGo = C.btn(C.right, "CARI", UDim2.new(1, -74, 0, 0), UDim2.new(0, 44, 0, 24), C.ORG_BTN, 8)
C.btnX = C.btn(C.right, "X", UDim2.new(1, -26, 0, 0), UDim2.new(0, 26, 0, 24), C.PUR_BTN, 10)

C.catBar = Instance.new("ScrollingFrame")
C.catBar.Position = UDim2.new(0, 0, 0, 28)
C.catBar.Size = UDim2.new(1, 0, 0, 22)
C.catBar.BackgroundTransparency = 1
C.catBar.BorderSizePixel = 0
C.catBar.ScrollBarThickness = 0
C.catBar.ScrollingDirection = Enum.ScrollingDirection.X
C.catBar.AutomaticCanvasSize = Enum.AutomaticSize.X
C.catBar.CanvasSize = UDim2.new()
C.catBar.ZIndex = 52
C.catBar.Parent = C.right
C.subBar = C.catBar:Clone()
C.subBar.Position = UDim2.new(0, 0, 0, 52)
C.subBar.Parent = C.right
for _, bar in ipairs({ C.catBar, C.subBar }) do
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 4)
    l.Parent = bar
end

C.grid = Instance.new("ScrollingFrame")
C.grid.Position = UDim2.new(0, 0, 0, 78)
C.grid.Size = UDim2.new(1, 0, 1, -78 - 56)
C.grid.BackgroundTransparency = 1
C.grid.BorderSizePixel = 0
C.grid.ScrollBarThickness = 3
C.grid.ScrollBarImageColor3 = C.PUR_BTN
C.grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
C.grid.CanvasSize = UDim2.new()
C.grid.ZIndex = 52
C.grid.Parent = C.right
do
    local g = Instance.new("UIGridLayout")
    g.CellSize = UDim2.new(0.19, 0, 0, 88)
    g.CellPadding = UDim2.new(0.0125, 0, 0, 5)
    g.SortOrder = Enum.SortOrder.LayoutOrder
    g.Parent = C.grid
end

C.status = newLabel(C.right, "Ketik nama item lalu tekan CARI", 8, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 1, -54), UDim2.new(1, 0, 0, 12), Enum.TextXAlignment.Left)
C.status.ZIndex = 53
C.status.TextTruncate = Enum.TextTruncate.AtEnd

C.idBox = Instance.new("TextBox")
C.idBox.Position = UDim2.new(0, 0, 1, -38)
C.idBox.Size = UDim2.new(1, -150, 0, 30)
C.idBox.BackgroundColor3 = C.PUR_PANEL
C.idBox.Text = ""
C.idBox.PlaceholderText = "Masukkan tautan / ID item..."
C.idBox.PlaceholderColor3 = GREY
C.idBox.TextSize = 9
C.idBox.Font = Enum.Font.GothamBold
C.idBox.TextColor3 = WHITE
C.idBox.ClearTextOnFocus = false
C.idBox.TextXAlignment = Enum.TextXAlignment.Left
C.idBox.ZIndex = 53
C.idBox.Parent = C.right
corner(C.idBox, 10)
do
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 8)
    p.Parent = C.idBox
end
C.btnUse = C.btn(C.right, "PAKAI", UDim2.new(1, -144, 1, -38), UDim2.new(0, 56, 0, 30), C.PUR_BTN, 10)
C.hint = newLabel(C.right, "Ketik ID lalu tekan PAKAI. Tekan ATUR untuk lihat & lepas item yang dipakai.", 7, Enum.Font.GothamBold, C.ORG_TXT, UDim2.new(1, -84, 1, -38), UDim2.new(0, 84, 0, 30))
C.hint.ZIndex = 53
C.hint.TextWrapped = true
C.hint.TextXAlignment = Enum.TextXAlignment.Left

function C.setStatus(t, col)
    C.status.Text = t
    C.status.TextColor3 = col or GREY
end

-- ---------- PREVIEW ----------
function C.preview()
    if C.vpModel then C.vpModel:Destroy() C.vpModel = nil end
    local ch = C.char()
    if not ch then return end
    local wasArch = ch.Archivable
    ch.Archivable = true
    local ok, cl = pcall(function() return ch:Clone() end)
    ch.Archivable = wasArch
    if not ok or not cl then return end
    for _, d in ipairs(cl:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then d:Destroy() end
    end
    local hrp = cl:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = true end
    cl.Parent = C.vp
    C.vpModel = cl
    C.applyRot()
end

function C.applyRot()
    local m = C.vpModel
    if not m or not m.Parent then return end
    local hrp = m:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        m:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(C.rotY), 0))
        local cf = m:GetPivot()
        C.cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, 1.2, 8.5), cf.Position + Vector3.new(0, 0.6, 0))
    end)
end

C.dragging = false
C.vp.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        C.dragging = true
        C.lastX = i.Position.X
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if C.dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        C.rotY = C.rotY + (i.Position.X - (C.lastX or i.Position.X)) * 0.8
        C.lastX = i.Position.X
        C.applyRot()
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        C.dragging = false
    end
end)

-- ---------- PASANG ITEM ----------
function C.removeById(id)
    local ch = C.char()
    if ch then
        for _, d in ipairs(ch:GetDescendants()) do
            if d:GetAttribute("UHCat") == id then
                local acc = d:IsA("Accessory") and d or d:FindFirstAncestorOfClass("Accessory")
                pcall(function() (acc or d):Destroy() end)
            end
        end
    end
    C.worn[id] = nil
end

function C.handleObj(o, id)
    local ch = C.char()
    if not ch or not o then return 0 end
    local n = 0
    if o:IsA("Accessory") then
        local h = o:FindFirstChild("Handle")
        if h then
            h:SetAttribute("UHCat", id)
            o:SetAttribute("UHCat", id)
            AV.addAccessory(ch, o)
            n = 1
        end
    elseif o:IsA("Shirt") or o:IsA("Pants") or o:IsA("ShirtGraphic") then
        for _, t in ipairs(ch:GetChildren()) do
            if t.ClassName == o.ClassName then t:Destroy() end
        end
        o:SetAttribute("UHCat", id)
        o.Parent = ch
        n = 1
    elseif o:IsA("BodyColors") then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("BodyColors") then t:Destroy() end
        end
        o:SetAttribute("UHCat", id)
        o.Parent = ch
        n = 1
    elseif o:IsA("Decal") or o:IsA("Texture") then
        local head = ch:FindFirstChild("Head")
        if head then
            for _, t in ipairs(head:GetChildren()) do
                if t:IsA("Decal") and t.Name == "face" then t:Destroy() end
            end
            o.Name = "face"
            o:SetAttribute("UHCat", id)
            o.Parent = head
            n = 1
        end
    else
        for _, c in ipairs(o:GetChildren()) do
            n = n + C.handleObj(c, id)
        end
    end
    return n
end

function C.viaDescription(prop, id)
    local ch, hum = C.char(), C.hum()
    if not ch or not hum then return false end
    local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
    if not ok or not desc then return false end
    pcall(function() desc[prop] = id end)
    local ok2 = AV.apply(ch, hum, desc)
    return ok2 and true or false
end

function C.bundleItems(id)
    local ok, info = pcall(function() return game:GetService("AssetService"):GetBundleDetailsAsync(id) end)
    if ok and type(info) == "table" and type(info.Items) == "table" then return info.Items end
    local data = C.fetch("https://catalog.roblox.com/v1/bundles/" .. id .. "/details")
    if data and type(data.items) == "table" then
        local out = {}
        for _, it in ipairs(data.items) do table.insert(out, { Id = it.id, Type = it.type, Name = it.name }) end
        return out
    end
    return nil
end

function C.wearBundle(id)
    local items = C.bundleItems(id)
    if not items then C.lastErr = "detail bundle tidak bisa diambil" return false end
    for _, it in ipairs(items) do
        if it.Type == "UserOutfit" then
            local ok2, desc = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(it.Id) end)
            if ok2 and desc then
                local ch, hum = C.char(), C.hum()
                if ch and hum then
                    local okA, resA = pcall(AV.apply, ch, hum, desc)
                    if okA and resA then return true end
                end
            end
        end
    end
    local any = false
    for _, it in ipairs(items) do
        if it.Type == "Asset" and C.wearAsset(it.Id, nil, true) then any = true end
    end
    if not any then C.lastErr = C.lastErr or "isi bundle tidak bisa dipasang" end
    return any
end

C.ACCPROP = { [8]="HatAccessory", [41]="HairAccessory", [42]="FaceAccessory", [43]="NeckAccessory",
    [44]="ShouldersAccessory", [45]="FrontAccessory", [46]="BackAccessory", [47]="WaistAccessory" }
C.LAYER = { [64]="TShirtAccessory", [65]="ShirtAccessory", [66]="PantsAccessory", [67]="JacketAccessory",
    [68]="SweaterAccessory", [69]="ShortsAccessory", [70]="LeftShoeAccessory", [71]="RightShoeAccessory", [72]="DressSkirtAccessory" }

-- cara cadangan: lewat HumanoidDescription (dipasang pakai engine copy avatar yang sudah jalan)
function C.viaDesc(id, atype)
    local ch, hum = C.char(), C.hum()
    if not ch or not hum then return false end
    local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
    if not ok or not desc then return false end
    local done = false
    if atype and C.ACCPROP[atype] then
        local p = C.ACCPROP[atype]
        local cur = tostring(desc[p] or "")
        desc[p] = (cur ~= "" and (cur .. ",") or "") .. tostring(id)
        done = true
    elseif atype and C.LAYER[atype] then
        done = pcall(function()
            local list = desc:GetAccessories(true)
            table.insert(list, { AssetId = id, AccessoryType = Enum.AccessoryType[C.LAYER[atype]:gsub("Accessory$", "")], IsLayered = true, Order = 10 })
            desc:SetAccessories(list, true)
        end)
    elseif atype == 11 then desc.Shirt = id done = true
    elseif atype == 12 then desc.Pants = id done = true
    elseif atype == 2 then desc.GraphicTShirt = id done = true
    elseif atype == 18 then desc.Face = id done = true
    end
    if not done then return false end
    local ok2, res = pcall(function() return AV.apply(ch, hum, desc) end)
    return ok2 and res and true or false
end

C.BODYPARTS = {
    Head = { "Head" },
    Torso = { "UpperTorso", "LowerTorso" },
    RightArm = { "RightUpperArm", "RightLowerArm", "RightHand" },
    LeftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
    LeftLeg = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
    RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}

-- Cara utama: bikin HumanoidDescription kosong yang isinya HANYA item ini -> dummy -> ambil item dari dummy
-- lalu tempel ke karaktermu (sama seperti engine Copyava). Tidak butuh GetObjects & tidak menimpa avatar.
function C.viaDummy(id, atype)
    local ch, hum = C.char(), C.hum()
    if not ch or not hum then C.lastErr = "karakter belum siap" return false end
    atype = tonumber(atype)
    if not atype then return false end
    local isR15 = ch:FindFirstChild("UpperTorso") ~= nil
    local desc = Instance.new("HumanoidDescription")
    local okSet = false
    if C.ACCPROP[atype] then
        desc[C.ACCPROP[atype]] = tostring(id)
        okSet = true
    elseif C.LAYER[atype] then
        okSet = pcall(function()
            desc:SetAccessories({ { AssetId = id, AccessoryType = Enum.AccessoryType[(C.LAYER[atype]:gsub("Accessory$", ""))], IsLayered = true, Order = 10 } }, true)
        end)
    elseif atype == 57 or atype == 58 then
        okSet = pcall(function()
            desc:SetAccessories({ { AssetId = id, AccessoryType = (atype == 57) and Enum.AccessoryType.Eyebrow or Enum.AccessoryType.Eyelash, IsLayered = true, Order = 10 } }, true)
        end)
    elseif atype == 11 then desc.Shirt = id okSet = true
    elseif atype == 12 then desc.Pants = id okSet = true
    elseif atype == 2 then desc.GraphicTShirt = id okSet = true
    elseif atype == 18 then desc.Face = id okSet = true
    elseif C.BODYDESC[atype] and isR15 then desc[C.BODYDESC[atype]] = id okSet = true
    end
    if not okSet then return false end

    local okD, dummy = pcall(function()
        return Players:CreateHumanoidModelFromDescription(desc, isR15 and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6)
    end)
    if not okD or not dummy then C.lastErr = "gagal bikin dummy item" return false end
    dummy.Archivable = true
    C.removeById(id)
    local n = 0

    if C.BODYDESC[atype] then
        -- body part: ganti part terkait saja (R15)
        local names = C.BODYPARTS[C.BODYDESC[atype]]
        if names then
            pcall(function() dummy:PivotTo(CFrame.new(0, 6000, 0)) end)
            dummy.Parent = workspace
            local oR = hum.RequiresNeck
            hum.RequiresNeck = false
            for _, nm in ipairs(names) do
                local dp = dummy:FindFirstChild(nm)
                local en = AV.R15M[nm]
                if dp and en and pcall(function() hum:ReplaceBodyPartR15(en, dp:Clone()) end) then n = n + 1 end
            end
            task.delay(0.5, function()
                if hum and hum.Parent then pcall(function() hum.RequiresNeck = oR end) end
            end)
        end
    else
        for _, t in ipairs(dummy:GetChildren()) do
            if t:IsA("Accessory") then
                local cl = t:Clone()
                local h = cl:FindFirstChild("Handle")
                if h then
                    h:SetAttribute("UHCat", id)
                    AV.addAccessory(ch, cl, true)
                    n = n + 1
                end
            elseif t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") then
                for _, o in ipairs(ch:GetChildren()) do
                    if o.ClassName == t.ClassName then o:Destroy() end
                end
                local cl = t:Clone()
                cl:SetAttribute("UHCat", id)
                cl:SetAttribute("CCI", true)
                cl.Parent = ch
                n = n + 1
            end
        end
        if atype == 18 then
            local dh, head = dummy:FindFirstChild("Head"), ch:FindFirstChild("Head")
            local f = dh and dh:FindFirstChildOfClass("Decal")
            if f and head then
                for _, o in ipairs(head:GetChildren()) do
                    if o:IsA("Decal") and o.Name == "face" then o:Destroy() end
                end
                local cl = f:Clone()
                cl.Name = "face"
                cl:SetAttribute("UHCat", id)
                cl.Parent = head
                n = n + 1
            end
        end
    end
    pcall(function() dummy:Destroy() end)
    if n == 0 then C.lastErr = "dummy item kosong (item tidak cocok dengan rig ini?)" return false end
    return true
end

function C.loadObjs(id)
    local urls = { "rbxassetid://" .. id, "https://assetdelivery.roblox.com/v1/asset/?id=" .. id }
    for _, u in ipairs(urls) do
        local ok, objs = pcall(function() return game:GetObjects(u) end)
        if ok and type(objs) == "table" and #objs > 0 then return objs end
    end
    local ok2, m = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok2 and m then return { m } end
    return nil
end

function C.wearAsset(id, atype, quiet)
    C.lastErr = nil
    if not atype then
        local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(id) end)
        if ok and info then atype = info.AssetTypeId end
    end
    atype = tonumber(atype)
    if atype and C.viaDummy(id, atype) then return true end
    if atype and C.BODYDESC[atype] then
        if C.viaDescription(C.BODYDESC[atype], id) then return true end
        C.lastErr = "body part gagal dipasang (CreateHumanoidModelFromDescription diblok?)"
        return false
    end
    local objs = C.loadObjs(id)
    if objs then
        C.removeById(id)
        local n = 0
        for _, o in ipairs(objs) do
            local okH, cnt = pcall(C.handleObj, o, id)
            if okH then n = n + (cnt or 0) else C.lastErr = tostring(cnt) end
        end
        if n > 0 then return true end
        C.lastErr = C.lastErr or "item termuat tapi bentuknya tidak dikenali"
    else
        C.lastErr = "GetObjects gagal (executor tidak support / item tidak bisa dimuat)"
    end
    if C.viaDesc(id, atype) then
        C.worn_desc = true
        return true
    end
    return false
end

function C.wear(item)
    local id = tonumber(item.id)
    if not id then return end
    if C.worn[id] and item.itemType ~= "Bundle" then
        C.removeById(id)
        C.setStatus("Dilepas: " .. tostring(item.name), GREY)
        C.refresh()
        return
    end
    C.setStatus("⏳ Memasang: " .. tostring(item.name), GREY)
    task.spawn(function()
        local ok
        if item.itemType == "Bundle" then
            ok = C.wearBundle(id)
        else
            ok = C.wearAsset(id, item.assetType)
            if not ok then ok = C.wearBundle(id) end
        end
        if ok then
            C.worn[id] = { id = id, name = item.name, itemType = item.itemType, assetType = item.assetType }
            C.setStatus("✅ Dipakai: " .. tostring(item.name), GREEN)
        else
            C.setStatus("Gagal memasang ❌ " .. tostring(C.lastErr or "tidak diketahui"), RED)
        end
        task.wait(0.3)
        C.refresh()
    end)
end

function C.thumb(item)
    if item.itemType == "Bundle" then
        return "rbxthumb://type=BundleThumbnail&id=" .. item.id .. "&w=150&h=150"
    end
    return "rbxthumb://type=Asset&id=" .. item.id .. "&w=150&h=150"
end

-- ---------- DAFTAR ITEM ----------
function C.priceText(it)
    if it.priceStatus == "Free" or it.price == 0 then return "GRATIS", GREEN end
    if it.priceStatus == "Off Sale" or (it.price == nil and it.lowestPrice == nil) then return "Off Sale", GREY end
    return "R$ " .. tostring(it.price or it.lowestPrice), C.ORG_TXT
end

function C.match(it)
    local c, t = C.cat, tonumber(it.assetType)
    if it.itemType == "Bundle" then return c == "all" or c == "bundle" or (c == "fav" and C.fav[it.id]) end
    if c == "all" then return true end
    if c == "fav" then return C.fav[it.id] == true end
    if c == "bundle" then return false end
    if c == "acc" then
        if not (t and C.ACC[t]) then return false end
        return C.sub == "all" or t == C.sub
    end
    local s = C.SETS[c]
    return s ~= nil and t ~= nil and s[t] == true
end

function C.makeCard(it, order)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.BackgroundColor3 = C.PUR_CARD
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 53
    b.Parent = C.grid
    corner(b, 8)
    local st = stroke(b, GREEN, 2)
    st.Enabled = C.worn[it.id] ~= nil

    local img = Instance.new("ImageLabel")
    img.Position = UDim2.new(0, 3, 0, 3)
    img.Size = UDim2.new(1, -6, 0, 46)
    img.BackgroundColor3 = C.PUR_BG
    img.BackgroundTransparency = 0.3
    img.BorderSizePixel = 0
    img.ScaleType = Enum.ScaleType.Fit
    img.Image = C.thumb(it)
    img.ZIndex = 54
    img.Parent = b
    corner(img, 6)

    local heart = Instance.new("TextButton")
    heart.Position = UDim2.new(0, 3, 0, 3)
    heart.Size = UDim2.new(0, 16, 0, 16)
    heart.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
    heart.BackgroundTransparency = 0.3
    heart.Text = "♥"
    heart.TextSize = 9
    heart.Font = Enum.Font.GothamBold
    heart.TextColor3 = C.fav[it.id] and Color3.fromRGB(255, 90, 120) or WHITE
    heart.ZIndex = 56
    heart.Parent = b
    corner(heart, 8)
    heart.MouseButton1Click:Connect(function()
        C.fav[it.id] = (not C.fav[it.id]) or nil
        heart.TextColor3 = C.fav[it.id] and Color3.fromRGB(255, 90, 120) or WHITE
        if C.cat == "fav" then C.refresh() end
    end)

    local nm = newLabel(b, tostring(it.name), 7, Enum.Font.GothamBold, WHITE, UDim2.new(0, 3, 0, 50), UDim2.new(1, -6, 0, 24), Enum.TextXAlignment.Left)
    nm.TextWrapped = true
    nm.TextYAlignment = Enum.TextYAlignment.Top
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    nm.ZIndex = 54
    local ptxt, pcol = C.priceText(it)
    local pl = newLabel(b, ptxt, 7, Enum.Font.GothamBold, pcol, UDim2.new(0, 3, 1, -14), UDim2.new(1, -6, 0, 12), Enum.TextXAlignment.Left)
    pl.ZIndex = 54

    b.MouseButton1Click:Connect(function() C.wear(it) end)
    table.insert(C.rows, b)
end

function C.refresh()
    for _, r in ipairs(C.rows) do r:Destroy() end
    C.rows = {}
    -- slot item yang sedang dipakai
    for _, c in ipairs(C.slots:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local list = {}
    for _, w in pairs(C.worn) do table.insert(list, w) end
    table.sort(list, function(a, b) return a.id < b.id end)
    for i, w in ipairs(list) do
        if i > 4 then break end
        local s = Instance.new("ImageButton")
        s.Size = UDim2.new(0, 30, 0, 30)
        s.BackgroundColor3 = C.PUR_CARD
        s.Image = C.thumb(w)
        s.ZIndex = 53
        s.Parent = C.slots
        corner(s, 6)
        s.MouseButton1Click:Connect(function()
            C.removeById(w.id)
            C.refresh()
        end)
    end
    local shown = 0
    if C.showWorn then
        for _, w in ipairs(list) do
            shown = shown + 1
            C.makeCard(w, shown)
        end
        C.setStatus("Dipakai: " .. #list .. " item (tap untuk lepas)", GREY)
    else
        for _, it in ipairs(C.items) do
            if C.match(it) then
                shown = shown + 1
                C.makeCard(it, shown)
            end
        end
        if shown > 0 then C.setStatus(shown .. " item", GREY) end
    end
    if not C.showWorn and C.cursor and not C.loading then
        local more = Instance.new("TextButton")
        more.LayoutOrder = 999999
        more.BackgroundColor3 = C.PUR_BTN
        more.Text = "⬇ MUAT LAGI"
        more.TextSize = 8
        more.Font = Enum.Font.GothamBold
        more.TextColor3 = WHITE
        more.ZIndex = 53
        more.Parent = C.grid
        corner(more, 8)
        more.MouseButton1Click:Connect(function() C.search_(false) end)
        table.insert(C.rows, more)
    end
    task.delay(0.1, C.preview)
end

-- ---------- CARI (API katalog Roblox) ----------
function C.fetch(url)
    local body = httpGet(url)
    if not body then body = httpGet((url:gsub("roblox%.com", "roproxy.com"))) end
    if not body then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if ok and type(data) == "table" then return data end
    return nil
end

function C.search_(fresh)
    if C.loading then return end
    C.showWorn = false
    C.seen = C.seen or {}
    if fresh then
        C.items = {}
        C.cursor = nil
        C.seen = {}
    end
    C.loading = true
    C.token = C.token + 1
    local tk = C.token
    C.setStatus("⏳ Mencari...", GREY)
    task.spawn(function()
        local added, tries, failed = 0, 0, false
        local cursor = C.cursor
        repeat
            tries = tries + 1
            local url = "https://catalog.roblox.com/v1/search/items/details?Limit=30&IncludeNotForSale=true&Keyword="
                .. HttpService:UrlEncode(C.q)
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local data = C.fetch(url)
            if tk ~= C.token then C.loading = false return end
            if not data or not data.data then failed = true break end
            for _, it in ipairs(data.data) do
                if it.id and not C.seen[it.id] then
                    C.seen[it.id] = true
                    table.insert(C.items, it)
                    if C.match(it) then added = added + 1 end
                end
            end
            cursor = data.nextPageCursor
        until added >= 12 or not cursor or tries >= 5
        C.cursor = cursor
        C.loading = false
        C.refresh()
        if failed and #C.items == 0 then
            C.setStatus("Gagal ambil katalog ⚠️ (cek koneksi / pakai ID di bawah)", Color3.fromRGB(255, 190, 70))
        elseif added == 0 then
            C.setStatus("Tidak ada hasil untuk filter ini • coba MUAT LAGI / kategori lain", GREY)
        end
    end)
end

-- ---------- PAKAI LEWAT ID / LINK ----------
function C.useId()
    local txt = C.idBox.Text or ""
    local id = tonumber(txt:match("/bundles/(%d+)") or txt:match("/catalog/(%d+)") or txt:match("(%d%d+)"))
    if not id then
        C.setStatus("Masukkan ID / tautan item yang valid ❌", RED)
        return
    end
    local isBundle = txt:find("/bundles/", 1, true) ~= nil
    local name = "ID " .. id
    local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(id) end)
    if ok and info and info.Name then name = info.Name end
    C.wear({ id = id, name = name, itemType = isBundle and "Bundle" or "Asset", assetType = (ok and info and info.AssetTypeId) or nil })
end

-- ---------- KATEGORI ----------
function C.buildBars()
    for _, bar in ipairs({ C.catBar, C.subBar }) do
        for _, c in ipairs(bar:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
    end
    local function chip(bar, text, active, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, #text * 5 + 18, 1, 0)
        b.BackgroundColor3 = active and Color3.fromRGB(230, 190, 150) or C.PUR_PANEL
        b.Text = text
        b.TextSize = 7
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = active and Color3.fromRGB(40, 20, 10) or WHITE
        b.AutoButtonColor = false
        b.ZIndex = 53
        b.Parent = bar
        corner(b, 11)
        stroke(b, Color3.fromRGB(200, 150, 220), 1)
        b.MouseButton1Click:Connect(onClick)
    end
    for _, c in ipairs(C.CATS) do
        chip(C.catBar, c[1], C.cat == c[2], function()
            C.cat = c[2]
            C.sub = "all"
            C.showWorn = false
            C.buildBars()
            C.refresh()
            -- kategori jarang muncul di hasil? ambil lagi sesuai kata kunci
            if C.cat ~= "fav" and C.cat ~= "all" then
                local n = 0
                for _, it in ipairs(C.items) do if C.match(it) then n = n + 1 end end
                if n < 8 and C.cursor then C.search_(false) end
            end
        end)
    end
    C.subBar.Visible = (C.cat == "acc")
    C.grid.Position = UDim2.new(0, 0, 0, C.subBar.Visible and 78 or 54)
    C.grid.Size = UDim2.new(1, 0, 1, (C.subBar.Visible and -78 or -54) - 56)
    for _, s in ipairs(C.SUBS) do
        chip(C.subBar, s[1], C.sub == s[2], function()
            C.sub = s[2]
            C.buildBars()
            C.refresh()
        end)
    end
end

-- ---------- TOMBOL ----------
C.btnGo.MouseButton1Click:Connect(function()
    C.q = C.search.Text or ""
    C.search_(true)
end)
C.search.FocusLost:Connect(function(enter)
    if enter then
        C.q = C.search.Text or ""
        C.search_(true)
    end
end)
C.btnOfficial.MouseButton1Click:Connect(function()
    C.search.Text = "Roblox"
    C.q = "Roblox"
    C.search_(true)
end)
C.btnUse.MouseButton1Click:Connect(C.useId)
C.idBox.FocusLost:Connect(function(enter) if enter then C.useId() end end)
C.btnX.MouseButton1Click:Connect(function() C.gui.Visible = false end)
C.btnPrev.MouseButton1Click:Connect(C.preview)
C.btnSet.MouseButton1Click:Connect(function()
    C.showWorn = not C.showWorn
    C.refresh()
end)
C.btnTake.MouseButton1Click:Connect(function()
    local ids = {}
    for id in pairs(C.worn) do table.insert(ids, id) end
    for _, id in ipairs(ids) do C.removeById(id) end
    C.setStatus("Item dari katalog dilepas", GREY)
    C.refresh()
end)
C.btnAll.MouseButton1Click:Connect(function()
    local ch = C.char()
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Accessory") or t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic")
                or (t:IsA("BasePart") and t:GetAttribute("UHAcc")) then
                pcall(function() t:Destroy() end)
            end
        end
    end
    C.worn = {}
    C.setStatus("Semua aksesori & baju dilepas", GREY)
    C.refresh()
end)

-- ---------- ITEM TETAP TERPAKAI (respawn / setelah copy avatar menimpa) ----------
function C.clearWorn()
    C.worn = {}
    C.refresh()
end

function C.reapply()
    if C.reapplying then return end
    local ch = C.char()
    if not ch then return end
    local list = {}
    for _, w in pairs(C.worn) do
        if w.itemType ~= "Bundle" and not C.BODYDESC[tonumber(w.assetType) or 0] then table.insert(list, w) end
    end
    if #list == 0 then return end
    C.reapplying = true
    for _, w in ipairs(list) do
        local present = false
        for _, d in ipairs(ch:GetDescendants()) do
            if d:GetAttribute("UHCat") == w.id then present = true break end
        end
        if not present then pcall(C.wearAsset, w.id, w.assetType, true) end
    end
    C.reapplying = false
end

player.CharacterAdded:Connect(function(c)
    task.spawn(function()
        if not c:WaitForChild("Humanoid", 10) then return end
        c:WaitForChild("Head", 10)
        local t0 = os.clock()
        while not player:HasAppearanceLoaded() and os.clock() - t0 < 5 do task.wait(0.1) end
        task.wait(0.8)
        local cs = pages.CS
        if (cs and cs.active) or player.Character ~= c then return end -- kalau mode copy, urusan copy yang pasang ulang
        C.reapply()
    end)
end)

-- tombol pembuka di tab ANIMASI (paling atas, di atas emote & animasi)
pages.ANIMASI:FindFirstChildWhichIsA("Frame").LayoutOrder = -2 -- header judul
C.openBtn = makeButton(pages.ANIMASI, "🛍 BUKA CATALOG", -1)
C.openBtn.MouseButton1Click:Connect(function()
    C.gui.Visible = not C.gui.Visible
    if C.gui.Visible then
        C.buildBars()
        C.refresh()
        if #C.items == 0 then C.q = "" C.search_(true) end
    end
end)
table.insert(cleanupFns, function() C.gui:Destroy() end)
C.buildBars()
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
    if pages.applyTitle then pages.applyTitle() end
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
    if o == bgImage or o.Name == "ThemeFX" or o:FindFirstAncestor("ThemeFX") or o.Name:sub(1, 6) == "Bubble" then return end
    if (o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox") or o:IsA("ScrollingFrame"))
        and o.BackgroundTransparency == 0 then
        o.BackgroundTransparency = 0.5
    end
end
for _, o in ipairs(mainFrame:GetDescendants()) do softenUI(o) end
mainFrame.DescendantAdded:Connect(softenUI)

-- ==================== TEMA UI + TOMBOL BUBBLE ====================
-- Semua kode tema ada di dalam SATU fungsi (pages.initTheme) supaya tidak menambah variabel local
-- di scope utama (batas Lua 200). Warna tema = variabel BG_BLACK, BG_DARK, dst yang di-assign ulang,
-- lalu semua elemen UI yang sudah ada diwarnai ulang (old -> new) lewat recolor().
pages.initTheme = function()
    local TweenService = game:GetService("TweenService")
    local rgb = Color3.fromRGB

    local ROLES = { "black", "dark", "btn", "border", "accent", "on", "grey", "info",
        "cbg", "cpanel", "ccard", "cbtn", "cbtn2", "cstroke" }

    local function mkPal(arr)
        local pal, seen = {}, {}
        for i, role in ipairs(ROLES) do
            local c = arr[i]
            local r, g, b = c[1], c[2], c[3]
            while seen[r * 65536 + g * 256 + b] do b = (b + 1) % 256 end
            seen[r * 65536 + g * 256 + b] = true
            pal[role] = rgb(r, g, b)
        end
        return pal
    end

    -- urutan: black, dark, btn, border, accent, on, grey, info, cbg, cpanel, ccard, cbtn, cbtn2, cstroke
    local THEMES = {
        { id = "default", name = "Bawaan (Foto)", icon = "🖼️",
            sw = { rgb(10, 10, 15), rgb(60, 120, 255), rgb(125, 100, 215) },
            rim = { rgb(255, 255, 255), 0.78 },
            pal = mkPal({ {10,10,15}, {18,22,35}, {25,32,50}, {60,120,255}, {70,130,255}, {40,80,40}, {150,160,180}, {12,15,25},
                {45,22,62}, {68,34,88}, {52,26,72}, {125,100,215}, {205,115,75}, {150,110,220} }) },
        { id = "mono", name = "Monokrom", icon = "⚪",
            sw = { rgb(14, 14, 16), rgb(120, 122, 134), rgb(232, 234, 240) },
            rim = { rgb(235, 238, 245), 0.55 },
            pal = mkPal({ {12,12,14}, {30,31,35}, {52,53,59}, {206,209,217}, {118,121,132}, {96,102,110}, {172,175,184}, {20,20,23},
                {26,27,31}, {44,45,51}, {36,37,42}, {138,141,152}, {190,193,201}, {176,180,190} }) },
        { id = "forest", name = "Hutan", icon = "🌲",
            sw = { rgb(4, 20, 11), rgb(44, 138, 74), rgb(150, 230, 150) },
            rim = { rgb(150, 240, 170), 0.6 },
            pal = mkPal({ {6,24,13}, {12,42,24}, {20,64,38}, {92,208,120}, {44,138,74}, {30,104,52}, {156,204,170}, {8,30,17},
                {10,36,20}, {22,70,40}, {16,52,30}, {58,160,90}, {196,160,70}, {110,200,130} }) },
        { id = "hacker", name = "Hacker", icon = "💻",
            sw = { rgb(0, 6, 2), rgb(0, 150, 62), rgb(0, 255, 90) },
            rim = { rgb(0, 255, 90), 0.2 },
            pal = mkPal({ {2,9,4}, {4,20,9}, {7,34,14}, {0,255,90}, {0,150,62}, {0,106,44}, {96,204,128}, {3,14,7},
                {3,16,7}, {9,40,18}, {5,27,12}, {0,176,72}, {0,220,200}, {0,210,80} }) },
        { id = "ocean", name = "Lautan", icon = "🌊",
            sw = { rgb(96, 184, 240), rgb(24, 102, 184), rgb(3, 26, 66) },
            rim = { rgb(190, 235, 255), 0.55 },
            pal = mkPal({ {5,26,56}, {9,46,90}, {15,72,128}, {120,206,255}, {30,122,204}, {20,128,150}, {176,214,238}, {6,32,68},
                {8,40,80}, {18,80,138}, {12,60,108}, {44,150,224}, {70,190,200}, {140,210,250} }) },
        { id = "sunset", name = "Sunset", icon = "🌇",
            sw = { rgb(70, 30, 120), rgb(238, 108, 82), rgb(255, 172, 84) },
            rim = { rgb(255, 200, 150), 0.55 },
            pal = mkPal({ {34,12,42}, {56,20,58}, {90,36,82}, {255,156,76}, {222,96,64}, {150,58,112}, {232,192,196}, {38,14,46},
                {48,18,56}, {100,42,90}, {74,30,70}, {214,100,90}, {244,150,60}, {255,170,100} }) },
        { id = "nebula", name = "Nebula", icon = "🌌",
            sw = { rgb(30, 10, 74), rgb(98, 72, 222), rgb(60, 140, 255) },
            rim = { rgb(200, 180, 255), 0.5 },
            pal = mkPal({ {12,7,32}, {22,13,56}, {36,22,86}, {156,126,255}, {98,72,222}, {40,100,190}, {192,182,232}, {15,9,38},
                {20,11,50}, {44,28,100}, {30,18,74}, {120,86,236}, {70,150,240}, {170,140,255} }) },
        { id = "blackhole", name = "Blackhole", icon = "🕳️",
            sw = { rgb(3, 3, 8), rgb(255, 130, 40), rgb(130, 70, 200) },
            rim = { rgb(255, 170, 90), 0.45 },
            pal = mkPal({ {3,3,8}, {10,8,20}, {22,16,40}, {255,152,62}, {168,78,40}, {92,52,122}, {196,176,168}, {6,5,12},
                {9,7,18}, {26,18,46}, {16,12,30}, {190,92,44}, {120,70,190}, {255,170,90} }) },
        { id = "aurora", name = "Aurora", icon = "🌠",
            sw = { rgb(6, 20, 40), rgb(60, 230, 180), rgb(170, 110, 255) },
            rim = { rgb(120, 255, 215), 0.5 },
            pal = mkPal({ {5,12,24}, {9,26,40}, {14,42,60}, {96,240,205}, {60,200,170}, {30,130,112}, {164,208,210}, {7,17,30},
                {10,24,42}, {20,52,74}, {14,38,58}, {40,172,152}, {150,112,240}, {112,232,212} }) },
        { id = "sakura", name = "Sakura", icon = "🌸",
            sw = { rgb(52, 16, 40), rgb(240, 120, 170), rgb(255, 205, 220) },
            rim = { rgb(255, 180, 212), 0.5 },
            pal = mkPal({ {38,14,28}, {62,24,46}, {96,40,72}, {255,162,202}, {240,120,170}, {160,70,112}, {236,198,214}, {44,16,32},
                {52,20,40}, {104,44,78}, {78,32,60}, {222,110,160}, {255,176,120}, {255,172,208} }) },
    }
    local byId = {}
    for _, th in ipairs(THEMES) do byId[th.id] = th end

    local cur = THEMES[1].pal -- palet yang sedang dipakai UI (awalnya bawaan)

    local function keyOf(c)
        return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
    end

    -- ---------- container dekorasi (di belakang semua isi menu) ----------
    local fxRoot = Instance.new("Frame")
    fxRoot.Name = "ThemeFX"
    fxRoot.Size = UDim2.new(1, 0, 1, 0)
    fxRoot.BackgroundColor3 = rgb(255, 255, 255)
    fxRoot.BorderSizePixel = 0
    fxRoot.ClipsDescendants = true
    fxRoot.ZIndex = 0
    fxRoot.Visible = false
    fxRoot.Parent = mainFrame
    corner(fxRoot, 14)
    local baseGrad = Instance.new("UIGradient")
    baseGrad.Parent = fxRoot
    local deco = Instance.new("Frame")
    deco.Name = "Deco"
    deco.Size = UDim2.new(1, 0, 1, 0)
    deco.BackgroundTransparency = 1
    deco.BorderSizePixel = 0
    deco.ZIndex = 0
    deco.Parent = fxRoot

    local anims = {}
    local animOn = true
    local t0 = os.clock()
    local hbConn = RunService.Heartbeat:Connect(function(dt)
        if not animOn or #anims == 0 or not mainFrame.Visible then return end
        local t = os.clock() - t0
        for i = 1, #anims do
            local f = anims[i]
            if f then pcall(f, t, dt) end
        end
    end)
    table.insert(cleanupFns, function() hbConn:Disconnect() end)

    -- ---------- helper bikin dekorasi ----------
    local function mk(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        o.Parent = parent or deco
        return o
    end

    local function ugrad(parent, rot, cols, trans)
        local g = Instance.new("UIGradient")
        g.Rotation = rot or 0
        if cols then
            local k = {}
            for _, s in ipairs(cols) do table.insert(k, ColorSequenceKeypoint.new(s[1], s[2])) end
            g.Color = ColorSequence.new(k)
        end
        if trans then
            local k = {}
            for _, s in ipairs(trans) do table.insert(k, NumberSequenceKeypoint.new(s[1], s[2])) end
            g.Transparency = NumberSequence.new(k)
        end
        g.Parent = parent
        return g
    end

    local function setBase(rot, stops)
        local k = {}
        for _, s in ipairs(stops) do table.insert(k, ColorSequenceKeypoint.new(s[1], s[2])) end
        baseGrad.Color = ColorSequence.new(k)
        baseGrad.Rotation = rot
    end

    local function circle(x, y, size, color, transp, parent)
        local f = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, y, 0),
            Size = UDim2.new(0, size, 0, size), BackgroundColor3 = color,
            BackgroundTransparency = transp or 0, BorderSizePixel = 0,
        }, parent)
        mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
        return f
    end

    -- gumpalan lembut (lingkaran bertumpuk, makin ke tengah makin pekat)
    local function blob(x, y, size, color, layers)
        local g = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(x, 0, y, 0),
            Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1, BorderSizePixel = 0,
        })
        for i = 1, layers do
            local s = 1 - (i - 1) / layers * 0.8
            local c = mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(s, 0, s, 0), BackgroundColor3 = color,
                BackgroundTransparency = 0.97 - 0.17 * (i - 1) / math.max(1, layers - 1), BorderSizePixel = 0,
            }, g)
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
        end
        return g
    end

    local function stars(n, seed, maxS, yMax)
        local rnd = Random.new(seed)
        for _ = 1, n do
            local s = rnd:NextInteger(1, maxS or 2)
            local d = circle(rnd:NextNumber(), rnd:NextNumber() * (yMax or 1), s, rgb(255, 255, 255), rnd:NextNumber(0.2, 0.6))
            local ph, sp = rnd:NextNumber(0, 6.28), rnd:NextNumber(0.8, 2.5)
            local base = d.BackgroundTransparency
            table.insert(anims, function(t)
                d.BackgroundTransparency = math.clamp(base + math.sin(t * sp + ph) * 0.35, 0, 0.95)
            end)
        end
    end

    local function beams(n, color, x0, rot)
        for i = 1, n do
            local r = mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(x0 + i * 0.18, 0, -0.1, 0),
                Size = UDim2.new(0, 34, 0, 440), Rotation = rot, BackgroundColor3 = color,
                BackgroundTransparency = 0.9, BorderSizePixel = 0,
            })
            ugrad(r, 90, nil, { { 0, 0.2 }, { 1, 1 } })
            local ph = i * 1.7
            table.insert(anims, function(t) r.BackgroundTransparency = 0.88 + math.sin(t * 0.6 + ph) * 0.04 end)
        end
    end

    local build = {}

    -- 1) MONOKROM: hitam-putih elegan + kilau metalik
    build.mono = function()
        setBase(135, { { 0, rgb(8, 8, 10) }, { 0.5, rgb(54, 55, 61) }, { 1, rgb(12, 12, 14) } })
        for i = 1, 16 do
            mk("Frame", { Position = UDim2.new(0, 0, i / 17, 0), Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.95, BorderSizePixel = 0 })
        end
        blob(0.92, 0.08, 170, rgb(210, 212, 222), 6)
        blob(0.05, 0.95, 150, rgb(150, 152, 165), 6)
        local sheen = mk("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.3, 0, 0.5, 0),
            Size = UDim2.new(0, 70, 0, 520), Rotation = 24, BackgroundColor3 = rgb(255, 255, 255),
            BackgroundTransparency = 0.8, BorderSizePixel = 0,
        })
        ugrad(sheen, 0, nil, { { 0, 1 }, { 0.5, 0 }, { 1, 1 } })
        table.insert(anims, function(t)
            local p = (t % 8) / 8
            sheen.Position = UDim2.new(-0.3 + p * 1.6, 0, 0.5, 0)
        end)
    end

    -- 2) HUTAN: hijau + pohon, daun jatuh, kunang-kunang, sinar matahari
    build.forest = function()
        setBase(90, { { 0, rgb(30, 96, 54) }, { 0.5, rgb(11, 46, 27) }, { 1, rgb(3, 18, 10) } })
        local rnd = Random.new(7)
        beams(3, rgb(220, 255, 170), 0.15, -18)
        for _, layer in ipairs({ 2, 1 }) do
            for i = 0, 6 do
                mk("TextLabel", {
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new((i + rnd:NextNumber(0.1, 0.9)) / 7, 0, layer == 1 and 1.03 or 0.97, 0),
                    Size = UDim2.new(0, 60, 0, 60), BackgroundTransparency = 1,
                    Text = rnd:NextInteger(1, 2) == 1 and "🌲" or "🌳",
                    TextSize = layer == 1 and 56 or 38, TextTransparency = layer == 1 and 0.15 or 0.5,
                })
            end
        end
        mk("TextLabel", { Position = UDim2.new(0, 4, 0, 52), Size = UDim2.new(0, 60, 0, 40), BackgroundTransparency = 1,
            Text = "🌿", TextSize = 30, TextTransparency = 0.4, Rotation = -20 })
        mk("TextLabel", { Position = UDim2.new(1, -64, 0, 52), Size = UDim2.new(0, 60, 0, 40), BackgroundTransparency = 1,
            Text = "🌿", TextSize = 30, TextTransparency = 0.4, Rotation = 20 })
        mk("TextLabel", { Position = UDim2.new(0.08, 0, 0.9, 0), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1,
            Text = "🍄", TextSize = 20, TextTransparency = 0.25 })
        mk("TextLabel", { Position = UDim2.new(0.82, 0, 0.92, 0), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1,
            Text = "🌸", TextSize = 18, TextTransparency = 0.25 })
        local glyphs = { "🍃", "🌿", "🍃", "🍀", "🍃" }
        for i = 1, 6 do
            local l = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency = 1, Text = glyphs[(i % 5) + 1], TextSize = 16, TextTransparency = 0.25 })
            local x0, sp, ph = rnd:NextNumber(), rnd:NextNumber(0.05, 0.1), rnd:NextNumber(0, 6)
            table.insert(anims, function(t)
                local p = (t * sp + ph) % 1.2 - 0.1
                l.Position = UDim2.new((x0 + math.sin(t * 0.9 + ph) * 0.06) % 1, 0, p, 0)
                l.Rotation = (t * 40 + ph * 50) % 360
            end)
        end
        for _ = 1, 9 do
            local x, y = rnd:NextNumber(0.05, 0.95), rnd:NextNumber(0.45, 0.95)
            local g = circle(x, y, 11, rgb(210, 255, 120), 0.9)
            local d = circle(x, y, 3, rgb(240, 255, 170), 0.1)
            local ph = rnd:NextNumber(0, 6)
            table.insert(anims, function(t)
                local a = (math.sin(t * 1.6 + ph) + 1) / 2
                d.BackgroundTransparency = 0.8 - a * 0.7
                g.BackgroundTransparency = 0.95 - a * 0.2
                local pos = UDim2.new(x + math.sin(t * 0.4 + ph) * 0.03, 0, y + math.cos(t * 0.3 + ph) * 0.02, 0)
                g.Position = pos
                d.Position = pos
            end)
        end
    end

    -- 3) HACKER: hitam-hijau neon, hujan kode, grid cyber, scanline
    build.hacker = function()
        setBase(90, { { 0, rgb(0, 18, 7) }, { 1, rgb(0, 3, 1) } })
        for i = 1, 8 do
            mk("Frame", { Position = UDim2.new(i / 9, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0),
                BackgroundColor3 = rgb(0, 255, 90), BackgroundTransparency = 0.93, BorderSizePixel = 0 })
        end
        for i = 1, 12 do
            mk("Frame", { Position = UDim2.new(0, 0, i / 13, 0), Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = rgb(0, 255, 90), BackgroundTransparency = 0.94, BorderSizePixel = 0 })
        end
        local chars = "01ABCDEFabcdef<>/{}[]$#%&*+=?"
        local rnd = Random.new(11)
        local function rstr(n)
            local s = {}
            for i = 1, n do
                local k = rnd:NextInteger(1, #chars)
                s[i] = chars:sub(k, k)
            end
            return table.concat(s, "\n")
        end
        for i = 1, 14 do
            local lb = mk("TextLabel", {
                Position = UDim2.new((i - 0.5) / 14, -4, 0, -230), Size = UDim2.new(0, 10, 0, 210),
                BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
                TextColor3 = rgb(0, 255, 100), TextTransparency = 0.3, Text = rstr(14),
                TextYAlignment = Enum.TextYAlignment.Top,
            })
            ugrad(lb, 90, nil, { { 0, 1 }, { 0.8, 0.2 }, { 1, 0 } })
            local sp, off = rnd:NextNumber(60, 140), rnd:NextNumber(0, 600)
            local nextChange = 0
            table.insert(anims, function(t)
                lb.Position = UDim2.new((i - 0.5) / 14, -4, 0, ((t * sp + off) % 620) - 230)
                if t > nextChange then
                    nextChange = t + rnd:NextNumber(0.15, 0.4)
                    lb.Text = rstr(14)
                end
            end)
        end
        local scan = mk("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = rgb(0, 255, 90),
            BackgroundTransparency = 0.88, BorderSizePixel = 0 })
        ugrad(scan, 90, nil, { { 0, 1 }, { 0.5, 0 }, { 1, 1 } })
        table.insert(anims, function(t) scan.Position = UDim2.new(0, 0, ((t % 5) / 5) * 1.15 - 0.08, 0) end)
    end

    -- 4) LAUTAN: biru cantik, awan putih, ombak, gelembung
    build.ocean = function()
        setBase(90, { { 0, rgb(96, 184, 240) }, { 0.4, rgb(24, 102, 184) }, { 1, rgb(3, 26, 66) } })
        local rnd = Random.new(21)
        beams(3, rgb(210, 240, 255), 0.1, -16)
        local function cloud(y, scale, speed, off, alpha)
            local g = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 110 * scale, 0, 40 * scale),
                BackgroundTransparency = 1, BorderSizePixel = 0 })
            local parts = { { 0, 0.45, 64, 22 }, { 0.22, 0.2, 44, 26 }, { 0.45, 0.3, 52, 28 }, { 0.62, 0.55, 44, 18 } }
            for _, p in ipairs(parts) do
                local e = mk("Frame", { Position = UDim2.new(p[1], 0, p[2], 0),
                    Size = UDim2.new(0, p[3] * scale, 0, p[4] * scale), BackgroundColor3 = rgb(255, 255, 255),
                    BackgroundTransparency = alpha, BorderSizePixel = 0 }, g)
                mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, e)
            end
            table.insert(anims, function(t)
                g.Position = UDim2.new(((t * speed + off) % 1.6) - 0.35, 0, y, 0)
            end)
        end
        cloud(0.12, 1.0, 0.012, 0.1, 0.7)
        cloud(0.26, 0.8, 0.018, 0.6, 0.78)
        cloud(0.42, 1.2, 0.009, 1.1, 0.8)
        for i = 1, 8 do
            local b = circle(0.5, 1, rnd:NextInteger(4, 9), rgb(220, 245, 255), 0.75)
            local sp, ph, x0 = rnd:NextNumber(0.04, 0.1), rnd:NextNumber(0, 5), rnd:NextNumber(0.05, 0.95)
            table.insert(anims, function(t)
                b.Position = UDim2.new(x0 + math.sin(t + ph) * 0.02, 0, 1.05 - ((t * sp + ph) % 1.1), 0)
            end)
        end
        for layer = 1, 2 do
            local col = layer == 1 and rgb(150, 214, 255) or rgb(8, 70, 140)
            local tr = layer == 1 and 0.82 or 0.55
            local yb = layer == 1 and 0.9 or 0.96
            local sp = layer == 1 and 18 or 30
            for i = 0, 6 do
                local w = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 90, 0, 90),
                    BackgroundColor3 = col, BackgroundTransparency = tr, BorderSizePixel = 0 })
                mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, w)
                table.insert(anims, function(t)
                    local x = ((i * 55 + t * sp) % 385) - 60
                    w.Position = UDim2.new(0, x, yb, math.sin(t * 1.4 + i) * 3)
                end)
            end
        end
    end

    -- 5) SUNSET: jingga halus ke ungu malam, matahari terbenam
    build.sunset = function()
        setBase(90, { { 0, rgb(44, 20, 96) }, { 0.38, rgb(126, 50, 130) }, { 0.72, rgb(238, 108, 82) }, { 1, rgb(255, 172, 84) } })
        stars(26, 5, 2, 0.45)
        local glow = blob(0.5, 0.8, 260, rgb(255, 160, 90), 7)
        local sun = circle(0.5, 0.8, 120, rgb(255, 226, 150), 0.05)
        table.insert(anims, function(t)
            local y = 0.8 + math.sin(t * 0.4) * 0.012
            glow.Position = UDim2.new(0.5, 0, y, 0)
            sun.Position = UDim2.new(0.5, 0, y, 0)
        end)
        local rnd = Random.new(31)
        for i = 1, 5 do
            local y = 0.5 + i * 0.07
            local s = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, rnd:NextInteger(70, 120), 0, 6),
                BackgroundColor3 = i % 2 == 0 and rgb(255, 196, 170) or rgb(170, 100, 190),
                BackgroundTransparency = 0.7, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, s)
            local sp, off = rnd:NextNumber(0.008, 0.02), rnd:NextNumber(0, 1.5)
            table.insert(anims, function(t) s.Position = UDim2.new(((t * sp + off) % 1.5) - 0.3, 0, y, 0) end)
        end
        circle(0.12, 1.14, 300, rgb(46, 18, 70), 0.08)
        circle(0.88, 1.17, 330, rgb(38, 14, 60), 0.08)
    end

    -- 6) NEBULA: ungu angkasa + biru, bintang berkelip, bintang jatuh
    build.nebula = function()
        setBase(120, { { 0, rgb(30, 10, 74) }, { 0.5, rgb(10, 16, 72) }, { 1, rgb(54, 14, 100) } })
        local bl = {
            { 0.2, 0.22, 230, rgb(160, 70, 230) }, { 0.88, 0.5, 250, rgb(50, 110, 255) },
            { 0.5, 0.88, 200, rgb(236, 84, 196) }, { 0.25, 0.68, 160, rgb(60, 200, 255) },
            { 0.75, 0.15, 150, rgb(120, 90, 255) },
        }
        for i, b in ipairs(bl) do
            local g = blob(b[1], b[2], b[3], b[4], 7)
            local ph = i * 1.3
            table.insert(anims, function(t)
                g.Position = UDim2.new(b[1] + math.sin(t * 0.25 + ph) * 0.04, 0, b[2] + math.cos(t * 0.2 + ph) * 0.03, 0)
            end)
        end
        stars(46, 3, 2)
        local sh = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 40, 0, 1),
            BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.1, BorderSizePixel = 0,
            Rotation = -43, Visible = false })
        ugrad(sh, 0, nil, { { 0, 0 }, { 1, 1 } })
        table.insert(anims, function(t)
            local p = (t % 7) / 7
            if p < 0.14 then
                local q = p / 0.14
                sh.Visible = true
                sh.Position = UDim2.new(0.95 - q * 0.6, 0, 0.05 + q * 0.4, 0)
            else
                sh.Visible = false
            end
        end)
    end

    -- 7) BLACKHOLE: lubang hitam + cakram akresi berputar + cincin foton + partikel jatuh
    build.blackhole = function()
        setBase(90, { { 0, rgb(6, 4, 14) }, { 0.5, rgb(2, 2, 6) }, { 1, rgb(8, 4, 16) } })
        stars(36, 9, 2)
        local cx, cy = 0.5, 0.42
        blob(cx, cy, 300, rgb(110, 50, 200), 6)
        blob(cx, cy, 230, rgb(255, 120, 40), 7)

        local diskCols = { { 0, rgb(255, 120, 30) }, { 0.5, rgb(255, 238, 195) }, { 1, rgb(255, 120, 30) } }
        local spinners = {}
        local function ring(parent, w, h, th, px, py, dir)
            local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(px, 0, py, 0),
                Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0 }, parent)
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            local s = mk("UIStroke", { Thickness = th, Color = rgb(255, 255, 255),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
            local g = ugrad(s, 0, diskCols)
            table.insert(spinners, { g, dir })
        end
        local dims = { { 210, 56, 5, 1 }, { 178, 45, 3, -1 }, { 148, 34, 2, 1 } }

        -- cakram belakang
        local fill = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, 0),
            Size = UDim2.new(0, 196, 0, 46), BackgroundColor3 = rgb(255, 130, 40),
            BackgroundTransparency = 0.88, BorderSizePixel = 0 })
        mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
        for _, d in ipairs(dims) do ring(deco, d[1], d[2], d[3], cx, cy, d[4]) end

        -- cincin foton + inti hitam
        local photon = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, 0),
            Size = UDim2.new(0, 94, 0, 94), BackgroundTransparency = 1, BorderSizePixel = 0 })
        mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, photon)
        mk("UIStroke", { Thickness = 2, Color = rgb(255, 150, 60), Transparency = 0.5 }, photon)
        local hole = circle(cx, cy, 70, rgb(0, 0, 0), 0)
        mk("UIStroke", { Thickness = 2, Color = rgb(255, 196, 120), Transparency = 0.2 }, hole)

        -- cakram depan (separuh bawah) supaya kelihatan melintas di depan lubang hitam
        local front = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cx, 0, cy, 0),
            Size = UDim2.new(0, 230, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true })
        for _, d in ipairs(dims) do ring(front, d[1], d[2], d[3], 0.5, 0, d[4]) end

        table.insert(anims, function(t)
            for i = 1, #spinners do
                local s = spinners[i]
                s[1].Rotation = (t * 45 * s[2] * (1 + (i % 3) * 0.2)) % 360
            end
        end)

        local rnd = Random.new(41)
        for _ = 1, 10 do
            local d = circle(cx, cy, 2, rgb(255, 220, 170), 0.2)
            local ph, sp = rnd:NextNumber(0, 6.28), rnd:NextNumber(0.25, 0.6)
            table.insert(anims, function(t)
                local p = (t * sp * 0.2 + ph / 6.28) % 1
                local r = 1 - p * 0.75
                local a = ph + t * sp * 2.2 * (1 + p * 2)
                d.Position = UDim2.new(cx, math.cos(a) * 112 * r, cy, math.sin(a) * 36 * r)
                d.BackgroundTransparency = 0.1 + p * 0.85
            end)
        end
    end

    -- 8) AURORA: pita cahaya hijau-biru-ungu yang melayang pelan + bintang berkedip
    build.aurora = function()
        setBase(160, { { 0, rgb(4, 10, 28) }, { 0.55, rgb(6, 28, 46) }, { 1, rgb(16, 10, 42) } })
        stars(40, 17, 2, 0.75)
        local cols = { rgb(60, 255, 190), rgb(90, 170, 255), rgb(180, 110, 255) }
        for i = 1, 3 do
            local y0 = 0.16 + i * 0.17
            local band = mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, y0, 0),
                Size = UDim2.new(1.7, 0, 0, 74), Rotation = -8 + i * 6,
                BackgroundColor3 = cols[i], BackgroundTransparency = 0.8, BorderSizePixel = 0,
            })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, band)
            ugrad(band, 0, nil, { { 0, 1 }, { 0.3, 0.15 }, { 0.7, 0.15 }, { 1, 1 } })
            local ph = i * 1.9
            table.insert(anims, function(t)
                band.Position = UDim2.new(0.5 + math.sin(t * 0.22 + ph) * 0.08, 0, y0 + math.sin(t * 0.35 + ph) * 0.04, 0)
                band.Rotation = -8 + i * 6 + math.sin(t * 0.3 + ph) * 5
                band.BackgroundTransparency = 0.78 + math.sin(t * 0.6 + ph) * 0.07
            end)
        end
        local g = blob(0.88, 0.92, 210, rgb(60, 255, 190), 6)
        table.insert(anims, function(t) g.Size = UDim2.new(0, 210 + math.sin(t * 0.5) * 18, 0, 210 + math.sin(t * 0.5) * 18) end)
    end

    -- 9) SAKURA: kelopak bunga jatuh melayang + cahaya pink berdenyut
    build.sakura = function()
        setBase(150, { { 0, rgb(54, 16, 42) }, { 0.5, rgb(98, 36, 78) }, { 1, rgb(42, 14, 34) } })
        local b1 = blob(0.14, 0.12, 230, rgb(255, 150, 200), 7)
        local b2 = blob(0.9, 0.86, 250, rgb(255, 120, 170), 7)
        table.insert(anims, function(t)
            b1.Position = UDim2.new(0.14 + math.sin(t * 0.2) * 0.03, 0, 0.12 + math.cos(t * 0.17) * 0.03, 0)
            b2.Position = UDim2.new(0.9 + math.cos(t * 0.18) * 0.03, 0, 0.86 + math.sin(t * 0.22) * 0.03, 0)
        end)
        local rnd = Random.new(23)
        for _ = 1, 18 do
            local sz = rnd:NextInteger(5, 9)
            local pt = mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz, 0, math.max(3, math.floor(sz * 0.7))),
                BackgroundColor3 = rgb(255, rnd:NextInteger(170, 205), rnd:NextInteger(200, 225)),
                BackgroundTransparency = rnd:NextNumber(0.1, 0.35), BorderSizePixel = 0,
            })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pt)
            local x0, sp, ph, sw = rnd:NextNumber(), rnd:NextNumber(0.03, 0.07), rnd:NextNumber(), rnd:NextNumber(0.02, 0.06)
            table.insert(anims, function(t)
                local q = (t * sp + ph) % 1
                pt.Position = UDim2.new((x0 + math.sin(t * 0.8 + ph * 6) * sw + q * 0.1) % 1, 0, -0.05 + q * 1.1, 0)
                pt.Rotation = t * 40 + ph * 360
            end)
        end
    end

    -- ---------- ganti palet ----------
    local PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3", "ScrollBarImageColor3", "PlaceholderColor3" }

    local function setPalette(p)
        BG_BLACK, BG_DARK, BG_BUTTON = p.black, p.dark, p.btn
        BORDER_BLUE, ACCENT_BLUE, ON_COLOR, GREY = p.border, p.accent, p.on, p.grey
        local Cc = pages.C
        if Cc then
            Cc.PUR_BG, Cc.PUR_PANEL, Cc.PUR_CARD = p.cbg, p.cpanel, p.ccard
            Cc.PUR_BTN, Cc.ORG_BTN = p.cbtn, p.cbtn2
        end
    end

    local function recolor(old, new)
        local map = {}
        for _, r in ipairs(ROLES) do map[keyOf(old[r])] = new[r] end
        for _, o in ipairs(screenGui:GetDescendants()) do
            if not o:IsDescendantOf(fxRoot) then
                for _, p in ipairs(PROPS) do
                    local ok, v = pcall(function() return o[p] end)
                    if ok and typeof(v) == "Color3" then
                        local n = map[keyOf(v)]
                        if n then pcall(function() o[p] = n end) end
                    end
                end
                if o:IsA("UIStroke") then
                    local n = map[keyOf(o.Color)]
                    if n then o.Color = n end
                end
            end
        end
    end

    -- ---------- halaman tab TEMA ----------
    local page = pages.TEMA
    local tick, rows = {}, {}
    pages.header(page, "🎨 TEMA TAMPILAN", 0)
    local info = newLabel(page, "Pilih tema untuk mengganti tampilan UI", 9, Enum.Font.Gotham, GREY,
        UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 14))
    info.LayoutOrder = 1

    local curId = "default"
    local function markActive()
        for id, t in pairs(tick) do t.Visible = (id == curId) end
    end

    local function applyTheme(id)
        local th = byId[id]
        if not th then return end
        local old = cur
        cur = th.pal
        curId = id
        setPalette(th.pal)
        recolor(old, th.pal)

        for i = #anims, 1, -1 do anims[i] = nil end
        deco:ClearAllChildren()
        if id == "default" then
            fxRoot.Visible = false
            bgImage.Visible = true
        else
            bgImage.Visible = false
            fxRoot.Visible = true
            local ok, err = pcall(build[id])
            if not ok then warn("UNIVERSAL tema " .. id .. ": " .. tostring(err)) end
        end

        for _, o in ipairs(screenGui:GetDescendants()) do
            if o.Name == "BubbleRim" and o:IsA("UIStroke") then
                o.Color = th.rim[1]
                o.Transparency = th.rim[2]
            end
        end
        markActive()
        pcall(function() writefile("UniversalHub_theme.txt", id) end)
    end

    for i, th in ipairs(THEMES) do
        local b = makeButton(page, th.icon .. "  " .. th.name, i + 1)
        b.Size = UDim2.new(1, 0, 0, 38)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextSize = 12
        mk("UIPadding", { PaddingLeft = UDim.new(0, 44) }, b)
        local sw = mk("Frame", { Position = UDim2.new(0, -36, 0.5, -11), Size = UDim2.new(0, 22, 0, 22),
            BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0 }, b)
        mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, sw)
        mk("UIStroke", { Thickness = 1, Color = rgb(255, 255, 255), Transparency = 0.4 }, sw)
        ugrad(sw, 45, { { 0, th.sw[1] }, { 0.5, th.sw[2] }, { 1, th.sw[3] } })
        local tk = mk("TextLabel", { Position = UDim2.new(1, -52, 0, 0), Size = UDim2.new(0, 20, 1, 0),
            BackgroundTransparency = 1, Text = "✔", TextSize = 14, Font = Enum.Font.GothamBold,
            TextColor3 = rgb(255, 255, 255), Visible = (th.id == "default") }, b)
        tick[th.id] = tk
        b.MouseButton1Click:Connect(function() applyTheme(th.id) end)
        rows[th.id] = b
    end

    local animBtn = makeButton(page, "✨ Animasi dekorasi • ON", 20)
    animBtn.MouseButton1Click:Connect(function()
        animOn = not animOn
        animBtn.Text = animOn and "✨ Animasi dekorasi • ON" or "✨ Animasi dekorasi • OFF"
    end)

    -- ---------- TOMBOL BUBBLE ----------
    local TI_DOWN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local TI_UP = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local function bubble(b)
        if not b.Parent or b:GetAttribute("UHBubble") then return end
        if b.Text == "" or b.BackgroundTransparency >= 0.8 then return end
        b:SetAttribute("UHBubble", true)

        local h = b.Size.Y.Offset
        if b.Size.Y.Scale > 0 then h = b.AbsoluteSize.Y end
        local w = b.Size.X.Offset
        if b.Size.X.Scale > 0 then w = b.AbsoluteSize.X end
        local hasImg = b:FindFirstChildWhichIsA("ImageLabel") ~= nil

        -- bentuk bulat penuh (pil)
        local found = false
        for _, c in ipairs(b:GetChildren()) do
            if c:IsA("UICorner") then
                c.CornerRadius = (h > 0 and h <= 46) and UDim.new(0.5, 0) or UDim.new(0, 16)
                found = true
            end
        end
        if not found then
            local c = Instance.new("UICorner")
            c.CornerRadius = (h > 0 and h <= 46) and UDim.new(0.5, 0) or UDim.new(0, 16)
            c.Parent = b
        end

        if b.BackgroundTransparency > 0.3 then b.BackgroundTransparency = 0.3 end

        -- kilap gelembung: terang di atas, agak gelap di bawah
        if not b:FindFirstChildOfClass("UIGradient") then
            local g = Instance.new("UIGradient")
            g.Name = "BubbleGrad"
            g.Color = ColorSequence.new(rgb(255, 255, 255), rgb(172, 172, 188))
            g.Rotation = 90
            g.Parent = b
        end

        -- rim tipis berkilau (kalau tombol belum punya garis tepi sendiri)
        if not b:FindFirstChildOfClass("UIStroke") then
            local th = byId[curId]
            local s = Instance.new("UIStroke")
            s.Name = "BubbleRim"
            s.Thickness = 1
            s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            s.Color = th.rim[1]
            s.Transparency = th.rim[2]
            s.Parent = b
        end

        -- highlight cembung di atas + titik kilau kecil
        if not hasImg and h >= 14 then
            local gl = Instance.new("Frame")
            gl.Name = "BubbleGloss"
            gl.AnchorPoint = Vector2.new(0.5, 0)
            gl.Position = UDim2.new(0.5, 0, 0.07, 0)
            gl.Size = UDim2.new(0.84, 0, 0.4, 0)
            gl.BackgroundColor3 = rgb(255, 255, 255)
            gl.BackgroundTransparency = 0.8
            gl.BorderSizePixel = 0
            gl.Active = false
            gl.Parent = b
            local gc = Instance.new("UICorner")
            gc.CornerRadius = UDim.new(0.5, 0)
            gc.Parent = gl
            local gg = Instance.new("UIGradient")
            gg.Rotation = 90
            gg.Transparency = NumberSequence.new(0, 1)
            gg.Parent = gl
            if w >= 40 or w == 0 then
                local sp = Instance.new("Frame")
                sp.Name = "BubbleSpark"
                sp.AnchorPoint = Vector2.new(0.5, 0.5)
                sp.Position = UDim2.new(0.12, 0, 0.3, 0)
                sp.Size = UDim2.new(0, 3, 0, 3)
                sp.BackgroundColor3 = rgb(255, 255, 255)
                sp.BackgroundTransparency = 0.35
                sp.BorderSizePixel = 0
                sp.Active = false
                sp.Parent = b
                local sc2 = Instance.new("UICorner")
                sc2.CornerRadius = UDim.new(0.5, 0)
                sc2.Parent = sp
            end
        end

        -- efek pencet: mengecil lalu memantul balik
        local us = Instance.new("UIScale")
        us.Name = "BubbleScale"
        us.Parent = b
        local function release() TweenService:Create(us, TI_UP, { Scale = 1 }):Play() end
        b.MouseButton1Down:Connect(function() TweenService:Create(us, TI_DOWN, { Scale = 0.92 }):Play() end)
        b.MouseButton1Up:Connect(release)
        b.MouseLeave:Connect(release)
    end

    for _, o in ipairs(screenGui:GetDescendants()) do
        if o:IsA("TextButton") then pcall(bubble, o) end
    end
    screenGui.DescendantAdded:Connect(function(o)
        if o:IsA("TextButton") then
            task.defer(function() pcall(bubble, o) end)
        end
    end)

    -- tema terakhir yang dipakai (kalau executor mendukung readfile)
    local saved
    pcall(function()
        if isfile and isfile("UniversalHub_theme.txt") then saved = readfile("UniversalHub_theme.txt") end
    end)
    if saved and byId[saved] and saved ~= "default" then applyTheme(saved) end
end

task.spawn(function()
    local okT, errT = pcall(pages.initTheme)
    if not okT then warn("UNIVERSAL tema error: " .. tostring(errT)) end
end)


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

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
mainFrame.Size = UDim2.new(0, 265, 0, 405)
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
tabContainer.Position = UDim2.new(0, 8, 0, 84)
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
    f:SetAttribute("UHHeader", true)
    corner(f, 6)
    stroke(f, ACCENT_BLUE, 1)
    newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), Enum.TextXAlignment.Left)
    return f
end

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -170)
    page.Position = UDim2.new(0, 8, 0, 118)
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
makePage("APLIKASI") -- diakses lewat pages.APLIKASI
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
makeTabButton("APLIKASI", "🎮", "APLIKASI")
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

-- ==================== ESP BINTANG 3 + EMOTE ====================
-- Skeleton + Prediction + Chat Bubble + Target Info Panel + Emote Mirror
-- Semua nyambung ke state ESP yang udah ada (X.overlays, X.conn, X.step, X.refreshLoop)
do
    -- state
    X.skelOn   = false
    X.predOn   = false
    X.bubbleOn = false
    X.panelOn  = false
    X.emoteOn  = false
    X.bubbles  = {}
    X.panelTarget = nil
    X.panelPos = UDim2.new(1, -240, 0, 90)
    X._emoteConns = {}

    local SKEL = Color3.fromRGB(255, 220, 120)
    local PRED = Color3.fromRGB(120, 220, 255)
    local BUBBLE_BG = Color3.fromRGB(20, 25, 40)
    local EMOTE_C  = Color3.fromRGB(255, 120, 220)

    -- tombol baru (LayoutOrder 9-13 = tepat di bawah FPS BOOST MAX, masih di bagian judul ESP)
    X.skelBtn   = makeButton(playerPage, "🦴 SKELETON • OFF",     9)
    X.predBtn   = makeButton(playerPage, "🔮 PREDICTION • OFF",   10)
    X.bubbleBtn = makeButton(playerPage, "💬 CHAT BUBBLE • OFF",  11)
    X.panelBtn  = makeButton(playerPage, "🎯 TARGET PANEL • OFF", 12)
    X.emoteBtn  = makeButton(playerPage, "🎭 EMOTE MIRROR • OFF", 13)

    -- ==================== SKELETON ====================
    local SK_R15 = {
        {"UpperTorso","LowerTorso"}, {"UpperTorso","Head"},
        {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
    }
    local SK_R6 = {
        {"Torso","Head"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
        {"Torso","Left Leg"}, {"Torso","Right Leg"},
    }

    local function getSkelLines(p)
        local o = X.overlays[p]
        if not o then return nil end
        if o.skelLines then return o.skelLines end
        local lines = {}
        local ch = p.Character
        local pairList = (ch and ch:FindFirstChild("UpperTorso")) and SK_R15 or SK_R6
        for i = 1, #pairList do
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.BackgroundColor3 = SKEL
            f.BorderSizePixel = 0
            f.Visible = false
            f.ZIndex = 5
            f.Parent = X.folder
            lines[i] = f
        end
        o.skelLines = lines
        o.skelPairs = pairList
        return lines
    end

    local function hideSkel(o)
        if not o or not o.skelLines then return end
        for _, f in ipairs(o.skelLines) do
            if f.Parent then f.Visible = false end
        end
    end

    local function drawLine2D(frame, a, b)
        if not (a and b) then frame.Visible = false return end
        local d = b - a
        frame.Size = UDim2.fromOffset(d.Magnitude, 1.5)
        frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
        frame.Rotation = math.deg(math.atan2(d.Y, d.X))
        frame.Visible = true
    end

    local function screenPos(cam, part)
        if not part then return nil end
        local wp = cam:WorldToViewportPoint(part.Position)
        if wp.Z <= 0 then return nil end
        return Vector2.new(wp.X, wp.Y)
    end

    -- ==================== WRAP X.step ====================
    local oldStep = X.step
    X.step = function()
        oldStep()
        local cam = workspace.CurrentCamera
        if not cam then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local o = X.overlays[p]
                if o then
                    local ch = p.Character
                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        -- SKELETON
                        if X.skelOn then
                            local lines = getSkelLines(p)
                            if lines and o.skelPairs then
                                for i, pair in ipairs(o.skelPairs) do
                                    local a = screenPos(cam, ch:FindFirstChild(pair[1]))
                                    local b = screenPos(cam, ch:FindFirstChild(pair[2]))
                                    if a and b then drawLine2D(lines[i], a, b)
                                    else lines[i].Visible = false end
                                end
                            end
                        else hideSkel(o) end

                        -- PREDICTION
                        if X.predOn then
                            local v = hrp.AssemblyLinearVelocity
                            local fwd = Vector3.new(v.X, 0, v.Z) * 0.5
                            local predPos = hrp.Position + fwd
                            local wp = cam:WorldToViewportPoint(predPos)
                            if wp.Z > 0 and v.Magnitude > 4 then
                                if not o.predDot then
                                    o.predDot = Instance.new("Frame")
                                    o.predDot.Size = UDim2.fromOffset(8, 8)
                                    o.predDot.BackgroundColor3 = PRED
                                    o.predDot.BorderSizePixel = 0
                                    o.predDot.ZIndex = 6
                                    o.predDot.Parent = X.folder
                                    local c = Instance.new("UICorner")
                                    c.CornerRadius = UDim.new(0.5, 0)
                                    c.Parent = o.predDot
                                    local st = Instance.new("UIStroke")
                                    st.Color = Color3.new(1, 1, 1)
                                    st.Thickness = 1
                                    st.Transparency = 0.4
                                    st.Parent = o.predDot
                                end
                                o.predDot.Position = UDim2.fromOffset(wp.X - 4, wp.Y - 4)
                                o.predDot.Visible = true
                            elseif o.predDot then o.predDot.Visible = false end
                        elseif o.predDot then o.predDot.Visible = false end
                    else
                        hideSkel(o)
                        if o.predDot then o.predDot.Visible = false end
                    end
                end
            end
        end

        -- CHAT BUBBLE
        if X.bubbleOn then
            local now = os.clock()
            for p, b in pairs(X.bubbles) do
                if b.label.Parent then
                    if now > b.exp then
                        b.label:Destroy()
                        X.bubbles[p] = nil
                    else
                        local ch = p.Character
                        local head = ch and ch:FindFirstChild("Head")
                        if head then
                            local wp = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                            if wp.Z > 0 then
                                b.label.Position = UDim2.fromOffset(wp.X, wp.Y - 20)
                                b.label.Visible = true
                            else b.label.Visible = false end
                        else b.label.Visible = false end
                    end
                else X.bubbles[p] = nil end
            end
        end
    end

    -- ==================== CHAT BUBBLE HOOK ====================
    local function onChatted(p, msg)
        if p == player or not X.bubbleOn then return end
        if #msg > 60 then msg = msg:sub(1, 57) .. "..." end
        local old = X.bubbles[p]
        if old and old.label.Parent then old.label:Destroy() end
        local lbl = Instance.new("TextLabel")
        lbl.AnchorPoint = Vector2.new(0.5, 1)
        lbl.Size = UDim2.fromOffset(200, 28)
        lbl.BackgroundColor3 = BUBBLE_BG
        lbl.BackgroundTransparency = 0.15
        lbl.BorderSizePixel = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextWrapped = true
        lbl.Text = msg
        lbl.ZIndex = 7
        lbl.Visible = false
        lbl.Parent = X.folder
        local uc = Instance.new("UICorner")
        uc.CornerRadius = UDim.new(0, 8)
        uc.Parent = lbl
        local st = Instance.new("UIStroke")
        st.Color = ACCENT_BLUE
        st.Thickness = 1
        st.Transparency = 0.4
        st.Parent = lbl
        X.bubbles[p] = { label = lbl, exp = os.clock() + 5 }
    end

    local function hookChat(p)
        if not p.Chatted then return end
        local c = p.Chatted:Connect(function(msg) onChatted(p, msg) end)
        table.insert(X._emoteConns, c)
    end
    for _, p in ipairs(Players:GetPlayers()) do hookChat(p) end
    table.insert(X._emoteConns, Players.PlayerAdded:Connect(hookChat))

    -- ==================== EMOTE MIRROR ====================
    -- daftar emote populer (ID + nama) — bisa ditambah
    local EMOTES = {
        { id = "rbxassetid://3695333486", name = "Dance" },
        { id = "rbxassetid://507770239",  name = "Wave"  },
        { id = "rbxassetid://507770453",  name = "Laugh" },
        { id = "rbxassetid://507770818",  name = "Cheer" },
        { id = "rbxassetid://507771019",  name = "Point" },
        { id = "rbxassetid://507771964",  name = "Shrug"},
        { id = "rbxassetid://507768375",  name = "Salute"},
        { id = "rbxassetid://507770499",  name = "Stomp"},
        { id = "rbxassetid://3695333486", name = "Floss" },
        { id = "rbxassetid://507770677",  name = "Dance2"},
        { id = "rbxassetid://507770132",  name = "Dance3"},
        { id = "rbxassetid://507771539",  name = "Tilt"  },
    }

    -- pengaturan yang bisa diubah dari panel
    X.cfg = { followDist = 4, followSpeed = 60, emoteDur = 5, emoteSpeed = 1, mirrorIdx = 1 }

    -- aktifitas emote per player: { track, id, exp }
    X.emoteState = {}

    local function emoteExp()
        return X.cfg.emoteDur > 0 and (os.clock() + X.cfg.emoteDur) or math.huge
    end

    local function emoteName(id)
        for _, e in ipairs(EMOTES) do
            if e.id == id then return e.name end
        end
        return id:match("(%d+)$") or "?"
    end

    -- mainkan emote di karakter target (otomatis berhenti sesuai DURASI, 0 = terus)
    local function playEmoteOn(p, id)
        local ch = p.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local an = hum and hum:FindFirstChildOfClass("Animator")
        if not an then return nil end
        local a = Instance.new("Animation")
        a.AnimationId = id
        local ok, tr = pcall(function() return an:LoadAnimation(a) end)
        if not ok or not tr then return nil end
        tr.Priority = Enum.AnimationPriority.Action
        tr.Looped = true
        pcall(function() tr:Play() end)
        pcall(function() tr:AdjustSpeed(X.cfg.emoteSpeed) end)
        local dur = X.cfg.emoteDur
        if dur > 0 then
            task.delay(dur, function()
                local st = X.emoteState[p]
                if st and st.track == tr then
                    pcall(function() tr:Stop() end)
                    X.emoteState[p] = nil
                end
            end)
        end
        return tr
    end

    -- mirror: mainkan di semua player lain
    local function startMirror(id)
        for p, st in pairs(X.emoteState) do
            if st.track then pcall(function() st.track:Stop() end) end
        end
        X.emoteState = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local tr = playEmoteOn(p, id)
                if tr then
                    X.emoteState[p] = { track = tr, id = id, exp = emoteExp() }
                end
            end
        end
    end

    -- stop semua emote
    local function stopMirror()
        for p, st in pairs(X.emoteState) do
            if st.track then pcall(function() st.track:Stop() end) end
        end
        X.emoteState = {}
    end

    -- ==================== TARGET PANEL ====================
    local panel, panelBody
    local tog = {}   -- tombol toggle di dalam panel

    local function setTog(btn, label, on)
        if not btn then return end
        btn.Text = label .. (on and " • ON" or " • OFF")
        btn.BackgroundColor3 = on and ON_COLOR or BG_BUTTON
    end

    -- angka besar disingkat (K / M / B)
    local function fmtNum(n)
        if n >= 1e9 then return string.format("%.1fB", n / 1e9)
        elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
        elseif n >= 1e4 then return string.format("%.1fK", n / 1e3) end
        return tostring(math.floor(n))
    end

    -- ---------- FOLLOW ----------
    local function stopFollow()
        if X._followConn then X._followConn:Disconnect() X._followConn = nil end
        X.folOn = false
        setTog(tog.fol, "🚶 FOLLOW", false)
    end

    local function startFollow(p)
        stopFollow()
        X.folOn = true
        setTog(tog.fol, "🚶 FOLLOW", true)
        X._followConn = RunService.Heartbeat:Connect(function(dt)
            if not p.Parent then stopFollow() return end
            local th = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mh = getHRP()
            if not (th and mh) then return end
            local look = th.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
            flat = flat.Unit
            local dest = th.Position - flat * X.cfg.followDist
            local delta = Vector3.new(dest.X - mh.Position.X, 0, dest.Z - mh.Position.Z)
            if delta.Magnitude > 0.4 then
                local step = math.min(delta.Magnitude, X.cfg.followSpeed * dt)
                local u = delta.Unit
                mh.CFrame = CFrame.new(mh.Position.X + u.X * step, mh.Position.Y, mh.Position.Z + u.Z * step)
            end
        end)
    end

    -- ---------- SPECTATE ----------
    local function stopSpectate()
        X.specOn = false
        local cam = workspace.CurrentCamera
        local mine = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if cam and mine then cam.CameraSubject = mine end
        setTog(tog.spec, "👀 SPECTATE", false)
    end

    local function startSpectate(p)
        local cam = workspace.CurrentCamera
        local th = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if cam and th then
            cam.CameraSubject = th
            cam.CameraType = Enum.CameraType.Custom
            X.specOn = true
            setTog(tog.spec, "👀 SPECTATE", true)
        end
    end

    -- ---------- FLING (pakai mesin FLING PLAYER yang sudah ada, tanpa ubah daftar pilihan) ----------
    local function stopFlingPanel()
        local F = pages.fling
        if F and F.FL.on and F.FL.ovr then F.stop("⏹ Fling dihentikan", GREY) end
    end

    local function stopAllActions()
        stopFollow()
        if X.specOn then stopSpectate() end
        stopFlingPanel()
    end

    -- ---------- picker emote untuk target ----------
    local function openEmotePicker(p)
        local pick = Instance.new("Frame")
        pick.Size = UDim2.new(0, 240, 0, 220)
        pick.Position = UDim2.new(0.5, -120, 0.5, -110)
        pick.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
        pick.BackgroundTransparency = 0.05
        pick.BorderSizePixel = 0
        pick.ZIndex = 61
        pick.Parent = screenGui
        corner(pick, 10)
        stroke(pick, EMOTE_C, 2)
        newLabel(pick, "🎭 PILIH EMOTE", 11, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 10, 0, 4), UDim2.new(1, -40, 0, 20), Enum.TextXAlignment.Left)
        local x = Instance.new("TextButton")
        x.Size = UDim2.new(0, 22, 0, 22)
        x.Position = UDim2.new(1, -26, 0, 4)
        x.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
        x.Text = "X"
        x.TextSize = 10
        x.Font = Enum.Font.GothamBold
        x.TextColor3 = RED
        x.AutoButtonColor = false
        x.Parent = pick
        corner(x, 4)
        x.MouseButton1Click:Connect(function() pick:Destroy() end)
        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.new(1, -8, 1, -34)
        sc.Position = UDim2.new(0, 4, 0, 30)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 3
        sc.ScrollBarImageColor3 = EMOTE_C
        sc.CanvasSize = UDim2.new(0, 0, 0, 0)
        sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sc.Parent = pick
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 4)
        lay.Parent = sc
        for _, e in ipairs(EMOTES) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 28)
            b.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
            b.Text = "🎭 " .. e.name
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.AutoButtonColor = false
            b.ZIndex = 62
            b.Parent = sc
            corner(b, 6)
            b.MouseButton1Click:Connect(function()
                local st = X.emoteState[p]
                if st and st.track then pcall(function() st.track:Stop() end) end
                local tr = playEmoteOn(p, e.id)
                if tr then X.emoteState[p] = { track = tr, id = e.id, exp = emoteExp() } end
                pick:Destroy()
            end)
        end
    end

    local PANEL_W, PANEL_H = 230, 340
    local function buildPanel()
        if panel then panel:Destroy() end
        panel = Instance.new("Frame")
        panel.Name = "ESPInfoPanel"
        panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
        panel.Position = X.panelPos
        panel.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
        panel.BackgroundTransparency = 0.1
        panel.BorderSizePixel = 0
        panel.Visible = false
        panel.ZIndex = 40
        panel.Active = true
        panel.Parent = screenGui
        corner(panel, 10)
        stroke(panel, ACCENT_BLUE, 1)
        local me = panel

        -- ===== title bar =====
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 24)
        bar.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
        bar.BackgroundTransparency = 0.2
        bar.BorderSizePixel = 0
        bar.Parent = panel
        corner(bar, 10)
        newLabel(bar, "🎯 TARGET INFO", 9, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 8, 0, 0), UDim2.new(1, -60, 1, 0), Enum.TextXAlignment.Left)

        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 20, 0, 20)
        close.Position = UDim2.new(1, -22, 0, 2)
        close.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
        close.Text = "X"
        close.TextSize = 10
        close.Font = Enum.Font.GothamBold
        close.TextColor3 = RED
        close.AutoButtonColor = false
        close.Parent = bar
        corner(close, 4)
        close.MouseButton1Click:Connect(function()
            stopAllActions()
            me.Visible = false
            X.panelOn = false
            X.setBtn(X.panelBtn, "🎯 TARGET PANEL", false)
        end)

        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 20, 0, 20)
        minBtn.Position = UDim2.new(1, -44, 0, 2)
        minBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 75)
        minBtn.Text = "–"
        minBtn.TextSize = 12
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextColor3 = WHITE
        minBtn.AutoButtonColor = false
        minBtn.Parent = bar
        corner(minBtn, 4)

        -- drag
        local dragging, start, startPos = false, nil, nil
        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                start = input.Position
                startPos = me.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - start
                me.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                X.panelPos = me.Position
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        -- ===== isi panel (bisa di-scroll) =====
        panelBody = Instance.new("ScrollingFrame")
        panelBody.Position = UDim2.new(0, 4, 0, 28)
        panelBody.Size = UDim2.new(1, -8, 1, -32)
        panelBody.BackgroundTransparency = 1
        panelBody.BorderSizePixel = 0
        panelBody.ScrollBarThickness = 3
        panelBody.ScrollBarImageColor3 = ACCENT_BLUE
        panelBody.CanvasSize = UDim2.new(0, 0, 0, 0)
        panelBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
        panelBody.ZIndex = 41
        panelBody.Parent = panel
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 3)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = panelBody
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 4)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 4)
        pad.Parent = panelBody

        local collapsed = false
        minBtn.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            panelBody.Visible = not collapsed
            me.Size = UDim2.new(0, PANEL_W, 0, collapsed and 24 or PANEL_H)
            minBtn.Text = collapsed and "+" or "–"
        end)

        local ord = 0
        local function nextOrd() ord = ord + 1 return ord end

        local function mkText(text, color)
            local l = Instance.new("TextLabel")
            l.LayoutOrder = nextOrd()
            l.Size = UDim2.new(1, 0, 0, 16)
            l.BackgroundTransparency = 1
            l.Text = text
            l.TextSize = 10
            l.Font = Enum.Font.GothamBold
            l.TextColor3 = color or WHITE
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.ZIndex = 42
            l.Parent = panelBody
            return l
        end

        local function sect(text)
            local f = Instance.new("Frame")
            f.LayoutOrder = nextOrd()
            f.Size = UDim2.new(1, 0, 0, 18)
            f.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
            f.BorderSizePixel = 0
            f.ZIndex = 42
            f.Parent = panelBody
            corner(f, 5)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -10, 1, 0)
            l.Position = UDim2.new(0, 6, 0, 0)
            l.BackgroundTransparency = 1
            l.Text = text
            l.TextSize = 9
            l.Font = Enum.Font.GothamBlack
            l.TextColor3 = WHITE
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.ZIndex = 43
            l.Parent = f
        end

        local function mkBtn(parent, text, color, size, pos, fn)
            local b = Instance.new("TextButton")
            b.Size = size
            b.Position = pos
            b.BackgroundColor3 = color
            b.Text = text
            b.TextSize = 9
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.AutoButtonColor = false
            b.ZIndex = 42
            b.Parent = parent
            corner(b, 6)
            if fn then b.MouseButton1Click:Connect(fn) end
            return b
        end

        local function full(text, color, fn)
            local b = mkBtn(panelBody, text, color, UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 0), fn)
            b.LayoutOrder = nextOrd()
            return b
        end

        local function pair(t1, c1, f1, t2, c2, f2)
            local row = Instance.new("Frame")
            row.LayoutOrder = nextOrd()
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundTransparency = 1
            row.ZIndex = 42
            row.Parent = panelBody
            local a = mkBtn(row, t1, c1, UDim2.new(0.5, -2, 1, 0), UDim2.new(0, 0, 0, 0), f1)
            local b = mkBtn(row, t2, c2, UDim2.new(0.5, -2, 1, 0), UDim2.new(0.5, 2, 0, 0), f2)
            return a, b
        end

        -- baris angka (kolom isi). get/set supaya bisa dipakai buat pengaturan panel & pengaturan FLING
        local syncBoxes = {}
        local function numRow(label, lo, hi, get, set)
            local row = Instance.new("Frame")
            row.LayoutOrder = nextOrd()
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
            row.BorderSizePixel = 0
            row.ZIndex = 42
            row.Parent = panelBody
            corner(row, 6)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -70, 1, 0)
            l.Position = UDim2.new(0, 8, 0, 0)
            l.BackgroundTransparency = 1
            l.Text = label
            l.TextSize = 9
            l.Font = Enum.Font.GothamBold
            l.TextColor3 = WHITE
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextTruncate = Enum.TextTruncate.AtEnd
            l.ZIndex = 43
            l.Parent = row
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 54, 0, 18)
            box.Position = UDim2.new(1, -60, 0.5, -9)
            box.BackgroundColor3 = Color3.fromRGB(40, 50, 75)
            box.Text = string.format("%g", get())
            box.TextSize = 10
            box.Font = Enum.Font.GothamBold
            box.TextColor3 = WHITE
            box.ClearTextOnFocus = false
            box.ZIndex = 43
            box.Parent = row
            corner(box, 5)
            box.FocusLost:Connect(function()
                local v = math.clamp(tonumber(box.Text) or get(), lo, hi)
                set(v)
                box.Text = string.format("%g", get())
            end)
            table.insert(syncBoxes, { box = box, get = get })
            return box
        end

        local function flingRef() return pages.fling end

        -- ===== INFO =====
        local rName = mkText("👤 -", WHITE)
        local rUser = mkText("@-", GREY)
        local rHP = mkText("❤ -", WHITE)
        local hpBg = Instance.new("Frame")
        hpBg.LayoutOrder = nextOrd()
        hpBg.Size = UDim2.new(1, 0, 0, 5)
        hpBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        hpBg.BorderSizePixel = 0
        hpBg.ZIndex = 42
        hpBg.Parent = panelBody
        corner(hpBg, 3)
        local hpFill = Instance.new("Frame")
        hpFill.Size = UDim2.new(1, 0, 1, 0)
        hpFill.BackgroundColor3 = GREEN
        hpFill.BorderSizePixel = 0
        hpFill.ZIndex = 43
        hpFill.Parent = hpBg
        corner(hpFill, 3)
        local rDist = mkText("📏 -", WHITE)
        local rSpd = mkText("🏃 -", WHITE)
        local rTool = mkText("🔫 -", WHITE)
        local rEmote = mkText("🎭 -", WHITE)
        local rTeam = mkText("🏳 -", GREY)
        local rAge = mkText("📅 -", GREY)

        -- ===== AKSI =====
        sect("⚡ AKSI")
        local cpBtn
        local _, cpB = pair("🚀 TELEPORT", ACCENT_BLUE, function()
            local p = X.panelTarget
            if not p then return end
            local th = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mh = getHRP()
            if th and mh then mh.CFrame = th.CFrame * CFrame.new(0, 0, 3) end
        end, "📋 COPY @USER", Color3.fromRGB(60, 90, 140), function()
            local p = X.panelTarget
            if not p then return end
            local ok = pcall(function() (setclipboard or toclipboard or set_clipboard)("@" .. p.Name) end)
            cpBtn.Text = ok and "✅ DISALIN" or "⚠️ TIDAK DIDUKUNG"
            task.delay(1.2, function() cpBtn.Text = "📋 COPY @USER" end)
        end)
        cpBtn = cpB

        tog.fol = full("🚶 FOLLOW • OFF", BG_BUTTON, function()
            local p = X.panelTarget
            if not p then return end
            if X.folOn then stopFollow() else startFollow(p) end
        end)
        tog.spec = full("👀 SPECTATE • OFF", BG_BUTTON, function()
            local p = X.panelTarget
            if not p then return end
            if X.specOn then stopSpectate() else startSpectate(p) end
        end)
        tog.fl = full("💥 FLING • OFF", BG_BUTTON, function()
            local p = X.panelTarget
            if not p then return end
            local F = flingRef()
            if not F then
                tog.fl.Text = "⚠️ FLING BELUM SIAP"
                return
            end
            if F.FL.on then
                F.stop("⏹ Fling dihentikan", GREY)
            else
                F.start({ [p.Name] = p })
            end
        end)

        pair("🎭 EMOTE", EMOTE_C, function()
            local p = X.panelTarget
            if p then openEmotePicker(p) end
        end, "⏹ STOP EMOTE", Color3.fromRGB(120, 80, 40), function()
            local p = X.panelTarget
            if not p then return end
            local st = X.emoteState[p]
            if st and st.track then pcall(function() st.track:Stop() end) end
            X.emoteState[p] = nil
        end)

        -- ===== SETTING FOLLOW =====
        sect("⚙️ SETTING FOLLOW")
        numRow("Jarak di belakang (stud)", 1, 50, function() return X.cfg.followDist end, function(v) X.cfg.followDist = v end)
        numRow("Kecepatan (stud/s)", 5, 200, function() return X.cfg.followSpeed end, function(v) X.cfg.followSpeed = v end)

        -- ===== SETTING FLING (nyambung ke FLING PLAYER: metode, power, loop, balik) =====
        sect("⚙️ SETTING FLING")
        tog.method = full("⚙️ METODE: -", Color3.fromRGB(60, 60, 100), function()
            local F = flingRef()
            if not F then return end
            local idx = table.find(F.METHODS, F.FL.method) or 1
            F.FL.method = F.METHODS[idx % #F.METHODS + 1]
            F.refresh()
        end)
        numRow("Power (1 - 100)", 1, 100,
            function() local F = flingRef() return F and F.FL.power or 10 end,
            function(v) local F = flingRef() if F then F.FL.power = v F.refresh() end end)
        tog.loop = full("🔁 LOOP • ON", ON_COLOR, function()
            local F = flingRef()
            if not F then return end
            F.FL.loop = not F.FL.loop
            F.refresh()
        end)
        tog.back = full("🏠 BALIK POSISI AWAL • ON", ON_COLOR, function()
            local F = flingRef()
            if not F then return end
            F.FL.back = not F.FL.back
            F.refresh()
        end)

        -- ===== SETTING EMOTE =====
        sect("⚙️ SETTING EMOTE")
        numRow("Durasi detik (0 = terus)", 0, 600, function() return X.cfg.emoteDur end, function(v) X.cfg.emoteDur = v end)
        numRow("Kecepatan animasi", 0.1, 5, function() return X.cfg.emoteSpeed end, function(v) X.cfg.emoteSpeed = v end)
        tog.mirror = full("🪞 MIRROR: " .. EMOTES[X.cfg.mirrorIdx].name, Color3.fromRGB(110, 60, 110), function()
            X.cfg.mirrorIdx = X.cfg.mirrorIdx % #EMOTES + 1
            tog.mirror.Text = "🪞 MIRROR: " .. EMOTES[X.cfg.mirrorIdx].name
            if X.emoteOn then startMirror(EMOTES[X.cfg.mirrorIdx].id) end
        end)

        -- ===== LAIN-LAIN =====
        sect("🧰 LAIN-LAIN")
        full("⛔ STOP SEMUA (follow / spectate / fling / emote)", Color3.fromRGB(150, 50, 60), function()
            stopAllActions()
            local p = X.panelTarget
            local st = p and X.emoteState[p]
            if st and st.track then pcall(function() st.track:Stop() end) end
            if p then X.emoteState[p] = nil end
        end)

        -- ===== update 0.2 detik =====
        task.spawn(function()
            while me.Parent do
                task.wait(0.2)
                if not me.Visible then continue end
                local p = X.panelTarget
                if not p or p.Parent ~= Players then
                    stopAllActions()
                    me.Visible = false
                    X.panelOn = false
                    X.setBtn(X.panelBtn, "🎯 TARGET PANEL", false)
                    continue
                end
                local ch = p.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")

                rName.Text = "👤 " .. ((p.DisplayName ~= "" and p.DisplayName) or p.Name)
                rUser.Text = "@" .. p.Name .. "  •  ID " .. p.UserId
                if hum and hum.Health > 0 then
                    local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    rHP.Text = string.format("❤ %d / %d", math.floor(hum.Health), math.floor(hum.MaxHealth))
                    hpFill.Size = UDim2.new(frac, 0, 1, 0)
                    hpFill.BackgroundColor3 = Color3.fromHSV(frac * 0.33, 1, 1)
                else
                    rHP.Text = "❤ 💀 mati / belum spawn"
                    hpFill.Size = UDim2.new(0, 0, 1, 0)
                end
                local mh = getHRP()
                if hrp and mh then
                    rDist.Text = "📏 " .. fmtNum((hrp.Position - mh.Position).Magnitude) .. " stud"
                    rSpd.Text = string.format("🏃 %.0f stud/s", hrp.AssemblyLinearVelocity.Magnitude)
                else
                    rDist.Text = "📏 -"
                    rSpd.Text = "🏃 -"
                end
                local tool = ch and ch:FindFirstChildOfClass("Tool")
                rTool.Text = "🔫 " .. (tool and tool.Name or "-")
                local st = X.emoteState[p]
                if st and st.track and st.exp > os.clock() then
                    rEmote.Text = "🎭 " .. emoteName(st.id)
                else
                    rEmote.Text = "🎭 -"
                end
                rTeam.Text = "🏳 Tim: " .. (p.Team and p.Team.Name or "-")
                rAge.Text = "📅 Akun: " .. tostring(p.AccountAge) .. " hari"

                -- sinkron tombol toggle
                setTog(tog.fol, "🚶 FOLLOW", X.folOn == true)
                if X.specOn then
                    local cam = workspace.CurrentCamera
                    if cam and hum and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
                end
                setTog(tog.spec, "👀 SPECTATE", X.specOn == true)
                local F = pages.fling
                setTog(tog.fl, "💥 FLING", F ~= nil and F.FL.on and F.FL.ovr ~= nil)
                if F then
                    tog.method.Text = "⚙️ METODE: " .. F.FL.method
                    setTog(tog.loop, "🔁 LOOP", F.FL.loop)
                    setTog(tog.back, "🏠 BALIK POSISI AWAL", F.FL.back)
                end
                for _, sb in ipairs(syncBoxes) do
                    if not sb.box:IsFocused() then sb.box.Text = string.format("%g", sb.get()) end
                end
            end
        end)
        return panel
    end

    -- picker target
    local function pickTarget()
        local pick = Instance.new("Frame")
        pick.Size = UDim2.new(0, 220, 0, 280)
        pick.Position = UDim2.new(0.5, -110, 0.5, -140)
        pick.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
        pick.BackgroundTransparency = 0.05
        pick.BorderSizePixel = 0
        pick.ZIndex = 60
        pick.Parent = screenGui
        corner(pick, 10)
        stroke(pick, ACCENT_BLUE, 2)
        newLabel(pick, "🎯 PILIH TARGET", 11, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 10, 0, 4), UDim2.new(1, -40, 0, 20), Enum.TextXAlignment.Left)
        local x = Instance.new("TextButton")
        x.Size = UDim2.new(0, 22, 0, 22)
        x.Position = UDim2.new(1, -26, 0, 4)
        x.BackgroundColor3 = Color3.fromRGB(80, 30, 40)
        x.Text = "X"
        x.TextSize = 10
        x.Font = Enum.Font.GothamBold
        x.TextColor3 = RED
        x.AutoButtonColor = false
        x.Parent = pick
        corner(x, 4)
        x.MouseButton1Click:Connect(function() pick:Destroy() end)
        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.new(1, -8, 1, -34)
        sc.Position = UDim2.new(0, 4, 0, 30)
        sc.BackgroundTransparency = 1
        sc.BorderSizePixel = 0
        sc.ScrollBarThickness = 3
        sc.ScrollBarImageColor3 = ACCENT_BLUE
        sc.CanvasSize = UDim2.new(0, 0, 0, 0)
        sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sc.Parent = pick
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 4)
        lay.Parent = sc
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, 28)
                b.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
                b.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                b.TextSize = 10
                b.Font = Enum.Font.GothamBold
                b.TextColor3 = WHITE
                b.AutoButtonColor = false
                b.Parent = sc
                corner(b, 6)
                b.MouseButton1Click:Connect(function()
                    if X.panelTarget ~= p then stopAllActions() end
                    X.panelTarget = p
                    if not panel then buildPanel() end
                    panel.Visible = true
                    pick:Destroy()
                end)
            end
        end
    end

    -- ==================== TOGGLE HANDLERS ====================
    X.skelBtn.MouseButton1Click:Connect(function()
        X.skelOn = not X.skelOn
        X.setBtn(X.skelBtn, "🦴 SKELETON", X.skelOn)
        if not X.skelOn then for _, o in pairs(X.overlays) do hideSkel(o) end end
        X.refreshLoop()
    end)
    X.predBtn.MouseButton1Click:Connect(function()
        X.predOn = not X.predOn
        X.setBtn(X.predBtn, "🔮 PREDICTION", X.predOn)
        if not X.predOn then
            for _, o in pairs(X.overlays) do if o.predDot then o.predDot.Visible = false end end
        end
        X.refreshLoop()
    end)
    X.bubbleBtn.MouseButton1Click:Connect(function()
        X.bubbleOn = not X.bubbleOn
        X.setBtn(X.bubbleBtn, "💬 CHAT BUBBLE", X.bubbleOn)
        if not X.bubbleOn then
            for p, b in pairs(X.bubbles) do if b.label and b.label.Parent then b.label:Destroy() end end
            X.bubbles = {}
        end
        X.refreshLoop()
    end)
    X.panelBtn.MouseButton1Click:Connect(function()
        X.panelOn = not X.panelOn
        X.setBtn(X.panelBtn, "🎯 TARGET PANEL", X.panelOn)
        if X.panelOn then
            if not panel then buildPanel() end
            panel.Visible = true
            pickTarget()
        else
            stopAllActions()
            if panel then panel.Visible = false end
        end
    end)
    X.emoteBtn.MouseButton1Click:Connect(function()
        X.emoteOn = not X.emoteOn
        X.setBtn(X.emoteBtn, "🎭 EMOTE MIRROR", X.emoteOn)
        if X.emoteOn then
            startMirror(EMOTES[X.cfg.mirrorIdx].id)
        else
            stopMirror()
        end
        X.refreshLoop()
    end)

    -- ==================== REFRESH LOOP WRAP ====================
    X.refreshLoop = function()
        local need = X.espOn or X.boxOn or X.tracerOn or X.skelOn or X.predOn or X.bubbleOn
        if need and not X.conn then
            X.conn = RunService.RenderStepped:Connect(X.step)
        elseif not need and X.conn then
            X.conn:Disconnect()
            X.conn = nil
            for _, o in pairs(X.overlays) do
                X.hideOverlay(o)
                hideSkel(o)
                if o.predDot then o.predDot.Visible = false end
            end
            for p, b in pairs(X.bubbles) do
                if b.label and b.label.Parent then b.label:Destroy() end
            end
            X.bubbles = {}
        end
    end

    -- ==================== DESTROY OVERLAY WRAP ====================
    local oldDestroy = X.destroyOverlay
    X.destroyOverlay = function(o)
        if o.skelLines then for _, f in ipairs(o.skelLines) do f:Destroy() end end
        if o.predDot then o.predDot:Destroy() end
        oldDestroy(o)
    end

    -- ==================== CLEANUP ====================
    table.insert(cleanupFns, function()
        X.skelOn, X.predOn, X.bubbleOn, X.panelOn, X.emoteOn = false, false, false, false, false
        for _, o in pairs(X.overlays) do
            hideSkel(o)
            if o.predDot then o.predDot:Destroy() end
        end
        for _, b in pairs(X.bubbles) do
            if b.label and b.label.Parent then b.label:Destroy() end
        end
        X.bubbles = {}
        stopMirror()
        stopAllActions()
        if panel then panel:Destroy() end
        if X._followConn then X._followConn:Disconnect() end
        for _, c in ipairs(X._emoteConns) do pcall(function() c:Disconnect() end) end
        X._emoteConns = {}
    end)
end

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

-- ==================== AUTO CLICK TITIK (tab FARM) ====================
-- Bulatan bernomor (1, 2, 3...) bisa ditambah, digeser, dihapus. Auto click menekan bulatan satu per satu berurutan.
-- Jeda: NANO DETIK (min 10) / DETIK (min 1) / MENIT (min 1) / JAM (min 1). Batas atas bebas.
-- Dibungkus fungsi sendiri supaya tidak menambah variabel local di script utama (batas Lua 200).
;(function()
local VIM = game:GetService("VirtualInputManager")
local GuiSvc = game:GetService("GuiService")
local AC = { mx = 0, my = 0, auto = true, off = Vector2.zero, lastP = nil, starting = false, markers = {}, sel = nil, on = false, show = true, unit = 2, val = 1, idx = 1, acc = 0, conn = nil, MAXF = 25, drag = nil }
local UNITS = { { "NANO DETIK", 1e-9, 10 }, { "DETIK", 1, 1 }, { "MENIT", 60, 1 }, { "JAM", 3600, 1 } }
local BLUE = Color3.fromRGB(15, 105, 230)
local TEAL = Color3.fromRGB(0, 185, 150)
local GOLD = Color3.fromRGB(255, 200, 60)

local oldG = player:WaitForChild("PlayerGui"):FindFirstChild("AutoClickMarkers")
if oldG then oldG:Destroy() end
AC.gui = Instance.new("ScreenGui")
AC.gui.Name = "AutoClickMarkers"
AC.gui.ResetOnSpawn = false
AC.gui.IgnoreGuiInset = true
AC.gui.DisplayOrder = 90
AC.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
AC.gui.Parent = player.PlayerGui

pages.header(farmPage, "🎯 AUTO CLICK TITIK", 44)

local row = Instance.new("Frame")
row.LayoutOrder = 45
row.Size = UDim2.new(1, 0, 0, 30)
row.BackgroundTransparency = 1
row.BorderSizePixel = 0
row.Parent = farmPage
AC.addBtn = makeButton(row, "➕ TAMBAH TITIK", 0)
AC.addBtn.Size = UDim2.new(0.5, -3, 1, 0)
AC.delBtn = makeButton(row, "🗑 HAPUS TITIK", 0)
AC.delBtn.Size = UDim2.new(0.5, -3, 1, 0)
AC.delBtn.Position = UDim2.new(0.5, 3, 0, 0)

AC.clearBtn = makeButton(farmPage, "🧹 HAPUS SEMUA TITIK", 46)
AC.showBtn = makeButton(farmPage, "👁 TITIK: TAMPIL", 47)

-- jeda: angka + satuan
local tf = Instance.new("Frame")
tf.LayoutOrder = 48
tf.Size = UDim2.new(1, 0, 0, 30)
tf.BackgroundColor3 = BG_BUTTON
tf.BorderSizePixel = 0
tf.Parent = farmPage
corner(tf, 8)
newLabel(tf, "⏱ JEDA", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(0.22, 0, 1, 0), Enum.TextXAlignment.Left)
AC.box = Instance.new("TextBox")
AC.box.Size = UDim2.new(0.34, -4, 1, -8)
AC.box.Position = UDim2.new(0.22, 0, 0, 4)
AC.box.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
AC.box.Text = "1"
AC.box.TextSize = 12
AC.box.Font = Enum.Font.GothamBold
AC.box.TextColor3 = WHITE
AC.box.ClearTextOnFocus = false
AC.box.Parent = tf
corner(AC.box, 6)
AC.unitBtn = Instance.new("TextButton")
AC.unitBtn.Size = UDim2.new(0.44, -6, 1, -8)
AC.unitBtn.Position = UDim2.new(0.56, 2, 0, 4)
AC.unitBtn.BackgroundColor3 = ACCENT_BLUE
AC.unitBtn.TextSize = 10
AC.unitBtn.Font = Enum.Font.GothamBold
AC.unitBtn.TextColor3 = WHITE
AC.unitBtn.AutoButtonColor = false
AC.unitBtn.Parent = tf
corner(AC.unitBtn, 6)

AC.status = newLabel(farmPage, "Tambah titik dulu, lalu tekan MULAI", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), Enum.TextXAlignment.Left)
AC.status.LayoutOrder = 50
AC.status.TextWrapped = true
AC.status.TextYAlignment = Enum.TextYAlignment.Top
AC.startBtn = makeButton(farmPage, "▶ MULAI AUTO CLICK • OFF", 51)

-- koreksi klik manual (piksel): kalau klik masih geser dari tengah bulatan, isi X / Y di sini. AUTO = kalibrasi otomatis.
local cf = Instance.new("Frame")
cf.LayoutOrder = 49
cf.Size = UDim2.new(1, 0, 0, 30)
cf.BackgroundColor3 = BG_BUTTON
cf.BorderSizePixel = 0
cf.Parent = farmPage
corner(cf, 8)
newLabel(cf, "🎯 GESER", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(0.2, 0, 1, 0), Enum.TextXAlignment.Left)
local function offBox(xs, init, key)
    local b = Instance.new("TextBox")
    b.Size = UDim2.new(0.22, -4, 1, -8)
    b.Position = UDim2.new(xs, 0, 0, 4)
    b.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
    b.Text = tostring(init)
    b.PlaceholderText = key == "mx" and "X" or "Y"
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.ClearTextOnFocus = false
    b.Parent = cf
    corner(b, 6)
    b.FocusLost:Connect(function()
        local v = tonumber(b.Text) or 0
        AC[key] = math.clamp(v, -400, 400)
        b.Text = tostring(AC[key])
    end)
end
offBox(0.2, 0, "mx")
offBox(0.43, 0, "my")
AC.autoBtn = Instance.new("TextButton")
AC.autoBtn.Size = UDim2.new(0.33, -6, 1, -8)
AC.autoBtn.Position = UDim2.new(0.66, 2, 0, 4)
AC.autoBtn.BackgroundColor3 = ON_COLOR
AC.autoBtn.Text = "AUTO • ON"
AC.autoBtn.TextSize = 10
AC.autoBtn.Font = Enum.Font.GothamBold
AC.autoBtn.TextColor3 = WHITE
AC.autoBtn.AutoButtonColor = false
AC.autoBtn.Parent = cf
corner(AC.autoBtn, 6)
AC.autoBtn.MouseButton1Click:Connect(function()
    AC.auto = not AC.auto
    AC.autoBtn.Text = AC.auto and "AUTO • ON" or "AUTO • OFF"
    AC.autoBtn.BackgroundColor3 = AC.auto and ON_COLOR or Color3.fromRGB(45, 55, 85)
end)

function AC.setStatus(t, c)
    AC.status.Text = t
    AC.status.TextColor3 = c or GREY
end

function AC.interval()
    return AC.val * UNITS[AC.unit][2]
end

function AC.fmt(v)
    if v == math.floor(v) then return string.format("%.0f", v) end
    return tostring(v)
end

function AC.info()
    local iv = AC.interval()
    local cps = 1 / iv
    local txt
    if cps >= 1 then
        txt = string.format("Jeda %s %s ≈ %s klik/detik", AC.fmt(AC.val), string.lower(UNITS[AC.unit][1]), AC.fmt(math.floor(cps)))
        if cps > 60 * AC.MAXF then
            txt = txt .. " (dibatasi ±" .. (60 * AC.MAXF) .. "/detik: Roblox cuma jalan per frame)"
        end
    else
        txt = string.format("Jeda %s %s", AC.fmt(AC.val), string.lower(UNITS[AC.unit][1]))
    end
    AC.setStatus(txt, GREY)
end

-- aturan minimal tiap satuan (batas atas bebas)
function AC.clampVal()
    local min = UNITS[AC.unit][3]
    local v = tonumber(AC.box.Text)
    local clamped = false
    if not v or v ~= v then v = AC.val end
    if v < min then v = min clamped = true end
    AC.val = v
    AC.box.Text = AC.fmt(v)
    AC.unitBtn.Text = UNITS[AC.unit][1] .. " ▾"
    if clamped then
        AC.setStatus("Minimal " .. min .. " " .. string.lower(UNITS[AC.unit][1]), RED)
    else
        AC.info()
    end
end
AC.box.FocusLost:Connect(AC.clampVal)
AC.unitBtn.MouseButton1Click:Connect(function()
    AC.unit = AC.unit % #UNITS + 1
    AC.box.Text = AC.fmt(AC.val)
    AC.clampVal()
end)
AC.clampVal()

-- ---------- bulatan ----------
function AC.renumber()
    for i, m in ipairs(AC.markers) do m.label.Text = tostring(i) end
end

function AC.select(m)
    AC.sel = m
    for _, o in ipairs(AC.markers) do
        o.stroke.Color = (o == m) and GOLD or BLUE
    end
end

function AC.remove(m)
    for i, o in ipairs(AC.markers) do
        if o == m then table.remove(AC.markers, i) break end
    end
    if AC.sel == m then AC.sel = nil end
    pcall(function() m.frame:Destroy() end)
    AC.renumber()
    if #AC.markers == 0 and AC.on then AC.stop("Semua titik dihapus") end
end

function AC.center(m)
    local f = m.frame
    return f.AbsolutePosition + f.AbsoluteSize / 2
end

function AC.add()
    local cam = workspace.CurrentCamera
    local vs = cam and cam.ViewportSize or Vector2.new(800, 600)
    local n = #AC.markers
    local pos = Vector2.new(vs.X * 0.5 + (n % 5) * 56 - 112, vs.Y * 0.5 + math.floor(n / 5) * 56)
    local mp, ms = mainFrame.AbsolutePosition, mainFrame.AbsoluteSize
    if mainFrame.Visible and pos.X >= mp.X - 30 and pos.X <= mp.X + ms.X + 30 and pos.Y >= mp.Y - 30 and pos.Y <= mp.Y + ms.Y + 30 then
        pos = Vector2.new(vs.X * 0.88, vs.Y * 0.25 + (n % 6) * 56)
    end

    local f = Instance.new("Frame")
    f.Name = "Marker"
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Size = UDim2.fromOffset(46, 46)
    f.Position = UDim2.fromOffset(pos.X, pos.Y)
    f.BackgroundColor3 = BLUE
    f.BackgroundTransparency = 0.65
    f.BorderSizePixel = 0
    f.Active = true
    f.Parent = AC.gui
    corner(f, 23)
    local st = stroke(f, BLUE, 3)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, 0, 1, 0)
    lb.BackgroundTransparency = 1
    lb.Text = tostring(n + 1)
    lb.TextSize = 24
    lb.Font = Enum.Font.GothamBold
    lb.TextColor3 = TEAL
    lb.Parent = f
    local x = Instance.new("TextButton")
    x.Size = UDim2.fromOffset(16, 16)
    x.Position = UDim2.new(1, -8, 0, -8)
    x.BackgroundColor3 = Color3.fromRGB(220, 60, 70)
    x.Text = "x"
    x.TextSize = 10
    x.Font = Enum.Font.GothamBold
    x.TextColor3 = WHITE
    x.AutoButtonColor = false
    x.ZIndex = 3
    x.Parent = f
    corner(x, 8)

    local m = { frame = f, label = lb, stroke = st, x = x }
    table.insert(AC.markers, m)
    AC.select(m)
    x.MouseButton1Click:Connect(function() AC.remove(m) end)
    f.InputBegan:Connect(function(input)
        if AC.on then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            AC.select(m)
            AC.drag = { m = m, start = input.Position, pos = f.Position }
        end
    end)
    AC.setStatus("Titik " .. (n + 1) .. " ditambah • geser bulatan ke tempat yang mau diklik", GREY)
end

local dragMove = UserInputService.InputChanged:Connect(function(input)
    local d = AC.drag
    if d and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - d.start
        d.m.frame.Position = UDim2.fromOffset(d.pos.X.Offset + delta.X, d.pos.Y.Offset + delta.Y)
    end
end)
local dragEnd = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        AC.drag = nil
    end
end)

AC.addBtn.MouseButton1Click:Connect(AC.add)
AC.delBtn.MouseButton1Click:Connect(function()
    local m = AC.sel or AC.markers[#AC.markers]
    if m then AC.remove(m) AC.setStatus("Titik dihapus", GREY) else AC.setStatus("Belum ada titik", GREY) end
end)
AC.clearBtn.MouseButton1Click:Connect(function()
    for i = #AC.markers, 1, -1 do AC.remove(AC.markers[i]) end
    AC.setStatus("Semua titik dihapus", GREY)
end)
AC.showBtn.MouseButton1Click:Connect(function()
    AC.show = not AC.show
    AC.gui.Enabled = AC.show
    AC.showBtn.Text = AC.show and "👁 TITIK: TAMPIL" or "👁 TITIK: SEMBUNYI (tetap klik)"
end)

-- ---------- klik ----------
-- AC.off = koreksi posisi klik (otomatis dihitung pas MULAI) supaya klik PERSIS di tengah bulatan
function AC.clickAt(p)
    p = p + AC.off + Vector2.new(AC.mx, AC.my)
    AC.lastP = p
    local ok = pcall(function()
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    if not ok and mouse1click then
        pcall(function()
            if mousemoveabs then mousemoveabs(p.X, p.Y) end
            mouse1click()
        end)
    end
end

-- Kalibrasi: klik percobaan di tengah bulatan 1, lihat klik itu sebenarnya mendarat di mana, lalu geser koreksinya.
function AC.calibrate()
    AC.off = Vector2.zero
    local m = AC.markers[1]
    if not m or not AC.auto then return end
    local probe = Instance.new("TextButton")
    probe.Name = "Probe"
    probe.Size = UDim2.fromScale(1, 1)
    probe.BackgroundTransparency = 1
    probe.Text = ""
    probe.AutoButtonColor = false
    probe.Active = true
    probe.ZIndex = 100
    probe.Parent = AC.gui
    local got
    local c = probe.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            got = Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    local p = AC.center(m)
    pcall(function()
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    local t = os.clock()
    while not got and os.clock() - t < 0.3 do task.wait() end
    c:Disconnect()
    probe:Destroy()
    if got then
        local off = p - got - GuiSvc:GetGuiInset()
        if math.abs(off.X) < 300 and math.abs(off.Y) < 300 then
            AC.off = off
            AC.setStatus(string.format("Kalibrasi otomatis: geser %d, %d px", off.X, off.Y), GREY)
        end
    end
end

-- Setelah auto click mati: lepas klik yang nyangkut, lepas fokus TextBox, dan hidupkan lagi kontrol jalan (joystick / WASD)
function AC.restoreControls()
    pcall(function()
        local p = AC.lastP or Vector2.new(0, 0)
        VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end)
    pcall(function()
        local tb = UserInputService:GetFocusedTextBox()
        if tb then tb:ReleaseFocus() end
    end)
    -- di HP, klik mouse virtual bikin game ganti ke mode "mouse" dan joystick mati; satu sentuhan virtual balikin ke mode sentuh
    if UserInputService.TouchEnabled then
        pcall(function()
            local cam = workspace.CurrentCamera
            local vs = cam and cam.ViewportSize or Vector2.new(800, 600)
            VIM:SendTouchEvent(8191, 0, vs.X * 0.5, 2)
            VIM:SendTouchEvent(8191, 2, vs.X * 0.5, 2)
        end)
    end
    pcall(function()
        local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        local ctrl = pm:GetControls()
        ctrl:Disable()
        ctrl:Enable()
    end)
end

function AC.lock(on)
    for _, m in ipairs(AC.markers) do
        m.frame.Active = not on
        m.frame.BackgroundTransparency = on and 0.85 or 0.65
        m.x.Visible = not on
        pcall(function() m.frame.Interactable = not on end)
    end
end

function AC.stop(reason)
    local wasOn = AC.on
    AC.on = false
    AC.starting = false
    if AC.conn then AC.conn:Disconnect() AC.conn = nil end
    if wasOn then
        AC.restoreControls()
        task.delay(0.1, AC.restoreControls)
    end
    AC.lock(false)
    AC.startBtn.Text = "▶ MULAI AUTO CLICK • OFF"
    AC.startBtn.BackgroundColor3 = BG_BUTTON
    if reason then AC.setStatus(reason, GREY) else AC.info() end
end

function AC.start()
    if #AC.markers == 0 then
        AC.setStatus("Tambah titik dulu ⚠️", RED)
        return
    end
    if AC.starting then return end
    AC.clampVal()
    AC.starting = true
    AC.drag = nil
    AC.lock(true)
    AC.calibrate()
    if not AC.starting then return end -- dihentikan pas kalibrasi
    AC.starting = false
    AC.on = true
    AC.idx = 1
    AC.acc = AC.interval() -- klik pertama langsung
    AC.startBtn.Text = "⏹ AUTO CLICK • ON"
    AC.startBtn.BackgroundColor3 = ON_COLOR
    AC.conn = RunService.Heartbeat:Connect(function(dt)
        local iv = AC.interval()
        AC.acc = AC.acc + dt
        local n = 0
        while AC.acc >= iv and n < AC.MAXF do
            AC.acc = AC.acc - iv
            n = n + 1
            local count = #AC.markers
            if count == 0 then break end
            if AC.idx > count then AC.idx = 1 end
            local m = AC.markers[AC.idx]
            AC.idx = AC.idx % count + 1
            if m then AC.clickAt(AC.center(m)) end
        end
        if n >= AC.MAXF then AC.acc = 0 end
    end)
end

AC.startBtn.MouseButton1Click:Connect(function()
    if AC.on or AC.starting then AC.stop() else task.spawn(AC.start) end
end)

table.insert(cleanupFns, function()
    AC.stop()
    dragMove:Disconnect()
    dragEnd:Disconnect()
    pcall(function() AC.gui:Destroy() end)
end)
end)()

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
sectionHeader("🚀 TELEPORT PLAYER", 14)
local tpPick
local tpPlayerBtn = makePlayerButton("🚀 TELEPORT PLAYER", 17)

tpPick = makePicker({
    btnText = "🎯 SELECT TELEPORT",
    closeText = "🎯 CLOSE SELECT",
    btnOrder = 15,
    frameOrder = 16,
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
    { folder = "sit",      kids = { "SitAnim" } },
    { folder = "toolnone", kids = { "ToolNoneAnim" } },
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

-- samakan animasi dengan target.
-- live = AnimationId asli dari script Animate milik target (kalau ada) -> paling akurat (termasuk animasi custom game).
-- Kalau tidak ada: pakai HumanoidDescription target. Kalau target polos (tanpa animasi) -> animasi bawaan game.
local function syncAnimations(char, desc, live)
    local animate = char and char:FindFirstChild("Animate")
    if not animate then return end
    local o = CS.orig
    local changed = false
    for _, slot in ipairs(ANIM_SLOTS) do
        local id = 0
        pcall(function() id = desc and desc[slot.prop] or 0 end)
        local folder = animate:FindFirstChild(slot.folder)
        if folder then
            for _, kid in ipairs(slot.kids) do
                local a = folder:FindFirstChild(kid)
                if a and a:IsA("Animation") then
                    local key = slot.folder .. "/" .. kid
                    local want = live and live[key]
                    if (not want or want == "") and id ~= 0 then want = "rbxassetid://" .. tostring(id) end
                    if not want or want == "" then want = o and o.anim[key] end
                    if want and a.AnimationId ~= want then
                        a.AnimationId = want
                        changed = true
                    end
                end
            end
        end
    end
    if changed then
        -- script Animate menyimpan animasi di cache -> hentikan track lama & restart script biar animasi baru dipakai
        pcall(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            local an = hum and hum:FindFirstChildOfClass("Animator")
            if an then
                for _, tr in ipairs(an:GetPlayingAnimationTracks()) do tr:Stop(0.1) end
            end
        end)
        if pages.AV and pages.AV.reload then
            pcall(pages.AV.reload, char, animate)
        else
            pcall(function()
                animate.Enabled = false
                task.wait(0.05)
                if animate.Parent then animate.Enabled = true end
            end)
        end
    end
end

-- ===== ENGINE COPY (diport dari script Copyava yang sudah jalan) =====
-- Bukan lagi Humanoid:ApplyDescription (sering gagal/tidak kelihatan kalau dipanggil dari client).
-- Cara kerja: bikin "dummy" dari HumanoidDescription target, lalu body part / baju / warna kulit /
-- aksesori / ukuran badan dummy dipasang ke karakter kamu sendiri.
local AV = {}
pages.AV = AV
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
-- ===== ENGINE BARU: ubah tampilan SECARA LANGSUNG (in-place) =====
-- Body part TIDAK dihapus / diganti lagi (itu yang bikin joint putus -> karakter mati -> avatar balik ke asli).
-- Mesh, tekstur, ukuran, attachment dan joint tiap body part cuma disamakan dengan dummy target.
-- Kalau executor tidak bisa ubah mesh, baru part itu diganti lewat ReplaceBodyPartR15 (joint disambung ulang).
AV.SKINKIDS = { SurfaceAppearance = true, Decal = true, Texture = true, FaceControls = true, WrapTarget = true, WrapLayer = true, Bone = true }

function AV.skin(mine, theirs)
    if not (mine and theirs and mine:IsA("MeshPart") and theirs:IsA("MeshPart")) then return false end
    local same = (mine.MeshId == theirs.MeshId)
    if not same then
        pcall(function() mine:ApplyMesh(theirs) end)
        same = (mine.MeshId == theirs.MeshId)
    end
    if not same then
        pcall(function() mine.MeshId = theirs.MeshId end)
        same = (mine.MeshId == theirs.MeshId)
    end
    if not same then return false end
    pcall(function() mine.TextureID = theirs.TextureID end)
    pcall(function() mine.Size = theirs.Size end)
    pcall(function() mine.Color = theirs.Color end)
    for _, c in ipairs(mine:GetChildren()) do
        if AV.SKINKIDS[c.ClassName] then pcall(function() c:Destroy() end) end
    end
    for _, c in ipairs(theirs:GetChildren()) do
        if AV.SKINKIDS[c.ClassName] then pcall(function() c:Clone().Parent = mine end) end
    end
    for _, a in ipairs(theirs:GetChildren()) do
        if a:IsA("Attachment") then
            local m = mine:FindFirstChild(a.Name)
            if m and m:IsA("Attachment") then
                pcall(function() m.CFrame = a.CFrame end)
            else
                pcall(function() a:Clone().Parent = mine end)
            end
        elseif a:IsA("Motor6D") then
            local m = mine:FindFirstChild(a.Name)
            if m and m:IsA("Motor6D") then
                pcall(function() m.C0 = a.C0 m.C1 = a.C1 end)
            end
        end
    end
    return true
end

-- cadangan: ganti body part yang mesh-nya tidak bisa diubah langsung
function AV.replaceParts(ch, hm, d, names)
    local oR = true
    pcall(function() oR = hm.RequiresNeck end)
    pcall(function() hm.RequiresNeck = false end)
    local stash = Instance.new("Folder")
    for _, name in ipairs(names) do
        local old, dp, en = ch:FindFirstChild(name), d:FindFirstChild(name), AV.R15M[name]
        if old and dp and en then
            local kept = stashExtras(old, stash)
            local new = dp:Clone()
            pcall(function() new.CFrame = old.CFrame end)
            pcall(function() hm:ReplaceBodyPartR15(en, new) end)
            unstashExtras(kept, ch:FindFirstChild(name))
        end
    end
    -- joint yang masih menunjuk ke part dummy disambung ke part milikmu
    for _, j in ipairs(ch:GetDescendants()) do
        if j:IsA("JointInstance") then
            local p0, p1 = j.Part0, j.Part1
            if p0 and not p0:IsDescendantOf(ch) then
                local r = ch:FindFirstChild(p0.Name)
                if r then j.Part0 = r end
            end
            if p1 and not p1:IsDescendantOf(ch) then
                local r = ch:FindFirstChild(p1.Name)
                if r then j.Part1 = r end
            end
        end
    end
    pcall(function() stash:Destroy() end)
    task.delay(1.5, function()
        if not (hm and hm.Parent) then return end
        local neckOk = false
        for _, j in ipairs(ch:GetDescendants()) do
            if j:IsA("Motor6D") and j.Name == "Neck" and j.Part0 and j.Part1
                and j.Part0:IsDescendantOf(ch) and j.Part1:IsDescendantOf(ch) then neckOk = true break end
        end
        if neckOk then pcall(function() hm.RequiresNeck = oR end) end
    end)
end

function AV.isGameItem(t)
    if t:FindFirstChildOfClass("Script") or t:FindFirstChildOfClass("LocalScript") then return true end
    for _, x in ipairs(t:GetDescendants()) do
        if x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam") or x:IsA("Fire") or x:IsA("Smoke")
            or x:IsA("Sparkles") or x:IsA("Light") then return true end
    end
    return false
end

function AV.core(ch, dm, hm)
    local iR = ch:FindFirstChild("UpperTorso") ~= nil
    if hm and ch == player.Character then pcall(function() hm:UnequipTools() end) end

    -- dummy target ditaruh jauh di workspace (di-anchor) supaya aset & skala selesai dimuat
    ch.Archivable = true
    dm.Archivable = true
    local d = dm:Clone()
    pcall(function() d:PivotTo(CFrame.new(0, 6000, 0)) end)
    for _, x in ipairs(d:GetDescendants()) do
        if x:IsA("BasePart") then x.Anchored = true end
    end
    d.Parent = workspace
    local dHm = d:FindFirstChildOfClass("Humanoid")
    task.wait(0.2)

    -- 1) bersihkan baju / aksesori lama (item katalog UHCat & item bawaan game yang punya script / efek tetap)
    for _, t in ipairs(ch:GetChildren()) do
        local isCat = t:GetAttribute("UHCat")
        if t:IsA("Shirt") or t:IsA("Pants") or t:IsA("ShirtGraphic") or t:IsA("BodyColors") then
            if not isCat then t:Destroy() end
        elseif t:IsA("CharacterMesh") then
            if not isCat then t:Destroy() end
        elseif t:IsA("BasePart") and t:GetAttribute("CCI") and not isCat then
            t:Destroy()
        elseif t:IsA("Accessory") and not isCat and not AV.isGameItem(t) then
            t:Destroy()
        end
    end

    -- 2) badan
    if iR then
        local failed = {}
        for _, name in ipairs(R15_PARTS) do
            local mine, theirs = ch:FindFirstChild(name), d:FindFirstChild(name)
            if mine and theirs and not AV.skin(mine, theirs) then table.insert(failed, name) end
        end
        if #failed > 0 and hm then AV.replaceParts(ch, hm, d, failed) end
        if hm and dHm then pcall(function() hm.HipHeight = dHm.HipHeight end) end
    else
        for _, name in ipairs(R6_PARTS) do
            local m, dp = ch:FindFirstChild(name), d:FindFirstChild(name)
            if m and dp and m:IsA("BasePart") then pcall(function() m.Color = dp.Color end) end
        end
        for _, cm in ipairs(d:GetChildren()) do
            if cm:IsA("CharacterMesh") then cm:Clone().Parent = ch end
        end
        local mH, dH = ch:FindFirstChild("Head"), d:FindFirstChild("Head")
        if mH and dH then
            for _, c in ipairs(mH:GetChildren()) do
                if c:IsA("DataModelMesh") or c:IsA("Decal") then c:Destroy() end
            end
            for _, c in ipairs(dH:GetChildren()) do
                if c:IsA("DataModelMesh") or c:IsA("Decal") then c:Clone().Parent = mH end
            end
        end
    end

    -- 3) aksesori, baju, celana, warna kulit dari dummy
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

    pcall(function() d:Destroy() end)
end

-- script Animate baru (clone) supaya animasi yang diganti PASTI dipakai (cache script lama dibuang)
function AV.reload(char, animate)
    animate = animate or (char and char:FindFirstChild("Animate"))
    if not animate then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if an then
        for _, tr in ipairs(an:GetPlayingAnimationTracks()) do pcall(function() tr:Stop(0.1) end) end
    end
    local ok = pcall(function()
        local new = animate:Clone()
        animate:Destroy()
        new.Parent = char
    end)
    if not ok then
        pcall(function()
            animate.Enabled = false
            task.wait(0.05)
            if animate.Parent then animate.Enabled = true end
        end)
    end
end

-- ikuti animasi LIVE target (emote / tarian / animasi game) selama mode copy aktif.
-- Animasi inti (idle / jalan / lari dll) sudah ikut lewat script Animate; yang lain dimainkan ulang di sini.
function AV.mirror(target)
    CS.mirrorToken = (CS.mirrorToken or 0) + 1
    local tk = CS.mirrorToken
    if not target then return end
    task.spawn(function()
        local mine, lastChar = {}, nil
        local function stopAll()
            for id, t in pairs(mine) do pcall(function() t:Stop(0.1) end) mine[id] = nil end
        end
        while CS.active and CS.mirrorToken == tk do
            task.wait(0.25)
            local tc = target.Parent and target.Character
            local th = tc and tc:FindFirstChildOfClass("Humanoid")
            local ta = th and th:FindFirstChildOfClass("Animator")
            local mc = player.Character
            local mh = mc and mc:FindFirstChildOfClass("Humanoid")
            local ma = mh and mh:FindFirstChildOfClass("Animator")
            if mc ~= lastChar then stopAll() lastChar = mc end
            if ta and ma and (tc:FindFirstChild("UpperTorso") ~= nil) == (mc:FindFirstChild("UpperTorso") ~= nil) then
                local want = {}
                for _, tr in ipairs(ta:GetPlayingAnimationTracks()) do
                    local a = tr.Animation
                    local id = a and a.AnimationId
                    if id and id ~= "" and not (CS.core and CS.core[id]) and tr.IsPlaying then want[id] = tr end
                end
                for id, tr in pairs(want) do
                    local t = mine[id]
                    if not t then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = id
                        local ok, nt = pcall(function() return ma:LoadAnimation(anim) end)
                        if ok and nt then
                            pcall(function() nt.Priority = tr.Priority end)
                            pcall(function() nt.Looped = tr.Looped end)
                            pcall(function() nt:Play(0.1, 1, tr.Speed) end)
                            pcall(function() nt.TimePosition = tr.TimePosition end)
                            mine[id] = nt
                        end
                    else
                        pcall(function() t:AdjustSpeed(tr.Speed) end)
                    end
                end
                for id, t in pairs(mine) do
                    if not want[id] then pcall(function() t:Stop(0.1) end) mine[id] = nil end
                end
            elseif next(mine) then
                stopAll()
            end
        end
        stopAll()
    end)
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

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local wasAnch = hrp and hrp.Anchored
    if hrp and char == player.Character then pcall(function() hrp.Anchored = true end) end
    local okA, errA = pcall(AV.core, char, dummy, hum)
    pcall(function() dummy:Destroy() end)
    if hrp then pcall(function() if hrp.Parent then hrp.Anchored = wasAnch and true or false end end) end
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
    pcall(syncAnimations, char, desc, CS.anim)
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

-- ambil animasi yang sedang dipakai target dari script Animate-nya (hanya kalau tipe rig sama R15/R6)
function AV.liveAnims(target, mine)
    local tc = target and target.Character
    local ta = tc and tc:FindFirstChild("Animate")
    if not ta or not mine then return nil end
    if (tc:FindFirstChild("UpperTorso") ~= nil) ~= (mine:FindFirstChild("UpperTorso") ~= nil) then return nil end
    local out, any = {}, false
    for _, slot in ipairs(ANIM_SLOTS) do
        local folder = ta:FindFirstChild(slot.folder)
        if folder then
            for _, kid in ipairs(slot.kids) do
                local a = folder:FindFirstChild(kid)
                if a and a:IsA("Animation") and a.AnimationId ~= "" then
                    out[slot.folder .. "/" .. kid] = a.AnimationId
                    any = true
                end
            end
        end
    end
    return any and out or nil
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
        local prevDesc, prevActive, prevAnim = CS.desc, CS.active, CS.anim
        CS.desc = desc
        CS.anim = AV.liveAnims(target, char)
        CS.target = target
        CS.core = {}
        for _, v in pairs(CS.anim or {}) do CS.core[v] = true end
        for _, slot in ipairs(ANIM_SLOTS) do
            local id = 0
            if slot.prop then pcall(function() id = desc[slot.prop] or 0 end) end
            if id ~= 0 then CS.core["rbxassetid://" .. tostring(id)] = true end
        end
        CS.active = true
        local ok, err = applyDescription(char, hum, desc)
        if not ok then
            local dead = player.Character ~= char or not hum.Parent or hum.Health <= 0
            if not dead then CS.desc, CS.active, CS.anim = prevDesc, prevActive, prevAnim end
            return false, tostring(err)
        end

        pcall(function()
            hum.Died:Connect(function()
                warn("[UniversalHub] karakter mati setelah copy avatar -> avatar akan dipasang ulang saat respawn")
            end)
        end)
        if pages.C and pages.C.reapply then pcall(pages.C.reapply) end

        AV.watch()
        AV.mirror(target)
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
        CS.mirrorToken = (CS.mirrorToken or 0) + 1
        local ok, err = AV.apply(char, hum, desc)
        if not ok then
            CS.active, CS.desc = true, wasDesc
            AV.watch()
            AV.mirror(CS.target)
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

        CS.anim = nil
        CS.core = nil
        CS.target = nil
        if animate then pcall(AV.reload, char, animate) end
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
    -- kalau karakter terus mati setelah dipasangi avatar copy (mis. game menolak perubahan avatar) -> berhenti, jangan loop
    local now = os.clock()
    CS.respawns = CS.respawns or {}
    local keep = {}
    for _, t in ipairs(CS.respawns) do
        if now - t < 40 then table.insert(keep, t) end
    end
    CS.respawns = keep
    table.insert(CS.respawns, now)
    if #CS.respawns > 3 then
        CS.active = false
        CS.desc = nil
        CS.watchToken = (CS.watchToken or 0) + 1
        CS.mirrorToken = (CS.mirrorToken or 0) + 1
        warn("[UniversalHub] copy avatar dihentikan: karakter terus mati/respawn setelah copy (kemungkinan game menolak perubahan avatar)")
        return
    end
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
        AV.mirror(CS.target)
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

-- ==================== FLING PLAYER (MULTI TARGET + 14 METODE) ====================
--  Pilih banyak target (centang), pilih metode, tekan FLING. Cara kerja (SkidFling asli):
--  badanmu dipindah tepat ke badan target tiap frame dengan kecepatan super besar -> tabrakan -> target mental.
--  Tiap target maksimal 2 detik, berhenti sendiri begitu target melesat (>500 stud/detik), lalu kamu balik ke posisi awal.
--  Nama MERAH di daftar = target itu tidak bisa ditabrak (CanCollide mati / Massless / Anchored) -> fling sulit berhasil.
do
sectionHeader("💥 FLING PLAYER", 70)

local Debris = game:GetService("Debris")
local FL = { on = false, token = 0, hits = 0, power = 10, loop = true, back = true,
    method = "BodyVelocity", sel = {}, oldPos = nil, oldFall = nil, open = false, alive = true }
local METHODS = { "BodyVelocity", "FlingNEW", "BodyThrust", "BodyForce", "VectorForce", "LinearVelocity",
    "ExplodeFling", "RocketFling", "TorqueFling", "ImpulseFling1", "ImpulseFling2", "AlignPositionFling",
    "PhysicsRepFling", "NaNFling" }
local M = {}
local flingBtn, flingInfo, stopFling

-- ---------- tombol & info ----------
local targetBtn = makePlayerButton("🎯 PILIH TARGET (0)", 71)
flingBtn = makePlayerButton("💥 FLING • OFF", 73)
local methodBtn = makePlayerButton("⚙️ METODE: BodyVelocity", 74)

local function countSel()
    local n = 0
    for _ in pairs(FL.sel) do n = n + 1 end
    return n
end

local function setTargetBtn()
    local n = countSel()
    targetBtn.Text = (FL.open and "🎯 TUTUP PILIHAN (" or "🎯 PILIH TARGET (") .. n .. ")"
end

local function setFlingBtn()
    if FL.on then
        flingBtn.Text = "💥 FLINGING " .. (FL.ovr and 1 or countSel()) .. " TARGET"
        flingBtn.BackgroundColor3 = ON_COLOR
    else
        flingBtn.Text = "💥 FLING • OFF"
        flingBtn.BackgroundColor3 = BG_BUTTON
    end
end

local function flingFlash(text)
    flingBtn.Text = text
    flingBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
    task.delay(1.5, setFlingBtn)
end

flingInfo = Instance.new("TextLabel")
flingInfo.LayoutOrder = 78
flingInfo.Size = UDim2.new(1, 0, 0, 18)
flingInfo.BackgroundTransparency = 1
flingInfo.Text = ""
flingInfo.TextSize = 10
flingInfo.Font = Enum.Font.GothamBold
flingInfo.TextColor3 = GREEN
flingInfo.TextTruncate = Enum.TextTruncate.AtEnd
flingInfo.Visible = false
flingInfo.Parent = playerPage

local function say(text, color)
    flingInfo.Text = text
    flingInfo.TextColor3 = color or GREY
    flingInfo.Visible = true
end

-- ---------- baris POWER ----------
local powerRow = Instance.new("Frame")
powerRow.LayoutOrder = 75
powerRow.Size = UDim2.new(1, 0, 0, 30)
powerRow.BackgroundColor3 = BG_DARK
powerRow.BorderSizePixel = 0
powerRow.Parent = playerPage
corner(powerRow, 8)
newLabel(powerRow, "💪 POWER (1 - 100)", 10, Enum.Font.GothamBold, WHITE,
    UDim2.new(0, 8, 0, 0), UDim2.new(1, -76, 1, 0), Enum.TextXAlignment.Left)
local powerBox = Instance.new("TextBox")
powerBox.Size = UDim2.new(0, 56, 0, 22)
powerBox.Position = UDim2.new(1, -62, 0.5, -11)
powerBox.BackgroundColor3 = BG_BUTTON
powerBox.Text = "10"
powerBox.TextSize = 12
powerBox.Font = Enum.Font.GothamBold
powerBox.TextColor3 = WHITE
powerBox.ClearTextOnFocus = false
powerBox.Parent = powerRow
corner(powerBox, 6)
powerBox.FocusLost:Connect(function()
    FL.power = math.clamp(tonumber(powerBox.Text) or FL.power, 1, 100)
    powerBox.Text = tostring(FL.power)
end)

-- ---------- toggle LOOP & BALIK ----------
local loopBtn = makePlayerButton("🔁 LOOP • ON", 76)
loopBtn.BackgroundColor3 = ON_COLOR
loopBtn.MouseButton1Click:Connect(function()
    FL.loop = not FL.loop
    loopBtn.Text = FL.loop and "🔁 LOOP • ON" or "🔁 LOOP • OFF"
    loopBtn.BackgroundColor3 = FL.loop and ON_COLOR or BG_BUTTON
end)

local backBtn = makePlayerButton("🏠 BALIK KE POSISI AWAL • ON", 77)
backBtn.BackgroundColor3 = ON_COLOR
backBtn.MouseButton1Click:Connect(function()
    FL.back = not FL.back
    backBtn.Text = FL.back and "🏠 BALIK KE POSISI AWAL • ON" or "🏠 BALIK KE POSISI AWAL • OFF"
    backBtn.BackgroundColor3 = FL.back and ON_COLOR or BG_BUTTON
end)

methodBtn.MouseButton1Click:Connect(function()
    local idx = table.find(METHODS, FL.method) or 1
    FL.method = METHODS[idx % #METHODS + 1]
    methodBtn.Text = "⚙️ METODE: " .. FL.method
end)

-- ---------- daftar target (centang banyak player) ----------
local panel = Instance.new("Frame")
panel.LayoutOrder = 72
panel.Size = UDim2.new(1, 0, 0, 190)
panel.BackgroundColor3 = BG_DARK
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = playerPage
corner(panel, 8)
stroke(panel, BORDER_BLUE, 1)

local search = Instance.new("TextBox")
search.Size = UDim2.new(1, -16, 0, 22)
search.Position = UDim2.new(0, 8, 0, 6)
search.BackgroundColor3 = BG_BUTTON
search.PlaceholderText = "🔍 cari nama..."
search.PlaceholderColor3 = GREY
search.Text = ""
search.TextSize = 10
search.Font = Enum.Font.GothamBold
search.TextColor3 = WHITE
search.ClearTextOnFocus = false
search.Parent = panel
corner(search, 6)

local function smallBtn(text, xs, xo)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -12, 0, 22)
    b.Position = UDim2.new(xs, xo, 0, 32)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = panel
    corner(b, 6)
    return b
end
local allBtn = smallBtn("☑ PILIH SEMUA", 0, 8)
local noneBtn = smallBtn("☐ BATAL SEMUA", 0.5, 4)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -62)
scroll.Position = UDim2.new(0, 4, 0, 58)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = ACCENT_BLUE
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel
local sl = Instance.new("UIListLayout")
sl.Padding = UDim.new(0, 3)
sl.SortOrder = Enum.SortOrder.Name
sl.Parent = scroll

local function noCollide(pl)
    local hrp = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
    return hrp ~= nil and (hrp.CanCollide == false or hrp.Massless == true or hrp.Anchored == true)
end

local function nameText(pl)
    return string.format('<font color="#%s">%s</font> <font color="#999999">@%s</font>',
        noCollide(pl) and "FF5050" or "FFFFFF", pl.DisplayName, pl.Name)
end

local rowLabels = {}
local refreshList
refreshList = function()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    rowLabels = {}
    local q = string.lower(search.Text or "")
    local shown = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local hay = string.lower(p.Name .. " " .. p.DisplayName)
            if q == "" or string.find(hay, q, 1, true) then
                shown = shown + 1
                local isSel = FL.sel[p.Name] ~= nil

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

                local lb = newLabel(row, nameText(p), 10, Enum.Font.GothamBold, WHITE,
                    UDim2.new(0, 34, 0, 0), UDim2.new(1, -64, 1, 0), Enum.TextXAlignment.Left)
                lb.RichText = true
                lb.TextTruncate = Enum.TextTruncate.AtEnd
                rowLabels[p.Name] = { lb, p }

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
                    if FL.sel[p.Name] then
                        FL.sel[p.Name] = nil
                    else
                        FL.sel[p.Name] = p
                    end
                    local on = FL.sel[p.Name] ~= nil
                    check.Visible = on
                    row.BackgroundColor3 = on and ON_COLOR or BG_BUTTON
                    setTargetBtn()
                    if FL.on then setFlingBtn() end
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
    setTargetBtn()
end

targetBtn.MouseButton1Click:Connect(function()
    FL.open = not FL.open
    panel.Visible = FL.open
    if FL.open then refreshList() else setTargetBtn() end
end)
search:GetPropertyChangedSignal("Text"):Connect(function()
    if FL.open then refreshList() end
end)
allBtn.MouseButton1Click:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then FL.sel[p.Name] = p end
    end
    refreshList()
end)
noneBtn.MouseButton1Click:Connect(function()
    FL.sel = {}
    refreshList()
end)
Players.PlayerAdded:Connect(function()
    if FL.open then refreshList() end
end)
Players.PlayerRemoving:Connect(function(p)
    FL.sel[p.Name] = nil
    task.defer(function()
        if FL.open then refreshList() else setTargetBtn() end
    end)
end)

-- warna merah di nama diperbarui tiap 1 detik selama daftar terbuka
task.spawn(function()
    while FL.alive do
        task.wait(1)
        if FL.open then
            for _, d in pairs(rowLabels) do
                if d[1].Parent and d[2].Parent == Players then d[1].Text = nameText(d[2]) end
            end
        end
    end
end)

-- ---------- 14 METODE (dipanggil dengan: badanmu, power, arah, badan target) ----------
local function mk(class)
    local o = Instance.new(class)
    o.Name = "_FlingObj" -- semua objek fling diberi nama ini, jadi pembersihan tidak menyentuh fitur lain
    return o
end

local function destroyBody(b)
    if type(b) == "table" then
        for _, o in ipairs(b) do pcall(function() o:Destroy() end) end
    elseif b then
        pcall(function() b:Destroy() end)
    end
end

M.BodyVelocity = function(root, power, dir)
    local bv = mk("BodyVelocity")
    bv.Velocity = dir * power * 100
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root
    return bv
end

M.BodyThrust = function(root, power, dir)
    local bt = mk("BodyThrust")
    bt.Force = dir * power * 500
    bt.Location = root.Position + Vector3.new(0, 1, 0)
    bt.Parent = root
    return bt
end

M.BodyForce = function(root, power, dir)
    local bf = mk("BodyForce")
    bf.Force = dir * power * 500
    bf.Parent = root
    return bf
end

M.VectorForce = function(root, power, dir)
    local att = mk("Attachment")
    att.Parent = root
    local vf = mk("VectorForce")
    vf.Attachment0 = att
    vf.RelativeTo = Enum.ActuatorRelativeTo.World
    vf.Force = dir * power * 500
    vf.Parent = root
    return { vf, att }
end

M.LinearVelocity = function(root, power, dir)
    local att = mk("Attachment")
    att.Parent = root
    local lv = mk("LinearVelocity")
    lv.Attachment0 = att
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.VectorVelocity = dir * power * 100
    lv.MaxForce = 9e9
    lv.Parent = root
    return { lv, att }
end

M.ExplodeFling = function(root, power, dir)
    local bf = mk("BodyForce")
    bf.Force = dir * power * 999999
    bf.Parent = root
    local bv = mk("BodyVelocity")
    bv.Velocity = Vector3.new(math.random(-1000, 1000), math.random(500, 1500), math.random(-1000, 1000))
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root
    Debris:AddItem(bf, 0.3)
    Debris:AddItem(bv, 0.3)
    return { bf, bv }
end

M.NaNFling = function(root, power, dir, tRoot)
    if not tRoot then return nil end
    local nan = 0 / 0
    local nanV = Vector3.new(nan, nan, nan)
    local hum = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    root.CFrame = tRoot.CFrame
    root.AssemblyLinearVelocity = nanV
    root.AssemblyAngularVelocity = nanV
    pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tRoot) end)
    return nil
end

M.PhysicsRepFling = function(root, power, dir, tRoot)
    if not sethiddenproperty or not tRoot then return nil end
    pcall(function() sethiddenproperty(root, "PhysicsRepRootPart", tRoot) end)
    root.CFrame = tRoot.CFrame
    root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
    root.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
    return nil
end

M.FlingNEW = function(root, power, dir, tRoot)
    if not tRoot then return nil end
    pcall(function()
        sethiddenproperty(root, "PhysicsRepRootPart", tRoot)
        sethiddenproperty(player, "SimulationRadius", math.huge)
    end)
    local bodies = {}
    local nan = 0 / 0
    for i = 1, 100 do
        local bv = mk("BodyVelocity")
        bv.Velocity = Vector3.new(nan, nan, nan)
        bv.MaxForce = Vector3.new(9e30, 9e30, 9e30)
        bv.Parent = root
        table.insert(bodies, bv)
        Debris:AddItem(bv, 0.05 + i * 0.001)
    end
    return bodies
end

M.RocketFling = function(root, power, dir)
    local rp = mk("RocketPropulsion")
    rp.Parent = root
    local tp = Instance.new("Part")
    tp.Name = "_FlingObj"
    tp.Position = root.Position + dir * 100
    tp.Anchored = true
    tp.CanCollide = false
    tp.Parent = workspace
    rp.Target = tp
    rp.MaxThrust = power * 1000
    rp.ThrustP = 1e5
    rp.ThrustD = math.huge
    rp:Fire()
    Debris:AddItem(rp, 0.5)
    Debris:AddItem(tp, 0.5)
    return { rp, tp }
end

M.TorqueFling = function(root, power, dir)
    local att = mk("Attachment")
    att.Parent = root
    local tq = mk("Torque")
    tq.Attachment0 = att
    tq.RelativeTo = Enum.ActuatorRelativeTo.World
    tq.Torque = Vector3.new(power * 10000, power * 10000, power * 10000)
    tq.Parent = root
    Debris:AddItem(tq, 0.5)
    return { tq, att }
end

M.ImpulseFling1 = function(root, power, dir)
    local bodies = {}
    for i = 1, 100 do
        local bv = mk("BodyVelocity")
        bv.Velocity = Vector3.new(9e9, 9e9, 9e9)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = root
        table.insert(bodies, bv)
        Debris:AddItem(bv, 0.05)
    end
    return bodies
end

-- 40 objek per jenis (bukan 100) supaya HP tidak nge-lag
M.ImpulseFling2 = function(root, power, dir)
    local bodies = {}
    for i = 1, 40 do
        local bv = mk("BodyVelocity")
        bv.Velocity = dir * power * 9e9
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = root
        table.insert(bodies, bv)
        Debris:AddItem(bv, 0.05 + i * 0.001)

        local bf = mk("BodyForce")
        bf.Force = dir * power * 9e9
        bf.Parent = root
        table.insert(bodies, bf)
        Debris:AddItem(bf, 0.1 + i * 0.01)

        local bt = mk("BodyThrust")
        bt.Force = dir * power * 9e9
        bt.Location = root.Position + Vector3.new(0, 1, 0) * i
        bt.Parent = root
        table.insert(bodies, bt)
        Debris:AddItem(bt, 0.1 + i * 0.01)

        local gy = mk("BodyGyro")
        gy.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        gy.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(1, 1, 1) * i)
        gy.Parent = root
        table.insert(bodies, gy)
        Debris:AddItem(gy, 0.1 + i * 0.01)

        local bp = mk("BodyPosition")
        bp.Position = root.Position + dir * 9e9 * i
        bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bp.Parent = root
        table.insert(bodies, bp)
        Debris:AddItem(bp, 0.1 + i * 0.01)
    end
    return bodies
end

M.AlignPositionFling = function(root, power, dir)
    local att = mk("Attachment")
    att.Parent = root
    local tp = Instance.new("Part")
    tp.Name = "_FlingObj"
    tp.Position = root.Position + dir * 100
    tp.Anchored = true
    tp.CanCollide = false
    tp.Parent = workspace
    local att2 = mk("Attachment")
    att2.Parent = tp
    local al = mk("AlignPosition")
    al.Attachment0 = att
    al.Attachment1 = att2
    al.RigidityEnabled = false
    al.MaxForce = power * 10000
    al.Responsiveness = 200
    al.Parent = root
    Debris:AddItem(al, 0.5)
    Debris:AddItem(tp, 0.5)
    return { al, att, tp }
end

-- ---------- bantu: tegakkan karakter (anti tengkurap) & kembali ke posisi awal ----------
local BAD_STATES = { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Seated }
local function setBadStates(hum, enabled)
    for _, st in ipairs(BAD_STATES) do
        pcall(function() hum:SetStateEnabled(st, enabled) end)
    end
end

local function uprightAt(root, pos, look)
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
    root.CFrame = CFrame.new(pos, pos + flat.Unit)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function zeroAll(char)
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function goBack(char, root, hum)
    if FL.back and FL.oldPos then
        local t1 = tick()
        repeat
            uprightAt(root, FL.oldPos.Position + Vector3.new(0, 0.5, 0), FL.oldPos.LookVector)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
            zeroAll(char)
            task.wait()
        until (root.Position - FL.oldPos.Position).Magnitude < 25 or tick() - t1 > 3
    else
        uprightAt(root, root.Position, root.CFrame.LookVector)
        zeroAll(char)
    end
end

local function cleanChar(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name == "_FlingObj" then pcall(function() d:Destroy() end) end
    end
    local r = char:FindFirstChild("HumanoidRootPart")
    if r then
        pcall(function() sethiddenproperty(r, "PhysicsRepRootPart", r) end)
    end
end

-- ---------- SkidFling: 1 target ----------
-- return true kalau target mental
local function skid(tp)
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    local tc = tp.Character
    if not (char and hum and root and tc) then return false end

    local thum = tc:FindFirstChildOfClass("Humanoid")
    local troot = thum and thum.RootPart
    local thead = tc:FindFirstChild("Head")
    local acc = tc:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")
    local base = troot or thead or handle
    if not base then
        say("⚠️ @" .. tp.Name .. " tidak punya part valid", GREY)
        return false
    end
    if thum and thum.Sit then
        say("⚠️ @" .. tp.Name .. " sedang duduk", GREY)
        return false
    end

    if root.AssemblyLinearVelocity.Magnitude < 50 then FL.oldPos = root.CFrame end
    say("💥 " .. FL.method .. " → @" .. tp.Name .. " • mental: " .. FL.hits, GREEN)

    local function fpos(pos, ang)
        char:PivotTo(CFrame.new(base.Position) * pos * ang)
        root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
        root.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
    end

    local method = M[FL.method] or M.BodyVelocity
    local body = method(root, FL.power, Vector3.new(0, 1, 0), troot or base)

    local flung, angle, t0 = false, 0, tick()
    repeat
        if not (FL.on and root.Parent and base.Parent and tp.Parent == Players and (not thum or thum.Parent)) then break end
        local moveDir = thum and thum.MoveDirection or Vector3.zero
        local speed = thum and thum.WalkSpeed or 16
        local vel = base.AssemblyLinearVelocity.Magnitude
        if vel > 500 then
            flung = true
            break
        end

        if vel < 50 then
            angle = angle + 100
            local ang = CFrame.Angles(math.rad(angle), 0, 0)
            local push = moveDir * (vel / 1.25)
            local seq = {
                CFrame.new(0, 1.5, 0) + push, CFrame.new(0, -1.5, 0) + push,
                CFrame.new(0, 1.5, 0) + push, CFrame.new(0, -1.5, 0) + push,
                CFrame.new(0, 1.5, 0) + moveDir, CFrame.new(0, -1.5, 0) + moveDir,
            }
            for _, o in ipairs(seq) do
                fpos(o, ang)
                task.wait()
            end
        else
            local high = CFrame.Angles(math.rad(90), 0, 0)
            local zero = CFrame.new()
            local seq = {
                { CFrame.new(0, 1.5, speed), high }, { CFrame.new(0, -1.5, -speed), zero },
                { CFrame.new(0, 1.5, speed), high }, { CFrame.new(0, -1.5, 0), high },
                { CFrame.new(0, -1.5, 0), zero }, { CFrame.new(0, -1.5, 0), high },
                { CFrame.new(0, -1.5, 0), zero },
            }
            for _, sp in ipairs(seq) do
                fpos(sp[1], sp[2])
                task.wait()
            end
        end
    until tick() - t0 >= 2 or not FL.on

    destroyBody(body)
    cleanChar(char)
    hum.PlatformStand = false
    goBack(char, root, hum)
    return flung
end

-- ---------- start / stop ----------
local function restoreFall()
    if FL.oldFall ~= nil then
        pcall(function() workspace.FallenPartsDestroyHeight = FL.oldFall end)
        FL.oldFall = nil
    end
end

stopFling = function(msg, color)
    local wasOn = FL.on
    FL.on = false
    FL.ovr = nil
    FL.token = FL.token + 1
    setFlingBtn()
    if msg then
        say(msg, color)
        task.delay(3, function()
            if not FL.on then flingInfo.Visible = false end
        end)
    else
        flingInfo.Visible = false
    end
    if not wasOn then return end
    task.spawn(function()
        local char, hum, root = player.Character, getHumanoid(), getHRP()
        cleanChar(char)
        if char and hum and root then
            hum.PlatformStand = false
            setBadStates(hum, true)
            pcall(goBack, char, root, hum)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        restoreFall()
    end)
end

local function startFling(ovr)
    if FL.on then return end
    if not ovr and countSel() == 0 then
        flingFlash("⚠️ PILIH TARGET DULU!")
        return
    end
    local hum, root = getHumanoid(), getHRP()
    if not hum or not root then
        flingFlash("⚠️ KARAKTER BELUM SIAP")
        return
    end

    FL.ovr = ovr
    FL.on = true
    FL.token = FL.token + 1
    local tk = FL.token
    FL.hits = 0
    FL.oldPos = root.CFrame
    setFlingBtn()
    say("💥 Memulai fling...", GREEN)

    pcall(function()
        FL.oldFall = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = -1e9
    end)
    setBadStates(hum, false)

    task.spawn(function()
        repeat
            local list = {}
            local src = FL.ovr or FL.sel
            for name, pl in pairs(src) do
                if pl and pl.Parent == Players then
                    table.insert(list, pl)
                else
                    src[name] = nil
                end
            end
            setTargetBtn()
            if #list == 0 then break end

            for _, pl in ipairs(list) do
                if not FL.on or FL.token ~= tk then break end
                local ok, res = pcall(skid, pl)
                if not ok then
                    warn("[UniversalHub Fling] " .. tostring(res))
                elseif res then
                    FL.hits = FL.hits + 1
                end
                task.wait(0.1)
            end
            if not FL.loop then break end
            task.wait(0.5)
        until not FL.on or FL.token ~= tk

        if FL.token == tk and FL.on then
            stopFling("✅ Selesai • mental: " .. FL.hits, GREEN)
        end
    end)
end

flingBtn.MouseButton1Click:Connect(function()
    if FL.on then
        stopFling("⏹ Fling dihentikan", GREY)
        return
    end
    startFling(nil)
end)

-- sinkron tampilan tombol FLING PLAYER kalau pengaturan diubah dari TARGET PANEL
local function refreshFlingUI()
    methodBtn.Text = "⚙️ METODE: " .. FL.method
    loopBtn.Text = FL.loop and "🔁 LOOP • ON" or "🔁 LOOP • OFF"
    loopBtn.BackgroundColor3 = FL.loop and ON_COLOR or BG_BUTTON
    backBtn.Text = FL.back and "🏠 BALIK KE POSISI AWAL • ON" or "🏠 BALIK KE POSISI AWAL • OFF"
    backBtn.BackgroundColor3 = FL.back and ON_COLOR or BG_BUTTON
    powerBox.Text = tostring(FL.power)
end
pages.fling = { FL = FL, start = startFling, stop = stopFling, METHODS = METHODS, refresh = refreshFlingUI }

table.insert(cleanupFns, function()
    FL.alive = false
    if FL.on then stopFling() end
end)
player.CharacterAdded:Connect(function()
    if FL.on then
        FL.on = false
        FL.ovr = nil
        FL.token = FL.token + 1
        restoreFall()
        setFlingBtn()
        say("Karaktermu respawn, fling dihentikan", GREY)
    end
end)

setTargetBtn()
end


do
-- ==================== TELEPORT PAGE (10 SLOT + NAMA + HAPUS + COMPASS MATA ANGIN) ====================
-- Fitur:
--   • 💾 SAVE    : simpan posisi sekarang ke slot
--   • 🚀 GO      : teleport ke slot
--   • ✕ HAPUS    : hapus slot kalau salah save
--   • 🏷️ NAMA    : kasih nama custom tiap slot (auto save & load ke file)
--   • 🧭 COMPASS : bulat semi transparan di samping info bar FPS
--                  N = utara dunia Roblox (-Z), E = timur (+X), S = selatan (+Z), W = barat (-X)
--                  Ring muter ikut kamera, jarum ▲ nunjuk waypoint
-- ============================================================
    pages.header(teleportPage, "📍 TELEPORT SLOTS (10)", 0)

    local TPS = {
        slots = {},       -- [i] = { cf = CFrame|nil, name = string }
        selected = nil,   -- nomor slot yang dipantau compass
        savefile = "UniversalHub_tp.json",
        compassGui = nil,
        compassRing = nil,
        compassNeedle = nil,
        compassDist = nil,
        compassName = nil,
        compassConn = nil,
        compassBg = nil,
    }
    pages.TPS = TPS

    -- ============ SAVE / LOAD (nama + posisi + slot terpilih) ============
    function TPS.save()
        if not writefile then return end
        local out = {}
        for i, s in pairs(TPS.slots) do
            if s.cf then
                out[tostring(i)] = {
                    name = s.name or "",
                    pos = { s.cf.X, s.cf.Y, s.cf.Z,
                            s.cf.LookVector.X, s.cf.LookVector.Y, s.cf.LookVector.Z }
                }
            end
        end
        pcall(function()
            writefile(TPS.savefile, HttpService:JSONEncode({
                slots = out,
                selected = TPS.selected,
            }))
        end)
    end

    function TPS.load()
        if not (readfile and isfile) then return end
        pcall(function()
            if isfile(TPS.savefile) then
                local data = HttpService:JSONDecode(readfile(TPS.savefile))
                if type(data) == "table" then
                    if type(data.slots) == "table" then
                        for k, v in pairs(data.slots) do
                            local i = tonumber(k)
                            if i and type(v) == "table" and type(v.pos) == "table" then
                                local p = v.pos
                                local ok, cf = pcall(function()
                                    return CFrame.lookAt(
                                        Vector3.new(p[1], p[2], p[3]),
                                        Vector3.new(p[1] + p[4], p[2] + p[5], p[3] + p[6])
                                    )
                                end)
                                if ok and cf then
                                    TPS.slots[i] = {
                                        cf = cf,
                                        name = tostring(v.name or ""),
                                    }
                                end
                            end
                        end
                    end
                    if tonumber(data.selected) then
                        TPS.selected = tonumber(data.selected)
                    end
                end
            end
        end)
    end

    -- ============ COMPASS MATA ANGIN ============
    -- Konvensi Roblox:
    --   Utara  (N) = -Z   (sudut 0°)
    --   Timur  (E) = +X   (sudut 90°)
    --   Selatan(S) = +Z   (sudut 180°)
    --   Barat  (W) = -X   (sudut 270°)
    local COMPASS_SIZE = 88

    -- helper: hitung bearing (0-360) dari vektor delta dunia
    local function bearingFromDelta(delta)
        -- atan2(X, -Z) supaya -Z = 0°, +X = 90°, +Z = 180°, -X = 270°
        local deg = math.deg(math.atan2(delta.X, -delta.Z))
        return (deg + 360) % 360
    end

    function TPS.buildCompass()
        if TPS.compassGui then TPS.compassGui:Destroy() end

        -- container utama (bulat, semi transparan, di samping kanan info bar FPS)
        local bg = Instance.new("Frame")
        bg.Name = "TP_Compass"
        bg.Size = UDim2.new(0, COMPASS_SIZE, 0, COMPASS_SIZE)
        -- info bar FPS: posisi (0.5, -145, 0, 2), width 290
        -- compass: 0.5 + 145 + 8 = tepat di samping kanan info bar
        bg.Position = UDim2.new(0.5, 145 + 8, 0, 2)
        bg.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
        bg.BackgroundTransparency = 0.25  -- semi transparan
        bg.BorderSizePixel = 0
        bg.ZIndex = 50
        bg.Visible = false
        bg.ClipsDescendants = true
        bg.Parent = screenGui
        corner(bg, COMPASS_SIZE / 2)
        local st = stroke(bg, ACCENT_BLUE, 1.5)
        st.Transparency = 0.4

        -- ring huruf N/E/S/W (MUTER ikut kamera)
        local ring = Instance.new("Frame")
        ring.Name = "Ring"
        ring.Size = UDim2.new(1, 0, 1, 0)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.ZIndex = 51
        ring.Parent = bg
        TPS.compassRing = ring

        local LABELS = {
            { "N",  0,   Color3.fromRGB(255, 90, 90) },     -- Utara = merah
            { "NE", 45,  Color3.fromRGB(255, 210, 120) },
            { "E",  90,  Color3.fromRGB(160, 210, 255) },   -- Timur = biru muda
            { "SE", 135, Color3.fromRGB(255, 210, 120) },
            { "S",  180, Color3.fromRGB(160, 210, 255) },   -- Selatan = biru muda
            { "SW", 225, Color3.fromRGB(255, 210, 120) },
            { "W",  270, Color3.fromRGB(160, 210, 255) },   -- Barat = biru muda
            { "NW", 315, Color3.fromRGB(255, 210, 120) },
        }

        local cx = COMPASS_SIZE / 2
        local radius = COMPASS_SIZE / 2 - 13

        for _, item in ipairs(LABELS) do
            local txt = item[1]
            local angleDeg = item[2]
            local color = item[3]

            local rad = math.rad(angleDeg - 90)  -- 0° = atas ring
            local x = cx + math.cos(rad) * radius
            local y = cx + math.sin(rad) * radius

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0, 16, 0, 12)
            lbl.Position = UDim2.new(0, x - 8, 0, y - 6)
            lbl.BackgroundTransparency = 1
            lbl.Text = txt
            lbl.TextSize = (#txt > 1) and 7 or 10
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextColor3 = color
            lbl.TextStrokeTransparency = 0.6
            lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
            lbl.ZIndex = 52
            lbl.Parent = ring
        end

        -- titik kecil di antara huruf
        for i = 1, 8 do
            local angleDeg = i * 45 - 22.5
            local rad = math.rad(angleDeg - 90)
            local x = cx + math.cos(rad) * radius
            local y = cx + math.sin(rad) * radius
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 2, 0, 2)
            dot.Position = UDim2.new(0, x - 1, 0, y - 1)
            dot.BackgroundColor3 = Color3.fromRGB(130, 140, 165)
            dot.BackgroundTransparency = 0.3
            dot.BorderSizePixel = 0
            dot.ZIndex = 52
            dot.Parent = ring
            corner(dot, 1)
        end

        -- lingkaran dalam tipis
        local innerRing = Instance.new("Frame")
        innerRing.Size = UDim2.new(0, COMPASS_SIZE - 28, 0, COMPASS_SIZE - 28)
        innerRing.Position = UDim2.new(0, 14, 0, 14)
        innerRing.BackgroundTransparency = 1
        innerRing.BorderSizePixel = 0
        innerRing.ZIndex = 51
        innerRing.Parent = bg
        corner(innerRing, (COMPASS_SIZE - 28) / 2)
        local ist = stroke(innerRing, Color3.fromRGB(80, 100, 140), 1)
        ist.Transparency = 0.65

        -- jarum ▲ (TETAP di tengah, hanya rotasi yang berubah)
        local needle = Instance.new("TextLabel")
        needle.Name = "Needle"
        needle.Size = UDim2.new(0, 20, 0, 20)
        needle.Position = UDim2.new(0.5, -10, 0.5, -10)
        needle.BackgroundTransparency = 1
        needle.Text = "▲"
        needle.TextSize = 16
        needle.Font = Enum.Font.GothamBlack
        needle.TextColor3 = Color3.fromRGB(255, 220, 100)
        needle.TextStrokeTransparency = 0.4
        needle.TextStrokeColor3 = Color3.new(0, 0, 0)
        needle.ZIndex = 53
        needle.Parent = bg
        TPS.compassNeedle = needle

        -- titik pusat
        local centerDot = Instance.new("Frame")
        centerDot.Size = UDim2.new(0, 4, 0, 4)
        centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
        centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        centerDot.BackgroundTransparency = 0.2
        centerDot.BorderSizePixel = 0
        centerDot.ZIndex = 54
        centerDot.Parent = bg
        corner(centerDot, 2)

        -- jarak (di bawah compass)
        local dist = Instance.new("TextLabel")
        dist.Name = "Dist"
        dist.Size = UDim2.new(0, COMPASS_SIZE + 30, 0, 14)
        dist.Position = UDim2.new(0, -15, 1, 3)
        dist.BackgroundTransparency = 1
        dist.Text = "0m"
        dist.TextSize = 10
        dist.Font = Enum.Font.GothamBold
        dist.TextColor3 = GREEN
        dist.TextStrokeTransparency = 0.5
        dist.TextStrokeColor3 = Color3.new(0, 0, 0)
        dist.TextXAlignment = Enum.TextXAlignment.Center
        dist.ZIndex = 51
        dist.Parent = bg
        TPS.compassDist = dist

        -- nama slot (di bawah jarak)
        local nm = Instance.new("TextLabel")
        nm.Name = "Name"
        nm.Size = UDim2.new(0, COMPASS_SIZE + 30, 0, 12)
        nm.Position = UDim2.new(0, -15, 1, 17)
        nm.BackgroundTransparency = 1
        nm.Text = ""
        nm.TextSize = 9
        nm.Font = Enum.Font.GothamBold
        nm.TextColor3 = Color3.fromRGB(200, 210, 230)
        nm.TextStrokeTransparency = 0.55
        nm.TextStrokeColor3 = Color3.new(0, 0, 0)
        nm.TextTruncate = Enum.TextTruncate.AtEnd
        nm.TextXAlignment = Enum.TextXAlignment.Center
        nm.ZIndex = 51
        nm.Parent = bg
        TPS.compassName = nm

        TPS.compassGui = bg
        TPS.compassBg = bg
    end

    function TPS.updateCompass()
        if not TPS.compassGui or not TPS.compassGui.Visible then return end
        local slot = TPS.selected and TPS.slots[TPS.selected]
        if not slot or not slot.cf then
            TPS.compassGui.Visible = false
            return
        end
        local hrp = getHRP()
        if not hrp then return end

        local target = slot.cf.Position
        local myPos = hrp.Position
        local delta = target - myPos
        local dist = delta.Magnitude
        local cam = workspace.CurrentCamera

        -- BEARING WAYPOINT (0-360, 0=N, 90=E, 180=S, 270=W)
        local bearing = bearingFromDelta(delta)

        -- BEARING KAMERA (global)
        local camBearing = 0
        if cam then
            local look = cam.CFrame.LookVector
            if Vector2.new(look.X, look.Z).Magnitude > 0.01 then
                camBearing = bearingFromDelta(Vector3.new(look.X, 0, look.Z))
            end
        end

        -- RING MUTER: N selalu menunjuk utara dunia relatif kamera
        if TPS.compassRing then
            TPS.compassRing.Rotation = -camBearing
        end

        -- JARUM: selisih sudut waypoint vs kamera
        local relAngle = (bearing - camBearing + 360) % 360
        if TPS.compassNeedle then
            TPS.compassNeedle.Rotation = relAngle
        end

        -- jarak + warna
        TPS.compassDist.Text = (dist >= 1000) and (string.format("%.1fK", dist / 1000) .. "m")
                                or (string.format("%d", math.floor(dist)) .. "m")
        TPS.compassDist.TextColor3 = (dist < 50 and GREEN)
                                    or (dist < 200 and Color3.fromRGB(250, 204, 21))
                                    or RED

        TPS.compassName.Text = (slot.name ~= "") and slot.name or ("SLOT " .. TPS.selected)
    end

    -- loop update compass (RenderStepped, ringan)
    TPS.compassConn = RunService.RenderStepped:Connect(function()
        if TPS.selected then
            if not TPS.compassGui then TPS.buildCompass() end
            if TPS.compassGui.Visible ~= true then TPS.compassGui.Visible = true end
            TPS.updateCompass()
        else
            if TPS.compassGui and TPS.compassGui.Visible then
                TPS.compassGui.Visible = false
            end
        end
    end)
    table.insert(cleanupFns, function()
        if TPS.compassConn then TPS.compassConn:Disconnect() end
        if TPS.compassGui then TPS.compassGui:Destroy() end
    end)

    -- ============ UI TIAP SLOT ============
    local slotUIRefs = {}

    local function makeSlot(i)
        local slot = TPS.slots[i] or { cf = nil, name = "" }
        TPS.slots[i] = slot

        local row = Instance.new("Frame")
        row.Name = "Slot" .. i
        row.LayoutOrder = i
        row.Size = UDim2.new(1, 0, 0, 52)
        row.BackgroundColor3 = BG_DARK
        row.BorderSizePixel = 0
        row.Parent = teleportPage
        corner(row, 8)
        local hl = stroke(row, BORDER_BLUE, 1)

        newLabel(row, "SLOT " .. i, 10, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 8, 0, 3), UDim2.new(0, 60, 0, 16), Enum.TextXAlignment.Left)

        -- tombol compass
        local selBtn = Instance.new("TextButton")
        selBtn.Size = UDim2.new(0, 20, 0, 20)
        selBtn.Position = UDim2.new(0, 60, 0, 3)
        selBtn.BackgroundColor3 = BG_BUTTON
        selBtn.Text = "🧭"
        selBtn.TextSize = 11
        selBtn.Font = Enum.Font.GothamBold
        selBtn.TextColor3 = WHITE
        selBtn.AutoButtonColor = false
        selBtn.Parent = row
        corner(selBtn, 4)

        -- status
        local sub = newLabel(row, slot.cf and "Saved" or "Empty", 8, Enum.Font.Gotham,
            slot.cf and GREEN or GREY,
            UDim2.new(0, 8, 0, 17), UDim2.new(1, -100, 0, 14), Enum.TextXAlignment.Left)
        sub.TextTruncate = Enum.TextTruncate.AtEnd

        -- textbox nama
        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(1, -16, 0, 18)
        nameBox.Position = UDim2.new(0, 8, 0, 32)
        nameBox.BackgroundColor3 = BG_BUTTON
        nameBox.Text = slot.name or ""
        nameBox.PlaceholderText = "🏷️ kasih nama (mis. Boss Room)"
        nameBox.PlaceholderColor3 = GREY
        nameBox.TextSize = 9
        nameBox.Font = Enum.Font.GothamBold
        nameBox.TextColor3 = WHITE
        nameBox.ClearTextOnFocus = false
        nameBox.TextXAlignment = Enum.TextXAlignment.Left
        nameBox.Parent = row
        corner(nameBox, 5)

        local function sBtn(text, xPos, color, w)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, w or 24, 0, 22)
            b.Position = UDim2.new(1, xPos, 0, 3)
            b.BackgroundColor3 = color
            b.Text = text
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.AutoButtonColor = false
            b.Parent = row
            corner(b, 5)
            return b
        end

        -- urutan dari kanan: [✕ hapus] [🚀 GO] [💾 SAVE]
        local delBtn  = sBtn("✕", -30, Color3.fromRGB(150, 40, 50), 24)
        local goBtn   = sBtn("🚀", -58, Color3.fromRGB(0, 130, 150), 24)
        local saveBtn = sBtn("💾", -86, BG_BUTTON, 24)

        local function refreshSelectBtn()
            local on = (TPS.selected == i)
            selBtn.BackgroundColor3 = on and Color3.fromRGB(255, 220, 100) or BG_BUTTON
            selBtn.TextColor3 = on and Color3.fromRGB(20, 20, 20) or WHITE
            hl.Color = on and Color3.fromRGB(255, 220, 100) or BORDER_BLUE
            hl.Thickness = on and 2 or 1
        end

        -- SAVE
        saveBtn.MouseButton1Click:Connect(function()
            local hrp = getHRP()
            if not hrp then
                saveBtn.Text = "⚠️"
                task.delay(1.2, function() saveBtn.Text = "💾" end)
                return
            end
            slot.cf = hrp.CFrame
            local p = hrp.Position
            sub.Text = string.format("Saved (%d, %d, %d)", p.X, p.Y, p.Z)
            sub.TextColor3 = GREEN
            saveBtn.Text = "✅"
            task.delay(1.2, function() saveBtn.Text = "💾" end)
            TPS.save()
        end)

        -- GO
        goBtn.MouseButton1Click:Connect(function()
            local hrp = getHRP()
            if hrp and slot.cf then
                hrp.CFrame = slot.cf
                goBtn.Text = "✅"
                task.delay(1.0, function() goBtn.Text = "🚀" end)
            else
                goBtn.Text = "⚠️"
                task.delay(1.2, function() goBtn.Text = "🚀" end)
            end
        end)

        -- ✕ HAPUS
        delBtn.MouseButton1Click:Connect(function()
            slot.cf = nil
            sub.Text = "Empty"
            sub.TextColor3 = GREY
            delBtn.Text = "✅"
            task.delay(1.0, function() delBtn.Text = "✕" end)
            if TPS.selected == i then
                TPS.selected = nil
            end
            for _, ref in pairs(slotUIRefs) do
                if ref.refreshSelectBtn then ref.refreshSelectBtn() end
            end
            TPS.save()
        end)

        -- COMPASS SELECT
        selBtn.MouseButton1Click:Connect(function()
            if not slot.cf then
                selBtn.Text = "⚠️"
                task.delay(1.0, function() selBtn.Text = "🧭" end)
                return
            end
            if TPS.selected == i then
                TPS.selected = nil
            else
                TPS.selected = i
            end
            for _, ref in pairs(slotUIRefs) do
                if ref.refreshSelectBtn then ref.refreshSelectBtn() end
            end
            TPS.save()
        end)

        -- NAMA (simpan saat selesai ngetik)
        nameBox.FocusLost:Connect(function()
            local txt = (nameBox.Text or ""):match("^%s*(.-)%s*$")
            if #txt > 20 then txt = txt:sub(1, 20) end
            nameBox.Text = txt
            slot.name = txt
            TPS.save()
        end)

        slotUIRefs[i] = { row = row, sub = sub, refreshSelectBtn = refreshSelectBtn, hl = hl }
        refreshSelectBtn()
    end

    -- ============ LOAD DATA LAMA, LALU BUAT UI ============
    TPS.load()
    -- slot terpilih yang datanya sudah tidak ada -> kosongkan
    if TPS.selected and not (TPS.slots[TPS.selected] and TPS.slots[TPS.selected].cf) then
        TPS.selected = nil
    end
    for i = 1, 10 do
        makeSlot(i)
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

-- ==================== TAB APLIKASI (8 MINI GAMES + STATISTIK) ====================
-- Halaman & tombol tab dibuat di atas (pages.APLIKASI). Kartu game ikut bisa dicari & di-favorit-kan
-- (grid ditandai UHGroup, tiap kartu punya UHKey + UHLabel).
do
    local APP = {
        file = "UniversalHub_games.json",
        stats = {},
        current = nil,
        gui = nil,
        conns = {},
        startTime = 0,
    }

    local GAME_LIST = {
        { id = "snake",   name = "Snake",         icon = "🐍", color = Color3.fromRGB(60, 200, 100) },
        { id = "2048",    name = "2048",          icon = "🟦", color = Color3.fromRGB(240, 180, 60) },
        { id = "ttt",     name = "Tic Tac Toe",   icon = "🎯", color = Color3.fromRGB(200, 80, 140) },
        { id = "pong",    name = "Pong vs AI",    icon = "🏓", color = Color3.fromRGB(80, 160, 240) },
        { id = "shooter", name = "Space Shooter", icon = "🚀", color = Color3.fromRGB(240, 100, 100) },
        { id = "memory",  name = "Memory Card",   icon = "🃏", color = Color3.fromRGB(180, 100, 240) },
        { id = "simon",   name = "Simon Says",    icon = "🎨", color = Color3.fromRGB(240, 200, 60) },
        { id = "mines",   name = "Minesweeper",   icon = "💣", color = Color3.fromRGB(160, 160, 160) },
    }

    function APP.getStat(id)
        if not APP.stats[id] then
            APP.stats[id] = { plays = 0, totalTime = 0, best = 0, totalScore = 0 }
        end
        return APP.stats[id]
    end

    function APP.save()
        if not writefile then return end
        pcall(function()
            writefile(APP.file, HttpService:JSONEncode(APP.stats))
        end)
    end

    function APP.load()
        if not (readfile and isfile) then return end
        pcall(function()
            if isfile(APP.file) then
                local data = HttpService:JSONDecode(readfile(APP.file))
                if type(data) == "table" then
                    for id, st in pairs(data) do
                        if type(st) == "table" then
                            APP.stats[id] = {
                                plays = tonumber(st.plays) or 0,
                                totalTime = tonumber(st.totalTime) or 0,
                                best = tonumber(st.best) or 0,
                                totalScore = tonumber(st.totalScore) or 0,
                            }
                        end
                    end
                end
            end
        end)
    end

    function APP.recordStart(id)
        local st = APP.getStat(id)
        st.plays = st.plays + 1
        APP.startTime = os.clock()
        APP.current = id
    end

    function APP.recordEnd(id, finalScore)
        if not id then return end
        local st = APP.getStat(id)
        local elapsed = os.clock() - APP.startTime
        st.totalTime = st.totalTime + elapsed
        if finalScore and finalScore > 0 then
            st.totalScore = st.totalScore + finalScore
            if finalScore > st.best then st.best = finalScore end
        end
        APP.current = nil
        APP.save()
    end

    function APP.fmtTime(sec)
        local m = math.floor(sec / 60)
        local s = math.floor(sec % 60)
        return string.format("%d:%02d", m, s)
    end

    local appPage = pages.APLIKASI
    pages.header(appPage, "🎮 APLIKASI / MINI GAMES", 0)

    local infoLbl = newLabel(appPage, "Pilih game buat main sambil nunggu. Statistik tersimpan otomatis.",
        9, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28), Enum.TextXAlignment.Left)
    infoLbl.LayoutOrder = 1
    infoLbl.TextWrapped = true

    local grid = Instance.new("Frame")
    grid.LayoutOrder = 2
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.BackgroundTransparency = 1
    grid:SetAttribute("UHGroup", true) -- supaya kartu game ikut kebaca fitur CARI / FAV
    grid.Parent = appPage
    local gLayout = Instance.new("UIGridLayout")
    gLayout.CellSize = UDim2.new(0.5, -4, 0, 110)
    gLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gLayout.Parent = grid

    local gameCards = {}

    local function refreshCards()
        for _, card in pairs(gameCards) do
            local st = APP.getStat(card.id)
            card.playsLbl.Text = "🎮 " .. st.plays .. "x main"
            card.timeLbl.Text = "⏱️ " .. APP.fmtTime(st.totalTime)
            card.bestLbl.Text = "🏆 " .. st.best .. " skor"
        end
    end

    -- tutup paksa (tombol X): simpan statistik, putus koneksi, hancurkan jendela
    local function closeGame(finalScore)
        if APP.current then
            APP.recordEnd(APP.current, finalScore)
        end
        for _, c in ipairs(APP.conns) do pcall(function() c:Disconnect() end) end
        APP.conns = {}
        if APP.gui then APP.gui:Destroy() APP.gui = nil end
        refreshCards()
    end

    -- game selesai: simpan skor, hentikan loop, tapi jendela dibiarkan terbuka sebentar
    -- supaya tulisan MENANG / KALAH / GAME OVER sempat kebaca
    local function finishGame(gui, finalScore, delay)
        if APP.current then
            APP.recordEnd(APP.current, finalScore)
        end
        for _, c in ipairs(APP.conns) do pcall(function() c:Disconnect() end) end
        APP.conns = {}
        refreshCards()
        task.delay(delay or 2, function()
            if gui and gui.Parent then
                gui:Destroy()
                if APP.gui == gui then APP.gui = nil end
            end
        end)
    end

    local function makeGameWindow(title, sizeX, sizeY)
        if APP.gui then APP.gui:Destroy() end
        local gui = Instance.new("Frame")
        gui.Name = "MiniGameWindow"
        gui.AnchorPoint = Vector2.new(0.5, 0.5)
        gui.Position = UDim2.new(0.5, 0, 0.5, 0)
        gui.Size = UDim2.new(0, sizeX, 0, sizeY)
        gui.BackgroundColor3 = Color3.fromRGB(14, 6, 28)
        gui.BorderSizePixel = 0
        gui.ZIndex = 80
        gui.Active = true
        gui.Parent = screenGui
        corner(gui, 14)
        stroke(gui, ACCENT_BLUE, 2)
        APP.gui = gui

        -- tombol di dalam game tidak dikasih efek "bubble" tema
        gui.DescendantAdded:Connect(function(o)
            if o:IsA("TextButton") then o:SetAttribute("UHBubble", true) end
        end)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 28)
        bar.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
        bar.BorderSizePixel = 0
        bar.Parent = gui
        corner(bar, 14)
        newLabel(bar, title, 11, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 10, 0, 0), UDim2.new(1, -40, 1, 0), Enum.TextXAlignment.Left)

        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 22, 0, 22)
        close.Position = UDim2.new(1, -26, 0, 3)
        close.BackgroundColor3 = Color3.fromRGB(150, 40, 50)
        close.Text = "X"
        close.TextSize = 11
        close.Font = Enum.Font.GothamBold
        close.TextColor3 = WHITE
        close.AutoButtonColor = false
        close.Parent = bar
        corner(close, 6)
        close.MouseButton1Click:Connect(function() closeGame(nil) end)

        local body = Instance.new("Frame")
        body.Size = UDim2.new(1, -12, 1, -40)
        body.Position = UDim2.new(0, 6, 0, 34)
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.Parent = gui

        return gui, body
    end

    -- ============ SNAKE ============
    local function openSnake()
        APP.recordStart("snake")
        local gui, body = makeGameWindow("🐍 SNAKE", 320, 440)

        local GRID = 15
        local CELL = 16
        local SIZE = GRID * CELL

        local scoreLbl = newLabel(body, "SKOR: 0", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -4, 0, 20), Enum.TextXAlignment.Left)
        local bestLbl = newLabel(body, "BEST: " .. APP.getStat("snake").best, 12, Enum.Font.GothamBlack, GREEN,
            UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -4, 0, 20), Enum.TextXAlignment.Right)

        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, SIZE, 0, SIZE)
        board.Position = UDim2.new(0.5, -SIZE / 2, 0, 26)
        board.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
        board.BorderSizePixel = 0
        board.Parent = body
        corner(board, 6)

        local cells = {}
        for y = 1, GRID do
            for x = 1, GRID do
                local c = Instance.new("Frame")
                c.Size = UDim2.new(0, CELL - 1, 0, CELL - 1)
                c.Position = UDim2.new(0, (x - 1) * CELL, 0, (y - 1) * CELL)
                c.BackgroundColor3 = Color3.fromRGB(30, 38, 56)
                c.BorderSizePixel = 0
                c.Parent = board
                cells[x .. "," .. y] = c
            end
        end

        local state = { snake = { { x = 8, y = 8 } }, dir = { x = 1, y = 0 }, nextDir = { x = 1, y = 0 },
            food = { x = 12, y = 8 }, score = 0, over = false, speed = 0.18 }
        local moveAcc = 0

        local function placeFood()
            while true do
                local fx = math.random(1, GRID)
                local fy = math.random(1, GRID)
                local bad = false
                for _, s in ipairs(state.snake) do
                    if s.x == fx and s.y == fy then bad = true break end
                end
                if not bad then state.food = { x = fx, y = fy } return end
            end
        end

        local function render()
            for y = 1, GRID do
                for x = 1, GRID do
                    local c = cells[x .. "," .. y]
                    if c then c.BackgroundColor3 = Color3.fromRGB(30, 38, 56) end
                end
            end
            local fc = cells[state.food.x .. "," .. state.food.y]
            if fc then fc.BackgroundColor3 = Color3.fromRGB(255, 80, 100) end
            for i, s in ipairs(state.snake) do
                local c = cells[s.x .. "," .. s.y]
                if c then
                    c.BackgroundColor3 = (i == 1) and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(60, 180, 100)
                end
            end
        end

        local function step()
            if state.over then return end
            state.dir = state.nextDir
            local head = state.snake[1]
            local nx = head.x + state.dir.x
            local ny = head.y + state.dir.y
            if nx < 1 or nx > GRID or ny < 1 or ny > GRID then
                state.over = true
                return
            end
            for _, s in ipairs(state.snake) do
                if s.x == nx and s.y == ny then state.over = true return end
            end
            local newHead = { x = nx, y = ny }
            table.insert(state.snake, 1, newHead)
            if nx == state.food.x and ny == state.food.y then
                state.score = state.score + 10
                scoreLbl.Text = "SKOR: " .. state.score
                if state.score > APP.getStat("snake").best then
                    bestLbl.Text = "BEST: " .. state.score
                    bestLbl.TextColor3 = Color3.fromRGB(255, 220, 60)
                end
                placeFood()
            else
                table.remove(state.snake)
            end
        end

        local conn = RunService.Heartbeat:Connect(function(dt)
            if state.over then
                if not state.overShown then
                    state.overShown = true
                    scoreLbl.Text = "GAME OVER — SKOR: " .. state.score
                    scoreLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    finishGame(gui, state.score, 2.5)
                end
                return
            end
            moveAcc = moveAcc + dt
            if moveAcc >= state.speed then
                moveAcc = 0
                step()
                render()
            end
        end)
        table.insert(APP.conns, conn)

        local ctrl = Instance.new("Frame")
        ctrl.Size = UDim2.new(0, 160, 0, 110)
        ctrl.Position = UDim2.new(0.5, -80, 1, -118)
        ctrl.BackgroundTransparency = 1
        ctrl.Parent = body

        local function arrowBtn(text, x, y, w, h, dx, dy)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, w, 0, h)
            b.Position = UDim2.new(0, x, 0, y)
            b.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
            b.Text = text
            b.TextSize = 18
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.AutoButtonColor = false
            b.Parent = ctrl
            corner(b, 8)
            b.MouseButton1Click:Connect(function()
                if state.over then return end
                if dx == 1 and state.dir.x == -1 then return end
                if dx == -1 and state.dir.x == 1 then return end
                if dy == 1 and state.dir.y == -1 then return end
                if dy == -1 and state.dir.y == 1 then return end
                state.nextDir = { x = dx, y = dy }
            end)
        end
        arrowBtn("↑", 55, 0, 50, 50, 0, -1)
        arrowBtn("←", 0, 55, 50, 50, -1, 0)
        arrowBtn("↓", 55, 55, 50, 50, 0, 1)
        arrowBtn("→", 110, 55, 50, 50, 1, 0)

        render()
    end

    -- ============ 2048 ============
    local function open2048()
        APP.recordStart("2048")
        local gui, body = makeGameWindow("🟦 2048", 320, 480)

        local N = 4
        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, 280, 0, 280)
        board.Position = UDim2.new(0.5, -140, 0, 26)
        board.BackgroundColor3 = Color3.fromRGB(40, 46, 60)
        board.BorderSizePixel = 0
        board.Parent = body
        corner(board, 8)

        local scoreLbl = newLabel(body, "SKOR: 0", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 20, 1, -130), UDim2.new(0.5, -20, 0, 20), Enum.TextXAlignment.Left)
        local bestLbl = newLabel(body, "BEST: " .. APP.getStat("2048").best, 12, Enum.Font.GothamBlack, GREEN,
            UDim2.new(0.5, 20, 1, -130), UDim2.new(0.5, -20, 0, 20), Enum.TextXAlignment.Right)

        local tiles = {}
        for y = 1, N do
            for x = 1, N do
                local t = Instance.new("Frame")
                t.Size = UDim2.new(0, 64, 0, 64)
                t.Position = UDim2.new(0, (x - 1) * 70 + 4, 0, (y - 1) * 70 + 4)
                t.BackgroundColor3 = Color3.fromRGB(60, 66, 84)
                t.BorderSizePixel = 0
                t.Parent = board
                corner(t, 6)
                local lbl = newLabel(t, "", 22, Enum.Font.GothamBlack, WHITE,
                    UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
                tiles[x .. "," .. y] = { frame = t, lbl = lbl }
            end
        end

        local grid = {}
        for y = 1, N do
            grid[y] = {}
            for x = 1, N do grid[y][x] = 0 end
        end
        local score = 0
        local over = false

        local COLORS = {
            [2] = Color3.fromRGB(90, 96, 116), [4] = Color3.fromRGB(110, 116, 136),
            [8] = Color3.fromRGB(240, 160, 70), [16] = Color3.fromRGB(240, 130, 60),
            [32] = Color3.fromRGB(240, 100, 60), [64] = Color3.fromRGB(240, 70, 50),
            [128] = Color3.fromRGB(240, 210, 80), [256] = Color3.fromRGB(240, 190, 60),
            [512] = Color3.fromRGB(240, 170, 40), [1024] = Color3.fromRGB(240, 150, 20),
            [2048] = Color3.fromRGB(255, 120, 40),
        }

        local function render()
            for y = 1, N do
                for x = 1, N do
                    local t = tiles[x .. "," .. y]
                    local v = grid[y][x]
                    t.lbl.Text = (v == 0) and "" or tostring(v)
                    t.frame.BackgroundColor3 = (v == 0) and Color3.fromRGB(60, 66, 84)
                        or COLORS[v] or Color3.fromRGB(255, 80, 200)
                end
            end
            scoreLbl.Text = "SKOR: " .. score
        end

        local function addRandom()
            local empty = {}
            for y = 1, N do
                for x = 1, N do
                    if grid[y][x] == 0 then table.insert(empty, { x = x, y = y }) end
                end
            end
            if #empty == 0 then return false end
            local pick = empty[math.random(1, #empty)]
            grid[pick.y][pick.x] = (math.random() < 0.9) and 2 or 4
            return true
        end

        -- geser + gabung satu baris ke arah kiri (versi aman: tiap petak cuma gabung sekali)
        local function slide(row)
            local out = {}
            for _, v in ipairs(row) do if v ~= 0 then table.insert(out, v) end end
            local res = {}
            local i = 1
            while i <= #out do
                if out[i + 1] and out[i] == out[i + 1] then
                    local m = out[i] * 2
                    score = score + m
                    table.insert(res, m)
                    i = i + 2
                else
                    table.insert(res, out[i])
                    i = i + 1
                end
            end
            while #res < N do table.insert(res, 0) end
            return res
        end

        local function snapshot()
            local t = {}
            for y = 1, N do
                for x = 1, N do t[#t + 1] = grid[y][x] end
            end
            return table.concat(t, ",")
        end

        local function move(dx, dy)
            if over then return end
            local before = snapshot()
            if dx == 1 then
                for y = 1, N do
                    local row = {}
                    for x = N, 1, -1 do table.insert(row, grid[y][x]) end
                    row = slide(row)
                    for x = 1, N do grid[y][N - x + 1] = row[x] end
                end
            elseif dx == -1 then
                for y = 1, N do
                    local row = {}
                    for x = 1, N do table.insert(row, grid[y][x]) end
                    row = slide(row)
                    for x = 1, N do grid[y][x] = row[x] end
                end
            elseif dy == 1 then
                for x = 1, N do
                    local col = {}
                    for y = N, 1, -1 do table.insert(col, grid[y][x]) end
                    col = slide(col)
                    for y = 1, N do grid[N - y + 1][x] = col[y] end
                end
            elseif dy == -1 then
                for x = 1, N do
                    local col = {}
                    for y = 1, N do table.insert(col, grid[y][x]) end
                    col = slide(col)
                    for y = 1, N do grid[y][x] = col[y] end
                end
            end
            if snapshot() == before then return end -- gerakan tidak mengubah apa-apa: tidak ada petak baru
            addRandom()
            render()
            if score > APP.getStat("2048").best then bestLbl.Text = "BEST: " .. score end

            local canMove = false
            for y = 1, N do
                for x = 1, N do
                    if grid[y][x] == 0 then canMove = true end
                end
            end
            if not canMove then
                for y = 1, N do
                    for x = 1, N - 1 do
                        if grid[y][x] == grid[y][x + 1] then canMove = true end
                    end
                end
                for x = 1, N do
                    for y = 1, N - 1 do
                        if grid[y][x] == grid[y + 1][x] then canMove = true end
                    end
                end
            end
            if not canMove then
                over = true
                scoreLbl.Text = "GAME OVER — SKOR: " .. score
                scoreLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                finishGame(gui, score, 2.5)
            end
        end

        local ctrl = Instance.new("Frame")
        ctrl.Size = UDim2.new(0, 160, 0, 110)
        ctrl.Position = UDim2.new(0.5, -80, 1, -118)
        ctrl.BackgroundTransparency = 1
        ctrl.Parent = body
        local function arrowBtn(text, x, y, w, h, dx, dy)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, w, 0, h)
            b.Position = UDim2.new(0, x, 0, y)
            b.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
            b.Text = text
            b.TextSize = 18
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.AutoButtonColor = false
            b.Parent = ctrl
            corner(b, 8)
            b.MouseButton1Click:Connect(function() move(dx, dy) end)
        end
        arrowBtn("↑", 55, 0, 50, 50, 0, -1)
        arrowBtn("←", 0, 55, 50, 50, -1, 0)
        arrowBtn("↓", 55, 55, 50, 50, 0, 1)
        arrowBtn("→", 110, 55, 50, 50, 1, 0)

        addRandom()
        addRandom()
        render()
    end

    -- ============ TIC TAC TOE ============
    local TTT_LEVELS = { "EASY", "MEDIUM", "HARD" }
    local tttLevelIdx = 2

    local function openTTT()
        APP.recordStart("ttt")
        local gui, body = makeGameWindow("🎯 TIC TAC TOE", 320, 400)

        local lvlBtn = Instance.new("TextButton")
        lvlBtn.Size = UDim2.new(0, 100, 0, 22)
        lvlBtn.Position = UDim2.new(0, 0, 0, 0)
        lvlBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
        lvlBtn.Text = "LEVEL: " .. TTT_LEVELS[tttLevelIdx]
        lvlBtn.TextSize = 10
        lvlBtn.Font = Enum.Font.GothamBold
        lvlBtn.TextColor3 = WHITE
        lvlBtn.AutoButtonColor = false
        lvlBtn.Parent = body
        corner(lvlBtn, 6)
        lvlBtn.MouseButton1Click:Connect(function()
            tttLevelIdx = tttLevelIdx % #TTT_LEVELS + 1
            lvlBtn.Text = "LEVEL: " .. TTT_LEVELS[tttLevelIdx]
        end)

        local turnLbl = newLabel(body, "GILIRAN: X", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 100, 0, 0), UDim2.new(1, -100, 0, 24), Enum.TextXAlignment.Right)

        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, 240, 0, 240)
        board.Position = UDim2.new(0.5, -120, 0, 30)
        board.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
        board.BorderSizePixel = 0
        board.Parent = body
        corner(board, 8)

        local cells = {}
        for y = 1, 3 do
            for x = 1, 3 do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, 74, 0, 74)
                b.Position = UDim2.new(0, (x - 1) * 78 + 4, 0, (y - 1) * 78 + 4)
                b.BackgroundColor3 = Color3.fromRGB(35, 42, 60)
                b.Text = ""
                b.TextSize = 36
                b.Font = Enum.Font.GothamBlack
                b.TextColor3 = WHITE
                b.AutoButtonColor = false
                b.Parent = board
                corner(b, 6)
                cells[x .. "," .. y] = b
            end
        end

        local board2 = {}
        for y = 1, 3 do board2[y] = {} for x = 1, 3 do board2[y][x] = "" end end
        local over = false
        local thinking = false

        local function render()
            for y = 1, 3 do
                for x = 1, 3 do
                    local b = cells[x .. "," .. y]
                    b.Text = board2[y][x]
                    if board2[y][x] == "X" then b.TextColor3 = Color3.fromRGB(80, 180, 255)
                    elseif board2[y][x] == "O" then b.TextColor3 = Color3.fromRGB(255, 130, 180) end
                end
            end
        end

        local function winner(b)
            for y = 1, 3 do if b[y][1] ~= "" and b[y][1] == b[y][2] and b[y][2] == b[y][3] then return b[y][1] end end
            for x = 1, 3 do if b[1][x] ~= "" and b[1][x] == b[2][x] and b[2][x] == b[3][x] then return b[1][x] end end
            if b[1][1] ~= "" and b[1][1] == b[2][2] and b[2][2] == b[3][3] then return b[1][1] end
            if b[1][3] ~= "" and b[1][3] == b[2][2] and b[2][2] == b[3][1] then return b[1][3] end
            return nil
        end

        local function emptyCells(b)
            local out = {}
            for y = 1, 3 do for x = 1, 3 do if b[y][x] == "" then table.insert(out, { x = x, y = y }) end end end
            return out
        end

        local function minimax(b, isMax)
            local w = winner(b)
            if w == "O" then return 1 end
            if w == "X" then return -1 end
            local empty = emptyCells(b)
            if #empty == 0 then return 0 end
            if isMax then
                local best = -999
                for _, e in ipairs(empty) do
                    b[e.y][e.x] = "O"
                    local sc = minimax(b, false)
                    b[e.y][e.x] = ""
                    if sc > best then best = sc end
                end
                return best
            else
                local best = 999
                for _, e in ipairs(empty) do
                    b[e.y][e.x] = "X"
                    local sc = minimax(b, true)
                    b[e.y][e.x] = ""
                    if sc < best then best = sc end
                end
                return best
            end
        end

        local function aiMove()
            local empty = emptyCells(board2)
            if #empty == 0 then return end
            local lvl = TTT_LEVELS[tttLevelIdx]
            if lvl == "EASY" then
                local pick = empty[math.random(1, #empty)]
                board2[pick.y][pick.x] = "O"
            elseif lvl == "MEDIUM" then
                for _, e in ipairs(empty) do
                    board2[e.y][e.x] = "O"
                    if winner(board2) == "O" then return end
                    board2[e.y][e.x] = ""
                end
                for _, e in ipairs(empty) do
                    board2[e.y][e.x] = "X"
                    if winner(board2) == "X" then board2[e.y][e.x] = "O" return end
                    board2[e.y][e.x] = ""
                end
                if board2[2][2] == "" then board2[2][2] = "O" return end
                local pick = empty[math.random(1, #empty)]
                board2[pick.y][pick.x] = "O"
            else
                local best, bestSc = nil, -999
                for _, e in ipairs(empty) do
                    board2[e.y][e.x] = "O"
                    local sc = minimax(board2, false)
                    board2[e.y][e.x] = ""
                    if sc > bestSc then bestSc = sc best = e end
                end
                if best then board2[best.y][best.x] = "O" end
            end
        end

        local function endGame(w)
            over = true
            if w then
                turnLbl.Text = "🏆 " .. w .. " MENANG!"
                turnLbl.TextColor3 = (w == "X") and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(255, 100, 100)
            else
                turnLbl.Text = "SERI 🤝"
                turnLbl.TextColor3 = Color3.fromRGB(250, 204, 21)
            end
            finishGame(gui, (w == "X") and 100 or 0, 2)
        end

        for y = 1, 3 do
            for x = 1, 3 do
                cells[x .. "," .. y].MouseButton1Click:Connect(function()
                    if over or thinking or board2[y][x] ~= "" then return end
                    board2[y][x] = "X"
                    render()
                    local w = winner(board2)
                    if w then return endGame(w) end
                    if #emptyCells(board2) == 0 then return endGame(nil) end
                    thinking = true
                    task.delay(0.3, function()
                        if over or not gui.Parent then return end
                        aiMove()
                        render()
                        thinking = false
                        local w2 = winner(board2)
                        if w2 then return endGame(w2) end
                        if #emptyCells(board2) == 0 then return endGame(nil) end
                    end)
                end)
            end
        end
    end

    -- ============ PONG ============
    local PONG_LEVELS = {
        { name = "EASY",   speed = 0.85, err = 60 },
        { name = "MEDIUM", speed = 1.0,  err = 30 },
        { name = "HARD",   speed = 1.25, err = 10 },
    }
    local pongLevelIdx = 2

    local function openPong()
        APP.recordStart("pong")
        local gui, body = makeGameWindow("🏓 PONG vs AI", 340, 360)

        local lvlBtn = Instance.new("TextButton")
        lvlBtn.Size = UDim2.new(0, 90, 0, 22)
        lvlBtn.Position = UDim2.new(0, 0, 0, 0)
        lvlBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 160)
        lvlBtn.Text = "LEVEL: " .. PONG_LEVELS[pongLevelIdx].name
        lvlBtn.TextSize = 10
        lvlBtn.Font = Enum.Font.GothamBold
        lvlBtn.TextColor3 = WHITE
        lvlBtn.AutoButtonColor = false
        lvlBtn.Parent = body
        corner(lvlBtn, 6)
        lvlBtn.MouseButton1Click:Connect(function()
            pongLevelIdx = pongLevelIdx % #PONG_LEVELS + 1
            lvlBtn.Text = "LEVEL: " .. PONG_LEVELS[pongLevelIdx].name
        end)

        local scoreLbl = newLabel(body, "LU: 0    AI: 0", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 100, 0, 0), UDim2.new(1, -100, 0, 22), Enum.TextXAlignment.Right)

        local W, H = 300, 240
        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, W, 0, H)
        board.Position = UDim2.new(0.5, -W / 2, 0, 30)
        board.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
        board.BorderSizePixel = 0
        board.Parent = body
        corner(board, 6)

        local myPaddle = Instance.new("Frame")
        myPaddle.Size = UDim2.new(0, 6, 0, 50)
        myPaddle.Position = UDim2.new(0, 4, 0.5, -25)
        myPaddle.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        myPaddle.BorderSizePixel = 0
        myPaddle.Parent = board
        corner(myPaddle, 3)

        local aiPaddle = Instance.new("Frame")
        aiPaddle.Size = UDim2.new(0, 6, 0, 50)
        aiPaddle.Position = UDim2.new(1, -10, 0.5, -25)
        aiPaddle.BackgroundColor3 = Color3.fromRGB(240, 80, 100)
        aiPaddle.BorderSizePixel = 0
        aiPaddle.Parent = board
        corner(aiPaddle, 3)

        local ball = Instance.new("Frame")
        ball.Size = UDim2.new(0, 10, 0, 10)
        ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ball.BorderSizePixel = 0
        ball.Parent = board
        corner(ball, 5)

        local state = { bx = W/2, by = H/2, bdx = 200, bdy = 150, myY = H/2, aiY = H/2, scoreMe = 0, scoreAi = 0, over = false }

        local function resetBall(dir)
            state.bx = W / 2
            state.by = H / 2
            state.bdx = 200 * dir
            state.bdy = (math.random() < 0.5 and 1 or -1) * math.random(80, 180)
        end

        local dragConn = board.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                local rel = input.Position.Y - board.AbsolutePosition.Y
                state.myY = math.clamp(rel, 25, H - 25)
            end
        end)
        table.insert(APP.conns, dragConn)
        local moveConn = board.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = input.Position.Y - board.AbsolutePosition.Y
                state.myY = math.clamp(rel, 25, H - 25)
            end
        end)
        table.insert(APP.conns, moveConn)

        local conn = RunService.Heartbeat:Connect(function(dt)
            if state.over then return end
            local lvl = PONG_LEVELS[pongLevelIdx]
            state.bx = state.bx + state.bdx * dt
            state.by = state.by + state.bdy * dt
            if state.by < 5 then state.by = 5; state.bdy = math.abs(state.bdy) end
            if state.by > H - 5 then state.by = H - 5; state.bdy = -math.abs(state.bdy) end
            -- pantul di paddle kamu (kiri)
            if state.bdx < 0 and state.bx < 12 and math.abs(state.by - state.myY) < 30 then
                state.bdx = math.abs(state.bdx)
                state.bdy = state.bdy + (state.by - state.myY) * 3
            end
            -- pantul di paddle AI (kanan)
            if state.bdx > 0 and state.bx > W - 12 and math.abs(state.by - state.aiY) < 30 then
                state.bdx = -math.abs(state.bdx)
                state.bdy = state.bdy + (state.by - state.aiY) * 3
            end
            state.bdy = math.clamp(state.bdy, -320, 320)
            local target = state.by + (math.random(-lvl.err, lvl.err))
            state.aiY = state.aiY + (target - state.aiY) * math.min(1, lvl.speed * dt * 8)
            state.aiY = math.clamp(state.aiY, 25, H - 25)
            if state.bx < -10 then
                state.scoreAi = state.scoreAi + 1
                resetBall(1)
            elseif state.bx > W + 10 then
                state.scoreMe = state.scoreMe + 1
                resetBall(-1)
            end
            myPaddle.Position = UDim2.new(0, 4, 0, state.myY - 25)
            aiPaddle.Position = UDim2.new(1, -10, 0, state.aiY - 25)
            ball.Position = UDim2.new(0, state.bx - 5, 0, state.by - 5)
            scoreLbl.Text = "LU: " .. state.scoreMe .. "    AI: " .. state.scoreAi
            if state.scoreMe >= 5 or state.scoreAi >= 5 then
                state.over = true
                scoreLbl.Text = (state.scoreMe >= 5 and "🎉 LU MENANG!" or "💀 LU KALAH")
                scoreLbl.TextColor3 = (state.scoreMe >= 5) and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(255, 100, 100)
                finishGame(gui, state.scoreMe * 10, 2)
            end
        end)
        table.insert(APP.conns, conn)
    end

    -- ============ SPACE SHOOTER ============
    local function openShooter()
        APP.recordStart("shooter")
        local gui, body = makeGameWindow("🚀 SPACE SHOOTER", 320, 440)
        local rand = math.random
        local sin, cos, floor, abs, max, min = math.sin, math.cos, math.floor, math.abs, math.max, math.min

        local scoreLbl = newLabel(body, "⭐ SKOR: 0", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -4, 0, 20), Enum.TextXAlignment.Left)
        local waveLbl = newLabel(body, "🌌 W1 ❤️❤️❤️", 11, Enum.Font.GothamBlack, GREEN,
            UDim2.new(0.5, 4, 0, 0), UDim2.new(0.5, -4, 0, 20), Enum.TextXAlignment.Right)
        local statusLbl = newLabel(body, "☄️ hindari meteor & tembak alien!", 10, Enum.Font.GothamBold,
            Color3.fromRGB(255, 220, 120), UDim2.new(0, 0, 0, 350), UDim2.new(1, 0, 0, 18))
        newLabel(body, "👆 geser = gerak  •  tahan = tembak otomatis", 9, Enum.Font.Gotham, GREY,
            UDim2.new(0, 0, 0, 370), UDim2.new(1, 0, 0, 16))

        local W, H = 280, 320
        local BOARD_POS = UDim2.new(0.5, -W / 2, 0, 26)
        local CYAN = Color3.fromRGB(120, 235, 255)
        local GOLDC = Color3.fromRGB(255, 225, 110)

        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, W, 0, H)
        board.Position = BOARD_POS
        board.BackgroundColor3 = WHITE
        board.BorderSizePixel = 0
        board.ClipsDescendants = true
        board.Parent = body
        corner(board, 8)
        stroke(board, Color3.fromRGB(130, 90, 255), 2)
        do
            local g = Instance.new("UIGradient")
            g.Rotation = 90
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 7, 22)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(22, 10, 50)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(52, 18, 70)),
            })
            g.Parent = board
        end

        local function layer(z)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 1, 0)
            f.BackgroundTransparency = 1
            f.BorderSizePixel = 0
            f.ZIndex = z
            f.Parent = board
            return f
        end
        local bgLayer, gameLayer, fxLayer = layer(1), layer(2), layer(3)

        local function rect(parent, w, h, color, tr, round)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, w, 0, h)
            f.BackgroundColor3 = color
            f.BackgroundTransparency = tr or 0
            f.BorderSizePixel = 0
            f.Parent = parent
            local c = Instance.new("UICorner")
            c.CornerRadius = round and UDim.new(0.5, 0) or UDim.new(0, 2)
            c.Parent = f
            return f
        end

        local function emo(parent, icon, sz)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(0, sz, 0, sz)
            l.Text = icon
            l.TextScaled = true
            l.Font = Enum.Font.GothamBold
            l.TextColor3 = WHITE
            l.Parent = parent
            return l
        end

        -- ===== latar: nebula, planet, bintang berkedip, bintang jatuh =====
        local nebs = {}
        local nebCols = { Color3.fromRGB(150, 70, 255), Color3.fromRGB(255, 80, 170), Color3.fromRGB(60, 170, 255) }
        for i = 1, 3 do
            local s = rand(130, 190)
            local n = { f = rect(bgLayer, s, s, nebCols[i], 0.88, true), x = rand(-40, W - 80), y = rand(-40, H - 60), s = s, v = 4 + i * 2 }
            n.f.Position = UDim2.new(0, n.x, 0, n.y)
            nebs[i] = n
        end

        local PLANETS = { "🪐", "🌕", "🌎", "🌑" }
        local planet = emo(bgLayer, PLANETS[1], 54)
        planet.TextTransparency = 0.3
        local pl = { x = 190, y = -10, idx = 1 }
        planet.Position = UDim2.new(0, pl.x, 0, pl.y)

        local stars = {}
        for i = 1, 38 do
            local sp = ({ 10, 24, 48 })[rand(1, 3)]
            local sz = sp < 20 and 1 or (sp < 40 and 2 or 3)
            local col = WHITE
            if rand(1, 3) == 1 then col = Color3.fromRGB(170, 200, 255)
            elseif rand(1, 5) == 1 then col = Color3.fromRGB(255, 220, 170) end
            local s = { f = rect(bgLayer, sz, sz, col, 0.3, true), x = rand(0, W), y = rand(0, H), v = sp, ph = rand() * 6.28 }
            s.f.Position = UDim2.new(0, s.x, 0, s.y)
            stars[i] = s
        end
        local shots = {}

        -- ===== kapal =====
        local ship = Instance.new("Frame")
        ship.Size = UDim2.new(0, 30, 0, 34)
        ship.BackgroundTransparency = 1
        ship.BorderSizePixel = 0
        ship.Parent = gameLayer
        local shipIcon = emo(ship, "🚀", 32)
        shipIcon.Position = UDim2.new(0, -1, 0, 0)
        shipIcon.Rotation = -45
        shipIcon.ZIndex = 2
        local shieldF = rect(ship, 46, 46, Color3.fromRGB(80, 220, 255), 0.82, true)
        shieldF.Position = UDim2.new(0.5, -23, 0.5, -23)
        shieldF.ZIndex = 3
        shieldF.Visible = false
        stroke(shieldF, Color3.fromRGB(120, 235, 255), 2)

        local S = {
            score = 0, wave = 1, lives = 3, kills = 0, px = W / 2, over = false,
            shootCD = 0, spawnCD = 0.6, holding = false, shield = false, rapid = 0,
            combo = 0, comboT = 0, shake = 0, inv = 0, t = 0, trailCD = 0, starCD = 2, last = "",
        }
        local bullets, enemies, ebul, picks, fxs = {}, {}, {}, {}, {}

        local function updateHud()
            scoreLbl.Text = "⭐ SKOR: " .. S.score
            waveLbl.Text = "🌌 W" .. S.wave .. " " .. string.rep("❤️", max(0, S.lives))
        end

        -- ===== efek partikel (satu mekanisme untuk semua) =====
        local function addFx(f, cx, cy, vx, vy, life, s0, s1, kind)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Parent = fxLayer
            f.Position = UDim2.new(0, cx, 0, cy)
            if s0 then f.Size = UDim2.new(0, s0, 0, s0) end
            fxs[#fxs + 1] = { f = f, x = cx, y = cy, vx = vx, vy = vy, t = 0, life = life, s0 = s0, s1 = s1, kind = kind }
        end

        local function floatText(txt, x, y, color, size)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(0, 90, 0, 16)
            l.Text = txt
            l.TextSize = size or 11
            l.Font = Enum.Font.GothamBlack
            l.TextColor3 = color or WHITE
            l.TextStrokeTransparency = 0.4
            addFx(l, math.clamp(x, 40, W - 40), y, 0, -34, 0.9, nil, nil, "text")
        end

        local function banner(txt)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(0, W, 0, 34)
            l.Text = txt
            l.TextSize = 22
            l.Font = Enum.Font.GothamBlack
            l.TextColor3 = Color3.fromRGB(255, 235, 150)
            l.TextStrokeColor3 = Color3.fromRGB(120, 60, 220)
            l.TextStrokeTransparency = 0.3
            addFx(l, W / 2, H * 0.38, 0, -8, 1.6, nil, nil, "text")
        end

        local function explode(cx, cy, sz, col)
            addFx(emo(fxLayer, "💥", 10), cx, cy, 0, 0, 0.38, 10, sz * 1.5, "text")
            for i = 1, floor(sz / 4) + 4 do
                local a, sp, ps = rand() * 6.283, rand(40, 110), rand(3, 5)
                local p = rect(fxLayer, ps, ps, (i % 2 == 0) and col or Color3.fromRGB(255, 220, 90), 0, true)
                addFx(p, cx, cy, cos(a) * sp, sin(a) * sp, 0.5 + rand() * 0.3, ps, 1, "frame")
            end
        end

        -- ===== tembakan pemain =====
        local function fire()
            if S.shootCD > 0 or S.over then return end
            local double = S.rapid > 0
            local col = double and Color3.fromRGB(255, 120, 220) or Color3.fromRGB(150, 255, 255)
            for _, o in ipairs(double and { -8, 8 } or { 0 }) do
                local f = rect(gameLayer, 4, 14, col, 0, true)
                stroke(f, col, 2).Transparency = 0.55
                f.Position = UDim2.new(0, S.px + o - 2, 0, H - 56)
                bullets[#bullets + 1] = { f = f, x = S.px + o - 2, y = H - 56 }
            end
            addFx(rect(fxLayer, 10, 10, col, 0.2, true), S.px, H - 54, 0, -20, 0.12, 10, 3, "frame")
            S.shootCD = double and 0.13 or 0.24
        end

        -- ===== power-up =====
        local PICK = {
            { kind = "shield", icon = "🛡️", col = Color3.fromRGB(80, 200, 255), w = 30 },
            { kind = "rapid",  icon = "⚡", col = Color3.fromRGB(255, 220, 60), w = 30 },
            { kind = "heart",  icon = "❤️", col = Color3.fromRGB(255, 80, 110), w = 16 },
            { kind = "gem",    icon = "💎", col = Color3.fromRGB(120, 230, 255), w = 14 },
            { kind = "nova",   icon = "🌟", col = Color3.fromRGB(255, 170, 60), w = 10 },
        }
        local function spawnPick(cx, cy)
            local r, acc, d = rand(1, 100), 0, PICK[1]
            for _, p in ipairs(PICK) do
                acc = acc + p.w
                if r <= acc then
                    d = p
                    break
                end
            end
            local f = rect(gameLayer, 26, 26, d.col, 0.55, true)
            stroke(f, d.col, 2)
            f.Position = UDim2.new(0, cx - 13, 0, cy - 13)
            emo(f, d.icon, 18).Position = UDim2.new(0, 4, 0, 4)
            picks[#picks + 1] = { f = f, d = d, x = cx - 13, y = cy - 13, ph = rand() * 6 }
        end

        -- ===== musuh =====
        local ETYPE = {
            meteor = { icon = "☄️", sz = 28, hp = 1, pts = 10, col = Color3.fromRGB(255, 140, 60) },
            alien  = { icon = "👾", sz = 24, hp = 1, pts = 20, col = Color3.fromRGB(190, 90, 255) },
            ufo    = { icon = "🛸", sz = 30, hp = 2, pts = 35, col = Color3.fromRGB(90, 230, 200) },
            rock   = { icon = "🪨", sz = 36, hp = 3, pts = 45, col = Color3.fromRGB(170, 160, 150) },
        }
        local function spawnEnemy()
            local r, kind = rand(1, 100), "meteor"
            if S.wave >= 3 and r > 90 then kind = "ufo"
            elseif S.wave >= 2 and r > 80 then kind = "rock"
            elseif r > (S.wave >= 2 and 52 or 78) then kind = "alien" end
            local d = ETYPE[kind]
            local x = rand(0, W - d.sz)
            if kind == "meteor" then x = rand(floor(W * 0.15), W + 10) end
            local e = { f = emo(gameLayer, d.icon, d.sz), kind = kind, d = d, x = x, y = -d.sz, bx = x,
                hp = d.hp, sz = d.sz, ph = rand() * 6.28, shootCD = 1 + rand() * 1.5, vx = 0 }
            local base = 42 + S.wave * 8
            if kind == "meteor" then e.vy = base * 1.15; e.vx = -(22 + rand(0, 25))
            elseif kind == "alien" then e.vy = base * 0.8
            elseif kind == "ufo" then e.vy = base * 0.5
            else e.vy = base * 0.55; e.vx = rand(-12, 12) end
            e.f.Position = UDim2.new(0, x, 0, -d.sz)
            enemies[#enemies + 1] = e
        end

        local function enemyShot(x, y)
            local f = rect(gameLayer, 7, 7, Color3.fromRGB(255, 80, 90), 0, true)
            stroke(f, Color3.fromRGB(255, 160, 170), 1)
            f.Position = UDim2.new(0, x - 3, 0, y)
            ebul[#ebul + 1] = { f = f, x = x - 3, y = y }
        end

        local function hurtPlayer()
            if S.inv > 0 or S.over then return end
            if S.shield then
                S.shield = false
                shieldF.Visible = false
                S.inv = 0.6
                floatText("🛡️ BLOCK", S.px, H - 70, CYAN, 11)
                return
            end
            S.lives = S.lives - 1
            S.inv = 1.2
            S.shake = 0.3
            S.combo = 0
            explode(S.px, H - 34, 30, Color3.fromRGB(255, 90, 90))
            updateHud()
        end

        local function killEnemy(e, ei)
            local cx, cy = e.x + e.sz / 2, e.y + e.sz / 2
            explode(cx, cy, e.sz, e.d.col)
            e.f:Destroy()
            table.remove(enemies, ei)
            S.kills = S.kills + 1
            if S.comboT > 0 then S.combo = min(5, S.combo + 1) else S.combo = 1 end
            S.comboT = 1.8
            local pts = e.d.pts * (1 + floor((S.combo - 1) / 2))
            S.score = S.score + pts
            floatText("+" .. pts, cx, cy - 8, GOLDC, 11)
            if rand(1, 100) <= (e.kind == "meteor" and 12 or 22) then spawnPick(cx, cy) end
            local nw = 1 + floor(S.kills / 12)
            if nw > S.wave then
                S.wave = nw
                banner("🌠 WAVE " .. nw)
            end
            updateHud()
        end

        local function nova()
            local f = rect(fxLayer, 10, 10, WHITE, 0.2, true)
            addFx(f, S.px, H - 40, 0, 0, 0.5, 10, 460, "frame")
            S.shake = 0.3
            for i = #enemies, 1, -1 do killEnemy(enemies[i], i) end
            for i = #ebul, 1, -1 do
                ebul[i].f:Destroy()
                table.remove(ebul, i)
            end
        end

        local function applyPick(p)
            local k = p.d.kind
            if k == "shield" then
                S.shield = true
                shieldF.Visible = true
                floatText("🛡️ PERISAI", S.px, H - 70, CYAN, 11)
            elseif k == "rapid" then
                S.rapid = 8
                floatText("⚡ RAPID FIRE", S.px, H - 70, GOLDC, 11)
            elseif k == "heart" then
                S.lives = min(5, S.lives + 1)
                floatText("❤️ +1 NYAWA", S.px, H - 70, Color3.fromRGB(255, 130, 150), 11)
            elseif k == "gem" then
                S.score = S.score + 50
                floatText("💎 +50", S.px, H - 70, CYAN, 11)
            else
                banner("🌟 NOVA!")
                nova()
            end
            updateHud()
        end

        -- ===== input =====
        local function setX(input)
            S.px = math.clamp(input.Position.X - board.AbsolutePosition.X, 15, W - 15)
        end
        table.insert(APP.conns, board.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                S.holding = true
                setX(input)
                fire()
            end
        end))
        table.insert(APP.conns, board.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
                setX(input)
            end
        end))
        table.insert(APP.conns, board.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                S.holding = false
            end
        end))

        banner("🚀 SIAP TERBANG!")

        local conn = RunService.Heartbeat:Connect(function(dt)
            if S.over then return end
            dt = min(dt, 0.05)
            S.t = S.t + dt
            local t = S.t

            -- latar
            for _, n in ipairs(nebs) do
                n.y = n.y + n.v * dt
                if n.y > H then n.y = -n.s; n.x = rand(-40, W - 80) end
                n.f.Position = UDim2.new(0, n.x, 0, n.y)
            end
            pl.y = pl.y + 7 * dt
            if pl.y > H + 10 then
                pl.y = -60
                pl.x = rand(10, W - 60)
                pl.idx = pl.idx % #PLANETS + 1
                planet.Text = PLANETS[pl.idx]
            end
            planet.Position = UDim2.new(0, pl.x, 0, pl.y)
            for _, s in ipairs(stars) do
                s.y = s.y + s.v * dt
                if s.y > H then s.y = -3; s.x = rand(0, W) end
                s.f.Position = UDim2.new(0, s.x, 0, s.y)
                s.f.BackgroundTransparency = 0.25 + 0.5 * (0.5 + 0.5 * sin(t * 3 + s.ph))
            end
            S.starCD = S.starCD - dt
            if S.starCD <= 0 then
                S.starCD = 2.5 + rand() * 3
                local f = rect(bgLayer, 2, 18, WHITE, 0, true)
                f.Rotation = 35
                shots[#shots + 1] = { f = f, x = rand(60, W), y = rand(-10, 60), t = 0 }
            end
            for i = #shots, 1, -1 do
                local s = shots[i]
                s.t = s.t + dt
                s.x = s.x - 140 * dt
                s.y = s.y + 200 * dt
                if s.t > 0.9 then
                    s.f:Destroy()
                    table.remove(shots, i)
                else
                    s.f.Position = UDim2.new(0, s.x, 0, s.y)
                    s.f.BackgroundTransparency = s.t / 0.9
                end
            end

            -- timer
            S.shootCD = max(0, S.shootCD - dt)
            S.inv = max(0, S.inv - dt)
            if S.rapid > 0 then S.rapid = max(0, S.rapid - dt) end
            if S.comboT > 0 then
                S.comboT = S.comboT - dt
                if S.comboT <= 0 then S.combo = 0 end
            end
            if S.holding then fire() end

            -- kapal
            ship.Position = UDim2.new(0, S.px - 15, 0, H - 50)
            shipIcon.TextTransparency = (S.inv > 0 and floor(t * 14) % 2 == 0) and 0.6 or 0
            shieldF.BackgroundTransparency = 0.8 + 0.1 * sin(t * 6)
            S.trailCD = S.trailCD - dt
            if S.trailCD <= 0 then
                S.trailCD = 0.04
                local p = rect(fxLayer, 5, 5, rand(1, 2) == 1 and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(255, 225, 90), 0.1, true)
                addFx(p, S.px + rand(-2, 2), H - 20, rand(-8, 8), 70, 0.35, 5, 1, "frame")
            end

            -- spawn
            S.spawnCD = S.spawnCD - dt
            if S.spawnCD <= 0 then
                spawnEnemy()
                S.spawnCD = max(0.28, 1.0 - S.wave * 0.07) + rand() * 0.25
            end

            -- peluru pemain
            for i = #bullets, 1, -1 do
                local b = bullets[i]
                b.y = b.y - 460 * dt
                if b.y < -16 then
                    b.f:Destroy()
                    table.remove(bullets, i)
                else
                    b.f.Position = UDim2.new(0, b.x, 0, b.y)
                end
            end

            -- musuh
            for i = #enemies, 1, -1 do
                local e = enemies[i]
                e.y = e.y + e.vy * dt
                if e.kind == "alien" then
                    e.x = e.bx + sin(t * 2.4 + e.ph) * 34
                elseif e.kind == "ufo" then
                    e.x = math.clamp(e.bx + sin(t * 1.3 + e.ph) * (W * 0.28), 0, W - e.sz)
                    e.shootCD = e.shootCD - dt
                    if e.shootCD <= 0 and e.y > 0 and e.y < H * 0.6 then
                        enemyShot(e.x + e.sz / 2, e.y + e.sz)
                        e.shootCD = 2.2
                    end
                else
                    e.x = e.x + e.vx * dt
                    if e.kind == "rock" then e.f.Rotation = (t * 50 + e.ph * 30) % 360 end
                end
                e.f.Position = UDim2.new(0, e.x, 0, e.y)
                if e.f.TextTransparency > 0 then e.f.TextTransparency = max(0, e.f.TextTransparency - dt * 4) end
                local cx, cy = e.x + e.sz / 2, e.y + e.sz / 2
                if abs(cx - S.px) < e.sz * 0.35 + 10 and abs(cy - (H - 34)) < e.sz * 0.35 + 12 then
                    explode(cx, cy, e.sz, e.d.col)
                    e.f:Destroy()
                    table.remove(enemies, i)
                    hurtPlayer()
                elseif e.y > H then
                    e.f:Destroy()
                    table.remove(enemies, i)
                    if e.kind ~= "meteor" then
                        S.lives = S.lives - 1
                        S.shake = 0.2
                        floatText("-❤️", e.x + e.sz / 2, H - 20, Color3.fromRGB(255, 110, 110), 12)
                        updateHud()
                    end
                elseif e.x < -e.sz - 10 or e.x > W + 40 then
                    e.f:Destroy()
                    table.remove(enemies, i)
                end
            end

            -- peluru vs musuh
            for bi = #bullets, 1, -1 do
                local b = bullets[bi]
                local bx, by = b.x + 2, b.y + 7
                for ei = #enemies, 1, -1 do
                    local e = enemies[ei]
                    if bx > e.x + 3 and bx < e.x + e.sz - 3 and by > e.y + 3 and by < e.y + e.sz - 3 then
                        b.f:Destroy()
                        table.remove(bullets, bi)
                        e.hp = e.hp - 1
                        if e.hp <= 0 then
                            killEnemy(e, ei)
                        else
                            e.f.TextTransparency = 0.7
                            addFx(rect(fxLayer, 8, 8, GOLDC, 0.2, true), bx, by, 0, 0, 0.18, 8, 2, "frame")
                        end
                        break
                    end
                end
            end

            -- peluru musuh
            for i = #ebul, 1, -1 do
                local b = ebul[i]
                b.y = b.y + 140 * dt
                b.f.Position = UDim2.new(0, b.x, 0, b.y)
                if abs(b.x + 3 - S.px) < 12 and abs(b.y + 3 - (H - 34)) < 14 then
                    b.f:Destroy()
                    table.remove(ebul, i)
                    hurtPlayer()
                elseif b.y > H then
                    b.f:Destroy()
                    table.remove(ebul, i)
                end
            end

            -- power-up
            for i = #picks, 1, -1 do
                local p = picks[i]
                p.y = p.y + 55 * dt
                p.f.Position = UDim2.new(0, p.x, 0, p.y)
                p.f.BackgroundTransparency = 0.55 + 0.2 * sin(t * 6 + p.ph)
                if abs(p.x + 13 - S.px) < 24 and abs(p.y + 13 - (H - 34)) < 26 then
                    p.f:Destroy()
                    table.remove(picks, i)
                    applyPick(p)
                elseif p.y > H then
                    p.f:Destroy()
                    table.remove(picks, i)
                end
            end

            -- partikel
            for i = #fxs, 1, -1 do
                local p = fxs[i]
                p.t = p.t + dt
                if p.t >= p.life or not p.f.Parent then
                    p.f:Destroy()
                    table.remove(fxs, i)
                else
                    local a = p.t / p.life
                    p.x = p.x + p.vx * dt
                    p.y = p.y + p.vy * dt
                    p.f.Position = UDim2.new(0, p.x, 0, p.y)
                    if p.s0 then
                        local s = p.s0 + (p.s1 - p.s0) * a
                        p.f.Size = UDim2.new(0, s, 0, s)
                    end
                    if p.kind == "text" then
                        p.f.TextTransparency = a * a
                        p.f.TextStrokeTransparency = 0.4 + 0.6 * a
                    else
                        p.f.BackgroundTransparency = a
                    end
                end
            end

            -- getar layar
            if S.shake > 0 then
                S.shake = max(0, S.shake - dt)
                local m = S.shake / 0.3 * 5
                board.Position = UDim2.new(0.5, -W / 2 + (rand() * 2 - 1) * m, 0, 26 + (rand() * 2 - 1) * m)
            else
                board.Position = BOARD_POS
            end

            -- status
            local parts = {}
            if S.shield then parts[#parts + 1] = "🛡️ PERISAI" end
            if S.rapid > 0 then parts[#parts + 1] = "⚡ " .. math.ceil(S.rapid) .. "s" end
            if S.combo >= 2 then parts[#parts + 1] = "🔥 COMBO x" .. S.combo end
            local txt = #parts > 0 and table.concat(parts, "   ") or "☄️ hindari meteor & tembak alien!"
            if txt ~= S.last then
                S.last = txt
                statusLbl.Text = txt
            end

            -- game over
            if S.lives <= 0 then
                S.over = true
                for _, p in ipairs(fxs) do pcall(function() p.f:Destroy() end) end
                ship.Visible = false
                local boom = emo(fxLayer, "💥", 70)
                boom.AnchorPoint = Vector2.new(0.5, 0.5)
                boom.Position = UDim2.new(0, S.px, 0, H - 34)
                banner("💀 GAME OVER")
                scoreLbl.Text = "GAME OVER — SKOR: " .. S.score
                scoreLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                finishGame(gui, S.score, 2.5)
            end
        end)
        table.insert(APP.conns, conn)
    end

    -- ============ MEMORY CARD ============
    local function openMemory()
        APP.recordStart("memory")
        local gui, body = makeGameWindow("🃏 MEMORY CARD", 320, 400)

        local turnLbl = newLabel(body, "PASANGAN: 0 / 8", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center)

        local N = 4
        local board = Instance.new("Frame")
        board.Size = UDim2.new(0, 280, 0, 280)
        board.Position = UDim2.new(0.5, -140, 0, 26)
        board.BackgroundTransparency = 1
        board.Parent = body

        local EMOJIS = { "🍎","🍌","🍇","🍓","🍒","🍑","🍍","🥝" }
        local cards = {}
        local data = {}
        for i = 1, 8 do
            table.insert(data, { id = i, e = EMOJIS[i] })
            table.insert(data, { id = i, e = EMOJIS[i] })
        end
        for i = #data, 2, -1 do
            local j = math.random(1, i)
            data[i], data[j] = data[j], data[i]
        end

        local state = { sel = {}, matches = 0, lock = false }

        for y = 1, N do
            for x = 1, N do
                local idx = (y - 1) * N + x
                local card = Instance.new("TextButton")
                card.Size = UDim2.new(0, 64, 0, 64)
                card.Position = UDim2.new(0, (x - 1) * 70 + 4, 0, (y - 1) * 70 + 4)
                card.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
                card.Text = "?"
                card.TextSize = 28
                card.Font = Enum.Font.GothamBlack
                card.TextColor3 = WHITE
                card.AutoButtonColor = false
                card.Parent = board
                corner(card, 6)
                cards[idx] = { btn = card, data = data[idx], open = false, done = false }
                card.MouseButton1Click:Connect(function()
                    local c = cards[idx]
                    if state.lock or c.open or c.done then return end
                    c.open = true
                    c.btn.Text = c.data.e
                    c.btn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
                    table.insert(state.sel, c)
                    if #state.sel == 2 then
                        state.lock = true
                        local a, b = state.sel[1], state.sel[2]
                        if a.data.id == b.data.id then
                            a.done = true
                            b.done = true
                            a.btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                            b.btn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
                            state.matches = state.matches + 1
                            turnLbl.Text = "PASANGAN: " .. state.matches .. " / 8"
                            state.sel = {}
                            state.lock = false
                            if state.matches >= 8 then
                                turnLbl.Text = "🎉 SEMUA PASANGAN KETEMU!"
                                turnLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
                                finishGame(gui, 100, 2)
                            end
                        else
                            task.delay(0.8, function()
                                a.open = false; b.open = false
                                a.btn.Text = "?"; b.btn.Text = "?"
                                a.btn.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
                                b.btn.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
                                state.sel = {}
                                state.lock = false
                            end)
                        end
                    end
                end)
            end
        end
    end

    -- ============ SIMON SAYS ============
    local function openSimon()
        APP.recordStart("simon")
        local gui, body = makeGameWindow("🎨 SIMON SAYS", 300, 360)

        local scoreLbl = newLabel(body, "LEVEL: 0", 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center)

        local COLORS = {
            Color3.fromRGB(240, 80, 100), Color3.fromRGB(80, 200, 120),
            Color3.fromRGB(240, 200, 60), Color3.fromRGB(80, 160, 240),
        }
        local btns = {}
        local positions = {
            { x = 0, y = 0 }, { x = 0.5, y = 0 },
            { x = 0, y = 0.5 }, { x = 0.5, y = 0.5 },
        }
        for i = 1, 4 do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0.5, -4, 0.5, -8)
            b.Position = UDim2.new(positions[i].x, 2, positions[i].y + 0.05, 2)
            b.BackgroundColor3 = COLORS[i]
            b.BackgroundTransparency = 0.6
            b.Text = ""
            b.AutoButtonColor = false
            b.Parent = body
            corner(b, 12)
            btns[i] = b
        end

        local state = { seq = {}, input = 0, level = 0, showing = false, over = false }

        local function flash(i, dur)
            btns[i].BackgroundTransparency = 0
            task.delay(dur or 0.3, function()
                if btns[i] and btns[i].Parent then btns[i].BackgroundTransparency = 0.6 end
            end)
        end

        local function playSeq()
            state.showing = true
            state.input = 0
            task.spawn(function()
                task.wait(0.5)
                for _, v in ipairs(state.seq) do
                    if not gui.Parent then return end
                    flash(v, 0.4)
                    task.wait(0.55)
                end
                state.showing = false
            end)
        end

        local function addNew()
            if state.over or not gui.Parent then return end
            state.level = state.level + 1
            scoreLbl.Text = "LEVEL: " .. state.level
            table.insert(state.seq, math.random(1, 4))
            playSeq()
        end

        for i = 1, 4 do
            btns[i].MouseButton1Click:Connect(function()
                if state.showing or state.over then return end
                flash(i, 0.2)
                state.input = state.input + 1
                if state.seq[state.input] ~= i then
                    state.over = true
                    scoreLbl.Text = "GAME OVER — LEVEL: " .. state.level
                    scoreLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                    finishGame(gui, state.level * 10, 2)
                    return
                end
                if state.input >= #state.seq then
                    task.delay(0.6, addNew)
                end
            end)
        end

        addNew()
    end

    -- ============ MINESWEEPER ============
    local function openMines()
        APP.recordStart("mines")
        local gui, body = makeGameWindow("💣 MINESWEEPER", 320, 400)

        local N = 8
        local MINES = 10
        local CELL = 34

        local stateLbl = newLabel(body, "💣 " .. MINES .. " bom", 11, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 20), Enum.TextXAlignment.Center)

        local board = Instance.new("Frame")
        local SIZE = N * CELL
        board.Size = UDim2.new(0, SIZE, 0, SIZE)
        board.Position = UDim2.new(0.5, -SIZE / 2, 0, 26)
        board.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
        board.BorderSizePixel = 0
        board.Parent = body
        corner(board, 4)

        local grid, btns = {}, {}
        for y = 1, N do
            grid[y] = {}
            for x = 1, N do
                grid[y][x] = { mine = false, open = false, count = 0, flagged = false }
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, CELL - 1, 0, CELL - 1)
                b.Position = UDim2.new(0, (x - 1) * CELL, 0, (y - 1) * CELL)
                b.BackgroundColor3 = Color3.fromRGB(60, 70, 100)
                b.Text = ""
                b.TextSize = 14
                b.Font = Enum.Font.GothamBlack
                b.TextColor3 = WHITE
                b.AutoButtonColor = false
                b.Parent = board
                corner(b, 3)
                btns[x .. "," .. y] = b
            end
        end

        local placed = 0
        while placed < MINES do
            local x, y = math.random(1, N), math.random(1, N)
            if not grid[y][x].mine then
                grid[y][x].mine = true
                placed = placed + 1
            end
        end
        for y = 1, N do
            for x = 1, N do
                if not grid[y][x].mine then
                    local c = 0
                    for dy = -1, 1 do
                        for dx = -1, 1 do
                            local nx, ny = x + dx, y + dy
                            if nx >= 1 and nx <= N and ny >= 1 and ny <= N and grid[ny][nx].mine then
                                c = c + 1
                            end
                        end
                    end
                    grid[y][x].count = c
                end
            end
        end

        local state = { over = false, opened = 0 }
        local COLORS_N = {
            Color3.new(1,1,1),
            Color3.fromRGB(80,180,255),
            Color3.fromRGB(80,220,120),
            Color3.fromRGB(240,100,100),
            Color3.fromRGB(180,100,240),
            Color3.fromRGB(240,200,60),
            Color3.fromRGB(60,220,220),
            Color3.fromRGB(180,180,180),
        }

        local function revealFlood(x, y)
            if x < 1 or x > N or y < 1 or y > N then return end
            local c = grid[y][x]
            if c.open or c.flagged or c.mine then return end
            c.open = true
            state.opened = state.opened + 1
            local b = btns[x .. "," .. y]
            b.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
            if c.count > 0 then
                b.Text = tostring(c.count)
                b.TextColor3 = COLORS_N[c.count] or Color3.new(1,1,1)
            else
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if not (dx == 0 and dy == 0) then revealFlood(x + dx, y + dy) end
                    end
                end
            end
        end

        for y = 1, N do
            for x = 1, N do
                btns[x .. "," .. y].MouseButton1Click:Connect(function()
                    if state.over then return end
                    local c = grid[y][x]
                    if c.open or c.flagged then return end
                    if c.mine then
                        state.over = true
                        for yy = 1, N do
                            for xx = 1, N do
                                if grid[yy][xx].mine then
                                    local bb = btns[xx .. "," .. yy]
                                    bb.Text = "💣"
                                    bb.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
                                end
                            end
                        end
                        stateLbl.Text = "💥 KENA BOM!"
                        stateLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                        finishGame(gui, 0, 2.5)
                        return
                    end
                    revealFlood(x, y)
                    if state.opened >= N*N - MINES then
                        state.over = true
                        stateLbl.Text = "🎉 MENANG!"
                        stateLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
                        finishGame(gui, 200, 2.5)
                    end
                end)
            end
        end
    end

    -- ============ BUAT KARTU GAME ============
    local OPEN_FN = {
        snake = openSnake,
        ["2048"] = open2048,
        ttt = openTTT,
        pong = openPong,
        shooter = openShooter,
        memory = openMemory,
        simon = openSimon,
        mines = openMines,
    }

    for i, g in ipairs(GAME_LIST) do
        local card = Instance.new("TextButton")
        card.LayoutOrder = i
        card.BackgroundColor3 = BG_DARK
        card.BorderSizePixel = 0
        card.Text = ""
        card.AutoButtonColor = false
        card:SetAttribute("UHKey", "APLIKASI|game_" .. g.id)
        card:SetAttribute("UHLabel", g.icon .. " " .. g.name)
        card.Parent = grid
        corner(card, 10)
        stroke(card, g.color, 2)

        newLabel(card, g.icon, 32, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 0, 0, 6), UDim2.new(0.4, 0, 0, 44), Enum.TextXAlignment.Center)
        local name = newLabel(card, g.name, 12, Enum.Font.GothamBlack, WHITE,
            UDim2.new(0, 8, 0, 52), UDim2.new(1, -16, 0, 18), Enum.TextXAlignment.Left)
        name.TextTruncate = Enum.TextTruncate.AtEnd

        local playsLbl = newLabel(card, "", 8, Enum.Font.GothamBold, g.color,
            UDim2.new(0, 8, 0, 72), UDim2.new(0.5, -8, 0, 12), Enum.TextXAlignment.Left)
        local timeLbl = newLabel(card, "", 8, Enum.Font.GothamBold, GREY,
            UDim2.new(0.5, 0, 0, 72), UDim2.new(0.5, -8, 0, 12), Enum.TextXAlignment.Right)
        local bestLbl = newLabel(card, "", 8, Enum.Font.GothamBold, GREEN,
            UDim2.new(0, 8, 0, 86), UDim2.new(1, -16, 0, 12), Enum.TextXAlignment.Left)

        gameCards[g.id] = { id = g.id, card = card, playsLbl = playsLbl, timeLbl = timeLbl, bestLbl = bestLbl, color = g.color }

        card.MouseButton1Click:Connect(function()
            if APP.current then return end
            local fn = OPEN_FN[g.id]
            if fn then fn() end
        end)
    end

    local resetStatBtn = makeButton(appPage, "🗑️ RESET SEMUA STATISTIK", 10)
    resetStatBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 50)
    resetStatBtn.MouseButton1Click:Connect(function()
        for _, g in ipairs(GAME_LIST) do
            APP.stats[g.id] = { plays = 0, totalTime = 0, best = 0, totalScore = 0 }
        end
        APP.save()
        refreshCards()
    end)

    APP.load()
    refreshCards()
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
logoBtn.Text = "💲"
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
        { id = "galaxy", name = "Galaksi", icon = "🌀",
            sw = { rgb(8, 4, 22), rgb(190, 120, 255), rgb(255, 210, 160) },
            rim = { rgb(215, 175, 255), 0.45 },
            pal = mkPal({ {6,4,16}, {16,10,36}, {30,18,64}, {196,146,255}, {126,100,255}, {44,122,172}, {192,182,226}, {9,6,22},
                {18,10,40}, {42,26,86}, {28,16,62}, {132,92,236}, {255,132,192}, {204,154,255} }) },
        { id = "solar", name = "Tata Surya", icon = "🪐",
            sw = { rgb(6, 8, 22), rgb(255, 170, 60), rgb(80, 150, 255) },
            rim = { rgb(255, 205, 125), 0.5 },
            pal = mkPal({ {4,5,14}, {10,14,30}, {20,28,56}, {255,200,104}, {255,168,58}, {48,132,92}, {192,198,216}, {6,8,20},
                {12,16,34}, {28,36,70}, {20,26,52}, {72,122,222}, {255,150,58}, {255,202,124} }) },
        { id = "saturn", name = "Saturnus", icon = "🌕",
            sw = { rgb(20, 9, 14), rgb(226, 166, 106), rgb(110, 160, 210) },
            rim = { rgb(244, 198, 144), 0.5 },
            pal = mkPal({ {20,10,12}, {40,20,22}, {70,36,34}, {242,192,132}, {226,160,96}, {120,100,62}, {224,202,182}, {26,13,15},
                {34,18,20}, {74,44,40}, {54,30,30}, {200,140,86}, {110,160,210}, {244,198,142} }) },
        { id = "neon", name = "Neon Retro", icon = "🌴",
            sw = { rgb(14, 4, 32), rgb(255, 60, 200), rgb(0, 230, 255) },
            rim = { rgb(255, 100, 220), 0.35 },
            pal = mkPal({ {10,4,24}, {26,8,50}, {50,14,84}, {255,64,204}, {0,226,255}, {0,150,172}, {204,172,232}, {13,5,30},
                {22,8,44}, {56,18,92}, {40,12,70}, {200,42,162}, {0,190,232}, {255,96,214} }) },
        { id = "lava", name = "Lava", icon = "🌋",
            sw = { rgb(40, 6, 6), rgb(255, 110, 20), rgb(255, 200, 70) },
            rim = { rgb(255, 150, 70), 0.45 },
            pal = mkPal({ {20,5,4}, {44,10,8}, {78,20,12}, {255,120,40}, {226,84,30}, {150,70,20}, {220,184,170}, {26,6,5}, {34,8,6}, {90,26,14}, {64,18,10}, {200,70,28}, {255,170,40}, {255,140,60} }) },
        { id = "snow", name = "Salju", icon = "❄️",
            sw = { rgb(8, 24, 60), rgb(90, 170, 235), rgb(240, 248, 255) },
            rim = { rgb(190, 232, 255), 0.5 },
            pal = mkPal({ {10,22,44}, {18,40,76}, {30,66,112}, {170,225,255}, {90,170,235}, {50,130,170}, {200,224,240}, {12,28,56}, {14,32,62}, {34,72,122}, {24,52,96}, {70,150,220}, {150,210,250}, {190,232,255} }) },
        { id = "rain", name = "Hujan Petir", icon = "🌧️",
            sw = { rgb(6, 10, 20), rgb(78, 124, 180), rgb(170, 205, 245) },
            rim = { rgb(140, 180, 225), 0.55 },
            pal = mkPal({ {10,13,20}, {22,28,40}, {38,48,66}, {120,170,220}, {78,124,180}, {50,110,120}, {170,184,200}, {14,18,28}, {16,21,32}, {34,44,62}, {26,34,50}, {70,110,160}, {130,170,210}, {140,180,225} }) },
        { id = "desert", name = "Gurun", icon = "🏜️",
            sw = { rgb(120, 60, 40), rgb(236, 138, 74), rgb(255, 230, 170) },
            rim = { rgb(255, 200, 120), 0.5 },
            pal = mkPal({ {44,24,14}, {74,40,22}, {112,64,36}, {255,196,110}, {232,150,70}, {140,120,50}, {238,214,184}, {52,28,16}, {60,32,18}, {120,70,40}, {92,52,30}, {210,130,60}, {240,180,90}, {255,200,120} }) },
        { id = "cyber", name = "Cyberpunk", icon = "🌆",
            sw = { rgb(22, 4, 44), rgb(255, 60, 190), rgb(0, 230, 255) },
            rim = { rgb(255, 230, 60), 0.35 },
            pal = mkPal({ {10,4,22}, {24,8,46}, {44,12,74}, {255,230,60}, {0,230,255}, {0,160,170}, {200,180,225}, {14,6,30}, {20,6,40}, {54,14,86}, {38,10,64}, {240,40,150}, {0,200,230}, {255,240,90} }) },
        { id = "candy", name = "Permen", icon = "🍭",
            sw = { rgb(255, 120, 180), rgb(150, 110, 230), rgb(70, 170, 230) },
            rim = { rgb(255, 215, 235), 0.4 },
            pal = mkPal({ {90,40,90}, {120,60,120}, {150,84,150}, {255,200,230}, {255,130,190}, {90,180,150}, {250,220,240}, {100,46,100}, {108,52,108}, {170,100,170}, {140,76,140}, {255,120,180}, {120,200,255}, {255,210,235} }) },
        { id = "city", name = "Kota Malam", icon = "🏙️",
            sw = { rgb(10, 14, 40), rgb(80, 62, 120), rgb(255, 210, 110) },
            rim = { rgb(255, 220, 140), 0.5 },
            pal = mkPal({ {8,10,28}, {16,20,50}, {28,34,76}, {255,210,110}, {240,180,80}, {70,120,100}, {190,196,226}, {10,12,32}, {12,16,40}, {34,40,88}, {24,30,66}, {90,100,190}, {255,190,90}, {255,220,140} }) },
        { id = "thunder", name = "Petir Ungu", icon = "⚡",
            sw = { rgb(14, 6, 40), rgb(140, 90, 240), rgb(240, 220, 90) },
            rim = { rgb(200, 160, 255), 0.4 },
            pal = mkPal({ {10,4,24}, {22,10,50}, {40,18,84}, {190,140,255}, {140,90,240}, {80,70,170}, {200,186,236}, {12,6,30}, {18,8,42}, {50,24,100}, {34,16,72}, {120,70,230}, {240,220,90}, {200,160,255} }) },
        { id = "gold", name = "Emas Mewah", icon = "👑",
            sw = { rgb(10, 8, 4), rgb(200, 150, 50), rgb(255, 226, 130) },
            rim = { rgb(245, 205, 110), 0.4 },
            pal = mkPal({ {10,8,4}, {28,22,10}, {52,40,16}, {240,196,90}, {200,150,50}, {120,110,50}, {214,200,170}, {14,11,6}, {20,15,7}, {58,44,18}, {42,32,14}, {190,140,44}, {250,214,110}, {245,205,110} }) },
        { id = "autumn", name = "Musim Gugur", icon = "🍁",
            sw = { rgb(60, 24, 16), rgb(226, 120, 44), rgb(250, 190, 110) },
            rim = { rgb(255, 180, 90), 0.5 },
            pal = mkPal({ {40,18,10}, {70,30,16}, {108,50,24}, {255,170,70}, {226,120,44}, {130,110,40}, {236,206,180}, {46,20,12}, {56,24,12}, {116,54,26}, {88,40,20}, {210,100,36}, {240,170,60}, {255,180,90} }) },
        { id = "moon", name = "Bulan Purnama", icon = "🌙",
            sw = { rgb(8, 12, 34), rgb(150, 170, 230), rgb(250, 248, 220) },
            rim = { rgb(230, 230, 170), 0.45 },
            pal = mkPal({ {8,12,34}, {14,22,56}, {26,40,86}, {230,230,170}, {150,170,230}, {80,130,130}, {196,204,228}, {10,16,40}, {12,18,46}, {30,46,96}, {20,32,72}, {90,110,190}, {240,230,160}, {210,215,250} }) },
        { id = "rainbow", name = "Pelangi", icon = "🌈",
            sw = { rgb(255, 70, 70), rgb(80, 220, 110), rgb(120, 90, 240) },
            rim = { rgb(255, 255, 255), 0.35 },
            pal = mkPal({ {30,20,50}, {46,30,76}, {70,44,110}, {255,255,255}, {255,120,200}, {70,190,140}, {226,214,240}, {34,22,56}, {40,26,66}, {80,52,126}, {60,40,96}, {240,100,160}, {90,190,255}, {255,230,120} }) },
        { id = "abyss", name = "Laut Dalam", icon = "🐙",
            sw = { rgb(2, 12, 22), rgb(40, 190, 200), rgb(200, 110, 255) },
            rim = { rgb(110, 245, 235), 0.4 },
            pal = mkPal({ {2,12,22}, {4,26,44}, {8,48,72}, {80,240,230}, {40,190,200}, {30,140,120}, {150,204,214}, {3,16,28}, {3,18,32}, {8,52,80}, {6,38,60}, {30,170,190}, {200,110,255}, {110,245,235} }) },
        { id = "fireworks", name = "Kembang Api", icon = "🎆",
            sw = { rgb(6, 4, 20), rgb(255, 100, 150), rgb(255, 200, 70) },
            rim = { rgb(255, 170, 110), 0.4 },
            pal = mkPal({ {6,4,20}, {14,8,40}, {30,16,72}, {255,190,80}, {255,100,150}, {70,160,120}, {206,190,230}, {9,6,26}, {10,6,32}, {40,20,90}, {26,14,62}, {220,70,150}, {255,200,70}, {255,170,110} }) },
        { id = "blueflame", name = "Api Biru", icon = "🔵",
            sw = { rgb(3, 8, 24), rgb(40, 150, 250), rgb(220, 250, 255) },
            rim = { rgb(140, 225, 255), 0.4 },
            pal = mkPal({ {3,8,24}, {6,18,52}, {10,34,86}, {110,220,255}, {40,150,250}, {20,130,160}, {160,200,236}, {4,11,32}, {5,14,40}, {12,40,100}, {8,28,74}, {30,130,240}, {140,230,255}, {140,225,255} }) },
        { id = "firefly", name = "Malam Kunang", icon = "🏕️",
            sw = { rgb(5, 16, 22), rgb(150, 210, 70), rgb(240, 255, 150) },
            rim = { rgb(215, 255, 130), 0.5 },
            pal = mkPal({ {5,12,16}, {9,24,28}, {15,40,44}, {200,240,90}, {150,210,70}, {40,110,60}, {160,190,180}, {7,16,20},
                {8,20,24}, {18,50,50}, {12,34,38}, {90,160,60}, {230,200,70}, {200,240,100} }) },
        { id = "meteor", name = "Hujan Meteor", icon = "☄️",
            sw = { rgb(6, 6, 26), rgb(255, 140, 70), rgb(130, 110, 255) },
            rim = { rgb(255, 190, 130), 0.45 },
            pal = mkPal({ {6,6,20}, {12,12,38}, {22,22,60}, {255,170,90}, {255,140,70}, {60,120,90}, {180,176,210}, {8,8,26},
                {10,10,30}, {30,24,70}, {20,16,52}, {200,100,60}, {255,190,90}, {255,170,100} }) },
        { id = "coral", name = "Terumbu Karang", icon = "🐠",
            sw = { rgb(4, 60, 90), rgb(255, 120, 110), rgb(120, 230, 220) },
            rim = { rgb(255, 180, 170), 0.5 },
            pal = mkPal({ {4,22,34}, {8,40,58}, {14,62,84}, {255,130,120}, {255,110,110}, {30,150,130}, {170,214,220}, {5,28,42},
                {6,30,46}, {16,70,96}, {10,52,74}, {240,120,110}, {255,190,100}, {255,150,140} }) },
        { id = "gear", name = "Mesin Uap", icon = "⚙️",
            sw = { rgb(30, 18, 8), rgb(200, 130, 50), rgb(240, 205, 130) },
            rim = { rgb(240, 190, 110), 0.45 },
            pal = mkPal({ {18,11,6}, {40,26,14}, {66,44,24}, {214,150,70}, {200,130,50}, {90,110,50}, {206,190,164}, {24,15,8},
                {30,19,10}, {70,46,24}, {52,34,18}, {170,110,50}, {230,170,80}, {220,160,80} }) },
        { id = "matcha", name = "Matcha Latte", icon = "🍵",
            sw = { rgb(150, 190, 120), rgb(70, 110, 76), rgb(240, 250, 200) },
            rim = { rgb(235, 250, 190), 0.4 },
            pal = mkPal({ {28,46,34}, {44,70,50}, {64,98,70}, {200,230,150}, {170,210,120}, {70,130,80}, {210,226,200}, {32,52,38},
                {36,58,42}, {70,106,76}, {54,86,62}, {120,170,90}, {230,200,130}, {200,232,160} }) },
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

    -- bintang jatuh (dipakai tema luar angkasa)
    local function shoot(period, delay0)
        local sh = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 46, 0, 1),
            BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.1, BorderSizePixel = 0,
            Rotation = -40, Visible = false })
        ugrad(sh, 0, nil, { { 0, 0 }, { 1, 1 } })
        table.insert(anims, function(t)
            local p = ((t + delay0) % period) / period
            if p < 0.12 then
                local q = p / 0.12
                sh.Visible = true
                sh.Position = UDim2.new(0.95 - q * 0.55, 0, 0.04 + q * 0.38, 0)
            else
                sh.Visible = false
            end
        end)
    end

    -- 10) GALAKSI: galaksi spiral berputar + inti bercahaya + bintang berkedip
    build.galaxy = function()
        setBase(150, { { 0, rgb(6, 3, 18) }, { 0.5, rgb(16, 8, 38) }, { 1, rgb(4, 3, 14) } })
        stars(56, 31, 2)
        local cx, cy = 0.5, 0.4
        local glow = blob(cx, cy, 300, rgb(150, 80, 230), 6)
        local spin = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, 0),
            Size = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0 })
        local rnd = Random.new(77)
        for arm = 0, 2 do
            for i = 1, 26 do
                local r = 8 + i * 4.8
                local th = i * 0.27 + arm * 2.094 + rnd:NextNumber(-0.13, 0.13)
                local k = i / 26
                local sz = (i < 6) and 4 or rnd:NextInteger(2, 4)
                local d = circle(0.5, 0.5, sz, rgb(math.floor(255 - 120 * k), math.floor(205 - 75 * k), math.floor(150 + 105 * k)),
                    0.05 + 0.5 * k, spin)
                d.Position = UDim2.new(0.5, math.cos(th) * r, 0.5, math.sin(th) * r)
            end
        end
        local halo = blob(cx, cy, 90, rgb(255, 230, 190), 6)
        local core = circle(cx, cy, 20, rgb(255, 242, 214), 0.05)
        table.insert(anims, function(t)
            spin.Rotation = t * 8
            local s = 20 + math.sin(t * 1.4) * 3
            core.Size = UDim2.new(0, s, 0, s)
            glow.Position = UDim2.new(cx + math.sin(t * 0.2) * 0.02, 0, cy + math.cos(t * 0.17) * 0.02, 0)
        end)
        shoot(7, 0)
        shoot(11, 4)
    end

    -- 11) TATA SURYA: matahari + 7 planet mengorbit (bulan, cincin Saturnus) + bintang
    build.solar = function()
        setBase(100, { { 0, rgb(3, 4, 14) }, { 0.5, rgb(8, 10, 26) }, { 1, rgb(3, 3, 12) } })
        stars(54, 5, 2)
        local cx, cy, SQ = 0.5, 0.42, 0.36
        blob(cx, cy, 180, rgb(255, 150, 40), 7)
        local sun = circle(cx, cy, 32, rgb(255, 205, 90), 0.02)
        mk("UIStroke", { Thickness = 2, Color = rgb(255, 150, 40), Transparency = 0.4 }, sun)
        table.insert(anims, function(t)
            local sz = 32 + math.sin(t * 1.6) * 2.5
            sun.Size = UDim2.new(0, sz, 0, sz)
        end)
        local P = {
            { 44, 5, rgb(176, 166, 156), 1.30 }, { 62, 8, rgb(240, 176, 96), 0.95 },
            { 82, 9, rgb(84, 150, 255), 0.75, "moon" }, { 102, 7, rgb(236, 104, 72), 0.60 },
            { 124, 15, rgb(226, 190, 140), 0.38 }, { 146, 12, rgb(236, 216, 164), 0.29, "ring" },
            { 164, 9, rgb(140, 212, 232), 0.22 },
        }
        for i, p in ipairs(P) do
            local r, sz, col, sp, kind = p[1], p[2], p[3], p[4], p[5]
            local orb = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(cx, 0, cy, 0),
                Size = UDim2.new(0, r * 2, 0, r * 2 * SQ), BackgroundTransparency = 1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, orb)
            mk("UIStroke", { Thickness = 1, Color = rgb(255, 255, 255), Transparency = 0.86 }, orb)
            local pl = circle(cx, cy, sz, col, 0)
            local ring, moon
            if kind == "ring" then
                ring = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz * 2.3, 0, sz * 0.7),
                    BackgroundTransparency = 1, BorderSizePixel = 0 })
                mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
                mk("UIStroke", { Thickness = 2, Color = rgb(232, 204, 150), Transparency = 0.2 }, ring)
            elseif kind == "moon" then
                moon = circle(cx, cy, 3, rgb(225, 225, 232), 0)
            end
            local ph = i * 1.1
            table.insert(anims, function(t)
                local a = ph + t * sp * 0.5
                local px, py = math.cos(a) * r, math.sin(a) * r * SQ
                pl.Position = UDim2.new(cx, px, cy, py)
                pl.ZIndex = (py < 0) and 0 or 2
                if ring then
                    ring.Position = pl.Position
                    ring.ZIndex = (py < 0) and 0 or 3
                end
                if moon then
                    local b = t * 3
                    moon.Position = UDim2.new(cx, px + math.cos(b) * 10, cy, py + math.sin(b) * 4)
                    moon.ZIndex = (py < 0) and 0 or 3
                end
            end)
        end
        shoot(9, 2)
    end

    -- 12) SATURNUS: planet besar bercincin, pita awan bergeser, bulan mengorbit di depan/belakang
    build.saturn = function()
        setBase(160, { { 0, rgb(20, 9, 14) }, { 0.5, rgb(40, 18, 22) }, { 1, rgb(12, 6, 10) } })
        stars(44, 12, 2)
        local cx, cy = 0.5, 0.4
        local glow = blob(cx, cy, 270, rgb(255, 170, 100), 6)
        local function ellipse(parent, w, h, th, col, tr, px, py, zi)
            local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(px, 0, py, 0),
                Size = UDim2.new(0, w, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = zi }, parent)
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            mk("UIStroke", { Thickness = th, Color = col, Transparency = tr }, f)
            return f
        end
        -- cincin (bagian belakang, ketutup planet)
        ellipse(deco, 252, 64, 7, rgb(214, 176, 128), 0.25, cx, cy, 1)
        ellipse(deco, 206, 50, 3, rgb(240, 210, 160), 0.3, cx, cy, 1)
        -- planet
        local planet = circle(cx, cy, 124, rgb(222, 166, 106), 0)
        planet.ZIndex = 2
        local bands = ugrad(planet, 90, { { 0, rgb(188, 128, 82) }, { 0.2, rgb(242, 198, 142) }, { 0.4, rgb(206, 148, 96) },
            { 0.6, rgb(248, 208, 152) }, { 0.8, rgb(196, 136, 88) }, { 1, rgb(156, 104, 68) } })
        local shade = circle(cx, cy, 124, rgb(0, 0, 0), 0)
        shade.ZIndex = 3
        ugrad(shade, 0, nil, { { 0, 1 }, { 0.5, 0.82 }, { 1, 0.15 } })
        -- cincin (bagian depan = separuh bawah saja, di atas planet)
        local clip = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(cx, 0, cy, 0),
            Size = UDim2.new(0, 280, 0, 60), BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, ZIndex = 4 })
        ellipse(clip, 252, 64, 7, rgb(214, 176, 128), 0.25, 0.5, 0, 4)
        ellipse(clip, 206, 50, 3, rgb(240, 210, 160), 0.3, 0.5, 0, 4)
        -- bulan
        local moon = circle(cx, cy, 12, rgb(206, 204, 210), 0)
        local moon2 = circle(cx, cy, 6, rgb(150, 190, 235), 0)
        table.insert(anims, function(t)
            bands.Offset = Vector2.new(0, math.sin(t * 0.3) * 0.04)
            local a = t * 0.55
            moon.Position = UDim2.new(cx, math.cos(a) * 150, cy, math.sin(a) * 44)
            moon.ZIndex = (math.sin(a) > 0) and 5 or 0
            local b = t * 0.9 + 2
            moon2.Position = UDim2.new(cx, math.cos(b) * 112, cy, math.sin(b) * 30 - 36)
            moon2.ZIndex = (math.sin(b) > 0) and 5 or 0
            glow.Position = UDim2.new(cx, 0, cy + math.sin(t * 0.4) * 0.015, 0)
        end)
        shoot(8, 1)
    end

    -- 13) NEON RETRO: matahari synthwave + grid jalan yang terus bergerak ke depan
    build.neon = function()
        setBase(90, { { 0, rgb(14, 4, 32) }, { 0.55, rgb(46, 8, 76) }, { 1, rgb(10, 3, 24) } })
        stars(44, 9, 2, 0.5)
        local hz = 0.56
        local sun = circle(0.5, 0.36, 132, rgb(255, 90, 170), 0)
        ugrad(sun, 90, { { 0, rgb(255, 224, 96) }, { 0.5, rgb(255, 92, 154) }, { 1, rgb(184, 44, 204) } })
        blob(0.5, 0.36, 230, rgb(255, 70, 190), 6)
        local ground = mk("Frame", { Position = UDim2.new(0, 0, hz, 0), Size = UDim2.new(1, 0, 1 - hz, 0),
            BackgroundColor3 = rgb(18, 4, 44), BackgroundTransparency = 0.1, BorderSizePixel = 0 })
        ugrad(ground, 90, nil, { { 0, 0.5 }, { 1, 0 } })
        mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, hz, 0), Size = UDim2.new(1, 0, 0, 3),
            BackgroundColor3 = rgb(0, 236, 255), BackgroundTransparency = 0.15, BorderSizePixel = 0 })
        -- garis menuju titik hilang
        local L = 330
        for j = -7, 7 do
            local th = j * 0.17
            mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, math.sin(th) * L / 2, hz, math.cos(th) * L / 2),
                Size = UDim2.new(0, 1, 0, L), Rotation = -math.deg(th),
                BackgroundColor3 = rgb(255, 64, 204), BackgroundTransparency = 0.45, BorderSizePixel = 0 })
        end
        -- garis melintang yang bergerak mendekat
        local N = 9
        local lines = {}
        for i = 1, N do
            lines[i] = mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = rgb(255, 64, 204),
                BorderSizePixel = 0, BackgroundTransparency = 0.4 })
        end
        table.insert(anims, function(t)
            for i = 1, N do
                local u = (t * 0.22 + i / N) % 1
                lines[i].Position = UDim2.new(0, 0, hz + u * u * (1 - hz), 0)
                lines[i].BackgroundTransparency = 0.25 + (1 - u) * 0.6
            end
            local s = 132 + math.sin(t * 1.3) * 5
            sun.Size = UDim2.new(0, s, 0, s)
        end)
        shoot(10, 3)
    end

    -- ==================== 15 TEMA BARU ====================
    -- partikel umum: jatuh (dir=1) / naik (dir=-1), bisa teks emoji atau lingkaran/persegi panjang
    build._particles = function(n, seed, o)
        local rnd = Random.new(seed)
        for _ = 1, n do
            local sz = rnd:NextInteger(o.s1, o.s2)
            local e
            if o.glyph then
                e = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz, 0, sz),
                    BackgroundTransparency = 1, Text = o.glyph[rnd:NextInteger(1, #o.glyph)], TextSize = sz,
                    TextTransparency = o.tr or 0.2 })
            elseif o.rect then
                e = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, o.w or 1, 0, sz),
                    BackgroundColor3 = o.color, BackgroundTransparency = o.tr or 0.4, BorderSizePixel = 0,
                    Rotation = o.angle or 0 })
            else
                e = circle(0.5, 0.5, sz, o.color, o.tr or 0.3)
            end
            local x0, sp, ph = rnd:NextNumber(), rnd:NextNumber(o.sp1, o.sp2), rnd:NextNumber(0, 10)
            table.insert(anims, function(t)
                local p = (t * sp + ph) % 1.2 - 0.1
                if o.dir < 0 then p = 1 - p end
                local x = x0 + math.sin(t * (o.swf or 1) + ph) * (o.sway or 0.03) + p * (o.drift or 0)
                e.Position = UDim2.new(x % 1, 0, p, 0)
                if o.rot then e.Rotation = (t * o.rot + ph * 40) % 360 end
            end)
        end
    end

    -- kota: gedung siluet + jendela menyala berkedip
    build._skyline = function(seed, n, col, hMin, hMax, wins, base)
        local rnd = Random.new(seed)
        local lit = {}
        for i = 0, n - 1 do
            local h = rnd:NextInteger(hMin, hMax)
            local b = mk("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(i / n, 0, base, 0),
                Size = UDim2.new(1 / n, 1, 0, h), BackgroundColor3 = col, BorderSizePixel = 0 })
            if wins then
                for r = 0, math.floor(h / 11) - 1 do
                    for c = 0, 2 do
                        if rnd:NextNumber() < 0.45 then
                            local w = mk("Frame", { Position = UDim2.new(0, 5 + c * 9, 0, 6 + r * 11),
                                Size = UDim2.new(0, 4, 0, 5), BackgroundColor3 = wins[rnd:NextInteger(1, #wins)],
                                BackgroundTransparency = 0.15, BorderSizePixel = 0 }, b)
                            if rnd:NextNumber() < 0.18 then table.insert(lit, { w, rnd:NextNumber(0, 6), rnd:NextNumber(0.5, 2) }) end
                        end
                    end
                end
            end
        end
        table.insert(anims, function(t)
            for i = 1, #lit do
                local l = lit[i]
                l[1].BackgroundTransparency = (math.sin(t * l[3] + l[2]) > 0.3) and 0.1 or 0.9
            end
        end)
    end

    -- ubur-ubur bercahaya
    build._jelly = function(x, y, size, col, ph)
        local g = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(x, 0, y, 0),
            Size = UDim2.new(0, size, 0, size * 1.8), BackgroundTransparency = 1, BorderSizePixel = 0 })
        local us = mk("UIScale", {}, g)
        local dome = mk("Frame", { Size = UDim2.new(1, 0, 0, size * 0.75), BackgroundColor3 = col,
            BackgroundTransparency = 0.45, BorderSizePixel = 0 }, g)
        mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dome)
        mk("UIStroke", { Thickness = 1.5, Color = col, Transparency = 0.2 }, dome)
        ugrad(dome, 90, nil, { { 0, 0.1 }, { 1, 0.7 } })
        local tents = {}
        for i = 1, 5 do
            local tn = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new((i - 0.5) / 5, 0, 0, size * 0.62),
                Size = UDim2.new(0, 2, 0, size * 0.95), BackgroundColor3 = col, BackgroundTransparency = 0.5,
                BorderSizePixel = 0 }, g)
            ugrad(tn, 90, nil, { { 0, 0.2 }, { 1, 1 } })
            tents[i] = tn
        end
        table.insert(anims, function(t)
            local k = math.sin(t * 1.6 + ph)
            us.Scale = 1 + k * 0.07
            g.Position = UDim2.new(x + math.sin(t * 0.3 + ph) * 0.05, 0, y + math.sin(t * 0.5 + ph) * 0.05, 0)
            for i = 1, 5 do tents[i].Rotation = math.sin(t * 1.4 + ph + i) * 9 end
        end)
    end

    -- 16) LAVA: gunung api, lava bercahaya, bara api naik
    build.lava = function()
        setBase(90, { { 0, rgb(36, 6, 6) }, { 0.6, rgb(118, 22, 8) }, { 1, rgb(255, 110, 20) } })
        stars(14, 3, 2, 0.35)
        local glow = blob(0.5, 1.0, 340, rgb(255, 120, 20), 7)
        local peak = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1.05, 0),
            Size = UDim2.new(0, 270, 0, 270), Rotation = 45, BackgroundColor3 = rgb(22, 7, 6), BorderSizePixel = 0 })
        mk("UICorner", { CornerRadius = UDim.new(0, 16) }, peak)
        local crater = circle(0.5, 0.66, 26, rgb(255, 150, 40), 0.1)
        local cglow = blob(0.5, 0.66, 80, rgb(255, 130, 30), 6)
        for i = 0, 5 do
            local w = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 90, 0, 60),
                BackgroundColor3 = i % 2 == 0 and rgb(255, 90, 20) or rgb(255, 160, 40), BackgroundTransparency = 0.25,
                BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, w)
            table.insert(anims, function(t)
                w.Position = UDim2.new(0, ((i * 62 + t * (14 + i * 3)) % 400) - 50, 0.96, math.sin(t * 1.6 + i) * 3)
            end)
        end
        build._particles(26, 51, { s1 = 2, s2 = 5, color = rgb(255, 170, 60), tr = 0.15, dir = -1, sp1 = 0.06, sp2 = 0.16, sway = 0.04, swf = 1.3 })
        build._particles(5, 52, { glyph = { "🔥" }, s1 = 14, s2 = 20, dir = -1, sp1 = 0.05, sp2 = 0.1, sway = 0.03, tr = 0.35 })
        table.insert(anims, function(t)
            local s = 340 + math.sin(t * 1.5) * 16
            glow.Size = UDim2.new(0, s, 0, s)
            crater.BackgroundTransparency = 0.1 + (math.sin(t * 3) + 1) * 0.12
            cglow.Size = UDim2.new(0, 80 + math.sin(t * 2.4) * 10, 0, 80 + math.sin(t * 2.4) * 10)
        end)
    end

    -- 17) SALJU: salju turun, gunung es, aurora tipis
    build.snow = function()
        setBase(90, { { 0, rgb(150, 200, 240) }, { 0.45, rgb(40, 90, 160) }, { 1, rgb(8, 24, 60) } })
        stars(18, 8, 2, 0.4)
        beams(3, rgb(190, 240, 255), 0.1, -14)
        for i = 0, 3 do
            local m = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.12 + i * 0.3, 0, 1.0, 0),
                Size = UDim2.new(0, 150, 0, 150), Rotation = 45, BackgroundColor3 = i % 2 == 0 and rgb(180, 215, 245) or rgb(130, 175, 225),
                BackgroundTransparency = 0.3, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0, 10) }, m)
        end
        circle(0.5, 1.12, 420, rgb(235, 245, 255), 0.05)
        build._particles(26, 61, { s1 = 2, s2 = 4, color = rgb(255, 255, 255), tr = 0.2, dir = 1, sp1 = 0.05, sp2 = 0.1, sway = 0.04, swf = 1.1 })
        build._particles(12, 62, { s1 = 4, s2 = 6, color = rgb(235, 248, 255), tr = 0.35, dir = 1, sp1 = 0.09, sp2 = 0.16, sway = 0.05, swf = 0.8 })
        build._particles(5, 63, { glyph = { "❄️" }, s1 = 14, s2 = 22, dir = 1, sp1 = 0.04, sp2 = 0.08, sway = 0.05, rot = 25, tr = 0.3 })
    end

    -- 18) HUJAN: awan gelap, hujan miring, kilat, riak air
    build.rain = function()
        setBase(90, { { 0, rgb(26, 32, 48) }, { 1, rgb(6, 10, 20) } })
        blob(0.2, 0.0, 230, rgb(90, 100, 120), 6)
        blob(0.8, 0.02, 240, rgb(70, 80, 104), 6)
        blob(0.5, -0.04, 260, rgb(100, 110, 130), 6)
        build._particles(34, 71, { rect = true, w = 1, s1 = 10, s2 = 18, color = rgb(170, 205, 245), tr = 0.45, angle = 10, dir = 1, sp1 = 0.5, sp2 = 0.9, sway = 0, drift = -0.06 })
        for i = 1, 4 do
            local r = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, r)
            local st = mk("UIStroke", { Thickness = 1.5, Color = rgb(170, 205, 245) }, r)
            local x, y, off = 0.15 + i * 0.18, 0.88 + (i % 2) * 0.07, i * 0.8
            table.insert(anims, function(t)
                local p = ((t * 0.7) + off) % 1
                r.Position = UDim2.new(x, 0, y, 0)
                r.Size = UDim2.new(0, 8 + p * 46, 0, 3 + p * 14)
                st.Transparency = 0.3 + p * 0.7
            end)
        end
        local flash = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = rgb(210, 225, 255),
            BackgroundTransparency = 1, BorderSizePixel = 0 })
        table.insert(anims, function(t)
            local p = t % 6.5
            if p < 0.08 then flash.BackgroundTransparency = 0.7
            elseif p < 0.16 then flash.BackgroundTransparency = 0.93
            elseif p < 0.24 then flash.BackgroundTransparency = 0.8
            else flash.BackgroundTransparency = math.min(1, flash.BackgroundTransparency + 0.08) end
        end)
    end

    -- 19) GURUN: matahari besar, bukit pasir, unta jalan, debu
    build.desert = function()
        setBase(90, { { 0, rgb(255, 196, 120) }, { 0.5, rgb(236, 138, 74) }, { 1, rgb(120, 60, 40) } })
        local sunGlow = blob(0.5, 0.28, 260, rgb(255, 236, 170), 7)
        local sun = circle(0.5, 0.28, 90, rgb(255, 246, 200), 0.05)
        beams(3, rgb(255, 230, 170), 0.1, -12)
        circle(0.15, 1.12, 360, rgb(200, 120, 66), 0.05)
        circle(0.8, 1.15, 380, rgb(176, 98, 56), 0.05)
        circle(0.5, 1.28, 460, rgb(138, 74, 46), 0.05)
        mk("TextLabel", { Position = UDim2.new(0.06, 0, 0.84, 0), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1, Text = "🌵", TextSize = 22 })
        mk("TextLabel", { Position = UDim2.new(0.86, 0, 0.88, 0), Size = UDim2.new(0, 30, 0, 30), BackgroundTransparency = 1, Text = "🌵", TextSize = 18 })
        local camel = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(0, 40, 0, 40), BackgroundTransparency = 1, Text = "🐪", TextSize = 28 })
        local rnd = Random.new(81)
        for _ = 1, 14 do
            local d = circle(0.5, 0.5, rnd:NextInteger(2, 4), rgb(255, 224, 170), 0.5)
            local y0, sp, ph = rnd:NextNumber(0.3, 0.95), rnd:NextNumber(0.03, 0.08), rnd:NextNumber(0, 8)
            table.insert(anims, function(t)
                d.Position = UDim2.new(((t * sp + ph) % 1.2) - 0.1, 0, y0 + math.sin(t + ph) * 0.02, 0)
            end)
        end
        table.insert(anims, function(t)
            camel.Position = UDim2.new(((t * 0.02) % 1.3) - 0.15, 0, 0.9 + math.sin(t * 3) * 0.004, 0)
            local s = 260 + math.sin(t * 0.8) * 12
            sunGlow.Size = UDim2.new(0, s, 0, s)
        end)
    end

    -- 20) CYBERPUNK: kota neon, papan neon, glitch
    build.cyber = function()
        setBase(160, { { 0, rgb(22, 4, 44) }, { 0.55, rgb(64, 6, 74) }, { 1, rgb(4, 20, 44) } })
        stars(20, 4, 2, 0.4)
        local moon = circle(0.72, 0.22, 74, rgb(255, 255, 255), 0.1)
        ugrad(moon, 90, { { 0, rgb(255, 220, 90) }, { 1, rgb(255, 40, 170) } })
        for i = 1, 6 do
            mk("Frame", { Position = UDim2.new(0.72, -37, 0.22, -37 + 30 + i * 6), Size = UDim2.new(0, 74, 0, 1 + i * 0.6),
                BackgroundColor3 = rgb(22, 4, 44), BorderSizePixel = 0 })
        end
        build._skyline(91, 9, rgb(12, 6, 28), 90, 190, { rgb(255, 230, 80), rgb(0, 230, 255), rgb(255, 60, 190) }, 1.0)
        build._skyline(92, 7, rgb(6, 4, 16), 50, 110, { rgb(0, 230, 255), rgb(255, 60, 190) }, 1.02)
        local neons = {}
        for i = 1, 4 do
            local n = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.12 + i * 0.2, 0, 0.55 + (i % 2) * 0.08, 0),
                Size = UDim2.new(0, 46, 0, 4), BackgroundColor3 = (i % 2 == 0) and rgb(0, 240, 255) or rgb(255, 60, 190),
                BackgroundTransparency = 0.1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, n)
            mk("UIStroke", { Thickness = 3, Color = n.BackgroundColor3, Transparency = 0.7 }, n)
            neons[i] = n
        end
        build._particles(12, 93, { rect = true, w = 1, s1 = 8, s2 = 14, color = rgb(255, 80, 200), tr = 0.5, angle = 14, dir = 1, sp1 = 0.3, sp2 = 0.6, sway = 0, drift = -0.08 })
        local glitch = mk("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = rgb(0, 240, 255),
            BackgroundTransparency = 1, BorderSizePixel = 0 })
        table.insert(anims, function(t)
            for i = 1, 4 do
                neons[i].BackgroundTransparency = (math.sin(t * (2 + i) + i * 2) > -0.6) and 0.1 or 0.8
            end
            local p = t % 4
            if p < 0.18 then
                glitch.BackgroundTransparency = 0.8
                glitch.Position = UDim2.new(((p * 37) % 1) * 0.2 - 0.05, 0, (t * 7.3) % 0.9, 0)
            else
                glitch.BackgroundTransparency = 1
            end
        end)
    end

    -- 21) CANDY: warna permen, gelembung, taburan warna-warni
    build.candy = function()
        setBase(135, { { 0, rgb(255, 120, 180) }, { 0.5, rgb(150, 110, 230) }, { 1, rgb(70, 170, 230) } })
        blob(0.15, 0.2, 200, rgb(255, 255, 255), 6)
        blob(0.88, 0.75, 220, rgb(255, 230, 120), 6)
        for i = 1, 9 do
            local b = circle(0.5, 0.5, 14 + (i * 7) % 26, rgb(255, 255, 255), 0.82)
            mk("UIStroke", { Thickness = 1.5, Color = rgb(255, 255, 255), Transparency = 0.4 }, b)
            local sp, ph, x0 = 0.03 + (i % 4) * 0.015, i * 1.3, (i * 0.113) % 1
            table.insert(anims, function(t)
                b.Position = UDim2.new((x0 + math.sin(t * 0.7 + ph) * 0.04) % 1, 0, 1.1 - ((t * sp + ph) % 1.2), 0)
            end)
        end
        local cols = { rgb(255, 230, 90), rgb(120, 240, 200), rgb(255, 255, 255), rgb(255, 150, 90) }
        local rnd = Random.new(101)
        for i = 1, 22 do
            local s = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 3, 0, 9),
                BackgroundColor3 = cols[(i % #cols) + 1], BackgroundTransparency = 0.1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, s)
            local x0, sp, ph = rnd:NextNumber(), rnd:NextNumber(0.03, 0.07), rnd:NextNumber(0, 9)
            table.insert(anims, function(t)
                local p = (t * sp + ph) % 1.2 - 0.1
                s.Position = UDim2.new((x0 + math.sin(t * 0.6 + ph) * 0.03) % 1, 0, p, 0)
                s.Rotation = (t * 60 + ph * 70) % 360
            end)
        end
        build._particles(5, 102, { glyph = { "🍭", "🍬", "🍩", "🧁" }, s1 = 18, s2 = 26, dir = -1, sp1 = 0.02, sp2 = 0.05, sway = 0.05, swf = 0.8, rot = 20, tr = 0.1 })
    end

    -- 22) KOTA MALAM: bulan, gedung berlapis, jendela berkedip, lampu mobil
    build.city = function()
        setBase(90, { { 0, rgb(10, 14, 40) }, { 0.6, rgb(30, 36, 86) }, { 1, rgb(80, 62, 120) } })
        stars(40, 14, 2, 0.5)
        blob(0.8, 0.16, 120, rgb(255, 240, 190), 6)
        circle(0.8, 0.16, 38, rgb(255, 246, 214), 0.05)
        build._skyline(111, 8, rgb(34, 36, 78), 110, 220, nil, 1.0)
        build._skyline(112, 10, rgb(18, 20, 50), 60, 160, { rgb(255, 226, 130), rgb(255, 200, 100) }, 1.0)
        local cars = {}
        for i = 1, 4 do
            local c = circle(0.5, 0.97, 4, i % 2 == 0 and rgb(255, 80, 80) or rgb(255, 250, 220), 0.1)
            cars[i] = { c, 0.1 + i * 0.07, i * 0.23, i % 2 == 0 and -1 or 1 }
        end
        shoot(9, 2)
        table.insert(anims, function(t)
            for i = 1, 4 do
                local c = cars[i]
                local p = (t * c[2] + c[3]) % 1
                if c[4] < 0 then p = 1 - p end
                c[1].Position = UDim2.new(p, 0, 0.975 + (i % 2) * 0.012, 0)
            end
        end)
    end

    -- 23) PETIR UNGU: badai ungu, kilat zig-zag
    build.thunder = function()
        setBase(90, { { 0, rgb(34, 10, 72) }, { 0.5, rgb(14, 6, 40) }, { 1, rgb(4, 2, 14) } })
        local c1 = blob(0.25, 0.04, 240, rgb(120, 60, 200), 6)
        local c2 = blob(0.75, 0.0, 250, rgb(90, 50, 170), 6)
        local W = math.max(260, mainFrame.AbsoluteSize.X)
        local H = math.max(300, mainFrame.AbsoluteSize.Y)
        local rnd = Random.new(121)
        local bolts = {}
        for b = 1, 3 do
            local g = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false })
            local x, y = W * (0.2 + b * 0.22), 0
            for _ = 1, 6 do
                local dx, dy = rnd:NextNumber(-36, 36), H * 0.14
                local len = math.sqrt(dx * dx + dy * dy)
                local seg = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, x + dx / 2, 0, y + dy / 2),
                    Size = UDim2.new(0, 3, 0, len), Rotation = -math.deg(math.atan2(dx, dy)),
                    BackgroundColor3 = rgb(245, 235, 255), BorderSizePixel = 0 }, g)
                mk("UIStroke", { Thickness = 4, Color = rgb(170, 110, 255), Transparency = 0.55 }, seg)
                x, y = x + dx, y + dy
            end
            bolts[b] = g
        end
        local flash = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = rgb(190, 150, 255),
            BackgroundTransparency = 1, BorderSizePixel = 0 })
        build._particles(18, 122, { rect = true, w = 1, s1 = 8, s2 = 14, color = rgb(200, 170, 255), tr = 0.55, angle = 8, dir = 1, sp1 = 0.4, sp2 = 0.8, sway = 0, drift = -0.04 })
        table.insert(anims, function(t)
            c1.Position = UDim2.new(0.25 + math.sin(t * 0.3) * 0.05, 0, 0.04, 0)
            c2.Position = UDim2.new(0.75 + math.cos(t * 0.25) * 0.05, 0, 0.0, 0)
            local cyc = math.floor(t / 4.5)
            local p = t % 4.5
            for b = 1, 3 do bolts[b].Visible = false end
            if p < 0.3 then
                local on = (p < 0.08) or (p > 0.14 and p < 0.22)
                bolts[(cyc % 3) + 1].Visible = on
                flash.BackgroundTransparency = on and 0.8 or 0.94
            else
                flash.BackgroundTransparency = math.min(1, flash.BackgroundTransparency + 0.06)
            end
        end)
    end

    -- 24) EMAS MEWAH: hitam-emas, kilau menyapu, cincin berputar, kilauan
    build.gold = function()
        setBase(135, { { 0, rgb(10, 8, 4) }, { 0.5, rgb(46, 34, 12) }, { 1, rgb(8, 6, 3) } })
        local goldCols = { { 0, rgb(120, 80, 20) }, { 0.5, rgb(255, 226, 130) }, { 1, rgb(160, 110, 30) } }
        blob(0.95, 0.05, 190, rgb(240, 190, 80), 6)
        blob(0.05, 0.95, 170, rgb(220, 160, 60), 6)
        local spin = {}
        for _, d in ipairs({ { 230, 2, 1 }, { 180, 1.5, -1 }, { 130, 1, 1 } }) do
            local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.9, 0, 0.1, 0),
                Size = UDim2.new(0, d[1], 0, d[1]), BackgroundTransparency = 1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            local s = mk("UIStroke", { Thickness = d[2], Color = rgb(255, 255, 255), Transparency = 0.25 }, f)
            spin[#spin + 1] = { ugrad(s, 0, goldCols), d[3] }
        end
        for _, y in ipairs({ 0.045, 0.955 }) do
            local l = mk("Frame", { Position = UDim2.new(0.05, 0, y, 0), Size = UDim2.new(0.9, 0, 0, 1),
                BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.2, BorderSizePixel = 0 })
            ugrad(l, 0, { { 0, rgb(160, 110, 30) }, { 0.5, rgb(255, 226, 130) }, { 1, rgb(160, 110, 30) } }, { { 0, 1 }, { 0.5, 0 }, { 1, 1 } })
        end
        local sheen = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.3, 0, 0.5, 0),
            Size = UDim2.new(0, 80, 0, 560), Rotation = 24, BackgroundColor3 = rgb(255, 226, 140), BackgroundTransparency = 0.82,
            BorderSizePixel = 0 })
        ugrad(sheen, 0, nil, { { 0, 1 }, { 0.5, 0 }, { 1, 1 } })
        local rnd = Random.new(131)
        for _ = 1, 16 do
            local s = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(rnd:NextNumber(), 0, rnd:NextNumber(), 0),
                Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Text = "✦", TextSize = rnd:NextInteger(8, 16),
                TextColor3 = rgb(255, 228, 140) })
            local ph, sp = rnd:NextNumber(0, 6), rnd:NextNumber(0.8, 2)
            table.insert(anims, function(t)
                s.TextTransparency = 0.3 + (math.sin(t * sp + ph) + 1) * 0.35
                s.Rotation = math.sin(t * 0.7 + ph) * 25
            end)
        end
        table.insert(anims, function(t)
            sheen.Position = UDim2.new(-0.3 + ((t % 7) / 7) * 1.6, 0, 0.5, 0)
            for i = 1, #spin do spin[i][1].Rotation = (t * 25 * spin[i][2]) % 360 end
        end)
    end

    -- 25) MUSIM GUGUR: langit senja, daun jatuh berputar
    build.autumn = function()
        setBase(90, { { 0, rgb(250, 190, 110) }, { 0.45, rgb(190, 90, 40) }, { 1, rgb(60, 24, 16) } })
        beams(3, rgb(255, 220, 150), 0.1, -16)
        blob(0.8, 0.12, 170, rgb(255, 220, 140), 6)
        for i = 0, 6 do
            mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new((i + 0.5) / 7, 0, 1.02, 0),
                Size = UDim2.new(0, 56, 0, 56), BackgroundTransparency = 1, Text = (i % 2 == 0) and "🌳" or "🌲",
                TextSize = 44, TextTransparency = 0.25 })
        end
        circle(0.5, 1.14, 440, rgb(120, 56, 28), 0.05)
        build._particles(11, 141, { glyph = { "🍂", "🍁", "🍂" }, s1 = 14, s2 = 24, dir = 1, sp1 = 0.04, sp2 = 0.09, sway = 0.07, swf = 1.2, rot = 50, tr = 0.12 })
        build._particles(10, 142, { s1 = 2, s2 = 4, color = rgb(255, 210, 130), tr = 0.4, dir = -1, sp1 = 0.02, sp2 = 0.05, sway = 0.05 })
    end

    -- 26) BULAN: bulan purnama besar, kawah, awan lewat, bintang
    build.moon = function()
        setBase(90, { { 0, rgb(8, 12, 34) }, { 0.6, rgb(18, 30, 70) }, { 1, rgb(34, 54, 96) } })
        stars(50, 17, 2, 0.7)
        local glow = blob(0.5, 0.3, 280, rgb(220, 225, 180), 7)
        circle(0.5, 0.3, 112, rgb(250, 248, 220), 0.02)
        circle(0.43, 0.26, 20, rgb(222, 220, 190), 0.2)
        circle(0.57, 0.33, 28, rgb(226, 224, 194), 0.2)
        circle(0.5, 0.38, 14, rgb(220, 218, 186), 0.25)
        local rnd = Random.new(151)
        for i = 1, 4 do
            local c = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, rnd:NextInteger(90, 150), 0, rnd:NextInteger(14, 22)),
                BackgroundColor3 = rgb(26, 40, 84), BackgroundTransparency = 0.25, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
            local y, sp, off = 0.2 + i * 0.08, rnd:NextNumber(0.01, 0.025), rnd:NextNumber(0, 1.5)
            table.insert(anims, function(t) c.Position = UDim2.new(((t * sp + off) % 1.6) - 0.4, 0, y, 0) end)
        end
        circle(0.2, 1.16, 330, rgb(10, 18, 40), 0.05)
        circle(0.85, 1.18, 350, rgb(8, 14, 34), 0.05)
        shoot(8, 1)
        table.insert(anims, function(t)
            local s = 280 + math.sin(t * 0.7) * 10
            glow.Size = UDim2.new(0, s, 0, s)
        end)
    end

    -- 27) PELANGI: warna berganti halus + pelangi berdenyut + awan
    build.rainbow = function()
        setBase(90, { { 0, rgb(60, 40, 110) }, { 1, rgb(30, 20, 70) } })
        local arcs = {}
        local cols = { rgb(255, 70, 70), rgb(255, 150, 50), rgb(255, 230, 70), rgb(80, 220, 110), rgb(70, 160, 255), rgb(120, 90, 240), rgb(190, 90, 230) }
        for i, c in ipairs(cols) do
            local s = 330 - i * 18
            local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.98, 0),
                Size = UDim2.new(0, s, 0, s), BackgroundTransparency = 1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            arcs[i] = mk("UIStroke", { Thickness = 8, Color = c, Transparency = 0.4 }, f)
        end
        local rnd = Random.new(161)
        for i = 1, 3 do
            local c = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 100 + i * 20, 0, 24),
                BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.7, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, c)
            local y, sp, off = 0.1 + i * 0.12, rnd:NextNumber(0.012, 0.025), rnd:NextNumber(0, 1.5)
            table.insert(anims, function(t) c.Position = UDim2.new(((t * sp + off) % 1.6) - 0.4, 0, y, 0) end)
        end
        build._particles(14, 162, { s1 = 3, s2 = 6, color = rgb(255, 255, 255), tr = 0.4, dir = -1, sp1 = 0.03, sp2 = 0.07, sway = 0.04 })
        table.insert(anims, function(t)
            local h = (t * 0.03) % 1
            baseGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0.65, 0.5)),
                ColorSequenceKeypoint.new(0.5, Color3.fromHSV((h + 0.18) % 1, 0.7, 0.4)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV((h + 0.38) % 1, 0.7, 0.3)),
            })
            baseGrad.Rotation = 90 + math.sin(t * 0.2) * 30
            for i = 1, 7 do arcs[i].Transparency = 0.35 + (math.sin(t * 1.5 - i * 0.5) + 1) * 0.12 end
        end)
    end

    -- 28) LAUT DALAM: ubur-ubur bercahaya, plankton, sinar dari atas
    build.abyss = function()
        setBase(90, { { 0, rgb(4, 44, 66) }, { 0.5, rgb(2, 18, 40) }, { 1, rgb(0, 4, 14) } })
        beams(3, rgb(120, 230, 240), 0.05, -10)
        build._jelly(0.2, 0.2, 40, rgb(80, 240, 230), 0)
        build._jelly(0.72, 0.1, 54, rgb(200, 110, 255), 2)
        build._jelly(0.5, 0.52, 34, rgb(255, 120, 200), 4)
        build._jelly(0.85, 0.58, 28, rgb(100, 200, 255), 1)
        build._jelly(0.12, 0.62, 30, rgb(150, 255, 190), 3)
        build._particles(24, 171, { s1 = 2, s2 = 4, color = rgb(150, 255, 240), tr = 0.45, dir = -1, sp1 = 0.015, sp2 = 0.04, sway = 0.05, swf = 0.7 })
        circle(0.5, 1.22, 420, rgb(2, 10, 20), 0.05)
    end

    -- 29) KEMBANG API: langit malam, roket naik lalu meledak warna-warni
    build.fireworks = function()
        setBase(90, { { 0, rgb(6, 4, 22) }, { 1, rgb(26, 10, 52) } })
        stars(34, 19, 2, 0.6)
        build._skyline(181, 10, rgb(6, 4, 14), 30, 70, nil, 1.0)
        for b = 1, 4 do
            local period, off = 4.2 + b * 0.5, b * 1.1
            local pts, rocket = {}, circle(0.5, 1, 4, rgb(255, 230, 170), 0.1)
            for i = 1, 14 do pts[i] = circle(0.5, 0.5, 4, rgb(255, 255, 255), 1) end
            local lastK = -1
            table.insert(anims, function(t)
                local u = t + off
                local k = math.floor(u / period)
                local p = (u % period) / period
                local cx = 0.2 + 0.6 * ((k * 0.37 + b * 0.21) % 1)
                local cy = 0.18 + 0.3 * ((k * 0.53 + b * 0.31) % 1)
                if k ~= lastK then
                    lastK = k
                    for i = 1, 14 do pts[i].BackgroundColor3 = Color3.fromHSV((k * 0.21 + b * 0.17 + i * 0.01) % 1, 0.65, 1) end
                end
                if p < 0.25 then
                    local q = p / 0.25
                    rocket.BackgroundTransparency = 0.1
                    rocket.Position = UDim2.new(cx, 0, 1 - (1 - cy) * q, 0)
                    for i = 1, 14 do pts[i].BackgroundTransparency = 1 end
                else
                    rocket.BackgroundTransparency = 1
                    local q = (p - 0.25) / 0.75
                    local e = 1 - (1 - q) * (1 - q)
                    for i = 1, 14 do
                        local a = (i / 14) * 6.2832
                        pts[i].Position = UDim2.new(cx, math.cos(a) * 62 * e, cy, math.sin(a) * 62 * e + q * q * 30)
                        pts[i].BackgroundTransparency = math.min(1, 0.05 + q * q * 1.1)
                    end
                end
            end)
        end
    end

    -- 30) API BIRU: lidah api biru-putih menari, bara biru naik
    build.blueflame = function()
        setBase(90, { { 0, rgb(4, 10, 30) }, { 0.6, rgb(8, 26, 76) }, { 1, rgb(10, 64, 150) } })
        local glow = blob(0.5, 1.0, 320, rgb(40, 150, 255), 7)
        local flames = {}
        for layer = 1, 3 do
            local col = ({ rgb(20, 70, 200), rgb(60, 180, 255), rgb(220, 250, 255) })[layer]
            local hh = ({ 120, 92, 56 })[layer]
            for i = 0, 7 do
                local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new((i + 0.5) / 8, 0, 1.02, 0),
                    Size = UDim2.new(0, 38 - layer * 6, 0, hh), BackgroundColor3 = col,
                    BackgroundTransparency = ({ 0.45, 0.3, 0.15 })[layer], BorderSizePixel = 0 })
                mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
                ugrad(f, 90, nil, { { 0, 0.2 }, { 1, 0 } })
                flames[#flames + 1] = { f, hh, i * 0.9 + layer * 1.7, 38 - layer * 6 }
            end
        end
        build._particles(22, 191, { s1 = 2, s2 = 4, color = rgb(150, 225, 255), tr = 0.2, dir = -1, sp1 = 0.07, sp2 = 0.17, sway = 0.04, swf = 1.4 })
        table.insert(anims, function(t)
            for i = 1, #flames do
                local f = flames[i]
                local k = math.sin(t * 5 + f[3]) * 0.5 + math.sin(t * 8.3 + f[3] * 2) * 0.3
                f[1].Size = UDim2.new(0, f[4] * (1 - k * 0.12), 0, f[2] * (1 + k * 0.28))
                f[1].Rotation = math.sin(t * 3 + f[3]) * 7
            end
            local s = 320 + math.sin(t * 2.2) * 14
            glow.Size = UDim2.new(0, s, 0, s)
        end)
    end

    -- 30) MALAM KUNANG: langit malam, bukit gelap, ilalang, kunang-kunang berkedip
    build.firefly = function()
        setBase(90, { { 0, rgb(10, 32, 44) }, { 0.55, rgb(8, 36, 30) }, { 1, rgb(3, 14, 10) } })
        stars(20, 31, 2, 0.4)
        blob(0.85, 0.1, 120, rgb(230, 250, 170), 6)
        local rnd = Random.new(31)
        for i = 0, 4 do
            local h = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(i * 0.26, 0, 1.06, 0),
                Size = UDim2.new(0, 190, 0, 150), BackgroundColor3 = (i % 2 == 0) and rgb(4, 22, 16) or rgb(6, 30, 22),
                BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, h)
        end
        for _ = 1, 10 do
            mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(rnd:NextNumber(0.03, 0.97), 0, 1.02, 0),
                Size = UDim2.new(0, 2, 0, rnd:NextInteger(30, 70)), BackgroundColor3 = rgb(10, 48, 30),
                BorderSizePixel = 0, Rotation = rnd:NextInteger(-8, 8) })
        end
        for _ = 1, 22 do
            local x, y = rnd:NextNumber(0.05, 0.95), rnd:NextNumber(0.2, 0.95)
            local g = circle(x, y, 12, rgb(190, 255, 110), 0.9)
            local d = circle(x, y, 3, rgb(235, 255, 170), 0.1)
            local ph, sp = rnd:NextNumber(0, 6), rnd:NextNumber(1.1, 2.2)
            table.insert(anims, function(t)
                local a = (math.sin(t * sp + ph) + 1) / 2
                d.BackgroundTransparency = 0.85 - a * 0.75
                g.BackgroundTransparency = 0.96 - a * 0.2
                local pos = UDim2.new(x + math.sin(t * 0.4 + ph) * 0.04, 0, y + math.cos(t * 0.33 + ph) * 0.03, 0)
                g.Position = pos
                d.Position = pos
            end)
        end
    end

    -- 31) HUJAN METEOR: langit ungu-biru, bintang berkedip, meteor jatuh miring
    build.meteor = function()
        setBase(90, { { 0, rgb(8, 8, 34) }, { 0.6, rgb(26, 14, 60) }, { 1, rgb(62, 22, 72) } })
        stars(40, 41, 2, 0.8)
        blob(0.15, 0.97, 230, rgb(255, 120, 80), 6)
        blob(0.92, 0.04, 150, rgb(140, 110, 255), 6)
        local rnd = Random.new(41)
        for _ = 1, 7 do
            local len = rnd:NextInteger(60, 110)
            local m = mk("Frame", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, len, 0, 2),
                BackgroundColor3 = rgb(255, 235, 200), BackgroundTransparency = 0, BorderSizePixel = 0, Rotation = 45 })
            ugrad(m, 0, nil, { { 0, 1 }, { 1, 0 } })
            local sp, ph = rnd:NextNumber(0.16, 0.34), rnd:NextNumber(0, 6)
            local x0, y0 = rnd:NextNumber(-0.1, 0.5), rnd:NextNumber(-0.2, 0.15)
            table.insert(anims, function(t)
                local p = (t * sp + ph) % 2.4
                m.Position = UDim2.new(x0 + p * 0.75, 0, y0 + p * 0.55, 0)
            end)
        end
        build._particles(8, 42, { s1 = 2, s2 = 3, color = rgb(255, 210, 160), tr = 0.5, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.02, swf = 1 })
    end

    -- 32) TERUMBU KARANG: air tosca, sinar, gelembung naik, ikan berenang, karang & pasir
    build.coral = function()
        setBase(90, { { 0, rgb(30, 160, 190) }, { 0.45, rgb(10, 80, 130) }, { 1, rgb(3, 28, 56) } })
        beams(3, rgb(200, 255, 250), 0.1, -16)
        build._particles(18, 51, { s1 = 3, s2 = 8, color = rgb(220, 250, 255), tr = 0.6, dir = -1, sp1 = 0.06, sp2 = 0.14, sway = 0.03, swf = 1.2 })
        local rnd = Random.new(51)
        mk("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 22),
            BackgroundColor3 = rgb(214, 186, 128), BackgroundTransparency = 0.15, BorderSizePixel = 0 })
        local cols = { rgb(255, 110, 120), rgb(255, 160, 90), rgb(230, 90, 170), rgb(255, 200, 110) }
        for i = 0, 8 do
            local x = (i + 0.5) / 9
            local h = rnd:NextInteger(26, 62)
            local col = cols[rnd:NextInteger(1, #cols)]
            local stem = mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(x, 0, 1, -6),
                Size = UDim2.new(0, 9, 0, h), BackgroundColor3 = col, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, stem)
            for _, side in ipairs({ -1, 1 }) do
                local br = mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, side * 5, 0.6, 0),
                    Size = UDim2.new(0, 6, 0, h * 0.5), BackgroundColor3 = col, BorderSizePixel = 0, Rotation = side * 35 }, stem)
                mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, br)
            end
            local ph = rnd:NextNumber(0, 6)
            table.insert(anims, function(t) stem.Rotation = math.sin(t * 0.9 + ph) * 3 end)
        end
        local glyphs = { "🐠", "🐟", "🐡", "🐠" }
        for i = 1, 4 do
            local f = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 26, 0, 26),
                BackgroundTransparency = 1, Text = glyphs[i], TextSize = rnd:NextInteger(16, 24), TextTransparency = 0.15 })
            local y0, sp, ph = rnd:NextNumber(0.2, 0.75), rnd:NextNumber(0.04, 0.09), rnd:NextNumber(0, 6)
            table.insert(anims, function(t)
                local p = (t * sp + ph) % 1.3
                f.Position = UDim2.new(1.15 - p, 0, y0 + math.sin(t * 1.3 + ph) * 0.02, 0)
            end)
        end
    end

    -- 33) MESIN UAP: tembaga gelap, roda gigi berputar, uap naik
    build.gear = function()
        setBase(135, { { 0, rgb(72, 46, 20) }, { 0.5, rgb(34, 21, 11) }, { 1, rgb(16, 10, 5) } })
        blob(0.9, 0.1, 170, rgb(230, 160, 70), 6)
        blob(0.1, 0.95, 170, rgb(200, 120, 50), 6)
        for i = 1, 9 do
            mk("Frame", { Position = UDim2.new(i / 10, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0),
                BackgroundColor3 = rgb(214, 150, 70), BackgroundTransparency = 0.93, BorderSizePixel = 0 })
        end
        local specs = {
            { 0.12, 0.18, 92, 14 }, { 0.52, 0.3, 64, -22 }, { 0.9, 0.14, 78, 18 },
            { 0.2, 0.74, 70, -16 }, { 0.82, 0.82, 100, 12 }, { 0.5, 0.6, 46, 30 },
        }
        for _, s in ipairs(specs) do
            local gl = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s[1], 0, s[2], 0),
                Size = UDim2.new(0, s[3], 0, s[3]), BackgroundTransparency = 1, Text = "⚙", TextSize = s[3],
                TextColor3 = rgb(214, 150, 70), TextTransparency = 0.6 })
            table.insert(anims, function(t) gl.Rotation = (t * s[4]) % 360 end)
        end
        build._particles(10, 71, { s1 = 8, s2 = 18, color = rgb(235, 225, 205), tr = 0.82, dir = -1, sp1 = 0.05, sp2 = 0.1, sway = 0.05, swf = 1 })
        build._particles(8, 72, { s1 = 2, s2 = 3, color = rgb(255, 190, 90), tr = 0.3, dir = -1, sp1 = 0.08, sp2 = 0.16, sway = 0.03, swf = 2 })
    end

    -- 34) MATCHA LATTE: hijau lembut, daun melayang, mutiara boba naik, cangkir
    build.matcha = function()
        setBase(90, { { 0, rgb(150, 190, 120) }, { 0.45, rgb(70, 110, 76) }, { 1, rgb(22, 40, 30) } })
        blob(0.85, 0.1, 160, rgb(240, 250, 200), 6)
        blob(0.1, 0.9, 170, rgb(190, 230, 150), 6)
        build._particles(8, 81, { glyph = { "🍃", "🌿", "🍃" }, s1 = 14, s2 = 22, dir = 1, sp1 = 0.04, sp2 = 0.09, sway = 0.06, swf = 0.9, rot = 30, tr = 0.3 })
        build._particles(16, 82, { s1 = 6, s2 = 12, color = rgb(40, 28, 22), tr = 0.45, dir = -1, sp1 = 0.04, sp2 = 0.09, sway = 0.03, swf = 1.2 })
        build._particles(14, 83, { s1 = 2, s2 = 4, color = rgb(255, 255, 235), tr = 0.4, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.03, swf = 1.4 })
        mk("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -4), Size = UDim2.new(0, 56, 0, 56),
            BackgroundTransparency = 1, Text = "🍵", TextSize = 46, TextTransparency = 0.35 })
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

    local animBtn = makeButton(page, "✨ Animasi dekorasi • ON", 100)
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

-- ==================== CARI FITUR + FAVORIT (BAR DI ATAS, BUKAN TAB) ====================
-- Bar di atas daftar tab: kolom 🔍 cari + tombol ⭐ FAV.
--   • Ketik di kolom cari  -> daftar fitur dari SEMUA tab yang cocok muncul di bawah (tap = jalankan, ↗ = loncat ke tab asal).
--   • Tekan ⭐ FAV         -> cuma fitur favorit yang tampil. Tekan lagi -> balik seperti biasa.
--   • Tekan ☆ di kanan tombol fitur mana pun untuk menyimpan / menghapus dari favorit.
-- Semua ditaruh di dalam satu fungsi (pages.initFav) supaya tidak menambah variabel local di level atas.
function pages.initFav()
    local StarterGui = game:GetService("StarterGui")
    local FAV_FILE = "UniversalHub_fav.json"
    local GOLD = Color3.fromRGB(255, 205, 60)
    local TABS = { "FARM", "SERVER", "PLAYER", "TELEPORT", "ANIMASI", "APLIKASI", "TEMA" }
    local SKIP_TEXT = { "TAMPILKAN LEBIH" }

    -- ---------- simpan / muat favorit ----------
    local favList, favSet = {}, {}
    pcall(function()
        if isfile and readfile and isfile(FAV_FILE) then
            local data = HttpService:JSONDecode(readfile(FAV_FILE))
            if type(data) == "table" then
                for _, k in ipairs(data) do
                    if type(k) == "string" and not favSet[k] then
                        favSet[k] = true
                        favList[#favList + 1] = k
                    end
                end
            end
        end
    end)

    local function saveFavs()
        pcall(function()
            if writefile then writefile(FAV_FILE, HttpService:JSONEncode(favList)) end
        end)
    end

    local function notify(text)
        pcall(function()
            StarterGui:SetCore("SendNotification", { Title = "UNIVERSAL", Text = text, Duration = 3 })
        end)
    end

    -- ---------- pilih tab ----------
    local function selectTab(name)
        for n, b in pairs(tabButtons) do
            if n == name then
                b.BackgroundColor3 = ACCENT_BLUE
                b.TextColor3 = WHITE
                pages[n].Visible = true
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
    end

    -- ---------- registry fitur (dibaca langsung dari isi tiap tab) ----------
    local used = {}
    local function newKey(tab, inst)
        local base = tab .. "|" .. tostring(inst.LayoutOrder)
        local k, n = base, 1
        while used[k] do
            n = n + 1
            k = base .. "#" .. n
        end
        used[k] = true
        inst.Destroying:Connect(function() used[k] = nil end)
        return k
    end

    local starBtns = {}      -- key -> daftar tombol bintang
    local refreshers = {}    -- dipanggil setelah favorit berubah

    local function paintStar(s, key)
        local on = favSet[key] == true
        s.Text = on and "★" or "☆"
        s.TextColor3 = on and GOLD or GREY
    end

    local function trackStar(key, s)
        local list = starBtns[key]
        if not list then
            list = {}
            starBtns[key] = list
        end
        list[#list + 1] = s
        paintStar(s, key)
    end

    local function toggleFav(key)
        if favSet[key] then
            favSet[key] = nil
            for i, k in ipairs(favList) do
                if k == key then
                    table.remove(favList, i)
                    break
                end
            end
        else
            favSet[key] = true
            favList[#favList + 1] = key
        end
        saveFavs()
        for k, list in pairs(starBtns) do
            for i = #list, 1, -1 do
                if list[i].Parent then paintStar(list[i], k) else table.remove(list, i) end
            end
        end
        for _, fn in ipairs(refreshers) do pcall(fn) end
    end

    local function makeStar(parent, key, pos, size)
        local s = Instance.new("TextButton")
        s.Name = "UHStar"
        s.AnchorPoint = Vector2.new(1, 0.5)
        s.Position = pos
        s.Size = size
        s.BackgroundTransparency = 1
        s.Font = Enum.Font.GothamBold
        s.TextSize = 17
        s.AutoButtonColor = false
        s.ZIndex = 6
        s.Parent = parent
        trackStar(key, s)
        s.MouseButton1Click:Connect(function() toggleFav(key) end)
        return s
    end

    local function headerText(f)
        local l = f:FindFirstChildWhichIsA("TextLabel")
        return l and l.Text or ""
    end

    local function sortedChildren(page)
        local list = {}
        for i, c in ipairs(page:GetChildren()) do
            if c:IsA("GuiObject") then list[#list + 1] = { c = c, i = i } end
        end
        table.sort(list, function(a, b)
            if a.c.LayoutOrder ~= b.c.LayoutOrder then return a.c.LayoutOrder < b.c.LayoutOrder end
            return a.i < b.i
        end)
        return list
    end

    local function isInputFrame(c)
        if not c:IsA("Frame") then return false end
        local h = c.Size.Y
        if h.Scale ~= 0 or h.Offset < 20 or h.Offset > 70 then return false end
        return c:FindFirstChildWhichIsA("TextBox") ~= nil
    end

    local function skipText(t)
        for _, s in ipairs(SKIP_TEXT) do
            if string.find(t, s, 1, true) then return true end
        end
        return false
    end

    -- teks tombol: kartu (mis. kartu game) yang teksnya kosong bisa pakai attribute UHLabel
    local function btnLabel(c)
        local l = c:GetAttribute("UHLabel")
        if type(l) == "string" and l ~= "" then return l end
        return c.Text
    end

    -- kumpulkan semua fitur + pasang bintang di tombol yang belum punya
    local function collect()
        local out = {}
        for _, tab in ipairs(TABS) do
            local page = pages[tab]
            if typeof(page) == "Instance" then
                local section = ""

                local function addBtn(c)
                    local lbl = btnLabel(c)
                    if lbl == "" or skipText(lbl) then return end
                    local key = c:GetAttribute("UHKey")
                    if not key then
                        key = newKey(tab, c)
                        c:SetAttribute("UHKey", key)
                    end
                    if not c:FindFirstChild("UHStar") then
                        if c:GetAttribute("UHLabel") then
                            makeStar(c, key, UDim2.new(1, -3, 0, 14), UDim2.new(0, 24, 0, 24))
                        else
                            makeStar(c, key, UDim2.new(1, -3, 0.5, 0), UDim2.new(0, 24, 0, 24))
                        end
                    end
                    out[#out + 1] = { inst = c, kind = "button", tab = tab, section = section, key = key }
                end

                for _, e in ipairs(sortedChildren(page)) do
                    local c = e.c
                    if c:GetAttribute("UHHeader") then
                        section = headerText(c)
                    elseif c.Visible then
                        if c:IsA("TextButton") then
                            addBtn(c)
                        elseif c:GetAttribute("UHGroup") then
                            for _, g in ipairs(sortedChildren(c)) do
                                if g.c:IsA("TextButton") and g.c.Visible then addBtn(g.c) end
                            end
                        elseif isInputFrame(c) then
                            out[#out + 1] = { inst = c, kind = "input", tab = tab, section = section }
                        end
                    end
                end
            end
        end
        return out
    end

    local function labelOf(e)
        if e.kind == "button" then return btnLabel(e.inst) end
        local l = e.inst:FindFirstChildWhichIsA("TextLabel")
        if l and l.Text ~= "" then return l.Text end
        local tb = e.inst:FindFirstChildWhichIsA("TextBox")
        if tb and tb.PlaceholderText ~= "" then return tb.PlaceholderText end
        return "input"
    end

    -- ---------- aksi: jalankan / loncat ----------
    local function fireClick(btn)
        local ok = false
        if firesignal then ok = pcall(firesignal, btn.MouseButton1Click) end
        if not ok and getconnections then
            ok = pcall(function()
                for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
            end)
        end
        return ok
    end

    -- ---------- bar cari + FAV (di atas daftar tab) ----------
    local bar = Instance.new("Frame")
    bar.Name = "SearchBar"
    bar.Position = UDim2.new(0, 8, 0, 54)
    bar.Size = UDim2.new(1, -16, 0, 26)
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.Parent = mainFrame

    local box = Instance.new("TextBox")
    box.Name = "UHSearchBox"
    box.Position = UDim2.new(0, 0, 0, 0)
    box.Size = UDim2.new(1, -62, 1, 0)
    box.BackgroundColor3 = BG_BUTTON
    box.PlaceholderText = "🔍 cari fitur (mis. fly, esp)"
    box.PlaceholderColor3 = GREY
    box.Text = ""
    box.TextSize = 11
    box.Font = Enum.Font.GothamBold
    box.TextColor3 = WHITE
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = bar
    corner(box, 8)
    stroke(box, ACCENT_BLUE, 1)
    do
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 6)
        pad.Parent = box
    end

    local favBtn = Instance.new("TextButton")
    favBtn.Name = "UHFavBtn"
    favBtn.Position = UDim2.new(1, -58, 0, 0)
    favBtn.Size = UDim2.new(0, 58, 1, 0)
    favBtn.BackgroundColor3 = BG_BUTTON
    favBtn.Text = "☆ FAV"
    favBtn.TextSize = 11
    favBtn.Font = Enum.Font.GothamBold
    favBtn.TextColor3 = WHITE
    favBtn.AutoButtonColor = false
    favBtn.Parent = bar
    corner(favBtn, 8)
    favBtn:SetAttribute("UHBubble", true) -- jangan ikut efek bubble tema (warnanya dipakai buat penanda aktif)
    local favStroke = stroke(favBtn, ACCENT_BLUE, 1)

    -- ---------- panel hasil (menutupi isi tab selama cari / FAV aktif) ----------
    local overlay = Instance.new("ScrollingFrame")
    overlay.Name = "SearchOverlay"
    overlay.Position = UDim2.new(0, 8, 0, 118)
    overlay.Size = UDim2.new(1, -16, 1, -170)
    overlay.BackgroundColor3 = BG_BLACK
    overlay.BackgroundTransparency = 0
    overlay:SetAttribute("UHBubble", true)
    overlay.BorderSizePixel = 0
    overlay.Active = true
    overlay.ScrollBarThickness = 3
    overlay.ScrollBarImageColor3 = ACCENT_BLUE
    overlay.CanvasSize = UDim2.new(0, 0, 0, 0)
    overlay.AutomaticCanvasSize = Enum.AutomaticSize.Y
    overlay.ZIndex = 5
    overlay.Visible = false
    overlay.Parent = mainFrame
    corner(overlay, 8)
    do
        local pad = Instance.new("UIPadding")
        pad.PaddingBottom = UDim.new(0, 8)
        pad.Parent = overlay
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 4)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = overlay
    end

    local ovInfo = newLabel(overlay, "", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 26), Enum.TextXAlignment.Left)
    ovInfo.LayoutOrder = 0
    ovInfo.TextWrapped = true

    local holder = Instance.new("Frame")
    holder.LayoutOrder = 1
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = overlay
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = holder
    end
    local rowConns = {}

    local favMode = false
    local overlayOpen = false

    -- halaman tab disembunyikan selama panel cari/FAV aktif (supaya tidak numpuk 2 daftar),
    -- lalu dibalikin persis seperti semula saat ditutup
    local hiddenPage = nil
    local function hidePages()
        for _, tab in ipairs(TABS) do
            local pg = pages[tab]
            if typeof(pg) == "Instance" and pg.Visible then
                if not hiddenPage then hiddenPage = pg end
                pg.Visible = false
            end
        end
    end
    local function restorePage()
        if not hiddenPage then return end
        local anyVisible = false
        for _, tab in ipairs(TABS) do
            local pg = pages[tab]
            if typeof(pg) == "Instance" and pg.Visible then
                anyVisible = true
                break
            end
        end
        if not anyVisible then hiddenPage.Visible = true end
        hiddenPage = nil
    end

    local function clearList()
        for _, c in ipairs(rowConns) do pcall(function() c:Disconnect() end) end
        table.clear(rowConns)
        for _, ch in ipairs(holder:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() end
        end
    end

    local function queryText()
        return string.lower(string.match(box.Text or "", "^%s*(.-)%s*$") or "")
    end

    local function paintFavBtn()
        if favMode then
            favBtn.Text = "★ FAV"
            favBtn.TextColor3 = Color3.fromRGB(30, 22, 0)
            favBtn.BackgroundColor3 = GOLD
            favStroke.Color = GOLD
        else
            favBtn.Text = "☆ FAV"
            favBtn.TextColor3 = WHITE
            favBtn.BackgroundColor3 = BG_BUTTON
            favStroke.Color = ACCENT_BLUE
        end
    end

    local closeOverlay -- dideklarasi dulu, dipakai jumpTo

    local function jumpTo(entry)
        local inst, tab = entry.inst, entry.tab
        closeOverlay()
        selectTab(tab)
        task.spawn(function()
            task.wait(0.1)
            local page = pages[tab]
            if inst.Parent == page then
                local y = inst.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 6
                page.CanvasPosition = Vector2.new(0, math.max(0, y))
            end
            local s = Instance.new("UIStroke")
            s.Name = "UHFlash"
            s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            s.Color = GOLD
            s.Thickness = 2
            s.Parent = inst
            task.delay(1.4, function() s:Destroy() end)
        end)
    end

    -- baris hasil
    local function makeRow(entry, order)
        local inst = entry.inst
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = holder

        local isBtn = entry.kind == "button"
        local main = Instance.new("TextButton")
        main.Size = isBtn and UDim2.new(1, -54, 1, 0) or UDim2.new(1, 0, 1, 0)
        main.BackgroundColor3 = isBtn and inst.BackgroundColor3 or BG_BUTTON
        main.Text = isBtn and labelOf(entry) or ("⌨️ " .. labelOf(entry))
        main.TextSize = 11
        main.Font = Enum.Font.GothamBold
        main.TextColor3 = WHITE
        main.TextXAlignment = Enum.TextXAlignment.Left
        main.TextYAlignment = Enum.TextYAlignment.Top
        main.TextTruncate = Enum.TextTruncate.AtEnd
        main.AutoButtonColor = false
        main.Parent = row
        corner(main, 8)

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingTop = UDim.new(0, 5)
        pad.Parent = main

        local cap = newLabel(main, entry.tab .. "  ›  " .. (entry.section ~= "" and entry.section or "-"),
            8, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 1, -14), UDim2.new(1, 0, 0, 12), Enum.TextXAlignment.Left)
        cap.TextTruncate = Enum.TextTruncate.AtEnd

        if isBtn then
            -- cerminkan teks & warna tombol asli (ON/OFF ikut berubah)
            rowConns[#rowConns + 1] = inst:GetPropertyChangedSignal("Text"):Connect(function()
                main.Text = labelOf(entry)
            end)
            rowConns[#rowConns + 1] = inst:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                main.BackgroundColor3 = inst.BackgroundColor3
            end)

            local jb = Instance.new("TextButton")
            jb.Name = "UHJump"
            jb.Position = UDim2.new(1, -50, 0, 0)
            jb.Size = UDim2.new(0, 24, 1, 0)
            jb.BackgroundTransparency = 1
            jb.Text = "↗"
            jb.TextSize = 15
            jb.Font = Enum.Font.GothamBold
            jb.TextColor3 = WHITE
            jb.AutoButtonColor = false
            jb.Parent = row
            jb.MouseButton1Click:Connect(function() jumpTo(entry) end)

            makeStar(row, entry.key, UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 24, 0, 30))
        end

        main.MouseButton1Click:Connect(function()
            if isBtn then
                if not fireClick(inst) then
                    notify("Executor tidak support firesignal, dibuka di tab asal")
                    jumpTo(entry)
                end
            else
                jumpTo(entry)
            end
        end)
        return row
    end

    -- susun ulang isi panel hasil
    local function rebuild()
        clearList()
        local q = queryText()
        local words = {}
        for w in string.gmatch(q, "%S+") do words[#words + 1] = w end
        local entries = collect()

        local pool = entries
        if favMode then
            local byKey = {}
            for _, e in ipairs(entries) do
                if e.key then byKey[e.key] = e end
            end
            pool = {}
            for _, k in ipairs(favList) do
                if byKey[k] then pool[#pool + 1] = byKey[k] end
            end
        end

        local shown, more = 0, false
        for _, e in ipairs(pool) do
            local ok = true
            if #words > 0 then
                local hay = string.lower(labelOf(e) .. " " .. e.tab .. " " .. e.section)
                for _, w in ipairs(words) do
                    if not string.find(hay, w, 1, true) then
                        ok = false
                        break
                    end
                end
            end
            if ok then
                if shown >= 40 then
                    more = true
                    break
                end
                shown = shown + 1
                makeRow(e, shown)
            end
        end

        if favMode then
            if #pool == 0 then
                ovInfo.Text = "Belum ada favorit. Tekan ☆ di kanan tombol fitur mana pun untuk menyimpannya, lalu tekan ⭐ FAV lagi untuk balik."
            elseif shown == 0 then
                ovInfo.Text = "Tidak ada favorit yang cocok dengan kata kunci."
            else
                ovInfo.Text = "⭐ " .. shown .. " favorit  •  tap = jalankan  •  ↗ = tab asal  •  ★ = hapus"
            end
        else
            if shown == 0 then
                ovInfo.Text = "Tidak ada fitur yang cocok."
            else
                ovInfo.Text = "🔍 " .. shown .. " hasil" .. (more and " (40 teratas, persempit kata kunci)" or "")
                    .. "  •  tap = jalankan  •  ↗ = tab asal"
            end
        end
    end

    -- tampilkan / sembunyikan panel sesuai kondisi (ada kata kunci atau mode FAV)
    local function refreshState()
        paintFavBtn()
        local active = favMode or queryText() ~= ""
        if active then
            if not overlayOpen then
                overlayOpen = true
                overlay.CanvasPosition = Vector2.new(0, 0)
                overlay.Visible = true
            end
            hidePages()
            rebuild()
        else
            overlayOpen = false
            overlay.Visible = false
            clearList()
            restorePage()
        end
    end

    closeOverlay = function()
        favMode = false
        if box.Text ~= "" then box.Text = "" end
        refreshState()
    end

    favBtn.MouseButton1Click:Connect(function()
        favMode = not favMode
        refreshState()
    end)

    local token = 0
    box:GetPropertyChangedSignal("Text"):Connect(function()
        token = token + 1
        local my = token
        task.delay(0.25, function()
            if my == token then refreshState() end
        end)
    end)

    -- pindah tab lewat tombol tab -> tutup mode cari / FAV
    for _, b in pairs(tabButtons) do
        b.MouseButton1Click:Connect(closeOverlay)
    end

    -- kalau favorit berubah (☆ / ★ ditekan) dan panel lagi terbuka -> segarkan
    refreshers[#refreshers + 1] = function()
        if overlayOpen then rebuild() end
    end

    -- bintang untuk fitur yang baru muncul / berganti teks: pasang ulang tiap tab dibuka
    for _, tab in ipairs(TABS) do
        local page = pages[tab]
        if typeof(page) == "Instance" then
            page:GetPropertyChangedSignal("Visible"):Connect(function()
                if page.Visible then task.defer(function() pcall(collect) end) end
            end)
            page.ChildAdded:Connect(function(c)
                if c:IsA("TextButton") or c:GetAttribute("UHGroup") then
                    task.defer(function() pcall(collect) end)
                end
            end)
        end
    end

    paintFavBtn()
    collect() -- pasang bintang pertama kali
end

xpcall(pages.initFav, function(e)
    warn("UNIVERSAL cari/favorit error: " .. tostring(e))
end)

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

-- =====================================================================
--  AUTO FARM HUB v1  —  UI & detail ala UNIVERSAL HUB v28
--  Target : workspace.HeistEggs  (Teleport ke egg -> Steal -> balik ke Safe Spot)
--  Tab    : FARM | AKUN | PLAYER | TELEPORT | SERVER | SETTING
--  Baru   : info akun (username, display name, UserId, tanggal, umur akun, dll),
--           bar FPS/ping + panel info (tap), notifikasi, riak sentuh, LED toggle,
--           scanner egg, ESP egg, prioritas income, fly/noclip/speed, slot teleport,
--           server hop, config tersimpan otomatis, slider ukuran UI.
-- =====================================================================

local __ok, __err = xpcall(function()

-- ==================== SERVICES ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ==================== THEME (sama dengan Universal) ====================
local BG_BLACK = Color3.fromRGB(10, 10, 15)
local BG_DARK = Color3.fromRGB(18, 22, 35)
local BG_BUTTON = Color3.fromRGB(25, 32, 50)
local BORDER_BLUE = Color3.fromRGB(60, 120, 255)
local ACCENT_BLUE = Color3.fromRGB(70, 130, 255)
local WHITE = Color3.fromRGB(255, 255, 255)
local GREY = Color3.fromRGB(150, 160, 180)
local GREEN = Color3.fromRGB(80, 220, 120)
local RED = Color3.fromRGB(255, 80, 80)
local YELLOW = Color3.fromRGB(250, 204, 21)
local ON_COLOR = Color3.fromRGB(40, 80, 40)
local LEFT = Enum.TextXAlignment.Left
local RIGHT = Enum.TextXAlignment.Right

-- ==================== CONFIG ====================
local RARITY_LIST = { "Common", "Uncommon", "Rare", "Epic", "Mythic", "Legendary", "Secret", "Special", "Godly", "Celestial" }
local RARITY_COLORS = {
    Common = Color3.fromRGB(160, 165, 175), Uncommon = Color3.fromRGB(95, 200, 120),
    Rare = Color3.fromRGB(80, 150, 255), Epic = Color3.fromRGB(170, 100, 255),
    Mythic = Color3.fromRGB(255, 90, 150), Legendary = Color3.fromRGB(255, 165, 50),
    Secret = Color3.fromRGB(60, 200, 190), Special = Color3.fromRGB(90, 220, 255),
    Godly = Color3.fromRGB(255, 220, 80), Celestial = Color3.fromRGB(190, 220, 255),
}

local CFG_FILE = "AutoFarmHub_config.json"
local cfg = {
    minIncome = "0",
    rarities = {},
    safe = { -87.02, 3.75, -180.10 },
    dTP = 0.25, dSteal = 0.35, dBack = 0.4,
    backSafe = true, priority = true,
    speed = 100, jump = 100, fly = 70,
    scale = 0, trans = 0.35, notif = true,
    slots = {},
}

local function loadCfg()
    pcall(function()
        if readfile and isfile and isfile(CFG_FILE) then
            local d = HttpService:JSONDecode(readfile(CFG_FILE))
            for k, v in pairs(d) do cfg[k] = v end
        end
    end)
end
loadCfg()

local saveToken = 0
local function saveCfg()
    saveToken = saveToken + 1
    local my = saveToken
    task.delay(0.8, function()
        if my ~= saveToken then return end
        pcall(function()
            if writefile then writefile(CFG_FILE, HttpService:JSONEncode(cfg)) end
        end)
    end)
end

-- ==================== STATE ====================
local S = {
    farmOn = false, stolen = 0, income = 0, t0 = os.clock(), joinTime = os.time(),
    recent = {}, espEggs = {}, espPlayers = {},
    cleanup = {},
}
local function onCleanup(fn) table.insert(S.cleanup, fn) end

-- ==================== HELPERS ====================
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

local function tw(o, t, props, style, dir, rep, rev)
    local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false), props)
    tween:Play()
    return tween
end

local function getChar() return player.Character end
local function getHum() local c = player.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = player.Character return c and c:FindFirstChild("HumanoidRootPart") end

local DAYS = { "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu" }
local MONTHS = { "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember" }

local function fmtDate(t)
    local d = os.date("*t", t)
    return string.format("%s, %d %s %d", DAYS[d.wday], d.day, MONTHS[d.month], d.year)
end
local function fmtDur(sec)
    sec = math.max(0, math.floor(sec))
    return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
end

local function parseIncome(text)
    if not text or text == "" then return 0 end
    text = (tostring(text):lower():gsub("%s+", ""):gsub(",", ""))
    local num = tonumber(text:match("[%d%.]+"))
    if not num then return 0 end
    if text:find("k") then return num * 1e3
    elseif text:find("m") then return num * 1e6
    elseif text:find("b") then return num * 1e9
    elseif text:find("t") then return num * 1e12 end
    return num
end

local function formatNumber(n)
    if n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function teleportTo(position)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(position) end
end

local function getObjectPosition(obj)
    local ok, pos = pcall(function()
        if obj:IsA("Model") or obj:IsA("BasePart") then return obj:GetPivot().Position end
    end)
    if ok and pos then return pos end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("BasePart") then return v.Position end
    end
    return nil
end

local function getPrompt(egg)
    return egg:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function eggIncome(egg)
    local v = egg:GetAttribute("HatchIncome") or 0
    if type(v) == "string" then v = parseIncome(v) end
    return tonumber(v) or 0
end

local clipFn = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard) or nil

-- ==================== SCREEN GUI ====================
local oldGui = PlayerGui:FindFirstChild("AutoFarmHubGui")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- ==================== NOTIFIKASI ====================
local NOTIF = { id = 0 }
local function notify(text, kind, dur)
    if cfg.notif == false then return end
    pcall(function()
        text = tostring(text)
        dur = dur or 2.6
        local marks = { { "✅", "ok" }, { "⚠️", "warn" }, { "⚠", "warn" }, { "❌", "err" }, { "⏳", nil }, { "ℹ️", nil }, { "💾", "ok" } }
        local icon
        for _, m in ipairs(marks) do
            if text:sub(1, #m[1]) == m[1] then
                icon = m[1]
                text = (text:sub(#m[1] + 1):gsub("^%s+", ""))
                kind = kind or m[2]
                break
            end
        end
        if not icon then icon = (kind == "ok" and "✅") or (kind == "warn" and "⚠️") or (kind == "err" and "❌") or "🔔" end
        local color = (kind == "ok" and GREEN) or (kind == "warn" and YELLOW) or (kind == "err" and RED) or ACCENT_BLUE

        if NOTIF.close then pcall(NOTIF.close, true) end
        local W = 236
        local bounds = TextService:GetTextSize(text, 11, Enum.Font.GothamBold, Vector2.new(W - 60, 10000))
        local H = math.max(40, bounds.Y + 27)
        local Y0 = 30
        NOTIF.id = NOTIF.id + 1
        local myId = NOTIF.id

        local f = Instance.new("Frame")
        f.Name = "AFNotif"
        f.AnchorPoint = Vector2.new(0.5, 0)
        f.Position = UDim2.new(0.5, 0, 0, Y0 - 12)
        f.Size = UDim2.new(0, W, 0, H)
        f.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ZIndex = 200
        f.Active = true
        f.Parent = screenGui
        corner(f, 12)
        local st = stroke(f, color, 1.5)
        st.Transparency = 1
        local sc = Instance.new("UIScale")
        sc.Scale = 0.8
        sc.Parent = f

        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.55) })
        g.Parent = st
        TweenService:Create(g, TweenInfo.new(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()

        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.new(0, 26, 0, 26)
        iconBg.Position = UDim2.new(0, 8, 0.5, -13)
        iconBg.BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.65)
        iconBg.BackgroundTransparency = 1
        iconBg.BorderSizePixel = 0
        iconBg.ZIndex = 201
        iconBg.Parent = f
        corner(iconBg, 13)
        local iconLbl = newLabel(iconBg, icon, 14, Enum.Font.GothamBold, WHITE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        iconLbl.TextTransparency = 1
        iconLbl.ZIndex = 202
        local iconScale = Instance.new("UIScale")
        iconScale.Scale = 0.2
        iconScale.Parent = iconLbl

        local titleLbl = newLabel(f, "AUTO FARM", 8, Enum.Font.GothamBlack, color, UDim2.new(0, 42, 0, 5), UDim2.new(1, -52, 0, 10), LEFT)
        titleLbl.TextTransparency = 1
        titleLbl.ZIndex = 201
        local msgLbl = newLabel(f, text, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 42, 0, 16), UDim2.new(1, -52, 0, bounds.Y), LEFT)
        msgLbl.TextWrapped = true
        msgLbl.TextYAlignment = Enum.TextYAlignment.Top
        msgLbl.TextTransparency = 1
        msgLbl.ZIndex = 201

        local track = Instance.new("Frame")
        track.Position = UDim2.new(0, 12, 1, -6)
        track.Size = UDim2.new(1, -24, 0, 2)
        track.BackgroundColor3 = Color3.fromRGB(40, 48, 70)
        track.BackgroundTransparency = 1
        track.BorderSizePixel = 0
        track.ZIndex = 201
        track.Parent = f
        corner(track, 1)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(1, 0, 1, 0)
        fill.BackgroundColor3 = color
        fill.BackgroundTransparency = 1
        fill.BorderSizePixel = 0
        fill.ZIndex = 202
        fill.Parent = track
        corner(fill, 1)

        tw(f, 0.26, { BackgroundTransparency = 0.28, Position = UDim2.new(0.5, 0, 0, Y0) })
        tw(st, 0.26, { Transparency = 0.2 })
        tw(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
        tw(iconBg, 0.26, { BackgroundTransparency = 0.15 })
        tw(iconLbl, 0.26, { TextTransparency = 0 })
        tw(iconScale, 0.42, { Scale = 1 }, Enum.EasingStyle.Back)
        tw(titleLbl, 0.28, { TextTransparency = 0.1 })
        tw(msgLbl, 0.28, { TextTransparency = 0 })
        tw(track, 0.28, { BackgroundTransparency = 0.4 })
        tw(fill, 0.28, { BackgroundTransparency = 0.1 })
        TweenService:Create(iconBg, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Size = UDim2.new(0, 29, 0, 29), Position = UDim2.new(0, 6.5, 0.5, -14.5) }):Play()

        local rnd = Random.new()
        for _ = 1, 4 do
            local sp = newLabel(f, rnd:NextInteger(0, 1) == 0 and "✦" or "✧", rnd:NextInteger(8, 11), Enum.Font.GothamBold, color,
                UDim2.new(0, rnd:NextInteger(8, W - 20), 0, rnd:NextInteger(4, math.max(6, H - 14))), UDim2.new(0, 12, 0, 12))
            sp.ZIndex = 203
            sp.TextTransparency = 0.15
            tw(sp, rnd:NextNumber(0.6, 1.0), {
                Position = UDim2.new(sp.Position.X.Scale, sp.Position.X.Offset + rnd:NextInteger(-10, 10), 0, sp.Position.Y.Offset - rnd:NextInteger(14, 28)),
                TextTransparency = 1,
            })
            task.delay(1.2, function() if sp.Parent then sp:Destroy() end end)
        end
        tw(fill, dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

        local closed = false
        local function close(instant)
            if closed then return end
            closed = true
            if NOTIF.close == close then NOTIF.close = nil end
            if instant then f:Destroy() return end
            tw(f, 0.2, { BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0, Y0 - 8) })
            tw(st, 0.2, { Transparency = 1 })
            tw(sc, 0.22, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tw(iconBg, 0.18, { BackgroundTransparency = 1 })
            tw(iconLbl, 0.18, { TextTransparency = 1 })
            tw(titleLbl, 0.18, { TextTransparency = 1 })
            tw(msgLbl, 0.18, { TextTransparency = 1 })
            tw(track, 0.18, { BackgroundTransparency = 1 })
            tw(fill, 0.18, { BackgroundTransparency = 1 })
            task.delay(0.26, function() if f.Parent then f:Destroy() end end)
        end
        NOTIF.close = close
        f.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then close() end
        end)
        task.delay(dur, function() if NOTIF.id == myId then close() end end)
    end)
end

local function copyText(text, what)
    if not clipFn then notify("⚠️ Executor tidak support salin", "warn") return end
    local ok = pcall(clipFn, tostring(text))
    notify(ok and ("✅ " .. what .. " tersalin") or "⚠️ Gagal menyalin", ok and "ok" or "warn")
end

-- ==================== TOMBOL ↑ ↓ (FLY) ====================
local flyControlFrame = Instance.new("Frame")
flyControlFrame.Name = "FlyControls"
flyControlFrame.Size = UDim2.new(0, 40, 0, 86)
flyControlFrame.Position = UDim2.new(1, -50, 0.5, -43)
flyControlFrame.BackgroundTransparency = 1
flyControlFrame.BorderSizePixel = 0
flyControlFrame.Visible = false
flyControlFrame.Parent = screenGui

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

-- ==================== MAIN FRAME ====================
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

local uiScale = Instance.new("UIScale")
uiScale.Name = "UHMiniScale"
uiScale.Parent = mainFrame
do
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local def = math.clamp((vp.Y * 0.9) / 405, 0.55, 1)
    def = math.floor(def * 20 + 0.5) / 20
    if not cfg.scale or cfg.scale <= 0 then cfg.scale = def end
    uiScale.Scale = cfg.scale
end

local bgImage = Instance.new("ImageLabel")
bgImage.Name = "Background"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxassetid://134262192520482"
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ImageTransparency = cfg.trans or 0.35
bgImage.ZIndex = 0
bgImage.Parent = mainFrame
corner(bgImage, 12)
task.spawn(function()
    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://134262192520482") end)
    if ok and objs and objs[1] then
        local o = objs[1]
        local d = (o:IsA("Decal") or o:IsA("Texture")) and o or o:FindFirstChildWhichIsA("Decal", true) or o:FindFirstChildWhichIsA("Texture", true)
        if d and d.Texture and d.Texture ~= "" then bgImage.Image = d.Texture end
    end
end)

-- ==================== TOP BAR ====================
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = BG_BLACK
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
corner(topBar, 14)

local globeIcon = newLabel(topBar, "🌐", 18, Enum.Font.GothamBold, WHITE, UDim2.new(0, 10, 0, 10), UDim2.new(0, 22, 0, 22))
local titleLabel = newLabel(topBar, "AUTO FARM", 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 36, 0, 8), UDim2.new(1, -110, 0, 20), LEFT)
newLabel(topBar, "Heist Egg Hub", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 28), UDim2.new(1, -110, 0, 12), LEFT)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 10, 0, 44)
statusDot.BackgroundColor3 = GREEN
statusDot.BorderSizePixel = 0
statusDot.Parent = topBar
corner(statusDot, 3)
statusDot.BackgroundTransparency = 0.1
tw(statusDot, 0.9, { BackgroundTransparency = 0.7 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
newLabel(topBar, "ONLINE", 8, Enum.Font.GothamBold, GREEN, UDim2.new(0, 20, 0, 40), UDim2.new(0, 50, 0, 12), LEFT)

-- judul berkilau
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 160, 215)),
        ColorSequenceKeypoint.new(0.5, WHITE),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 160, 215)),
    })
    g.Offset = Vector2.new(-1, 0)
    g.Parent = titleLabel
    tw(g, 2.4, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)
end

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
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

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
    S.farmOn = false
    for _, fn in ipairs(S.cleanup) do pcall(fn) end
    screenGui:Destroy()
end)

-- ==================== DRAG ====================
do
    local dragging, dragStart, startPos = false, nil, nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    local c = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    onCleanup(function() c:Disconnect() end)
end

-- ==================== LOGO BUBBLE ====================
local logoBtn = Instance.new("TextButton")
logoBtn.Size = UDim2.new(0, 44, 0, 44)
logoBtn.Position = UDim2.new(0, 15, 0.5, -22)
logoBtn.BackgroundColor3 = BG_BLACK
logoBtn.Text = "🥚"
logoBtn.TextSize = 18
logoBtn.Font = Enum.Font.GothamMedium
logoBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
logoBtn.Parent = screenGui
corner(logoBtn, 22)
local logoStroke = stroke(logoBtn, Color3.fromRGB(255, 215, 0), 1.5)
tw(logoStroke, 1.1, { Thickness = 3, Transparency = 0.35 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
do
    local ld, lm, ls, lsp = false, false, nil, nil
    logoBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ld, lm, ls, lsp = true, false, input.Position, logoBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then ld = false end
            end)
        end
    end)
    local c = UserInputService.InputChanged:Connect(function(input)
        if not ld then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - ls
        if not lm and d.Magnitude < 8 then return end
        lm = true
        logoBtn.Position = UDim2.new(lsp.X.Scale, lsp.X.Offset + d.X, lsp.Y.Scale, lsp.Y.Offset + d.Y)
    end)
    onCleanup(function() c:Disconnect() end)
    logoBtn.MouseButton1Click:Connect(function()
        if lm then lm = false return end
        mainFrame.Visible = not mainFrame.Visible
    end)
end

-- animasi buka hub (membesar memantul)
do
    local popTween
    mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not mainFrame.Visible then return end
        local base = cfg.scale
        if popTween then popTween:Cancel() end
        uiScale.Scale = base * 0.88
        popTween = tw(uiScale, 0.22, { Scale = base }, Enum.EasingStyle.Back)
    end)
end

-- ==================== INFO BAR (FPS / PING / PLAYER / MEMORI / JAM) ====================
local infoBar = Instance.new("Frame")
infoBar.Name = "InfoBar"
infoBar.Size = UDim2.new(0, 350, 0, 20)
infoBar.Position = UDim2.new(0.5, -175, 0, 2)
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

S.fps, S.ping, S.mem = 0, 0, 0
do
    local frames, acc = 0, 0
    local c = RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1
        acc = acc + dt
        if acc >= 0.5 then
            S.fps = math.floor(frames / acc + 0.5)
            frames, acc = 0, 0
            pcall(function() S.ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pcall(function() S.mem = math.floor(Stats:GetTotalMemoryUsageMb()) end)
            infoLabel.Text = string.format("📊 FPS %d  |  📶 %dms  |  👥 %d  |  💾 %dMB  |  🕒 %s", S.fps, S.ping, #Players:GetPlayers(), S.mem, os.date("%H:%M"))
            infoLabel.TextColor3 = (S.ping < 100 and GREEN) or (S.ping < 200 and YELLOW) or RED
        end
    end)
    onCleanup(function() c:Disconnect() end)
end

-- ==================== DATA AKUN / GAME ====================
local gameName = "Memuat..."
task.spawn(function()
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    gameName = (ok and info and info.Name) or ("Place " .. tostring(game.PlaceId))
end)

local function executorName()
    local ok, n, v = pcall(function() if identifyexecutor then return identifyexecutor() end end)
    if ok and n then return tostring(n) .. (v and (" " .. tostring(v)) or "") end
    return "Tidak diketahui"
end
local function deviceName()
    local ui = UserInputService
    if ui.TouchEnabled and not ui.KeyboardEnabled then return "📱 Mobile" end
    if ui.GamepadEnabled and not ui.KeyboardEnabled then return "🎮 Console/Gamepad" end
    return "💻 PC"
end
local function accountCreated()
    return os.time() - (player.AccountAge * 86400)
end
local function membership()
    local ok, n = pcall(function() return player.MembershipType.Name end)
    return ok and n or "Unknown"
end

-- panel info (tap bar FPS)
local infoPanel = Instance.new("Frame")
infoPanel.Name = "InfoPanel"
infoPanel.Size = UDim2.new(0, 290, 0, 168)
infoPanel.Position = UDim2.new(0.5, -145, 0, 25)
infoPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
infoPanel.BackgroundTransparency = 0.15
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 50
infoPanel.Visible = false
infoPanel.Parent = screenGui
corner(infoPanel, 10)
stroke(infoPanel, ACCENT_BLUE, 1)

local infoText = Instance.new("TextLabel")
infoText.BackgroundTransparency = 1
infoText.Position = UDim2.new(0, 8, 0, 4)
infoText.Size = UDim2.new(1, -16, 1, -52)
infoText.TextXAlignment = LEFT
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.TextSize = 10
infoText.Font = Enum.Font.GothamBold
infoText.TextColor3 = WHITE
infoText.ZIndex = 51
infoText.Parent = infoPanel

local function infoCopyBtn(text, xs, xo, getter, what)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(xs, xo, 1, -40)
    b.Size = UDim2.new(0.5, -12, 0, 32)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.ZIndex = 51
    b.Parent = infoPanel
    corner(b, 8)
    b.MouseButton1Click:Connect(function() copyText(getter(), what) end)
end
infoCopyBtn("📋 SALIN USERNAME", 0, 8, function() return player.Name end, "Username")
infoCopyBtn("📋 SALIN JOB ID", 0.5, 4, function() return game.JobId end, "Job ID")

local function refreshInfoPanel()
    infoText.Text = string.format(
        "👤 %s (@%s)\n🆔 UserId: %d\n📅 Akun dibuat: %s (%d hari)\n🗓️ Hari ini: %s\n🎮 %s\n🧩 Job: %s\n👥 Player: %d / %d   ⏱ Main: %s",
        player.DisplayName, player.Name, player.UserId, fmtDate(accountCreated()), player.AccountAge,
        fmtDate(os.time()) .. " • " .. os.date("%H:%M:%S"),
        tostring(gameName), (game.JobId ~= "" and game.JobId or "-"),
        #Players:GetPlayers(), Players.MaxPlayers, fmtDur(os.clock() - S.t0))
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

-- ==================== SEARCH ====================
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -16, 0, 24)
searchBox.Position = UDim2.new(0, 8, 0, 55)
searchBox.BackgroundColor3 = BG_DARK
searchBox.PlaceholderText = "🔍 cari fitur di tab ini..."
searchBox.PlaceholderColor3 = GREY
searchBox.Text = ""
searchBox.TextSize = 10
searchBox.Font = Enum.Font.GothamBold
searchBox.TextColor3 = WHITE
searchBox.ClearTextOnFocus = false
searchBox.Parent = mainFrame
corner(searchBox, 8)
stroke(searchBox, ACCENT_BLUE, 1)

-- ==================== TABS + PAGES ====================
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
tabContainer.Parent = mainFrame
corner(tabContainer, 8)
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabContainer

local pages, tabButtons = {}, {}

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
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = page
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    pages[name] = page
    return page
end

local currentTab = "FARM"
local function applySearch()
    local q = string.lower(searchBox.Text or "")
    for _, c in ipairs(pages[currentTab]:GetChildren()) do
        if c:IsA("GuiObject") then
            if c:GetAttribute("Srch") then
                c.Visible = (q == "") or (string.find(string.lower(c.Text), q, 1, true) ~= nil)
            elseif c:GetAttribute("SrchHide") then
                c.Visible = (q == "")
            end
        end
    end
end
searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

local function selectTab(name)
    currentTab = name
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
    applySearch()
end

local function makeTabButton(name, icon, text)
    makePage(name)
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
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
end

makeTabButton("FARM", "🌾", "FARM")
makeTabButton("AKUN", "🪪", "AKUN")
makeTabButton("PLAYER", "👤", "PLAYER")
makeTabButton("TELEPORT", "📍", "TELEPORT")
makeTabButton("SERVER", "🖥️", "SERVER")
makeTabButton("SETTING", "⚙️", "SETTING")

-- ==================== STATUS BAR (bawah) ====================
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -16, 0, 40)
statusBar.Position = UDim2.new(0, 8, 1, -46)
statusBar.BackgroundColor3 = BG_DARK
statusBar.BackgroundTransparency = 0.1
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
corner(statusBar, 8)
stroke(statusBar, ACCENT_BLUE, 1)

local statusLbl = newLabel(statusBar, "● Idle", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 8, 0, 3), UDim2.new(1, -16, 0, 17), LEFT)
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
local statsLbl = newLabel(statusBar, "", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 20), UDim2.new(1, -16, 0, 17), LEFT)

local function setStatus(text, color)
    statusLbl.Text = "● " .. text
    statusLbl.TextColor3 = color or GREY
end
local function updateStats()
    statsLbl.Text = string.format("🥚 %d  |  💰 %s  |  ⏱ %s", S.stolen, formatNumber(S.income), fmtDur(os.clock() - S.t0))
end
updateStats()
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        updateStats()
    end
end)

-- ==================== KOMPONEN UI ====================
local function makeHeader(parent, text, order)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundColor3 = BG_DARK
    f.BorderSizePixel = 0
    f.Parent = parent
    f:SetAttribute("SrchHide", true)
    corner(f, 6)
    stroke(f, ACCENT_BLUE, 1)
    local acc = Instance.new("Frame")
    acc.Position = UDim2.new(0, 5, 0.5, -6)
    acc.Size = UDim2.new(0, 3, 0, 12)
    acc.BackgroundColor3 = ACCENT_BLUE
    acc.BackgroundTransparency = 0.1
    acc.BorderSizePixel = 0
    acc.Parent = f
    corner(acc, 2)
    tw(acc, 1.1, { BackgroundTransparency = 0.65 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 14, 0, 0), UDim2.new(1, -22, 1, 0), LEFT)
    return f
end

local function makeCard(parent, order, height)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, height)
    f.BackgroundColor3 = BG_DARK
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.Parent = parent
    f:SetAttribute("SrchHide", true)
    corner(f, 8)
    return f
end

local function inScale()
    return uiScale.Scale > 0 and uiScale.Scale or 1
end

-- riak sentuh + LED + kilat toggle
local function decorate(btn)
    btn.ClipsDescendants = true
    local function ripple(input)
        local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
        if size.X < 2 or size.Y < 2 then return end
        local fx = math.clamp((input.Position.X - abs.X) / size.X, 0, 1)
        local fy = math.clamp((input.Position.Y - abs.Y) / size.Y, 0, 1)
        local d = (size.X / inScale()) * 1.5
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(fx, 0, fy, 0)
        r.Size = UDim2.new(0, 0, 0, 0)
        r.BackgroundColor3 = WHITE
        r.BackgroundTransparency = 0.72
        r.BorderSizePixel = 0
        r.ZIndex = btn.ZIndex + 3
        r.Parent = btn
        corner(r, 999)
        local t = tw(r, 0.5, { Size = UDim2.new(0, d, 0, d), BackgroundTransparency = 1 })
        t.Completed:Connect(function() r:Destroy() end)
    end
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pcall(ripple, input)
        end
    end)

    local function isOn() return string.find(btn.Text, "• ON", 1, true) ~= nil end
    if string.find(btn.Text, "• ON", 1, true) or string.find(btn.Text, "• OFF", 1, true) then
        local led = Instance.new("Frame")
        led.AnchorPoint = Vector2.new(0, 0.5)
        led.Position = UDim2.new(0, 9, 0.5, 0)
        led.Size = UDim2.new(0, 7, 0, 7)
        led.BorderSizePixel = 0
        led.ZIndex = btn.ZIndex + 2
        led.Parent = btn
        corner(led, 4)
        local glow = Instance.new("UIStroke")
        glow.Color = GREEN
        glow.Thickness = 2
        glow.Parent = led
        local wasOn = isOn()
        local function paint()
            local on = isOn()
            led.BackgroundColor3 = on and GREEN or Color3.fromRGB(70, 78, 98)
            glow.Transparency = on and 0.45 or 1
            if on and not wasOn then
                local sw = Instance.new("Frame")
                sw.AnchorPoint = Vector2.new(0, 0.5)
                sw.Position = UDim2.new(-0.4, 0, 0.5, 0)
                sw.Size = UDim2.new(0.4, 0, 1.6, 0)
                sw.Rotation = 15
                sw.BackgroundColor3 = WHITE
                sw.BackgroundTransparency = 0.78
                sw.BorderSizePixel = 0
                sw.ZIndex = btn.ZIndex + 3
                sw.Parent = btn
                local gr = Instance.new("UIGradient")
                gr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
                gr.Parent = sw
                local t = tw(sw, 0.5, { Position = UDim2.new(1.1, 0, 0.5, 0) })
                t.Completed:Connect(function() sw:Destroy() end)
            end
            wasOn = on
        end
        paint()
        btn:GetPropertyChangedSignal("Text"):Connect(paint)
    end
end

local function makeButton(parent, text, order, noNotify)
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
    btn:SetAttribute("Srch", true)
    corner(btn, 8)
    decorate(btn)
    if not noNotify then
        btn.MouseButton1Click:Connect(function() notify("ℹ️ " .. btn.Text, nil, 1.6) end)
    end
    return btn
end

-- tombol toggle: label + " • ON/OFF"
local function makeToggle(parent, label, order, onChange, initial)
    local btn = makeButton(parent, label .. " • OFF", order, true)
    local state = false
    local api = {}
    function api.set(v, silent)
        state = v and true or false
        btn.Text = label .. (state and " • ON" or " • OFF")
        btn.BackgroundColor3 = state and ON_COLOR or BG_BUTTON
        if not silent then
            notify((state and "✅ " or "ℹ️ ") .. label .. (state and " dinyalakan" or " dimatikan"), state and "ok" or nil, 1.8)
            if onChange then onChange(state) end
        end
    end
    function api.get() return state end
    btn.MouseButton1Click:Connect(function() api.set(not state) end)
    api.btn = btn
    if initial then api.set(true, true) end
    return api
end

local function makeInput(parent, order, label, default, commit)
    local card = makeCard(parent, order, 52)
    newLabel(card, label, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 18), LEFT)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 0, 24)
    box.Position = UDim2.new(0, 8, 0, 22)
    box.BackgroundColor3 = BG_BUTTON
    box.Text = tostring(default)
    box.TextSize = 12
    box.Font = Enum.Font.GothamBold
    box.TextColor3 = WHITE
    box.ClearTextOnFocus = false
    box.Parent = card
    corner(box, 6)
    local st = stroke(box, Color3.fromRGB(40, 48, 70), 1)
    box.Focused:Connect(function() tw(st, 0.15, { Color = ACCENT_BLUE }) end)
    box.FocusLost:Connect(function()
        tw(st, 0.15, { Color = Color3.fromRGB(40, 48, 70) })
        commit(box)
    end)
    return card, box
end

local function numInput(parent, order, label, default, minV, maxV, onSet)
    local _, box
    _, box = makeInput(parent, order, label, default, function(b)
        local v = tonumber(b.Text)
        if v and v >= minV and v <= maxV then onSet(v) else b.Text = tostring(default) end
        default = tonumber(b.Text) or default
    end)
    return box
end

local function makeSlider(parent, order, label, minV, maxV, step, startV, setV, fmt)
    local card = makeCard(parent, order, 50)
    newLabel(card, label, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(0.6, -8, 0, 18), LEFT)
    local valLbl = newLabel(card, "", 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0.6, 0, 0, 4), UDim2.new(0.4, -8, 0, 18), RIGHT)
    local area = Instance.new("TextButton")
    area.Size = UDim2.new(1, -16, 0, 22)
    area.Position = UDim2.new(0, 8, 0, 24)
    area.BackgroundTransparency = 1
    area.Text = ""
    area.AutoButtonColor = false
    area.Parent = card
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0.5, -3)
    track.BackgroundColor3 = BG_BUTTON
    track.BorderSizePixel = 0
    track.Parent = area
    corner(track, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT_BLUE
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = WHITE
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 7)
    stroke(knob, ACCENT_BLUE, 2)

    local function render(v)
        local r = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        valLbl.Text = fmt(v)
    end
    local sliding = false
    local function fromInput(input)
        local r = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        local v = minV + r * (maxV - minV)
        v = math.clamp(math.floor(v / step + 0.5) * step, minV, maxV)
        render(v)
        setV(v)
    end
    area.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            fromInput(input)
        end
    end)
    local c1 = UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    local c2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if sliding then sliding = false saveCfg() end
        end
    end)
    onCleanup(function() c1:Disconnect() c2:Disconnect() end)
    render(startV)
    return render
end

-- =====================================================================
--  TAB FARM
-- =====================================================================
local farmPage = pages.FARM
makeHeader(farmPage, "🌾 AUTO FARM EGG", 0)

local function shouldSteal(egg)
    local rarity = egg:GetAttribute("Rarity")
    if not rarity then return false end
    if not cfg.rarities[rarity] then return false end
    if eggIncome(egg) < parseIncome(cfg.minIncome) then return false end
    return true
end

local function collectTargets()
    local list = {}
    local folder = workspace:FindFirstChild("HeistEggs")
    if not folder then return list, false end
    local now = os.clock()
    for _, egg in ipairs(folder:GetChildren()) do
        if shouldSteal(egg) then
            local last = S.recent[egg]
            if not last or now - last > 3 then
                local pos, prompt = getObjectPosition(egg), getPrompt(egg)
                if pos and prompt then
                    table.insert(list, { egg = egg, pos = pos, prompt = prompt, income = eggIncome(egg) })
                end
            end
        end
    end
    if cfg.priority then
        table.sort(list, function(a, b) return a.income > b.income end)
    end
    return list, true
end

local farmToggle
local function startFarm()
    if S.farmRunning then return end
    S.farmRunning = true
    task.spawn(function()
        while S.farmOn do
            local targets, hasFolder = collectTargets()
            if not hasFolder then
                setStatus("Folder HeistEggs tidak ditemukan", YELLOW)
            elseif #targets == 0 then
                setStatus("Menunggu target...", GREY)
            else
                for _, t in ipairs(targets) do
                    if not S.farmOn then break end
                    if t.egg.Parent and getHRP() then
                        S.recent[t.egg] = os.clock()
                        setStatus("Menuju " .. t.egg.Name, ACCENT_BLUE)
                        teleportTo(t.pos + Vector3.new(0, 3, 0))
                        task.wait(cfg.dTP)

                        setStatus("Mencuri " .. t.egg.Name, GREEN)
                        local fired = pcall(function()
                            if not fireproximityprompt then error("no fpp") end
                            fireproximityprompt(t.prompt)
                        end)
                        if not fired then
                            notify("⚠️ Executor tidak support fireproximityprompt", "warn", 4)
                            S.farmOn = false
                            if farmToggle then farmToggle.set(false, true) end
                            break
                        end
                        task.wait(cfg.dSteal)

                        if cfg.backSafe then teleportTo(Vector3.new(cfg.safe[1], cfg.safe[2], cfg.safe[3])) end
                        S.stolen = S.stolen + 1
                        S.income = S.income + t.income
                        updateStats()
                        task.wait(cfg.dBack)
                    end
                end
            end
            task.wait(0.5)
        end
        S.farmRunning = false
        setStatus("Idle", GREY)
    end)
end

farmToggle = makeToggle(farmPage, "🤖 AUTO FARM", 1, function(on)
    S.farmOn = on
    if on then
        if next(cfg.rarities) == nil or not (function() for _, v in pairs(cfg.rarities) do if v then return true end end return false end)() then
            notify("⚠️ Pilih minimal 1 rarity dulu", "warn")
        end
        setStatus("Berjalan", GREEN)
        notify("✅ Auto Farm dinyalakan", "ok")
        startFarm()
    else
        setStatus("Idle", GREY)
        notify("ℹ️ Auto Farm dimatikan")
    end
end)

local _, incomeBox = makeInput(farmPage, 2, "💰 MINIMAL INCOME  (1k / 1m / 1b / 1t)", cfg.minIncome, function(b)
    cfg.minIncome = b.Text
    b.Text = formatNumber(parseIncome(b.Text))
    saveCfg()
end)
incomeBox.PlaceholderText = "contoh: 1.5m"
incomeBox.PlaceholderColor3 = GREY

makeHeader(farmPage, "💎 RARITY", 3)

local rarRow = makeCard(farmPage, 4, 30)
rarRow.BackgroundTransparency = 1
local chips = {}
local function setRarity(r, state, silent)
    cfg.rarities[r] = state and true or false
    local c = chips[r]
    local color = RARITY_COLORS[r] or ACCENT_BLUE
    if state then
        tw(c.btn, 0.18, { BackgroundColor3 = color:Lerp(BG_BLACK, 0.55) })
        tw(c.st, 0.18, { Color = color })
        c.check.Text = "✓"
    else
        tw(c.btn, 0.18, { BackgroundColor3 = BG_BUTTON })
        tw(c.st, 0.18, { Color = Color3.fromRGB(40, 48, 70) })
        c.check.Text = ""
    end
    if not silent then saveCfg() end
end

local function rowBtn(parent, text, xs, xo, w)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w, -4, 1, 0)
    b.Position = UDim2.new(xs, xo, 0, 0)
    b.BackgroundColor3 = BG_BUTTON
    b.Text = text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = WHITE
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 8)
    decorate(b)
    return b
end
local allBtn = rowBtn(rarRow, "✅ SEMUA", 0, 0, 0.5)
local clrBtn = rowBtn(rarRow, "♻️ RESET", 0.5, 4, 0.5)

local chipScroll = Instance.new("ScrollingFrame")
chipScroll.LayoutOrder = 5
chipScroll.Size = UDim2.new(1, 0, 0, 132)
chipScroll.BackgroundColor3 = BG_DARK
chipScroll.BackgroundTransparency = 0.1
chipScroll.BorderSizePixel = 0
chipScroll.ScrollBarThickness = 3
chipScroll.ScrollBarImageColor3 = ACCENT_BLUE
chipScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
chipScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
chipScroll.Parent = farmPage
chipScroll:SetAttribute("SrchHide", true)
corner(chipScroll, 8)
stroke(chipScroll, Color3.fromRGB(40, 48, 70), 1)
do
    local p = Instance.new("UIPadding")
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 5), UDim.new(0, 5), UDim.new(0, 5), UDim.new(0, 5)
    p.Parent = chipScroll
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.5, -3, 0, 28)
    grid.CellPadding = UDim2.new(0, 5, 0, 5)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = chipScroll
end
for i, r in ipairs(RARITY_LIST) do
    local color = RARITY_COLORS[r]
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = i
    btn.BackgroundColor3 = BG_BUTTON
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = chipScroll
    corner(btn, 7)
    local st = stroke(btn, Color3.fromRGB(40, 48, 70), 1)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 8, 0.5, -4)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    dot.Parent = btn
    corner(dot, 4)
    local lbl = newLabel(btn, r, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 22, 0, 0), UDim2.new(1, -40, 1, 0), LEFT)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    local check = newLabel(btn, "", 13, Enum.Font.GothamBold, color, UDim2.new(1, -20, 0, 0), UDim2.new(0, 16, 1, 0))
    chips[r] = { btn = btn, st = st, check = check }
    btn.MouseButton1Click:Connect(function()
        setRarity(r, not cfg.rarities[r])
        notify((cfg.rarities[r] and "✅ Rarity " or "ℹ️ Rarity ") .. r .. (cfg.rarities[r] and " dipilih" or " dibatalkan"), cfg.rarities[r] and "ok" or nil, 1.4)
    end)
end
for _, r in ipairs(RARITY_LIST) do setRarity(r, cfg.rarities[r], true) end
allBtn.MouseButton1Click:Connect(function() for _, r in ipairs(RARITY_LIST) do setRarity(r, true, true) end saveCfg() notify("✅ Semua rarity dipilih", "ok", 1.6) end)
clrBtn.MouseButton1Click:Connect(function() for _, r in ipairs(RARITY_LIST) do setRarity(r, false, true) end saveCfg() notify("ℹ️ Pilihan rarity direset", nil, 1.6) end)

makeHeader(farmPage, "⚙️ PENGATURAN FARM", 6)
makeToggle(farmPage, "🏆 PRIORITAS INCOME TERTINGGI", 7, function(on) cfg.priority = on saveCfg() end, cfg.priority)
makeToggle(farmPage, "🏠 BALIK KE SAFE SPOT", 8, function(on) cfg.backSafe = on saveCfg() end, cfg.backSafe)
numInput(farmPage, 9, "⏱ DELAY SETELAH TP KE EGG (detik)", cfg.dTP, 0, 5, function(v) cfg.dTP = v saveCfg() end)
numInput(farmPage, 10, "⏱ DELAY SETELAH STEAL (detik)", cfg.dSteal, 0, 5, function(v) cfg.dSteal = v saveCfg() end)
numInput(farmPage, 11, "⏱ DELAY SETELAH BALIK (detik)", cfg.dBack, 0, 5, function(v) cfg.dBack = v saveCfg() end)

local safeLbl = newLabel(farmPage, "", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 16), LEFT)
safeLbl.LayoutOrder = 14
safeLbl:SetAttribute("SrchHide", true)
local function refreshSafeLbl()
    safeLbl.Text = string.format("🏠 Safe Spot: %.1f, %.1f, %.1f", cfg.safe[1], cfg.safe[2], cfg.safe[3])
end
refreshSafeLbl()
local setSafeBtn = makeButton(farmPage, "📌 SET SAFE SPOT = POSISI SEKARANG", 12)
setSafeBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP()
    if not hrp then notify("⚠️ Karakter belum siap", "warn") return end
    local p = hrp.Position
    cfg.safe = { p.X, p.Y, p.Z }
    refreshSafeLbl()
    saveCfg()
    notify("✅ Safe Spot disimpan", "ok")
end)
local goSafeBtn = makeButton(farmPage, "🏠 TELEPORT KE SAFE SPOT", 13)
goSafeBtn.MouseButton1Click:Connect(function() teleportTo(Vector3.new(cfg.safe[1], cfg.safe[2], cfg.safe[3])) end)

makeHeader(farmPage, "🥚 SCANNER & ESP EGG", 15)
local scanBtn = makeButton(farmPage, "🔍 SCAN EGG (HeistEggs)", 16)

local eggList = Instance.new("ScrollingFrame")
eggList.LayoutOrder = 17
eggList.Size = UDim2.new(1, 0, 0, 120)
eggList.BackgroundColor3 = BG_DARK
eggList.BackgroundTransparency = 0.1
eggList.BorderSizePixel = 0
eggList.ScrollBarThickness = 3
eggList.ScrollBarImageColor3 = ACCENT_BLUE
eggList.CanvasSize = UDim2.new(0, 0, 0, 0)
eggList.AutomaticCanvasSize = Enum.AutomaticSize.Y
eggList.Parent = farmPage
eggList:SetAttribute("SrchHide", true)
corner(eggList, 8)
stroke(eggList, Color3.fromRGB(40, 48, 70), 1)
do
    local p = Instance.new("UIPadding")
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
    p.Parent = eggList
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 3)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = eggList
end

local function refreshEggList()
    for _, c in ipairs(eggList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    local folder = workspace:FindFirstChild("HeistEggs")
    local items = {}
    if folder then
        for _, egg in ipairs(folder:GetChildren()) do
            table.insert(items, { egg = egg, rarity = egg:GetAttribute("Rarity") or "?", income = eggIncome(egg) })
        end
    end
    table.sort(items, function(a, b) return a.income > b.income end)
    if #items == 0 then
        local l = newLabel(eggList, folder and "Belum ada egg" or "Folder HeistEggs tidak ada", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 24))
        return 0
    end
    for i, it in ipairs(items) do
        local b = Instance.new("TextButton")
        b.LayoutOrder = i
        b.Size = UDim2.new(1, 0, 0, 24)
        b.BackgroundColor3 = BG_BUTTON
        b.Text = string.format("%s • %s • %s/s", it.egg.Name, it.rarity, formatNumber(it.income))
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = RARITY_COLORS[it.rarity] or WHITE
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.AutoButtonColor = false
        b.Parent = eggList
        corner(b, 6)
        b.MouseButton1Click:Connect(function()
            local pos = getObjectPosition(it.egg)
            if pos then teleportTo(pos + Vector3.new(0, 3, 0)) notify("✅ Teleport ke " .. it.egg.Name, "ok", 1.6) else notify("⚠️ Egg sudah hilang", "warn") end
        end)
    end
    return #items
end
scanBtn.MouseButton1Click:Connect(function()
    local n = refreshEggList()
    notify("ℹ️ Ditemukan " .. n .. " egg (tap egg di daftar = teleport)")
end)

local function clearEggESP()
    for egg, o in pairs(S.espEggs) do
        if o.hl then o.hl:Destroy() end
        if o.bb then o.bb:Destroy() end
        S.espEggs[egg] = nil
    end
end
local espEggToggle = makeToggle(farmPage, "👁️ ESP EGG", 18, function(on)
    S.espEggOn = on
    if not on then clearEggESP() end
end)
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if S.espEggOn then
            local folder = workspace:FindFirstChild("HeistEggs")
            if folder then
                local alive = {}
                for _, egg in ipairs(folder:GetChildren()) do
                    alive[egg] = true
                    local rarity = egg:GetAttribute("Rarity") or "?"
                    local color = RARITY_COLORS[rarity] or WHITE
                    local o = S.espEggs[egg]
                    if not o then
                        o = {}
                        o.hl = Instance.new("Highlight")
                        o.hl.FillTransparency = 0.6
                        o.hl.OutlineTransparency = 0
                        o.hl.Adornee = egg
                        o.hl.Parent = screenGui
                        local part = egg:IsA("BasePart") and egg or egg:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            o.bb = Instance.new("BillboardGui")
                            o.bb.Size = UDim2.new(0, 150, 0, 30)
                            o.bb.AlwaysOnTop = true
                            o.bb.StudsOffset = Vector3.new(0, 3, 0)
                            o.bb.Adornee = part
                            o.bb.Parent = screenGui
                            o.lbl = newLabel(o.bb, "", 12, Enum.Font.GothamBold, WHITE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
                            o.lbl.TextStrokeTransparency = 0.3
                        end
                        S.espEggs[egg] = o
                    end
                    local ok = shouldSteal(egg)
                    o.hl.FillColor = color
                    o.hl.OutlineColor = ok and GREEN or WHITE
                    if o.lbl then
                        o.lbl.TextColor3 = color
                        o.lbl.Text = string.format("%s%s • %s/s", ok and "✅ " or "", rarity, formatNumber(eggIncome(egg)))
                    end
                end
                for egg, o in pairs(S.espEggs) do
                    if not alive[egg] or not egg.Parent then
                        if o.hl then o.hl:Destroy() end
                        if o.bb then o.bb:Destroy() end
                        S.espEggs[egg] = nil
                    end
                end
            end
        end
    end
end)
onCleanup(clearEggESP)

makeHeader(farmPage, "📊 STATISTIK", 19)
local resetStatBtn = makeButton(farmPage, "🗑 RESET STATISTIK", 20)
resetStatBtn.MouseButton1Click:Connect(function()
    S.stolen, S.income, S.t0 = 0, 0, os.clock()
    updateStats()
    notify("🗑 Statistik direset")
end)

-- =====================================================================
--  TAB AKUN  (info akun, tanggal, sesi, game)
-- =====================================================================
local akunPage = pages.AKUN
makeHeader(akunPage, "🪪 INFO AKUN", 0)

local idCard = makeCard(akunPage, 1, 84)
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 68, 0, 68)
avatar.Position = UDim2.new(0, 8, 0, 8)
avatar.BackgroundColor3 = BG_BUTTON
avatar.Image = ""
avatar.Parent = idCard
corner(avatar, 34)
stroke(avatar, ACCENT_BLUE, 2)
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok and url then avatar.Image = url end
end)
local dispLbl = newLabel(idCard, player.DisplayName, 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 84, 0, 8), UDim2.new(1, -92, 0, 20), LEFT)
dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
local userLbl = newLabel(idCard, "@" .. player.Name, 11, Enum.Font.GothamBold, ACCENT_BLUE, UDim2.new(0, 84, 0, 28), UDim2.new(1, -92, 0, 16), LEFT)
userLbl.TextTruncate = Enum.TextTruncate.AtEnd
newLabel(idCard, "🆔 " .. tostring(player.UserId), 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 84, 0, 46), UDim2.new(1, -92, 0, 14), LEFT)
newLabel(idCard, "💎 " .. membership(), 10, Enum.Font.GothamBold, YELLOW, UDim2.new(0, 84, 0, 62), UDim2.new(1, -92, 0, 14), LEFT)

local function infoCard(order, height)
    local card = makeCard(akunPage, order, height)
    local l = newLabel(card, "", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 1, -8), LEFT)
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.TextWrapped = true
    return l
end

makeHeader(akunPage, "📅 DETAIL AKUN", 2)
local detailLbl = infoCard(3, 112)
makeHeader(akunPage, "🗓️ TANGGAL & SESI", 4)
local sessionLbl = infoCard(5, 100)
makeHeader(akunPage, "🎮 INFO GAME & SERVER", 6)
local gameLbl = infoCard(7, 112)

local function refreshAkun()
    local created = accountCreated()
    local team = player.Team and player.Team.Name or "-"
    detailLbl.Text = string.format(
        "📅 Dibuat: %s\n⏳ Umur akun: %d hari (%.1f tahun)\n🌍 Locale: %s\n👥 Team: %s\n🖥️ Device: %s\n🧪 Executor: %s",
        fmtDate(created), player.AccountAge, player.AccountAge / 365, tostring(player.LocaleId), team, deviceName(), executorName())
    sessionLbl.Text = string.format(
        "🗓️ Hari ini: %s\n🕒 Jam: %s\n🚪 Masuk game: %s\n⏱ Durasi sesi: %s\n📅 Zona waktu: UTC%s",
        fmtDate(os.time()), os.date("%H:%M:%S"), os.date("%H:%M:%S", S.joinTime), fmtDur(os.time() - S.joinTime), os.date("%z"))
    gameLbl.Text = string.format(
        "🎮 %s\n🆔 Place ID: %s\n🧩 Job ID: %s\n👥 Player: %d / %d\n📶 Ping: %dms   📊 FPS: %d\n🕹️ Server aktif: %s",
        tostring(gameName), tostring(game.PlaceId), (game.JobId ~= "" and game.JobId or "-"),
        #Players:GetPlayers(), Players.MaxPlayers, S.ping, S.fps, fmtDur(workspace.DistributedGameTime))
end
refreshAkun()
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if mainFrame.Visible and akunPage.Visible then pcall(refreshAkun) end
    end
end)

makeHeader(akunPage, "📋 SALIN", 8)
makeButton(akunPage, "📋 SALIN USERNAME", 9).MouseButton1Click:Connect(function() copyText(player.Name, "Username") end)
makeButton(akunPage, "📋 SALIN DISPLAY NAME", 10).MouseButton1Click:Connect(function() copyText(player.DisplayName, "Display name") end)
makeButton(akunPage, "📋 SALIN USER ID", 11).MouseButton1Click:Connect(function() copyText(player.UserId, "User ID") end)
makeButton(akunPage, "📋 SALIN PLACE ID", 12).MouseButton1Click:Connect(function() copyText(game.PlaceId, "Place ID") end)
makeButton(akunPage, "📋 SALIN SEMUA INFO", 13).MouseButton1Click:Connect(function()
    copyText(string.format(
        "Username: %s\nDisplay: %s\nUserId: %d\nDibuat: %s (%d hari)\nMembership: %s\nTanggal: %s %s\nGame: %s\nPlaceId: %s\nJobId: %s\nExecutor: %s",
        player.Name, player.DisplayName, player.UserId, fmtDate(accountCreated()), player.AccountAge, membership(),
        fmtDate(os.time()), os.date("%H:%M:%S"), tostring(gameName), tostring(game.PlaceId), game.JobId, executorName()), "Semua info")
end)

-- =====================================================================
--  TAB PLAYER
-- =====================================================================
local playerPage = pages.PLAYER
makeHeader(playerPage, "🏃 MOVEMENT", 0)

S.speedOn, S.jumpOn = false, false
numInput(playerPage, 1, "🏃 SPEED", cfg.speed, 1, 500, function(v) cfg.speed = v saveCfg() end)
makeToggle(playerPage, "🏃 SPEED", 2, function(on)
    S.speedOn = on
    if not on then local h = getHum() if h then h.WalkSpeed = 16 end end
end)
numInput(playerPage, 3, "🦘 JUMP POWER", cfg.jump, 1, 500, function(v) cfg.jump = v saveCfg() end)
makeToggle(playerPage, "🦘 JUMP POWER", 4, function(on)
    S.jumpOn = on
    if not on then local h = getHum() if h then h.UseJumpPower = true h.JumpPower = 50 end end
end)
do
    local c = RunService.Heartbeat:Connect(function()
        local h = getHum()
        if not h then return end
        if S.speedOn and h.WalkSpeed ~= cfg.speed then h.WalkSpeed = cfg.speed end
        if S.jumpOn then
            if not h.UseJumpPower then h.UseJumpPower = true end
            if h.JumpPower ~= cfg.jump then h.JumpPower = cfg.jump end
        end
    end)
    onCleanup(function() c:Disconnect() end)
end

-- FLY
numInput(playerPage, 5, "✈️ FLY SPEED", cfg.fly, 1, 500, function(v) cfg.fly = v saveCfg() end)
S.flyUp, S.flyDown = false, false
local flyToggle
local function stopFly()
    S.flyOn = false
    S.flyUp, S.flyDown = false, false
    if S.flyConn then S.flyConn:Disconnect() S.flyConn = nil end
    if S.flyBV then S.flyBV:Destroy() S.flyBV = nil end
    if S.flyBG then S.flyBG:Destroy() S.flyBG = nil end
    local h = getHum()
    if h then
        h.PlatformStand = false
        pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    flyControlFrame.Visible = false
    if flyToggle then flyToggle.set(false, true) end
end
local function startFly()
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum then if flyToggle then flyToggle.set(false, true) end return end
    S.flyOn = true
    flyControlFrame.Visible = true
    S.flyBV = Instance.new("BodyVelocity")
    S.flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    S.flyBV.Velocity = Vector3.zero
    S.flyBV.Parent = hrp
    S.flyBG = Instance.new("BodyGyro")
    S.flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    S.flyBG.P = 9000
    S.flyBG.CFrame = hrp.CFrame
    S.flyBG.Parent = hrp
    hum.PlatformStand = true
    S.flyConn = RunService.RenderStepped:Connect(function()
        local root, h = getHRP(), getHum()
        if not root or not h or not S.flyBV or not S.flyBG then stopFly() return end
        local cam = workspace.CurrentCamera
        local speed = cfg.fly
        local look = cam.CFrame.LookVector
        local dir = h.MoveDirection
        local vel = dir * speed
        if dir.Magnitude > 0 then
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0 then
                vel = vel + Vector3.new(0, look.Y * dir:Dot(flat.Unit) * speed, 0)
            end
        end
        if S.flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, speed, 0) end
        if S.flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, speed, 0) end
        S.flyBV.Velocity = vel
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then S.flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook) end
    end)
end
flyToggle = makeToggle(playerPage, "✈️ FLY", 6, function(on) if on then startFly() else stopFly() end end)
local function bindHold(btn, setter)
    btn.MouseButton1Down:Connect(function() setter(true) end)
    btn.MouseButton1Up:Connect(function() setter(false) end)
    btn.MouseLeave:Connect(function() setter(false) end)
end
bindHold(flyUpBtn, function(v) S.flyUp = v end)
bindHold(flyDownBtn, function(v) S.flyDown = v end)
onCleanup(function() if S.flyOn then stopFly() end end)

-- NOCLIP / INF JUMP
makeToggle(playerPage, "🚫 NOCLIP", 7, function(on)
    S.noclip = on
    if on then
        S.noclipConn = RunService.Stepped:Connect(function()
            local ch = getChar()
            if ch then
                for _, p in ipairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    elseif S.noclipConn then
        S.noclipConn:Disconnect()
        S.noclipConn = nil
    end
end)
onCleanup(function() if S.noclipConn then S.noclipConn:Disconnect() end end)

S.infJump = false
makeToggle(playerPage, "🦘 INF JUMP", 8, function(on) S.infJump = on end)
do
    local c = UserInputService.JumpRequest:Connect(function()
        if S.infJump and not S.flyOn then
            local h = getHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    onCleanup(function() c:Disconnect() end)
end

-- ANTI AFK
makeHeader(playerPage, "🛡️ UTILITAS", 9)
makeToggle(playerPage, "💤 ANTI AFK", 10, function(on)
    S.antiAfk = on
    if on and not S.afkConn then
        S.afkConn = player.Idled:Connect(function()
            if not S.antiAfk then return end
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end)
    end
    notify(on and "✅ Anti AFK aktif" or "ℹ️ Anti AFK mati", on and "ok" or nil)
end, true)
S.antiAfk = true
do
    S.afkConn = player.Idled:Connect(function()
        if not S.antiAfk then return end
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end)
    onCleanup(function() if S.afkConn then S.afkConn:Disconnect() end end)
end

-- ESP PLAYER
local function clearPlayerESP()
    for p, h in pairs(S.espPlayers) do h:Destroy() S.espPlayers[p] = nil end
end
makeToggle(playerPage, "👁️ ESP PLAYER", 11, function(on)
    S.espPlayerOn = on
    if not on then clearPlayerESP() end
end)
task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        if S.espPlayerOn then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character and not (S.espPlayers[p] and S.espPlayers[p].Parent) then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = WHITE
                    h.FillTransparency = 0.7
                    h.Parent = p.Character
                    S.espPlayers[p] = h
                end
            end
        end
    end
end)
onCleanup(clearPlayerESP)

-- FULLBRIGHT
S.lightSaved = nil
makeToggle(playerPage, "🔆 FULLBRIGHT", 12, function(on)
    if on then
        S.lightSaved = { Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient }
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows = 2, 14, 1e5, false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    elseif S.lightSaved then
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows, Lighting.Ambient = unpack(S.lightSaved)
    end
end)

-- FPS BOOST
S.boosted = {}
makeToggle(playerPage, "🚀 FPS BOOST", 13, function(on)
    if on then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") then
                if o.Enabled then
                    o.Enabled = false
                    table.insert(S.boosted, o)
                end
            end
        end
        notify("✅ FPS Boost aktif (" .. #S.boosted .. " efek dimatikan)", "ok")
    else
        for _, o in ipairs(S.boosted) do pcall(function() o.Enabled = true end) end
        S.boosted = {}
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    end
end)

makeButton(playerPage, "💀 RESET CHARACTER", 14).MouseButton1Click:Connect(function()
    local h = getHum()
    if h then h.Health = 0 end
end)

player.CharacterAdded:Connect(function()
    stopFly()
    if S.farmOn then setStatus("Respawn... lanjut farm", YELLOW) end
end)

-- =====================================================================
--  TAB TELEPORT
-- =====================================================================
local tpPage = pages.TELEPORT
makeHeader(tpPage, "📍 TELEPORT SLOTS (5)", 0)
for i = 1, 5 do
    local row = makeCard(tpPage, i, 36)
    local lbl = newLabel(row, "", 10, Enum.Font.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -118, 1, 0), LEFT)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    local function refresh()
        local s = cfg.slots[tostring(i)]
        lbl.Text = s and string.format("📍 %d: %.0f, %.0f, %.0f", i, s[1], s[2], s[3]) or ("📍 Slot " .. i .. ": kosong")
        lbl.TextColor3 = s and WHITE or GREY
    end
    refresh()
    local save = Instance.new("TextButton")
    save.Size = UDim2.new(0, 50, 0, 26)
    save.Position = UDim2.new(1, -108, 0.5, -13)
    save.BackgroundColor3 = BG_BUTTON
    save.Text = "💾 SAVE"
    save.TextSize = 9
    save.Font = Enum.Font.GothamBold
    save.TextColor3 = WHITE
    save.AutoButtonColor = false
    save.Parent = row
    corner(save, 6)
    decorate(save)
    local go = Instance.new("TextButton")
    go.Size = UDim2.new(0, 50, 0, 26)
    go.Position = UDim2.new(1, -54, 0.5, -13)
    go.BackgroundColor3 = BG_BUTTON
    go.Text = "🚀 GO"
    go.TextSize = 9
    go.Font = Enum.Font.GothamBold
    go.TextColor3 = GREEN
    go.AutoButtonColor = false
    go.Parent = row
    corner(go, 6)
    decorate(go)
    save.MouseButton1Click:Connect(function()
        local hrp = getHRP()
        if not hrp then return end
        local p = hrp.Position
        cfg.slots[tostring(i)] = { p.X, p.Y, p.Z }
        refresh()
        saveCfg()
        notify("💾 Slot " .. i .. " disimpan", "ok")
    end)
    go.MouseButton1Click:Connect(function()
        local s = cfg.slots[tostring(i)]
        if s then teleportTo(Vector3.new(s[1], s[2], s[3])) else notify("⚠️ Slot " .. i .. " masih kosong", "warn") end
    end)
end

makeHeader(tpPage, "👥 TELEPORT KE PLAYER", 10)
local plBtn = makeButton(tpPage, "🔄 REFRESH DAFTAR PLAYER", 11)
local plList = Instance.new("ScrollingFrame")
plList.LayoutOrder = 12
plList.Size = UDim2.new(1, 0, 0, 130)
plList.BackgroundColor3 = BG_DARK
plList.BackgroundTransparency = 0.1
plList.BorderSizePixel = 0
plList.ScrollBarThickness = 3
plList.ScrollBarImageColor3 = ACCENT_BLUE
plList.CanvasSize = UDim2.new(0, 0, 0, 0)
plList.AutomaticCanvasSize = Enum.AutomaticSize.Y
plList.Parent = tpPage
plList:SetAttribute("SrchHide", true)
corner(plList, 8)
stroke(plList, Color3.fromRGB(40, 48, 70), 1)
do
    local p = Instance.new("UIPadding")
    p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
    p.Parent = plList
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 3)
    l.SortOrder = Enum.SortOrder.Name
    l.Parent = plList
end
local function refreshPlayers()
    for _, c in ipairs(plList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local b = Instance.new("TextButton")
            b.Name = p.DisplayName:lower()
            b.Size = UDim2.new(1, 0, 0, 24)
            b.BackgroundColor3 = BG_BUTTON
            b.Text = string.format("%s (@%s)", p.DisplayName, p.Name)
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = WHITE
            b.TextTruncate = Enum.TextTruncate.AtEnd
            b.AutoButtonColor = false
            b.Parent = plList
            corner(b, 6)
            b.MouseButton1Click:Connect(function()
                local ch = p.Character
                local r = ch and ch:FindFirstChild("HumanoidRootPart")
                if r then teleportTo(r.Position + Vector3.new(0, 3, 0)) else notify("⚠️ Karakter player belum ada", "warn") end
            end)
        end
    end
end
plBtn.MouseButton1Click:Connect(refreshPlayers)
refreshPlayers()

-- =====================================================================
--  TAB SERVER
-- =====================================================================
local srvPage = pages.SERVER
makeHeader(srvPage, "🖥️ SERVER TOOLS", 0)
makeButton(srvPage, "🔁 REJOIN SERVER INI", 1).MouseButton1Click:Connect(function()
    notify("⏳ Rejoin...")
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            player:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, player)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end
    end)
end)

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" then return res end
    local req = (syn and syn.request) or http_request or request
    if req then
        local ok2, r = pcall(req, { Url = url, Method = "GET" })
        if ok2 and r and r.Body then return r.Body end
    end
    return nil
end

makeButton(srvPage, "🚀 SERVER HOP (server sepi)", 2).MouseButton1Click:Connect(function()
    notify("⏳ Mencari server...")
    task.spawn(function()
        local body = httpGet(string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId))
        local target
        if body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and data and data.data then
                for _, sv in ipairs(data.data) do
                    if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then
                        target = sv.id
                        break
                    end
                end
            end
        end
        if target then
            notify("✅ Pindah server...", "ok")
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target, player) end)
        else
            notify("⚠️ Server lain tidak ditemukan / HttpGet tidak didukung", "warn", 3.5)
        end
    end)
end)

local jobBox
do
    local _, b = makeInput(srvPage, 3, "🧩 JOIN LEWAT JOB ID", "", function() end)
    jobBox = b
    jobBox.PlaceholderText = "tempel Job ID di sini"
    jobBox.PlaceholderColor3 = GREY
end
makeButton(srvPage, "➡️ JOIN JOB ID", 4).MouseButton1Click:Connect(function()
    local id = (jobBox.Text or ""):gsub("%s+", "")
    if id == "" then notify("⚠️ Isi Job ID dulu", "warn") return end
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player) end)
end)
makeButton(srvPage, "📋 SALIN JOB ID", 5).MouseButton1Click:Connect(function() copyText(game.JobId, "Job ID") end)
makeButton(srvPage, "📋 SALIN LINK JOIN SERVER", 6).MouseButton1Click:Connect(function()
    copyText(string.format("roblox://experiences/start?placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId), "Link join")
end)

-- =====================================================================
--  TAB SETTING
-- =====================================================================
local setPage = pages.SETTING
makeHeader(setPage, "🖥️ TAMPILAN", 0)
makeSlider(setPage, 1, "📐 UKURAN UI", 0.55, 1.4, 0.05, cfg.scale, function(v)
    cfg.scale = v
    uiScale.Scale = v
end, function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
makeSlider(setPage, 2, "🖼️ TRANSPARANSI BACKGROUND", 0, 1, 0.05, cfg.trans or 0.35, function(v)
    cfg.trans = v
    bgImage.ImageTransparency = v
end, function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)

makeHeader(setPage, "⚙️ SETTING", 3)
makeToggle(setPage, "🔔 NOTIFIKASI", 4, function(on) cfg.notif = on saveCfg() end, cfg.notif ~= false)
local keyToggle = makeToggle(setPage, "⌨️ TOMBOL RIGHTSHIFT (PC)", 5, function() end, true)
do
    local c = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift and keyToggle.get() then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    onCleanup(function() c:Disconnect() end)
end

makeHeader(setPage, "💾 CONFIG", 6)
makeButton(setPage, "💾 SIMPAN CONFIG SEKARANG", 7).MouseButton1Click:Connect(function()
    saveToken = saveToken + 1
    local ok = pcall(function()
        if not writefile then error("no writefile") end
        writefile(CFG_FILE, HttpService:JSONEncode(cfg))
    end)
    notify(ok and "💾 Config tersimpan" or "⚠️ Executor tidak support writefile", ok and "ok" or "warn")
end)
makeButton(setPage, "🗑 RESET CONFIG (default)", 8).MouseButton1Click:Connect(function()
    pcall(function() if delfile and isfile and isfile(CFG_FILE) then delfile(CFG_FILE) end end)
    notify("🗑 Config dihapus — jalankan ulang script", "warn", 3.5)
end)

makeHeader(setPage, "ℹ️ TENTANG HUB", 9)
do
    local about = newLabel(setPage, "AUTO FARM HUB v1\nUI ala UNIVERSAL HUB. Auto farm HeistEggs (TP → steal → safe spot), scanner & ESP egg, info akun lengkap, slot teleport, server hop, config tersimpan otomatis.",
        9, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 64), LEFT)
    about.LayoutOrder = 10
    about.TextWrapped = true
    about:SetAttribute("SrchHide", true)
end

-- ==================== TRANSISI ANTAR TAB ====================
for _, pg in pairs(pages) do
    local base = pg.Position
    pg:GetPropertyChangedSignal("Visible"):Connect(function()
        if pg.Visible then
            pg.Position = base + UDim2.new(0, 0, 0, 10)
            tw(pg, 0.18, { Position = base })
        end
    end)
end

-- ==================== START ====================
selectTab("FARM")
setStatus("Idle", GREY)
print("✅ AUTO FARM HUB loaded!  User: " .. player.Name .. " (" .. player.DisplayName .. ")")

end, function(e)
    return tostring(e) .. "\n" .. tostring(debug.traceback())
end)

if not __ok then
    warn("AUTO FARM HUB error: " .. tostring(__err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "AUTO FARM HUB", Text = "Error: " .. tostring(__err):sub(1, 150), Duration = 8 })
    end)
else
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "AUTO FARM HUB", Text = "Siap dipakai ✨", Duration = 3 })
    end)
end

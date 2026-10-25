-- =====================================================================
--  THE RICH 🤑 v3  —  (dulu AUTO FARM HUB v2)  UI & detail ala UNIVERSAL HUB v28
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
local INFO_BG = Color3.fromRGB(12, 15, 25)
local LINE = Color3.fromRGB(40, 48, 70)
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
    theme = "default", panel = 0.12, anim = true,
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
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
for _, n in ipairs({ "AutoFarmHubGui", "TheRichGui" }) do
    local oldGui = PlayerGui:FindFirstChild(n)
    if oldGui then oldGui:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TheRichGui"
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
        f.BackgroundColor3 = INFO_BG
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

        local titleLbl = newLabel(f, "THE RICH 🤑", 8, Enum.Font.GothamBlack, color, UDim2.new(0, 42, 0, 5), UDim2.new(1, -52, 0, 10), LEFT)
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
        track.BackgroundColor3 = LINE
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
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0, 62)
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
    local def = math.clamp((vp.Y - 76) / 405, 0.5, 1)
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
do
    local ln = Instance.new("Frame")
    ln.Size = UDim2.new(1, -24, 0, 1)
    ln.Position = UDim2.new(0, 12, 1, -1)
    ln.BackgroundColor3 = ACCENT_BLUE
    ln.BackgroundTransparency = 0.45
    ln.BorderSizePixel = 0
    ln.Parent = topBar
end

local globeIcon = newLabel(topBar, "🌐", 18, Enum.Font.GothamBold, WHITE, UDim2.new(0, 10, 0, 10), UDim2.new(0, 22, 0, 22))
local titleLabel = newLabel(topBar, "THE RICH 🤑", 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 36, 0, 8), UDim2.new(1, -110, 0, 20), LEFT)
newLabel(topBar, "💲 Heist Egg & Pet Hub", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 28), UDim2.new(1, -110, 0, 12), LEFT)

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
logoBtn.Text = "💲"
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
infoBar.BackgroundColor3 = INFO_BG
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
infoPanel.BackgroundColor3 = INFO_BG
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
        "👤 %s (@%s)\n🆔 UserId: %d\n📅 Akun dibuat: %s (%d hari)\n📅 Hari ini: %s\n🎮 %s\n🧩 Job: %s\n👥 Player: %d / %d   ⏱ Main: %s",
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
    stroke(btn, LINE, 1)
    tabButtons[name] = btn
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
end

makeTabButton("FARM", "🌾", "FARM")
makeTabButton("AKUN", "👤", "AKUN")
makeTabButton("PLAYER", "🏃", "PLAYER")
makeTabButton("TELEPORT", "📍", "TELEPORT")
makeTabButton("SERVER", "🖥️", "SERVER")
makeTabButton("TEMA", "🎨", "TEMA")
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
    statsLbl.Text = string.format("💲 %d  |  💰 %s  |  ⏱ %s", S.stolen, formatNumber(S.income), fmtDur(os.clock() - S.t0))
    if S.tSteal then
        S.tSteal.Text = tostring(S.stolen)
        S.tIncome.Text = formatNumber(S.income)
        S.tTime.Text = fmtDur(os.clock() - S.t0)
    end
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
    stroke(f, LINE, 1)
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
    stroke(btn, LINE, 1)
    decorate(btn)
    if not noNotify then
        btn.MouseButton1Click:Connect(function() notify("ℹ️ " .. btn.Text, nil, 1.6) end)
    end
    return btn
end

-- tombol toggle: label + " • ON/OFF"
local function makeToggle(parent, label, order, onChange, initial)
    local btn = makeButton(parent, label .. " • OFF", order, true)
    local btnStroke = btn:FindFirstChildOfClass("UIStroke")
    local state = false
    local api = {}
    function api.set(v, silent)
        state = v and true or false
        btn.Text = label .. (state and " • ON" or " • OFF")
        btn.BackgroundColor3 = state and ON_COLOR or BG_BUTTON
        if btnStroke then btnStroke.Color = state and GREEN or LINE end
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
    local st = stroke(box, LINE, 1)
    box.Focused:Connect(function() tw(st, 0.15, { Color = ACCENT_BLUE }) end)
    box.FocusLost:Connect(function()
        tw(st, 0.15, { Color = LINE })
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
    track:SetAttribute("NoPanel", true)
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
makeHeader(farmPage, "🤑 THE RICH • FARM", 0)
do
    local card = makeCard(farmPage, -1, 56)
    local function tile(i, caption, color)
        local w = 1 / 3
        local v = newLabel(card, "0", 15, Enum.Font.GothamBlack, color, UDim2.new(w * (i - 1), 0, 0, 7), UDim2.new(w, 0, 0, 24))
        newLabel(card, caption, 9, Enum.Font.GothamBold, GREY, UDim2.new(w * (i - 1), 0, 0, 32), UDim2.new(w, 0, 0, 14))
        if i > 1 then
            local d = Instance.new("Frame")
            d.Position = UDim2.new(w * (i - 1), 0, 0, 10)
            d.Size = UDim2.new(0, 1, 1, -20)
            d.BackgroundColor3 = LINE
            d.BorderSizePixel = 0
            d.Parent = card
        end
        return v
    end
    S.tSteal = tile(1, "💲 STEAL", GREEN)
    S.tIncome = tile(2, "💰 INCOME", YELLOW)
    S.tTime = tile(3, "⏱ WAKTU", WHITE)
    updateStats()
end

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

-- Steal 1 egg: TP ke egg -> fire prompt -> balik ke safe spot.
-- Dipakai oleh THE RICH FARM, tombol STEAL SEMUA, dan tap egg di daftar.
local function stealEgg(egg, quiet)
    if S.busy then
        if not quiet then notify("⏳ Masih ada proses steal...", "warn", 1.5) end
        return false, "busy"
    end
    local pos, prompt = getObjectPosition(egg), getPrompt(egg)
    if not (egg.Parent and pos and prompt) then
        if not quiet then notify("⚠️ Egg sudah hilang / tidak ada prompt", "warn") end
        return false, "gone"
    end
    if not getHRP() then
        if not quiet then notify("⚠️ Karakter belum siap", "warn") end
        return false, "nochar"
    end
    S.busy = true
    local name = egg.Name
    local inc = eggIncome(egg)
    S.recent[egg] = os.clock()
    setStatus("Menuju " .. name, ACCENT_BLUE)
    teleportTo(pos + Vector3.new(0, 3, 0))
    task.wait(cfg.dTP)
    setStatus("Mencuri " .. name, GREEN)
    local fired = pcall(function()
        if not fireproximityprompt then error("no fpp") end
        fireproximityprompt(prompt)
    end)
    if not fired then
        S.busy = false
        notify("⚠️ Executor tidak support fireproximityprompt", "warn", 4)
        return false, "nofpp"
    end
    task.wait(cfg.dSteal)
    if cfg.backSafe then teleportTo(Vector3.new(cfg.safe[1], cfg.safe[2], cfg.safe[3])) end
    S.stolen = S.stolen + 1
    S.income = S.income + inc
    updateStats()
    task.wait(cfg.dBack)
    S.busy = false
    setStatus(S.farmOn and "Berjalan" or "Idle", S.farmOn and GREEN or GREY)
    if not quiet then notify("✅ Berhasil steal " .. name .. " (+" .. formatNumber(inc) .. "/s)", "ok") end
    return true
end

local function startFarm()
    if S.farmRunning then return end
    S.farmRunning = true
    task.spawn(function()
        while S.farmOn do
            while S.busy and S.farmOn do task.wait(0.1) end
            local targets, hasFolder = collectTargets()
            if not hasFolder then
                setStatus("Folder HeistEggs tidak ditemukan", YELLOW)
            elseif #targets == 0 then
                setStatus("Menunggu target...", GREY)
            else
                for _, t in ipairs(targets) do
                    if not S.farmOn then break end
                    local _, why = stealEgg(t.egg, true)
                    if why == "nofpp" then
                        S.farmOn = false
                        if farmToggle then farmToggle.set(false, true) end
                        break
                    end
                end
            end
            task.wait(0.5)
        end
        S.farmRunning = false
        setStatus("Idle", GREY)
    end)
end

farmToggle = makeToggle(farmPage, "🤑 THE RICH FARM", 1, function(on)
    S.farmOn = on
    if on then
        if next(cfg.rarities) == nil or not (function() for _, v in pairs(cfg.rarities) do if v then return true end end return false end)() then
            notify("⚠️ Pilih minimal 1 rarity dulu", "warn")
        end
        setStatus("Berjalan", GREEN)
        notify("🤑 The Rich dinyalakan", "ok")
        startFarm()
    else
        setStatus("Idle", GREY)
        notify("ℹ️ The Rich dimatikan")
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
        tw(c.st, 0.18, { Color = LINE })
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
stroke(chipScroll, LINE, 1)
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
    btn:SetAttribute("Panel", true)
    local st = stroke(btn, LINE, 1)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 8, 0.5, -4)
    dot.BackgroundColor3 = color
    dot.BorderSizePixel = 0
    dot.Parent = btn
    corner(dot, 4)
    dot:SetAttribute("NoTheme", true)
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

do
local function isEgg(obj)
    return tostring(obj.Name):lower():find("egg", 1, true) ~= nil
end
S.isEgg = isEgg

local function distTo(pos)
    local hrp = getHRP()
    if not hrp or not pos then return nil end
    return (hrp.Position - pos).Magnitude
end

local function tpToObj(obj)
    local pos = getObjectPosition(obj)
    if not (obj.Parent and pos) then notify("⚠️ Target sudah hilang", "warn") return end
    if not getHRP() then notify("⚠️ Karakter belum siap", "warn") return end
    teleportTo(pos + Vector3.new(0, 3, 0))
    notify("📍 Teleport ke " .. obj.Name, "ok", 1.6)
end
S.tpToObj = tpToObj

-- cari egg/pet terdekat atau terbaik (income tertinggi)
S.pickTarget = function(wantEgg, mode)
    local folder = workspace:FindFirstChild("HeistEggs")
    if not folder then return nil end
    local best, bestV
    for _, obj in ipairs(folder:GetChildren()) do
        if isEgg(obj) == wantEgg then
            local pos = getObjectPosition(obj)
            if pos then
                local v
                if mode == "near" then v = -(distTo(pos) or 1e9) else v = eggIncome(obj) end
                if not bestV or v > bestV then best, bestV = obj, v end
            end
        end
    end
    return best
end

makeHeader(farmPage, "💲 SCANNER & STEAL MANUAL", 15)
S.liveList = true
makeToggle(farmPage, "🔄 LIVE LIST", 16, function(on) S.liveList = on end, true)
local refreshAllBtn = makeButton(farmPage, "🔄 REFRESH EGG + PET", 17, true)
S.stealAllBtn = makeButton(farmPage, "⚡ STEAL SEMUA (sesuai filter)", 18)
do
    local hint = newLabel(farmPage, "👆 Tap baris = steal  •  📍 TP = teleport saja (tanpa steal)", 9, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 14))
    hint.LayoutOrder = 19
    hint:SetAttribute("SrchHide", true)
end

S.lists = {}
local function makeList(kind, label, icon, base)
    local L = { rows = {}, known = nil }
    local wantEgg = (kind == "egg")
    local hdr = makeHeader(farmPage, icon .. " " .. label .. " (0)", base)
    local hdrLbl = hdr:FindFirstChildWhichIsA("TextLabel")
    local rbtn = makeButton(farmPage, "🔄 REFRESH " .. label, base + 1, true)

    local list = Instance.new("ScrollingFrame")
    list.LayoutOrder = base + 2
    list.Size = UDim2.new(1, 0, 0, 150)
    list.BackgroundColor3 = BG_DARK
    list.BackgroundTransparency = 0.1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = ACCENT_BLUE
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = farmPage
    list:SetAttribute("SrchHide", true)
    corner(list, 8)
    stroke(list, LINE, 1)
    do
        local p = Instance.new("UIPadding")
        p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4)
        p.Parent = list
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = list
    end
    local empty = newLabel(list, "Memuat...", 10, Enum.Font.GothamBold, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 28))
    empty.LayoutOrder = -1

    local function makeRow(obj)
        local R = {}
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = BG_BUTTON
        row.BackgroundTransparency = cfg.panel or 0.12
        row.Text = ""
        row.AutoButtonColor = false
        row.Parent = list
        corner(row, 8)
        stroke(row, LINE, 1)
        decorate(row)
        R.row = row
        R.bar = Instance.new("Frame")
        R.bar.Position = UDim2.new(0, 5, 0.5, -14)
        R.bar.Size = UDim2.new(0, 4, 0, 28)
        R.bar.BorderSizePixel = 0
        R.bar:SetAttribute("NoTheme", true)
        R.bar:SetAttribute("NoPanel", true)
        R.bar.Parent = row
        corner(R.bar, 2)
        R.name = newLabel(row, "", 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 16, 0, 4), UDim2.new(1, -134, 0, 16), LEFT)
        R.name.TextTruncate = Enum.TextTruncate.AtEnd
        R.sub = newLabel(row, "", 9, Enum.Font.GothamBold, GREY, UDim2.new(0, 16, 0, 21), UDim2.new(1, -134, 0, 14), LEFT)
        R.sub.TextTruncate = Enum.TextTruncate.AtEnd

        local tp = Instance.new("TextButton")
        tp.Position = UDim2.new(1, -118, 0.5, -11)
        tp.Size = UDim2.new(0, 44, 0, 22)
        tp.BackgroundColor3 = BG_DARK
        tp.Text = "📍 TP"
        tp.TextSize = 9
        tp.Font = Enum.Font.GothamBlack
        tp.TextColor3 = YELLOW
        tp.AutoButtonColor = false
        tp.Parent = row
        tp:SetAttribute("NoPanel", true)
        corner(tp, 11)
        stroke(tp, YELLOW, 1)
        tp.MouseButton1Click:Connect(function() tpToObj(obj) end)

        local pill = Instance.new("TextLabel")
        pill.Position = UDim2.new(1, -68, 0.5, -11)
        pill.Size = UDim2.new(0, 62, 0, 22)
        pill.BackgroundColor3 = wantEgg and GREEN or ACCENT_BLUE
        pill.Text = wantEgg and "💲 STEAL" or "⚡ STEAL"
        pill.TextSize = 9
        pill.Font = Enum.Font.GothamBlack
        pill.TextColor3 = WHITE
        pill.Parent = row
        pill:SetAttribute("NoPanel", true)
        pill:SetAttribute("NoTheme", true)
        corner(pill, 11)

        row.MouseButton1Click:Connect(function() task.spawn(stealEgg, obj) end)
        return R
    end

    function L.refresh(force)
        local folder = workspace:FindFirstChild("HeistEggs")
        if force then
            for obj, R in pairs(L.rows) do R.row:Destroy() L.rows[obj] = nil end
        end
        local items, seen = {}, {}
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if isEgg(obj) == wantEgg then
                    table.insert(items, { obj = obj, rarity = obj:GetAttribute("Rarity") or "?", income = eggIncome(obj) })
                end
            end
        end
        table.sort(items, function(a, b)
            if a.income ~= b.income then return a.income > b.income end
            return a.obj.Name < b.obj.Name
        end)
        local firstScan = (L.known == nil)
        L.known = L.known or {}
        for i, it in ipairs(items) do
            local R = L.rows[it.obj]
            if not R then
                R = makeRow(it.obj)
                L.rows[it.obj] = R
            end
            seen[it.obj] = true
            R.row.LayoutOrder = i
            local col = RARITY_COLORS[it.rarity] or (wantEgg and GREEN or WHITE)
            R.bar.BackgroundColor3 = col
            local nm = it.obj.Name:gsub("_", " ")
            R.name.Text = (shouldSteal(it.obj) and "✅ " or "") .. (wantEgg and "💲 " or "🐾 ") .. nm
            local parts = {}
            if it.rarity ~= "?" then table.insert(parts, it.rarity) end
            if it.income > 0 then table.insert(parts, formatNumber(it.income) .. "/s") end
            local d = distTo(getObjectPosition(it.obj))
            if d then table.insert(parts, "📏 " .. math.floor(d) .. "m") end
            R.sub.Text = #parts > 0 and table.concat(parts, "  •  ") or "-"
            R.sub.TextColor3 = col
            if not L.known[it.obj] then
                L.known[it.obj] = true
                if not firstScan and S.notifNew and not wantEgg and shouldSteal(it.obj) then
                    notify("🐾 Pet baru: " .. nm .. " (" .. it.rarity .. ")", "ok", 3)
                end
            end
        end
        for obj, R in pairs(L.rows) do
            if not seen[obj] then
                R.row:Destroy()
                L.rows[obj] = nil
                L.known[obj] = nil
            end
        end
        empty.Visible = #items == 0
        empty.Text = folder and ("Belum ada " .. label:lower() .. " di map") or "Folder HeistEggs tidak ditemukan"
        if hdrLbl then hdrLbl.Text = icon .. " " .. label .. " (" .. #items .. ")" end
        return #items
    end

    rbtn.MouseButton1Click:Connect(function()
        local n = L.refresh(true)
        notify("🔄 " .. label .. " di-refresh • " .. n .. " ditemukan", "ok", 1.8)
    end)
    S.lists[kind] = L
    L.refresh()
    return L
end

makeList("egg", "EGG", "💲", 20)
makeList("pet", "PET", "🐾", 23)

refreshAllBtn.MouseButton1Click:Connect(function()
    local a = S.lists.egg.refresh(true)
    local b = S.lists.pet.refresh(true)
    notify("🔄 Refresh selesai • " .. a .. " egg, " .. b .. " pet", "ok", 1.8)
end)

task.spawn(function()
    while screenGui.Parent do
        task.wait(2)
        if S.liveList and mainFrame.Visible and farmPage.Visible then
            pcall(S.lists.egg.refresh)
            pcall(S.lists.pet.refresh)
        end
    end
end)
end

S.stealAllBtn.MouseButton1Click:Connect(function()
    if S.busy then notify("⏳ Masih ada proses steal...", "warn", 1.5) return end
    task.spawn(function()
        local targets, hasFolder = collectTargets()
        if not hasFolder then notify("⚠️ Folder HeistEggs tidak ditemukan", "warn") return end
        if #targets == 0 then notify("⚠️ Tidak ada egg yang cocok dengan filter", "warn") return end
        notify("⏳ Steal " .. #targets .. " egg...")
        local n = 0
        for _, t in ipairs(targets) do
            local ok, why = stealEgg(t.egg, true)
            if ok then n = n + 1 end
            if why == "nofpp" then break end
        end
        notify("✅ Selesai: " .. n .. "/" .. #targets .. " egg berhasil", n > 0 and "ok" or "warn")
    end)
end)

do
local espMap = { egg = {}, pet = {} }
local function clearESP(kind)
    for obj, o in pairs(espMap[kind]) do
        if o.hl then o.hl:Destroy() end
        if o.bb then o.bb:Destroy() end
        espMap[kind][obj] = nil
    end
end
local function makeESPToggle(kind, label, order)
    makeToggle(farmPage, label, order, function(on)
        S["esp_" .. kind] = on
        if not on then clearESP(kind) end
    end)
end
makeHeader(farmPage, "👁️ ESP & NOTIFIKASI", 29)
makeESPToggle("egg", "👁️ ESP EGG 💲", 30)
makeESPToggle("pet", "👁️ ESP PET 🐾", 31)
makeToggle(farmPage, "🔔 NOTIF PET BARU", 32, function(on) S.notifNew = on end)

task.spawn(function()
    while screenGui.Parent do
        task.wait(1)
        local folder = workspace:FindFirstChild("HeistEggs")
        for _, kind in ipairs({ "egg", "pet" }) do
            if S["esp_" .. kind] and folder then
                local alive = {}
                for _, obj in ipairs(folder:GetChildren()) do
                    if S.isEgg(obj) == (kind == "egg") then
                        alive[obj] = true
                        local rarity = obj:GetAttribute("Rarity") or "?"
                        local color = RARITY_COLORS[rarity] or (kind == "egg" and GREEN or WHITE)
                        local o = espMap[kind][obj]
                        if not o then
                            o = {}
                            o.hl = Instance.new("Highlight")
                            o.hl.FillTransparency = 0.6
                            o.hl.OutlineTransparency = 0
                            o.hl.Adornee = obj
                            o.hl.Parent = screenGui
                            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                            if part then
                                o.bb = Instance.new("BillboardGui")
                                o.bb.Size = UDim2.new(0, 170, 0, 34)
                                o.bb.AlwaysOnTop = true
                                o.bb.StudsOffset = Vector3.new(0, 3, 0)
                                o.bb.Adornee = part
                                o.bb.Parent = screenGui
                                o.lbl = newLabel(o.bb, "", 12, Enum.Font.GothamBold, WHITE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
                                o.lbl.TextStrokeTransparency = 0.3
                                o.lbl.TextWrapped = true
                            end
                            espMap[kind][obj] = o
                        end
                        local ok = shouldSteal(obj)
                        o.hl.FillColor = color
                        o.hl.OutlineColor = ok and GREEN or WHITE
                        if o.lbl then
                            o.lbl.TextColor3 = color
                                                        local pos = getObjectPosition(obj)
                            local hrp = getHRP()
                            local dist = (pos and hrp) and math.floor((hrp.Position - pos).Magnitude) or 0
                            o.lbl.Text = string.format("%s%s %s\n%s • %s/s • %dm", ok and "✅ " or "", kind == "egg" and "💲" or "🐾",
                                (obj.Name:gsub("_", " ")), rarity, formatNumber(eggIncome(obj)), dist)
                        end
                    end
                end
                for obj, o in pairs(espMap[kind]) do
                    if not alive[obj] or not obj.Parent then
                        if o.hl then o.hl:Destroy() end
                        if o.bb then o.bb:Destroy() end
                        espMap[kind][obj] = nil
                    end
                end
            end
        end
    end
end)
onCleanup(function() clearESP("egg") clearESP("pet") end)
end

-- ==================== AUTO UPGRADE & EQUIP ====================
do
    local RS = game:GetService("ReplicatedStorage")
    local function getRemote(name)
        local r = RS:FindFirstChild("Remotes")
        return r and r:FindFirstChild(name)
    end
    makeHeader(farmPage, "🛠️ AUTO UPGRADE & EQUIP", 33)
    local function autoRemote(label, order, remoteName, args)
        local token = 0
        makeToggle(farmPage, label, order, function(on)
            token = token + 1
            local my = token
            if not on then return end
            task.spawn(function()
                while token == my and screenGui.Parent do
                    local r = getRemote(remoteName)
                    if r then pcall(function() r:FireServer(unpack(args)) end) end
                    task.wait(math.max(0.1, tonumber(cfg.dUpg) or 1))
                end
            end)
        end)
    end
    autoRemote("🌱 UPGRADE PLOT", 34, "BuyPenUpgrade", {})
    autoRemote("🏃 UPGRADE TREADMILL", 35, "BuyTreadmillUpgrade", {})
    autoRemote("🐾 UPGRADE PLOT PET", 36, "BuyPenUpgrade", { "Window" })
    autoRemote("⭐ EQUIP BEST", 37, "PetEquipBest", {})
    numInput(farmPage, 38, "⏱ DELAY AUTO UPGRADE (detik)", cfg.dUpg or 1, 0.1, 30, function(v) cfg.dUpg = v saveCfg() end)
end

makeHeader(farmPage, "📊 STATISTIK", 40)
local resetStatBtn = makeButton(farmPage, "🗑 RESET STATISTIK", 41)
resetStatBtn.MouseButton1Click:Connect(function()
    S.stolen, S.income, S.t0 = 0, 0, os.clock()
    updateStats()
    notify("🗑 Statistik direset")
end)

-- =====================================================================
--  TAB AKUN  (info akun, tanggal, sesi, game)
-- =====================================================================
do
local akunPage = pages.AKUN
makeHeader(akunPage, "👤 INFO AKUN", 0)

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
makeHeader(akunPage, "📅 TANGGAL & SESI", 4)
local sessionLbl = infoCard(5, 100)
makeHeader(akunPage, "🎮 INFO GAME & SERVER", 6)
local gameLbl = infoCard(7, 112)

local function refreshAkun()
    local created = accountCreated()
    local team = player.Team and player.Team.Name or "-"
    detailLbl.Text = string.format(
        "📅 Dibuat: %s\n⏳ Umur akun: %d hari (%.1f tahun)\n🌍 Locale: %s\n👥 Team: %s\n🖥️ Device: %s\n🔧 Executor: %s",
        fmtDate(created), player.AccountAge, player.AccountAge / 365, tostring(player.LocaleId), team, deviceName(), executorName())
    sessionLbl.Text = string.format(
        "📅 Hari ini: %s\n🕒 Jam: %s\n🚪 Masuk game: %s\n⏱ Durasi sesi: %s\n📅 Zona waktu: UTC%s",
        fmtDate(os.time()), os.date("%H:%M:%S"), os.date("%H:%M:%S", S.joinTime), fmtDur(os.time() - S.joinTime), os.date("%z"))
    gameLbl.Text = string.format(
        "🎮 %s\n🆔 Place ID: %s\n🧩 Job ID: %s\n👥 Player: %d / %d\n📶 Ping: %dms   📊 FPS: %d\n⏳ Server aktif: %s",
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

end

-- =====================================================================
--  TAB PLAYER
-- =====================================================================
do
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
makeHeader(playerPage, "🔒 UTILITAS", 9)
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

end

-- =====================================================================
--  TAB TELEPORT
-- =====================================================================
do
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
stroke(plList, LINE, 1)
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

-- ==================== MAP TOOLS ====================
do
    makeHeader(tpPage, "🗺️ MAP TOOLS", 50)
    local function goBest(wantEgg, mode)
        local obj = S.pickTarget(wantEgg, mode)
        if not obj then notify("⚠️ " .. (wantEgg and "Egg" or "Pet") .. " tidak ditemukan di map", "warn") return end
        S.tpToObj(obj)
    end
    makeButton(tpPage, "💲 TP EGG TERDEKAT", 51, true).MouseButton1Click:Connect(function() goBest(true, "near") end)
    makeButton(tpPage, "💲 TP EGG INCOME TERTINGGI", 52, true).MouseButton1Click:Connect(function() goBest(true, "best") end)
    makeButton(tpPage, "🐾 TP PET TERDEKAT", 53, true).MouseButton1Click:Connect(function() goBest(false, "near") end)
    makeButton(tpPage, "🐾 TP PET INCOME TERTINGGI", 54, true).MouseButton1Click:Connect(function() goBest(false, "best") end)
    makeButton(tpPage, "🏠 TP KE SAFE SPOT", 55, true).MouseButton1Click:Connect(function()
        teleportTo(Vector3.new(cfg.safe[1], cfg.safe[2], cfg.safe[3]))
        notify("🏠 Kembali ke Safe Spot", "ok", 1.6)
    end)
    makeButton(tpPage, "🧭 TP KE SPAWN", 56, true).MouseButton1Click:Connect(function()
        local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if sp then teleportTo(sp.Position + Vector3.new(0, 4, 0)) notify("🧭 Teleport ke spawn", "ok", 1.6)
        else notify("⚠️ SpawnLocation tidak ditemukan", "warn") end
    end)
    makeButton(tpPage, "📋 SALIN KOORDINAT POSISI", 57, true).MouseButton1Click:Connect(function()
        local hrp = getHRP()
        if not hrp then notify("⚠️ Karakter belum siap", "warn") return end
        local p = hrp.Position
        local txt = string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z)
        if clipFn then pcall(clipFn, txt) notify("📋 " .. txt, "ok", 2.5) else notify("📍 " .. txt, nil, 4) end
    end)
end

end

-- =====================================================================
--  TAB SERVER
-- =====================================================================
do
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

end

-- =====================================================================
--  TAB SETTING
-- =====================================================================
do
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
    local about = newLabel(setPage, "THE RICH 🤑 v3\nUI ala UNIVERSAL HUB. Auto farm HeistEggs (TP → steal → safe spot), daftar EGG & PET terpisah (TP / steal / refresh), ESP egg & pet, tool map, info akun lengkap, slot teleport, server hop, config tersimpan otomatis.",
        9, Enum.Font.Gotham, GREY, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 64), LEFT)
    about.LayoutOrder = 10
    about.TextWrapped = true
    about:SetAttribute("SrchHide", true)
end

end

-- =====================================================================
--  TAB TEMA  (14 tema + efek animasi, ganti warna semua UI)
-- =====================================================================
local function initTheme()
    local rgb = Color3.fromRGB
    local page = pages.TEMA
    local ROLES = { "black", "dark", "btn", "border", "accent", "on", "grey", "info", "line" }

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
    -- a = 8 warna: black, dark, btn, border, accent, on, grey, info. "line" dihitung otomatis.
    local function P(a, line)
        local arr = {}
        for i = 1, 8 do arr[i] = a[i] end
        if line then
            arr[9] = line
        else
            local b, ac = a[3], a[5]
            arr[9] = { math.floor(b[1] * 0.72 + ac[1] * 0.28), math.floor(b[2] * 0.72 + ac[2] * 0.28), math.floor(b[3] * 0.72 + ac[3] * 0.28) }
        end
        return mkPal(arr)
    end

    local THEMES = {
        { id = "default", name = "Bawaan (Foto)", icon = "🖼️", fx = "none",
            sw = { rgb(10, 10, 15), rgb(60, 120, 255), rgb(125, 100, 215) },
            pal = P({ {10,10,15}, {18,22,35}, {25,32,50}, {60,120,255}, {70,130,255}, {40,80,40}, {150,160,180}, {12,15,25} }, { 40, 48, 70 }) },
        { id = "mono", name = "Monokrom", icon = "⚪", fx = "sheen",
            sw = { rgb(14, 14, 16), rgb(120, 122, 134), rgb(232, 234, 240) },
            pal = P({ {12,12,14}, {30,31,35}, {52,53,59}, {206,209,217}, {118,121,132}, {96,102,110}, {172,175,184}, {20,20,23} }) },
        { id = "forest", name = "Hutan", icon = "🌲", fx = "leaves",
            sw = { rgb(4, 20, 11), rgb(44, 138, 74), rgb(150, 230, 150) },
            pal = P({ {6,24,13}, {12,42,24}, {20,64,38}, {92,208,120}, {44,138,74}, {30,104,52}, {156,204,170}, {8,30,17} }) },
        { id = "hacker", name = "Hacker", icon = "💻", fx = "matrix",
            sw = { rgb(0, 6, 2), rgb(0, 150, 62), rgb(0, 255, 90) },
            pal = P({ {2,9,4}, {4,20,9}, {7,34,14}, {0,255,90}, {0,150,62}, {0,106,44}, {96,204,128}, {3,14,7} }) },
        { id = "ocean", name = "Lautan", icon = "🌊", fx = "bubbles",
            sw = { rgb(96, 184, 240), rgb(24, 102, 184), rgb(3, 26, 66) },
            pal = P({ {5,26,56}, {9,46,90}, {15,72,128}, {120,206,255}, {30,122,204}, {20,128,150}, {176,214,238}, {6,32,68} }) },
        { id = "sunset", name = "Sunset", icon = "🌇", fx = "embers",
            sw = { rgb(70, 30, 120), rgb(238, 108, 82), rgb(255, 172, 84) },
            pal = P({ {34,12,42}, {56,20,58}, {90,36,82}, {255,156,76}, {222,96,64}, {150,58,112}, {232,192,196}, {38,14,46} }) },
        { id = "nebula", name = "Nebula", icon = "🌌", fx = "stars",
            sw = { rgb(30, 10, 74), rgb(98, 72, 222), rgb(60, 140, 255) },
            pal = P({ {12,7,32}, {22,13,56}, {36,22,86}, {156,126,255}, {98,72,222}, {40,100,190}, {192,182,232}, {15,9,38} }) },
        { id = "blackhole", name = "Blackhole", icon = "🕳️", fx = "blackhole",
            sw = { rgb(3, 3, 8), rgb(255, 130, 40), rgb(130, 70, 200) },
            pal = P({ {3,3,8}, {10,8,20}, {22,16,40}, {255,152,62}, {168,78,40}, {92,52,122}, {196,176,168}, {6,5,12} }) },
        { id = "aurora", name = "Aurora", icon = "🌠", fx = "aurora",
            sw = { rgb(6, 20, 40), rgb(60, 230, 180), rgb(170, 110, 255) },
            pal = P({ {5,12,24}, {9,26,40}, {14,42,60}, {96,240,205}, {60,200,170}, {30,130,112}, {164,208,210}, {7,17,30} }) },
        { id = "sakura", name = "Sakura", icon = "🌸", fx = "petals",
            sw = { rgb(52, 16, 40), rgb(240, 120, 170), rgb(255, 205, 220) },
            pal = P({ {38,14,28}, {62,24,46}, {96,40,72}, {255,162,202}, {240,120,170}, {160,70,112}, {236,198,214}, {44,16,32} }) },
        { id = "galaxy", name = "Galaksi", icon = "🌀", fx = "galaxy",
            sw = { rgb(8, 4, 22), rgb(190, 120, 255), rgb(255, 210, 160) },
            pal = P({ {6,4,16}, {16,10,36}, {30,18,64}, {196,146,255}, {126,100,255}, {44,122,172}, {192,182,226}, {9,6,22} }) },
        { id = "solar", name = "Tata Surya", icon = "🪐", fx = "stars",
            sw = { rgb(6, 8, 22), rgb(255, 170, 60), rgb(80, 150, 255) },
            pal = P({ {4,5,14}, {10,14,30}, {20,28,56}, {255,200,104}, {255,168,58}, {48,132,92}, {192,198,216}, {6,8,20} }) },
        { id = "neon", name = "Neon Retro", icon = "🌴", fx = "grid",
            sw = { rgb(14, 4, 32), rgb(255, 60, 200), rgb(0, 230, 255) },
            pal = P({ {10,4,24}, {26,8,50}, {50,14,84}, {255,64,204}, {0,226,255}, {0,150,172}, {204,172,232}, {13,5,30} }) },
        { id = "gold", name = "Emas Mewah", icon = "👑", fx = "sheen",
            sw = { rgb(14, 11, 6), rgb(222, 168, 48), rgb(255, 225, 140) },
            pal = P({ {14,11,6}, {34,26,12}, {58,44,18}, {255,205,90}, {222,168,48}, {112,92,30}, {214,200,170}, {20,15,8} }) },
    }
    local byId = {}
    for _, th in ipairs(THEMES) do byId[th.id] = th end
    local cur = byId.default.pal

    local function keyOf(c)
        return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
    end

    -- ---------- lapisan dekorasi di belakang isi menu ----------
    local fxRoot = Instance.new("Frame")
    fxRoot.Name = "ThemeFX"
    fxRoot.Size = UDim2.new(1, 0, 1, 0)
    fxRoot.BackgroundColor3 = WHITE
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
    do
        local acc = 0
        local hb = RunService.Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.033 then return end
            acc = 0
            if cfg.anim == false or not mainFrame.Visible or #anims == 0 then return end
            local t = os.clock()
            for i = 1, #anims do pcall(anims[i], t) end
        end)
        onCleanup(function() hb:Disconnect() end)
    end

    local function clearDeco()
        for _, c in ipairs(deco:GetChildren()) do c:Destroy() end
        anims = {}
    end

    local function dot(x, y, size, color, transp)
        local d = Instance.new("Frame")
        d.AnchorPoint = Vector2.new(0.5, 0.5)
        d.Position = UDim2.new(x, 0, y, 0)
        d.Size = UDim2.new(0, size, 0, size)
        d.BackgroundColor3 = color
        d.BackgroundTransparency = transp or 0.5
        d.BorderSizePixel = 0
        d.ZIndex = 0
        d.Parent = deco
        corner(d, size)
        return d
    end

    local function stars(n, seed, color)
        local rnd = Random.new(seed)
        for _ = 1, n do
            local d = dot(rnd:NextNumber(), rnd:NextNumber(), rnd:NextInteger(1, 3), color, 0.5)
            local ph, sp = rnd:NextNumber(0, 6.28), rnd:NextNumber(0.8, 2.4)
            table.insert(anims, function(t) d.BackgroundTransparency = 0.55 + math.sin(t * sp + ph) * 0.35 end)
        end
    end

    local function blob(x, y, size, color)
        for i = 1, 4 do
            local s = size * (1 - (i - 1) * 0.22)
            dot(x, y, s, color, 0.94 - i * 0.03)
        end
    end

    -- partikel jatuh / naik (glyph emoji atau huruf)
    local function floaters(n, glyphs, color, size, speed, up, sway, seed)
        local rnd = Random.new(seed or 5)
        for i = 1, n do
            local l = newLabel(deco, glyphs[(i - 1) % #glyphs + 1], size + rnd:NextInteger(-2, 3), Enum.Font.GothamBold, color,
                UDim2.new(0, 0, 0, 0), UDim2.new(0, 16, 0, 16))
            l.ZIndex = 0
            l.TextTransparency = rnd:NextNumber(0.25, 0.6)
            local x0, ph, sp = rnd:NextNumber(0.02, 0.98), rnd:NextNumber(), speed * rnd:NextNumber(0.6, 1.3)
            table.insert(anims, function(t)
                local p = (ph + t * sp) % 1
                local y = up and (1.05 - p * 1.1) or (p * 1.1 - 0.05)
                l.Position = UDim2.new(x0 + math.sin(t * 0.8 + ph * 6) * sway, 0, y, 0)
            end)
        end
    end

    local function sheen(color)
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.new(-0.3, 0, 0.5, 0)
        f.Size = UDim2.new(0, 70, 0, 520)
        f.Rotation = 24
        f.BackgroundColor3 = color
        f.BackgroundTransparency = 0.8
        f.BorderSizePixel = 0
        f.ZIndex = 0
        f.Parent = deco
        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) })
        g.Parent = f
        table.insert(anims, function(t) f.Position = UDim2.new(-0.3 + ((t % 7) / 7) * 1.6, 0, 0.5, 0) end)
    end

    local function beams(colors)
        for i, col in ipairs(colors) do
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0)
            f.Position = UDim2.new(0.2 + i * 0.22, 0, -0.1, 0)
            f.Size = UDim2.new(0, 52, 0, 440)
            f.Rotation = 14
            f.BackgroundColor3 = col
            f.BackgroundTransparency = 0.86
            f.BorderSizePixel = 0
            f.ZIndex = 0
            f.Parent = deco
            local g = Instance.new("UIGradient")
            g.Rotation = 90
            g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
            g.Parent = f
            local ph = i * 1.7
            table.insert(anims, function(t)
                f.BackgroundTransparency = 0.84 + math.sin(t * 0.6 + ph) * 0.05
                f.Position = UDim2.new(0.2 + i * 0.22 + math.sin(t * 0.25 + ph) * 0.06, 0, -0.1, 0)
            end)
        end
    end

    local function grid(color)
        for i = 1, 9 do
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 0, 1)
            f.BackgroundColor3 = color
            f.BorderSizePixel = 0
            f.ZIndex = 0
            f.Parent = deco
            local ph = i / 9
            table.insert(anims, function(t)
                local p = (ph + t * 0.06) % 1
                f.Position = UDim2.new(0, 0, 0.45 + p * 0.55, 0)
                f.BackgroundTransparency = 0.85 - p * 0.55
            end)
        end
    end

    local function build(th)
        clearDeco()
        fxRoot.Visible = th.fx ~= "none"
        bgImage.Visible = th.fx == "none"
        if th.fx == "none" then return end
        local pal = th.pal
        baseGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, pal.dark:Lerp(pal.accent, 0.22)),
            ColorSequenceKeypoint.new(0.55, pal.black),
            ColorSequenceKeypoint.new(1, pal.dark),
        })
        baseGrad.Rotation = 135
        local ac, fx = pal.accent, th.fx
        if fx == "sheen" then
            sheen(rgb(255, 255, 255))
            blob(0.92, 0.08, 150, ac)
            blob(0.05, 0.95, 130, ac)
        elseif fx == "leaves" then
            floaters(11, { "🍃", "🍂" }, ac, 12, 0.05, false, 0.04, 3)
            stars(8, 3, rgb(210, 255, 150))
        elseif fx == "matrix" then
            floaters(18, { "1", "0" }, ac, 11, 0.12, false, 0.005, 9)
        elseif fx == "bubbles" then
            floaters(12, { "○", "◦" }, rgb(190, 235, 255), 12, 0.07, true, 0.03, 4)
            blob(0.5, 1.05, 260, ac)
        elseif fx == "embers" then
            floaters(14, { "✦", "•" }, ac, 10, 0.08, true, 0.03, 6)
            blob(0.5, 1.05, 260, ac)
        elseif fx == "stars" then
            stars(30, 11, rgb(255, 255, 255))
            blob(0.88, 0.1, 160, ac)
        elseif fx == "blackhole" then
            stars(22, 13, rgb(255, 255, 255))
            floaters(8, { "✦" }, ac, 9, 0.06, true, 0.02, 8)
            blob(0.5, 0.45, 150, ac)
        elseif fx == "aurora" then
            beams({ rgb(96, 240, 205), rgb(150, 112, 240), rgb(96, 240, 205) })
            stars(14, 21, rgb(255, 255, 255))
        elseif fx == "petals" then
            floaters(12, { "🌸", "🌺" }, ac, 12, 0.05, false, 0.05, 2)
        elseif fx == "galaxy" then
            stars(28, 31, rgb(255, 255, 255))
            blob(0.2, 0.2, 180, ac)
            blob(0.85, 0.8, 200, rgb(255, 132, 192))
        elseif fx == "grid" then
            grid(ac)
            stars(12, 41, rgb(0, 226, 255))
        end
    end

    -- ---------- transparansi panel ----------
    local function applyPanel()
        local keys = {}
        for _, role in ipairs({ "black", "dark", "btn", "on" }) do keys[keyOf(cur[role])] = true end
        local v = cfg.panel or 0.12
        for _, d in ipairs(mainFrame:GetDescendants()) do
            if (d:IsA("Frame") or d:IsA("TextButton") or d:IsA("TextBox") or d:IsA("ScrollingFrame") or d:IsA("TextLabel"))
                and d.BackgroundTransparency < 1 and not d:GetAttribute("NoPanel") and not d:FindFirstAncestor("ThemeFX") then
                if keys[keyOf(d.BackgroundColor3)] or d:GetAttribute("Panel") then
                    d.BackgroundTransparency = v
                end
            end
        end
    end
    S.applyPanel = applyPanel

    -- ---------- ganti tema ----------
    local rows = {}
    local function refreshRows()
        for id, r in pairs(rows) do
            local on = (cfg.theme == id)
            r.stroke.Color = on and ACCENT_BLUE or LINE
            r.check.Text = on and "✓" or ""
        end
    end

    local function applyTheme(id)
        local th = byId[id] or THEMES[1]
        local np = th.pal
        local map = {}
        for role, c in pairs(cur) do map[keyOf(c)] = np[role] end
        BG_BLACK, BG_DARK, BG_BUTTON, BORDER_BLUE, ACCENT_BLUE = np.black, np.dark, np.btn, np.border, np.accent
        ON_COLOR, GREY, INFO_BG, LINE = np.on, np.grey, np.info, np.line

        local function mp(c) return map[keyOf(c)] end
        local function recolor(inst)
            if inst:GetAttribute("NoTheme") then return end
            if inst:IsA("UIStroke") then
                local n = mp(inst.Color)
                if n then inst.Color = n end
            elseif inst:IsA("GuiObject") then
                local n = mp(inst.BackgroundColor3)
                if n then inst.BackgroundColor3 = n end
                if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
                    n = mp(inst.TextColor3)
                    if n then inst.TextColor3 = n end
                    if inst:IsA("TextBox") then
                        n = mp(inst.PlaceholderColor3)
                        if n then inst.PlaceholderColor3 = n end
                    end
                end
                if inst:IsA("ScrollingFrame") then
                    n = mp(inst.ScrollBarImageColor3)
                    if n then inst.ScrollBarImageColor3 = n end
                end
            end
        end
        for _, d in ipairs(screenGui:GetDescendants()) do
            if not d:FindFirstAncestor("ThemeFX") then pcall(recolor, d) end
        end

        cur = np
        cfg.theme = th.id
        build(th)
        refreshRows()
        for _, r in ipairs(RARITY_LIST) do setRarity(r, cfg.rarities[r], true) end
        selectTab(currentTab)
        applyPanel()
        saveCfg()
    end

    -- ---------- isi tab ----------
    makeHeader(page, "🎨 TEMA TAMPILAN", 0)
    makeHeader(page, "✨ EFEK", 1)
    makeToggle(page, "✨ ANIMASI TEMA", 2, function(on) cfg.anim = on saveCfg() end, cfg.anim ~= false)
    makeSlider(page, 3, "🪟 TRANSPARANSI PANEL", 0, 0.7, 0.05, cfg.panel or 0.12, function(v)
        cfg.panel = v
        applyPanel()
    end, function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
    makeHeader(page, "🎨 DAFTAR TEMA (" .. #THEMES .. ")", 10)

    for i, th in ipairs(THEMES) do
        local row = Instance.new("TextButton")
        row.LayoutOrder = 10 + i
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = BG_BUTTON
        row.Text = th.icon .. "  " .. th.name
        row.TextSize = 11
        row.Font = Enum.Font.GothamBold
        row.TextColor3 = WHITE
        row.TextXAlignment = LEFT
        row.AutoButtonColor = false
        row.Parent = page
        row:SetAttribute("Srch", true)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 12)
        pad.Parent = row
        corner(row, 8)
        local st = stroke(row, LINE, 1)
        decorate(row)
        for k = 1, 3 do
            local sw = Instance.new("Frame")
            sw.Position = UDim2.new(1, -92 + (k - 1) * 20, 0.5, -8)
            sw.Size = UDim2.new(0, 16, 0, 16)
            sw.BackgroundColor3 = th.sw[k]
            sw.BorderSizePixel = 0
            sw:SetAttribute("NoTheme", true)
            sw:SetAttribute("NoPanel", true)
            sw.Parent = row
            corner(sw, 5)
        end
        local check = newLabel(row, "", 14, Enum.Font.GothamBold, GREEN, UDim2.new(1, -30, 0, 0), UDim2.new(0, 20, 1, 0))
        rows[th.id] = { stroke = st, check = check }
        row.MouseButton1Click:Connect(function()
            applyTheme(th.id)
            notify("✅ Tema " .. th.name .. " dipakai", "ok", 1.8)
        end)
    end

    local tip = newLabel(page, "Tema mengganti warna seluruh menu. Beberapa tema punya animasi (bisa dimatikan).", 9, Enum.Font.Gotham, GREY,
        UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), LEFT)
    tip.LayoutOrder = 99
    tip.TextWrapped = true
    tip:SetAttribute("SrchHide", true)

    applyTheme(cfg.theme or "default")
end

local okT, errT = pcall(initTheme)
if not okT then warn("THE RICH tema error: " .. tostring(errT)) end

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
print("🤑 THE RICH loaded!  User: " .. player.Name .. " (" .. player.DisplayName .. ")")

end, function(e)
    return tostring(e) .. "\n" .. tostring(debug.traceback())
end)

if not __ok then
    warn("THE RICH error: " .. tostring(__err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "THE RICH 🤑", Text = "Error: " .. tostring(__err):sub(1, 150), Duration = 8 })
    end)
else
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = "THE RICH 🤑", Text = "Siap dipakai ✨", Duration = 3 })
    end)
end

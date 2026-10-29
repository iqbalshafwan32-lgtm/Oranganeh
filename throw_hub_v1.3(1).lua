local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
local TARGET = CFrame.new(5, 6, -39)
local LOOP_DELAY = 0.15    -- jeda antar putaran auto farm (detik)
local UPGRADE_DELAY = 0.3  -- jeda antar upgrade otomatis (detik)

-- Remote disiapkan di awal supaya tidak ada tunggu setelah teleport
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowStart = Remotes:WaitForChild("Throw_Start")
local ThrowResolve = Remotes:WaitForChild("Throw_Resolve")
local ThrowComplete = Remotes:WaitForChild("Throw_Complete")
local EquipBest = Remotes:WaitForChild("Plot_EquipBest")
local UpgradeFence = Remotes:WaitForChild("Plot_UpgradeFence")
local SellAll = Remotes:WaitForChild("Plot_SellAll", 5)
local StandUpgrade = Remotes:WaitForChild("Stand_Upgrade")

-- Hapus UI lama kalau ada
pcall(function()
	local root = (gethui and gethui()) or CoreGui
	local old = root:FindFirstChild("ThrowHub")
	if old then old:Destroy() end
	local oldB = root:FindFirstChild("ThrowHubBlack")
	if oldB then oldB:Destroy() end
end)

-- ===== UI (tampilan sama dengan Universal Hub) =====
-- Warna tema (di-assign ulang oleh tab TEMA)
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

local cleanupFns = {}
local pages = {}
local tabButtons = {}

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

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThrowHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = (gethui and gethui()) or CoreGui

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

-- skala menu (dipakai animasi buka & riak tombol)
local miniScale = Instance.new("UIScale")
miniScale.Name = "UHMiniScale"
miniScale.Scale = 1
miniScale.Parent = mainFrame

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

newLabel(topBar, "TheRich🤑", 14, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 36, 0, 8), UDim2.new(1, -80, 0, 20), Enum.TextXAlignment.Left)
newLabel(topBar, "Player Hub  •  v1.3", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 36, 0, 28), UDim2.new(1, -80, 0, 12), Enum.TextXAlignment.Left)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 10, 0, 44)
statusDot.BackgroundColor3 = GREEN
statusDot.BorderSizePixel = 0
statusDot.Parent = topBar
corner(statusDot, 3)

newLabel(topBar, "ONLINE", 8, Enum.Font.GothamBold, GREEN, UDim2.new(0, 20, 0, 40), UDim2.new(0, 50, 0, 12), Enum.TextXAlignment.Left)

-- Minimize Button  ( – )
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -60, 0, 10)
minBtn.BackgroundColor3 = BG_BUTTON
minBtn.Text = "–"
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.TextColor3 = WHITE
minBtn.AutoButtonColor = false
minBtn.Parent = topBar
corner(minBtn, 6)

minBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false -- buka lagi lewat tombol 💲
end)

-- Close Button  ( X )  — cleanup semua fitur lalu hapus UI
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

-- Tab Container (bisa digeser kiri/kanan)
local tabContainer = Instance.new("ScrollingFrame")
tabContainer.Size = UDim2.new(1, -16, 0, 28)
tabContainer.Position = UDim2.new(0, 8, 0, 58)
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

-- ===== NOTIFIKASI (sama seperti Universal) =====
pages.NOTIF = { list = {}, ready = false }

function pages.notify(text, kind, dur)
    local ok, err = pcall(function()
        local state = pages.NOTIF
        local list = state.list
        text = tostring(text)
        dur = dur or 2.6

        local marks = {
            { "✅", "ok" }, { "✔", "ok" }, { "💾", "ok" },
            { "⚠️", "warn" }, { "⚠", "warn" },
            { "❌", "err" }, { "⛔", "err" },
            { "⏳", nil }, { "ℹ️", nil }, { "🗑", nil }, { "✏️", nil }, { "🎨", nil }, { "⚙️", nil }, { "⚪", nil },
        }
        local icon
        for _, m in ipairs(marks) do
            if text:sub(1, #m[1]) == m[1] then
                icon = m[1]
                text = (text:sub(#m[1] + 1):gsub("^%s+", ""))
                kind = kind or m[2]
                break
            end
        end
        if not icon then
            icon = (kind == "ok" and "✅") or (kind == "warn" and "⚠️") or (kind == "err" and "❌") or "🔔"
        end

        -- pesan yang sama masih tampil -> cukup diperbarui
        for _, e in ipairs(list) do
            if e.text == text and e.icon == icon and not e.closed then
                e.start(dur, true)
                return
            end
        end

        local color = (kind == "ok" and Color3.fromRGB(80, 220, 120))
            or (kind == "warn" and Color3.fromRGB(250, 204, 21))
            or (kind == "err" and Color3.fromRGB(255, 80, 80))
            or Color3.fromRGB(70, 130, 255)

        local TextService = game:GetService("TextService")
        local TweenService = game:GetService("TweenService")
        local W = 236
        local GAP = 6
        local Y0 = 30 -- tepat di bawah bar FPS
        local bounds = TextService:GetTextSize(text, 11, Enum.Font.GothamBold, Vector2.new(W - 60, 10000))
        local H = math.max(40, bounds.Y + 27)

        -- posisi: di bawah notifikasi yang sudah ada
        local y = Y0
        for _, e in ipairs(list) do y = y + e.H + GAP end

        local f = Instance.new("Frame")
        f.Name = "UHNotif"
        f.AnchorPoint = Vector2.new(0.5, 0)
        f.Position = UDim2.new(0.5, 0, 0, y - 12)
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
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.55),
        })
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

        local iconLbl = newLabel(iconBg, icon, 14, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255),
            UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
        iconLbl.TextTransparency = 1
        iconLbl.ZIndex = 202

        local iconScale = Instance.new("UIScale")
        iconScale.Scale = 0.2
        iconScale.Parent = iconLbl

        local titleLbl = newLabel(f, "TheRich🤑", 8, Enum.Font.GothamBlack, color,
            UDim2.new(0, 42, 0, 5), UDim2.new(1, -52, 0, 10), Enum.TextXAlignment.Left)
        titleLbl.TextTransparency = 1
        titleLbl.ZIndex = 201

        local msgLbl = newLabel(f, text, 11, Enum.Font.GothamBold, Color3.fromRGB(255, 255, 255),
            UDim2.new(0, 42, 0, 16), UDim2.new(1, -52, 0, bounds.Y), Enum.TextXAlignment.Left)
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

        local function tw(o, t, props, style, dir)
            local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
            tween:Play()
            return tween
        end

        local entry = { f = f, H = H, y = y, text = text, icon = icon, closed = false, tok = 0 }
        list[#list + 1] = entry

        -- susun ulang: semua naik menutup celah kalau ada yang hilang
        local function relayout()
            local yy = Y0
            for _, e in ipairs(list) do
                if e.y ~= yy then
                    e.y = yy
                    TweenService:Create(e.f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        { Position = UDim2.new(0.5, 0, 0, yy) }):Play()
                end
                yy = yy + e.H + GAP
            end
        end

        function entry.close(instant)
            if entry.closed then return end
            entry.closed = true
            for i, e in ipairs(list) do
                if e == entry then table.remove(list, i) break end
            end
            relayout()

            if instant then
                f:Destroy()
                return
            end

            tw(f, 0.2, { BackgroundTransparency = 1 })
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

        -- mulai / ulang timer (refresh = pesan sama muncul lagi)
        function entry.start(d, refresh)
            entry.tok = entry.tok + 1
            local tok = entry.tok
            fill.Size = UDim2.new(1, 0, 1, 0)
            tw(fill, d, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
            if refresh then
                sc.Scale = 1.07
                tw(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
            end
            task.delay(d, function()
                if entry.tok == tok then entry.close() end
            end)
        end

        -- animasi masuk
        tw(f, 0.26, { BackgroundTransparency = 0.28, Position = UDim2.new(0.5, 0, 0, y) })
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
            local dx = rnd:NextInteger(-10, 10)
            tw(sp, rnd:NextNumber(0.6, 1.0), {
                Position = UDim2.new(sp.Position.X.Scale, sp.Position.X.Offset + dx, 0, sp.Position.Y.Offset - rnd:NextInteger(14, 28)),
                TextTransparency = 1,
            })
            task.delay(1.2, function() if sp.Parent then sp:Destroy() end end)
        end

        f.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                entry.close()
            end
        end)

        entry.start(dur)

        -- terlalu banyak: yang paling lama ditutup
        while #list > 5 do
            list[1].close()
        end
    end)

    if not ok then
        warn("THROW HUB notify error: " .. tostring(err))
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", { Title = "TheRich🤑", Text = tostring(text), Duration = 3 })
        end)
    end
end

-- Header section
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

    -- detail: strip aksen di kiri yang berdenyut pelan
    local acc = Instance.new("Frame")
    acc.Name = "BubbleAccent"
    acc.Position = UDim2.new(0, 5, 0.5, -6)
    acc.Size = UDim2.new(0, 3, 0, 12)
    acc.BackgroundColor3 = ACCENT_BLUE
    acc.BackgroundTransparency = 0.1
    acc.BorderSizePixel = 0
    acc:SetAttribute("UHNoFade", true)
    acc.Parent = f
    corner(acc, 2)
    game:GetService("TweenService"):Create(acc,
        TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.65 }):Play()

    newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 14, 0, 0), UDim2.new(1, -22, 1, 0), Enum.TextXAlignment.Left)
    return f
end

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -16, 1, -144)
    page.Position = UDim2.new(0, 8, 0, 92)
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
makePage("TEMA") -- diakses lewat pages.TEMA
makePage("INFO") -- diakses lewat pages.INFO

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
makeTabButton("TEMA", "🎨", "TEMA")
makeTabButton("INFO", "ℹ️", "INFO")

tabButtons["FARM"].BackgroundColor3 = ACCENT_BLUE
tabButtons["FARM"].TextColor3 = WHITE
pages["FARM"].Visible = true

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

-- ==================== FARM PAGE ====================
pages.header(farmPage, "🌾 THROW / FARM", 0)

local statusFrame = Instance.new("Frame")
statusFrame.LayoutOrder = 1
statusFrame.Size = UDim2.new(1, 0, 0, 26)
statusFrame.BackgroundColor3 = BG_DARK
statusFrame.BorderSizePixel = 0
statusFrame.Parent = farmPage
corner(statusFrame, 8)

local status = newLabel(statusFrame, "Status: Idle", 10, Enum.Font.GothamBold, GREY,
    UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), Enum.TextXAlignment.Left)

local farmBtn = makeButton(farmPage, "🎯 AUTO FARM • OFF", 2)
local equipBtn = makeButton(farmPage, "⭐ EQUIP BEST", 3)
local tapBtn = makeButton(farmPage, "🤚 AUTO TAP BONUS • OFF", 4)
local plotBtn = makeButton(farmPage, "🏗️ UPGRADE PLOT • OFF", 5)
local treadBtn = makeButton(farmPage, "⚙️ UPGRADE TREADMILL • OFF", 6)
local sellBtn = makeButton(farmPage, "💰 SELL ALL", 7)

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

-- Logo Button (buka/tutup menu, bisa digeser)
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

local logoConn = UserInputService.InputChanged:Connect(function(input)
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
table.insert(cleanupFns, function() logoConn:Disconnect() end)

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

do
-- ==================== INFO BAR (FPS / PING / PLAYER / MEMORI) — paling atas layar ====================
local Stats = game:GetService("Stats")

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

        infoLabel.Text = string.format("📊 FPS %d  |  📶 %dms  |  👥 %d  |  💾 %dMB  |  🕒 %s", fps, ping, #Players:GetPlayers(), mem, os.date("%H:%M"))
        infoLabel.TextColor3 = (ping < 100 and GREEN) or (ping < 200 and Color3.fromRGB(250, 204, 21)) or RED
    end
end)
-- ===== INFO GAME (tap bar FPS untuk buka / tutup): foto map, nama, pembuat, player, ID + tombol salin =====
local MarketplaceSvc = game:GetService("MarketplaceService")
local infoPanel = Instance.new("Frame")
infoPanel.Name = "InfoPanel"
infoPanel.AnchorPoint = Vector2.new(0.5, 0)
infoPanel.Size = UDim2.new(0, 290, 0, 156)
infoPanel.Position = UDim2.new(0.5, 0, 0, 25)
infoPanel.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
infoPanel.BackgroundTransparency = 0.12
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 50
infoPanel.Visible = false
infoPanel.Parent = screenGui
corner(infoPanel, 12)
stroke(infoPanel, ACCENT_BLUE, 1.2)

local infoScale = Instance.new("UIScale")
infoScale.Scale = 1
infoScale.Parent = infoPanel

local gameName, creatorName = "Memuat...", ""

local function infoLabel2(text, size, font, color, pos, sz)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Text = text
    l.TextSize = size
    l.Font = font
    l.TextColor3 = color
    l.Position = pos
    l.Size = sz
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.TextWrapped = true
    l.ZIndex = 51
    l.Parent = infoPanel
    return l
end

-- foto map (ikon game asli; emoji sebagai cadangan)
local iconHold = Instance.new("Frame")
iconHold.Name = "BubbleIcon"
iconHold.Size = UDim2.new(0, 64, 0, 64)
iconHold.Position = UDim2.new(0, 10, 0, 10)
iconHold.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
iconHold.BorderSizePixel = 0
iconHold.ZIndex = 51
iconHold.Parent = infoPanel
corner(iconHold, 14)
local iconStroke = stroke(iconHold, ACCENT_BLUE, 2)
iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local iconEmoji = Instance.new("TextLabel")
iconEmoji.BackgroundTransparency = 1
iconEmoji.Size = UDim2.new(1, 0, 1, 0)
iconEmoji.Text = "🎮"
iconEmoji.TextSize = 26
iconEmoji.Font = Enum.Font.GothamBold
iconEmoji.TextColor3 = WHITE
iconEmoji.ZIndex = 52
iconEmoji.Parent = iconHold

local iconImg = Instance.new("ImageLabel")
iconImg.BackgroundTransparency = 1
iconImg.Size = UDim2.new(1, 0, 1, 0)
iconImg.ScaleType = Enum.ScaleType.Crop
iconImg.ZIndex = 53
iconImg.Parent = iconHold
corner(iconImg, 14)
if game.GameId ~= 0 then
    iconImg.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
end

local infoName = infoLabel2("Memuat...", 13, Enum.Font.GothamBlack, WHITE, UDim2.new(0, 84, 0, 10), UDim2.new(1, -94, 0, 34))
local infoBy = infoLabel2("", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 84, 0, 46), UDim2.new(1, -94, 0, 12))
local infoStat = infoLabel2("", 10, Enum.Font.GothamBold, GREEN, UDim2.new(0, 84, 0, 60), UDim2.new(1, -94, 0, 14))
local infoIds = infoLabel2("", 9, Enum.Font.Gotham, GREY, UDim2.new(0, 10, 0, 80), UDim2.new(1, -20, 0, 28))

task.spawn(function()
    local ok, info = pcall(function() return MarketplaceSvc:GetProductInfo(game.PlaceId) end)
    gameName = (ok and info and info.Name) or ("Place " .. tostring(game.PlaceId))
    if ok and info and info.Creator and info.Creator.Name then creatorName = tostring(info.Creator.Name) end
end)

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
    infoName.Text = tostring(gameName)
    infoBy.Text = (creatorName ~= "") and ("oleh " .. creatorName) or ""
    local up = 0
    pcall(function() up = workspace.DistributedGameTime end)
    infoStat.Text = string.format("🟢 %d / %d player  •  server %dm", #Players:GetPlayers(), Players.MaxPlayers, math.floor(up / 60))
    infoIds.Text = string.format("🆔 Place ID: %s\n🧩 Job ID: %s", tostring(game.PlaceId), (game.JobId ~= "" and game.JobId or "-"))
end

local infoTap = Instance.new("TextButton")
infoTap.Size = UDim2.new(1, 0, 1, 0)
infoTap.BackgroundTransparency = 1
infoTap.Text = ""
infoTap.ZIndex = 52
infoTap.Parent = infoBar
infoTap.MouseButton1Click:Connect(function()
    local TS = game:GetService("TweenService")
    if infoPanel.Visible then
        local t = TS:Create(infoScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 })
        t:Play()
        t.Completed:Connect(function() infoPanel.Visible = false end)
    else
        refreshInfoPanel()
        infoScale.Scale = 0.9
        infoPanel.Visible = true
        TS:Create(infoScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    end
end)
task.spawn(function()
    while infoPanel.Parent do
        task.wait(1)
        if infoPanel.Visible then refreshInfoPanel() end
    end
end)

table.insert(cleanupFns, function() infoConn:Disconnect() end)
end
-- ===== Util GUI =====
local function isVisible(o)
	local g = o
	while g and g ~= game do
		if g:IsA("GuiObject") then
			if not g.Visible then return false end
		elseif g:IsA("LayerCollector") then
			return g.Enabled
		end
		g = g.Parent
	end
	return true
end

local function centerOf(g)
	local sg = g:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = Vector2.zero
	if not (sg and sg.IgnoreGuiInset) then
		local ok, v = pcall(function() return GuiService:GetGuiInset() end)
		if ok and v then inset = v end
	end
	return g.AbsolutePosition + g.AbsoluteSize / 2 + inset
end

local MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function clickAt(c)
	if not VIM then return end
	task.spawn(function()
		if MOBILE then
			pcall(function() VIM:SendTouchEvent(9, 0, c.X, c.Y) end)
			RunService.Heartbeat:Wait()
			pcall(function() VIM:SendTouchEvent(9, 2, c.X, c.Y) end)
		else
			pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0) end)
			RunService.Heartbeat:Wait()
			pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0) end)
		end
	end)
end

local function fireButton(b)
	if firesignal then
		pcall(function() firesignal(b.MouseButton1Click) end)
		pcall(function() firesignal(b.Activated) end)
	elseif getconnections then
		pcall(function()
			for _, sig in ipairs({ b.MouseButton1Click, b.Activated }) do
				for _, cn in ipairs(getconnections(sig)) do
					pcall(function() cn:Fire() end)
				end
			end
		end)
	end
end

-- ===== Layar hitam saat farm + loading TheRich🤑 =====
local TweenService = game:GetService("TweenService")
local blackOn = true
local blackShown = false
local blackToken = 0

-- ScreenGui khusus (di belakang menu) tanpa inset, supaya hitamnya sampai ke pinggir/poni layar
local blackGui = Instance.new("ScreenGui")
blackGui.Name = "ThrowHubBlack"
blackGui.ResetOnSpawn = false
blackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
blackGui.IgnoreGuiInset = true
blackGui.DisplayOrder = -5
pcall(function() blackGui.ScreenInsets = Enum.ScreenInsets.None end)
blackGui.Parent = screenGui.Parent
table.insert(cleanupFns, function() blackGui:Destroy() end)

local blackFrame = Instance.new("CanvasGroup")
blackFrame.Name = "FarmBlack"
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackFrame.BorderSizePixel = 0
blackFrame.GroupTransparency = 1
blackFrame.ZIndex = 0 -- di bawah menu, bar FPS, dan notifikasi
blackFrame.Visible = false
blackFrame.Parent = blackGui

local blackBox = Instance.new("Frame")
blackBox.AnchorPoint = Vector2.new(0.5, 0.5)
blackBox.Position = UDim2.new(0.5, 0, 0.5, 0)
blackBox.Size = UDim2.new(0, 360, 0, 110)
blackBox.BackgroundTransparency = 1
blackBox.BorderSizePixel = 0
blackBox.Parent = blackFrame

local blackTitle = newLabel(blackBox, "TheRich🤑", 46, Enum.Font.GothamBlack, WHITE,
    UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 56))
local titleScale = Instance.new("UIScale")
titleScale.Parent = blackTitle
TweenService:Create(titleScale, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Scale = 1.07 }):Play()
local titleShine = Instance.new("UIGradient")
titleShine.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 205, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 205, 255)),
})
titleShine.Offset = Vector2.new(-1, 0)
titleShine.Parent = blackTitle
TweenService:Create(titleShine, TweenInfo.new(1.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Offset = Vector2.new(1, 0) }):Play()

-- garis loading ( _____ ) di bawah judul
local loadTrack = Instance.new("Frame")
loadTrack.AnchorPoint = Vector2.new(0.5, 0)
loadTrack.Position = UDim2.new(0.5, 0, 0, 68)
loadTrack.Size = UDim2.new(0, 320, 0, 5)
loadTrack.BackgroundColor3 = Color3.fromRGB(38, 40, 52)
loadTrack.BorderSizePixel = 0
loadTrack.ClipsDescendants = true
loadTrack.Parent = blackBox
corner(loadTrack, 2)

local loadFill = Instance.new("Frame")
loadFill.Size = UDim2.new(0.4, 0, 1, 0)
loadFill.Position = UDim2.new(-0.4, 0, 0, 0)
loadFill.BackgroundColor3 = ACCENT_BLUE
loadFill.BorderSizePixel = 0
loadFill.Parent = loadTrack
corner(loadFill, 2)
TweenService:Create(loadFill, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1),
    { Position = UDim2.new(1, 0, 0, 0) }):Play()

local loadText = newLabel(blackBox, "Loading", 12, Enum.Font.GothamBold, GREY,
    UDim2.new(0, 0, 0, 84), UDim2.new(1, 0, 0, 16))

task.spawn(function()
    local n = 0
    while blackFrame.Parent do
        task.wait(0.4)
        if blackShown then
            n = (n + 1) % 4
            loadText.Text = "Loading" .. string.rep(".", n)
        end
    end
end)

local function blackShow()
    if not blackOn then return end
    blackToken += 1
    if blackShown then return end
    blackShown = true
    blackFrame.Visible = true
    TweenService:Create(blackFrame, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
end

local function blackHide(delay)
    local tok = blackToken
    task.delay(delay or 0.6, function()
        if tok ~= blackToken or not blackShown then return end
        blackShown = false
        local t = TweenService:Create(blackFrame, TweenInfo.new(0.35), { GroupTransparency = 1 })
        t:Play()
        t.Completed:Connect(function()
            if not blackShown then blackFrame.Visible = false end
        end)
    end)
end

-- ===== Auto Farm: teleport lalu langsung remote =====
local busy = false

local function runSequence()
	if busy then return end
	busy = true

	local ok = pcall(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if not hrp then return end

		-- 1. Teleport, lalu langsung lanjut
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = TARGET

		-- 2. Throw Start
		pcall(function() ThrowStart:InvokeServer() end)

		-- 3. Throw Resolve
		pcall(function() ThrowResolve:InvokeServer(math.huge) end) -- sama dengan 10e100000

		-- 4. Throw Complete
		pcall(function() ThrowComplete:InvokeServer() end)
	end)

	busy = false
	return ok
end

local farming = false
local farmId = 0
local lastFarmNotif, lastTapNotif = 0, 0

local function stopFarm(msg)
	farming = false
	farmId += 1
	blackHide(0.3)
	farmBtn.Text = "🎯 AUTO FARM • OFF"
	farmBtn.BackgroundColor3 = BG_BUTTON
	if msg then status.Text = msg end
end

farmBtn.MouseButton1Click:Connect(function()
	if farming then
		stopFarm("Status: Auto Farm berhenti")
		return
	end

	farming = true
	farmId += 1
	local myId = farmId
	farmBtn.Text = "🎯 AUTO FARM • ON"
	farmBtn.BackgroundColor3 = ON_COLOR

	task.spawn(function()
		while farming and farmId == myId do
			status.Text = "Status: Farm..."
			blackShow()
			local done = runSequence()
			if done then blackHide(0.6) end
			if done and os.clock() - lastFarmNotif > 2 then
				lastFarmNotif = os.clock()
				pages.notify("✅ Proses farm selesai", "ok", 1.6)
			end
			task.wait(LOOP_DELAY)
		end
	end)
end)

-- ===== Equip Best =====
equipBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		local ok = pcall(function() EquipBest:InvokeServer() end)
		status.Text = ok and "Status: Equip Best OK" or "Status: Equip Best Error"
		pages.notify(ok and "✅ Equip Best berhasil" or "❌ Equip Best gagal", nil, 1.8)
	end)
end)

-- ===== Auto Tap Bonus (PlayerGui.TrainingSequence.TapBonusLayer) =====
local function tapBonusOnce()
	local pg = player:FindFirstChild("PlayerGui")
	local seq = pg and pg:FindFirstChild("TrainingSequence")
	local layer = seq and seq:FindFirstChild("TapBonusLayer")
	if not (layer and isVisible(layer)) then return false end

	local tapped = false
	-- 1) tombol yang terlihat di dalam layer
	for _, d in ipairs(layer:GetDescendants()) do
		if d:IsA("GuiButton") and isVisible(d) and d.AbsoluteSize.X > 0 then
			fireButton(d)
			clickAt(centerOf(d))
			tapped = true
		end
	end
	-- 2) kalau tidak ada tombol: objek bernama tap/bonus yang terlihat
	if not tapped then
		for _, d in ipairs(layer:GetDescendants()) do
			if d:IsA("GuiObject") and isVisible(d) and d.AbsoluteSize.X > 0 then
				local n = d.Name:lower()
				if n:find("tap") or n:find("bonus") then
					clickAt(centerOf(d))
					tapped = true
					break
				end
			end
		end
	end
	return tapped
end

local tapAuto = false
local tapId = 0

tapBtn.MouseButton1Click:Connect(function()
	tapAuto = not tapAuto
	tapId += 1
	local myId = tapId

	tapBtn.Text = "🤚 AUTO TAP BONUS • " .. (tapAuto and "ON" or "OFF")
	tapBtn.BackgroundColor3 = tapAuto and ON_COLOR or BG_BUTTON

	if tapAuto then
		task.spawn(function()
			while tapAuto and tapId == myId do
				local ok, tapped = pcall(tapBonusOnce)
				if ok and tapped then
					status.Text = "Status: Tap Bonus dipencet"
					if os.clock() - lastTapNotif > 1.5 then
						lastTapNotif = os.clock()
						pages.notify("🤚 Bonus training berhasil dipencet", "ok", 1.6)
					end
				end
				task.wait(0.05)
			end
		end)
	end
end)

-- ===== Upgrade Plot & Upgrade Treadmill (on/off) =====
local function makeUpgradeToggle(btn, icon, label, remote, plain)
	local on = false
	local id = 0
	btn.MouseButton1Click:Connect(function()
		on = not on
		id += 1
		local myId = id

		if plain then
			-- tampilan polos seperti EQUIP BEST: teks tetap, status ditunjukkan lewat warna tombol
			btn.Text = icon .. " " .. label
			pages.notify((on and "✅ " or "⚪ ") .. label .. (on and " aktif" or " nonaktif"), nil, 2)
		else
			btn.Text = icon .. " " .. label .. " • " .. (on and "ON" or "OFF")
		end
		btn.BackgroundColor3 = on and ON_COLOR or BG_BUTTON

		if on then
			task.spawn(function()
				while on and id == myId do
					local ok = pcall(function() remote:InvokeServer() end)
					status.Text = ok and ("Status: " .. label .. " OK") or ("Status: " .. label .. " Error")
					task.wait(UPGRADE_DELAY)
				end
			end)
		end
	end)
	-- dipanggil saat tombol X ditekan
	table.insert(cleanupFns, function() on = false; id += 1 end)
end

makeUpgradeToggle(plotBtn, "🏗️", "UPGRADE PLOT", UpgradeFence)
makeUpgradeToggle(treadBtn, "⚙️", "UPGRADE TREADMILL", StandUpgrade)
makeUpgradeToggle(sellBtn, "💰", "SELL ALL", SellAll, true)

-- hentikan auto farm & auto tap saat tombol X ditekan
table.insert(cleanupFns, function()
	farming = false; farmId += 1
	tapAuto = false; tapId += 1
end)

-- ==================== v33: TAB INFO (profil + foto, detail akun & game, supported maps, teleport map) ====================
-- Tampilan: kartu profil (foto avatar dengan cincin berputar, nama, @username, ID yang bisa disalin, badge membership),
-- 3 kotak statistik (teman / pengikut / mengikuti), jam & tanggal hidup, DETAIL AKUN, DETAIL GAME,
-- SUPPORTED MAPS (buka-tutup, kartu map dengan ikon game) + TELEPORT MAP.
-- Bio, tanggal dibuat asli, dan jumlah teman diambil dari API Roblox lewat executor.
-- Semua di dalam satu fungsi (pages.initInfo) supaya tidak menambah variabel local di level atas.
function pages.initInfo()
    local page = pages.INFO
    local TweenService = game:GetService("TweenService")
    local TextService = game:GetService("TextService")
    local TeleportService = game:GetService("TeleportService")
    local MarketplaceService = game:GetService("MarketplaceService")
    local UIS = game:GetService("UserInputService")
    local lp = Players.LocalPlayer
    local HttpService = game:GetService("HttpService")
    local startTime = os.time()

    local GOLD = Color3.fromRGB(255, 215, 0)
    local PURPLE = Color3.fromRGB(160, 100, 255)

    local HARI = { "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu" }
    local BULAN = { "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember" }

    local function fmtDur(sec)
        sec = math.max(0, math.floor(sec))
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        if h > 0 then return string.format("%dj %dm", h, m) end
        return string.format("%dm %ds", m, sec % 60)
    end

    local function fmtNum(n)
        local str = tostring(math.floor(n))
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        return (out:gsub("^%.", ""))
    end

    local function copy(text, what)
        local ok = pcall(function() (setclipboard or toclipboard or set_clipboard)(tostring(text)) end)
        if ok then
            pages.notify("✅ " .. what .. " tersalin", "ok", 1.8)
        else
            pages.notify("⚠️ Executor tidak mendukung salin", "warn", 2)
        end
    end

    local function spin(gradient, secs)
        TweenService:Create(gradient, TweenInfo.new(secs, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
    end

    local function chip(parent, text, color, asButton, fixedW)
        local b = Instance.new(asButton and "TextButton" or "TextLabel")
        local w = fixedW or (TextService:GetTextSize(text, 9, Enum.Font.GothamBold, Vector2.new(400, 20)).X + 18)
        b.Size = UDim2.new(0, w, 0, 18)
        b.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
        b.BackgroundTransparency = 0.25
        b.BorderSizePixel = 0
        b.Text = text
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = color
        if asButton then b.AutoButtonColor = false end
        b.Parent = parent
        corner(b, 9)
        local cs = stroke(b, color, 1)
        cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- tanpa ini garis ikut menebalkan teks
        return b
    end

    pages.header(page, "ℹ️ INFO", 0)

    -- ================= KARTU PROFIL =================
    local card = Instance.new("Frame")
    card.LayoutOrder = 1
    card.Size = UDim2.new(1, 0, 0, 136)
    card.BackgroundColor3 = BG_DARK
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = page
    corner(card, 12)
    stroke(card, ACCENT_BLUE, 1.2)

    local banner = Instance.new("Frame")
    banner.Name = "BubbleBanner"
    banner.Size = UDim2.new(1, 0, 0, 46)
    banner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    banner.BackgroundTransparency = 0.35
    banner.BorderSizePixel = 0
    banner:SetAttribute("UHNoFade", true)
    banner.Parent = card
    local bannerG = Instance.new("UIGradient")
    bannerG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACCENT_BLUE),
        ColorSequenceKeypoint.new(0.5, PURPLE),
        ColorSequenceKeypoint.new(1, ACCENT_BLUE),
    })
    bannerG.Parent = banner
    spin(bannerG, 8)

    -- foto avatar + cincin berputar
    local ring = Instance.new("Frame")
    ring.Name = "BubbleRing"
    ring.Size = UDim2.new(0, 66, 0, 66)
    ring.Position = UDim2.new(0, 12, 0, 20)
    ring.BackgroundColor3 = BG_BLACK
    ring.BorderSizePixel = 0
    ring:SetAttribute("UHNoFade", true)
    ring.Parent = card
    corner(ring, 33)
    local ringStroke = stroke(ring, Color3.fromRGB(255, 255, 255), 3)
    local ringG = Instance.new("UIGradient")
    ringG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GOLD),
        ColorSequenceKeypoint.new(0.35, ACCENT_BLUE),
        ColorSequenceKeypoint.new(0.7, PURPLE),
        ColorSequenceKeypoint.new(1, GOLD),
    })
    ringG.Parent = ringStroke
    spin(ringG, 4)

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "BubbleAvatar"
    avatar.Size = UDim2.new(1, -8, 1, -8)
    avatar.Position = UDim2.new(0, 4, 0, 4)
    avatar.BackgroundColor3 = BG_BUTTON
    avatar.BorderSizePixel = 0
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar:SetAttribute("UHNoFade", true)
    avatar.Parent = ring
    corner(avatar, 29)

    task.spawn(function()
        local ok, thumb = pcall(function()
            return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and thumb and avatar.Parent then avatar.Image = thumb end
    end)

    local onlineDot = Instance.new("Frame")
    onlineDot.Name = "BubbleDot"
    onlineDot.AnchorPoint = Vector2.new(0.5, 0.5)
    onlineDot.Position = UDim2.new(0, 70, 0, 70)
    onlineDot.Size = UDim2.new(0, 12, 0, 12)
    onlineDot.BackgroundColor3 = GREEN
    onlineDot.BorderSizePixel = 0
    onlineDot:SetAttribute("UHNoFade", true)
    onlineDot.Parent = card
    corner(onlineDot, 6)
    stroke(onlineDot, BG_BLACK, 2)
    TweenService:Create(onlineDot, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.55 }):Play()

    local nameLbl = newLabel(card, lp.DisplayName, 14, Enum.Font.GothamBlack, WHITE,
        UDim2.new(0, 88, 0, 50), UDim2.new(1, -96, 0, 18), Enum.TextXAlignment.Left)
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    newLabel(card, "@" .. lp.Name, 10, Enum.Font.GothamBold, ACCENT_BLUE,
        UDim2.new(0, 88, 0, 68), UDim2.new(1, -96, 0, 14), Enum.TextXAlignment.Left)

    local idChip = chip(card, "🆔 " .. tostring(lp.UserId) .. "  📋", GREY, true)
    idChip.Position = UDim2.new(0, 88, 0, 87)
    idChip.MouseButton1Click:Connect(function() copy(lp.UserId, "User ID") end)

    -- baris chip di bawah: hari akun dibuat, umur, ultah (diisi setelah data siap)
    local chipDay = chip(card, "📅 …", Color3.fromRGB(190, 215, 255), false, 74)
    chipDay.Position = UDim2.new(0, 12, 0, 108)
    chipDay.TextSize = 8
    local chipAge = chip(card, "⏳ …", Color3.fromRGB(150, 235, 190), false, 82)
    chipAge.Position = UDim2.new(0, 92, 0, 108)
    chipAge.TextSize = 8
    local chipBday = chip(card, "🎂 …", Color3.fromRGB(255, 200, 150), false, 74)
    chipBday.Position = UDim2.new(0, 180, 0, 108)
    chipBday.TextSize = 8

    local premium = false
    pcall(function() premium = (lp.MembershipType == Enum.MembershipType.Premium) end)
    local badge = chip(banner, premium and "✨ PREMIUM" or "👤 REGULER", premium and GOLD or Color3.fromRGB(235, 240, 255), false)
    badge.AnchorPoint = Vector2.new(1, 0)
    badge.Position = UDim2.new(1, -8, 0, 8)

    -- ================= 3 KOTAK STATISTIK =================
    local tiles = Instance.new("Frame")
    tiles.LayoutOrder = 2
    tiles.Size = UDim2.new(1, 0, 0, 52)
    tiles.BackgroundTransparency = 1
    tiles.BorderSizePixel = 0
    tiles.Parent = page
    local tilesLayout = Instance.new("UIListLayout")
    tilesLayout.FillDirection = Enum.FillDirection.Horizontal
    tilesLayout.Padding = UDim.new(0, 6)
    tilesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tilesLayout.Parent = tiles

    local function tile(order, caption, color)
        local t = Instance.new("Frame")
        t.LayoutOrder = order
        t.Size = UDim2.new(1 / 3, -4, 1, 0)
        t.BackgroundColor3 = BG_DARK
        t.BackgroundTransparency = 0.35
        t.BorderSizePixel = 0
        t.Parent = tiles
        corner(t, 10)
        stroke(t, color, 1)
        local num = newLabel(t, "…", 17, Enum.Font.GothamBlack, color,
            UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 22))
        newLabel(t, caption, 8, Enum.Font.GothamBold, GREY,
            UDim2.new(0, 0, 0, 31), UDim2.new(1, 0, 0, 12))
        return num
    end
    local friendsNum = tile(1, "TEMAN", GREEN)
    local followersNum = tile(2, "PENGIKUT", ACCENT_BLUE)
    local followingNum = tile(3, "MENGIKUTI", PURPLE)

    local function countUp(lbl, target)
        task.spawn(function()
            for i = 1, 16 do
                lbl.Text = fmtNum(target * i / 16)
                task.wait(0.03)
            end
            lbl.Text = fmtNum(target)
        end)
    end

    -- ================= JAM & TANGGAL =================
    local clock = Instance.new("Frame")
    clock.LayoutOrder = 3
    clock.Size = UDim2.new(1, 0, 0, 52)
    clock.BackgroundColor3 = BG_DARK
    clock.BackgroundTransparency = 0.35
    clock.BorderSizePixel = 0
    clock.Parent = page
    corner(clock, 10)
    stroke(clock, ACCENT_BLUE, 1)

    local timeLbl = newLabel(clock, "--:--:--", 20, Enum.Font.GothamBlack, WHITE,
        UDim2.new(0, 12, 0, 6), UDim2.new(0.55, 0, 0, 24), Enum.TextXAlignment.Left)
    local dateLbl = newLabel(clock, "", 10, Enum.Font.GothamMedium, GREY,
        UDim2.new(0, 12, 0, 31), UDim2.new(1, -20, 0, 14), Enum.TextXAlignment.Left)
    local sessLbl = newLabel(clock, "", 9, Enum.Font.GothamBold, GREEN,
        UDim2.new(0.5, 0, 0, 10), UDim2.new(0.5, -12, 0, 14), Enum.TextXAlignment.Right)

    local function tickClock()
        timeLbl.Text = os.date("%H:%M:%S")
        dateLbl.Text = string.format("%s, %d %s %s",
            HARI[tonumber(os.date("%w")) + 1], tonumber(os.date("%d")), BULAN[tonumber(os.date("%m"))], os.date("%Y"))
        sessLbl.Text = "⏱ sesi " .. fmtDur(os.time() - startTime)
    end
    tickClock()

    -- ================= SEDANG BERMAIN (foto map + nama + pembuat + player) =================
    pages.header(page, "🎮 SEDANG BERMAIN", 4)

    local nowFrame = Instance.new("Frame")
    nowFrame.LayoutOrder = 5
    nowFrame.Size = UDim2.new(1, 0, 0, 80)
    nowFrame.BackgroundColor3 = BG_DARK
    nowFrame.BackgroundTransparency = 0.3
    nowFrame.BorderSizePixel = 0
    nowFrame.Parent = page
    corner(nowFrame, 12)
    local nfs = stroke(nowFrame, ACCENT_BLUE, 1.2)
    nfs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local nowHold = Instance.new("Frame")
    nowHold.Name = "BubbleNowIcon"
    nowHold.Size = UDim2.new(0, 64, 0, 64)
    nowHold.Position = UDim2.new(0, 8, 0, 8)
    nowHold.BackgroundColor3 = BG_BLACK
    nowHold.BorderSizePixel = 0
    nowHold:SetAttribute("UHNoFade", true)
    nowHold.Parent = nowFrame
    corner(nowHold, 14)
    local nhs = stroke(nowHold, Color3.fromRGB(255, 255, 255), 2)
    nhs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local nhg = Instance.new("UIGradient")
    nhg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GOLD),
        ColorSequenceKeypoint.new(0.35, ACCENT_BLUE),
        ColorSequenceKeypoint.new(0.7, PURPLE),
        ColorSequenceKeypoint.new(1, GOLD),
    })
    nhg.Parent = nhs
    spin(nhg, 5)

    newLabel(nowHold, "🎮", 24, Enum.Font.GothamBold, WHITE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
    local nowImg = Instance.new("ImageLabel")
    nowImg.BackgroundTransparency = 1
    nowImg.Size = UDim2.new(1, 0, 1, 0)
    nowImg.ScaleType = Enum.ScaleType.Crop
    nowImg.Parent = nowHold
    corner(nowImg, 14)
    if game.GameId ~= 0 then
        nowImg.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=150&h=150"
    end

    local nowName = newLabel(nowFrame, "Memuat nama game…", 12, Enum.Font.GothamBlack, WHITE,
        UDim2.new(0, 82, 0, 8), UDim2.new(1, -90, 0, 32), Enum.TextXAlignment.Left)
    nowName.TextWrapped = true
    nowName.TextYAlignment = Enum.TextYAlignment.Top
    local nowCreator = newLabel(nowFrame, "", 9, Enum.Font.Gotham, GREY,
        UDim2.new(0, 82, 0, 42), UDim2.new(1, -90, 0, 12), Enum.TextXAlignment.Left)
    nowCreator.TextTruncate = Enum.TextTruncate.AtEnd
    local nowSub = newLabel(nowFrame, "", 10, Enum.Font.GothamBold, GREEN,
        UDim2.new(0, 82, 0, 58), UDim2.new(1, -90, 0, 14), Enum.TextXAlignment.Left)
    nowSub.TextTruncate = Enum.TextTruncate.AtEnd

    local nowCard = { name = nowName, creator = nowCreator, sub = nowSub }

    -- ================= BARIS DETAIL =================
    local function addRow(order, icon, key, withBar)
        local fr = Instance.new("Frame")
        fr.LayoutOrder = order
        fr.Size = UDim2.new(1, 0, 0, 30)
        fr.BackgroundColor3 = BG_DARK
        fr.BackgroundTransparency = 0.35
        fr.BorderSizePixel = 0
        fr.ClipsDescendants = true
        fr.Parent = page
        corner(fr, 10)
        local frs = stroke(fr, ACCENT_BLUE, 1)
        frs.Transparency = 0.6

        -- ikon dalam lingkaran
        local ib = Instance.new("Frame")
        ib.Size = UDim2.new(0, 22, 0, 22)
        ib.Position = UDim2.new(0, 6, 0, 4)
        ib.BackgroundColor3 = BG_BUTTON
        ib.BorderSizePixel = 0
        ib:SetAttribute("UHNoFade", true)
        ib.Parent = fr
        corner(ib, 11)
        newLabel(ib, icon, 11, Enum.Font.GothamBold, WHITE, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))

        newLabel(fr, key, 9, Enum.Font.GothamBold, GREY,
            UDim2.new(0, 34, 0, 9), UDim2.new(0, 66, 0, 12), Enum.TextXAlignment.Left)

        local v = newLabel(fr, "…", 10, Enum.Font.GothamBold, WHITE,
            UDim2.new(0, 102, 0, 7), UDim2.new(1, -110, 0, 16), Enum.TextXAlignment.Left)
        v.TextWrapped = true
        v.TextYAlignment = Enum.TextYAlignment.Top

        local bar
        if withBar then
            local tr = Instance.new("Frame")
            tr.Name = "BubbleBar"
            tr.AnchorPoint = Vector2.new(0, 1)
            tr.Position = UDim2.new(0, 10, 1, -4)
            tr.Size = UDim2.new(1, -20, 0, 3)
            tr.BackgroundColor3 = BG_BLACK
            tr.BorderSizePixel = 0
            tr:SetAttribute("UHNoFade", true)
            tr.Parent = fr
            corner(tr, 2)
            bar = Instance.new("Frame")
            bar.Name = "BubbleBarFill"
            bar.Size = UDim2.new(0, 0, 1, 0)
            bar.BackgroundColor3 = GREEN
            bar.BorderSizePixel = 0
            bar:SetAttribute("UHNoFade", true)
            bar.Parent = tr
            corner(bar, 2)
        end

        local row = {}
        function row.set(text, color)
            text = tostring(text)
            v.Text = text
            v.TextColor3 = color or WHITE
            local bnd = TextService:GetTextSize(text, 10, Enum.Font.GothamBold, Vector2.new(140, 10000))
            v.Size = UDim2.new(1, -110, 0, bnd.Y + 2)
            fr.Size = UDim2.new(1, 0, 0, math.max(30, bnd.Y + 15 + (withBar and 6 or 0)))
        end
        function row.setBar(frac)
            if bar then
                TweenService:Create(bar, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0) }):Play()
            end
        end
        return row
    end

    pages.header(page, "📋 DETAIL AKUN", 6)
    local R = {}
    R.created = addRow(7, "📅", "Dibuat")
    R.age = addRow(8, "⏳", "Umur akun")
    R.birthday = addRow(9, "🎂", "Ultah akun", true)
    R.locale = addRow(10, "🌐", "Locale")
    R.team = addRow(11, "👥", "Team")
    R.device = addRow(12, "💻", "Device")
    R.exec = addRow(13, "🔧", "Executor")
    R.bio = addRow(14, "💬", "Bio")

    pages.header(page, "🎮 DETAIL GAME", 15)
    R.game = { set = function(t) nowCard.name.Text = tostring(t) end }
    R.place = addRow(17, "🆔", "Place ID")
    R.job = addRow(18, "🧩", "Job ID")
    R.players = addRow(19, "👥", "Player")
    R.server = addRow(20, "⏱", "Server")

    -- tombol salin Place ID / Job ID
    local copyRow = Instance.new("Frame")
    copyRow.LayoutOrder = 21
    copyRow.Size = UDim2.new(1, 0, 0, 30)
    copyRow.BackgroundTransparency = 1
    copyRow.BorderSizePixel = 0
    copyRow.Parent = page
    local function smallBtn(xScale, text, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.Position = UDim2.new(xScale, xScale == 0 and 0 or 3, 0, 0)
        b.BackgroundColor3 = BG_BUTTON
        b.BackgroundTransparency = 0.3
        b.Text = text
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = WHITE
        b.AutoButtonColor = false
        b.Parent = copyRow
        corner(b, 8)
        local sbs = stroke(b, ACCENT_BLUE, 1)
        sbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        b.MouseButton1Click:Connect(fn)
        return b
    end
    smallBtn(0, "📋 SALIN PLACE ID", function() copy(game.PlaceId, "Place ID") end)
    smallBtn(0.5, "📋 SALIN JOB ID", function()
        if game.JobId == "" then
            pages.notify("⚠️ Job ID kosong (Studio / private)", "warn", 2)
        else
            copy(game.JobId, "Job ID")
        end
    end)

    local function serverText()
        local up = 0
        pcall(function() up = workspace.DistributedGameTime end)
        return "hidup " .. fmtDur(up)
    end

    -- tanggal akun dibuat -> hari + tanggal Indonesia, ultah akun berikutnya
    local function applyCreated(y, m, d, approx)
        local t = os.time({ year = y, month = m, day = d, hour = 12 })
        local wd = os.date("*t", t).wday
        R.created.set(string.format("%s, %d %s %d%s", HARI[wd], d, BULAN[m], y, approx and " (perkiraan)" or ""))

        local nowT = os.time()
        local ny = tonumber(os.date("%Y"))
        local nt = os.time({ year = ny, month = m, day = d, hour = 12 })
        if nt < nowT - 43200 then
            ny = ny + 1
            nt = os.time({ year = ny, month = m, day = d, hour = 12 })
        end
        local days = math.ceil((nt - nowT) / 86400)
        if days <= 0 then
            R.birthday.set("Hari ini! 🎉 (tahun ke-" .. (ny - y) .. ")", GREEN)
            chipBday.Text = "🎂 HARI INI!"
            R.birthday.setBar(1)
        else
            R.birthday.set(days .. " hari lagi (tahun ke-" .. (ny - y) .. ")")
            chipBday.Text = "🎂 " .. days .. " hari"
            R.birthday.setBar(1 - days / 365)
        end
        chipDay.Text = "📅 " .. HARI[wd]
        local nowY = tonumber(os.date("%Y"))
        local yr = nowY - y
        chipAge.Text = "⏳ " .. yr .. " tahun lebih"
    end

    local function httpGet(url)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" and res ~= "" then return res end
        local req = (syn and syn.request) or http_request or request or (http and http.request)
        if req then
            local ok2, r = pcall(function() return req({ Url = url, Method = "GET" }) end)
            if ok2 and type(r) == "table" then
                local body = r.Body or r.body
                if type(body) == "string" and body ~= "" then return body end
            end
        end
        return nil
    end

    local function getJson(url)
        local raw = httpGet(url)
        if not raw then return nil end
        local ok, d = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(d) == "table" then return d end
        return nil
    end

    local loading = false
    local function loadInfo()
        if loading then return end
        loading = true

        local ageDays = lp.AccountAge
        local yrs = math.floor(ageDays / 365)
        local rem = ageDays % 365
        R.age.set(string.format("%d tahun %d bulan %d hari (%s hari)", yrs, math.floor(rem / 30), rem % 30, fmtNum(ageDays)))

        local est = os.date("*t", os.time() - ageDays * 86400)
        applyCreated(est.year, est.month, est.day, true) -- perkiraan dulu, diganti data asli kalau API bisa

        local loc = "-"
        pcall(function() loc = lp.LocaleId end)
        R.locale.set(loc)

        local teamName = "-"
        pcall(function() if lp.Team then teamName = lp.Team.Name end end)
        R.team.set(teamName)

        local dev = "💻 PC"
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then
            dev = "📱 HP / Tablet"
        elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then
            dev = "🎮 Controller"
        end
        pcall(function()
            local vs = workspace.CurrentCamera.ViewportSize
            dev = dev .. string.format(" • %d×%d", vs.X, vs.Y)
        end)
        R.device.set(dev)

        local exec = "Tidak diketahui"
        pcall(function()
            if identifyexecutor then
                local n, v = identifyexecutor()
                exec = tostring(n) .. (v and (" " .. tostring(v)) or "")
            end
        end)
        R.exec.set(exec)

        R.bio.set("Memuat…", GREY)
        friendsNum.Text, followersNum.Text, followingNum.Text = "…", "…", "…"

        R.game.set("Place " .. tostring(game.PlaceId))
        R.place.set(game.PlaceId)
        R.job.set(game.JobId ~= "" and game.JobId or "-")
        R.players.set(string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers))
        R.server.set(serverText())
        nowCard.sub.Text = string.format("🟢 %d/%d player • %s", #Players:GetPlayers(), Players.MaxPlayers, serverText())

        task.spawn(function()
            local okG, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
            if okG and type(info) == "table" and info.Name then
                R.game.set(tostring(info.Name))
                if info.Creator and info.Creator.Name then
                    nowCard.creator.Text = "oleh " .. tostring(info.Creator.Name)
                end
            end

            local u = getJson("https://users.roblox.com/v1/users/" .. lp.UserId)
            if u then
                local y, m, d = tostring(u.created or ""):match("^(%d+)-(%d+)-(%d+)")
                if y then applyCreated(tonumber(y), tonumber(m), tonumber(d), false) end
                local bio = tostring(u.description or "")
                if bio:gsub("%s", "") == "" then
                    R.bio.set("(kosong)", GREY)
                else
                    R.bio.set(bio:sub(1, 200))
                end
                if u.hasVerifiedBadge then nameLbl.Text = lp.DisplayName .. " ✔" end
            else
                R.bio.set("Tidak bisa diambil (executor memblokir request)", GREY)
            end

            local fr = getJson("https://friends.roblox.com/v1/users/" .. lp.UserId .. "/friends/count")
            local fo = getJson("https://friends.roblox.com/v1/users/" .. lp.UserId .. "/followers/count")
            local fg = getJson("https://friends.roblox.com/v1/users/" .. lp.UserId .. "/followings/count")
            if fr and fr.count then countUp(friendsNum, fr.count) else friendsNum.Text = "?" end
            if fo and fo.count then countUp(followersNum, fo.count) else followersNum.Text = "?" end
            if fg and fg.count then countUp(followingNum, fg.count) else followingNum.Text = "?" end

            loading = false
        end)
    end

    local refreshBtn = makeButton(page, "🔄 REFRESH INFO", 22)
    refreshBtn.MouseButton1Click:Connect(function()
        loadInfo()
        pages.notify("ℹ️ Info diperbarui", nil, 1.6)
    end)

    -- jam & server hidup (hanya jalan saat tab INFO terlihat)
    task.spawn(function()
        while page.Parent do
            task.wait(1)
            if page.Visible then
                tickClock()
                R.players.set(string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers))
                R.server.set(serverText())
                nowCard.sub.Text = string.format("🟢 %d/%d player • %s", #Players:GetPlayers(), Players.MaxPlayers, serverText())
            end
        end
    end)

    loadInfo()
end

xpcall(pages.initInfo, function(e)
    warn("THROW HUB info-tab error: " .. tostring(e))
end)

-- ==================== DETAIL TAMBAHAN: border berkilau, judul berkilau, lampu ON/OFF, animasi ====================
function pages.initV24()
    local TweenService = game:GetService("TweenService")
    local function tw(o, t, props, style, dir, rep, rev)
        local ti = TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false)
        local tween = TweenService:Create(o, ti, props)
        tween:Play()
        return tween
    end

    -- 1. border hub berkilau (cahaya berputar, warnanya ikut tema)
    pcall(function()
        local st = mainFrame:FindFirstChildOfClass("UIStroke")
        if not st then return end
        local g = Instance.new("UIGradient")
        g.Name = "UHShimmer"
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.6),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.6),
        })
        g.Parent = st
        local con = RunService.RenderStepped:Connect(function(dt)
            if mainFrame.Visible then g.Rotation = (g.Rotation + dt * 70) % 360 end
        end)
        table.insert(cleanupFns, function() con:Disconnect() end)
    end)

    -- 2. judul "THROW HUB" berkilau (sapuan cahaya)
    pcall(function()
        for _, c in ipairs(topBar:GetChildren()) do
            if c:IsA("TextLabel") and c.Text == "TheRich🤑" then
                local g = Instance.new("UIGradient")
                g.Name = "UHTitleShine"
                g.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(195, 215, 255)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 215, 255)),
                })
                g.Offset = Vector2.new(-1, 0)
                g.Parent = c
                tw(g, 2.4, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)
                break
            end
        end
    end)

    -- 3. titik ONLINE berdenyut
    pcall(function()
        for _, c in ipairs(topBar:GetChildren()) do
            if c:IsA("Frame") and c.Size == UDim2.new(0, 6, 0, 6) then
                c:SetAttribute("UHNoFade", true)
                c.BackgroundTransparency = 0.1
                tw(c, 0.9, { BackgroundTransparency = 0.7 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            end
        end
    end)

    -- 4. tombol logo 💲 berdenyut halus
    pcall(function()
        local st = logoBtn:FindFirstChildOfClass("UIStroke")
        if st then
            tw(st, 1.1, { Thickness = 3, Transparency = 0.35 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        end
    end)

    -- 5. animasi buka hub: membesar sedikit memantul (pakai UIScale yang sama dengan slider UKURAN)
    pcall(function()
        local ms = mainFrame:FindFirstChild("UHMiniScale")
        if not ms then return end
        local popTween
        mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
            if not mainFrame.Visible then return end
            local V = pages.V20
            local base = (V and V.UI and V.UI.scale) or 1
            if popTween then popTween:Cancel() end
            ms.Scale = base * 0.88
            popTween = tw(ms, 0.22, { Scale = base }, Enum.EasingStyle.Back)
        end)
    end)

    -- 6. transisi antar tab: isi tab naik pelan dari bawah
    for _, pg in pairs(pages) do
        if typeof(pg) == "Instance" and pg:IsA("ScrollingFrame") then
            local base = pg.Position
            pg:GetPropertyChangedSignal("Visible"):Connect(function()
                if pg.Visible then
                    pg.Position = base + UDim2.new(0, 0, 0, 10)
                    tw(pg, 0.18, { Position = base })
                end
            end)
        end
    end

    -- 7. lampu status kecil di kiri tombol toggle (hijau menyala = ON, abu = OFF)
    local function ledFor(btn)
        if not btn.Parent or not btn:IsA("TextButton") or btn:FindFirstChild("BubbleLED") then return end
        if not (string.find(btn.Text, "• ON", 1, true) or string.find(btn.Text, "• OFF", 1, true)) then return end
        local led = Instance.new("Frame")
        led.Name = "BubbleLED"
        led.AnchorPoint = Vector2.new(0, 0.5)
        led.Position = UDim2.new(0, 9, 0.5, 0)
        led.Size = UDim2.new(0, 7, 0, 7)
        led.BorderSizePixel = 0
        led.ZIndex = btn.ZIndex + 2
        led:SetAttribute("UHNoFade", true)
        led.Parent = btn
        corner(led, 4)
        local glow = Instance.new("UIStroke")
        glow.Color = GREEN
        glow.Thickness = 2
        glow.Parent = led
        local function paint()
            local on = string.find(btn.Text, "• ON", 1, true) ~= nil
            led.BackgroundColor3 = on and GREEN or Color3.fromRGB(70, 78, 98)
            glow.Transparency = on and 0.45 or 1
        end
        paint()
        btn:GetPropertyChangedSignal("Text"):Connect(paint)
    end
    for _, pg in pairs(pages) do
        if typeof(pg) == "Instance" and pg:IsA("ScrollingFrame") then
            for _, c in ipairs(pg:GetChildren()) do pcall(ledFor, c) end
            pg.ChildAdded:Connect(function(c) task.defer(function() pcall(ledFor, c) end) end)
        end
    end

    -- 8. (banner atas dihapus: pesan sambutan sekarang pakai pages.notify di tengah layar)
end

xpcall(pages.initV24, function(e)
    warn("THROW HUB v24 error: " .. tostring(e))
end)

-- ==================== DETAIL TAMBAHAN 2: riak sentuh, kilat toggle, notifikasi ON/OFF ====================
function pages.initV28()
    local TweenService = game:GetService("TweenService")
    local ms = mainFrame:FindFirstChild("UHMiniScale")

    local function ripple(btn, input)
        local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
        if size.X < 2 or size.Y < 2 then return end
        local fx = math.clamp((input.Position.X - abs.X) / size.X, 0, 1)
        local fy = math.clamp((input.Position.Y - abs.Y) / size.Y, 0, 1)
        local d = (size.X / ((ms and ms.Scale) or 1)) * 1.5

        local r = Instance.new("Frame")
        r.Name = "BubbleRipple"
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(fx, 0, fy, 0)
        r.Size = UDim2.new(0, 0, 0, 0)
        r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        r.BackgroundTransparency = 0.72
        r.BorderSizePixel = 0
        r.ZIndex = btn.ZIndex + 3
        r:SetAttribute("UHNoFade", true)
        r.Parent = btn
        corner(r, 999)

        local t = TweenService:Create(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, d, 0, d), BackgroundTransparency = 1 })
        t:Play()
        t.Completed:Connect(function() r:Destroy() end)
    end

    local function sweep(btn)
        local sw = Instance.new("Frame")
        sw.Name = "BubbleSweep"
        sw.AnchorPoint = Vector2.new(0, 0.5)
        sw.Position = UDim2.new(-0.4, 0, 0.5, 0)
        sw.Size = UDim2.new(0.4, 0, 1.6, 0)
        sw.Rotation = 15
        sw.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sw.BackgroundTransparency = 0.78
        sw.BorderSizePixel = 0
        sw.ZIndex = btn.ZIndex + 3
        sw:SetAttribute("UHNoFade", true)
        sw.Parent = btn

        local g = Instance.new("UIGradient")
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = sw

        local t = TweenService:Create(sw, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new(1.1, 0, 0.5, 0) })
        t:Play()
        t.Completed:Connect(function() sw:Destroy() end)
    end

    -- (v30) Semua tombol toggle di semua tab: berubah ON/OFF -> muncul notifikasi "<fitur> aktif / nonaktif".
    -- Tidak muncul 5 detik pertama (saat script dimuat), mengikuti pengaturan "Notifikasi toast" di SETTING,
    -- dan kalau banyak yang berubah sekaligus (misal Load Config) diringkas jadi satu notifikasi.
    local NT = pages.NOTIF
    NT.ready = false
    task.delay(5, function() NT.ready = true end)

    local burstN, burstT = 0, 0
    local function toggleNotice(btn, on)
        if not NT.ready then return end
        local V = pages.V20
        if V and V.toastOn == false then return end

        local now = os.clock()
        if now - burstT > 0.4 then burstN = 0 end
        burstT = now
        burstN = burstN + 1
        if burstN == 4 then
            pages.notify("⚙️ Banyak pengaturan berubah sekaligus", nil, 2)
            return
        elseif burstN > 4 then
            return
        end

        local label = btn.Text:match("^(.-)%s*•%s*O[NF]+") or btn.Text
        label = (label:gsub("^[^%w]+", "")) -- buang emoji di depan
        pages.notify((on and "✅ " or "⚪ ") .. label .. (on and " aktif" or " nonaktif"), nil, 2.2)
    end

    local function attach(btn)
        if not btn:IsA("TextButton") or btn:GetAttribute("UHRipple") then return end
        btn:SetAttribute("UHRipple", true)
        btn.ClipsDescendants = true

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                pcall(ripple, btn, input)
            end
        end)

        local wasOn = string.find(btn.Text, "• ON", 1, true) ~= nil
        btn:GetPropertyChangedSignal("Text"):Connect(function()
            local isOn = string.find(btn.Text, "• ON", 1, true) ~= nil
            local isOff = string.find(btn.Text, "• OFF", 1, true) ~= nil
            if isOn and not wasOn then pcall(sweep, btn) end
            if (isOn or isOff) and isOn ~= wasOn then pcall(toggleNotice, btn, isOn) end
            wasOn = isOn
        end)
    end

    for _, pg in pairs(pages) do
        if typeof(pg) == "Instance" and pg:IsA("ScrollingFrame") then
            for _, c in ipairs(pg:GetChildren()) do pcall(attach, c) end
            pg.ChildAdded:Connect(function(c) task.defer(function() pcall(attach, c) end) end)
        end
    end

    for _, b in pairs(tabButtons) do pcall(attach, b) end
end

xpcall(pages.initV28, function(e)
    warn("THROW HUB v28 error: " .. tostring(e))
end)

-- ==================== TEMA (sama seperti Universal: palet, dekorasi, tombol bubble) ====================
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
        -- ===== v21: 12 tema baru =====
        { id = "halloween", name = "Malam Halloween", icon = "🎃",
            sw = { rgb(60, 20, 70), rgb(255, 120, 20), rgb(160, 90, 230) },
            rim = { rgb(255, 150, 50), 0.4 },
            pal = mkPal({ {14,6,20}, {30,14,40}, {52,24,62}, {255,130,30}, {255,120,20}, {80,120,40}, {204,184,206}, {18,8,26},
                {24,10,32}, {62,28,74}, {44,20,56}, {190,90,20}, {140,80,220}, {255,150,50} }) },
        { id = "sky", name = "Langit Cerah", icon = "☁️",
            sw = { rgb(70, 150, 240), rgb(190, 230, 255), rgb(255, 245, 190) },
            rim = { rgb(255, 255, 255), 0.35 },
            pal = mkPal({ {18,40,78}, {30,66,116}, {46,92,152}, {255,255,255}, {120,200,255}, {50,150,110}, {196,218,242}, {22,48,90},
                {26,56,104}, {52,100,166}, {38,80,134}, {70,140,225}, {255,200,90}, {200,232,255} }) },
        { id = "beach", name = "Pantai Tropis", icon = "🏝️",
            sw = { rgb(50, 190, 215), rgb(250, 228, 170), rgb(255, 150, 90) },
            rim = { rgb(255, 240, 190), 0.4 },
            pal = mkPal({ {8,44,56}, {14,72,86}, {24,104,118}, {255,226,150}, {60,210,225}, {60,150,100}, {196,230,230}, {10,52,64},
                {12,60,74}, {26,112,126}, {18,88,102}, {40,170,190}, {255,150,90}, {255,236,170} }) },
        { id = "arcade", name = "Arkade Retro", icon = "🕹️",
            sw = { rgb(30, 8, 64), rgb(255, 64, 200), rgb(0, 230, 255) },
            rim = { rgb(0, 230, 255), 0.35 },
            pal = mkPal({ {6,4,20}, {16,8,44}, {32,14,72}, {0,230,255}, {255,64,200}, {40,150,60}, {190,180,230}, {9,6,26},
                {14,8,38}, {40,18,84}, {28,12,62}, {210,40,160}, {0,190,230}, {255,220,60} }) },
        { id = "icecream", name = "Es Krim", icon = "🍦",
            sw = { rgb(255, 170, 200), rgb(170, 230, 210), rgb(255, 240, 170) },
            rim = { rgb(255, 255, 255), 0.4 },
            pal = mkPal({ {96,44,76}, {128,64,102}, {164,90,132}, {255,214,232}, {255,150,196}, {90,170,140}, {250,226,240}, {106,50,84},
                {112,54,90}, {176,100,142}, {146,78,118}, {240,130,180}, {130,210,190}, {255,200,225} }) },
        { id = "lantern", name = "Lentera Festival", icon = "🏮",
            sw = { rgb(120, 16, 24), rgb(255, 190, 80), rgb(255, 90, 60) },
            rim = { rgb(255, 200, 100), 0.4 },
            pal = mkPal({ {22,5,8}, {50,10,16}, {84,20,28}, {255,196,90}, {240,70,50}, {120,110,40}, {226,196,180}, {28,6,10},
                {34,8,12}, {96,24,32}, {70,16,24}, {200,50,40}, {255,180,60}, {255,210,120} }) },
        { id = "wizard", name = "Penyihir", icon = "🔮",
            sw = { rgb(40, 16, 90), rgb(120, 90, 255), rgb(80, 230, 220) },
            rim = { rgb(170, 140, 255), 0.4 },
            pal = mkPal({ {8,6,26}, {18,12,52}, {34,22,88}, {150,120,255}, {110,80,240}, {40,150,140}, {190,184,236}, {10,8,32},
                {14,10,42}, {42,28,100}, {28,18,74}, {100,70,220}, {80,220,210}, {170,140,255} }) },
        { id = "dino", name = "Zaman Dino", icon = "🦖",
            sw = { rgb(120, 150, 60), rgb(70, 100, 40), rgb(255, 160, 60) },
            rim = { rgb(220, 240, 140), 0.45 },
            pal = mkPal({ {16,26,12}, {30,46,22}, {48,70,34}, {190,220,110}, {150,190,80}, {90,130,50}, {200,214,176}, {20,32,14},
                {24,38,18}, {54,80,38}, {40,62,28}, {120,160,60}, {240,160,60}, {200,230,120} }) },
        { id = "rosegold", name = "Rose Gold", icon = "🌹",
            sw = { rgb(150, 84, 96), rgb(240, 180, 170), rgb(255, 226, 200) },
            rim = { rgb(255, 205, 190), 0.4 },
            pal = mkPal({ {28,14,20}, {58,30,40}, {92,50,62}, {246,196,180}, {226,150,150}, {130,130,80}, {226,196,196}, {34,18,24},
                {44,22,30}, {100,56,68}, {76,40,52}, {190,110,120}, {240,190,150}, {255,215,200} }) },
        { id = "space", name = "Astronot", icon = "🚀",
            sw = { rgb(4, 6, 24), rgb(70, 110, 255), rgb(255, 140, 70) },
            rim = { rgb(160, 190, 255), 0.45 },
            pal = mkPal({ {3,5,18}, {8,12,40}, {16,24,70}, {120,160,255}, {70,110,255}, {50,140,110}, {170,182,224}, {5,8,26},
                {6,10,32}, {20,30,82}, {12,20,58}, {50,90,230}, {255,140,70}, {150,180,255} }) },
        { id = "bamboo", name = "Hutan Bambu", icon = "🎋",
            sw = { rgb(190, 225, 150), rgb(80, 140, 80), rgb(24, 60, 40) },
            rim = { rgb(220, 250, 180), 0.45 },
            pal = mkPal({ {12,30,20}, {22,54,36}, {36,82,54}, {190,236,150}, {120,200,100}, {70,140,70}, {196,222,196}, {14,36,24},
                {18,44,30}, {40,90,58}, {30,68,44}, {90,160,80}, {230,210,120}, {200,240,160} }) },
        { id = "carnival", name = "Karnaval", icon = "🎪",
            sw = { rgb(70, 20, 100), rgb(255, 80, 120), rgb(255, 220, 70) },
            rim = { rgb(255, 220, 100), 0.4 },
            pal = mkPal({ {16,6,36}, {36,14,70}, {62,24,106}, {255,214,80}, {255,80,130}, {60,160,110}, {214,190,236}, {20,8,44},
                {28,10,56}, {70,28,118}, {50,20,90}, {220,60,110}, {80,200,240}, {255,225,110} }) },
        -- ===== v28: 10 tema baru =====
        { id = "sakuranight", name = "Sakura Malam", icon = "🏯",
            sw = { rgb(40, 18, 60), rgb(240, 120, 170), rgb(255, 210, 225) },
            rim = { rgb(255, 170, 200), 0.4 },
            pal = mkPal({ {16,8,22}, {32,16,44}, {54,28,70}, {255,150,190}, {240,120,170}, {70,130,90}, {214,190,210}, {20,10,28},
                {26,12,36}, {58,30,76}, {44,22,60}, {200,90,140}, {255,200,120}, {255,170,200} }) },
        { id = "dragon", name = "Naga Emas", icon = "🐉",
            sw = { rgb(60, 10, 10), rgb(230, 60, 40), rgb(255, 200, 80) },
            rim = { rgb(255, 200, 90), 0.45 },
            pal = mkPal({ {18,4,4}, {40,10,10}, {72,18,16}, {255,190,70}, {230,60,40}, {110,120,40}, {222,190,170}, {22,5,5},
                {30,6,6}, {84,20,18}, {62,14,14}, {190,40,30}, {255,190,70}, {255,200,90} }) },
        { id = "crystal", name = "Kristal", icon = "💎",
            sw = { rgb(10, 30, 70), rgb(90, 190, 255), rgb(220, 160, 255) },
            rim = { rgb(170, 240, 255), 0.4 },
            pal = mkPal({ {6,12,28}, {12,26,52}, {20,44,84}, {130,230,255}, {90,190,255}, {40,140,150}, {176,208,230}, {8,16,36},
                {8,18,40}, {22,50,92}, {16,38,72}, {70,140,230}, {190,140,255}, {150,230,255} }) },
        { id = "pirate", name = "Bajak Laut", icon = "🏴",
            sw = { rgb(16, 40, 44), rgb(200, 150, 70), rgb(110, 200, 200) },
            rim = { rgb(230, 190, 110), 0.45 },
            pal = mkPal({ {10,16,18}, {20,34,38}, {34,56,60}, {220,170,90}, {200,150,70}, {60,120,80}, {190,200,190}, {12,20,22},
                {14,24,26}, {40,64,68}, {30,50,54}, {150,100,50}, {230,190,110}, {230,190,110} }) },
        { id = "mushroom", name = "Hutan Jamur", icon = "🍄",
            sw = { rgb(20, 14, 60), rgb(255, 90, 200), rgb(90, 255, 220) },
            rim = { rgb(120, 255, 230), 0.4 },
            pal = mkPal({ {8,6,22}, {16,12,44}, {28,22,72}, {90,255,220}, {255,90,200}, {40,150,110}, {190,176,230}, {10,8,28},
                {10,8,30}, {30,24,80}, {22,18,60}, {200,60,170}, {90,240,210}, {120,255,230} }) },
        { id = "winterfest", name = "Natal Salju", icon = "🎄",
            sw = { rgb(14, 50, 30), rgb(220, 60, 60), rgb(255, 220, 110) },
            rim = { rgb(255, 140, 140), 0.45 },
            pal = mkPal({ {8,24,16}, {14,44,28}, {22,68,42}, {255,90,90}, {220,60,60}, {60,150,80}, {206,226,206}, {10,30,20},
                {12,36,24}, {30,80,52}, {22,62,40}, {190,50,50}, {255,210,90}, {255,120,120} }) },
        { id = "coffee", name = "Kopi Senja", icon = "☕",
            sw = { rgb(50, 32, 24), rgb(206, 150, 96), rgb(250, 226, 190) },
            rim = { rgb(240, 206, 160), 0.4 },
            pal = mkPal({ {24,14,10}, {48,30,22}, {80,54,40}, {226,184,130}, {206,150,96}, {110,130,70}, {220,200,180}, {28,17,12},
                {32,20,15}, {88,60,44}, {68,46,34}, {160,110,70}, {240,210,160}, {232,196,150} }) },
        { id = "garden", name = "Kebun Bunga", icon = "🌻",
            sw = { rgb(24, 70, 36), rgb(255, 200, 60), rgb(255, 140, 170) },
            rim = { rgb(255, 226, 110), 0.45 },
            pal = mkPal({ {12,34,18}, {20,58,30}, {32,88,46}, {255,214,70}, {255,190,50}, {70,160,70}, {206,230,200}, {14,40,22},
                {18,48,26}, {40,104,56}, {30,82,44}, {120,190,70}, {255,130,160}, {255,226,110} }) },
        { id = "dream", name = "Awan Mimpi", icon = "🌙",
            sw = { rgb(50, 36, 100), rgb(180, 150, 255), rgb(255, 200, 230) },
            rim = { rgb(230, 210, 255), 0.4 },
            pal = mkPal({ {22,14,46}, {40,28,82}, {64,48,116}, {210,180,255}, {180,150,255}, {90,150,150}, {212,204,240}, {26,17,54},
                {30,20,62}, {76,58,132}, {58,44,104}, {150,120,240}, {255,190,220}, {220,196,255} }) },
        { id = "toxic", name = "Radioaktif", icon = "☢️",
            sw = { rgb(10, 30, 10), rgb(110, 230, 40), rgb(255, 230, 50) },
            rim = { rgb(170, 255, 80), 0.4 },
            pal = mkPal({ {4,10,4}, {10,24,10}, {18,44,16}, {150,255,60}, {110,230,40}, {50,150,40}, {176,210,160}, {6,14,6},
                {8,18,8}, {22,56,20}, {16,42,14}, {70,170,30}, {255,230,40}, {170,255,80} }) },
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

    -- ==================== v21: 12 TEMA BARU (dekorasi) ====================
    -- emoji melintas horizontal (back=true: dari kanan ke kiri), sedikit naik-turun
    build._drift = function(glyph, size, y0, sp, ph, back, bob, tr)
        local f = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1, Text = glyph, TextSize = size, TextTransparency = tr or 0.15 })
        table.insert(anims, function(t)
            local p = (t * sp + ph) % 1.3
            if back then p = 1.15 - p else p = p - 0.15 end
            f.Position = UDim2.new(p, 0, y0 + math.sin(t * 1.3 + ph) * (bob or 0.02), 0)
        end)
        return f
    end

    -- emoji diam di pojok bawah (opsional goyang)
    build._corner = function(glyph, size, right)
        local f = mk("TextLabel", { AnchorPoint = Vector2.new(right and 1 or 0, 1),
            Position = UDim2.new(right and 1 or 0, right and -8 or 8, 1, -4), Size = UDim2.new(0, size + 10, 0, size + 10),
            BackgroundTransparency = 1, Text = glyph, TextSize = size, TextTransparency = 0.25 })
        table.insert(anims, function(t) f.Rotation = math.sin(t * 1.1) * 4 end)
        return f
    end

    -- deretan lampu kecil berkedip di atas
    build._bulbs = function(n, cols, y)
        for i = 1, n do
            local c = circle((i - 0.5) / n, y, 7, cols[(i - 1) % #cols + 1], 0.1)
            local ph = i * 0.9
            table.insert(anims, function(t) c.BackgroundTransparency = 0.1 + (math.sin(t * 3 + ph) * 0.5 + 0.5) * 0.6 end)
        end
    end

    -- 1) MALAM HALLOWEEN
    build.halloween = function()
        setBase(90, { { 0, rgb(70, 24, 84) }, { 0.5, rgb(30, 10, 40) }, { 1, rgb(10, 4, 14) } })
        stars(30, 91, 2, 0.6)
        blob(0.82, 0.12, 150, rgb(255, 210, 120), 7)
        build._particles(9, 92, { glyph = { "🦇", "🦇", "🕸️" }, s1 = 14, s2 = 22, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.08, swf = 1.1, tr = 0.25 })
        build._particles(7, 93, { glyph = { "👻" }, s1 = 16, s2 = 24, dir = -1, sp1 = 0.03, sp2 = 0.06, sway = 0.05, swf = 0.8, tr = 0.45 })
        build._particles(14, 94, { s1 = 2, s2 = 4, color = rgb(255, 140, 30), tr = 0.35, dir = -1, sp1 = 0.04, sp2 = 0.09, sway = 0.03, swf = 1.6 })
        build._corner("🎃", 46, false)
        build._corner("🕯️", 30, true)
    end

    -- 2) LANGIT CERAH
    build.sky = function()
        setBase(90, { { 0, rgb(70, 150, 240) }, { 0.6, rgb(140, 200, 250) }, { 1, rgb(215, 238, 255) } })
        blob(0.85, 0.1, 150, rgb(255, 245, 190), 7)
        for i = 1, 5 do build._drift("☁️", 30 + i * 7, 0.08 + i * 0.17, 0.012 + i * 0.004, i * 1.9, false, 0.01, 0.1) end
        build._drift("🕊️", 20, 0.3, 0.05, 2, false, 0.04, 0.2)
        build._drift("🎈", 26, 0.78, 0.025, 4, false, 0.03, 0.2)
        build._particles(10, 95, { s1 = 2, s2 = 4, color = rgb(255, 255, 255), tr = 0.4, dir = -1, sp1 = 0.03, sp2 = 0.06, sway = 0.03, swf = 1.2 })
    end

    -- 3) PANTAI TROPIS
    build.beach = function()
        setBase(90, { { 0, rgb(50, 190, 215) }, { 0.7, rgb(120, 225, 225) }, { 1, rgb(250, 228, 170) } })
        blob(0.15, 0.1, 150, rgb(255, 240, 160), 7)
        mk("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = rgb(244, 218, 160), BackgroundTransparency = 0.1, BorderSizePixel = 0 })
        for i = 1, 3 do
            local w = mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24 - i * 9),
                Size = UDim2.new(1.4, 0, 0, 16), BackgroundColor3 = rgb(255, 255, 255),
                BackgroundTransparency = 0.5 + i * 0.1, BorderSizePixel = 0 })
            mk("UICorner", { CornerRadius = UDim.new(0.5, 0) }, w)
            local ph = i * 1.3
            table.insert(anims, function(t) w.Position = UDim2.new(0.5 + math.sin(t * 0.7 + ph) * 0.08, 0, 1, -24 - i * 9) end)
        end
        build._particles(10, 96, { s1 = 4, s2 = 9, color = rgb(255, 255, 255), tr = 0.6, dir = -1, sp1 = 0.04, sp2 = 0.09, sway = 0.03, swf = 1.3 })
        build._drift("🦀", 20, 0.93, 0.03, 1, false, 0.005, 0.1)
        build._drift("🐚", 16, 0.95, 0.02, 3, true, 0.003, 0.1)
        build._corner("🌴", 50, true)
    end

    -- 4) ARKADE RETRO
    build.arcade = function()
        setBase(90, { { 0, rgb(30, 8, 64) }, { 0.55, rgb(14, 6, 38) }, { 1, rgb(6, 4, 20) } })
        for i = 1, 8 do
            mk("Frame", { Position = UDim2.new(i / 9, 0, 0, 0), Size = UDim2.new(0, 1, 1, 0),
                BackgroundColor3 = rgb(0, 230, 255), BackgroundTransparency = 0.88, BorderSizePixel = 0 })
        end
        local lines = {}
        for i = 0, 9 do
            lines[i] = mk("Frame", { Position = UDim2.new(0, 0, i / 10, 0), Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = rgb(255, 64, 200), BackgroundTransparency = 0.75, BorderSizePixel = 0 })
        end
        table.insert(anims, function(t)
            for i = 0, 9 do lines[i].Position = UDim2.new(0, 0, ((i + t * 0.4) % 10) / 10, 0) end
        end)
        stars(26, 97, 3, 0.8)
        build._drift("👾", 22, 0.18, 0.05, 0.5, false, 0.03, 0.15)
        build._drift("👾", 18, 0.42, 0.035, 2.4, true, 0.03, 0.2)
        build._corner("🕹️", 44, true)
    end

    -- 5) ES KRIM
    build.icecream = function()
        setBase(90, { { 0, rgb(255, 170, 200) }, { 0.5, rgb(200, 150, 220) }, { 1, rgb(150, 220, 205) } })
        blob(0.85, 0.12, 160, rgb(255, 245, 200), 6)
        blob(0.1, 0.9, 170, rgb(255, 255, 255), 5)
        build._particles(10, 98, { glyph = { "🍦", "🍧", "🍨", "🍓" }, s1 = 16, s2 = 26, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.05, swf = 0.9, rot = 20, tr = 0.3 })
        local cols = { rgb(255, 90, 140), rgb(255, 230, 90), rgb(110, 210, 255), rgb(150, 255, 170) }
        for i, c in ipairs(cols) do
            build._particles(6, 98 + i, { rect = true, w = 3, s1 = 6, s2 = 10, color = c, tr = 0.2, dir = 1, sp1 = 0.04, sp2 = 0.1, sway = 0.03, swf = 1.2, angle = 30, rot = 60 })
        end
        build._corner("🍦", 46, true)
    end

    -- 6) LENTERA FESTIVAL
    build.lantern = function()
        setBase(90, { { 0, rgb(120, 16, 24) }, { 0.5, rgb(60, 8, 16) }, { 1, rgb(20, 4, 8) } })
        blob(0.5, 0.05, 200, rgb(255, 190, 80), 6)
        build._bulbs(14, { rgb(255, 210, 90), rgb(255, 90, 70) }, 0.012)
        build._particles(8, 107, { glyph = { "🏮" }, s1 = 20, s2 = 34, dir = -1, sp1 = 0.03, sp2 = 0.07, sway = 0.05, swf = 0.9, tr = 0.2 })
        build._particles(18, 108, { s1 = 2, s2 = 4, color = rgb(255, 210, 100), tr = 0.3, dir = -1, sp1 = 0.05, sp2 = 0.12, sway = 0.03, swf = 1.8 })
        build._particles(8, 109, { glyph = { "✨" }, s1 = 10, s2 = 16, dir = 1, sp1 = 0.03, sp2 = 0.06, sway = 0.04, swf = 1.4, tr = 0.35 })
    end

    -- 7) PENYIHIR
    build.wizard = function()
        setBase(90, { { 0, rgb(50, 20, 110) }, { 0.55, rgb(20, 14, 64) }, { 1, rgb(6, 10, 36) } })
        stars(34, 117, 3, 0.7)
        blob(0.2, 0.18, 150, rgb(120, 90, 255), 6)
        blob(0.85, 0.85, 170, rgb(70, 220, 210), 6)
        build._particles(10, 118, { glyph = { "✨", "⭐", "🔮", "🌙" }, s1 = 12, s2 = 20, dir = -1, sp1 = 0.03, sp2 = 0.07, sway = 0.05, swf = 1.1, rot = 25, tr = 0.3 })
        build._particles(14, 119, { s1 = 2, s2 = 4, color = rgb(190, 160, 255), tr = 0.3, dir = -1, sp1 = 0.04, sp2 = 0.1, sway = 0.03, swf = 1.6 })
        build._drift("🦉", 22, 0.22, 0.03, 1.5, true, 0.04, 0.2)
        build._corner("🔮", 46, true)
    end

    -- 8) ZAMAN DINO
    build.dino = function()
        setBase(90, { { 0, rgb(130, 160, 70) }, { 0.5, rgb(66, 98, 42) }, { 1, rgb(26, 38, 20) } })
        blob(0.85, 0.1, 160, rgb(255, 170, 70), 7)
        for i = 0, 7 do
            local f = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new((i + 0.5) / 8, 0, 1, 2),
                Size = UDim2.new(0, 34, 0, 34), BackgroundTransparency = 1, Text = "🌿", TextSize = 30, TextTransparency = 0.15 })
            local ph = i * 0.8
            table.insert(anims, function(t) f.Rotation = math.sin(t * 0.9 + ph) * 6 end)
        end
        build._particles(12, 127, { s1 = 3, s2 = 6, color = rgb(70, 66, 60), tr = 0.45, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.04, swf = 1.1 })
        build._drift("🦖", 34, 0.9, 0.018, 1, false, 0.005, 0.1)
        build._drift("🦕", 30, 0.28, 0.012, 3, true, 0.01, 0.2)
        build._drift("☄️", 20, 0.1, 0.03, 5, false, 0.0, 0.2)
    end

    -- 9) ROSE GOLD
    build.rosegold = function()
        setBase(135, { { 0, rgb(150, 84, 96) }, { 0.5, rgb(86, 44, 56) }, { 1, rgb(40, 20, 28) } })
        blob(0.9, 0.1, 170, rgb(255, 200, 190), 6)
        blob(0.08, 0.92, 160, rgb(240, 170, 150), 6)
        for i = 1, 14 do
            mk("Frame", { Position = UDim2.new(0, 0, i / 15, 0), Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = rgb(255, 214, 200), BackgroundTransparency = 0.95, BorderSizePixel = 0 })
        end
        local sheen = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.3, 0, 0.5, 0),
            Size = UDim2.new(0, 70, 0, 520), Rotation = 24, BackgroundColor3 = rgb(255, 226, 210), BackgroundTransparency = 0.78, BorderSizePixel = 0 })
        ugrad(sheen, 0, nil, { { 0, 1 }, { 0.5, 0 }, { 1, 1 } })
        table.insert(anims, function(t) sheen.Position = UDim2.new(-0.3 + ((t % 9) / 9) * 1.6, 0, 0.5, 0) end)
        build._particles(10, 137, { glyph = { "🌹", "🌸", "🌹" }, s1 = 12, s2 = 20, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.06, swf = 1, rot = 40, tr = 0.3 })
        build._particles(14, 138, { s1 = 2, s2 = 4, color = rgb(255, 226, 190), tr = 0.35, dir = -1, sp1 = 0.03, sp2 = 0.08, sway = 0.03, swf = 1.5 })
    end

    -- 10) ASTRONOT
    build.space = function()
        setBase(90, { { 0, rgb(14, 18, 64) }, { 0.55, rgb(6, 8, 32) }, { 1, rgb(2, 3, 14) } })
        stars(46, 147, 3, 1)
        blob(0.82, 0.2, 120, rgb(255, 150, 80), 7)
        circle(0.82, 0.2, 54, rgb(230, 130, 70), 0.05)
        blob(0.12, 0.78, 110, rgb(90, 150, 255), 7)
        circle(0.12, 0.78, 40, rgb(80, 140, 235), 0.05)
        build._particles(6, 148, { rect = true, w = 2, s1 = 18, s2 = 34, color = rgb(255, 255, 255), tr = 0.35, dir = 1, sp1 = 0.2, sp2 = 0.4, sway = 0, drift = 0.15, angle = 20 })
        local rk = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 34, 0, 34),
            BackgroundTransparency = 1, Text = "🚀", TextSize = 30, Rotation = 45 })
        table.insert(anims, function(t)
            local p = (t * 0.05) % 1.4 - 0.2
            rk.Position = UDim2.new(p, 0, 1 - p, 0)
        end)
        build._drift("🛰️", 24, 0.5, 0.02, 2, true, 0.06, 0.2)
        build._drift("🛸", 22, 0.3, 0.03, 4, false, 0.04, 0.2)
    end

    -- 11) HUTAN BAMBU
    build.bamboo = function()
        setBase(90, { { 0, rgb(190, 225, 150) }, { 0.45, rgb(80, 140, 80) }, { 1, rgb(24, 60, 40) } })
        beams(3, rgb(255, 255, 210), 0.1, -14)
        local rnd = Random.new(157)
        for i = 0, 8 do
            local x = (i + 0.5) / 9 + rnd:NextNumber(-0.02, 0.02)
            local w = rnd:NextInteger(9, 14)
            local stem = mk("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(x, 0, 1.02, 0),
                Size = UDim2.new(0, w, 1.05, 0), BackgroundColor3 = rgb(96 + i * 6, 170, 90), BackgroundTransparency = 0.2, BorderSizePixel = 0 })
            for j = 1, 7 do
                mk("Frame", { Position = UDim2.new(0, -1, j / 8, 0), Size = UDim2.new(1, 2, 0, 3),
                    BackgroundColor3 = rgb(40, 100, 50), BackgroundTransparency = 0.2, BorderSizePixel = 0 }, stem)
            end
            local ph = rnd:NextNumber(0, 6)
            table.insert(anims, function(t) stem.Rotation = math.sin(t * 0.6 + ph) * 1.6 end)
        end
        build._particles(10, 158, { glyph = { "🍃", "🌿" }, s1 = 12, s2 = 20, dir = 1, sp1 = 0.03, sp2 = 0.08, sway = 0.06, swf = 1, rot = 40, tr = 0.3 })
        build._corner("🐼", 46, true)
    end

    -- 12) KARNAVAL
    build.carnival = function()
        setBase(90, { { 0, rgb(90, 26, 120) }, { 0.5, rgb(40, 14, 76) }, { 1, rgb(14, 6, 36) } })
        blob(0.5, 0.0, 220, rgb(255, 200, 90), 6)
        build._bulbs(14, { rgb(255, 80, 120), rgb(255, 220, 70), rgb(90, 210, 255) }, 0.014)
        build._particles(8, 167, { glyph = { "🎈" }, s1 = 20, s2 = 32, dir = -1, sp1 = 0.03, sp2 = 0.07, sway = 0.05, swf = 0.9, tr = 0.2 })
        local cols = { rgb(255, 80, 120), rgb(255, 220, 70), rgb(90, 210, 255) }
        for i, c in ipairs(cols) do
            build._particles(6, 167 + i, { rect = true, w = 3, s1 = 6, s2 = 10, color = c, tr = 0.15, dir = 1, sp1 = 0.05, sp2 = 0.12, sway = 0.03, swf = 1.2, angle = 25, rot = 80 })
        end
        build._drift("🎠", 28, 0.9, 0.02, 2, false, 0.005, 0.15)
        build._corner("🎪", 46, true)
    end

    -- ===== v28: efek 10 tema baru =====
    build.sakuranight = function()
        setBase(90, { { 0, rgb(70, 24, 96) }, { 0.55, rgb(34, 14, 54) }, { 1, rgb(14, 6, 24) } })
        stars(26, 311, 2, 0.5)
        blob(0.8, 0.14, 150, rgb(255, 220, 235), 7)
        build._particles(14, 312, { glyph = { "🌸", "🌸", "💮" }, s1 = 12, s2 = 20, dir = 1, sp1 = 0.03, sp2 = 0.07, sway = 0.07, swf = 1.2, tr = 0.2, drift = -0.1, rot = 40 })
        build._drift("🏮", 22, 0.25, 0.02, 1, false, 0.03, 0.2)
        build._corner("🏯", 44, true)
    end

    build.dragon = function()
        setBase(90, { { 0, rgb(96, 14, 12) }, { 0.5, rgb(44, 8, 8) }, { 1, rgb(16, 3, 4) } })
        blob(0.5, 0.0, 220, rgb(255, 160, 60), 6)
        build._bulbs(12, { rgb(255, 200, 70), rgb(255, 90, 50) }, 0.014)
        build._particles(18, 321, { s1 = 2, s2 = 4, color = rgb(255, 150, 40), tr = 0.3, dir = -1, sp1 = 0.05, sp2 = 0.12, sway = 0.03, swf = 1.6 })
        build._drift("🐉", 34, 0.7, 0.025, 2, false, 0.03, 0.2)
        build._corner("🏮", 34, false)
    end

    build.crystal = function()
        setBase(90, { { 0, rgb(24, 60, 120) }, { 0.5, rgb(10, 28, 62) }, { 1, rgb(4, 10, 26) } })
        stars(30, 331, 2, 0.7)
        beams(3, rgb(150, 230, 255), 0.05, 18)
        build._particles(12, 332, { glyph = { "💎", "✨", "❄️" }, s1 = 10, s2 = 18, dir = -1, sp1 = 0.02, sp2 = 0.05, sway = 0.04, swf = 1.0, tr = 0.3, rot = 20 })
        build._corner("💎", 40, true)
    end

    build.pirate = function()
        setBase(90, { { 0, rgb(18, 50, 56) }, { 0.6, rgb(10, 28, 32) }, { 1, rgb(4, 12, 14) } })
        stars(18, 341, 2, 0.4)
        blob(0.2, 0.1, 120, rgb(255, 230, 170), 6)
        build._drift("⛵", 28, 0.62, 0.02, 1, false, 0.02, 0.15)
        build._drift("🦜", 20, 0.25, 0.04, 3, true, 0.05, 0.2)
        build._particles(10, 342, { s1 = 3, s2 = 6, color = rgb(150, 220, 230), tr = 0.5, dir = -1, sp1 = 0.03, sp2 = 0.07, sway = 0.03, swf = 1.4 })
        build._corner("☠️", 36, true)
        build._corner("⚓", 30, false)
    end

    build.mushroom = function()
        setBase(90, { { 0, rgb(36, 16, 90) }, { 0.55, rgb(14, 10, 44) }, { 1, rgb(6, 4, 20) } })
        stars(20, 351, 2, 0.5)
        blob(0.2, 0.9, 170, rgb(90, 255, 220), 6)
        blob(0.85, 0.85, 150, rgb(255, 90, 200), 6)
        build._particles(16, 352, { s1 = 2, s2 = 5, color = rgb(120, 255, 230), tr = 0.25, dir = -1, sp1 = 0.03, sp2 = 0.08, sway = 0.05, swf = 1.3 })
        build._particles(8, 353, { glyph = { "🍄" }, s1 = 14, s2 = 20, dir = -1, sp1 = 0.02, sp2 = 0.04, sway = 0.05, swf = 0.9, tr = 0.35 })
        build._corner("🍄", 40, false)
    end

    build.winterfest = function()
        setBase(90, { { 0, rgb(20, 76, 46) }, { 0.55, rgb(10, 40, 26) }, { 1, rgb(4, 16, 10) } })
        stars(22, 361, 2, 0.5)
        build._bulbs(14, { rgb(255, 80, 80), rgb(255, 220, 80), rgb(100, 230, 120), rgb(120, 190, 255) }, 0.014)
        build._particles(22, 362, { s1 = 2, s2 = 5, color = rgb(255, 255, 255), tr = 0.2, dir = 1, sp1 = 0.04, sp2 = 0.1, sway = 0.04, swf = 1.0 })
        build._particles(5, 363, { glyph = { "🎁", "⭐" }, s1 = 16, s2 = 22, dir = 1, sp1 = 0.02, sp2 = 0.04, sway = 0.05, swf = 0.8, tr = 0.3, rot = 30 })
        build._corner("🎄", 46, true)
        build._drift("🦌", 24, 0.8, 0.02, 2, false, 0.01, 0.2)
    end

    build.coffee = function()
        setBase(90, { { 0, rgb(96, 60, 40) }, { 0.55, rgb(48, 28, 20) }, { 1, rgb(20, 11, 8) } })
        blob(0.5, 0.15, 200, rgb(255, 200, 130), 6)
        build._particles(10, 371, { s1 = 3, s2 = 6, color = rgb(255, 226, 190), tr = 0.55, dir = -1, sp1 = 0.03, sp2 = 0.06, sway = 0.05, swf = 1.1 })
        build._particles(6, 372, { glyph = { "☁️" }, s1 = 16, s2 = 24, dir = -1, sp1 = 0.015, sp2 = 0.03, sway = 0.04, swf = 0.7, tr = 0.65 })
        build._corner("☕", 42, true)
        build._corner("🥐", 30, false)
    end

    build.garden = function()
        setBase(90, { { 0, rgb(120, 210, 120) }, { 0.55, rgb(50, 140, 70) }, { 1, rgb(14, 50, 28) } })
        blob(0.85, 0.08, 150, rgb(255, 244, 170), 7)
        build._drift("🦋", 20, 0.3, 0.05, 1, false, 0.05, 0.15)
        build._drift("🐝", 18, 0.55, 0.06, 3, true, 0.04, 0.15)
        build._particles(10, 381, { glyph = { "🌼", "🌸", "🍃" }, s1 = 12, s2 = 20, dir = 1, sp1 = 0.02, sp2 = 0.05, sway = 0.06, swf = 1.0, tr = 0.25, rot = 30 })
        build._corner("🌻", 44, true)
        build._corner("🌷", 34, false)
    end

    build.dream = function()
        setBase(90, { { 0, rgb(120, 90, 210) }, { 0.55, rgb(60, 40, 130) }, { 1, rgb(24, 14, 60) } })
        stars(36, 391, 2, 0.8)
        blob(0.2, 0.12, 140, rgb(255, 230, 250), 7)
        for i = 1, 4 do
            build._drift("☁️", 26 + i * 6, 0.12 + i * 0.2, 0.01 + i * 0.004, i * 2.1, false, 0.01, 0.2)
        end
        build._particles(8, 392, { glyph = { "⭐", "✨", "🌙" }, s1 = 10, s2 = 16, dir = -1, sp1 = 0.02, sp2 = 0.05, sway = 0.05, swf = 1.0, tr = 0.3, rot = 25 })
        build._corner("🌙", 40, true)
    end

    build.toxic = function()
        setBase(90, { { 0, rgb(30, 70, 10) }, { 0.5, rgb(12, 30, 8) }, { 1, rgb(3, 8, 3) } })
        blob(0.5, 1.0, 230, rgb(140, 255, 60), 6)
        build._bulbs(10, { rgb(150, 255, 60), rgb(255, 230, 40) }, 0.014)
        build._particles(18, 401, { s1 = 3, s2 = 8, color = rgb(150, 255, 60), tr = 0.45, dir = -1, sp1 = 0.03, sp2 = 0.09, sway = 0.04, swf = 1.4 })
        build._drift("☣️", 24, 0.35, 0.025, 1, false, 0.03, 0.25)
        build._corner("☢️", 44, true)
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

    -- (v29) Dulu: semua objek UI diperiksa sekaligus dalam 1 frame (5 pcall + closure per objek) -> game membeku
    -- beberapa detik saat tema ditekan. Sekarang: periksa properti warna sesuai kelasnya saja (tanpa pcall/closure)
    -- dan dikerjakan bertahap (±6 ms per frame), jadi game tetap jalan mulus. Tekan tema lagi saat masih jalan -> diantre.
    local CP = {
        Frame = { "BackgroundColor3" },
        CanvasGroup = { "BackgroundColor3" },
        TextLabel = { "BackgroundColor3", "TextColor3" },
        TextButton = { "BackgroundColor3", "TextColor3" },
        TextBox = { "BackgroundColor3", "TextColor3", "PlaceholderColor3" },
        ImageLabel = { "BackgroundColor3", "ImageColor3" },
        ImageButton = { "BackgroundColor3", "ImageColor3" },
        ScrollingFrame = { "BackgroundColor3", "ScrollBarImageColor3" },
        UIStroke = { "Color" },
    }

    local uiPal = cur -- palet yang sudah terpasang penuh di UI
    local recolorBusy, recolorPending = false, nil

    local function recolorTo(th)
        if recolorBusy then
            recolorPending = th -- hanya tema terakhir yang diantre
            return
        end
        recolorBusy = true

        local old, new = uiPal, th.pal
        local map = {}
        for _, r in ipairs(ROLES) do map[keyOf(old[r])] = new[r] end

        local skip = { [fxRoot] = true }
        for _, o in ipairs(fxRoot:GetDescendants()) do skip[o] = true end
        local list = screenGui:GetDescendants()

        task.spawn(function()
            local i, n = 1, #list
            while i <= n do
                local t0 = os.clock()
                while i <= n and os.clock() - t0 < 0.006 do
                    local o = list[i]
                    i = i + 1
                    if o.Parent and not skip[o] then
                        local props = CP[o.ClassName]
                        if props then
                            for k = 1, #props do
                                local p = props[k]
                                local nv = map[keyOf(o[p])]
                                if nv then o[p] = nv end
                            end
                            if o.Name == "BubbleRim" and o.ClassName == "UIStroke" then
                                o.Color = th.rim[1]
                                o.Transparency = th.rim[2]
                            end
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end

            uiPal = new
            recolorBusy = false
            if recolorPending then
                local nxt = recolorPending
                recolorPending = nil
                recolorTo(nxt)
            end
        end)
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
        cur = th.pal
        curId = id
        setPalette(th.pal)

        for i = #anims, 1, -1 do anims[i] = nil end
        deco:ClearAllChildren()
        if id == "default" then
            fxRoot.Visible = false
            bgImage.Visible = true
        else
            bgImage.Visible = false
            fxRoot.Visible = true
            local ok, err = pcall(build[id])
            if not ok then warn("THROW HUB tema " .. id .. ": " .. tostring(err)) end
        end

        -- warna UI diganti bertahap di latar (tidak membekukan game)
        recolorTo(th)
        markActive()
        task.spawn(function() pcall(function() writefile("ThrowHub_theme.txt", id) end) end)
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
        b.MouseButton1Click:Connect(function()
            applyTheme(th.id)
            pages.notify("🎨 Tema: " .. th.name, nil, 1.6)
        end)
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
        if isfile and isfile("ThrowHub_theme.txt") then saved = readfile("ThrowHub_theme.txt") end
    end)
    if saved and byId[saved] and saved ~= "default" then applyTheme(saved) end
end

task.spawn(function()
    local okT, errT = pcall(pages.initTheme)
    if not okT then warn("THROW HUB tema error: " .. tostring(errT)) end
end)

pcall(function()
    pages.notify("🎯 TheRich🤑 v1.3 siap • halo, " .. player.DisplayName, "ok", 3)
end)
print("✅ THROW HUB Loaded!")


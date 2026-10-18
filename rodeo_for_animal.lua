--[[
    RODEO FOR ANIMAL  •  SORU HUB
    UI gaya UniversalHub (panel gelap, border biru, tab di atas) tapi LEBAR (landscape), bukan tinggi.
    Fitur: Auto Catch, Auto Base, Auto x2 (treadmill), Animal ESP, Info game, dan tab TEMA (ganti background UI).
    Script ini berdiri sendiri (tidak perlu SORU_Window / UI.lua).
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Http = game:GetService("HttpService")
local Market = game:GetService("MarketplaceService")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local rgb = Color3.fromRGB
local WHITE = rgb(255, 255, 255)
local GREEN, RED, YELLOW = rgb(80, 220, 120), rgb(255, 80, 80), rgb(250, 204, 21)
local FONT = Enum.Font

do
    local o = playerGui:FindFirstChild("RodeoHubGui")
    if o then o:Destroy() end
end

----------------------------------------------------------------------
-- STATE + SIMPAN TEMA
----------------------------------------------------------------------
local S = {
    autoCatch = false, autoBase = false, baseMode = "Tween", baseSpeed = 25,
    autoX2 = false, esp = false, espFilter = 0,
    pt = 0.35, anim = true, theme = "default", img = "134262192520482",
}
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local SAVE = "RodeoHub_theme.json"
pcall(function()
    if isfile and isfile(SAVE) then
        local d = Http:JSONDecode(readfile(SAVE))
        if type(d) == "table" then
            if type(d.theme) == "string" then S.theme = d.theme end
            if type(d.pt) == "number" then S.pt = math.clamp(d.pt, 0, 0.85) end
            if type(d.anim) == "boolean" then S.anim = d.anim end
            if type(d.img) == "string" and d.img ~= "" then S.img = d.img end
        end
    end
end)
local function save()
    pcall(function()
        if writefile then
            writefile(SAVE, Http:JSONEncode({ theme = S.theme, pt = S.pt, anim = S.anim, img = S.img }))
        end
    end)
end

----------------------------------------------------------------------
-- DAFTAR TEMA
-- palet: black, dark, btn, border, accent, on, grey
----------------------------------------------------------------------
local ROLES = { "black", "dark", "btn", "border", "accent", "on", "grey" }
local function mkPal(arr)
    local t = {}
    for i, k in ipairs(ROLES) do
        local c = arr[i]
        t[k] = rgb(c[1], c[2], c[3])
    end
    return t
end

local THEMES, byId = {}, {}
local function T(id, name, icon, p, g, deco, dcol, photo)
    local th = { id = id, name = name, icon = icon, pal = mkPal(p), grad = g, deco = deco or "none", dcol = dcol, photo = photo }
    THEMES[#THEMES + 1] = th
    byId[id] = th
end

T("default", "Bawaan (Foto)", "🖼️", { {10,10,15}, {18,22,35}, {25,32,50}, {60,120,255}, {70,130,255}, {40,80,40}, {150,160,180} },
    { {10,10,15}, {18,22,35} }, "none", nil, true)
T("mono", "Monokrom", "⚪", { {12,12,14}, {30,31,35}, {52,53,59}, {206,209,217}, {118,121,132}, {96,102,110}, {172,175,184} },
    { {14,14,16}, {52,53,59} }, "none")
T("forest", "Hutan", "🌲", { {6,24,13}, {12,42,24}, {20,64,38}, {92,208,120}, {44,138,74}, {30,104,52}, {156,204,170} },
    { {4,20,11}, {20,64,38}, {8,34,20} }, "fireflies", { 190, 255, 140 })
T("hacker", "Hacker", "💻", { {2,9,4}, {4,20,9}, {7,34,14}, {0,255,90}, {0,150,62}, {0,106,44}, {96,204,128} },
    { {0,6,2}, {7,34,14} }, "matrix", { 0, 255, 90 })
T("ocean", "Lautan", "🌊", { {5,26,56}, {9,46,90}, {15,72,128}, {120,206,255}, {30,122,204}, {20,128,150}, {176,214,238} },
    { {3,26,66}, {24,102,184}, {5,40,90} }, "bubbles", { 190, 235, 255 })
T("sunset", "Sunset", "🌇", { {34,12,42}, {56,20,58}, {90,36,82}, {255,156,76}, {222,96,64}, {150,58,112}, {232,192,196} },
    { {70,30,120}, {238,108,82}, {255,172,84} }, "embers", { 255, 200, 150 })
T("nebula", "Nebula", "🌌", { {12,7,32}, {22,13,56}, {36,22,86}, {156,126,255}, {98,72,222}, {40,100,190}, {192,182,232} },
    { {30,10,74}, {98,72,222}, {12,7,32} }, "stars", { 200, 180, 255 })
T("aurora", "Aurora", "🌠", { {5,12,24}, {9,26,40}, {14,42,60}, {96,240,205}, {60,200,170}, {30,130,112}, {164,208,210} },
    { {6,20,40}, {30,130,112}, {60,50,120} }, "stars", { 150, 255, 225 })
T("sakura", "Sakura", "🌸", { {38,14,28}, {62,24,46}, {96,40,72}, {255,162,202}, {240,120,170}, {160,70,112}, {236,198,214} },
    { {52,16,40}, {160,70,112} }, "petals", { 255, 190, 215 })
T("neon", "Neon Retro", "🌴", { {10,4,24}, {26,8,50}, {50,14,84}, {255,64,204}, {0,226,255}, {0,150,172}, {204,172,232} },
    { {14,4,32}, {90,20,110}, {0,100,130} }, "stars", { 255, 100, 220 })
T("lava", "Lava", "🌋", { {20,5,4}, {44,10,8}, {78,20,12}, {255,120,40}, {226,84,30}, {150,70,20}, {220,184,170} },
    { {40,6,6}, {150,50,15} }, "embers", { 255, 160, 60 })
T("snow", "Salju", "❄️", { {10,22,44}, {18,40,76}, {30,66,112}, {170,225,255}, {90,170,235}, {50,130,170}, {200,224,240} },
    { {8,24,60}, {60,120,180} }, "snow", { 240, 248, 255 })
T("rain", "Hujan", "🌧️", { {10,13,20}, {22,28,40}, {38,48,66}, {120,170,220}, {78,124,180}, {50,110,120}, {170,184,200} },
    { {6,10,20}, {38,48,66} }, "rain", { 150, 190, 235 })
T("gold", "Emas Mewah", "👑", { {10,8,4}, {28,22,10}, {52,40,16}, {240,196,90}, {200,150,50}, {120,110,50}, {214,200,170} },
    { {10,8,4}, {80,60,20} }, "stars", { 255, 226, 130 })
T("cyber", "Cyberpunk", "🌆", { {10,4,22}, {24,8,46}, {44,12,74}, {255,230,60}, {0,230,255}, {0,160,170}, {200,180,225} },
    { {22,4,44}, {60,14,90}, {0,90,110} }, "rain", { 255, 60, 190 })
T("candy", "Permen", "🍭", { {90,40,90}, {120,60,120}, {150,84,150}, {255,200,230}, {255,130,190}, {90,180,150}, {250,220,240} },
    { {255,120,180}, {150,110,230}, {70,170,230} }, "bubbles", { 255, 255, 255 })

-- palet aktif (diisi ulang saat ganti tema)
local pal = {}
for k, v in pairs(byId.default.pal) do pal[k] = v end

----------------------------------------------------------------------
-- HELPER UI
----------------------------------------------------------------------
local function new(class, props, parent)
    local o = Instance.new(class)
    if props then for k, v in pairs(props) do o[k] = v end end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r)
    return new("UICorner", { CornerRadius = (typeof(r) == "UDim") and r or UDim.new(0, r or 8) }, o)
end
local function stroke(o, th)
    return new("UIStroke", { Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function lbl(parent, text, size, font, color, pos, sz, align)
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size, Font = font, TextColor3 = color,
        Position = pos, Size = sz, TextXAlignment = align or Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end
local LEFT = Enum.TextXAlignment.Left

-- daftar elemen yang ikut berubah warna saat ganti tema: {instance, property, role}
local reg, softList, refreshers = {}, {}, {}
local function role(inst, prop, r)
    reg[#reg + 1] = { inst, prop, r }
    inst[prop] = pal[r]
    return inst
end
local function soft(inst)
    softList[#softList + 1] = inst
    inst.BackgroundTransparency = S.pt
    return inst
end
local function applySoft()
    for i = #softList, 1, -1 do
        local o = softList[i]
        if o.Parent then o.BackgroundTransparency = S.pt else table.remove(softList, i) end
    end
end
local TI_COLOR = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function recolor()
    for i = #reg, 1, -1 do
        local e = reg[i]
        if e[1].Parent then
            TweenService:Create(e[1], TI_COLOR, { [e[2]] = pal[e[3]] }):Play()
        else
            table.remove(reg, i)
        end
    end
    for _, fn in ipairs(refreshers) do pcall(fn) end
end

----------------------------------------------------------------------
-- GUI UTAMA
----------------------------------------------------------------------
local gui = new("ScreenGui", {
    Name = "RodeoHubGui", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true, DisplayOrder = 100,
}, playerGui)

local W, H = 500, 250
local main = new("Frame", {
    Name = "MainFrame", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(W, H), BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, gui)
role(main, "BackgroundColor3", "black")
corner(main, 14)
role(stroke(main, 2), "Color", "border")

local uiScale = new("UIScale", {}, main)
local function fit()
    local vp = gui.AbsoluteSize
    if vp.X < 10 or vp.Y < 10 then
        local cam = workspace.CurrentCamera
        vp = cam and cam.ViewportSize or Vector2.new(800, 400)
    end
    uiScale.Scale = math.clamp(math.min((vp.X - 16) / W, (vp.Y - 16) / H), 0.5, 1.25)
end
fit()
bind(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)

-- background: gradien warna + foto + dekorasi
local bgFrame = new("Frame", { Name = "BG", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0 }, main)
corner(bgFrame, 14)
local bgGrad = new("UIGradient", {}, bgFrame)
local bgImage = new("ImageLabel", {
    Name = "BGImage", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    ScaleType = Enum.ScaleType.Crop, ZIndex = 0, Visible = false,
}, main)
corner(bgImage, 14)
local deco = new("Frame", { Name = "Deco", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1, ClipsDescendants = true }, main)

local function setImage(id)
    local digits = (tostring(id):gsub("%D", ""))
    if digits == "" then return false end
    S.img = digits
    bgImage.Image = "rbxassetid://" .. digits
    task.spawn(function()
        -- kalau ID itu Decal, ambil gambar aslinya (butuh executor yang support GetObjects)
        local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. digits) end)
        if ok and objs and objs[1] and S.img == digits then
            local o = objs[1]
            local d = ((o:IsA("Decal") or o:IsA("Texture")) and o)
                or o:FindFirstChildWhichIsA("Decal", true) or o:FindFirstChildWhichIsA("Texture", true)
            if d and d.Texture and d.Texture ~= "" then bgImage.Image = d.Texture end
        end
    end)
    return true
end

-- dekorasi animasi
local DECO = {
    stars     = { n = 24, twinkle = true, s = { 2, 3 }, round = true },
    fireflies = { n = 16, twinkle = true, s = { 3, 4 }, round = true },
    bubbles   = { n = 14, from = 1.05, to = -0.05, d = { 5, 9 }, s = { 4, 10 }, round = true, tr = 0.55, drift = 0.05 },
    embers    = { n = 18, from = 1.05, to = -0.05, d = { 3, 6 }, s = { 2, 4 }, round = true, tr = 0.2, drift = 0.08 },
    snow      = { n = 24, from = -0.05, to = 1.05, d = { 5, 9 }, s = { 2, 4 }, round = true, tr = 0.15, drift = 0.06 },
    petals    = { n = 16, from = -0.05, to = 1.05, d = { 5, 8 }, s = { 4, 6 }, round = true, tr = 0.2, drift = 0.15 },
    rain      = { n = 26, from = -0.1, to = 1.1, d = { 0.6, 1.1 }, w = 1, h = 10, tr = 0.45, drift = -0.03, fixed = true },
    matrix    = { n = 20, from = -0.1, to = 1.1, d = { 1.2, 2.4 }, w = 2, h = 14, tr = 0.35, drift = 0, fixed = true },
}
local function rnd(a, b) return a + math.random() * (b - a) end
local decoTok = 0
local function startDeco(kind, c3)
    decoTok = decoTok + 1
    local tok = decoTok
    deco:ClearAllChildren()
    local cfg = DECO[kind]
    if not cfg then return end
    local col = c3 and rgb(c3[1], c3[2], c3[3]) or pal.accent
    for _ = 1, cfg.n do
        local p = new("Frame", { BackgroundColor3 = col, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, deco)
        if cfg.round then corner(p, UDim.new(1, 0)) end
        task.spawn(function()
            task.wait(math.random() * 3)
            while tok == decoTok and p.Parent do
                if S.anim and main.Visible then
                    if cfg.twinkle then
                        local sz = math.random(cfg.s[1], cfg.s[2])
                        p.Size = UDim2.fromOffset(sz, sz)
                        p.Position = UDim2.fromScale(math.random(), math.random())
                        local d = rnd(1.2, 3)
                        TweenService:Create(p, TweenInfo.new(d, Enum.EasingStyle.Sine), { BackgroundTransparency = rnd(0.1, 0.5) }):Play()
                        task.wait(d)
                        TweenService:Create(p, TweenInfo.new(d, Enum.EasingStyle.Sine), { BackgroundTransparency = 1 }):Play()
                        task.wait(d)
                    else
                        local d = rnd(cfg.d[1], cfg.d[2])
                        local x = math.random()
                        if cfg.w then
                            p.Size = UDim2.fromOffset(cfg.w, cfg.h)
                        else
                            local sz = math.random(cfg.s[1], cfg.s[2])
                            p.Size = UDim2.fromOffset(sz, sz)
                        end
                        p.Position = UDim2.fromScale(x, cfg.from)
                        p.BackgroundTransparency = 1
                        local dx = cfg.fixed and cfg.drift or (cfg.drift * (math.random() * 2 - 1))
                        TweenService:Create(p, TweenInfo.new(d, Enum.EasingStyle.Linear), { Position = UDim2.fromScale(x + dx, cfg.to) }):Play()
                        TweenService:Create(p, TweenInfo.new(d * 0.25), { BackgroundTransparency = cfg.tr }):Play()
                        task.wait(d * 0.75)
                        TweenService:Create(p, TweenInfo.new(d * 0.25), { BackgroundTransparency = 1 }):Play()
                        task.wait(d * 0.25)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    end
end

-- drag generik (mouse + sentuh)
local function drag(handle, target, onClick)
    local down, moved, sp, st = false, false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            down, moved, sp, st = true, false, i.Position, target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    if down and not moved and onClick then onClick() end
                    down = false
                end
            end)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if down and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - sp
            if not moved and d.Magnitude < 6 then return end
            moved = true
            target.Position = UDim2.new(st.X.Scale, st.X.Offset + d.X, st.Y.Scale, st.Y.Offset + d.Y)
        end
    end)
end

----------------------------------------------------------------------
-- TOP BAR
----------------------------------------------------------------------
local top = new("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 38), BorderSizePixel = 0, ZIndex = 2, Active = true }, main)
role(top, "BackgroundColor3", "black")
soft(top)
corner(top, 14)

lbl(top, "🌐", 18, FONT.GothamBold, WHITE, UDim2.new(0, 10, 0, 8), UDim2.new(0, 22, 0, 22))
lbl(top, "RODEO FOR ANIMAL", 13, FONT.GothamBlack, WHITE, UDim2.new(0, 38, 0, 4), UDim2.new(0, 200, 0, 18), LEFT)
role(lbl(top, "Soru Hub  •  Auto Catch / Base / ESP", 9, FONT.Gotham, WHITE, UDim2.new(0, 38, 0, 21), UDim2.new(0, 220, 0, 12), LEFT), "TextColor3", "grey")

local dot = new("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.new(1, -128, 0, 16), BackgroundColor3 = GREEN, BorderSizePixel = 0 }, top)
corner(dot, UDim.new(1, 0))
lbl(top, "ONLINE", 8, FONT.GothamBold, GREEN, UDim2.new(1, -118, 0, 10), UDim2.new(0, 50, 0, 18), LEFT)

local function topBtn(text, x, textColor, fallbackBg)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, x, 0, 6), Text = text, TextSize = 13,
        Font = FONT.GothamBold, TextColor3 = textColor, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3,
    }, top)
    if fallbackBg then b.BackgroundColor3 = fallbackBg else role(b, "BackgroundColor3", "btn") end
    corner(b, 6)
    return b
end
local minBtn = topBtn("−", -62, WHITE)
local closeBtn = topBtn("X", -32, RED, rgb(80, 30, 40))
drag(top, main)

----------------------------------------------------------------------
-- TAB + HALAMAN (2 kolom = lebar)
----------------------------------------------------------------------
local tabBar = new("ScrollingFrame", {
    Name = "Tabs", Size = UDim2.new(1, -16, 0, 24), Position = UDim2.new(0, 8, 0, 42), BorderSizePixel = 0,
    ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 2,
}, main)
role(tabBar, "BackgroundColor3", "dark")
soft(tabBar)
corner(tabBar, 8)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3) }, tabBar)

local pages, tabs, orderOf = {}, {}, setmetatable({}, { __mode = "k" })
local curTab = nil

local function makePage(name)
    local sf = new("ScrollingFrame", {
        Name = name, Size = UDim2.new(1, -16, 1, -76), Position = UDim2.new(0, 8, 0, 70), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, ZIndex = 2,
    }, main)
    role(sf, "ScrollBarImageColor3", "accent")
    new("UIPadding", { PaddingBottom = UDim.new(0, 6), PaddingRight = UDim.new(0, 4) }, sf)
    local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sf)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
    local function col(order)
        local c = new("Frame", { Size = UDim2.new(0.5, -3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order }, wrap)
        new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, c)
        return c
    end
    local p = { frame = sf, L = col(1), R = col(2) }
    pages[name] = p
    return p
end

local function refreshTabs()
    for n, b in pairs(tabs) do
        local on = (n == curTab)
        b.BackgroundColor3 = on and pal.accent or pal.btn
        b.TextColor3 = on and WHITE or pal.grey
    end
end
refreshers[#refreshers + 1] = refreshTabs

local function showTab(name)
    curTab = name
    for n, p in pairs(pages) do p.frame.Visible = (n == name) end
    refreshTabs()
end

local function addTab(name, text)
    local b = new("TextButton", {
        Size = UDim2.new(0, 84, 1, 0), Text = text, TextSize = 10, Font = FONT.GothamBold, AutoButtonColor = false,
        BorderSizePixel = 0, ZIndex = 3,
    }, tabBar)
    soft(b)
    corner(b, 6)
    tabs[name] = b
    b.MouseButton1Click:Connect(function() showTab(name) end)
end

----------------------------------------------------------------------
-- KOMPONEN
----------------------------------------------------------------------
local function nextOrder(c)
    local n = (orderOf[c] or 0) + 1
    orderOf[c] = n
    return n
end

local function header(c, text)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BorderSizePixel = 0, LayoutOrder = nextOrder(c) }, c)
    role(f, "BackgroundColor3", "dark")
    soft(f)
    corner(f, 6)
    role(stroke(f, 1), "Color", "accent")
    lbl(f, text, 11, FONT.GothamBlack, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), LEFT)
    return f
end

local function infoText(c, text, h)
    local l = lbl(c, text, 9, FONT.Gotham, WHITE, UDim2.new(), UDim2.new(1, 0, 0, h or 24), LEFT)
    l.TextWrapped = true
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.LayoutOrder = nextOrder(c)
    role(l, "TextColor3", "grey")
    return l
end

local function button(c, text, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), Text = text, TextSize = 11, Font = FONT.GothamBold, TextColor3 = WHITE,
        AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder(c),
    }, c)
    role(b, "BackgroundColor3", "btn")
    soft(b)
    corner(b, 8)
    b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
    return b
end

local function toggle(c, text, init, cb)
    local state = init and true or false
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), TextSize = 11, Font = FONT.GothamBold, TextColor3 = WHITE,
        AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder(c),
    }, c)
    soft(b)
    corner(b, 8)
    local function refresh()
        b.Text = text .. (state and " • ON" or " • OFF")
        b.BackgroundColor3 = state and pal.on or pal.btn
    end
    refreshers[#refreshers + 1] = refresh
    refresh()
    b.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        if cb then cb(state) end
    end)
    return { Set = function(_, v) state = v and true or false refresh() end, Get = function() return state end }
end

local function inputRow(c, text, default, cb, placeholder)
    local f = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BorderSizePixel = 0, LayoutOrder = nextOrder(c) }, c)
    role(f, "BackgroundColor3", "dark")
    soft(f)
    corner(f, 8)
    lbl(f, text, 10, FONT.GothamBold, WHITE, UDim2.new(0, 8, 0, 0), UDim2.new(0.5, -8, 1, 0), LEFT)
    local tb = new("TextBox", {
        Size = UDim2.new(0.5, -12, 0, 24), Position = UDim2.new(0.5, 4, 0.5, -12), Text = tostring(default),
        PlaceholderText = placeholder or "", TextSize = 11, Font = FONT.GothamBold, TextColor3 = WHITE,
        ClearTextOnFocus = false, BorderSizePixel = 0,
    }, f)
    role(tb, "BackgroundColor3", "btn")
    role(tb, "PlaceholderColor3", "grey")
    soft(tb)
    corner(tb, 6)
    tb.FocusLost:Connect(function() if cb then cb(tb.Text, tb) end end)
    return tb
end

local function cycle(c, text, options, default, cb)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i end end
    local b
    b = button(c, "", function()
        idx = idx % #options + 1
        b.Text = text .. ": " .. options[idx]
        if cb then cb(options[idx]) end
    end)
    b.Text = text .. ": " .. options[idx]
    return b
end

-- notifikasi kecil
local curToast
local function notify(title, msg, color)
    if curToast then curToast:Destroy() end
    local f = new("Frame", {
        Size = UDim2.fromOffset(230, 42), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 260, 0, 30),
        BackgroundColor3 = rgb(12, 15, 25), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 60,
    }, gui)
    curToast = f
    corner(f, 10)
    local s = stroke(f, 1.5)
    s.Color = color or pal.accent
    lbl(f, title, 11, FONT.GothamBold, WHITE, UDim2.new(0, 10, 0, 4), UDim2.new(1, -20, 0, 16), LEFT).ZIndex = 61
    local m = lbl(f, msg, 9, FONT.Gotham, rgb(190, 196, 215), UDim2.new(0, 10, 0, 21), UDim2.new(1, -20, 0, 16), LEFT)
    m.ZIndex = 61
    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(1, -10, 0, 30) }):Play()
    task.delay(2.6, function()
        if f.Parent then
            TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(1, 260, 0, 30) }):Play()
            task.wait(0.35)
            f:Destroy()
        end
    end)
end

----------------------------------------------------------------------
-- LOGIKA FITUR (dari script Rodeo asli)
----------------------------------------------------------------------
local BASE_V3 = Vector3.new(-2.3, 15.0, -287.8)
local BASE_CF = CFrame.new(-2.3, 15.0, -287.8) * CFrame.Angles(0, math.rad(15), 0)

local function goToBase()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if S.baseMode == "Teleport" then
        hrp.CFrame = BASE_CF
    else
        local dist = (hrp.Position - BASE_V3).Magnitude
        local dur = math.clamp(dist / (S.baseSpeed or 25), 0.25, 12)
        TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = BASE_CF }):Play()
    end
end

local function isRidePrompt(p)
    for _, txt in ipairs({ p.ActionText or "", p.ObjectText or "", p.Name or "", p.Parent and p.Parent.Name or "" }) do
        if string.lower(txt):find("ride") then return true end
    end
    return false
end
bind(PPS.PromptTriggered, function(prompt, player)
    if player == plr and S.autoBase and isRidePrompt(prompt) then
        task.wait(0.35)
        goToBase()
    end
end)

-- auto x2 (treadmill)
local activeX2 = {}
local function addX2(o) if o.Name == "X2PopUp" and o:IsA("GuiButton") then activeX2[o] = true end end
for _, o in ipairs(playerGui:GetDescendants()) do addX2(o) end
bind(playerGui.DescendantAdded, addX2)
bind(playerGui.DescendantRemoving, function(o) activeX2[o] = nil end)

local function safeClick(btn)
    if not btn or not btn.Parent or not btn.Visible then return end
    local p = btn.Parent
    while p and p ~= playerGui do
        if p:IsA("GuiObject") and not p.Visible then return end
        p = p.Parent
    end
    pcall(function()
        if firesignal then
            firesignal(btn.Activated)
        elseif getconnections then
            for _, c in pairs(getconnections(btn.Activated)) do c:Fire() end
        else
            btn:Activate()
        end
    end)
end

-- ESP
local espData, infos = {}, {}
local function trackInfo(o) if o.Name == "AnimalInfo" and o:IsA("BillboardGui") then infos[o] = true end end
for _, o in ipairs(workspace:GetDescendants()) do trackInfo(o) end
bind(workspace.DescendantAdded, trackInfo)
bind(workspace.DescendantRemoving, function(o) infos[o] = nil end)

local function parseMoney(text)
    if not text then return 0 end
    local s = string.lower(tostring(text)):gsub("%$", ""):gsub("/s", ""):gsub(" ", ""):gsub(",", "")
    local num = tonumber(s:match("([%d%.]+)")) or 0
    if s:find("k") then num = num * 1e3
    elseif s:find("m") then num = num * 1e6
    elseif s:find("b") then num = num * 1e9
    elseif s:find("t") then num = num * 1e12 end
    return num
end
local function getMoney(b)
    local info = b:FindFirstChild("InfoSort")
    if info then
        for _, o in ipairs(info:GetDescendants()) do
            if o.Name == "MoneyPerSecond" and o:IsA("TextLabel") then return o.Text end
        end
    end
    for _, o in ipairs(b:GetDescendants()) do
        if o.Name == "MoneyPerSecond" and o:IsA("TextLabel") then return o.Text end
    end
    return nil
end
local function getModel(b)
    local ad = b.Adornee
    local m
    if ad then
        m = ad:IsA("Model") and ad or ad:FindFirstAncestorOfClass("Model")
    else
        m = b:FindFirstAncestorOfClass("Model")
    end
    return m
end
local function removeEsp(m)
    local d = espData[m]
    if d then
        if d.hl then d.hl:Destroy() end
        if d.bg then d.bg:Destroy() end
        espData[m] = nil
    end
end
local function clearEsp() for m in pairs(espData) do removeEsp(m) end end
local function refreshEspColors()
    for _, d in pairs(espData) do
        if d.hl then d.hl.FillColor = pal.accent d.hl.OutlineColor = pal.border end
        if d.st then d.st.Color = pal.accent end
        if d.stripe then d.stripe.BackgroundColor3 = pal.accent end
    end
end
local function createCard(part, moneyText, value)
    local bg = new("BillboardGui", {
        Name = "RODEO_EspCard", Adornee = part, Size = UDim2.fromOffset(210, 56), StudsOffset = Vector3.new(0, 4.2, 0),
        AlwaysOnTop = true, LightInfluence = 0,
    }, part)
    local f = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = pal.black, BackgroundTransparency = 0.1, BorderSizePixel = 0 }, bg)
    corner(f, 10)
    local st = stroke(f, 1.5)
    st.Color = pal.accent
    local stripe = new("Frame", { Size = UDim2.new(1, -20, 0, 3), Position = UDim2.new(0, 10, 0, 0), BackgroundColor3 = pal.accent, BorderSizePixel = 0 }, f)
    corner(stripe, UDim.new(1, 0))
    local m = lbl(f, moneyText or "$0/s", 18, FONT.GothamBold, WHITE, UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 26), LEFT)
    m.TextScaled = true
    local sub = lbl(f, string.format("%s $/s", tostring(value)), 11, FONT.GothamMedium, pal.grey, UDim2.new(0, 12, 0, 36), UDim2.new(1, -24, 0, 14), LEFT)
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    return bg, m, st, stripe
end
local function updateEsp()
    local seen = {}
    for b in pairs(infos) do
        if not b.Parent then
            infos[b] = nil
        else
            local model = getModel(b)
            if model and model ~= plr.Character and not Players:GetPlayerFromCharacter(model) then
                local moneyText = getMoney(b)
                local value = parseMoney(moneyText)
                if value >= S.espFilter then
                    seen[model] = true
                    local d = espData[model]
                    if not d then
                        local hl = new("Highlight", {
                            FillColor = pal.accent, OutlineColor = pal.border, FillTransparency = 0.6,
                            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                        }, model)
                        local part = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                        local bg, ml, st, stripe
                        if part then bg, ml, st, stripe = createCard(part, moneyText, value) end
                        espData[model] = { hl = hl, bg = bg, money = ml, st = st, stripe = stripe }
                    elseif d.money and moneyText then
                        d.money.Text = moneyText
                    end
                end
            end
        end
    end
    for m in pairs(espData) do
        if not seen[m] or not m.Parent then removeEsp(m) end
    end
end

----------------------------------------------------------------------
-- HALAMAN: MAIN
----------------------------------------------------------------------
local pMain = makePage("MAIN")
local pEsp = makePage("ESP")
local pTema = makePage("TEMA")
local pInfo = makePage("INFO")
addTab("MAIN", "🎯 MAIN")
addTab("ESP", "👁️ ESP")
addTab("TEMA", "🎨 TEMA")
addTab("INFO", "🎮 INFO")

local catchT
header(pMain.L, "🥚 AUTO CATCH")
catchT = toggle(pMain.L, "🥚 AUTO CATCH", false, function(v)
    S.autoCatch = v
    if not v then return end
    local ok, remote = pcall(function() return RS.Modules.Shared.Packages.Network.rev_EggClick end)
    if not (ok and remote) then
        S.autoCatch = false
        catchT:Set(false)
        notify("ERROR", "Remote EggClick tidak ketemu", rgb(248, 113, 113))
        return
    end
    task.spawn(function()
        while S.autoCatch and gui.Parent do
            pcall(function()
                remote:FireServer()
                remote:FireServer()
            end)
            task.wait(0.01)
        end
    end)
end)
infoText(pMain.L, "Mengirim remote EggClick sangat cepat. Berisiko kena kick / ban.", 24)

header(pMain.L, "🏃 TREADMILL")
toggle(pMain.L, "⏩ AUTO X2", false, function(v)
    S.autoX2 = v
    if not v then return end
    task.spawn(function()
        while S.autoX2 and gui.Parent do
            for b in pairs(activeX2) do safeClick(b) end
            task.wait(0.25)
        end
    end)
end)
infoText(pMain.L, "Klik tombol X2PopUp otomatis kalau sedang terlihat.", 24)

header(pMain.R, "🏠 BASE")
toggle(pMain.R, "🏠 AUTO BASE", false, function(v) S.autoBase = v end)
cycle(pMain.R, "📦 MODE", { "Tween", "Teleport" }, "Tween", function(v) S.baseMode = v end)
inputRow(pMain.R, "⚡ SPEED (stud/s)", S.baseSpeed, function(t, tb)
    local n = tonumber(t)
    if n then S.baseSpeed = math.clamp(n, 5, 500) end
    tb.Text = tostring(S.baseSpeed)
end)
button(pMain.R, "📍 GO TO BASE NOW", function() goToBase() end)
infoText(pMain.R, "Auto Base: balik ke base setelah kamu menekan prompt 'ride'.", 24)

----------------------------------------------------------------------
-- HALAMAN: ESP
----------------------------------------------------------------------
header(pEsp.L, "👁️ ANIMAL ESP")
toggle(pEsp.L, "👁️ ANIMAL ESP", false, function(v)
    S.esp = v
    if v then
        task.spawn(function()
            while S.esp and gui.Parent do
                updateEsp()
                task.wait(0.7)
            end
        end)
    else
        clearEsp()
    end
end)
inputRow(pEsp.L, "💰 MIN $/s", "0", function(t)
    local v = parseMoney(t)
    if v == 0 then v = tonumber(t) or 0 end
    S.espFilter = v
    if S.esp then updateEsp() end
end, "1000 / 5k / 1m")

header(pEsp.R, "ℹ️ CARA PAKAI")
infoText(pEsp.R, "1. Nyalakan Animal ESP\n2. Isi filter money/s (contoh 5k, 1m)\n3. Hewan diberi highlight + kartu info\nWarna kartu mengikuti tema.", 56)

----------------------------------------------------------------------
-- HALAMAN: INFO
----------------------------------------------------------------------
local gameName = "Memuat..."
task.spawn(function()
    local ok, info = pcall(function() return Market:GetProductInfo(game.PlaceId) end)
    gameName = (ok and info and info.Name) or ("Place " .. tostring(game.PlaceId))
end)
header(pInfo.L, "🎮 INFO GAME")
local infoLbl = lbl(pInfo.L, "", 10, FONT.GothamBold, WHITE, UDim2.new(), UDim2.new(1, 0, 0, 62), LEFT)
infoLbl.TextWrapped = true
infoLbl.TextYAlignment = Enum.TextYAlignment.Top
infoLbl.LayoutOrder = nextOrder(pInfo.L)
local function refreshInfo()
    infoLbl.Text = string.format("🎮 %s\n🆔 Place ID: %s\n🧩 Job ID: %s\n👥 Player: %d / %d",
        tostring(gameName), tostring(game.PlaceId), (game.JobId ~= "" and game.JobId or "-"),
        #Players:GetPlayers(), Players.MaxPlayers)
end
refreshInfo()
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if pInfo.frame.Visible then refreshInfo() end
    end
end)
header(pInfo.R, "📋 SALIN")
local function copyBtn(text, getter)
    button(pInfo.R, text, function(b)
        local ok = false
        if setclipboard then ok = pcall(setclipboard, tostring(getter())) end
        b.Text = ok and "✅ TERSALIN" or "⚠️ TIDAK SUPPORT"
        task.delay(1.5, function() b.Text = text end)
    end)
end
copyBtn("📋 SALIN PLACE ID", function() return game.PlaceId end)
copyBtn("📋 SALIN JOB ID", function() return game.JobId end)

----------------------------------------------------------------------
-- HALAMAN: TEMA (ganti background UI)
----------------------------------------------------------------------
local tickMarks = {}
local applyTheme

for i, th in ipairs(THEMES) do
    local c = (i % 2 == 1) and pTema.L or pTema.R
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = nextOrder(c),
    }, c)
    role(b, "BackgroundColor3", "btn")
    soft(b)
    corner(b, 8)
    local sw = new("Frame", { Position = UDim2.new(0, 8, 0.5, -10), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, b)
    corner(sw, UDim.new(1, 0))
    local g1, g2 = th.grad[1], th.grad[#th.grad]
    local ac = th.pal.accent
    new("UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, rgb(g1[1], g1[2], g1[3])),
            ColorSequenceKeypoint.new(0.5, ac),
            ColorSequenceKeypoint.new(1, rgb(g2[1], g2[2], g2[3])),
        }),
    }, sw)
    lbl(b, th.icon .. "  " .. th.name, 11, FONT.GothamBold, WHITE, UDim2.new(0, 36, 0, 0), UDim2.new(1, -62, 1, 0), LEFT)
    local tk = lbl(b, "✔", 14, FONT.GothamBold, WHITE, UDim2.new(1, -26, 0, 0), UDim2.new(0, 20, 1, 0))
    tk.Visible = false
    tickMarks[th.id] = tk
    b.MouseButton1Click:Connect(function() applyTheme(th.id) end)
end

header(pTema.L, "⚙️ PENGATURAN TEMA")
toggle(pTema.L, "✨ ANIMASI DEKORASI", S.anim, function(v)
    S.anim = v
    save()
end)
inputRow(pTema.L, "🌫️ TRANSPARAN %", tostring(math.floor(S.pt * 100 + 0.5)), function(t, tb)
    local n = tonumber(t)
    if n then
        S.pt = math.clamp(n, 0, 85) / 100
        applySoft()
        save()
    end
    tb.Text = tostring(math.floor(S.pt * 100 + 0.5))
end, "0 - 85")

header(pTema.R, "🖼️ GAMBAR SENDIRI")
inputRow(pTema.R, "🆔 ID GAMBAR", S.img, function(t, tb)
    if setImage(t) then
        applyTheme("default")
        notify("TEMA", "Background gambar diganti", pal.accent)
    else
        tb.Text = S.img
    end
end, "angka asset id")
infoText(pTema.R, "Isi asset ID gambar / decal, lalu tema 'Bawaan (Foto)' dipakai dengan gambar itu.", 36)

applyTheme = function(id, silent)
    local th = byId[id] or byId.default
    S.theme = th.id
    for k, v in pairs(th.pal) do pal[k] = v end
    recolor()

    local keys = {}
    for i, cc in ipairs(th.grad) do
        keys[i] = ColorSequenceKeypoint.new((i - 1) / (#th.grad - 1), rgb(cc[1], cc[2], cc[3]))
    end
    bgGrad.Color = ColorSequence.new(keys)
    bgGrad.Rotation = 45
    bgFrame.BackgroundTransparency = 0.7
    TweenService:Create(bgFrame, TweenInfo.new(0.35), { BackgroundTransparency = 0 }):Play()

    bgImage.Visible = th.photo == true
    if th.photo then setImage(S.img) end
    startDeco(th.deco, th.dcol)

    for tid, tk in pairs(tickMarks) do tk.Visible = (tid == th.id) end
    refreshEspColors()
    if not silent then save() end
end

----------------------------------------------------------------------
-- LOGO BUBBLE + INFO BAR + TOMBOL MIN / CLOSE
----------------------------------------------------------------------
local logo = new("TextButton", {
    Name = "LogoBtn", Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 12, 0.5, -20), Text = "🌐", TextSize = 20,
    Font = FONT.GothamBold, TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 40,
}, gui)
role(logo, "BackgroundColor3", "black")
corner(logo, UDim.new(1, 0))
role(stroke(logo, 2), "Color", "accent")
drag(logo, logo, function() main.Visible = not main.Visible end)

minBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local infoBar = new("Frame", {
    Name = "InfoBar", Size = UDim2.fromOffset(290, 20), Position = UDim2.new(0.5, -145, 0, 2),
    BackgroundColor3 = rgb(12, 15, 25), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 50,
}, gui)
corner(infoBar, 10)
role(stroke(infoBar, 1), "Color", "accent")
local infoLabel = lbl(infoBar, "📊 FPS --  |  📶 --ms", 10, FONT.GothamBold, GREEN, UDim2.new(0, 4, 0, 0), UDim2.new(1, -8, 1, 0))
infoLabel.ZIndex = 51
local frames, acc = 0, 0
bind(RunService.RenderStepped, function(dt)
    frames = frames + 1
    acc = acc + dt
    if acc >= 0.5 then
        local fps = math.floor(frames / acc + 0.5)
        frames, acc = 0, 0
        local ping, mem = 0, 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        pcall(function() mem = math.floor(Stats:GetTotalMemoryUsageMb()) end)
        infoLabel.Text = string.format("📊 FPS %d  |  📶 %dms  |  👥 %d  |  💾 %dMB", fps, ping, #Players:GetPlayers(), mem)
        infoLabel.TextColor3 = (ping < 100 and GREEN) or (ping < 200 and YELLOW) or RED
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    S.autoCatch, S.autoBase, S.autoX2, S.esp = false, false, false, false
    decoTok = decoTok + 1
    clearEsp()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end)

----------------------------------------------------------------------
-- START
----------------------------------------------------------------------
showTab("MAIN")
applyTheme(S.theme, true)
applySoft()
notify("RODEO HUB", "Loaded • tab TEMA untuk ganti background", pal.accent)

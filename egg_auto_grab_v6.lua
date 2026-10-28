-- Egg Auto Grab v6
-- START/STOP | Glide speed | Area (trail) | Scout | Rarity dropdown | Egg Muncul (list + Ambil)
-- Alur: ke egg -> steal -> glide ke pen (Set Pen) -> tap di pen buat naruh egg
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

local nests = workspace:WaitForChild("LocalNests")
local eggsFolder = nests:WaitForChild("Eggs")

local glideSpeed = 350
local eggMode = "TP"   -- cara ke egg: "TP" (teleport) atau "Glide"
local autoOn, busy = false, false
local savedPos         -- posisi pen (Set Pen)
local selected, rows, chips, tried = {}, {}, {}, {}

-- ===== Area / Trail (awal -> akhir) =====
local TRAILS = {
    {"Glacier Trail", Vector3.new(-190.72, 19.65, 661.02),  Vector3.new(-3477.77, 987.48, 664.45)},
    {"New Player",    Vector3.new(-11.63, 19.65, 554.44),   Vector3.new(-2.65, 736.25, -3012.10)},
    {"Volcanic Trail", Vector3.new(183.93, 19.65, 667.45),  Vector3.new(2229.71, 590.41, 663.98)},
}
local areaIdx = 1
local scoutOn = false
local scoutToEnd = true   -- arah scout: true = ke akhir trail, false = balik ke awal

-- ===== Rarity (dari RarityConfig) =====
local RARITY_DATA = {
    {"Common", "C9D2DF"}, {"Uncommon", "53DD63"}, {"Rare", "348AFF"}, {"Epic", "9650FA"},
    {"Legendary", "FFAE27"}, {"Mythic", "FF3C83"}, {"Secret", "BA42DB"}, {"Godly", "FFD768"},
    {"Divine", "FFF0AD"}, {"Celestial", "68BBFF"}, {"Eternal", "45DEBB"}, {"Transcendent", "B68BFF"},
    {"Cosmic", "765BFA"}, {"Ascendant", "FFAF50"}, {"Primordial", "E96335"}, {"Empyrean", "E7BCFF"},
    {"Omniversal", "FF78B9"}, {"Singularity", "7555AF"}, {"Exalted", "FFA95B"}, {"Golden", "FFD572"},
    {"Diamond", "55FFFF"}, {"Rainbow", "FF4D4D"}, {"Ruby", "FF4D40"}, {"Galaxy", "8A5CFF"},
    {"Frozen", "5FC8FF"}, {"Void", "5A1E9E"}, {"Halloween", "FF7A00"},
    {"ToastGreen", "6EF03A"}, {"ToastRed", "FF314C"},
}
local RARITY, LOWER, NAMES = {}, {}, {}
local function registerRarity(name, color)
    if RARITY[name] then return end
    table.insert(NAMES, name)
    RARITY[name] = {#NAMES, color}
    LOWER[name:lower()] = name
end
for _, d in ipairs(RARITY_DATA) do registerRarity(d[1], Color3.fromHex(d[2])) end
pcall(function()
    local cfg = require(RS:WaitForChild("SwimAdventure", 2):WaitForChild("RarityConfig", 2))
    for _, v in ipairs(cfg.Ordered) do registerRarity(v.Name, v.Color) end
end)

local MATCH = {}
for _, n in ipairs(NAMES) do table.insert(MATCH, n) end
table.sort(MATCH, function(a, b) return #a > #b end)

local function canon(r)
    local l = tostring(r):lower()
    if l == "ancient" then return "Secret" end
    if l == "god" then return "Godly" end
    return LOWER[l] or tostring(r)
end

-- order makin besar = makin langka (urutan sama dengan RarityConfig)
local function rarityInfo(r)
    local d = RARITY[r]
    if d then return d[1], d[2] end
    return 0, Color3.fromRGB(150, 150, 165)
end

local function getRarity(egg)
    local r = egg:GetAttribute("Rarity")
    if r ~= nil then return canon(r) end
    local v = egg:FindFirstChild("Rarity", true)
    if v and v:IsA("ValueBase") then return canon(v.Value) end
    local n = egg.Name:lower()
    for _, name in ipairs(MATCH) do
        if n:find(name:lower(), 1, true) then return name end
    end
    return "Unknown"
end

-- nama hewan/pet di egg (kalau ketemu), kalau nggak pakai nama egg
local function petName(egg)
    for _, k in ipairs({"PetName", "Pet", "PetId", "Animal", "Creature", "DisplayName"}) do
        local v = egg:GetAttribute(k)
        if v ~= nil then return tostring(v) end
    end
    local pr = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if pr and pr.ObjectText ~= "" then
        local t = pr.ObjectText:gsub("%s+[Ee][Gg][Gg]$", "")
        return t
    end
    return egg.Name
end

local function getPos(egg)
    if egg:IsA("Model") then return egg:GetPivot().Position end
    if egg:IsA("BasePart") then return egg.Position end
end

local function myHRP()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

-- ===== Deteksi lagi bawa egg (lewat teks hint game) =====
local function visibleChain(o)
    while o and o ~= playerGui do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return true
end
local CARRY_WORDS = {"inside your pen", "place it in your pen", "your pen to place", "pena anda", "kandang anda"}
local function carryingByHint()
    for _, d in ipairs(playerGui:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            local t = d.Text:lower()
            for _, w in ipairs(CARRY_WORDS) do
                if t:find(w, 1, true) and visibleChain(d) then return true end
            end
        end
    end
    return false
end

local function characterHasEgg()
    local ch = lp.Character
    if not ch then return false end
    for _, d in ipairs(ch:GetDescendants()) do
        if d.Name:lower():find("egg") then return true end
    end
    return false
end

local function isCarrying()
    return carryingByHint() or characterHasEgg()
end

-- ===== Gerak =====
local currentTween
local function tpTo(pos)
    local hrp = myHRP()
    if not hrp then return end
    if currentTween then currentTween:Cancel() end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

local function glideTo(pos)
    local hrp = myHRP()
    if not hrp then return end
    if currentTween then currentTween:Cancel() end
    local dist = (hrp.Position - pos).Magnitude
    currentTween = TweenService:Create(hrp,
        TweenInfo.new(math.max(dist / glideSpeed, 0.03), Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
    currentTween:Play()
    return currentTween
end

local function glideAndWait(pos)
    local tw = glideTo(pos)
    if tw then tw.Completed:Wait() end
end

local function goHome()
    if savedPos then glideAndWait(savedPos) end
end

-- ===== Steal =====
local function triggerPrompt(prompt, method)
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 1000
    prompt.HoldDuration = 0
    if method == 1 then
        if fireproximityprompt then pcall(fireproximityprompt, prompt) end
    elseif method == 2 then
        if getconnections then
            pcall(function()
                for _, cn in ipairs(getconnections(prompt.Triggered)) do cn:Fire(lp) end
            end)
        end
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end)
    end
end

-- berhasil kalau egg/prompt hilang, atau hint "taruh di pen" muncul
local function steal(egg)
    local prompt = egg and egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt then return false end
    local was = carryingByHint()
    for attempt = 1, 3 do
        triggerPrompt(prompt, attempt)
        local t = os.clock()
        while os.clock() - t < 0.7 do
            task.wait(0.1)
            if not egg.Parent or not prompt.Parent or not prompt.Enabled
                or (not was and carryingByHint()) then
                return true
            end
        end
    end
    return false
end

-- ===== Taruh egg di pen (tap di dalam pen) =====
local PLACE_WORDS = {"place", "letak", "tempat", "taruh", "simpan", "deposit", "nest", "kandang"}
local function placePrompts()
    local hrp = myHRP()
    if not (hrp and fireproximityprompt) then return end
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and not d:IsDescendantOf(eggsFolder) then
            local par = d.Parent
            local pos
            if par and par:IsA("BasePart") then pos = par.Position
            elseif par and par:IsA("Attachment") then pos = par.WorldPosition
            elseif par and par:IsA("Model") then pos = par:GetPivot().Position end
            if pos and (pos - hrp.Position).Magnitude <= 30 then
                local txt = (d.ActionText .. " " .. d.ObjectText .. " " .. (par and par.Name or "")):lower()
                for _, w in ipairs(PLACE_WORDS) do
                    if txt:find(w, 1, true) then
                        d.HoldDuration = 0
                        pcall(fireproximityprompt, d)
                        break
                    end
                end
            end
        end
    end
end

local function tapPen()
    if not (VIM and savedPos) then return end
    local cam = workspace.CurrentCamera
    local hrp = myHRP()
    if not (cam and hrp) then return end
    local oldType = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 14, 14), savedPos)
    task.wait(0.2)
    local v, on = cam:WorldToViewportPoint(savedPos)
    if on then
        for _ = 1, 2 do
            pcall(function()
                VIM:SendMouseButtonEvent(v.X, v.Y, 0, true, game, 0)
                task.wait(0.05)
                VIM:SendMouseButtonEvent(v.X, v.Y, 0, false, game, 0)
            end)
            task.wait(0.2)
        end
    end
    cam.CameraType = oldType
end

local function placeEgg()
    for _ = 1, 3 do
        tapPen()
        placePrompts()
        local t = os.clock()
        while os.clock() - t < 1.2 do
            task.wait(0.15)
            if not carryingByHint() then return true end
        end
    end
    return false
end

-- ke egg -> steal -> glide ke pen -> taruh
local setStatus -- diisi setelah UI dibuat
local function stealAndReturn(egg)
    if busy then return false end
    busy = true
    local ok, res = pcall(function()
        local p = getPos(egg)
        if not p then return false end
        if eggMode == "TP" then tpTo(p) else glideAndWait(p) end
        task.wait(0.6) -- biar server baca posisi baru
        if not steal(egg) then return false end
        setStatus("Glide ke pen")
        task.wait(0.3)
        goHome()
        task.wait(0.2)
        setStatus("Taruh egg di pen")
        placeEgg()
        return true
    end)
    busy = false
    return ok and res == true
end

-- ambil egg lalu balik lagi ke posisi scout (kalau Scout aktif)
local function grab(egg)
    if busy then return false end
    local hrp = myHRP()
    local resume = scoutOn and hrp and hrp.Position
    local ok = stealAndReturn(egg)
    if resume then
        local h2 = myHRP()
        if h2 then
            h2.AssemblyLinearVelocity = Vector3.zero
            h2.CFrame = CFrame.new(resume)
        end
    end
    return ok
end

-- ===== Scout: jalan dari awal ke akhir trail (bolak-balik) biar egg muncul =====
RunService.Heartbeat:Connect(function(dt)
    if not scoutOn or busy then return end
    local hrp = myHRP()
    if not hrp then return end
    local t = TRAILS[areaIdx]
    local target = (scoutToEnd and t[3] or t[2]) + Vector3.new(0, 3, 0)
    local cur = hrp.Position
    local delta = target - cur
    local dist = delta.Magnitude
    if dist < 8 then
        scoutToEnd = not scoutToEnd
        return
    end
    local step = math.min(glideSpeed * dt, dist)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(cur + delta.Unit * step)
end)

-- ===== ESP dunia =====
local function addESP(egg, r)
    if egg:FindFirstChild("EggESP") then return end
    local adornee = egg:IsA("Model") and (egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)) or egg
    if not adornee then return end
    local _, color = rarityInfo(r)
    local bb = Instance.new("BillboardGui")
    bb.Name = "EggESP"
    bb.Adornee = adornee
    bb.Size = UDim2.fromOffset(170, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 1000000
    bb.Parent = egg
    local t = Instance.new("TextLabel")
    t.Name = "Label"
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = petName(egg) .. "\n[" .. r .. "]"
    t.TextColor3 = color
    t.TextStrokeTransparency = 0
    t.TextScaled = true
    t.Font = Enum.Font.GothamBold
    t.Parent = bb
end

-- ===== UI =====
local BG = Color3.fromRGB(14, 14, 20)
local PANEL = Color3.fromRGB(26, 26, 36)
local PANEL2 = Color3.fromRGB(40, 40, 56)
local BLUE = Color3.fromRGB(70, 130, 255)
local GREEN = Color3.fromRGB(60, 200, 120)
local RED = Color3.fromRGB(228, 78, 58)
local TEXT = Color3.fromRGB(240, 240, 248)
local MUTED = Color3.fromRGB(140, 150, 175)

local function corner(o, r)
    local c = Instance.new("UICorner", o)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

local function label(parent, text, size, pos, ts, color, font, align)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos or UDim2.new()
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = ts or 13
    l.TextColor3 = color or TEXT
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function button(parent, text, size, pos, color, ts)
    local b = Instance.new("TextButton")
    b.Size = size
    b.Position = pos or UDim2.new()
    b.BackgroundColor3 = color or PANEL2
    b.TextColor3 = TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = ts or 13
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 8)
    return b
end

local ord = 0
local function O() ord += 1 return ord end

local function vlist(f, pad)
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, pad or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    return l
end

pcall(function()
    local root = (gethui and gethui()) or game:GetService("CoreGui")
    local old = root:FindFirstChild("EggAutoGrab")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "EggAutoGrab"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local W = 340
local main = Instance.new("Frame")
main.Position = UDim2.fromOffset(10, 40)
main.BackgroundColor3 = BG
main.Active = true
main.Draggable = true
main.ClipsDescendants = true
main.Parent = gui
corner(main, 14)
local uiScale = Instance.new("UIScale", main)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(60, 60, 84)
stroke.Thickness = 1.5

local minimized = false
local function fit()
    local cam = workspace.CurrentCamera
    local vy = cam and cam.ViewportSize.Y or 600
    local vx = cam and cam.ViewportSize.X or 800
    local h = math.min(560, (vy - 60) / uiScale.Scale)
    local w = math.min(W, (vx - 20) / uiScale.Scale)
    main.Size = UDim2.fromOffset(w, minimized and 40 or h)
end
fit()

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 40)
bar.BackgroundColor3 = PANEL
bar.BorderSizePixel = 0
bar.Parent = main
label(bar, "🥚  Egg Auto Grab", UDim2.new(1, -120, 1, 0), UDim2.fromOffset(12, 0), 15, TEXT, Enum.Font.GothamBold)
local smallBtn = button(bar, "A-", UDim2.fromOffset(30, 26), UDim2.new(1, -108, 0.5, -13), PANEL2, 12)
local bigBtn = button(bar, "A+", UDim2.fromOffset(30, 26), UDim2.new(1, -74, 0.5, -13), PANEL2, 12)
local minBtn = button(bar, "–", UDim2.fromOffset(30, 26), UDim2.new(1, -38, 0.5, -13), PANEL2, 16)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -40)
scroll.Position = UDim2.fromOffset(0, 40)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main
vlist(scroll, 8)
local sp = Instance.new("UIPadding", scroll)
sp.PaddingTop = UDim.new(0, 10)
sp.PaddingBottom = UDim.new(0, 10)
sp.PaddingLeft = UDim.new(0, 10)
sp.PaddingRight = UDim.new(0, 12)

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    scroll.Visible = not minimized
    minBtn.Text = minimized and "+" or "–"
    fit()
end)
smallBtn.MouseButton1Click:Connect(function() uiScale.Scale = math.max(0.6, uiScale.Scale - 0.1) fit() end)
bigBtn.MouseButton1Click:Connect(function() uiScale.Scale = math.min(1.5, uiScale.Scale + 0.1) fit() end)

local function mkRow(h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundTransparency = 1
    f.LayoutOrder = O()
    f.Parent = scroll
    return f
end

-- Baris 1: START/STOP + Glide speed
local r1 = mkRow(48)
local startBtn = button(r1, "START", UDim2.new(0.56, -4, 1, 0), nil, GREEN, 17)
label(r1, "Glide\nspeed", UDim2.new(0.2, 0, 1, 0), UDim2.new(0.56, 6, 0, 0), 12, MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.24, 0, 1, 0)
speedBox.Position = UDim2.new(0.76, 0, 0, 0)
speedBox.BackgroundColor3 = PANEL2
speedBox.Text = tostring(glideSpeed)
speedBox.TextColor3 = TEXT
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 15
speedBox.ClearTextOnFocus = false
speedBox.Parent = r1
corner(speedBox, 8)
speedBox.FocusLost:Connect(function()
    local n = tonumber(speedBox.Text)
    if n then glideSpeed = math.max(n, 1) end
    speedBox.Text = tostring(glideSpeed)
end)

-- Baris 2: Status + Scout
local r2 = mkRow(30)
local statusLbl = label(r2, "Status: Idle", UDim2.new(0.62, 0, 1, 0), nil, 11, Color3.fromRGB(110, 150, 255))
statusLbl.TextWrapped = true
statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
local scoutBtn = button(r2, "Scout: OFF", UDim2.new(0.38, 0, 1, 0), UDim2.new(0.62, 0, 0, 0), PANEL2, 11)
function setStatus(t) statusLbl.Text = "Status: " .. t end

-- Baris 3: Area dropdown + Rarity dropdown
local r3 = mkRow(38)
local areaBtn = button(r3, "Area: " .. TRAILS[areaIdx][1] .. " ▾", UDim2.new(0.5, -4, 1, 0), nil, PANEL2, 12)
local rarBtn = button(r3, "Rarity ▾", UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), PANEL2, 13)

local penBtn -- dibuat di baris 4
local function setSavedPos(pos)
    savedPos = pos
    if penBtn then penBtn.Text = "📍 Pen ✓" end
end

-- Dropdown area
local areaDD = Instance.new("Frame")
areaDD.Size = UDim2.new(1, 0, 0, 0)
areaDD.AutomaticSize = Enum.AutomaticSize.Y
areaDD.BackgroundColor3 = PANEL
areaDD.LayoutOrder = O()
areaDD.Visible = false
areaDD.Parent = scroll
corner(areaDD, 10)
vlist(areaDD, 6)
local ap = Instance.new("UIPadding", areaDD)
ap.PaddingTop = UDim.new(0, 8)
ap.PaddingBottom = UDim.new(0, 8)
ap.PaddingLeft = UDim.new(0, 8)
ap.PaddingRight = UDim.new(0, 8)

local areaOpts = {}
local function paintAreas()
    for i, b in ipairs(areaOpts) do
        b.BackgroundColor3 = (i == areaIdx) and BLUE or PANEL2
    end
end
for i, t in ipairs(TRAILS) do
    local b = button(areaDD, t[1], UDim2.new(1, 0, 0, 32), nil, PANEL2, 13)
    b.LayoutOrder = i
    areaOpts[i] = b
    b.MouseButton1Click:Connect(function()
        areaIdx = i
        areaBtn.Text = "Area: " .. t[1] .. " ▾"
        areaDD.Visible = false
        paintAreas()
        scoutToEnd = true
        if scoutOn then
            local hrp = myHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(t[2] + Vector3.new(0, 3, 0)) -- TP ke awal trail baru
            end
        end
        setStatus("Area: " .. t[1])
    end)
end
paintAreas()
areaBtn.MouseButton1Click:Connect(function()
    areaDD.Visible = not areaDD.Visible
end)

-- Dropdown rarity
local dropdown = Instance.new("Frame")
dropdown.Size = UDim2.new(1, 0, 0, 0)
dropdown.AutomaticSize = Enum.AutomaticSize.Y
dropdown.BackgroundColor3 = PANEL
dropdown.LayoutOrder = O()
dropdown.Visible = false
dropdown.Parent = scroll
corner(dropdown, 10)
vlist(dropdown, 6)
local dp = Instance.new("UIPadding", dropdown)
dp.PaddingTop = UDim.new(0, 8)
dp.PaddingBottom = UDim.new(0, 8)
dp.PaddingLeft = UDim.new(0, 8)
dp.PaddingRight = UDim.new(0, 8)

local ddBtns = Instance.new("Frame")
ddBtns.Size = UDim2.new(1, 0, 0, 30)
ddBtns.BackgroundTransparency = 1
ddBtns.LayoutOrder = 1
ddBtns.Parent = dropdown
local allBtn = button(ddBtns, "Pilih semua", UDim2.new(0.5, -3, 1, 0), nil, PANEL2, 12)
local noneBtn = button(ddBtns, "Kosongkan", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), PANEL2, 12)

local chipHolder = Instance.new("Frame")
chipHolder.Size = UDim2.new(1, 0, 0, 0)
chipHolder.AutomaticSize = Enum.AutomaticSize.Y
chipHolder.BackgroundTransparency = 1
chipHolder.LayoutOrder = 2
chipHolder.Parent = dropdown
local grid = Instance.new("UIGridLayout", chipHolder)
grid.CellSize = UDim2.new(1 / 3, -4, 0, 30)
grid.CellPadding = UDim2.fromOffset(4, 4)
grid.SortOrder = Enum.SortOrder.LayoutOrder

rarBtn.MouseButton1Click:Connect(function()
    dropdown.Visible = not dropdown.Visible
end)

-- Baris 4: Pulang / Set Pen / Ke egg
local r4 = mkRow(30)
local homeBtn = button(r4, "🏠 Pulang", UDim2.new(1 / 3, -4, 1, 0), nil, PANEL2, 11)
penBtn = button(r4, "📍 Set Pen", UDim2.new(1 / 3, -4, 1, 0), UDim2.new(1 / 3, 2, 0, 0), PANEL2, 11)
local modeBtn = button(r4, "Ke egg: TP", UDim2.new(1 / 3, -4, 1, 0), UDim2.new(2 / 3, 4, 0, 0), PANEL2, 11)
homeBtn.MouseButton1Click:Connect(function() task.spawn(goHome) end)
penBtn.MouseButton1Click:Connect(function()
    local hrp = myHRP()
    if hrp then setSavedPos(hrp.Position) end
end)
modeBtn.MouseButton1Click:Connect(function()
    eggMode = (eggMode == "TP") and "Glide" or "TP"
    modeBtn.Text = "Ke egg: " .. eggMode
end)

-- Baris 5: Debug / Copy StealEgg
local r5 = mkRow(30)
local dbgBtn = button(r5, "🛠 Debug", UDim2.new(0.5, -3, 1, 0), nil, PANEL2, 11)
local cpBtn = button(r5, "📋 StealEgg", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), PANEL2, 11)

-- Scout toggle
scoutBtn.MouseButton1Click:Connect(function()
    scoutOn = not scoutOn
    scoutBtn.Text = "Scout: " .. (scoutOn and "ON" or "OFF")
    scoutBtn.BackgroundColor3 = scoutOn and GREEN or PANEL2
    if scoutOn then
        scoutToEnd = true
        local hrp = myHRP()
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(TRAILS[areaIdx][2] + Vector3.new(0, 3, 0)) -- TP ke awal trail
        end
        setStatus("Scout " .. TRAILS[areaIdx][1])
    else
        setStatus("Scout berhenti")
    end
end)

-- Header list
local listHead = label(mkRow(22), "Egg Muncul (0)", UDim2.new(1, 0, 1, 0), nil, 14, TEXT, Enum.Font.GothamBold)
listHead.Parent.LayoutOrder = O()

local listHolder = Instance.new("Frame")
listHolder.Size = UDim2.new(1, 0, 0, 0)
listHolder.AutomaticSize = Enum.AutomaticSize.Y
listHolder.BackgroundTransparency = 1
listHolder.LayoutOrder = O()
listHolder.Parent = scroll
vlist(listHolder, 5)

-- ===== Chips, rows, filter =====
local seq = 0

local function updateCounts()
    local counts, shown = {}, 0
    for _, r in pairs(rows) do
        counts[r.rarity] = (counts[r.rarity] or 0) + 1
        if r.frame.Visible then shown += 1 end
    end
    local n = 0
    for name, ch in pairs(chips) do
        ch.btn.Text = name .. " " .. (counts[name] or 0)
        if selected[name] then n += 1 end
    end
    rarBtn.Text = "Rarity (" .. n .. ") ▾"
    listHead.Text = "Egg Muncul (" .. shown .. ")"
end

local function applyFilter()
    for _, r in pairs(rows) do
        r.frame.Visible = selected[r.rarity] == true
    end
    for _, ch in pairs(chips) do ch.paint() end
    updateCounts()
end

local function ensureChip(r)
    if chips[r] then return end
    if selected[r] == nil then selected[r] = true end
    local order, color = rarityInfo(r)
    local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    local fillText = lum > 0.5 and Color3.fromRGB(15, 15, 20) or Color3.new(1, 1, 1)
    local softText = color:Lerp(Color3.new(1, 1, 1), 0.35)

    local b = Instance.new("TextButton")
    b.LayoutOrder = 100 - order
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    b.Text = r .. " 0"
    b.Parent = chipHolder
    corner(b, 8)
    local tsc = Instance.new("UITextSizeConstraint", b)
    tsc.MaxTextSize = 12
    tsc.MinTextSize = 8
    local s = Instance.new("UIStroke", b)
    s.Color = color
    s.Thickness = 1.2
    local function paint()
        if selected[r] then
            b.BackgroundColor3 = color
            b.TextColor3 = fillText
        else
            b.BackgroundColor3 = PANEL
            b.TextColor3 = softText
        end
    end
    b.MouseButton1Click:Connect(function()
        selected[r] = not selected[r]
        applyFilter()
    end)
    chips[r] = {btn = b, paint = paint}
    paint()
end

for _, n in ipairs(NAMES) do ensureChip(n) end

local function setAllSelected(v)
    for k in pairs(chips) do selected[k] = v end
    applyFilter()
end
allBtn.MouseButton1Click:Connect(function() setAllSelected(true) end)
noneBtn.MouseButton1Click:Connect(function() setAllSelected(false) end)

local function addRow(egg, r)
    if rows[egg] then return end
    ensureChip(r)
    local order, color = rarityInfo(r)
    seq += 1

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = PANEL
    row.LayoutOrder = (1000 - order) * 10000 + seq -- paling langka di atas
    row.Visible = selected[r] == true
    row.Parent = listHolder
    corner(row, 10)

    local nm = label(row, petName(egg), UDim2.new(1, -170, 0, 24), UDim2.fromOffset(12, 6), 14, TEXT, Enum.Font.GothamBold)
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    local sub = label(row, egg.Name, UDim2.new(1, -170, 0, 16), UDim2.fromOffset(12, 30), 10, MUTED)
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    label(row, r, UDim2.fromOffset(94, 54), UDim2.new(1, -158, 0, 0), 12, color, Enum.Font.GothamBold, Enum.TextXAlignment.Right)

    local take = button(row, "Ambil", UDim2.fromOffset(56, 34), UDim2.new(1, -62, 0.5, -17), BLUE, 13)
    take.MouseButton1Click:Connect(function()
        task.spawn(function()
            setStatus("Ambil: " .. petName(egg) .. " (" .. r .. ")")
            local ok = grab(egg)
            setStatus(ok and "Selesai: " .. petName(egg) or "Steal belum kena: " .. petName(egg))
        end)
    end)

    rows[egg] = {frame = row, sub = sub, rarity = r}
end

local function onAdd(egg)
    task.wait(0.2)
    local r = getRarity(egg)
    addESP(egg, r)
    addRow(egg, r)
    updateCounts()
end

for _, e in ipairs(eggsFolder:GetChildren()) do task.spawn(onAdd, e) end
eggsFolder.ChildAdded:Connect(onAdd)
eggsFolder.ChildRemoved:Connect(function(e)
    local r = rows[e]
    if r then r.frame:Destroy() rows[e] = nil end
    tried[e] = nil
    updateCounts()
end)

-- ===== Debug & copy StealEgg =====
dbgBtn.MouseButton1Click:Connect(function()
    print("[EggGrab] carryingByHint:", carryingByHint(), "| characterHasEgg:", characterHasEgg(), "| VIM:", VIM ~= nil)
    local first = eggsFolder:GetChildren()[1]
    if first then
        print("[EggGrab] egg contoh:", first:GetFullName(), first.ClassName)
        for k, v in pairs(first:GetAttributes()) do print("   attr", k, v) end
        for _, ch in ipairs(first:GetChildren()) do print("   child", ch.Name, ch.ClassName) end
        local pr = first:FindFirstChildWhichIsA("ProximityPrompt", true)
        if pr then
            print("   prompt:", pr:GetFullName(), "| Action:", pr.ActionText, "| Object:", pr.ObjectText,
                "| Enabled:", pr.Enabled, "| MaxDist:", pr.MaxActivationDistance)
        end
    end
    local hrp = myHRP()
    if hrp then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and not d:IsDescendantOf(eggsFolder) then
                local par = d.Parent
                local pos = par and ((par:IsA("BasePart") and par.Position) or (par:IsA("Attachment") and par.WorldPosition))
                if pos and (pos - hrp.Position).Magnitude <= 40 then
                    print("[EggGrab] prompt dekat:", d:GetFullName(), "|", d.ActionText, "|", d.ObjectText)
                end
            end
        end
    end
    dbgBtn.Text = "✓ cek console"
    task.delay(3, function() dbgBtn.Text = "🛠 Debug" end)
end)

cpBtn.MouseButton1Click:Connect(function()
    local ok, src = pcall(function()
        local s = lp:WaitForChild("PlayerScripts"):FindFirstChild("StealEgg")
            or game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("StealEgg")
        return decompile(s)
    end)
    if ok and src and setclipboard then
        setclipboard(src)
        cpBtn.Text = "✓ tersalin"
    else
        print("[EggGrab] decompile gagal:", src)
        cpBtn.Text = "✗ gagal"
    end
    task.delay(3, function() cpBtn.Text = "📋 StealEgg" end)
end)

-- ===== Loop jarak =====
task.spawn(function()
    while gui.Parent do
        local hrp = myHRP()
        if hrp then
            for egg, r in pairs(rows) do
                local p = getPos(egg)
                local d = p and math.floor((p - hrp.Position).Magnitude)
                if d then
                    r.sub.Text = egg.Name .. "  ·  " .. d .. "m"
                    local esp = egg:FindFirstChild("EggESP")
                    local lbl = esp and esp:FindFirstChild("Label")
                    if lbl then lbl.Text = petName(egg) .. "\n[" .. r.rarity .. "] " .. d .. "m" end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ===== Auto grab =====
-- Pilih egg rarity terpilih: paling langka dulu, lalu yang terdekat.
local function pickTarget()
    local hrp = myHRP()
    if not hrp then return end
    local best, bo, bd
    for egg, r in pairs(rows) do
        if selected[r.rarity] and (not tried[egg] or os.clock() - tried[egg] > 6) then
            local p = getPos(egg)
            if p then
                local o = rarityInfo(r.rarity)
                local d = (p - hrp.Position).Magnitude
                if not best or o > bo or (o == bo and d < bd) then best, bo, bd = egg, o, d end
            end
        end
    end
    return best
end

local function setAuto(v)
    autoOn = v
    startBtn.Text = v and "STOP" or "START"
    startBtn.BackgroundColor3 = v and RED or GREEN
    if v then
        if not savedPos then
            local hrp = myHRP()
            if hrp then setSavedPos(hrp.Position) end -- posisi sekarang jadi pen
        end
        setStatus("Mulai")
    else
        setStatus("Idle")
        if currentTween then currentTween:Cancel() end
    end
end
startBtn.MouseButton1Click:Connect(function() setAuto(not autoOn) end)

local lastPlace = 0
task.spawn(function()
    while gui.Parent do
        if autoOn and not busy then
            -- masih bawa egg? taruh dulu, jangan ambil egg lain
            if carryingByHint() and os.clock() - lastPlace > 15 then
                lastPlace = os.clock()
                busy = true
                setStatus("Bawa egg, glide ke pen")
                local hrp0 = myHRP()
                local resume0 = scoutOn and hrp0 and hrp0.Position
                pcall(function() goHome() placeEgg() end)
                if resume0 then
                    local h2 = myHRP()
                    if h2 then h2.AssemblyLinearVelocity = Vector3.zero h2.CFrame = CFrame.new(resume0) end
                end
                busy = false
                task.wait(1)
            end
            local egg = autoOn and pickTarget()
            if egg then
                local r = rows[egg] and rows[egg].rarity or "?"
                setStatus("Ambil: " .. petName(egg) .. " (" .. r .. ")")
                tried[egg] = os.clock()
                if grab(egg) then
                    tried[egg] = os.clock() + 60
                    setStatus("Selesai: " .. petName(egg))
                    task.wait(1)
                else
                    setStatus("Steal belum kena: " .. petName(egg))
                end
            elseif autoOn then
                setStatus("Menunggu egg rarity terpilih")
            end
        end
        task.wait(0.3)
    end
end)

applyFilter()

--==================================================
-- SAVE YOUR FRIEND HUB v7
-- Dari v6: reset level 401 -> 451, tampilan disamakan dengan UniversalHub.
-- Fitur tetap: Auto Skip, Anti Lag + AFK, auto teleport ke map yang benar.
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

--==================================================
-- AUTO TELEPORT KE MAP YANG BENAR
--==================================================

-- Start place [400] Save Your Friend! (0 = pengecekan map dimatikan)
local TARGET_PLACE_ID = 134360023649587

-- Isi dengan link RAW script ini (GitHub/Pastefy) supaya script otomatis jalan lagi
-- setelah teleport. Kalau dikosongkan, setelah sampai di map tujuan kamu harus
-- menjalankan script ini sekali lagi secara manual.
local SCRIPT_URL = ""

if TARGET_PLACE_ID ~= 0 and game.PlaceId ~= TARGET_PLACE_ID then
	local queue = queue_on_teleport
		or (syn and syn.queue_on_teleport)
		or (fluxus and fluxus.queue_on_teleport)

	if queue and SCRIPT_URL ~= "" then
		pcall(function()
			queue(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
		end)
	end

	local ok, err = pcall(function()
		game:GetService("TeleportService"):Teleport(TARGET_PLACE_ID, LocalPlayer)
	end)

	if not ok then
		warn("Teleport ke map tujuan gagal: " .. tostring(err))
	end

	return
end


local HUB_NAME = "SAVE YOUR FRIEND"
local GUI_NAME = "SaveYourFriendHub"
local RESET_LEVEL = 451 -- level yang dikirim untuk reset (dulu 401)

-- Auto Skip: jeda antar kirim (0 = tiap frame, paling cepat) dan jumlah kirim per frame
local RETRY = 0
local BURST = 3

if env.__SYF_CLEANUP then
	pcall(env.__SYF_CLEANUP)
end

local function purge(parent)
	if not parent then return end

	local old = parent:FindFirstChild(GUI_NAME)

	if old then
		old:Destroy()
	end
end

pcall(function()
	purge(gethui and gethui())
end)

pcall(function()
	purge(game:GetService("CoreGui"))
end)

pcall(function()
	purge(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
end)

local token = {}

env.__SYF_TOKEN = token

local connections = {}

local function alive()
	return env.__SYF_TOKEN == token
end

--==================================================
-- LOGIC
--==================================================

local autoSave = false
local cachedRemote = nil
local lastLevel = nil
local lastFire = 0

local function getLevel()
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	local lv = ls and ls:FindFirstChild("Level")

	if lv then
		return lv.Value
	end

	return nil
end

local function getRemote()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")

	return folder and folder:FindFirstChild("RequestComplete")
end

--==================================================
-- ANTI LAG + ANTI AFK
--==================================================

local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

local lagAfkOn = false
local lagPulse
local lagStore = {}      -- [efek] = nilai Enabled asli
local lagDescConn
local origQuality
local origShadows

local function isHeavyEffect(o)
	return o:IsA("ParticleEmitter")
		or o:IsA("Trail")
		or o:IsA("Beam")
		or o:IsA("Smoke")
		or o:IsA("Fire")
		or o:IsA("Sparkles")
end

local function disableEffect(o)
	if isHeavyEffect(o) then
		if lagStore[o] == nil then
			lagStore[o] = o.Enabled
		end
		o.Enabled = false
	end
end

local function applyAntiLag(on)
	if on then
		-- matikan efek berat yang sudah ada + yang muncul belakangan
		for _, o in ipairs(workspace:GetDescendants()) do
			pcall(disableEffect, o)
		end

		if not lagDescConn then
			lagDescConn = workspace.DescendantAdded:Connect(function(o)
				pcall(disableEffect, o)
			end)
		end

		pcall(function()
			origQuality = settings().Rendering.QualityLevel
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end)

		pcall(function()
			origShadows = Lighting.GlobalShadows
			Lighting.GlobalShadows = false
		end)
	else
		if lagDescConn then
			lagDescConn:Disconnect()
			lagDescConn = nil
		end

		for o, wasEnabled in pairs(lagStore) do
			pcall(function()
				if o.Parent then
					o.Enabled = wasEnabled
				end
			end)
		end

		lagStore = {}

		pcall(function()
			if origQuality ~= nil then
				settings().Rendering.QualityLevel = origQuality
			end
		end)

		pcall(function()
			if origShadows ~= nil then
				Lighting.GlobalShadows = origShadows
			end
		end)
	end
end

-- Anti AFK: setiap game mau menendang karena idle, kirim klik palsu
table.insert(
	connections,
	LocalPlayer.Idled:Connect(function()
		if not lagAfkOn then return end

		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end)
)

-- kembalikan efek/grafik ke semula kalau script dijalankan ulang atau di-cleanup
table.insert(connections, {
	Disconnect = function()
		if lagAfkOn then
			lagAfkOn = false
			applyAntiLag(false)
		end
	end
})

--==================================================
-- TEMA (sama dengan UniversalHub)
--==================================================

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
local GOLD = Color3.fromRGB(255, 215, 0)
local ON_COLOR = Color3.fromRGB(40, 80, 40)
local LED_OFF = Color3.fromRGB(70, 78, 98)

local SOFT = 0.4 -- panel semi-transparan supaya foto background kelihatan

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = o
	return c
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
	l.BorderSizePixel = 0
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

local function tween(o, t, props, style, dir, rep, rev)
	local info = TweenInfo.new(
		t,
		style or Enum.EasingStyle.Quad,
		dir or Enum.EasingDirection.Out,
		rep or 0,
		rev or false
	)
	local tw = TweenService:Create(o, info, props)
	tw:Play()
	return tw
end

local SINE = Enum.EasingStyle.Sine
local LINEAR = Enum.EasingStyle.Linear
local BACK = Enum.EasingStyle.Back
local INOUT = Enum.EasingDirection.InOut
local IN = Enum.EasingDirection.In

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

if syn and syn.protect_gui then
	pcall(syn.protect_gui, gui)
end

local mounted = pcall(function()
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)

if not mounted or not gui.Parent then
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

env.__SYF_CLEANUP = function()
	env.__SYF_TOKEN = nil

	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end

	pcall(function()
		gui:Destroy()
	end)
end

-- ---------- bar info paling atas (FPS / ping / player / memori / jam) ----------
local infoBar = Instance.new("Frame")
infoBar.Name = "InfoBar"
infoBar.Size = UDim2.new(0, 350, 0, 20)
infoBar.Position = UDim2.new(0.5, -175, 0, 2)
infoBar.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
infoBar.BackgroundTransparency = 0.35
infoBar.BorderSizePixel = 0
infoBar.ZIndex = 50
infoBar.Parent = gui
corner(infoBar, 10)
stroke(infoBar, ACCENT_BLUE, 1)

local infoLabel = newLabel(infoBar, "📊 FPS --  |  📶 --ms", 10, Enum.Font.GothamBold, GREEN,
	UDim2.new(0, 4, 0, 0), UDim2.new(1, -8, 1, 0))
infoLabel.ZIndex = 51

local infoFrames, infoAcc = 0, 0

table.insert(
	connections,
	RunService.RenderStepped:Connect(function(dt)
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

			infoLabel.Text = string.format(
				"📊 FPS %d  |  📶 %dms  |  👥 %d  |  💾 %dMB  |  🕒 %s",
				fps, ping, #Players:GetPlayers(), mem, os.date("%H:%M")
			)
			infoLabel.TextColor3 = (ping < 100 and GREEN) or (ping < 200 and YELLOW) or RED
		end
	end)
)

-- ---------- frame utama ----------
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.Size = UDim2.new(0, 280, 0, 410)
main.BackgroundColor3 = BG_BLACK
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
corner(main, 14)
local mainStroke = stroke(main, BORDER_BLUE, 2)

local scale = Instance.new("UIScale")
scale.Scale = 0
scale.Parent = main

-- foto background (id yang sama dengan UniversalHub)
local BG_ASSET_ID = "134262192520482"

local bgImage = Instance.new("ImageLabel")
bgImage.Name = "Background"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.BackgroundTransparency = 1
bgImage.Image = "rbxassetid://" .. BG_ASSET_ID
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.ZIndex = 0
bgImage.Parent = main
corner(bgImage, 12)

task.spawn(function()
	-- kalau ID itu ternyata Decal, ambil ID gambar aslinya lewat GetObjects (executor)
	local ok, objs = pcall(function()
		return game:GetObjects("rbxassetid://" .. BG_ASSET_ID)
	end)

	if ok and objs and objs[1] then
		local o = objs[1]
		local d = (o:IsA("Decal") or o:IsA("Texture")) and o
			or o:FindFirstChildWhichIsA("Decal", true)
			or o:FindFirstChildWhichIsA("Texture", true)

		if d and d.Texture and d.Texture ~= "" and bgImage.Parent then
			bgImage.Image = d.Texture
		end
	end
end)

-- ---------- top bar ----------
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = BG_BLACK
topBar.BackgroundTransparency = SOFT
topBar.BorderSizePixel = 0
topBar.Parent = main
corner(topBar, 14)

newLabel(topBar, "🛟", 18, Enum.Font.GothamBold, WHITE,
	UDim2.new(0, 10, 0, 8), UDim2.new(0, 22, 0, 22))

local titleLabel = newLabel(topBar, HUB_NAME, 14, Enum.Font.GothamBlack, WHITE,
	UDim2.new(0, 36, 0, 8), UDim2.new(1, -110, 0, 20), Enum.TextXAlignment.Left)

newLabel(topBar, "Auto Skip Hub • reset " .. RESET_LEVEL, 9, Enum.Font.Gotham, GREY,
	UDim2.new(0, 36, 0, 28), UDim2.new(1, -110, 0, 12), Enum.TextXAlignment.Left)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(0, 10, 0, 40)
statusDot.BackgroundColor3 = GREEN
statusDot.BorderSizePixel = 0
statusDot.Parent = topBar
corner(statusDot, 3)

newLabel(topBar, "ONLINE", 8, Enum.Font.GothamBold, GREEN,
	UDim2.new(0, 20, 0, 36), UDim2.new(0, 60, 0, 14), Enum.TextXAlignment.Left)

local function topButton(text, xOff, bg, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 26, 0, 26)
	b.Position = UDim2.new(1, xOff, 0, 10)
	b.BackgroundColor3 = bg
	b.Text = text
	b.TextSize = 14
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = color
	b.AutoButtonColor = false
	b.Parent = topBar
	corner(b, 6)
	return b
end

local minBtn = topButton("−", -60, BG_BUTTON, WHITE)
local closeBtn = topButton("X", -30, Color3.fromRGB(80, 30, 40), RED)

-- ---------- halaman (bisa di-scroll) ----------
local page = Instance.new("ScrollingFrame")
page.Name = "Page"
page.Position = UDim2.new(0, 8, 0, 58)
page.Size = UDim2.new(1, -16, 1, -66)
page.BackgroundTransparency = 1
page.BorderSizePixel = 0
page.ScrollBarThickness = 3
page.ScrollBarImageColor3 = ACCENT_BLUE
page.CanvasSize = UDim2.new(0, 0, 0, 0)
page.AutomaticCanvasSize = Enum.AutomaticSize.Y
page.Parent = main

local pageLayout = Instance.new("UIListLayout")
pageLayout.Padding = UDim.new(0, 6)
pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
pageLayout.Parent = page

local function header(text, order)
	local f = Instance.new("Frame")
	f.LayoutOrder = order
	f.Size = UDim2.new(1, 0, 0, 22)
	f.BackgroundColor3 = BG_DARK
	f.BackgroundTransparency = SOFT
	f.BorderSizePixel = 0
	f.Parent = page
	corner(f, 6)
	stroke(f, ACCENT_BLUE, 1)
	newLabel(f, text, 11, Enum.Font.GothamBlack, WHITE,
		UDim2.new(0, 8, 0, 0), UDim2.new(1, -16, 1, 0), Enum.TextXAlignment.Left)
	return f
end

local function note(text, order)
	local l = newLabel(page, text, 9, Enum.Font.Gotham, GREY,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 14), Enum.TextXAlignment.Left)
	l.LayoutOrder = order
	l.TextWrapped = true
	return l
end

-- tombol ON/OFF gaya UniversalHub: lampu status di kiri, hijau kalau ON
local function makeToggle(order, label, onChange)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = order
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = BG_BUTTON
	btn.BackgroundTransparency = SOFT
	btn.Text = label .. " • OFF"
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = WHITE
	btn.AutoButtonColor = false
	btn.Parent = page
	corner(btn, 8)

	local edge = stroke(btn, GREEN, 1.2)
	edge.Transparency = 1

	local led = Instance.new("Frame")
	led.AnchorPoint = Vector2.new(0, 0.5)
	led.Position = UDim2.new(0, 10, 0.5, 0)
	led.Size = UDim2.new(0, 7, 0, 7)
	led.BackgroundColor3 = LED_OFF
	led.BorderSizePixel = 0
	led.Parent = btn
	corner(led, 4)

	local glow = Instance.new("UIStroke")
	glow.Color = GREEN
	glow.Thickness = 2
	glow.Transparency = 1
	glow.Parent = led

	local on = false
	local pulseTween

	local function set(v)
		on = v
		btn.Text = label .. (on and " • ON" or " • OFF")
		tween(btn, 0.2, { BackgroundColor3 = on and ON_COLOR or BG_BUTTON })
		tween(led, 0.2, { BackgroundColor3 = on and GREEN or LED_OFF })
		glow.Transparency = on and 0.45 or 1

		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
		end

		edge.Transparency = on and 0.35 or 1

		if on then
			pulseTween = tween(edge, 0.9, { Transparency = 0.85 }, SINE, INOUT, -1, true)
		end
	end

	btn.Activated:Connect(function()
		set(not on)
		if onChange then onChange(on) end
	end)

	btn.MouseEnter:Connect(function()
		if not on then tween(btn, 0.15, { BackgroundTransparency = SOFT - 0.15 }) end
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = SOFT })
	end)

	return btn, set
end

-- ---------- isi ----------
header("⏭ AUTO SKIP", 0)

local skipBtn, setSkip = makeToggle(1, "⏭ AUTO SKIP", function(on)
	autoSave = on
	if not on then lastLevel = nil end
end)

note("Level mencapai " .. RESET_LEVEL .. " → langsung reset, lalu lanjut dari awal.", 2)

header("🛡️ UTILITAS", 3)

local lagBtn, setLag = makeToggle(4, "🥱 ANTI LAG + AFK", function(on)
	lagAfkOn = on
	applyAntiLag(on)
end)

note("Efek berat dimatikan, grafik diturunkan, tidak ditendang karena idle.", 5)

header("👤 PLAYER", 6)

local userCard = Instance.new("Frame")
userCard.LayoutOrder = 7
userCard.Size = UDim2.new(1, 0, 0, 50)
userCard.BackgroundColor3 = BG_DARK
userCard.BackgroundTransparency = SOFT
userCard.BorderSizePixel = 0
userCard.Parent = page
corner(userCard, 8)
stroke(userCard, ACCENT_BLUE, 1)

local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 36, 0, 36)
avatarFrame.Position = UDim2.new(0, 8, 0, 7)
avatarFrame.BackgroundColor3 = BG_BUTTON
avatarFrame.BorderSizePixel = 0
avatarFrame.Parent = userCard
corner(avatarFrame, 18)
stroke(avatarFrame, ACCENT_BLUE, 1.5)

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(1, -4, 1, -4)
avatarImg.Position = UDim2.new(0, 2, 0, 2)
avatarImg.BackgroundTransparency = 1
avatarImg.ScaleType = Enum.ScaleType.Crop
avatarImg.Parent = avatarFrame
corner(avatarImg, 16)

task.spawn(function()
	local ok, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)

	if ok and thumb and avatarImg.Parent then
		avatarImg.Image = thumb
	end
end)

local nameLabel = newLabel(userCard, LocalPlayer.DisplayName, 13, Enum.Font.GothamBold, WHITE,
	UDim2.new(0, 52, 0, 8), UDim2.new(1, -60, 0, 18), Enum.TextXAlignment.Left)
nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

local userLabel = newLabel(userCard, "@" .. LocalPlayer.Name, 10, Enum.Font.Gotham, GREY,
	UDim2.new(0, 52, 0, 27), UDim2.new(1, -60, 0, 14), Enum.TextXAlignment.Left)
userLabel.TextTruncate = Enum.TextTruncate.AtEnd

header("📊 STATUS", 8)

local levelCard = Instance.new("Frame")
levelCard.LayoutOrder = 9
levelCard.Size = UDim2.new(1, 0, 0, 68)
levelCard.BackgroundColor3 = BG_DARK
levelCard.BackgroundTransparency = SOFT
levelCard.BorderSizePixel = 0
levelCard.Parent = page
corner(levelCard, 8)
stroke(levelCard, ACCENT_BLUE, 1)

newLabel(levelCard, "CURRENT LEVEL", 9, Enum.Font.GothamBold, GREY,
	UDim2.new(0, 10, 0, 6), UDim2.new(0.5, 0, 0, 12), Enum.TextXAlignment.Left)

local levelValue = newLabel(levelCard, "?", 22, Enum.Font.GothamBlack, WHITE,
	UDim2.new(0, 10, 0, 18), UDim2.new(0.5, 0, 0, 28), Enum.TextXAlignment.Left)

local levelState = newLabel(levelCard, "/ " .. RESET_LEVEL, 11, Enum.Font.GothamBold, GREY,
	UDim2.new(0.5, 0, 0, 22), UDim2.new(0.5, -10, 0, 20), Enum.TextXAlignment.Right)

local barTrack = Instance.new("Frame")
barTrack.Position = UDim2.new(0, 10, 0, 52)
barTrack.Size = UDim2.new(1, -20, 0, 7)
barTrack.BackgroundColor3 = BG_BUTTON
barTrack.BorderSizePixel = 0
barTrack.Parent = levelCard
corner(barTrack, 4)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = ACCENT_BLUE
barFill.BorderSizePixel = 0
barFill.Parent = barTrack
corner(barFill, 4)

-- ---------- tombol logo 💲 (bisa digeser, tap = buka/tutup hub) ----------
local logoBtn = Instance.new("TextButton")
logoBtn.Name = "Logo"
logoBtn.Size = UDim2.new(0, 44, 0, 44)
logoBtn.Position = UDim2.new(0, 15, 0.5, -22)
logoBtn.BackgroundColor3 = BG_BLACK
logoBtn.Text = "🛟"
logoBtn.TextSize = 18
logoBtn.Font = Enum.Font.GothamMedium
logoBtn.TextColor3 = GOLD
logoBtn.AutoButtonColor = false
logoBtn.Parent = gui
corner(logoBtn, 22)
local logoStroke = stroke(logoBtn, GOLD, 1.5)

--==================================================
-- BUKA / TUTUP + DRAG
--==================================================

local shown = true

local function showMain()
	shown = true
	main.Visible = true
	scale.Scale = 0.85
	tween(scale, 0.25, { Scale = 1 }, BACK)
end

local function hideMain()
	shown = false
	local t = tween(scale, 0.18, { Scale = 0.85 }, Enum.EasingStyle.Quad, IN)
	t.Completed:Connect(function()
		if not shown then
			main.Visible = false
		end
	end)
end

minBtn.Activated:Connect(hideMain)

closeBtn.Activated:Connect(function()
	if env.__SYF_CLEANUP then
		env.__SYF_CLEANUP()
	end
end)

-- geser hub lewat top bar
local dragging, dragStart, startPos = false, nil, nil

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPos = main.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

-- geser logo: > 8 px = drag, tap biasa = buka/tutup hub
local logoDragging, logoMoved, logoStart, logoStartPos = false, false, nil, nil

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

table.insert(
	connections,
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		if dragging then
			local d = input.Position - dragStart

			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end

		if logoDragging then
			local d = input.Position - logoStart

			if not logoMoved and d.Magnitude < 8 then
				return
			end

			logoMoved = true

			logoBtn.Position = UDim2.new(
				logoStartPos.X.Scale, logoStartPos.X.Offset + d.X,
				logoStartPos.Y.Scale, logoStartPos.Y.Offset + d.Y
			)
		end
	end)
)

logoBtn.Activated:Connect(function()
	if logoMoved then
		logoMoved = false -- habis di-drag, jangan toggle hub
		return
	end

	if shown then
		hideMain()
	else
		showMain()
	end
end)

--==================================================
-- DETAIL TAMPILAN (kilau, denyut, animasi)
--==================================================

-- border hub berkilau (cahaya berputar)
do
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	g.Parent = mainStroke

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt)
			if main.Visible then
				g.Rotation = (g.Rotation + dt * 70) % 360
			end
		end)
	)
end

-- judul berkilau
do
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(135, 160, 215)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 160, 215)),
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = titleLabel
	tween(g, 2.4, { Offset = Vector2.new(1, 0) }, LINEAR, Enum.EasingDirection.Out, -1, false)
end

-- titik ONLINE dan logo berdenyut
tween(statusDot, 0.9, { BackgroundTransparency = 0.7 }, SINE, INOUT, -1, true)
tween(logoStroke, 1.1, { Thickness = 3, Transparency = 0.35 }, SINE, INOUT, -1, true)

-- bar level: ikut level sekarang, hijau + "RESET" kalau sudah di batas
local function paintLevel(lv)
	if lv == nil then
		levelValue.Text = "?"
		levelState.Text = "/ " .. RESET_LEVEL
		levelState.TextColor3 = GREY
		return
	end

	levelValue.Text = tostring(lv)

	local ratio = math.clamp(lv / RESET_LEVEL, 0, 1)
	local atReset = lv >= RESET_LEVEL

	tween(barFill, 0.25, {
		Size = UDim2.new(ratio, 0, 1, 0),
		BackgroundColor3 = atReset and GREEN or ACCENT_BLUE,
	})

	if atReset then
		levelState.Text = "⟳ RESET " .. RESET_LEVEL
		levelState.TextColor3 = GREEN
	else
		levelState.Text = "/ " .. RESET_LEVEL
		levelState.TextColor3 = GREY
	end
end

task.spawn(function()
	while alive() do
		paintLevel(tonumber(getLevel()))
		task.wait(0.25)
	end
end)

--==================================================
-- AUTO SKIP (loop)
--
-- Kirim level sekarang. Kalau level sudah >= RESET_LEVEL (451),
-- kirim 451 (reset), lalu lanjut terus dari awal.
--==================================================

table.insert(
	connections,
	RunService.Heartbeat:Connect(function()
		if not cachedRemote or not cachedRemote.Parent then
			cachedRemote = getRemote()
		end

		local now = os.clock()

		if not autoSave then
			lastLevel = nil
			return
		end

		local level = tonumber(getLevel())

		if not cachedRemote or not level then
			return
		end

		local sendLevel = level

		if level >= RESET_LEVEL then
			sendLevel = RESET_LEVEL
		end

		if level ~= lastLevel
			or now - lastFire >= RETRY then

			lastLevel = level
			lastFire = now

			for _ = 1, BURST do
				pcall(function()
					cachedRemote:FireServer(sendLevel)
				end)
			end
		end
	end)
)

--==================================================
-- ANIMASI BUKA + BANNER
--==================================================

tween(scale, 0.5, { Scale = 1 }, BACK)

task.spawn(function()
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Size = UDim2.new(0, 250, 0, 26)
	f.Position = UDim2.new(0.5, 0, 0, -34)
	f.BackgroundColor3 = BG_BLACK
	f.BackgroundTransparency = 0.1
	f.BorderSizePixel = 0
	f.ZIndex = 80
	f.Parent = gui
	corner(f, 13)
	stroke(f, ACCENT_BLUE, 1.5)

	local l = newLabel(f, "✨ SAVE YOUR FRIEND • reset di " .. RESET_LEVEL, 10, Enum.Font.GothamBold, WHITE,
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0))
	l.ZIndex = 81

	tween(f, 0.45, { Position = UDim2.new(0.5, 0, 0, 28) }, BACK)
	task.wait(2.6)

	if f.Parent then
		local out = tween(f, 0.35, { Position = UDim2.new(0.5, 0, 0, -34) }, Enum.EasingStyle.Quad, IN)
		out.Completed:Wait()
		f:Destroy()
	end
end)

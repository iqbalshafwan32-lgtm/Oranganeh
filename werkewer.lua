--[[
	werkewer  |  UI TheRichHUB + fitur Farm
	Tab FARM : Auto Farm, Auto Bonus, Equip Best
	Jenis    : LocalScript / executor (satu file, tanpa file tambahan)
	Toggle   : tombol RightShift
]]

-- ============================================================
-- 1. SERVICES
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local env = (type(getgenv) == "function" and getgenv()) or _G
if type(env.__TheRichStop) == "function" then pcall(env.__TheRichStop) end

-- ============================================================
-- 2. CONFIG (ubah di sini)
-- ============================================================
local CONFIG = {
	Name = "TheRichHUB",
	Subtitle = "Premium Interface  •  v1.3",
	ProfileName = nil, -- nil = pakai DisplayName pemain
	ProfileSubtitle = "DARLING",
	ProfileBio = "Belum ada bio. Isi di CONFIG.ProfileBio", -- bio akun (Roblox tidak mengizinkan script membaca bio asli)
	ProfileFollowers = nil, -- opsional: isi angka manual (API followers tidak bisa dibaca dari client)
	ProfileFollowing = nil, -- opsional: isi angka manual
	ProfileImageId = "", -- isi "rbxassetid://ID" gambar karakter anime (milik/izin Anda)
	BackgroundImageId = "", -- opsional: gambar langit 2D di belakang UI
	ApplyEnvironment = true, -- buat Sky/Atmosphere/Clouds fallback bila belum ada
	GlassFactor = 0.4, -- kepekatan kaca: makin KECIL makin pekat (0.4 = cukup pekat, 1 = transparan seperti dulu)
	BackdropTransparency = 0.6, -- gelap latar belakang saat UI terbuka (makin kecil makin gelap)
	BlurSize = 6, -- ukuran BlurEffect saat UI terbuka
	ToggleKey = Enum.KeyCode.RightShift,
	Design = Vector2.new(960, 540), -- rasio 16:9
	Stats = {
		{ Icon = "", Label = "Bounty", Value = "30M" },
		{ Icon = "", Label = "Level", Value = "2800" },
		{ Icon = "", Label = "Time", Value = "2:54" },
		{ Icon = "", Label = "Health", Value = "67%" },
	},
	Nav = {
		{ Name = "INFO", Label = "Info", Sub = "Profil & server", Icon = "i" },
		{ Name = "FARM", Label = "Farm", Sub = "Farm, bonus, equip", Icon = "F" },
		{ Name = "Misc", Label = "Misc", Sub = "Utilitas", Icon = "M" },
	},
}

-- ============================================================
-- 3. THEME & STATE
-- ============================================================
local THEME = {
	Font = Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
	FontBold = Font.new("rbxasset://fonts/families/Inter.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	Text = Color3.fromRGB(242, 246, 255),
	SubText = Color3.fromRGB(162, 176, 203),
	Dark = Color3.fromRGB(7, 12, 26),
	Mid = Color3.fromRGB(20, 34, 68),
	NavIdle = Color3.fromRGB(34, 50, 92),
	Off = Color3.fromRGB(78, 90, 116),
	Accents = {
		Biru = Color3.fromRGB(58, 150, 255),
		Cyan = Color3.fromRGB(40, 210, 235),
		Ungu = Color3.fromRGB(140, 110, 255),
		Mawar = Color3.fromRGB(255, 95, 150),
	},
}

local state = {
	Accent = THEME.Accents.Biru,
	Open = true,
	UserScale = 1,
	BlurEnabled = true,
	CurrentPage = "INFO",
}

local connections = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

-- ============================================================
-- 4. HELPER
-- ============================================================
local function create(class, props, children)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in props do
		if k == "Font" and typeof(v) == "Font" then
			inst.FontFace = v
		else
			inst[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function tween(inst, time, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local accentListeners = {}
local function onAccent(fn)
	table.insert(accentListeners, fn)
	fn(state.Accent)
end
local function setAccent(color)
	state.Accent = color
	for _, fn in accentListeners do
		fn(color)
	end
end

local function label(parent, text, size, props)
	local p = {
		BackgroundTransparency = 1,
		Text = text,
		TextSize = size,
		Font = THEME.Font,
		TextColor3 = THEME.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	}
	for k, v in props or {} do
		p[k] = v
	end
	return create("TextLabel", p)
end

-- Efek kaca: permukaan gelap, sudut bulat, border tipis, gradient halus
local function glass(frame, transparency, radius, strokeTransparency)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = math.clamp((transparency or 0.5) * CONFIG.GlassFactor, 0, 1)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 14), Parent = frame })
	create("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Transparency = math.clamp((strokeTransparency or 0.82) + 0.06, 0.55, 0.95),
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame,
	})
	create("UIGradient", { Color = ColorSequence.new(THEME.Mid, THEME.Dark), Rotation = 90, Parent = frame })
	return frame
end

local function addPress(btn)
	local s = create("UIScale", { Scale = 1, Parent = btn })
	connect(btn.MouseButton1Down, function() tween(s, 0.1, { Scale = 0.96 }) end)
	connect(btn.MouseButton1Up, function() tween(s, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end)
	connect(btn.MouseLeave, function() tween(s, 0.2, { Scale = 1 }) end)
end


-- ============================================================
-- 1b. FITUR: Auto Farm, Auto Bonus, Equip Best
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local FEAT = {
	farmDelay = 1,       -- delay Auto Farm (detik), diubah dari UI
	bonusCheck = 0.3,    -- seberapa sering cek popup bonus
	equipInterval = 5,   -- jeda Equip Best
	bonusName = "bonus", -- nama objek yang diklik di PullUpGui (tidak peka huruf besar/kecil)
}

-- token: naik tiap start/stop, loop lama otomatis berhenti
local tokens = { farm = 0, bonus = 0, equip = 0 }
local remotesFolder

local function fireRemote(name, ...)
	if not remotesFolder or not remotesFolder.Parent then
		remotesFolder = ReplicatedStorage:FindFirstChild("_NewRemotes")
	end
	local r = remotesFolder and remotesFolder:FindFirstChild(name)
	if r then pcall(r.FireServer, r, ...) end
end

-- ---------- Auto Farm: LaunchEvent -> tunggu -> LaunchCollect -> tunggu ----------
local function startFarm()
	tokens.farm += 1
	local my = tokens.farm
	task.spawn(function()
		while tokens.farm == my do
			fireRemote("LaunchEvent", 1, 1)
			task.wait(FEAT.farmDelay)
			if tokens.farm ~= my then break end
			fireRemote("LaunchCollect")
			task.wait(FEAT.farmDelay)
		end
	end)
end
local function stopFarm() tokens.farm += 1 end

-- ---------- Equip Best ----------
local function startEquip()
	tokens.equip += 1
	local my = tokens.equip
	task.spawn(function()
		while tokens.equip == my do
			fireRemote("EquipBestClowns")
			task.wait(FEAT.equipInterval)
		end
	end)
end
local function stopEquip() tokens.equip += 1 end

-- ---------- Auto Bonus: klik objek "Bonus" di PullUpGui ----------
local lastBonusClick = 0

local function isVisibleUnder(obj, root)
	local cur = obj
	while cur and cur ~= root do
		if cur:IsA("GuiObject") and not cur.Visible then return false end
		cur = cur.Parent
	end
	return true
end

local function findBonus(pull)
	for _, d in ipairs(pull:GetDescendants()) do
		if d:IsA("GuiObject")
			and d.Name:lower() == FEAT.bonusName
			and d.AbsoluteSize.X > 0 and d.AbsoluteSize.Y > 0
			and isVisibleUnder(d, pull) then
			return d
		end
	end
end

local function fireButton(btn)
	if type(getconnections) ~= "function" then return false end
	local fired = false
	for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down" }) do
		pcall(function()
			for _, c in ipairs(getconnections(btn[sig])) do
				c:Fire()
				fired = true
			end
		end)
		if fired then return true end
	end
	return false
end

local function virtualClick(obj)
	pcall(function()
		local inset = GuiService:GetGuiInset()
		local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
		task.wait(0.05)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
	end)
end

local function clickBonus(obj)
	if obj:IsA("GuiButton") and fireButton(obj) then return end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("GuiButton") and fireButton(d) then return end
	end
	virtualClick(obj)
end

local function startBonus()
	tokens.bonus += 1
	local my = tokens.bonus
	task.spawn(function()
		while tokens.bonus == my do
			local pull = playerGui:FindFirstChild("PullUpGui")
			if pull and pull.Enabled then
				local bonus = findBonus(pull)
				if bonus and os.clock() - lastBonusClick > 1 then
					lastBonusClick = os.clock()
					clickBonus(bonus)
				end
			end
			task.wait(FEAT.bonusCheck)
		end
	end)
end
local function stopBonus() tokens.bonus += 1 end

local function stopAllFeatures()
	stopFarm()
	stopEquip()
	stopBonus()
end

-- ============================================================
-- 5. ENVIRONMENT (langit, awan, blur)
-- ============================================================
local blur = create("BlurEffect", { Name = "TheRichHUB_Blur", Size = 0, Parent = Lighting })

local function setupEnvironment()
	if not CONFIG.ApplyEnvironment then return end
	task.wait(3) -- beri waktu BackgroundLoader (server) memasang asset
	if not Lighting:FindFirstChildOfClass("Sky") then
		create("Sky", { Name = "TheRichHUB_Sky", Parent = Lighting })
	end
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		create("Atmosphere", {
			Density = 0.3, Offset = 0.25,
			Color = Color3.fromRGB(190, 215, 255), Decay = Color3.fromRGB(120, 160, 230),
			Glare = 0.2, Haze = 1.2, Parent = Lighting,
		})
	end
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.4
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain and not terrain:FindFirstChildOfClass("Clouds") then
		create("Clouds", { Cover = 0.55, Density = 0.6, Color = Color3.new(1, 1, 1), Parent = terrain })
	end
end
task.spawn(setupEnvironment)

-- ============================================================
-- 6. ROOT GUI
-- ============================================================
local old = playerGui:FindFirstChild(CONFIG.Name)
if old then old:Destroy() end

local gui = create("ScreenGui", {
	Name = CONFIG.Name, ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100, Parent = playerGui,
})

-- Backdrop lembut (vignette biru) + gambar langit opsional
local backdrop = create("Frame", {
	Name = "Backdrop", Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = CONFIG.BackdropTransparency, BorderSizePixel = 0, Parent = gui,
}, {
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(90, 160, 255), Color3.fromRGB(10, 25, 60)),
		Rotation = 90, Parent = nil,
	}),
})
backdrop:FindFirstChildOfClass("UIGradient").Parent = backdrop
if CONFIG.BackgroundImageId ~= "" then
	create("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = CONFIG.BackgroundImageId,
		ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.2, ZIndex = 0, Parent = backdrop,
	})
end

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local restPos = UDim2.new(0.5, 0, 0.5, IS_TOUCH and 24 or 0)
local main = create("Frame", {
	Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = restPos,
	Size = UDim2.fromOffset(CONFIG.Design.X, CONFIG.Design.Y), BackgroundTransparency = 1, Parent = gui,
})
create("UICorner", { CornerRadius = UDim.new(0, 22), Parent = main })
-- Latar kaca dipisah dari CanvasGroup: UIGradient pada CanvasGroup akan ikut menggelapkan teks & isinya
local glassBG = create("Frame", { Name = "GlassBG", Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = main })
glass(glassBG, 0.45, 22, 0.75)
do -- garis cahaya aksen di tepi jendela
	local glow = create("UIStroke", {
		Color = state.Accent, Thickness = 1.5, Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = glassBG,
	})
	onAccent(function(c) glow.Color = c end)
end
local mainScale = create("UIScale", { Parent = main })
create("UIAspectRatioConstraint", { AspectRatio = 16 / 9, Parent = main })

local function fitScale()
	local vp = gui.AbsoluteSize
	local fit = math.min(vp.X * 0.92 / CONFIG.Design.X, vp.Y * (IS_TOUCH and 0.78 or 0.88) / CONFIG.Design.Y)
	return math.clamp(fit, 0.3, 1.35) * state.UserScale
end
local function updateScale()
	mainScale.Scale = fitScale()
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"), updateScale)
updateScale()

-- ============================================================
-- 7. HEADER
-- ============================================================
local function buildHeader()
	local header = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = main })
	create("Frame", {
		Size = UDim2.new(1, -32, 0, 1), Position = UDim2.new(0, 16, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = header,
	})

	-- garis aksen gradasi di bawah header
	local accentLine = create("Frame", {
		Size = UDim2.new(1, -32, 0, 2), Position = UDim2.new(0, 16, 1, -1),
		BackgroundColor3 = state.Accent, BorderSizePixel = 0, Parent = header,
	}, {
		create("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		}),
	})
	onAccent(function(c) accentLine.BackgroundColor3 = c end)

	-- chip LIVE + jam
	local chip = create("Frame", {
		Size = UDim2.fromOffset(150, 28), Position = UDim2.new(1, -250, 0, 14),
		BackgroundColor3 = THEME.Dark, BackgroundTransparency = 0.2, Parent = header,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.8, Thickness = 1 }),
	})
	local dot = create("Frame", {
		Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(12, 10),
		BackgroundColor3 = Color3.fromRGB(80, 230, 130), BorderSizePixel = 0, Parent = chip,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local clock = label(chip, "LIVE", 12, {
		Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -34, 1, 0), Font = THEME.FontBold,
	})
	task.spawn(function()
		local on = true
		while gui.Parent do
			clock.Text = "LIVE  " .. os.date("%H:%M:%S")
			tween(dot, 0.5, { BackgroundTransparency = on and 0.65 or 0 })
			on = not on
			task.wait(1)
		end
	end)

	local logo = create("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(20, 10), BackgroundColor3 = state.Accent, Parent = header }, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)), Rotation = 90, Transparency = NumberSequence.new(0.55, 0) }),
	})
	label(logo, "R", 22, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold })
	onAccent(function(c) logo.BackgroundColor3 = c end)

	label(header, CONFIG.Name, 21, { Position = UDim2.fromOffset(66, 6), Size = UDim2.fromOffset(300, 26), Font = THEME.FontBold })
	label(header, CONFIG.Subtitle, 12, { Position = UDim2.fromOffset(66, 31), Size = UDim2.fromOffset(400, 16), TextColor3 = THEME.SubText })

	local function winButton(text, xOffset, hoverColor)
		local b = create("TextButton", {
			Text = text, TextSize = 20, Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false,
			Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOffset, 0, 12),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, Parent = header,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		connect(b.MouseEnter, function() tween(b, 0.2, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.2 }) end)
		connect(b.MouseLeave, function() tween(b, 0.2, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7 }) end)
		addPress(b)
		return b
	end
	local minimizeBtn = winButton("−", -78, Color3.fromRGB(255, 190, 60))
	local closeBtn = winButton("×", -40, Color3.fromRGB(255, 80, 90))
	return header, minimizeBtn, closeBtn
end
local header, minimizeBtn, closeBtn = buildHeader()

-- Drag (mouse & touch)
do
	local dragging, startInput, startPos
	connect(header.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					restPos = main.Position
				end
			end)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- ============================================================
-- 8. KOMPONEN UI (toggle, stepper, tombol aksi)
-- ============================================================
local function row(parent, height)
	local r = create("TextButton", {
		Text = "", AutoButtonColor = false, Size = UDim2.new(1, -10, 0, height or 62), Parent = parent,
	})
	glass(r, 0.55, 14, 0.85)
	return r
end

local function rowTexts(r, title, desc)
	label(r, title, 15, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -150, 0, 20), Font = THEME.FontBold, TextTruncate = Enum.TextTruncate.AtEnd })
	label(r, desc or "", 13, { Position = UDim2.fromOffset(16, 33), Size = UDim2.new(1, -150, 0, 18), TextColor3 = THEME.SubText, TextTruncate = Enum.TextTruncate.AtEnd })
end

local function createToggle(parent, title, desc, default, callback)
	local r = row(parent)
	rowTexts(r, title, desc)
	local sw = create("Frame", {
		Size = UDim2.fromOffset(50, 28), Position = UDim2.new(1, -66, 0.5, -14), BackgroundColor3 = THEME.Off, Parent = r,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local knob = create("Frame", {
		Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sw,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local value = default
	local function paint(animate)
		local t = animate and 0.25 or 0
		tween(sw, t, { BackgroundColor3 = value and state.Accent or THEME.Off })
		tween(knob, t, { Position = value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back)
	end
	onAccent(function() paint(false) end)
	connect(r.MouseButton1Click, function()
		value = not value
		paint(true)
		if callback then task.spawn(callback, value) end
	end)
	addPress(r)
	return r
end

local function createStepper(parent, title, desc, initial, min, max, step, format, callback)
	local r = row(parent)
	rowTexts(r, title, desc)
	local value = initial
	local function stepBtn(text, x)
		local b = create("TextButton", {
			Text = text, TextSize = 18, Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false,
			Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, x, 0.5, -15),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Parent = r,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 9) }) })
		addPress(b)
		return b
	end
	local minus, plus = stepBtn("–", -138), stepBtn("+", -16)
	local valueLabel = label(r, format(value), 14, {
		Size = UDim2.fromOffset(70, 30), Position = UDim2.new(1, -106, 0.5, -15),
		TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold,
	})
	local function change(delta)
		value = math.clamp(math.round((value + delta) * 100) / 100, min, max)
		valueLabel.Text = format(value)
		callback(value)
	end
	connect(minus.MouseButton1Click, function() change(-step) end)
	connect(plus.MouseButton1Click, function() change(step) end)
	return r
end

local function createAction(parent, title, desc, buttonText, callback)
	local r = row(parent)
	rowTexts(r, title, desc)
	local b = create("TextButton", {
		Text = buttonText, TextSize = 13, Font = THEME.FontBold, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
		Size = UDim2.fromOffset(100, 32), Position = UDim2.new(1, -116, 0.5, -16), BackgroundColor3 = state.Accent, Parent = r,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	onAccent(function(c) b.BackgroundColor3 = c end)
	addPress(b)
	connect(b.MouseButton1Click, function() task.spawn(callback, b) end)
	return b
end

-- ============================================================
-- 9. HALAMAN
-- ============================================================
local content = create("Frame", {
	Name = "Content", Position = UDim2.fromOffset(222, 72), Size = UDim2.fromOffset(722, 452),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
})

local pages, pageOrder = {}, {}

local function newPage(name)
	local p = create("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content })
	pages[name] = p
	table.insert(pageOrder, name)
	return p
end

local function newSettingsPage(name, title, desc)
	local p = newPage(name)
	local sf = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.SubText,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = p,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }),
	})
	label(sf, title, 22, { Size = UDim2.new(1, 0, 0, 30), Font = THEME.FontBold, LayoutOrder = -2, AutoLocalize = false })
	label(sf, desc, 14, { Size = UDim2.new(1, 0, 0, 22), TextColor3 = THEME.SubText, LayoutOrder = -1 })
	return sf
end

-- ---------- HOME (gaya "Player Hub": kartu profil + info akun + detail game) ----------
local HARI = { "Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu" }
local BULAN = { "Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember" }

-- HTTP lewat fungsi request milik executor (di Studio/LocalScript biasa akan nil -> fallback)
local function httpGet(url)
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if not req then return nil end
	local ok, res = pcall(req, { Url = url, Method = "GET" })
	if ok and res and res.Body and (res.StatusCode == nil or res.StatusCode == 200) then
		local ok2, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res.Body) end)
		if ok2 then return data end
	end
	return nil
end

local function diffYMD(a, b) -- a = lebih awal, b = lebih akhir (tabel os.date)
	local y, m, d = b.year - a.year, b.month - a.month, b.day - a.day
	if d < 0 then
		m -= 1
		local pm, py = b.month - 1, b.year
		if pm < 1 then pm = 12; py -= 1 end
		d += os.date("!*t", os.time({ year = py, month = pm + 1, day = 0, hour = 12 })).day
	end
	if m < 0 then m += 12; y -= 1 end
	return y, m, d
end

local function fmtDur(s)
	s = math.max(0, math.floor(s))
	local h, m, sec = s // 3600, (s % 3600) // 60, s % 60
	if h > 0 then return ("%dj %dm %ds"):format(h, m, sec) end
	return ("%dm %ds"):format(m, sec)
end

local function buildHome()
	local p = newPage("INFO")
	local MarketplaceService = game:GetService("MarketplaceService")
	local LocalizationService = game:GetService("LocalizationService")
	local startClock = os.clock()

	local GREEN = Color3.fromRGB(90, 230, 140)
	local ACCENT = state.Accent
	local PURPLE = Color3.fromRGB(150, 120, 255)
	local YELLOW = Color3.fromRGB(255, 205, 70)
	local COL_W = 351 -- lebar tiap kolom (2 kolom + jarak 12 = 714)

	local function panel(parent, size, pos, stroke, radius, strokeT)
		local tinted = stroke ~= nil and stroke ~= Color3.new(1, 1, 1)
		return create("Frame", {
			Size = size, Position = pos or UDim2.new(), BackgroundColor3 = THEME.Dark, BackgroundTransparency = 0.3,
			BorderSizePixel = 0, Parent = parent,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, radius or 14) }),
			create("UIStroke", { Color = stroke or Color3.new(1, 1, 1), Thickness = 1, Transparency = tinted and 0.62 or 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
	end

	local function centered(parent, text, size, props)
		local q = { TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold }
		for k, v in props or {} do q[k] = v end
		return label(parent, text, size, q)
	end

	-- ============ SATU HALAMAN SCROLL (profil + info jadi satu) ============
	local list = create("ScrollingFrame", {
		Position = UDim2.new(), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = p,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) }),
	})
	local order = 0
	local function nextOrder() order += 1; return order end

	local cols = create("Frame", {
		Name = "Columns", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = nextOrder(), Parent = list,
	}, {
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function column(order)
		return create("Frame", {
			Name = "Col" .. order, LayoutOrder = order, Size = UDim2.fromOffset(COL_W, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Parent = cols,
		}, { create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	end
	local left, right = column(1), column(2)
	local cur = left -- kolom tujuan untuk header()/row()/dst

	-- ============ KARTU PROFIL (di atas) ============
	local card = create("Frame", { Name = "Profile", Size = UDim2.fromOffset(COL_W, 442), LayoutOrder = nextOrder(), Parent = left })
	glass(card, 0.5, 20, 0.45)
	card:FindFirstChildOfClass("UIStroke").Color = ACCENT

	create("Frame", { -- banner gradient ungu -> biru
		Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 84), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, Parent = card,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(150, 100, 235), Color3.fromRGB(50, 100, 210)), Rotation = 20 }),
	})

	local premium = panel(card, UDim2.fromOffset(108, 24), UDim2.new(1, -124, 0, 16), YELLOW, 12, 0)
	centered(premium, "PREMIUM", 11, { Size = UDim2.fromScale(1, 1), TextColor3 = YELLOW })

	local ring = create("Frame", {
		Size = UDim2.fromOffset(84, 84), Position = UDim2.fromOffset(16, 50), BackgroundTransparency = 1, Parent = card,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local ringStroke = create("UIStroke", { Thickness = 3.5, Color = Color3.new(1, 1, 1), Parent = ring })
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 150)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 205, 70)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 230, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 120, 255)),
		}),
		Rotation = 45, Parent = ringStroke,
	})
	local avatar = create("ImageLabel", {
		Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), BackgroundColor3 = THEME.Dark, Parent = ring,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then avatar.Image = img end
	end)
	create("Frame", { -- titik status online
		Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -18, 1, -18), BackgroundColor3 = GREEN, Parent = ring,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = THEME.Dark, Thickness = 2 }),
	})

	label(card, CONFIG.ProfileName or player.DisplayName, 18, {
		Position = UDim2.fromOffset(112, 96), Size = UDim2.new(1, -122, 0, 22), Font = THEME.FontBold, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(card, "@" .. player.Name, 12, { Position = UDim2.fromOffset(112, 118), Size = UDim2.new(1, -122, 0, 16), TextColor3 = ACCENT, Font = THEME.FontBold })

	local idPill = panel(card, UDim2.fromOffset(150, 24), UDim2.fromOffset(112, 140), Color3.new(1, 1, 1), 12, 0.4)
	local idBtn = create("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "ID  " .. player.UserId, TextSize = 12,
		Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false, Parent = idPill,
	})

	-- chip: hari bergabung, umur, ultah
	local function chip(x, w)
		local c = panel(card, UDim2.fromOffset(w, 24), UDim2.fromOffset(x, 178), Color3.fromRGB(120, 230, 200), 12, 0.35)
		return centered(c, "...", 12, { Size = UDim2.fromScale(1, 1) })
	end
	local chipDay, chipAge = chip(16, 154), chip(181, 154)

	-- 3 kartu angka: teman / pengikut / mengikuti
	local function statCard(x, color, title)
		local c = panel(card, UDim2.fromOffset(99, 62), UDim2.fromOffset(x, 214), color, 14, 0.1)
		local v = centered(c, "-", 22, { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 28), TextColor3 = color })
		centered(c, title, 11, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 14), TextColor3 = THEME.SubText })
		return v
	end
	local friendsVal = statCard(16, GREEN, "TEMAN")
	local followersVal = statCard(126, ACCENT, "PENGIKUT")
	local followingVal = statCard(236, PURPLE, "MENGIKUTI")

	-- jam & sesi
	local clockCard = panel(card, UDim2.fromOffset(319, 64), UDim2.fromOffset(16, 288), ACCENT, 14, 0.3)
	local clockLbl = label(clockCard, "--:--:--", 24, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(0.6, 0, 0, 30), Font = THEME.FontBold })
	local sessLbl = label(clockCard, "Sesi 0m 0s", 11, {
		Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0.5, -12, 0, 18), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GREEN, Font = THEME.FontBold,
	})
	local dateLbl = label(clockCard, "-", 12, { Position = UDim2.fromOffset(14, 38), Size = UDim2.new(1, -28, 0, 18), TextColor3 = THEME.SubText })

	-- ulang tahun akun + progress bar
	local anivCard = panel(card, UDim2.fromOffset(319, 64), UDim2.fromOffset(16, 362), GREEN, 14, 0.4)
	label(anivCard, "Ultah akun", 12, { Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(100, 18), Font = THEME.FontBold })
	local anivVal = label(anivCard, "-", 12, { Position = UDim2.fromOffset(112, 8), Size = UDim2.new(1, -120, 0, 18), Font = THEME.FontBold, TextTruncate = Enum.TextTruncate.AtEnd })
	local barBg = create("Frame", {
		Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = anivCard,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local barFill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN, BorderSizePixel = 0, Parent = barBg }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local function header(text)
		local h = create("Frame", { Size = UDim2.fromOffset(COL_W, 24), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = cur })
		create("Frame", {
			Position = UDim2.fromOffset(2, 6), Size = UDim2.fromOffset(3, 12), BackgroundColor3 = ACCENT, BorderSizePixel = 0, Parent = h,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		label(h, text, 12, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0), Font = THEME.FontBold, TextColor3 = THEME.SubText })
	end

	local function row(icon, title, height)
		local h = height or 38
		local r = panel(cur, UDim2.fromOffset(COL_W, h), nil, Color3.new(1, 1, 1), 12, 0.6)
		r.LayoutOrder = nextOrder()
		label(r, title, 13, { Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(100, h), Font = THEME.FontBold, TextColor3 = THEME.SubText })
		return label(r, "-", 13, {
			Position = UDim2.fromOffset(120, 0), Size = UDim2.new(1, -130, 1, 0), Font = THEME.FontBold,
			TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end

	local function button(parent, text, size, pos, onClick)
		local b = create("TextButton", {
			Size = size, Position = pos or UDim2.new(), BackgroundColor3 = THEME.Dark, BackgroundTransparency = 0.35, Text = text,
			TextSize = 12, Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false, BorderSizePixel = 0, Parent = parent,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 12) }),
			create("UIStroke", { Color = ACCENT, Thickness = 1.5, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
		addPress(b)
		connect(b.MouseButton1Click, function() onClick(b) end)
		return b
	end

	-- --- sedang bermain ---
	header("SEDANG BERMAIN")
	local gameCard = panel(cur, UDim2.fromOffset(COL_W, 96), nil, Color3.new(1, 1, 1), 14, 0.5)
	gameCard.LayoutOrder = nextOrder()
	local icon = create("ImageLabel", {
		Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(72, 72), BackgroundColor3 = THEME.Dark,
		Image = "rbxthumb://type=GameIcon&id=" .. game.GameId .. "&w=150&h=150", Parent = gameCard,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		create("UIStroke", { Color = YELLOW, Thickness = 2 }),
	})
	local gameName = label(gameCard, game.Name ~= "" and game.Name or "Game", 14, {
		Position = UDim2.fromOffset(96, 8), Size = UDim2.new(1, -106, 0, 38), Font = THEME.FontBold, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local gameCreator = label(gameCard, "oleh -", 11, { Position = UDim2.fromOffset(96, 50), Size = UDim2.new(1, -106, 0, 16), TextColor3 = THEME.SubText })
	local gamePlayers = label(gameCard, "-", 12, { Position = UDim2.fromOffset(96, 68), Size = UDim2.new(1, -106, 0, 18), TextColor3 = GREEN, Font = THEME.FontBold })

	-- --- detail akun ---
	cur = right
	header("DETAIL AKUN")
	local createdVal = row("", "Dibuat")
	local ageVal = row("", "Umur akun")
	local localeVal = row("", "Locale")
	local teamVal = row("", "Team")
	local deviceVal = row("", "Device")
	local execVal = row("", "Executor")
	local bioVal = row("", "Bio", 52)

	-- --- detail game ---
	cur = left
	header("DETAIL GAME")
	local placeVal = row("", "Place ID")
	local jobVal = row("", "Job ID", 52)
	local playerVal = row("", "Player")
	local serverVal = row("", "Server")

	-- --- tombol ---
	local btnRow = create("Frame", { Size = UDim2.fromOffset(COL_W, 36), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = cur })
	local function copyText(text, btn, restore)
		local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
		local ok = fn and pcall(fn, text)
		btn.Text = ok and "Tersalin" or "Tidak didukung"
		task.delay(1.2, function() btn.Text = restore end)
	end
	button(btnRow, "Salin Place ID", UDim2.new(0.5, -4, 1, 0), UDim2.new(), function(b) copyText(tostring(game.PlaceId), b, "Salin Place ID") end)
	button(btnRow, "Salin Job ID", UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), function(b) copyText(game.JobId, b, "Salin Job ID") end)
	local refreshBtn = button(cur, "Refresh Info", UDim2.fromOffset(COL_W, 36), nil, function() end)
	refreshBtn.LayoutOrder = nextOrder()
	connect(idBtn.MouseButton1Click, function() copyText(tostring(player.UserId), idBtn, "ID  " .. player.UserId) end)

	-- ============ SEBELAH KARTU PROFIL (kolom kanan) ============
	local RW = COL_W
	local TeleportService = game:GetService("TeleportService")
	local StatsService = game:GetService("Stats")

	local function rtitle(parent, text)
		label(parent, text, 12, { Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 18), Font = THEME.FontBold, TextColor3 = THEME.SubText })
	end

	-- 1) statistik server
	local statPanel = panel(right, UDim2.new(1, 0, 0, 120), nil, ACCENT, 14, 0.3)
	statPanel.LayoutOrder = -3
	rtitle(statPanel, "STATISTIK SERVER")
	local function miniStat(i, color, title)
		local c = panel(statPanel, UDim2.fromOffset(74, 62), UDim2.fromOffset(14 + (i - 1) * 83, 40), color, 12, 0.15)
		local v = centered(c, "-", 18, { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 26), TextColor3 = color })
		centered(c, title, 11, { Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 14), TextColor3 = THEME.SubText })
		return v
	end
	local sFps = miniStat(1, GREEN, "FPS")
	local sPing = miniStat(2, YELLOW, "PING")
	local sPlayers = miniStat(3, ACCENT, "PLAYER")
	local sUp = miniStat(4, PURPLE, "UPTIME")

	-- 2) tombol cepat
	local quickPanel = panel(right, UDim2.new(1, 0, 0, 128), nil, ACCENT, 14, 0.3)
	quickPanel.LayoutOrder = -2
	rtitle(quickPanel, "TOMBOL CEPAT")
	local BW = (RW - 28 - 8) / 2
	local function qbtn(col, row, text, fn)
		return button(quickPanel, text, UDim2.fromOffset(BW, 34), UDim2.fromOffset(14 + col * (BW + 8), 40 + row * 42), fn)
	end
	local function flash(b, msg, restore)
		b.Text = msg
		task.delay(1.4, function() if b.Parent then b.Text = restore end end)
	end
	qbtn(0, 0, "Salin User ID", function(b) copyText(tostring(player.UserId), b, "Salin User ID") end)
	qbtn(1, 0, "Salin Link Profil", function(b) copyText("https://www.roblox.com/users/" .. player.UserId .. "/profile", b, "Salin Link Profil") end)
	qbtn(0, 1, "Rejoin", function(b)
		flash(b, "Menghubungkan...", "Rejoin")
		pcall(function()
			if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player)
			else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
		end)
	end)
	qbtn(1, 1, "Server Hop", function(b)
		b.Text = "Mencari server..."
		task.spawn(function()
			local data = httpGet("https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			local target
			for _, sv in (data and data.data) or {} do
				if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then target = sv.id break end
			end
			if target then
				flash(b, "Pindah...", "Server Hop")
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target, player) end)
			else
				flash(b, "Server tidak ada", "Server Hop")
			end
		end)
	end)

	-- 3) tentang
	local aboutPanel = panel(right, UDim2.new(1, 0, 0, 178), nil, ACCENT, 14, 0.3)
	aboutPanel.LayoutOrder = -1
	rtitle(aboutPanel, "TENTANG")
	local function arow(i, key, val)
		label(aboutPanel, key, 13, { Position = UDim2.fromOffset(14, 40 + (i - 1) * 26), Size = UDim2.fromOffset(90, 18), TextColor3 = THEME.SubText })
		return label(aboutPanel, val, 13, {
			Position = UDim2.fromOffset(110, 40 + (i - 1) * 26), Size = UDim2.new(1, -124, 0, 18), Font = THEME.FontBold,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	arow(1, "Script", CONFIG.Name)
	arow(2, "Versi", (CONFIG.Subtitle:match("v[%d%.]+")) or "-")
	arow(3, "Pemain", player.DisplayName .. " (@" .. player.Name .. ")")
	local aExec = arow(4, "Executor", "-")
	local okX, xn, xv = pcall(identifyexecutor)
	aExec.Text = (okX and xn) and (xn .. (xv and (" " .. xv) or "")) or "Tidak terdeteksi"
	arow(5, "Dimuat", os.date("%H:%M:%S • %d/%m/%Y"))

	-- update statistik: FPS tiap 0.5 dtk, lainnya tiap 1 dtk
	do
		local frames, last = 0, os.clock()
		connect(RunService.RenderStepped, function()
			frames += 1
			local now = os.clock()
			if now - last >= 0.5 then
				sFps.Text = tostring(math.round(frames / (now - last)))
				frames, last = 0, now
			end
		end)
	end
	task.spawn(function()
		while card.Parent do
			local okP, ping = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			sPing.Text = okP and (math.round(ping) .. "ms") or "-"
			sPlayers.Text = ("%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers)
			sUp.Text = fmtDur(workspace.DistributedGameTime)
			task.wait(1)
		end
	end)

	-- ============ ISI DATA ============
	local function fmtDate(t) return ("%s, %d %s %d"):format(HARI[t.wday], t.day, BULAN[t.month], t.year) end

	local function applyJoin(joinT)
		local nowT = os.time()
		local jd, nd = os.date("!*t", joinT), os.date("!*t", nowT)
		local y, m, d = diffYMD(jd, nd)
		local totalDays = math.floor((nowT - joinT) / 86400)

		createdVal.Text = fmtDate(jd)
		local parts = {}
		if y > 0 then table.insert(parts, y .. " tahun") end
		if m > 0 or y > 0 then table.insert(parts, m .. " bulan") end
		table.insert(parts, d .. " hari")
		ageVal.Text = table.concat(parts, " ") .. (" (%d hari)"):format(totalDays)
		chipDay.Text = "Gabung " .. HARI[jd.wday]
		chipAge.Text = y > 0 and ("%d tahun lebih"):format(y) or ("%d bulan"):format(m)

		local todayMid = os.time({ year = nd.year, month = nd.month, day = nd.day, hour = 0 })
		local annivYear = nd.year
		local annivT = os.time({ year = annivYear, month = jd.month, day = jd.day, hour = 0 })
		if annivT < todayMid then
			annivYear += 1
			annivT = os.time({ year = annivYear, month = jd.month, day = jd.day, hour = 0 })
		end
		local daysLeft = math.floor((annivT - todayMid) / 86400 + 0.5)
		local nth = annivYear - jd.year
		anivVal.Text = daysLeft == 0 and ("Hari ini! (tahun ke-%d)"):format(nth) or ("%d hari lagi (tahun ke-%d)"):format(daysLeft, nth)
		tween(barFill, 0.9, { Size = UDim2.fromScale(math.clamp((365 - daysLeft) / 365, 0, 1), 1) })
	end

	local function refreshStatic()
		applyJoin(os.time() - player.AccountAge * 86400) -- fallback dari AccountAge
		bioVal.Text = (CONFIG.ProfileBio and CONFIG.ProfileBio ~= "") and CONFIG.ProfileBio or "-"
		followersVal.Text = CONFIG.ProfileFollowers and tostring(CONFIG.ProfileFollowers) or "-"
		followingVal.Text = CONFIG.ProfileFollowing and tostring(CONFIG.ProfileFollowing) or "-"

		local okL, loc = pcall(function() return LocalizationService.RobloxLocaleId end)
		localeVal.Text = okL and loc or "-"
		teamVal.Text = player.Team and player.Team.Name or "-"
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(0, 0)
		local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		deviceVal.Text = ("%s • %d×%d"):format(mobile and "HP / Tablet" or "PC", math.floor(vp.X), math.floor(vp.Y))
		local okE, en, ev = pcall(identifyexecutor)
		execVal.Text = (okE and en) and (en .. (ev and (" " .. ev) or "")) or "Tidak terdeteksi"
		placeVal.Text = tostring(game.PlaceId)
		jobVal.Text = game.JobId ~= "" and game.JobId or "-"
	end

	local function refreshRemote()
		task.spawn(function() -- teman (API game, selalu bisa)
			local ok, count = pcall(function()
				local pages = Players:GetFriendsAsync(player.UserId)
				local n = 0
				while true do
					n += #pages:GetCurrentPage()
					if pages.IsFinished then break end
					pages:AdvanceToNextPageAsync()
				end
				return n
			end)
			if ok then friendsVal.Text = tostring(count) end
		end)
		task.spawn(function() -- pengikut / mengikuti / bio / tanggal dibuat (butuh request executor)
			local id = player.UserId
			local f = httpGet("https://friends.roproxy.com/v1/users/" .. id .. "/followers/count")
			if f and f.count then followersVal.Text = tostring(f.count) end
			local g = httpGet("https://friends.roproxy.com/v1/users/" .. id .. "/followings/count")
			if g and g.count then followingVal.Text = tostring(g.count) end
			local u = httpGet("https://users.roproxy.com/v1/users/" .. id)
			if u then
				if u.description then bioVal.Text = u.description ~= "" and u.description or "-" end
				local y, mo, d, h, mi, s = tostring(u.created or ""):match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
				if y then
					applyJoin(os.time({ year = tonumber(y), month = tonumber(mo), day = tonumber(d), hour = tonumber(h), min = tonumber(mi), sec = tonumber(s) }))
				end
			end
		end)
		task.spawn(function() -- info game
			local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
			if ok and info then
				gameName.Text = info.Name or gameName.Text
				gameCreator.Text = "oleh " .. ((info.Creator and info.Creator.Name) or "-")
			end
		end)
	end

	connect(refreshBtn.MouseButton1Click, function()
		refreshBtn.Text = "Memuat..."
		refreshStatic()
		refreshRemote()
		task.delay(1, function() refreshBtn.Text = "Refresh Info" end)
	end)

	local function tick1()
		local t = os.date("*t")
		clockLbl.Text = ("%02d:%02d:%02d"):format(t.hour, t.min, t.sec)
		dateLbl.Text = fmtDate(t)
		sessLbl.Text = "Sesi " .. fmtDur(os.clock() - startClock)
		local up = fmtDur(workspace.DistributedGameTime)
		serverVal.Text = "hidup " .. up
		local cnt = ("%d/%d"):format(#Players:GetPlayers(), Players.MaxPlayers)
		playerVal.Text = cnt
		gamePlayers.Text = "" .. cnt .. " player • hidup " .. up
	end

	refreshStatic()
	refreshRemote()
	tick1()
	task.spawn(function()
		while card.Parent do
			task.wait(1)
			tick1()
		end
	end)
end

-- ---------- MISC ----------
local function buildMisc()
	local sf = newSettingsPage("Misc", "Misc", "Anti lag, anti AFK, rejoin, dan server hop.")
	local TeleportService = game:GetService("TeleportService")
	local VirtualUser = game:GetService("VirtualUser")

	-- ===== ANTI LAG =====
	local lag = {
		on = false, parts = setmetatable({}, { __mode = "k" }), fx = setmetatable({}, { __mode = "k" }),
		shadows = nil, quality = nil, conn = nil,
	}
	local FX = { "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles", "Beam" }
	local function lagApply(d)
		if d:IsA("BasePart") then
			if not lag.parts[d] then lag.parts[d] = { d.Material, d.Reflectance, d.CastShadow } end
			d.Material, d.Reflectance, d.CastShadow = Enum.Material.Plastic, 0, false
			return
		end
		for _, cls in FX do
			if d:IsA(cls) then
				if lag.fx[d] == nil then lag.fx[d] = d.Enabled end
				d.Enabled = false
				return
			end
		end
	end
	local function setAntiLag(v)
		lag.on = v
		if v then
			lag.shadows = Lighting.GlobalShadows
			Lighting.GlobalShadows = false
			pcall(function()
				lag.quality = settings().Rendering.QualityLevel
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			for _, e in Lighting:GetChildren() do
				if e:IsA("PostEffect") and lag.fx[e] == nil then lag.fx[e] = e.Enabled; e.Enabled = false end
			end
			lag.conn = connect(workspace.DescendantAdded, function(d) if lag.on then lagApply(d) end end)
			for i, d in workspace:GetDescendants() do
				if not lag.on then return end
				lagApply(d)
				if i % 400 == 0 then task.wait() end
			end
		else
			if lag.conn then lag.conn:Disconnect(); lag.conn = nil end
			if lag.shadows ~= nil then Lighting.GlobalShadows = lag.shadows end
			pcall(function() if lag.quality then settings().Rendering.QualityLevel = lag.quality end end)
			for d, o in lag.parts do
				if d.Parent then d.Material, d.Reflectance, d.CastShadow = o[1], o[2], o[3] end
			end
			for d, en in lag.fx do
				if d.Parent then d.Enabled = en end
			end
			table.clear(lag.parts)
			table.clear(lag.fx)
		end
	end
	createToggle(sf, "Anti Lag", "Kurangi grafik: tanpa bayangan, efek, dan tekstur berat supaya FPS naik", false, setAntiLag)

	-- ===== ANTI AFK =====
	local afkConn
	createToggle(sf, "Anti AFK", "Cegah kamu ter-kick karena diam terlalu lama (20 menit)", false, function(v)
		if v then
			afkConn = connect(player.Idled, function()
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end)
		elseif afkConn then
			afkConn:Disconnect()
			afkConn = nil
		end
	end)

	-- ===== REJOIN =====
	createAction(sf, "Rejoin", "Masuk ulang ke server yang sama (kalau sendirian, cari server baru)", "Rejoin", function(b)
		b.Text = "..."
		pcall(function()
			if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player)
			else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
		end)
		task.delay(3, function() if b.Parent then b.Text = "Rejoin" end end)
	end)

	-- ===== SERVER HOP =====
	createAction(sf, "Server Hop", "Pindah ke server lain yang belum penuh (butuh executor dengan request HTTP)", "Hop", function(b)
		b.Text = "..."
		local data = httpGet("https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		local target
		for _, sv in (data and data.data) or {} do
			if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then target = sv.id break end
		end
		if target then
			b.Text = "OK"
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target, player) end)
		else
			b.Text = "Gagal"
		end
		task.delay(2, function() if b.Parent then b.Text = "Hop" end end)
	end)
end

-- ---------- komponen tambahan (collapsible, mini toggle, info) ----------
local function createCollapsible(parent, title, desc, onToggle)
	local wrap = create("Frame", {
		Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = parent,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	local head = create("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = 1, Parent = wrap })
	glass(head, 0.55, 14, 0.85)
	label(head, title, 15, { Position = UDim2.fromOffset(16, 9), Size = UDim2.new(1, -170, 0, 20), Font = THEME.FontBold })
	local descLbl = label(head, desc or "", 13, { Position = UDim2.fromOffset(16, 31), Size = UDim2.new(1, -170, 0, 18), TextColor3 = THEME.SubText })
	local chev = label(head, "›", 26, {
		Position = UDim2.new(1, -36, 0, 0), Size = UDim2.fromOffset(24, 56), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold,
		TextColor3 = THEME.SubText,
	})
	local body = create("Frame", {
		Size = UDim2.new(1, -16, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = wrap,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	addPress(head)
	local open = false
	connect(head.MouseButton1Click, function()
		open = not open
		body.Visible = open
		tween(chev, 0.2, { Rotation = open and 90 or 0 })
		if onToggle then task.spawn(onToggle, open, body) end
	end)
	return { wrap = wrap, head = head, body = body, setDesc = function(t) descLbl.Text = t end, isOpen = function() return open end }
end

local function miniRow(parent, height)
	local r = create("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, height or 38), Parent = parent })
	glass(r, 0.6, 10, 0.88)
	return r
end

local function miniToggle(parent, text, default, callback)
	local r = miniRow(parent, 38)
	label(r, text, 13, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -90, 1, 0), Font = THEME.FontBold })
	local sw = create("Frame", {
		Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = THEME.Off, Parent = r,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local knob = create("Frame", {
		Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sw,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local value = default and true or false
	local function paint(animate)
		local t = animate and 0.2 or 0
		tween(sw, t, { BackgroundColor3 = value and state.Accent or THEME.Off })
		tween(knob, t, { Position = value and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3) })
	end
	onAccent(function() paint(false) end)
	connect(r.MouseButton1Click, function()
		value = not value
		paint(true)
		if callback then callback(value) end
	end)
	return r
end

local function createInfo(parent, title, text)
	local r = create("Frame", { Size = UDim2.new(1, -10, 0, 62), Parent = parent })
	glass(r, 0.55, 14, 0.85)
	label(r, title, 15, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20), Font = THEME.FontBold })
	return label(r, text, 13, { Position = UDim2.fromOffset(16, 33), Size = UDim2.new(1, -32, 0, 18), TextColor3 = THEME.SubText, TextTruncate = Enum.TextTruncate.AtEnd })
end

local function clearBody(body)
	for _, ch in ipairs(body:GetChildren()) do
		if not ch:IsA("UIListLayout") then ch:Destroy() end
	end
end

-- ---------- input angka bebas (untuk delay) ----------
local function createInput(parent, title, desc, initial, callback)
	local r = row(parent)
	rowTexts(r, title, desc)
	local last = initial
	local box = create("TextBox", {
		Text = tostring(initial), PlaceholderText = "detik", TextSize = 14, Font = THEME.FontBold,
		TextColor3 = THEME.Text, PlaceholderColor3 = THEME.SubText, ClearTextOnFocus = false,
		Size = UDim2.fromOffset(90, 32), Position = UDim2.new(1, -106, 0.5, -16),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.82, Parent = r,
	}, { create("UICorner", { CornerRadius = UDim.new(0, 9) }) })
	connect(box.FocusLost, function()
		local n = tonumber(box.Text)
		if n and n >= 0 then
			last = n
			callback(n)
		else
			box.Text = tostring(last)
		end
	end)
	return r
end

-- ---------- FARM ----------
local function buildFarm()
	local sf = newSettingsPage("FARM", "Farm", "Auto Farm, Auto Bonus, dan Equip Best.")

	createToggle(sf, "Auto Farm", "LaunchEvent lalu LaunchCollect bergantian, tidak bareng", false, function(v)
		if v then startFarm() else stopFarm() end
	end)

	createInput(sf, "Delay Auto Farm", "Jeda antar Launch dan Collect (detik, bebas diisi)", FEAT.farmDelay, function(n)
		FEAT.farmDelay = n
	end)

	createToggle(sf, "Auto Bonus", "Klik otomatis \"Bonus\" saat popup PullUpGui muncul", false, function(v)
		if v then startBonus() else stopBonus() end
	end)

	createToggle(sf, "Equip Best", "Pasang clown terbaik otomatis (tiap 5 detik)", false, function(v)
		if v then startEquip() else stopEquip() end
	end)
end

-- ---------- TAB KOSONG (tab tetap ada, fitur dihapus) ----------
local fullbrightOriginal -- dipakai closeUI (tetap dipertahankan)
local fpsLabel -- dipakai FPS counter (nil = tidak ada label FPS)

buildHome()
buildFarm()
buildMisc()

-- FPS counter
do
	local frames, last = 0, os.clock()
	connect(RunService.RenderStepped, function()
		frames += 1
		local now = os.clock()
		if now - last >= 0.5 then
			if fpsLabel then fpsLabel.Text = tostring(math.round(frames / (now - last))) end
			frames, last = 0, now
		end
	end)
end

-- ============================================================
-- 10. SIDEBAR + PINDAH HALAMAN (TweenService)
-- ============================================================
local navItems = {}

local function paintNav(item)
	local active = item.name == state.CurrentPage
	tween(item.button, 0.25, active
		and { BackgroundColor3 = state.Accent, BackgroundTransparency = 0.8 }
		or { BackgroundColor3 = THEME.NavIdle, BackgroundTransparency = item.hover and 0.55 or 0.8 })
	tween(item.stroke, 0.25, { Color = active and state.Accent or Color3.new(1, 1, 1), Transparency = active and 0.45 or 0.92 })
	tween(item.tile, 0.25, { BackgroundColor3 = active and state.Accent or THEME.NavIdle })
	tween(item.tileText, 0.25, { TextColor3 = active and Color3.new(1, 1, 1) or THEME.SubText })
	tween(item.indicator, 0.25, { BackgroundTransparency = active and 0 or 1 })
	tween(item.text, 0.25, { TextColor3 = active and Color3.new(1, 1, 1) or (item.hover and THEME.Text or THEME.SubText) })
end

local switchToken = 0
local function switchPage(name)
	if name == state.CurrentPage or not pages[name] then return end
	switchToken += 1
	local token = switchToken
	local oldPage, newPage_ = pages[state.CurrentPage], pages[name]
	local dir = table.find(pageOrder, name) > table.find(pageOrder, state.CurrentPage) and 1 or -1
	state.CurrentPage = name

	tween(oldPage, 0.15, { Position = UDim2.fromOffset(-24 * dir, 0) })
	task.delay(0.15, function()
		if token ~= switchToken then return end
		oldPage.Visible = false
		oldPage.Position = UDim2.new()
		newPage_.Position = UDim2.fromOffset(28 * dir, 0)
		newPage_.Visible = true
		tween(newPage_, 0.3, { Position = UDim2.fromOffset(0, 0) })
	end)
	for _, item in navItems do paintNav(item) end
end

local function buildSidebar()
	local sidebar = create("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(16, 72), Size = UDim2.fromOffset(190, 452), Parent = main })
	glass(sidebar, 0.55, 18, 0.82)
	create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = sidebar })
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })

	for i, nav in CONFIG.Nav do
		local b = create("TextButton", {
			Name = nav.Name, LayoutOrder = i, Text = "", AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = THEME.NavIdle, BackgroundTransparency = 0.8, Parent = sidebar,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		local stroke = create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.92, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		local indicator = create("Frame", {
			Size = UDim2.fromOffset(3, 22), Position = UDim2.fromOffset(4, 16), BackgroundColor3 = state.Accent,
			BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		onAccent(function(c) indicator.BackgroundColor3 = c end)
		local tile = create("Frame", {
			Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14, 10), BackgroundColor3 = THEME.NavIdle, BorderSizePixel = 0, Parent = b,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		local tileText = label(tile, nav.Icon, 17, {
			Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold, TextColor3 = THEME.SubText,
		})
		local text = label(b, nav.Label or nav.Name, 15, {
			Position = UDim2.fromOffset(58, 9), Size = UDim2.new(1, -64, 0, 18), Font = THEME.FontBold, TextColor3 = THEME.SubText, AutoLocalize = false,
		})
		label(b, nav.Sub or "", 12, {
			Position = UDim2.fromOffset(58, 28), Size = UDim2.new(1, -64, 0, 16), TextColor3 = THEME.SubText, TextTransparency = 0.2,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local item = { name = nav.Name, button = b, stroke = stroke, tile = tile, tileText = tileText, indicator = indicator, text = text, hover = false }
		navItems[nav.Name] = item
		addPress(b)
		connect(b.MouseEnter, function() item.hover = true; paintNav(item) end)
		connect(b.MouseLeave, function() item.hover = false; paintNav(item) end)
		connect(b.MouseButton1Click, function() switchPage(nav.Name) end)
	end
	onAccent(function()
		for _, item in navItems do paintNav(item) end
	end)

	-- hint tombol toggle
	label(main, CONFIG.ToggleKey.Name .. "  untuk buka / tutup", 11, {
		Position = UDim2.fromOffset(28, 430), Size = UDim2.fromOffset(170, 18), TextColor3 = THEME.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	-- kartu profil di dasar sidebar
	local card = create("Frame", { Name = "ProfileFooter", Position = UDim2.fromOffset(26, 452), Size = UDim2.fromOffset(170, 60), Parent = main })
	glass(card, 0.5, 14, 0.7)
	local av = create("ImageLabel", {
		Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = THEME.Dark,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150", Parent = card,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local avStroke = create("UIStroke", { Color = state.Accent, Thickness = 2, Parent = av })
	onAccent(function(c) avStroke.Color = c end)
	create("Frame", {
		Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(40, 40), BackgroundColor3 = Color3.fromRGB(80, 230, 130),
		BorderSizePixel = 0, Parent = card,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Color = THEME.Dark, Thickness = 2 }),
	})
	label(card, player.DisplayName, 14, {
		Position = UDim2.fromOffset(58, 11), Size = UDim2.new(1, -64, 0, 18), Font = THEME.FontBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	label(card, "@" .. player.Name, 12, {
		Position = UDim2.fromOffset(58, 30), Size = UDim2.new(1, -64, 0, 16), TextColor3 = THEME.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end
buildSidebar()

pages[state.CurrentPage].Visible = true

-- ============================================================
-- 11. MINIMIZE / CLOSE / REOPEN
-- ============================================================
local reopen = create("TextButton", {
	Name = "Reopen", Text = "", AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(160, 40), Visible = false, Parent = gui,
})
glass(reopen, 0.35, 20, 0.7)
label(reopen, "Buka " .. CONFIG.Name, 14, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold })
local reopenScale = create("UIScale", { Scale = 0, Parent = reopen })

local function setOpen(open)
	if state.Open == open then return end
	state.Open = open
	if open then
		tween(reopenScale, 0.2, { Scale = 0 })
		task.delay(0.2, function() if state.Open then reopen.Visible = false end end)
		backdrop.Visible = true
		main.Visible = true
		mainScale.Scale = fitScale() * 0.9
		main.Position = restPos + UDim2.fromOffset(0, 24)
		tween(mainScale, 0.4, { Scale = fitScale() }, Enum.EasingStyle.Back)
		tween(main, 0.4, { Position = restPos })
		tween(backdrop, 0.45, { BackgroundTransparency = CONFIG.BackdropTransparency })
		tween(blur, 0.45, { Size = state.BlurEnabled and CONFIG.BlurSize or 0 })
	else
		tween(mainScale, 0.3, { Scale = fitScale() * 0.88 })
		tween(main, 0.3, { Position = restPos + UDim2.fromOffset(0, 24) })
		tween(backdrop, 0.35, { BackgroundTransparency = 1 })
		tween(blur, 0.35, { Size = 0 })
		task.delay(0.35, function()
			if state.Open then return end
			main.Visible = false
			backdrop.Visible = false
			reopen.Visible = true
			reopenScale.Scale = 0
			tween(reopenScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
	end
end

local function destroyAll()
	pcall(stopAllFeatures)
	if fullbrightOriginal then
		Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(fullbrightOriginal)
	end
	for _, c in connections do c:Disconnect() end
	pcall(function() blur:Destroy() end)
	pcall(function() gui:Destroy() end)
end

local function closeUI()
	tween(mainScale, 0.3, { Scale = fitScale() * 0.88 })
	tween(main, 0.3, { Position = restPos + UDim2.fromOffset(0, 24) })
	tween(backdrop, 0.3, { BackgroundTransparency = 1 })
	tween(blur, 0.3, { Size = 0 })
	task.wait(0.35)
	destroyAll()
end

-- ---------- Dialog konfirmasi close (English) ----------
local confirm = create("TextButton", {
	Name = "ConfirmClose", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 50, Parent = gui,
})
local dlg = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(400, 196), Parent = confirm,
})
glass(dlg, 0.2, 18, 0.7)
local dlgScale = create("UIScale", { Scale = 1, Parent = dlg })
local DANGER = Color3.fromRGB(255, 84, 96)
create("Frame", {
	Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(24, 24), BackgroundColor3 = DANGER, BackgroundTransparency = 0.78,
	BorderSizePixel = 0, Parent = dlg,
}, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	create("UIStroke", { Color = DANGER, Thickness = 1.5, Transparency = 0.2 }),
	label(nil, "!", 22, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold, TextColor3 = DANGER }),
})
label(dlg, "Close " .. CONFIG.Name .. "?", 20, { Position = UDim2.fromOffset(78, 24), Size = UDim2.new(1, -100, 0, 26), Font = THEME.FontBold })
label(dlg, "This will remove the interface and stop all running features. You will need to run the script again to reopen it.", 14, {
	Position = UDim2.fromOffset(78, 54), Size = UDim2.new(1, -102, 0, 64), TextColor3 = THEME.SubText,
	TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
})

local function dlgButton(text, xScale, xOff, fill, fillT, textColor)
	local b = create("TextButton", {
		Text = text, TextSize = 15, Font = THEME.FontBold, TextColor3 = textColor, AutoButtonColor = false,
		Size = UDim2.new(0.5, -17, 0, 40), Position = UDim2.new(xScale, xOff, 1, -62),
		BackgroundColor3 = fill, BackgroundTransparency = fillT, Parent = dlg,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 11) }),
		create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.88, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	addPress(b)
	connect(b.MouseEnter, function() tween(b, 0.15, { BackgroundTransparency = math.max(0, fillT - 0.15) }) end)
	connect(b.MouseLeave, function() tween(b, 0.15, { BackgroundTransparency = fillT }) end)
	return b
end
local cancelBtn = dlgButton("Cancel", 0, 24, THEME.NavIdle, 0.45, THEME.Text)
local confirmBtn = dlgButton("Close", 0.5, 7, DANGER, 0.1, Color3.new(1, 1, 1))

local function dlgBase() return math.clamp(gui.AbsoluteSize.Y / 450, 0.7, 1.15) end
local function showConfirm()
	confirm.Visible = true
	confirm.BackgroundTransparency = 1
	dlgScale.Scale = dlgBase() * 0.9
	tween(confirm, 0.2, { BackgroundTransparency = 0.45 })
	tween(dlgScale, 0.3, { Scale = dlgBase() }, Enum.EasingStyle.Back)
end
local function hideConfirm()
	tween(confirm, 0.15, { BackgroundTransparency = 1 })
	tween(dlgScale, 0.15, { Scale = dlgBase() * 0.9 })
	task.delay(0.15, function() confirm.Visible = false end)
end
connect(cancelBtn.MouseButton1Click, hideConfirm)
connect(confirmBtn.MouseButton1Click, function()
	confirm.Visible = false
	task.spawn(closeUI)
end)
connect(confirm.MouseButton1Click, hideConfirm)

connect(minimizeBtn.MouseButton1Click, function() setOpen(false) end)
connect(closeBtn.MouseButton1Click, showConfirm)
connect(reopen.MouseButton1Click, function() setOpen(true) end)
addPress(reopen)
connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == CONFIG.ToggleKey then setOpen(not state.Open) end
end)

-- Animasi masuk awal
mainScale.Scale = fitScale() * 0.9
main.Position = restPos + UDim2.fromOffset(0, 30)
backdrop.BackgroundTransparency = 1
tween(mainScale, 0.6, { Scale = fitScale() }, Enum.EasingStyle.Back)
tween(main, 0.6, { Position = restPos })
tween(backdrop, 0.6, { BackgroundTransparency = CONFIG.BackdropTransparency })
tween(blur, 0.6, { Size = CONFIG.BlurSize })

env.__TheRichStop = destroyAll

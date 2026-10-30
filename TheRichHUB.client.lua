--[[
	TheRichHUB  |  iOS Glassmorphism Gaming Dashboard
	Jenis   : LocalScript
	Letakkan: StarterPlayer > StarterPlayerScripts
	Toggle  : tombol RightShift
]]

-- ============================================================
-- 1. SERVICES
-- ============================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- 2. CONFIG (ubah di sini)
-- ============================================================
local CONFIG = {
	Name = "TheRichHUB",
	Subtitle = "PREMIUM  •  GLASS  •  INTERFACE  v1.0",
	ProfileName = nil, -- nil = pakai DisplayName pemain
	ProfileSubtitle = "DARLING",
	ProfileImageId = "", -- isi "rbxassetid://ID" gambar karakter anime (milik/izin Anda)
	BackgroundImageId = "", -- opsional: gambar langit 2D di belakang UI
	ApplyEnvironment = true, -- buat Sky/Atmosphere/Clouds fallback bila belum ada
	BlurSize = 14, -- ukuran BlurEffect saat UI terbuka
	ToggleKey = Enum.KeyCode.RightShift,
	Design = Vector2.new(960, 540), -- rasio 16:9
	Stats = {
		{ Icon = "💰", Label = "Bounty", Value = "30M" },
		{ Icon = "⭐", Label = "Level", Value = "2800" },
		{ Icon = "⏱️", Label = "Time", Value = "2:54" },
		{ Icon = "❤️", Label = "Health", Value = "67%" },
	},
	Nav = {
		{ Name = "Home", Icon = "🏠" },
		{ Name = "Combat", Icon = "⚔️" },
		{ Name = "Glitches", Icon = "🐛" },
		{ Name = "UI Customs", Icon = "🔥" },
		{ Name = "Visual", Icon = "👁️" },
		{ Name = "Misc", Icon = "⚙️" },
	},
}

-- ============================================================
-- 3. THEME & STATE
-- ============================================================
local THEME = {
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	Text = Color3.fromRGB(245, 248, 255),
	SubText = Color3.fromRGB(175, 190, 215),
	Dark = Color3.fromRGB(6, 12, 26),
	Mid = Color3.fromRGB(24, 56, 120),
	NavIdle = Color3.fromRGB(40, 70, 130),
	Off = Color3.fromRGB(90, 100, 120),
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
	CurrentPage = "Home",
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
		inst[k] = v
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

-- Efek kaca: transparan + sudut bulat + border putih tipis + gradient biru gelap
local function glass(frame, transparency, radius, strokeTransparency)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = transparency or 0.5
	create("UICorner", { CornerRadius = UDim.new(0, radius or 14), Parent = frame })
	create("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Transparency = strokeTransparency or 0.82,
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
	BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0, Parent = gui,
}, {
	create("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(20, 60, 140), Color3.fromRGB(4, 8, 20)),
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

local restPos = UDim2.fromScale(0.5, 0.5)
local main = create("CanvasGroup", {
	Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = restPos,
	Size = UDim2.fromOffset(CONFIG.Design.X, CONFIG.Design.Y), Parent = gui,
})
glass(main, 0.3, 22, 0.75)
local mainScale = create("UIScale", { Parent = main })
create("UIAspectRatioConstraint", { AspectRatio = 16 / 9, Parent = main })

local function updateScale()
	local vp = gui.AbsoluteSize
	local fit = math.min(vp.X * 0.92 / CONFIG.Design.X, vp.Y * 0.88 / CONFIG.Design.Y)
	mainScale.Scale = math.clamp(fit, 0.3, 1.35) * state.UserScale
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

	local logo = create("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(20, 10), BackgroundColor3 = state.Accent, Parent = header }, {
		create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)), Rotation = 90, Transparency = NumberSequence.new(0.55, 0) }),
	})
	label(logo, "R", 22, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold })
	onAccent(function(c) logo.BackgroundColor3 = c end)

	label(header, CONFIG.Name, 22, { Position = UDim2.fromOffset(66, 6), Size = UDim2.fromOffset(300, 26), Font = THEME.FontBold })
	label(header, CONFIG.Subtitle, 11, { Position = UDim2.fromOffset(66, 31), Size = UDim2.fromOffset(400, 16), TextColor3 = THEME.SubText })

	local function winButton(text, xOffset, hoverColor)
		local b = create("TextButton", {
			Text = text, TextSize = 16, Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false,
			Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, xOffset, 0, 12),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, Parent = header,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		connect(b.MouseEnter, function() tween(b, 0.2, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.2 }) end)
		connect(b.MouseLeave, function() tween(b, 0.2, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85 }) end)
		addPress(b)
		return b
	end
	local minimizeBtn = winButton("–", -78, Color3.fromRGB(255, 190, 60))
	local closeBtn = winButton("✕", -40, Color3.fromRGB(255, 80, 90))
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
	label(r, title, 15, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -150, 0, 20), Font = THEME.FontBold })
	label(r, desc or "", 12, { Position = UDim2.fromOffset(16, 32), Size = UDim2.new(1, -150, 0, 18), TextColor3 = THEME.SubText })
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
	local p = create("CanvasGroup", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = content })
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
	label(sf, title, 24, { Size = UDim2.new(1, 0, 0, 30), Font = THEME.FontBold, LayoutOrder = -2 })
	label(sf, desc, 13, { Size = UDim2.new(1, 0, 0, 20), TextColor3 = THEME.SubText, LayoutOrder = -1 })
	return sf
end

-- ---------- HOME ----------
local function buildHome()
	local p = newPage("Home")

	-- Panel profil
	local card = create("Frame", { Name = "Profile", Size = UDim2.fromOffset(292, 452), Parent = p })
	glass(card, 0.5, 20, 0.8)
	if CONFIG.ProfileImageId ~= "" then
		create("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = CONFIG.ProfileImageId,
			ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0.45, Parent = card,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 20) }) })
	end
	create("Frame", { -- fade bawah agar teks terbaca
		Size = UDim2.fromScale(1, 0.55), Position = UDim2.fromScale(0, 0.45), BorderSizePixel = 0,
		BackgroundColor3 = THEME.Dark, Parent = card,
	}, {
		create("UICorner", { CornerRadius = UDim.new(0, 20) }),
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.25) }),
	})

	local avatarRing = create("Frame", {
		Size = UDim2.fromOffset(120, 120), Position = UDim2.new(0.5, -60, 0, 60), BackgroundTransparency = 1, Parent = card,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	local ringStroke = create("UIStroke", { Thickness = 3, Color = state.Accent, Parent = avatarRing })
	onAccent(function(c) ringStroke.Color = c end)
	local avatar = create("ImageLabel", {
		Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = THEME.Dark, Parent = avatarRing,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then avatar.Image = img end
	end)

	local nameRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 200), BackgroundTransparency = 1, Parent = card,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6),
		}),
	})
	label(nameRow, CONFIG.ProfileName or player.DisplayName, 22, {
		AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 26), Font = THEME.FontBold,
	})
	local badge = create("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.fromRGB(0, 140, 255), Parent = nameRow }, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	label(badge, "✓", 13, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold })

	local sub = label(card, CONFIG.ProfileSubtitle, 14, {
		Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 234),
		TextXAlignment = Enum.TextXAlignment.Center, Font = THEME.FontBold, TextColor3 = state.Accent,
	})
	onAccent(function(c) sub.TextColor3 = c end)
	label(card, "@" .. player.Name, 12, {
		Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 256),
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = THEME.SubText,
	})

	-- Panel statistik
	local right = create("Frame", { Position = UDim2.fromOffset(308, 0), Size = UDim2.fromOffset(414, 452), BackgroundTransparency = 1, Parent = p })
	label(right, "Statistics", 20, { Size = UDim2.new(1, 0, 0, 28), Font = THEME.FontBold })
	local grid = create("Frame", { Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 212), BackgroundTransparency = 1, Parent = right }, {
		create("UIGridLayout", { CellSize = UDim2.fromOffset(201, 100), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for i, s in CONFIG.Stats do
		local c = create("Frame", { LayoutOrder = i, Parent = grid })
		glass(c, 0.5, 16, 0.82)
		local iconBox = create("Frame", {
			Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(16, 27), BackgroundTransparency = 0.7, BackgroundColor3 = state.Accent, Parent = c,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 13) }) })
		onAccent(function(col) iconBox.BackgroundColor3 = col end)
		label(iconBox, s.Icon, 22, { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center })
		label(c, s.Label, 13, { Position = UDim2.fromOffset(74, 22), Size = UDim2.new(1, -84, 0, 18), TextColor3 = THEME.SubText })
		label(c, s.Value, 28, { Position = UDim2.fromOffset(74, 42), Size = UDim2.new(1, -84, 0, 36), Font = THEME.FontBold })
	end

	local info = create("Frame", { Position = UDim2.fromOffset(0, 262), Size = UDim2.new(1, 0, 0, 190), Parent = right })
	glass(info, 0.55, 16, 0.85)
	label(info, "Selamat datang 👋", 18, { Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -36, 0, 24), Font = THEME.FontBold })
	label(info, "Gunakan menu di kiri untuk berpindah halaman.\n\n• " .. CONFIG.ToggleKey.Name .. " : buka / tutup UI\n• Tombol – : minimize, ✕ : tutup\n• UI Customs : ubah warna & ukuran UI", 13, {
		Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -36, 0, 130), TextColor3 = THEME.SubText,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
	})
end

-- ---------- COMBAT ----------
local function buildCombat()
	local sf = newSettingsPage("Combat", "⚔️ Combat", "Pengaturan pertarungan. Sambungkan callback ke sistem game Anda.")
	local function stub(name) return function(v) print(("[TheRichHUB] %s = %s"):format(name, tostring(v))) end end
	createToggle(sf, "Auto Block", "Blok otomatis saat diserang", false, stub("AutoBlock"))
	createToggle(sf, "Hit Indicator", "Tampilkan indikator damage", true, stub("HitIndicator"))
	createToggle(sf, "Combo Assist", "Bantu urutan serangan", false, stub("ComboAssist"))
	createToggle(sf, "Target Lock", "Kunci kamera ke target terdekat", false, stub("TargetLock"))
end

-- ---------- GLITCHES ----------
local function buildGlitches()
	local sf = newSettingsPage("Glitches", "🐛 Glitches", "Opsi eksperimental. Sambungkan callback ke sistem game Anda.")
	local function stub(name) return function(v) print(("[TheRichHUB] %s = %s"):format(name, tostring(v))) end end
	createToggle(sf, "Smooth Animation", "Haluskan transisi animasi karakter", true, stub("SmoothAnim"))
	createToggle(sf, "Lag Reducer", "Kurangi efek visual berat", false, stub("LagReducer"))
	createToggle(sf, "Debug Overlay", "Tampilkan info debug di console", false, stub("DebugOverlay"))
end

-- ---------- UI CUSTOMS ----------
local function buildCustoms()
	local sf = newSettingsPage("UI Customs", "🔥 UI Customs", "Sesuaikan tampilan TheRichHUB secara langsung.")

	local r = row(sf, 84)
	label(r, "Warna Aksen", 15, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 20), Font = THEME.FontBold })
	local x = 16
	for name, color in THEME.Accents do
		local b = create("TextButton", {
			Text = name, TextSize = 12, Font = THEME.FontBold, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
			Size = UDim2.fromOffset(78, 30), Position = UDim2.fromOffset(x, 40), BackgroundColor3 = color, Parent = r,
		}, { create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
		addPress(b)
		connect(b.MouseButton1Click, function() setAccent(color) end)
		x += 88
	end

	createStepper(sf, "Ukuran UI", "Perbesar / perkecil seluruh UI", 1, 0.7, 1.15, 0.05,
		function(v) return ("%d%%"):format(math.round(v * 100)) end,
		function(v) state.UserScale = v; updateScale() end)

	createToggle(sf, "Background Blur", "Blur dunia 3D di belakang UI", true, function(v)
		state.BlurEnabled = v
		if state.Open then tween(blur, 0.4, { Size = v and CONFIG.BlurSize or 0 }) end
	end)

	createToggle(sf, "Transparansi Tinggi", "Panel utama lebih bening", false, function(v)
		tween(main, 0.3, { BackgroundTransparency = v and 0.55 or 0.3 })
	end)
end

-- ---------- VISUAL ----------
local fullbrightOriginal
local function buildVisual()
	local sf = newSettingsPage("Visual", "👁️ Visual", "Pengaturan kamera dan pencahayaan.")
	createStepper(sf, "Field of View", "Sudut pandang kamera", workspace.CurrentCamera.FieldOfView, 50, 120, 5,
		function(v) return tostring(math.round(v)) .. "°" end,
		function(v) workspace.CurrentCamera.FieldOfView = v end)
	createToggle(sf, "Fullbright", "Terangkan seluruh dunia", false, function(v)
		if v then
			fullbrightOriginal = { Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient }
			Lighting.Brightness = 3
			Lighting.Ambient = Color3.fromRGB(190, 190, 190)
			Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
		elseif fullbrightOriginal then
			Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(fullbrightOriginal)
		end
	end)
	createStepper(sf, "Jam Dunia", "Atur waktu siang / malam", Lighting.ClockTime, 0, 24, 1,
		function(v) return ("%02d:00"):format(math.floor(v) % 24) end,
		function(v) Lighting.ClockTime = v end)
end

-- ---------- MISC ----------
local fpsLabel
local function buildMisc()
	local sf = newSettingsPage("Misc", "⚙️ Misc", "Utilitas tambahan.")
	createAction(sf, "Reset Karakter", "Respawn karakter Anda", "Reset", function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end)
	createAction(sf, "Salin User ID", "Tampilkan User ID di console", "Print", function(btn)
		print("[TheRichHUB] UserId:", player.UserId)
		btn.Text = "Tercetak ✓"
		task.wait(1.2)
		btn.Text = "Print"
	end)
	local r = row(sf)
	rowTexts(r, "FPS", "Frame per detik realtime")
	fpsLabel = label(r, "--", 18, {
		Size = UDim2.fromOffset(80, 30), Position = UDim2.new(1, -96, 0.5, -15),
		TextXAlignment = Enum.TextXAlignment.Right, Font = THEME.FontBold,
	})
	onAccent(function(c) fpsLabel.TextColor3 = c end)
end

buildHome()
buildCombat()
buildGlitches()
buildCustoms()
buildVisual()
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
		and { BackgroundColor3 = state.Accent, BackgroundTransparency = 0.15 }
		or { BackgroundColor3 = THEME.NavIdle, BackgroundTransparency = item.hover and 0.5 or 0.75 })
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

	tween(oldPage, 0.18, { GroupTransparency = 1, Position = UDim2.fromOffset(-24 * dir, 0) })
	task.delay(0.18, function()
		if token ~= switchToken then return end
		oldPage.Visible = false
		newPage_.Position = UDim2.fromOffset(28 * dir, 0)
		newPage_.GroupTransparency = 1
		newPage_.Visible = true
		tween(newPage_, 0.35, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
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
			Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = THEME.NavIdle, BackgroundTransparency = 0.75, Parent = sidebar,
		}, {
			create("UICorner", { CornerRadius = UDim.new(0, 14) }),
			create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.88, Thickness = 1 }),
		})
		local indicator = create("Frame", {
			Size = UDim2.fromOffset(4, 22), Position = UDim2.fromOffset(6, 13), BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		label(b, nav.Icon, 20, { Position = UDim2.fromOffset(18, 0), Size = UDim2.fromOffset(30, 48), TextXAlignment = Enum.TextXAlignment.Center })
		local text = label(b, nav.Name, 15, { Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -62, 1, 0), Font = THEME.FontBold, TextColor3 = THEME.SubText })

		local item = { name = nav.Name, button = b, indicator = indicator, text = text, hover = false }
		navItems[nav.Name] = item
		addPress(b)
		connect(b.MouseEnter, function() item.hover = true; paintNav(item) end)
		connect(b.MouseLeave, function() item.hover = false; paintNav(item) end)
		connect(b.MouseButton1Click, function() switchPage(nav.Name) end)
	end
	onAccent(function()
		for _, item in navItems do paintNav(item) end
	end)
end
buildSidebar()

pages[state.CurrentPage].Visible = true

-- ============================================================
-- 11. MINIMIZE / CLOSE / REOPEN
-- ============================================================
local reopen = create("TextButton", {
	Name = "Reopen", Text = "◆  " .. CONFIG.Name, TextSize = 14, Font = THEME.FontBold, TextColor3 = THEME.Text, AutoButtonColor = false,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(160, 40), Visible = false, Parent = gui,
})
glass(reopen, 0.35, 20, 0.7)
local reopenScale = create("UIScale", { Scale = 0, Parent = reopen })

local function setOpen(open)
	if state.Open == open then return end
	state.Open = open
	if open then
		tween(reopenScale, 0.2, { Scale = 0 })
		task.delay(0.2, function() if state.Open then reopen.Visible = false end end)
		backdrop.Visible = true
		main.Visible = true
		main.GroupTransparency = 1
		main.Position = restPos + UDim2.fromOffset(0, 30)
		tween(main, 0.45, { GroupTransparency = 0, Position = restPos })
		tween(backdrop, 0.45, { BackgroundTransparency = 0.55 })
		tween(blur, 0.45, { Size = state.BlurEnabled and CONFIG.BlurSize or 0 })
	else
		tween(main, 0.35, { GroupTransparency = 1, Position = restPos + UDim2.fromOffset(0, 30) })
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

local function closeUI()
	tween(main, 0.3, { GroupTransparency = 1, Position = restPos + UDim2.fromOffset(0, 30) })
	tween(backdrop, 0.3, { BackgroundTransparency = 1 })
	tween(blur, 0.3, { Size = 0 })
	task.wait(0.35)
	if fullbrightOriginal then
		Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient = table.unpack(fullbrightOriginal)
	end
	for _, c in connections do c:Disconnect() end
	blur:Destroy()
	gui:Destroy()
end

connect(minimizeBtn.MouseButton1Click, function() setOpen(false) end)
connect(closeBtn.MouseButton1Click, closeUI)
connect(reopen.MouseButton1Click, function() setOpen(true) end)
addPress(reopen)
connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == CONFIG.ToggleKey then setOpen(not state.Open) end
end)

-- Animasi masuk awal
main.GroupTransparency = 1
main.Position = restPos + UDim2.fromOffset(0, 30)
backdrop.BackgroundTransparency = 1
tween(main, 0.6, { GroupTransparency = 0, Position = restPos })
tween(backdrop, 0.6, { BackgroundTransparency = 0.55 })
tween(blur, 0.6, { Size = CONFIG.BlurSize })

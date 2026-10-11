local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

local HUB_NAME = "Save Your Friend!"
local GUI_NAME = "SaveYourFriendHub"
local STOP_LEVEL = 400

-- AutoSave cooldown
local RETRY = 0.1

-- Halloween cooldown
local HALLOWEEN_RETRY = 1

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

local BG1 = Color3.fromRGB(32, 8, 24)
local BG2 = Color3.fromRGB(5, 2, 8)
local CARD = Color3.fromRGB(30, 10, 26)
local BORDER = Color3.fromRGB(125, 22, 40)
local BLOOD = Color3.fromRGB(190, 12, 28)
local BLOOD_L = Color3.fromRGB(255, 52, 44)
local BLOOD_D = Color3.fromRGB(95, 4, 14)
local ORANGE = Color3.fromRGB(255, 112, 16)
local ORANGE_L = Color3.fromRGB(255, 170, 48)
local PURPLE = Color3.fromRGB(110, 40, 190)
local TOXIC = Color3.fromRGB(110, 255, 70)
local TEXT = Color3.fromRGB(248, 232, 232)
local MUTED = Color3.fromRGB(176, 140, 150)
local OFFCOL = Color3.fromRGB(52, 30, 50)
local WHITE = Color3.new(1, 1, 1)

local SINE = Enum.EasingStyle.Sine
local QUAD = Enum.EasingStyle.Quad
local LINEAR = Enum.EasingStyle.Linear
local BACK = Enum.EasingStyle.Back

local IN = Enum.EasingDirection.In
local OUT = Enum.EasingDirection.Out
local INOUT = Enum.EasingDirection.InOut

local function new(class, props, parent)
	local inst = Instance.new(class)

	for k, v in pairs(props or {}) do
		inst[k] = v
	end

	if parent then
		inst.Parent = parent
	end

	return inst
end

local function label(props, parent)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		TextColor3 = TEXT,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	}

	for k, v in pairs(props) do
		base[k] = v
	end

	return new("TextLabel", base, parent)
end

local function ti(time, style, dir, rep, rev, delay)
	return TweenInfo.new(
		time,
		style or QUAD,
		dir or OUT,
		rep or 0,
		rev or false,
		delay or 0
	)
end

local function tween(obj, info, goal)
	local t = TweenService:Create(obj, info, goal)
	t:Play()
	return t
end

local function corner(parent, r)
	return new("UICorner", {
		CornerRadius = UDim.new(0, r)
	}, parent)
end

local function fireGradient()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, BLOOD),
		ColorSequenceKeypoint.new(0.35, ORANGE),
		ColorSequenceKeypoint.new(0.7, PURPLE),
		ColorSequenceKeypoint.new(1, BLOOD),
	})
end

--==================================================
-- GUI
--==================================================

local gui = new("ScreenGui", {
	Name = GUI_NAME,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
})

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

local main = new("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.fromOffset(340, 260),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
}, gui)

corner(main, 18)

new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(BG1, BG2)
}, main)

local mainStroke = new("UIStroke", {
	Color = WHITE,
	Thickness = 2.5,
	Transparency = 0.1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, main)

local strokeGrad = new("UIGradient", {
	Color = fireGradient()
}, mainStroke)

tween(
	strokeGrad,
	ti(5, LINEAR, IN, -1),
	{ Rotation = 360 }
)

local scale = new("UIScale", {
	Scale = 0
}, main)

--==================================================
-- DECORATION
--==================================================

local decor = new("Frame", {
	Name = "Decor",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 1,
}, main)

local rng = Random.new()

local topGlow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 46),
	BackgroundColor3 = BLOOD,
	BorderSizePixel = 0,
}, decor)

new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new(0.55, 1)
}, topGlow)

local ground = new("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 1, -40),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
}, decor)

new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new(1, 0.15)
}, ground)

for _ = 1, 6 do
	local x = rng:NextNumber(0.04, 0.96)
	local w = rng:NextInteger(3, 5)
	local len = rng:NextInteger(10, 22)

	local drip = new("Frame", {
		Size = UDim2.fromOffset(w, len),
		Position = UDim2.new(x, 0, 0, 0),
		BackgroundColor3 = BLOOD,
		BorderSizePixel = 0,
	}, decor)

	corner(drip, 3)

	local bulb = new("Frame", {
		Size = UDim2.fromOffset(w + 3, w + 3),
		AnchorPoint = Vector2.new(0.5, 0.65),
		Position = UDim2.new(0.5, 0, 1, 0),
		BackgroundColor3 = BLOOD,
		BorderSizePixel = 0,
	}, drip)

	corner(bulb, 6)

	tween(
		drip,
		ti(
			rng:NextNumber(2.5, 4.5),
			SINE,
			INOUT,
			-1,
			true,
			rng:NextNumber(0, 2)
		),
		{
			Size = UDim2.fromOffset(
				w,
				len + rng:NextInteger(8, 16)
			)
		}
	)
end

for _ = 1, 3 do
	local x = rng:NextNumber(0.05, 0.95)

	local drop = new("Frame", {
		Size = UDim2.fromOffset(4, 6),
		Position = UDim2.new(x, 0, 0, 28),
		BackgroundColor3 = BLOOD_L,
		BorderSizePixel = 0,
	}, decor)

	corner(drop, 3)

	tween(
		drop,
		ti(
			rng:NextNumber(1.4, 2.2),
			QUAD,
			IN,
			-1,
			false,
			rng:NextNumber(1.5, 4)
		),
		{
			Position = UDim2.new(x, 0, 1, 0),
			BackgroundTransparency = 0.6
		}
	)
end

for i = 1, 10 do
	local s = rng:NextInteger(2, 4)
	local x = rng:NextNumber(0.03, 0.97)

	local color = ORANGE_L

	if i % 4 == 0 then
		color = TOXIC
	elseif i % 2 == 0 then
		color = BLOOD_L
	end

	local ember = new("Frame", {
		Size = UDim2.fromOffset(s, s),
		Position = UDim2.new(x, 0, 1.05, 0),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, decor)

	corner(ember, 4)

	tween(
		ember,
		ti(
			rng:NextNumber(4, 9),
			LINEAR,
			OUT,
			-1,
			false,
			rng:NextNumber(0, 4)
		),
		{
			Position = UDim2.new(
				x + rng:NextNumber(-0.06, 0.06),
				0,
				-0.05,
				0
			),
			BackgroundTransparency = 1
		}
	)
end

local function bat(y, size, dur, delay)
	local b = label({
		Text = "🦇",
		TextSize = size,
		TextTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromOffset(size + 6, size + 6),
		Position = UDim2.new(-0.15, 0, y, 0),
	}, decor)

	tween(
		b,
		ti(dur, LINEAR, OUT, -1, false, delay),
		{
			Position = UDim2.new(1.1, 0, y + 0.04, 0)
		}
	)

	b.Rotation = -14

	tween(
		b,
		ti(0.28, SINE, INOUT, -1, true),
		{ Rotation = 14 }
	)
end

bat(0.82, 18, 7, 0)
bat(0.30, 14, 9, 2.5)
bat(0.60, 16, 11, 5)

local function fog(y, h, dur, delay)
	local f = new("Frame", {
		Size = UDim2.new(0.8, 0, 0, h),
		Position = UDim2.new(-0.8, 0, 1, y),
		BackgroundColor3 = Color3.fromRGB(205, 190, 225),
		BorderSizePixel = 0,
	}, decor)

	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, f)

	corner(f, 8)

	tween(
		f,
		ti(dur, LINEAR, OUT, -1, false, delay),
		{
			Position = UDim2.new(1, 0, 1, y)
		}
	)
end

fog(-18, 18, 13, 0)
fog(-10, 14, 9, 4)

label({
	Text = "🕸️",
	TextSize = 38,
	TextTransparency = 0.5,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(0, -8, 1, -40),
}, decor)

label({
	Text = "🕸️",
	TextSize = 38,
	TextTransparency = 0.5,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(46, 46),
	Position = UDim2.new(1, -38, 1, -40),
	Rotation = 90,
}, decor)

local skull = label({
	Text = "💀",
	TextSize = 20,
	TextTransparency = 0.2,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(26, 26),
	Position = UDim2.new(0.5, -13, 1, -28),
	Rotation = -6,
}, decor)

tween(
	skull,
	ti(2.2, SINE, INOUT, -1, true),
	{ Rotation = 6 }
)

local function eyes(xScale, yOffset, color, dur, delay)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(20, 6),
		Position = UDim2.new(xScale, 0, 1, yOffset),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, decor)

	for _, ex in ipairs({0, 13}) do
		local e = new("Frame", {
			Size = UDim2.fromOffset(7, 4),
			Position = UDim2.fromOffset(ex, 1),
			BackgroundColor3 = color,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, holder)

		corner(e, 3)

		tween(
			e,
			ti(dur, SINE, INOUT, -1, true, delay),
			{
				BackgroundTransparency = 0
			}
		)
	end
end

eyes(0.18, -24, BLOOD_L, 1.4, 0)
eyes(0.66, -17, Color3.fromRGB(255, 210, 40), 2.1, 1.2)

local ghost = label({
	Text = "👻",
	TextSize = 20,
	TextTransparency = 0.3,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(28, 28),
	Position = UDim2.new(0.8, 0, 1, -32),
}, decor)

tween(
	ghost,
	ti(1.8, SINE, INOUT, -1, true),
	{
		Position = UDim2.new(0.8, 0, 1, -42),
		TextTransparency = 0.7
	}
)

--==================================================
-- CONTENT
--==================================================

local content = new("Frame", {
	Name = "Content",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 2,
}, main)

local pumpkin = label({
	Text = "🎃",
	TextSize = 26,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(32, 34),
	Position = UDim2.fromOffset(10, 6),
	Rotation = -12,
}, content)

tween(
	pumpkin,
	ti(0.9, SINE, INOUT, -1, true),
	{ Rotation = 12 }
)

local title = label({
	Text = HUB_NAME,
	Font = Enum.Font.Creepster,
	TextSize = 28,
	TextColor3 = WHITE,
	TextStrokeColor3 = BLOOD_D,
	TextStrokeTransparency = 0.35,
	Size = UDim2.fromOffset(210, 46),
	Position = UDim2.fromOffset(44, 0),
}, content)

new("UIGradient", {
	Color = ColorSequence.new(BLOOD_L, BLOOD),
	Rotation = 90,
}, title)

local webLine = new("Frame", {
	Size = UDim2.fromOffset(1, 10),
	Position = UDim2.fromOffset(272, 0),
	BackgroundColor3 = Color3.fromRGB(200, 190, 224),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
}, content)

local spider = label({
	Text = "🕷️",
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(22, 20),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromOffset(272, 8),
}, content)

local swing = ti(1.6, SINE, INOUT, -1, true)

tween(
	webLine,
	swing,
	{ Size = UDim2.fromOffset(1, 26) }
)

tween(
	spider,
	swing,
	{ Position = UDim2.fromOffset(272, 24) }
)

local minBtn = new("TextButton", {
	Name = "Minimize",
	AutoButtonColor = false,
	Text = "–",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = ORANGE_L,
	BackgroundColor3 = Color3.fromRGB(46, 14, 30),
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(30, 30),
	Position = UDim2.new(1, -40, 0, 8),
}, content)

corner(minBtn, 9)

new("UIStroke", {
	Color = BORDER,
	Thickness = 1.2
}, minBtn)

minBtn.MouseEnter:Connect(function()
	tween(
		minBtn,
		ti(0.15),
		{
			BackgroundColor3 = Color3.fromRGB(96, 22, 40)
		}
	)
end)

minBtn.MouseLeave:Connect(function()
	tween(
		minBtn,
		ti(0.15),
		{
			BackgroundColor3 = Color3.fromRGB(46, 14, 30)
		}
	)
end)

local divider = new("Frame", {
	Size = UDim2.new(1, -24, 0, 2),
	Position = UDim2.fromOffset(12, 46),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, content)

corner(divider, 2)

new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BLOOD),
		ColorSequenceKeypoint.new(0.5, ORANGE),
		ColorSequenceKeypoint.new(1, BLOOD),
	}),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, divider)

--==================================================
-- AUTOSAVE CARD
--==================================================

local card = new("TextButton", {
	Name = "AutoSaveCard",
	AutoButtonColor = false,
	Text = "",
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.fromOffset(316, 58),
	BackgroundColor3 = CARD,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
}, content)

corner(card, 12)

local cardStroke = new("UIStroke", {
	Color = BORDER,
	Thickness = 1.5,
	Transparency = 0.2
}, card)

label({
	Text = "AutoSave",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromOffset(200, 24),
	Position = UDim2.fromOffset(16, 17),
}, card)

local track = new("Frame", {
	Size = UDim2.fromOffset(52, 28),
	Position = UDim2.fromOffset(250, 15),
	BackgroundColor3 = OFFCOL,
	BorderSizePixel = 0,
}, card)

corner(track, 14)

local trackStroke = new("UIStroke", {
	Color = BORDER,
	Thickness = 1.2,
	Transparency = 0.2
}, track)

local knob = new("Frame", {
	Size = UDim2.fromOffset(22, 22),
	Position = UDim2.new(0, 3, 0.5, -11),
	BackgroundColor3 = Color3.fromRGB(255, 236, 224),
	BorderSizePixel = 0,
}, track)

corner(knob, 11)

local knobIcon = label({
	Text = "💀",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = Color3.fromRGB(30, 20, 40),
	Size = UDim2.fromScale(1, 1),
}, knob)

card.MouseEnter:Connect(function()
	tween(
		card,
		ti(0.15),
		{
			BackgroundColor3 = Color3.fromRGB(50, 16, 38)
		}
	)
end)

card.MouseLeave:Connect(function()
	tween(
		card,
		ti(0.15),
		{
			BackgroundColor3 = CARD
		}
	)
end)

--==================================================
-- HALLOWEEN MODE CARD
--==================================================

local halloweenCard = new("TextButton", {
	Name = "AutoSaveHalloweenMode",
	AutoButtonColor = false,
	Text = "",
	Position = UDim2.fromOffset(12, 122),
	Size = UDim2.fromOffset(316, 58),
	BackgroundColor3 = CARD,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
}, content)

corner(halloweenCard, 12)

local halloweenStroke = new("UIStroke", {
	Color = BORDER,
	Thickness = 1.5,
	Transparency = 0.2
}, halloweenCard)

label({
	Text = "Halloween Mode",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	Size = UDim2.fromOffset(200, 24),
	Position = UDim2.fromOffset(16, 8),
}, halloweenCard)

label({
	Text = "222 → " .. STOP_LEVEL,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = MUTED,
	Size = UDim2.fromOffset(200, 14),
	Position = UDim2.fromOffset(16, 32),
}, halloweenCard)

local hTrack = new("Frame", {
	Size = UDim2.fromOffset(52, 28),
	Position = UDim2.fromOffset(250, 15),
	BackgroundColor3 = OFFCOL,
	BorderSizePixel = 0,
}, halloweenCard)

corner(hTrack, 14)

local hTrackStroke = new("UIStroke", {
	Color = BORDER,
	Thickness = 1.2,
	Transparency = 0.2
}, hTrack)

local hKnob = new("Frame", {
	Size = UDim2.fromOffset(22, 22),
	Position = UDim2.new(0, 3, 0.5, -11),
	BackgroundColor3 = Color3.fromRGB(255, 236, 224),
	BorderSizePixel = 0,
}, hTrack)

corner(hKnob, 11)

local hKnobIcon = label({
	Text = "💀",
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = Color3.fromRGB(30, 20, 40),
	Size = UDim2.fromScale(1, 1),
}, hKnob)

halloweenCard.MouseEnter:Connect(function()
	tween(
		halloweenCard,
		ti(0.15),
		{
			BackgroundColor3 = Color3.fromRGB(50, 16, 38)
		}
	)
end)

halloweenCard.MouseLeave:Connect(function()
	tween(
		halloweenCard,
		ti(0.15),
		{
			BackgroundColor3 = CARD
		}
	)
end)

--==================================================
-- LEVEL CARD
--==================================================

local levelCard = new("Frame", {
	Position = UDim2.fromOffset(12, 188),
	Size = UDim2.fromOffset(316, 52),
	BackgroundColor3 = CARD,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
}, content)

corner(levelCard, 12)

new("UIStroke", {
	Color = BORDER,
	Thickness = 1.2,
	Transparency = 0.35
}, levelCard)

label({
	Text = "CURRENT LEVEL",
	Font = Enum.Font.GothamBold,
	TextSize = 10,
	TextColor3 = MUTED,
	Size = UDim2.fromOffset(160, 12),
	Position = UDim2.fromOffset(16, 7),
}, levelCard)

local levelValue = label({
	Text = "?",
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = ORANGE_L,
	Size = UDim2.fromOffset(200, 26),
	Position = UDim2.fromOffset(16, 21),
}, levelCard)

label({
	Text = "☠️",
	TextSize = 28,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.new(1, -52, 0.5, -20),
}, levelCard)

--==================================================
-- MINIMIZED PILL
--==================================================

local pill = new("TextButton", {
	Name = "Minimized",
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -60),
	Size = UDim2.fromOffset(250, 40),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, gui)

corner(pill, 20)

new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(BG1, BG2)
}, pill)

local pillStroke = new("UIStroke", {
	Color = WHITE,
	Thickness = 2,
	Transparency = 0.1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, pill)

local pillGrad = new("UIGradient", {
	Color = fireGradient()
}, pillStroke)

tween(
	pillGrad,
	ti(4, LINEAR, IN, -1),
	{ Rotation = 360 }
)

tween(
	pillStroke,
	ti(1.2, SINE, INOUT, -1, true),
	{ Transparency = 0.55 }
)

local pillText = label({
	Text = "🎃  " .. HUB_NAME .. "  💀",
	Font = Enum.Font.Creepster,
	TextSize = 24,
	TextColor3 = WHITE,
	TextStrokeColor3 = BLOOD_D,
	TextStrokeTransparency = 0.35,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.fromScale(1, 1),
}, pill)

new("UIGradient", {
	Color = ColorSequence.new(BLOOD_L, BLOOD),
	Rotation = 90
}, pillText)

--==================================================
-- EFFECTS
--==================================================

local flash = new("Frame", {
	Name = "Flash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(235, 225, 255),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 5,
}, main)

corner(flash, 18)

task.spawn(function()
	while alive() do
		task.wait(rng:NextNumber(7, 15))

		if not alive() then
			break
		end

		for _ = 1, 2 do
			flash.BackgroundTransparency = 0.88

			tween(
				flash,
				ti(0.25),
				{ BackgroundTransparency = 1 }
			)

			task.wait(rng:NextNumber(0.12, 0.25))
		end
	end
end)

task.spawn(function()
	while alive() do
		task.wait(rng:NextNumber(2.5, 6))

		if not alive() then
			break
		end

		for _ = 1, rng:NextInteger(2, 4) do
			title.TextTransparency = rng:NextNumber(0.4, 0.8)

			task.wait(rng:NextNumber(0.03, 0.08))

			title.TextTransparency = 0

			task.wait(rng:NextNumber(0.04, 0.12))
		end
	end
end)

--==================================================
-- MINIMIZE / RESTORE
--==================================================

local busy = false

local function minimize()
	if busy then return end

	busy = true

	local t = tween(
		scale,
		ti(0.2, QUAD, IN),
		{ Scale = 0 }
	)

	t.Completed:Wait()

	main.Visible = false

	pill.Position = UDim2.new(
		0.5,
		0,
		0,
		-60
	)

	pill.Visible = true

	tween(
		pill,
		ti(0.4, BACK, OUT),
		{
			Position = UDim2.new(
				0.5,
				0,
				0,
				10
			)
		}
	)

	busy = false
end

local function restore()
	if busy then return end

	busy = true

	local t = tween(
		pill,
		ti(0.22, QUAD, IN),
		{
			Position = UDim2.new(
				0.5,
				0,
				0,
				-60
			)
		}
	)

	t.Completed:Wait()

	pill.Visible = false

	scale.Scale = 0
	main.Visible = true

	tween(
		scale,
		ti(0.4, BACK, OUT),
		{ Scale = 1 }
	)

	busy = false
end

minBtn.Activated:Connect(minimize)
pill.Activated:Connect(restore)

--==================================================
-- DRAG
--==================================================

local dragging
local dragStart
local startPos

main.InputBegan:Connect(function(input)
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

table.insert(
	connections,
	UserInputService.InputChanged:Connect(function(input)
		if dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			) then

			local d = input.Position - dragStart

			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + d.X,
				startPos.Y.Scale,
				startPos.Y.Offset + d.Y
			)
		end
	end)
)

--==================================================
-- LOGIC
--==================================================

local autoSave = false
local halloweenMode = false

local pulse
local hPulse

-- Halloween starts at 222
local hCounter = 222

-- Timers (dideklarasikan di atas supaya tombol Halloween memakai variabel yang sama dengan loop)
local cachedRemote = nil
local lastLevel = nil
local lastFire = 0
local lastHalloweenFire = 0

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
-- AUTOSAVE SWITCH
--==================================================

local function setSwitch(on)
	local info = ti(0.22, QUAD, OUT)

	tween(
		track,
		info,
		{
			BackgroundColor3 = on and TOXIC or OFFCOL
		}
	)

	tween(
		knob,
		info,
		{
			Position = on
				and UDim2.new(1, -25, 0.5, -11)
				or UDim2.new(0, 3, 0.5, -11)
		}
	)

	tween(
		cardStroke,
		info,
		{
			Color = on and TOXIC or BORDER
		}
	)

	tween(
		trackStroke,
		info,
		{
			Color = on and TOXIC or BORDER
		}
	)

	knobIcon.Text = on and "🎃" or "💀"

	if pulse then
		pulse:Cancel()
	end

	cardStroke.Transparency = 0.2

	if on then
		pulse = tween(
			cardStroke,
			ti(0.8, SINE, INOUT, -1, true),
			{
				Transparency = 0.8
			}
		)
	else
		pulse = nil
	end
end

--==================================================
-- HALLOWEEN SWITCH
--==================================================

local function setHalloweenSwitch(on)
	local info = ti(0.22, QUAD, OUT)

	tween(
		hTrack,
		info,
		{
			BackgroundColor3 = on and ORANGE or OFFCOL
		}
	)

	tween(
		hKnob,
		info,
		{
			Position = on
				and UDim2.new(1, -25, 0.5, -11)
				or UDim2.new(0, 3, 0.5, -11)
		}
	)

	tween(
		halloweenStroke,
		info,
		{
			Color = on and ORANGE or BORDER
		}
	)

	tween(
		hTrackStroke,
		info,
		{
			Color = on and ORANGE or BORDER
		}
	)

	hKnobIcon.Text = on and "🎃" or "💀"

	if hPulse then
		hPulse:Cancel()
	end

	halloweenStroke.Transparency = 0.2

	if on then
		hPulse = tween(
			halloweenStroke,
			ti(0.8, SINE, INOUT, -1, true),
			{
				Transparency = 0.8
			}
		)
	else
		hPulse = nil
	end
end

--==================================================
-- BUTTONS
--==================================================

card.Activated:Connect(function()
	autoSave = not autoSave
	setSwitch(autoSave)
end)

halloweenCard.Activated:Connect(function()
	halloweenMode = not halloweenMode

	if halloweenMode then
		hCounter = 222

		-- Make the first call respect the 1 second cooldown
		-- starting from the moment the mode is enabled.
		lastHalloweenFire = os.clock()
	end

	setHalloweenSwitch(halloweenMode)
end)

local function stopAutoSave()
	autoSave = false
	setSwitch(false)
end

--==================================================
-- REMOTE / TIMERS
--==================================================

table.insert(
	connections,
	RunService.RenderStepped:Connect(function()
		if not cachedRemote or not cachedRemote.Parent then
			cachedRemote = getRemote()
		end

		local now = os.clock()

		--==================================================
		-- HALLOWEEN MODE
		--
		-- 222
		-- wait 1 second
		-- 223
		-- wait 1 second
		-- ... until STOP_LEVEL
		--==================================================

		if halloweenMode and cachedRemote then
			if hCounter > STOP_LEVEL then
				-- sudah sampai level maksimal, matikan mode otomatis
				halloweenMode = false
				setHalloweenSwitch(false)

			elseif now - lastHalloweenFire >= HALLOWEEN_RETRY then

				lastHalloweenFire = now

				pcall(function()
					cachedRemote:FireServer(hCounter)
				end)

				hCounter = hCounter + 1
			end
		end

		--==================================================
		-- AUTOSAVE
		--==================================================

		if not autoSave then
			lastLevel = nil
			return
		end

		local level = tonumber(getLevel())

		if not cachedRemote or not level then
			return
		end

		if level >= STOP_LEVEL then
			stopAutoSave()
			return
		end

		if level ~= lastLevel
			or now - lastFire >= RETRY then

			lastLevel = level
			lastFire = now

			pcall(function()
				cachedRemote:FireServer(level)
			end)
		end
	end)
)

--==================================================
-- LEVEL DISPLAY
--==================================================

task.spawn(function()
	while alive() do
		local lv = getLevel()

		levelValue.Text =
			lv ~= nil
			and tostring(lv)
			or "?"

		task.wait(0.25)
	end
end)

--==================================================
-- OPEN ANIMATION
--==================================================

tween(
	scale,
	ti(0.5, BACK, OUT),
	{ Scale = 1 }
)

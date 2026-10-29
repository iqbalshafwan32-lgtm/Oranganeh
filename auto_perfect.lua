-- Auto Perfect (script terpisah)
-- Baca angka "+N" di layar, klik tepat saat angka mencapai Target,
-- lalu otomatis klik tombol "Klik untuk melanjutkan".

if _G.AUTOPERFECT_CLEAN then pcall(_G.AUTOPERFECT_CLEAN) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local lp = Players.LocalPlayer
while not lp do task.wait() lp = Players.LocalPlayer end
local pg = lp:WaitForChild("PlayerGui")

local CFG = {
	Enabled = false,
	AutoContinue = true,
	Target = 20,       -- angka target (bisa diubah di UI)
	Lead = 0.02,       -- klik sedikit lebih awal (detik) untuk kompensasi delay
	Cooldown = 0.45,   -- jeda minimal antar klik perfect (detik)
}

local alive = true
local conns = {}
local function bind(c) conns[#conns + 1] = c return c end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local parent = (gethui and gethui()) or CoreGui
pcall(function()
	local old = parent:FindFirstChild("AutoPerfectUI")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPerfectUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = parent

_G.AUTOPERFECT_CLEAN = function()
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
end

local BG = Color3.fromRGB(20, 8, 10)
local ON = Color3.fromRGB(60, 170, 90)
local OFFC = Color3.fromRGB(90, 40, 46)
local TXT = Color3.fromRGB(246, 232, 232)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(230, 190)
frame.Position = UDim2.new(0.5, -115, 0.3, 0)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local fs = Instance.new("UIStroke", frame)
fs.Color = Color3.fromRGB(176, 16, 36)
fs.Thickness = 1.5

local function makeLabel(text, y, size, color, font)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -20, 0, 20)
	l.Position = UDim2.fromOffset(10, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or TXT
	l.Font = font or Enum.Font.GothamMedium
	l.TextSize = size or 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = frame
	return l
end

makeLabel("Auto Perfect", 6, 16, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
local info = makeLabel("Nilai: -  |  Target: 20", 30, 12, Color3.fromRGB(190, 150, 155))

local function makeButton(text, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -20, 0, 32)
	b.Position = UDim2.fromOffset(10, y)
	b.BackgroundColor3 = OFFC
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.AutoButtonColor = false
	b.Parent = frame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local toggleBtn = makeButton("AUTO PERFECT: OFF", 54)
local contBtn = makeButton("AUTO LANJUTKAN: ON", 92)
contBtn.BackgroundColor3 = ON

local targetBox = Instance.new("TextBox")
targetBox.Size = UDim2.new(1, -20, 0, 32)
targetBox.Position = UDim2.fromOffset(10, 130)
targetBox.BackgroundColor3 = Color3.fromRGB(40, 20, 24)
targetBox.BorderSizePixel = 0
targetBox.Text = tostring(CFG.Target)
targetBox.PlaceholderText = "Target (angka)"
targetBox.TextColor3 = Color3.new(1, 1, 1)
targetBox.PlaceholderColor3 = Color3.fromRGB(150, 110, 115)
targetBox.Font = Enum.Font.GothamBold
targetBox.TextSize = 13
targetBox.ClearTextOnFocus = false
targetBox.Parent = frame
Instance.new("UICorner", targetBox).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -30, 0, 6)
closeBtn.BackgroundColor3 = OFFC
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
	if _G.AUTOPERFECT_CLEAN then _G.AUTOPERFECT_CLEAN() end
end)

-- Drag UI
do
	local dragging, dragStart, startPos
	bind(frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end))
	bind(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
end

toggleBtn.MouseButton1Click:Connect(function()
	CFG.Enabled = not CFG.Enabled
	toggleBtn.Text = "AUTO PERFECT: " .. (CFG.Enabled and "ON" or "OFF")
	toggleBtn.BackgroundColor3 = CFG.Enabled and ON or OFFC
end)

contBtn.MouseButton1Click:Connect(function()
	CFG.AutoContinue = not CFG.AutoContinue
	contBtn.Text = "AUTO LANJUTKAN: " .. (CFG.AutoContinue and "ON" or "OFF")
	contBtn.BackgroundColor3 = CFG.AutoContinue and ON or OFFC
end)

targetBox.FocusLost:Connect(function()
	local n = tonumber(targetBox.Text)
	if n then CFG.Target = n else targetBox.Text = tostring(CFG.Target) end
end)

------------------------------------------------------------
-- Util teks & visibilitas
------------------------------------------------------------
local function clean(s) return (s:gsub("<[^>]+>", "")) end
local function norm(raw) return (raw:lower():gsub("[^%a]", "")) end

local function ours(o) return o:IsDescendantOf(gui) end

local function visible(o)
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

-- Indeks semua teks UI (cache 0.3 detik supaya tidak lag)
local idx, idxT = {}, 0
local function texts()
	local now = os.clock()
	if now - idxT > 0.3 then
		idxT = now
		local out = {}
		for _, o in ipairs(pg:GetDescendants()) do
			if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and not ours(o) then
				out[#out + 1] = o
			end
		end
		idx = out
	end
	return idx
end

------------------------------------------------------------
-- Klik
------------------------------------------------------------
local MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function centerOf(g)
	local sg = g:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = Vector2.zero
	if not (sg and sg.IgnoreGuiInset) then
		local ok, v = pcall(function() return GuiService:GetGuiInset() end)
		if ok and v then inset = v end
	end
	return g.AbsolutePosition + g.AbsoluteSize / 2 + inset
end

local function click(pos)
	task.spawn(function()
		local cam = workspace.CurrentCamera
		local c = pos or (cam and cam.ViewportSize / 2) or Vector2.new(300, 300)
		if not pos then
			local char = lp.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool then pcall(function() tool:Activate() end) end
		end
		if not VIM then return end
		if MOBILE then
			pcall(function() VIM:SendTouchEvent(7, 0, c.X, c.Y) end)
			RunService.Heartbeat:Wait()
			pcall(function() VIM:SendTouchEvent(7, 2, c.X, c.Y) end)
		else
			pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0) end)
			RunService.Heartbeat:Wait()
			pcall(function() VIM:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0) end)
		end
	end)
end

local function fireButton(b)
	if not (b and b:IsA("GuiButton")) then return false end
	if firesignal then
		pcall(function() firesignal(b.MouseButton1Click) end)
		pcall(function() firesignal(b.Activated) end)
		return true
	elseif getconnections then
		pcall(function()
			for _, sig in ipairs({ b.MouseButton1Click, b.Activated }) do
				for _, cn in ipairs(getconnections(sig)) do
					pcall(function() cn:Fire() end)
				end
			end
		end)
		return true
	end
	return false
end

local function clickableFor(o)
	local c = o:IsA("GuiButton") and o or o:FindFirstAncestorWhichIsA("GuiButton")
	if c then return c end
	local anc = o.Parent
	for _ = 1, 3 do
		if anc and anc:IsA("GuiObject") then
			local b = anc:FindFirstChildWhichIsA("GuiButton", true)
			if b and visible(b) then return b end
			anc = anc.Parent
		end
	end
	return (o.Parent and o.Parent:IsA("GuiObject")) and o.Parent or o
end

------------------------------------------------------------
-- Baca angka "+N"
------------------------------------------------------------
local valueLabel, lastFind = nil, 0
local function readValue()
	if valueLabel and not (valueLabel.Parent and visible(valueLabel)) then valueLabel = nil end
	if not valueLabel then
		local now = os.clock()
		if now - lastFind < 0.2 then return nil end
		lastFind = now
		for _, o in ipairs(texts()) do
			if o.Parent and clean(o.Text):match("^%s*%+%s*%d+%s*$") and visible(o) then
				valueLabel = o
				break
			end
		end
	end
	if not valueLabel then return nil end
	return tonumber(clean(valueLabel.Text):match("%d+"))
end

------------------------------------------------------------
-- Auto Perfect: klik tepat saat angka mencapai Target
------------------------------------------------------------
local lastVal, lastChangeT, rate = nil, 0, 0
local lastPerfectT = 0
local firedThisRound = false

bind(RunService.Heartbeat:Connect(function()
	if not alive then return end
	local now = os.clock()
	local v = readValue()

	if not v then
		firedThisRound = false
		lastVal = nil
		info.Text = "Nilai: -  |  Target: " .. CFG.Target
		return
	end

	-- hitung kecepatan naik angka (per detik)
	if lastVal == nil then
		lastVal, lastChangeT, rate = v, now, 0
	elseif v ~= lastVal then
		local dt = now - lastChangeT
		if dt > 0 then
			local r = (v - lastVal) / dt
			rate = (rate == 0) and r or (rate * 0.5 + r * 0.5)
		end
		if v < lastVal then firedThisRound = false end -- angka reset = putaran baru
		lastVal, lastChangeT = v, now
	end

	info.Text = "Nilai: " .. v .. "  |  Target: " .. CFG.Target

	if not CFG.Enabled then return end
	if v < CFG.Target - 1 then firedThisRound = false end

	if not firedThisRound and now - lastPerfectT >= CFG.Cooldown then
		local predicted = v + math.max(rate, 0) * CFG.Lead
		if v >= CFG.Target or predicted >= CFG.Target then
			firedThisRound = true
			lastPerfectT = now
			click()
		end
	end
end))

------------------------------------------------------------
-- Auto klik "Klik untuk melanjutkan"
------------------------------------------------------------
local lastContT = 0
task.spawn(function()
	while alive do
		task.wait(0.25)
		if CFG.Enabled and CFG.AutoContinue and os.clock() - lastContT > 1 then
			for _, o in ipairs(texts()) do
				if o.Parent and visible(o) and o.TextTransparency < 0.9 then
					local n = norm(clean(o.Text))
					if n:find("klikuntukmelanjutkan", 1, true)
						or n:find("klikuntukmelanjut", 1, true)
						or n:find("clicktocontinue", 1, true) then
						lastContT = os.clock()
						local b = clickableFor(o)
						fireButton(b)
						click(centerOf(b))
						break
					end
				end
			end
		end
	end
end)

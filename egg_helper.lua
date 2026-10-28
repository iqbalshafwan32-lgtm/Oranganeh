-- Egg Helper: Live Egg ESP (rarity) + Set Teleport (Glide) + Steal
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local GLIDE_SPEED = 60 -- studs/detik, makin kecil makin aman
local eggsFolder = workspace:WaitForChild("LocalNests"):WaitForChild("Eggs")

-- Warna rarity (sesuaikan nama rarity game-nya)
local RARITY_COLORS = {
    common = Color3.fromRGB(200, 200, 200),
    uncommon = Color3.fromRGB(90, 220, 90),
    rare = Color3.fromRGB(70, 140, 255),
    epic = Color3.fromRGB(180, 80, 255),
    legendary = Color3.fromRGB(255, 190, 40),
    mythic = Color3.fromRGB(255, 70, 90),
}

local function getRarity(egg)
    local r = egg:GetAttribute("Rarity")
    if r then return tostring(r) end
    local v = egg:FindFirstChild("Rarity", true)
    if v and v:IsA("ValueBase") then return tostring(v.Value) end
    local lname = egg.Name:lower()
    for k in pairs(RARITY_COLORS) do
        if lname:find(k) then return k end
    end
    return "unknown"
end

local function getPos(egg)
    if egg:IsA("Model") then return egg:GetPivot().Position end
    if egg:IsA("BasePart") then return egg.Position end
end

-- ESP
local function addESP(egg)
    if egg:FindFirstChild("EggESP") then return end
    local adornee = egg:IsA("Model") and (egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)) or egg
    if not adornee then return end
    local rarity = getRarity(egg)
    local color = RARITY_COLORS[rarity:lower()] or Color3.new(1, 1, 1)

    local bb = Instance.new("BillboardGui")
    bb.Name = "EggESP"
    bb.Adornee = adornee
    bb.Size = UDim2.fromOffset(140, 36)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = egg

    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Text = egg.Name .. "\n[" .. rarity .. "]"
    t.TextColor3 = color
    t.TextStrokeTransparency = 0
    t.TextScaled = true
    t.Font = Enum.Font.GothamBold
    t.Parent = bb
end

for _, e in ipairs(eggsFolder:GetChildren()) do addESP(e) end
eggsFolder.ChildAdded:Connect(function(e) task.wait(0.2) addESP(e) end)

-- Glide
local currentTween
local function glideTo(pos)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if currentTween then currentTween:Cancel() end
    local dist = (hrp.Position - pos).Magnitude
    currentTween = TweenService:Create(hrp,
        TweenInfo.new(dist / GLIDE_SPEED, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))})
    currentTween:Play()
    return currentTween
end

local function nearestEgg()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local best, bd
    for _, e in ipairs(eggsFolder:GetChildren()) do
        local p = getPos(e)
        if p then
            local d = (p - hrp.Position).Magnitude
            if not bd or d < bd then best, bd = e, d end
        end
    end
    return best
end

-- Steal: coba pakai ProximityPrompt di egg.
-- Kalau StealEgg pakai RemoteEvent, kirim isi script StealEgg biar gue pasangin.
local function steal(egg)
    if not egg then return end
    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        fireproximityprompt(prompt)
    end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "EggHelper"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(160, 190)
frame.Position = UDim2.fromOffset(20, 120)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame)

local savedPos
local function button(text, y, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 34)
    b.Position = UDim2.fromOffset(8, y)
    b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = text
    b.Parent = frame
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

button("Set Teleport", 8, function(b)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if hrp then savedPos = hrp.Position b.Text = "Saved ✓" task.wait(1) b.Text = "Set Teleport" end
end)
button("Glide ke Teleport", 48, function()
    if savedPos then glideTo(savedPos) end
end)
button("Glide ke Egg Terdekat", 88, function()
    local e = nearestEgg()
    if e then glideTo(getPos(e)) end
end)
button("Steal Egg Terdekat", 128, function()
    local e = nearestEgg()
    if e then
        local tw = glideTo(getPos(e))
        if tw then tw.Completed:Wait() end
        steal(e)
    end
end)

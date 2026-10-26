--[[
SafeZone.luau — LocalScript (v14 • The Rich 🤑)
Place in: StarterPlayer > StarterPlayerScripts
MUST be a LocalScript.

Cleaned: duplicate TAP watcher removed, tail section (button wiring,
pulse, held HUD, hotkey) merged in once. No logic changed.
]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    warn("[The Rich] not a LocalScript — aborting")
    return
end
local playerGui = player:WaitForChild("PlayerGui")

-- config -------------------------------------------------------------------
local CONFIG = {
    DEFAULTS = {
        heightOff = 3,
        cooldown  = 1.0,
    },
    DASH = {
        speed      = 900,
        subSteps   = 6,
        stopRadius = 4,
        maxTime    = 8,
        jumpHeight = 14,
        wallProbe  = 8,
    },
    TARGET_WORDS = { "egg", "tap" },
    FARM = {
        retry      = 8,     -- detik sebelum egg yg sama dicoba lagi
        afterSteal = 0.6,   -- jeda setelah steal sebelum lanjut
    },
}

-- state --------------------------------------------------------------------
local state = {
    safeCFrame     = nil,
    lastTP         = 0,
    dashing        = false,
    savedSpeed     = nil,
    dashHumanoid   = nil,
    dashCharacter  = nil,
    hooked         = {},
}

-- UI -----------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name              = "TheRichUI"
gui.ResetOnSpawn      = false
gui.IgnoreGuiInset    = true
gui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
gui.Parent            = playerGui

local PANEL_W, PANEL_H, BAR_H = 300, 380, 48

local frame = Instance.new("Frame")
frame.Name                  = "Panel"
frame.Size                  = UDim2.fromOffset(PANEL_W, PANEL_H)
frame.Position              = UDim2.new(0, 16, 0.5, -PANEL_H / 2)
frame.BackgroundColor3      = Color3.fromRGB(20, 14, 34)
frame.BackgroundTransparency= 0.05
frame.BorderSizePixel       = 0
frame.Active                = true
frame.Parent                = gui

local frameGradient = Instance.new("UIGradient")
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 16, 52)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 20)),
})
frameGradient.Rotation = 90
frameGradient.Parent   = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent       = frame

local stroke = Instance.new("UIStroke")
stroke.Color        = Color3.fromRGB(120, 90, 220)
stroke.Thickness    = 1.5
stroke.Transparency = 0.25
stroke.Parent       = frame

-- title bar ----------------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Name                   = "TitleBar"
titleBar.Size                   = UDim2.new(1, 0, 0, BAR_H)
titleBar.BackgroundTransparency = 1
titleBar.Parent                 = frame

local title = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, -80, 0, 26)
title.Position               = UDim2.fromOffset(16, 6)
title.BackgroundTransparency = 1
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 20
title.TextXAlignment         = Enum.TextXAlignment.Left
title.TextColor3             = Color3.fromRGB(245, 245, 255)
title.Text                   = "The Rich 🤑"
title.Parent                 = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 220, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 130, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 80, 200)),
})
titleGradient.Parent = title

local titleStroke = Instance.new("UIStroke")
titleStroke.Color        = Color3.fromRGB(0, 200, 255)
titleStroke.Thickness    = 1
titleStroke.Transparency = 0.55
titleStroke.Parent       = title

local subtitle = Instance.new("TextLabel")
subtitle.Size                   = UDim2.new(1, -80, 0, 12)
subtitle.Position               = UDim2.fromOffset(16, 32)
subtitle.BackgroundTransparency = 1
subtitle.Font                   = Enum.Font.GothamMedium
subtitle.TextSize               = 10
subtitle.TextXAlignment         = Enum.TextXAlignment.Left
subtitle.TextColor3             = Color3.fromRGB(150, 140, 200)
subtitle.Text                   = "◈  SAFE ZONE  ·  FARM"
subtitle.Parent                 = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size                   = UDim2.fromOffset(26, 26)
minimizeBtn.Position               = UDim2.new(1, -64, 0, (BAR_H - 26) / 2)
minimizeBtn.BackgroundColor3       = Color3.fromRGB(50, 40, 80)
minimizeBtn.BackgroundTransparency = 0.2
minimizeBtn.BorderSizePixel        = 0
minimizeBtn.AutoButtonColor        = true
minimizeBtn.Font                   = Enum.Font.GothamBold
minimizeBtn.TextSize               = 18
minimizeBtn.TextColor3             = Color3.fromRGB(220, 220, 255)
minimizeBtn.Text                   = "−"
minimizeBtn.Parent                 = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent       = minimizeBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size                   = UDim2.fromOffset(26, 26)
closeBtn.Position               = UDim2.new(1, -32, 0, (BAR_H - 26) / 2)
closeBtn.BackgroundColor3       = Color3.fromRGB(180, 50, 80)
closeBtn.BackgroundTransparency = 0.15
closeBtn.BorderSizePixel        = 0
closeBtn.AutoButtonColor        = true
closeBtn.Font                   = Enum.Font.GothamBold
closeBtn.TextSize               = 16
closeBtn.TextColor3             = Color3.fromRGB(255, 230, 240)
closeBtn.Text                   = "×"
closeBtn.Parent                 = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent       = closeBtn

-- content ------------------------------------------------------------------
local content = Instance.new("Frame")
content.Name                   = "Content"
content.Size                   = UDim2.new(1, 0, 1, -BAR_H)
content.Position               = UDim2.fromOffset(0, BAR_H)
content.BackgroundTransparency = 1
content.Parent                 = frame

local status = Instance.new("TextLabel")
status.Size                   = UDim2.new(1, -32, 0, 18)
status.Position               = UDim2.fromOffset(16, 4)
status.BackgroundTransparency = 1
status.Font                   = Enum.Font.Gotham
status.TextSize               = 12
status.TextXAlignment         = Enum.TextXAlignment.Left
status.TextColor3             = Color3.fromRGB(160, 160, 190)
status.Text                   = "no zone set"
status.Parent                 = content

local heldLabel = Instance.new("TextLabel")
heldLabel.Size                   = UDim2.new(1, -32, 0, 16)
heldLabel.Position               = UDim2.fromOffset(16, 24)
heldLabel.BackgroundTransparency = 1
heldLabel.Font                   = Enum.Font.Gotham
heldLabel.TextSize               = 11
heldLabel.TextXAlignment         = Enum.TextXAlignment.Left
heldLabel.TextColor3             = Color3.fromRGB(130, 200, 255)
heldLabel.Text                   = "held: none"
heldLabel.Parent                 = content

local function makeButton(text, yOffset, accent)
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, -32, 0, 34)
    btn.Position               = UDim2.fromOffset(16, yOffset)
    btn.BackgroundColor3       = accent
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel        = 0
    btn.AutoButtonColor        = true
    btn.Font                   = Enum.Font.GothamSemibold
    btn.TextSize               = 14
    btn.TextColor3             = Color3.fromRGB(255, 255, 255)
    btn.Text                   = text
    btn.Parent                 = content
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = btn
    return btn
end

local setBtn   = makeButton("Set Safe Zone Here", 48, Color3.fromRGB(46, 118, 220))
local clearBtn = makeButton("Clear Zone",          90, Color3.fromRGB(150, 60, 60))

-- floating reopen toggle ---------------------------------------------------
local reopen = Instance.new("TextButton")
reopen.Name                   = "TheRichReopen"
reopen.Size                   = UDim2.fromOffset(40, 40)
reopen.Position               = UDim2.new(0, 16, 0, 16)
reopen.BackgroundColor3       = Color3.fromRGB(120, 70, 200)
reopen.BackgroundTransparency = 0.1
reopen.BorderSizePixel        = 0
reopen.AutoButtonColor        = true
reopen.Font                   = Enum.Font.GothamBold
reopen.TextSize               = 20
reopen.TextColor3             = Color3.fromRGB(255, 255, 255)
reopen.Text                   = "◈"
reopen.Visible                = false
reopen.Parent                 = gui

local reopenCorner = Instance.new("UICorner")
reopenCorner.CornerRadius = UDim.new(0, 10)
reopenCorner.Parent       = reopen

local reopenGradient = Instance.new("UIGradient")
reopenGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200)),
})
reopenGradient.Rotation = 45
reopenGradient.Parent   = reopen

-- custom drag (title label only — buttons stay clickable) ------------------
do
    local dragging, dragStart, dragStartPos = false, nil, nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging     = true
            dragStart    = input.Position
            dragStartPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(
            input.Position.X - dragStart.X,
            input.Position.Y - dragStart.Y
        )
        frame.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- minimize / close ---------------------------------------------------------
local minimized = false
local function setMinimized(v)
    minimized        = v
    content.Visible  = not v
    frame.Size       = v
        and UDim2.fromOffset(PANEL_W, BAR_H)
        or  UDim2.fromOffset(PANEL_W, PANEL_H)
    minimizeBtn.Text = v and "+" or "−"
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible  = false
    reopen.Visible = true
end)

reopen.MouseButton1Click:Connect(function()
    frame.Visible  = true
    reopen.Visible = false
end)

-- helpers ------------------------------------------------------------------
local function getRoot()
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- equipped tools are a child of Character, not Humanoid
local function getEquippedTool()
    local char = player.Character
    if char then
        return char:FindFirstChildOfClass("Tool")
    end
    return nil
end

local function setSafeZone()
    local root = getRoot()
    if not root then return end
    local target = root.CFrame + Vector3.new(0, CONFIG.DEFAULTS.heightOff, 0)
    state.safeCFrame = target
    status.Text = string.format("zone set @ %.0f, %.0f, %.0f",
        target.X, target.Y, target.Z)
end

-- dash ---------------------------------------------------------------------
local function endDash()
    state.dashing = false
    if state.dashHumanoid and state.dashHumanoid.Parent and state.savedSpeed then
        state.dashHumanoid.WalkSpeed = state.savedSpeed
        state.dashHumanoid.AutoRotate = true
    end
    state.savedSpeed    = nil
    state.dashHumanoid  = nil
    state.dashCharacter = nil
end

local function wallAhead(root, dir)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { player.Character }
    params.FilterType = Enum.RaycastFilterType.Exclude
    return workspace:Raycast(root.Position, dir * CONFIG.DASH.wallProbe, params) ~= nil
end

local function dashToZone()
    if state.dashing then return end
    if not state.safeCFrame then
        status.Text = "no zone set - set one first"
        return
    end

    local root = getRoot()
    local hum  = getHumanoid()
    if not root or not hum then return end
    if os.clock() - state.lastTP < CONFIG.DEFAULTS.cooldown then return end

    local targetPos  = state.safeCFrame.Position
    local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
    if (flatTarget - root.Position).Magnitude < CONFIG.DASH.stopRadius then return end

    state.dashing       = true
    state.lastTP        = os.clock()
    state.savedSpeed    = hum.WalkSpeed
    state.dashHumanoid  = hum
    state.dashCharacter = player.Character
    hum.WalkSpeed       = CONFIG.DASH.speed
    hum.AutoRotate      = false

    local equippedTool = getEquippedTool()
    local equippedName = equippedTool and equippedTool.Name or nil
    local deadline     = os.clock() + CONFIG.DASH.maxTime
    local heartbeat

    heartbeat = RunService.Heartbeat:Connect(function(dt)
        if not state.dashing then
            heartbeat:Disconnect(); return
        end
        if player.Character ~= state.dashCharacter then
            endDash(); heartbeat:Disconnect(); return
        end
        local r = getRoot()
        local h = getHumanoid()
        if not r or not h or not r.Parent then
            endDash(); heartbeat:Disconnect(); return
        end

        local goal     = Vector3.new(targetPos.X, r.Position.Y, targetPos.Z)
        local diff     = goal - r.Position
        local flatDist = Vector3.new(diff.X, 0, diff.Z).Magnitude

        if flatDist <= CONFIG.DASH.stopRadius or os.clock() > deadline then
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.CFrame = CFrame.new(Vector3.new(targetPos.X, r.Position.Y, targetPos.Z))
            endDash()
            if equippedName then
                task.defer(function()
                    task.wait(0.05)
                    local char = player.Character
                    local hh   = char and char:FindFirstChildOfClass("Humanoid")
                    if not hh then return end
                    local still = char:FindFirstChildOfClass("Tool")
                    if still and still.Name == equippedName then return end
                    local backpack = player:FindFirstChild("Backpack")
                    local t = backpack and backpack:FindFirstChild(equippedName)
                    if t and t:IsA("Tool") then hh:EquipTool(t) end
                end)
            end
            heartbeat:Disconnect(); return
        end

        local look = Vector3.new(diff.X, 0, diff.Z)
        if look.Magnitude <= 0.01 then
            endDash(); heartbeat:Disconnect(); return
        end
        local dir = look.Unit

        local frameMove = math.min(CONFIG.DASH.speed * dt, flatDist)
        local stepDist  = frameMove / CONFIG.DASH.subSteps
        local remaining = frameMove
        local here      = r.Position

        for _ = 1, CONFIG.DASH.subSteps do
            if remaining <= 0 then break end
            local move    = math.min(stepDist, remaining)
            local nextPos = here + dir * move

            local floorParams = RaycastParams.new()
            floorParams.FilterDescendantsInstances = { player.Character }
            floorParams.FilterType = Enum.RaycastFilterType.Exclude
            local floorHit = workspace:Raycast(
                nextPos + Vector3.new(0, 4, 0),
                Vector3.new(0, -12, 0),
                floorParams
            )

            if floorHit then
                here = Vector3.new(nextPos.X, r.Position.Y, nextPos.Z)
            else
                break
            end
            remaining -= move
        end

        r.CFrame = CFrame.new(here, here + dir)
        r.AssemblyLinearVelocity = Vector3.new(
            dir.X * CONFIG.DASH.speed,
            r.AssemblyLinearVelocity.Y,
            dir.Z * CONFIG.DASH.speed
        )

        if h.FloorMaterial ~= Enum.Material.Air and wallAhead(r, dir) then
            h.Jump = true
            r.AssemblyLinearVelocity = r.AssemblyLinearVelocity
                + Vector3.new(0, CONFIG.DASH.jumpHeight, 0)
        end
    end)
end

local function clearZone()
    state.safeCFrame = nil
    if state.dashing then endDash() end
    status.Text = "no zone set"
end

-- TAP watcher --------------------------------------------------------------
local function nameHasTarget(name)
    local low = string.lower(name or "")
    for _, word in ipairs(CONFIG.TARGET_WORDS) do
        if string.find(low, word, 1, true) then return true end
    end
    return false
end

local function isEggTarget(obj)
    if nameHasTarget(obj.Name) then return true end
    local p = obj.Parent
    if p and nameHasTarget(p.Name) then return true end
    if obj:IsA("ClickDetector") or obj:IsA("ProximityPrompt") then
        local part = obj.Parent
        if part and part.Parent and nameHasTarget(part.Parent.Name) then
            return true
        end
    end
    return false
end

local function fireTap(sourceLabel)
    if not state.safeCFrame then
        status.Text = "TAP heard - no zone set"
        return
    end
    status.Text = "TAP fired (" .. sourceLabel .. ") - dashing"
    dashToZone()
end

local function hookClickDetector(cd)
    if state.hooked[cd] then return end
    state.hooked[cd] = true
    cd.MouseClick:Connect(function(who)
        if who ~= player then return end
        fireTap("ClickDetector")
    end)
end

local function hookGuiButton(btn)
    if state.hooked[btn] then return end
    state.hooked[btn] = true
    btn.MouseButton1Click:Connect(function()
        fireTap("GuiButton")
    end)
end

local function hookPrompt(prompt)
    if state.hooked[prompt] then return end
    state.hooked[prompt] = true
    prompt.Triggered:Connect(function(who)
        if who ~= player then return end
        fireTap("ProximityPrompt")
    end)
end

local function hookIfTap(inst)
    if inst:IsA("ClickDetector") and isEggTarget(inst) then
        hookClickDetector(inst)
        local partName = inst.Parent and inst.Parent.Name or "?"
        status.Text = "hooked egg TAP (ClickDetector: " .. partName .. ")"
    elseif inst:IsA("ProximityPrompt") and isEggTarget(inst) then
        hookPrompt(inst)
    elseif inst:IsA("GuiButton") and nameHasTarget(inst.Name) then
        hookGuiButton(inst)
    end
end

-- hook BEFORE scanning, so nothing spawned in the gap is missed
workspace.DescendantAdded:Connect(function(d)
    if d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
        hookIfTap(d)
    end
end)
playerGui.DescendantAdded:Connect(hookIfTap)

for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("ClickDetector") or d:IsA("ProximityPrompt") then
        hookIfTap(d)
    end
end
for _, d in ipairs(playerGui:GetDescendants()) do
    hookIfTap(d)
end

-- egg list + TP / STEAL + auto farm ----------------------------------------
-- Urutan rarity dari paling rendah ke paling tinggi (ubah di sini kalau beda)
local RARITY_ORDER = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Mythic", "Secret", "Godly", "Divine", "Celestial",
}
local RARITY_COLORS = {
    Common    = Color3.fromRGB(190, 190, 200),
    Uncommon  = Color3.fromRGB(110, 220, 120),
    Rare      = Color3.fromRGB(80, 160, 255),
    Epic      = Color3.fromRGB(180, 100, 255),
    Legendary = Color3.fromRGB(255, 190, 50),
    Mythic    = Color3.fromRGB(255, 80, 120),
    Secret    = Color3.fromRGB(120, 255, 230),
    Godly     = Color3.fromRGB(255, 140, 40),
    Divine    = Color3.fromRGB(255, 245, 170),
    Celestial = Color3.fromRGB(110, 230, 255),
    Unknown   = Color3.fromRGB(150, 150, 160),
}

local rarityCanon = {}   -- lowercase -> nama kanonik
for _, n in ipairs(RARITY_ORDER) do rarityCanon[string.lower(n)] = n end

-- cocokkan dari nama terpanjang dulu supaya "Uncommon" tidak kebaca "Common"
local rarityByLength = table.clone(RARITY_ORDER)
table.sort(rarityByLength, function(a, b) return #a > #b end)

local function rankOf(r)
    for i, n in ipairs(RARITY_ORDER) do
        if n == r then return i end
    end
    return 0
end

local function matchRarityInText(text)
    local low = string.lower(text or "")
    for _, n in ipairs(rarityByLength) do
        if string.find(low, string.lower(n), 1, true) then return n end
    end
    return nil
end

local function detectRarity(egg)
    local attr = egg:GetAttribute("Rarity")
    if typeof(attr) == "string" and rarityCanon[string.lower(attr)] then
        return rarityCanon[string.lower(attr)]
    end
    local val = egg:FindFirstChild("Rarity")
    if val and val:IsA("StringValue") and rarityCanon[string.lower(val.Value)] then
        return rarityCanon[string.lower(val.Value)]
    end
    local byName = matchRarityInText(egg.Name)
    if byName then return byName end
    for _, d in ipairs(egg:GetDescendants()) do
        local r = matchRarityInText(d.Name)
        if r then return r end
    end
    return nil
end

-- egg helpers --------------------------------------------------------------
local function getEggFolder()
    local nests = workspace:FindFirstChild("LocalNests")
    return nests and nests:FindFirstChild("Eggs")
end

local function getEggPos(egg)
    if egg:IsA("Model") then
        return egg:GetPivot().Position
    elseif egg:IsA("BasePart") then
        return egg.Position
    end
    local part = egg:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function tpToEgg(egg)
    local root = getRoot()
    local pos  = egg and egg.Parent and getEggPos(egg)
    if not root or not pos then return false end
    if state.dashing then endDash() end
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    return true
end

local function findInteract(egg)
    return egg:FindFirstChildWhichIsA("ProximityPrompt", true)
        or egg:FindFirstChildWhichIsA("ClickDetector", true)
end

-- TP ke egg lalu "ambil" lewat ProximityPrompt / ClickDetector di dalam egg.
-- Hook TAP di atas ikut kepicu, jadi kalau safe zone sudah di-set,
-- karakter otomatis dash balik ke zone setelah steal.
local function stealEgg(egg)
    if not egg or not egg.Parent then
        status.Text = "egg sudah hilang"
        return false
    end
    if not tpToEgg(egg) then
        status.Text = "gagal TP ke egg"
        return false
    end
    task.wait(0.2)
    local it = findInteract(egg)
    if not it then
        status.Text = "steal: prompt/click tidak ketemu"
        return false
    end
    status.Text = "steal: " .. egg.Name
    if it:IsA("ProximityPrompt") then
        local ok = false
        if typeof(fireproximityprompt) == "function" then
            ok = pcall(fireproximityprompt, it)
        end
        if not ok then
            pcall(function()
                it:InputHoldBegin()
                task.wait(math.max(it.HoldDuration, 0) + 0.1)
                it:InputHoldEnd()
            end)
        end
    else
        if typeof(fireclickdetector) == "function" then
            pcall(fireclickdetector, it)
        else
            status.Text = "steal: executor tidak support fireclickdetector"
        end
    end
    return true
end

-- layout tombol atas: Set / Clear sebaris ----------------------------------
setBtn.Size       = UDim2.new(0.5, -20, 0, 34)
setBtn.Position   = UDim2.fromOffset(16, 48)
clearBtn.Size     = UDim2.new(0.5, -20, 0, 34)
clearBtn.Position = UDim2.new(0.5, 4, 0, 48)

-- auto farm controls -------------------------------------------------------
local farm = { on = false, minIdx = 0 }   -- minIdx 0 = semua rarity
local tried = setmetatable({}, { __mode = "k" })

local farmBtn = makeButton("Auto Farm: OFF", 88, Color3.fromRGB(70, 70, 90))
farmBtn.Size     = UDim2.new(0.5, -20, 0, 30)
farmBtn.Position = UDim2.fromOffset(16, 88)
farmBtn.TextSize = 12

local minBtn = makeButton("Min: Any", 88, Color3.fromRGB(90, 70, 160))
minBtn.Size     = UDim2.new(0.5, -20, 0, 30)
minBtn.Position = UDim2.new(0.5, 4, 0, 88)
minBtn.TextSize = 12

farmBtn.MouseButton1Click:Connect(function()
    farm.on = not farm.on
    farmBtn.Text = farm.on and "Auto Farm: ON" or "Auto Farm: OFF"
    farmBtn.BackgroundColor3 = farm.on
        and Color3.fromRGB(40, 160, 90)
        or  Color3.fromRGB(70, 70, 90)
    status.Text = farm.on and "auto farm jalan" or "auto farm berhenti"
end)

minBtn.MouseButton1Click:Connect(function()
    farm.minIdx = (farm.minIdx + 1) % (#RARITY_ORDER + 1)
    minBtn.Text = farm.minIdx == 0
        and "Min: Any"
        or ("Min: " .. RARITY_ORDER[farm.minIdx] .. "+")
end)

-- egg list UI --------------------------------------------------------------
local eggHeader = Instance.new("TextLabel")
eggHeader.Size                   = UDim2.new(1, -110, 0, 18)
eggHeader.Position               = UDim2.fromOffset(16, 126)
eggHeader.BackgroundTransparency = 1
eggHeader.Font                   = Enum.Font.GothamBold
eggHeader.TextSize               = 12
eggHeader.TextXAlignment         = Enum.TextXAlignment.Left
eggHeader.TextColor3             = Color3.fromRGB(200, 180, 255)
eggHeader.Text                   = "EGGS · searching…"
eggHeader.Parent                 = content

local refreshBtn = Instance.new("TextButton")
refreshBtn.Name                   = "Refresh"
refreshBtn.Size                   = UDim2.fromOffset(78, 20)
refreshBtn.Position               = UDim2.new(1, -94, 0, 125)
refreshBtn.BackgroundColor3       = Color3.fromRGB(70, 55, 130)
refreshBtn.BackgroundTransparency = 0.15
refreshBtn.BorderSizePixel        = 0
refreshBtn.AutoButtonColor        = true
refreshBtn.Font                   = Enum.Font.GothamSemibold
refreshBtn.TextSize               = 11
refreshBtn.TextColor3             = Color3.fromRGB(240, 235, 255)
refreshBtn.Text                   = "↻ Refresh"
refreshBtn.Parent                 = content
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent       = refreshBtn
end

local eggList = Instance.new("ScrollingFrame")
eggList.Name                   = "EggList"
eggList.Position               = UDim2.fromOffset(16, 150)
eggList.Size                   = UDim2.new(1, -32, 1, -160)
eggList.BackgroundColor3       = Color3.fromRGB(10, 8, 20)
eggList.BackgroundTransparency = 0.45
eggList.BorderSizePixel        = 0
eggList.ScrollBarThickness     = 3
eggList.CanvasSize             = UDim2.new()
eggList.AutomaticCanvasSize    = Enum.AutomaticSize.Y
eggList.Parent                 = content
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent       = eggList
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding   = UDim.new(0, 2)
    l.Parent    = eggList
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingTop  = UDim.new(0, 4)
    p.Parent      = eggList
end

local function clearRows()
    for _, c in ipairs(eggList:GetChildren()) do
        if c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end
    end
end

local function addHeader(text, color, order)
    local l = Instance.new("TextLabel")
    l.Size                   = UDim2.new(1, -8, 0, 20)
    l.BackgroundTransparency = 1
    l.Font                   = Enum.Font.GothamBold
    l.TextSize               = 12
    l.TextXAlignment         = Enum.TextXAlignment.Left
    l.TextColor3             = color
    l.Text                   = text
    l.LayoutOrder            = order
    l.Parent                 = eggList
end

local function makeRowButton(name, text, pos, width, color)
    local b = Instance.new("TextButton")
    b.Name                   = name   -- jangan pakai kata "egg"/"tap" (kena hook TAP)
    b.Size                   = UDim2.fromOffset(width, 18)
    b.Position               = pos
    b.BackgroundColor3       = color
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel        = 0
    b.AutoButtonColor        = true
    b.Font                   = Enum.Font.GothamBold
    b.TextSize               = 10
    b.TextColor3             = Color3.fromRGB(255, 255, 255)
    b.Text                   = text
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent       = b
    return b
end

local function addEggRow(egg, label, color, order)
    local row = Instance.new("Frame")
    row.Name                   = "Row"
    row.Size                   = UDim2.new(1, -8, 0, 22)
    row.BackgroundTransparency = 1
    row.LayoutOrder            = order
    row.Parent                 = eggList

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -100, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 11
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.TextColor3             = color
    lbl.Text                   = "  " .. label
    lbl.Parent                 = row

    local tpB = makeRowButton("GoBtn", "TP",
        UDim2.new(1, -94, 0.5, -9), 38, Color3.fromRGB(46, 118, 220))
    tpB.Parent = row
    local stB = makeRowButton("TakeBtn", "STEAL",
        UDim2.new(1, -52, 0.5, -9), 46, Color3.fromRGB(190, 70, 90))
    stB.Parent = row

    tpB.MouseButton1Click:Connect(function()
        if not tpToEgg(egg) then status.Text = "egg sudah hilang" end
    end)
    stB.MouseButton1Click:Connect(function()
        task.spawn(stealEgg, egg)
    end)
end

local function refreshEggs()
    clearRows()

    local folder = getEggFolder()
    if not folder then
        eggHeader.Text = "EGGS · not found"
        return
    end

    local groups, total = {}, 0   -- groups[rarity] = { egg, egg, ... }
    for _, egg in ipairs(folder:GetChildren()) do
        total += 1
        local r = detectRarity(egg) or "Unknown"
        groups[r] = groups[r] or {}
        table.insert(groups[r], egg)
    end
    eggHeader.Text = "EGGS · " .. total

    local order = 0
    local function emit(rarity)
        local list = groups[rarity]
        if not list then return end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        local color = RARITY_COLORS[rarity] or RARITY_COLORS.Unknown
        order += 1
        addHeader(string.format("◈ %s (%d)", string.upper(rarity), #list), color, order)

        local seen, totals = {}, {}
        for _, e in ipairs(list) do totals[e.Name] = (totals[e.Name] or 0) + 1 end
        for _, e in ipairs(list) do
            seen[e.Name] = (seen[e.Name] or 0) + 1
            local label = e.Name
            if totals[e.Name] > 1 then
                label = string.format("%s #%d", e.Name, seen[e.Name])
            end
            order += 1
            addEggRow(e, label, color, order)
        end
    end

    for i = #RARITY_ORDER, 1, -1 do   -- paling langka di atas
        emit(RARITY_ORDER[i])
    end
    emit("Unknown")
end

local refreshQueued = false
local function queueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    task.delay(0.3, function()
        refreshQueued = false
        refreshEggs()
    end)
end

refreshBtn.MouseButton1Click:Connect(refreshEggs)

task.spawn(function()
    local bound
    while gui.Parent do
        local f = getEggFolder()
        if f and f ~= bound then
            bound = f
            f.ChildAdded:Connect(queueRefresh)
            f.ChildRemoved:Connect(queueRefresh)
            refreshEggs()
        elseif not f and bound then
            bound = nil
            refreshEggs()
        end
        task.wait(2)
    end
end)

-- auto farm loop -----------------------------------------------------------
local function pickTarget()
    local folder = getEggFolder()
    local root   = getRoot()
    if not folder or not root then return nil end

    local best, bestRank, bestDist
    for _, egg in ipairs(folder:GetChildren()) do
        local last = tried[egg]
        if not (last and os.clock() - last < CONFIG.FARM.retry) then
            local rank = rankOf(detectRarity(egg))
            if rank >= farm.minIdx then
                local pos = getEggPos(egg)
                if pos then
                    local d = (pos - root.Position).Magnitude
                    if not best or rank > bestRank
                        or (rank == bestRank and d < bestDist) then
                        best, bestRank, bestDist = egg, rank, d
                    end
                end
            end
        end
    end
    return best
end

task.spawn(function()
    while gui.Parent do
        task.wait(0.3)
        if farm.on and not state.dashing then
            local egg = pickTarget()
            if egg then
                tried[egg] = os.clock()
                stealEgg(egg)
                task.wait(CONFIG.FARM.afterSteal)
                local t0 = os.clock()
                while state.dashing and farm.on and os.clock() - t0 < 10 do
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- button wiring ------------------------------------------------------------
setBtn.MouseButton1Click:Connect(setSafeZone)
clearBtn.MouseButton1Click:Connect(clearZone)

-- visual pulse (branding only, does not touch state) -----------------------
task.spawn(function()
    local t = 0
    while gui.Parent do
        task.wait(0.05)
        t = t + 0.05
        local a = (math.sin(t * 2) + 1) * 0.5
        stroke.Transparency      = 1 - a * 0.6
        stroke.Color             = Color3.fromRGB(
            120 + math.floor(a * 60),
            90  + math.floor(a * 40),
            220
        )
        titleGradient.Rotation   = t * 25
        titleStroke.Transparency = 0.7 - a * 0.3
    end
end)

-- held-tool HUD ------------------------------------------------------------
task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        local equipped = getEquippedTool()
        heldLabel.Text = equipped and ("held: " .. equipped.Name) or "held: none"
    end
end)

-- hotkey: RightShift = set zone --------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setSafeZone()
    end
end)

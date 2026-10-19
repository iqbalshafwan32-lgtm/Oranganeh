-- ==========================================================
-- V13: ULTIMATE SNIPER (Filter Rarity, Noclip, Delay, Auto Sell)
-- ==========================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- ==========================================
-- [1] TABEL PENGATURAN RARITY (UBAH TRUE/FALSE)
-- ==========================================
local RaritySettings = {
    ["Common"]    = true,  -- true = Cari/Ambil, false = Abaikan
    ["Uncommon"]  = true,
    ["Rare"]      = true,
    ["Epic"]      = true,
    ["Legendary"] = true,
    ["Mythic"]    = true,
    ["Diamond"]   = true,  -- Khusus tier Diamond
    ["Gold"]      = true,  -- Khusus tier Gold
    ["Golden"]    = true,  -- Kadang game pakai kata "Golden"
    ["Rainbow"]   = true
}

-- Pengaturan Lainnya
local FlySpeed = 120
local isBusy = false
local homePos = nil

-- ==========================================
-- [2] SETUP DASAR (NOCLIP & POSISI)
-- ==========================================
local function getHRP()
    if LocalPlayer.Character then return LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
    return nil
end

local hrp = getHRP()
if hrp then homePos = hrp.CFrame end
print("[V13] Base dicatat. Sniper Rarity Aktif!")

-- Noclip Otomatis
RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide then
                child.CanCollide = false
            end
        end
    end
end)

-- ==========================================
-- [3] FUNGSI PENDUKUNG
-- ==========================================
local function flyTo(targetCFrame)
    local h_root = getHRP()
    if not h_root then return end
    while true do
        if not getHRP() then break end
        local dist = (targetCFrame.Position - getHRP().Position).Magnitude
        if dist < 6 then
            getHRP().Velocity = Vector3.new(0, 0, 0)
            break
        end
        local dir = (targetCFrame.Position - getHRP().Position).Unit
        getHRP().Velocity = dir * FlySpeed
        task.wait(0.05)
    end
end

local function isCarryingGift()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Visible then
                local txt = string.lower(gui.Text)
                if string.find(txt, "carrying") or string.find(txt, "cross the line") then return true end
            end
        end
    end
    return false
end

local function isBaseFull()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Visible then
                if string.find(string.lower(gui.Text), "base full") then return true end
            end
        end
    end
    return false
end

-- [FUNGSI UTAMA] Cek apakah kotak ini sesuai dengan Tier yang di-ON-kan
local function isTargetRarity(obj)
    -- Kita baca teks melayang di atas kotak hadiah
    for _, child in pairs(obj:GetChildren()) do
        if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
            for _, desc in pairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    local text = string.lower(desc.Text)
                    -- Cek setiap rarity di tabel kita
                    for rarityName, isEnabled in pairs(RaritySettings) do
                        if isEnabled then
                            -- Jika teks di game mengandung nama rarity yang ON, maka ambil!
                            if string.find(text, string.lower(rarityName)) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end


-- ==========================================
-- [4] LOOP UTAMA
-- ==========================================
task.spawn(function()
    while task.wait(0.5) do
        if not isBusy and homePos then
            local currentHrp = getHRP()
            
            if currentHrp then
                -- PRIORITAS 1: JIKA MEMBAWA KOTAK, PULANG
                if isCarryingGift() then
                    isBusy = true
                    print("[V13] Membawa Kotak! Terbang pulang...")
                    flyTo(homePos * CFrame.new(0, 0, -10))
                    task.wait(2)
                    isBusy = false
                    
                -- PRIORITAS 2: JIKA BASE PENUH, JUAL (KLIK 2X)
                elseif isBaseFull() then
                    isBusy = true
                    print("[V13] Base Penuh! Mencari barang untuk dijual...")
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled and string.find(string.lower(prompt.ActionText), "sell") then
                            local pos = obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
                            if pos and (homePos.Position - pos).Magnitude < 50 then
                                flyTo(obj:IsA("BasePart") and obj.CFrame or obj.PrimaryPart.CFrame)
                                task.wait(0.5)
                                pcall(function()
                                    fireproximityprompt(prompt)
                                    task.wait(0.2)
                                    fireproximityprompt(prompt) -- Klik Ganda
                                end)
                                task.wait(2)
                                break
                            end
                        end
                    end
                    isBusy = false
                    
                -- PRIORITAS 3: CARI HADIAH BARU (Berdasarkan Tabel Rarity)
                else
                    local bestGift, bestPrompt, maxDist = nil, nil, 1000
                    
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if (obj:IsA("BasePart") or obj:IsA("Model")) and not obj:IsDescendantOf(LocalPlayer.Character) then
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            
                            -- Pastikan ada tombol Steal
                            if prompt and prompt.Enabled and string.find(string.lower(prompt.ActionText), "steal") then
                                
                                -- CEK RARITY: Apakah ini Gold/Diamond/Common yang di-ON kan?
                                if isTargetRarity(obj) then
                                    local pos = obj:IsA("BasePart") and obj.Position or (obj.PrimaryPart and obj.PrimaryPart.Position)
                                    if pos then
                                        local d = (currentHrp.Position - pos).Magnitude
                                        if d < maxDist then
                                            bestGift, bestPrompt, maxDist = obj, prompt, d
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if bestGift and bestPrompt then
                        isBusy = true
                        print("[V13] Menemukan target rarity! Mencuri: " .. bestGift.Name)
                        local targetPos = bestGift:IsA("BasePart") and bestGift.CFrame or bestGift.PrimaryPart.CFrame
                        
                        flyTo(targetPos)
                        task.wait(0.5)
                        
                        print("[V13] Menekan Steal. Menunggu animasi...")
                        pcall(function() fireproximityprompt(bestPrompt, 1) end)
                        
                        -- DELAY: Tunggu sampai UI "Carrying" muncul (maksimal 10 detik)
                        local timeout = 0
                        while not isCarryingGift() and timeout < 20 do
                            task.wait(0.5)
                            timeout = timeout + 1
                        end
                        
                        if isCarryingGift() then print("[V13] Sukses membawa kotak!") end
                        task.wait(1)
                        isBusy = false
                    end
                end
            end
        end
    end
end)
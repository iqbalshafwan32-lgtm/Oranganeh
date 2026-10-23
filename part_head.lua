--[[
    RIDE A FISH  •  Wild Eggs Hub   (UI Rodeo Edition)
    tt: indr.ra_

    • Tampilan / UI disamakan dengan Rodeo (46 tema + dekorasi animasi + tombol bubble + foto bawaan)
    • Ada tab TEMA (ganti tema, transparansi, ukuran UI, gambar background)
    • Fitur tetap milik rdfsh: Radar Egg, Run Once, Auto Loop Farm, Farm Token, Quick Get, Anti AFK
    • Detail tambahan: alert egg langka, Egg ESP, statistik sesi, egg terdekat, pengaturan radar,
      preset pilih egg, pilihan egg & pengaturan tersimpan otomatis, animasi pembuka.
    Script ini berdiri sendiri.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Http = game:GetService("HttpService")
local Market = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local rgb = Color3.fromRGB
local WHITE = rgb(255, 255, 255)
local GREEN, RED, YELLOW = rgb(80, 220, 120), rgb(255, 80, 80), rgb(250, 204, 21)
local FONT = Enum.Font
local LEFT, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right

----------------------------------------------------------------------
-- LOGO (opsional)
-- Isi dengan Asset ID gambar dari Roblox (angka saja), contoh: "1234567890"
-- Kosongkan ("") untuk memakai logo emoji bawaan.
----------------------------------------------------------------------
local LOGO_ASSET_ID = ""
local LOGO_IMAGE = nil
do
    local str = tostring(LOGO_ASSET_ID or "")
    if str ~= "" then
        LOGO_IMAGE = str:match("^%d+$") and ("rbxassetid://" .. str) or str
    end
end

-- kalau script dijalankan ulang: matikan instance lama dulu
local genv = (getgenv and getgenv()) or _G
if genv.RdfshCleanup then
    pcall(genv.RdfshCleanup)
    genv.RdfshCleanup = nil
end
do
    local o = playerGui:FindFirstChild("RdfshHubGui")
    if o then o:Destroy() end
    local e = playerGui:FindFirstChild("RdfshEggEsp")
    if e then e:Destroy() end
    local r = Workspace:FindFirstChild("RdfshRadarFolder")
    if r then r:Destroy() end
end

----------------------------------------------------------------------
-- STATE + SIMPAN PENGATURAN
----------------------------------------------------------------------
local S = {
    -- fitur
    antiAfk = true, rareAlert = true, alertSound = true, eggEsp = false, clickSnd = true,
    radarMax = 8, radarSpeed = 0.8, loopDelay = 2,
    sel = {}, -- egg yang dipilih: [namaEgg] = true/false
    -- tampilan
    pt = 0.35, anim = true, theme = "default", img = "134262192520482", size = 1, infoBar = true,
}
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local SAVE = "RideAFishHub_config.json"
local SAVED = { "theme", "pt", "anim", "img", "size", "infoBar", "antiAfk", "rareAlert", "alertSound", "eggEsp",
    "clickSnd", "radarMax", "radarSpeed", "loopDelay", "sel" }
pcall(function()
    if isfile and isfile(SAVE) then
        local d = Http:JSONDecode(readfile(SAVE))
        if type(d) == "table" then
            for _, k in ipairs(SAVED) do
                if d[k] ~= nil and type(d[k]) == type(S[k]) then S[k] = d[k] end
            end
        end
    end
end)
S.pt = math.clamp(S.pt, 0, 0.85)
S.size = math.clamp(S.size, 0.6, 1)
S.radarMax = math.clamp(math.floor(S.radarMax), 1, 20)
S.radarSpeed = math.clamp(S.radarSpeed, 0.2, 3)
S.loopDelay = math.clamp(S.loopDelay, 0.5, 30)
if S.img == "" then S.img = "134262192520482" end

local saveTok = 0
local function save()
    saveTok = saveTok + 1
    local tok = saveTok
    task.delay(0.6, function()
        if tok ~= saveTok then return end
        pcall(function()
            if writefile then
                local t = {}
                for _, k in ipairs(SAVED) do t[k] = S[k] end
                writefile(SAVE, Http:JSONEncode(t))
            end
        end)
    end)
end

----------------------------------------------------------------------
-- SUARA
----------------------------------------------------------------------
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://122835655736085"
clickSound.Volume = 0.35
clickSound.Parent = Workspace
local alertSnd = Instance.new("Sound")
alertSnd.SoundId = "rbxassetid://122835655736085"
alertSnd.Volume = 0.7
alertSnd.PlaybackSpeed = 0.75
alertSnd.Parent = Workspace
local function playClick()
    if S.clickSnd then pcall(function() clickSound:Play() end) end
end


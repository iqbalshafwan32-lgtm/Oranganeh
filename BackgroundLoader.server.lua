--[[
	TheRichHUB BackgroundLoader
	Jenis   : Script (server)
	Letakkan: ServerScriptService
	Fungsi  : memuat asset 70693066629625 dan menyesuaikan jenisnya otomatis.
	          Sky/Atmosphere/Clouds/PostEffect -> Lighting/Terrain
	          Part/Model/Folder                -> Workspace.TheRichHUB_Environment
	          Script di dalam asset dihapus demi keamanan.
]]
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")

local ASSET_ID = 70693066629625

local ok, container = pcall(InsertService.LoadAsset, InsertService, ASSET_ID)
if not ok then
	warn("[TheRichHUB] Gagal memuat asset " .. ASSET_ID .. ": " .. tostring(container)
		.. "\nPastikan asset sudah di-claim/diizinkan untuk experience ini dan Allow Third Party Sales/InsertService aktif.")
	return
end

for _, d in container:GetDescendants() do
	if d:IsA("LuaSourceContainer") then d:Destroy() end
end

local POST = { "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect", "DepthOfFieldEffect" }
local envFolder = Instance.new("Folder")
envFolder.Name = "TheRichHUB_Environment"

local function replaceIn(parent, inst)
	local existing = parent:FindFirstChildOfClass(inst.ClassName)
	if existing then existing:Destroy() end
	inst.Parent = parent
end

for _, child in container:GetChildren() do
	if child:IsA("Sky") then
		replaceIn(Lighting, child)
	elseif child:IsA("Clouds") then
		replaceIn(workspace.Terrain, child)
	elseif table.find(POST, child.ClassName) then
		replaceIn(Lighting, child)
	elseif child:IsA("BasePart") or child:IsA("Model") or child:IsA("Folder") then
		child.Parent = envFolder
	elseif child:IsA("Decal") or child:IsA("Texture") then
		warn("[TheRichHUB] Asset berupa gambar; pakai ID-nya di CONFIG.BackgroundImageId.")
	end
end

if #envFolder:GetChildren() > 0 then envFolder.Parent = workspace else envFolder:Destroy() end
container:Destroy()
print("[TheRichHUB] Asset background diterapkan.")

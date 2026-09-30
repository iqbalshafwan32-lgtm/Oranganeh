local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SimpleAutoClickerGui") then
	playerGui.SimpleAutoClickerGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleAutoClickerGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 195)
mainFrame.Position = UDim2.new(0.5, -115, 0.5, -97)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(75, 75, 110)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -65, 0, 35)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
titleLabel.Text = " OPEN SEA FOR ANIMALS"
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -28, 0, 6)
closeButton.BackgroundColor3 = Color3.fromRGB(235, 75, 75)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.TextSize = 11
closeButton.Font = Enum.Font.FredokaOne
closeButton.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 24, 0, 24)
minimizeButton.Position = UDim2.new(1, -56, 0, 6)
minimizeButton.BackgroundColor3 = Color3.fromRGB(235, 165, 75)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.Text = "-"
minimizeButton.TextSize = 13
minimizeButton.Font = Enum.Font.FredokaOne
minimizeButton.Parent = mainFrame

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeButton

local container = Instance.new("ScrollingFrame")
container.Name = "UIContainer"
container.Size = UDim2.new(1, 0, 1, -40)
container.Position = UDim2.new(0, 0, 0, 36)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.CanvasSize = UDim2.new(0, 0, 0, 220)
container.ScrollBarThickness = 3
container.Parent = mainFrame

local containerLayout = Instance.new("UIListLayout")
containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
containerLayout.Padding = UDim.new(0, 6)
containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
containerLayout.Parent = container

local toggleClickButton = Instance.new("TextButton")
toggleClickButton.Size = UDim2.new(0, 206, 0, 32)
toggleClickButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
toggleClickButton.TextColor3 = Color3.fromRGB(200, 200, 220)
toggleClickButton.Text = "AUTO X2: OFF"
toggleClickButton.TextSize = 12
toggleClickButton.Font = Enum.Font.FredokaOne
toggleClickButton.LayoutOrder = 1
toggleClickButton.Parent = container

local toggleClickCorner = Instance.new("UICorner")
toggleClickCorner.CornerRadius = UDim.new(0, 8)
toggleClickCorner.Parent = toggleClickButton

local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(0, 206, 0, 32)
dropdownButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
dropdownButton.TextColor3 = Color3.fromRGB(200, 200, 220)
dropdownButton.Text = "Target: Pilih Target (0) ▾"
dropdownButton.TextSize = 12
dropdownButton.Font = Enum.Font.FredokaOne
dropdownButton.LayoutOrder = 2
dropdownButton.Parent = container

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 8)
dropdownCorner.Parent = dropdownButton

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Size = UDim2.new(0, 206, 0, 100)
dropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ScrollBarThickness = 4
dropdownList.LayoutOrder = 3
dropdownList.Parent = container

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 8)
listCorner.Parent = dropdownList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = dropdownList

local toggleTpButton = Instance.new("TextButton")
toggleTpButton.Size = UDim2.new(0, 206, 0, 34)
toggleTpButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
toggleTpButton.TextColor3 = Color3.fromRGB(200, 200, 220)
toggleTpButton.Text = "AUTO CLAIM EGG: OFF"
toggleTpButton.TextSize = 12
toggleTpButton.Font = Enum.Font.FredokaOne
toggleTpButton.LayoutOrder = 4
toggleTpButton.Parent = container

local toggleTpCorner = Instance.new("UICorner")
toggleTpCorner.CornerRadius = UDim.new(0, 8)
toggleTpCorner.Parent = toggleTpButton

local statusCarryLabel = Instance.new("TextLabel")
statusCarryLabel.Size = UDim2.new(0, 206, 0, 18)
statusCarryLabel.BackgroundTransparency = 1
statusCarryLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
statusCarryLabel.Text = "Status: Idle"
statusCarryLabel.TextSize = 10
statusCarryLabel.Font = Enum.Font.FredokaOne
statusCarryLabel.LayoutOrder = 5
statusCarryLabel.Parent = container

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(0, 206, 0, 16)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.TextColor3 = Color3.fromRGB(110, 110, 140)
watermarkLabel.Text = "ORANGANEH?"
watermarkLabel.TextSize = 10
watermarkLabel.Font = Enum.Font.FredokaOne
watermarkLabel.LayoutOrder = 6
watermarkLabel.Parent = container

local isClickRunning = false
local isTpRunning = false
local isMinimized = false
local selectedTargets = {} 
local originalPosition = nil

local finalItemsList = {
  "balrog_egg",
  "basic_egg",
  "bats_egg",
  "capybara_egg",
  "dragon_egg",
  "frogs_egg",
  "gem_egg",
  "giraffe_egg",
  "golem_egg",
  "gorilla_egg",
  "historic_egg",
  "imp_egg",
  "knight_egg",
  "mamut_egg",
  "mouse_egg",
  "ocean_egg",
  "osctrich_egg",
  "phoenix_egg",
  "polarbear_egg",
  "rift_egg",
  "sakura_egg",
  "seal_egg",
  "sentinel_egg",
  "snails_egg",
  "snake_egg",
  "sphinx_egg",
  "star_egg",
  "tigers_egg",
  "tree_egg",
  "trex_egg",
  "whale_egg"

}

pcall(function()
	dropdownList.CanvasSize = UDim2.new(0, 0, 0, #finalItemsList * 26)
	
	for i, itemName in ipairs(finalItemsList) do
		local itemButton = Instance.new("TextButton")
		itemButton.Size = UDim2.new(1, 0, 0, 24)
		itemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
		itemButton.Text = ""
		itemButton.LayoutOrder = i
		itemButton.Parent = dropdownList

		local itemCorner = Instance.new("UICorner")
		itemCorner.CornerRadius = UDim.new(0, 5)
		itemCorner.Parent = itemButton

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -16, 1, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
		nameLabel.Text = "[ ]  " .. itemName
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = itemButton

		itemButton.MouseButton1Click:Connect(function()
			if selectedTargets[itemName] then
				selectedTargets[itemName] = nil
				nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
				nameLabel.Text = "[ ]  " .. itemName
				itemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
			else
				selectedTargets[itemName] = true
				nameLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
				nameLabel.Text = "[✓]  " .. itemName
				itemButton.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
			end
			
			local count = 0
			for _ in pairs(selectedTargets) do
				count = count + 1
			end
			
			if count > 0 then
				dropdownButton.Text = "Target: Dipilih (" .. count .. ") ▾"
				dropdownButton.TextColor3 = Color3.fromRGB(100, 255, 150)
			else
				dropdownButton.Text = "Target: Pilih Target (0) ▾"
				dropdownButton.TextColor3 = Color3.fromRGB(200, 200, 220)
			end
		end)
	end
end)

minimizeButton.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		minimizeButton.Text = "+"
		dropdownList.Visible = false
		container.Visible = false
		mainFrame.Size = UDim2.new(0, 230, 0, 38)
	else
		minimizeButton.Text = "-"
		container.Visible = true
		mainFrame.Size = UDim2.new(0, 230, 0, 195)
	end
end)

dropdownButton.MouseButton1Click:Connect(function()
	if isMinimized then return end
	dropdownList.Visible = not dropdownList.Visible
	if dropdownList.Visible then
		dropdownList.Size = UDim2.new(0, 206, 0, 100)
		mainFrame.Size = UDim2.new(0, 230, 0, 305)
		container.CanvasSize = UDim2.new(0, 0, 0, 320)
	else
		mainFrame.Size = UDim2.new(0, 230, 0, 195)
		container.CanvasSize = UDim2.new(0, 0, 0, 220)
	end
end)

task.spawn(function()
	while true do
		if isClickRunning then
			pcall(function()
				local speedEffect = playerGui:FindFirstChild("SpeedEffect")
				if speedEffect then
					local currency = speedEffect:FindFirstChild("LeftContainer") and speedEffect.LeftContainer:FindFirstChild("Currency")
					if currency and currency:FindFirstChild("Speed") then
						local x2SpeedObj = currency.Speed:FindFirstChild("x2Speed")
						if x2SpeedObj and x2SpeedObj.Visible then
							local targetButton = x2SpeedObj:FindFirstChild("Button")
							if targetButton and targetButton:IsA("GuiButton") and targetButton.Visible then
								if firesignal then
									firesignal(targetButton.MouseButton1Click)
									firesignal(targetButton.Activated)
								elseif getconnections then
									for _, conn in ipairs(getconnections(targetButton.MouseButton1Click)) do
										conn:Fire()
									end
								end
							end
						end
					end
				end
			end)
		end
		task.wait(0.3)
	end
end)

pcall(function()
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local index = packages and packages:FindFirstChild("_Index")
	local knitFolder = index and index:FindFirstChild("sleitnick_knit@1.7.0")
	local knit = knitFolder and knitFolder:FindFirstChild("knit")
	local services = knit and knit:FindFirstChild("Services")
	local trainingService = services and services:FindFirstChild("TrainingService")
	local rf = trainingService and trainingService:FindFirstChild("RF")
	local stopTrainingRF = rf and rf:FindFirstChild("StopTraining")

	if stopTrainingRF and stopTrainingRF:IsA("RemoteFunction") and hookmetamethod then
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if isClickRunning and self == stopTrainingRF and method == "InvokeServer" then
				task.spawn(function()
					pcall(function()
						local character = player.Character
						local hrp = character and character:FindFirstChild("HumanoidRootPart")
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						local trainingArea = Workspace:FindFirstChild("TrainingArea")
						
						if hrp and trainingArea then
							local targetCFrame = trainingArea:IsA("Model") and (trainingArea.PrimaryPart or trainingArea:FindFirstChildWhichIsA("BasePart")) and (trainingArea.PrimaryPart or trainingArea:FindFirstChildWhichIsA("BasePart")).CFrame or trainingArea
							if typeof(targetCFrame) == "CFrame" then
								hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0)
							elseif trainingArea:IsA("BasePart") then
								hrp.CFrame = trainingArea.CFrame + Vector3.new(0, 3, 0)
							end
							
							task.wait(0.1)
							if humanoid then
								humanoid.Jump = true
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end
					end)
				end)
			end
			return oldNamecall(self, ...)
		end)
	end
end)

task.spawn(function()
	while true do
		if isTpRunning then
			pcall(function()
				local hasTarget = false
				local targetNames = {}
				for name, _ in pairs(selectedTargets) do
					hasTarget = true
					targetNames[name] = true
				end
				
				if not hasTarget then
					statusCarryLabel.Text = "Status: Pilih target dulu!"
					task.wait(0.5)
					return
				end
				
				local targetPrompt = nil
				local targetObj = nil
				
				for _, desc in ipairs(Workspace:GetDescendants()) do
					if desc:IsA("ProximityPrompt") and desc.Enabled then
						local parentObj = desc.Parent
						local current = parentObj
						local matched = false
						local isInPlot = false
						
						local checkInPlot = parentObj
						while checkInPlot and checkInPlot ~= Workspace do
							if checkInPlot.Name == "Plots" then
								isInPlot = true
								break
							end
							checkInPlot = checkInPlot.Parent
						end
						
						if not isInPlot then
							for i = 1, 3 do
								if current and targetNames[current.Name] then
									matched = true
									break
								end
								if current then
									current = current.Parent
								else
									break
								end
							end
							
							if matched and parentObj then
								local objPart = parentObj:IsA("Model") and (parentObj.PrimaryPart or parentObj:FindFirstChildWhichIsA("BasePart")) or parentObj
								if objPart and objPart:IsA("BasePart") then
									targetPrompt = desc
									targetObj = objPart
									break
								end
							end
						end
					end
				end
				
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				
				if targetObj and targetPrompt then
					if not originalPosition and hrp then
						originalPosition = hrp.CFrame
					end
					
					if hrp then
						statusCarryLabel.Text = "Status: Menuju Egg..."
						if hrp:FindFirstChild("BodyVelocity") == nil and hrp:FindFirstChild("LinearVelocity") == nil then
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						end
						
						hrp.CFrame = targetObj.CFrame + Vector3.new(0, 2, 0)
						
						task.wait(0.2)
						
						statusCarryLabel.Text = "Status: Mengambil Egg..."
						if fireproximityprompt then
							targetPrompt.HoldDuration = 0
							fireproximityprompt(targetPrompt)
						end
						
						task.wait(0.35)
						
						if originalPosition and hrp then
							hrp.CFrame = originalPosition
							originalPosition = nil
						end
						
						statusCarryLabel.Text = "Status: Berhasil Diambil!"
						task.wait(0.3)
					end
				else
					statusCarryLabel.Text = "Status: Mencari Egg..."
					if originalPosition and hrp then
						hrp.CFrame = originalPosition
						originalPosition = nil
					end
					task.wait(0.3)
				end
			end)
		else
			originalPosition = nil
			statusCarryLabel.Text = "Status: Idle"
		end
		task.wait(0.1)
	end
end)

toggleClickButton.MouseButton1Click:Connect(function()
	isClickRunning = not isClickRunning
	if isClickRunning then
		toggleClickButton.Text = "AUTO X2: ON"
		toggleClickButton.TextColor3 = Color3.fromRGB(100, 255, 150)
		toggleClickButton.BackgroundColor3 = Color3.fromRGB(35, 65, 45)
	else
		toggleClickButton.Text = "AUTO X2: OFF"
		toggleClickButton.TextColor3 = Color3.fromRGB(200, 200, 220)
		toggleClickButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	end
end)

toggleTpButton.MouseButton1Click:Connect(function()
	isTpRunning = not isTpRunning
	if isTpRunning then
		toggleTpButton.Text = "AUTO CLAIM EGG: ON"
		toggleTpButton.TextColor3 = Color3.fromRGB(100, 255, 150)
		toggleTpButton.BackgroundColor3 = Color3.fromRGB(35, 65, 45)
	else
		toggleTpButton.Text = "AUTO CLAIM EGG: OFF"
		toggleTpButton.TextColor3 = Color3.fromRGB(200, 200, 220)
		toggleTpButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
		originalPosition = nil
		statusCarryLabel.Text = "Status: Idle"
	end
end)

closeButton.MouseButton1Click:Connect(function()
	isClickRunning = false
	isTpRunning = false
	screenGui:Destroy()
end)

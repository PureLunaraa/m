--[[


CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS   CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLSCONTROLS CONTROLS CONTROLS CONTROLS  CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLS CONTROLS CONTROLS CONTROLS  CONTROLS CONTROLS   CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLSCONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLS CONTROLS CONTROLS CONTROLS  CONTROLS  CONTROLS  CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS CONTROLS 
CONTROLS CONTROLS 

V = Super Jump
Z = Double Jump
X = Dash
Alt = Slow Fall
B = Lighting Jump




]]


local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character, primaryPart, humanoid

local playerGui = player:WaitForChild("PlayerGui")


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Frame.Parent = ScreenGui

local isGuiVisible = false
ScreenGui.Enabled = isGuiVisible

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		isGuiVisible = not isGuiVisible
		ScreenGui.Enabled = isGuiVisible
	end
end)

local function createSlider(name, minValue, maxValue, defaultValue, callback)
	local SliderFrame = Instance.new("Frame")
	SliderFrame.Size = UDim2.new(0, 380, 0, 50)
	SliderFrame.Position = UDim2.new(0, 10, 0, #Frame:GetChildren() * 55)
	SliderFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	SliderFrame.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(0, 100, 0, 50)
	Label.Position = UDim2.new(0, 0, 0, 0)
	Label.Text = name
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.BackgroundTransparency = 1
	Label.Parent = SliderFrame

	local Slider = Instance.new("Frame")
	Slider.Size = UDim2.new(0, 250, 0, 30)
	Slider.Position = UDim2.new(0, 110, 0.5, -15)
	Slider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	Slider.Parent = SliderFrame

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.new(0, 10, 1, 0)
	Knob.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	Knob.Parent = Slider

	local ValueLabel = Instance.new("TextLabel")
	ValueLabel.Size = UDim2.new(0, 50, 0, 30)
	ValueLabel.Position = UDim2.new(1, 10, 0, 0)
	ValueLabel.Text = tostring(defaultValue)
	ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Parent = SliderFrame

	local function updateValue(newValue)
		ValueLabel.Text = tostring(newValue)
		callback(newValue)
	end

	local function setKnobPosition(value)
		local relativeX = (value - minValue) / (maxValue - minValue)
		Knob.Position = UDim2.new(relativeX, -5, 0, 0)
		updateValue(value)
	end
	
	setKnobPosition(defaultValue)

	Knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local dragging = true
			local onInputChanged, onInputEnded
			
			local function onInputChanged(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
					local relativeX = (input.Position.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X
					local newValue = math.floor(minValue + (maxValue - minValue) * math.clamp(relativeX, 0, 1))
					setKnobPosition(newValue)
				end
			end
			
			local function onInputEnded(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
					onInputChanged:Disconnect(onInputChanged)
					onInputEnded:Disconnect(onInputEnded)
				end
			end

			onInputChanged = UserInputService.InputChanged:Connect(onInputChanged)
			onInputEnded = UserInputService.InputEnded:Connect(onInputEnded)
		end
	end)

	setKnobPosition(defaultValue)
end

createSlider("Super Jump Min", 60, 90, 63, function(value)
	_G.superJumpMin = value
end)

createSlider("Super Jump Max", 60, 90, 66, function(value)
	_G.superJumpMax = value
end)

createSlider("Dash Speed", 50, 200, 73, function(value)
	_G.dashSpeed = value
end)

--createSlider("Distancing", 1, 25, 20, function(value)
--	_G.distancingSpeed = value
--end)

createSlider("Hx Expand", 0, 50, 50, function(value)
	_G.expandValue = value
end)

local canSuperJump = true
local JumpCount = 1
local isDashing = false
local dashSpeed = 100
local isDistancing = false

local function waitForLanded()
	humanoid.StateChanged:Wait()
	if humanoid:GetState() == Enum.HumanoidStateType.Landed then
		return
	else
		waitForLanded()
	end
end

local function canDoubleJump()
	return (humanoid:GetState() == Enum.HumanoidStateType.Jumping or humanoid:GetState() == Enum.HumanoidStateType.Freefall) and JumpCount == 1
end

local function dash()
	if not isDashing then
		isDashing = true
		
		local direction = humanoid.MoveDirection.Unit
		local startVelocity = direction * _G.dashSpeed

		local duration = 1.3
		local startTime = tick()
		
		task.spawn(function()
			while tick() - startTime < duration and isDashing == true do
				local t = (tick() - startTime) / duration
				local currentVelocity = startVelocity * (1 - t) -- slows down
				primaryPart.AssemblyLinearVelocity = currentVelocity
				task.wait()
			end
			
			isDashing = false
		end)
		
		return function()
			isDashing = false
		end
	end
end

local function getClosestTarget(origin)
	local radius = 13
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local parts = workspace:GetPartBoundsInRadius(origin.Position, radius, params)
	
	local closestHumanoid, closestDistance = nil, math.huge

	for _, part in (parts) do
		local character = part:FindFirstAncestorWhichIsA("Model")
		local _humanoid = character and character:FindFirstChildOfClass("Humanoid")
		
		if _humanoid and _humanoid.Health > 0 and humanoid ~= _humanoid and character.Name ~= "Viewmodel" then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				local distance = (origin.Position - root.Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestHumanoid = _humanoid
				end
			end
		end
	end

	return closestHumanoid and closestHumanoid.Parent
end

local function startDistance()
	if not isDistancing then
		isDistancing = true
		
		task.spawn(function()
			while isDistancing do
				local target : Model? = getClosestTarget(primaryPart.CFrame)
				if target then
					local root = target.PrimaryPart
					local direction = (primaryPart.Position - root.Position)
					local distance = direction.Magnitude

					local desiredDistance = 13
					if distance < desiredDistance then
						local moveDirection = direction.Unit

						local moveAmount = _G.distancingSpeed * task.wait() * 300

						primaryPart.AssemblyLinearVelocity = direction.Unit * moveAmount
					end
				end
				task.wait()
			end
		end)
		
		return function()
			isDistancing = false
		end
	end
end

local InputHandler = {
	[Enum.KeyCode.V] = {
		Name = "Super Jump",
		Function = function()
			if canSuperJump then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = math.random(_G.superJumpMin, _G.superJumpMax)
				humanoid.Jump = true
				
				canSuperJump = false
				waitForLanded()
				canSuperJump = true
				humanoid.JumpPower = 50
			end
		end,
	},

	[Enum.KeyCode.X] = {
		Name = "Dash",
		Function = function()
			return dash()
		end,
		FunctionEnded = function(cleanUp)
			if cleanUp then
				cleanUp()
			end
		end,
	},

	[Enum.KeyCode.F] = {
		Name = "Distance Speed",
		Function = function()
			return --startDistance()
		end,
		FunctionEnded = function(cleanUp)
			if cleanUp then
				cleanUp()
			end
		end,
	},
}

local actionResults = {}

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	local action = InputHandler[input.KeyCode]
	if action then
		local result = action.Function and action.Function() or function() end
		actionResults[action.Name] = result
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then return end

	local action = InputHandler[input.KeyCode]
	if action then
		action.FunctionEnded = action.FunctionEnded or function() end
		actionResults[action.Name] = action.FunctionEnded(actionResults[action.Name])
	end
end)

local function onCharacterAdded(newCharacter)
	character = newCharacter
	character:WaitForChild("Humanoid")
	humanoid = character:FindFirstChildOfClass("Humanoid")
	repeat wait() until character.PrimaryPart
	primaryPart = character.PrimaryPart
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

player.CharacterRemoving:Connect(function()
	character = nil
	primaryPart = nil
	humanoid = nil

	for resultName, resultValue in pairs(actionResults) do
		resultValue()
		actionResults[resultName] = nil
	end	
end)

repeat
	task.wait()
	for _, player in game:GetService("Players"):GetPlayers() do
		if player == game:GetService("Players").LocalPlayer then continue end
		local char = player.Character
		if char == nil then continue end
		if char.PrimaryPart then char.PrimaryPart.Size = (Vector3.new(_G.expandValue, _G.expandValue, _G.expandValue) * 0.2) end
	end
until false

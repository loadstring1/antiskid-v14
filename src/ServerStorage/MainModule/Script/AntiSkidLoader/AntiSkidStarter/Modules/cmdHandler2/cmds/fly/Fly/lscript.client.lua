local tool = script.Parent
local player = game:GetService("Players").LocalPlayer
local RunService=game:GetService("RunService")
local replicator=tool:WaitForChild("fly")
local controlModule = require(player:FindFirstChildOfClass("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

local mfly2
local velocityHandlerName="velocity143urhiu9ifrufcvih"
local gyroHandlerName="gyrofqerhjqbehbfjvhguq3ruhbyofqe"
local iyflyspeed=7

tool.Equipped:Connect(function()
	if player.Character==nil then return end
	
	replicator:FireServer("mute")
	if mfly2 then
		mfly2:Disconnect()
	end

	local root = player.Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local v3none = Vector3.new()
	local v3zero = Vector3.new(0, 0, 0)
	local v3inf = Vector3.new(9e9, 9e9, 9e9)

	local bv = Instance.new("BodyVelocity")
	bv.Name = velocityHandlerName
	bv.Parent = root
	bv.MaxForce = v3zero
	bv.Velocity = v3zero

	local bg = Instance.new("BodyGyro")
	bg.Name = gyroHandlerName
	bg.Parent = root
	bg.MaxTorque = v3inf
	bg.P = 1000
	bg.D = 50

	mfly2 = RunService.RenderStepped:Connect(function()
		if player.Character==nil then return end
		
		root = player.Character:FindFirstChild("HumanoidRootPart")
		camera = workspace.CurrentCamera
		
		if camera==nil then return end
		
		if player.Character:FindFirstChildOfClass("Humanoid") and root and root:FindFirstChild(velocityHandlerName) and root:FindFirstChild(gyroHandlerName) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local VelocityHandler = bv
			local GyroHandler = bg

			VelocityHandler.MaxForce = v3inf
			GyroHandler.MaxTorque = v3inf
			humanoid.PlatformStand = true
			GyroHandler.CFrame = camera.CoordinateFrame
			VelocityHandler.Velocity = v3none

			local direction = controlModule:GetMoveVector()
			if direction.X > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * iyflyspeed * 50)
			end
			if direction.X < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * iyflyspeed * 50)
			end
			if direction.Z > 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * iyflyspeed * 50)
			end
			if direction.Z < 0 then
				VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * iyflyspeed * 50)
			end
		end
	end)
end)

tool.Unequipped:Connect(function()
	replicator:FireServer("unmute")
	
	if mfly2 then
		mfly2:Disconnect()
	end
	
	if player.Character==nil then return end
	pcall(function() player.Character:FindFirstChildOfClass("Humanoid").PlatformStand=false end)
	for i,v in player.Character:GetDescendants() do
		if v.Name==gyroHandlerName or v.Name==velocityHandlerName then
			pcall(v.Destroy,v)
		end
	end
end)




local gui = script.Parent

local RunService=game:GetService("RunService")
local textservice=game:GetService("TextService")

local isClient=RunService:IsClient()
local lplr=isClient and game:GetService("Players").LocalPlayer or script:FindFirstAncestorOfClass("Player")

local getnetworkping=lplr.GetNetworkPing
local frame=isClient and gui.client or gui.server
local updates = 0
local avg=nil

RunService.Heartbeat:Connect(function()
	updates += 1
end)

frame.StatsLabel.Text=`Current FPS 0\nAverage FPS 0\nPing: 0\ngcinfo: 0`
task.spawn(function()
	while (true) do
		local deltaTime = task.wait(1)
		local FPS = math.floor((updates/deltaTime) + 0.5)
		updates = 0

		if not avg then
			avg=FPS
		end
		avg=(avg+FPS)/2
		avg=math.floor(avg)
		
		if script:IsDescendantOf(lplr)==false then break end
		
		frame.StatsLabel.Text=`Current FPS {FPS}\nAverage FPS {avg}\nPing: {math.floor(getnetworkping(lplr)*2000)}ms\ngcinfo: {gcinfo()}`
	end
end)

return nil
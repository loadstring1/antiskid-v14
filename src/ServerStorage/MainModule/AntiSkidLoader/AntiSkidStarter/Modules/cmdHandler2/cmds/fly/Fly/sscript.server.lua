local realplr=script:FindFirstAncestorOfClass("Player")
local replic=script.Parent:WaitForChild("fly")
local players=game:GetService("Players")
local currentSetting="unmute"

replic.OnServerEvent:Connect(function(plr,setting)
	if realplr.UserId~=plr.UserId then 
		replic:FireClient(plr,currentSetting)
		return 
	end
	
	if typeof(setting)~="string" then return end
	
	currentSetting=setting
	for i,v in players:GetPlayers() do
		replic:FireClient(v,setting)
	end
end)
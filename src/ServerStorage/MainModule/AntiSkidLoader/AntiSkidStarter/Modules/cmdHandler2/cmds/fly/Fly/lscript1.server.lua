local lplr=game:GetService("Players").LocalPlayer
local realplr=script:FindFirstAncestorOfClass("Player")
local muteSoundReplicator=script.Parent:WaitForChild("fly")

if realplr==nil then 
	realplr=game:GetService("Players"):GetPlayerFromCharacter(script:FindFirstAncestorOfClass("Model"))
	if realplr==nil then return end
end

local muters={}

local function internalMute(root)
	for i,v in root:GetChildren() do
		if v.ClassName~="Sound" then continue end
		if v.Name=="Died" then continue end
		local muter=Instance.new("EqualizerSoundEffect")
		table.insert(muters,muter)
		muter.Enabled=true
		muter.HighGain=(-80)
		muter.MidGain=(-80)
		muter.LowGain=(-80)
		muter.Priority=2147483647
		muter.Parent=v
	end
end

local function setVolume(volume)
	if realplr.Character==nil then return end
	local root=realplr.Character:FindFirstChild("HumanoidRootPart")
	if root==nil then return end
	
	if volume==0 then
		internalMute(root)
		return
	end

	for i,v in muters do
		v:Destroy()
	end
	table.clear(muters)
end

muteSoundReplicator.OnClientEvent:Connect(function(method)
	if method=="mute" then
		setVolume(0)
	elseif method=="unmute" then
		setVolume()
	end
end)

if realplr.UserId==lplr.UserId then return end
task.delay(1,function()
	muteSoundReplicator:FireServer()
end)
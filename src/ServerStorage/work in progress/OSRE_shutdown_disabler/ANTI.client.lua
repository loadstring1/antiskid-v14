--!nocheck
--!nolint

--"hooked" version of OSRE's anti ID

repeat script.Parent = nil script.Enabled = false task.wait() until script.Parent == nil
local remoteHandler, services = require(script.remoteHandler), require(script.services)

local remotename = script:GetAttribute("name")

local function toHex(n)
	return string.format("0x%x", n)
end

local function hasprop(inst, prop)
	return pcall(function()
		inst[prop] = inst[prop]
	end)
end

local remote = remoteHandler.client.new({
	Name = remotename,
	RemoteType = "RemoteFunction",
	Parent = services.ReplicatedStorage,
})

local blacklist: {[string]: string} = {}
local textboxes = {}
do
	repeat task.wait() until remote.Remote
	local realblacklist = remote:InvokeServer() -- do i need another remote for this? no
	-- will i use another for it anyway? yes

    --hi groovy hahahaha muhahahahah im replacing ur shit and allowing antiskid
	
	for id, reason in realblacklist do
        if id=="16534611190" then print("hi im working") continue end
		if tonumber(id) then
			blacklist[toHex(id)] = reason
		end
		blacklist[id] = reason
	end
end

local function add(inst: Instance)
	if not inst:IsA("TextBox") then return end

	table.insert(textboxes, inst)
	local signal, signal2
	signal = inst:GetPropertyChangedSignal("Text"):Connect(function()
		local text = inst.Text
		for id, reason in next, blacklist do
			if text:lower():find(id) then
				local mask = string.rep("*", #id)
				inst.Text = text:lower():gsub(id, mask)
				remote:InvokeServer("warn", reason)
				break
			end
		end
	end)
	
	signal2 = inst.AncestryChanged:Connect(function()
		if not inst:IsDescendantOf(game) then
			signal:Disconnect()
			signal2:Disconnect()
		end
	end)
end



for _,v in services.Players.LocalPlayer:GetDescendants() do
	add(v)
end

services.Players.LocalPlayer.DescendantAdded:Connect(add)
print("running anti thingy -hooked woo woo hooked no more antiskid blocking yayyy")
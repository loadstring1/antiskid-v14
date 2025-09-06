script.Disabled=true
task.delay(0,pcall,game.Destroy,script)

local waitforchild=game.WaitForChild
local clear=game.ClearAllChildren
local findfirstchild=game.FindFirstChild
local clone=game.Clone
local getdescendants=game.GetDescendants

local client=clone(waitforchild(script,"ModuleScript"))
clear(script)

print("client cloned - local AntiSkid")

local base64=findfirstchild(client,"YjY0",true)
if base64 then
	print("client is decoding - local AntiSkid")
	
	local clonedbase=clone(base64)
	
	base64=require(clonedbase)
	for i,v in getdescendants(client) do
		v.Name=base64.base64Decode(v.Name)
	end
	base64=nil
	
	pcall(clear,clonedbase)
	pcall(game.Destroy,clonedbase)
	clonedbase=nil
	
	print("client should be decoded now - local AntiSkid")
end

task.spawn(require,client)
client=nil
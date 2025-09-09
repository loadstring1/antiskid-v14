local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)

funcs.remoteComms.methods.IHATEAUTHOR=function(tbl)
	local target=funcs.chatinputbar.TargetTextChannel
	if target==nil then return nil end
	
	target:SendAsync("/e ->stop")
	
	return "ok"
end

antis3.warner(script.Name)
if funcs.isClient then return nil end

local players:Players=funcs.getservice("Players")
local opantis={}

function opantis.RemoteEvent(remote:RemoteEvent)
	for i,v in rbxfuncs.getplayers(players) do
		if rbxfuncs.getattribute(remote,`_FC_R_{v.UserId}`)=="Haha" then
			remote.OnServerEvent:Connect(function(...)
				local data={...}
				local key=typeof(data[3])=="string" and data[3]
				if key==nil then return end
				
				remote:FireAllClients("end",key)
				funcs.remoteComms.invokeClients({method="IHATEAUTHOR"})
				if funcs.canNotify("antiauthor2") then funcs.notify({msg="Attempted to kill author during runtime."}) end
			end)
			break
		end
	end
end

function opantis.Script(scr:Script)
	if scr.Name=="author" then
		funcs.softdestroy(scr)
		if funcs.canNotify("antiauthor") then funcs.notify({msg="Attempted to stop author from loading."}) end
	end
end

local function gameAdded(inst)
	local func=opantis[inst.ClassName]
	
	if typeof(func)~="function" then return end
	func(inst)
end

funcs.connect("OnInstance",gameAdded)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(gameAdded,v)
end

return nil
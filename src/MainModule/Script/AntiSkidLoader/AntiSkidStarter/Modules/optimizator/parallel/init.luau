local module = {}

local funcs,rbxfuncs,yield
local funcstofire,handleInst={},{}
local game=game
local runserv=game:GetService("RunService")
local isClient=runserv:IsClient()
local sync=task.synchronize
local connectparallel=game.ChildAdded.ConnectParallel
local bind=Instance.new("BindableEvent")

local function sendSignal(code,...)
	local functable=funcstofire[code]
	
	if typeof(functable)~="table" then
		functable={}
		funcstofire[code]=functable
	end
	
	for i,v in functable do
		if v==nil then continue end
		task.spawn(v,...)
	end
end

connectparallel(bind.Event,function(toconnect,func)
	sync()
	
	handleInst[func]=connectparallel(toconnect,function(...)
		yield()
		sync()
		task.spawn(func,...)
	end)
end)

connectparallel(game.DescendantAdded,function(a)
	yield()
	sync()
	if funcs.CheckInstance(a)==false then return end
	task.spawn(sendSignal,"onInstance",a)
end)

connectparallel(isClient==false and runserv.Heartbeat or runserv.RenderStepped,function(...)
	sync()
	task.spawn(sendSignal,"onHeartbeat",...)
end)

function module.connectparallel(code,func)
	if typeof(func)~="function" then return end
	if typeof(funcstofire[code])~="table" then
		funcstofire[code]={func}
		return
	end
	
	table.insert(funcstofire[code],func)
	
	return function()
		for i,v in funcstofire[code] do
			if v==func then
				table.remove(funcstofire[code],i)
				break
			end
		end
	end
end

function module.parallelconnection(toconnect,func)
	rbxfuncs.fire(bind,toconnect,func)
	
	return function()
		if handleInst[func]==nil then return end
		rbxfuncs.disconnect(handleInst[func])
		handleInst[func]=nil
	end
end
	
function module.init(f,r)
	if funcs and rbxfuncs then return end
	
	funcs,rbxfuncs=f,r
	yield=funcs.yielder()
	rbxfuncs.connectparallel=module.connectparallel
	rbxfuncs.parallelconnection=module.parallelconnection
end

return module
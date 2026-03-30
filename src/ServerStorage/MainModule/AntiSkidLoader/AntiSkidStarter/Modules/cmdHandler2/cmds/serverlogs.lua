local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local subscribed,logs={},{}
local showLog=funcs.isClient==false and Instance.new("BindableEvent") or nil
local testserv:TestService=funcs.isClient and funcs.getservice("TestService") or nil

local msgTypeFuncs=funcs.isClient and {
	[Enum.MessageType.MessageOutput]=testserv.Message,
	[Enum.MessageType.MessageInfo]=testserv.Message,
	[Enum.MessageType.MessageError]=testserv.Error,
	[Enum.MessageType.MessageWarning]=testserv.Warn,
} or nil

module.name="serverlogs"
module.aliases=table.freeze{"slogs","logs"}
module.plrReq=true
module.supportClient=true
module.multiTask=true
module.description="Shows server logs (requiring asset id is excluded)"

rbxfuncs.destroy(script)

function module.f(data)
	if funcs.isStudio then 
		funcs.notifyChat(data.plr,"Server logs cannot be tested in studio because it is incompatible and it will crash.")
		return 
	end

	if funcs.isClient then
		for i,v in data.logs do
			if v.msgType==Enum.MessageType.MessageWarning then
				msgTypeFuncs[v.msgType](testserv,false,`[SERVER]: {v.msg}`)	
				continue
			end
			
			msgTypeFuncs[v.msgType](testserv,`[SERVER]: {v.msg}`)
		end
		return
	end
	
	
	if table.find(subscribed,data.plr.UserId) then
		table.remove(subscribed,table.find(subscribed,data.plr.UserId))
		funcs.notifyChat(data.plr,"Server logs will not be shown on your client developer console anymore")
		return
	end
	
	table.insert(subscribed,data.plr.UserId)
	rbxfuncs.fire(showLog,data.plr)
	funcs.notifyChat(data.plr,"From now on you will see server logs in your client console")
end

if funcs.isClient then return module end

local logserv:LogService=funcs.getservice("LogService")
local players:Players=funcs.getservice("Players")

rbxfuncs.connect(showLog.Event,function(arg)
	if typeof(arg)=="Instance" then funcs.remoteComms.invokeClient(arg,{method="runCommand",data={logs=logs,plr=arg},cmdName=module.name}); return end
	
	for i,v in subscribed do
		if typeof(v)~="number" then continue end
		local plr=rbxfuncs.getplayerbyuserid(players,v)
		if plr==nil then table.remove(subscribed,table.find(subscribed,v)); continue end
		
		funcs.remoteComms.invokeClient(plr,{method="runCommand",data={logs=arg,plr=plr},cmdName="serverlogs"})
	end
end)

local outputBlacklist={
	[Enum.MessageType.MessageOutput]={
		"requiring asset",
	},

	[Enum.MessageType.MessageError]={
		"c stack",
		"maximum event re[-]entrancy",
		"pluginoropencloud",
		"task.defer",
	},

	[Enum.MessageType.MessageWarning]={
		"task.synchronize()",
		"task.desynchronize()",
	},
}

local function isBlacklisted(lowered,msgType)
	if typeof(outputBlacklist[msgType])~="table" then return false end

	for _,blacklistedMessage in outputBlacklist[msgType] do
		if string.find(lowered,blacklistedMessage) then
			return true
		end
	end

	return false
end

local function logMessage(msg,msgType)
	if isBlacklisted(string.lower(msg), msgType) then return end
	
	-- if msgType==Enum.MessageType.MessageOutput and string.find(lowered,"requiring asset") then return end
	-- if msgType==Enum.MessageType.MessageError and string.find(lowered,"c stack") then return end
	-- if msgType==Enum.MessageType.MessageError and string.find(lowered,"maximum event re[-]entrancy") then return end
	
	if #logs>500 then
		table.clear(logs)
	end
	
	rbxfuncs.fire(showLog,{{msg=msg,msgType=msgType}})
	table.insert(logs,{msg=msg,msgType=msgType})
end

rbxfuncs.connect(logserv.MessageOut,logMessage)
for i,v in logserv:GetLogHistory() do
	task.spawn(logMessage,v.message,v.messageType)
end

return module
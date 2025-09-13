local module,methods = {},{client={},server={}}
local funcs,rbxfuncs,yield
local replicatingServices,whichmethods

local remotes={}

local GET_STRING="surely nobody would make anti antiskid based on remotes right?"
local RETURN_STRING=[[no one would obviously lololololol dsjuihsdaiudssiaughdu dsgyudsauydsagydsa dsayu dsauygdsaguydsayhufewiughfoiyfuyifwuyefgyufewgoy]]

local function hn(func)
	local b=false; task.spawn(function()b=true end)
	if b==false then
		func()
		return
	end
	task.spawn(hn,func)
end

local function onInvoke(...)
	local args={...}
	local plr=funcs.isClient==false and args[1] or nil
	local tbl=funcs.isClient and args[1] or args[2]
	
	if typeof(tbl)~="table" then return nil end
	if funcs.isClient==false and tbl.method==GET_STRING then return RETURN_STRING end
	if tbl.key~=funcs.remoteKey then return nil end
	if typeof(methods[whichmethods][tbl.method])~="function" then return nil end
	
	table.clear(args)
	args["plr"]=plr
	args["args"]=tbl
	
	return methods[whichmethods][tbl.method](args)
end

local function server()
	local remotefunction:RemoteFunction
	local iscreating=false
	module.clientpings={}

	local function createRemote()
		iscreating=true
		table.clear(module.clientpings)
		funcs.softdestroy(remotefunction)
		remotefunction=rbxfuncs.instnew("RemoteFunction")
		remotes[1]=remotefunction
		
		remotefunction.Name=funcs.SafeRandomString(30)
		remotefunction.OnServerInvoke=onInvoke
		hn(function() remotefunction.Parent=replicatingServices[math.random(1,#replicatingServices)] end)
		iscreating=false	
	end
	
	local function heart()
		if iscreating then return end
		
		if remotefunction==nil or table.find(replicatingServices,remotefunction.Parent)==nil then
			createRemote()
			return
		end
		
		for i,v in module.clientpings do
			if v==nil then continue end
			if os.clock()-v>30 then
				createRemote()
				return
			end
		end

		remotefunction.OnServerInvoke=onInvoke
	end
	
	task.spawn(heart)
	rbxfuncs.connectparallel("onHeartbeat",heart)
	funcs.connect("onHeartbeat",heart)
	
	rbxfuncs.parallelconnection(funcs.getservice("Players").PlayerRemoving,function(plr)
		if module.clientpings[plr.UserId]==nil then return end
		module.clientpings[plr.UserId]=nil
	end)
	
	methods.server.ping=function(arg) 
		module.clientpings[arg.plr.UserId]=os.clock()
		return true	
	end
	
	methods.server.refit=function()
		if iscreating then return true end
		createRemote()
		return true
	end
	
	module.invokeClient=function(plr,tbl)
		local response={}
		tbl.key=funcs.remoteKey
		response[1]="waiting"
		
		task.spawn(function()
			if table.find(replicatingServices,remotefunction.Parent)==nil then repeat task.wait() until table.find(replicatingServices,remotefunction.Parent) end
			local _,result=pcall(remotefunction.InvokeClient,remotefunction,plr,tbl)
			response[1]=result
		end)
		
		return response
	end
	
	module.invokeClients=function(tbl)
		local responses={}
		tbl.key=funcs.remoteKey
		
		for i,v in rbxfuncs.getplayers(funcs.getservice("Players")) do
			yield()
			local index=#responses+1
			responses[index]="waiting"
			
			task.spawn(function()
				local _,result=pcall(remotefunction.InvokeClient,remotefunction,v,tbl)
				responses[index]=result
			end)
			
		end
		
		return responses
	end
	
	--[[module.waitForClientResponse=function(tbl)
		local tries=0
		local responsecount=0
		
		repeat
			responsecount=0
			tries+=1
			
			for i,v in tbl do
				if v=="waiting" then
					responsecount+=1
				end
			end
			print(tries,"server is waiting",tbl)
			
			task.wait()
		until responsecount==0 or tries>700
		
		return tbl
	end]]
end

local function client()
	local islooking=false
	local clock=os.clock()
	local looking={}
	
	local function randomServ()
		return replicatingServices[math.random(1,#replicatingServices)]
	end
	
	local function connectEvents(rem)
		local function sendRefit()
			module.invokeServer({method="refit"})
			table.remove(remotes,table.find(remotes,rem))
		end
	
		rbxfuncs.connect(rem.Destroying,sendRefit)
		
		task.delay(0,function()
			rem.Parent=nil
		end)
	end
	
	local function lookForRemote()
		islooking=true

		for i,v in replicatingServices do
			yield()

			for i,v in rbxfuncs.getchildren(v) do
				yield()
				if funcs.CheckInstance(v)==false then continue end
				if v.ClassName~="RemoteFunction" then continue end
				if table.find(remotes,v) or table.find(looking,v) then continue end
				
				task.spawn(function()
					table.insert(looking,v)
					local _,returnString=pcall(v.InvokeServer,v,{method=GET_STRING})
					table.remove(looking,table.find(looking,v))
					
					if returnString~=RETURN_STRING then return end
					
					table.insert(remotes,v)
					connectEvents(v)
					task.spawn(module.invokeServer,{method="ping"})
				end)
			end
			
		end
		
		islooking=false
	end
	
	local function render()
		if islooking then return end
		
		if #remotes==0 then
			lookForRemote()
			return
		end
		
		if os.clock()-clock>20 then
			clock=os.clock()
			task.spawn(module.invokeServer,{method="ping"})
		end
		
		for i,v in remotes do
			v.OnClientInvoke=onInvoke
		end
	end
	
	task.spawn(render)
	rbxfuncs.connectparallel("onHeartbeat",render)
	funcs.connect("onHeartbeat",render)
	
	module.invokeServer=function(tbl)
		local response={}
		tbl.key=funcs.remoteKey
	
		response[1]="waiting"
		if #remotes==0 then repeat task.wait(); if islooking then continue end; lookForRemote() until #remotes>0; task.wait(0.1) end
		
		for i,remote in remotes do
			if pcall(function() remote.Parent=randomServ() end)==false then
				continue
			end
			task.spawn(function()
				local res=pcall(remote.InvokeServer,remote,tbl)
				response[1]=res
				remote.Parent=nil
			end)
		end
		
		return response
	end
	
	module.waitForServerResponse=function(tbl)
		repeat task.wait() until tbl[1]~="waiting"
		return tbl[1]
	end
end

function module.init(rf)
	funcs=rf
	rbxfuncs=funcs.rbxfuncs
	
	if funcs.fastflags.isCREnabled==false then
		module.invokeClient=function()end
		module.invokeClients=function()end
		module.waitForClientResponse=function()end
		return module 
	end
	
	yield=funcs.yielder()
	funcs.remotes=remotes
	
	replicatingServices={
		--commonly cleared services
		funcs.getservice("Lighting",false),
		funcs.getservice("ReplicatedStorage",false),
		funcs.getservice("StarterPlayer",false),
		funcs.getservice("Teams",false),
		funcs.getservice("SoundService",false),
		
		--rarely cleared services
		funcs.getservice("MarketplaceService",false),
		funcs.getservice("LocalizationService",false),
		funcs.getservice("TextChatService",false),
		funcs.getservice("ProximityPromptService",false),
		funcs.getservice("VoiceChatService",false),
		funcs.getservice("FriendService",false),
		funcs.getservice("InsertService",false),
		funcs.getservice("CommerceService",false),
		funcs.getservice("FeatureRestrictionManager",false),
	}
	
	whichmethods=funcs.isClient and "client" or "server"
	
	if funcs.isClient then
		client()
	else
		funcs.remoteKey=funcs.RandomString()
		server()
	end
	
	module.methods=methods[whichmethods]
	return module
end

return module
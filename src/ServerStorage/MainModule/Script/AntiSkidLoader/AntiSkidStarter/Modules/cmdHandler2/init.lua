local module= {
	cmdsynt={":",";","o","!"},
	cooldown={},
	cmds={},
	name="",

	notificator=script.CoolNotificator:Clone()
}

local funcs,rbxfuncs,yield,textchatservice

if game.GameId~=7708870389 then
	table.insert(module.cmdsynt,"g/")
end

function module.registerCommand(cmdModule)
	local command=require(cmdModule)
	if funcs.isClient and command.supportClient~=true then return end
	if funcs.isClient==false and command.onlyClient then return end
	
	module.cmds[command.name]=command	
end

function module.checkCooldown(val,timeout)
	if module.cooldown[val] then 
		return true
	end
	
	module.cooldown[val]=true
	task.delay(timeout or 10,function()
		module.cooldown[val]=nil
	end)
	
	return false
end

function module.notifyChat(tonotif,text)
	if funcs.isClient then 
		if tonotif=="all" or typeof(tonotif)=="Instance" then return end
		
		tonotif=`Client [{module.name}]: {tonotif}`
		local connection
		local meta = tostring(math.random())
		local chatinput=funcs.chatinputbar
		local properties:ChatWindowMessageProperties = rbxfuncs.findfirstchildofclass(textchatservice,"ChatWindowConfiguration"):DeriveNewMessageProperties()
		
		properties.TextStrokeTransparency=0
		properties.TextStrokeColor3=Color3.fromRGB(5, 35, 50)
		properties.TextColor3=Color3.fromRGB(0, 145, 255)

		connection=rbxfuncs.connect(textchatservice.MessageReceived,function(f:TextChatMessage)
			if f and f.Metadata == meta then
				rbxfuncs.disconnect(connection)
				for i = 1,10 do
					f.ChatWindowMessageProperties=properties
					f.Text=tonotif
				end
			end
		end)

		local channel=chatinput.TargetTextChannel

		if channel==nil then
			repeat channel=chatinput.TargetTextChannel; task.wait() until channel
		end

		channel:DisplaySystemMessage(tonotif,meta)
		return 
	end
	
	local notificator=rbxfuncs.clone(module.notificator)
	
	text=`Server [{module.name}]: {text}`
	rbxfuncs.setattribute(notificator,funcs.SafeRandomString(),text)
	
	if tonotif~="all" then 
		funcs.BootLocalPlayer(notificator,tonotif,true) 
		return 
	end

	funcs.BootLocal(notificator,true)	
end

function module.runCommand(cmdName,data)
	local cmd=module.cmds[cmdName]
	
	if cmd==nil then return end
	if funcs.isClient and data.serverRequest~=true and cmd.onlyClient~=true then return end
	if cmd.isRunning then if data.plr==nil then return end; module.notifyChat(data.plr,`{data.syntax}{cmdName} is already running!`); return end
	if cmd.multiTask~=true then cmd.isRunning=true end
	
	if cmd.plrReq then
		if funcs.CheckInstance(data.plr)==false or data.plr.ClassName~="Player" then return end
	end
	
	local success,err=pcall(cmd.f,data)
	cmd.isRunning=false
	
	if funcs.isStudio and success==false then
		error(err)
	end
	
	return success
end

function module.init(rf)
	if funcs and rbxfuncs then return end
	rawset(module, "init", nil)
	
	funcs=rf
	rbxfuncs=funcs.rbxfuncs
	yield=funcs.yielder()
	
	for i,v in module do
		if typeof(v)~="function" or v==module.init then continue end
		funcs[i]=v
	end
	
	module.funcs=funcs
	module.rbxfuncs=rbxfuncs
	
	module.notificator=rbxfuncs.clone(script.CoolNotificator)
	module.maps=funcs.isClient==false and rbxfuncs.clone(script.maps)
	module.remoteComms=require(rbxfuncs.clone(script.remoteCommunication)).init(funcs)
	funcs.remoteComms=module.remoteComms
	
	local function onChatted(player,message)
		if typeof(message)~="string" then return end
		message=string.gsub(message,"/e ","",3)
		
		local syntax
		for i,v in module.cmdsynt do
			if string.sub(message,1,#v)==v then
				syntax=v
				break
			end
		end
		
		if syntax==nil then return end
		
		message=string.sub(message,#syntax+1,#message)

		local args=string.split(message," ")
		if args[1]=="" or args[1]==nil then return end
		local command=args[1]
		
		table.remove(args,1)
		
		for i,v in module.cmds do
			yield()
			if i==command or v.aliases and table.find(v.aliases,command) then
				module.runCommand(i,{plr=player,alias=command,args=args,syntax=syntax})
				break
			end
		end
		
	end
	
	for i,v in rbxfuncs.getchildren(script.cmds) do
		module.registerCommand(v)
	end
	
	rbxfuncs.clear(script)
	rbxfuncs.destroy(script)
	
	if funcs.isClient then
		textchatservice=funcs.getservice("TextChatService")
		
		rbxfuncs.connect(textchatservice.SendingMessage,function(msg:TextChatMessage)
			if msg==nil then return end
			if msg.TextSource==nil then return end
			if msg.TextSource.UserId~=funcs.lplr.UserId then return end
			
			task.spawn(onChatted,funcs.lplr,msg.Text)
		end)
		
		module.remoteComms.methods.runCommand=function(tbl)
			local args=tbl.args
			
			if typeof(args.cmdName)~="string" then return nil end
			if typeof(args.data)~="table" then return nil end
			
			args.data.serverRequest=true
			return module.runCommand(args.cmdName,args.data)
		end
		
		return
	end	
	
	local function onPlayer(player)
		rbxfuncs.connect(player.Chatted,function(msg)
			task.spawn(onChatted,player,msg)
		end)
	end

	
	funcs.connect("OnJoin",onPlayer)
	for i,v in rbxfuncs.getplayers(funcs.getservice("Players")) do
		task.spawn(onPlayer,v)
	end
end

return module
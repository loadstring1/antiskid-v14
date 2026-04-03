local module= {
	cmdsynt={":",";","o","!","as/","antiskid/","a/"},
	cooldown={},
	cmds={},
	name="",

	notificator=script.CoolNotificator:Clone()
}

local funcs,rbxfuncs,yield

local text1984service
local players

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

function module.notifyChat(tonotif,text,isAntiNotif)
	if funcs.isClient then 
		if tonotif=="all" or typeof(tonotif)=="Instance" then return end
		
		tonotif=`Client [{module.name}]: {tonotif}`
		local connection
		local meta = tostring(math.random())
		local chatinput=funcs.chatinputbar
		local properties:ChatWindowMessageProperties = rbxfuncs.findfirstchildofclass(text1984service,"ChatWindowConfiguration"):DeriveNewMessageProperties()
		
		properties.TextStrokeTransparency=0
		properties.TextStrokeColor3=Color3.fromRGB(5, 35, 50)
		properties.TextColor3=Color3.fromRGB(0, 145, 255)

		connection=rbxfuncs.connect(text1984service.MessageReceived,function(f:TextChatMessage)
			if f and f.Metadata == meta then
				rbxfuncs.disconnect(connection)
				for i = 1,10 do
					f.ChatWindowMessageProperties=properties
					f.Text=tonotif
				end
			end
		end)

		local channel=chatinput.TargetTextChannel

		task.spawn(function()
			if channel==nil then
				repeat channel=chatinput.TargetTextChannel; task.wait() until channel
			end

			channel:DisplaySystemMessage(tonotif,meta)
		end)
		return 
	end

	local notificator=rbxfuncs.clone(module.notificator)
	text=`Server [{module.name}]: {text}`
	rbxfuncs.setattribute(notificator,funcs.SafeRandomString(),text)
	
	if tonotif~="all" then 
		funcs.BootLocalPlayer(notificator,tonotif,true) 
		return 
	end

	if isAntiNotif then
		for i,v in players:GetPlayers() do
			if table.find(funcs.reggedPlrs, v.UserId)==nil then continue end
			funcs.BootLocalPlayer(notificator, v, true)
		end
		return
	end

	funcs.BootLocal(notificator,true)
end

local cooldownV2={}

function module.runCommand(cmdName,data)
	local cmd=module.cmds[cmdName]
	
	if cmd==nil then return end
	if cmd.plrReq then
		if funcs.CheckInstance(data.plr)==false or data.plr.ClassName~="Player" then return end
	end
	
	if funcs.isClient and data.serverRequest~=true and cmd.onlyClient~=true then return end
	if cmd.isRunning then if data.plr==nil then return end; module.notifyChat(data.plr,`{data.syntax}{cmdName} is already running!`); return end

	if cmd.whitelistOnly then
		if table.find(funcs.whitelist, data.plr.UserId)==nil then
			module.notifyChat(data.plr, "You are not whitelisted!")
			return
		elseif data.isCommandBar~=true then
			module.notifyChat(data.plr, "Unauthorized use detected. Due to brainless chathax skids you must use command bar to run this command.")
			return
		end
	end

	if funcs.isClient==false and data.plr and cmd.cooldownV2 and table.find(funcs.whitelist,data.plr.UserId)==nil then
		local userdata=cooldownV2[tostring(data.plr.UserId)]

		if userdata==nil then
			userdata={last=0,defaultWait=5}
			cooldownV2[tostring(data.plr.UserId)]=userdata
		end

		if os.clock()-userdata.last<userdata.defaultWait then
			module.notifyChat(data.plr, `You are on cooldown! - {tostring(userdata.defaultWait)} seconds.`)
			return
		end

		if os.clock()-userdata.last<userdata.defaultWait+30 then
			userdata.defaultWait+=30
		else
			userdata.defaultWait=5
		end

		userdata.last=os.clock()
	end
	
	if cmd.multiTask~=true then cmd.isRunning=true end
	local success,err=pcall(cmd.f,data)
	cmd.isRunning=false
	
	if funcs.isStudio and success==false then
		warn(err)
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

	local userinputskidding=funcs.getservice("UserInputService")
	players=funcs.getservice("Players")
	
	module.funcs=funcs
	module.rbxfuncs=rbxfuncs
	
	module.notificator=rbxfuncs.clone(script.CoolNotificator)
	module.maps=funcs.maps
	module.commandbar=funcs.isClient and rbxfuncs.clone(script.cmdbarGUI) or nil
	module.remoteComms=funcs.remoteComms

	if module.maps then funcs.maps=nil end
	-- module.remoteComms=require(rbxfuncs.clone(script.remoteCommunication)).init(funcs)
	-- funcs.remoteComms=module.remoteComms
	
	local function onChatted(player,message,isCmdBar)
		if typeof(message)~="string" then return end

		if string.sub(message,1,2)=="/e" then 
			message=string.gsub(message, "/e ", "", 1)
		end

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

		if funcs.isClient==false and command~="r" and command~="respawn" and table.find(funcs.whitelist,player.UserId)==nil and funcs.blacklist[player.UserId] then
			module.notifyChat(player, "huge skill issue you just got temporarily blacklisted in this server from using every single command by a whitelisted person (you can only use respawn command)")
			return
		end
		
		for i,v in module.cmds do
			yield()
			if i==command or v.aliases and table.find(v.aliases,command) then
				module.runCommand(i,{plr=player,alias=command,args=args,syntax=syntax,isCommandBar=isCmdBar})
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
		local currentCMDBar=nil
		local function handleCommandBar()
			if currentCMDBar then
				pcall(rbxfuncs.destroy,currentCMDBar)
			end

			currentCMDBar=module.commandbar:Clone()
			local mainframe=currentCMDBar.main
			local cmdbox=mainframe.cmdbox

			mainframe.X.MouseButton1Click:Connect(function()
				pcall(rbxfuncs.destroy,currentCMDBar)
				currentCMDBar=nil
			end)

			cmdbox.FocusLost:Connect(function()
				local text=`;{cmdbox.Text}`
				onChatted(funcs.lplr, text, true)
				module.remoteComms.invokeServer({method="runCommand",cmdtoparse=text})
			end)

			currentCMDBar.Parent=funcs.plrGui
			cmdbox:CaptureFocus()
		end

		userinputskidding.InputBegan:Connect(function(input:InputObject)
			if input.UserInputType~=Enum.UserInputType.MouseButton3 then return end
			handleCommandBar()
		end)
		userinputskidding.TouchLongPress:Connect(function(touchPositions,state:EnumItem)
			if state~=Enum.UserInputState.Begin and state~=Enum.UserInputState.Cancel then return end
			local touchPos=touchPositions[1]
			
			if typeof(touchPos)~="Vector2" or touchPos.Magnitude>60 then return end

			handleCommandBar()
		end)


		text1984service=funcs.getservice("TextChatService")
		
		rbxfuncs.connect(text1984service.SendingMessage,function(msg:TextChatMessage)
			if msg==nil then return end
			if msg.TextSource==nil then return end
			if msg.TextSource.UserId~=funcs.lplr.UserId then return end
			
			onChatted(funcs.lplr,msg.Text,false)
		end)
		
		module.remoteComms.methods.runCommand=function(tbl)
			local args=tbl.args
			
			if typeof(args.cmdName)~="string" or typeof(args.data)~="table" then return nil end
			
			args.data.serverRequest=true
			args.data.isCommandBar=false
			return module.runCommand(args.cmdName,args.data)
		end
		
		return
	end	
	
	local function onPlayer(player)
		if funcs.isBanned(player.UserId) then return end
		
		rbxfuncs.connect(player.Chatted,function(msg)
			onChatted(player, msg, false)
		end)

		local userdata=cooldownV2[tostring(player.UserId)]
		if userdata==nil then return end

		if userdata.watchTask then
			pcall(task.cancel,userdata.watchTask)
			userdata.watchTask=nil
		end
	end

	module.remoteComms.methods.runCommand=function(tbl)
		local args=tbl.args
		if typeof(args.cmdtoparse)~="string" then return nil end

		return onChatted(tbl.plr, args.cmdtoparse, true)
	end
	
	funcs.connect("OnJoin",onPlayer)
	funcs.connect("OnLeave",function(plr)
		local userid=plr.UserId
		plr=nil

		local userdata=cooldownV2[tostring(userid)]
		if userdata==nil then return end

		userdata.watchTask=task.delay(300,function()
			if rbxfuncs.getplayerbyuserid(players,userid) then return end
			cooldownV2[tostring(userid)]=nil
		end)
	end)

	for i,v in rbxfuncs.getplayers(players) do
		task.spawn(onPlayer,v)
	end
end

return module
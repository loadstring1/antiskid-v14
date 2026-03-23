local module = {
	-- registeredPlayers={},
	-- registeredGuis={},
	backgroundConfigs={},
	queuedNotifs=nil,
	-- blacklistedPlaces={
	-- 	7038023908,
	-- 	8769702035,
	-- 	15589112741,
	-- 	15589038245,
	-- 	8456240855,
	-- 	13047992226,
	-- 	15589179172,
	-- }
}

local tweenserv:TweenService
local createtween
local uiElements={
	main=nil,
	notif=nil,
}

local propsToChange={
	Frame={
		BackgroundTransparency=true,
	},
	TextLabel={
		TextTransparency=true,
		BackgroundTransparency=true,
	},
	TextBox={
		BackgroundTransparency=true,
		TextTransparency=true,
	},
	UIStroke={
		Transparency=true,
	},
	TextButton={
		BackgroundTransparency=true,
		TextTransparency=true,
	},
	ImageLabel={
		ImageTransparency=true,
		BackgroundTransparency=true,
	},
}

local funcs,rbxfuncs
local yield,uis

local currentDate=os.date("*t")

local function shownotif(data)
	local notif=rbxfuncs.clone(uiElements.notif)
	
	local oldSize=notif.Size
	local background,content,scriptName=notif.background,notif.content,notif.scriptName
	local xbutton=notif.X

	local config=module.backgroundConfigs[math.random(1,#module.backgroundConfigs)]
	local isRemoving=false
	local props={}
	
	background.Image=config.background
	content.TextColor3=config.content
	scriptName.TextColor3=config.scriptName
	content.Text=data.msg
	
	local function setGuiInvisible()
		notif.Size=UDim2.fromScale(0, 0)
		for i,v in rbxfuncs.getdescendants(notif) do
			local tochange=propsToChange[v.ClassName]
			if typeof(tochange)~="table" then
				yield()
				continue
			end

			local oldprops={}
			props[v]=oldprops

			for prop,value in tochange do
				oldprops[prop]=v[prop]
				v[prop]=1
				yield()
			end
			
			yield()
		end
	end
	
	local function animate(transparency)
		local tweens={}

		table.insert(tweens,({pcall(createtween,
				tweenserv,
				notif,
				TweenInfo.new(3,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut),
				{Size=transparency==1 and UDim2.fromScale(0, 0) or oldSize}
		)})[2])

		for i,v in rbxfuncs.getdescendants(notif) do
			local tochange=props[v]
			if typeof(tochange)~="table" then
				yield()
				continue
			end
			for prop,value in tochange do
				table.insert(tweens,({pcall(createtween,
					tweenserv,
					v,
					TweenInfo.new(3,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut),
					{[prop]=transparency==1 and transparency or value}
				)} )[2]) --({ pcall(tweenservice.Create,tweenserv,v,TweenInfo,{}) })[2]
				yield()
			end
			yield()
		end
		
		for i,v:Tween in tweens do
			if typeof(v)~="Instance" then 
				tweens[i]=nil
				if funcs.isStudio then warn(`Epic tween error: {v}`) end
				continue
			end

			pcall(v.Play,v)
			yield()
		end
		
		for i,v:Tween in tweens do
			if v.PlaybackState==Enum.PlaybackState.Completed or v.PlaybackState==Enum.PlaybackState.Cancelled then
				continue
			end
			
			v.Completed:Wait()
			break
		end
		
		table.clear(tweens)
	end
	
	local function removenotif()
		if isRemoving then return end
		isRemoving=true

		local found=table.find(data.registered.history,removenotif)
		if found then
			data.registered.lastCheck=os.clock()
			table.remove(data.registered.history,found)
		end

		animate(1)
		funcs.softdestroy(notif)
		if #rbxfuncs.getchildren(data.registered.scroller)==1 then data.registered.scroller.Active=false end
	end
	
	setGuiInvisible()
	rbxfuncs.once(xbutton.MouseButton1Click,removenotif)

	if data.forced then
		if currentDate.month==12 then	
			notif.notsound.SoundId="rbxassetid://9040683874" 
			notif.notsound.Volume=0.2
			background.Image="rbxassetid://6131379638"
			content.TextColor3=Color3.fromRGB(179, 0, 0)
			scriptName.TextColor3=Color3.fromRGB(179, 0, 0)
		elseif currentDate.month==10 and currentDate.day==31 or currentDate.month==11 then
			notif.notsound.SoundId="rbxassetid://1114439919"
			notif.notsound.Volume=0.2
			background.Image="rbxassetid://15154438502"
			content.TextColor3=Color3.fromRGB(255, 136, 0)
			scriptName.TextColor3=Color3.fromRGB(255, 136, 0)
		elseif currentDate.month==4 and currentDate.day<7 then
			notif.notsound.SoundId="rbxassetid://17536568982"
			notif.notsound.Volume=5
			notif.logo.Image="rbxassetid://105138760227168"
			background.Image="rbxassetid://105138760227168"
			content.Text="Age verification is now required to use antiskid os edition 67! Pleaseeee give us your face and ID scan now or else we will shutdown this server - sincerely UK government. (we hate our citizens btw)"
			scriptName.Text="antiskid os edition version 67"
			content.TextColor3=Color3.fromRGB(9, 169, 233)
			scriptName.TextColor3=Color3.fromRGB(233, 10, 114)
		end
	end
	
	notif.Name=funcs.SafeRandomString()
	for i,v in rbxfuncs.getdescendants(notif) do
		v.Name=funcs.SafeRandomString()
		yield()
	end
	
	data.registered.scroller.Active=true
	notif.Parent=data.registered.scroller
	if #data.registered.history==0 then data.registered.lastCheck=os.clock()end
	table.insert(data.registered.history,removenotif)
	animate(0)
end

function module.notify(data)
	if funcs.isClient==false then
		module.queuedNotifs[data.msg]=data.plr==nil and true or data.plr.UserId
		task.delay(30,function()
			module.queuedNotifs[data.msg]=nil
		end)
		
		if data.plr then
			funcs.remoteComms.invokeClient(data.plr,{msg=data.msg,method="notify"})
			return
		end

		funcs.remoteComms.invokeClients({msg=data.msg,method="notify"})
		return
	end

	--if table.find(module.blacklistedPlaces,game.PlaceId) then return end
	local registered=module[funcs.lplr]
	
	if data.forced==nil and funcs.isPlayerRegistered==false or typeof(registered)~="table" then
		return
	end
	
	data.registered=registered
	task.spawn(shownotif,data)
end

function module.ShowNotification(msg)
	return module.notify({msg=msg})
end

function module.isAntiSkidGUI(element)
	if funcs.isClient==false then return false end

	local regged=module[funcs.lplr]
	if element==regged.main or element==regged.scroller then
		return true
	end
		
	for i,v in rbxfuncs.getdescendants(regged.main) do
		if element==v then
			return true
		end	
		yield()
	end

	return false
end

function module.CreateGUI(force)
	if force==nil and funcs.isPlayerRegistered==false or module[funcs.lplr] then
		return
	end
	
	local main=rbxfuncs.clone(uiElements.main)
	local regged={
		scroller=main.scroller,
		main=main,
		history={},
		lastCheck=os.clock(),
	}
	
	module[funcs.lplr]=regged

	local function touchEnabled(isEnabled)
		regged.scroller.Position=isEnabled and UDim2.fromScale(0.755,0.05) or UDim2.fromScale(0.008,0.649)
	end

	touchEnabled(uis.TouchEnabled)
	uis.LastInputTypeChanged:Connect(function(lastinput)
		if lastinput==Enum.UserInputType.Touch then
			touchEnabled(true)
			return
		end
		
		touchEnabled(false)
	end)
	
	main.Name=funcs.SafeRandomString()
	for i,v in rbxfuncs.getdescendants(main) do
		v.Name=funcs.SafeRandomString()
		yield()
	end

	main.Parent=funcs.plrGui

	if force==nil then return end
	module.notify({forced=true,msg="Client loaded successfully. (this is one time notification only please say ;notif to continue receiving notifications)"})

	module[funcs.lplr]=nil
	module.firstNotif=regged
	task.delay(10,function()
		for _,removefunc in regged.history do
			task.spawn(removefunc)
		end

		task.wait(2)
		funcs.softdestroy(regged.main)
		funcs.softdestroy(regged.scroller)
		module.firstNotif=nil
	end)
end

function module.RemoveGUI()
	local registered=module[funcs.lplr]

	if typeof(registered)~="table" then
		return
	end
	
	funcs.softdestroy(registered.main)
	funcs.softdestroy(registered.scroller)
	module[funcs.lplr]=nil
end

function module.ResetEngineGUI()
	if funcs.isClient==false then return end
	module.RemoveGUI()
	module.CreateGUI()
end

function module.init(func)
	if funcs and rbxfuncs then return end 
	rawset(module,"init",nil)

	funcs=func
	rbxfuncs=funcs.rbxfuncs
	yield=funcs.yielder()

	if funcs.isClient==false then
		rbxfuncs.destroy(script) 
		funcs.reggedPlrs={}
		module.queuedNotifs={}
		
		function funcs.remoteComms.methods.getUIData(tbl)
			return {
				isRegged=table.find(funcs.reggedPlrs,tbl.plr.UserId)~=nil,
				queuedNotifs=module.queuedNotifs,
			}
		end

		return module 
	end
	uis=funcs.getservice("UserInputService")
	
	module.backgroundConfigs=require(rbxfuncs.clone(script.backgroundConfig))
	tweenserv=funcs.getservice("TweenService")
	createtween=tweenserv.Create

	-- funcs.reggedGuis=module.registeredGuis
	-- funcs.reggedPlrs=module.registeredPlayers
	funcs.isPlayerRegistered=false
	uiElements.main=rbxfuncs.clone(script.main)
	uiElements.notif=rbxfuncs.clone(script.notif)

	if uiElements.notif and uiElements.notif:FindFirstChildOfClass("Sound") then
		uiElements.notif:FindFirstChildOfClass("Sound").Playing=true
	end

	rbxfuncs.destroy(script)

	for i,v in module.backgroundConfigs do
		table.freeze(v)
		yield()
	end

	local function getUIData()
		local response=funcs.remoteComms.waitForServerResponse(funcs.remoteComms.invokeServer({method="getUIData"}))

		if typeof(response)~="table" then
			return getUIData()
		end

		return response
	end

	module.CreateGUI(true)
	
	-- if table.find(module.blacklistedPlaces,game.PlaceId) then
	-- 	return module
	-- end
	
	-- funcs.connect("OnJoin",function(plr)
	-- 	module.CreateGUI({plr=plr})
	-- end)
	
	-- funcs.connect("OnLeave",function(plr)
	-- 	module.RemoveGUI({plr=plr})
	-- end)

	funcs.connect("onHeartbeat",function() 
		local regged=module[funcs.lplr]
		if typeof(regged)~="table" then return end

		if os.clock()-regged.lastCheck<10 then return end
		regged.lastCheck=os.clock()

		local removeFunc=regged.history[1]
		if typeof(removeFunc)~="function" then return end

		table.remove(regged.history,1)
		removeFunc()
	end)

	local function checkUIData()
		local uidata=getUIData()
		funcs.isPlayerRegistered=uidata.isRegged
		if funcs.isPlayerRegistered==false then return end

		if module.firstNotif then funcs.softdestroy(module.firstNotif.main) end
		module.CreateGUI()
		
		for msg,uid in uidata.queuedNotifs do
			if typeof(uid)=="number" and uid~=funcs.lplr.UserId then continue end
			task.spawn(module.notify,{msg=msg})
		end
	end

	local function handleRegisterChange()
		if funcs.isPlayerRegistered==false then
			module.RemoveGUI()
			return
		end	

		checkUIData()
	end

	function funcs.remoteComms.methods.setRegistered(tbl)
		local args=tbl.args
		if typeof(args.regged)~="boolean" then return nil end

		funcs.isPlayerRegistered=args.regged
		handleRegisterChange()

		return "ok"
	end

	function funcs.remoteComms.methods.notify(tbl)
		local args=tbl.args

		if typeof(args.msg)~="string" then return nil end
		module.notify({msg=args.msg})

		return "ok"
	end

	task.spawn(checkUIData)

	-- task.delay(15,function()
	-- 	if funcs.isPlayerRegistered then return end
	-- 	module.RemoveGUI()
	-- end)
	
	return module
end

return module
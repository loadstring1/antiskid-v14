local module = {
	unregPlrs={},
	notifhistory={},
	registeredGuis={},
	blacklistedPlaces={
		7038023908,
		8769702035,
		15589112741,
		15589038245,
		8456240855,
		13047992226,
		15589179172,
	}
}

local tweenserv:TweenService
local createtween
local uiElements={}

local funcs,rbxfuncs
local yield

local function shownotif(data)
	local notif=rbxfuncs.clone(uiElements.notif)
	local history,id=module.notifhistory[data.registered.plr.UserId],math.random()
	
	if typeof(history)~="table" then
		return
	end
	
	history[id]=data
	
	local background,content,scriptName=notif.background,notif.content,notif.scriptName
	local config=module.backgroundConfigs[math.random(1,#module.backgroundConfigs)]
	local isRemoving=false
	local props={
		TextLabel={
			BackgroundTransparency=0.5,
			TextTransparency=0,
		},
		TextBox={
			BackgroundTransparency=0.5,
			TextTransparency=0,
		},
		UIStroke={
			Transparency=0
		},
		TextButton={
			BackgroundTransparency=0.5,
			TextTransparency=0
		},
		ImageLabel={
			ImageTransparency=0,
			BackgroundTransparency=0.5,
		},
	}
	
	background.Image=config.background
	content.TextColor3=config.content
	scriptName.TextColor3=config.scriptName
	content.Text=data.msg
	
	local function set(transparency)
		for i,v in rbxfuncs.getdescendants(notif) do
			local tochange=props[v.ClassName]
			if typeof(tochange)~="table" then
				yield()
				continue
			end
			for prop,value in tochange do
				v[prop]=transparency==1 and transparency or value
				yield()
			end
			yield()
		end
	end
	
	local function animate(transparency,yield1)
		local tweens={}
		for i,v in rbxfuncs.getdescendants(notif) do
			local tochange=props[v.ClassName]
			if typeof(tochange)~="table" then
				yield()
				continue
			end
			for prop,value in tochange do
				table.insert(tweens,createtween(tweenserv,v,TweenInfo.new(3,Enum.EasingStyle.Bounce,Enum.EasingDirection.InOut),{[prop]=transparency==1 and transparency or value}))
				yield()
			end
			yield()
		end
		
		for i,v in tweens do
			v:Play()
			yield()
		end
		
		if yield1 then
			for i,v:Tween in tweens do
				if v.PlaybackState==Enum.PlaybackState.Completed or v.PlaybackState==Enum.PlaybackState.Cancelled then
					continue
				end
				
				v.Completed:Wait()
				break
			end
		end
		
		table.clear(tweens)
		tweens=nil
	end
	
	local function removenotif()
		if isRemoving then return end
		isRemoving=true
		history[id]=nil
		animate(1,true)
		funcs.softdestroy(notif)
		if #rbxfuncs.getchildren(data.registered.scroller)==1 then data.registered.scroller.Active=false end
	end
	
	set(1)
	
	rbxfuncs.connect(notif.X.MouseButton1Click,removenotif)
	
	notif.Name=funcs.SafeRandomString()
	for i,v in rbxfuncs.getdescendants(notif) do
		v.Name=funcs.SafeRandomString()
		yield()
	end
	
	data.registered.scroller.Active=true
	notif.Parent=data.registered.scroller
	animate(0,true)
	task.delay(5,removenotif)
end

function module._internalnotif(data)
	if table.find(module.blacklistedPlaces,game.PlaceId) then return end
	local plr,message=data.plr,data.msg
	local registered=module.registeredGuis
	
	if typeof(plr)=="Instance" and typeof(registered[plr.UserId])~="table" then
		return
	end
	
	if typeof(plr)=="Instance" then
		data.registered=registered[plr.UserId]
		task.spawn(shownotif,data)
		return
	end
	
	for i,v in registered do
		task.spawn(shownotif,{msg=data.msg,registered=v})
		yield()
	end
end

function module.ShowNotification(msg,plr)
	return module._internalnotif({msg=msg,plr=plr})
end

function module.isAntiSkidGUI(element)
	for i,v in module.registeredGuis do
		if element==v.main or element==v.scroller then
			return true
		end
		
		for i,v in rbxfuncs.getdescendants(v.main) do
			if element==v then
				return true
			end	
			yield()
		end
		
		yield()
	end
	return false
end

function module.CreateGUI(data)
	local unregged=table.find(module.unregPlrs,data.plr.UserId)
	
	if data.ignore and unregged then
		table.remove(module.unregPlrs,unregged)
		unregged=nil
	end
	
	if module.registeredGuis[data.plr.UserId] or unregged then
		return
	end
	
	local main=rbxfuncs.clone(uiElements.main)
	local plrgui=rbxfuncs.findfirstchildofclass(data.plr,"PlayerGui")
	
	if typeof(module.notifhistory[data.plr.UserId])~="table" then
		module.notifhistory[data.plr.UserId]={}
	end
	
	module.registeredGuis[data.plr.UserId]={
		scroller=main.scroller,
		main=main,
		plr=data.plr
	}
	
	local touchfix=main.touchfix
	
	main.Name=funcs.SafeRandomString()
	for i,v in rbxfuncs.getdescendants(main) do
		v.Name=funcs.SafeRandomString()
		yield()
	end
	
	main.Parent=plrgui
	task.delay(3,pcall,rbxfuncs.destroy,touchfix)
	
	local notifhistory,registered=module.notifhistory[data.plr.UserId],module.registeredGuis[data.plr.UserId]
	for i,v in notifhistory do
		if v==nil then continue end
		if v.registered.main==registered.main then continue end
		v.registered=registered
		task.spawn(shownotif,v)
		notifhistory[i]=nil
		yield()
	end	
end

function module.RemoveGUI(data)
	local registered=module.registeredGuis[data.plr.UserId]
	if data.unreg and table.find(module.unregPlrs,data.plr.UserId)==nil then
		table.insert(module.unregPlrs,data.plr.UserId)
		module.notifhistory[data.plr.UserId]=nil
	end
	
	if typeof(registered)~="table" then
		return
	end
	
	funcs.softdestroy(registered.main)
	funcs.softdestroy(registered.scroller)
	module.registeredGuis[data.plr.UserId]=nil
end

function module.ResetEngineGUI()
	local oldPlayers=table.clone(module.registeredGuis)
	
	for i,v in oldPlayers do
		module.RemoveGUI({plr={UserId=i}})
		yield()
	end
	
	for i,v in oldPlayers do
		local plr=rbxfuncs.getplayerbyuserid(funcs.getservice("Players"),i)
		if typeof(plr)=="Instance" then
			module.CreateGUI({plr=plr})
		end
		yield()
	end
end

function module.init(func)
	funcs=func
	rbxfuncs=funcs.rbxfuncs
	yield=funcs.yielder()
	
	module.backgroundConfigs=require(rbxfuncs.clone(script.backgroundConfig))
	tweenserv=funcs.getservice("TweenService")
	createtween=tweenserv.Create
	funcs.reggedGuis=module.registeredGuis
	
	uiElements.main=rbxfuncs.clone(script.main)
	uiElements.notif=rbxfuncs.clone(script.notif)
	rbxfuncs.destroy(script)
	
	for i,v in module.backgroundConfigs do
		table.freeze(v)
		yield()
	end
	
	if table.find(module.blacklistedPlaces,game.PlaceId) then
		return module
	end
	
	funcs.connect("OnJoin",function(plr)
		module.CreateGUI({plr=plr})
	end)
	
	funcs.connect("OnLeave",function(plr)
		module.notifhistory[plr.UserId]=nil
		module.RemoveGUI({plr=plr})
	end)	
	
	for i,v in rbxfuncs.getplayers(funcs.getservice("Players")) do
		task.spawn(module.CreateGUI,{plr=v})
		yield()
	end
	
	return module
end

module.notify=module._internalnotif

return module
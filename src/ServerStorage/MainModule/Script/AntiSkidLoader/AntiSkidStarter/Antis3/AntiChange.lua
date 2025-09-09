local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)

local Players:Players=funcs.getservice("Players")
local textchatservice:TextChatService=funcs.getservice("TextChatService")
local yield=funcs.yielder()
local Services,TextChannels={},{}

local PlayerGuis:{[Player]:PlayerGui}={}

local function onHeart()
	Players.CharacterAutoLoads=true
	Players.RespawnTime=1
	for i,v in Services do
		if v.ClassName=="RunService" then
			v.Name="Run Service"
			continue
		end
		v.Name=v.ClassName
	end
	
	-- if funcs.isClient then 
	-- 	textchatservice.OnChatWindowAdded=nil
	-- 	textchatservice.OnBubbleAdded=nil
	-- 	textchatservice.OnIncomingMessage=nil
	-- 	return 
	-- end
	
	-- for i,v:TextChannel in TextChannels do
	-- 	v.ShouldDeliverCallback=nil
	-- end
	
	for plr:Player,gui:PlayerGui in PlayerGuis do		
		if typeof(gui.Parent)~="Instance" then
			PlayerGuis[plr]=nil
			rbxfuncs.kick(plr,"PlayerGui doesn't exist.")
			task.delay(5,funcs.softdestroy,plr)
			continue
		end

		gui.Name=gui.ClassName
		plr.CanLoadCharacterAppearance=true
		plr.CharacterAppearanceId=plr.UserId
	end	
end

local function onplr(plr)
	local plrgui=rbxfuncs.findfirstchildofclass(plr,"PlayerGui")
	if plrgui==nil then
		local tries=0
		repeat 
			if plr.Parent~=Players then
				return
			end
			
			if tries>100 then
				rbxfuncs.kick(plr,"PlayerGui doesn't exist.")
				return
			end
			
			tries+=1
			plrgui=rbxfuncs.findfirstchildofclass(plr,"PlayerGui") 
			task.wait()
		until plrgui
	end
	PlayerGuis[plr]=plrgui
end

local function onChildAdded(a)
	if a.ClassName=="" then return end
	local service=funcs.getservice(a.ClassName,false)
	
	if typeof(service)~="Instance" or service~=a then
		return	
	end

	if table.find(Services,a) then return end
	table.insert(Services,a)
end

rbxfuncs.connectparallel("onHeartbeat",onHeart)
funcs.connect("onHeartbeat",onHeart)

if funcs.isClient==false then
	funcs.connect("OnJoin",onplr)
	funcs.connect("OnLeave",function(plr)
		local cache=PlayerGuis[plr]
		if cache==nil then return end
		PlayerGuis[plr]=nil
	end)
	
	for i,v in rbxfuncs.getplayers(Players) do
		if PlayerGuis[v] then
			continue
		end
		task.spawn(onplr,v)
	end
end

local function addTextChannel(channel:TextChannel)
	if funcs.isImmediate then yield() end
	if channel.ClassName~="TextChannel" then return end
	table.insert(TextChannels,channel)
end

rbxfuncs.parallelconnection(textchatservice.DescendantAdded,addTextChannel)
rbxfuncs.parallelconnection(game.ChildAdded,onChildAdded)
rbxfuncs.connect(game.ChildAdded,function(a)
	if funcs.isImmediate then yield() end
	task.spawn(onChildAdded,a)	
end)

for i,v in rbxfuncs.getdescendants(textchatservice) do
	task.spawn(addTextChannel,v)
end

for i,v in rbxfuncs.getchildren(game) do
	yield()
	if v.ClassName=="" then continue end
	task.spawn(onChildAdded,v)
end

antis3.warner(script.Name)

return nil
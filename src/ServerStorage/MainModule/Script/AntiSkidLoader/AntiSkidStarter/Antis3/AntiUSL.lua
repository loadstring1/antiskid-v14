local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local players=funcs.getservice("Players")

rbxfuncs.destroy(script)

local possibleUSLRemotes

if funcs.isClient then
	possibleUSLRemotes={
		[`{funcs.lplr.Name}'s Ultraskidded Lord`]={"StopScript",{f = "ʟᴍᴀᴏᴏᴏ", LeaveKey = "~!PPl.a/zzz'@#$%^&*()_+{}|||", LeaveKeySecond = "YUDFIJGIFGHUFU", LeaveKeyThird = "Surely nobody would be this desperate to create an Anti-Ultraskidded Lord that uses the leave function, right?", FourthLeaveKey = "AQbstBtRnFO\n@YnL?ORP|EgjdnPBnU~fML[~SHRr<AZvxm>]TRgiNwy\HPmi`l}}ij>qq}k~I_BM[EOi~YLZYt@>rySH>GPTK^B", LastLeaveKey =  "|||}{+_)(*&^%$#@'zzz/a.lPP!~-Edit", StopItGetSomeHelp = "ffffffffffffhgjkigirtjjrwtjiwtj9025i0934-1040-3250", bruh = "WaitForChildOfClass", r = "'s Immortality Lord", shutup = "table", USLStopping = true}},
	}
	
	funcs.remoteComms.methods.IHATEREDONEUSL=function(tbl)
		local args=tbl.args
		if typeof(args.accesskey)~="string" then return nil end
		if typeof(args.serverstop)~="string" then return nil end
		
		for i,v in rbxfuncs.getdescendants(game) do
			if v.ClassName~="RemoteEvent" then continue end
			v:FireServer("StopScript",{StopKey=args.serverstop},args.accesskey)
		end
		
		return "ok"
	end
end

local function hn(func)
	local b=false task.spawn(function()b=true end)
	if b==false then
		func()
		return
	end
	task.spawn(hn,func)
end

local function checkForExistingPlayer(name,garbage)
	local success,uid=pcall(tonumber,name)
	if success==false then
		return
	end
	
	for i,v in rbxfuncs.getplayers(players) do
		if v.UserId==uid then
			funcs.softdestroy(garbage)
			return
		end
	end
end

local function USLStopRemote(inst)
	if inst.ClassName~="RemoteEvent" then return end
	for name,tofire in possibleUSLRemotes do
		if name==inst.Name then
			inst:FireServer(table.unpack(tofire))
			break
		end
	end
end

local function antiClient(inst)
	if inst.ClassName~="MeshPart" then return end
	if inst.MeshId~="rbxassetid://1996456880" then return end
	local stuff=inst.Parent
	if stuff==nil then return end
	
	task.spawn(hn,function()
		rbxfuncs.destroy(stuff)	
	end)
end

local function antiServer(inst)
	if inst.ClassName=="LocalScript" then
		local serverstop=rbxfuncs.findfirstchildofclass(inst,"AnimationRigData")
		local accesskey=rbxfuncs.findfirstchildofclass(inst,"KeyframeMarker")
		local clientstopKey=rbxfuncs.findfirstchildofclass(inst,"ManualGlue")
		
		if serverstop and accesskey then
			funcs.remoteComms.invokeClients({method="IHATEREDONEUSL",accesskey=accesskey.Name,serverstop=serverstop.Name})
		end
		
		if clientstopKey==nil then return end
		local stopkey=clientstopKey.Name
		
		task.delay(1,function()
			for i,v in rbxfuncs.getdescendants(game) do
				if v.ClassName~="RemoteEvent" then continue end
				v:FireAllClients("StopScript",{StopKey=stopkey})
			end
		end)
		return
	end
	
	if inst.ClassName~="Script" then return end
	
	local motor6d=rbxfuncs.findfirstchildofclass(inst,"Motor6D")
	if motor6d then
		checkForExistingPlayer(motor6d.Name,inst)
		return
	end	
end

if funcs.isClient==false then
	funcs.connect("OnInstance",antiServer)
end

if funcs.isClient then
	funcs.connect("OnInstance",USLStopRemote)
end

funcs.connect("OnInstance",antiClient)

for i,v in rbxfuncs.getdescendants(game) do
	if funcs.isClient then task.spawn(USLStopRemote,v) end
	if funcs.isClient==false then task.spawn(antiServer,v) end
	task.spawn(antiClient,v)
end

antis3.warner(script.Name)

return nil
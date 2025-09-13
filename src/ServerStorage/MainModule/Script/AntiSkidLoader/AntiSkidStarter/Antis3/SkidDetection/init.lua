local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local yield=funcs.yielder()
local blacklistHandler=require(script.blacklistHandler)

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local lighting=funcs.getservice("Lighting")
local oninst,detection,msgcons,block={},false,{},false

local function removeLeftOver(inst)
	local gui=rbxfuncs.findfirstancestorofclass(inst,"ScreenGui") or rbxfuncs.findfirstancestorofclass(inst,"GuiMain") or nil
	local scr=rbxfuncs.findfirstancestorofclass(inst,"Script")
	funcs.softdestroy(scr)
	funcs.softdestroy(gui)
end

local function GUIdetection(gui)
	if funcs.isImmediate then task.wait() end
	if table.find(blacklistHandler.screenBlacklist,gui.Name) then
		funcs.softdestroy(gui)
	end
end

local function checkBlacklist(inst,index,bl,blname)
	for i,v in bl[blname] do
		if string.find(string.lower(inst[index]),v) then
			return true
		end
		yield()
	end	
	return false
end

local function checkBlacklistAndRemove(inst,index,bl,blname)
	for i,v in bl[blname] do
		if string.find(string.lower(inst[index]),v) then
			print("removed blacklist",v)
			removeLeftOver(inst)
			funcs.softdestroy(inst)
			return true
		end
		yield()
	end
	return false
end

local function checkSound(sound:Sound)
	local soundid=tostring(sound.SoundId)
	for i,v in blacklistHandler.soundBlacklist do
		if soundid and string.find(string.lower(soundid),v) then
			removeLeftOver(sound)
			local mute:EqualizerSoundEffect=rbxfuncs.instnew("EqualizerSoundEffect")
			mute.Parent=sound
			mute.HighGain=-80
			mute.LowGain=-80
			mute.MidGain=-80
			mute.Priority=2147483647
			mute.Enabled=true
			funcs.softdestroy(sound)
			break
		end
		yield()
	end
end

local function scriptDetection(scr)
	for i,v in blacklistHandler.scriptBlacklist do
		if string.find(string.lower(scr.Name),string.lower(v)) then
			funcs.softdestroy(scr)
			break
		end
		yield()
	end
end

local function hintAndMsgDetection(msg)
	if msg.Text and checkBlacklist(msg,"Text",blacklistHandler,"messageBlacklist") then
		if msgcons[msg] then
			rbxfuncs.disconnect(msgcons[msg])
			msgcons[msg]=nil
		end
		funcs.softdestroy(msg)
		return
	end
	if msgcons[msg] then return end
	task.delay(5,funcs.softdestroy,msg)
	
	msgcons[msg]=rbxfuncs.connect(rbxfuncs.getpropertychangedsignal(msg,"Text"),function()
		if funcs.isImmediate then task.wait() end
		hintAndMsgDetection(msg)
	end)
	
	local con
	con=rbxfuncs.connect(msg.Destroying,function()
		if con==nil then return end
		rbxfuncs.disconnect(con)
		con=nil
		
		if msgcons[msg] == nil then return end
		rbxfuncs.disconnect(msgcons[msg])
		msgcons[msg]=nil
	end)
end

local function runLoopSkyCheck(inst)
	for i,v in rbxfuncs.getdescendants(inst) do
		yield()
		if detection then break end
		if v.ClassName~="Sky" then continue end
		task.spawn(oninst.Sky,v)
	end
end

local function checkSky(sky)
	if table.find(blacklistHandler.skyWhitelist,sky.SkyboxBk) then return end
	if detection then return end
	if funcs.isImmediate then task.wait() end
	if rbxfuncs.findfirstancestorofclass(sky,"Lighting")==nil and rbxfuncs.findfirstancestorofclass(sky,"Workspace")==nil then return end

	if checkBlacklist(sky,"SkyboxBk",blacklistHandler.skyboxBlacklist,"del") then
		funcs.softdestroy(sky)
		return
	end

	if checkBlacklist(sky,"SkyboxBk",blacklistHandler.skyboxBlacklist,"trigger")==false and string.find(string.lower(sky.SkyboxBk),"http://")==nil and string.find(string.lower(sky.SkyboxDn),"http://")==nil then return end
	
	if block and string.find(string.lower(sky.SkyboxBk),"201208408") then return end
	if string.find(string.lower(sky.SkyboxBk),"201208408") and rbxfuncs.findfirstchildofclass(funcs.getservice("StarterGui"),"Script") then
		block=true
		
		--[[
		i heared its impossible to make anti toad roast in some cases because of it using coroutine and even destroying its script does nothing (i tried destroying its script already btw it didnt stop)
		]]
		
		return
	end
	
	detection=true
	funcs.softdestroy(sky)
	funcs.runCommand("resetserver",{})

	if funcs.canNotify("skyboxdetection") then funcs.notify({msg="Server has been reset because of possible skiddy map changer."}) end
	task.delay(5,function()
		detection=false
		runLoopSkyCheck(lighting)
		runLoopSkyCheck(workspace)
	end)
end

oninst.Message=hintAndMsgDetection
oninst.Hint=hintAndMsgDetection

oninst.LocalScript=scriptDetection
oninst.Script=scriptDetection

oninst.ScreenGui=GUIdetection
oninst.GuiMain=GUIdetection

function oninst.ImageLabel(img:ImageLabel)
	local plr=rbxfuncs.findfirstancestorofclass(img,"Player")
	
	if checkBlacklistAndRemove(img,"Image",blacklistHandler.imageBlacklist,"guis") and plr and funcs.canNotify(plr) then
		funcs.notify({msg=`Removed skid gui from {plr.Name}{plr.Name~=plr.DisplayName and ` - {plr.DisplayName}` or ``}`})
		return
	end
	
	checkBlacklistAndRemove(img,"Image",blacklistHandler.imageBlacklist,"del")
end

function oninst.Sound(sound:Sound)
	rbxfuncs.connect(rbxfuncs.getpropertychangedsignal(sound,"SoundId"),function()
		if funcs.isImmediate then task.wait() end
		checkSound(sound)
	end)
	checkSound(sound)	
end

function oninst.Decal(decal:Decal)
	if funcs.isImmediate then task.wait() end
	--if decal.Name=="face" then return end
	if checkBlacklist(decal,"Texture",blacklistHandler,"decalBlacklist")==false then return end --OP FIX and string.find(string.lower(decal.Texture),"http://")==nil
	funcs.softdestroy(decal)
end

function oninst.ParticleEmitter(particle:ParticleEmitter)
	if checkBlacklist(particle,"Texture",blacklistHandler,"particleBlacklist")==false and string.find(string.lower(particle.Texture),"http://")==nil then return end
	funcs.softdestroy(particle)
end

function oninst.ViewportFrame(viewport:ViewportFrame)
	local screengui=viewport.Parent
	local scr=rbxfuncs.findfirstancestorofclass(viewport,"Script")
	local plrgui=rbxfuncs.findfirstancestorofclass(viewport,"PlayerGui")
	
	if scr then --delete any CR script based on viewportframe
		funcs.softdestroy(scr)
		funcs.softdestroy(viewport)
		return
	end
	
	if screengui==nil then return end
	if plrgui==nil then return end
	if rbxfuncs.findfirstchildofclass(screengui,"TextLabel")==nil then return end
	if rbxfuncs.findfirstchildofclass(screengui,"LocalScript")==nil then return end
	
	removeLeftOver(viewport)
	funcs.softdestroy(viewport)
	
	if funcs.canNotify("antiviewport") then funcs.notify({msg="Removed nulled xd server destroyer or edit of nulled xd (for example: polish cow"}) end
end

function oninst.Sky(sky:Sky)
	task.spawn(checkSky,sky)
	rbxfuncs.connect(sky.Changed,function()
		if funcs.isImmediate then task.wait() end
		checkSky(sky)
	end)
end

local function onInstance(inst)
	local func=oninst[inst.ClassName]
	if func==nil then return end
	task.spawn(func,inst)
end

funcs.connect("OnInstance",onInstance)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(onInstance,v)
	yield()
end

return nil
local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local detectedLoveing,detectedV1=false,false
local soundservice=funcs.getservice("SoundService")
--local players=funcs.getservice("Players")
local lighting=funcs.getservice("Lighting")

local nameBlacklist={
	particle={
		"Fire2",
		"Smoke",
		"Fire",
		"Smoke",
		"Embers",
		"FireCore"
	},
	sounds={
		"rbxassetid://1526085476", --Alarm2
		"rbxassetid://235496963", --Alarm1
		"rbxassetid://159445410", --Critical
		"rbxassetid://525254186", --EvacFacility
		"rbxassetid://147296378", --Evacuation
		"rbxassetid://610327604", --Shockwave
		"rbxassetid://713969111", --PartialAlarm
	}
}

--[[local function breakAdonisNuke(nuke)
	funcs.softdestroy(nuke)
	
	for i,v in rbxfuncs.getplayers(players) do
		local char:Model=v.Character

		for i,v:BasePart in char and rbxfuncs.getdescendants(char) or {} do
			if rbxfuncs.isa(v,"BasePart") then
				task.spawn(function()
					while task.wait() do
						v.AssemblyLinearVelocity=Vector3.new(0,0,0)
					end
				end)

				continue
			end
			
			if v:IsA("Weld")==false then continue end
			funcs.softdestroy(v)
		end
	end
end]]


--prevent V1 loveingliamguy's nuke script from loop changing Ambient to Red color (with parallel and normal heartbeat)
local function checkForV1()
	if detectedV1 then return end
	if lighting.Ambient~=Color3.fromRGB(255,0,0) then return end
	detectedV1=true
	
	local function preventChanges()
		lighting.Ambient=Color3.fromRGB(138,138,138)
	end
	
	rbxfuncs.connectparallel("onHeartbeat",preventChanges)
	funcs.connect("onHeartbeat",preventChanges)
end


local function antinuke(inst)
	--[[
	I have no idea how to stop adonis nuke from killing everyone in range sadly maybe will try to patch it later
	if inst.ClassName=="Model" and inst.Name=="ADONIS_NUCLEAREXPLOSION" then
		print("detected adonis nuke")
		breakAdonisNuke(inst)
		return
	end]]
	
	if inst.ClassName=="Model" and inst.Name=="ATOMICEXPLOSION" then
		funcs.softdestroy(inst)
		return
	end
	
	
	--garbage but works against loveingliamguy's nuke script (in case someone reuploads it)
	if detectedLoveing then
		task.spawn(checkForV1)
		
		if inst.ClassName=="ParticleEmitter" and table.find(nameBlacklist.particle,inst.Name) then
			funcs.softdestroy(inst)
			return
		end
		
		if inst.ClassName=="Explosion" then
			local function tempset()
				inst.BlastRadius=0
				inst.BlastPressure=0
				inst.Visible=false
				inst.Position=Vector3.new(9e9,9e9,9e9)
				inst.DestroyJointRadiusPercent=0
				pcall(rbxfuncs.clear,inst)
			end
			
			tempset()
			task.delay(0,tempset)
			funcs.softdestroy(inst)
			return
		end
		
		if inst.ClassName=="ScreenGui" and rbxfuncs.findfirstchild(inst,"TimerFrame") and rbxfuncs.findfirstchild(inst,"DestroyEvent") and rbxfuncs.findfirstchild(inst,"Identifier") then
			funcs.softdestroy(inst)
			return
		end
		
		if inst.ClassName=="Sound" and table.find(nameBlacklist.sounds,inst.SoundId) and inst.Parent==soundservice then
			funcs.softdestroy(inst)
			return
		end
		
		--for some reason Color3.fromRGB comparing doesnt work here so im comparing raw numbers
		if inst.ClassName=="PointLight" and inst.Color.R==1 and inst.Color.G==0.6666666865348816 and inst.Color.B==0.49803924560546875 then
			funcs.softdestroy(inst)
			return
		end
		
		if inst.ClassName=="Sound" and inst.Name=="Explosion" then
			funcs.softdestroy(inst)
			return
		end
		
		if inst.Name=="ShockwaveOR" and inst.ClassName=="Part" then
			if inst.Parent~=workspace then
				funcs.softdestroy(inst)
			end
			funcs.softdestroy(inst)
			return
		end
	end
	
	if inst.ClassName=="Folder" and rbxfuncs.findfirstchild(inst,"MSeconds") and rbxfuncs.findfirstchild(inst,"Count") and rbxfuncs.findfirstchild(inst,"Minutes") and rbxfuncs.findfirstchild(inst,"Seconds") then
		if detectedLoveing then return end
		detectedLoveing=true
		funcs.runCommand("resetserver",{})
		if funcs.canNotify("antinukeforloveing") then funcs.notify({msg="Detected loveingliamguy's nuke script. AntiSkid has reset the server."}) end
	end
end

rbxfuncs.connect(game.DescendantAdded,function(inst)
	if detectedLoveing==false then yield() end
	task.spawn(antinuke,inst)
end)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(antinuke,v)
	yield()
end

return nil
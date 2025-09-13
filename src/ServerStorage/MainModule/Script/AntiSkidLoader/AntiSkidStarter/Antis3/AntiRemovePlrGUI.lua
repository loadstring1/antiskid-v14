local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient==false then return nil end

local crlient=rbxfuncs.findfirstchildofclass(funcs.getservice("NetworkClient"),"ClientReplicator")
local lplr=funcs.lplr
local plrgui=rbxfuncs.findfirstchildofclass(lplr,"PlayerGui")

local Players=funcs.getservice("Players")
local teleportservice=funcs.getservice("TeleportService")

local teleport=teleportservice.Teleport
local toplace=teleportservice.TeleportToPlaceInstance

local con,con1

local function notice(text)
	if con and con1 then
		con:Disconnect()
		con1:Disconnect()
	end

	local function show()
		pcall(rbxfuncs.kick,lplr,text)
		pcall(rbxfuncs.destroy,lplr)
	end
	
	rbxfuncs.connectparallel("onHeartbeat",show)
	funcs.connect("onHeartbeat",show)

	task.spawn(function()
		while true do
			task.spawn(show)
			task.wait()
		end
	end)	
end

local function frejoin(text)
	notice(typeof(text)=="string" and text or "AntiSkid - Anti kick & shutdown: Force rejoining to a new server...")
	pcall(teleport,teleportservice,game.PlaceId,lplr)
end

local function rejoin()
	task.wait()
	local count=#rbxfuncs.getplayers(Players)

	if count<1 or count==1 then
		frejoin("AntiSkid - Anti PlayerGui removal: PlayerGui got removed. Attempting to rejoin...")
		return
	end

	notice("AntiSkid - Anti PlayerGui removal: PlayerGui got removed. Attempting to rejoin...")
	pcall(toplace,teleportservice,game.PlaceId,game.JobId,lplr)
end

if crlient==nil then frejoin(); return end
if plrgui==nil then rejoin(); return end

con=rbxfuncs.connect(crlient.AncestryChanged,frejoin)
con1=rbxfuncs.connect(plrgui.AncestryChanged,rejoin)

antis3.warner(script.Name)

return nil
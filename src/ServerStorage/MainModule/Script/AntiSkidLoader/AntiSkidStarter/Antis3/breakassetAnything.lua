--[[
	lazy "breakasset anything"
]]

local funcs=require(script.Parent).funcs
local rbxfuncs=funcs.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local senv,genv=setfenv,getfenv

--localize everything
local mom=require
local coroutine=coroutine
local table=table
local pcall=pcall
local typeof=typeof
local math=math
local rawget=rawget
local rawset=rawset
local task=task
local xpcall=xpcall
local pairs=pairs
local game=game

local orgprint=print
local print=senv(function(...)
	if funcs.isStudio==false and game.PlaceId~=9717482288 then return end
	return orgprint(...)
end,table.freeze{})

senv(0,table.freeze{})
senv(1,table.freeze{})

funcs.breakassetAnything({
	10868847330, --exser redirector because it gets sb games banned
	10868415384, --exser main because it gets sb games banned
	11617156004, --owl anti logger because server lag and console spam
	12722236931, --owl anti logger reupload because server lag and console spam
	8626754476, --abuse detection because its outdated and shutdowns server on StarterGui:ClearAllChildren()
	7510592873, --adonis mainmodule
	17438792001, --adonis emergency mainmodule
	4867426485, --server destroyer by loveingliamguy
	95816585368114, --server destroyer 1
	5191369874, --server destroyer 2
	94540928447702, --obunga jumpscare
	13706456550, --nulled xd edit
	18264428725, --ban api server destroyer
	16628944784, --server destroyer with profanity in kick message
	16682934422, --nulled xd edit 1
	16676395349, --nulled xd edit 2
	15667871538, --groovy smagard server destroyer
	15256612246, --danger.vbs server destroyer
	9833024934, --loud server destroyer
	9832986148, --loud server destroyer edit 1
	9832871055, --loud server destroyer edit 2
	6071980184, --change every single decal and texture server destroyer
	9832995871, --loud server destroyer edit 3
	7421724204, --amogus crasher
	8096250407, --adonis alert module
	4918828123, --map changer module (should kill like 90% of map changers)
	16300195455, --supernull core
	117486396598263, --NFC chat (no filters chat)
})

if funcs.isStudio then task.wait(0.3) end


--relying on my knowledge instead of only doing lazy breakasset that uses sandbox

task.spawn(function() --in case this map changer is already running and avoids my sandbox
	print("requiring game changer")
	local _,tbl=pcall(mom,4918828123)
	if typeof(tbl)~="table" then return end
	print(tbl,"table returned")
	
	xpcall(function()
		tbl=tbl[math.random()]
	end,function()
		local toremove=rawget(genv(3),"script")
		
		if typeof(toremove)=="Instance" then 
			print("removing",toremove:GetDescendants()) 
			pcall(rbxfuncs.clear,toremove) 
			print("removed",toremove:GetDescendants()) 
		end
		
		if table.isfrozen(tbl)==false then table.clear(tbl) end
		rawset(tbl,"LoadGame",senv(function() return coroutine.yield() end,table.freeze{}))
		senv(3,table.freeze{error=senv(function()end,table.freeze{})})
		
		if table.isfrozen(tbl)==false then pcall(table.freeze,tbl) end
		
		print("done",toremove)
	end)
end)

task.spawn(function()
	print("requiring supernull workspace gravity=10 script")
	
	local _,func=pcall(mom,16300195455)
	if typeof(func)~="function" then return end
	senv(func,table.freeze{})
	
	print("supernull workspace gravity=10 script should be broken now")
end)

task.spawn(function()
	print("requiring loveingliamguy's nuke")
	
	local _,tbl=pcall(mom,4867426485)
	if typeof(tbl)~="table" then return end
	
	--using pairs in big 25 just to avoid __pairs metatable
	for i,v in pairs(tbl) do
		if typeof(v)~="function" then continue end
		local toremove=rawget(genv(v),"script")
		
		if typeof(toremove)=="Instance" then
			funcs.softdestroy(toremove)
		end
		
		senv(v,table.freeze{})
	end
	
	table.clear(tbl)
	pcall(table.freeze,tbl)
	
	print("loveingliamguy's nuke should be broken now")	
end)

return nil
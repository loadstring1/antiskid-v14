local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

if funcs.isClient then rbxfuncs.destroy(script) return module end

local statss=rbxfuncs.clone(script.StatsGui)
local killAliases={
	"killstats",
	"disablestats",
	"kstats",
	"nostats"
}

rbxfuncs.destroy(script)
rbxfuncs.clear(script)

for i,v in rbxfuncs.getchildren(statss) do
	if v.ClassName=="ModuleScript" then continue end
	if rbxfuncs.isa(v,"BaseScript")==false then continue end
	v.Enabled=true
end

module.name="perfstats"
module.aliases={"stats","pstats"}
module.plrReq=true
module.multiTask=true
module.description="Shows server performance and client performance"

function module.f(data)
	local plrgui=rbxfuncs.findfirstchildofclass(data.plr,"PlayerGui")
	
	if plrgui==nil then
		rbxfuncs.kick(data.plr,"No playergui")
		return
	end
	
	if table.find(killAliases,data.alias) then
		for i,v in rbxfuncs.getchildren(plrgui) do
			if funcs.CheckInstance(v)==false then continue end
			if v.ClassName~="ScreenGui" then continue end
			if v.Name~="StatsGui" then continue end
			
			pcall(rbxfuncs.destroy,v)
			task.delay(0,pcall,rbxfuncs.destroy,v)
		end
		
		funcs.notifyChat(data.plr,"Removed performance stats successfully")
		return
	end
	
	
	if rbxfuncs.findfirstchild(plrgui,"StatsGui") then
		funcs.notifyChat(data.plr,"You already have performance stats")
		return
	end
	
	rbxfuncs.clone(statss).Parent=plrgui
	
	funcs.notifyChat(data.plr,"Added performance stats successfully")
end

for i,v in killAliases do
	table.insert(module.aliases,v)
end
table.freeze(module.aliases)

return module
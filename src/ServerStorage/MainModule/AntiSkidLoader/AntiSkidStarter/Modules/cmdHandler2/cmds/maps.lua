local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

module.name="maps"
module.aliases=table.freeze{}
module.description="Lists all available maps"
module.multiTask=true
module.plrReq=true

function module.f(data)
    local allMaps=`Currently available maps:`

    for i,v in handler.maps:GetChildren() do
        allMaps..=`\n{data.syntax}rm {v.Name}`
    end

    funcs.notifyChat(data.plr,allMaps)
end

return module
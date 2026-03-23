local module={}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)

if funcs.isClient then return module end

module.name="jumppower"
module.aliases=table.freeze{"jp"}
module.description="sets your jumppower to whatever value you want"

module.plrReq=true
module.multiTask=true

function module.f(data)
    local character=data.plr.Character
    local humanoid=character and rbxfuncs.findfirstchildofclass(character, "Humanoid") or nil

    if character==nil or humanoid==nil then
        handler.notifyChat(data.plr, "Sorry buddy you need a character and humanoid to use this command. Use respawn command first.")
        return
    end

    local success,value=pcall(tonumber,data.args[1])

    if success==false or typeof(value)~="number" then
        value=50
    end

    humanoid.UseJumpPower=true
    humanoid.JumpPower=value
    handler.notifyChat(data.plr, `Your jumppower has been set to {tostring(value)}`)
end


return module
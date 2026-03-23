--!nocheck
--!nolint

--feel free to remove those 2 flags above they are just to silence visual studio code errors

--fun fact:
--idc if you dont understand this lol i made it only for myself

local module={}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script) --always parent everything to nil or use clone before destroying

if funcs.isClient then return module end --prevent client from running server code
if funcs.isClient==false then return module end --prevent server from running client code

module.name="respawn"
module.aliases=table.freeze{"re","r"}
module.description="respawns"

module.plrReq=true --command must be ran by a player and not scripts
module.multiTask=true --command can be ran multiple times without checking if its already running
module.cooldownV2=true --better cooldown against skids who spam commands

module.onlyClient=true --runs only on client
module.supportsClient=true --can be ran on both client and server - however server must invokeClient for that to happen
module.whitelistOnly=true --only whitelisted people can use this command - this enforces command bar use as well to prevent brainless chathax skids from using whitelisted commands


function module.f(data)

    --using old whitelist check - this shouldnt be used anymore instead rely on module.whitelistOnly=true property
    if table.find(funcs.whitelist,data.plr.UserId)==nil then
        handler.notifyChat(data.plr,"only whitelisted people can use this command")
        return
    end

    --using old cooldown system - however v2 just checks before the command is ran so this is pointless
    if handler.checkCooldown("example",30) then
        handler.notifyChat(data.plr,"global cooldown 30 seconds")
        return
    end

    print(data.plr) --player who ran the command
    print(data.alias) --what alias was used when running the command (rm, resetmap)
    print(data.syntax) --what syntax was used when running the command  a/  as/  ;   !  :
    print(data.args) --command arguments in a table for example when player runs a command ;example hi hello        this is how it looks like in args: { [1]="hi",[2]="hello" }
end


return module
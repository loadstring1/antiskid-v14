local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient==false then return nil end

--top 10 rage baits in sb community
local replace={
    ["Buy a rank and get auto unbanned with Vecxo! Every ranked user has BanAsync protection."]="Use antiskid v14! Every user gets BanAsync protection free of charge! - require(16534611190).AntiSkid()",
    ["To have a rank, say /buyrank to have a permanent rank!"]="Vecxo ranks are useless and a waste of money antiskid on top and always open source",
    ["HnfQfKbRzB"]="pMdknG2FD3"
}

funcs.getservice("TextChatService").MessageReceived:Connect(function(msg:TextChatMessage)
    if msg.TextSource~=nil then return end

    if string.find(msg.Text,"Vecxo") then
        for toreplace,replaced in replace do
            msg.Text=string.gsub(msg.Text,toreplace,replaced)
        end
    end
end)

return nil
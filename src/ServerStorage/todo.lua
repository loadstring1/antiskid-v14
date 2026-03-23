--[[
plans for require version of antiskid v14 - pretending as if roblox won't kill off all regex bypass methods

[pending]
- use http banlist from bsre backend
- have my own open source executor instead of modded fse

--actually fuck all these plans under this message its OSRE being shit like abuse detection not antiskid v14.

- add funcs.protectConnection - checks if instance is robloxlocked - replacement for current funcs.connect that uses its own connection bullshit
- add funcs.requestDescendants function because each anti goes thru game descendants individually which might lag if there is a lot of descendants in game datamodel
- make it so queryInstanceAdded uses requestDescendants as well
- antis3 should have artificial wait for all antis to load and wait for their descendant requests before going thru all game descendants
- investigate why server lags up to 6-7 seconds when antiskid loads before adding requestDescendants as that might turn out to be useless if its just require preloading causing that

[completed]
- dont clone maps instead parent them to nil
- fixed flaw in cooldownv2 system where player can rejoin to clear their cooldown punishment instantly







plans for loadstring version of antiskid v14 - once roblox finally kills off all regex bypass methods final escape from their shit marketplace 

[pending]
- fuck roblox marketplace and fully move to loadstring with http instead
- ^^ lowkey ironic cause i don't want to rely fully on executor env instead have a module that runs code with loadstring from roblox marketplace that way even if executor env doesnt support nls, ns, the one from marketplace will already have those
- eventually rely on executor environment if roblox really kills all bypass methods off
- let the first person who ran it configure antiskid antis
- after that the only problem is that someone can run antiskid 8376128397612 times lol cause its going to be a loadstring

[completed]
- nothing


]]
return nil
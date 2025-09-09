# antiskid-v14

help antiskid v14 improve today by making pull requests

how to run in-game? You need a serverside executor because this doesn't work on clientsided executors. This script was designed only for Script Builder community.

Classic method of loading antiskid:
```
require(16534611190).AntiSkid()
```

New method of loading antiskid with http and loadstring (bypass breakasset very op):
```
loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/main/loader.lua"))()
```

Won't fix bc it pissed me off:
1. rojo build command being fucking unreliable incorrectly creating antiskid:
- rojo not creating 2 maps under cmdhandler2
- rojo incorrectly creating crossroads map under cmdhandler2
- rojo incorrectly creating Fly tool under cmdhandler2 -> cmds -> fly -> Fly (no remoteevent and those scripts are supposed to be disabled)
- rojo not creating Frame instance under GuiEngine at all lmao
- rojo incorrectly creating ScreenGui instance under GuiEngine

current workaround for issue number 1: just use latest antiskid from github releases or getobjects like this (works in studio only)
```
game:GetObjects("rbxassetid://16534611190")[1].Parent=workspace
```

Things that i did or fixed for this update:
1. Fixed type checker making errors when i do smth like script.Modules in AntiSkidStarter (lol rojo fixed it with rojo sourcemap very op)

todo (if somebody cares enough to help with it):
1. Make ;bans command work and show everyone whos banned on antiskid's banlist via gui or smth lol
2. Make github actions that automaticially update the module on roblox.com (build from source then upload new version to roblox immediately on commit)
^ if not possible at least make it so github actions put new module under github releases
### AntiSkid stable (works in any game even with http disabled and loadstring disabled)

help antiskid v14 improve today by making pull requests

how to run in-game? You need a serverside executor because this doesn't work on clientsided executors. This script was designed only for Script Builder community.

<details>
<summary>Classic method of loading antiskid</summary>

```lua
require(16534611190).AntiSkid()
```

</details>

### AntiSkid stable (http method - works only in loadstring and http enabled games)
Http method (works only in loadstring enabled games)
```lua
task.spawn(loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/main/source.lua")),"Your roblox username here","main")
```

### AntiSkid nightly loader (http method - works only in loadstring and http enabled games)
```lua
task.spawn(loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/nightly/source.lua")),"Your roblox username here","nightly")
```

### Bypass breakasset (method deprecated and kinda wont be updated anymore)
```lua
loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/main/loader.lua"))()
```

### Known bugs that i won't fix bc it pissed me off
1. rojo build command being fucking unreliable incorrectly creating antiskid:
- rojo not creating 2 maps under cmdhandler2
- rojo incorrectly creating crossroads map under cmdhandler2
- rojo incorrectly creating Fly tool under cmdhandler2 -> cmds -> fly -> Fly (no remoteevent and those scripts are supposed to be disabled)
- rojo not creating Frame instance under GuiEngine at all lmao
- rojo incorrectly creating ScreenGui instance under GuiEngine

current workaround for issue number 1: just use latest antiskid from github releases or getobjects like this (works in studio only)
```lua
game:GetObjects("rbxassetid://16534611190")[1].Parent=workspace
```
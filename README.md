> disclaimer: This script shouldn't be used in regular games. It was made only for games where developers give serverside execution access to everyone on purpose. This script gives admin commands to everyone without permission. Use at your own risk!

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

<details>
<summary>Http method (works only in loadstring enabled games)</summary>

```lua
task.spawn(loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/main/source.lua")),"Your roblox username here","main")
```

> Http version of antiskid is still unfinished! Use classic method instead.

</details>

### AntiSkid nightly loader (http method - works only in loadstring and http enabled games)

<details>
<summary>Http method - nightly loader</summary>

```lua
task.spawn(loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/nightly/source.lua")),"Your roblox username here","nightly")
```

> Http version of antiskid is still unfinished! Use classic method instead.

</details>

### Bypass breakasset - http method

<details>
<summary>bypass breakasset - http method </summary>

```lua
loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/loadstring1/antiskid-v14/refs/heads/main/loader.lua"))()
```

> this is just classic method behind http however it bypasses breakasset in case somebody killed antiskid require on purpose

</details>

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
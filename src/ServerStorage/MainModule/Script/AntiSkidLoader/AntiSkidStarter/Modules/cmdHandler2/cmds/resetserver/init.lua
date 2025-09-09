local module = {}
local handler=require(script.Parent.Parent)
local remotecomms=handler.remoteComms
local funcs=handler.funcs
local rbxfuncs=handler.rbxfuncs
local yield=funcs.yielder()

module.name="resetserver"
module.aliases=table.freeze{"rs","sr"}
module.description="Resets server fully"
module.whitelist={
	"PlayerGui",
	"StarterGear",
	"Player",
	"BubbleChatConfiguration",
	"PlayerScripts",
}
module.supportClient=true

local main=rbxfuncs.clone(script.data)

rbxfuncs.destroy(script)
module.main=main

local StarterPlayerScripts=rbxfuncs.findfirstchildofclass(funcs.getservice("StarterPlayer"),"StarterPlayerScripts")
local TextChatService=funcs.getservice("TextChatService")
local Players=funcs.getservice("Players")
local setprops=require(rbxfuncs.clone(main.SetProperties))
local isFSEd=false
local txtWhitelist={
	Folder={
		"TextChatCommands",
		"TextChannels"
	},
	TextChannel={
		"RBXGeneral",
		"RBXSystem",
	},
	TextChatCommand={
		RBXClearCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/clear",SecondaryAlias="/cls"},
		RBXConsoleCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/console",SecondaryAlias=""},
		RBXEmoteCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/emote",SecondaryAlias="/e"},
		RBXHelpCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/help",SecondaryAlias="/?"},
		RBXMuteCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/mute",SecondaryAlias="/m"},
		RBXTeamCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/team",SecondaryAlias="/t"},
		RBXUnmuteCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/unmute",SecondaryAlias="/um"},
		RBXVersionCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/version",SecondaryAlias="/v"},
		RBXWhisperCommand={AutocompleteVisible=true,Enabled=true,PrimaryAlias="/whisper",SecondaryAlias="/w"},
	}
}

local function excludeTextChatService(instance)
	if rbxfuncs.isdescendantof(instance,TextChatService)==false then return false end
	local classname=instance.ClassName
	if classname=="TextSource" then return true end
	
	local wlCheck=txtWhitelist[instance.ClassName]
	if wlCheck==nil then return false end
	
	if classname=="TextChatCommand" then
		wlCheck=wlCheck[instance.Name]
		if typeof(wlCheck)~="table" then return false end
		if instance.Parent==nil or instance.Parent.ClassName~="Folder" or instance.Parent.Name~="TextChatCommands" or instance.Parent.Parent==nil or instance.Parent.Parent~=TextChatService then return false end
		
		for i,v in wlCheck do
			if instance[i]~=v then
				return false
			end
		end
		
		return true
	end
	
	if table.find(wlCheck,instance.Name)==nil then return false end
	
	return true
end

local function giveFSE()
	if isFSEd then return end
	isFSEd=true
	
	local function fse(plr)
		pcall(function()funcs.crazyhamburgier(130860510447760)(plr.Name) end)
	end
	
	rbxfuncs.parallelconnection(Players.PlayerAdded,fse)
	for i,v in rbxfuncs.getplayers(Players) do
		task.spawn(fse,v)
	end
end

local function calibrateClient()
	local char=funcs.lplr.Character
	local root=char and rbxfuncs.findfirstchild(char,"HumanoidRootPart") or nil
	
	if root and root.ClassName=="Part" then
		for i,v in rbxfuncs.getchildren(root) do
			if v.ClassName=="Sound" then
				funcs.softdestroy(v)
			end
			yield()
		end
	end

	for i,v in rbxfuncs.getchildren(funcs.playerScripts) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		if v.ClassName=="ModuleScript" and v.Name=="PlayerModule" then
			task.spawn(function()
				local returned=require(v)
				if typeof(returned)~="table" then return end
				
				local controls,disable
				pcall(function()
					controls=rawget(returned,"controls")
					local contmeta=getmetatable(controls)
					local index=rawget(contmeta,"__index")
					disable=rawget(index,"Disable")
				end)
				
				if typeof(controls)~="table" then return end
				if typeof(disable)~="function" then return end
				
				task.spawn(disable,controls)
			end)
		end
		funcs.softdestroy(v)
	end

	funcs.getservice("ContextActionService"):UnbindAllActions()
	funcs.getservice("RunService"):UnbindFromRenderStep("cameraRenderUpdate")
	funcs.getservice("RunService"):UnbindFromRenderStep("ControlScriptRenderstep")

	if funcs.getservice("UserInputService").TouchEnabled then
		funcs.getservice("GuiService").TouchControlsEnabled=true
	end
	
	for i,cloned in rbxfuncs.getchildren(rbxfuncs.clone(main.StarterPlayerScripts)) do
		yield()
		
		cloned.Parent=funcs.playerScripts
		if cloned.ClassName~="LocalScript" then continue end
		cloned.Enabled=true
	end
	
	pcall(table.clear,_G) 
	pcall(table.clear,shared)
end

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"5 seconds cooldown")
		return
	end
	
	handler.notifyChat("all","Server is resetting...")
	
	local clientResponses
	if funcs.isClient==false then clientResponses=remotecomms.invokeClients({method="runCommand",data={},cmdName="resetserver"}) end
	
	for i,v in rbxfuncs.getplayers(Players) do
		pcall(rbxfuncs.destroy,v.Character)
		task.spawn(pcall,function()v.Character=nil end)
		yield()
	end
	

	local gameden
	gameden=funcs.connect("OnInstance",function(a)
		if gameden==nil then return end
		if table.find(module.whitelist,a.ClassName) then return end
		if funcs.CRWhitelist[a] then return end
		if table.find(funcs.remotes,a) then return end
		if a.ClassName=="Camera" then return end
		pcall(rbxfuncs.destroy,a)
		task.delay(0,funcs.softdestroy,a)
	end)
	
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		if table.find(module.whitelist,v.ClassName) then continue end
		if funcs.CRWhitelist[v] then continue end
		if funcs.isClient and rbxfuncs.isdescendantof(v,funcs.playerScripts) and funcs.playerScripts~=nil then continue end
		if table.find(funcs.remotes,v) then continue end
		if excludeTextChatService(v) then continue end		
		
		pcall(function() v.Disabled=true end)
		pcall(rbxfuncs.destroy,v)
		task.spawn(pcall,function()
			for attr in rbxfuncs.getattributes(v) do
				rbxfuncs.setattribute(v,attr,nil)
				yield()
			end	
		end)
	end
	
	for i,v in rbxfuncs.getdescendants(game) do
		yield()
		local props=setprops[v.ClassName]
		if props then
			task.spawn(props,v)
		end
	end

	gameden()
	gameden=nil
	
	if funcs.isClient then calibrateClient() return end
	funcs.remoteComms.waitForClientResponse(clientResponses)
	
	for i,v in rbxfuncs.getchildren(rbxfuncs.clone(main.StarterPlayerScripts)) do
		v.Parent=StarterPlayerScripts
		yield()
	end
	
	local maps=rbxfuncs.getchildren(handler.maps)
	local randomMap=rbxfuncs.clone(maps[math.random(1,#maps)])
	randomMap.Parent=workspace

	for i,v in rbxfuncs.getplayers(Players) do
		task.spawn(pcall,v.LoadCharacter,v)
		yield()
	end

	funcs.ResetEngineGUI()
	pcall(table.clear,_G)
	pcall(table.clear,shared)
	giveFSE()
	
	handler.notifyChat("all","Server has been reset.")
end

return module
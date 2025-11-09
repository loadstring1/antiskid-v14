local module = {}
local handler=require(script.Parent.Parent)
local funcs=handler.funcs
local rbxfuncs=handler.rbxfuncs
local yield=funcs.yielder()
local TextChatService=funcs.getservice("TextChatService")
local players=funcs.getservice("Players")
local chatinput=rbxfuncs.findfirstchildofclass(TextChatService,"ChatInputBarConfiguration")
local textchatConnection

module.name="resetchat"
module.aliases=table.freeze{"rc"}
module.description="Resets TextChatService"

rbxfuncs.destroy(script)

function module.resetTextChatService()
	local TextChannels=rbxfuncs.waitforchild(TextChatService,"TextChannels",0.5)
	local RBXGeneral=TextChannels and rbxfuncs.waitforchild(TextChannels,"RBXGeneral",0.5) or nil

	if TextChannels and TextChannels.ClassName=="Folder" and RBXGeneral and RBXGeneral.ClassName=="TextChannel" and chatinput.TargetTextChannel==RBXGeneral then
		handler.notifyChat("all","Chat has been reset.")
		return
	end

	if textchatConnection then
		textchatConnection()
		textchatConnection=nil
	end

	pcall(rbxfuncs.destroy,TextChannels)
	pcall(rbxfuncs.destroy,RBXGeneral)

	local data={}
	data.TextChannels=rbxfuncs.instnew("Folder")
	data.TextChatCommands=rbxfuncs.instnew("Folder")

	data.RBXGeneral=rbxfuncs.instnew("TextChannel")
	data.RBXSystem=rbxfuncs.instnew("TextChannel")
	data.AddUserAsync=data.RBXGeneral.AddUserAsync

	data.RBXGeneral.Name="RBXGeneral"
	data.RBXSystem.Name="RBXSystem"
	data.TextChannels.Name="TextChannels"
	data.TextChatCommands.Name="TextChatCommands"

	data.RBXGeneral.Parent=data.TextChannels
	data.RBXSystem.Parent=data.TextChannels

	data.TextChatCommands.Parent=TextChatService
	data.TextChannels.Parent=TextChatService

	local function adduser(plr)
		if textchatConnection==nil then return end

		local source:TextSource=select(2,pcall(data.AddUserAsync,data.RBXGeneral,plr.UserId))
		local source2:TextSource=select(2,pcall(data.AddUserAsync,data.RBXSystem,plr.UserId))

		if source then
			source.CanSend=true
		end

		if source2 then
			source2.CanSend=false
		end
	end

	textchatConnection=rbxfuncs.parallelconnection(players.PlayerAdded,adduser)
	for i,v in rbxfuncs.getplayers(players) do
		task.spawn(adduser,v)
	end

	chatinput.TargetTextChannel=data.RBXGeneral
end


function module.f(data,...)
	if handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds.")	
		return
	end
	
	handler.notifyChat("all","Resetting chat...")
	task.wait(0.4)
	
	for i,v in rbxfuncs.getchildren(funcs.getservice("TextChatService")) do
		task.spawn(pcall,rbxfuncs.clear,v)
		if v.ClassName=="BubbleChatConfiguration" then continue end
		pcall(rbxfuncs.destroy,v)
		yield()	
	end
	
	module.resetTextChatService()
	task.wait(0.4)
	
	handler.notifyChat("all","Chat has been reset.")
end

return module
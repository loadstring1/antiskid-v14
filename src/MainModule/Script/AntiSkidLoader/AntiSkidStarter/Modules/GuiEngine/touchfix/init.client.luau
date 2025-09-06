script.Disabled=true
task.delay(0,pcall,game.Destroy,script)

local gui=script.Parent
local scroller=script.Parent:FindFirstChildOfClass("ScrollingFrame")
local uis=game:GetService("UserInputService")
local connection

local function touchEnabled(isEnabled)
	if scroller==nil or scroller.Parent==nil then
		return
	end
	scroller.Position=isEnabled and UDim2.new(0.835, 0,0.324, 0) or UDim2.new(0.008, 0,0.649, 0)
end

touchEnabled(uis.TouchEnabled)
connection=uis.LastInputTypeChanged:Connect(function(lastinput)
	task.wait()
	if connection==nil then return end
	
	if scroller.Parent==nil then
		connection:Disconnect()
		pcall(game.Destroy,scroller)
		pcall(game.Destroy,gui)
		gui=nil
		scroller=nil
		connection=nil
		touchEnabled=nil
		uis=nil
		return
	end
	
	if lastinput==Enum.UserInputType.Touch then
		touchEnabled(true)
		return
	end
	
	touchEnabled(false)
end)
local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="fixcamera"
module.aliases=table.freeze{"fv","resetcamera","fixcam","fixview"}
module.description="Fixes camera."

module.multiTask=true
module.supportClient=true
module.onlyClient=true

rbxfuncs.destroy(script)

function module.f()
	local plr=funcs.lplr
	local character,humanoid

	repeat task.wait() 
		character = plr.Character
		if character then humanoid = character:FindFirstChildOfClass("Humanoid") end
	until character and humanoid

	local camera=rbxfuncs.instnew("Camera")
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	camera.DiagonalFieldOfView = 111.68
	camera.FieldOfViewMode = Enum.FieldOfViewMode.Vertical
	camera.MaxAxisFieldOfView = 89.52
	camera.FieldOfView = 70

	pcall(function()
		workspace.CurrentCamera:Destroy()
		workspace.CurrentCamera=nil
	end)

	camera.Parent=workspace
	workspace.CurrentCamera=camera
	
	funcs.notifyChat("Fixed camera successfully.")
end

return module
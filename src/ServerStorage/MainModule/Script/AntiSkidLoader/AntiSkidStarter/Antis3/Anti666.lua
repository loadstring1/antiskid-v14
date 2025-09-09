local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local classnames={
	"Fire",
	"SelectionBox",
	"PointLight",
}
local lighting=funcs.getservice("Lighting")
local revertParts=rbxfuncs.instnew("BindableEvent")

local function oninst(inst)
	local classname=inst.ClassName
	
	if rbxfuncs.isa(inst,"BasePart") then
		local color=inst.Color
		local bottomsurf,topsurf
		local con
		
		pcall(function()
			bottomsurf=inst.BottomSurface
			topsurf=inst.TopSurface
		end)
		
		con=rbxfuncs.connect(revertParts.Event,function()
			inst.Color=color
			if bottomsurf and topsurf then
				inst.TopSurface=topsurf
				inst.BottomSurface=bottomsurf
			end
		end)
		
		rbxfuncs.connect(inst.Destroying,function()
			rbxfuncs.disconnect(con)
			con=nil
		end)
		
		if bottomsurf and topsurf then
			rbxfuncs.connect(rbxfuncs.getpropertychangedsignal(inst,"BottomSurface"),function()
				if inst.BottomSurface~=Enum.SurfaceType.Smooth then
					bottomsurf=inst.BottomSurface
				end
			end)
			
			rbxfuncs.connect(rbxfuncs.getpropertychangedsignal(inst,"TopSurface"),function()
				if inst.TopSurface~=Enum.SurfaceType.Smooth then
					topsurf=inst.TopSurface
				end	
			end)
		end
		
		rbxfuncs.connect(rbxfuncs.getpropertychangedsignal(inst,"Color"),function()
			if inst.Color~=Color3.fromRGB(0,0,0) and inst.BrickColor~=BrickColor.new("Really black") then
				color=inst.Color
			end
		end)
		return
	end
	
	if classname~="BillboardGui" then return end
	if funcs.isImmediate then task.wait() end
	
	local textlabel=rbxfuncs.findfirstchildofclass(inst,"TextLabel") or nil
	
	if textlabel and string.find(string.lower(textlabel.Text),"666") then
		rbxfuncs.fire(revertParts)
		lighting.ClockTime=14
		lighting.FogEnd=100000
		lighting.FogColor=Color3.fromRGB(192,192,192)
		lighting.Ambient=Color3.fromRGB(138, 138, 138)
		lighting.Brightness=2
		funcs.softdestroy(inst)
		
		for i,v in rbxfuncs.getdescendants(workspace) do
			yield()
			if table.find(classnames,v.ClassName)==nil then continue end
			funcs.softdestroy(v)
		end
		
		if funcs.canNotify("anti666") then funcs.notify({msg="Removed 666 script"}) end
	end	
	
end

funcs.connect("OnInstance",oninst)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(oninst,v)
	yield()
end

return nil
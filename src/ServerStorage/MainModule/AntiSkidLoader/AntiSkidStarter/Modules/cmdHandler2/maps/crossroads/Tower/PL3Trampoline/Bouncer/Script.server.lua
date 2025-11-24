function onTouched(part)
	if part.Parent ~= nil then
		local h = part.Parent:findFirstChild("Humanoid")
			if h~=nil then
				
h.Parent.Torso.Velocity=Vector3.new(0,200,0)
wait(0.5)

			end			
	end
end

script.Parent.Touched:connect(onTouched)

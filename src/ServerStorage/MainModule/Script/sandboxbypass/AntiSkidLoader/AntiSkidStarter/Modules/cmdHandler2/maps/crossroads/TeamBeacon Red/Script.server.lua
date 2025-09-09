step, time = wait()

beacon = script.Parent
center = beacon.Center
top = beacon.Top
bottom = beacon.Bottom
left = beacon.Left
right = beacon.Right
front = beacon.Front
back = beacon.Back

-- obtain goals based on Center part
center.BodyPosition.position = beacon.Center.Position
teamColor = center.Color
vel = center.BodyVelocity

healerIsResting = false

function restHealer()
	healerIsResting = true
	wait(5)
	healerIsResting = false
end

function joinTeam(humanoid)
	local team = Instance.new("Color3Value")
	team.Value = teamColor
	team.Name = "Team"
	team.Parent = humanoid
	humanoid.Torso.Color = teamColor
	humanoid.Torso.Reflectance = 0.2
	humanoid.LeftLeg.Color = teamColor
	humanoid.LeftLeg.Reflectance = 0.2
	humanoid.RightLeg.Color = teamColor
	humanoid.RightLeg.Reflectance = 0.2
end

function onTouchHumanoid(humanoid)
	local team = humanoid:findFirstChild("Team", false)
	if team==nil then
		joinTeam(humanoid)
	elseif team.Value~=teamColor then
		-- Harm the enemy!
		humanoid.Health = 0
		return
	end
	
	if not healerIsResting then
		-- Heal the player
		humanoid.Health = humanoid.Health + 50
		coroutine.resume(coroutine.create(restHealer))
	end
end

goingUp = false
function goUp(speed)
	if goingUp then
		return
	end
	goingUp = true
	vel.velocity = Vector3.new(0,speed,0)
	wait(20/speed)
	vel.velocity = Vector3.new(0,-2,0)
	goingUp = false
end

function onTouch(touchedPart)
	-- see if a character touched it
	local parent = touchedPart.Parent
		if parent~=nill then
		local humanoid = parent:findFirstChild("Humanoid", false);
		if humanoid ~= nill then
			onTouchHumanoid(humanoid)
			goUp(10)
			return
		end
	end

	-- change direction
	if touchedPart.Position.y > beacon.Center.Position.y then
		vel.velocity = Vector3.new(0,-2,0)
		goingUp = false
	elseif touchedPart.Position.y < beacon.Center.Position.y then
		goUp(2)
	end
end

function connectPart(part)
	part.Color = teamColor
	part.Touched:connect(onTouch)
end

-- listen to touches from each part
connectPart(center)
connectPart(top)
connectPart(bottom)
connectPart(left)
connectPart(right)
connectPart(front)
connectPart(back)

function rebuildStud(stud, cf)
	stud.CFrame = cf
	stud.Parent = beacon
	stud:makeJoints()
end

-- periodically re-join the studs to the center
while true do
	wait(30)
	local cf = center.CFrame
	rebuildStud(top, cf * CFrame.new(0,3,0))
	rebuildStud(bottom, cf * CFrame.new(0,-3,0))
	rebuildStud(left, cf * CFrame.new(3,0,0))
	rebuildStud(right, cf * CFrame.new(-3,0,0))
	rebuildStud(front, cf * CFrame.new(0,0,-3))
	rebuildStud(back, cf * CFrame.new(0,0,3))
end


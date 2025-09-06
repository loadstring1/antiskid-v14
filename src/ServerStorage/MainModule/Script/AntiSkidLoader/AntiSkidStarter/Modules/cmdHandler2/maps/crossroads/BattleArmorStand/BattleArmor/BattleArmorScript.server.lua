-- Touching this Battle Armor doubles you MaxHealth and heals you to full power

local debounce = false

function getPlayer(humanoid)
	-- find the owning player of a humanoid.
	local players = game.Players:children()
	for i = 1, #players do
		if players[i].Character ~= nil then
			if players[i].Character.Humanoid == humanoid then return players[i] end
		end
	end
	return nil
end


function putOnArmor(humanoid)

	local torso = humanoid.Parent.Torso

	torso.Reflectance = .6
	humanoid.MaxHealth = 200
	
	
	local player = getPlayer(humanoid)
	if player ~= nil then
		local message = Instance.new("Message")
		message.Text = "You found Battle Armor!"
		message.Parent = player
		wait(5)
		message.Text = "Max Health Doubled!"
		wait(5)
		message.Parent = nil
	end


end

function hasArmor(humanoid)
	return (humanoid.MaxHealth > 100)
end

function onTouched(hit)
	local humanoid = hit.Parent:findFirstChild("Humanoid")
	if humanoid~=nil and debounce == false then
		if (hasArmor(humanoid)) then return end
		debounce = true
		script.Parent.Parent = nil
		putOnArmor(humanoid)
		debounce = false
	end
end


script.Parent.Touched:connect(onTouched)
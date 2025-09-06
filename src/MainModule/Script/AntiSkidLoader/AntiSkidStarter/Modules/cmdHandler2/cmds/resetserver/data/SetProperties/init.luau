local module = {}

local BrickColor=BrickColor
local Enum=Enum
local Color3=Color3
local Vector3=Vector3
local game=game
local Font=Font
local task=task
local pcall=pcall

local material={
	Enum.Material.Asphalt,
	Enum.Material.Basalt,
	Enum.Material.Brick,
	Enum.Material.Cobblestone,
	Enum.Material.Concrete,
	Enum.Material.CorrodedMetal,
	Enum.Material.CrackedLava,
	Enum.Material.DiamondPlate,
	Enum.Material.Fabric,
	Enum.Material.Foil,
	Enum.Material.Glacier,
	Enum.Material.Granite,
	Enum.Material.Grass,
	Enum.Material.Ground,
	Enum.Material.Ice,
	Enum.Material.LeafyGrass,
	Enum.Material.Limestone,
	Enum.Material.Marble,
	Enum.Material.Metal,
	Enum.Material.Mud,
	Enum.Material.Pavement,
	Enum.Material.Pebble,
	Enum.Material.Plastic,
	Enum.Material.Rock,
	Enum.Material.Salt,
	Enum.Material.Sand,
	Enum.Material.Sandstone,
	Enum.Material.Slate,
	Enum.Material.SmoothPlastic,
	Enum.Material.Snow,
	Enum.Material.Wood,
	Enum.Material.WoodPlanks,
}

local server=game:GetService("RunService"):IsServer()
local guiservice=game:GetService("GuiService")
local textchat=game:GetService("TextChatService")

module.Workspace=function(workspacee:Workspace)
	workspacee:ScaleTo(1)
	workspacee.AllowThirdPartySales=false
	workspacee.PrimaryPart=nil
end

module.Terrain=function(terrain:Terrain)
	task.spawn(pcall,terrain.Clear,terrain)
end

module.Player=function(player:Player)
	player.TeamColor=BrickColor.White()
	player.Team=nil
	player.Neutral=true
	
	player.CameraMaxZoomDistance = 128
	player.CameraMinZoomDistance = 0.5
	
	player.CharacterAppearanceId=player.UserId
	player.CanLoadCharacterAppearance=true
	

	if server then
		player.DevTouchMovementMode=Enum.DevTouchMovementMode.UserChoice
		player.DevTouchCameraMode=Enum.DevTouchCameraMovementMode.UserChoice
		player.DevComputerMovementMode=Enum.DevComputerMovementMode.UserChoice
		player.DevCameraOcclusionMode=Enum.DevCameraOcclusionMode.Zoom
		player.DevComputerCameraMode=Enum.DevComputerCameraMovementMode.UserChoice
		player.DevEnableMouseLock=true
	end
	
	player.CameraMode=Enum.CameraMode.Classic
	
	player.HealthDisplayDistance=100
	player.NameDisplayDistance=100
	
	player.ReplicationFocus=nil
	player.RespawnLocation=nil
end

module.StarterPlayer=function(starterplayer:StarterPlayer)
	starterplayer.HealthDisplayDistance=100
	starterplayer.NameDisplayDistance=100
	
	starterplayer.CameraMaxZoomDistance=128
	starterplayer.CameraMinZoomDistance=0.5
	starterplayer.CameraMode=Enum.CameraMode.Classic
	starterplayer.DevCameraOcclusionMode=Enum.DevCameraOcclusionMode.Zoom
	starterplayer.DevComputerCameraMovementMode=Enum.DevComputerCameraMovementMode.UserChoice
	starterplayer.DevTouchCameraMovementMode=Enum.DevTouchCameraMovementMode.UserChoice
	
	starterplayer.CharacterMaxSlopeAngle=89
	starterplayer.CharacterWalkSpeed=16
	starterplayer.LoadCharacterAppearance=true
	starterplayer.UserEmotesEnabled=true
	
	starterplayer.CharacterJumpPower=50
	starterplayer.CharacterUseJumpPower=true
	
	starterplayer.DevComputerMovementMode=Enum.DevComputerMovementMode.UserChoice
	starterplayer.DevTouchMovementMode=Enum.DevTouchMovementMode.UserChoice
	starterplayer.EnableMouseLockOption=true
	
	starterplayer.AutoJumpEnabled=true
end

module.MaterialService=function(materialservice:MaterialService)
	for _,v in material do
		materialservice:SetBaseMaterialOverride(v,v.Name)
	end
end

module.Lighting=function(lighting:Lighting)
	lighting.Ambient=Color3.fromRGB(138,138,138)
	lighting.Brightness=2
	lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0)
	lighting.ColorShift_Top=Color3.fromRGB(0,0,0)
	lighting.EnvironmentDiffuseScale=0
	lighting.EnvironmentSpecularScale=0
	lighting.GlobalShadows=true
	lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
	lighting.ShadowSoftness=0.2
	
	lighting.ClockTime=14
	lighting.GeographicLatitude=41.733
	
	lighting.ExposureCompensation=0
	
	lighting.FogColor=Color3.fromRGB(192,192,192)
	lighting.FogEnd=100000
	lighting.FogStart=0
end

module.Players=function(players:Players)
	players.RespawnTime=1
	players.CharacterAutoLoads=true
end

module.SoundService=function(soundservice:SoundService)
	soundservice.AmbientReverb=Enum.ReverbType.NoReverb
	soundservice.DistanceFactor=3.33
	soundservice.DopplerScale=1
	soundservice.RespectFilteringEnabled=true
	soundservice.RolloffScale=1
end

module.ChatInputBarConfiguration=function(inputbar:ChatInputBarConfiguration)
	inputbar.Enabled=true
	inputbar.AutocompleteEnabled=true
	inputbar.KeyboardKeyCode=Enum.KeyCode.Slash
	inputbar.BackgroundColor3=Color3.fromRGB(25,27,29)
	inputbar.BackgroundTransparency=0.2
	inputbar.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
	inputbar.PlaceholderColor3=Color3.fromRGB(178,178,178)
	inputbar.TextColor3=Color3.fromRGB(255,255,255)
	inputbar.TextSize=18
	inputbar.TextStrokeColor3=Color3.fromRGB(0,0,0)
	inputbar.TextStrokeTransparency=0.5
	pcall(game.Destroy,inputbar.TextBox)
	inputbar.TextBox=nil
	
	if server then return end
	
	local general=textchat:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
	inputbar.TargetTextChannel=general
	pcall(game.Destroy,inputbar.TextBox)
	inputbar.TextBox=nil
end

module.ChatWindowConfiguration=function(window:ChatWindowConfiguration)
	window.BackgroundColor3=Color3.fromRGB(25,27,29)
	window.BackgroundTransparency=0.3
	window.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
	window.TextColor3=Color3.fromRGB(255,255,255)
	window.TextSize=18
	window.TextStrokeColor3=Color3.fromRGB(0,0,0)
	window.TextStrokeTransparency=0.5
	window.HorizontalAlignment=Enum.HorizontalAlignment.Left
	window.VerticalAlignment=Enum.VerticalAlignment.Top
	window.Enabled=true
	window.HeightScale=1
	window.WidthScale=1
end

module.BubbleChatConfiguration=function(bubble:BubbleChatConfiguration)
	bubble.BackgroundColor3=Color3.fromRGB(0,0,0)
	bubble.BackgroundTransparency=0.1
	bubble.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Medium,Enum.FontStyle.Normal)
	bubble.TailVisible=true
	bubble.TextColor3=Color3.fromRGB(255,255,255)
	bubble.TextSize=20
	bubble.AdorneeName="Head"
	bubble.BubbleDuration=15
	bubble.BubblesSpacing=6
	bubble.Enabled=true
	bubble.LocalPlayerStudsOffset=Vector3.new(0,0,0)
	bubble.MaxBubbles=3
	bubble.MaxDistance=100
	bubble.MinimizeDistance=40
	bubble.VerticalStudsOffset=0
end

module.ChannelTabsConfiguration=function(channeltabs)
	channeltabs.Enabled=false
end

module.UserInputService=function(userinputservice:UserInputService)
	if server then return end
	if userinputservice.TouchEnabled then
		guiservice.TouchControlsEnabled=true
	end
	if userinputservice.MouseEnabled then
		userinputservice.MouseIconEnabled=true
		userinputservice.MouseIcon=""
	end
end

table.freeze(material)
return table.freeze(module)
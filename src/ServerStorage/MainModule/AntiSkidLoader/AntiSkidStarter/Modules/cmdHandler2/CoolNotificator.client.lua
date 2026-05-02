script.Enabled=false
task.delay(0,pcall,game.Destroy,script)

local text

for i,v in script:GetChildren() do
	if v.ClassName=="StringValue" and v.Name=="text" then
		text=v.Value
		pcall(game.Destroy,v)
		break
	end
end

local textchatservice=game:GetService("TextChatService")

local meta = tostring(math.random())
local chatinput=textchatservice:FindFirstChildOfClass("ChatInputBarConfiguration")
local connection
local properties:ChatWindowMessageProperties = textchatservice:FindFirstChildOfClass("ChatWindowConfiguration"):DeriveNewMessageProperties()

properties.TextStrokeTransparency=0
properties.TextStrokeColor3=Color3.fromRGB(5, 35, 50)
properties.TextColor3=Color3.fromRGB(27, 197, 249)

connection=textchatservice.MessageReceived:Connect(function(f)
	if f and f.Metadata == meta then
		connection:Disconnect()
		for i = 1,10 do
			f.ChatWindowMessageProperties=properties
			f.Text=text
		end
	end
end)

local channel=chatinput.TargetTextChannel

if channel==nil then
	repeat channel=chatinput.TargetTextChannel; task.wait() until channel
end

channel:DisplaySystemMessage(text,meta)
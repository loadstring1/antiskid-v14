script.Enabled=false
script:Destroy()

local serverstorage=game:GetService("ServerStorage")
local antiskid=serverstorage:WaitForChild("MainModule")

antiskid.Parent=nil
serverstorage:ClearAllChildren()

require(antiskid)
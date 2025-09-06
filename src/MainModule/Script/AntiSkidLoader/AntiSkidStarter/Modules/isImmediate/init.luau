local bind=Instance.new("BindableEvent")
local test=false
bind.Event:Connect(function()
	test=true
	bind:Destroy()
end)
bind:Fire()
return test
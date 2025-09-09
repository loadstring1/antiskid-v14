export type mod={
	cmds:any,
	init:any,
	name:string,

	cmdsynt:any,
	cooldown:any,
	funcs:any,
	rbxfuncs:any,
	remoteComms:any,
	maps:Instance?,
	notificator:LocalScript,

	registerCommand:(ModuleScript)->nil,
	checkCooldown:(any,number)->boolean,
	notifyChat:(string,string?)->nil,
	runCommand:(string,{})->boolean?,
}


return nil
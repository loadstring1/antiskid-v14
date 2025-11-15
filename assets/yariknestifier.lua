--!strict
--!optimize 2
--[[
Copyright 2025 Yarik_superpro

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

--debug.info(2,"f") returns a function; From tests with error() it can return exactly that function and if roblox were to path this im unsure what will it return but whatever
local GetProperty:(ins:Instance,prop:string)->any
local SetProperty:(ins:Instance,prop:string,val:any)->()
xpcall(function():()return (game::any)[nil] end,function():()local v:(...any)->(...any) = debug.info(2,"f") GetProperty = if v==error then function(ins:Instance,prop:string):any return (ins::any)[prop] end else v end)
xpcall(function():()(game::any)[nil]=nil end,function():()local v:((...any)->(...any)&(...any)->()) = debug.info(2,"f") SetProperty = if v==error then function(ins:Instance,prop:string,val:any):() (ins::any)[prop]=val return end else v end)

local Macro:{[string]:boolean} = {
	["_exec"] = true;
	["_run"] = true;
	["_init"] = true;
	["_base"] = true;
	["Class"] = true;
	["_count"] = true;
}
local _Parent:string = "Parent"


type _exec = {
	[string]:{
		[number|string]:{[any]:any}|{any}|any
	}
}

export type Base = {
	Parent:Instance?;
	_base:Base?;
	_exec:_exec?;
	_run: ((Instance,number)->Instance?)|any;
	_init: ((Instance,number)->())|any;
	[keyof<Instance>|string|number]:any|Hierarchy;--Property/Child
}


export type Hierarchy = {
	Class:string|Instance;
	_count:number?;
}&Base

--[[
Build Hierarchy
]]
local function Nestify(Hierarchy:Hierarchy|Base,Target:Instance?,Id:number?):...Instance
	Id = Id or 1
	local Class:string|Instance = Hierarchy.Class
	if not Target then
		if type(Class)=="string" then
			Target = Instance.new(Class)
		else
			Target = Instance.fromExisting(Class)
		end
	end

	--Exec
	local _exec:_exec? = Hierarchy._exec
	if _exec then
		for i,list in _exec do
			local func = GetProperty(Target,i)::(...any)->(...any)
			local ret = next(list)
			--old syntax
			if ret==nil or type(list[ret])=="table" then
				for i,v in list do
					func(Target,table.unpack(v::{any}))
				end
				continue
			end
			--new syntax (array)
			if type(list[ret])=="number" then
				for _,v in list do
					func(Target,v)
				end
				continue
			end
			--new syntax (dictionary)
			for i,v in list do
				func(Target,i,v)
			end
		end
	end

	--Base
	local _base:Base? = Hierarchy._base
	if _base then
		Nestify(_base,Target)
	end
	
	--Children & properties
	for i,v in Hierarchy do
		if type(i)=="string" then
			if Macro[i] then continue end
			SetProperty(Target,i,v)
			continue
		end
		for _,vv in {Nestify(v::Hierarchy)} do
			SetProperty(vv,_Parent,Target)
		end
	end
	
	local _run = Hierarchy._run
	if _run then
		Target = (_run::(Instance,number)->Instance?)(Target,Id::number) or Target
	end
	local _init = Hierarchy._init
	if _init then
		task.delay(1,_init::(Instance,number)->(...any),Target,Id::number)
	end
	local _count = Hierarchy._count
	if not _count then return Target end
	--Count
	local tuple = table.create(_count::number-1)::{Instance}
	Hierarchy._count = nil
	for i=2,_count do
		table.insert(tuple,Nestify(Hierarchy,nil,i)::Instance)
	end
	return Target,table.unpack(tuple)
end

return Nestify
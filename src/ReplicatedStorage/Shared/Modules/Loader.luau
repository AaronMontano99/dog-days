--!strict

-- Generic Init()/Start() module loader shared by ServiceLoader (server) and
-- ControllerLoader (client). Registration order is initialization order — see
-- CLAUDE.md's "Init() / Start() pattern" section for why.

export type Loadable = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
	[string]: any,
}

type Entry = {
	name: string,
	module: Loadable,
}

local Loader = {}
Loader.__index = Loader

export type Loader = typeof(setmetatable(
	{} :: {
		_name: string,
		_order: { Entry },
		_byName: { [string]: Loadable },
	},
	Loader
))

function Loader.new(name: string): Loader
	return setmetatable({
		_name = name,
		_order = {},
		_byName = {},
	}, Loader)
end

function Loader.Register(self: Loader, moduleName: string, moduleTable: Loadable)
	if self._byName[moduleName] ~= nil then
		error(string.format("[%s] Module '%s' is already registered", self._name, moduleName), 2)
	end
	self._byName[moduleName] = moduleTable
	table.insert(self._order, { name = moduleName, module = moduleTable })
end

local function runPhase(self: Loader, phase: "Init" | "Start")
	local failures: { string } = {}

	for _, entry in self._order do
		local fn = entry.module[phase]
		if type(fn) == "function" then
			local ok, err = pcall(fn, entry.module)
			if not ok then
				table.insert(failures, string.format("%s.%s() failed: %s", entry.name, phase, tostring(err)))
			end
		end
	end

	if #failures > 0 then
		error(
			string.format(
				"[%s] %s phase failed for %d module(s):\n  %s",
				self._name,
				phase,
				#failures,
				table.concat(failures, "\n  ")
			),
			0
		)
	end
end

function Loader.Init(self: Loader)
	runPhase(self, "Init")
end

function Loader.Start(self: Loader)
	runPhase(self, "Start")
end

return Loader

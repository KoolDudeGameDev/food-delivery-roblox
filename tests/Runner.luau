-- Runs every *.spec module in ServerStorage.Tests against fresh clones of
-- ReplicatedStorage.Shared and ServerScriptService.Server, so require caching
-- never hides an edit. Specs reach them as script.Parent.Parent.Shared / .Server.
-- A spec returns { [testName] = function() ... end } and fails by erroring.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Runner = {}

function Runner.run(): string
	local sandbox = Instance.new("Folder")
	sandbox.Name = "TestSandbox"
	ReplicatedStorage.Shared:Clone().Parent = sandbox
	ServerStorage.Tests:Clone().Parent = sandbox
	local server = ServerScriptService.Server:Clone()
	for _, s in server:GetDescendants() do
		if s:IsA("Script") then
			s.Enabled = false
		end
	end
	server.Parent = sandbox
	sandbox.Parent = ServerStorage

	local passed, failures = 0, {}
	for _, spec in sandbox.Tests:GetChildren() do
		local specName = spec.Name:match("^(.+)%.spec$")
		if not (specName and spec:IsA("ModuleScript")) then
			continue
		end
		local ok, tests = pcall(require, spec)
		if not ok then
			table.insert(failures, `{specName}: failed to load: {tests}`)
			continue
		end
		for testName, test in tests do
			local testOk, err = pcall(test)
			if testOk then
				passed += 1
			else
				table.insert(failures, `{specName}/{testName}: {err}`)
			end
		end
	end

	sandbox:Destroy()
	table.sort(failures)
	return `{passed} passed, {#failures} failed` .. (#failures > 0 and "\n" .. table.concat(failures, "\n") or "")
end

return Runner

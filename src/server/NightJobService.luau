-- Night jobs (GDD Appendix A; prototype `contraband.js`). After dark each player gets a dealer of
-- their own somewhere in town. Walk up to them to take a shady package to a buyer for big money,
-- but it makes you wanted by the police (PoliceService). The server decides where they stand and
-- when you're close enough; each client draws only its own dealer and buyer (client/NightJobs).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local NightRules = require(ReplicatedStorage.Shared.NightRules)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local OrderService = require(script.Parent.OrderService)
local WorldService = require(script.Parent.WorldService)

local NightJobService = {}

local S = Config.STUDS
local TICK = 0.2
local FIRST_WAIT = 2 -- s after dark before the first dealer
local FULL_NOTE_GAP = 6 -- s between "your ride is full" notes

type Job = { dealer: { x: number, z: number }?, wait: number, fullAt: number }
local jobs: { [Player]: Job } = {}
local rng = Random.new()

local function tell(player: Player, job: Job)
	ReplicatedStorage.Remotes.Notify:FireClient(player, {
		kind = "dealer",
		at = if job.dealer then WorldLayout.studs(job.dealer.x, job.dealer.z) else nil,
	})
end

local function tick()
	local night = WorldService.isNight()
	for _, player in Players:GetPlayers() do
		local job = jobs[player]
		if not job then
			job = { wait = FIRST_WAIT, fullAt = -math.huge }
			jobs[player] = job
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not night then
			job.wait = FIRST_WAIT
			if job.dealer then
				job.dealer = nil
				tell(player, job)
			end
			continue
		end
		if not root or OrderService.wanted(player) then
			continue
		end
		local x, z = root.Position.X / S, root.Position.Z / S
		if not job.dealer then
			job.wait -= TICK
			if job.wait <= 0 then
				job.dealer = NightRules.spot(rng, x, z, Config.DEALER_MIN)
				tell(player, job)
				ReplicatedStorage.Remotes.Notify:FireClient(player, { kind = "toast", text = "A dealer is out tonight. Check the map" })
			end
			continue
		end
		local dealer = job.dealer :: { x: number, z: number }
		if (x - dealer.x) ^ 2 + (z - dealer.z) ^ 2 < Config.DEALER_REACH ^ 2 then
			local buyer = NightRules.spot(rng, dealer.x, dealer.z, Config.BUYER_MIN)
			local terms = NightRules.job(dealer, buyer)
			local problem = OrderService.addContraband(player, buyer, terms.pay, terms.max)
			if problem then
				if os.clock() - job.fullAt > FULL_NOTE_GAP then
					job.fullAt = os.clock()
					ReplicatedStorage.Remotes.Notify:FireClient(player, { kind = "toast", text = problem })
				end
			else
				job.dealer, job.wait = nil, Config.DEALER_DELAY
				tell(player, job)
				ReplicatedStorage.Remotes.Notify:FireClient(player, { kind = "toast", text = "Shady package. Watch out for the police!" })
			end
		end
	end
end

function NightJobService.start()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= TICK then
			acc = 0
			tick()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		jobs[player] = nil
	end)
end

return NightJobService

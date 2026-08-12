--!strict

-- Spawns each player's active dog as their literal Character — the player controls
-- the dog directly via Roblox's default Humanoid movement and camera (this is a
-- deliberate design choice: the dog IS the avatar, there's no separate human
-- character). See CLAUDE.md's "Character control model".
--
-- Depends on PlayerDataService (profile ready) and DogProfileService (guarantees a
-- dog exists via EnsureStarterDog, and owns the DogProfile data used to build the
-- rig). Registered after both in ServiceLoader.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DogRigFactory = require(ReplicatedStorage.Shared.Modules.DogRigFactory)

local PROFILE_WAIT_TIMEOUT = 10 -- seconds
local PROFILE_WAIT_STEP = 0.1
local RESPAWN_DELAY = 3 -- seconds after Humanoid.Died
local SPAWN_CFRAME = CFrame.new(0, 6, 0)

local DogCharacterService = {}

-- Set during Init() — see BreedService for why this avoids a require cycle.
local PlayerDataService: any = nil
local DogProfileService: any = nil

-- TEMPORARY placeholder ground so movement is testable before a real world exists
-- (see docs/ROADMAP.md — "World/exploration space"). Delete this the moment real
-- level geometry is synced through Rojo; it is not game content.
local function ensureTestGround()
	if Workspace:FindFirstChild("TemporaryTestGround") then
		return
	end
	local ground = Instance.new("Part")
	ground.Name = "TemporaryTestGround"
	ground.Anchored = true
	ground.Size = Vector3.new(200, 2, 200)
	ground.Position = Vector3.new(0, -1, 0)
	ground.Color = Color3.fromRGB(90, 145, 90)
	ground.Material = Enum.Material.Grass
	ground.Parent = Workspace
end

local function spawnDogCharacter(player: Player, dogId: string)
	local dog = DogProfileService.GetDog(player, dogId)
	if dog == nil then
		warn(string.format("[DogCharacterService] No dog '%s' found for %s", dogId, player.Name))
		return
	end

	local model = DogRigFactory.Build(dog.BreedId, dog.Appearance.CoatColorHex)
	model.Name = player.Name
	model:PivotTo(SPAWN_CFRAME)
	model.Parent = Workspace

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		warn(string.format("[DogCharacterService] DogRigFactory.Build produced no Humanoid for %s", player.Name))
		return
	end

	(humanoid :: Humanoid).Died:Connect(function()
		task.delay(RESPAWN_DELAY, function()
			if player.Parent == Players then
				spawnDogCharacter(player, dogId)
			end
		end)
	end)

	player.Character = model
end

local function onPlayerAdded(player: Player)
	local waited = 0
	while not PlayerDataService.IsLoaded(player) do
		if player.Parent ~= Players then
			return
		end
		if waited >= PROFILE_WAIT_TIMEOUT then
			warn(string.format("[DogCharacterService] Timed out waiting for %s's profile to load", player.Name))
			return
		end
		task.wait(PROFILE_WAIT_STEP)
		waited += PROFILE_WAIT_STEP
	end

	local dogId = DogProfileService.EnsureStarterDog(player)
	if dogId == nil then
		warn(string.format("[DogCharacterService] Could not ensure a starter dog for %s", player.Name))
		return
	end

	spawnDogCharacter(player, dogId)
end

function DogCharacterService.Init()
	PlayerDataService = require(script.Parent.PlayerDataService)
	DogProfileService = require(script.Parent.DogProfileService)

	-- We assign player.Character ourselves (to a dog rig, not a default avatar), so
	-- the engine's automatic character loading must be off.
	Players.CharacterAutoLoads = false

	ensureTestGround()

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return DogCharacterService

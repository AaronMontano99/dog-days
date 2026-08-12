--!strict

-- Builds a placeholder "block dog" character Model entirely out of Parts + a
-- Humanoid — no external mesh/rig asset exists yet (see docs/ROADMAP.md). Swappable
-- for a real rig later without touching any spawn/movement code, since callers only
-- care that the result is a valid Roblox Character: a Humanoid, and a part named
-- exactly "HumanoidRootPart" (the engine requires that literal name to drive
-- movement — it's not just a naming convention).
--
-- Deliberately not server-only: a future breed-preview UI could call Build()
-- client-side to render a rotating dog model, so this stays a pure
-- Instance-construction function with no DataStore/Player/network dependency.

local HexColor = require(script.Parent.HexColor)

local DogRigFactory = {}

local BODY_SIZE = Vector3.new(2, 1.6, 3.2)
local HEAD_SIZE = Vector3.new(1.2, 1.1, 1.1)
local LEG_SIZE = Vector3.new(0.4, 1, 0.4)
local TAIL_SIZE = Vector3.new(0.3, 0.3, 1)

-- `massless` should be true for purely decorative welded parts (Head/Tail/Legs) so
-- they don't add unwanted inertia, and false for the root/body — a massless primary
-- collider behaves unpredictably under Roblox's physics (standing on ground,
-- pushing against walls), so the main collidable part needs real mass.
local function newPart(name: string, size: Vector3, color: Color3, canCollide: boolean, massless: boolean): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.CanCollide = canCollide
	part.Massless = massless
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function weld(base: BasePart, attachment: BasePart)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = base
	weldConstraint.Part1 = attachment
	weldConstraint.Parent = base
end

-- Builds a Model that's a valid Roblox Character. Caller is responsible for
-- parenting/positioning it and assigning it to a Player's Character.
function DogRigFactory.Build(breedId: string, coatColorHex: string): Model
	local coatColor = HexColor.ToColor3(coatColorHex)

	local model = Instance.new("Model")
	model.Name = breedId

	-- The body doubles as HumanoidRootPart (visible + collidable) rather than
	-- having a separate invisible root — simplest rig that satisfies the engine's
	-- naming requirement without adding a second physics-relevant part.
	local root = newPart("HumanoidRootPart", BODY_SIZE, coatColor, true, false)
	root.Parent = model
	model.PrimaryPart = root

	local head = newPart("Head", HEAD_SIZE, coatColor, false, true)
	head.CFrame = root.CFrame * CFrame.new(BODY_SIZE.X / 2 + HEAD_SIZE.X / 2, BODY_SIZE.Y * 0.2, 0)
	head.Parent = model
	weld(root, head)

	local tail = newPart("Tail", TAIL_SIZE, coatColor, false, true)
	tail.CFrame = root.CFrame * CFrame.new(-(BODY_SIZE.X / 2 + TAIL_SIZE.Z / 2), BODY_SIZE.Y * 0.2, 0)
	tail.Parent = model
	weld(root, tail)

	local legOffsets = {
		Vector3.new(BODY_SIZE.X / 2 - LEG_SIZE.X, -BODY_SIZE.Y / 2 - LEG_SIZE.Y / 2, BODY_SIZE.Z / 2 - LEG_SIZE.Z),
		Vector3.new(BODY_SIZE.X / 2 - LEG_SIZE.X, -BODY_SIZE.Y / 2 - LEG_SIZE.Y / 2, -(BODY_SIZE.Z / 2 - LEG_SIZE.Z)),
		Vector3.new(-(BODY_SIZE.X / 2 - LEG_SIZE.X), -BODY_SIZE.Y / 2 - LEG_SIZE.Y / 2, BODY_SIZE.Z / 2 - LEG_SIZE.Z),
		Vector3.new(-(BODY_SIZE.X / 2 - LEG_SIZE.X), -BODY_SIZE.Y / 2 - LEG_SIZE.Y / 2, -(BODY_SIZE.Z / 2 - LEG_SIZE.Z)),
	}
	for i, offset in legOffsets do
		local leg = newPart("Leg" .. i, LEG_SIZE, coatColor, false, true)
		leg.CFrame = root.CFrame * CFrame.new(offset)
		leg.Parent = model
		weld(root, leg)
	end

	-- Static welds mean legs don't animate while walking (they'll visibly slide
	-- rather than step) — acceptable for V1, see docs/ROADMAP.md for animation as
	-- future work once a real rig/animation asset exists.

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 20
	humanoid.JumpPower = 40
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	return model
end

return DogRigFactory

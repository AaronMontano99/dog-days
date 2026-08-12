--!strict

-- Converts between a "RRGGBB" hex string (how DogProfile.Appearance.CoatColorHex is
-- persisted — ProfileStore forbids storing Color3 userdata directly, see
-- CLAUDE.md's DogProfile schema) and a Color3 for rendering.

local HexColor = {}

function HexColor.ToColor3(hex: string): Color3
	local clean = hex:gsub("^#", "")
	local r = tonumber(clean:sub(1, 2), 16) or 0
	local g = tonumber(clean:sub(3, 4), 16) or 0
	local b = tonumber(clean:sub(5, 6), 16) or 0
	return Color3.fromRGB(r, g, b)
end

function HexColor.FromColor3(color: Color3): string
	return string.format(
		"%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

return HexColor

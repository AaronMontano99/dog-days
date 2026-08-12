--!strict

-- Per-(player, remote) token bucket. Foundation-level: covers "one client spamming
-- one remote", not cross-remote or cross-account abuse patterns. See docs/SECURITY.md.

local RateLimiter = {}

type Bucket = {
	tokens: number,
	maxCalls: number,
	perSeconds: number,
	lastRefill: number,
}

-- [UserId][remoteName] = Bucket
local buckets: { [number]: { [string]: Bucket } } = {}

function RateLimiter.Allow(userId: number, remoteName: string, maxCalls: number, perSeconds: number): boolean
	local now = os.clock()

	local userBuckets = buckets[userId]
	if userBuckets == nil then
		userBuckets = {}
		buckets[userId] = userBuckets
	end

	local bucket = userBuckets[remoteName]
	if bucket == nil then
		bucket = {
			tokens = maxCalls - 1,
			maxCalls = maxCalls,
			perSeconds = perSeconds,
			lastRefill = now,
		}
		userBuckets[remoteName] = bucket
		return true
	end

	local elapsed = now - bucket.lastRefill
	if elapsed > 0 then
		local refillRate = bucket.maxCalls / bucket.perSeconds
		bucket.tokens = math.min(bucket.maxCalls, bucket.tokens + elapsed * refillRate)
		bucket.lastRefill = now
	end

	if bucket.tokens < 1 then
		return false
	end

	bucket.tokens -= 1
	return true
end

-- Called from PlayerDataService's leave handling so buckets don't leak memory for
-- players who've left the game.
function RateLimiter.ClearPlayer(userId: number)
	buckets[userId] = nil
end

return RateLimiter

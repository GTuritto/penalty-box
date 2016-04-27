local rlKey = KEYS[1]
local tokenKey = KEYS[2]
local epochKey = KEYS[3]
local currentEpoch = tonumber(ARGV[1])
local requestCost = tonumber(ARGV[2])
local rateLimit = ARGV[3]
local keyTimeout = ARGV[4]

-- Ensure that the rate limit keys are set up
redis.call('set', rlKey, rateLimit, 'EX', keyTimeout, 'NX')
redis.call('set', epochKey, currentEpoch, 'EX', keyTimeout, 'NX')
redis.call('setnx', tokenKey, rateLimit)

-- Perform the actual rate limit logic
local returnStatus
local rateLimitPerMinute = tonumber(redis.call('get', rlKey))
local pastEpoch = tonumber(redis.call('get', epochKey))
local epochDiffSec = (currentEpoch - pastEpoch) / 1000

if (epochDiffSec > 60) then
    redis.call('setex', tokenKey, keyTimeout, tostring(rateLimitPerMinute))
    redis.call('setex', epochKey, keyTimeout, tostring(currentEpoch))
end

local currentTokens = tonumber(redis.call('get', tokenKey))

if ((currentTokens <= 0) or (requestCost > currentTokens)) then
    returnStatus = -1
else
    currentTokens = math.max(currentTokens - requestCost, 0)
    redis.call('setex', tokenKey, keyTimeout, tostring(currentTokens))
    returnStatus = 0
end

return {returnStatus, currentTokens}

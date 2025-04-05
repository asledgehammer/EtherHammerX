--- @type fun(minChars: number, maxChars?: number): string
local randomstring = require "asledgehammer/randomstring";

--- @param player IsoPlayer
--- 
--- @return string keyFragment
return function(player)
    return randomstring(32, 48);
end

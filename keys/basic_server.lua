---[[
--- This file is for EtherHammerX.
---
--- This creates the key-fragment for the server-side of EtherHammerX operations.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type fun(minChars: number, maxChars?: number): string
local randomstring = require "asledgehammer/randomstring";

--- @param player IsoPlayer
--- 
--- @return string keyFragment
return function(player)
    return randomstring(32, 48);
end

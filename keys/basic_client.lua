---[[
--- This file is for EtherHammerX.
---
--- This creates the key-fragment for the client-side of EtherHammerX operations.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type fun(minChars: number, maxChars?: number, rand?: Random): string
local randomstring = require "asledgehammer/randomstring";

--- @type Random | nil
local rand = nil;

--- @param player IsoPlayer
---
--- @return string keyFragment
return function(player)
    if not rand then
        -- Synchromize invocation on both server and client.
        rand = newrandom();
        rand:seed(player:getSteamID());
    end
    return randomstring(32, 48, rand);
end

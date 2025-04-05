---[[
--- This file is for ModLoader.
---
--- This whitelist filters what client-requests can retrieve using aliases. Server-side
--- requests can access the entire directory. 
--- 
--- NOTE: To turn the whitelist off, simply delete this file. (Not recommended! Doing so exposes all files in the 
--- folder!)
--- 
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type table<string, string>
return {
    client = 'client.lua',
};

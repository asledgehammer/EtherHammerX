---[[
--- This file is for EtherHammerX.
---
--- The configuration for EtherHammerX anti-cheat framework. All configuation options goes here.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @return EtherHammerXConfiguration
return {
    --- The time (in second(s)) that the client must respond at the time on login.
    ---
    --- @type number
    TIME_TO_GREET = 10,

    --- The time (in second(s)) that the client must respond after a request is sent post-greeting.
    ---
    --- @type number
    TIME_TO_VERIFY = 120,

    --- If true, players are pinged for a new key and verification is done.
    ---
    --- @type boolean
    SHOULD_HEARTBEAT = true,

    --- The time (in second(s)) that the client must respond (At the time of request) periodically.
    ---
    --- @type number
    TIME_TO_HEARTBEAT = 20,

    --- The time (in second(s)) that the player-manager updates.
    ---
    --- @type number
    TIME_TO_TICK = 5,

    --- The key-generation profile to use. All server and client key fragments are calculated and audited using these functions.
    ---
    --- Filename(s) must be consistent:
    --- - `keys/<KEY_ID>_client.lua`
    --- - `keys/<KEY_ID>_server.lua`
    ---
    --- NOTE: In order to audit the client key-fragment against hack-tampering / forging keys, the client key-fragment must be
    --- consistent if ran on both the client and server, otherwise the audit will fail.
    ---
    --- @type string
    KEY = 'basic',

    --- All modules to check for anti-cheats are defined here.
    ---
    --- Filename must be:
    --- - `modules/<MODULE_ID>.lua`
    ---
    --- NOTE: Server-side modules are optional.
    MODULES = {
        etherhack = {
            enable = true,
            name = 'EtherHack',
            options = {
                --- @type boolean
                ---
                --- If true, a ticket is submitted to the admins that the player is hacking.
                SUBMIT_TICKET_ON_KICK = true,
            }
        },
        generic = {
            enable = true,
            name = 'Generic',
            runOnce = true,
            options = {}
        }
    }
};

--- @meta EtherHammerX

---[[
--- This file is for EtherHammerX.
---
--- Use these Lua type-definitions to develop modules and keys for EtherHammerX.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- MARK: General

--- @class EtherHammerXConfiguration
--- @field MODULE_ID string The module ID of EtherHammerX. (NOTE: Leave empty to auto-generate)
--- @field HANDSHAKE_KEY string The handshake-key used for the initial encryption of EtherHammerX. (NOTE: Leave empty to auto-generate)
--- @field HANDSHAKE_REQUEST_COMMAND string The command ID of the request. (NOTE: Leave empty to auto-generate)
--- @field HEARTBEAT_RESPONSE_COMMAND string The command ID of the heartbeat-response. (NOTE: Leave empty to auto-generate)
--- @field HEARTBEAT_REQUEST_COMMAND string The command ID of the heartbeat-request. (NOTE: Leave empty to auto-generate)
--- @field JOIN_RESPONSE_COMMAND string The command ID of the join-response. (NOTE: Leave empty to auto-generate)
--- @field JOIN_REQUEST_COMMAND string The command ID of the join-request. (NOTE: Leave empty to auto-generate)
--- @field TIME_TO_GREET number The time (in second(s)) that the client must respond at the time on login.
--- @field TIME_TO_VERIFY number The time (in second(s)) that the client must respond after a request is sent post-greeting.
--- @field TIME_TO_HEARTBEAT number The time (in second(s)) that the client must respond (At the time of request) periodically.
--- @field TIME_TO_TICK number The time (in second(s)) that the player-manager updates.
--- @field SHOULD_HEARTBEAT boolean If true, players are pinged for a new key and verification is done.
--- @field MODULES table<string, EtherHammerModule> All anti-cheat modules loaded.
--- @field KEY string The key-generation profile ID.

--- MARK: Client

--- @alias EtherHammerXClientModule fun(api: EtherHammerXClientAPI, options: table<string, any>): boolean | nil, string | nil If true, the hack is detected. The 2nd argument passed is the name or identifier of the hack detected.
--- @alias ClientKeyFragmentCallback fun(player: IsoPlayer): string
--- @alias EtherHammerModule {name: string, code: fun(player: IsoPlayer): boolean, runOnce: boolean}

--- @class EtherHammerXClientAPI
local EtherHammerXClientAPI = {};

--- @param author string
--- @param message string
--- @param callback fun(result: boolean): void
---
--- @return void
function EtherHammerXClientAPI.ticketExists(author, message, callback) end

--- Submits a hack ticket & kicks the player from the server.
---
--- @param message string
--- @param callback fun(): void
---
--- @return void
function EtherHammerXClientAPI.submitTicket(message, callback) end

--- Only perform the actual kick here. We want to check and see if a ticket exists first with
--- our message. (This prevents ticket spamming the server)
--- 
--- @return void
function EtherHammerXClientAPI.disconnect() end

--- @return boolean result True if the API call to disconnect the player is invoked.
function EtherHammerXClientAPI.isDisconnected() end

--- Reports the anti-cheat to the server.
---
--- @param type string
--- @param reason string
--- @param disconnect boolean
---
--- @return void
function EtherHammerXClientAPI.report(type, reason, disconnect) end

--- MARK: Server

--- @alias ServerKeyFragmentCallback fun(config: EtherHammerXConfiguration, player: IsoPlayer): string
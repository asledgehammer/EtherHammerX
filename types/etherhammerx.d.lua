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

--- @alias EtherHammerXClientModule fun(api: EtherHammerXClientAPI, options: table<string, any>): void
--- @alias ClientKeyFragmentCallback fun(player: IsoPlayer): string
--- @alias EtherHammerModule {name: string, code: fun(player: IsoPlayer): boolean, runOnce: boolean}

--- @class EtherHammerXClientAPI
local EtherHammerXClientAPI = {};

--- Checks if a ticket with a username and message exists on the server.
--- 
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

--- Reports a cheat to the server.
---
--- @param type string The type of report. (E.G: module, type of hack)
--- @param reason? string (Optional) Additional information provided by the report.
--- @param disconnect? boolean (Optional) If true, the client will disconnect itself. If other actions are desired prior to this call, do not set this to true.
---
--- @return void
function EtherHammerXClientAPI.report(type, reason, disconnect) end

--- @return {globalName: string, typeName: string}[] ClassNames The first string is the `_G[ID]`. The second string is the `class.Type` value.
function EtherHammerXClientAPI.getGlobalClasses() end

--- @return string[] FunctionNames The table names stored as `_G[ID]`.
function EtherHammerXClientAPI.getGlobalTables() end

--- @return string[] FunctionNames The function names stored as `_G[ID]`.
function EtherHammerXClientAPI.getGlobalFunctions() end

--- @param classes? {globalName: string, typeName: string}[] If not provided, the API will fetch them. If provided, the function will execute way faster.
function EtherHammerXClientAPI.printGlobalClasses(classes) end

--- @param tables? string[] If not provided, the API will fetch them. If provided, the function will execute way faster.
function EtherHammerXClientAPI.printGlobalTables(tables) end

--- @param functions? string[] If not provided, the API will fetch them. If provided, the function will execute way faster.
function EtherHammerXClientAPI.printGlobalFunctions(functions) end

--- Checks if an array contains a value.
---
--- @param array string[] The array to check.
--- @param value string The value to check.
--- @return boolean True if one or more values are in the array.
function EtherHammerXClientAPI.arrayContains(array, value) end

--- Checks if one or more values exists in an array.
---
--- @param list string[] The list to test.
--- @param match string[] The list to match.
---
--- @return boolean True if one or more matches.
function EtherHammerXClientAPI.anyExists(list, match) end

--- MARK: Server

--- @alias ServerKeyFragmentCallback fun(config: EtherHammerXConfiguration, player: IsoPlayer): string

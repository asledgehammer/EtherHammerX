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
--- @field module_id string The module ID of EtherHammerX. (NOTE: Leave empty to auto-generate)
--- @field time_to_greet number The time (in second(s)) that the client must respond at the time on login.
--- @field time_to_verify number The time (in second(s)) that the client must respond after a request is sent post-greeting.
--- @field time_to_heartbeat number The time (in second(s)) that the client must respond (At the time of request) periodically.
--- @field time_to_tick number The time (in second(s)) that the player-manager updates.
--- @field should_heartbeat boolean If true, players are pinged for a new key and verification is done.
--- @field modules table<string, EtherHammerModule> All anti-cheat modules loaded.
--- @field key string The key-generation profile ID.

--- MARK: Client

--- @alias EtherHammerXClientModule fun(api: EtherHammerXClientAPI, options: table<string, any>): void
--- @alias ClientKeyFragmentCallback fun(player: IsoPlayer): string
--- @alias EtherHammerModule {name: string, code: fun(player: IsoPlayer): boolean, runOnce: boolean}
--- @alias ReportAction 'kick' | 'log'

--- @class EtherHammerXClientAPI
local EtherHammerXClientAPI = {};

--- Checks if a ticket with a username and message exists on the server.
---
--- @param author string
--- @param message string
--- @param callback fun(result: boolean): void
function EtherHammerXClientAPI.ticketExists(author, message, callback) end

--- Submits a ticket to the server.
---
--- @param message string The text-body content of the ticket.
--- @param callback? fun(): void (Optional) Invoked after a ticket is submitted.
function EtherHammerXClientAPI.submitTicket(message, callback) end

--- Only perform the actual kick here. We want to check and see if a ticket exists first with
--- our message. (This prevents ticket spamming the server)
function EtherHammerXClientAPI.disconnect() end

--- @return boolean result True if the API call to disconnect the player is invoked.
function EtherHammerXClientAPI.isDisconnected() end

--- Reports a cheat to the server.
---
--- @param type string The type of report. (E.G: module, type of hack)
--- @param reason string Additional information provided by the report.
--- @param action ReportAction The action to take.
function EtherHammerXClientAPI.report(type, reason, action) end

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
--- 
--- @return boolean True if one or more values are in the array.
function EtherHammerXClientAPI.arrayContains(array, value) end

--- Checks if one or more values exists in an array.
---
--- @param list string[] The list to test.
--- @param match string[] The list to match.
---
--- @return boolean True if one or more matches.
function EtherHammerXClientAPI.anyExists(list, match) end

--- Grabs the server's information for the player. This is to make sure that the info is genuine. Cheater clientc can
--- modify and compromise the client's information on the player being a staff member, etc.
---
--- @param callback ServerPlayerInfoCallback The callback that is invoked when the server responds with the player's information
function EtherHammerXClientAPI.getServerPlayerInfo(callback) end

--- MARK: Server

--- @alias ServerPlayerInfo { steamID: number, onlineID: number, username: string, accessLevel: string, position: {x: number, y: number, z: number} }
--- @alias ServerPlayerInfoCallback fun(info: ServerPlayerInfo): void
--- @alias ServerKeyFragmentCallback fun(config: EtherHammerXConfiguration, player: IsoPlayer): string

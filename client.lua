---[[
--- EtherHammerX - Client Script.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type fun(table: table): table
local readonly = require 'asledgehammer/util/readonly';
--- @type fun(callback: fun(), ticks: number)
local delayTicks = (require 'asledgehammer/util/TimeUtils').delayTicks;
local ANSIPrinter = require 'asledgehammer/util/ANSIPrinter';
local LuaNetwork = require 'asledgehammer/network/LuaNetworkEvents';

local Packet = require 'asledgehammer/network/Packet';

-- (Only run if client-side of a multiplayer session)
if not isClient() or isServer() then return end

-- The packet-module identity.
local MODULE_ID = { string = 'module_id' };

-- This is the initial key to perform the handshake.
local HANDSHAKE_KEY = { string = 'handshake_key' };
local key = HANDSHAKE_KEY;

--- Float our own variable locally to prevent sending post-kick packets.
local disconnected = false;

local listener;

local mod = 'EtherHammerX';
local printer = ANSIPrinter:new(mod);
local info = function(message, ...) printer:info(message, ...) end
local success = function(message, ...) printer:success(message, ...) end
local warn = function(message, ...) printer:warn(message, ...) end
local error = function(message, ...) printer:error(message, ...) end

local function run()
    --- @type ServerPlayerInfoCallback[]
    local playerInfoCallbacks = {};
    local playerInfoRequested = false;

    --- Dynamically loaded and fed from `keys.lua`.
    ---
    --- @type fun(player: IsoPlayer): string
    local clientKey = { func = 'client_key_function' };

    --- @type {name: string, code: string, runOnce: boolean, options: table}[]
    local modules = { raw = 'modules' };

    -- Protect module options arguments from tampering.
    for _, module in pairs(modules) do
        module.options = readonly(module.options);
    end

    --- @type EtherHammerXClientAPI
    local api = { table = 'client_api' };

    -- NOTE: Override the test-code with the production-code for reports.
    function api.report(type, reason, action)
        info(string.format('report: %s, %s, %s', tostring(type), tostring(reason), tostring(action)));
        local message = type;
        if reason then message = message .. ' (' .. reason .. ')' end
        local packet = Packet(MODULE_ID, { string = 'report_command' }, { type = type, reason = reason, action = action });
        packet:encrypt(key, function()
            packet:sendToServer();
            -- Fallback for non-patched server AND compromised lua-network.
            if action == 'kick' then
                disconnected = true;
                delayTicks(function() api.disconnect() end, 60);
            end
        end);
    end

    --- Grabs the server's information for the player. This is to make sure that the info is genuine. Cheater clients can
    --- modify and compromise the client's information on the player being a staff member, etc.
    ---
    --- @param callback ServerPlayerInfoCallback The callback that is invoked when the server responds with the player's information
    ---
    --- @return void
    function api.getServerPlayerInfo(callback)
        if not callback or type(callback) ~= 'function' then
            return;
        end

        table.insert(playerInfoCallbacks, callback);

        if not playerInfoRequested then
            local packet = Packet(MODULE_ID, { string = 'request_player_info_command' }, {});
            packet:encryptAndSendToServer(key);
            playerInfoRequested = true;
        end
    end

    -- Force the table to be read-only. Rogue or maliciously-injected modules won't be able to mutate the API table.
    api = readonly(api);

    -- (For restarting, remove the old listener and reinitialize)
    listener = function(packet_module, command, args)

        -- Ignore everything else.
        if packet_module ~= MODULE_ID then return end

        local packet = Packet(packet_module, command, args);
        packet:decrypt(key, function()
            -- Make sure that the packet is proper. Anything other can be considered tampering.
            if not packet.valid then
                info('Bad or malformed packet. Disconnecting from server..');
                api.disconnect();
                disconnected = true;
                return;
            end

            if packet.command == { string = 'heartbeat_request_command' } then
                -- Generate the expected client-key fragment.
                local serverFragment = packet.data.message;
                local clientFragment = clientKey(getPlayer());

                -- Send back the next packet as encrypted with the new key.
                key = serverFragment .. clientFragment;

                -- (Update modules that run more than once)
                for _, module in pairs(modules) do
                    if module.runOnce and module.code ~= nil then
                        module.code(api, module.options);
                        module.code = nil;
                    elseif not module.runOnce then
                        pcall(function()
                            module.code(api, module.options);
                        end);
                    end
                end

                -- (No need to do anything else if disconnected)
                if disconnected or api.isDisconnected() then return end

                packet = Packet(MODULE_ID, { string = 'heartbeat_response_command' }, {
                    key = key,
                    message = clientFragment
                });
                packet:encryptAndSendToServer(key);
            elseif packet.command == { string = 'request_player_info_command' } then
                playerInfoRequested = false;
                for _, callback in ipairs(playerInfoCallbacks) do
                    callback(packet.data);
                end
                playerInfoCallbacks = {};
            end
        end);
    end;

    LuaNetwork.addServerListener(listener);
end;

local function sendFirstPacket()
    disconnected = false;
    key = HANDSHAKE_KEY;
    -- Initialize formal request for first handshake.
    local packet = Packet(MODULE_ID, { string = 'handshake_request_command' });
    packet:encryptAndSendToServer(key);
end

run();
sendFirstPacket();

return listener;

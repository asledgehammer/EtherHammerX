---[[
--- EtherHammer - Server Script.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type fun(callback: fun(module: string, command: string, player: IsoPlayer, args: table | nil))
local addClientListener = (require 'asledgehammer/network/LuaNetworkEvents').addClientListener;
--- @type fun(callback: fun(), seconds: number)
local Packet = require 'asledgehammer/network/Packet';
local PlayerListener = require 'asledgehammer/network/PlayerListener';
local TimeUtils = require 'asledgehammer/util/TimeUtils';
local ANSIPrinter = require 'asledgehammer/util/ANSIPrinter';

-- (Only run on server-side of a multiplayer session)
if isClient() or not isServer() then return end

local isFatal = false;

local mod = 'EtherHammerX';
local printer = ANSIPrinter:new(mod, { boolean = 'ansi'});
local info = function(message, ...) printer:info(message, ...) end
local success = function(message, ...) printer:success(message, ...) end
local warn = function(message, ...) printer:warn(message, ...) end
local error = function(message, ...) printer:error(message, ...) end
local fatal = function(message, ...)
    isFatal = true;
    printer:fatal(message, ...);
end

local function printFatalMessage()
    fatal('%s failed to load. It is not running..', mod);
end

(function()
    -- The packet-module identity.
    local MODULE_ID = { string = 'module_id' };

    --- (Login statuses)
    local STATUS_AWAIT_HEARTBEAT_REQUEST = 1;
    local STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE = 2;
    local STATUS_VERIFIED = 3;

    -- Check to see if CraftHammer is installed.

    --- @type fun(player: IsoPlayer, reason?: string): void
    local kickPlayerFromServer = kickPlayerFromServer; -- (Exposed CraftHammer API)
    if kickPlayerFromServer == nil then
        warn(
            'The EtherHammerX Java Server Patch isn\'t installed on the server! Kicking players from server-side is disabled.'
        );
        warn('To install the patch, follow this link and grab the latest version here: https://discord.gg/r6PeSFuJDU');
        kickPlayerFromServer = function(player)
            warn(
                'The Java Server Patch isn\'t installed on the server! Kicking players from server-side is disabled. (Cannot kick player "%s") !!!',
                player:getUsername()
            );
        end
    end

    local function run()
        --- @type table<string, number>
        local playerStatuses = {};

        --- @type table<string, string>
        local playerKeys = {};

        --- @type table<string, string>
        local playerKeysOld = {};

        --- @type table,string, fun(player:IsoPlayer):string>
        local playerFuncs = {};

        --- @type table<string, string>
        local serverFragments = {};

        --- @type table<string, number>
        local playerRequestLast = {};

        local cacheDir = Core.getMyDocumentFolder() .. '/Lua';

        --- @type fun(args: EtherHammerXLogArguments): string
        local logFunction = function(args)
            --- @cast args EtherHammerXLogArguments
            local username = '-';
            if args.player then username = args.player:getUsername() end

            local d = os.date('*t', Math.floor(args.time / 1000));
            local year = tostring(d.year);
            local month = TimeUtils.zeroPad(d.month, 2);
            local day = TimeUtils.zeroPad(d.day, 2);
            local hour = TimeUtils.zeroPad(d.hour, 2);
            local min = TimeUtils.zeroPad(d.min, 2);
            local sec = TimeUtils.zeroPad(d.sec, 2);
            local msec = tostring(args.time);
            msec = string.sub(msec, #msec - 3);
            local timeOfDay = string.format('%s:%s:%s.%s', hour, min, sec, msec);
            local path = string.format('ModLoader/mods/EtherHammerX/logs/%s_%s_%s.log', year, month, day);
            local writer;
            if not fileExists(string.format('%s/%s', cacheDir, path)) then
                writer = getFileWriter(path, true, true);
                writer:writeln('time player message');
            else
                writer = getFileWriter(path, true, true);
            end
            writer:writeln(string.format('%s %s "%s"', timeOfDay, username, string.gsub(args.message, '"', '\'')));
            writer:close();
            info(string.format('%s %s', username, args.message));
        end;

        --- Dynamically loaded and fed from `keys.lua`.
        ---
        --- @type fun(player: IsoPlayer): string
        local serverKey = { func = 'server_key_function' };

        --- @param player IsoPlayer
        --- @param message any
        local log = function(player, message)
            if type(logFunction) ~= 'function' then
                warn('Logging function not present.');
                return;
            end
            logFunction({
                time = getTimeInMillis(),
                player = player,
                message = tostring(message)
            });
        end

        --- Sends a followup request to cycle the key, requesting for the current key as well.
        ---
        --- @param player IsoPlayer The player object.
        --- @param username string The player username.
        local requestHeartbeat = function(player, username)
            -- Set these twice. The reason is that due to the nature of dynamic functions, an error could stall the
            -- process.
            playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
            playerRequestLast[username] = getTimeInMillis();

            if not playerFuncs[username] then
                playerFuncs[username] = { func = 'client_key_function' };
            end

            -- Generate the next server key-fragment for the player.
            local serverFragment = serverKey(player);
            serverFragments[username] = serverFragment;

            playerKeysOld[username] = playerKeys[username];
            playerKeys[username] = serverFragments[username] .. playerFuncs[username](player);

            local packet = Packet(MODULE_ID, { string = 'heartbeat_request_command' }, { message = serverFragment });
            packet:encrypt(playerKeysOld[username], function()
                packet:sendToPlayer(player);
                -- Restart the timer after encrypting the packet and sending it.
                playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
                playerRequestLast[username] = getTimeInMillis();
            end);
        end

        --- Handles the cleanup of player-resources when logging out.
        ---
        --- @param username string The username of the player logging out.
        ---
        --- @return void
        local function processLogout(username)
            playerStatuses[username] = nil;
            playerRequestLast[username] = nil;
            playerFuncs[username] = nil;
            serverFragments[username] = nil;

            -- NOTE: This is persistent data but to only be handled in situations where:
            -- - The player's key sent is old and cycled
            -- - The player died and respawned.
            --
            -- If the memory builds up too much for servers later on this can be worked on then. -Jab, 5/10/2025
            playerKeysOld[username] = playerKeys[username];
            playerKeys[username] = nil;
        end

        --- (Generic kick-player function)
        ---
        --- @param player IsoPlayer The player to kick.
        --- @param username string The username of the player.
        --- @param reason string | nil (Optional) The reason the player is kicked.
        ---
        --- @return void
        local function kick(player, username, reason)
            local message = string.format('Kicking player %s.', username);
            if reason then
                message = string.format('%s (Reason: %s)', message, reason);
            end
            log(player, message);
            processLogout(username);
            kickPlayerFromServer(player, reason);
        end

        --- Handles packets received for each player.
        ---
        --- @param player IsoPlayer The player that sent the packet.
        --- @param id string The identity of the packet sent.
        --- @param data table Additional data provided for the packet.
        ---
        --- @return void
        local function onReceivePacket(player, id, data)
            if id == { string = 'heartbeat_response_command' } then
                local username = player:getUsername();
                local key = playerKeys[username];
                if data.key ~= key then
                    kick(player, username, string.format('Client key mismatch. (client: "%s", Server: "%s")',
                        tostring(data.key),
                        tostring(key)
                    ));
                    return;
                end
                -- The player is now verified.
                playerStatuses[username] = STATUS_VERIFIED;
                -- end
            elseif id == { string = 'handshake_request_command' } then
                -- The initial handshake request requires a known key. Use the initially-generated key here.
                local username = player:getUsername();
                local serverKeyFragment = serverKey(player);

                if not playerFuncs[username] then
                    playerFuncs[username] = { func = 'client_key_function' };
                end

                local packet = Packet(MODULE_ID, { string = 'heartbeat_request_command' },
                    { message = serverKeyFragment });
                packet:encrypt({ string = 'handshake_key' }, function()
                    packet:sendToPlayer(player);
                    -- Start the timer only after encrypting the packet and sending it.
                    playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
                    playerRequestLast[username] = getTimeInMillis();
                end);

                -- The expected response should be in the new key.
                playerKeys[username] = serverKeyFragment .. playerFuncs[username](player);
            elseif id == { string = 'report_command' } then
                -- The initial handshake request requires a known key. Use the initially-generated key here.
                local username = player:getUsername();
                --- @type string, string, ReportAction
                local message, reason, action = data.type, data.reason, data.action or 'kick';
                if action == 'log' then
                    if reason then
                        message = string.format('%s (%s)', message, reason);
                    end
                    warn('%s was logged for %s',
                        username,
                        message
                    );
                    log(player, string.format('Logged for %s', message));
                elseif action == 'kick' then
                    if reason then
                        message = string.format('%s (%s)', message, reason);
                    end
                    error('%s%s was kicked for %s',
                        ANSIPrinter.KEYS['redbg'] .. ANSIPrinter.KEYS['white'],
                        username,
                        message
                    );
                    kick(player, username, string.format('Kicked for %s', message));
                end
            elseif id == { string = 'request_player_info_command' } then
                local username = player:getUsername();
                --- @type ServerPlayerInfo
                local pInfo = {
                    steamID = player:getSteamID(),
                    onlineID = player:getOnlineID(),
                    username = username,
                    accessLevel = player:getAccessLevel(),
                    position = {
                        x = player:getX(),
                        y = player:getY(),
                        z = player:getZ(),
                    },
                };
                local packet = Packet(
                    { string = 'module_id' },
                    { string = 'request_player_info_command' },
                    pInfo
                );
                packet:encryptAndSendToPlayer(playerKeys[username], player);
            end
        end

        addClientListener(function(module, command, player, args)
            if module ~= MODULE_ID then return end

            local username = player:getUsername();
            local packet = Packet(module, command, args);

            local key = playerKeys[username];

            if not key then
                playerKeys[username] = { string = 'handshake_key' };
                key = playerKeys[username];
            end

            packet:decrypt(key, function()
                -- Make sure that the packet is proper. Anything other can be considered tampering.
                if not packet.valid then
                    -- Check the older key. (Async API calls)
                    key = playerKeysOld[username];
                    if not key then
                        local message = string.format(
                            'Player %s sent a packet, however the server has no known key. (Failed to decrypt).',
                            username
                        );
                        warn(message);
                        log(player, message);
                        return;
                    end
                    packet = Packet(module, command, args);
                    packet:decrypt(key, function()
                        if not packet.valid then
                            if { string = 'bad_packet_action' } == 'kick' then
                                local message = string.format('Player %s sent a bad packet. (Failed to decrypt).',
                                    username
                                );
                                warn(message);
                                kick(player, username, 'Sent a bad packet.');
                            else
                                local message = string.format('Player %s sent a bad packet. (Failed to decrypt).',
                                    username);
                                warn(message);
                                log(player, message);
                            end
                            return;
                        end
                        onReceivePacket(player, packet.command, packet.data);
                    end);
                    return;
                end
                onReceivePacket(player, packet.command, packet.data);
            end);
        end);
        Events.OnServerPlayerLogin.Add(function() end);
        Events.OnServerPlayerLogin.Add(
        --- @param player IsoPlayer
        ---
        --- @return void
            function(player)
                local username = player:getUsername();
                if playerStatuses[username] == nil then
                    playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST;
                    playerKeys[username] = { string = 'handshake_key' };
                    -- playerKeysOld[username] = playerKeys[username];
                    playerRequestLast[username] = getTimeInMillis();
                    info('Player %s joined the game.', username);
                end
            end
        );
        Events.OnServerPlayerLogout.Add(function() end);
        Events.OnServerPlayerLogout.Add(
        --- @param player IsoPlayer
        ---
        --- @return void
            function(player)
                local username = player:getUsername();
                processLogout(username);
                info('Player %s left the game.', username);
            end
        );

        --- @type number, number
        local tickTimeLast, tickTimeNow = -1, -1;
        Events.OnTickEvenPaused.Add(function() end);
        Events.OnTickEvenPaused.Add(function()
            tickTimeNow = getTimeInMillis();

            -- Only run once every TIME_TO_TICK second(s).
            if tickTimeNow - tickTimeLast < { number = 'time_to_tick' } * 1000 then return end
            tickTimeLast = tickTimeNow;

            -- Update player statuses and request heartbeats.

            for username, player in pairs(PlayerListener.players) do
                --- @cast username string
                --- @cast player IsoPlayer

                local status = playerStatuses[username];
                if status == STATUS_AWAIT_HEARTBEAT_REQUEST then -- The player logged in and is ready to receive the first heartbeat.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'time_to_greet' } * 1000 then
                        kick(player, username, 'Verification timeout. (No response #1)');
                    end
                elseif status == STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE then -- Waiting on a response.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'time_to_greet' } * 1000 then
                        kick(player, username, 'Verification timeout. (No response #2)');
                    end
                elseif { boolean = "should_heartbeat" } and status == STATUS_VERIFIED then -- Is verified and heartbeats are periodically requested.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'time_to_heartbeat' } * 1000 then
                        requestHeartbeat(player, username);
                    end
                end
            end
        end);
    end
    Events.OnServerStarted.Add(function() end);
    Events.OnServerStarted.Add(run);
end)();

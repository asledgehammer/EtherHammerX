local ModLoader = require 'asledgehammer/modloader/ModLoader';
local ZedCrypt = require 'asledgehammer/encryption/ZedCrypt';

(function()

    local ticks = 0;

    --- @type fun(): void | nil
    local onGameStart = nil;
    onGameStart = function()
    
        if ticks < 5 then
            ticks = ticks + 1;
            return;
        end
    
        Events.OnTickEvenPaused.Remove(onGameStart);

        ModLoader.requestServerFile('etherhammer', 'EtherHammer_Client.lua', true, function(module, path, result, data)
            
            if result == ModLoader.RESULT_FILE_NOT_FOUND then
                print('[ModLoader] :: File not found: module=' .. module .. ', path=' .. path);
                return;
            end

            print('[EtherHammer] :: Unpacking..');
            local timeThen = getTimeInMillis();
            local decryptedData = ZedCrypt.decrypt(data, 'EtherHammer');
            local delta = getTimeInMillis() - timeThen;
            print('[EtherHammer] :: Unpacked in ' .. delta .. ' ms.');

            pcall(function()
                loadstring(decryptedData)();
            end);
            
        end);
    
    end
    
    Events.OnTickEvenPaused.Add(onGameStart);

end)();

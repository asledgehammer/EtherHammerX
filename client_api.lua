---[[
--- EtherHammerX - Client API. Import this separately to test module development.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

local API = {
    disconnected = false,
};

--- @return boolean result True if the API call to disconnect the player is invoked.
function API.isDisconnected()
    return API.disconnected;
end

--- Only perform the actual kick here. We want to check and see if a ticket exists first with
--- our message. (This prevents ticket spamming the server)
---
--- @return void
function API.disconnect()
    API.disconnected = true;
    setGameSpeed(1);
    pauseSoundAndMusic();
    setShowPausedMessage(true);
    getCore():quit();
end

--- @return {globalName: string, typeName: string}[] ClassNames The first string is the `_G[ID]`. The second string is the `class.Type` value.
function API.getGlobalClasses()
    local array = {};
    for name, value in pairs(_G) do
        if type(value) == 'table' and value.Type ~= nil then
            -- [global reference name, pseudo-class type name]
            table.insert(array, { globalName = name, typeName = value.Type });
        end
    end
    table.sort(array, function(a, b) return a.globalName < b.globalName end);
    return array;
end

--- @return string[] FunctionNames The table names stored as `_G[ID]`.
function API.getGlobalTables()
    local array = {};
    for name, value in pairs(_G) do
        if type(value) == 'table' then
            -- [global reference name, pseudo-class type name]
            table.insert(array, name);
        end
    end
    table.sort(array, function(a, b) return a:upper() < b:upper() end);
    return array;
end

--- @return string[] FunctionNames The function names stored as `_G[ID]`.
function API.getGlobalFunctions()
    local array = {};
    for name, value in pairs(_G) do
        -- Java API:
        --     'function <memory address>'
        -- Lua API:
        --     'closure <memory address>'
        if type(value) == 'function' and string.find(tostring(value), 'function ') == 1 then
            table.insert(array, name);
        end
    end
    table.sort(array, function(a, b) return a:upper() < b:upper() end);
    return array;
end

--- Checks if an array contains a value.
---
--- @param array string[] The array to check.
--- @param value string The value to check.
---
--- @return boolean True if one or more values are in the array.
function API.arrayContains(array, value)
    for _, next in ipairs(array) do if value == next then return true end end
    return false
end

--- Checks if one or more values exists in an array.
---
--- @param list string[] The list to test.
--- @param match string[] The list to match.
---
--- @return boolean True if one or more matches.
function API.anyExists(list, match)
    for i = 1, #match do if API.arrayContains(list, match[i]) then return true end end
    return false;
end

function API.printGlobalClasses(classes)
    classes = classes or API.getGlobalClasses();
    local s = 'Global Class(es) (' .. tostring(#classes) .. '):\n';
    for _, names in ipairs(classes) do
        s = s .. '\t' .. tostring(names.globalName) .. ' (class.Type = ' .. tostring(names.typeName) .. ')\n';
    end
    print(s);
end

function API.printGlobalTables(tables)
    tables = tables or API.getGlobalTables();
    local s = 'Global Table(s) (' .. tostring(#tables) .. '):\n';
    for _, name in ipairs(tables) do
        s = s .. '\t' .. tostring(name) .. '\n';
    end
    print(s);
end

function API.printGlobalFunctions(funcs)
    funcs = funcs or API.getGlobalFunctions();
    local s = 'Global function(s) (' .. tostring(#funcs) .. '):\n';
    for _, funcName in ipairs(funcs) do
        s = s .. '\t' .. tostring(funcName) .. '\n';
    end
    print(s);
end

--- Checks if a ticket with a username and message exists on the server.
---
--- @param author string
--- @param message string
--- @param callback fun(result: boolean): void
---
--- @return void
function API.ticketExists(author, message, callback)
    local __f = function() end
    --- Add and Remove the ticket checker after checking for a pre-existing hack message.
    --- @param tickets ArrayList<DBTicket>
    __f = function(tickets)
        -- Execute only once.
        Events.ViewTickets.Remove(__f);
        local length = tickets:size() - 1;
        for i = 0, length do
            --- @type DBTicket
            local ticket = tickets:get(i);
            if ticket:getAuthor() == author and message == ticket:getMessage() then
                callback(true);
                return;
            end
        end
        callback(false);
    end
    Events.ViewTickets.Add(__f);
    getTickets(author);
end

--- Submits a hack ticket & kicks the player from the server.
---
--- @param message string
--- @param callback fun(): void
---
--- @return void
function API.submitTicket(message, callback)
    local player = getPlayer();
    local username = player:getUsername();
    API.ticketExists(username, message, function(exists)
        if not exists then
            addTicket(username, message, -1);
        end
        callback();
    end);
end

-- NOTE: Debug or test version. The client code overrides this with the production version.
function API.report(type, reason, disconnect)
    local message = tostring(type);
    if reason then message = message .. ' (' .. tostring(reason) .. ')' end
    print('[EtherHammerX] :: ' .. message);
    if disconnect then API.disconnect() end
end

-- Force the table to be read-only. Rogue or maliciously-injected modules won't be able to mutate the API table.
return API;

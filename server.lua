local playerInventories = {}
local droppedItems = {}
local dropId = 0

-- Database per gli inventari dei giocatori (in un vero server useresti un database)
local playerInventories = {}

-- Funzione per ottenere l'inventario di un giocatore
local function getPlayerInventory(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not playerInventories[identifier] then
        playerInventories[identifier] = {}
    end
    return playerInventories[identifier]
end

-- Funzione per salvare l'inventario (placeholder - implementa con il tuo database)
local function savePlayerInventory(source, inventory)
    local identifier = GetPlayerIdentifier(source, 0)
    playerInventories[identifier] = inventory
    -- Qui dovresti salvare nel database
end

RegisterCommand('giveitem', function(source, args)
    local name = args[1]
    local count = tonumber(args[2]) or 1

    if not name then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Uso: /giveitem [name] [count]"}
        })
        return
    end

    local inventory = getPlayerInventory(source)

    -- Aggiungi l'item all'inventario
    inventory[name] = (inventory[name] or 0) + count

    -- Salva l'inventario
    savePlayerInventory(source, inventory)

    -- Invia al client
    TriggerClientEvent('inventory:addItem', source, name, count)

    -- Messaggio di conferma
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Ricevuto %s x%d"):format(name, count)}
    })
end, false)

RegisterCommand('giveitemto', function(source, args)
    local targetId = tonumber(args[1])
    local name = args[2]
    local count = tonumber(args[3]) or 1

    if not targetId or not name then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Uso: /giveitemto [id] [name] [count]"}
        })
        return
    end

    local targetInventory = getPlayerInventory(targetId)

    -- Aggiungi l'item all'inventario del target
    targetInventory[name] = (targetInventory[name] or 0) + count

    -- Salva l'inventario del target
    savePlayerInventory(targetId, targetInventory)

    -- Invia al client target
    TriggerClientEvent('inventory:addItem', targetId, name, count)

    -- Messaggi di conferma
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Dato %s x%d al giocatore %d"):format(name, count, targetId)}
    })

    TriggerClientEvent('chat:addMessage', targetId, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Ricevuto %s x%d"):format(name, count)}
    })
end, false)

-- Event per usare un item
RegisterNetEvent('inventory:useItem', function(itemName)
    local source = source
    local inventory = getPlayerInventory(source)
    
    if inventory[itemName] and inventory[itemName] > 0 then
        -- Rimuovi l'item dall'inventario
        inventory[itemName] = inventory[itemName] - 1
        if inventory[itemName] == 0 then
            inventory[itemName] = nil
        end
        
        -- Salva l'inventario
        savePlayerInventory(source, inventory)
        
        -- Aggiorna il client
        TriggerClientEvent('inventory:removeItem', source, itemName, count)

        -- Crea un prop nel mondo di gioco alla posizione del giocatore
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        dropId = dropId + 1
        droppedItems[dropId] = { item = itemName, count = count }
        TriggerClientEvent('inventory:spawnDroppedItem', -1, dropId, itemName, count, { x = coords.x, y = coords.y, z = coords.z })

        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 165, 0},
            multiline = false,
            args = {"Sistema", ("Hai droppato: %s x%d"):format(itemName, count)}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Non hai abbastanza di questo item!"}
        })
    end
end)

-- Event per raccogliere un item dal terreno
RegisterNetEvent('inventory:pickupFromGround', function(itemName, count)
    local source = source
    local inventory = getPlayerInventory(source)

    inventory[itemName] = (inventory[itemName] or 0) + count
    savePlayerInventory(source, inventory)

    TriggerClientEvent('inventory:addItem', source, itemName, count)
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Hai raccolto: %s x%d"):format(itemName, count)}
    })
end)

-- Pickup tramite prop a terra
RegisterNetEvent('inventory:pickupDroppedItem', function(id)
    local source = source
    local drop = droppedItems[id]
    if not drop then return end

    droppedItems[id] = nil

    local inventory = getPlayerInventory(source)
    inventory[drop.item] = (inventory[drop.item] or 0) + drop.count
    savePlayerInventory(source, inventory)

    TriggerClientEvent('inventory:addItem', source, drop.item, drop.count)
    TriggerClientEvent('inventory:removeDroppedItem', -1, id)

    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Hai raccolto: %s x%d"):format(drop.item, drop.count)}
    })
end)

-- Event per droppare un item
RegisterNetEvent('inventory:dropItem', function(itemName, count)
    local source = source
    local inventory = getPlayerInventory(source)
    
    if inventory[itemName] and inventory[itemName] >= count then
        -- Rimuovi l'item dall'inventario
        inventory[itemName] = inventory[itemName] - count
        if inventory[itemName] == 0 then
            inventory[itemName] = nil
        end
        
        -- Salva l'inventario
        savePlayerInventory(source, inventory)
        
        -- Aggiorna il client
        TriggerClientEvent('inventory:removeItem', source, itemName, count)

        -- Crea un prop nel mondo di gioco alla posizione del giocatore
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        TriggerClientEvent('inventory:spawnDroppedItem', -1, itemName, count, { x = coords.x, y = coords.y, z = coords.z })

        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 165, 0},
            multiline = false,
            args = {"Sistema", ("Hai droppato: %s x%d"):format(itemName, count)}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Non hai abbastanza di questo item!"}
        })
    end
end)

-- Event per raccogliere un item dal terreno
RegisterNetEvent('inventory:pickupFromGround', function(itemName, count)
    local source = source
    local inventory = getPlayerInventory(source)

    inventory[itemName] = (inventory[itemName] or 0) + count
    savePlayerInventory(source, inventory)

    TriggerClientEvent('inventory:addItem', source, itemName, count)
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Hai raccolto: %s x%d"):format(itemName, count)}
    })
end)

-- Event per dare un item ad un altro giocatore
RegisterNetEvent('inventory:giveItem', function(itemName, count, targetId)
    local source = source
    local inventory = getPlayerInventory(source)
    
    if inventory[itemName] and inventory[itemName] >= count then
        local targetInventory = getPlayerInventory(targetId)
        
        -- Rimuovi dall'inventario del mittente
        inventory[itemName] = inventory[itemName] - count
        if inventory[itemName] == 0 then
            inventory[itemName] = nil
        end
        
        -- Aggiungi all'inventario del ricevente
        targetInventory[itemName] = (targetInventory[itemName] or 0) + count
        
        -- Salva entrambi gli inventari
        savePlayerInventory(source, inventory)
        savePlayerInventory(targetId, targetInventory)
        
        -- Aggiorna entrambi i client
        TriggerClientEvent('inventory:removeItem', source, itemName, count)
        TriggerClientEvent('inventory:addItem', targetId, itemName, count)
        
        -- Messaggi di conferma
        TriggerClientEvent('chat:addMessage', source, {
            color = {0, 255, 0},
            multiline = false,
            args = {"Sistema", ("Hai dato %s x%d al giocatore %d"):format(itemName, count, targetId)}
        })
        
        TriggerClientEvent('chat:addMessage', targetId, {
            color = {0, 255, 0},
            multiline = false,
            args = {"Sistema", ("Hai ricevuto %s x%d dal giocatore %d"):format(itemName, count, source)}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Non hai abbastanza di questo item!"}
        })
    end
end)

-- Funzione per gestire l'uso degli items (personalizza in base ai tuoi needs)
function useItem(source, itemName)
    -- Esempi di utilizzo items
    if itemName == "medkit" then
        -- Cura il giocatore
        TriggerClientEvent('inventory:healPlayer', source)
    elseif itemName == "water" then
        -- Disseta il giocatore
        TriggerClientEvent('inventory:drinkWater', source)
    elseif itemName == "food" then
        -- Nutri il giocatore
        TriggerClientEvent('inventory:eatFood', source)
    end
    -- Aggiungi altri items qui
end

-- Event per quando un giocatore si connette
AddEventHandler('playerConnecting', function()
    local source = source
    -- Carica l'inventario dal database
    -- loadPlayerInventory(source)
end)

-- Event per quando un giocatore si disconnette
AddEventHandler('playerDropped', function()
    local source = source
    -- Salva l'inventario nel database
    -- savePlayerInventory(source)
end)
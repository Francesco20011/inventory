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

-- Comando per dare items
lib.addCommand('giveitem', {
    help = 'Dai un item a te stesso',
    params = {
        {name = 'name', type = 'string', help = 'Nome dell\'item'},
        {name = 'count', type = 'number', default = 1, help = 'Quantità'}
    }
}, function(source, args)
    local inventory = getPlayerInventory(source)
    
    -- Aggiungi l'item all'inventario
    inventory[args.name] = (inventory[args.name] or 0) + args.count
    
    -- Salva l'inventario
    savePlayerInventory(source, inventory)
    
    -- Invia al client
    TriggerClientEvent('minimal_inventory:addItem', source, args.name, args.count)
    
    -- Messaggio di conferma
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Ricevuto %s x%d"):format(args.name, args.count)}
    })
end)

-- Comando per dare item ad un altro giocatore
lib.addCommand('giveitemto', {
    help = 'Dai un item ad un altro giocatore',
    params = {
        {name = 'id', type = 'playerId', help = 'ID del giocatore'},
        {name = 'name', type = 'string', help = 'Nome dell\'item'},
        {name = 'count', type = 'number', default = 1, help = 'Quantità'}
    }
}, function(source, args)
    local targetInventory = getPlayerInventory(args.id)
    
    -- Aggiungi l'item all'inventario del target
    targetInventory[args.name] = (targetInventory[args.name] or 0) + args.count
    
    -- Salva l'inventario del target
    savePlayerInventory(args.id, targetInventory)
    
    -- Invia al client target
    TriggerClientEvent('minimal_inventory:addItem', args.id, args.name, args.count)
    
    -- Messaggi di conferma
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Dato %s x%d al giocatore %d"):format(args.name, args.count, args.id)}
    })
    
    TriggerClientEvent('chat:addMessage', args.id, {
        color = {0, 255, 0},
        multiline = false,
        args = {"Sistema", ("Ricevuto %s x%d"):format(args.name, args.count)}
    })
end)

-- Event per usare un item
RegisterNetEvent('minimal_inventory:useItem', function(itemName)
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
        TriggerClientEvent('minimal_inventory:removeItem', source, itemName, 1)
        
        -- Logica per usare l'item (personalizza in base ai tuoi items)
        useItem(source, itemName)
        
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 255, 0},
            multiline = false,
            args = {"Sistema", ("Hai usato: %s"):format(itemName)}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = false,
            args = {"Errore", "Non hai questo item!"}
        })
    end
end)

-- Event per droppare un item
RegisterNetEvent('minimal_inventory:dropItem', function(itemName, count)
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
        TriggerClientEvent('minimal_inventory:removeItem', source, itemName, count)
        
        -- Qui potresti creare l'item nel mondo di gioco
        -- createWorldItem(source, itemName, count)
        
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

-- Event per dare un item ad un altro giocatore
RegisterNetEvent('minimal_inventory:giveItem', function(itemName, count, targetId)
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
        TriggerClientEvent('minimal_inventory:removeItem', source, itemName, count)
        TriggerClientEvent('minimal_inventory:addItem', targetId, itemName, count)
        
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
        TriggerClientEvent('minimal_inventory:healPlayer', source)
    elseif itemName == "water" then
        -- Disseta il giocatore
        TriggerClientEvent('minimal_inventory:drinkWater', source)
    elseif itemName == "food" then
        -- Nutri il giocatore
        TriggerClientEvent('minimal_inventory:eatFood', source)
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
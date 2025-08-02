local display = false
local items = {}
local wasInventoryOpen = false
local droppedItems = {}

-- Funzione per aprire/chiudere l'inventario
local function toggleInventory()
    display = not display
    
    local ped = PlayerPedId()
    
    if display then
        -- APERTURA INVENTARIO
        wasInventoryOpen = true
        
        -- Attiva focus e cursor
        SetNuiFocus(true, true)
        
        -- Congela il giocatore
        FreezeEntityPosition(ped, true)
        
        -- Invia messaggio per aprire l'inventario
        SendNUIMessage({
            action = 'toggle',
            show = true
        })
        
        print("Inventario aperto") -- Debug
    else
        -- CHIUSURA INVENTARIO
        wasInventoryOpen = false
        
        -- IMPORTANTE: Disattiva focus e cursor PRIMA
        SetNuiFocus(false, false)
        
        -- Scongela il giocatore
        FreezeEntityPosition(ped, false)
        
        -- Ripristina completamente i controlli
        EnableAllControlActions(0)
        
        -- Invia messaggio per chiudere l'inventario
        SendNUIMessage({
            action = 'toggle',
            show = false
        })
        
        print("Inventario chiuso") -- Debug
        
        -- Piccolo delay per assicurarsi che tutto sia ripristinato
        Citizen.SetTimeout(100, function()
            SetNuiFocus(false, false)
            EnableAllControlActions(0)
        end)
    end
end

-- Comando per toggleare l'inventario
RegisterCommand('toggleInventory', function()
    toggleInventory()
end, false)

-- Mappa il tasto F2 per aprire l'inventario
RegisterKeyMapping('toggleInventory', 'Apri/Chiudi Inventario', 'keyboard', 'F2')

-- Hotbar (tasti 1-7)
for i = 1, 7 do
    RegisterCommand('hotbar' .. i, function()
        if not display then -- Solo se l'inventario è chiuso
            SendNUIMessage({
                action = 'useSlot',
                slot = i
            })
            print('Usando slot hotbar: ' .. i) -- Debug
        end
    end, false)
    
    RegisterKeyMapping('hotbar' .. i, ('Usa Slot Hotbar %d'):format(i), 'keyboard', tostring(i))
end

-- Event per aggiungere items
RegisterNetEvent('minimal_inventory:addItem', function(name, count)
    if not name or not count then return end
    
    items[name] = (items[name] or 0) + count
    
    -- Aggiorna la UI
    SendNUIMessage({
        action = 'setItem',
        name = name,
        count = items[name]
    })
    
    -- Notifica al giocatore
    print(('Ricevuto: %s x%d'):format(name, count))
end)

-- Event per rimuovere items
RegisterNetEvent('minimal_inventory:removeItem', function(name, count)
    if not name or not count then return end
    
    if items[name] then
        items[name] = math.max(0, items[name] - count)
        
        if items[name] == 0 then
            items[name] = nil
        end
        
        -- Aggiorna la UI
        SendNUIMessage({
            action = 'setItem',
            name = name,
            count = items[name] or 0
        })
    end
end)

-- Thread per disabilitare i controlli quando l'inventario è aperto
CreateThread(function()
    while true do
        if display then
            -- Disabilita tutti i controlli quando l'inventario è aperto
            DisableAllControlActions(0)
            
            -- Permetti solo alcuni controlli essenziali per la UI
            EnableControlAction(0, 1, true)   -- Mouse X
            EnableControlAction(0, 2, true)   -- Mouse Y
            EnableControlAction(0, 24, true)  -- Attack (click sinistro)
            EnableControlAction(0, 25, true)  -- Aim (click destro)
            EnableControlAction(0, 200, true) -- ESC menu
            EnableControlAction(0, 322, true) -- ESC (alternativo)
            
            -- Controlla se ESC è premuto per chiudere l'inventario
            if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then -- ESC
                toggleInventory()
            end
        else
            -- Quando l'inventario è chiuso, assicurati che tutti i controlli siano attivi
            if wasInventoryOpen then
                EnableAllControlActions(0)
                wasInventoryOpen = false
            end
        end
        
        Wait(0)
    end
end)

-- Disattiva la weapon wheel nativa
CreateThread(function()
    while true do
        Wait(0)
        DisableControlAction(0, 37, true)
    end
end)

-- Callback NUI per chiudere l'inventario
RegisterNUICallback('closeInventory', function(data, cb)
    if display then
        toggleInventory()
    end
    cb('ok')
end)

-- Callback NUI per spostare item nella hotbar
RegisterNUICallback('moveToHotbar', function(data, cb)
    if data.item and data.count and data.slot then
        TriggerServerEvent('minimal_inventory:moveToHotbar', data.item, data.count, data.slot)
        print(('Spostato %s x%d nella hotbar slot %d'):format(data.item, data.count, data.slot))
    end
    cb('ok')
end)

-- Callback NUI per raccogliere da terra
RegisterNUICallback('pickupFromGround', function(data, cb)
    if data.item and data.count then
        TriggerServerEvent('minimal_inventory:pickupFromGround', data.item, data.count)
        print(('Raccolto da terra: %s x%d'):format(data.item, data.count))
    end
    cb('ok')
end)

-- Callback NUI per rimuovere dalla hotbar
RegisterNUICallback('removeFromHotbar', function(data, cb)
    if data.item and data.count and data.slot then
        TriggerServerEvent('minimal_inventory:removeFromHotbar', data.item, data.count, data.slot)
        print(('Rimosso dalla hotbar slot %d: %s x%d'):format(data.slot, data.item, data.count))
    end
    cb('ok')
end)

-- Callback NUI per riorganizzare hotbar
RegisterNUICallback('reorganizeHotbar', function(data, cb)
    if data.item and data.count and data.fromSlot and data.toSlot then
        TriggerServerEvent('minimal_inventory:reorganizeHotbar', data.item, data.count, data.fromSlot, data.toSlot)
        print(('Riorganizzato hotbar: %s da slot %d a slot %d'):format(data.item, data.fromSlot, data.toSlot))
    end
    cb('ok')
end)

-- Comando di emergenza per sbloccare il giocatore
RegisterCommand('unlock', function()
    display = false
    wasInventoryOpen = false
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
    EnableAllControlActions(0)
    SendNUIMessage({action = 'toggle', show = false})
    print("Giocatore sbloccato!")
end, false)

-- Callback NUI per usare un item
RegisterNUICallback('useItem', function(data, cb)
    if data.name then
        -- Trigger server event per usare l'item
        TriggerServerEvent('minimal_inventory:useItem', data.name)
    end
    cb('ok')
end)

-- Callback NUI per droppare un item
RegisterNUICallback('dropItem', function(data, cb)
    if data.name and data.count then
        -- Trigger server event per droppare l'item
        TriggerServerEvent('minimal_inventory:dropItem', data.name, data.count)
    end
    cb('ok')
end)

-- Gestione oggetti droppati a terra
RegisterNetEvent('minimal_inventory:spawnDroppedItem', function(id, itemName, count, coords)
    local model = `prop_cs_package_01`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local obj = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, true, true)
    PlaceObjectOnGroundProperly(obj)
    droppedItems[id] = { object = obj, item = itemName, count = count }
end)

RegisterNetEvent('minimal_inventory:removeDroppedItem', function(id)
    local drop = droppedItems[id]
    if drop then
        DeleteObject(drop.object)
        droppedItems[id] = nil
    end
end)

-- Controlla la vicinanza ai props per permettere il pickup
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, data in pairs(droppedItems) do
            local objCoords = GetEntityCoords(data.object)
            if #(coords - objCoords) <= 1.5 then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Premi ~INPUT_CONTEXT~ per raccogliere")
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustPressed(0, 38) then -- E
                    TriggerServerEvent('minimal_inventory:pickupDroppedItem', id)
                end
            end
        end
        Wait(0)
    end
end)

-- Spawna un prop quando un item viene droppato a terra
RegisterNetEvent('minimal_inventory:spawnDroppedItem', function(itemName, count, coords)
    local model = GetHashKey('prop_cs_package_01')
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local obj = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, true, true)
    PlaceObjectOnGroundProperly(obj)
end)

-- Callback NUI per dare un item
RegisterNUICallback('giveItem', function(data, cb)
    if data.name and data.count and data.targetId then
        -- Trigger server event per dare l'item
        TriggerServerEvent('minimal_inventory:giveItem', data.name, data.count, data.targetId)
    end
    cb('ok')
end)

-- Funzione di debug per vedere gli items
RegisterCommand('showItems', function()
    print('=== INVENTARIO ===')
    for name, count in pairs(items) do
        print(('%s: %d'):format(name, count))
    end
    print('==================')
end, false)

-- Quando la risorsa si avvia, assicurati che l'inventario sia chiuso
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        display = false
        wasInventoryOpen = false
        SetNuiFocus(false, false)
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        EnableAllControlActions(0)
        
        -- Forza la chiusura dell'inventario
        SendNUIMessage({
            action = 'toggle',
            show = false
        })
        
        print("Risorsa avviata - inventario forzato chiuso")
    end
end)

-- Assicurati che quando il giocatore spawna tutto sia resettato
AddEventHandler('playerSpawned', function()
    Citizen.SetTimeout(1000, function() -- Piccolo delay per essere sicuri
        display = false
        wasInventoryOpen = false
        SetNuiFocus(false, false)
        FreezeEntityPosition(PlayerPedId(), false)
        EnableAllControlActions(0)
        
        SendNUIMessage({
            action = 'toggle',
            show = false
        })
        
        print("Player spawned - stato resettato")
    end)
end)
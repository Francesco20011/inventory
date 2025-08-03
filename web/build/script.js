const itemGrid = document.getElementById('item-grid');
const dropGrid = document.getElementById('drop-grid');
const hotbar = document.getElementById('hotbar');
const itemDetails = document.getElementById('item-details');
const itemNameEl = document.getElementById('item-name');
const itemDescEl = document.getElementById('item-desc');
const useBtn = document.getElementById('use-btn');
const giveBtn = document.getElementById('give-btn');
const dropBtn = document.getElementById('drop-btn');
const inventory = document.getElementById('inventory');

const ICON_BASE = '../icons/';
const IMAGE_BASE = '../images/';
const iconMap = {
    arco: `${ICON_BASE}arco.png`,
    cornice: `${ICON_BASE}cornice.png`,
    lucchetto: `${ICON_BASE}lucchetto.png`,
    manoaperta: `${ICON_BASE}manoaperta.png`,
    mela: `${ICON_BASE}mela.png`,
    monete: `${ICON_BASE}monete.png`,
    money: `${ICON_BASE}monete.png`,
    patata: `${ICON_BASE}patata.png`,
    scudo: `${ICON_BASE}scudo.png`,
    slotbloccato: `${ICON_BASE}slotbloccato.png`,
    slotevidenziato: `${ICON_BASE}slotevidenziato.png`,
    slotvuoto: `${ICON_BASE}slotvuoto.png`,
    spada: `${ICON_BASE}spada.png`,
    stella: `${ICON_BASE}stella.png`,
    X: `${ICON_BASE}X.png`,
    zaino: `${ICON_BASE}zaino.png`
};

function getIcon(name) {
    const key = name?.toLowerCase();
     if (iconMap[key]) return iconMap[key];

    // fallback dinamico alle immagini degli item
    if (name) {
        return `${IMAGE_BASE}${name.toUpperCase()}.png`;
    }

    return iconMap.slotvuoto;
}

// Variables for custom drag system
let currentSlot = null;
let isInventoryOpen = false;
let isDragging = false;
let draggedSlot = null;
let dragElement = null;
let mouseStartX = 0;
let mouseStartY = 0;
let dragThreshold = 5; // pixel threshold to start dragging

// Use the correct resource name. If the native GetParentResourceName is not available
// fall back to 'inventory' instead of 'minimal_inventory'.
const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'inventory';

// Inizializza l'inventario come chiuso
document.addEventListener('DOMContentLoaded', function() {
    inventory.classList.add('hidden');
    itemDetails.classList.add('hidden');
    isInventoryOpen = false;
    console.log('DOM caricato, inventario inizializzato come chiuso');
});

// Helper to create a slot with all event listeners attached
function createSlot(parent, type, slotIndex) {
    const slot = document.createElement('div');
    
    // Assegna la classe in base al tipo
    if (type === 'hotbar') {
        slot.className = 'hotbar-slot';
        slot.dataset.slot = slotIndex;
        slot.dataset.type = 'hotbar';
    } else if (type === 'drop') {
        slot.className = 'slot drop-slot';
        slot.dataset.type = 'drop';
    } else {
        slot.className = 'slot inventory-slot';
        slot.dataset.type = 'inventory';
    }
    
    // Custom drag system events
    slot.addEventListener('mousedown', handleMouseDown);
    slot.addEventListener('click', handleSlotClick);
    
    // Doppio click per hotbar
    if (type === 'hotbar') {
        slot.addEventListener('dblclick', handleHotbarDoubleClick);
    }
    
    slot.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
    parent.appendChild(slot);
    return slot;
}

// Build grids
for (let i = 0; i < 25; i++) {
    createSlot(itemGrid, 'inventory');
}

for (let i = 0; i < 25; i++) {
    createSlot(dropGrid, 'drop');
}

for (let i = 1; i <= 7; i++) {
    createSlot(hotbar, 'hotbar', i);
}

// Global mouse events for drag system
document.addEventListener('mousemove', handleMouseMove);
document.addEventListener('mouseup', handleMouseUp);

// NUI message listener
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('Ricevuto messaggio NUI:', data);
    
    if (data.action === 'toggle') {
        if (data.show) {
            inventory.classList.remove('hidden');
            document.body.classList.add('inventory-open');
            isInventoryOpen = true;
            console.log('Inventario aperto');
        } else {
            inventory.classList.add('hidden');
            itemDetails.classList.add('hidden');
            document.body.classList.remove('inventory-open');
            isInventoryOpen = false;
            console.log('Inventario chiuso');
        }
    } else if (data.action === 'addItem' || data.action === 'setItem') {
        // Support both 'addItem' (legacy) and 'setItem' actions from the client.
        setItem(data.name, data.count);
    } else if (data.action === 'clear') {
        clearItems();
    } else if (data.action === 'useSlot') {
        highlightHotbar(data.slot);
    }
});

function setItem(name, count) {
    console.log(`Aggiungendo item: ${name} x${count}`);
    const empty = Array.from(itemGrid.children).find((el) => !el.dataset.itemName);
    if (empty) {
        empty.dataset.itemName = name;
        empty.dataset.count = count;
        const iconPath = getIcon(name);
        empty.innerHTML = `<img src="${iconPath}" class="slot-icon" onerror="this.onerror=null;this.src='${iconMap.slotvuoto}'"><span class="item-count">${count}</span>`;
        empty.style.backgroundImage = 'none';
        console.log(`Item aggiunto in slot: ${name} x${count}`);
    } else {
        console.log('Nessuno slot vuoto trovato nell\'inventario!');
    }
}

function clearItems() {
    console.log('Pulendo tutti gli items');
    
    Array.from(itemGrid.children).forEach((el) => {
        el.dataset.itemName = '';
        el.dataset.count = '';
        el.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
        el.style.backgroundImage = '';
    });
    
    Array.from(dropGrid.children).forEach((el) => {
        el.dataset.itemName = '';
        el.dataset.count = '';
        el.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
        el.style.backgroundImage = '';
        el.classList.remove('filled')
    });
    
    Array.from(hotbar.children).forEach((el) => {
        el.textContent = '';
    });
}

function lockSlot(slot) {
    slot.classList.add('locked');
    slot.dataset.locked = 'true';
}

function highlightHotbar(slot) {
    const el = hotbar.querySelector(`[data-slot="${slot}"]`);
    if (el) {
        el.classList.add('active');
        setTimeout(() => el.classList.remove('active'), 200);
        console.log(`Hotbar slot ${slot} evidenziato`);
    }
}

// CUSTOM DRAG SYSTEM
function handleMouseDown(e) {
    // Solo se c'è un item nello slot
    if (!this.dataset.itemName) return;
    
    e.preventDefault();
    
    // Salva posizione mouse iniziale
    mouseStartX = e.clientX;
    mouseStartY = e.clientY;
    draggedSlot = this;
    
    console.log('Mouse down su item:', this.dataset.itemName);
}

function handleMouseMove(e) {
    if (!draggedSlot || isDragging) return;
    
    // Calcola distanza dal punto iniziale
    const deltaX = Math.abs(e.clientX - mouseStartX);
    const deltaY = Math.abs(e.clientY - mouseStartY);
    
    // Se superiamo la soglia, inizia il drag
    if (deltaX > dragThreshold || deltaY > dragThreshold) {
        startDrag(e);
    }
}

function startDrag(e) {
    if (!draggedSlot) return;
    
    isDragging = true;
    console.log('Iniziando drag di:', draggedSlot.dataset.itemName);
    
    // Crea elemento visuale per il drag
    dragElement = document.createElement('div');
    dragElement.textContent = draggedSlot.textContent;
    dragElement.className = 'drag-preview';
    dragElement.style.cssText = `
        position: fixed;
        top: ${e.clientY - 25}px;
        left: ${e.clientX - 25}px;
        width: 50px;
        height: 50px;
        background: rgba(216, 184, 95, 0.9);
        border: 2px solid #d8b85f;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        pointer-events: none;
        z-index: 10000;
    `;
    
    document.body.appendChild(dragElement);
    document.body.classList.add('dragging');
    
    // Evidenzia lo slot sorgente
    draggedSlot.classList.add('dragging-source');
    
    // Aggiungi event listener per aggiornare posizione
    document.addEventListener('mousemove', updateDragPosition);
}

function updateDragPosition(e) {
    if (!dragElement) return;
    
    dragElement.style.left = (e.clientX - 25) + 'px';
    dragElement.style.top = (e.clientY - 25) + 'px';
    
    // Evidenzia slot sotto il mouse
    const elementBelow = document.elementFromPoint(e.clientX, e.clientY);
    
    // Rimuovi evidenziazione precedente
    document.querySelectorAll('.drag-hover').forEach(el => {
        el.classList.remove('drag-hover');
    });
    
    // Aggiungi evidenziazione al nuovo slot
    if (elementBelow && (elementBelow.classList.contains('slot') || elementBelow.classList.contains('hotbar-slot'))) {
        if (elementBelow !== draggedSlot) {
            elementBelow.classList.add('drag-hover');
        }
    }
}

function handleMouseUp(e) {
    if (!isDragging && draggedSlot) {
        // Era solo un click, non un drag
        setTimeout(() => {
            if (draggedSlot && draggedSlot.dataset.type !== 'hotbar') {
                handleSlotClick.call(draggedSlot, e);
            }
        }, 10);
    }
    
    if (isDragging) {
        completeDrag(e);
    }
    
    // Reset
    draggedSlot = null;
    isDragging = false;
}

function completeDrag(e) {
    console.log('Completando drag');
    
    // Trova l'elemento sotto il mouse
    const targetElement = document.elementFromPoint(e.clientX, e.clientY);
    
    // Cleanup visuale
    if (dragElement) {
        document.body.removeChild(dragElement);
        dragElement = null;
    }
    
    document.removeEventListener('mousemove', updateDragPosition);
    document.body.classList.remove('dragging');
    
    // Rimuovi tutte le classi di evidenziazione
    document.querySelectorAll('.dragging-source, .drag-hover').forEach(el => {
        el.classList.remove('dragging-source', 'drag-hover');
    });
    
    // Verifica se abbiamo un target valido
    if (!targetElement || !draggedSlot) {
        console.log('Drop su target non valido');
        return;
    }
    
    // Trova il target slot
    let targetSlot = targetElement;
    if (!targetSlot.classList.contains('slot') && !targetSlot.classList.contains('hotbar-slot')) {
        targetSlot = targetElement.closest('.slot, .hotbar-slot');
    }
    
    if (!targetSlot || targetSlot === draggedSlot) {
        console.log('Nessun target valido o stesso slot');
        return;
    }
    
    // Esegui il movimento
    const sourceType = draggedSlot.dataset.type;
    const targetType = targetSlot.dataset.type;
    const itemData = draggedSlot.dataset.itemName;
    
    console.log(`Drop: ${sourceType} -> ${targetType} | Item: ${itemData}`);
    
    moveItem(draggedSlot, targetSlot, sourceType, targetType);
}

function moveItem(sourceSlot, targetSlot, sourceType, targetType) {
    if (!sourceSlot.dataset.itemName) {
        console.log('Nessun item da spostare');
        return;
    }
    
    const itemName = sourceSlot.dataset.itemName;
    const itemCount = parseInt(sourceSlot.dataset.count) || 1;
    
    if (targetSlot.dataset.itemName) {
        console.log('Slot di destinazione occupato - facendo swap');
    
        const targetName = targetSlot.dataset.itemName;
        const targetCount = targetSlot.dataset.count;
        const targetHTML = targetSlot.innerHTML;
        const targetBg = targetSlot.style.backgroundImage;

        targetSlot.dataset.itemName = itemName;
        targetSlot.dataset.count = itemCount;
        targetSlot.innerHTML = sourceSlot.innerHTML;
        targetSlot.style.backgroundImage = 'none';

        sourceSlot.dataset.itemName = targetName;
        sourceSlot.dataset.count = targetCount;
        sourceSlot.innerHTML = targetHTML;
        sourceSlot.style.backgroundImage = targetBg;

        if (targetType === 'hotbar') targetSlot.classList.add('filled');
        if (sourceType === 'hotbar' && !sourceSlot.dataset.itemName) sourceSlot.classList.remove('filled');
        
        console.log('Swap completato');
        return;
    }
    
    // Movimento normale
    console.log(`Spostando ${itemName} da ${sourceType} a ${targetType}`);
    
    targetSlot.dataset.itemName = itemName;
    targetSlot.dataset.count = itemCount;
    targetSlot.innerHTML = sourceSlot.innerHTML;
    targetSlot.style.backgroundImage = 'none';
    if (targetType === 'hotbar') targetSlot.classList.add('filled');

    sourceSlot.dataset.itemName = '';
    sourceSlot.dataset.count = '';
    sourceSlot.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
    sourceSlot.style.backgroundImage = '';
    if (sourceType === 'hotbar') sourceSlot.classList.remove('filled');
    
    // Invia al server in base al tipo di movimento
    handleServerMovement(sourceType, targetType, itemName, itemCount, sourceSlot, targetSlot);
    
    console.log(`Item spostato con successo: ${itemName} x${itemCount}`);
}

function handleServerMovement(sourceType, targetType, itemName, itemCount, sourceSlot, targetSlot) {
    // INVENTORY → HOTBAR
    if (sourceType === 'inventory' && targetType === 'hotbar') {
        console.log('Server: Inventario -> Hotbar');
        sendCallback('moveToHotbar', {
            item: itemName,
            count: itemCount,
            slot: targetSlot.dataset.slot
        });
    }
    
    // INVENTORY → DROP (buttare a terra)
    else if (sourceType === 'inventory' && targetType === 'drop') {
        console.log('Server: Inventario -> Terra');
        sendCallback('dropItem', {
            name: itemName,
            count: itemCount
        });
    }
    
    // DROP → INVENTORY (raccogliere da terra)
    else if (sourceType === 'drop' && targetType === 'inventory') {
        console.log('Server: Terra -> Inventario');
        sendCallback('pickupFromGround', {
            item: itemName,
            count: itemCount
        });
    }
    
    // HOTBAR → INVENTORY
    else if (sourceType === 'hotbar' && targetType === 'inventory') {
        console.log('Server: Hotbar -> Inventario');
        sendCallback('removeFromHotbar', {
            item: itemName,
            count: itemCount,
            slot: sourceSlot.dataset.slot
        });
    }
    
    // HOTBAR → HOTBAR (riorganizzare hotbar)
    else if (sourceType === 'hotbar' && targetType === 'hotbar') {
        console.log('Server: Riorganizzazione Hotbar');
        sendCallback('reorganizeHotbar', {
            item: itemName,
            count: itemCount,
            fromSlot: sourceSlot.dataset.slot,
            toSlot: targetSlot.dataset.slot
        });
    }
    
    // INVENTORY → INVENTORY o DROP → DROP (solo riorganizzazione locale)
    else if ((sourceType === 'inventory' && targetType === 'inventory') || 
             (sourceType === 'drop' && targetType === 'drop')) {
        console.log('Riorganizzazione locale - nessun evento server necessario');
    }
    
    // Altri movimenti
    else {
        console.log(`Movimento ${sourceType} -> ${targetType} completato localmente`);
    }
}

// Funzione helper per inviare callback
function sendCallback(action, data) {
    console.log(`Inviando callback: ${action}`, data);
    
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).then(response => {
        console.log(`Callback ${action} inviato con successo`);
    }).catch(error => {
        console.error(`Errore nel callback ${action}:`, error);
    });
}

// Doppio click su hotbar per rimuovere item
function handleHotbarDoubleClick() {
    if (!this.dataset.itemName) return;
    const itemName = this.dataset.itemName;
    const itemCount = this.dataset.count || 1;
    console.log('Doppio click su hotbar slot');
    // Trova uno slot vuoto nell'inventario
    const emptySlot = Array.from(itemGrid.children).find(slot => !slot.dataset.itemName);
    if (emptySlot) {
        emptySlot.dataset.itemName = itemName;
        emptySlot.dataset.count = itemCount;
        emptySlot.innerHTML = this.innerHTML;
        emptySlot.style.backgroundImage = 'none';

        this.dataset.itemName = '';
        this.dataset.count = '';
        this.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
        this.style.backgroundImage = '';
        this.classList.remove('filled');
        
        sendCallback('removeFromHotbar', {
            item: itemName,
            count: itemCount,
            slot: this.dataset.slot
        });
        
        console.log(`Item rimosso dalla hotbar: ${itemName}`);
    } else {
        console.log('Nessuno slot vuoto nell\'inventario per rimuovere dalla hotbar');
    }
}

// Show item details when clicking a slot
function handleSlotClick(e) {
    if (!this.dataset.itemName || !isInventoryOpen) return;

    console.log('Click su slot - aprendo dettagli:', this.dataset.itemName);
    
    currentSlot = this;
    itemNameEl.textContent = this.dataset.itemName;
    itemDescEl.textContent = 'Descrizione: Questo è un item di esempio';
    itemDetails.classList.remove('hidden');
}

// Button actions nel dettaglio
useBtn.addEventListener('click', () => {
    if (currentSlot && currentSlot.dataset.itemName) {
        const itemName = currentSlot.dataset.itemName;
        
        sendCallback('useItem', { name: itemName });
        
        currentSlot.dataset.itemName = '';
        currentSlot.dataset.count = '';
        currentSlot.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
        currentSlot.style.backgroundImage = '';
        currentSlot.classList.remove('filled');
    }
    itemDetails.classList.add('hidden');
});

giveBtn.addEventListener('click', () => {
    if (currentSlot && currentSlot.dataset.itemName) {
        const itemName = currentSlot.dataset.itemName;
        const count = parseInt(currentSlot.dataset.count) || 1;
        
        const targetId = prompt('ID del giocatore a cui dare l\'item:');
        
        if (targetId) {
            sendCallback('giveItem', {
                name: itemName,
                count: count,
                targetId: parseInt(targetId)
            });
            
            currentSlot.dataset.itemName = '';
            currentSlot.dataset.count = '';
            currentSlot.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
            currentSlot.style.backgroundImage = '';
            currentSlot.classList.remove('filled');
        }
    }
    itemDetails.classList.add('hidden');
});

dropBtn.addEventListener('click', () => {
    if (currentSlot && currentSlot.dataset.itemName) {
        const itemName = currentSlot.dataset.itemName;
        const count = parseInt(currentSlot.dataset.count) || 1;
        
        sendCallback('dropItem', {
            name: itemName,
            count: count
        });
        
        currentSlot.dataset.itemName = '';
        currentSlot.dataset.count = '';
        currentSlot.innerHTML = `<img src="${iconMap.slotvuoto}" class="slot-icon">`;
        currentSlot.style.backgroundImage = '';
        currentSlot.classList.remove('filled');
    }
    itemDetails.classList.add('hidden');
});

// Chiudi il dettaglio quando si clicca fuori
window.addEventListener('click', (e) => {
    if (itemDetails.classList.contains('hidden')) return;
    if (!itemDetails.contains(e.target) && e.target !== currentSlot) {
        itemDetails.classList.add('hidden');
    }
});

// Chiudi inventario con ESC
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && isInventoryOpen) {
        e.preventDefault();
        e.stopPropagation();
        if (!itemDetails.classList.contains('hidden')) {
            itemDetails.classList.add('hidden');
            console.log('Dettagli item chiusi con ESC');
        } else {
            console.log('Chiudendo inventario con ESC');
            closeInventory();
        }
    }
});

// Chiudi cliccando fuori dall'inventario
document.addEventListener('click', function(e) {
    if (!isInventoryOpen) return;
    const inventoryContainer = document.querySelector('.inventory-container');
    const itemDetailsBox = document.querySelector('#item-details');
    const slot = e.target.closest('.slot, .hotbar-slot');
    if (!itemDetails.classList.contains('hidden') && !itemDetailsBox.contains(e.target) && !slot) {
        itemDetails.classList.add('hidden');
        console.log('Dettagli item chiusi con click fuori');
        return;
    }
    if (!inventoryContainer.contains(e.target) && !itemDetailsBox.contains(e.target)) {
        console.log('Chiudendo inventario con click fuori');
        closeInventory();
    }
});

// Chiude immediatamente l'inventario lato NUI e notifica il server
function closeInventory() {
    inventory.classList.add('hidden');
    itemDetails.classList.add('hidden');
    isInventoryOpen = false;
    sendCallback('closeInventory', {});
}

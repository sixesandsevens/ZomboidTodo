require "ZT_Tasks"

ZT_ContextMenu = {}

local function getRealItem(entry)
    if not entry then return nil end

    if instanceof(entry, "InventoryItem") then
        return entry
    end

    if type(entry) == "table" then
        return entry.items and entry.items[1] or entry[1]
    end

    return nil
end

function ZT_ContextMenu.openTasks(playerNum)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    ZomboidTodo.openWindow(player)
end

function ZT_ContextMenu.onFillInventoryObjectContextMenu(playerNum, context, items)
    if not context or not items then return end

    for _, entry in ipairs(items) do
        local item = getRealItem(entry)

        if item and ZT_Tasks.isNotebookItem(item) then
            context:addOption("Open Survivor Tasks", item, function()
                ZT_ContextMenu.openTasks(playerNum)
            end)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ZT_ContextMenu.onFillInventoryObjectContextMenu)

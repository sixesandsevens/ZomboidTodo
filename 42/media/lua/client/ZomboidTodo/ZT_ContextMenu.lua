require "ZomboidTodo/ZT_Tasks"

ZT_ContextMenu = {}

local function debugLog(...)
    if print then
        print("[ZomboidTodo]", ...)
    end
end

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

local function getItemsCount(items)
    if type(items) == "table" then
        return #items
    end
    if items and items.size then
        local ok, count = pcall(function() return items:size() end)
        if ok then
            return count
        end
    end
    return nil
end

local function iterateItems(items)
    if type(items) == "table" then
        return ipairs(items)
    end
    if items and items.size then
        local i = 0
        return function()
            if i >= items:size() then
                return nil
            end
            local entry = items:get(i)
            i = i + 1
            return i, entry
        end
    end
    return function() return nil end
end

function ZT_ContextMenu.openTasks(playerNum)
    local player = getSpecificPlayer(playerNum)
    if not player then
        debugLog("openTasks: no player found for playerNum=", tostring(playerNum))
        return
    end
    ZomboidTodo.openWindow(player)
end

function ZT_ContextMenu.onFillInventoryObjectContextMenu(playerNum, context, items)
    if not context or not items then
        debugLog("onFillInventoryObjectContextMenu: missing context or items", tostring(playerNum), tostring(context), tostring(items))
        return
    end

    local player = getSpecificPlayer(playerNum)
    local itemCount = getItemsCount(items)
    debugLog("onFillInventoryObjectContextMenu: playerNum=", tostring(playerNum), "player=", tostring(player), "itemsType=", type(items), "itemsCount=", tostring(itemCount))

    for _, entry in iterateItems(items) do
        local item = getRealItem(entry)

        if item and ZT_Tasks.isNotebookItem(item) then
            debugLog("onFillInventoryObjectContextMenu: matched notebook item=", tostring(item:getFullType()))
            context:addOption("Open Survivor Tasks", item, function()
                ZT_ContextMenu.openTasks(playerNum)
            end)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ZT_ContextMenu.onFillInventoryObjectContextMenu)

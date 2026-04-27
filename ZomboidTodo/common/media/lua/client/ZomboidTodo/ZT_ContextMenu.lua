require "ZT_Tasks"

ZT_ContextMenu = {}

function ZT_ContextMenu.openTasks(player)
    if not player then return end
    ZomboidTodo.openWindow(player)
end

function ZT_ContextMenu.onFillInventoryObjectContextMenu(player, context, items)
    if not player or not context or not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and ZT_Tasks.isNotebookItem(item) then
            context:addOption("Open Survivor Tasks", items, function()
                ZT_ContextMenu.openTasks(player)
            end)
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ZT_ContextMenu.onFillInventoryObjectContextMenu)

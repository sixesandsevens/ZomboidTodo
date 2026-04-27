require "ZomboidTodo/ZT_Tasks"
require "ZomboidTodo/ZT_UI"
require "ZomboidTodo/ZT_ContextMenu"

ZomboidTodo = ZomboidTodo or {}
ZomboidTodo.window = nil

function ZomboidTodo.openWindow(player, item)
    if not player or not item then return end

    if ZomboidTodo.window then
        if ZomboidTodo.window.player == player and ZomboidTodo.window.item == item then
            ZomboidTodo.window:bringToTop()
            return ZomboidTodo.window
        end
        ZomboidTodo.window:close()
        ZomboidTodo.window = nil
    end

    ZomboidTodo.window = ZomboidTodoWindow:new(120, 120, 360, 420, player, item)
    ZomboidTodo.window:initialise()
    ZomboidTodo.window:instantiate()
    ZomboidTodo.window:setVisible(true)
    ZomboidTodo.window:addToUIManager()
    ZomboidTodo.window:bringToTop()
    return ZomboidTodo.window
end

function ZomboidTodo.closeWindow()
    if ZomboidTodo.window then
        ZomboidTodo.window:close()
        ZomboidTodo.window = nil
    end
end

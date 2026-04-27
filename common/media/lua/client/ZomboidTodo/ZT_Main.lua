require "ZomboidTodo/ZT_Tasks"
require "ZomboidTodo/ZT_UI"
require "ZomboidTodo/ZT_ContextMenu"

ZomboidTodo = ZomboidTodo or {}
ZomboidTodo.window = nil

function ZomboidTodo.openWindow(player)
    if not player then return end

    if ZomboidTodo.window then
        ZomboidTodo.window:close()
        ZomboidTodo.window = nil
    end

    ZomboidTodo.window = ZomboidTodoWindow:new(120, 120, 360, 420, player)
    ZomboidTodo.window:initialise()
    ZomboidTodo.window:instantiate()
    ZomboidTodo.window:setVisible(true)
    ZomboidTodo.window:addToUIManager()
    ZomboidTodo.window:bringToTop()
end

function ZomboidTodo.closeWindow()
    if ZomboidTodo.window then
        ZomboidTodo.window:close()
        ZomboidTodo.window = nil
    end
end

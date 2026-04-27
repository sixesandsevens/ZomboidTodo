require "ZT_Tasks"
require "ZT_UI"
require "ZT_ContextMenu"

ZomboidTodo = ZomboidTodo or {}
ZomboidTodo.window = nil

function ZomboidTodo.openWindow(player)
    if not player then return end

    if ZomboidTodo.window and ZomboidTodo.window:isVisible() then
        ZomboidTodo.window:setVisible(false)
        ZomboidTodo.window:removeFromUIManager()
        ZomboidTodo.window = nil
    end

    ZomboidTodo.window = ZomboidTodoWindow:new(120, 120, 360, 420, player)
    ZomboidTodo.window:initialise()
    ZomboidTodo.window:instantiate()
    ZomboidTodo.window:addToUIManager()
    ZomboidTodo.window:bringToTop()
end

function ZomboidTodo.closeWindow()
    if ZomboidTodo.window then
        ZomboidTodo.window:setVisible(false)
        ZomboidTodo.window:removeFromUIManager()
        ZomboidTodo.window = nil
    end
end

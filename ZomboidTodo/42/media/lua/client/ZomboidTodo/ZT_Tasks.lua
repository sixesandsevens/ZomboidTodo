ZT_Tasks = {}

local notebookTypes = {
    ["Base.Notebook"] = true,
    ["Base.Journal"] = true,
    ["Base.Diary"] = true,
}

local writingTools = {
    ["Base.Pen"] = true,
    ["Base.Pencil"] = true,
    ["Base.RedPen"] = true,
    ["Base.BluePen"] = true,
}

local function getPlayerModData(player)
    if not player then return {} end
    local data = player:getModData()
    if not data.ZomboidTodo then
        data.ZomboidTodo = { tasks = {}, nextTaskId = 1 }
    end
    return data.ZomboidTodo
end

local function trim(text)
    if not text then return "" end
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

function ZT_Tasks.isNotebookItem(item)
    return item and notebookTypes[item:getFullType()]
end

function ZT_Tasks.hasWritingTool(player)
    if not player then return false end
    local inventory = player:getInventory()
    if not inventory then return false end
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and writingTools[item:getFullType()] then
            return true
        end
    end
    return false
end

function ZT_Tasks.hasNotebook(player)
    if not player then return false end
    local inventory = player:getInventory()
    if not inventory then return false end
    for i = 0, inventory:getItems():size() - 1 do
        local item = inventory:getItems():get(i)
        if item and ZT_Tasks.isNotebookItem(item) then
            return true
        end
    end
    return false
end

function ZT_Tasks.getTasks(player)
    return getPlayerModData(player).tasks
end

function ZT_Tasks.addTask(player, text)
    local taskText = trim(text)
    if taskText == "" then
        return false
    end

    local data = getPlayerModData(player)
    local task = {
        id = tostring(data.nextTaskId),
        text = taskText,
        done = false,
        createdAt = os.time(),
    }
    data.nextTaskId = data.nextTaskId + 1
    table.insert(data.tasks, task)
    return true
end

local function findTaskIndex(tasks, id)
    for index, task in ipairs(tasks) do
        if task.id == id then
            return index
        end
    end
    return nil
end

function ZT_Tasks.toggleTask(player, id)
    local tasks = ZT_Tasks.getTasks(player)
    local index = findTaskIndex(tasks, id)
    if index then
        tasks[index].done = not tasks[index].done
        return true
    end
    return false
end

function ZT_Tasks.removeTask(player, id)
    local tasks = ZT_Tasks.getTasks(player)
    local index = findTaskIndex(tasks, id)
    if index then
        table.remove(tasks, index)
        return true
    end
    return false
end

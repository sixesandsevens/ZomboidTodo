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
    if not player then return { tasks = {}, nextTaskId = 1 } end
    local data = player:getModData()
    if not data.ZomboidTodo then
        data.ZomboidTodo = { tasks = {}, nextTaskId = 1 }
    end
    if type(data.ZomboidTodo.tasks) ~= "table" then
        data.ZomboidTodo.tasks = {}
    end
    if type(data.ZomboidTodo.nextTaskId) ~= "number" then
        data.ZomboidTodo.nextTaskId = 1
    end
    return data.ZomboidTodo
end

local function collectionToTable(collection)
    if not collection then return {} end
    if type(collection) == "table" then
        return collection
    end

    local list = {}
    for i = 0, collection:size() - 1 do
        table.insert(list, collection:get(i))
    end
    return list
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
    for _, item in ipairs(collectionToTable(inventory:getItems())) do
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
    for _, item in ipairs(collectionToTable(inventory:getItems())) do
        if item and ZT_Tasks.isNotebookItem(item) then
            return true
        end
    end
    return false
end

function ZT_Tasks.getTasks(player)
    local data = getPlayerModData(player)
    data.tasks = data.tasks or {}
    return data.tasks
end

function ZT_Tasks.addTask(player, text)
    local taskText = trim(text)
    if taskText == "" then
        return false
    end

    local data = getPlayerModData(player)
    data.tasks = data.tasks or {}
    data.nextTaskId = data.nextTaskId or 1
    local task = {
        id = data.nextTaskId,
        text = taskText,
        done = false,
        createdAt = os.time(),
    }
    data.nextTaskId = data.nextTaskId + 1
    table.insert(data.tasks, task)
    return true
end

local function findTaskIndex(tasks, id)
    local lookupId = tostring(id)
    for index, task in ipairs(tasks) do
        if tostring(task.id) == lookupId then
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

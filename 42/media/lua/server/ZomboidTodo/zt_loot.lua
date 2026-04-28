require "Items/Distributions"

local DEBUG_LOOT = true
local loggedSandboxState = false

local targetDistributions = {
    "OfficeDesk",
    "DeskDrawer",
    "FilingCabinet",
    "SchoolLockers",
    "Mail",
    "BookstoreBooks",
    "LibraryBooks",
    "BedroomDrawers",
    "KitchenDrawers",
    "Counter",
    "GloveBox",
    "Bookshelf",
    "BookstoreShelf",
    "LibraryShelf",
}

local baseWeights = {
    ["Base.SheetOfPaper"] = 4,
    ["Base.Paper"] = 4,
    ["Base.Pencil"] = 3,
    ["Base.Pen"] = 3,
    ["Base.Notebook"] = 2,
    ["Base.Notepad"] = 2,
    ["Base.Journal"] = 1,
    ["Base.Eraser"] = 1,
}

local rateMultipliers = {
    [1] = 0,
    [2] = 0.5,
    [3] = 1,
    [4] = 2,
    [5] = 4,
    [6] = 8,
}

local function log(...)
    if DEBUG_LOOT and print then
        print("[ZomboidTodo.Loot]", ...)
    end
end

local function addItemToDistribution(distName, item, weight)
    local dist = DistributionTable and DistributionTable[distName]
    if not dist or not dist.items then
        log("Skipping missing distribution:", distName)
        return
    end

    for i = 1, #dist.items, 2 do
        if dist.items[i] == item then
            dist.items[i + 1] = dist.items[i + 1] + weight
            log("Updated", item, "in", distName, "by", weight, "new", dist.items[i + 1])
            return
        end
    end

    table.insert(dist.items, item)
    table.insert(dist.items, weight)
    log("Added", item, "to", distName, "with", weight)
end

local function getSupplyRate()
    if SandboxVars and SandboxVars.ZomboidTodo then
        local value = tonumber(SandboxVars.ZomboidTodo.SupplySpawnRate) or 4
        if not loggedSandboxState then
            log("SupplySpawnRate =", tostring(SandboxVars.ZomboidTodo.SupplySpawnRate), "resolved", value)
            loggedSandboxState = true
        end
        return value
    end
    if not loggedSandboxState then
        log("SandboxVars.ZomboidTodo missing; using default SupplySpawnRate 4")
        loggedSandboxState = true
    end
    return 4
end

local function applyLootBoost()
    local rate = getSupplyRate()
    local multiplier = rateMultipliers[rate] or 2
    if multiplier <= 0 then
        log("SupplySpawnRate minimum, no changes applied")
        return
    end

    if not DistributionTable then
        log("DistributionTable not available")
        return
    end

    log("Applying loot boost for rate", rate, "multiplier", multiplier)
    for _, distName in ipairs(targetDistributions) do
        for item, baseWeight in pairs(baseWeights) do
            local weight = math.max(1, math.floor(baseWeight * multiplier))
            addItemToDistribution(distName, item, weight)
        end
    end
end

Events.OnPreDistributionMerge.Add(applyLootBoost)

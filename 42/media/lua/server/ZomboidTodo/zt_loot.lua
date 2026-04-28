require "Items/ProceduralDistributions"

local DEBUG_LOOT = true
local loggedSandboxState = false

local targetDistributions = {
    "OfficeDesk",
    "OfficeDeskHome",
    "OfficeDeskSecretary",
    "OfficeDrawers",
    "OfficeShelfSupplies",
    "FilingCabinetGeneric",
    "SchoolLockers",
    "BookstoreBooks",
    "LibraryBooks",
    "PostOfficeSupplies",
    "LivingRoomShelf",
    "ShelfGeneric",
    "ClassroomDesk",
    "ClassroomSecondaryDesk",
}

local baseWeights = {
    ["SheetPaper2"] = 4,
    ["Pencil"] = 3,
    ["Pen"] = 3,
    ["Notebook"] = 2,
    ["Notepad"] = 2,
    ["Journal"] = 1,
    ["Eraser"] = 1,
}

local rateMultipliers = {
    [1] = 0.05,
    [2] = 0.2,
    [3] = 0.6,
    [4] = 1.0,
    [5] = 2.0,
    [6] = 3.0,
}

local function log(...)
    if DEBUG_LOOT and print then
        print("[ZomboidTodo.Loot]", ...)
    end
end

local function addItemToDistribution(distName, item, weight)
    local dist = ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list[distName]
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
    local multiplier = rateMultipliers[rate] or 1.0
    if multiplier <= 0 then
        log("SupplySpawnRate minimum, no changes applied")
        return
    end

    if not ProceduralDistributions or not ProceduralDistributions.list then
        log("ProceduralDistributions.list not available")
        return
    end

    log("Applying loot boost for rate", rate, "multiplier", multiplier)
    for _, distName in ipairs(targetDistributions) do
        for item, baseWeight in pairs(baseWeights) do
            local weight = baseWeight * multiplier
            addItemToDistribution(distName, item, weight)
        end
    end
end

Events.OnPreDistributionMerge.Add(applyLootBoost)

require "Items/Distributions"

local DEBUG_LOOT = false

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
    [2] = 1,
    [3] = 2,
    [4] = 4,
    [5] = 8,
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
        return tonumber(SandboxVars.ZomboidTodo.SupplySpawnRate) or 3
    end
    return 3
end

local function applyLootBoost()
    local rate = getSupplyRate()
    if rate == 1 then
        log("SupplySpawnRate=Vanilla, no changes applied")
        return
    end

    local multiplier = rateMultipliers[rate] or 2
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

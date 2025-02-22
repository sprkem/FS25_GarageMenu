--
-- FS25 - GarageMenu
--
-- @Author: Ozz
-- @Date: 14.02.2025
-- @Version: 1.0.0.0
--
-- Changelog:
--  v1.0.0.0 (TODO):
--  - Initial Release


GarageMenu = {}
GarageMenu.dir = g_currentModDirectory
GarageMenu.modName = g_currentModName

source(GarageMenu.dir .. "gui/MenuGarageMenu.lua")

function GarageMenu:loadMap()
    g_gui:loadProfiles(GarageMenu.dir .. "gui/guiProfiles.xml")

    self.itemCache = {}
    self.categoryData = nil
    self.garagePage = ShopCategoriesFrame:new()
    local pageName = "garageFrame"
    g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", pageName, self.garagePage, true)

    self.garagePage["onFrameOpen"] = Utils.overwrittenFunction(self.garagePage["onFrameOpen"], GarageMenu.onFrameOpen)
    self:removeMoneyBox()

    GarageMenu.fixInGameMenu(self.garagePage, "menuGarageMenu", { 0, 0, 1024, 1024 }, 2,
        GarageMenu:makeIsGarageMenuCheckEnabledPredicate())

    g_currentMission.garageMenu = self
end

function GarageMenu.onFrameOpen()
    local self = g_currentMission.garageMenu

    local categoryTypes = g_storeManager:getCategoryTypes()
    local shopCategories = g_shopController:getShopCategories()
    local ownedItemCategories = self:getOwnedItemCategories()
    local displayCategories = {}

    for k, category in pairs(shopCategories) do
        if ownedItemCategories[k] ~= nil then
            local itemCategories = {}
            for _, itemCategory in pairs(category) do
                if ownedItemCategories[k][itemCategory.id] ~= nil then
                    table.insert(itemCategories, itemCategory)
                end
            end
            displayCategories[k] = itemCategories
        end
    end

    local config = {
        categoryTypes,
        displayCategories,
        -- g_currentMission.garageMenu:makeSelfCallback(GarageMenu.onClickItemCategory),
        GarageMenu.onClickItemCategory,
        g_shopMenu:makeSelfCallback(g_shopMenu.onSelectCategory),
        g_i18n:getText("garage_menu_header"),
        ShopMenu.SLICE_ID.VEHICLES,
        ShopMenu.LIST_CELL_NAME_CATEGORY,
        ShopMenu.LIST_EMPTY_CELL_NAME_CATEGORY
    }

    self.garagePage:reset()
    self.garagePage:initialize(unpack(config))
    self.garagePage.categoryList:reloadData()
end

function GarageMenu:removeMoneyBox()
    local headerPanel = self.garagePage.elements[1].elements[1].elements[1]
    local toRemove = {
        shopMoneyBoxBg = 1,
        shopMoneyBox = 1
    }

    for i = #headerPanel.elements, 1, -1 do
        local e = headerPanel.elements[i]
        if toRemove[e.id] ~= nil then
            table.remove(headerPanel.elements, i)
        end
    end
end

function GarageMenu:getOwnedItemCategories()
    local ownedItemCategories = {}
    local currentFarmId = 1

    if self.categoryData == nil then
        self:setCategoryData()
    end

    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == currentFarmId then
            local xmlFileName = vehicle.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            local itemCategoryName = self.itemCache[xmlFileName].categoryName
            local categoryTypeID = self.categoryData[itemCategoryName].sectionID

            if categoryTypeID ~= "OBJECTS" then
                if ownedItemCategories[categoryTypeID] == nil then ownedItemCategories[categoryTypeID] = {} end
                ownedItemCategories[categoryTypeID][itemCategoryName] = 1
            end
        end
    end

    return ownedItemCategories
end

function GarageMenu:setCategoryData()
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    self.categoryData = {}
    for sectionID, entries in pairs(inGameMenu.pageShopVehicles.categories) do
        for _, category in pairs(entries) do
            self.categoryData[category.id] = {
                sectionID = sectionID
            }
        end
    end
end

function GarageMenu:storeItemDetails(itemXml)
    self.itemCache[itemXml] = {}
    for index, item in pairs(g_storeManager.items) do
        if item ~= nil then
            if item.xmlFilename == itemXml then
                self.itemCache[itemXml].categoryName = item.categoryName
                self.itemCache[itemXml].itemName = item.name
                self.itemCache[itemXml].brandNameRaw = item.brandNameRaw
                break
            end
        end
    end
end

function GarageMenu.onClickItemCategory(categoryName, screenTitle, categoryDisplayName, baseCategoryIconUVs)
    local categoryItems = g_shopController:getItemsByCategory(categoryName)
    local currentDisplayItems = categoryItems

    -- if self.state ~= 0 then
    local displayItems = {}

    for i = 1, #categoryItems do
        -- if self:getIsItemVisible(categoryItems[i].storeItem) then
        table.insert(displayItems, categoryItems[i])
        -- end
    end

    currentDisplayItems = displayItems
    -- end

    g_shopMenu.currentCategoryName = categoryName
    g_shopMenu.currentDisplayItems = currentDisplayItems
    g_shopMenu.currentCategoryFilter = nil
    g_shopMenu.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    g_shopMenu.pageShopItemDetails:setDisplayItems(currentDisplayItems)

    g_shopMenu.pageShopItemDetails:setCategory(baseCategoryIconUVs, categoryDisplayName, categoryDisplayName)
    g_shopMenu:pushDetail(g_shopMenu.pageShopItemDetails)
end

function GarageMenu:makeIsGarageMenuCheckEnabledPredicate()
    return function() return true end
end

-- from Courseplay
function GarageMenu.fixInGameMenu(frame, pageName, uvs, position, predicateFunc)
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    local targetPosition = 0

    -- remove all to avoid warnings
    for k, v in pairs({ pageName }) do
        inGameMenu.controlIDs[v] = nil
    end

    for i = 1, #inGameMenu.pagingElement.elements do
        local child = inGameMenu.pagingElement.elements[i]
        if child == inGameMenu["pageUsedSale"] then
            targetPosition = i + 1;
            break
        end
    end

    if targetPosition == 0 then
        targetPosition = position
    end

    inGameMenu[pageName] = frame
    inGameMenu.pagingElement:addElement(inGameMenu[pageName])

    inGameMenu:exposeControlsAsFields(pageName)

    for i = 1, #inGameMenu.pagingElement.elements do
        local child = inGameMenu.pagingElement.elements[i]
        if child == inGameMenu[pageName] then
            table.remove(inGameMenu.pagingElement.elements, i)
            table.insert(inGameMenu.pagingElement.elements, targetPosition, child)
            break
        end
    end

    for i = 1, #inGameMenu.pagingElement.pages do
        local child = inGameMenu.pagingElement.pages[i]
        if child.element == inGameMenu[pageName] then
            table.remove(inGameMenu.pagingElement.pages, i)
            table.insert(inGameMenu.pagingElement.pages, targetPosition, child)
            break
        end
    end

    inGameMenu.pagingElement:updateAbsolutePosition()
    inGameMenu.pagingElement:updatePageMapping()

    inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
    local iconFileName = Utils.getFilename('images/menuIcon.dds', GarageMenu.dir)
    inGameMenu:addPageTab(inGameMenu[pageName], iconFileName, GuiUtils.getUVs(uvs))

    for i = 1, #inGameMenu.pageFrames do
        local child = inGameMenu.pageFrames[i]
        if child == inGameMenu[pageName] then
            table.remove(inGameMenu.pageFrames, i)
            table.insert(inGameMenu.pageFrames, targetPosition, child)
            break
        end
    end

    inGameMenu:rebuildTabList()
end

addModEventListener(GarageMenu)

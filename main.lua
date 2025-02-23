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
source(GarageMenu.dir .. "gui/ItemsFrame.lua")

function GarageMenu:loadMap()
    g_gui:loadProfiles(GarageMenu.dir .. "gui/guiProfiles.xml")

    self.itemCache = {}
    self.brandCache = {}
    self.categoryData = nil

    self.garagePage = ShopCategoriesFrame:new()
    g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "garageFrame", self.garagePage, true)

    self.garagePage["onFrameOpen"] = Utils.overwrittenFunction(self.garagePage["onFrameOpen"], GarageMenu.onFrameOpen)
    self:configureGaragePage()

    self.garageItemsPage = ItemsFrame.new()
    g_gui:loadGui(GarageMenu.dir .. "gui/ItemsFrame.xml", "menuTaskList", self.garageItemsPage, true)    
    g_shopMenu.pagingElement:addElement(self.garageItemsPage)

    GarageMenu.addShopPage(self.garagePage, "menuGarageMenu", { 0, 0, 1024, 1024 },
        GarageMenu:makeIsGarageMenuCheckEnabledPredicate(), true, "pageUsedSale")

    g_currentMission.garageMenu = self
end

function GarageMenu.onFrameOpen()
    local self = g_currentMission.garageMenu

    local frameXml = "dataS/gui/InGameMenuStatisticsFrame.xml"
    local xmlFile = loadXMLFile("Temp", frameXml)
    saveXMLFileTo(xmlFile, g_currentMission.missionInfo.savegameDirectory .. "/InGameMenuStatisticsFrame.xml")

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
    self.garagePage:updatePagingButtons()
end

function GarageMenu:configureGaragePage()
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
                self.itemCache[itemXml].brand = self:getBrandFromRawName(item.brandNameRaw)
                self.itemCache[itemXml].categoryName = item.categoryName
                self.itemCache[itemXml].itemName = item.name
                self.itemCache[itemXml].canBeSold = item.canBeSold
                self.itemCache[itemXml].id = item.id
                self.itemCache[itemXml].imageFilename = item.imageFilename
                break
            end
        end
    end
end

function GarageMenu:getBrandFromRawName(rawName)
    if self.brandCache[rawName] ~= nil then
        return self.brandCache[rawName]
    end

    for brandIndex, brandItem in pairs(g_brandManager.indexToBrand) do
        if brandItem ~= nil then
            if brandItem.name == rawName then
                self.brandCache[rawName] = brandItem -- image, imageOffset, name, title (friendly)
                return self.brandCache[rawName]
            end
        else
            break
        end
    end
end

function GarageMenu:getCurrentFarmId()
    local currentFarmId = -1
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if farm ~= nil then
        return farm.farmId
    end
    return currentFarmId -- Not sure can happen!
end

function GarageMenu.onClickItemCategory(categoryName, screenTitle, categoryDisplayName, baseCategoryIconUVs)
    local self = g_currentMission.garageMenu
    local categoryItems = g_shopController:getItemsByCategory(categoryName)
    local currentDisplayItems = categoryItems

    -- if self.state ~= 0 then
    local displayItems = {}
    local currentFarmId = self:getCurrentFarmId()
    local owned = g_currentMission.vehicleSystem.vehicles
    for _, item in owned do
        if item.ownerFarmId == currentFarmId then
            local xmlFileName = item.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            local itemCacheEntry = self.itemCache[xmlFileName]
            local itemCategoryName = self.itemCache[xmlFileName].categoryName

            -- local mapEntry = self.categoryData[itemCacheEntry.categoryName]
            if itemCategoryName == categoryName then
                table.insert(displayItems, {
                    xmlFileName = xmlFileName,
                    id = item.id,
                    brand = item.brand,
                    price = item.price -- might be base price
                })
            end
        end
    end
    -- for i = 1, #categoryItems do
    --     -- if self:getIsItemVisible(categoryItems[i].storeItem) then
    --     table.insert(displayItems, categoryItems[i])
    --     -- end
    -- end

    currentDisplayItems = displayItems
    -- end

    g_shopMenu.currentCategoryName = categoryName
    g_shopMenu.currentDisplayItems = currentDisplayItems
    g_shopMenu.currentCategoryFilter = ShopMenu.FILTER.OWNED
    g_shopMenu.currentItemDetailsType = ShopMenu.DETAILS.VEHICLE
    -- g_shopMenu.pageShopItemDetails:setDisplayItems(currentDisplayItems)

    -- g_shopMenu.pageShopItemDetails:setCategory(baseCategoryIconUVs, categoryDisplayName, categoryDisplayName)
    -- g_shopMenu:pushDetail(g_shopMenu.pageShopItemDetails)

    self.garageItemsPage:setDisplayItems(currentDisplayItems)

    self.garageItemsPage:setCategory(baseCategoryIconUVs, categoryDisplayName, categoryName)
    g_shopMenu:pushDetail(self.garageItemsPage)
    -- g_shopMenu.pagingElement:setPage(g_shopMenu.pagingElement:getPageMappingIndexByElement(self.garageItemsPage))
    -- local targetIndex = g_shopMenu.pagingElement:getPageMappingIndexByElement(self.garageItemsPage)
    -- g_shopMenu:onPageChange(targetIndex)
end

function GarageMenu:makeIsGarageMenuCheckEnabledPredicate()
    return function() return true end
end

-- from Courseplay
function GarageMenu.addShopPage(frame, pageName, uvs, predicateFunc, addTab, insertAfter)
    -- local inGameMenu = g_shopMenu
    local targetPosition = 0

    -- remove all to avoid warnings
    for k, v in pairs({ pageName }) do
        g_shopMenu.controlIDs[v] = nil
    end

    for i = 1, #g_shopMenu.pagingElement.elements do
        local child = g_shopMenu.pagingElement.elements[i]
        if child == g_shopMenu[insertAfter] then
            targetPosition = i + 1;
            break
        end
    end

    g_shopMenu[pageName] = frame
    g_shopMenu.pagingElement:addElement(g_shopMenu[pageName])

    g_shopMenu:exposeControlsAsFields(pageName)

    for i = 1, #g_shopMenu.pagingElement.elements do
        local child = g_shopMenu.pagingElement.elements[i]
        if child == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pagingElement.elements, i)
            table.insert(g_shopMenu.pagingElement.elements, targetPosition, child)
            break
        end
    end

    for i = 1, #g_shopMenu.pagingElement.pages do
        local child = g_shopMenu.pagingElement.pages[i]
        if child.element == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pagingElement.pages, i)
            table.insert(g_shopMenu.pagingElement.pages, targetPosition, child)
            break
        end
    end

    g_shopMenu.pagingElement:updateAbsolutePosition()
    g_shopMenu.pagingElement:updatePageMapping()

    g_shopMenu:registerPage(g_shopMenu[pageName], nil, predicateFunc)

    if addTab == true then
        local iconFileName = Utils.getFilename('images/menuIcon.dds', GarageMenu.dir)
        g_shopMenu:addPageTab(g_shopMenu[pageName], iconFileName, GuiUtils.getUVs(uvs))
    end

    for i = 1, #g_shopMenu.pageFrames do
        local child = g_shopMenu.pageFrames[i]
        if child == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pageFrames, i)
            table.insert(g_shopMenu.pageFrames, targetPosition, child)
            break
        end
    end

    g_shopMenu:rebuildTabList()
end

addModEventListener(GarageMenu)

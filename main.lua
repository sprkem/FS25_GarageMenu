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

source(GarageMenu.dir .. "AttributeUtils.lua")
source(GarageMenu.dir .. "gui/MenuGarageMenu.lua")
source(GarageMenu.dir .. "gui/ItemsFrame.lua")

function GarageMenu:loadMap()
    g_gui:loadProfiles(GarageMenu.dir .. "gui/guiProfiles.xml")

    -- -- self.itemCache = {}
    -- self.brandCache = {}
    -- self.categoryData = nil

    -- self.garagePage = ShopCategoriesFrame:new()
    -- g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "garageFrame", self.garagePage, true)
    self.garagePage = MenuGarageMenu.new()
    g_gui:loadGui(GarageMenu.dir .. "gui/MenuGarageMenu.xml", "garageFrame", self.garagePage, false)
    self.garagePage:initialize()
    -- self.garagePage["onFrameOpen"] = Utils.overwrittenFunction(self.garagePage["onFrameOpen"], GarageMenu.onFrameOpen)
    -- self:configureGaragePage()

    self.garageItemsPage = ItemsFrame.new()
    g_gui:loadGui(GarageMenu.dir .. "gui/ItemsFrame.xml", "garageItemsFrame", self.garageItemsPage, false)
    g_shopMenu.pagingElement:addElement(self.garageItemsPage)    
    self.garageItemsPage:initialize()

    GarageMenu.addShopPage(self.garagePage, "menuGarageMenu", { 0, 0, 1024, 1024 },
        GarageMenu:makeIsGarageMenuCheckEnabledPredicate(), true, "pageUsedSale")

    g_currentMission.garageMenu = self
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
    -- local categoryItems = g_shopController:getItemsByCategory(categoryName)
    -- local currentDisplayItems = categoryItems

    -- if self.state ~= 0 then
    local displayItems = {}
    local currentFarmId = self:getCurrentFarmId()
    local owned = g_currentMission.vehicleSystem.vehicles
    for _, item in owned do
        if item.ownerFarmId == currentFarmId then
            local xmlFileName = item.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            -- local itemCacheEntry = self.itemCache[xmlFileName]
            local itemCategoryName = self.itemCache[xmlFileName].categoryName

            -- local mapEntry = self.categoryData[itemCacheEntry.categoryName]
            if itemCategoryName == categoryName then
                -- local x, _, z = getTranslation(item.rootNode)
                table.insert(displayItems, item)
            end
        end
    end

    self.garageItemsPage:setDisplayItems(displayItems)

    self.garageItemsPage:setCategory(baseCategoryIconUVs, categoryDisplayName, categoryName)
    g_shopMenu:pushDetail(self.garageItemsPage)
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

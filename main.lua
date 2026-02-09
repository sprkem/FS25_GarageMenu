--
-- FS25 - GarageMenu
--
-- @Author: Ozz
-- @Date: 28.02.2025
-- @Version: 1.0.0.0
--
-- Changelog:
--  v1.0.0.0:
--  - Initial Release


GarageMenu = {}
GarageMenu.dir = g_currentModDirectory
GarageMenu.modName = g_currentModName

source(GarageMenu.dir .. "gui/MenuGarageMenu.lua")
source(GarageMenu.dir .. "gui/ItemsFrame.lua")

function GarageMenu:loadMap()
    self.garagePage = MenuGarageMenu.new()
    g_gui:loadGui(GarageMenu.dir .. "gui/MenuGarageMenu.xml", "garageFrame", self.garagePage, false)
    self.garagePage:initialize()

    self.garageItemsPage = ItemsFrame.new()
    g_gui:loadGui(GarageMenu.dir .. "gui/ItemsFrame.xml", "garageItemsFrame", self.garageItemsPage, false)
    g_shopMenu.pagingElement:addElement(self.garageItemsPage)
    self.garageItemsPage:initialize()

    self.isBuyUsedEquipmentEnabled = false

    GarageMenu.addShopPage(self.garagePage, "menuGarageMenu", { 0, 0, 1024, 1024 },
        GarageMenu:makeIsGarageMenuCheckEnabledPredicate(), "pageUsedSale")

    g_currentMission.garageMenu = self
end

function GarageMenu:makeIsGarageMenuCheckEnabledPredicate()
    return function() return true end
end

-- from Courseplay
function GarageMenu.addShopPage(frame, pageName, uvs, predicateFunc, insertAfter)
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

    local iconFileName = Utils.getFilename('images/menuIcon.dds', GarageMenu.dir)
    g_shopMenu:addPageTab(g_shopMenu[pageName], iconFileName, GuiUtils.getUVs(uvs))

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

function GarageMenu:onStartMission()
    if g_modIsLoaded["FS25_BuyUsedEquipment"] then g_currentMission.garageMenu.isBuyUsedEquipmentEnabled = true end
end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, GarageMenu.onStartMission)

addModEventListener(GarageMenu)

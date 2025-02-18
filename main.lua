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

    local guiGarageMenu = MenuGarageMenu.new(g_i18n)
    g_gui:loadGui(GarageMenu.dir .. "gui/MenuGarageMenu.xml", "menuGarageMenu", guiGarageMenu, true)

    GarageMenu.fixInGameMenu(guiGarageMenu, "menuGarageMenu", { 0, 0, 1024, 1024 }, 2,
        GarageMenu:makeIsGarageMenuCheckEnabledPredicate())


    guiGarageMenu:initialize()
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
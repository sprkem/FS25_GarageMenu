MenuGarageMenu = {}
MenuGarageMenu.currentTasks = {}
MenuGarageMenu._mt = Class(MenuGarageMenu, TabbedMenuFrameElement)

function MenuGarageMenu.new(i18n, messageCenter)
    local self = MenuGarageMenu:superClass().new(nil, MenuGarageMenu._mt)
    self.name = "menuGarageMenu"
    self.i18n = i18n
    self.messageCenter = messageCenter

    self.dataBindings = {}
    self.itemCache = {}

    return self
end

function MenuGarageMenu:delete()
    MenuGarageMenu:superClass().delete(self)
end

function MenuGarageMenu:copyAttributes(src)
    MenuGarageMenu:superClass().copyAttributes(self, src)
    self.i18n = src.i18n
end

function MenuGarageMenu:onGuiSetupFinished()
    MenuGarageMenu:superClass().onGuiSetupFinished(self)
end

function MenuGarageMenu:initialize()
end

function MenuGarageMenu:onFrameOpen()
    MenuGarageMenu:superClass().onFrameOpen(self)
    self:updateContent()
    FocusManager:setFocus(self.currentTasksTable)
end

function MenuGarageMenu:onFrameClose()
    MenuGarageMenu:superClass().onFrameClose(self)
end

function MenuGarageMenu:updateContent()
    print("MenuGarageMenu:updateContent()")
    local currentFarmId = 1 -- TODO - fix this
    local dataByCategory = {}
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == currentFarmId then
            local xmlFileName = vehicle.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            local category = self.itemCache[xmlFileName].category
            if dataByCategory[category] == nil then dataByCategory[category] = {} end
            table.insert(dataByCategory[category], self.itemCache[xmlFileName])
        end
    end
    DebugUtil.printTableRecursively(dataByCategory)

    for _, category in pairs(g_storeManager.categories) do
        if dataByCategory[category.name] ~= nil then
            print("Showing " .. category.title) -- NB: category also has image we can use
        end
    end

end

function MenuGarageMenu:storeItemDetails(itemXml)
    self.itemCache[itemXml] = {}
    for index, item in pairs(g_storeManager.items) do
        if item ~= nil then
            if item.xmlFilename == itemXml then
                self.itemCache[itemXml].category = item.categoryName
                self.itemCache[itemXml].itemName = item.name
                break
            end
        end
    end
    return
end

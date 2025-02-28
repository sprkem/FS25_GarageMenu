MenuGarageMenu = {}
MenuGarageMenu._mt = Class(MenuGarageMenu, TabbedMenuFrameElement)

function MenuGarageMenu.new()
    local self = MenuGarageMenu:superClass().new(nil, MenuGarageMenu._mt)
    self.name = "menuGarageMenu"

    self.dataBindings = {}
    self.itemCache = {}
    self.categories = nil
    self.categoryTypes = nil

    self.btnBack = {
        inputAction = InputAction.MENU_BACK
    }
    self.btnPreviousPage = {
        text = g_i18n:getText("ui_ingameMenuPrev"),
        inputAction = InputAction.MENU_PAGE_PREV
    }
    self.btnNextPage = {
        text = g_i18n:getText("ui_ingameMenuNext"),
        inputAction = InputAction.MENU_PAGE_NEXT
    }
    self.btnToggleView = {
        text = g_i18n:getText("ui_switchMode"),
        inputAction = InputAction.MENU_EXTRA_1,
        callback = function()
            self:toggleView()
        end
    }
    self.btnSelectCategory = {
        text = g_i18n:getText("button_select"),
        inputAction = InputAction.MENU_ACCEPT,
        callback = function()
            self:onOpenCategory()
        end
    }
    self:setMenuButtonInfo({
        self.btnBack,
        self.btnNextPage,
        self.btnPreviousPage,
        self.btnSelectCategory,
        self.btnToggleView
    })

    return self
end

function MenuGarageMenu:setSectionData()
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    self.sectionData = {}
    for index, detail in pairs(inGameMenu.pageShopVehicles.categoryTypes) do
        self.sectionData[detail.name] = {
            index = index,
            title = detail.title
        }
    end
end

function MenuGarageMenu:getCurrentFarmId()
    local currentFarmId = -1
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if farm ~= nil then
        return farm.farmId
    end
    return currentFarmId -- Not sure can happen!
end

function MenuGarageMenu:setCategoryData()
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    self.categoryData = {}
    for sectionID, entries in pairs(inGameMenu.pageShopVehicles.categories) do
        for _, category in pairs(entries) do
            self.categoryData[category.id] = {
                sectionID = sectionID,
                iconFilename = category.iconFilename,
                label = category.label,
                sortValue = category.sortValue
            }
        end
    end
end

function MenuGarageMenu:storeItemDetails(itemXml)
    self.itemCache[itemXml] = {}
    for index, item in pairs(g_storeManager.items) do
        if item ~= nil then
            if item.xmlFilename == itemXml then
                StoreItemUtil.loadSpecsFromXML(item)
                self.itemCache[itemXml].configurations = item.configurations
                self.itemCache[itemXml].categoryName = item.categoryName
                self.itemCache[itemXml].itemName = item.name
                self.itemCache[itemXml].canBeSold = item.canBeSold
                self.itemCache[itemXml].id = item.id
                self.itemCache[itemXml].imageFilename = item.imageFilename
                self.itemCache[itemXml].specs = item.specs
                break
            end
        end
    end
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
    self.categoryList:setDataSource(self)
    self.categoryList:setDelegate(self)
end

function MenuGarageMenu:initialize()
    self.categoryHeaderText:setText(g_i18n:getText("shop_ownedItems"))
end

function MenuGarageMenu:onFrameOpen()
    print("MenuGarageMenu:onFrameOpen")
    MenuGarageMenu:superClass().onFrameOpen(self)
    g_messageCenter:subscribe(SellVehicleEvent, self.updateContent, self)
    self:setMenuButtonInfoDirty()
    self.propertyState = VehiclePropertyState.OWNED
    self:updateContent()
end

function MenuGarageMenu:onFrameClose()
    print("MenuGarageMenu:onFrameClose")
    MenuGarageMenu:superClass().onFrameClose(self)
    g_messageCenter:unsubscribeAll(self)
end

function MenuGarageMenu:toggleView()
    if self.propertyState == VehiclePropertyState.OWNED then
        self.propertyState = VehiclePropertyState.LEASED
    else
        self.propertyState = VehiclePropertyState.OWNED
    end
    self:updateContent()
end

function MenuGarageMenu:updateContent()
    if self.propertyState == VehiclePropertyState.OWNED then
        self.categoryHeaderText:setText(g_i18n:getText("shop_ownedItems"))
    else
        self.categoryHeaderText:setText(g_i18n:getText("shop_leasedItems"))
    end

    if self.sectionData == nil then
        self:setSectionData()
    end

    if self.categoryData == nil then
        self:setCategoryData()
    end

    local currentFarmId = self:getCurrentFarmId()
    local dataByCategory = {}

    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == currentFarmId and vehicle.propertyState == self.propertyState then
            local xmlFileName = vehicle.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            local itemCacheEntry = self.itemCache[xmlFileName]
            local mapEntry = self.categoryData[itemCacheEntry.categoryName]

            if dataByCategory[mapEntry.sectionID] == nil then
                dataByCategory[mapEntry.sectionID] = {
                    id = mapEntry.sectionID,
                    categories = {}
                }
            end

            local categoryIndex = mapEntry.sortValue + 1
            if dataByCategory[mapEntry.sectionID].categories[categoryIndex] == nil then
                dataByCategory[mapEntry.sectionID].categories[categoryIndex] = {
                    categoryName = itemCacheEntry.categoryName,
                    iconFilename = mapEntry.imageFilename,
                    label = mapEntry.label,
                }
            end
        end
    end

    self.renderData = {}
    for index, detail in pairs(g_shopMenu.pageShopVehicles.categoryTypes) do
        if detail.name ~= "OBJECTS" then
            if dataByCategory[detail.name] ~= nil then
                local toInsert = {
                    id         = dataByCategory[detail.name].id,
                    categories = {}
                }
                for _, category in pairs(dataByCategory[detail.name].categories) do
                    table.insert(toInsert.categories, category)
                end

                table.insert(self.renderData, toInsert)
            end
        end
    end

    if #self.renderData == 0 then
        self.noItemsText:setVisible(true)
    else
        self.noItemsText:setVisible(false)
    end

    self.categoryList:reloadData()
end

function MenuGarageMenu:getNumberOfSections()
    return #self.renderData
end

function MenuGarageMenu:getNumberOfItemsInSection(list, section)
    local count = #self.renderData[section].categories
    return count
end

function MenuGarageMenu:getTitleForSectionHeader(list, section)
    local sectionId = self.renderData[section].id
    return self.sectionData[sectionId].title
end

function MenuGarageMenu:getCellTypeForItemInSection(list, section, index)
    return "category"
end

function MenuGarageMenu:populateCellForItemInSection(list, section, index, cell)
    local category = self.renderData[section].categories[index]
    local categoryInfo = self.categoryData[category.categoryName]
    cell:getAttribute("icon"):setImageFilename(categoryInfo.iconFilename)
    cell:getAttribute("title"):setText(categoryInfo.label)
end

function MenuGarageMenu:onOpenCategory(_, _, _, _)
    local section = self.renderData[self.categoryList.selectedSectionIndex]
    local index = self.categoryList.selectedIndex
    local itemsPage = g_currentMission.garageMenu.garageItemsPage
    if section ~= nil and section.categories[index] ~= nil then
        local categoryName = section.categories[index].categoryName
        itemsPage:setContent(self:getItemsForCategory(categoryName), section.categories[index].label, self.propertyState)
        g_shopMenu:pushDetail(itemsPage)
    end
end

function MenuGarageMenu:getItemsForCategory(categoryName)
    local currentFarmId = self:getCurrentFarmId()
    local items = {}
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == currentFarmId and vehicle.propertyState == self.propertyState then
            local xmlFileName = vehicle.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end
            local itemCacheEntry = self.itemCache[xmlFileName]
            if itemCacheEntry.categoryName == categoryName then
                table.insert(items, vehicle)
            end
        end
    end
    return items
end

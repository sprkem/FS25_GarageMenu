ItemsFrame = {}
ItemsFrame._mt = Class(ItemsFrame, TabbedMenuFrameElement)

function ItemsFrame.new()
    local self = ItemsFrame:superClass().new(nil, ItemsFrame._mt)
    self.name = "itemsFrame"

    self.items = nil
    self.elementCache = {}
    self.toScroll = {}

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
    self.btnSellOrReturn = {
        text = g_i18n:getText("ui_sellItem"),
        inputAction = InputAction.MENU_CANCEL,
        callback = function()
            self:showSellSelected()
        end
    }
    self.btnViewOnMap = {
        text = g_i18n:getText("button_viewOnMap"),
        inputAction = InputAction.MENU_ACTIVATE,
        callback = function()
            self:onVehicleViewOnMap()
        end
    }
    self.btnEnterVehicle = {
        text = g_i18n:getText("button_enterVehicle"),
        inputAction = InputAction.MENU_ACCEPT,
        callback = function()
            self:onTryEnterVehicle()
        end
    }
    self:setMenuButtonInfo({
        self.btnBack,
        self.btnNextPage,
        self.btnPreviousPage,
        self.btnViewOnMap,
        self.btnEnterVehicle,
        self.btnSellOrReturn
    })

    return self
end

function ItemsFrame:update(dt)
    ItemsFrame:superClass().update(self, dt)
    self:updateScrollingAnimation(dt)
end

function ItemsFrame:updateScrollingAnimation(dt)
    for k, v in pairs(self.toScroll) do
        local x = k.absSize[1]
        local parentX = k.parent.absSize[1]
        local difference = x - parentX
        local speed = 5000 * (x / parentX)
        local next = v + dt
        if speed <= next then
            next = -speed
        end
        k:setPosition(-(difference * MathUtil.smoothstep(0.1, 0.9, math.abs(next) / speed)))
        self.toScroll[k] = next
    end
end

function ItemsFrame:setTemplates()
    self.detailTemplate = self.attributesLayout:getDescendantByName("detailTemplate")
    self.valueTemplate = self.attributesLayout:getDescendantByName("valueTemplate")
    self.fillTypesTemplate = self.attributesLayout:getDescendantByName("fillTypesTemplate")
    self.detailTemplate:setVisible(false)
    self.valueTemplate:setVisible(false)
    self.fillTypesTemplate:setVisible(false)
end

function ItemsFrame:delete()
    ItemsFrame:superClass().delete(self)
end

function ItemsFrame:copyAttributes(src)
    ItemsFrame:superClass().copyAttributes(self, src)
    self.i18n = src.i18n
end

function ItemsFrame:onGuiSetupFinished()
    ItemsFrame:superClass().onGuiSetupFinished(self)
    self.itemsList:setDataSource(self)
    self.itemsList:setDelegate(self)
end

function ItemsFrame:initialize()
    self:setTemplates()
end

function ItemsFrame:onFrameOpen()
    self.detailBox:setVisible(true)
    self.itemDetailsMap:setIngameMap(g_currentMission.hud:getIngameMap())
    ItemsFrame:superClass().onFrameOpen(self)
end

function ItemsFrame:onFrameClose()
    self.itemsList.selectedIndex = 1
    ItemsFrame:superClass().onFrameClose(self)
end

function ItemsFrame:setContent(items, categoryName, categoryDisplayName, propertyState)
    self.items = items
    if self.items == nil then
        return
    end

    self.propertyState = propertyState
    self.categoryItems = g_shopController:getItemsByCategory(categoryName)
    self.categoryDisplayName = categoryDisplayName
    self.itemsHeaderText:setText(categoryDisplayName)

    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        self.btnSellOrReturn.disabled = true
        self.btnViewOnMap.disabled = true
        self.btnEnterVehicle.disabled = true
    else
        self.btnSellOrReturn.disabled = false
        self.btnViewOnMap.disabled = false
        self.btnEnterVehicle.disabled = false
    end

    if self.propertyState == VehiclePropertyState.OWNED then
        self.btnSellOrReturn.text = g_i18n:getText("ui_sellItem")
    else
        self.btnSellOrReturn.text = g_i18n:getText("ui_returnThis")
    end
    self:setMenuButtonInfoDirty()
    self.itemsList:reloadData()
end

function ItemsFrame:getNumberOfSections()
    return 1
end

function ItemsFrame:getNumberOfItemsInSection(list, section)
    return #self.items
end

function ItemsFrame:getTitleForSectionHeader(list, section)
    return ""
end

function ItemsFrame:populateCellForItemInSection(list, section, index, cell)
    local item = self.items[index]
    local menuPage = g_currentMission.garageMenu.garagePage

    local xmlFilename = self:getItemXMLFileName(item)
    local storeItem = menuPage.itemCache[xmlFilename]

    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        storeItem = self:getUsedVehicleStoreItem(xmlFilename)
    end

    cell:getAttribute("icon"):setImageFilename(storeItem.imageFilename)
    cell:getAttribute("title"):setText(self:getItemName(item, storeItem))
    cell:getAttribute("brandIcon"):setImageFilename(self:getBrandIconFilename(item, storeItem))

    local valueText = ""
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        valueText = tostring(math.floor(item.ttl / 24) + 1)
    elseif item.propertyState == VehiclePropertyState.OWNED then
        valueText = item:getSellPrice()
    elseif item.propertyState == VehiclePropertyState.LEASED then
        valueText = item.price *
            (EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR)
    end

    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        cell:getAttribute("value"):setText(string.format(g_i18n:getText("garage_used_equipment_ttl_format"), valueText))
    else
        cell:getAttribute("value"):setText(g_i18n:formatMoney(valueText, 0, 0, true))
    end
end

function ItemsFrame:getUsedVehicleStoreItem(xmlFilename)
    for _, categoryItem in pairs(self.categoryItems) do
        if categoryItem.storeItem.xmlFilename == xmlFilename then
            return categoryItem.storeItem
        end
    end
end

function ItemsFrame:getUsedVehicleCategoryItem(xmlFilename)
    for _, categoryItem in pairs(self.categoryItems) do
        if categoryItem.storeItem.xmlFilename == xmlFilename then
            return categoryItem
        end
    end
end

function ItemsFrame:getBrandIconFilename(item, storeItem)
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
        return brand.image
    end
    return item.brand.image
end

function ItemsFrame:getItemXMLFileName(item)
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        return item.filename
    end
    return item.xmlFile.filename
end

function ItemsFrame:getItemName(item, storeItem)
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        return storeItem.name
    end
    return item:getFullName()
end

function ItemsFrame:onListSelectionChanged(list, section, index)
    local menuPage = g_currentMission.garageMenu.garagePage
    local vehicle = self.items[index]

    local xmlFilename = self:getItemXMLFileName(vehicle)
    local storeItem = menuPage.itemCache[xmlFilename]
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        storeItem = self:getUsedVehicleStoreItem(xmlFilename)
    end

    self.itemDetailsImage:setImageFilename(storeItem.imageFilename)
    self.itemDetailsName:setText(self:getItemName(vehicle, storeItem))

    for k, element in pairs(self.elementCache) do
        element:setVisible(false)
    end

    for k, _ in pairs(self.toScroll) do
        self.toScroll[k] = nil
    end

    for k, v in pairs(self.elementCache) do
        v:delete()
        self.elementCache[k] = nil
    end

    local displayItem = nil
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        displayItem = self:getUsedVehicleCategoryItem(xmlFilename)
    else
        if vehicle.getIsEnterableFromMenu == nil or not vehicle:getIsEnterableFromMenu() then
            self.btnEnterVehicle.disabled = true
        else
            self.btnEnterVehicle.disabled = false
        end
        self:setMenuButtonInfoDirty()

        local item = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        displayItem = g_shopController:makeDisplayItem(item, vehicle, vehicle.configurations)
    end

    self:displayAttributes(displayItem)
    local fillTypes = FillUnit.getSpecValueFillTypes(storeItem, vehicle)
    local seedFillTypes = SowingMachine.getSpecValueSeedFillTypes(storeItem, vehicle)

    self:updateFillTypes(self.fruitIconTemplate, fillTypes, "gui.storeAttribute_crops")
    self:updateFillTypes(self.fruitIconTemplate, seedFillTypes, "gui.storeAttribute_seeding")

    self.attributesLayout:invalidateLayout()

    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        local storePlace = g_currentMission.storeSpawnPlaces[1]
        self.itemDetailsMap:setCenterToWorldPosition(storePlace.startX, storePlace.startZ)
    else
        local x, _, z = getTranslation(vehicle.rootNode)
        self.itemDetailsMap:setCenterToWorldPosition(x, z)
    end

    self.itemDetailsMap:setMapZoom(7)
    self.itemDetailsMap:setMapAlpha(1)
end

function ItemsFrame:displayAttributes(displayItem)
    for k, profile in displayItem.attributeIconProfiles do
        local element = self.detailTemplate:clone(self.attributesLayout)
        table.insert(self.elementCache, element)

        local iconElement = element:getDescendantByName("icon")
        iconElement:applyProfile(profile)
        local textElement = element:getDescendantByName("text")
        textElement:setText(displayItem.attributeValues[k])
        element:setVisible(true)
        element:setSize(textElement.size[1] + iconElement.size[1] + 0.0025, textElement.size[2])
    end
end

function ItemsFrame:updateFillTypes(template, fillTypes, slice)
    if fillTypes == nil then
        return
    end

    local element = self.fillTypesTemplate:clone(self.attributesLayout)
    table.insert(self.elementCache, element)

    element:setVisible(true)
    local iconsLayoutBox = element.elements[3]

    local icon = element:getDescendantByName("icon")
    local iconsLayout = iconsLayoutBox:getDescendantByName("iconsLayout")
    icon:setImageSlice(nil, slice)

    iconsLayout.elements = {}

    local cumulSize = 0
    for _, fillTypeId in pairs(fillTypes) do
        local fillType = g_fillTypeManager.indexToFillType[fillTypeId]
        local image = fillType.hudOverlayFilename
        local fruitElement = template:clone(iconsLayout)
        fruitElement:setVisible(true)
        fruitElement:setImageFilename(image)
        cumulSize = cumulSize + fruitElement.absSize[1] + fruitElement.margin[1] + fruitElement.margin[3]
    end

    local toFit = self.attributesLayout.absSize[1] * 0.91
    local space = math.min(toFit, cumulSize)
    local availableSpace = space + icon.absSize[1] + icon.margin[1]

    iconsLayout:setSize(cumulSize, nil)
    iconsLayout:setPosition(0, nil)
    iconsLayout.parent:setSize(space, nil)

    iconsLayout:invalidateLayout()
    if availableSpace < cumulSize then
        self.toScroll[iconsLayout] = 0
        return
    end
    self.toScroll[iconsLayout] = nil
end

function ItemsFrame:showSellSelected()
    if self.propertyState == MenuGarageMenu.CUSTOM_VIEW_MODE.BUY_USED_EQUIPMENT then
        return
    end

    local vehicle = self.items[self.itemsList.selectedIndex]

    local label = nil
    if self.propertyState == VehiclePropertyState.OWNED then
        label = g_i18n:getText("ui_youWantToSellVehicle")
    else
        label = g_i18n:getText("ui_youWantToReturnVehicle")
    end

    YesNoDialog.show(
        function(self, clickOk)
            if clickOk then
                g_client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle, 1, true))
                if self.propertyState == VehiclePropertyState.OWNED then
                    InfoDialog.show(g_i18n:getText("shop_messageSoldVehicle"))
                else
                    InfoDialog.show(g_i18n:getText("shop_messageReturnedVehicle"))
                end
                local garagePage = g_currentMission.garageMenu.garagePage
                g_shopMenu.pagingElement:setPage(g_shopMenu.pagingElement:getPageMappingIndexByElement(garagePage))
            end
        end, self,
        label)
end

function ItemsFrame:onVehicleViewOnMap()
    local vehicle = self.items[self.itemsList.selectedIndex]
    local garagePage = g_currentMission.garageMenu.garagePage
    g_shopMenu.pagingElement:setPage(g_shopMenu.pagingElement:getPageMappingIndexByElement(garagePage))
    g_inGameMenu:openMapOverview()
    g_inGameMenu.pageMapOverview:showMapHotspot(vehicle:getMapHotspot())
end

function ItemsFrame:onTryEnterVehicle()
    local vehicle = self.items[self.itemsList.selectedIndex]
    if vehicle ~= nil and (vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()) then
        local garagePage = g_currentMission.garageMenu.garagePage
        g_shopMenu.pagingElement:setPage(g_shopMenu.pagingElement:getPageMappingIndexByElement(garagePage))
        g_gui:showGui("")
        g_localPlayer:requestToEnterVehicle(vehicle)
    end
end

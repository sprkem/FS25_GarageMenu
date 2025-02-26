ItemsFrame = {}
ItemsFrame._mt = Class(ItemsFrame, TabbedMenuFrameElement)

function ItemsFrame.new(i18n, messageCenter)
    local self = ItemsFrame:superClass().new(nil, ItemsFrame._mt)
    self.name = "itemsFrame"
    self.i18n = i18n
    self.messageCenter = messageCenter

    self.dataBindings = {}
    self.items = nil
    self.elementCache = {}

    self.itemsBtnBack = {
        inputAction = InputAction.MENU_BACK
    }
    self.itemsBtnActivate = {
        text = self.i18n:getText("garage_menu_sell"),
        inputAction = InputAction.MENU_ACTIVATE,
        callback = function()
            self:showSellSelected()
        end
    }
    self:setMenuButtonInfo({
        self.itemsBtnBack,
        self.itemsBtnActivate
    })

    return self
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
end

function ItemsFrame:onFrameOpen()
    self.detailBox:setVisible(true)
    --self.itemDetailsMap.ingameMap = g_currentMission.hud:getIngameMap()
    self.itemDetailsMap:setIngameMap(g_currentMission.hud:getIngameMap())
    ItemsFrame:superClass().onFrameOpen(self)
    -- Need to refresh buttons on load as with pushDetails we get shop defaults instead otherwise
    self:setMenuButtonInfoDirty()
    self:updateContent()
end

function ItemsFrame:onFrameClose()
    ItemsFrame:superClass().onFrameClose(self)
    self.itemsList.selectedIndex = 1
end

function ItemsFrame:setDisplayItems(items)
    self.items = items
end

function ItemsFrame:setCategory(categoryDisplayName, categoryName)
    self.categoryName = categoryName
    self.categoryDisplayName = categoryDisplayName
    self.itemsHeaderText:setText(categoryDisplayName)
end

function ItemsFrame:updateContent()
    if self.items == nil then
        return
    end
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
    local itemCacheEntry = menuPage.itemCache[item.xmlFile.filename]
    cell:getAttribute("icon"):setImageFilename(itemCacheEntry.imageFilename)
    cell:getAttribute("brandIcon"):setImageFilename(item.brand.image)
    cell:getAttribute("title"):setText(itemCacheEntry.itemName)
    cell:getAttribute("value"):setText(g_i18n:formatMoney(item:getSellPrice(), 0, 0, true))
end

function ItemsFrame:onListSelectionChanged(list, section, index)
    print("onListSelectionChanged:" .. index)
    local menuPage = g_currentMission.garageMenu.garagePage
    -- TODO - update details panel
    local item = self.items[index]
    local itemCacheEntry = menuPage.itemCache[item.xmlFile.filename]
    self.itemDetailsImage:setImageFilename(itemCacheEntry.imageFilename)
    self.itemDetailsName:setText(item.brand.title .. " " .. itemCacheEntry.itemName)

    for k, element in pairs(self.elementCache) do
        -- element:setVisible(false)
        element.parent:removeElement(element)
    end

    self.elementCache = AttributeUtils.createAttributeElements(self.elementCache, self.detailTemplate, self.attributesLayout, item,
        itemCacheEntry)

    self.attributesLayout:invalidateLayout()

    local x, _, z = getTranslation(item.rootNode)
    self.itemDetailsMap:setCenterToWorldPosition(x, z)
end

function ItemsFrame:showSellSelected()
    local item = self.items[self.itemsList.selectedIndex]

    YesNoDialog.show(
        function(self, clickOk)
            if clickOk then
                g_client:getServerConnection():sendEvent(SellVehicleEvent.new(item, 1, true))
                self:updateContent()
            end
        end, self,
        g_i18n:getText("garage_menu_confirm_sell"))
end

ItemsFrame = {}
ItemsFrame._mt = Class(ItemsFrame, TabbedMenuFrameElement)

function ItemsFrame.new(i18n, messageCenter)
    local self = ItemsFrame:superClass().new(nil, ItemsFrame._mt)
    self.name = "itemsFrame"
    self.i18n = i18n
    self.messageCenter = messageCenter

    self.dataBindings = {}
    self.items = nil

    self.itemsBtnBack = {
        inputAction = InputAction.MENU_BACK
    }
    self.itemsBtnActivate = {
        -- text = self.i18n:getText("ui_manage_tasks"),
        text = "Sell(L)",
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
    self.itemDetailsMap.ingameMap = g_currentMission.hud:getIngameMap()
    ItemsFrame:superClass().onFrameOpen(self)
    -- Need to refresh buttons on load as with pushDetails we get shop defaults instead otherwise
    self:setMenuButtonInfoDirty()
    self:updateContent()
end

function ItemsFrame:onFrameClose()
    ItemsFrame:superClass().onFrameClose(self)
end

function ItemsFrame:setDisplayItems(items)
    self.items = items
end

function ItemsFrame:setCategory(baseCategoryIconUVs, categoryDisplayName, categoryName)
    self.baseCategoryIconUVs = baseCategoryIconUVs
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
    local item           = self.items[index]
    local itemCacheEntry = g_currentMission.garageMenu.itemCache[item.xmlFileName]
    cell:getAttribute("icon"):setImageFilename(itemCacheEntry.imageFilename)
    cell:getAttribute("brandIcon"):setImageFilename(item.brand.image)
    cell:getAttribute("title"):setText(itemCacheEntry.itemName)
    cell:getAttribute("value"):setText(item.price)
    -- cell:getAttribute("section"):setText(self.renderData[section].name)
    -- cell:getAttribute("brandIcon"):setText(category.iconFilename) -- TODO copy get from raw from reference
end

function ItemsFrame:onListSelectionChanged(list, section, index)
    print("onListSelectionChanged:" .. index)
    -- TODO - update details panel
    local item = self.items[self.itemsList.selectedIndex]
    local itemCacheEntry = g_currentMission.garageMenu.itemCache[item.xmlFileName]
    self.itemDetailsImage:setImageFilename(itemCacheEntry.imageFilename)
    self.itemDetailsName:setText(itemCacheEntry.brand.title .. " " .. itemCacheEntry.itemName)
end

function ItemsFrame:showSellSelected()
    print("Sell selected")
    local selected = self.items[self.itemsList.selectedIndex]
end

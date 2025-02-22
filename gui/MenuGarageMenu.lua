MenuGarageMenu = {}
MenuGarageMenu._mt = Class(MenuGarageMenu, TabbedMenuFrameElement)

function MenuGarageMenu.new(i18n, messageCenter)
    local self = MenuGarageMenu:superClass().new(nil, MenuGarageMenu._mt)
    self.name = "menuGarageMenu"
    self.i18n = i18n
    self.messageCenter = messageCenter

    self.dataBindings = {}
    self.itemCache = {}
    self.renderData = {}

    self.sectionData = nil
    self.categoryData = nil

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

function MenuGarageMenu:setCategoryData()
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    self.categoryData = {}
    -- local categoryIndex = 1 -- TODO remove
    for sectionID, entries in pairs(inGameMenu.pageShopVehicles.categories) do
        -- TODO - get category index here and add to value
        -- local nextIndex = 1

        for _, category in pairs(entries) do
            self.categoryData[category.id] = {
                sectionID    = sectionID,
                iconFilename = category.iconFilename,
                label        = category.label,
                -- categoryIndex = k,
                sortValue    = category.sortValue,
                -- categoryIndex    = categoryIndex
            }
            -- nextIndex = nextIndex + 1
        end
        -- categoryIndex = categoryIndex + 1 -- TODO remove
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
end

function MenuGarageMenu:onFrameOpen()
    MenuGarageMenu:superClass().onFrameOpen(self)
    self:updateContent()
end

function MenuGarageMenu:onFrameClose()
    MenuGarageMenu:superClass().onFrameClose(self)
end

function MenuGarageMenu:updateContent()
    local inGameMenu = g_gui.screenControllers[ShopMenu]
    --     local shopXml = inGameMenu.xmlFilename
    -- local frameXml = "dataS/gui/ShopCategoriesFrame.xml"
    -- local xmlFile = loadXMLFile("Temp", frameXml)
    -- saveXMLFileTo(xmlFile, g_currentMission.missionInfo.savegameDirectory .. "/ShopCategoriesFrame.xml")

    if self.sectionData == nil then
        self:setSectionData()
    end

    if self.categoryData == nil then
        self:setCategoryData()
    end

    print("MenuGarageMenu:updateContent()")
    local currentFarmId = 1 -- TODO - fix this
    self.renderData = {}
    local sectionIndexMap = {}
    -- local categoryIndexMap = {}
    local nextSectionIndex = 1
    for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.ownerFarmId == currentFarmId then
            local xmlFileName = vehicle.xmlFile.filename
            if self.itemCache[xmlFileName] == nil then self:storeItemDetails(xmlFileName) end

            local itemCacheEntry = self.itemCache[xmlFileName]
            local itemCategoryName = self.itemCache[xmlFileName].categoryName

            local mapEntry = self.categoryData[itemCacheEntry.categoryName]
            if mapEntry.sectionID ~= "OBJECTS" then
                if sectionIndexMap[mapEntry.sectionID] == nil then
                    sectionIndexMap[mapEntry.sectionID] = {
                        sectionIndex = nextSectionIndex,
                        nextCategoryIndex = 1,
                        categories = {}
                    }
                    self.renderData[nextSectionIndex] = {
                        iconFilename = mapEntry.iconFilename,
                        id = mapEntry.sectionID,
                        categories = {}
                    }
                    nextSectionIndex = nextSectionIndex + 1
                end

                local sectionIndexMapEntry = sectionIndexMap[mapEntry.sectionID]
                local sectionIndex = sectionIndexMap[mapEntry.sectionID].sectionIndex

                if sectionIndexMap[mapEntry.sectionID].categories[itemCategoryName] == nil then
                    sectionIndexMap[mapEntry.sectionID].categories[itemCategoryName] = {
                        categoryIndex = sectionIndexMapEntry.nextCategoryIndex
                    }
                    self.renderData[sectionIndex].categories[sectionIndexMapEntry.nextCategoryIndex] = {
                        name = itemCategoryName,
                        iconFilename = mapEntry.iconFilename,
                        label = mapEntry.label,
                        items = {},
                    }
                    sectionIndexMapEntry.nextCategoryIndex = sectionIndexMapEntry.nextCategoryIndex + 1
                end

                local categoryIndex = sectionIndexMap[mapEntry.sectionID].categories[itemCategoryName].categoryIndex

                table.insert(self.renderData[sectionIndex].categories[categoryIndex].items, self.itemCache[xmlFileName])
            end
        end
    end
    DebugUtil.printTableRecursively(self.renderData)
    self.categoryList:reloadData()
end

function MenuGarageMenu:storeItemDetails(itemXml)
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

function MenuGarageMenu:getNumberOfSections()
    return #self.renderData
end

function MenuGarageMenu:getNumberOfItemsInSection(list, section)
    return #self.renderData[section].categories
end

function MenuGarageMenu:getTitleForSectionHeader(list, section)
    return self.sectionData[self.renderData[section].id].title
end

function MenuGarageMenu:getCellTypeForItemInSection(list, section, index)
    return "category"
end

function MenuGarageMenu:populateCellForItemInSection(list, section, index, cell)
    local category = self.renderData[section].categories[index]
    cell:getAttribute("icon"):setImageFilename(category.iconFilename)
    cell:getAttribute("title"):setText(category.label)
    -- cell:getAttribute("value"):setText(category.label)
    -- cell:getAttribute("section"):setText(self.renderData[section].name)
    -- cell:getAttribute("brandIcon"):setText(category.iconFilename) -- TODO copy get from raw from reference
end

function MenuGarageMenu:onOpenCategory(list, sectionIndex, index, element)
    local section = self.renderData[sectionIndex]
    if section ~= nil and section.categories[index] ~= nil then
        DebugUtil.printTableRecursively(section.categories[index])
        g_shopMenu.pagingElement:setPage(1)
        -- local frame = g_gui:showDialog("itemsFrame")
        -- if frame ~= nil then
        --     print("frame is not nil")
        -- end
    end
end

-- function MenuGarageMenu:onListSelectionChanged(list, section, index)
--     self.selectedGroupIndex = index
-- end

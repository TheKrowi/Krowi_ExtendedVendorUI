-- [[ Namespaces ]] --
local _, addon = ...;

KrowiV_ScrollableListMixin = {};

function KrowiV_ScrollableListMixin:OnLoad()
    self.DataProvider = CreateDataProvider();
    self.DataProvider:SetSortComparator(function (a, b) return a.Name < b.Name end, true);

    local elementExtent = 30; -- Better performance if hardcoded, must be same height as KrowiV_ScrollableListItem_Template

    self.ScrollView = CreateScrollBoxListLinearView();
    self.ScrollView:SetDataProvider(self.DataProvider);
    self.ScrollView:SetElementExtent(elementExtent);
    self.ScrollView:SetElementInitializer("KrowiV_ScrollableListItem_Template", function(frame, elementData)
        frame:Init(elementData);
    end);

    local paddingT = 0;
    local paddingB = 0;
    local paddingL = 0;
    local paddingR = 0;
    local spacing = 1;

    self.ScrollView:SetPadding(paddingT, paddingB, paddingL, paddingR, spacing);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, self.ScrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", 0, 4),
    };

    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };

    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.ScrollBox, self.ScrollBar, anchorsWithBar, anchorsWithoutBar);
end

function KrowiV_ScrollableListMixin:AppendListItem(link, icon, color, name, onClick, bag, slot, ...)
    local elementData =
    {
        Link = link,
        Icon = icon,
        Color = color,
        Name = name,
        OnClick = onClick and onClick or self.ListItemsOnClick,
        Bag = bag,
        Slot = slot,
        MouseButtons = ... and ... or self.ListItemsMouseButtons
    };

    self.DataProvider:Insert(elementData);
    self.DataProvider:Sort();
end

function KrowiV_ScrollableListMixin:RemoveListItem(elementData)
    local index = self.DataProvider:FindIndex(elementData);
    self.DataProvider:RemoveIndex(index);
end

function KrowiV_ScrollableListMixin:SetListItemsOnClick(func)
    self.ListItemsOnClick = func;
end

function KrowiV_ScrollableListMixin:RegisterListItemsForClicks(...)
    self.ListItemsMouseButtons = {...};
end

function KrowiV_ScrollableListMixin:ClearListItems()
    self.DataProvider:Flush();
end

function KrowiV_ScrollableListMixin:GetItems()
    return self.DataProvider:GetCollection();
end

function KrowiV_ScrollableListMixin:OnSearchTextChanged()
    local dataProvider = self:GetParent().DataProvider;
    -- print("OnSearchTextChanged()", self:GetText())
    -- if strlen(self:GetText()) <= 0 then
    --     dataProvider:Flush();
    --     dataProvider:InsertTable(tempCollection);
    --     return;
    -- end
    -- print("doing more")
    self.TempCollection = self.TempCollection or dataProvider:GetCollection();
    -- print(#tempCollection)
    dataProvider:Flush();
    dataProvider:InsertTable(self.TempCollection);
    -- print(#dataProvider:GetCollection())
    dataProvider:ReverseForEach(
        function(elementData)
            -- print(elementData.Name, self:GetText(), string.find(elementData.Name, self:GetText(), 1, true), #dataProvider:GetCollection())
            if not string.find(elementData.Name:lower(), self:GetText(), 1, true) then
                dataProvider:Remove(elementData);
            end
        end
    );
    -- KrowiV_AutoSellListFrame:Update();
end

function KrowiV_ScrollableListMixin:ClearSearch()
    -- print("ClearSearch()")
    self:SetText("");
    self.TempCollection = nil;
end
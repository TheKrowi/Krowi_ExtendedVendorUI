local _, addon = ...
if addon.NotLoaded then return end
addon.Gui.Paging = {}
local paging = addon.Gui.Paging

-- The addon's own page controls; Blizzard's page through the unfiltered list. Anchored in Gui/MerchantFrame.lua.
local prevButton = CreateFrame('Button', 'KrowiEVU_MerchantPrevPageButton', MerchantFrame, 'KrowiEVU_MerchantPrevPageButton_Template')
local nextButton = CreateFrame('Button', 'KrowiEVU_MerchantNextPageButton', MerchantFrame, 'KrowiEVU_MerchantNextPageButton_Template')
local pageText = MerchantFrame:CreateFontString('KrowiEVU_MerchantPageText', 'BORDER', 'GameFontNormal')
pageText:SetSize(104, 0)
pageText:Hide()

local page = 1

function paging:GetPage()
    return page
end

function paging:SetPage(newPage)
    page = newPage
end

local function ChangePage(delta)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    page = page + delta
    if paging.OnPageChanged then
        paging.OnPageChanged()
    end
end

prevButton:SetScript('OnClick', function()
    ChangePage(-1)
end)

nextButton:SetScript('OnClick', function()
    ChangePage(1)
end)

-- Blizzard's own wheel handler does nothing while its page buttons are hidden (live MerchantFrame.lua:177-187)
MerchantFrame:HookScript('OnMouseWheel', function(_, value)
    if value > 0 then
        if prevButton:IsShown() and prevButton:IsEnabled() then
            ChangePage(-1)
        end
    else
        if nextButton:IsShown() and nextButton:IsEnabled() then
            ChangePage(1)
        end
    end
end)

-- Blizzard's rules (live MerchantFrame.lua:273 and 431-450, classic TBC MerchantFrame.lua:193 and 351-370) with the filtered count
function paging:Update(numItems, itemsPerPage)
    if addon.Util.IsModern then
        pageText:SetFormattedText(MERCHANT_PAGE_NUMBER, page, math.ceil(numItems / itemsPerPage))
    else
        pageText:SetFormattedText(PAGE_NUMBER, page)
    end

    if numItems > itemsPerPage then
        if page == 1 then
            prevButton:Disable()
        else
            prevButton:Enable()
        end
        if page == math.ceil(numItems / itemsPerPage) or numItems == 0 then
            nextButton:Disable()
        else
            nextButton:Enable()
        end
        pageText:Show()
        prevButton:Show()
        nextButton:Show()
    else
        pageText:Hide()
        prevButton:Hide()
        nextButton:Hide()
    end
end

function paging:Hide()
    pageText:Hide()
    prevButton:Hide()
    nextButton:Hide()
end

function paging:IsShown()
    return pageText:IsShown()
end
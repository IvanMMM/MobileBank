--	MobileBank v0.26
----------------------------
--	Список команд:
-- /mb cls - очистить собраные данные
----------------------------



MB = { }

MB.version=0.26

MB.dataDefaultItems = {
    data = {}
}

for i=1,GetNumGuilds() do
	MB.dataDefaultItems.data[i]={
		[GetGuildName(i)]={}
	}
end 

MB.dataDefaultParams = {
	MBUI_Menu = {10,10},
	MBUI_Container = {530,380}
}

MB.GuildNames = {}

MB.UI_Movable=false
MB.AddonReady=false
MB.TempData={}
MB.GCountOnUpdateTimer=0
MB.GuildBankIdToPrepare=1
MB.Dedug=false
MB.PreviousButtonClicked=nil
MB.LastButtonClicked=nil

function debug(text)
	if MB.Debug then
		d(text)
	end
end

function MB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "MobileBank" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/mb"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_BANK, MB.PL_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_CLOSE_BANK, MB.PL_Closed)
	-- EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_GUILD_BANK_SELECTED, MB.GB_Selected)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_GUILD_BANK, MB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_GUILD_BANK_ITEMS_READY, MB.GB_Ready)

	--Загрузка сохраненных переменных
	MB.items= ZO_SavedVars:NewAccountWide( "MB_SavedVars" , 2, "items" , MB.dataDefaultItems, nil )
	MB.params= ZO_SavedVars:New( "MB_SavedVars" , 2, "params" , MB.dataDefaultParams, nil )

	--Инициализация графического интерфейся
	MB_UI = WINDOW_MANAGER:CreateTopLevelWindow("MBUI")

	-- Создаем меню
	MB.CreateMenu()
	-- Создаем банк
	MB.CreateBank()

	MB.AddonReady=true
end


function MB.CreateMenu()
	MB_UI.Menu=WINDOW_MANAGER:CreateControl("MBUI_Menu",MBUI,CT_CONTROL)
	MB_UI.Menu.BG = WINDOW_MANAGER:CreateControl("MBUI_Menu_BG",MBUI_Menu,CT_BACKDROP)
	MB_UI.Menu.Title = WINDOW_MANAGER:CreateControl("MBUI_Menu_Title",MBUI_Menu,CT_LABEL)
	MB_UI.Menu.Button={}
	MB_UI.Menu.Button.Guild = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Guild",MBUI_Menu,CT_BUTTON)
	MB_UI.Menu.Button.Player = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Player",MBUI_Menu,CT_BUTTON)
	MB_UI.Menu.Button.Move = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Move",MBUI_Menu,CT_BUTTON)

	--Обработчики событий

    -- Клик по гильдии
    MB_UI.Menu.Button.Guild:SetHandler( "OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Guild"

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Guild",1)
		MB.FillBank(MB.CurrentLastValue)
    	MB.HideContainer(bool)
    end )

    -- Клик по игроку
    MB_UI.Menu.Button.Player:SetHandler( "OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Player"

		if MB.PlayerShown then
			bool=false
		end

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Player")
    	MB.FillBank(MB.CurrentLastValue)
    	MB.HideContainer(bool)
    end )

    -- Клик по M
    MB_UI.Menu.Button.Move:SetHandler( "OnClicked" , function(self)
    	if MB.UI_Movable then
    		MB_UI.Menu:SetMovable(true)
    		MBUI_Container:SetMovable(true)
    		MB.UI_Movable=false
    	else
    		MB_UI.Menu:SetMovable(false)
    		MBUI_Container:SetMovable(false)
    		MB.UI_Movable=true
    	end
    end )

    MBUI_Menu:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)
    MBUI_Container:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)

	--Настройки меню
	MB_UI.Menu:SetAnchor(TOPLEFT,MBUI,TOPLEFT,MB.params.MBUI_Menu[1],MB.params.MBUI_Menu[2])
	MB_UI.Menu:SetDimensions(200,50)
	MB_UI.Menu:SetMouseEnabled(true)

    if MB.UI_Movable then
		MB_UI:SetMovable(true)
		MB.UI_Movable=false
	else
		MB_UI:SetMovable(false)
		MB.UI_Movable=true
	end

	--Фон
	MB_UI.Menu.BG:SetAnchor(BOTTOM,MBUI_Menu,BOTTOM,0,0)
	MB_UI.Menu.BG:SetDimensions(200,50)
	MB_UI.Menu.BG:SetCenterColor(0,0,0,1)
	MB_UI.Menu.BG:SetEdgeColor(0,0,0,1)
	MB_UI.Menu.BG:SetEdgeTexture("", 8, 1, 1)
	MB_UI.Menu.BG:SetAlpha(0.5)

	--Заголовок
	MB_UI.Menu.Title:SetAnchor(TOP,MBUI_Menu,TOP,0,0)
	MB_UI.Menu.Title:SetFont("ZoFontGame" )
	MB_UI.Menu.Title:SetColor(255,255,255,1.5)
	MB_UI.Menu.Title:SetText( "|cff8000Bank Storage|" )

	-- Кнопка "Гильдия"
	MB_UI.Menu.Button.Guild:SetAnchor(TOP,MBUI_Menu,TOPRIGHT,-150,20)
	MB_UI.Menu.Button.Guild:SetText("[Guild]")
	MB_UI.Menu.Button.Guild:SetDimensions(70,25)
	MB_UI.Menu.Button.Guild:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Guild:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Guild:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Игрок"
	MB_UI.Menu.Button.Player:SetAnchor(TOP,MBUI_Menu,TOPRIGHT,-90,20)
	MB_UI.Menu.Button.Player:SetText("[Player]")
	MB_UI.Menu.Button.Player:SetDimensions(70,25)
	MB_UI.Menu.Button.Player:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Player:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Player:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "M"
	MB_UI.Menu.Button.Move:SetAnchor(TOP,MBUI_Menu,TOPRIGHT,-40,20)
	MB_UI.Menu.Button.Move:SetText("[M]")
	MB_UI.Menu.Button.Move:SetDimensions(40,25)
	MB_UI.Menu.Button.Move:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Move:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Move:SetMouseOverFontColor(0.8,0.4,0,1)
end

function MB.CreateBank()
	local OldAnchor=false

	--Настройки контейнера
	MBUI_Container:SetParent(MBUI)
	MBUI_Container:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,MB.params.MBUI_Container[1],MB.params.MBUI_Container[2])
	MBUI_Container:SetDimensions(560,720)
	MBUI_Container:SetMouseEnabled(true)
	MBUI_Container:SetHidden(true)

    -- Фон
    MBUI_ContainerBg:SetAnchor(TOPLEFT,MBUI_Container,TOPLEFT,10,0)
    MBUI_ContainerBg:SetCenterColor(0,0,0,0.5)
    MBUI_ContainerBg:SetEdgeColor(0,0,0,0.5)
    MBUI_ContainerBg:SetDimensions(MBUI_Container:GetDimensions())

	-- + Правим Заглавие 
	MBUI_ContainerTitle:SetAnchor(TOP,MBUI_Container,TOP,0,15)
	MBUI_ContainerTitle:SetFont("ZoFontGame")
	MBUI_ContainerTitle:SetText( "|cff8000Offline Bank Storage|" )
	MBUI_ContainerTitle:SetHeight(150)

	-- Правим Заголовки
	MBUI_ContainerTitleName:SetAnchor(TOP,MBUI_ContainerTitle,LEFT,-100,-15)
	MBUI_ContainerTitleStat:SetAnchor(TOP,MBUI_ContainerTitle,CENTER,130,-15)
	MBUI_ContainerTitleValue:SetAnchor(TOP,MBUI_ContainerTitle,RIGHT,155,-15)

	-- Правим Содержание банка
	MBUI_ContainerItemCounter:SetAnchor(CENTER,MBUI_Container,BOTTOM,0,-17)	

	-- + Правим Слайдер
    MBUI_ContainerSlider:SetAnchor(BOTTOM,MBUI_Container,BOTTOMRIGHT,0,-50)
    MBUI_ContainerSlider:SetValue(11)
    MBUI_ContainerSlider:SetWidth(ZO_PlayerBankBackpackScrollBar:GetWidth())
    MBUI_ContainerSlider:SetHeight(565)
    MBUI_ContainerSlider:SetAllowDraggingFromThumb(true)

    -- Создаем кнопки для переключения между гильдбанками
	local nextXstep=0
    for i=1,#MB.items.data do

    	-- Сохраняем названия гильдий из Ключей(да, да...)
	    for k, v in pairs(MB.items.data[i]) do
	        MB.GuildNames[#MB.GuildNames+1] = k
	    end

    	local guildname=tostring(MB.GuildNames[i])
    	WINDOW_MANAGER:CreateControl("MBUI_ContainerTitleGuildButton"..i,MBUI_ContainerTitle,CT_BUTTON)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetParent(MBUI_ContainerTitleGuildButtons)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetFont("ZoFontGame" )
		nextXstep=(MBUI_Container:GetWidth()/#MB.items.data*i)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetDimensions(MBUI_Container:GetWidth()/#MB.items.data,20)
    	-- Делаем поправку на ширину самой кнопки
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetAnchor(TOP,MBUI_Container,TOPLEFT,nextXstep-_G["MBUI_ContainerTitleGuildButton"..i]:GetWidth()/2,40)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetText("["..guildname.."]")
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["MBUI_ContainerTitleGuildButton"..i]:SetHandler( "OnClicked" , function(self)
			MB.PrepareBankValues("Guild",i)
			MB.SortPreparedValues()
			MB.FillBank(11)	
		 end)


	end

    -- Создаем строки
	for i = 1, 11 do
	    local dynamicControl = CreateControlFromVirtual("MBUI_Row", MBUI_Container, "TemplateRow",i)
	    -- _G[] - позволяет подставлять динамические имена переменных

	    -- Строка
	    local fromtop=100
	    _G["MBUI_Row"..i]:ClearAnchors()
	    _G["MBUI_Row"..i]:SetAnchor(TOP,MBUI_Container,TOP,0,fromtop+52*(i-1))
	    _G["MBUI_Row"..i]:SetDimensions (530,52)

	    -- Фон
	    _G["MBUI_Row"..i.."Bg"]:SetColor(1,1,1,1)
	    --На самом деле это хак ('notexture'). Не могу найти нормальную текстуру
	    _G["MBUI_Row"..i.."Bg"]:SetTexture('notexture')
	    _G["MBUI_Row"..i.."Bg"]:SetDimensions (549,59)
	    _G["MBUI_Row"..i.."Bg"]:GetTextureFileDimensions(512,64)

	    -- Кнопка
		OldAnchor=_G["MBUI_Row"..i.."Button"]:GetParent()

			--Иконка
			OldAnchor=_G["MBUI_Row"..i.."ButtonIcon"]:GetParent()
			-- Это не ошибки. Привязки ниже идут к другому якорю.
			_G["MBUI_Row"..i.."ButtonIcon"]:ClearAnchors()
		    _G["MBUI_Row"..i.."ButtonIcon"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,0,0)
		    _G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
		    _G["MBUI_Row"..i.."ButtonIcon"]:SetDimensions (40,40)
		    _G["MBUI_Row"..i.."ButtonIcon"]:GetTextureFileDimensions(64,64)

		    --Количество
			_G["MBUI_Row"..i.."ButtonStackCount"]:ClearAnchors()
		    _G["MBUI_Row"..i.."ButtonStackCount"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,20,20)
		    _G["MBUI_Row"..i.."ButtonStackCount"]:SetDimensions (38,35)

	    -- Наименование
		_G["MBUI_Row"..i.."Name"]:ClearAnchors()
	    _G["MBUI_Row"..i.."Name"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,50,15)


		-- Отображение статов
		_G["MBUI_Row"..i.."StatValue"]:ClearAnchors()
	    _G["MBUI_Row"..i.."StatValue"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,380,15)

	    -- Цена
		_G["MBUI_Row"..i.."SellPrice"]:ClearAnchors()
	    _G["MBUI_Row"..i.."SellPrice"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,480,15)

	    _G["MBUI_Row"..i.."Highlight"]:SetEdgeTexture("", 8, 1, 1)
	    _G["MBUI_Row"..i.."Highlight"]:SetCenterColor(0,0,0,0)
	    _G["MBUI_Row"..i.."Highlight"]:SetEdgeColor(0,0,0,0.5)
	end
end

function MB.PrepareBankValues(PrepareType,GuildBankIdToPrepare)
	MB.GuildBankIdToPrepare=GuildBankIdToPrepare
	MB.BankValueTable={}
	MB.BankMaxCapacity=0

	if PrepareType=="Player" then
		debug("Preparing Player values")
		bagIcon, bagSlots=GetBagInfo(BAG_BANK)
		MB.BankMaxCapacity=bagSlots
		MB.ItemCounter=0
		while (MB.ItemCounter < bagSlots) do
			if GetItemName(BAG_BANK,MB.ItemCounter)~="" then

				--Избавляемся от мусора при сохранении
				local clearlink=string.gsub(GetItemLink(BAG_BANK,MB.ItemCounter), "(^p)", "")
				clearlink=string.gsub(clearlink, "(^n)", "")

				local start,finish=string.find(clearlink,'|h.+|h')
				local nameClear=string.sub(clearlink,start+2,finish-2)
				local count = GetSlotStackSize(BAG_BANK,MB.ItemCounter)
				local statvalue = GetItemStatValue(BAG_BANK,MB.ItemCounter)
				local quality = GetItemInfo(BAG_BANK,MB.ItemCounter)

				local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(clearlink)
				iconFile=icon

				MB.BankValueTable[#MB.BankValueTable+1]={
					["link"]=tostring(clearlink),
					["icon"] = tostring(iconFile),
					["name"]=tostring(nameClear),
					["count"]=tostring(count),
					["statvalue"]=tostring(statvalue),
					["sellPrice"] = tostring(sellPrice),
					["quality"] = tostring(quality)

				}
			end
			MB.ItemCounter=MB.ItemCounter+1
		end
		MBUI_ContainerTitleGuildButtons:SetHidden(true)
	elseif PrepareType=="Guild" then
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)
		MB.BankMaxCapacity=bagSlots
		debug("Preparing Guild values")

	    local guildname=tostring(GetGuildName(GuildBankIdToPrepare))
		MB.BankValueTable=MB.items.data[GuildBankIdToPrepare][guildname]
		MBUI_ContainerTitleGuildButtons:SetHidden(false)
	else
		debug("Unknown prepare type: "..tostring(PrepareType))
	end

    MBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
		MB.FillBank(value)
    end)

    for i=1,11 do
        _G["MBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self, delta)
	    	local calculatedvalue=MB.CurrentLastValue-delta
	    	if (calculatedvalue>=11) and (calculatedvalue<=#MB.BankValueTable) then
	    		MB.FillBank(calculatedvalue)
	    		MBUI_ContainerSlider:SetValue(calculatedvalue)
	    	end
	    end )
    end
MB.SortPreparedValues()
return MB.BankValueTable
end

function MB.SortPreparedValues()

	function compare(a,b)
		return a["name"]<b["name"]	
	end

	table.sort(MB.BankValueTable,compare)
end

function MB.FillBank(last)
	if last<=1 then debug("last<=1") return end
    if (#MB.BankValueTable==0) then 
    	d("No data avaliable. Open your bank first.")
    	MBUI_ContainerItemCounter:SetHidden(true)
    	MB.HideContainer(true)
	    	for i=1,11 do
	    		_G["MBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	else
		local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
    	MBUI_ContainerSlider:SetMinMax(11,#MB.BankValueTable)
    	MBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#MB.BankValueTable*25000)/3, 0, 0, 1, 1)
    	for i=1,11 do
    		_G["MBUI_Row"..i]:SetHidden(false)
    	end
    end
    MB.CurrentLastValue=last

    if #MB.BankValueTable<11 then
    	-- Прячем Слайдер
    	MBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,#MB.BankValueTable do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(MB.BankValueTable[i].link)

	    	-- Регистрируем отображение тултипов при наведении на строку
		    _G["MBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)

		    	-- Тут может быть любой другой якорь. Нам важен его родитель
		    	OldAnchor=_G["MBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-200,0)
		    	ItemTooltip:SetLink(_G["MBUI_Row"..i.."Name"]:GetText())
		    	ItemTooltip:SetAlpha(1)
		    	ItemTooltip:SetHidden(false)
		    	_G["MBUI_Row"..i.."Highlight"]:SetCenterColor(0.5,0.5,0.5,0.5)
		    	_G["MBUI_Row"..i.."Highlight"]:SetDimensions(GetDimensions(_G["MBUI_Row"..i]))
		    	
		    	end)

		    _G["MBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	_G["MBUI_Row"..i.."Highlight"]:SetCenterColor(0.5,0.5,0.5,0)
		    	
		    	end)

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(MB.BankValueTable[i].icon)
			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(MB.BankValueTable[i].count)
			_G["MBUI_Row"..i.."Name"]:SetText(MB.BankValueTable[i].link)
		    if (MB.BankValueTable[i].statvalue~="0") then
				_G["MBUI_Row"..i.."StatValue"]:SetText(MB.BankValueTable[i].statvalue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(MB.BankValueTable[i].count*sellPrice.."|t24:24:EsoUI/Art/currency/currency_gold.dds|t")
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = #MB.BankValueTable
		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..MB.BankMaxCapacity)
		-- Прячем пустые строки
		for i=#MB.BankValueTable+1,11 do
			_G["MBUI_Row"..i]:SetHidden(true)
		end
    else
    	-- Показываем слайдер
    	MBUI_ContainerSlider:SetHidden(false)
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(MB.BankValueTable[last].link)

		    -- Регистрируем отображение тултипов при наведении на строку
		    _G["MBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)

		    	-- Тут может быть любой другой якорь. Нам важен его родитель
		    	OldAnchor=_G["MBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	if _G["MBUI_Row"..i]:GetLeft()>=480 then
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-480,0)
		    	else
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,500,0)
		    	end

		    	ItemTooltip:SetLink(_G["MBUI_Row"..i.."Name"]:GetText())
		    	ItemTooltip:SetAlpha(1)
		    	ItemTooltip:SetHidden(false)
		    	_G["MBUI_Row"..i.."Highlight"]:SetCenterColor(0.5,0.5,0.5,0.5)	    	
		    	end)

		    _G["MBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	_G["MBUI_Row"..i.."Highlight"]:SetCenterColor(0.5,0.5,0.5,0)
		    	
		    	end)

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(MB.BankValueTable[last].icon)
			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(MB.BankValueTable[last].count)
			_G["MBUI_Row"..i.."Name"]:SetText(MB.BankValueTable[last].link)
		    if (MB.BankValueTable[last].statvalue~="0") then
				_G["MBUI_Row"..i.."StatValue"]:SetText(MB.BankValueTable[last].statvalue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(MB.BankValueTable[last].count*sellPrice.."|t24:24:EsoUI/Art/currency/currency_gold.dds|t")
			if last<=#MB.BankValueTable and last>1 then
	    		last=last-1
	    	else
	    		last=11
	    	end
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = #MB.BankValueTable
		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..MB.BankMaxCapacity)
		MBUI_ContainerItemCounter:SetHidden(false)
	end
end




function MB.PL_Opened()
	debug("Event PL_Opened fired")
end

function MB.PL_Closed()
	debug("Event PL_Closed fired")
end

function MB.GB_Opened()
	debug("Event GB_Opened fired")
end

function MB.GB_Ready()
	debug("Event GB_Ready fired")
	MB.gcount()
end



function commandHandler( text )
	if text=="cls" then
		MB.items.data={}
		MB.params.MBUI_Menu=nil
		MB.params.MBUI_Container=nil
		ReloadUI()
	else
		d("/mb cls - clear all data and reloadui ")
	end
end

function MB.gcount()
	MB.GCountOnUpdateTimer=GetGameTimeMilliseconds()
	MB.GCountOnUpdateReady=true
end

function MB.MouseUp(self)
	local name = self:GetName()
    local left = self:GetLeft()
    local top = self:GetTop()

    if name=="MBUI_Menu" then
    	debug("Menu saved")
    	MB.params.MBUI_Menu={left,top}
    elseif name=="MBUI_Container" then
    	debug("Container saved")
    	MB.params.MBUI_Container={left,top}
    else
    	debug("Unknown window")
    end
end

function MB.Update(self)
if (not MB.AddonReady) then return end

	local EscMenuHidden = ZO_GameMenu_InGame:IsHidden()
	local interactHidden = ZO_InteractWindow:IsHidden()

	if (EscMenuHidden == false) then
		MBUI_Container:SetHidden(true)
		MBUI_Menu:SetHidden(true)
	elseif (interactHidden == false) then
		MBUI_Container:SetHidden(true)
		MBUI_Menu:SetHidden(true)
	else
		MBUI_Menu:SetHidden(false)
	end

	--Хак на проверку инвентаря спустя Х сек после первого срабатывания эвента
	if MB.GCountOnUpdateReady and (GetGameTimeMilliseconds()-MB.GCountOnUpdateTimer>=1000) then
	    local guildbankid=GetSelectedGuildBankId()
	    local guildname=tostring(GetGuildName(guildbankid))
	    MB.items.data[guildbankid][guildname]={}
		d("Data saved for "..guildname)
	    local sv=false
	      	
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

		sv = MB.items.data[guildbankid][guildname]

		for i=1, #ZO_GuildBankBackpack.data do
			name=ZO_GuildBankBackpack.data[i].data.name
			count=ZO_GuildBankBackpack.data[i].data.stackCount
			statValue=ZO_GuildBankBackpack.data[i].data.statValue
			sellPrice=ZO_GuildBankBackpack.data[i].data.sellPrice
			quality=ZO_GuildBankBackpack.data[i].data.quality
			iconFile=ZO_GuildBankBackpack.data[i].data.iconFile
			slotIndex=ZO_GuildBankBackpack.data[i].data.slotIndex
			link = GetItemLink(BAG_GUILDBANK,slotIndex)
			clearlink =string.gsub(link, "(^p)", "")
			clearlink =string.gsub(clearlink, "(^n)", "")

			sv[#sv+1] = 
			{
				["link"] = tostring(clearlink),
				["icon"] = tostring(iconFile),
				["name"] = tostring(name),
				["count"] = tostring(count),
				["statvalue"] = tostring(statValue),
				["sellPrice"] = tostring(sellPrice),
				["quality"] = tostring(quality)
			}
		end
	MB.GCountOnUpdateReady=false
	end

end

function MB.HideContainer(value)
	debug("StartPrevious:"..tostring(MB.PreviousButtonClicked))
	debug("StartLast:"..tostring(MB.LastButtonClicked))
	if MB.PreviousButtonClicked==MB.LastButtonClicked then
		MBUI_Container:SetHidden(true)
		MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	else
		MBUI_Container:SetHidden(false)
	end
	debug("FinishPrevious:"..tostring(MB.PreviousButtonClicked))
	debug("FinishLast:"..tostring(MB.LastButtonClicked))
end

--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_ADD_ON_LOADED, MB.OnLoad)
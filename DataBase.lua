--	DataBase v0.01
----------------------------
--	Список команд:
-- /db bag - список сумок
-- /db ic - список инвентаря
-- /db bc - список банка
----------------------------
-- Сделать: тултипы, подсветку, занято/свободно, отобрафжение банка игрока
-- Пока работает только отображение Гильдбанка, игрока не трогал.

-- Косметические фиксы:  прыгает блядский скроллер.

-- Баги: открытый банк и аддон вызывает наложение друг на друга. Лучше бы, конечно, скрывать весь интерфейс при открытии банка.


DB = { }

DB.version=0.12

DB.dataDefault = {
    data = {}
}

DB.UI_Movable=false
DB.CurrentLastValue=11

local startupTS		= GetGameTimeMilliseconds()
local EventItemreadyHack=0
local ScrollDataTransfered=0

function DB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "DataBase" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/db"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_BANK, DB.PL_Opened)
	-- EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_SELECTED, DB.GB_Selected)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_GUILD_BANK, DB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_ITEMS_READY, DB.GB_Ready)

	--Загрузка сохраненных переменных
	DB.items= ZO_SavedVars:New( "DB_SavedVars" , 2, "items" , DB.dataDefault , nil )

	--Инициализация графического интерфейся
	db_UI = WINDOW_MANAGER:CreateTopLevelWindow("DBUI")
	db_UI.BG = WINDOW_MANAGER:CreateControl("DBUI_BG",DBUI,CT_BACKDROP)
	db_UI.Title = WINDOW_MANAGER:CreateControl("DBUI_Title",DBUI,CT_LABEL)
	db_UI.Button_Guild = WINDOW_MANAGER:CreateControl("DBUI_BtG",DBUI,CT_BUTTON)
	db_UI.Button_Player = WINDOW_MANAGER:CreateControl("DBUI_BtP",DBUI,CT_BUTTON)
	db_UI.Button_MoveOff = WINDOW_MANAGER:CreateControl("DBUI_MO",DBUI,CT_BUTTON)
	db_UI.iTitle = WINDOW_MANAGER:CreateControl("DBUI_iTitle",ZO_PlayerBank,CT_LABEL)
	db_UI.iSlider = WINDOW_MANAGER:CreateControl("DBUI_iSlider",ZO_PlayerBankBackpack,CT_SLIDER)

	--Обработчики событий

    -- Клик по гильдии
    db_UI.Button_Guild:SetHandler( "OnClicked" , function(self)
    	local bool = not(ZO_PlayerBank:IsHidden())
    	DB.FillGuildBank(DB.CurrentLastValue)
    	DB.DisplayGuildBank(bool)
    end )

    -- Клик по игроку
    db_UI.Button_Player:SetHandler( "OnClicked" , function(self)
    	DB.DisplayPlayerBank()
    end )

    -- Клик по M
    db_UI.Button_MoveOff:SetHandler( "OnClicked" , function(self)
    	if DB.UI_Movable then
    		db_UI:SetMovable(true)
    		DB.UI_Movable=false
    	else
    		db_UI:SetMovable(false)
    		DB.UI_Movable=true
    	end
    end )

	--Общие настройки интерфейса
	db_UI:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,10,10)
	db_UI:SetDimensions(200,50)
	db_UI:SetMouseEnabled(true)

    if DB.UI_Movable then
		db_UI:SetMovable(true)
		DB.UI_Movable=false
	else
		db_UI:SetMovable(false)
		DB.UI_Movable=true
	end

	--Фон
	db_UI.BG:SetDimensions(200,50)
	db_UI.BG:SetCenterColor(0,0,0,1)
	db_UI.BG:SetEdgeColor(0,0,0,1)
	db_UI.BG:SetEdgeTexture("", 8, 1, 1)
	db_UI.BG:SetAlpha(0.5)
	db_UI.BG:SetAnchor(BOTTOM,DBUI,BOTTOM,0,0)

	--Заголовок
	db_UI.Title:SetFont("ZoFontGame" )
	db_UI.Title:SetColor(255,255,255,1.5)
	db_UI.Title:SetText( "|cff8000Bank Storage|" )
	db_UI.Title:SetAnchor(TOP,DBUI,TOP,0,0)

	-- Кнопка "Гильдия"
	db_UI.Button_Guild:SetText("[Guild]")
	db_UI.Button_Guild:SetAnchor(TOP,DBUI,TOPRIGHT,-150,20)
	db_UI.Button_Guild:SetDimensions(70,25)
	db_UI.Button_Guild:SetFont("ZoFontGameBold")
	db_UI.Button_Guild:SetNormalFontColor(0,255,255,.7)
	db_UI.Button_Guild:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Игрок"
	db_UI.Button_Player:SetText("[Player]")
	db_UI.Button_Player:SetAnchor(TOP,DBUI,TOPRIGHT,-90,20)
	db_UI.Button_Player:SetDimensions(70,25)
	db_UI.Button_Player:SetFont("ZoFontGameBold")
	db_UI.Button_Player:SetNormalFontColor(0,255,255,.7)
	db_UI.Button_Player:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "M"
	db_UI.Button_MoveOff:SetText("[M]")
	db_UI.Button_MoveOff:SetAnchor(TOP,DBUI,TOPRIGHT,-40,20)
	db_UI.Button_MoveOff:SetDimensions(40,25)
	db_UI.Button_MoveOff:SetFont("ZoFontGameBold")
	db_UI.Button_MoveOff:SetNormalFontColor(0,255,255,.7)
	db_UI.Button_MoveOff:SetMouseOverFontColor(0.8,0.4,0,1)

	--Инициализируем наш банк
	DB.CreateGuildBank()
end

	function DB.DisplayPlayerBank()

	end


	function DB.DisplayGuildBank(value)

		ZO_SharedRightPanelBackground:SetHidden(value)
		ZO_PlayerBank:SetHidden(value)
		ZO_PlayerBankTabs:SetHidden(true)
		ZO_PlayerBankFilterDivider:SetHidden(value)
		ZO_PlayerBankSortBy:SetHidden(value)
		ZO_PlayerBankInfoBar:SetHidden(value)
		ZO_PlayerBankBackpack:SetHidden(value)
		ZO_PlayerBankBackpackScrollBar:SetHidden(true)
		ZO_PlayerBankBackpackContents:SetHidden(value)
		ZO_PlayerBankBackpackLandingArea:SetHidden(value)
	end

	function DB.CreateGuildBank()
		local OldAnchor=false
		for i = 1, 11 do
		    local dynamicControl = CreateControlFromVirtual("BackpackRow", ZO_PlayerBankBackpackContents, "TemplateBackpackRow",i)
		    -- _G[] - позволяет подставлять динамические имена переменных

	        _G["BackpackRow"..i]:SetHandler("OnMouseWheel" , function(self, delta)
		    	local calculatedvalue=DB.CurrentLastValue-delta
		    	if (calculatedvalue>=11) and (calculatedvalue<=#DB.items.data) then
		    		DB.FillGuildBank(calculatedvalue)
		    		db_UI.iSlider:SetValue(calculatedvalue)
		    	end
		    end )

		    --Настраиваем слайдер
		    local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
			if #DB.items.data>11 then
			    db_UI.iSlider:SetAnchor(BOTTOM,ZO_PlayerBankBackpack,BOTTOMRIGHT,-10,0)
			    db_UI.iSlider:SetMouseEnabled(true)
			    db_UI.iSlider:SetMinMax(11,#DB.items.data)
			    db_UI.iSlider:SetValue(11)
			    db_UI.iSlider:SetValueStep(1)
			    db_UI.iSlider:SetThumbTexture(texture, texture, texture, 18, (1/#DB.items.data+#DB.items.data)/3, 0, 0, 1, 1)
			    db_UI.iSlider:SetWidth(ZO_PlayerBankBackpackScrollBar:GetWidth())
			    db_UI.iSlider:SetHeight(550)
			    db_UI.iSlider:SetAllowDraggingFromThumb(true)

			    db_UI.iSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
			    	d("Slider:"..value)
			    	DB.FillGuildBank(value)
			    end)
			end

			-- Делаем заголовок
			db_UI.iTitle:SetFont("ZoFontGame" )
			db_UI.iTitle:SetColor(255,255,255,1.5)
			db_UI.iTitle:SetText( "|cff8000Offline Bank Storage|" )
			db_UI.iTitle:SetHeight(150)
			db_UI.iTitle:SetAnchor(TOP,ZO_PlayerBank,TOP,0,0)


		    -- Фон
		    OldAnchor=_G["BackpackRow"..i.."Bg"]:GetParent()
		    _G["BackpackRow"..i.."Bg"]:ClearAnchors()
		    _G["BackpackRow"..i.."Bg"]:SetAnchor(TOP,OldAnchor,TOP,0,52*(i-1))
		    _G["BackpackRow"..i.."Bg"]:SetColor(1,1,1,1)
		    --На самом деле это хак ('notexture'). Не могу найти нормальную текстуру
		    _G["BackpackRow"..i.."Bg"]:SetTexture('notexture')
		    _G["BackpackRow"..i.."Bg"]:SetDimensions (549,52)
		    _G["BackpackRow"..i.."Bg"]:GetTextureFileDimensions(512,64)

		    -- Кнопка
			OldAnchor=_G["BackpackRow"..i.."Button"]:GetParent()
			_G["BackpackRow"..i.."Button"]:ClearAnchors()
		    _G["BackpackRow"..i.."Button"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,25,52*(i-1))

				--Иконка
				OldAnchor=_G["BackpackRow"..i.."ButtonIcon"]:GetParent()
				-- Это не ошибки. Привязки ниже идут к другому якорю.
				_G["BackpackRow"..i.."ButtonIcon"]:ClearAnchors()
			    _G["BackpackRow"..i.."ButtonIcon"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,0,0)
			    _G["BackpackRow"..i.."ButtonIcon"]:SetColor(1,1,1,1)
			    _G["BackpackRow"..i.."ButtonIcon"]:SetDimensions (40,40)
			    _G["BackpackRow"..i.."ButtonIcon"]:GetTextureFileDimensions(64,64)

			    --Количество
				_G["BackpackRow"..i.."ButtonStackCount"]:ClearAnchors()
			    _G["BackpackRow"..i.."ButtonStackCount"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,20,20)
			    _G["BackpackRow"..i.."ButtonStackCount"]:SetDimensions (38,35)

		    -- Наименование
			_G["BackpackRow"..i.."Name"]:ClearAnchors()
		    _G["BackpackRow"..i.."Name"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,50,15)


			-- Отображение статов
			_G["BackpackRow"..i.."StatValue"]:ClearAnchors()
		    _G["BackpackRow"..i.."StatValue"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,380,15)

		    -- Цена
			_G["BackpackRow"..i.."SellPrice"]:ClearAnchors()
		    _G["BackpackRow"..i.."SellPrice"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,480,15)

		    _G["BackpackRow"..i.."Highlight"]:SetHidden(true)
		end
	end

	function DB.FillGuildBank(last)
		if last<=1 then return end
	    if (#DB.items.data==0) then 
	    	d("Nothing to parse")
		    	for i=1,11 do
		    		_G["BackpackRow"..i]:SetHidden(true)
		    	end
	    	return 
    	else
	    	for i=1,11 do
	    		_G["BackpackRow"..i]:SetHidden(false)
	    	end
	    end
	    DB.CurrentLastValue=last

	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(DB.items.data[last].name)
			_G["BackpackRow"..i.."ButtonIcon"]:SetTexture(icon)
			_G["BackpackRow"..i.."ButtonStackCount"]:SetText(DB.items.data[last].count)
			_G["BackpackRow"..i.."Name"]:SetText(DB.items.data[last].name)
		    if (DB.items.data[last].statvalue~="0") then
				_G["BackpackRow"..i.."StatValue"]:SetText(DB.items.data[last].statvalue)
			else
				_G["BackpackRow"..i.."StatValue"]:SetText("-")
			end
			_G["BackpackRow"..i.."SellPrice"]:SetText(DB.items.data[last].count*sellPrice)
			if last<=#DB.items.data and last>1 then
	    		last=last-1
	    	else
	    		last=11
	    	end
		end

	end


function DB.Update(self)
-- Заготовка для обновления данных

end

function DB.PL_Opened()
	d("Player bank opened")
	local value=false
	ZO_SharedRightPanelBackground:SetHidden(value)
	ZO_PlayerBank:SetHidden(value)
	ZO_PlayerBankTabs:SetHidden(value)
	ZO_PlayerBankFilterDivider:SetHidden(value)
	ZO_PlayerBankSortBy:SetHidden(value)
	ZO_PlayerBankInfoBar:SetHidden(value)
	ZO_PlayerBankBackpack:SetHidden(value)
	ZO_PlayerBankBackpackScrollBar:SetHidden(value)
	ZO_PlayerBankBackpackContents:SetHidden(value)
	ZO_PlayerBankBackpackLandingArea:SetHidden(value)

	db_UI.iTitle:SetHidden(true)
	db_UI.iSlider:SetHidden(true)
    for i=1,11 do
		_G["BackpackRow"..i]:SetHidden(true)
	end

end

function DB.GB_Opened()
	d("Guild bank opened")
end

function DB.GB_Ready()
	--хак на срабатываение после второго события

	if EventItemreadyHack==1 then 

		DB.gcount()

		EventItemreadyHack=0
	else
		EventItemreadyHack=1
	end
end

function DB.GB_Selected(guildid)
	d("Bank owned by "..guildid.." selected")
	DB.GuildBankId=GetSelectedGuildBankId()
	d("GuildBank id: "..DB.GuildBankId)
end


function commandHandler( text )
	if text=="ic" then
		DB.icount()
	elseif text=="bc" then
		DB.bcount()
	elseif text=="gc" then
		DB.gcount()		
	else
		d("/db bag - bags list")
		d("/db ic - iventory list")
		d("/db bc - bank list")
		d("/db gc - guildbank list")
	end
end

function DB.icount()
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_BACKPACK)

	for i = bagSlots, 0, -1 do
		bagSpace = i
		if CheckInventorySpaceSilently(bagSpace) then break end
	end

	d("BagSpaceTotal: "..bagSlots)
	d("BagSpaceFree: "..bagSpace)
	d("BagSpaceOccupied: "..(bagSlots-bagSpace))
	d("slot:name:count")
	
	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BACKPACK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemName(BAG_BACKPACK,DB.ItemCounter).." : "..GetItemTotalCount(BAG_BACKPACK,DB.ItemCounter))
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Items total: "..(bagSlots-bagSpace))
	d("Slots counted: "..DB.ItemCounter)
end

function DB.bcount()
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_BANK)

	d("BagSpaceTotal: "..bagSlots)

	d("slot:name:count")
	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BANK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemName(BAG_BANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_BANK,DB.ItemCounter))
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
end

function DB.gcount()

    local data = {}
    local dataStr = ""
    local sv=false
    -- 0-не найдено, 1-найдено, 2-обновлено
    local founditems = 0
      	
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_GUILDBANK,DB.ItemCounter)~="" then
			-- d(DB.ItemCounter.." : "..GetItemLink(BAG_GUILDBANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))

			if founditems==0 then
				founditems=1
			end

			--Обнуление сохраненной базы
			if  (founditems==1) then 
				DB.items.data={}
				sv = DB.items.data 
				founditems=2
				d("BaseWiped")
			end
	
			--Избавляемся от мусора при сохранении
			local namefine=string.gsub(GetItemLink(BAG_GUILDBANK,DB.ItemCounter), "(^p)", "")
			namefine=string.gsub(namefine, "(^n)", "")

			-- Разбираем строку и вытаскиваем из неё id
			local start,finish=string.find(namefine,'item:%d+')
			local id=string.sub(namefine,start+5,finish)

			sv[#sv+1] = 
					{
					 ["name"] = tostring(namefine),
					 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter)),
					 ["statvalue"]=tostring(GetItemStatValue(BAG_GUILDBANK,DB.ItemCounter)),
					 ["id"]=tostring(id)
					}
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
	if DB.ItemCounter==bagSlots and founditems==0 then
		d("Found nothing... try again")
	end
end


--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_ADD_ON_LOADED, DB.OnLoad)
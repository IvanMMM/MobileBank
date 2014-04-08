--	DataBase v0.01
----------------------------
--	Список команд:
-- /db bag - список сумок
-- /db ic - список инвентаря
-- /db bc - список банка
----------------------------
DB = { }

DB.version=0.01

DB.dataDefault = {
    data = {}
}


local ShowInfo = true
local startupTS		= GetGameTimeMilliseconds()
local EventItemreadyHack=0

function DB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "DataBase" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/db"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_BANK, DB.PL_Opened)
	-- EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_SELECTED, DB.GB_Selected)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_GUILD_BANK, DB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_ITEMS_READY, DB.GB_Ready)

	--Загрузка сохраненных переменных (?)
	DB.items= ZO_SavedVars:New( "DB_SavedVars" , 2, "items" , DB.dataDefault , nil )

	-- Инициализация графического интерфейся
	db_UI = WINDOW_MANAGER:CreateTopLevelWindow("DBUI")
	db_UI.BG = WINDOW_MANAGER:CreateControl("DBUI_BG",DBUI,CT_BACKDROP)
	db_UI.Title = WINDOW_MANAGER:CreateControl("DBUI_Title",DBUI,CT_LABEL)
	db_UI.Items = WINDOW_MANAGER:CreateControl("DBUI_Items",DBUI,CT_LABEL)

	--Общие настройки интерфейса
	db_UI:SetDimensions(425,645)

	--Создаем скролл // слайдер

	-- Похоже слайдер придётся рисовать самому.. а при скроллинге только изменять значения 10-15 полей заранее созданых.
	--а может и нет.. надо бы глянуть текстуры.

	-- db_UI.Scroll = WINDOW_MANAGER:CreateControl("DBUI_Scroll",DBUI,CT_SCROLL)
	db_UI.Slider = WINDOW_MANAGER:CreateControl("DBUI_Slider",DBUI,CT_SLIDER)
	-- db_UI.Slider:DoesAllowDraggingFromThumb()
	-- /script d(db_UI.Slider:DoesAllowDraggingFromThumb())

	--	Фон
	db_UI.BG:SetDimensions( 425 , 645 )
	db_UI.BG:SetCenterColor(0,0,0,1)
	db_UI.BG:SetEdgeColor(0,0,0,1)
	db_UI.BG:SetEdgeTexture("", 8, 1, 1)
	db_UI.BG:SetAlpha(0.5)
	db_UI.BG:SetAnchor(BOTTOM,DBUI,BOTTOM,0,0)

	--	Заголовок
	db_UI.Title:SetFont("ZoFontGame" )
	db_UI.Title:SetColor(255,255,255,1.5)
	db_UI.Title:SetText( "GuildBank Storage" )
	db_UI.Title:SetAnchor(TOPLEFT,DBUI,TOPLEFT,10,0)

	--Применяем общие настройки
	db_UI:SetMouseEnabled(false)
	db_UI:SetMovable(true)

	--Выводим число вещей в инвентаре:
	db_UI.Items:SetFont("ZoFontGame" )
	db_UI.Items:SetColor(255,255,255,1.5)
	db_UI.Items:SetText("ItemsTotal: "..#DB.items.data)
	db_UI.Items:SetAnchor(TOPLEFT,DBUI,TOPLEFT,10,20)

	--Выводим название и число вещей на экран
	db_UI.Items.Item={}
	db_UI.Items.Item.name ={}
	db_UI.Items.Item.count ={}

	-- Если добавлять фильтры, выносить эту залупу ниже в функцию и скармливать ей заранее подготовленый массив
	-- for i=1, #DB.items.data, 1 do
	for i=1, 10, 1 do
		--Название
		db_UI.Items.Item.name[i] = WINDOW_MANAGER:CreateControl("DBUI_Item_name_"..i,DBUI,CT_LABEL)
		db_UI.Items.Item.name[i]:SetFont("ZoFontGame" )
		db_UI.Items.Item.name[i]:SetColor(255,255,255,1.5)
		db_UI.Items.Item.name[i]:SetText(DB.items.data[i].name)
		db_UI.Items.Item.name[i]:SetAnchor(TOPLEFT,db_UI,TOPLEFT,20,20+i*20)

		--Количество
		db_UI.Items.Item.name[i] = WINDOW_MANAGER:CreateControl("DBUI_Item_count_"..i,DBUI,CT_LABEL)
		db_UI.Items.Item.name[i]:SetFont("ZoFontGame" )
		db_UI.Items.Item.name[i]:SetColor(255,255,255,1.5)
		db_UI.Items.Item.name[i]:SetText(DB.items.data[i].count)
		db_UI.Items.Item.name[i]:SetAnchor(TOPLEFT,db_UI,TOPLEFT,300,20+i*20)
	end


end


function DB.Update(self)
-- Заготовка для обновления данных

end

function DB.PL_Opened()
	d("Player bank opened")
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
	
	-- что-то тут не так...
	while (ItemCounter < bagSlots) do
		if GetItemName(BAG_BACKPACK,ItemCounter)~="" then
			d(ItemCounter.." : "..GetItemName(BAG_BACKPACK,ItemCounter).." : "..GetItemTotalCount(BAG_BACKPACK,ItemCounter))
		end
		ItemCounter=ItemCounter+1
	end
	d("---------------------")
	d("Items total: "..(bagSlots-bagSpace))
	d("Slots counted: "..ItemCounter)
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
    local founditems = false

	--Обнуление сохраненной базы
    DB.items.data={}
    
	local sv = DB.items.data
    	
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_GUILDBANK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemLink(BAG_GUILDBANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
			founditems=true

			if #sv == 0 then
				sv[1] = 
						{
						 ["name"] = tostring(GetItemLink(BAG_GUILDBANK,DB.ItemCounter)),
						 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
						}
			else
				sv[#sv+1] = 
						{
						 ["name"] = tostring(GetItemLink(BAG_GUILDBANK,DB.ItemCounter)),
						 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
						}
			end
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
	if DB.ItemCounter==bagSlots and founditems==false then
		d("Found nothing... try again")
	end
end


--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_ADD_ON_LOADED, DB.OnLoad)
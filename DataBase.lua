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


--Экспорт одним массивом
DB.ExportAsArray=true;

local ShowInfo = true
local startupTS		= GetGameTimeMilliseconds()
local EventItemreadyHack=0

function DB.Initizlise()
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
end


function DB.Update(self)
			--Регистрация функций
	if (ShowInfo == true) and ( (GetGameTimeMilliseconds() - startupTS) > 5000 ) then
		d("Addon loaded")
		ShowInfo = false

		--добавляем команду
		SLASH_COMMANDS["/db"] = commandHandler

		--Обработчик эвента
		EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_BANK, DB.PL_Opened)
		EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_SELECTED, DB.GB_Selected)
		EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_GUILD_BANK, DB.GB_Opened)
		EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_ITEMS_READY, DB.GB_Ready)
	end
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
	
	DB.items = ZO_SavedVars:NewAccountWide("DB_SavedVars", 1, "items", DB.dataDefault)
	local sv = DB.items.data
	
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

	d("slot:name:count")
	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_GUILDBANK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemLink(BAG_GUILDBANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
			
			--DB.items.name=GetItemName(BAG_GUILDBANK,DB.ItemCounter)
			--DB.items.count=GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter)
			
			if #sv == 0 then
				sv[1] = 
						{
						 ["name"] = tostring(GetItemName(BAG_GUILDBANK,DB.ItemCounter)),
						 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
						}
			else
				sv[#sv+1] = 
						{
						 ["name"] = tostring(GetItemName(BAG_GUILDBANK,DB.ItemCounter)),
						 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
						}
			end
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
end
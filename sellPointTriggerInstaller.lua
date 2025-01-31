-- ============================================================= --
-- INSTALLER FOR SELL POINT TRIGGER PLACEABLE TYPE
-- ============================================================= --
local modDir = g_currentModDirectory
local modName = g_currentModName

-- Create the new 'Placeable Types'
g_placeableTypeManager:addPlaceableType("sellPointTrigger", modName..".SellPointTrigger", modDir.."sellPointTrigger.lua", modName)
g_placeableTypeManager:addPlaceableType("woodSellPointTrigger", modName..".woodSellPointTrigger", modDir.."woodSellPointTrigger.lua", modName)

-- Create the new 'Store Category'
local function storeLoadMapData(xmlFile, missionInfo, baseDirectory)
    g_storeManager:addCategory("placeableSellPoints", g_i18n:getText("category_placeableSellPoints"), "categoryIcon.dds", "PLACEABLE", modDir)
end
StoreManager.loadMapData = Utils.appendedFunction(StoreManager.loadMapData, storeLoadMapData)

-- Create the new 'Installer/Manager Class'
SellPointTriggerInstaller = {};

addModEventListener(SellPointTriggerInstaller);

function SellPointTriggerInstaller:loadMap(name)
	--print("Load Mod: 'Sell Point Trigger Installer'")
	if g_currentMission.SellPointTriggers == nil then
		g_currentMission.SellPointTriggers = {}
	end
	
	PlacementScreenController.isPlacementValid = Utils.overwrittenFunction(PlacementScreenController.isPlacementValid, SellPointTriggerInstaller.isPlacementValid)
    PlacementScreenController.onTerrainValidationFinished = Utils.overwrittenFunction(PlacementScreenController.onTerrainValidationFinished, SellPointTriggerInstaller.onTerrainValidationFinished)
	
    PlacementUtil.isInsidePlacementPlaces = Utils.overwrittenFunction(PlacementUtil.isInsidePlacementPlaces, SellPointTriggerInstaller.isInsidePlacementPlaces);
    PlacementUtil.isInsideRestrictedZone = Utils.overwrittenFunction(PlacementUtil.isInsideRestrictedZone, SellPointTriggerInstaller.isInsideRestrictedZone);
	
	self.debugOutput = false
	self.initialised = false
	
end

function SellPointTriggerInstaller:deleteMap()
end

--function PlacementUtil.hasObjectOverlap(placeable, x, y, z, rotY)
--function PlacementUtil.hasOverlapWithPoint(placeable, x, y, z, rotY, pointX, pointZ)

function SellPointTriggerInstaller.isInsidePlacementPlaces(places, superFunc, placeable, x, y, z) 
    if placeable ~= nil and placeable.customEnvironment == 'FS19_PlaceableSellPoints' then
		return false
	end
	return superFunc(places, placeable, x, y, z) 
end
function SellPointTriggerInstaller.isInsideRestrictedZone(restrictedZones, superFunc, placeable, x, y, z)
    if placeable ~= nil and placeable.customEnvironment == 'FS19_PlaceableSellPoints' then
		return false
	end
	return superFunc(restrictedZones, placeable, x, y, z) 
end

function SellPointTriggerInstaller:update(dt)
	if not self.initialised then
		--print("***SellPointTriggerInstaller is loaded***")
		self.initialised = true
		
		local list = {}

		-- Prevent Duplicate Selling Point Names
		for  _, item in pairs(g_storeManager.items) do
			if item.categoryName == "PLACEABLESELLPOINTS" then
				for _, placeable in pairs(g_currentMission.placeables) do
					if placeable.sellingStation ~= nil then
						if placeable.sellingStation.stationName == item.name then
							if g_currentMission.SellPointTriggers[item.name]==nil then
								g_currentMission.SellPointTriggers[ item.name ] = 0
							end
						end
					end
				end
			end
		end
		
		if self.debugOutput then
			print("FillTypes:")
			for _, fillType in pairs(g_fillTypeManager.fillTypes) do
				print("  "..fillType.index.." - "..fillType.name)
			end
			print("Placeables:")
			for _, placeable in pairs(g_currentMission.placeables) do
				if placeable.sellingStation ~= nil then
					print("  "..placeable.sellingStation.stationName)
					for index, _ in pairs(placeable.sellingStation.acceptedFillTypes) do
						print("  -- "..tostring(index).." - "..g_fillTypeManager:getFillTypeNameByIndex(index) )
					end
				end
			end
			print("SellPointTriggers:")
			for sellPointName, value in pairs(g_currentMission.SellPointTriggers) do
				print("  "..sellPointName.." ("..tostring(value)..")")
			end
		end
	end
end

function SellPointTriggerInstaller.canPlacePlaceableSellPoint(placeable)
	if placeable~=nil and placeable.customEnvironment=='FS19_PlaceableSellPoints' and placeable:canBuy() then
		if placeable.appearsOnPDA == false or (placeable.sellingStation~=nil and
		g_currentMission.SellPointTriggers[placeable.sellingStation.stationName] == nil) then
			return true
		end
	end
	return false
end

function SellPointTriggerInstaller:isPlacementValid(superFunc, placeable, x, y, z, yRot, distance)
	if SellPointTriggerInstaller.canPlacePlaceableSellPoint(placeable) then
		return true, PlacementScreenController.PLACEMENT_REASON_SUCCESS
	end
	return superFunc(self, placeable, x, y, z, yRot, distance)
end

function SellPointTriggerInstaller:onTerrainValidationFinished(superFunc, errorCode, displacedVolume, blockedObjectName)
	if true or SellPointTriggerInstaller.canPlacePlaceableSellPoint(self.placeable) then
		if errorCode == TerrainDeformation.STATE_FAILED_BLOCKED
		or errorCode == TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT
		then
			errorCode = TerrainDeformation.STATE_SUCCESS
		end
		if errorCode == TerrainDeformation.STATE_SUCCESS then
			displacedVolume = 0
		end
	end
	return superFunc(self, errorCode, displacedVolume, blockedObjectName)
end

-- ADD custom strings from ModDesc.xml to GLOBAL g_i18n
local i = 0
local realI18N = getfenv(0)["g_i18n"]
local xmlFile = loadXMLFile("modDesc", modDir.."modDesc.xml")
while true do
	local key = string.format("modDesc.l10n.text(%d)", i)
	if not hasXMLProperty(xmlFile, key) then
		break
	end	
	local name = getXMLString(xmlFile, key.."#name")
	local text = getXMLString(xmlFile, key.."."..g_languageShort)
	if name ~= nil then
		realI18N:setText(name, text)
	end
	i = i + 1
end
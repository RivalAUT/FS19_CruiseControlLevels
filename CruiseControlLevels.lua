--
--
-- CruiseControlLevels
--
-- # Author:  Rival
-- # date: 02.06.2020

CruiseControlLevels = {}

function CruiseControlLevels.prerequisitesPresent(specializations)
    return true
end

function CruiseControlLevels.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CruiseControlLevels)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CruiseControlLevels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CruiseControlLevels)
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", CruiseControlLevels)
	--SpecializationUtil.registerEventListener(vehicleType, "onUpdate", CruiseControlLevels)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", CruiseControlLevels)
end

function CruiseControlLevels:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_ccl
		spec.actionEvents = {}
        self:clearActionEventsTable(spec.actionEvents)

        if self:getIsActiveForInput(true, true) then						--- addActionEvent arguments 5-9: triggerUp, triggerDown, triggerAlways, startActive, callbackState)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CC_LEVEL, self, CruiseControlLevels.toggleCruiseControlLevel, false, true, false, true)
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_CC_LEVEL_BACK, self, CruiseControlLevels.toggleCruiseControlLevel, false, true, false, true)
        end
    end
end

function CruiseControlLevels:onLoad(savegame)
	self.spec_ccl = {}
	self.spec_ccl.speeds = {10, math.min(20,self:getCruiseControlMaxSpeed()), self:getCruiseControlMaxSpeed()}
	self.spec_ccl.currentLevel = 3
	--for k,v in pairs(g_currentMission.inGameMenu.hud.speedMeter) do print(k,v) end
end

function CruiseControlLevels:onPostLoad(savegame)
	if savegame ~= nil then
		local speed1 = getXMLInt(savegame.xmlFile, savegame.key..".CruiseControlLevels#speed1")
		if speed1 ~= nil then
			self.spec_ccl.speeds[1] = speed1
		end
		local speed2 = getXMLInt(savegame.xmlFile, savegame.key..".CruiseControlLevels#speed2")
		if speed2~= nil then
			self.spec_ccl.speeds[2] = speed2
		end
		local speed3 = getXMLInt(savegame.xmlFile, savegame.key..".CruiseControlLevels#speed3")
		if speed3 ~= nil then
			self.spec_ccl.speeds[3] = speed3
		end
		local curLevel = getXMLInt(savegame.xmlFile, savegame.key..".CruiseControlLevels#currentLevel")
		if curLevel ~= nil then
			self.spec_ccl.currentLevel = curLevel
		end
	end
end

function CruiseControlLevels:setCruiseControlMaxSpeedListener(speed)
	if self.spec_ccl ~= nil then
		self.spec_ccl.speeds[self.spec_ccl.currentLevel] = speed
		--print(string.format("cruise control speed changed to %d", speed))
	end
end

Drivable.setCruiseControlMaxSpeed = Utils.appendedFunction(Drivable.setCruiseControlMaxSpeed, CruiseControlLevels.setCruiseControlMaxSpeedListener)

function CruiseControlLevels:saveToXMLFile(xmlFile, key)
	setXMLInt(xmlFile, key.."#speed1", math.ceil(self.spec_ccl.speeds[1]))
	setXMLInt(xmlFile, key.."#speed2", math.ceil(self.spec_ccl.speeds[2]))
	setXMLInt(xmlFile, key.."#speed3", math.ceil(self.spec_ccl.speeds[3]))
	setXMLInt(xmlFile, key.."#currentLevel", self.spec_ccl.currentLevel)
end

function CruiseControlLevels.toggleCruiseControlLevel(self, actionName, inputValue, callbackState, isAnalog)
	if actionName == "TOGGLE_CC_LEVEL" then
		self.spec_ccl.currentLevel = self.spec_ccl.currentLevel + 1
		if self.spec_ccl.currentLevel > 3 then
			self.spec_ccl.currentLevel = 1
		end
	elseif actionName == "TOGGLE_CC_LEVEL_BACK" then
		self.spec_ccl.currentLevel = self.spec_ccl.currentLevel - 1
		if self.spec_ccl.currentLevel < 1 then
			self.spec_ccl.currentLevel = 3
		end
	end
	
	self:setCruiseControlMaxSpeed(self.spec_ccl.speeds[self.spec_ccl.currentLevel])
	if self.spec_drivable.cruiseControl.speed ~= self.spec_drivable.cruiseControl.speedSent then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCruiseControlSpeedEvent:new(self, self.spec_drivable.cruiseControl.speed), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SetCruiseControlSpeedEvent:new(self, self.spec_drivable.cruiseControl.speed))
		end
		self.spec_drivable.cruiseControl.speedSent = self.spec_drivable.cruiseControl.speed
	end
end

function CruiseControlLevels:onDraw()
	if self.spec_enterable.isEntered then
		local cruiseOverlay = g_currentMission.inGameMenu.hud.speedMeter.cruiseControlElement.overlay	
		local KeyPosX = cruiseOverlay.x + cruiseOverlay.width * 0.8
		local KeyPosY = cruiseOverlay.y + cruiseOverlay.height * 0.8
		local KeyTextSize = g_currentMission.inGameMenu.hud.speedMeter.cruiseControlTextSize * 0.55

		setTextColor(unpack(g_currentMission.inGameMenu.hud.speedMeter.cruiseControlColor))
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(KeyPosX, KeyPosY, KeyTextSize, tostring(self.spec_ccl.currentLevel))
		setTextColor(1,1,1,1)
		setTextBold(false)
	end
end
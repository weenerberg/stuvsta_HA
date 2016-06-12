--[[
%% properties
121 value
%% globals
--]]

function anyoneHome()
	local martinHome = fibaro:getGlobalValue("Martin_Home");
	local rebeccaHome = fibaro:getGlobalValue("Rebecca_Home");
  
	if (martinHome == "True" or rebeccaHome == "True") then
    	fibaro:debug("Someone is registered as home.");
		return true;
	else
    	fibaro:debug("No one is registered as home.");
		return false;
	end
end


function getDimmerLevel(timeOfDay, lightLevel)
  	local level;
  	if(timeOfDay == "Night") then
    	level = 15;
    	fibaro:debug("Night. Dimmer level should be " .. level);
    else
    	level = 50 - lightLevel;
    	if(level < 0) then 
      		level = 0;
      	end
    	fibaro:debug("Dimmer level should be " .. level);
    end
  	
  	return level;
end

-- PROPERTIES --
local luxID = 123;
local motionID = 121;
local lampIDs = {175,179,183,187};

-- MAIN --
local started = os.time();
fibaro:debug("--- Scene triggered at " .. os.date("%x %X", started));

if(fibaro:countScenes() > 1) then
  fibaro:debug("--- Too many active scenes. Aborting...");
  fibaro:abort();
end

local startSource = fibaro:getSourceTrigger();

-- CURRENT LIGHT LEVEL
local lightLevel = tonumber(fibaro:getValue(luxID, "value"))
fibaro:debug("Light level: " .. lightLevel)

-- MOTION DETECTED?
local motionDetectValue = tonumber(fibaro:getValue(motionID, "value"));

if	((motionDetectValue > 0 and anyoneHome()) or startSource["type"] == "other")
then
  
  	local timeOfDay = fibaro:getGlobalValue("TimeOfDay"); 
  	local level = getDimmerLevel(timeOfDay, lightLevel);
  
  	-- Adjust light level for all dimmers
	for key,id in pairs (lampIDs) do
    	fibaro:debug ("Turning on light id " .. id);
    	
    	local currentDimmerLevel = fibaro:getValue(id, "value");
    	fibaro:debug("Current dimmer level is " .. currentDimmerLevel);
    
    	-- If light is off then adjust level to time of day
    	if (currentDimmerLevel == "0") then
  			fibaro:call(id, "setValue", level);
      		fibaro:debug("Setting dimmer level to " .. level);
      	else
      		fibaro:debug("Lights already on. No adjustment done.");
      	end
	end
end

local done = os.time();
fibaro:debug("--- Scene finished at " .. os.date("%x %X", done));

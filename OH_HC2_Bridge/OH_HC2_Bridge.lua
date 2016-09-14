--[[
%% properties
408 value
408 batteryLevel
408 tamper
409 value
410 value
413 value
413 batteryLevel
413 tamper
414 value
415 value
394 value
397 value
397 power
397 energy
401 value
401 power
401 energy
405 value
405 power
405 energy
419 value
419 power
419 energy
433 value
433 power
433 energy
429 value
429 batteryLevel
431 value
421 value
422 value
423 value
425 value
426 value
427 value


313 value
313 batteryLevel
313 tamper
314 value
315 value
298 value
298 power
298 energy
340 value
340 power
340 energy
302 value
302 power
302 energy
306 value
306 power
306 energy
309 value
310 value
311 value


319 value
319 power
319 energy
326 value
326 targetLevel
326 batteryLevel
322 value
322 batteryLevel
322 tamper
323 value
324 value


467 value
467 batteryLevel
467 tamper
468 value
469 value
470 value
471 value
485 value
485 batteryLevel
485 tamper
486 value
487 value
488 value
489 value
444 value
444 power
444 energy
445 sceneActivation
448 value
448 power
448 energy
452 value
452 power
452 energy
456 value
456 power
456 energy
463 value
463 batteryLevel
463 tamper
464 value
465 value


351 value
351 batterlyLevel
351 tamper
352 value
353 value
274 value
344 value
344 power
344 energy
348 value
348 power
348 energy
357 value
358 value
356 value


334 value
334 batteryLevel
334 tamper
335 value
336 value
330 value
330 power
330 energy
331 value
332 value
328 value
328 power
328 energy


367 value
367 power
367 energy
371 value
371 power
371 energy


392 value
392 batteryLevel
481 value
482 value
483 value

495 value
495 batteryLevel
378 value
378 batteryLevel
381 value
381 power
381 energy
389 value
390 value
390 mode
388 value
388 mode


361 value
361 power
361 energy
364 value
364 targetLevel
364 batteryLevel


473 value
473 batteryLevel


386 value
460 value
460 power
460 energy
375 value
375 power
375 energy
440 value
440 power
440 energy
497 value
497 r
497 b
497 g
497 w
497 energy
497 power

436 value
436 power
436 energy

477 value
478 value
479 value

%% globals
--]]

local function logDebug(msg)
  local isDebug = fibaro:getGlobalValue("isDebug")
  if (isDebug == "True") then
    fibaro:debug(msg)
  end
end


local function request(meth, requestUrl, data)

  logDebug("Calling url: " .. requestUrl .. " with data: " .. data)

  local http = net.HTTPClient()  
  http:request(requestUrl, {
      options = {
        method = meth,
        headers = {},
        data = data
      },
      success = function (response)
          local isDebug = fibaro:getGlobalValue("isDebug")
          if (isDebug == "True") then
            local now = os.time()
            fibaro:debug("--- Scene succeeded at " .. os.date("%x %X", now))
          end
              
            end,
      error = function (err)
              local now = os.time()
          fibaro:debug("--- Update failed at " .. os.date("%x %X", now));
              fibaro:debug ("Error:" .. err)
            end
  })
end

local function propertyErrorMessage(prop)
  local devNotification = tonumber(fibaro:getGlobalValue("DevNotification"))
  local msg = 'Unknown: ' .. prop
  fibaro:debug(msg)
  fibaro:call(devNotification, "sendPush", msg);
end


local function transformSendData(deviceType, triggeringProperty, value)

  if (deviceType == "com.fibaro.binarySwitch" or deviceType == "com.fibaro.FGWP101"   or
      deviceType == "com.fibaro.FGMS001"      or deviceType == "com.fibaro.FGMS001v2" or
      deviceType == "com.fibaro.doorLock") then
    if(triggeringProperty == "value") then
      if (tonumber(value) > 0) then return 'ON' else return 'OFF' end
    end
  elseif (deviceType == "com.fibaro.doorSensor") then
    if(triggeringProperty == "value") then
      if (tonumber(value) > 0) then return 'OPEN' else return 'CLOSED' end
    end
  end
  logDebug("DeviceType: " .. deviceType .. " Property: " .. triggeringProperty .. " Value: " .. value)
  return value
end

-- MAIN --
local now = os.time()
logDebug("--- Scene triggered at " .. os.date("%x %X", now));

local trigger = fibaro:getSourceTrigger()

if(trigger['type'] == 'property') then
    
  local deviceID = trigger['deviceID']
  local deviceType = fibaro:getType(deviceID)
  local deviceName = fibaro:getName(deviceID)
  local triggeringProperty = trigger['propertyName']
  local newValue = fibaro:getValue(deviceID, triggeringProperty)
  
  logDebug('Src: ' .. deviceID .. ' Trigger prop: ' .. triggeringProperty .. ' Type: ' .. deviceType .. ' Name: ' .. deviceName )
  
  local baseUrl = fibaro:getGlobalValue("OH_url") .. '/rest/items/'
  local deviceSuffix = '_' .. deviceID
  local sendData = ""
  
  local method = 'PUT'
  
  if(deviceType == "com.fibaro.FGD212"            or deviceType == "com.fibaro.multilevelSwitch"  or deviceType == "com.fibaro.binarySwitch"      or 
     deviceType == "com.fibaro.FGWP101"           or deviceType == "com.fibaro.doorLock"          or deviceType == "com.fibaro.setPoint"          or
     deviceType == "com.fibaro.thermostatDanfoss" or deviceType == "com.fibaro.doorSensor"        or deviceType == "com.fibaro.operatingMode"     or
     deviceType == "com.fibaro.lightSensor"       or deviceType == "com.fibaro.temperatureSensor" or deviceType == "com.fibaro.multilevelSensor"  or
     deviceType == "com.fibaro.FGMS001"           or deviceType == "com.fibaro.FGMS001v2") then
    if(triggeringProperty == "value") then
      sendData = transformSendData(deviceType,triggeringProperty,newValue)
      deviceSuffix = deviceSuffix .. '/state'
    elseif (triggeringProperty == "power"       or triggeringProperty == "energy"       or triggeringProperty == "sceneActivation"  or 
            triggeringProperty == "targetLevel" or triggeringProperty == "batteryLevel" or triggeringProperty == "mode"             or
            triggeringProperty == "tamper") then
      sendData = transformSendData(deviceType,triggeringProperty,newValue)
      deviceSuffix = deviceSuffix .. "_" .. triggeringProperty .. '/state'
    else -- UNKNOWN --
      propertyErrorMessage(triggeringProperty)
      fibaro:debug('Src: ' .. deviceID .. ' Trigger prop: ' .. triggeringProperty .. ' Type: ' .. deviceType .. ' Name: ' .. deviceName )
      return
    end
  -- UNKNOWN --
  else
    propertyErrorMessage(deviceType)
    fibaro:debug('Src: ' .. deviceID .. ' Trigger prop: ' .. triggeringProperty .. ' Type: ' .. deviceType .. ' Name: ' .. deviceName )
    return
  end
  
  request(method, baseUrl .. deviceName .. deviceSuffix, sendData)
end
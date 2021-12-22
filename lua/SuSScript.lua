-- File: SuSScript.lua
local deviceManager = require "telldus.DeviceManager"
local TYPE_TEMPERATURE = 1
local TYPE_HUMIDITY = 2
local TYPE_WATT = 256
local store = {}

function onInit()
	local sus = require 'sus.Client'
	if sus == nil then
		print("Initcheck: SUS plugin is not installed")
		return
	else
		print("Initcheck: SUS plugin is loaded")
		sus:send{msg='Telldus LUA SUS is loaded'}
	end
end

function onDeviceStateChanged(device, state, stateValue)
	local sus = require 'sus.Client'
	if state == 1 then
		status = "ON"
	elseif state == 2 then
		status = "OFF"
	end
	--report = device:name() .. " " .. status
	local report = device:id()
	report = report .. ", " .. device:name()
	report = report .. ", " .. state
	report = report .. ", " .. stateValue
	--print("Report: " .. report)
	local ret = sus:send{msg="SUS " .. report}-- .. string.char(10)}
end


function SensorName(valueType)
	if valueType == TYPE_TEMPERATURE then return 'C'
	elseif valueType == TYPE_HUMIDITY then return '%'
	elseif valueType == TYPE_WATT then return 'W'
	else return string.format(" Unknown Sensor Type(%s)", valueType) end
end


function onSensorValueUpdated(device, valueType, value, scale)
    local sus = require 'sus.Client'
	--report = device:name() .. " " .. value
	--report = device:id()
	--report = report .. ", " .. device:name()
	--report = report .. ", " .. device:uuidAsString()
	--report = report .. ", " .. valueType
	--report = report .. ", " .. value
	--report = report .. ", " .. scale
	--print("Report: " .. report)
	
	--[=====[ 
	local report = device:id()
	report = report .. ", " ..	device:uuidAsString()
	report = report .. ", " ..	device:name()
	report = report .. ", " ..	device:methods()
	report = report .. ", " ..	device:protocol()
	report = report .. ", " ..	device:model()
	report = report .. ", " ..	device:typeString()
	report = report .. ", " ..	valueType
	report = report .. ", " ..	value
	report = report .. ", " ..	scale
  --]=====]
	--print("Report: " .. report)
	print(device:id())
	print(Dump(device:sensorValues()))
	
	if device:name() == "kjhjkh" then --== '' then 
		print("id "				..	device:id())
		print("uuid "			..	device:uuidAsString())
		print("uuid  "			..	tostring(device:uuid()))
		print("name "			..	device:name())
		print("methods "		..	device:methods())
		print("protocol "		..	device:protocol())
		print("model "			..	device:model())
		print("transport "		..	device:typeString())
		print("valueType "		..	valueType)
		print("value  "			..	value)
		print("scale  "			..	scale)

	end

	--print("Report: " .. report)
	--local ret = sus:send{msg="SUS " .. report}-- .. string.char(10)}
	
	--print(tostring(device:id()))
	if store[device:name()] ~= nil then
		store[device:name()][valueType] = value
--		print(string.format("time: %s, %s: %s, unit: %s",
--			os.date('%Y-%m-%d %H:%M:%S', os.time()),
--			device:name(),
--			value,
--			sensorName(valueType)))
	else
		store[device:name()] = {}
		store[device:name()][valueType] = value
	end
end

function onRf433RawData(msg)
	local sus = require 'sus.Client'
	--local inspect = require('inspect')

	--local json = tojson(msg)
	--local ret = sus:send{msg=json}
	--print(json)
	--print(tostring(msg))
	--print(dump(msg))
end

function Decode(obj)
  if type(obj) == "nil" then
    
  elseif type(obj) == "number" then
    return string.format("%.19g", value)
  elseif type(obj) == "string" then
    return obj
  elseif type(obj) == "boolean" then
    return tostring(obj)
  elseif type(obj) == "table" then
  elseif type(obj) == "function" then
    return "not implemented"
  elseif type(obj) == "thread" then
    return "not implemented"
  elseif type(obj) == "userdata" then
    return DecodeUserData(obj)
  else
    return "unknown type: " .. tostring(obj)
  end
  
end

function Dump(msg)
	if type(msg) == 'table' then
		local json = "{"
		for key, value in pairs(msg) do
			if type(value) == 'userdata' then
				json = json .. "\""..key.."\":\""..DecodeUserData(value).."\""
			elseif type(value) == 'string' then
				json = json .. "\""..key.."\":\""..value.."\","
			elseif type(value) == 'number' then
				local tmp = string.format("%.19g", value)
				json = json .. "\""..key.."\":\""..tmp.."\","
			end
		end
		json = json .. "}"
		return json
	end
end

function DecodeUserData(msg)
	local value = tostring(msg):gsub("'","\"")
	value = value:gsub(":%s",":\"")
	value = value:gsub(",","\",")
	value = value:gsub("}","\"}")
	value = value:gsub("}\"","}")
	return value
end

function Tojson(o)
	if type(o) == 'table' then
		local s = ""
		for k,v in pairs(o) do
			if string.len(s) > 0 then s = s .. "," end
			--print('k: '.. k .. ' , v: ' .. v)
			s = s .. "\"" .. k .. "\"" .. ":" .. Tojson(v)
		end
		return "{" .. s .. "}"
	elseif type(o) == 'string' then
		local k = "\"" .. tostring(o) .. "\""
	elseif type(o) == 'userdata' then
		local k = tostring(o):gsub("'","\"")
		k = k:gsub(":%s",":\"")
		k = k:gsub(",","\",")
		k = k:gsub("}","\"}")
		k = k:gsub("}\"","}")
    return k
	else
		--print(o)
	  local k = "\"" .. o .. "\""
    --k = tostring(o)
    return k
	end
end
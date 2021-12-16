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
	report = device:id()
	report = report .. ", " .. device:name()
	report = report .. ", " .. state
	report = report .. ", " .. stateValue
	--print("Report: " .. report)
	local ret = sus:send{msg="SUS " .. report}-- .. string.char(10)}
end


function sensorName(valueType)
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
	
	
	report = device:id()
	report = report .. ", " ..	device:uuidAsString()
	report = report .. ", " ..	device:name()
	report = report .. ", " ..	device:methods()
	report = report .. ", " ..	device:protocol()
	report = report .. ", " ..	device:model()
	report = report .. ", " ..	device:typeString()
	report = report .. ", " ..	valueType
	report = report .. ", " ..	value
	report = report .. ", " ..	scale
	--print("Report: " .. report)
	
	if device:name() == "kjhjkh" then --== '' then 
		print("id "				..	device:id())
		print("uuid "			..	device:uuidAsString())
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
	print(tostring(msg))
end

function tojson(o)
	if type(o) == 'table' then
		local s = ""
		for k,v in pairs(o) do
			if string.len(s) > 0 then s = s .. "," end
			--print('k: '.. k .. ' , v: ' .. v)
			s = s .. "\"" .. k .. "\"" .. ":" .. tojson(v)
		end
		return "{" .. s .. "}"
	elseif type(o) == 'string' then
		k = "\"" .. tostring(o) .. "\""
	elseif type(o) == 'userdata' then
		k = tostring(o):gsub("'","\"")
		k = k:gsub(":%s",":\"")
		k = k:gsub(",","\",")
		k = k:gsub("}","\"}")
		k = k:gsub("}\"","}")
	else
		--print(o)
		k = "\"" .. o .. "\""
		--k = tostring(o)
	end
	return k
end 
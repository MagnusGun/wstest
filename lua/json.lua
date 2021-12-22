-- File: json.lua

function onInit()
	print("loaded")
end

function onDeviceStateChanged(device, state, stateValue)
  print("onDeviceStateChanged")
  print(string.format("device:%s, state:%s, stateValue:%s", device, state, stateValue))
end

function onSensorValueUpdated(device, valueType, value, scale)
  print("onSensorValueUpdated")
  print(string.format("device:%s, valueType:%s, value:%s, scale:%s", device, valueType, value, scale))
end

function onRf433RawData(msg)
  print(TableToJSON(msg))
end

function TableToJSON(obj)
  local result = {}
  for key, value in pairs(obj) do
    if type(value) == "string" then
      table.insert(result, string.format("\"%s\":\"%s\"", key, value))
    elseif type(value) == "number" then
      table.insert(result, string.format("\"%s\":%s", key, string.format("%.25g", value)))
    elseif type(value) == "boolean" then
      table.insert(result, string.format("\"%s\":\"%s\"", key, tostring(value)))
    elseif type(value) == "userdata" then
      table.insert(result, string.format("\"%s\":%s", key, DecodeUserData(value)))
    elseif type(value) == "table" then
      table.insert(result, string.format("\"%s\":%s", key, TableToJSON(value)))
    end
  end
  result = "{" .. table.concat(result, ",") .. "}"
  return result
end

function DecodeUserData(msg)
	local value = tostring(msg):gsub("'","\"")
	value = value:gsub(":%s",":\"")
	value = value:gsub(",","\",")
	value = value:gsub("}","\"}")
	value = value:gsub("}\"","}")
	return value
end
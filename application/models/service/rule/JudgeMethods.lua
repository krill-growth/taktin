--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file JudgeMethods.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief methods to judge experiment
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local type = type
local tostring = tostring
local tonumber = tonumber
local math_floor = math.floor
local str_find = string.find
local str_sub = string.sub
local str_gsub = string.gsub
local str_format = string.format
local str_lower = string.lower
local str_upper = string.upper
local math_random = math.random
local tostring = tostring

local function parseProportion(strProportion)
    if type(strProportion) ~= 'string' or strProportion:find('^%d+[/]%d+$', 1) == nil then return nil end
    local s, _ = strProportion:find('/', 1, true)
    if not s then return nil end
    local fracNumerator = tonumber(strProportion:sub(1, s - 1))
    if fracNumerator == nil or math_floor(fracNumerator) < fracNumerator or fracNumerator < 0 then return nil end
    local fracDenominator = tonumber(strProportion:sub(s + 1))
    if fracDenominator == nil or math_floor(fracDenominator) < fracDenominator or fracDenominator <= 0 then return nil end
    if fracDenominator < fracNumerator then return nil end
    return fracNumerator, fracDenominator
end
local JudgeMethods = {}

function JudgeMethods.checkProportion(value, strProportion)
    if type(value) ~= 'number' or value < 0 or math_floor(value) < value then
        BDLOG.log_warning('JudgeMethods:checkProportion(value, strProportion), [value] invalid : %s', value)
        return false
    end
    local fracNumerator, fracDenominator = parseProportion(strProportion)
    if fracNumerator == nil then
        BDLOG.log_fatal('JudgeMethods:checkProportion(value, strProportion), [strProportion] invalid:', strProportion)
        return false
    end
    if (value % fracDenominator) < fracNumerator then return true else return false end
end

function JudgeMethods.checkStrIncCaseSensitive(str, substr)
    if type(str) ~= 'string' or type(substr) ~= 'string' or str == '' or substr == '' then
        BDLOG.log_warning('JudgeMethods:checkStrIncCaseSensitive(str, substr), params invalid')
        return false
    end
    if str_find(str, substr, 1, true) then return true else return false end
end

function JudgeMethods.checkStrIncCaseInsensitive(str, substr)
    if type(str) ~= 'string' or type(substr) ~= 'string' or str == '' or substr == '' then
        BDLOG.log_warning('JudgeMethods:checkStrIncCaseInsensitive(str, substr), params invalid')
        return false
    end
    local substrPattern = str_gsub(substr, "%a", function(c) return str_format("[%s%s]", str_lower(c), str_upper(c)) end)
    if str_find(str, substrPattern, 1) then return true else return false end
end

function JudgeMethods.checkStrEqualCaseSensitive(str1, str2)
    if type(str1) ~= 'string' or type(str2) ~= 'string' or str1 == '' or str2 == '' then
        BDLOG.log_warning('JudgeMethods:checkStrEqualCaseSensitive(str1, str2), params invalid')
        return false
    end
    if str1 == str2 then return true else return false end
end

function JudgeMethods.checkStrEqualCaseInsensitive(str1, str2)
    if type(str1) ~= 'string' or type(str2) ~= 'string' or str1 == '' or str2 == '' then
        BDLOG.log_warning('JudgeMethods:checkStrEqualCaseInsensitive(str1, str2), invalid')
        return false
    end
    local strPattern = str_gsub(str2, "%A", function(char) return str_format("[%s]", char) end)
    strPattern = str_gsub(strPattern, "%a", function(char) return str_format("[%s%s]", str_lower(char), str_upper(char)) end)
    BDLOG.log_debug('JudgeMethods.checkStrEqualCaseInsensitive, strPattern : %s', strPattern)
    strPattern = '^' .. strPattern .. '$'
    if str_find(str1, strPattern, 1) then return true else return false end
end

function JudgeMethods.checkStrReMatch(str, strPreg, strModel)
    BDLOG.log_debug("string : %s , RE pattern : %s , RE model : %s", str, strPreg, strModel)
    if type(str) ~= 'string' or type(strPreg) ~= 'string' or str == '' or strPreg == '' then
        BDLOG.log_warning('JudgeMethods:checkStrReMatch(str, strPreg, strModel), params invalid')
        return false
    end
    -- 'rule_content' save RE pattern, 'rule_re_model' save RE model
    if ngx.re.match(str, strPreg, strModel) then return true else return false end
end

function JudgeMethods.checkWhiteList(value, whiteList)
    if type(value) ~= 'string' or type(whiteList) ~= 'string' or value == '' or whiteList == '' then
        BDLOG.log_warning('JudgeMethods:checkwhiteList(value, whiteList), params invalid')
        return false
    end
    if whiteList:sub(-1) ~= ',' then whiteList = whiteList .. ',' end
    local pos = 1
    for index in function() return str_find(whiteList, ',', pos, true) end do
        if value == str_sub(whiteList, pos, index - 1) then return true end
        pos = index + 1
    end
    return false
end

function JudgeMethods.checkListStrInc(strParent, strSubList)
    if type(strParent) ~= 'string' or type(strSubList) ~= 'string' or strParent == '' or strSubList == '' then
        BDLOG.log_warning('JudgeMethods:checkListStrInc(strParent, strSubList), params invalid')
        return false
    end
    if strSubList:sub(-1) ~= ',' then strSubList = strSubList .. ',' end
    local pos = 1
    for index in function() return str_find(strSubList, ',', pos, true) end do
        if str_find(strParent, str_sub(strSubList, pos, index - 1), 1, true) then return true end
        pos = index + 1
    end
    return false
end

function JudgeMethods.checkRandomValueInProprotion(strProportion)
    local fracNumerator, fracDenominator = parseProportion(strProportion)
    if fracNumerator == nil then
        BDLOG.log_warning('JudgeMethods:checkRandomValueInProprotion(strProportion), [strProportion] invalid : %s', strProportion)
        return false
    end
    local randValue = math_random(1, fracDenominator)
    BDLOG.log_debug('random value : %s', randValue)
    if randValue <= fracNumerator then return true else return false end
end

return JudgeMethods

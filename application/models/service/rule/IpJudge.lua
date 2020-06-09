--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file IpJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief IP dimension juge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local Ip = require('lua.bdlib.Ip')
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local str_find = string.find
local math_floor = math.floor
local Method = require('models.service.rule.JudgeMethods')

local IpJudge = {}

--[[
-- IP 维度 规则的判断
-- @ipInput  请求IP值
-- @ruleType 规则类型，现在支持按比例，和 CDIR段 匹配
-- @ruleContent 如果按比例，则是一个分数； 如果是 CDIR段 匹配，则是CDIR段列表
-- @return IpJudge
]]--
function IpJudge:new(ipInput, ruleType, ruleContent)
    local instance = {}
    instance.ipProportion_type = 1
    instance.ipSegment_type = 6
    instance.ipInput = ipInput
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContent
    setmetatable(instance, {__index = self})
    return instance
end
--[[
-- IP相关规则判断入口
-- @return boolean
]]--
function IpJudge:judge()
    if self.ruleType == self.ipProportion_type then
        BDLOG.log_debug('ipProportion judge , IP : %s', self.ipInput)
        local ipIntValue = Ip.ip2Int(self.ipInput)
        if not ipIntValue then 
            BDLOG.log_fatal('tranfer IP to int failed. IP Value : %s', self.ipInput)
            return false
        end
        return Method.checkProportion(ipIntValue, self.ruleContent)
    elseif  self.ruleType == self.ipSegment_type then
        BDLOG.log_debug('ip CDIR judge')
        return self:judgeCdirIm1()
    else
        BDLOG.log_fatal('unsupported rule type by IP judge. [rule type] : %s', self.ruleType)
        return false
    end
end
--[[
-- IP CDIR段匹配 规则的判断，采用字典树结构
-- @return boolean
]]--
function IpJudge:judgeCdirIm1()
    local ipBinStr = Ip.ip2BinStr(self.ipInput)
    if not ipBinStr then 
        BDLOG.log_fatal('IP invalid. IP Value : %s', self.ipInput)
        return false
    end
    BDLOG.log_debug('IP hash int value : %s', ipBinStr)
    local ruleContent = self.ruleContent
    if type(ruleContent) ~= 'table' then
        BDLOG.log_fatal('ruleContent invalid, not a table')
        return false
    end
    local bitPos = 1
    local tree = ruleContent
    while bitPos <= 32 do
        bitValue = ipBinStr:sub(bitPos, bitPos)
        -- 没有配置任何IP
        if (nil == next(tree)) then
            return false
        else
            -- 未匹配上
            if (nil == tree[bitValue]) then
                return false
            else
                -- 子table 是空 说明匹配成功
                if (nil == next(tree[bitValue])) then
                    return true
                end
            end
        end
        -- 子 table 不为空，继续后续二进制字符的匹配
        tree = tree[bitValue]
        bitPos = bitPos + 1
    end
end
--[[
-- IP CDIR段匹配 规则的判断
-- @return boolean
]]--
function IpJudge:judgeCdir()
    local ipBinStr = Ip.ip2BinStr(self.ipInput)
    if not ipBinStr then 
        BDLOG.log_fatal('IP invalid. IP Value : %s', self.ipInput)
        return false
    end
    BDLOG.log_debug('IP hash int value : %s', ipBinStr)
    local ruleContent = self.ruleContent
    if type(ruleContent) ~= 'string' or ruleContent == '' then
        BDLOG.log_fatal('ruleContent invalid. ruleContent Value : %s', ruleContent)
        return false
    end
    if ruleContent:sub(-1) ~= ',' then ruleContent = ruleContent .. ',' end
    local pos = 1
    for index in function() return ruleContent:find(',', pos, true) end do
        local cdirStr = ruleContent:sub(pos, index - 1)
        local backlashIndex = cdirStr:find('/', 1, true)
        if backlashIndex then 
            local cdirHostBinCount = tonumber(cdirStr:sub(backlashIndex + 1))
            if cdirHostBinCount == nil or math_floor(cdirHostBinCount) < cdirHostBinCount 
                or cdirHostBinCount < 1 or cdirHostBinCount > 32 then
                BDLOG.log_fatal( 'Host bit number in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            local cdirStrIpBin = Ip.ip2BinStr(cdirStr:sub(1, backlashIndex - 1))
            if (not cdirStrIpBin) then
                BDLOG.log_fatal('IP in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            local hostBinStr = cdirStrIpBin:sub(1, cdirHostBinCount)
            local pattern = '^' .. hostBinStr
            if ipBinStr:find(pattern, 1) then return true end
        else 
            BDLOG.log_fatal('ruleContent invalid. ruleContent Value : %s', ruleContent)
            return false
        end
        pos = index + 1
    end
    return false
end

return IpJudge

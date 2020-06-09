--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file PageUpdateConf.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief Page update conifg  
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local Ip = require('lua.bdlib.Ip')
local setmetatable = setmetatable
local type = type
local math_floor = math.floor
local table_insert = table.insert
local require = require
local TableUtil = require('lua.bdlib.Table')
local Cjson = require('cjson.safe')
local json_decode = Cjson.decode
local json_encode = Cjson.encode
local DaoExperConf = require('models.dao.ExperInfo')

local PageUpdateConf = {}

function PageUpdateConf:new(arr_input)
    local instance = {
        arr_ret = {
            errno = 0,
            data = {},
            msg = '',
        },
        RULE_INFO_DEF = {
            RULE_TYPE_PREG = 8,
            RULE_TYPE_IP_CIDR = 6,
            RULE_DIM_POSTDATA = 9,
        },
    }
    instance.input = arr_input
    instance.updateData = nil
    instance.delData = nil
    instance.experConf = nil
    setmetatable(instance, {__index = self})
    return instance
end
--[[
    更新实验配置
]]--
function PageUpdateConf:execute()
    if not self:parseInputData() then
        return self.arr_ret
    end
    -- get current conf
    local objExperConf = DaoExperConf:new()
    self.experConf = objExperConf:get()
    -- if has not conf, or old conf has error, set new conf
    if self.experConf == nil or type(self.experConf) ~= 'table' then
        BDLOG.log_warning('err_msg: get exeriment conf fail')
        self.experConf = {}
    end
    BDLOG.log_trace('Experiment conf : %s', TableUtil:serialize(self.experConf))
    -- delete experiment
    if self.delData ~= nil then
        for k, v in pairs(self.delData) do
            -- v is key in conf for delete data
            self.experConf[v] = nil
        end
    end
    -- update experiment conf
    if self.updateData ~= nil then
        for k, v in pairs(self.updateData) do
            self.experConf[k] = v
        end
        -- adjust conf
        local ret = self:adjustRuleContent()
        if not ret then
            self.arr_ret.errno = 1
            self.arr_ret.msg = 'adjustRuleContent failed.'
            BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno, self.arr_ret.msg)
            return self.arr_ret
        end
    end
    -- save conf
    BDLOG.log_trace('new experiment conf : %s', TableUtil:serialize(self.experConf))
    local newConf = json_encode(self.experConf)
    if newConf then
        local ret = objExperConf:set(newConf)
        if not ret then
            self.arr_ret.errno = 1
            self.arr_ret.msg = 'set experiment conf failed.'
            BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno, self.arr_ret.msg)
            return self.arr_ret
        end
    else
        self.arr_ret.errno = 1
        self.arr_ret.msg = 'json encode failed.'
        BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno ,self.arr_ret.msg)
        return self.arr_ret
    end
    BDLOG.log_trace('new experiment conf : %s', newConf)
    self.arr_ret.msg = 'update experiment conf OK.'
    BDLOG.log_trace('err_code: %s err_msg: %s', self.arr_ret.errno, self.arr_ret.msg)
    return self.arr_ret
end
--[[
    解析同步数据
]]--
function PageUpdateConf:parseInputData()
    if type(self.input) ~= 'table' then
        self.arr_ret.errno = 1
        self.arr_ret.msg = 'input data format error.'
        BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno ,self.arr_ret.msg)
        return false
    end
    BDLOG.log_trace('Input Data : %s', TableUtil:serialize(self.input))
    if self.input['update'] then
        self.updateData = json_decode(self.input['update'])
        if self.updateData == nil or type(self.updateData) ~= 'table' then
            self.arr_ret.errno = 1
            self.arr_ret.msg = 'input data format error.'
            BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno ,self.arr_ret.msg)
            return false
        end
    end
    if self.input['delete'] then
        self.delData = json_decode(self.input['delete'])
        if self.delData == nil or type(self.delData) ~= 'table' then
            self.arr_ret.errno = 1
            self.arr_ret.msg = 'input data format error.'
            BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret.errno ,self.arr_ret.msg)
            return false
        end
    end
    return true
end

--[[
    对策略规则做一些数据处理，以便于在策略判定时更高效的读取
]]--
function PageUpdateConf:adjustRuleContent()
    if (type(self.experConf) == 'table') then
        for groupKey, expsInfo in pairs(self.experConf) do
            -- 只对本次更新的实验做处理
            if ((self.updateData[groupKey] ~= nil) and (type(expsInfo) == 'table')) then
                for expKey, rulesInfo in pairs(expsInfo) do
                    if (type(rulesInfo['experiment_strategy_rules']) == 'table') then
                        for ruleKey, ruleInfo in pairs(rulesInfo['experiment_strategy_rules']) do
                            local ruleContent = ruleInfo['rule_content']
                            if (tonumber(ruleInfo['rule_dimension']) == self.RULE_INFO_DEF['RULE_DIM_POSTDATA']) then
                                local ret = self:parseReqParamsRuleContent(groupKey, expKey, ruleKey, ruleContent)    
                                if not ret then
                                    BDLOG.log_warning('parseReqParamsRuleContent failed.')
                                    return false
                                end
                                ruleContent = ret
                            end
                            if (tonumber(ruleInfo['rule_style']) == self.RULE_INFO_DEF['RULE_TYPE_PREG']) then
                                self:adjustRe(groupKey, expKey, ruleKey, ruleContent)
                            end
                            if (tonumber(ruleInfo['rule_style']) == self.RULE_INFO_DEF['RULE_TYPE_IP_CIDR']) then
                                local ret = self:adjustIpCidr2(ruleContent)
                                if (false == ret) then 
                                    BDLOG.log_fatal('exception happen, adjustIpCidr failed')
                                    return false
                                end
                                self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['rule_content'] = ret
                            end
                        end
                    end
                end
            end
        end
    end
    return true
end
--[[
-- Req Params 策略维度的策略规则解析
]]--
function PageUpdateConf:parseReqParamsRuleContent(groupKey, expKey, ruleKey, ruleContent)
    local ret = nil
    if type(ruleContent) ~= 'string' then
        BDLOG.log_fatal('rule content format error, not string, ruleContent : %s.', tostring(ruleContent))
        return false
    end
    local ruleContentJsonDecodeRet = json_decode(ruleContent)
    if (not ruleContentJsonDecodeRet) or (type(ruleContentJsonDecodeRet) ~= 'table') then
        BDLOG.log_fatal('rule content format error, json_decode failed, ruleContent : %s, json_decode return :%s.',
            tostring(ruleContent), tostring(ruleContentJsonDecodeRet))
        return false
    end
    local count = 0
    local content = nil
    for k, v in pairs(ruleContentJsonDecodeRet) do
        count = count + 1
        if (k ~= nil) then
            self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['req_params_key'] = k
        end
        if (v ~= nil) then
            self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['rule_content'] = v
            ret = v
        end
    end 
    if (count ~=  1) then
        BDLOG.log_fatal('rule content format error, ruleContent : %s.', tostring(ruleContent))
        return false
    end
    return ret
end

--[[
-- 解析正则表达式为 pattern 和 model 两部分
-- @param {groupKey} 实验分组
-- @param {expKey} 实验
-- @param {ruleKey} 规则
]]--
function PageUpdateConf:adjustRe(groupKey, expKey, ruleKey, ruleContent)
    local delimiter = ruleContent:sub(1,1) 
    local index = 1
    local lenRuleContent = #ruleContent
    while (index < lenRuleContent) do
        if (ruleContent:sub(-index, -index) == delimiter) then
            -- save pattern for preg
            self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['rule_content'] = {}
            local pattern = ruleContent:sub(2, -index - 1)
            self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['rule_content']['re_pattern'] = pattern
            local model = ''
            if (index > 1) then
                model = ruleContent:sub(-index + 1)
            end
            self.experConf[groupKey][expKey]['experiment_strategy_rules'][ruleKey]['rule_content']['re_model'] = model
            break
        end
        index = index + 1
    end
end

--[[
-- 解析IP CIDR 格式
-- @param {ruleContent} 规则内容，当规则是IP匹配类型时，规则内容为 IP CIDR 列表
]]--
function PageUpdateConf:adjustIpCidr(ruleContent)
    if type(ruleContent) ~= 'string' then
        BDLOG.log_fatal('rule content format error, not string, ruleContent : %s.', tostring(ruleContent))
        return false
    end
    local newContent = {}
    ruleContent = ruleContent .. ','
    local pos = 1
    for index in function() return ruleContent:find(',', pos, true) end do
        local cdirStr = ruleContent:sub(pos, index - 1)
        local backlashIndex = cdirStr:find('/', 1, true)
        if backlashIndex then 
            local cdirHostBinCount = tonumber(cdirStr:sub(backlashIndex + 1))
            if cdirHostBinCount == nil or math_floor(cdirHostBinCount) < cdirHostBinCount 
                or cdirHostBinCount < 1 or cdirHostBinCount > 32
            then
                BDLOG.log_fatal( 'Host bit number in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            local ipStr = cdirStr:sub(1, backlashIndex - 1);
            local cdirStrIpBin = Ip.ip2BinStr(ipStr)
            if (not cdirStrIpBin) then
                BDLOG.log_fatal('IP in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            cdirHostBinCount = tostring(cdirHostBinCount)
            if (type(newContent[cdirHostBinCount]) ~= 'table') then
                newContent[cdirHostBinCount] = {}
            end
            -- IP 格式的采用 十进制 做key
            if ('32' == cdirHostBinCount) then
                newContent['32'][ipStr] = true 
            else
                -- CDIR 格式的 采用 二进制 做Key
                local hostBinStr = cdirStrIpBin:sub(1, cdirHostBinCount)
                newContent[cdirHostBinCount][hostBinStr] = true
            end
        else 
            BDLOG.log_fatal('ruleContent invalid. ruleContent Value : %s', ruleContent)
            return false
        end
        pos = index + 1
    end
    return newContent
end

function PageUpdateConf:adjustIpCidr2(ruleContent)
    if type(ruleContent) ~= 'string' then
        BDLOG.log_fatal('rule content format error, not string, ruleContent : %s.', tostring(ruleContent))
        return false
    end
    local newContent = {}
    ruleContent = ruleContent .. ','
    local pos = 1
    for index in function() return ruleContent:find(',', pos, true) end do
        local cdirStr = ruleContent:sub(pos, index - 1)
        local backlashIndex = cdirStr:find('/', 1, true)
        if backlashIndex then 
            local cdirHostBinCount = tonumber(cdirStr:sub(backlashIndex + 1))
            if cdirHostBinCount == nil or math_floor(cdirHostBinCount) < cdirHostBinCount 
                or cdirHostBinCount < 1 or cdirHostBinCount > 32
            then
                BDLOG.log_fatal( 'Host bit number in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            local ipStr = cdirStr:sub(1, backlashIndex - 1);
            local cdirStrIpBin = Ip.ip2BinStr(ipStr)
            if (not cdirStrIpBin) then
                BDLOG.log_fatal('IP in ruleContent invalid. ruleContent Value : %s', ruleContent)
                return false
            end
            local hostBinStr = cdirStrIpBin:sub(1, cdirHostBinCount)
            local bitPos = 1
            local tree = newContent
            while bitPos <= cdirHostBinCount do
                bitValue = hostBinStr:sub(bitPos, bitPos)
                if (type(tree[bitValue]) ~= 'table') then
                    tree[bitValue] = {}
                else 
                    if (nil == next(tree[bitValue])) then
                        BDLOG.log_trace('IP cdir :%s include by other cdir', cdirStr)
                        break
                    end
                end
                tree = tree[bitValue]
                bitPos = bitPos + 1
            end
        else 
            BDLOG.log_fatal('ruleContent invalid. ruleContent Value : %s', ruleContent)
            return false
        end
        pos = index + 1
    end
    return newContent
end
return PageUpdateConf

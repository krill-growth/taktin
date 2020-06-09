--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file Rule.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief rule judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local type = type
local tonumber = tonumber
local tostring = tostring
local str_format = string.format
local TableUtil = require('lua.bdlib.Table')
local ExpDef = require('library.def.ExperDef')
local InputKey = ExpDef.ActionJudgeInputFields

local Rule = {}

function Rule:new(ruleId, ruleConf, input)
    local instance = {
        RULE_DIM_REQ_PARAMS = 9,
        rule_dimension = {
            -- ip
            [1] = InputKey.client_ip,
            -- passid
            [2] = InputKey.pass_id,
            -- userId
            -- [3] = InputKey.pass_id,
            -- cuid
            [4] = InputKey.cuid,
            -- os_type
            [5] = InputKey.user_agent,
            -- version
            [6] = InputKey.user_agent,
            -- uri
            [7] = InputKey.req_uri,
            -- random, not need input value
            [8] = '',
            -- post data, config in rule content
            [9] = 'from_rule_content',
        },
        rule_type = {
            -- proprotion
            [1] = '',
            -- string include (case sencitive)
            [2] = '',
            -- string include (case insencitive)
            [3] = '',
            -- new userid
            [4] = '',
            -- old userid
            [5] = '',
            -- IP CIDR
            [6] = '',
            -- white list
            [7] = '',
            -- preg match
            [8] = '',
            -- string equal (case sencitive)
            [9] = '',
            -- string equal (case insencitive)
            [10] = '',
        },
        dimension_module = {
            -- ip
            [1] = 'IpJudge',
            -- passid
            [2] = 'PassidJudge',
            -- userId
            -- [3] = CInputKey.pass_id,
            -- cuid
            [4] = 'CuidJudge',
            -- os_type
            [5] = 'OstypeJudge',
            -- version
            [6] = 'VersionJudge',
            -- uri
            [7] = 'UriJudge',
            -- random
            [8] = 'RandomJudge',
            -- post data
            [9] = 'ReqParamsJudge'
        },
    }
    instance.judgeClassPath = 'models.service.rule'
    instance.rule_id = ruleId
    instance.rule_conf = ruleConf
    instance.input = input
    setmetatable(instance, {__index = self})
    return instance
end

function Rule:judge()
    BDLOG.log_notice('Rule:judge, rule id : %s Rule Conf : %s', self.rule_id, TableUtil:serialize(self.rule_conf))
    if self.rule_conf['rule_dimension'] == nil or self.rule_conf['rule_style'] == nil 
        or self.rule_conf['rule_content'] == nil then
        BDLOG.log_fatal('rule conf error, some key not config.')
        return false
    end
    local ruleContent = self.rule_conf['rule_content']
    -- rule dimesion integer and string value
    local strRuleDim = self.rule_conf['rule_dimension']
    local intRuleDim = nil
    if type(strRuleDim) == 'string' then
        intRuleDim = tonumber(strRuleDim)
    elseif type(strRuleDim) == 'number' then
        intRuleDim = strRuleDim
        strRuleDim = tostring(intRuleDim)
    else 
        BDLOG.log_fatal('rule conf : rule_dimension invalid : %s', self.rule_conf['rule_dimension'])
        return false
    end
    -- rule type integer and string value
    local strRuleType = self.rule_conf['rule_style']
    local intRuleType = nil
    if type(strRuleType) == 'string' then
        intRuleType = tonumber(strRuleType)
    elseif type(strRuleType) == 'number' then
        intRuleType = strRuleType
        strRuleType = tostring(intRuleType)
    else 
        BDLOG.log_fatal('rule conf : rule_style invalid : %s', self.rule_conf['rule_style'])
        return false
    end
    -- check dimension value in conf
    if self.rule_dimension[intRuleDim] == nil then
        BDLOG.log_fatal('rule dimension unsupported. [rule_dimension] : %s', strRuleDim)
        return false
    end
    -- check type value in conf
    if self.rule_type[intRuleType] == nil then
        BDLOG.log_fatal('rule type unsupported. [rule_type] : %s', strRuleType)
        return false
    end
    BDLOG.log_debug("rule_dim : %s , rule_type : %s", strRuleDim, strRuleType)
    BDLOG.log_debug("rule judge class path : %s %s", self.judgeClassPath, self.dimension_module[intRuleDim])
    local judgeClass = require(self.judgeClassPath .. '.' .. self.dimension_module[intRuleDim])
    local inputData = self:getInputDataJudgeBy(intRuleDim)
    if not inputData then
        BDLOG.log_warning('Rule:getInputDataJudgeBy failed.')
        return false
    end
    local objJudge = judgeClass:new(inputData, intRuleType, ruleContent)
    return objJudge:judge()
end

function Rule:getInputDataJudgeBy(intRuleDim)
    -- 不需要输入数据来判定，如随机
    if self.rule_dimension[intRuleDim] == '' then
        return ''
    end
    local dimensionInputKey = self.rule_dimension[intRuleDim]
    -- Request Params 维度获取判断值的key 从rule content中获取
    if self.RULE_DIM_REQ_PARAMS == intRuleDim and self.rule_conf['req_params_key'] ~= nil then 
        dimensionInputKey = self.rule_conf['req_params_key']
    end
    BDLOG.log_debug('dimensionInputKey : %s', dimensionInputKey)
    -- NULL value stand not need dimension input data
    if dimensionInputKey ~= '' and self.input[dimensionInputKey] == nil then 
        BDLOG.log_warning('Not have dimension Input, dimension : %s', self.dimension_module[intRuleDim])
        return false
    end
    if self.input[dimensionInputKey] == nil then
        return false
    end
    return self.input[dimensionInputKey]
end

return Rule

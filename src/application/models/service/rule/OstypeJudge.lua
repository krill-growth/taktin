--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file OstypeJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief os type judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tonumber = tonumber
local Method = require('models.service.rule.JudgeMethods')

local OstypeJudge = {}

function OstypeJudge:new(userAgent, ruleType, ruleContent)
    local instance = {}
    instance.strIncludecSen = 2
    instance.strIncludeInsen = 3
    instance.userAgent = userAgent
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContent
    setmetatable(instance, {__index = self})
    return instance
end

function OstypeJudge:judge()
    if self.ruleType == self.strIncludecSen then
        return Method.checkStrIncCaseSensitive(self.userAgent, self.ruleContent)
    elseif self.ruleType == self.strIncludeInsen then
        return Method.checkStrIncCaseInsensitive(self.userAgent, self.ruleContent)
    else
        BDLOG.log_fatal('unsupported rule type by Os_Type judge. [rule type] : %s', self.ruleType)
        return false
    end
end

return OstypeJudge

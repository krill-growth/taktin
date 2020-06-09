--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file UriJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief uri judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tostring = tostring
local tonumber = tonumber
local Method = require('models.service.rule.JudgeMethods')

local UriJudge = {}

function UriJudge:new(uriInput, ruleType, ruleContentInput)
    local instance = {}
    instance.strReMatch = 8
    instance.strEqualsen = 9
    instance.strEqualInsen = 10
    instance.uri = uriInput
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContentInput
    setmetatable(instance, {__index = self})
    return instance
end

function UriJudge:judge()
    if self.ruleType == self.strReMatch then 
        local pattern, model = self.ruleContent['re_pattern'], ''
        if (self.ruleContent['re_model']) then model = self.ruleContent['re_model'] end
        return Method.checkStrReMatch(self.uri, pattern, model)
    elseif self.ruleType == self.strEqualsen then
        return Method.checkStrEqualCaseSensitive(self.uri, self.ruleContent)
    elseif self.ruleType == self.strEqualInsen then
        return Method.checkStrEqualCaseInsensitive(self.uri, self.ruleContent)
    else
        BDLOG.log_fatal('unsupported rule type by Uri judge. [rule type] : %s', self.ruleType)
        return false
    end
end

return UriJudge

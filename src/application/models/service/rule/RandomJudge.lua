--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file RandomJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief random judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tonumber = tonumber
local Method = require('models.service.rule.JudgeMethods')

local RandomJudge = {}

function RandomJudge:new(nullValue, ruleType, ruleContent)
    local instance = {}
    instance.proportion_type = 1
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContent
    setmetatable(instance, {__index = self})
    return instance
end

function RandomJudge:judge()
    if self.ruleType == self.proportion_type then
        return Method.checkRandomValueInProprotion(self.ruleContent)
    else
        BDLOG.log_fatal('unsupported rule type by Random judge. [rule type] : %s', self.ruleType)
        return false
    end
end

return RandomJudge

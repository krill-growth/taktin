--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file VersionJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief version judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tonumber = tonumber
local Method = require('models.service.rule.JudgeMethods')

local VersionJudge = {}

function VersionJudge:new(userAgent, ruleType, ruleContent)
    local instance = {}
    instance.whitelist_type = 7
    instance.userAgent = userAgent
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContent
    setmetatable(instance, {__index = self})
    return instance
end

function VersionJudge:judge()
    if self.ruleType == self.whitelist_type then
        return Method.checkListStrInc(self.userAgent, self.ruleContent)
    else
        BDLOG.log_fatal('unsupported rule type by Version judge. [rule type] : %s', self.ruleType)
        return false
    end
end

return VersionJudge

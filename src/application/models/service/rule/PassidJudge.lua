--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file PassidJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief passid judge
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local Method = require('models.service.rule.JudgeMethods')

local PassidJudge = {}

function PassidJudge:new(passid, ruleType, ruleContent)
    local instance = {}
    instance.proportion_type = 1
    instance.whitelist_type = 7
    instance.passid = passid
    instance.ruleType = tonumber(ruleType)
    instance.ruleContent = ruleContent
    setmetatable(instance, {__index = self})
    return instance
end

function PassidJudge:judge()
    if self.ruleType == self.proportion_type then 
        return Method.checkProportion(tonumber(self.passid), self.ruleContent)
    elseif self.ruleType == self.whitelist_type then
        return Method.checkWhiteList(tostring(self.passid), self.ruleContent)
    else
        BDLOG.log_fatal('unsupported rule type by pass_id judge. [rule type] : %s', self.ruleType)
        return false
    end
end

return PassidJudge

--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file ExperGroup.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief class experiment group, group judge enter
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local type = type
local pairs = pairs
local Experiment = require('models.service.Experiment')

local ExperGroup = {}

function ExperGroup:new(groupId, arrExperGroupConf, input)
    local instance = {}
    instance.group_id = groupId
    instance.arr_exper_group_conf = arrExperGroupConf
    instance.input = input
    setmetatable(instance, {__index = self})
    return instance
end

function ExperGroup:judge()
    BDLOG.log_debug('>> ExperGroup:judge, experiment group id : %s', self.group_id)
    local ret, matchedExperId = '', ''
    for experId, _ in pairs(self.arr_exper_group_conf) do
        if type(self.arr_exper_group_conf[experId]) ~= 'table' then
            BDLOG.log_fatal('experiment conf not exist. [experiment group id] : %s ', experId)
            break
        end
        local objExperiment = Experiment:new(experId, self.arr_exper_group_conf[experId], self.input)
        if objExperiment:judge() then
            matchedExperId = experId
            break
        end
    end
    -- if has experiment content to return, turn to format 
    if matchedExperId ~= '' then
        local expContent = self.arr_exper_group_conf[matchedExperId].exp_content
        if (expContent ~= nil) and (expContent ~= '') then
            ret = {}
            ret["exp_code"] = matchedExperId
            ret["exp_content"] = self.arr_exper_group_conf[matchedExperId].exp_content
        else 
            ret = matchedExperId
        end
    end
    return ret
end

return ExperGroup

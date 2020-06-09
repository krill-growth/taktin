--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file PageJudge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief Page judge 
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local setmetatable = setmetatable
local tostring = tostring
local require = require
local type = type
local pairs = pairs
local ipairs = pairs
local Cjson = require('cjson.safe')
local ExperDef = require('library.def.ExperDef')
local Error = require('library.ErrInfo')
local TableUtil = require('lua.bdlib.Table')
local DaoExperConf = require('models.dao.ExperInfo')
local ExperGroup = require('models.service.ExperGroup')

local PageJudge = {}

function PageJudge:new(arr_input)
    local instance = {
        arr_ret = {
            ret = 0,
            data = {},
            msg = 'AB test judge OK',
        }
    }
    instance.input = arr_input
    instance.smallflow_groupid = 'group_smallflow'
    setmetatable(instance, {__index = self})
    return instance
end

function PageJudge:execute()
    BDLOG.log_trace('Input Data : %s ', TableUtil:serialize(self.input))
    BDLOG.log_debug('Load experiment config.')
    local objExperConf = DaoExperConf:new()
    self.exper_conf = objExperConf:get()
    if self.exper_conf == nil or type(self.exper_conf) ~= 'table' then
        self.arr_ret['ret'] = Error.EXPER_CONF_GET_ERROR.errCode
        self.arr_ret['msg'] = Error.EXPER_CONF_GET_ERROR.errMsg
        BDLOG.log_fatal('err_code: %s err_msg: %s', self.arr_ret['ret'], self.arr_ret['msg'])
        return self.arr_ret
    end
    BDLOG.log_debug('Experiment conf : %s', TableUtil:serialize(self.exper_conf))
    local arrGroupId = self:getGroupId(self.input[ExperDef.ActionJudgeInputFields.group_id])
    BDLOG.log_debug('Start experiment judgement.')
    for groupId  in pairs(arrGroupId) do
        if self.exper_conf[groupId] and (type(self.exper_conf[groupId]) == 'table') then
            local objExpGroup = ExperGroup:new(groupId, self.exper_conf[groupId], self.input)
            self.arr_ret.data[groupId] = objExpGroup:judge()
        else
            self.arr_ret.data[groupId] = ''
            if groupId == self.smallflow_groupid then
                self.arr_ret.data[groupId] = 'off'
            end
        end
    end
    return self.arr_ret
end

function PageJudge:getGroupId(strGroupId)
    BDLOG.log_debug('Group id list : %s', strGroupId)
    local arrGroupId = {}
    if strGroupId == 'all' then
        for group_id, _ in pairs(self.exper_conf) do
            arrGroupId[group_id] = ''
        end
    else
        local arrGroupIdList = Cjson.decode(strGroupId)
        if arrGroupIdList then
            for _, group_id in ipairs(arrGroupIdList) do
                arrGroupId[group_id] = '' 
            end
        else
            arrGroupId[strGroupId] = ''
        end
    end
    if arrGroupId[self.smallflow_groupid] == nil then
        arrGroupId[self.smallflow_groupid] = ''
    end
    BDLOG.log_debug('Group id array : %s', TableUtil:serialize(arrGroupId))
    return arrGroupId
end
return PageJudge

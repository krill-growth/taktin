--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file Judge.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief action judge experiment
]]-- 

local tostring = tostring
local setmetatable = setmetatable
local ReqFieldName = require('library.def.ExperDef').ActionJudgeInputFields
local PageJudge = require('models.service.PageJudge')
local BDLOG = require('lua.bdlib.BdLogWrite')
local Table = require('lua.bdlib.Table')
local Bduss = require('lua.bdlib.Bduss')
local Cjson = require('cjson')
local json_encode = Cjson.encode

local ActionJudge = {}

function ActionJudge:new(request)
    local instance = {} 
    instance['response'] = {
        ret = 1001,
        data = '',
        msg = 'inner error',
    }
    instance['request'] = request
    setmetatable(instance, {__index = self})
    return instance
end

function ActionJudge:execute()
    local ok, executeActionRet = pcall(self.executeAction, self) 
    if not ok then 
        BDLOG.log_fatal('may have inner error : %s', executeActionRet)
    end
    str_response = json_encode(self['response'])
    BDLOG.log_notice('return json data : %s', str_response)
    return str_response
end

function ActionJudge:executeAction()
    BDLOG.log_trace('start experiment judgement')
    if self.request['arr_post'] ~= nil then
        local arr_input = self:phraseInput()
        if arr_input['log_id'] then
            ngx.ctx.logid = arr_input['log_id']
            ngx.var.log_id = arr_input['log_id']
            arr_input['log_id'] = nil
        end
        local objPageJudge = PageJudge:new(arr_input)
        self.response = objPageJudge:execute()
    else
        self.response['ret'] = 1000
        self.response['data'] = ''
        self.response['msg'] = 'input param error'
    end
end

function ActionJudge:phraseInput() 
    local arr = self.request['arr_post']
    if arr[ReqFieldName.group_id] == nil then
        arr[ReqFieldName.group_id] = 'all'
    end
    if arr[ReqFieldName.req_uri] ~= nil  then
        arr[ReqFieldName.req_uri] = ngx.unescape_uri(arr[ReqFieldName.req_uri])
    end
    if arr[ReqFieldName.pass_id] == nil and arr[ReqFieldName.bduss] then
        arr[ReqFieldName.pass_id] = Bduss.decode64(arr[ReqFieldName.bduss])
        BDLOG.log_debug('ReqFieldName.pass_id : %s', arr[ReqFieldName.pass_id])
    end
    -- delete bduss kv
    arr[ReqFieldName.bduss] = nil
    return arr
end

return ActionJudge


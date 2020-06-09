--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file UpdateConf.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief action update experiment config
]]-- 

local require = require
local setmetatable = setmetatable
local PageUpdateConf = require('models.service.PageUpdateConf')
local BDLOG = require('lua.bdlib.BdLogWrite')
local Cjson = require('cjson')
local json_encode = Cjson.encode

local ActionUpdateConf = {}

function ActionUpdateConf:new(request)
    local instance = {} 
    instance['response'] = {
        errno = 1001,
        data = '',
        msg = 'inner error',
    }
    instance['request'] = request
    setmetatable(instance, {__index = self})
    return instance
end

function ActionUpdateConf:execute(request)
    local ok, executeActionRet = pcall(self.executeAction, self) 
    if not ok then 
        BDLOG.log_fatal('may have inner error : %s', executeActionRet)
    end
    str_response = json_encode(self['response'])
    BDLOG.log_notice('action return json data : %s', str_response)
    return str_response
end

function ActionUpdateConf:executeAction()
    BDLOG.log_debug('start update experiment conf.')
    if self.request['arr_post'] ~= nil then
        local objPageUpdateConf = PageUpdateConf:new(self.request['arr_post'])
        self['response'] = objPageUpdateConf:execute()
    else
        response['errno'] = 1000
        response['data'] = ''
        response['msg'] = 'input param error'
    end
end

return ActionUpdateConf


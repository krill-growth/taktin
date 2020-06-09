--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file ExperInfo.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief operate experiment config
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local Cjson = require('cjson.safe')
local FileUtil = require('lua.bdlib.File')
local json_decode = Cjson.decode
local setmetatable = setmetatable
local debug_getinfo = debug.getinfo
local io_open = io.open

local ExperInfo = {}

function ExperInfo:new()
    local _, filePath = FileUtil.dirname(debug_getinfo(1, 'S').source:sub(2))
    local instance = {}
    instance.filePath = filePath .. '/ExperInfo.conf'
    instance.exp_conf_cache_key = 'exper_conf_key'
    setmetatable(instance, {__index = self})
    return instance
end

function ExperInfo:get()
    local experConf = nil
    -- get from ngx.shared.DICT
    BDLOG.log_debug('get form ngx.shared.DICT ')
    local experDict = ngx.shared.exper
    experConf = experDict:get(self.exp_conf_cache_key)
    if experConf == nil then
        -- get from conf file
        BDLOG.log_debug('get form Experiment Config file : %s', self.filePath)
        local file = io_open(self.filePath, 'r')
        if file then
            experConf = file:read()
            if experConf then
                local setRet = experDict:set(self.exp_conf_cache_key, experConf)
                if not setRet then
                    BDLOG.log_fatal('set ngx.shared.DICT failed.')
                end
            else
                BDLOG.log_warning('read from Experiment Config file failed.')
                return nil
            end
            file:close()
        else
            BDLOG.log_fatal('Experiment Config file [%s] not exist, get experiment config failed.', self.filePath)
            return nil
        end
    end
    experConf = json_decode(experConf)
    if experConf then
        return experConf
    else    
        BDLOG.log_fatal('Experiment Config file json decode failed.')
        return nil
    end
end

function ExperInfo:set(experConf)
    if type(experConf) ~= 'string' then
        BDLOG.log_fatal('Experiment Config format error, not a string, set failed.')
        return false
    end
    -- check json format
    local ret = json_decode(experConf)
    if not ret then
        BDLOG.log_fatal('Experiment Config format error, not a json, set failed.')
        return false
    end
    -- write to exper conf file
    local file = io_open(self.filePath, 'w+')
    if file then 
        local ret = file:write(experConf)
        if ret then
            file:flush()
        else
            BDLOG.log_fatal('write experiment conf file failed.')
            return false
        end
        file:close()
    else
        BDLOG.log_fatal('open experiment conf file failed.')
        return false
    end
    -- set to ngx.shared.DICT
    local experDict = ngx.shared.exper
    local setRet = experDict:set(self.exp_conf_cache_key, experConf)
    if not setRet then
        BDLOG.log_fatal('set ngx.shared.DICT failed.')
        return false
    else
        return true
    end
end

return ExperInfo

--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file exper.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief app controller
]]-- 

local Error = require 'vanilla.error'

local ExperController = { }

ExperController['update_conf'] = 'UpdateConf'
ExperController['judge'] = 'Judge'

function ExperController:default()
    if ExperController[self.request.action_name] ~= nil then
        local ok, action_or_err = pcall(function() return require('actions.' .. ExperController[self.request.action_name]) end)
        if ok == true then
            ngx.log(ngx.DEBUG, 'Action [' .. self.request.action_name .. '] load OK ')
            local objAction = action_or_err:new(self.request)
            return true, objAction:execute()
        else
            ngx.log(ngx.ERR, 'Action load failed :' .. action_or_err)
            return false, action_or_err
        end
    end
    ngx.log(ngx.ERR, 'Action load failed : action name not exist')
    return false, 'Action load failed : action name not exist'
end

return  ExperController

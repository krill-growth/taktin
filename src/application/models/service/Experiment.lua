--[[
Copyright (c) 2016 Baidu.com, Inc. All Rights Reserved

@file Experiment.lua
@author sunnnychan@gmail.com
@date 2016/03/12 11:27:24
@brief class experiment, experiment judge enter
]]-- 

local BDLOG = require('lua.bdlib.BdLogWrite')
local str_find = string.find
local str_sub = string.sub
local table_sort = table.sort
local time_diff = os.difftime
local type = type
local pairs = pairs
local next = next
local tostring = tostring
local setmetatable = setmetatable
local Rule = require('models.service.Rule')
local Time = require('lua.bdlib.Time')

local function trim(str, substr)
    local strRet = str
    local s, e = str_find(strRet, '^' .. substr .. '+', 1)
    if s then
        strRet = str_sub(strRet, e + 1)
    end
    s, e = str_find(strRet, substr .. '+$', 1)
    if s then
        strRet = str_sub(strRet, 1, e - 1)
    end
    return strRet
end

local function ipairsBySortedKey(t)
    local t_tmp = {} 
    for k in pairs(t) do
        if type(k) == 'number' then
            t_tmp[#t_tmp + 1] = k
        end
    end
    table_sort(t_tmp)
    local i = 0
    return function()
        i = i + 1
        return t_tmp[i], t[t_tmp[i]]
    end
end

local function parseStrExpress(strExpress, arr, input, recur_hier)
    -- 递归大于20层直接返回结果
    if (not recur_hier) then recur_hier = 0 end
    if (recur_hier > 20) then
        BDLOG.log_fatal('Recursive hierarchy great then 20, may have infinite recursion')
        return nil
    else 
        recur_hier = recur_hier + 1
    end
    -- 删除表达式两端没有意义的空格
    local strExpress = trim(strExpress, ' ')
    -- 先检查表达式开始是 ! 开头，且 取反操作是针对整个表达式的
    local wholeNotFlag = false
    local checkRet = strExpress:find('^![ ]*[(].*[)]$', 1)
    if checkRet ~= nil then
        -- 如果是，置取反标识，在求出真个表达式值时取反
        wholeNotFlag = true
        -- 删除开头的 取反 符号
        strExpress = strExpress:sub(2)
    end
    strExpress = trim(strExpress, ' ')
    -- 删除表达式两端开头和结尾 成对的 括号
    local len = #strExpress
    while strExpress:sub(1, 1) == '(' do
        -- 如果最后一个字符不是右括号，则表达式两端无括号
        if strExpress:sub(-1, -1) ~= ')' then
            break
        end
        local braceCout, for_break_index = 1, nil
        for index = 2, len, 1 do
            local curr_char = strExpress:sub(index, index)
            if curr_char == '(' then
                braceCout = braceCout + 1
            elseif curr_char == ')' then
                braceCout = braceCout - 1
            end
            if (braceCout == 0) then 
                for_break_index = index 
                break 
            end
        end
        BDLOG.log_debug('braceCout : %s, for_break_index : %s', braceCout, for_break_index)
        if (braceCout == 0) then 
            if (for_break_index == len) then 
                strExpress = strExpress:sub(2, -2)
                strExpress = trim(strExpress, ' ')
                len = #strExpress 
            else
                break 
            end
        else 
            BDLOG.log_fatal('rule logic express invalid [%s] ', strExpress)
            return nil
        end
    end
    braceIndex, len = nil, nil
    strExpress = trim(strExpress, ' ')
    -- 找到当前表达式 第一层级 的 '|' '&' 操作符
    local braceCout = 0
    local arrIndexList = {}
    for index = 1, #strExpress, 1 do
        if strExpress:sub(index, index) == '(' then
            braceCout = braceCout + 1
        elseif strExpress:sub(index, index) == ')' then
            braceCout = braceCout - 1
        elseif strExpress:sub(index, index) == '|' or strExpress:sub(index, index) == '&' then
            if braceCout == 0 then
                arrIndexList[index] = strExpress:sub(index, index)
            end
        end
    end
    -- 如果括号不成对，表达式不合法
    if braceCout ~= 0 then 
        BDLOG.log_fatal('rule logic express invalid : %s ', strExpress)
        return nil
    end
    -- 如果当前表达式中不包含 '|' '&', 也不为空(为空表达式不合法),
    -- 则 表达式为 true, false, !true, !false, !(false), !(true), !(!true) 中的一种，称之为元表达式（可以直接求出值）
    if next(arrIndexList) == nil then
        if strExpress == '' then
            BDLOG.log_fatal('rule logic express invalid : %s ', strExpress)
            return nil
        end
        -- 元表达是否有取反操作
        local notFlag = false
        if strExpress:sub(1, 1) == '!' then
            notFlag = true;
            strExpress = strExpress:sub(2)
        end
        strExpress = trim(strExpress, ' ')
        -- 获取 规则判定结果
        local ruleJudgeRet = nil
        if arr[strExpress] then
            local objRule = Rule:new(strExpress, arr[strExpress], input) 
            ruleJudgeRet = objRule:judge()
            BDLOG.log_debug('rule judge result : %s', ruleJudgeRet)
            if type(ruleJudgeRet) ~= 'boolean' then
                BDLOG.log_fatal('Rturn value from Rule:judge invalid.')
                return nil
            end
        else
            BDLOG.log_warning('Rule conf not found, rule_id : %s ', strExpress)
            return false
        end
        if notFlag then ruleJudgeRet = not ruleJudgeRet end
        if wholeNotFlag then ruleJudgeRet = not ruleJudgeRet end
        BDLOG.log_debug('%s, last judge result : %s', strExpress, ruleJudgeRet)
        return ruleJudgeRet
    end
    -- 如果当前表达式不是元表达式，变量当前层级的 '|' 和 '&'，按照它们来划分子表达式
    local boolRet =  nil 
    local k_prev, v_prev = nil, nil
    for k, v in ipairsBySortedKey(arrIndexList) do
        -- 求出第一个子表达式的 值
        if boolRet == nil then
            k_prev = k
            v_prev = v
            boolRet = parseStrExpress(strExpress:sub(1, k_prev - 1), arr, input, recur_hier)
            if boolRet == nil then return nil end
        else
            -- 根据前一个表达式的值 和 接下来的 逻辑运算符号，来计算 这两个表达式组成的表达式的值
            if (v_prev == '&' and boolRet == true) or (v_prev == '|' and boolRet == false) then
                boolRet = parseStrExpress(strExpress:sub(k_prev + 1, k - 1), arr, input, recur_hier)
                if boolRet == nil then return nil end
            end
            k_prev = k
            v_prev = v
        end
    end
    -- 求出最后一个表达式
    if (v_prev == '&' and boolRet == true) or (v_prev == '|' and boolRet == false) then
        boolRet = parseStrExpress(strExpress:sub(k_prev + 1), arr, input, recur_hier)
        if boolRet == nil then return nil end
    end
    if wholeNotFlag then boolRet = not boolRet end
    return boolRet 
end

local Experiment = {}

function Experiment:new(experId, experConf, input)
    local instance = {}
    instance.exper_id = experId
    instance.exper_conf = experConf
    instance.input = input
    setmetatable(instance, {__index = self})
    return instance
end

function Experiment:judge()
    BDLOG.log_notice('Experiment:judge, experiment id : %s', self.exper_id)
    -- check experiment expired date
    if self.exper_conf['start_time'] and self.exper_conf['end_time'] 
        and self.exper_conf['end_time'] ~= '' then
        local timeCheckRet = self:checkTime(self.exper_conf['start_time'], self.exper_conf['end_time']) 
        if not timeCheckRet then
            BDLOG.log_warning('experiment not start, or has expired')
            return false
        end
    end
    -- rule judge
    -- check rule conf
    if self.exper_conf['experiment_strategy_rules'] == nil then
        BDLOG.log_fatal('rule conf not exist.')
        return false
    end
    if not self.exper_conf['rule_express'] then
        BDLOG.log_fatal('rule logic express not exist.')
        return false
    end
    -- judge by rule logic express
    return self:judgeByLogicExpress()  
end

function Experiment:checkTime(t_start, t_end)
    local now = ngx.time() 
    local intStart = Time:getTimestamp(t_start)
    if not intStart then
        BDLOG.log_fatal('experiment start time format error.')
        return false
    end
    local intEnd = Time:getTimestamp(t_end)
    if not intEnd then
        BDLOG.log_fatal('experiment end time format error.')
        return false
    end
    return (time_diff(now, intStart) > 0 and time_diff(now, intEnd) < 0) 
end

function Experiment:judgeByLogicExpress()
    local ret = parseStrExpress(self.exper_conf['rule_express'], 
        self.exper_conf['experiment_strategy_rules'], self.input)
    if ret == nil then
        BDLOG.log_fatal('rule logic express format invalid. [%s]', self.exper_conf['rule_express'])
        return false
    else
        return ret
    end
end

return Experiment

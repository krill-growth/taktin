local Bd_Log = require('lua.bdlib.BdLog')
local str_format = string.format
WRITE_LOG = Bd_Log.write_log

local ActionBase = {}

function ActionBase:init()
    local logId, logId_r = nil, nil
    if self.logId then logId = self.logId end
    if self.logId_r then logId_r = self.logId_r end
    ngx.log(ngx.DEBUG, str_format("logId [%s] logId_r [%s]", logId, logId_r))
    Bd_Log.init_log(logId, logId_r) 
end

return ActionBase

local Bootstrap = require('vanilla.bootstrap'):new(dispatcher)

function Bootstrap:initWaf()
    require('vanilla.sys.waf.acc'):check()
end

function Bootstrap:initErrorHandle()
    self.dispatcher:setErrorHandler({controller = 'error', action = 'error'})
end

function Bootstrap:initRoute()
    local router = self.dispatcher:getRouter()
    local simple_route = require('vanilla.routes.simple'):new(self.dispatcher:getRequest())
    router:addRoute(simple_route, true)
end

function Bootstrap:initView()
end

function Bootstrap:initPlugin()
    local admin_plugin = require('plugins.admin'):new()
    self.dispatcher:registerPlugin(admin_plugin);
end

function Bootstrap:initBd()
    require('lua.bdlib.BdInit').init()
end

function Bootstrap:boot_list()
    return {
        -- Bootstrap.initWaf,
        -- Bootstrap.initErrorHandle,
        Bootstrap.initRoute,
        -- Bootstrap.initView,
        -- Bootstrap.initPlugin,
        Bootstrap.initBd,
    }
end

return Bootstrap

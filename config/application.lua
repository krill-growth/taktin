local Appconf={}
Appconf.name = 'exper'

Appconf.route='vanilla.routes.simple'
Appconf.bootstrap='application.bootstrap'
Appconf.app={}
-- Appconf.app.root='/home/users/chenguang02/openresty/app/'
Appconf.app.root='/home/pay/ovp/app/'

Appconf.controller={}
Appconf.controller.path=Appconf.app.root .. 'application/controllers/'

Appconf.view={}
Appconf.view.path=Appconf.app.root .. Appconf.name .. '/application/views/'
Appconf.view.suffix='.html'
Appconf.view.auto_render=true

return Appconf

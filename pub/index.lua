local config = require('config.application')
local app = require('vanilla.application'):new(config)
app:bootstrap():run()

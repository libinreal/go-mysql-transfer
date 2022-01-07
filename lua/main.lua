--[[
Entrance for go-mysql-transfer
]]
local log_file = "E:\\goworkspace\\my-go-mysql-trans\\store\\log\\my.lua.log"
local mlog = require("util.mlog")
mlog.Writefile(log_file,'main.lua running \r\n','ab+')
local morder_worksheet = require("tms.order_worksheet")
morder_worksheet.Run()
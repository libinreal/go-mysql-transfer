local module = {}

local ops = require("mongodbOps") --加载mongo数据库操作模块
local db = require("dbOps")   --加载数据库操作模块
local json = require("json")   -- 加载json模块
local mstring = require("util.mstr")
local mtable = require("util.mtable")
local mlog = require("util.mlog")
local row = ops.rawRow()
local action = ops.rawAction()

function module.Run()
   local log_file = "E:\\goworkspace\\my-go-mysql-trans\\store\\log\\my.ow.op_uid.log"
   mlog.Writefile(log_file,' '.._VERSION..'\r\n','ab+')
   local result = {}  -- 定义一个table
   local op_uid_split = {} -- op_uid字段: 1008,1098,2505 以','分割后的数组
   local tmp_op_uid = 0
   for k, v in pairs(row) do
      if k == "op_uid" then -- op_uid 转换为数组，方便 in 查询
         op_uid_split = mstring.Split(v, ",")
         mlog.Writefile(log_file,'pre  '..v..'\r\n','ab+')
         -- mlog.Writefile(log_file,'split  '..mtable.TableToStr(op_uid_split)..'\r\n','ab+')
         result['op_uid'] = {} -- op_uid 保存为数组
         for ui,uv in pairs(op_uid_split) do
            uv = mstring.Trim(uv)
            tmp_op_uid = tonumber(uv)
            -- if not tmp_op_uid then
            --    mlog.Writefile(log_file,'ui  '..ui..' uv '..uv..' trim '..mstring.Trim(uv)..' tonumber '..type(tonumber(uv))..'  len '..#uv..'\r\n','ab+')
            -- else
            --    mlog.Writefile(log_file,'ui  '..ui..' uv '..uv..' trim '..mstring.Trim(uv)..' tonumber '..tonumber(uv)..' tmp_op_uid  '..tmp_op_uid..'\r\n','ab+')
            -- end

            if tmp_op_uid then
               table.insert(result['op_uid'], tmp_op_uid)
            end
         end
         -- result['op_uid'] = json.encode(result['op_uid'])
         mlog.Writefile(log_file,'after '..mtable.TableToStr(result['op_uid'])..'\r\n','ab+')
      elseif k ~="ow_id" then -- 列名不为ID
         result[k] = v
      end
   end

   -- os.exit()
   local ow_id = row["ow_id"] --获取ID列的值
   result["_id"] = ow_id -- _id为MongoDB的主键标识
   -- local test
   -- if ow_id < 121000 or ow_id > 121200 then
   --    return
   -- end
   -- if action == "insert" then -- 新增事件
   --    ops.EINSERT("order_worksheet",result) -- 新增，第一个参数为collection名称，string类型；第二个参数为要修改的数据，talbe类型
   -- end
   if action == "insert" then -- 新增事件
       ops.INSERT("order_worksheet",result) -- 新增，第一个参数为collection名称，string类型；第二个参数为要修改的数据，talbe类型
   elseif action == "delete" then -- 删除事件  -- 修改事件
       ops.DELETE("order_worksheet",ow_id) -- 删除，第一个参数为collection名称(string类型)，第二个参数为ID 
   else -- 修改事件
      -- ops.UPDATE("order_worksheet",ow_id,result) -- 修改，第一个参数为collection名称，string类型；第二个参数为ID；第三个参数为要修改的数据，talbe类型
      ops.UPSERT("order_worksheet",ow_id,result) -- 修改或新增，第一个参数为collection名称，string类型；第二个参数为ID；第三个参数为要修改的数据，talbe类型
   end
end

return module
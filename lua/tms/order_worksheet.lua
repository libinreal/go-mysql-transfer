-- 字符串分割为数组
function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
      nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
      break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end

-- 忽略字符串首尾的空白字符
function trim(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end

-- table 转 string 辅助方法
function ToStringEx(value)
   if type(value)=='table' then
      return TableToStr(value)
   elseif type(value)=='string' then
      return "\'"..value.."\'"
   else
      return tostring(value)
   end
end

-- 字符串转数字
string_to_num = function(s) return s + 0 end

-- table 转 string 主方法
function TableToStr(t)
   if t == nil then return "" end
   local retstr= "{"

   local i = 1
   for key,value in pairs(t) do
      local signal = ","
      if i==1 then
       signal = ""
      end

      if key == i then
         retstr = retstr..signal..ToStringEx(value)
      else
         if type(key)=='number' or type(key) == 'string' then
             retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
         else
             if type(key)=='userdata' then
                 retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
             else
                 retstr = retstr..signal..key.."="..ToStringEx(value)
             end
         end
      end

     i = i+1
   end

   retstr = retstr.."}"
   return retstr
end

-- 写入文件
function writefile(path, content, mode)
      mode = mode or "w+b"
      local file = io.open(path, mode)
      if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
      else
        return false
      end
end

local ops = require("mongodbOps") --加载mongo数据库操作模块
local db = require("dbOps")   --加载数据库操作模块
local json = require("json")   -- 加载json模块
local row = ops.rawRow()
local action = ops.rawAction()

local log_file = "store/log/my.ow.op_uid.log"
-- writefile(log_file,' '.._VERSION..'\r\n','ab+')
local result = {}  -- 定义一个table
local op_uid_split = {} -- op_uid字段: 1008,1098,2505 以','分割后的数组
local tmp_op_uid = 0
for k, v in pairs(row) do
   if k == "op_uid" then -- op_uid 转换为数组，方便 in 查询
      op_uid_split = Split(v, ",")
      -- writefile(log_file,'pre  '..v..'\r\n','ab+')
      -- writefile(log_file,'split  '..TableToStr(op_uid_split)..'\r\n','ab+')
      result['op_uid'] = {} -- op_uid 保存为数组
      for ui,uv in pairs(op_uid_split) do
         uv = trim(uv)
         tmp_op_uid = tonumber(uv)
         -- if not tmp_op_uid then
         --    writefile(log_file,'ui  '..ui..' uv '..uv..' trim '..trim(uv)..' tonumber '..type(tonumber(uv))..'  len '..#uv..'\r\n','ab+')
         -- else
         --    writefile(log_file,'ui  '..ui..' uv '..uv..' trim '..trim(uv)..' tonumber '..tonumber(uv)..' tmp_op_uid  '..tmp_op_uid..'\r\n','ab+')
         -- end

         if tmp_op_uid then
            table.insert(result['op_uid'], tmp_op_uid)
         end
      end
      -- result['op_uid'] = json.encode(result['op_uid'])
      writefile(log_file,'after '..TableToStr(result['op_uid'])..'\r\n','ab+')
   elseif k ~="ow_id" then -- 列名不为ID
      result[k] = v
   end
end

-- os.exit()
-- local ow_id = string_to_num(row["ow_id"]) --获取ID列的值
result["_id"] = ow_id -- _id为MongoDB的主键标识

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
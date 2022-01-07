local module = {}
-- 写入文件
function module.writefile(path, content, mode)
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

return module
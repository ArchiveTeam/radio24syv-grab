dofile("table_show.lua")

local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')
local item_dir = os.getenv('item_dir')
local warc_file_base = os.getenv('warc_file_base')

local url_count = 0
local downloaded = {}
local abortgrab = false
local code_counts = {}

for ignore in io.open("ignore-list", "r"):lines() do
  downloaded[ignore] = true
end

local resp_codes_file = io.open(item_dir..'/'..warc_file_base..'_data.txt', 'w')

-----------------------------------------------------------------------------------------------------------------------

wget.callbacks.httploop_result = function(url, err, http_stat)
  status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. "  \n")
  io.stdout:flush()

  if code_counts[status_code] == nil then
    code_counts[status_code] = 1
  else
    code_counts[status_code] = code_counts[status_code] + 1
  end

  -- Expected results
  if (string.match(url["host"], "^storage%.sketch%.sonymobile%.com") and status_code == 307) or 
     (string.match(url["host"], "^storage%.sketch%.sonymobile%.com") and status_code == 404) or
     (string.match(url["host"], "^sketch[-]cloud[-]storage%.s3%.amazonaws%.com") and status_code == 200) then
    resp_codes_file:write(status_code .. " " .. url["url"] .. "\n")
    return wget.actions.NOTHING
  end

  -- Unexpected results
  abortgrab = true
  return wget.actions.ABORT
end

-----------------------------------------------------------------------------------------------------------------------

wget.callbacks.before_exit = function(exit_status, exit_status_string)
  resp_codes_file:close()
  io.stdout:write(table.show(code_counts,'\nResponse Code Frequency'))
  io.stdout:flush()
  if abortgrab == true then
    return wget.exits.IO_FAIL
  end
  return exit_status
end

-----------------------------------------------------------------------------------------------------------------------

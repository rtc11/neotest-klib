local lib = require("neotest.lib")
local async = require("neotest.async")
local output = require("neotest-klib.output")

local M = {}

local function test_args(pos)
    local args = {}
    if pos.type == 'test' then
        local ns = pos.id:gsub(pos.name, '')
        local class = pos.path:match("([^/]+)%.kt$")
        vim.list_extend(args, { '--class', ns .. class , "--test", '"' .. pos.name .. '"' })
    elseif pos.type == 'file' then
        vim.list_extend(args, { '--path', pos.path })
    elseif pos.type == 'dir' then
        vim.list_extend(args, { '--path', pos.path })
    end
    return args
end

function M.build(args)
    local pos = args.tree:data()
    local dir = pos.path
    local test = { vim.fn.getcwd() .. '/test.sh' }
    local res_path = async.fn.tempname() .. ".json"
    lib.files.write(res_path, "")

    vim.list_extend(test, test_args(pos))
    local cmd = table.concat(test, ' ') .. ' | tee -a ' .. res_path
    local stream_data, stop_stream = lib.files.stream_lines(res_path)

    print("command: " .. cmd)

    local all_res = {}

    return {
        command = cmd,
        context = {
            all_res = all_res,
            res_path = res_path,
            stop_stream = stop_stream,
        },
        stream = function()
            return function()
                local new_res = stream_data()
                local ok, parsed = pcall(output.parse, new_res, dir, pos.id)
                if not ok then
                    print("error parsing output: " .. parsed)
                    return nil
                else
                    for k, v in pairs(parsed) do all_res[k] = v end
                    return parsed
                end
            end
        end
    }
end

return M


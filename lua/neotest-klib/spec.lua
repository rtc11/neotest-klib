local lib = require("neotest.lib")
local async = require("neotest.async")
local output = require("neotest-klib.output")

local M = {}

-- find everything after the last / and before the .kt
local regex_classname = "([^/]+)%.kt$"

-- find everything after /test/ and before the last / 
local regex_namespace = "/test/([^/]+)/"

-- find everything after /test
local regex_resource = "/test/"

-- find everything after /test/ and before the .kt
local regex_package = "/test/[^/]+/([^/]+)%.kt$"

local function namespace(pos)
    if not pos.path:match(regex_namespace) then
        return ""
    else
        return pos.id:gsub(pos.name, ''):gsub(' ', '')
    end
end

local function test_args(pos)
    -- print("test", vim.inspect(pos))
    local args = {}

    if pos.type == 'test' then
        local ns = namespace(pos)
        local class = pos.path:match(regex_classname)
        local test = '"' .. pos.name .. '"'
        vim.list_extend(args, { '-c', ns .. class , "-t", test })

    elseif pos.type == 'class' then

        if not pos.path:match(regex_namespace) then
            local class = pos.path:match(regex_classname)
            vim.list_extend(args, { '-c', class })
        else
            vim.list_extend(args, { '-c', pos.id })
        end

    elseif pos.type == 'file' then

        vim.list_extend(args, { '-f', pos.path })

    elseif pos.type == 'dir' then

        vim.list_extend(args, { '-p', pos.name })

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


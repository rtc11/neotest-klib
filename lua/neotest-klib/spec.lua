local lib = require("neotest.lib")
local async = require("neotest.async")
local output = require("neotest-klib.output")

local M = {}

local function namespaces(tree)
    print("spec.namespaces", vim.inspect(tree))
    local nss = {}
    for _, pos in tree:iter() do
        table.insert(nss, pos)
    end

    return nss
end

local function test_args(tree, pos)
    print("spec.test_args", vim.inspect(tree), vim.inspect(pos))
    local args = {}
    if pos.type == 'test' or pos.type == 'namespace' then
        vim.list_extend(args, { '-t', '"' .. pos.id .. '"' })
    elseif pos.type == 'file' then
        for _, ns in pairs(namespaces(tree)) do
            vim.list_extend(args, { '-c', '"' .. ns.id .. '"' })
        end
    end
    return args
end

function M.build(args)
    print("spec.build", vim.inspect(args))
    local pos = args.tree:data()
    local dir = pos.path --lib.files.match_root_pattern("Makefile", pos.path)
    print("cwd:", vim.inspect(vim.fn.getcwd()))

    local test = { vim.fn.getcwd() .. '/test.sh' }
    local res_path = async.fn.tempname() .. ".json"
    lib.files.write(res_path, "")

    vim.list_extend(test, test_args(args.tree, pos))
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
                local ok, parsed = pcall(output.parse, new_res, dir)
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


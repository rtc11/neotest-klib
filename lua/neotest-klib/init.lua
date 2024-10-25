local lib = require("neotest.lib")
local output = require("neotest-klib.output")
local spec = require("neotest-klib.spec")
local pos = require("neotest-klib.pos")

local adapter = { name = "neotest-klib" }

---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function adapter.root(dir)
    print("init.root", vim.inspect(dir))
    local root = lib.files.match_root_pattern("Makefile", dir)
    print("init.root returns", root, vim.inspect(root))
    return root
end

---@async
---@param name string Name of directory
---@return boolean
function adapter.filter_dir(name, _, _)
    local deny = { '.libs', '.build', 'src', '.res', '.git' }
    for _, dir in ipairs(deny) do
        if dir == name then
            print("denied dir:", name)
            return false
        end
        print("allowed dir:", name)
        return true
    end
end

---@async
---@param file_path string
---@return boolean
function adapter.is_test_file(file_path)
    print("init.is_test_file", vim.inspect(file_path))
    local is_test_file = file_path:match("Test.kt$")
    return is_test_file
end

---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function adapter.discover_positions(file_path)
    print("init.discover_positions", vim.inspect(file_path))
    local pos_query = pos.query
    return lib.treesitter.parse_positions(file_path, pos_query, {
        require_namespaces = false,
        nested_tests = false,
        build_position = "require('neotest-klib.pos').build_pos",
        position_id = "require('neotest-klib.pos').build_pos_id"
    })
end

---@async
---@param _args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function adapter.build_spec(_args)
    print("init.build_spec", vim.inspect(_args))
    return spec.build(_args)
end

---@async
---@param _spec neotest.RunSpec
---@param _result neotest.StrategyResult
---@param _tree neotest.Tree
---@return table<string, neotest.Result>
function adapter.results(_spec, _res, _tree)
    print("init.results", vim.inspect(_spec), vim.inspect(_res), vim.inspect(_tree))
    return output.result(_spec, _res, _tree)
end

return adapter

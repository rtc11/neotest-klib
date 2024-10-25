local lib = require("neotest.lib")
local output = require("neotest-klib.output")
local spec = require("neotest-klib.spec")
local pos = require("neotest-klib.pos")

local adapter = { name = "neotest-klib" }

---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function adapter.root(dir)
    return  dir .. "/test"
end

---@async
---@param name string Name of directory
---@return boolean
function adapter.filter_dir(name, _, _)
    local deny = { '.libs', '.build', 'src', '.res', '.git' }
    for _, dir in ipairs(deny) do
        if dir == name then
            return false
        end
        return true
    end
end

---@async
---@param file_path string
---@return boolean
function adapter.is_test_file(file_path)
    return file_path:match("Test.kt$")
end

---@async
---@param file_path string Absolute file path
function adapter.discover_positions(file_path)
    -- local pos_query = pos.test_classes .. pos.test_functions
    local pos_query = pos.test_classes .. pos.test_functions
    local opt = {
        require_namespaces = false,
        nested_tests = true,
        build_position = pos.build_pos,
        position_id = pos.build_pos_id
    }
    return lib.treesitter.parse_positions(file_path, pos_query, opt)
end

---@async
function adapter.build_spec(_args)
    return spec.build(_args)
end

---@async
function adapter.results(_spec, _res, _tree)
    return output.result(_spec, _res, _tree)
end

return adapter

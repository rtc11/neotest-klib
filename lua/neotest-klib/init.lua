local lib = require("neotest.lib")
local logger = require("neotest.logger")
local async = require("neotest.async")
local output = require("neotest-klib.output")
local spec = require("neotest-klib.spec")
local pos = require("neotest-klib.pos")

local adapter = { name = "neotest-klib" }

---@async
function adapter.root(dir)
  return lib.files.match_root_pattern("Makefile", dir)
end

---@async
function adapter.filter_dir(name, _, _)
    local deny = { '.libs', 'src', 'test', '.res', '.git' }
    for _, dir in ipairs(deny) do
        if dir == name then
            return false
        end
        return true
    end
end

---@async
function adapter.is_test_file(file_path)
    -- filter names containing $ 
    return vim.endswith(file_path, "Test.class")
end

---@async
function adapter.discover_positions(file_path)
    local query = pos.package .. pos.test
    return lib.treesitter.parse_positions(file_path, query, {
        require_namespaces = false,
        nested_tests = false,
        position_id = "require('neotest-klib.pos').position_id"
    })
end

---@async
function adapter.build_spec(args)
    return spec.build(args)
end

---@async
function adapter.results(spec, result, tree)
    return output.result(spec, result, tree)
end

return adapter


local lib = require("neotest.lib")
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
    return file_path:match("Test.kt$")
end

---@async
function adapter.discover_positions(file_path)
    local pos_query = pos.query
    return lib.treesitter.parse_positions(file_path, pos_query, {
        require_namespaces = false,
        nested_tests = false,
        build_position = "require('neotest-klib.pos').build_pos",
        position_id = "require('neotest-klib.pos').build_pos_id"
    })
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


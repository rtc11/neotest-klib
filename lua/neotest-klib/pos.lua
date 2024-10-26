local lib = require("neotest.lib")
local M = {}

local function get_pkg_name(path)
    local first_line = lib.files.read_lines(path)[1]
    return first_line:gsub('^package ', '')
end

local function get_class(namespaces)
    local names = vim.tbl_map(function(namespace)
        return namespace.handle_name
    end, namespaces)

    local full_ns = table.concat(names, '.')
    return #full_ns > 0 and full_ns or ''
end

local function get_pos_name(name)
    return name:gsub('`', '')
end

local function get_captured_node_type(captured_nodes)
    if captured_nodes['test.name'] then
        return 'test'
    end
    if captured_nodes['namespace.name'] then
        return 'namespace'
    end
    if captured_nodes['class.name'] then
        return 'class'
    end
end

--- Build a position ID from a position and its parents
function M.build_pos_id(position, parents)
    local pkg_name = get_pkg_name(position.path)
    local class_name = get_class(parents)
    local pos_name = get_pos_name(position.handle_name)
    return pkg_name  .. '.' .. class_name .. pos_name
end

--- Build a position from a file path and a set of captured nodes
function M.build_pos(file_path, source, captured_nodes)
    local node_type = get_captured_node_type(captured_nodes)
    local handle_name = vim.treesitter.get_node_text(captured_nodes[node_type .. '.name'], source)
    local definition = captured_nodes[node_type .. '.definition']
    local name = handle_name:gsub('`', '')
    return {
        type = node_type,
        path = file_path,
        name = name,
        handle_name = handle_name,
        range = { definition:range() },
    }
end

M.test_functions = [[
    ; query for test function
    (
        (function_declaration
            (modifiers (annotation (user_type (type_identifier) @test_marker.identifier)))
            (simple_identifier) @test.name
        )
        (#eq? @test_marker.identifier "Test")
    ) @test.definition
]]

M.namespace = [[
    ; query for package
    (
        (package_header (identifier) @namespace.name)
    ) @namespace.definition
]]

M.class = [[
    ; query for test classes
    (
        (class_declaration (type_identifier) @class.name)
    ) @class.definition
]]

return M

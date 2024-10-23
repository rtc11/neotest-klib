local M = {}

function M.position_id(position, parents)
    local original_id = table.concat(
        vim.tbl_flatten({
            position.path,
            vim.tbl_map(function(pos)
                return pos.name
            end, parents),
            position.name,
        }),
        "::"
    )
    return original
end

return M

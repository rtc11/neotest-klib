local M = {}

function M.result(spec, _, _)
    spec.context.stop_stream()
    return spec.context.all_res
end

local function status(line)
    if string.find(line, "PASS") then
        return "passed"
    elseif string.find(line, "FAIL") then
        return "failed"
    else
        return "skipped"
    end
end

local function short(line)
    return line:gsub("PASS", ""):gsub("FAIL", "")
end

local function parse_line(line, path)
    if not string.find(line, ".*(ms).*") then
        return {}
    end

    return {
        id = path,
        status = status(line),
        short = short(line),
    }
end

function M.parse(lines, path, pos_id)
    local results = {}
    for _, line in ipairs(lines) do
        local res = parse_line(line, path)
        if not res.id then
            -- noop
        else
            results[pos_id] = res
        end
    end
    return results
end

return M

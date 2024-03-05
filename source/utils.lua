local chalk = require("source.chalk")
--local dataParser = require("source.data_parser")
local utils = {}

--- Function to check if a file exists.
function utils.fileExists(fileName)
    local file = io.open(fileName, "r")

    if file then
        file:close()
        return true
    else
        return false
    end
end

--- Function to determine compiler flags based on file types.
-- @param sourceFiles List of source files.
-- @return Compiler flags based on file types.
function utils.getFileTypeFlags(sourceFiles)
    -- Iterate through source files to determine file types
    for _, file in ipairs(sourceFiles) do
        local extension = file:match("%.([^%.]+)$")
        -- Return appropriate compiler based on file extension
        if extension == "c" then
            return "gcc"
        elseif extension == "cpp" or extension == "cc" or extension == "cxx" or extension == "c++" or extension == "cp" then
            return "g++"
        end
    end
    return "" -- Default to an empty string if no specific flags are needed
end

--- Detect system compiler or return g++.
-- @param params Architect parameters.
-- @return Compiler to be used.
function utils.detectSystemCompiler(params)
    local cc = os.getenv("CC") -- Check the CC environment variable
    if cc then
        return cc
    end

    -- Return compiler determined by file types if CC is not set
    if params and params.sourceFiles then
        return utils.getFileTypeFlags(params.sourceFiles)
    else
        return ""
    end
end

--- Function to get library flags using pkg-config.
-- @param libs List of libraries.
-- @return Library flags using pkg-config.
function utils.getPkgConfigLibs(libs)
    if not libs or #libs == 0 then
        return ""
    end

    local pkgConfigCommand = "pkg-config --cflags --libs " .. table.concat(libs, " ")
    local handle = io.popen(pkgConfigCommand)

    if not handle then
        return "" -- Return empty string on error
    end

    local pkgConfigOutput, pkgConfigError = handle:read("*a")
    handle:close()

    if pkgConfigOutput then
        return pkgConfigOutput:sub(1, -2) -- Remove the trailing newline
    else
        print(chalk.red.bold("Error: ") .. (pkgConfigError or "Unknown error occurred... Exiting!"))
        return "" -- Return empty string if there's an error
    end
end

return utils

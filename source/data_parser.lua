local chalk = require("source.chalk")
local toml = require("source.toml")
local lfs = require("source.lfs_ffi")

local dataParser = {}

-- Read the Configuration TOML file.
function dataParser.readConfigurationFile()
    local file = io.open("Blueprint.toml", "r")
    if not file then
        print(chalk.red.bold("ERROR:") ..
        chalk.bold(
        " Configuration file not found. To initialise a new Blueprint project, please use the command 'blueprint --init' in the project directory."))
        os.exit(1)
    end

    local tomlContent = file:read("*all")
    file:close()

    return tomlContent
end

-- Parse the Configuration TOML Data
function dataParser.parseConfigurationData(configFile)
    local parsedData, err = toml.parse(configFile)
    if not parsedData then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to parse configuration data: ") .. chalk.bold(err))
        print(chalk.bold("Make sure your configuration file is properly formatted and contains valid TOML syntax."))
        os.exit(1)
    end
    return parsedData
end

function dataParser.getProjectName(parsedConfigurationData)
    local extractedName = ""

    if parsedConfigurationData.package and parsedConfigurationData.package.name then
        extractedName = parsedConfigurationData.package.name
    end

    return extractedName
end

-- Get the configurations data
function dataParser.getDependencyData(parsedConfigurationData)
    local data = {}
    if parsedConfigurationData.dependencies then
        for name, dependencyData in pairs(parsedConfigurationData.dependencies) do
            if type(dependencyData) == "table" and dependencyData.git and dependencyData.rev then -- Check if the data returned from TOML is a table. Equivalant to inline table in TOML
                table.insert(data, {
                    name = name,
                    gitURL = dependencyData.git,
                    rev = dependencyData.rev
                })
            else
                print(chalk.red.bold("ERROR: ") ..
                    chalk.bold("Invalid or incomplete data for dependency '" ..
                        name .. "'. Please make sure it contains 'git' and 'rev' fields."))
            end
        end
    end

    return data
end

return dataParser

local chalk = require("source.chalk")
local lfs = require("source.lfs_ffi")
local dataParser = require("source.data_parser")
local dependency = require("source.dependency")

local blueprint = {}

local compiler = os.getenv("CC") or "g++"
local buildLocation = "target"
local srcDir = "src"


local function directoryExistsError(projectName)
    print(chalk.red.bold("ERROR: ") .. chalk.bold("Destination " .. lfs.currentdir() .. "/" .. projectName .. " already exists!"))
    print(chalk.red.yellow("HINT: ") .. chalk.bold("Use 'blueprint init' to initialise the directory"))
end

local function generateProjectTOML(projectName)
    -- Generate projects TOML file
    -- Retrieve user name and email from Git configuration
    local gitUsername = io.popen("git config --get user.name"):read("*l") or "Unknown User"
    local gitUseremail = io.popen("git config --get user.email"):read("*l") or "Unknown Email"

    -- Check if user name and email are retrieved successfully
    if not gitUsername or not gitUseremail then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to retrieve Git user name or email."))
        return
    end
    -- Create a table for the TOML content
    local projectContent = string.format([[
[package]
name = "%s"
version = "0.1"
authors = ["%s <%s>"]
cpp_version = "20"

[dependencies]
]], projectName, gitUsername, gitUseremail)

    -- Write the TOML content to blueprint.toml file
    local file = io.open("Blueprint.toml", "w")
    if not file then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to create blueprint.toml file."))
        os.exit(1)
    else
        -- Write the content to the file
        file:write(projectContent)
        file:close()
        local formattedMessage = chalk.green.bold("Created ") .. chalk.bold("binary (application) ") .. chalk.bold("'%s' package")
        print(string.format(formattedMessage, projectName))
    end
end

local function generateEntryFiles(projectName, arg)
    -- Create src folder & populate with main.cc file

    if arg ~= "init" then
        if not lfs.mkdir(projectName) then
            print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to create directory " .. projectName))
            os.exit(1)
        end

        if not lfs.chdir(projectName) then
            print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to enter the directory " .. projectName))
            os.exit(1)
        end
    end

    if not lfs.mkdir(srcDir) then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to generate source folder"))
        os.exit(1)
    end

    -- Creates or overwrite the 'main.cc' file
    local file = io.open(srcDir .. "/main.cc", "w")
    if not file then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to generate main.cc"))
        os.exit(1)
    end

    -- Write the code to the file
    file:write("#include <iostream>\n\n")
    file:write("int main() {\n")
    file:write("  std::cout << \"Hello, world!\" << std::endl;\n")
    file:write("}\n")

    -- Close the file
    file:close()
end

local function formatTime(timeInSeconds)
    if timeInSeconds < 1e-3 then
        return string.format("%.2f microseconds", timeInSeconds * 1e6)
    elseif timeInSeconds < 1 then
        return string.format("%.2f miliseconds", timeInSeconds * 1e3)
    else
        return string.format("%.2f seconds", timeInSeconds)
    end
end

local function executeAndMeasureTime(command)
    local startTime = os.clock()

    os.execute(command)

    local endTime = os.clock()
    local elapsedTime = endTime - startTime

    return elapsedTime
end

-- Check if a file exists
local function fileExists(filePath)
    return lfs.attributes(filePath, "mode") ~= nil
end

-- Get the modification time of a file
local function getFileModificationTime(filePath)
    local attributes = lfs.attributes(filePath)
    if attributes then
        return attributes.modification
    else
        return nil
    end
end

-- Check if the source file is newer than the executable
local function needsRebuild(sourceFile, executable)
    local sourceModTime = getFileModificationTime(sourceFile)
    local execModTime = getFileModificationTime(executable)
    return not execModTime or (sourceModTime and sourceModTime > execModTime)
end

-- Return project name from blueprint.toml
local function getProjectName()
    local configurationFile = dataParser.readConfigurationFile()
    local parsedConfigurationFile = dataParser.parseConfigurationData(configurationFile)    
    local extractedData = dataParser.getProjectName(parsedConfigurationFile)

    return extractedData
end

-- Compile a source file into an object file
local function compileSourceFile(sourceFile, objectFile, optimizationFlags, debugFlags)
    print(chalk.green.bold("Compiling ") .. chalk.bold(sourceFile))
    local command = compiler .. " -c " .. sourceFile .. " -o " .. objectFile .. " " .. optimizationFlags .. " " .. debugFlags
    os.execute(command)
end

-- Link object files into an executable
local function linkObjectFiles(objectFiles, outputFile, optimizationFlags, debugFlags, arg)
    print(chalk.green.bold("Linking ") .. chalk.bold(getProjectName()))
    local objectFilesStr = table.concat(objectFiles, " ")
    local command = compiler .. " " .. objectFilesStr .. " -o " .. outputFile .. " " .. optimizationFlags .. " " .. debugFlags
    local buildAndTime = executeAndMeasureTime(command)

    local argModified = (arg and string.sub(arg, 3)) or "debug"
    print(chalk.green.bold("Finished ") .. chalk.bold(argModified .. " target(s) in " .. formatTime(buildAndTime)))
end

-- Build based on the provided argument
local function buildBasedOnOption(arg)
    local optimizationFlags = ""
    local debugFlags = ""
    local buildType = "debug"  -- Default build type

    if arg == "--release" or "-r" then
        optimizationFlags = "-O3 -DNDEBUG"
        buildType = "release"
    end

    if arg == nil then
        debugFlags = "-g3 -Wall -Wextra"
        buildType = "debug"
    end

    local sourceFile = "src/main.cc"
    local buildDir = buildLocation .. "/" .. buildType  -- Set build directory based on build type
    local objectFile = buildDir .. "/" .. getProjectName() .. ".o"
    local outputFile = buildDir .. "/" .. getProjectName()

    if not fileExists("src/main.cc") then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("main entry file 'main.cc' is missing. Failed to build"))
        os.exit(1)
    end

    if needsRebuild(sourceFile, outputFile) then
        -- Create build directory if it doesn't exist
        lfs.mkdir(buildDir)

        compileSourceFile(sourceFile, objectFile, optimizationFlags, debugFlags)
        linkObjectFiles({objectFile}, outputFile, optimizationFlags, debugFlags, arg)

        -- Move executable and object file to the build directory
        os.rename(outputFile, buildDir .. "/" .. getProjectName())
        os.rename(objectFile, buildDir .. "/" .. getProjectName() .. ".o")
    else
        print(chalk.green.bold("Finished ") .. chalk.bold(buildType .. " target(s) in 0.00s"))
    end
end

function blueprint.updateDependency()
    local configurationFile = dataParser.readConfigurationFile()
    local parsedConfigurationFile = dataParser.parseConfigurationData(configurationFile)
    dependency.update(dataParser.getDependencyData(parsedConfigurationFile))
end

function blueprint.cloneDependency()
    local configurationFile = dataParser.readConfigurationFile()
    local parsedConfigurationFile = dataParser.parseConfigurationData(configurationFile)
    dependency.clone(dataParser.getDependencyData(parsedConfigurationFile))
end

function blueprint.updateSingle(dependencyName)
    local configurationFile = dataParser.readConfigurationFile()
    local parsedConfigurationFile = dataParser.parseConfigurationData(configurationFile)
    dependency.updateSingle(dataParser.getDependencyData(parsedConfigurationFile), dependencyName)
end

-- Generate a new project based on passed project name argument
function blueprint.newProject(projectName, arg)
    if lfs.attributes(projectName, "mode") then
        directoryExistsError(projectName)
    else
        generateEntryFiles(projectName, arg)
        generateProjectTOML(projectName)
    end
end

-- Initialise a project based on the current working directory folder name
function blueprint.init(arg)
    local folderName = lfs.currentdir():match("[^/]+$")

    -- We cant generate a project if an existing Blueprint project already exists in the current working directory
    if fileExists("Blueprint.toml") then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("'blueprint init' cannot be run on an existing Blueprint package"))
    else
        generateEntryFiles(folderName, arg)
        generateProjectTOML(folderName)
    end
end

-- Build the project
function blueprint.build(arg)
    if not fileExists("Blueprint.toml") then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Could not find 'Blueprint.toml' in ") .. chalk.bold(lfs.currentdir()))
    else
        lfs.mkdir(buildLocation)
        blueprint.cloneDependency()
        buildBasedOnOption(arg)
    end
end

-- Run the project
function blueprint.run()
    if not fileExists("Blueprint.toml") then
        print(chalk.red.bold("ERROR: ") .. chalk.bold("Could not find 'Blueprint.toml' in ") .. chalk.bold(lfs.currentdir()))
    else
        blueprint.cloneDependency()

        print(chalk.green.bold("Compiling " ) .. chalk.bold(buildLocation .. "/main.cc"))
        print(chalk.green.bold("Running ") .. chalk.bold(getProjectName()))
        local buildAndTime = executeAndMeasureTime(compiler .. " " .. srcDir .."/main.cc" .. " -o " .. getProjectName() .. " -g3 -Wall -Wextra" .. "&& ./" ..  getProjectName())
        os.remove(getProjectName())
        print(chalk.green.bold("Finished ") .. chalk.bold("debug target(s) in " .. formatTime(buildAndTime)))
    end
end

return blueprint

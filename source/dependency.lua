local chalk = require("source.chalk")
local lfs = require("source.lfs_ffi")

local dependency = {}

-- Extract cloned folder name
local function extractDirName(uri)
    local lastSlashIndex = uri:find("/[^/]*$")
    local name = uri:sub(lastSlashIndex + 1)

    return name
end

-- Clone dependencies found in config.toml and move them to the libs folder
function dependency.clone(extractedDependencyData)
    if not lfs.attributes("deps", "mode") then
        lfs.mkdir("deps")
    end

    for _, extractedData in pairs(extractedDependencyData) do
        local repoPath = "deps/" .. extractDirName(extractedData.name)
        if not lfs.attributes(repoPath, "mode") then
            local cloneCommand = "cd deps && git clone " .. extractedData.gitURL .. " > /dev/null 2>&1"
            local closeResult = os.execute(cloneCommand)
            if closeResult ~= 0 then
                print(chalk.red.bold("ERROR: ") .. chalk.bold("Failed to clone repository '" .. extractedData.name .. "'"))
                return
            else
                print(chalk.green.bold("Downloaded ") .. chalk.bold("Repository '" .. extractedData.name .. "'"))
            end
        end
    end
end

-- Print out dependency update status when changing revision
function dependency.printDependencyUpdateStatus(dependencyName, isUpdated)
    if isUpdated then
        print(chalk.green.bold("Updated ") .. chalk.bold("Repository '" .. dependencyName .. "'"))
    else
        print(chalk.green.bold("Skipping ") .. chalk.bold("No changes found in repository '" .. dependencyName .. "'"))
    end
end

-- Update existing dependencies found in Blueprint.toml
function dependency.update(extractedDependencyData)
    for _, extractedData in pairs(extractedDependencyData) do
        local repoPath = "deps/" .. extractDirName(extractedData.name)
        if lfs.attributes(repoPath, "mode") then
            local currentRev = io.popen("cd " .. repoPath .. " && git rev-parse HEAD"):read("*a")
            currentRev = string.gsub(currentRev, "%s+", "") -- remove whitespace
            if currentRev ~= extractedData.rev then
                local checkoutCommand = "cd " .. repoPath .. " && git checkout " .. extractedData.rev .. " > /dev/null 2>&1"
                os.execute(checkoutCommand)
                local updatedRev = io.popen("cd " .. repoPath .. " && git rev-parse HEAD"):read("*a")
                updatedRev = string.gsub(updatedRev, "%s+", "") -- remove whitespace
                local isUpdated = updatedRev == extractedData.rev
                dependency.printDependencyUpdateStatus(extractedData.name, isUpdated)
            else
                print(chalk.green.bold("Skipping ") .. chalk.bold("No changes found in repository '" .. extractedData.name .. "'"))
            end
        else
            print(chalk.red.bold("ERROR: ") .. chalk.bold("Repository '" .. extractedData.name .. "' does not exist."))
        end
    end
end

-- Update a single dependency by its name
function dependency.updateSingle(extractedDependencyData, dependencyName)
    for _, data in pairs(extractedDependencyData) do
        if extractDirName(data.name) == dependencyName then
            local depName = "deps/" .. extractDirName(data.name)
            if lfs.attributes(depName, "mode") then
                local currentRev = io.popen("cd " .. depName .. " && git rev-parse HEAD"):read("*a")
                currentRev = string.gsub(currentRev, "%s+", "") -- remove whitespace
                if currentRev ~= data.rev then
                    local checkoutCommand = "cd " .. depName .. " && git checkout " .. data.rev .. " > /dev/null 2>&1"
                    os.execute(checkoutCommand)
                    local updatedRev = io.popen("cd " .. depName .. " && git rev-parse HEAD"):read("*a")
                    updatedRev = string.gsub(updatedRev, "%s+", "") -- remove whitespace
                    local isUpdated = updatedRev == data.rev
                    dependency.printDependencyUpdateStatus(dependencyName, isUpdated)
                else
                    print(chalk.green.bold("Skipping ") .. chalk.bold("No changes found in repository '" .. dependencyName .. "'"))
                end
            else
                print(chalk.red.bold("ERROR: ") .. chalk.bold("Repository '" .. dependencyName .. "' does not exist."))
            end
            return  -- No need to continue looping once the specific dependency is found
        end
    end
    print(chalk.red.bold("ERROR: ") .. chalk.bold("Dependency '" .. dependencyName .. "' not found in Blueprint.toml"))
end



return dependency

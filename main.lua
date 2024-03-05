local blueprint = require("source.blueprint")
local lummander = require("source.lummander.lummander")

local cli = lummander.new{
  title = "Blueprint",
  tag = "blueprint",
  description = "A simple toy build & package manager for C++",
  version = "0.0.5",
  author = "Ishimachi",
  flag_prevent_help = false
}

cli:command("new <ProjectName>", "Create a new Blueprint project")
  :action(function(parsed)
    blueprint.newProject(parsed.ProjectName, "new")
end)

cli:command("init", "Create a new blueprint package in an existing directory")
  :action(function()
    blueprint.init("init")
end)

cli:command("build", "Compile the current package")
  :option("release", "r", "Compile the package using release mode", nil)
  :action(function(parsed)
    blueprint.build(parsed[2])
end)

cli:command("run", "Compile and run the project")
  :action(function()
    blueprint.run()
end)

cli:command("update", "Update project dependencies")
  :action(function(parsed)
    blueprint.cloneDependency()
    if parsed[2] ~= nil then
      blueprint.updateSingle(parsed[2])
    else
      blueprint.updateDependency()
    end
end)

cli:parse(arg)

require 'xcodeproj'

project_path = 'WSHackathonApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add file reference
file_ref = project.main_group.new_reference('.env')

# Add to resources build phase
resources_phase = target.resources_build_phase
resources_phase.add_file_reference(file_ref)

project.save
puts "Added .env to Xcode project and resources phase."

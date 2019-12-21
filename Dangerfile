# File for the Danger bot: https://danger.systems/ruby/
# Used to inspect pull requests for us to prevent issues. 

ReleaseFile = Struct.new(:relative_file_path, :warn_or_fail, :deployment_instruction)

files_to_update_for_releases = [ # we will also check the version changed in Info.plist. Don't include here. 
  # Edit your Info.plist 
  ReleaseFile.new('CHANGELOG.md', 'warn', "Add a new changelog entry detailing for future developers what has been done in the app."),  
  ReleaseFile.new('Wendy.podspec', 'warn', "Update the version in the podspec file.")
]

deployment_instructions = []
deployment_instructions += files_to_update_for_releases.map { |release_file| "#{release_file.relative_file_path}: #{release_file.deployment_instruction}" }

def determineIfRelease(files_to_update_for_releases)
  num_files_updated = 0

  files_to_update_for_releases.each { |release_file_array|
    release_file_relative_path = release_file_array[0]
    release_file_warn_or_fail = release_file_array[1]

    if git.diff_for_file(release_file_relative_path) 
      if num_files_updated == 0        
        message "🚀 I am going to assume that this *is a release* pull request because you have edited a file that would be updated for releases. 🚀"
      end 
      message "Release file edited: #{release_file_relative_path}"

      num_files_updated += 1
    else
      if num_files_updated > 0 # We only want to actually warn or fail if you forgot a file. If this PR is not a release, don't bother. 
        fail_message = "You did not update #{release_file_relative_path}, but you updated at least one file"
        if release_file_warn_or_fail == 'warn'
          warn fail_message
        else 
          fail fail_message
        end 
      end 
    end 
  }
end 

if ENV["CI"] 
  swiftformat.binary_path = "Example/Pods/SwiftFormat/CommandLineTool/swiftformat"
  swiftformat.check_format(fail_on_error: true)

  swiftlint.binary_path = 'Example/Pods/SwiftLint/swiftlint'
  swiftlint.config_file = 'Example/.swiftlint.yml'    
  swiftlint.max_num_violations = 0  
  swiftlint.lint_files fail_on_error: true    

  junit.parse "reports/report.junit"
  junit.report

  if github.branch_for_base == "master"
    if git.modified_files.include? "Wendy.podspec" or git.modified_files.include? "Example/Podfile"
      warn "I see you edited a pod file. Keep in mind that unless you are simply upgrading version numbers of libraries, that is ok. If you are adding dependencies, you may get your PR denied to keep the library slim."
    end

    determineIfRelease(files_to_update_for_releases)          
  end  
else 
  puts "It looks like you are looking for instructions on how to deploy your app, huh? Well, edit these files with these instructions: \n\n"
  puts deployment_instructions  
end 

if github.branch_for_base == "master"
#  if !git.modified_files.include? "docs/*"
#    warn 'Did you remember to generate documentation?
#  end
  if !git.modified_files.include? "CHANGELOG.md"
    fail 'You need to edit the CHANGELOG.md file.'
  end
  warn 'Did you remember to update the Podspec version code?'
end

if git.modified_files.include? "Wendy.podspec" or git.modified_files.include? "Example/Podfile"
   warn "I see you edited a pod file. Keep in mind that unless you are simply upgrading version numbers of libraries, that is ok. If you are adding dependencies, you may get your PR denied to keep the library slim."
end

swiftLintOutput = `./Example/Pods/SwiftLint/swiftlint --config Example/.swiftlint.yml`
markdown "Output of SwiftLint: \n ```#{swiftLintOutput}``` \n\nPR will not be merged until there are no warnings."

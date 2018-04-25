if github.branch_for_base != "development" && github.pr_author != "levibostian"
  fail "Sorry, wrong branch. Create a PR into the `development` branch instead."
end

if github.branch_for_base == "master" && github.branch_for_head != "development"
  fail "You must merge from the `development` branch into `master`."
end

if github.branch_for_base == "master"
#  if !git.modified_files.include? "docs/*"
#    warn 'Did you remember to generate documentation?
#  end
  if !git.modified_files.include? "CHANGELOG.md"
    fail 'You need to edit the CHANGELOG.md file.'
  end
  if !git.modified_files.include? "Wendy.podspec"
    fail 'You need to update the Podspec version code for a new release.'
  else
    warn 'Did you remember to update the Podspec version code for a new release?'
  end
end

if github.branch_for_base != "master"
  if git.modified_files.include? "Wendy.podspec" or git.modified_files.include? "Example/Podfile"
    warn "I see you edited a pod file. Keep in mind that unless you are simply upgrading version numbers of libraries, that is ok. If you are adding dependencies, you may get your PR denied to keep the library slim."
  end
end

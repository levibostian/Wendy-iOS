// The SDK is deployed to multiple dependency management softwares (Cocoapods and Swift Package Manager). 
// This code tries to prevent forgetting to update metadata files for one but not the other. 
let isSPMFilesModified = danger.git.modified_files.includes('Package.swift') 
let isCococapodsFilesModified = danger.git.modified_files.filter((filePath) => filePath.endsWith('.podspec')).length > 0

console.log(`SPM files modified: ${isSPMFilesModified}, CocoaPods: ${isCococapodsFilesModified}`)

if (isSPMFilesModified || isCococapodsFilesModified) {
  if (!isSPMFilesModified) { warn("Cocoapods files (*.podspec) were modified but Swift Package Manager files (Package.*) files were not. This is error-prone when updating dependencies in one service but not the other. Double-check that you updated all of the correct files.") }
  if (!isCococapodsFilesModified) { warn("Swift Package Manager files (Package.*) were modified but Cocoapods files (*.podspec) files were not. This is error-prone when updating dependencies in one service but not the other. Double-check that you updated all of the correct files.") }
}
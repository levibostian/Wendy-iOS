build:
	pod lib lint --allow-warnings
	xcrun xcodebuild -skipMacroValidation -skipPackagePluginValidation build -scheme Wendy -destination generic/platform=ios | xcbeautify
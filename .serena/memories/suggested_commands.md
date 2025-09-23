# Suggested Development Commands

## Build and Run
```bash
# Open project in Xcode
open "Micro Diary.xcodeproj"

# Build from command line
xcodebuild -project "Micro Diary.xcodeproj" -scheme "Micro Diary" -destination "platform=iOS Simulator,name=iPhone 15" build

# Run tests
xcodebuild test -project "Micro Diary.xcodeproj" -scheme "Micro Diary" -destination "platform=iOS Simulator,name=iPhone 15"
```

## Project Management
```bash
# Check project structure
ls -la "Micro Diary/"

# View Core Data model
open "Micro Diary/Micro_Diary.xcdatamodeld"

# Check entitlements
cat "Micro Diary/Micro_Diary.entitlements"
```

## Development Workflow
```bash
# Format Swift code (if SwiftFormat is installed)
swiftformat .

# Lint Swift code (if SwiftLint is installed)
swiftlint

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Micro_Diary-*
```

## Git Commands
```bash
# Initialize git (if not done)
git init
git add .
git commit -m "Initial commit"

# Standard workflow
git add .
git commit -m "Feature: description"
git push origin main
```

## Debugging
```bash
# View simulator logs
xcrun simctl spawn booted log stream --predicate 'subsystem contains "ryoasai.Micro-Diary"'

# Reset simulator
xcrun simctl erase all
```

## System Commands (macOS)
```bash
# File operations
ls -la          # List files with details
find . -name "*.swift"  # Find Swift files
grep -r "searchterm" .  # Search in files

# Directory navigation
cd /path/to/project
pwd                     # Current directory
```
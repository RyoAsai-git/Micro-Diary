# Code Style and Conventions

## Swift Coding Standards
- **Language**: Swift 5.0
- **Naming Convention**: camelCase for variables/functions, PascalCase for types
- **File Structure**: One main type per file, related extensions in same file
- **Access Control**: Use explicit access modifiers (private, internal, public)

## SwiftUI Conventions
- **View Structure**: Extract complex views into separate structs
- **State Management**: Use @State, @StateObject, @ObservedObject appropriately
- **Environment**: Pass shared data via @Environment
- **Previews**: Always include #Preview for UI components

## Core Data Conventions
- **Entity Names**: PascalCase (Entry, Badge, Settings)
- **Attribute Names**: camelCase (createdAt, updatedAt, isEdited)
- **Relationships**: Clear naming with appropriate inverse relationships
- **CloudKit**: Use cloudkit-compatible attribute types

## Project Organization
```
Micro Diary/
├── Models/          # Core Data entities, data models
├── Views/           # SwiftUI views
├── ViewModels/      # ObservableObject classes
├── Services/        # API, notification, ad services
├── Utilities/       # Helper functions, extensions
└── Resources/       # Assets, localization
```

## Error Handling
- Use Result<Success, Failure> for async operations
- Implement proper Core Data error handling
- Graceful degradation for CloudKit sync failures
- User-friendly error messages

## Documentation
- Use /// for public APIs
- Document complex business logic
- Include usage examples for reusable components
# Finlytic Project Structure

## Directory Overview

```
finlytic/
├── lib/                     # Main application code
│   ├── config/             # App configuration
│   ├── models/             # Data models
│   ├── providers/          # Riverpod state management
│   ├── screens/            # UI screens
│   ├── services/           # Business logic
│   ├── utils/              # Utilities and helpers
│   ├── widgets/            # Reusable components
│   ├── theme/              # App theming
│   └── main.dart           # Entry point
├── test/                   # Test files
├── assets/                 # Static assets
├── scripts/                # Build scripts
├── docs/                   # Documentation
└── platform configs/      # Platform-specific files
```

## Key Directories

### `/lib/models/`
- `expense_model.dart` - Expense data structure
- `budget_model.dart` - Budget data structure
- `user_model.dart` - User profile structure
- `category_model.dart` - Category structure

### `/lib/services/`
- `expense_service.dart` - Expense CRUD operations
- `budget_service.dart` - Budget management
- `auth_service.dart` - Authentication logic
- `ai_service.dart` - AI insights
- `ocr_service.dart` - Receipt scanning
- `voice_input_service.dart` - Voice recognition

### `/lib/providers/`
- `expense_provider.dart` - Expense state management
- `budget_provider.dart` - Budget state management
- `auth_provider.dart` - Auth state management
- `theme_provider.dart` - Theme management

### `/lib/screens/`
- `dashboard/` - Main dashboard
- `expenses/` - Expense management
- `budgets/` - Budget planning
- `analytics/` - Data visualization
- `auth/` - Authentication flows
- `profile/` - User settings

### `/lib/widgets/`
- `buttons.dart` - Custom buttons
- `cards.dart` - Card components
- `inputs.dart` - Input fields
- `loading_widgets.dart` - Loading states
- `modern_widgets.dart` - Modern UI components

### `/test/`
- `models/` - Model tests
- `services/` - Service tests
- `widgets/` - Widget tests
- `integration/` - Integration tests

## Architecture Patterns

### State Management
- **Riverpod** for state management
- **Provider pattern** for dependency injection
- **Repository pattern** for data access

### File Naming
- **snake_case** for file names
- **PascalCase** for class names
- **camelCase** for variables and methods

### Code Organization
- One class per file
- Group related functionality
- Clear separation of concerns
- Consistent import ordering

## Development Guidelines

### Adding New Features
1. Create model in `/lib/models/`
2. Implement service in `/lib/services/`
3. Add provider in `/lib/providers/`
4. Create UI in `/lib/screens/`
5. Write tests in `/test/`

### Testing Strategy
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for workflows
- Mock external dependencies

### Performance Considerations
- Lazy loading for large lists
- Image caching and optimization
- Efficient state updates
- Memory management

For detailed API documentation, see `/docs/API.md`.
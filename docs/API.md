# Finlytic API Documentation

## Core Services

### ExpenseService

#### Methods
```dart
// Add new expense
Future<void> addExpense(Expense expense);

// Get expenses with filters
Future<List<Expense>> getExpenses({
  DateTime? startDate,
  DateTime? endDate,
  String? categoryId,
});

// Update expense
Future<void> updateExpense(Expense expense);

// Delete expense
Future<void> deleteExpense(String expenseId);
```

### BudgetService

#### Methods
```dart
// Create budget
Future<void> createBudget(Budget budget);

// Get active budgets
Future<List<Budget>> getActiveBudgets();

// Check budget status
Future<BudgetStatus> checkBudgetStatus(String categoryId);
```

### AuthService

#### Methods
```dart
// Sign in with email
Future<UserCredential> signInWithEmail(String email, String password);

// Sign in with Google
Future<UserCredential> signInWithGoogle();

// Sign out
Future<void> signOut();
```

## Data Models

### Expense
```dart
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String description;
  final String categoryId;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? receiptUrl;
}
```

### Budget
```dart
class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
}
```

### User
```dart
class User {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String currency;
  final DateTime createdAt;
}
```

## Error Handling

### Custom Exceptions
```dart
class ExpenseException implements Exception {
  final String message;
  ExpenseException(this.message);
}

class AuthException implements Exception {
  final String message;
  final String code;
  AuthException(this.message, this.code);
}
```

## State Management

### Riverpod Providers
```dart
@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  FutureOr<List<Expense>> build() async {
    return _expenseService.getExpenses();
  }
  
  Future<void> addExpense(Expense expense) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _expenseService.addExpense(expense);
      return _expenseService.getExpenses();
    });
  }
}
```

For detailed implementation, see individual service files in `/lib/services/`.
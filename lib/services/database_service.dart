import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/income.dart';
import '../models/debt.dart';
import '../models/fondo_item.dart';
import '../models/savings_fund.dart';
import '../models/fixed_expense.dart';
import '../models/constants.dart';

class DatabaseService {
  static const String _incomeBox = 'incomes';
  static const String _debtBox = 'debts';
  static const String _paymentBox = 'payments';
  static const String _fondoItemsBox = 'fondo_items';
  static const String _savingsFundsBox = 'savings_funds';
  static const String _savingsMovementsBox = 'savings_movements';
  static const String _fixedExpensesBox = 'fixed_expenses';
  static const String _fixedExpensePaymentsBox = 'fixed_expense_payments';
  static const String _settingsBox = 'settings';

  static final _uuid = Uuid();

  // ── Initialization ──

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(IncomeAdapter());
    Hive.registerAdapter(DebtCategoryAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(DebtPaymentAdapter());
    Hive.registerAdapter(FondoItemAdapter());
    Hive.registerAdapter(SavingsFundAdapter());
    Hive.registerAdapter(SavingsMovementAdapter());
    Hive.registerAdapter(FixedExpenseAdapter());
    Hive.registerAdapter(FixedExpensePaymentAdapter());

    // Open boxes
    await Hive.openBox<Income>(_incomeBox);
    await Hive.openBox<Debt>(_debtBox);
    await Hive.openBox<DebtPayment>(_paymentBox);
    await Hive.openBox<FondoItem>(_fondoItemsBox);
    await Hive.openBox<SavingsFund>(_savingsFundsBox);
    await Hive.openBox<SavingsMovement>(_savingsMovementsBox);
    await Hive.openBox<FixedExpense>(_fixedExpensesBox);
    await Hive.openBox<FixedExpensePayment>(_fixedExpensePaymentsBox);
    await Hive.openBox(_settingsBox);
  }

  // ── Box accessors ──

  static Box<Income> get _incomes => Hive.box<Income>(_incomeBox);
  static Box<Debt> get _debts => Hive.box<Debt>(_debtBox);
  static Box<DebtPayment> get _payments => Hive.box<DebtPayment>(_paymentBox);
  static Box<FondoItem> get _fondoItems => Hive.box<FondoItem>(_fondoItemsBox);
  static Box<SavingsFund> get _savingsFunds => Hive.box<SavingsFund>(_savingsFundsBox);
  static Box<SavingsMovement> get _savingsMovements => Hive.box<SavingsMovement>(_savingsMovementsBox);
  static Box<FixedExpense> get _fixedExpenses => Hive.box<FixedExpense>(_fixedExpensesBox);
  static Box<FixedExpensePayment> get _fixedExpensePayments =>
      Hive.box<FixedExpensePayment>(_fixedExpensePaymentsBox);
  static Box get _settings => Hive.box(_settingsBox);

  static String generateId() => _uuid.v4();

  // ── Week helper ──

  /// Returns the start of the current week (most recent Sunday at 00:00).
  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday % 7));
  }

  static DateTime _currentMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  // ── Income Operations ──

  /// Register a new income. Automatically splits into Bloque de Titanio + Munición Libre.
  static Future<Income> registerIncome({
    required double amount,
    required String type,
    String? note,
  }) async {
    final titanio = FinancialConstants.bloqueDeTitanio;
    final municion = (amount - titanio).clamp(0.0, double.infinity);

    final income = Income(
      id: generateId(),
      amount: amount,
      type: type,
      date: DateTime.now(),
      bloqueDeTitanio: amount >= titanio ? titanio : amount,
      municionLibre: municion,
      note: note,
    );

    await _incomes.put(income.id, income);
    return income;
  }

  static List<Income> getAllIncomes() {
    final list = _incomes.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<void> deleteIncome(String id) async {
    await _incomes.delete(id);
  }

  // ── Debt Operations ──

  static Future<Debt> addDebt({
    required String name,
    required String description,
    required DebtCategory category,
    required double totalAmount,
    double monthlyPayment = 0,
    double interestRate = 0,
  }) async {
    final debt = Debt(
      id: generateId(),
      name: name,
      description: description,
      category: category,
      totalAmount: totalAmount,
      monthlyPayment: monthlyPayment,
      interestRate: interestRate,
      createdAt: DateTime.now(),
    );

    await _debts.put(debt.id, debt);
    return debt;
  }

  static List<Debt> getAllDebts() {
    return _debts.values.where((d) => d.isActive).toList();
  }

  static List<Debt> getDebtsByCategory(DebtCategory category) {
    return getAllDebts().where((d) => d.category == category).toList();
  }

  static Future<DebtPayment> makePayment({
    required String debtId,
    required double amount,
    String? note,
  }) async {
    final debt = _debts.get(debtId);
    if (debt == null) throw Exception('Deuda no encontrada');

    debt.paidAmount += amount;
    debt.lastPaymentDate = DateTime.now();
    await debt.save();

    final payment = DebtPayment(
      id: generateId(),
      debtId: debtId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );

    await _payments.put(payment.id, payment);
    return payment;
  }

  static List<DebtPayment> getPaymentsForDebt(String debtId) {
    return _payments.values.where((p) => p.debtId == debtId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteDebt(String id) async {
    final debt = _debts.get(id);
    if (debt != null) {
      debt.isActive = false;
      await debt.save();
    }
  }

  static Future<void> updateDebt(Debt debt) async {
    await debt.save();
  }

  // Weekly plan per debt (stored in settings)

  static String _weeklyPlanKey(String debtId) => 'weekly_plan_$debtId';

  static Future<void> splitDebtIntoWeeklyPlan({
    required String debtId,
    required int weeks,
    required int dueWeekday,
  }) async {
    final debt = _debts.get(debtId);
    if (debt == null) throw Exception('Deuda no encontrada');
    if (weeks <= 0) throw Exception('Semanas inválidas');

    final weeklyAmount = debt.remainingAmount / weeks;

    await _settings.put(_weeklyPlanKey(debtId), {
      'debtId': debtId,
      'weeks': weeks,
      'weeklyAmount': weeklyAmount,
      'dueWeekday': dueWeekday,
      'createdAt': DateTime.now().toIso8601String(),
      'active': true,
    });
  }

  static Map<String, dynamic>? getDebtWeeklyPlan(String debtId) {
    final raw = _settings.get(_weeklyPlanKey(debtId));
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static Future<void> removeDebtWeeklyPlan(String debtId) async {
    await _settings.delete(_weeklyPlanKey(debtId));
  }

  static double getDebtPaidThisWeek(String debtId) {
    final weekStart = _currentWeekStart();
    double paid = 0;
    for (final payment in _payments.values) {
      if (payment.debtId == debtId && payment.date.isAfter(weekStart)) {
        paid += payment.amount;
      }
    }
    return paid;
  }

  static bool isDebtWeeklyPaymentPending(Debt debt) {
    final plan = getDebtWeeklyPlan(debt.id);
    if (plan == null || plan['active'] != true) return false;

    final dueWeekday = (plan['dueWeekday'] as int?) ?? DateTime.friday;
    if (DateTime.now().weekday < dueWeekday) return false;

    final weeklyAmount = (plan['weeklyAmount'] as num?)?.toDouble() ?? 0;
    return getDebtPaidThisWeek(debt.id) + 0.01 < weeklyAmount;
  }

  // ══════════════════════════════════════════════════════
  // FIXED EXPENSES
  // ══════════════════════════════════════════════════════

  static Future<FixedExpense> addFixedExpense({
    required String name,
    required double amount,
    required int dueDay,
  }) async {
    final expense = FixedExpense(
      id: generateId(),
      name: name,
      amount: amount,
      dueDay: dueDay.clamp(1, 28),
    );
    await _fixedExpenses.put(expense.id, expense);
    return expense;
  }

  static List<FixedExpense> getAllFixedExpenses() {
    return _fixedExpenses.values.where((e) => e.isActive).toList()
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
  }

  static List<FixedExpensePayment> getAllFixedExpensePayments(String expenseId) {
    return _fixedExpensePayments.values
        .where((p) => p.expenseId == expenseId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteFixedExpense(String id) async {
    final expense = _fixedExpenses.get(id);
    if (expense != null) {
      expense.isActive = false;
      await expense.save();
    }
  }

  static bool isFixedExpensePaidThisMonth(String expenseId) {
    final key = _monthKey(DateTime.now());
    return _fixedExpensePayments.values.any((p) =>
        p.expenseId == expenseId && _monthKey(p.date) == key);
  }

  static Future<void> registerFixedExpensePayment({
    required String expenseId,
    String? note,
  }) async {
    final expense = _fixedExpenses.get(expenseId);
    if (expense == null) throw Exception('Gasto fijo no encontrado');
    if (isFixedExpensePaidThisMonth(expenseId)) return;

    final payment = FixedExpensePayment(
      id: generateId(),
      expenseId: expenseId,
      amount: expense.amount,
      date: DateTime.now(),
      note: note,
    );
    await _fixedExpensePayments.put(payment.id, payment);
  }

  static List<FixedExpense> getPendingFixedExpensesThisMonth() {
    final now = DateTime.now();
    return getAllFixedExpenses().where((e) {
      if (e.dueDay > now.day) return false;
      return !isFixedExpensePaidThisMonth(e.id);
    }).toList();
  }

  // ── Financial Calculations ──

  // ══════════════════════════════════════════════════════
  // FONDO INTOCABLE — CHECKLIST ITEMS
  // ══════════════════════════════════════════════════════

  /// Returns the current week's FondoItems, creating them if they don't exist yet.
  static Future<List<FondoItem>> getOrCreateWeeklyFondoItems() async {
    final weekStart = _currentWeekStart();
    final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';

    final existing = _fondoItems.values.where((item) {
      final k = '${item.weekStart.year}-${item.weekStart.month}-${item.weekStart.day}';
      return k == weekKey;
    }).toList();

    if (existing.isNotEmpty) return existing;

    // Create new items for this week from defaults
    final items = <FondoItem>[];
    for (final entry in FinancialConstants.fondoItemDefaults.entries) {
      final item = FondoItem(
        id: generateId(),
        name: entry.key,
        targetAmount: entry.value,
        weekStart: weekStart,
      );
      await _fondoItems.put(item.id, item);
      items.add(item);
    }
    return items;
  }

  /// Toggle the paid status of a FondoItem.
  static Future<void> toggleFondoItem(String id) async {
    final item = _fondoItems.get(id);
    if (item == null) return;
    item.isPaid = !item.isPaid;
    item.paidAt = item.isPaid ? DateTime.now() : null;
    await item.save();
  }

  /// Update the target amount of a FondoItem.
  static Future<void> updateFondoItemAmount(String id, double amount) async {
    final item = _fondoItems.get(id);
    if (item == null) return;
    item.targetAmount = amount;
    await item.save();
  }

  // ══════════════════════════════════════════════════════
  // SAVINGS FUNDS & MOVEMENTS
  // ══════════════════════════════════════════════════════

  static List<SavingsFund> getAllSavingsFunds() {
    return _savingsFunds.values.where((f) => f.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<SavingsFund> createSavingsFund({
    required String name,
    required String type,
    double targetAmount = 0,
    String? description,
  }) async {
    final fund = SavingsFund(
      id: generateId(),
      name: name,
      type: type,
      targetAmount: targetAmount,
      description: description,
      createdAt: DateTime.now(),
    );
    await _savingsFunds.put(fund.id, fund);
    return fund;
  }

  /// Deposit [amount] from Capital Libre into a savings fund.
  static Future<void> depositToFund({
    required String fundId,
    required double amount,
    String? note,
  }) async {
    final fund = _savingsFunds.get(fundId);
    if (fund == null) throw Exception('Fondo no encontrado');

    fund.balance += amount;
    await fund.save();

    final movement = SavingsMovement(
      id: generateId(),
      fundId: fundId,
      amount: amount,
      isDeposit: true,
      note: note,
      date: DateTime.now(),
    );
    await _savingsMovements.put(movement.id, movement);
  }

  /// Withdraw [amount] from a savings fund back to Capital Libre.
  static Future<void> withdrawFromFund({
    required String fundId,
    required double amount,
    String? note,
  }) async {
    final fund = _savingsFunds.get(fundId);
    if (fund == null) throw Exception('Fondo no encontrado');
    if (fund.balance < amount) throw Exception('Saldo insuficiente en el fondo');

    fund.balance -= amount;
    await fund.save();

    final movement = SavingsMovement(
      id: generateId(),
      fundId: fundId,
      amount: amount,
      isDeposit: false,
      note: note,
      date: DateTime.now(),
    );
    await _savingsMovements.put(movement.id, movement);
  }

  static List<SavingsMovement> getMovementsForFund(String fundId) {
    return _savingsMovements.values
        .where((m) => m.fundId == fundId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteSavingsFund(String id) async {
    final fund = _savingsFunds.get(id);
    if (fund != null) {
      fund.isActive = false;
      await fund.save();
    }
  }

  /// Sum of all active savings fund balances.
  static double getTotalSavingsBalance() {
    return getAllSavingsFunds().fold(0.0, (sum, f) => sum + f.balance);
  }

  // ── Financial Calculations ──

  /// Capital Libre disponible esta semana (munición libre menos pagos y depósitos a fondos).
  static double getMunicionLibreTotal() {
    final currentWeekStart = _currentWeekStart();

    double totalMunicion = 0;
    for (final income in _incomes.values) {
      if (income.date.isAfter(currentWeekStart)) {
        totalMunicion += income.municionLibre;
      }
    }

    // Subtract debt payments made this week
    for (final payment in _payments.values) {
      if (payment.date.isAfter(currentWeekStart)) {
        totalMunicion -= payment.amount;
      }
    }

    // Adjust for savings fund movements this week
    for (final movement in _savingsMovements.values) {
      if (movement.date.isAfter(currentWeekStart)) {
        if (movement.isDeposit) {
          totalMunicion -= movement.amount;
        } else {
          totalMunicion += movement.amount;
        }
      }
    }

    // Subtract fixed expense payments this week
    for (final fixed in _fixedExpensePayments.values) {
      if (fixed.date.isAfter(currentWeekStart)) {
        totalMunicion -= fixed.amount;
      }
    }

    return totalMunicion.clamp(0.0, double.infinity);
  }

  /// Total Bloque de Titanio secured this week.
  static double getBloqueDeTitanioThisWeek() {
    final currentWeekStart = _currentWeekStart();

    double total = 0;
    for (final income in _incomes.values) {
      if (income.date.isAfter(currentWeekStart)) {
        total += income.bloqueDeTitanio;
      }
    }
    return total;
  }

  /// BBVA total balance (all incomes - all payments)
  static double getSaldoTotal() {
    double totalIncome = 0;
    for (final income in _incomes.values) {
      totalIncome += income.amount;
    }

    double totalPayments = 0;
    for (final payment in _payments.values) {
      totalPayments += payment.amount;
    }

    for (final fixed in _fixedExpensePayments.values) {
      totalPayments += fixed.amount;
    }

    return totalIncome - totalPayments;
  }

  static MonthlyBalanceSummary getCurrentMonthSummary() {
    final monthStart = _currentMonthStart();

    double income = 0;
    for (final item in _incomes.values) {
      if (item.date.isAfter(monthStart)) income += item.amount;
    }

    double debtPayments = 0;
    for (final item in _payments.values) {
      if (item.date.isAfter(monthStart)) debtPayments += item.amount;
    }

    double fixedPayments = 0;
    for (final item in _fixedExpensePayments.values) {
      if (item.date.isAfter(monthStart)) fixedPayments += item.amount;
    }

    double savingsNet = 0;
    for (final item in _savingsMovements.values) {
      if (item.date.isAfter(monthStart)) {
        savingsNet += item.isDeposit ? item.amount : -item.amount;
      }
    }

    final cashResult = income - debtPayments - fixedPayments - savingsNet;
    return MonthlyBalanceSummary(
      incomes: income,
      debtPayments: debtPayments,
      fixedExpenses: fixedPayments,
      savingsNet: savingsNet,
      cashResult: cashResult,
    );
  }

  static List<PendingInfoItem> getPendingInfoItems() {
    final result = <PendingInfoItem>[];

    for (final debt in getAllDebts()) {
      final plan = getDebtWeeklyPlan(debt.id);
      if (plan == null || plan['active'] != true) continue;

      final dueDay = (plan['dueWeekday'] as int?) ?? DateTime.friday;
      final weeklyAmount = (plan['weeklyAmount'] as num?)?.toDouble() ?? 0;
      final paid = getDebtPaidThisWeek(debt.id);
      final pending = (weeklyAmount - paid).clamp(0.0, double.infinity);

      if (DateTime.now().weekday >= dueDay && pending > 0) {
        result.add(PendingInfoItem(
          title: debt.name,
          subtitle: 'Pago semanal pendiente',
          amount: pending,
          kind: PendingKind.weeklyDebt,
        ));
      }
    }

    for (final item in getPendingFixedExpensesThisMonth()) {
      result.add(PendingInfoItem(
        title: item.name,
        subtitle: 'Gasto fijo pendiente (día ${item.dueDay})',
        amount: item.amount,
        kind: PendingKind.fixedExpense,
        refId: item.id,
      ));
    }

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  /// Total debt across all categories
  static double getTotalDebtRemaining() {
    double total = 0;
    for (final debt in getAllDebts()) {
      total += debt.remainingAmount;
    }
    return total;
  }

  /// Total debt remaining for a specific category
  static double getTotalDebtByCategory(DebtCategory category) {
    double total = 0;
    for (final debt in getDebtsByCategory(category)) {
      total += debt.remainingAmount;
    }
    return total;
  }

  /// Boolean: is titanium block secured?
  static bool isTitaniumSecured() {
    return getBloqueDeTitanioThisWeek() >= FinancialConstants.bloqueDeTitanio;
  }

  // ── Settings ──

  static Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue);
  }

  /// Get Gemini API key from local settings
  static String? getGeminiApiKey() {
    return _settings.get('gemini_api_key') as String?;
  }

  static Future<void> setGeminiApiKey(String key) async {
    await _settings.put('gemini_api_key', key);
  }
}

enum PendingKind {
  weeklyDebt,
  fixedExpense,
}

class PendingInfoItem {
  final String title;
  final String subtitle;
  final double amount;
  final PendingKind kind;
  final String? refId;

  const PendingInfoItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
    this.refId,
  });
}

class MonthlyBalanceSummary {
  final double incomes;
  final double debtPayments;
  final double fixedExpenses;
  final double savingsNet;
  final double cashResult;

  const MonthlyBalanceSummary({
    required this.incomes,
    required this.debtPayments,
    required this.fixedExpenses,
    required this.savingsNet,
    required this.cashResult,
  });
}

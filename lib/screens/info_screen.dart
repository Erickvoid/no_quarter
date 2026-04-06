import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../models/fixed_expense.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final pendingItems = DatabaseService.getPendingInfoItems();
    final fixedExpenses = DatabaseService.getAllFixedExpenses();
    final monthly = DatabaseService.getCurrentMonthSummary();

    return RefreshIndicator(
      color: RefugioTheme.accent,
      backgroundColor: RefugioTheme.surface,
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Info Financiera',
            style: RefugioTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Pendientes, gastos fijos y balance mensual',
            style: RefugioTextStyles.label,
          ),
          const SizedBox(height: 20),
          _buildPendingSection(pendingItems),
          const SizedBox(height: 16),
          _buildFixedExpensesSection(fixedExpenses),
          const SizedBox(height: 16),
          _buildMonthlyBalanceSection(monthly),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPendingSection(List<PendingInfoItem> items) {
    return RefugioCard(
      borderColor: RefugioTheme.amber,
      headerLabel: 'Pagos Pendientes',
      child: items.isEmpty
          ? Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: RefugioTheme.primary, size: 16),
                const SizedBox(width: 8),
                Text('Sin pendientes por ahora', style: RefugioTextStyles.label),
              ],
            )
          : Column(
              children: items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.kind == PendingKind.fixedExpense
                        ? RefugioTheme.amber.withValues(alpha: 0.1)
                        : RefugioTheme.salmon.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.kind == PendingKind.fixedExpense
                            ? Icons.event_note_rounded
                            : Icons.payments_rounded,
                        size: 15,
                        color: item.kind == PendingKind.fixedExpense
                            ? RefugioTheme.amber
                            : RefugioTheme.salmon,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: RefugioTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                            Text(item.subtitle,
                                style: RefugioTextStyles.label.copyWith(fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormat.format(item.amount),
                        style: RefugioTextStyles.body.copyWith(
                          color: RefugioTheme.salmon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.kind == PendingKind.fixedExpense && item.refId != null)
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, size: 18, color: RefugioTheme.primary),
                          onPressed: () async {
                            await DatabaseService.registerFixedExpensePayment(expenseId: item.refId!);
                            if (!mounted) return;
                            setState(() {});
                          },
                          tooltip: 'Marcar pagado',
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFixedExpensesSection(List<FixedExpense> expenses) {
    return RefugioCard(
      borderColor: RefugioTheme.accent,
      headerLabel: 'Gastos Fijos por Fecha',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddFixedExpenseDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar gasto fijo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RefugioTheme.accent,
                side: BorderSide(color: RefugioTheme.accent.withValues(alpha: 0.4)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (expenses.isEmpty)
            Text('No has registrado gastos fijos.', style: RefugioTextStyles.label)
          else
            ...expenses.map((expense) {
              final paid = DatabaseService.isFixedExpensePaidThisMonth(expense.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: paid
                      ? RefugioTheme.primary.withValues(alpha: 0.08)
                      : RefugioTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RefugioTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      paid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 16,
                      color: paid ? RefugioTheme.primary : RefugioTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.name,
                              style: RefugioTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            'Día ${expense.dueDay} de cada mes',
                            style: RefugioTextStyles.label.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(expense.amount),
                      style: RefugioTextStyles.body.copyWith(
                        color: RefugioTheme.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!paid)
                      IconButton(
                        onPressed: () async {
                          await DatabaseService.registerFixedExpensePayment(expenseId: expense.id);
                          if (!mounted) return;
                          setState(() {});
                        },
                        icon: const Icon(Icons.done_rounded, size: 18),
                        color: RefugioTheme.primary,
                        tooltip: 'Marcar pagado',
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMonthlyBalanceSection(MonthlyBalanceSummary summary) {
    final resultPositive = summary.cashResult >= 0;

    return RefugioCard(
      borderColor: resultPositive ? RefugioTheme.primary : RefugioTheme.salmon,
      headerLabel: 'Balance Mensual',
      child: Column(
        children: [
          _buildSummaryRow('Ingresos', summary.incomes, RefugioTheme.primary),
          const SizedBox(height: 6),
          _buildSummaryRow('Pagos a pasivos', -summary.debtPayments, RefugioTheme.salmon),
          const SizedBox(height: 6),
          _buildSummaryRow('Gastos fijos pagados', -summary.fixedExpenses, RefugioTheme.amber),
          const SizedBox(height: 6),
          _buildSummaryRow('Ahorro / inversión neta', -summary.savingsNet, RefugioTheme.accent),
          Divider(color: RefugioTheme.cardBorder, height: 20),
          _buildSummaryRow('Resultado de caja', summary.cashResult,
              resultPositive ? RefugioTheme.primary : RefugioTheme.salmon,
              isBold: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color, {bool isBold = false}) {
    final isPositive = value >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: RefugioTextStyles.label.copyWith(
            color: isBold ? RefugioTheme.textPrimary : RefugioTheme.textSecondary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          '${isPositive ? '+' : '-'}${_currencyFormat.format(value.abs())}',
          style: RefugioTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showAddFixedExpenseDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueDayCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo gasto fijo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Internet, Renta, Spotify',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                suffixText: 'MXN',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dueDayCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Día de pago (1-28)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text.trim());
              final day = int.tryParse(dueDayCtrl.text.trim());
              if (name.isEmpty || amount == null || amount <= 0 || day == null || day < 1 || day > 28) {
                return;
              }
              await DatabaseService.addFixedExpense(name: name, amount: amount, dueDay: day);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {});
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

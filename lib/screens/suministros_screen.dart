import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
import '../models/constants.dart';
import '../models/income.dart';

/// Pantalla 2: Registro de Ingresos
class SuministrosScreen extends StatefulWidget {
  final VoidCallback? onIncomeRegistered;

  const SuministrosScreen({super.key, this.onIncomeRegistered});

  @override
  State<SuministrosScreen> createState() => _SuministrosScreenState();
}

class _SuministrosScreenState extends State<SuministrosScreen> {
  final _customAmountController = TextEditingController();
  final _noteController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _customAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomes = DatabaseService.getAllIncomes();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Ingresos',
          style: RefugioTextStyles.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          'Registro de ingresos',
          style: RefugioTextStyles.label,
        ),
        const SizedBox(height: 24),

        // ── Registro Rápido ──
        RefugioCard(
          headerLabel: 'Registro Rápido',
          borderColor: RefugioTheme.primary,
          child: Column(
            children: [
              _buildQuickButton(
                label: 'Nómina Base',
                description: 'Depósito semanal estándar',
                icon: Icons.account_balance_wallet_rounded,
                onTap: () => _showAmountDialog('nomina_base'),
              ),
              const SizedBox(height: 12),
              _buildQuickButton(
                label: 'Ingreso Extra',
                description: 'Nómina + bono u otro ingreso',
                icon: Icons.add_chart_rounded,
                onTap: () => _showAmountDialog('mega_deposito'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Distribución ──
        RefugioCard(
          headerLabel: 'Distribución Automática',
          borderColor: RefugioTheme.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProtocolRow(
                'Fondo Intocable',
                _currencyFormat.format(FinancialConstants.bloqueDeTitanio),
                RefugioTheme.amber,
                'Se asignan automáticamente',
              ),
              const SizedBox(height: 8),
              _buildProtocolRow(
                'Capital Libre',
                'Excedente',
                RefugioTheme.primary,
                'Todo por encima de \$2,810',
              ),
            ],
          ),
        ),

        const RefugioDivider(label: 'Historial de Ingresos'),

        // ── Historial ──
        if (incomes.isEmpty)
          const RefugioCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: RefugioTheme.textMuted, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Sin registros',
                      style: RefugioTextStyles.label,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Registra tu primer ingreso arriba',
                      style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 13,
                        color: RefugioTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...incomes.map((income) => _buildIncomeCard(income)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildQuickButton({
    required String label,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RefugioTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RefugioTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RefugioTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: RefugioTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: RefugioTextStyles.subtitle.copyWith(
                      color: RefugioTheme.primary,
                      fontWeight: FontWeight.w700,
                    )),
                    Text(description, style: TextStyle(
                      fontFamily: RefugioTheme.fontFamily,
                      fontSize: 12,
                      color: RefugioTheme.textMuted,
                    )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: RefugioTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolRow(String label, String value, Color color, String sub) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: RefugioTextStyles.label.copyWith(color: color)),
              Text(sub, style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 11,
                color: RefugioTheme.textMuted,
              )),
            ],
          ),
        ),
        Text(value, style: RefugioTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        )),
      ],
    );
  }

  Widget _buildIncomeCard(Income income) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'es').format(income.date);
    final isNomina = income.type == 'nomina_base';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(income.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: RefugioTheme.salmon.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_rounded, color: RefugioTheme.salmon),
        ),
        onDismissed: (_) async {
          await DatabaseService.deleteIncome(income.id);
          setState(() {});
          widget.onIncomeRegistered?.call();
        },
        child: RefugioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isNomina ? Icons.account_balance_wallet_rounded : Icons.add_chart_rounded,
                        color: RefugioTheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isNomina ? 'Nómina Base' : 'Ingreso Extra',
                        style: RefugioTextStyles.label.copyWith(color: RefugioTheme.primary),
                      ),
                    ],
                  ),
                  Text(dateStr, style: RefugioTextStyles.label),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currencyFormat.format(income.amount),
                style: RefugioTextStyles.moneyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSplitChip(
                    'Fondo',
                    _currencyFormat.format(income.bloqueDeTitanio),
                    RefugioTheme.amber,
                  ),
                  const SizedBox(width: 8),
                  _buildSplitChip(
                    'Libre',
                    _currencyFormat.format(income.municionLibre),
                    RefugioTheme.primary,
                  ),
                ],
              ),
              if (income.note != null && income.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  income.note!,
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 12,
                    color: RefugioTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: RefugioTheme.fontFamily,
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: RefugioTheme.fontFamily,
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showAmountDialog(String type) {
    _customAmountController.clear();
    _noteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'nomina_base' ? 'Nómina Base' : 'Ingreso Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto total',
                prefixText: '\$ ',
                suffixText: 'MXN',
              ),
              autofocus: true,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 22,
                color: RefugioTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej: Semana 14...',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 14,
                color: RefugioTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RefugioTheme.primaryMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: RefugioTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se asignarán \$2,810 al Fondo Intocable automáticamente.',
                      style: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        fontSize: 11,
                        color: RefugioTheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: RefugioTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => _registerIncome(type),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registerIncome(String type) async {
    final amountText = _customAmountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    Navigator.pop(context);

    await DatabaseService.registerIncome(
      amount: amount,
      type: type,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    setState(() {});
    widget.onIncomeRegistered?.call();

    if (mounted) {
      final fondo = FinancialConstants.bloqueDeTitanio;
      final libre = (amount - fondo).clamp(0.0, double.infinity);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingreso registrado: \$${amount.toStringAsFixed(2)} · Fondo: \$${fondo.toStringAsFixed(2)} · Libre: \$${libre.toStringAsFixed(2)}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

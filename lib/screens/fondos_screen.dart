import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/database_service.dart';
import '../models/savings_fund.dart';

class FondosScreen extends StatefulWidget {
  const FondosScreen({super.key});

  @override
  State<FondosScreen> createState() => _FondosScreenState();
}

class _FondosScreenState extends State<FondosScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'es');

  @override
  Widget build(BuildContext context) {
    final funds = DatabaseService.getAllSavingsFunds();
    final totalSaved = DatabaseService.getTotalSavingsBalance();
    final ahorroDisponible = DatabaseService.getTotalDisponible();

    return Scaffold(
      backgroundColor: RefugioTheme.background,
      body: RefreshIndicator(
        color: RefugioTheme.cobalt,
        backgroundColor: RefugioTheme.surface,
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Header ──
            _buildHeader(totalSaved, ahorroDisponible),
            const SizedBox(height: 20),

            if (funds.isEmpty) _buildEmptyState() else ...[
              ...funds.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFundCard(f),
              )),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFundDialog(),
        backgroundColor: RefugioTheme.cobalt,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo fondo',
          style: TextStyle(
            fontFamily: RefugioTheme.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(double total, double ahorroDisponible) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fondos de Ahorro',
          style: RefugioTextStyles.heading.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          'Aparta dinero de tu presupuesto de ahorro (20%)',
          style: RefugioTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatChip(
                icon: Icons.savings_rounded,
                label: 'Total ahorrado',
                value: _currencyFormat.format(total),
                color: RefugioTheme.cobalt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatChip(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Para ahorrar',
                value: _currencyFormat.format(ahorroDisponible),
                color: RefugioTheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label, style: RefugioTextStyles.label.copyWith(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: RefugioTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 56,
              color: RefugioTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin fondos todavía',
              style: RefugioTextStyles.heading.copyWith(fontSize: 18, color: RefugioTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un fondo de ahorro o inversión\ny empieza a apartar dinero de tu presupuesto disponible.',
              textAlign: TextAlign.center,
              style: RefugioTextStyles.body.copyWith(fontSize: 13, color: RefugioTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fund card ──

  Widget _buildFundCard(SavingsFund fund) {
    final isInversion = fund.type == 'inversion';
    final color = isInversion ? RefugioTheme.cobalt : RefugioTheme.primary;
    final hasGoal = fund.targetAmount > 0;

    return RefugioCard(
      borderColor: color,
      headerLabel: isInversion ? 'Inversión' : 'Ahorro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund.name,
                      style: RefugioTextStyles.heading.copyWith(fontSize: 16),
                    ),
                    if (fund.description != null && fund.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(fund.description!, style: RefugioTextStyles.subtitle.copyWith(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (fund.goalReached)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RefugioTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 12, color: RefugioTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Meta lograda',
                        style: RefugioTextStyles.label.copyWith(
                          color: RefugioTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(fund.balance),
            style: RefugioTextStyles.moneyLarge.copyWith(
              color: color,
              fontSize: 26,
            ),
          ),
          if (hasGoal) ...[
            const SizedBox(height: 4),
            Text(
              'Meta: ${_currencyFormat.format(fund.targetAmount)} · ${(fund.progressPercent * 100).toStringAsFixed(0)}%',
              style: RefugioTextStyles.label.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            RefugioProgressBar(
              progress: fund.progressPercent,
              color: color,
              height: 6,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDepositDialog(fund),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Depositar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    textStyle: TextStyle(
                      fontFamily: RefugioTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: fund.balance > 0 ? () => _showWithdrawDialog(fund) : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: const Text('Retirar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RefugioTheme.textSecondary,
                    side: BorderSide(color: RefugioTheme.cardBorder),
                    textStyle: TextStyle(
                      fontFamily: RefugioTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showMovementsSheet(fund),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RefugioTheme.textMuted,
                  side: BorderSide(color: RefugioTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: Size.zero,
                ),
                child: const Icon(Icons.history_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──

  void _showCreateFundDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String selectedType = 'ahorro';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo fondo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del fondo',
                    hintText: 'Ej: Viaje, Emergencias, ETF…',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Tipo:', style: RefugioTextStyles.label),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Ahorro'),
                      selected: selectedType == 'ahorro',
                      onSelected: (_) => setDialogState(() => selectedType = 'ahorro'),
                      selectedColor: RefugioTheme.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        color: selectedType == 'ahorro' ? RefugioTheme.primary : RefugioTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Inversión'),
                      selected: selectedType == 'inversion',
                      onSelected: (_) => setDialogState(() => selectedType = 'inversion'),
                      selectedColor: RefugioTheme.cobalt.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        fontFamily: RefugioTheme.fontFamily,
                        color: selectedType == 'inversion' ? RefugioTheme.cobalt : RefugioTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Meta (opcional)',
                    hintText: '0 = sin meta',
                    prefixText: '\$ ',
                    suffixText: 'MXN',
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final target = double.tryParse(targetCtrl.text.trim()) ?? 0;
                Navigator.pop(ctx);
                await DatabaseService.createSavingsFund(
                  name: name,
                  type: selectedType,
                  targetAmount: target,
                  description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                );
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: RefugioTheme.cobalt),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(SavingsFund fund) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final ahorroDisponible = DatabaseService.getTotalDisponible();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Depositar a "${fund.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RefugioTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 14, color: RefugioTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Disponible para ahorrar: ${_currencyFormat.format(ahorroDisponible)}',
                    style: RefugioTextStyles.label.copyWith(fontSize: 12, color: RefugioTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto a depositar',
                prefixText: '\$ ',
                suffixText: 'MXN',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 20,
                color: RefugioTheme.cobalt,
                fontWeight: FontWeight.w700,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 13,
                color: RefugioTheme.textPrimary,
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
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              if (amount > ahorroDisponible) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monto supera tu saldo disponible')),
                );
                return;
              }
              Navigator.pop(ctx);
              await DatabaseService.depositToFund(
                fundId: fund.id,
                amount: amount,
                note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
              );
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: RefugioTheme.cobalt),
            child: const Text('Depositar'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(SavingsFund fund) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Retirar de "${fund.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RefugioTheme.cobalt.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings_outlined, size: 14, color: RefugioTheme.cobalt),
                  const SizedBox(width: 6),
                  Text(
                    'Saldo del fondo: ${_currencyFormat.format(fund.balance)}',
                    style: RefugioTextStyles.label.copyWith(fontSize: 12, color: RefugioTheme.cobalt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monto a retirar',
                prefixText: '\$ ',
                suffixText: 'MXN',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 20,
                color: RefugioTheme.amber,
                fontWeight: FontWeight.w700,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 13,
                color: RefugioTheme.textPrimary,
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
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              if (amount > fund.balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Monto supera el saldo del fondo')),
                );
                return;
              }
              Navigator.pop(ctx);
              await DatabaseService.withdrawFromFund(
                fundId: fund.id,
                amount: amount,
                note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
              );
              if (mounted) setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: RefugioTheme.amber),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
  }

  void _showMovementsSheet(SavingsFund fund) {
    showModalBottomSheet(
      context: context,
      backgroundColor: RefugioTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final movements = DatabaseService.getMovementsForFund(fund.id);
        final isInversion = fund.type == 'inversion';
        final color = isInversion ? RefugioTheme.cobalt : RefugioTheme.primary;

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fund.name, style: RefugioTextStyles.heading.copyWith(fontSize: 18)),
                          Text(
                            'Historial de movimientos',
                            style: RefugioTextStyles.subtitle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: RefugioTheme.salmon),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Eliminar fondo'),
                            content: Text('¿Eliminar "${fund.name}"? El saldo regresará a tu presupuesto disponible.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: RefugioTheme.salmonDim),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await DatabaseService.deleteSavingsFund(fund.id);
                          if (mounted) setState(() {});
                        }
                      },
                      tooltip: 'Eliminar fondo',
                    ),
                  ],
                ),
              ),
              Divider(color: RefugioTheme.cardBorder, height: 1),
              if (movements.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded,
                          size: 40, color: RefugioTheme.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('Sin movimientos aún', style: RefugioTextStyles.label),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: movements.length,
                    separatorBuilder: (_, __) => Divider(
                      color: RefugioTheme.cardBorder.withValues(alpha: 0.4),
                      indent: 20,
                      endIndent: 20,
                      height: 1,
                    ),
                    itemBuilder: (_, i) {
                      final m = movements[i];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: m.isDeposit
                              ? color.withValues(alpha: 0.12)
                              : RefugioTheme.amber.withValues(alpha: 0.12),
                          child: Icon(
                            m.isDeposit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 16,
                            color: m.isDeposit ? color : RefugioTheme.amber,
                          ),
                        ),
                        title: Text(
                          m.isDeposit ? 'Depósito' : 'Retiro',
                          style: RefugioTextStyles.body.copyWith(fontSize: 13),
                        ),
                        subtitle: Text(
                          m.note ?? _dateFormat.format(m.date),
                          style: RefugioTextStyles.label.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${m.isDeposit ? '+' : '-'}${_currencyFormat.format(m.amount)}',
                          style: RefugioTextStyles.body.copyWith(
                            color: m.isDeposit ? color : RefugioTheme.amber,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        dense: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

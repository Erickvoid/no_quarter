import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import '../models/debt.dart';

class GeminiService {
  static GenerativeModel? _model;
  static String? _apiKey;

  static const List<String> _modelCandidates = [
    'gemini-3-flash-preview',
  ];

  static void initialize(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: _modelCandidates.first,
      apiKey: apiKey,
    );
  }

  static bool get isConfigured => _model != null;

  /// Construye el contexto financiero actual del usuario
  static String _buildFinancialContext() {
    final saldo = DatabaseService.getSaldoTotal();
    final disponible = DatabaseService.getMunicionLibreTotal();
    final necesidades = DatabaseService.getFondoIntocableThisPeriod();
    final necesidadesCubiertas = DatabaseService.isFondoAsegurado();
    final totalDebt = DatabaseService.getTotalDebtRemaining();
    final totalSavings = DatabaseService.getTotalSavingsBalance();
    final fixedExpenses = DatabaseService.getAllFixedExpenses();
    final pendingItems = DatabaseService.getPendingInfoItems();
    final monthly = DatabaseService.getCurrentMonthSummary();

    final needsPct = DatabaseService.getNeedsPercent();
    final wantsPct = DatabaseService.getWantsPercent();
    final savingsPct = DatabaseService.getSavingsPercent();

    final debtFamilia = DatabaseService.getTotalDebtByCategory(DebtCategory.deudaDeHonor);
    final debtTarjetas = DatabaseService.getTotalDebtByCategory(DebtCategory.lineaEstrategica);
    final debtUrgente = DatabaseService.getTotalDebtByCategory(DebtCategory.basuraFinanciera);
    final debtPausa = DatabaseService.getTotalDebtByCategory(DebtCategory.laCongeladora);

    final fixedTotal = fixedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final fixedPaidCount = fixedExpenses
      .where((e) => DatabaseService.isFixedExpensePaidThisMonth(e.id))
      .length;

    final pendingWeekly = pendingItems
      .where((item) => item.kind == PendingKind.weeklyDebt)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
    final pendingFixed = pendingItems
      .where((item) => item.kind == PendingKind.fixedExpense)
      .fold<double>(0.0, (sum, item) => sum + item.amount);

    final bankName = DatabaseService.getBankName();
    final frequencyLabel = DatabaseService.getFrequencyLabel();

    return '''
── Resumen Financiero ($frequencyLabel) ──
Saldo Total $bankName: \$${saldo.toStringAsFixed(2)} MXN
Necesidades del Hogar ($needsPct%): \$${necesidades.toStringAsFixed(2)} MXN [${necesidadesCubiertas ? "Cubiertas ✓" : "Pendiente ⚠"}]
Disponible ($wantsPct% gastos + $savingsPct% ahorro/deudas): \$${disponible.toStringAsFixed(2)} MXN
Fondos de Ahorro/Inversión: \$${totalSavings.toStringAsFixed(2)} MXN

── Deudas (Total: \$${totalDebt.toStringAsFixed(2)} MXN) ──
• Familia y Amigos: \$${debtFamilia.toStringAsFixed(2)} MXN
• Tarjetas y Créditos: \$${debtTarjetas.toStringAsFixed(2)} MXN
• Deudas Urgentes: \$${debtUrgente.toStringAsFixed(2)} MXN
• En Pausa: \$${debtPausa.toStringAsFixed(2)} MXN

── Gastos Fijos Mensuales ──
• Registrados: ${fixedExpenses.length}
• Monto mensual comprometido: \$${fixedTotal.toStringAsFixed(2)} MXN
• Pagados este mes: $fixedPaidCount/${fixedExpenses.length}

── Pendientes ──
• Pago semanal pendiente: \$${pendingWeekly.toStringAsFixed(2)} MXN
• Gastos fijos pendientes: \$${pendingFixed.toStringAsFixed(2)} MXN

── Resultado Mensual (acumulado) ──
• Ingresos: \$${monthly.incomes.toStringAsFixed(2)} MXN
• Pago de deudas: \$${monthly.debtPayments.toStringAsFixed(2)} MXN
• Gastos fijos pagados: \$${monthly.fixedExpenses.toStringAsFixed(2)} MXN
• Ahorro/Inversión neta: \$${monthly.savingsNet.toStringAsFixed(2)} MXN
• Resultado de caja: \$${monthly.cashResult.toStringAsFixed(2)} MXN
''';
  }

  /// Analiza una consulta de gasto del usuario
  static Future<String> analyzeSpending(String userMessage) async {
    if (_model == null || _apiKey == null) {
      return 'Para activar al Asesor Financiero, configura tu API Key de Gemini en ajustes.';
    }

    final context = _buildFinancialContext();

    final prompt = '''
Eres el Asesor Financiero de la app familiar "Refugio".
Tu objetivo es garantizar el bienestar financiero de la familia y proteger el presupuesto de Necesidades del Hogar.
Habla en español de México, con un tono sereno, empático, objetivo y profesional.
Tu lenguaje debe transmitir que todo está bajo control.

REGLAS:
1. Las "Necesidades del Hogar" (gastos esenciales como despensa, servicios y transporte) tienen prioridad absoluta — no se tocan.
2. Solo el dinero "Disponible" puede usarse para gastos discrecionales, compras o pago de deudas adicionales.
3. Si un gasto compromete las Necesidades del Hogar, es NO RECOMENDADO.
4. Siempre cierra con un veredicto claro: VIABLE / REQUIERE AJUSTE / NO RECOMENDADO.
5. Máximo 150 palabras. Sé claro, cálido y directo.

$context

Consulta del usuario: $userMessage
''';

    try {
      final response = await _generateWithFallback(prompt);
      return response.text ?? 'No se recibió respuesta del asesor.';
    } catch (e) {
      return 'Error de conexión: ${e.toString()}';
    }
  }

  /// Genera un diagnóstico ejecutivo de la situación financiera
  static Future<String> getFinancialBrief() async {
    if (_model == null || _apiKey == null) {
      return 'Para activar al Asesor Financiero, configura tu API Key de Gemini en ajustes.';
    }

    final context = _buildFinancialContext();

    final prompt = '''
Eres el Asesor Financiero Privado de la app "Refugio".
Habla en español de México con un tono sereno, empático, objetivo y profesional. Cero lenguaje militar.
Analiza el siguiente reporte y genera un Diagnóstico Ejecutivo.
Incluye: 1) Estado de liquidez, 2) Observaciones relevantes, 3) Siguiente paso recomendado para maximizar la tranquilidad financiera del usuario.
Tu lenguaje debe transmitir que todo está bajo control.
Máximo 200 palabras.

$context
''';

    try {
      final response = await _generateWithFallback(prompt);
      return response.text ?? 'No se recibió respuesta del asesor.';
    } catch (e) {
      return 'Error de conexión: ${e.toString()}';
    }
  }

  static Future<GenerateContentResponse> _generateWithFallback(String prompt) async {
    final content = [Content.text(prompt)];

    try {
      return await _model!.generateContent(content);
    } catch (e) {
      if (_apiKey == null || !_isModelUnavailableError(e.toString())) {
        rethrow;
      }

      for (final candidate in _modelCandidates.skip(1)) {
        try {
          _model = GenerativeModel(model: candidate, apiKey: _apiKey!);
          return await _model!.generateContent(content);
        } catch (retryError) {
          if (!_isModelUnavailableError(retryError.toString())) {
            rethrow;
          }
        }
      }

      rethrow;
    }
  }

  static bool _isModelUnavailableError(String error) {
    final text = error.toLowerCase();
    return text.contains('is not found') || text.contains('not supported for generatecontent');
  }
}
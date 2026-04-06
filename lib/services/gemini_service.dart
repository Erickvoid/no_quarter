import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import '../models/debt.dart';
import '../models/constants.dart';

class GeminiService {
  static GenerativeModel? _model;
  static String? _apiKey;

  static const List<String> _modelCandidates = [
    'gemini-3-flash-preview',
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
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
    final capitalLibre = DatabaseService.getMunicionLibreTotal();
    final fondoIntocable = DatabaseService.getBloqueDeTitanioThisWeek();
    final fondoAsegurado = DatabaseService.isTitaniumSecured();
    final totalDebt = DatabaseService.getTotalDebtRemaining();
    final totalSavings = DatabaseService.getTotalSavingsBalance();
    final fixedExpenses = DatabaseService.getAllFixedExpenses();
    final pendingItems = DatabaseService.getPendingInfoItems();
    final monthly = DatabaseService.getCurrentMonthSummary();

    final debtHonor = DatabaseService.getTotalDebtByCategory(DebtCategory.deudaDeHonor);
    final debtLinea = DatabaseService.getTotalDebtByCategory(DebtCategory.lineaEstrategica);
    final debtBasura = DatabaseService.getTotalDebtByCategory(DebtCategory.basuraFinanciera);
    final debtCongeladora = DatabaseService.getTotalDebtByCategory(DebtCategory.laCongeladora);

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

    return '''
── Resumen Financiero ──
Saldo Total BBVA: \$${saldo.toStringAsFixed(2)} MXN
Fondo Intocable: \$${fondoIntocable.toStringAsFixed(2)} / \$${FinancialConstants.bloqueDeTitanio.toStringAsFixed(2)} MXN [${fondoAsegurado ? "Asegurado ✓" : "Incompleto ⚠"}]
Capital Libre: \$${capitalLibre.toStringAsFixed(2)} MXN
  Fondos de Ahorro/Inversión: \$${totalSavings.toStringAsFixed(2)} MXN

── Estructura de Pasivos (Total: \$${totalDebt.toStringAsFixed(2)} MXN) ──
• Compromisos Personales: \$${debtHonor.toStringAsFixed(2)} MXN
• Líneas Estratégicas: \$${debtLinea.toStringAsFixed(2)} MXN
• Pasivos Prioritarios: \$${debtBasura.toStringAsFixed(2)} MXN
• En Pausa Estratégica: \$${debtCongeladora.toStringAsFixed(2)} MXN

  ── Gastos Fijos Mensuales ──
  • Registrados: ${fixedExpenses.length}
  • Monto mensual comprometido: \$${fixedTotal.toStringAsFixed(2)} MXN
  • Pagados este mes: $fixedPaidCount/${fixedExpenses.length}

  ── Pendientes Operativos ──
  • Pago semanal pendiente: \$${pendingWeekly.toStringAsFixed(2)} MXN
  • Gastos fijos pendientes: \$${pendingFixed.toStringAsFixed(2)} MXN

  ── Resultado Mensual (acumulado) ──
  • Ingresos: \$${monthly.incomes.toStringAsFixed(2)} MXN
  • Pagos a pasivos: \$${monthly.debtPayments.toStringAsFixed(2)} MXN
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
Eres el Asesor Financiero Privado de la app "Refugio".
Tu objetivo máximo es garantizar la paz mental del usuario y asegurar su "Fondo Intocable" (que incluye su comida, gasolina y el bienestar de sus 6 mascotas: Otilio, Tadea, Archivaldo, Alfredito, Chocolata y Griselda).
Habla en español de México, con un tono extremadamente sereno, empático, objetivo y profesional. Cero lenguaje militar.
Tu lenguaje debe transmitir que todo está bajo control.

REGLAS:
1. El "Fondo Intocable" (\$2,810 MXN) NO SE TOCA. Cubre gasolina, despensa, apoyo a su mamá y el cuidado de sus mascotas.
2. Solo el "Capital Libre" está disponible para gastos discrecionales, compras o liquidación de pasivos.
3. Si un gasto compromete el Fondo Intocable, es NO RECOMENDADO — proteger la tranquilidad es prioridad.
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
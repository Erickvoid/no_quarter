import 'package:flutter/material.dart';
import '../theme/refugio_theme.dart';
import '../widgets/tactical_widgets.dart';
import '../services/gemini_service.dart';
import '../services/database_service.dart';

/// Pantalla 4: Asesor Financiero (Gemini AI)
class AsistenteTacticoScreen extends StatefulWidget {
  const AsistenteTacticoScreen({super.key});

  @override
  State<AsistenteTacticoScreen> createState() => _AsistenteTacticoScreenState();
}

class _AsistenteTacticoScreenState extends State<AsistenteTacticoScreen> {
  final _messageController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitGemini();
  }

  void _checkAndInitGemini() {
    final apiKey = DatabaseService.getGeminiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      GeminiService.initialize(apiKey);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asesor Financiero',
                        style: RefugioTextStyles.heading.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      StatusIndicator(
                        active: GeminiService.isConfigured,
                        label: GeminiService.isConfigured ? 'Conectado' : 'Sin configurar',
                        activeColor: RefugioTheme.primary,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _requestFinancialBrief,
                        icon: const Icon(Icons.insights_rounded, color: RefugioTheme.accent),
                        tooltip: 'Diagnóstico ejecutivo',
                      ),
                      IconButton(
                        onPressed: _showApiKeyDialog,
                        icon: const Icon(Icons.key_rounded, color: RefugioTheme.textMuted),
                        tooltip: 'Configurar API Key',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: RefugioTheme.cardBorder),

        // ── Chat ──
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),

        // ── Cargando ──
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: RefugioTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analizando...',
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 13,
                    color: RefugioTheme.primary,
                  ),
                ),
              ],
            ),
          ),

        // ── Input ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: RefugioTheme.surface,
            border: Border(
              top: BorderSide(color: RefugioTheme.cardBorder),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Ej: "Quiero gastar \$500 en..."',
                    hintStyle: TextStyle(
                      fontFamily: RefugioTheme.fontFamily,
                      fontSize: 14,
                      color: RefugioTheme.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: RefugioTheme.cardBorder),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: RefugioTheme.fontFamily,
                    fontSize: 14,
                    color: RefugioTheme.textPrimary,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: RefugioTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RefugioTheme.primary),
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: RefugioTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 64,
              color: RefugioTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu asesor financiero privado',
              style: RefugioTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Consulta sobre gastos, estrategias\nde pago o tu situación financiera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 13,
                color: RefugioTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Quiero gastar \$500 en ropa'),
                _buildSuggestionChip('¿Puedo pagar \$1,000 a Kueski?'),
                _buildSuggestionChip('¿Cómo va mi semana?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: RefugioTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RefugioTheme.cardBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: RefugioTheme.fontFamily,
            fontSize: 12,
            color: RefugioTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RefugioTheme.primaryMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: RefugioTheme.primary,
                size: 16,
              ),
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? RefugioTheme.surfaceLight
                    : RefugioTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUser
                      ? RefugioTheme.cardBorder
                      : RefugioTheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'Tú' : 'Asesor Refugio',
                    style: RefugioTextStyles.label.copyWith(
                      color: isUser ? RefugioTheme.accent : RefugioTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    message.text,
                    style: RefugioTextStyles.body,
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: RefugioTheme.accentDim.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: RefugioTheme.accent,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    final response = await GeminiService.analyzeSpending(text);

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _requestFinancialBrief() async {
    setState(() {
      _messages.add(_ChatMessage(
        text: 'Solicitar diagnóstico ejecutivo de mi situación.',
        isUser: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final response = await GeminiService.getFinancialBrief();

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showApiKeyDialog() {
    final currentKey = DatabaseService.getGeminiApiKey() ?? '';
    _apiKeyController.text = currentKey;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Gemini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu API Key de Google Gemini.\nSe almacena solo localmente en tu dispositivo.',
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 13,
                color: RefugioTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIza...',
              ),
              style: TextStyle(
                fontFamily: RefugioTheme.fontFamily,
                fontSize: 14,
                color: RefugioTheme.textPrimary,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: RefugioTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = _apiKeyController.text.trim();
              if (key.isNotEmpty) {
                await DatabaseService.setGeminiApiKey(key);
                GeminiService.initialize(key);
                if (!mounted) return;
                setState(() {});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

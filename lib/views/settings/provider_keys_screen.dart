import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/provider_manager.dart';

class ProviderKeysScreen extends ConsumerStatefulWidget {
  const ProviderKeysScreen({super.key});

  @override
  ConsumerState<ProviderKeysScreen> createState() => _ProviderKeysScreenState();
}

class _ProviderKeysScreenState extends ConsumerState<ProviderKeysScreen> {
  final _keyController = TextEditingController();
  String _selectedProvider = 'anthropic';
  bool _saving = false;
  bool _loading = true;

  final _providers = [
    ('anthropic', 'Anthropic (Claude)', 'sk-ant-...'),
    ('openai', 'OpenAI (GPT)', 'sk-proj-...'),
    ('openrouter', 'OpenRouter', 'sk-or-...'),
    ('google', 'Google Gemini', 'AIza...'),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    setState(() => _loading = true);
    final config = ref.read(secureConfigServiceProvider);
    final existingKey = await config.getProviderApiKey();
    final existingType = await config.getProviderType();
    if (existingKey != null) {
      _keyController.text = existingKey;
    }
    if (existingType != null) {
      setState(() => _selectedProvider = existingType);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider AI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Provider AI')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Pilih Provider AI', style: AppTextStyles.headline),
          const SizedBox(height: 16),
          ..._providers.map((p) => _ProviderOption(
            value: p.$1,
            label: p.$2,
            hint: p.$3,
            selected: _selectedProvider == p.$1,
            onTap: () => setState(() => _selectedProvider = p.$1),
          )),
          const SizedBox(height: 24),
          Text('API Key', style: AppTextStyles.title),
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            obscureText: true,
            style: AppTextStyles.code,
            decoration: InputDecoration(
              hintText: _providers.firstWhere((p) => p.$1 == _selectedProvider).$3,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveKey,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveKey() async {
    setState(() => _saving = true);
    final config = ref.read(secureConfigServiceProvider);
    final api = ref.read(openCodeApiClientProvider);
    final key = _keyController.text.trim();

    await config.saveProviderType(_selectedProvider);
    await config.saveProviderApiKey(key);

    final synced = await api.setProviderAuth(_selectedProvider, key);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced ? 'API Key tersimpan & disinkron' : 'API Key tersimpan (gagal sinkron server)'),
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _ProviderOption extends StatelessWidget {
  final String value;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderOption({
    required this.value,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
          color: selected ? AppColors.primary : AppColors.textMuted,
          size: 22,
        ),
        title: Text(label, style: AppTextStyles.title),
        subtitle: Text(hint, style: AppTextStyles.bodySmall),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

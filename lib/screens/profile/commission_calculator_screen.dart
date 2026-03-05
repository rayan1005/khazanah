import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_settings_provider.dart';

class CommissionCalculatorScreen extends ConsumerStatefulWidget {
  const CommissionCalculatorScreen({super.key});

  @override
  ConsumerState<CommissionCalculatorScreen> createState() =>
      _CommissionCalculatorScreenState();
}

class _CommissionCalculatorScreenState
    extends ConsumerState<CommissionCalculatorScreen> {
  final _priceController = TextEditingController();
  double? _commission;
  double? _netAmount;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _calculate(double rate) {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      setState(() {
        _commission = null;
        _netAmount = null;
      });
      return;
    }
    setState(() {
      _commission = price * rate / 100;
      _netAmount = price - _commission!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة العمولة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Commission rate info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.percent,
                        size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'نسبة العمولة: ${settings.commissionRate}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'يتم خصم هذه النسبة من قيمة كل عملية بيع',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Calculator
              const Text(
                'احسب العمولة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'سعر البيع (ر.س)',
                  hintText: 'أدخل سعر البيع',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => _calculate(settings.commissionRate),
              ),
              const SizedBox(height: 16),

              if (_commission != null && _netAmount != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'سعر البيع',
                        value:
                            '${double.tryParse(_priceController.text.trim())?.toStringAsFixed(2)} ر.س',
                        color: AppColors.textPrimary,
                      ),
                      const Divider(height: 16),
                      _ResultRow(
                        label:
                            'العمولة (${settings.commissionRate}%)',
                        value: '${_commission!.toStringAsFixed(2)} ر.س',
                        color: AppColors.error,
                      ),
                      const Divider(height: 16),
                      _ResultRow(
                        label: 'المبلغ الصافي',
                        value: '${_netAmount!.toStringAsFixed(2)} ر.س',
                        color: AppColors.success,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Bank info
              if (settings.bankName.isNotEmpty ||
                  settings.bankAccount.isNotEmpty) ...[
                const Text(
                  'معلومات التحويل',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (settings.bankName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.account_balance,
                                size: 18, color: AppColors.info),
                            const SizedBox(width: 8),
                            Text(
                              'البنك: ${settings.bankName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (settings.bankAccount.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.credit_card,
                                size: 18, color: AppColors.info),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                settings.bankAccount,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            )),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            )),
      ],
    );
  }
}

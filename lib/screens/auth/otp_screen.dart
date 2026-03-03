import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otpCode.length != 4) return;

    final success =
        await ref.read(authNotifierProvider.notifier).verifyOtp(_otpCode);

    if (success && mounted) {
      final hasProfile =
          await ref.read(authNotifierProvider.notifier).hasProfile();
      if (mounted) {
        if (hasProfile) {
          context.go('/home');
        } else {
          context.go('/profile-setup');
        }
      }
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    await ref.read(authNotifierProvider.notifier).sendOtp(widget.phoneNumber);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.sms_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                AppStrings.enterOtp,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppStrings.otpSentTo}\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // OTP fields
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (_otpCode.length == 4) {
                            _verify();
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              if (authState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  authState.error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _verify,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(AppStrings.verify),
              ),

              const SizedBox(height: 20),

              // Resend
              TextButton(
                onPressed: _canResend ? _resend : null,
                child: Text(
                  _canResend
                      ? AppStrings.resendOtp
                      : '${AppStrings.resendOtp} ($_countdown)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

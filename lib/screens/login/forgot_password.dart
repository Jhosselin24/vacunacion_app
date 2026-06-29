import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading  = false;
  bool _enviado    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCorreo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    final auth  = context.read<AuthProvider>();
    final error = await auth.recuperarPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConstants.routeLogin),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: _enviado ? _buildExito() : _buildFormulario(),
        ),
      ),
    );
  }

  // ── Vista de éxito ─────────────────────────────────────────
  Widget _buildExito() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '¡Correo enviado!',
          style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Revisa tu bandeja de entrada en:\n${_emailCtrl.text.trim()}',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sigue las instrucciones del correo\npara restablecer tu contraseña.',
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OutlinedButton(
          onPressed: () => context.go(AppConstants.routeLogin),
          child: const Text('Volver al inicio de sesión'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() { _enviado = false; _error = null; }),
          child: const Text('Usar otro correo'),
        ),
      ],
    );
  }

  // ── Formulario ─────────────────────────────────────────────
  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Center(
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Ingresa tu correo y te enviaremos\nun enlace para restablecerla.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 36),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviarCorreo(),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarCorreo,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Enviar correo de recuperación'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go(AppConstants.routeLogin),
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
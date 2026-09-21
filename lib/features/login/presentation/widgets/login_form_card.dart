import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
import 'package:wms_app/features/login/presentation/bloc/login_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/auth/auth_buttons.dart';
import 'login_text_field.dart';

/// Tarjeta con el formulario de credenciales. Los controllers y el estado
/// visual (mostrar contraseña) viven aquí, no en el BLoC.
class LoginFormCard extends StatefulWidget {
  const LoginFormCard({super.key});

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;

  /// En Zebra el teclado no siempre se abre al tocar un campo que ya tiene
  /// foco, y cerrar el foco al enviar hace que el IME se comporte mal: se
  /// resuelve una vez (no en cada build).
  late final bool _isZebra = context.read<UserBloc>().fabricante.contains(
    'Zebra',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isZebra) FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    // La conectividad la valida el repositorio (NetworkInfo);
    // si no hay red llega un LoginFailure al listener.
    context.read<LoginBloc>().add(
      LoginButtonPressed(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        database: getIt<IStorageService>().nameDatabase,
      ),
    );
  }

  void _goBack() {
    _passwordController.clear();
    Navigator.pushReplacementNamed(context, 'enterprice');
  }

  GestureTapCallback? _zebraTap(FocusNode node) =>
      _isZebra ? () => FocusScope.of(context).requestFocus(node) : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ingrese sus credenciales de terminal OnPoint',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              LoginTextField(
                label: 'Correo electrónico',
                hint: 'operador@empresa.com',
                icon: Icons.mail_outline,
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onTap: _zebraTap(_emailFocus),
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (value) => Validator.email(value, context),
              ),
              const SizedBox(height: 16),
              LoginTextField(
                label: 'Contraseña',
                hint: '••••••••',
                icon: Icons.lock_outline,
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onTap: _zebraTap(_passwordFocus),
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => Validator.password(value, context),
                suffix: IconButton(
                  tooltip: _isPasswordVisible
                      ? 'Ocultar contraseña'
                      : 'Mostrar contraseña',
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: primaryColorApp,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<LoginBloc, LoginState>(
                buildWhen: (prev, curr) =>
                    (prev is LoginLoading) != (curr is LoginLoading),
                builder: (context, state) {
                  final loading = state is LoginLoading;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthPrimaryButton(
                        label: 'Iniciar Sesión',
                        loading: loading,
                        height: 52,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      AuthSecondaryButton(
                        label: 'Atrás',
                        icon: Icons.arrow_back,
                        onPressed: loading ? null : _goBack,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

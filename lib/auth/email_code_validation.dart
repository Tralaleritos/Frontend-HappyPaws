import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../config/themes/colors/AppColors.dart';
import '../../../services/auth_service.dart';

class EmailCodeValidation extends StatefulWidget {
  @override
  State<EmailCodeValidation> createState() => _EmailCodeValidationState();
}

class _EmailCodeValidationState extends State<EmailCodeValidation> {
  final List<TextEditingController> codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool isCodeValid = false;
  String? errorMessage;

  int resendCountdown = 60;
  Timer? _timer;
  bool canResend = false;

  // Agregar controlador de correo electrónico
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    canResend = false;
    resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (resendCountdown > 0) {
          resendCountdown--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    emailController.dispose();  // Liberar el controlador del email
    _timer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : AppColors.primary,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  String getFullCode() {
    return codeControllers.map((controller) => controller.text).join();
  }

  Future<void> _validateCode() async {
    final enteredCode = getFullCode();
    final email = emailController.text;

    if (enteredCode.length < 6) {
      setState(() {
        errorMessage = "Por favor ingresa el código completo de 6 dígitos";
      });
      _showToast(errorMessage!, isError: true);
      return;
    }

    if (email.isEmpty || !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      setState(() {
        errorMessage = "Por favor ingresa un correo válido";
      });
      _showToast(errorMessage!, isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    final success = await authService.verifyCode(email, enteredCode);

    if (success) {
      setState(() {
        isLoading = false;
        isCodeValid = true;
      });
      _showToast("Código validado correctamente");
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Código incorrecto. Por favor verifica e intenta nuevamente.";
        for (var controller in codeControllers) {
          controller.clear();
        }
        if (focusNodes.isNotEmpty) {
          focusNodes[0].requestFocus();
        }
      });
      _showToast(errorMessage!, isError: true);
    }
  }

  Future<void> _resendCode() async {
    if (!canResend) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resendCode(emailController.text);

    setState(() {
      isLoading = false;
    });

    if (success) {
      startResendTimer();
      _showToast('Código reenviado exitosamente');
    } else {
      _showToast('Error al reenviar el código', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verificación de Código',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.mail_lock, size: 80, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Ingresa el código de verificación',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Correo electrónico",
            hintText: "Ingresa tu correo",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        Text('Hemos enviado un código de 6 dígitos a:', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          emailController.text.isEmpty ? 'Esperando correo...' : emailController.text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildCodeInputs(),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: isLoading ? null : _validateCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text('Verificar Código', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 20),
        _buildResendOption(),
      ],
    );
  }

  Widget _buildCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
            (index) => SizedBox(
          width: 45,
          child: TextFormField(
            controller: codeControllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                focusNodes[index + 1].requestFocus();
              }
              if (index == 5 && value.isNotEmpty) {
                _validateCode();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResendOption() {
    return Column(
      children: [
        Text('¿No recibiste el código?', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextButton(
          onPressed: canResend ? _resendCode : null,
          style: TextButton.styleFrom(
            foregroundColor: canResend ? AppColors.primary : Colors.grey,
          ),
          child: Text(
            canResend ? 'Reenviar código' : 'Reenviar código (${resendCountdown}s)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: canResend ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

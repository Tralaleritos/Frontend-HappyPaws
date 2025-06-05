import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class EmailCodeValidation extends StatefulWidget {
  final String email;
  final Function onCodeValidated;

  const EmailCodeValidation({
    super.key,
    required this.email,
    required this.onCodeValidated,
  });

  @override
  State<EmailCodeValidation> createState() => _EmailCodeValidationState();
}

class _EmailCodeValidationState extends State<EmailCodeValidation> {
  final List<TextEditingController> codeControllers = List.generate(
    6,
        (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    6,
        (index) => FocusNode(),
  );

  bool isLoading = false;
  bool isCodeValid = false;
  String? errorMessage;

  // Contador regresivo para reenvío
  int resendCountdown = 60;
  Timer? _timer;
  bool canResend = false;

  final String mockValidCode = "123456"; // Código simulado

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
    _timer?.cancel();
    super.dispose();
  }

  // Método para mostrar toast
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: isError ? Colors.red : AppColors.primary,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  String getFullCode() {
    return codeControllers.map((controller) => controller.text).join();
  }

  Future<void> _validateCode() async {
    final enteredCode = getFullCode();

    if (enteredCode.length < 6) {
      setState(() {
        errorMessage = "Por favor ingresa el código completo de 6 dígitos";
      });
      _showToast("Por favor ingresa el código completo de 6 dígitos", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Simulación de validación
    await Future.delayed(const Duration(seconds: 2));

    if (enteredCode == mockValidCode) {
      setState(() {
        isLoading = false;
        isCodeValid = true;
      });

      _showToast("Código validado correctamente");

      // Llamamos a la función onCodeValidated que ahora redirigirá a LoginScreen
      widget.onCodeValidated();

      // Ya no es necesario la navegación aquí, ya que se manejará en el callback
      // La función onCodeValidated está configurada en RegisterScreen para navegar a LoginScreen
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "Código incorrecto. Por favor verifica e intenta nuevamente.";

        // Limpiar los campos de código
        for (var controller in codeControllers) {
          controller.clear();
        }

        // Enfocar el primer campo
        if (focusNodes.isNotEmpty) {
          focusNodes[0].requestFocus();
        }
      });

      _showToast("Código incorrecto. Por favor verifica e intenta nuevamente.", isError: true);
    }
  }

  Future<void> _resendCode() async {
    if (!canResend) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    // Reiniciar el contador
    startResendTimer();

    // Mostrar mensaje de éxito con toast
    _showToast('Código reenviado exitosamente');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verificación de Código',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
          ),
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
        const Icon(
          Icons.mail_lock,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Ingresa el código de verificación',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Hemos enviado un código de 6 dígitos a:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.email,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildCodeInputs(),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: isLoading ? null : _validateCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
              : Text(
            'Verificar Código',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
            ),
          ),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                // Mover al siguiente campo
                focusNodes[index + 1].requestFocus();
              }
              // Si borra el último dígito, validar automáticamente
              if (index == 5 && value.isNotEmpty) {
                // Validar automáticamente cuando se completan los 6 dígitos
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
        Text(
          '¿No recibiste el código?',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: canResend ? _resendCode : null,
          style: TextButton.styleFrom(
            foregroundColor: canResend ? AppColors.primary : Colors.grey,
          ),
          child: Text(
            canResend
                ? 'Reenviar código'
                : 'Reenviar código (${resendCountdown}s)',
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
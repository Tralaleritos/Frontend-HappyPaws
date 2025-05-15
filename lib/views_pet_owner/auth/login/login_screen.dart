import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:happyp/views_pet_owner/auth/login/update_password/recovery_password.dart';
import '../../../config/themes/colors/AppColors.dart';
import '../../../data/models/nueva/user_model.dart';

class LoginScreen extends StatefulWidget {
  final Function? onLoginSuccess;

  const LoginScreen({
    Key? key,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isPhoneMode = false;

  // Error message states
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Limpiar errores cuando el usuario comienza a editar
  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  //  iniciar sesión con email y contraseña
  Future<void> _signInWithEmailAndPassword() async {
    // Restablecer los mensajes de error
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String email = _emailController.text;
        final String password = _passwordController.text;

        // Llamar al servicio para autenticar al usuario
        final User? user = await UserService().login(email, password);

        if (user != null) {
          // Si el usuario existe, navegar al home de cuidador
          if (mounted) {
            widget.onLoginSuccess?.call(); //
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Mostrar mensajes de error específicos
          setState(() {
            _emailError = 'Correo no autenticado';
            _passwordError = 'Contraseña incorrecta';
          });
        }
      } catch (e) {
        // Mostrar error más específico en lugar de toast general
        setState(() {
          _emailError = 'No se pudo verificar este correo';
          _passwordError = 'No pudimos verificar tus credenciales';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Método para cambiar entre modo email y teléfono
  void _toggleInputMode() {
    setState(() {
      _isPhoneMode = !_isPhoneMode;
      _emailController.clear();
      _emailError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.tertiary,
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 130,
                            height: 130,
                            margin: EdgeInsets.only(bottom: 1),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logos/happyPawsTransparente.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Happy Paws',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Selector de modo Email/Número con tabs
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tab Email
                              GestureDetector(
                                onTap: () {
                                  if (_isPhoneMode) {
                                    _toggleInputMode();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: !_isPhoneMode ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: !_isPhoneMode ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tab Número
                              GestureDetector(
                                onTap: () {
                                  if (!_isPhoneMode) {
                                    _toggleInputMode();
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _isPhoneMode ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Número',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isPhoneMode ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Etiqueta para Email/Teléfono
                          Padding(
                            padding: const EdgeInsets.only(left: 5, bottom: 8),
                            child: Text(
                              _isPhoneMode ? 'Teléfono' : 'Correo electrónico',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          if (_isPhoneMode)
                          // Modo teléfono
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 15),
                                  onChanged: (_) => _clearErrors(),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(9),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '999 999 999',
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade400
                                    ),
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        '+51 |',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(minWidth: 60),
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    errorStyle: TextStyle(height: 0, fontSize: 0), // Ocultar el error predeterminado
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() => _emailError = 'Por favor ingresa tu número de teléfono');
                                      return '';
                                    }
                                    if (value.length < 9) {
                                      setState(() => _emailError = 'Ingresa un número de 9 dígitos');
                                      return '';
                                    }
                                    return null;
                                  },
                                ),
                                if (_emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 4),
                                    child: Text(
                                      _emailError!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else
                          // Modo email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 15),
                                  onChanged: (_) => _clearErrors(),
                                  decoration: InputDecoration(
                                    hintText: 'ejemplo@correo.com',
                                    hintStyle: TextStyle(
                                        color: Colors.grey.shade400
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    errorStyle: TextStyle(height: 0, fontSize: 0), // Ocultar el error predeterminado
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() => _emailError = 'Por favor ingresa tu correo electrónico');
                                      return '';
                                    }
                                    if (!_isPhoneMode && !EmailValidator.validate(value)) {
                                      setState(() => _emailError = 'Ingresa un correo electrónico válido');
                                      return '';
                                    }
                                    return null;
                                  },
                                ),
                                if (_emailError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 4),
                                    child: Text(
                                      _emailError!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          // Etiqueta contraseña
                          Padding(
                            padding: const EdgeInsets.only(left: 5, bottom: 8),
                            child: Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(fontSize: 15),
                                onChanged: (_) => _clearErrors(),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outlined,
                                    size: 20,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  errorStyle: TextStyle(height: 0, fontSize: 0), // Ocultar el error predeterminado
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    setState(() => _passwordError = 'Por favor ingresa tu contraseña');
                                    return '';
                                  }
                                  if (value.length < 6) {
                                    setState(() => _passwordError = 'La contraseña debe tener al menos 6 caracteres');
                                    return '';
                                  }
                                  return null;
                                },
                              ),
                              if (_passwordError != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 4),
                                  child: Text(
                                    _passwordError!,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                final currentEmail = _emailController.text;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecoveryPassword(
                                      email: currentEmail,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.3),
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        SizedBox(height: 8,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'O ',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),

                    /*const SizedBox(height: 20),

                    _buildGoogleButton(
                      onPressed: _signInWithGoogle,
                    ),*/
                    const SizedBox(height: 25),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        children: [
                          const TextSpan(text: '¿No tienes una cuenta? '),
                          TextSpan(
                            text: 'Regístrate',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/register');
                              },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Botón de Google
  /*Widget _buildGoogleButton({required VoidCallback onPressed}) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.google,
                color: Colors.red,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}
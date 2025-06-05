import 'package:flutter/material.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedRole;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final authService = Provider.of<AuthService>(context, listen: false);

      // Mostramos un loading mientras hacemos la solicitud
      showDialog(
        context: context,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final phone = _phoneController.text.trim();
      final registered = await authService.register(name, email, password, phone, _selectedRole!);

      Navigator.pop(context); // Cierra el loading

      if (registered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
        Navigator.pushReplacementNamed(context, '/inicio');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este correo ya está en uso o hubo un error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/images/logos/happyPaws_trans_log_text.png', height: 150),
                Text('Crea tu cuenta', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Text('Únete a nuestra comunidad de amantes de mascotas', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 10),

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Nombre', Icons.person_outline),
                  validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa tu nombre' : null,
                ),
                const SizedBox(height: 8),

                // Apellido
                TextFormField(
                  controller: _surnameController,
                  decoration: _inputDecoration('Apellidos', Icons.person_outline),
                  validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa tus apellidos' : null,
                ),
                const SizedBox(height: 8),

                // Correo
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor ingresa tu correo';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    return !regex.hasMatch(value) ? 'Correo inválido' : null;
                  },
                ),
                const SizedBox(height: 8),

                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Teléfono celular', Icons.phone_android),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor ingresa tu número celular';
                    return value.length < 8 ? 'Número inválido' : null;
                  },
                ),
                const SizedBox(height: 8),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecorationWithToggle('Contraseña', Icons.lock_outline, () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  }, _obscurePassword),
                  validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 8),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecorationWithToggle('Confirmar contraseña', Icons.lock_outline, () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  }, _obscureConfirmPassword),
                  validator: (value) => value != _passwordController.text ? 'No coinciden' : null,
                ),
                const SizedBox(height: 8),

                // Rol
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Tipo de cuenta', Icons.person),
                  items: const [
                    DropdownMenuItem(value: 'OWNER', child: Text('Dueño de mascota')),
                    DropdownMenuItem(value: 'CARETAKER', child: Text('Cuidador')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  value: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) => value == null ? 'Selecciona un tipo de cuenta' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text('Registrarse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.grey[700]),
                      children: [
                        TextSpan(
                          text: 'Inicia sesión',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  InputDecoration _inputDecorationWithToggle(
      String label,
      IconData icon,
      VoidCallback toggle,
      bool obscure,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: toggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}



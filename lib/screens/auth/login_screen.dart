import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'registration_success_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        if (_isSignUp) {
          await authProvider.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
          
          if (mounted) {
            // Başarılı kayıt sonrası onay ekranına yönlendir
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationSuccessScreen(
                  email: _emailController.text.trim(),
                  name: _nameController.text.trim(),
                ),
              ),
            );
            
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          await authProvider.signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'LinkedIn',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                if (_isSignUp)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen ad soyad girin';
                      }
                      if (value.trim().split(' ').length < 2) {
                        return 'Lütfen ad ve soyadınızı girin';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen email adresinizi girin';
                    }
                    // Gelişmiş email doğrulaması
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Geçerli bir email adresi girin';
                    }
                    // Kayıt olurken gmail kontrolü
                    if (_isSignUp && !value.toLowerCase().endsWith('@gmail.com')) {
                      return 'Geçersiz e-posta. Lütfen bir Gmail adresi kullanın';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    if (_isSignUp && !RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Şifre en az bir rakam içermelidir';
                    }
                    return null;
                  },
                  textInputAction: _isSignUp 
                      ? TextInputAction.next 
                      : TextInputAction.done,
                ),
                const SizedBox(height: 24),
                if (_isSignUp) 
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      children: [
                        TextSpan(text: 'Kayıt olarak '),
                        TextSpan(
                          text: 'Kullanım Koşulları',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Gizlilik Politikasını',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' kabul etmiş olursunuz.'),
                      ],
                    ),
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isSignUp ? 'Kayıt Ol' : 'Giriş Yap',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_isSignUp)
                  TextButton(
                    onPressed: () {
                      // Şifremi unuttum işlevselliği
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Şifre sıfırlama özelliği yakında eklenecek!'),
                        ),
                      );
                    },
                    child: const Text('Şifremi Unuttum'),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp 
                          ? 'Zaten hesabınız var mı?' 
                          : 'Hesabınız yok mu?'
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                _formKey.currentState?.reset();
                              });
                            },
                      child: Text(
                        _isSignUp ? 'Giriş Yap' : 'Kayıt Ol',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_isSignUp)
                  TextButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).signInWithDemo();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Demo Hesapla Giriş Yap'),
                  ),
                if (!_isSignUp)
                  TextButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).signInAsAdmin();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Olarak Giriş Yap'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
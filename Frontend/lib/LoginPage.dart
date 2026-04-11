import 'package:flutter/material.dart';
import 'auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.login(
          context: context,
          email: _emailCtrl.text.trim(),
        );
      } else {
        await AuthService.register(
          context: context,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggle() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _emailCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner image
                      SizedBox(
                        height: h * 0.45,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/login_banner.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: h * 0.03, vertical: h * 0.03),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLogin
                                    ? 'Welcome Back 👋'
                                    : 'Create Account ✨',
                                style: TextStyle(
                                    fontSize: h * 0.028,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A1A2E)),
                              ),
                              SizedBox(height: h * 0.005),
                              Text(
                                _isLogin
                                    ? 'Sign in to continue'
                                    : 'Register to get started',
                                style: TextStyle(
                                    fontSize: h * 0.016,
                                    color: Colors.grey),
                              ),

                              SizedBox(height: h * 0.025),

                              // Name — register only
                              if (!_isLogin) ...[
                                _buildField(
                                  controller: _nameCtrl,
                                  hint: 'Full Name',
                                  icon: Icons.person_outline_rounded,
                                  h: h,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Enter your name'
                                          : null,
                                ),
                                SizedBox(height: h * 0.018),
                              ],

                              // Email
                              _buildField(
                                controller: _emailCtrl,
                                hint: 'Email Address',
                                icon: Icons.email_outlined,
                                h: h,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Enter your email';
                                  if (!v.contains('@'))
                                    return 'Enter a valid email';
                                  return null;
                                },
                              ),

                              SizedBox(height: h * 0.025),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: h * 0.065,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFE91E8C),
                                    disabledBackgroundColor:
                                        const Color(0xFFE91E8C)
                                            .withOpacity(0.7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                h * 0.012)),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: h * 0.028,
                                          width: h * 0.028,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Login' : 'Register',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: h * 0.02,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                ),
                              ),

                              SizedBox(height: h * 0.02),

                              // Toggle
                              Center(
                                child: GestureDetector(
                                  onTap: _isLoading ? null : _toggle,
                                  child: RichText(
                                    text: TextSpan(
                                      style:
                                          TextStyle(fontSize: h * 0.016),
                                      children: [
                                        TextSpan(
                                          text: _isLogin
                                              ? "Don't have an account? "
                                              : 'Already have an account? ',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        TextSpan(
                                          text: _isLogin
                                              ? 'Register'
                                              : 'Login',
                                          style: const TextStyle(
                                              color: Color(0xFFE91E8C),
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: h * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Full screen loading overlay
          if (_isLoading)
            const Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double h,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: h * 0.018),
      validator: validator,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey, fontSize: h * 0.016),
        prefixIcon:
            Icon(icon, color: Colors.grey, size: h * 0.022),
        contentPadding:
            EdgeInsets.symmetric(vertical: h * 0.018),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(h * 0.012),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(h * 0.012),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(h * 0.012),
          borderSide: const BorderSide(
              color: Color(0xFFE91E8C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(h * 0.012),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late FocusNode _phoneFocusNode;
  late ScrollController _scrollController;
  final GlobalKey _phoneFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _phoneFocusNode = FocusNode();
    _scrollController = ScrollController();
    _phoneFocusNode.addListener(_scrollToPhoneField);
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_scrollToPhoneField);
    _phoneFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPhoneField() {
    if (_phoneFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final ctx = _phoneFieldKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.8, // scroll so field appears near bottom
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return AuthLoadingWrapper(
      child: Scaffold(
        backgroundColor: Colors.white,
        // Keep true so the scaffold shrinks when the keyboard appears,
        // giving SingleChildScrollView room to scroll up
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              // Ensures the Column fills at least the visible screen height,
              // so content doesn't collapse at the top when keyboard is hidden
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 60% image section — uses a fixed fraction of screen height,
                    // not the layout height, so it stays stable as keyboard opens
                    SizedBox(
                      height: h * 0.6,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/login_banner.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Bottom content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: h * 0.03,
                        vertical: h * 0.04,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            height: h * 0.065,
                            child: ElevatedButton(
                              onPressed: () async {
                                await AuthService.signInWithGoogle(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E8C),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(h * 0.012),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: h * 0.03,
                                    width: h * 0.03,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                  ),
                                  SizedBox(width: h * 0.015),
                                  Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: h * 0.02,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.02),

                          // --- Or --- divider
                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: h * 0.015),
                                child: Text(
                                  'Or',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: h * 0.018,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(thickness: 1)),
                            ],
                          ),

                          SizedBox(height: h * 0.02),

                          // Phone number input — keyed so ensureVisible can find it
                          TextFormField(
                            key: _phoneFieldKey,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: TextStyle(fontSize: h * 0.02),
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              hintStyle: TextStyle(fontSize: h * 0.018),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: h * 0.018),
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: h * 0.015,
                                  vertical: h * 0.015,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇮🇳',
                                        style:
                                            TextStyle(fontSize: h * 0.025)),
                                    SizedBox(width: h * 0.008),
                                    Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: h * 0.02,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: h * 0.01),
                                    SizedBox(
                                      height: h * 0.03,
                                      child: const VerticalDivider(
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(h * 0.012),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(h * 0.012),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),

                          // Bottom padding so the field isn't flush against
                          // the keyboard on very small devices
                          SizedBox(height: h * 0.03),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
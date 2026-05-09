import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';


class ResetPasswordScreen1 extends StatefulWidget {
  const ResetPasswordScreen1({super.key});

  @override
  State<ResetPasswordScreen1> createState() => _ResetPasswordScreen1State();
}

class _ResetPasswordScreen1State extends State<ResetPasswordScreen1> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenHeight * 0.05,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight * 0.85,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: screenHeight * 0.04),

                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.22,
                        height: screenWidth * 0.22,
                        child: Image.asset(
                          'assets/images/blue_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Text(
                        'Reset Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.08,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.07),

                Text(
                  'Enter your Email:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: screenHeight * 0.012),

                _buildTextField(
                  controller: emailController,
                  hintText: 'Email@domain.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: screenHeight * 0.04),

                _buildPrimaryButton(
                  text: 'Send',
                  onTap: () async {
                    final email = emailController.text.trim();

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your email")),
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reset link sent to your email"),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message ?? "Error")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton({required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDFDFDF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38B6FF)),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF38B6FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
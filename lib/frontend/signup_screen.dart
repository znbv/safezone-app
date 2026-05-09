import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),

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
                  'Join Safe Zone!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                Text(
                  "Create an account to monitor and protect your child’s safety",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                _buildTextField(
                  controller: usernameController,
                  hintText: 'Username',
                ),

                SizedBox(height: screenHeight * 0.018),

                _buildTextField(
                  controller: emailController,
                  hintText: 'Email@domain.com',
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: screenHeight * 0.018),

                _buildTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: isPasswordHidden,
                  onToggleVisibility: () {
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.018),

                _buildTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: isConfirmPasswordHidden,
                  onToggleVisibility: () {
                    setState(() {
                      isConfirmPasswordHidden = !isConfirmPasswordHidden;
                    });
                  },
                ),

                SizedBox(height: screenHeight * 0.03),
                _buildPrimaryButton(
                 text: 'Sign up',
                  onTap: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final confirmPassword = confirmPasswordController.text.trim();
                    final username = usernameController.text.trim();

                    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || username.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter all details")),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Passwords do not match")),
                      );
                      return;
                    }

                    try {
                      UserCredential userCredential =
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

          
                      if (userCredential.user != null) {
                        await userCredential.user!.updateDisplayName(username);
                        await userCredential.user!.reload();
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Account created successfully!")),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );

                    } on FirebaseAuthException catch (e) {
      
                      print("Firebase Error: ${e.code}");

                      String message;

                      switch (e.code) {
                        case 'email-already-in-use':
                          message = "Email already in use";
                          break;
                        case 'weak-password':
                          message = "Password is too weak (min 6 chars)";
                          break;
                        case 'invalid-email':
                          message = "Invalid email format";
                          break;
                        case 'operation-not-allowed':
                          message = "Email/password accounts are not enabled";
                          break;
                        default:
                          message = "Error: ${e.code}";
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    } catch (e) {
                      print("Unknown Error: $e");

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Unexpected error occurred")),
                      );
                    }
                  }
                ),
                SizedBox(height: screenHeight * 0.03),

                 GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: "Log in",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
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
        suffixIcon: onToggleVisibility != null
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
              )
            : null,
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
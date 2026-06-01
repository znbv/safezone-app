import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'reset_password_screen1.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      });
    }
  }
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return; // User canceled the Google sign-in popup
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in failed';

      if (e.code == 'account-exists-with-different-credential') {
        message = 'An account already exists with a different sign-in method';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid Google credentials';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("GOOGLE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

// catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Google sign-in failed')),
//       );
//     }
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
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Login to SafeZone',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
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
                SizedBox(height: screenHeight * 0.01),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordScreen1(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
                _buildPrimaryButton(
                  text: 'Log in',
                  onTap: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter email and password")),
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );

                    } on FirebaseAuthException catch (e) {
                      print("ERROR CODE: ${e.code}"); // for debugging

                      String message = "Login failed";

                      if (e.code == 'invalid-email') {
                        message = "Invalid email format";
                      } else if (e.code == 'too-many-requests') {
                        message = "Too many attempts. Try again later";
                      } else if (e.code == 'invalid-credential') {
                        message = "Invalid email or password";
                      } else if (e.code == 'user-disabled') {
                        message = "This account has been disabled";
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Something went wrong")),
                      );
                    }
                  },
                ),
                SizedBox(height: screenHeight * 0.018),
                _buildGoogleButton(
                  onTap: _signInWithGoogle,
                ),
                SizedBox(height: screenHeight * 0.04),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildGoogleButton({
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
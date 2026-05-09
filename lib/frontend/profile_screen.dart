import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String displayName = 'User';

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    nameController.text = user?.displayName ?? '';
    emailController.text = user?.email ?? '';

    displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'User';
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  bool get isEmailPasswordUser {
    final user = FirebaseAuth.instance.currentUser;

    return user?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
  }

  void _handleMenuSelection(String value) {
    if (value == 'reset') {
      _sendPasswordResetEmail();
    } else if (value == 'delete') {
      _showDeleteDialog();
    } else if (value == 'logout') {
      _logout();
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No email found for this account")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to send reset link")),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout successful")),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showDeleteDialog() {
    final TextEditingController deletePasswordController =
        TextEditingController();

    bool isDeletePasswordHidden = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter your password to confirm deletion'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deletePasswordController,
                    obscureText: isDeletePasswordHidden,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            isDeletePasswordHidden = !isDeletePasswordHidden;
                          });
                        },
                        icon: Icon(
                          isDeletePasswordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFDFDFDF),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF38B6FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    deletePasswordController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final enteredPassword =
                        deletePasswordController.text.trim();

                    if (enteredPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter your password"),
                        ),
                      );
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user != null && user.email != null) {
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: enteredPassword,
                        );

                        await user.reauthenticateWithCredential(credential);
                        await user.delete();

                        deletePasswordController.dispose();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account deleted successfully"),
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String message = "An error occurred";

                      if (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential') {
                        message = "Incorrect password";
                      } else if (e.code == 'requires-recent-login') {
                        message =
                            "Please log in again before deleting your account";
                      }

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("An error occurred")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final newName = nameController.text.trim();

    if (user == null || user.email == null) return;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      await user.updateDisplayName(newName);
      await user.reload();

      setState(() {
        displayName = newName;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();

    bool isCurrentPasswordHidden = true;
    bool isNewPasswordHidden = true;
    bool isConfirmPasswordHidden = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogPasswordField(
                      controller: currentPasswordController,
                      hintText: 'Current Password',
                      obscureText: isCurrentPasswordHidden,
                      onToggleVisibility: () {
                        setDialogState(() {
                          isCurrentPasswordHidden = !isCurrentPasswordHidden;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogPasswordField(
                      controller: newPasswordController,
                      hintText: 'New Password',
                      obscureText: isNewPasswordHidden,
                      onToggleVisibility: () {
                        setDialogState(() {
                          isNewPasswordHidden = !isNewPasswordHidden;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogPasswordField(
                      controller: confirmNewPasswordController,
                      hintText: 'Confirm New Password',
                      obscureText: isConfirmPasswordHidden,
                      onToggleVisibility: () {
                        setDialogState(() {
                          isConfirmPasswordHidden = !isConfirmPasswordHidden;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final currentPassword =
                        currentPasswordController.text.trim();
                    final newPassword = newPasswordController.text.trim();
                    final confirmNewPassword =
                        confirmNewPasswordController.text.trim();

                    if (currentPassword.isEmpty ||
                        newPassword.isEmpty ||
                        confirmNewPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all password fields'),
                        ),
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'New password must be at least 6 characters',
                          ),
                        ),
                      );
                      return;
                    }

                    if (newPassword != confirmNewPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New passwords do not match'),
                        ),
                      );
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null || user.email == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No logged-in user found'),
                          ),
                        );
                        return;
                      }

                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPassword);

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully'),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String message = 'Failed to update password';

                      if (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential') {
                        message = 'Current password is incorrect';
                      } else if (e.code == 'weak-password') {
                        message = 'New password is too weak';
                      } else if (e.code == 'requires-recent-login') {
                        message =
                            'Please log in again before updating your password';
                      }

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Something went wrong'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFDFDFDF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF38B6FF),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.08,
            vertical: h * 0.04,
          ),
          child: Column(
            children: [
              _buildTopBar(),
              SizedBox(height: h * 0.03),
              Text(
                'Profile Info',
                style: TextStyle(
                  fontSize: w * 0.085,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: h * 0.025),
              CircleAvatar(
                radius: 38,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: h * 0.015),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: w * 0.08,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2E2E),
                ),
              ),
              SizedBox(height: h * 0.05),
              _buildTextField(
                controller: nameController,
                hintText: 'Name',
              ),
              SizedBox(height: h * 0.018),
              _buildTextField(
                controller: emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              SizedBox(height: h * 0.018),
              _buildPasswordSummaryCard(),
              SizedBox(height: h * 0.04),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFBDBDBD),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuSelection,
          icon: const Icon(
            Icons.more_vert,
            color: Colors.black,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          itemBuilder: (context) => [
            if (isEmailPasswordUser)
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset Password'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Account'),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordSummaryCard() {
    if (!isEmailPasswordUser) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Password is managed by your sign-in provider.',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFDFDFDF),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Password\n••••••••',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: _showChangePasswordDialog,
            child: const Text(
              'Change',
              style: TextStyle(
                color: Color(0xFF38B6FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontSize: 14,
        ),
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF7F7F7) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFDFDFDF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF38B6FF),
          ),
        ),
      ),
    );
  }
}
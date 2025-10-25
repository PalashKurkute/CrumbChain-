import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signup_page.dart';
import '../services/auth_service.dart';
import '../services/google_signin_service.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import 'donor_home_page.dart';
import 'receiver_home_page.dart';
import 'driver_home_page.dart';

class LoginPage extends StatefulWidget {
  final String userType; // 'donor' or 'receiver'

  const LoginPage({super.key, required this.userType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _googleSignInService = GoogleSignInService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting Google Sign-In for ${widget.userType}...');

      final user = await _googleSignInService.signInWithGoogle(widget.userType);

      if (!mounted) return;

      if (user != null) {
        print('✅ Google Sign-In successful, navigating...');

        // Navigate to appropriate home page based on user type
        if (user.isDonor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DonorHomePage(user: user)),
          );
        } else if (user.isReceiver) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiverHomePage(user: user),
            ),
          );
        } else if (user.isDriver) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverHomePage(user: user),
            ),
          );
        }
      } else {
        print('❌ Google Sign-In cancelled');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      if (!mounted) return;

      // Check if it's a configuration error
      String errorMessage = 'Google Sign-In failed';
      if (e.toString().contains('PlatformException') ||
          e.toString().contains('sign_in_failed') ||
          e.toString().contains('DEVELOPER_ERROR')) {
        errorMessage =
            'Google Sign-In not configured. Please use email/password login.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    // Validate inputs
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final user = result['user'] as User;

        // Navigate to appropriate home page based on user type
        if (user.isDonor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DonorHomePage(user: user)),
          );
        } else if (user.isReceiver) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiverHomePage(user: user),
            ),
          );
        } else if (user.isDriver) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DriverHomePage(user: user),
            ),
          );
        }
      } else {
        // Show error message
        String errorMessage = result['message'] ?? 'Login failed';

        // Check for connection errors
        if (errorMessage.contains('Connection') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('SocketException')) {
          errorMessage =
              'Cannot connect to server.\nPlease check:\n'
              '• Backend is running\n'
              '• You are on the same WiFi network\n'
              '• IP address is correct: 10.9.31.173';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Detailed error handling
      String errorMessage = 'Error: ${e.toString()}';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage =
            'Network Error!\n\n'
            'Cannot reach server at 10.9.31.173:5000\n\n'
            'Checklist:\n'
            '✓ Backend server is running\n'
            '✓ Phone and computer on same WiFi\n'
            '✓ IP address is correct\n'
            '✓ No firewall blocking connection';
      } else if (e.toString().contains('timeout')) {
        errorMessage =
            'Connection Timeout!\n\n'
            'Server is not responding.\n'
            'Please ensure backend is running.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Connection Refused!\n\n'
            'Backend server is not running on:\n'
            'http://10.9.31.173:5000\n\n'
            'Start the server with: python app.py';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'CLOSE',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final testUrl = '${ApiConfig.baseUrl}${ApiConfig.health}';
      print('🧪 Testing connection to: $testUrl');

      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Connection successful!\nServer: ${ApiConfig.baseUrl}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Server responded with status: ${response.statusCode}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = '❌ Connection Failed!\n\n';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage +=
            'Cannot reach server at:\n${ApiConfig.baseUrl}\n\n'
            'Check:\n'
            '• Backend running (python app.py)\n'
            '• Same WiFi network\n'
            '• IP: 10.9.31.173';
      } else if (e.toString().contains('timeout')) {
        errorMessage +=
            'Server not responding\n\n'
            'Backend may not be running at:\n${ApiConfig.baseUrl}';
      } else {
        errorMessage += e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEFDD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Top Section - Cream Background with Logo
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFCEFDD),
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.volunteer_activism,
                              size: 120,
                              color: Color(0xFFE07A3E),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Section - White Background with Form
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),

                            // Welcome Back Text
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Name or Email Input
                            Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFBDBDBD),
                              width: 2,
                            ),
                          ),
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Name Or Email',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                            // Password Input
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFBDBDBD),
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Navigate to forgot password page
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Forgot Password clicked'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 3,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Divider with "or"
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[400],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Google Sign In Button
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                icon: Image.asset(
                                  'assets/images/googlelogo.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 32,
                                      color: Colors.blue,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Sign Up Text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account ",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SignUpPage(userType: widget.userType),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Test Connection Button (for debugging)
                            TextButton.icon(
                              onPressed: _isLoading ? null : _testConnection,
                              icon: const Icon(
                                Icons.wifi_find,
                                size: 18,
                                color: Colors.grey,
                              ),
                              label: const Text(
                                'Test Server Connection',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

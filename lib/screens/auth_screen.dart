import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/web_push_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shadowNameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shadowNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final shadowName = _shadowNameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (!_isLogin && shadowName.isEmpty) {
      setState(() {
        _error = 'Please choose a shadow_name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final client = Supabase.instance.client;

    try {
      if (_isLogin) {
        await client.auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await client.auth.signUp(
          email: email,
          password: password,
        );
        final user = response.user ?? client.auth.currentUser;
        if (user != null) {
          try {
            await client.from('profiles').insert({
              'id': user.id,
              'shadow_name': shadowName,
            });
          } catch (e) {
            // Handle duplicate shadow_name or other profile errors.
            final msg = e.toString();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    msg.contains('duplicate') || msg.contains('Unique')
                        ? 'That shadow_name is taken. Please pick another.'
                        : 'Could not create profile: $msg',
                  ),
                ),
              );
            }
            // Do not proceed to app if profile creation failed.
            return;
          }
        }
      }
      final authedUser = client.auth.currentUser;
      if (authedUser != null) registerWebPush(authedUser.id);
      widget.onAuthenticated();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Shadow-Comm',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Login to your shadow' : 'Create a new shadow',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _shadowNameController,
                  decoration: const InputDecoration(
                    labelText: 'shadow_name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? 'Login' : 'Sign up'),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _error = null;
                        });
                      },
                child: Text(
                  _isLogin
                      ? "Don't have a shadow? Sign up"
                      : "Already have a shadow? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

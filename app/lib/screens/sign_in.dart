import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Start waking the server immediately. The free host sleeps after ~15 min
    // idle, so doing this while the user types their login hides most of the
    // cold-start delay that used to hit on "Start Workout".
    ApiService.warmUp();
  }

  void login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (email == 'hi' && password == 'hi') {
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('loggedIn', true);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/workout_plan');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter email" : null,
                onSaved: (v) => email = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter password" : null,
                onSaved: (v) => password = v!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) => setState(() => rememberMe = val!),
                  ),
                  const Text("Remember Me",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: login,
                child: const Text("Sign In"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

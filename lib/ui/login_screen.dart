import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Title
              const Icon(Icons.games, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Caro Chess',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 48),

              // Guest Login Button
              BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                   if (state is GameAuthLoading) {
                     return const Center(child: CircularProgressIndicator());
                   }
                   return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<GameBloc>().add(LoginAsGuest());
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Play as Guest'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Social Logins (Disabled/Placeholder)
              _buildSocialButton(
                text: 'Sign in with Google',
                icon: Icons.g_mobiledata, // Placeholder icon
                onPressed: null, // Disabled
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                text: 'Sign in with Apple',
                icon: Icons.apple,
                onPressed: null, // Disabled
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                text: 'Sign in with Facebook',
                icon: Icons.facebook,
                onPressed: null, // Disabled
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Apple (Placeholder)
            _buildSocialButton(
              onTap: () {
                // Future Implementation
              },
              assetPath: "assets/icon/apple.svg",
            ),

            const SizedBox(width: 20),

            // Google (Functional)
            _buildSocialButton(
              onTap: isLoading
                  ? null
                  : () {
                      context.read<AuthCubit>().signInWithGoogle();
                    },
              assetPath: "assets/icon/google.svg",
              isLoading: state is AuthLoading && state.isGoogle,
            ),

            const SizedBox(width: 20),

            // Facebook (Placeholder)
            _buildSocialButton(
              onTap: () {
                // Future Implementation
              },
              assetPath: "assets/icon/facebook.svg",
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onTap,
    required String assetPath,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : SvgPicture.asset(assetPath, width: 32, height: 32),
      ),
    );
  }
}

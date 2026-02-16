// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../cubit/auth_cubit.dart';
// import '../cubit/auth_state.dart';

// class GoogleSignInButton extends StatelessWidget {
//   const GoogleSignInButton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AuthCubit, AuthState>(
//       builder: (context, state) {
//         final isLoading = state is AuthLoading;
//         return OutlinedButton(
//           onPressed: isLoading
//               ? null
//               : () {
//                   context.read<AuthCubit>().signInWithGoogle();
//                 },
//           style: OutlinedButton.styleFrom(
//             backgroundColor: Colors.white,
//             foregroundColor: Colors.black87,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             side: BorderSide.none,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Placeholder for Google Logo - Using a colorful G if possible or Icon
//               // Since we don't have assets, we'll try to mimic it or use a public URL if strictly needed.
//               // For robustness, let's use a Text representation or generic icon if offline.
//               // But 'Professional' usually implies the real logo.
//               // We will use a network image with a fallback.
//               Image.network(
//                 "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png",
//                 height: 24,
//                 width: 24,
//                 errorBuilder: (context, error, stackTrace) =>
//                     const Icon(Icons.public, color: Colors.blue, size: 24),
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return const SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   );
//                 },
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 "Sign in with Google",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

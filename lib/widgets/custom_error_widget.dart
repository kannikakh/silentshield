import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../routes/app_routes.dart';

class CustomErrorWidget extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;

  const CustomErrorWidget({
    super.key,
    this.errorDetails,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {

    // ignore: unused_local_variable
    final theme = Theme.of(context);

    return Scaffold(

      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(

        child: Center(

          child: Padding(

            padding: const EdgeInsets.all(24.0),

            child: Column(

              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.center,

              children: [

                // SOS ICON
                Container(

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    color: Colors.red.withOpacity(0.1),

                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.emergency,
                    color: Colors.red,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 24),

                // TITLE
                const Text(

                  "Emergency Service Activated",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 12),

                // DESCRIPTION
                const Text(

                  "Your SOS request is being processed.\nEmergency contacts and services will be notified shortly.",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 32),

                // LOADING INDICATOR
                const CircularProgressIndicator(),

                const SizedBox(height: 40),

                // BUTTON
                ElevatedButton.icon(

                  onPressed: () {

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.initial,
                      (route) => false,
                    );
                  },

                  icon: const Icon(
                    Icons.home,
                    size: 18,
                    color: Colors.white,
                  ),

                  label: const Text(
                    'Return Home',
                  ),

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.red,

                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
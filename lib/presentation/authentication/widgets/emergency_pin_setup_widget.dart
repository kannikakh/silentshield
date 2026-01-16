import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Emergency PIN setup widget for SOS cancellation.
/// Provides 4-digit PIN entry with confirmation and haptic feedback.
class EmergencyPinSetupWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const EmergencyPinSetupWidget({super.key, required this.onComplete});

  @override
  State<EmergencyPinSetupWidget> createState() =>
      _EmergencyPinSetupWidgetState();
}

class _EmergencyPinSetupWidgetState extends State<EmergencyPinSetupWidget> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _focusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _showConfirmation = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _focusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  /// Handle PIN completion
  void _handlePinComplete(String pin) {
    if (!_showConfirmation) {
      HapticFeedback.lightImpact();
      setState(() {
        _showConfirmation = true;
        _errorMessage = null;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        _confirmFocusNode.requestFocus();
      });
    } else {
      _handleConfirmPinComplete(pin);
    }
  }

  /// Handle confirmation PIN completion
  void _handleConfirmPinComplete(String confirmPin) {
    if (_pinController.text == confirmPin) {
      HapticFeedback.mediumImpact();
      widget.onComplete();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPinController.clear();
      });
    }
  }

  /// Handle back button
  void _handleBack() {
    if (_showConfirmation) {
      setState(() {
        _showConfirmation = false;
        _errorMessage = null;
        _confirmPinController.clear();
      });
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          _buildHeader(theme),
          SizedBox(height: 6.h),
          _buildInstructions(theme),
          SizedBox(height: 4.h),
          if (_errorMessage != null) _buildErrorMessage(theme),
          _buildPinInput(theme),
          SizedBox(height: 4.h),
          if (_showConfirmation) _buildBackButton(theme),
        ],
      ),
    );
  }

  /// Build header
  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: CustomIconWidget(
            iconName: 'pin',
            color: theme.colorScheme.primary,
            size: 10.w,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _showConfirmation ? 'Confirm Emergency PIN' : 'Set Emergency PIN',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build instructions
  Widget _buildInstructions(ThemeData theme) {
    return Text(
      _showConfirmation
          ? 'Re-enter your 4-digit PIN to confirm'
          : 'Create a 4-digit PIN to cancel SOS alerts in emergency situations',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build error message
  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: theme.colorScheme.error,
            size: 5.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build PIN input
  Widget _buildPinInput(ThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 15.w,
      height: 15.w,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
    );

    return Pinput(
      controller: _showConfirmation ? _confirmPinController : _pinController,
      focusNode: _showConfirmation ? _confirmFocusNode : _focusNode,
      length: 4,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      obscureText: true,
      obscuringCharacter: '●',
      keyboardType: TextInputType.number,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      onCompleted: _handlePinComplete,
      autofocus: true,
    );
  }

  /// Build back button
  Widget _buildBackButton(ThemeData theme) {
    return TextButton.icon(
      onPressed: _handleBack,
      icon: CustomIconWidget(
        iconName: 'arrow_back',
        color: theme.colorScheme.primary,
        size: 5.w,
      ),
      label: Text(
        'Change PIN',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/constants.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../../../../l10n/app_localizations.dart';

class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final _messageController = TextEditingController();
  String? _selectedType;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.feedbackStatus != current.feedbackStatus,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        if (state.feedbackStatus == FeedbackStatus.success) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.thankYou),
                ],
              ),
              content: Text(
                l10n.feedbackThankYouMessage,
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop dialog
                      Navigator.pop(this.context); // Pop FeedbackView
                    },
                    child: Text(
                      l10n.done,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          context.read<SettingsCubit>().resetFeedbackStatus();
        } else if (state.feedbackStatus == FeedbackStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: ${state.feedbackErrorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          context.read<SettingsCubit>().resetFeedbackStatus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.submitFeedback),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.feedbackHeader,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.feedbackHeaderSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Feedback Type Dropdown
              _buildLabel(context, AppLocalizations.of(context)!.feedbackType),
              const SizedBox(height: 8),
              _buildDropdown(context),

              const SizedBox(height: 24),

              // Feedback Message Field
              _buildLabel(
                context,
                AppLocalizations.of(context)!.howCanWeImprove,
              ),
              const SizedBox(height: 8),
              _buildMessageField(context),

              const SizedBox(height: 40),

              // Submit Button
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.slatePurple,
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType ?? AppLocalizations.of(context)!.bugReport,
          isExpanded: true,
          items:
              [
                AppLocalizations.of(context)!.bugReport,
                AppLocalizations.of(context)!.featureRequest,
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedType = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildMessageField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _messageController,
      maxLines: 6,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.enterMessageHere,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final isLoading = state.feedbackStatus == FeedbackStatus.loading;

        return ElevatedButton(
          onPressed: isLoading ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.submitFeedback,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  void _submitFeedback() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errEnterMessage)),
      );
      return;
    }

    context.read<SettingsCubit>().submitFeedback(
      type: _selectedType ?? AppLocalizations.of(context)!.bugReport,
      content: message,
    );
  }
}

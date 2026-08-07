import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers.dart';
import '../../../config/routes.dart';
import '../../../config/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_navigation_bar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
      _showMessage(AppStrings.profileUpdated);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
      _showMessage(AppStrings.passwordChanged);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.deleteAccount),
        content: const Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.home);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: const AppNavigationBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.profile,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _UserHeader(
                  fullName: user?.fullName ?? '',
                  email: user?.email ?? '',
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: AppStrings.fullName,
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _firstNameController,
                          label: AppStrings.firstName,
                          validator: validateRequired,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _lastNameController,
                          label: AppStrings.lastName,
                          validator: validateRequired,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LoadingButton(
                          label: AppStrings.saveChanges,
                          loading: _savingProfile,
                          onPressed: _saveProfile,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: AppStrings.changePassword,
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _currentPasswordController,
                          label: AppStrings.currentPassword,
                          obscureText: true,
                          validator: validateRequired,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _newPasswordController,
                          label: AppStrings.newPassword,
                          obscureText: true,
                          validator: validatePassword,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _confirmNewPasswordController,
                          label: AppStrings.confirmPassword,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.requiredField;
                            }
                            if (value != _newPasswordController.text) {
                              return AppStrings.passwordMismatch;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LoadingButton(
                          label: AppStrings.changePassword,
                          loading: _savingPassword,
                          onPressed: _savePassword,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                LoadingButton(
                  label: AppStrings.deleteAccount,
                  loading: _deleting,
                  isOutlined: true,
                  onPressed: _deleteAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.fullName, required this.email});

  final String fullName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person, color: AppColors.onPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : AppStrings.profile,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

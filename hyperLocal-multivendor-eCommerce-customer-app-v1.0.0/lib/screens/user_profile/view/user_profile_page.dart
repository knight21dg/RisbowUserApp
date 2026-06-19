import 'dart:io';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_event.dart';
import '../bloc/user_profile_bloc/user_profile_bloc.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _selectedImage = null;
      }
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage != null || _nameController.text.isNotEmpty) {
        
        // Check if there's pending registration data (new user from OTP)
        final authBloc = context.read<AuthBloc>();
        final pendingRegistrationData = authBloc.getPendingRegistrationData();
        
        if (pendingRegistrationData != null && _nameController.text.isNotEmpty) {
          // Complete registration with the name entered by user
          authBloc.add(RegisterRequest(
            name: _nameController.text.trim(),
            mobile: pendingRegistrationData['mobile']?.toString() ?? '',
            country: pendingRegistrationData['country']?.toString() ?? '',
            iso2: pendingRegistrationData['iso2']?.toString() ?? '',
            countryCode: pendingRegistrationData['countryCode']?.toString() ?? '',
            completePhoneNumber: pendingRegistrationData['completePhoneNumber']?.toString() ?? '',
          ));
          
          // Clear pending registration data
          authBloc.add(ClearRegistrationDataEvent());
          
          // Navigate to home after registration
          GoRouter.of(context).pushReplacement(AppRoutes.splashScreen);
        }
        
        // Also update user profile if already logged in
        if (Global.userData != null && Global.userData!.token.isNotEmpty) {
          context.read<UserProfileBloc>().add(
                UpdateUserProfile(
                  userName: _nameController.text.trim(),
                  userImage: _selectedImage,
                ),
              );
        }
        
        setState(() {
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSelectAnImageAndEnterYourName),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Widget _buildProfileSetupView(BuildContext context) {
    return _buildProfileForm(context);
  }

  Widget _buildProfileForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authBloc = context.read<AuthBloc>();
    final pendingData = authBloc.getPendingRegistrationData();
    final phoneNumber = pendingData?['mobile']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Profile image picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primaryContainer,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Welcome text
            Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your name to complete registration',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                phoneNumber,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Complete Registration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScaffold(
      title: AppLocalizations.of(context)!.profile,
      showAppBar: true,
      showViewCart: false,
      body: BlocConsumer<UserProfileBloc, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                behavior: SnackBarBehavior.floating,
                backgroundColor: colorScheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          } else if (state is UserProfileLoaded) {
            _selectedImage = null;
          }
        },
        builder: (context, state) {
          // Check if user is logged in
          final isLoggedIn =
              Global.userData != null && (Global.userData!.token.isNotEmpty);
          
          // Check if there's pending registration data (new user from OTP)
          final authBloc = context.read<AuthBloc>();
          final pendingData = authBloc.getPendingRegistrationData();
          final isNewUser = pendingData != null;

          // If not logged in but is new user from OTP, show profile form
          if (!isLoggedIn && isNewUser) {
            return _buildProfileForm(context);
          }
          
          if (!isLoggedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.notLoggedIn,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.pleaseLoginToViewYourProfile,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        GoRouter.of(context).push(AppRoutes.login);
                      },
                      icon: const Icon(Icons.login),
                      label: Text(AppLocalizations.of(context)!.goToLogin),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is UserProfileLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomCircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadingProfile,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is UserProfileLoaded) {
            final userData = state.userData.data!;

            if (!_isEditing && _nameController.text.isEmpty) {
              _nameController.text = userData.name ?? '';
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section with Gradient Background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profile Image Section
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                        as ImageProvider
                                    : (userData.profileImage != null &&
                                            userData.profileImage!
                                                .trim()
                                                .isNotEmpty &&
                                            resolveImageUrl(userData.profileImage!) != null &&
                                            resolveImageUrl(userData.profileImage!)!.isNotEmpty
                                        ? NetworkImage(resolveImageUrl(userData.profileImage!)!)
                                        : null),
                                child: _selectedImage == null &&
                                        (userData.profileImage == null ||
                                            userData.profileImage!
                                                .trim()
                                                .isEmpty)
                                    ? Image.asset(
                                        'assets/images/placeholder.png',
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Name and Email Section
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomTextFormField(
                                    controller: _nameController,
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return AppLocalizations.of(context)!.pleaseEnterYourName;
                                      }
                                      if (value.trim().length < 2) {
                                        return AppLocalizations.of(context)!.nameMustBeAtLeast2Characters;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _saveProfile,
                                          icon:
                                              const Icon(Icons.save, size: 18),
                                          label: Text(AppLocalizations.of(context)!.saveChanges),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _toggleEdit,
                                          icon:
                                              const Icon(Icons.close, size: 18),
                                          label: Text(AppLocalizations.of(context)!.cancel),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                colorScheme.onSurface,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Text(
                                userData.name ?? 'No Name',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (userData.email != null && userData.email!.isNotEmpty && !userData.email!.endsWith('@risbow.com')) 
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    userData.email!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              FilledButton.tonalIcon(
                                onPressed: _toggleEdit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(AppLocalizations.of(context)!.editProfile),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Profile Information Cards
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.accountInformation,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Information Card
                        _buildInfoCard([
                          _buildInfoItem(Icons.phone_outlined, AppLocalizations.of(context)!.mobile,
                              userData.mobile ?? AppLocalizations.of(context)!.notProvided),
                          _buildInfoItem(Icons.public_outlined, AppLocalizations.of(context)!.country,
                              userData.country ?? AppLocalizations.of(context)!.notProvided),
                        ]),

                        const SizedBox(height: 16),

                        // Financial Information Card
                        _buildInfoCard([
                          _buildInfoItem(
                            Icons.account_balance_wallet_outlined,
                            '${AppLocalizations.of(context)!.wallet} ${AppLocalizations.of(context)!.balance}',
                            '${AppConstant.currency}${userData.walletBalance?.toString() ?? '0'}',
                            valueColor: AppTheme.primaryColor,
                          ),
                          _buildInfoItem(
                            Icons.stars_outlined,
                            AppLocalizations.of(context)!.rewardPoints,
                            userData.rewardPoints?.toString() ?? '0',
                            valueColor: Colors.amber.shade700,
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // Coins & Referral Information Card
                        _buildInfoCard([
                          _buildInfoItem(
                            Icons.monetization_on_outlined,
                            'Coins',
                            (userData.coinsBalance ?? 0).toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            Icons.people_outline,
                            'Referrals',
                            (userData.referralCount ?? 0).toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoItem(
                            Icons.share_outlined,
                            AppLocalizations.of(context)!.referralCode,
                            // Show 'not available' when referral code is null or empty
                            (userData.referralCode != null && userData.referralCode!.isNotEmpty)
                                ? userData.referralCode!
                                : AppLocalizations.of(context)!.notAvailable,
                            showCopyButton: userData.referralCode != null && userData.referralCode!.isNotEmpty,
                          ),
                        ]),
                        const SizedBox(height: 12),
                        // View Referral Page Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/referral'),
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            label: const Text('View Referral & Earn', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is UserProfileFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.failedToLoadProfile,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.pleaseCheckConnection,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        context.read<UserProfileBloc>().add(FetchUserProfile());
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.tryAgain),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noProfileDataAvailable,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool showCopyButton = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (showCopyButton)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.labelCopiedToClipboard(label)),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                Icons.copy_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

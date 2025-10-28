import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  String? _selectedState;
  String? _selectedLGA;
  List<String> _states = [];
  List<String> _lgas = [];

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNigerianStates();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final user = supabaseService.currentUser;

      if (user != null) {
        final profile = await supabaseService.getCompleteUserProfile(user.id);

        if (profile != null) {
          setState(() {
            _userProfile = profile;
            _firstNameController.text = profile['first_name'] ?? '';
            _lastNameController.text = profile['last_name'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _addressController.text = profile['address'] ?? '';

            // Handle state - profile might contain state_code or state_name
            final stateCode = profile['state_code'];
            final stateName = profile['state_name'];

            if (stateName != null) {
              // Use state name directly for dropdown
              _selectedState = stateName;
              // Convert to state code for LGA loading
              final locationService =
                  Provider.of<LocationService>(context, listen: false);
              final code = locationService.getStateCode(stateName);
              if (code != null) {
                _loadLGAs(code);
              }
            } else if (stateCode != null) {
              // Convert state code to state name for dropdown
              final locationService =
                  Provider.of<LocationService>(context, listen: false);
              final name = locationService.getStateName(stateCode);
              if (name != null) {
                _selectedState = name;
                _loadLGAs(stateCode);
              }
            }

            _selectedLGA = profile['lga_code'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNigerianStates() async {
    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final states = await locationService.getNigerianStates();
      setState(() {
        // Remove duplicates and sort
        _states = states.toSet().toList()..sort();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load states: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadLGAs(String stateCode) async {
    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      final lgas = await locationService.getLGAsByState(stateCode);
      setState(() {
        // Remove duplicates and sort
        _lgas = lgas.toSet().toList()..sort();
        if (_selectedLGA != null && !_lgas.contains(_selectedLGA)) {
          _selectedLGA = null; // Reset LGA if it's not valid for the new state
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load LGAs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final user = supabaseService.currentUser;

      if (user != null) {
        await supabaseService.updateUserProfileData(
          userId: user.id,
          profileData: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'state_code': _selectedState,
            'lga_code': _selectedLGA,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fbf4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf8fbf4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0a164d)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF0a164d),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0a164d)),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF0a164d),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0a164d)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    _buildProfileHeader(),
                    const SizedBox(height: 32),

                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),

                    // Name Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              hintText: 'Enter your first name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'First name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                              hintText: 'Enter your last name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Last name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+234 ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Location Information Section
                    _buildSectionHeader('Location Information'),
                    const SizedBox(height: 16),

                    // State Selection
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'Select your state',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _states.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedState = value;
                        });
                        if (value != null) {
                          // Convert state name to state code
                          final locationService = Provider.of<LocationService>(
                              context,
                              listen: false);
                          final stateCode = locationService.getStateCode(value);
                          if (stateCode != null) {
                            _loadLGAs(stateCode);
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // LGA Selection
                    DropdownButtonFormField<String>(
                      value: _selectedLGA,
                      decoration: const InputDecoration(
                        labelText: 'Local Government Area (LGA)',
                        hintText: 'Select your LGA',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: _lgas.map((lga) {
                        return DropdownMenuItem(
                          value: lga,
                          child: Text(lga),
                        );
                      }).toList(),
                      onChanged: _selectedState != null
                          ? (value) {
                              setState(() {
                                _selectedLGA = value;
                              });
                            }
                          : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your LGA';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter your full address',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0a164d),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF0a164d),
          child: Text(
            _userProfile?['first_name']
                    ?.toString()
                    .substring(0, 1)
                    .toUpperCase() ??
                'U',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_userProfile?['first_name'] ?? ''} ${_userProfile?['last_name'] ?? ''}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0a164d),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _userProfile?['phone'] ?? 'No phone number',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0a164d),
        fontFamily: 'Poppins',
      ),
    );
  }
}

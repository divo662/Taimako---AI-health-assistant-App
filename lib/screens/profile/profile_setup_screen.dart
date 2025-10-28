import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedState;
  String? _selectedLGA;
  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _selectedBloodType;

  bool _isLoading = false;
  final List<String> _allergies = [];
  final List<String> _medications = [];
  final List<String> _medicalHistory = [];

  final List<String> _ageGroups = [
    'infant_0_2',
    'child_2_12',
    'adolescent_13_19',
    'adult_20_64',
    'elderly_65_plus'
  ];

  final List<String> _genders = [
    'male',
    'female',
    'other',
    'prefer_not_to_say'
  ];

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadNigerianStates() async {
    try {
      final locationService =
          Provider.of<LocationService>(context, listen: false);
      await locationService.initialize();
      // States will be loaded when dropdown is opened
    } catch (e) {
      // Error loading states - will use static data
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final currentUser = supabaseService.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': currentUser.email!,
        'phone': _phoneController.text.trim(),
        'state_code': _selectedState,
        'lga_code': _selectedLGA,
        'address': _addressController.text.trim(),
        'location': '$_selectedState, $_selectedLGA, Nigeria',
        'age_group': _selectedAgeGroup,
        'gender': _selectedGender,
        'blood_type': _selectedBloodType,
        'allergies': _allergies,
        'current_medications': _medications,
        'medical_history': _medicalHistory,
        'emergency_contacts': [],
        'preferences': {
          'notifications_enabled': true,
          'location_sharing': true,
          'data_privacy': 'standard',
        },
        'is_verified': false,
        'profile_completed': true,
      };

      await supabaseService.createUserProfile(
        userId: currentUser.id,
        profileData: profileData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Profile completed successfully! Welcome to Taimako!'),
            backgroundColor: Color(0xFF00D4AA),
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Error saving profile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0a164d)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Complete Your Profile',
          style: TextStyle(
            color: const Color(0xFF0a164d),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s get to know you better',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0a164d),
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'This information helps us provide better health predictions',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 32.h),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),

              // Location Information
              _buildSectionTitle('Location Information'),
              SizedBox(height: 16.h),

              Consumer<LocationService>(
                builder: (context, locationService, child) {
                  return _buildDropdown(
                    label: 'State',
                    value: _selectedState,
                    items: locationService.getNigerianStatesSync().map((state) {
                      return DropdownMenuItem(
                        value: state['code'],
                        child: Text(state['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                        _selectedLGA = null; // Reset LGA when state changes
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your state';
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),

              Consumer<LocationService>(
                builder: (context, locationService, child) {
                  final lgas = _selectedState != null
                      ? locationService.getLgasForStateSync(_selectedState!)
                      : <Map<String, String>>[];

                  return _buildDropdown(
                    label: 'Local Government Area',
                    value: _selectedLGA,
                    items: lgas.map((lga) {
                      return DropdownMenuItem(
                        value: lga['code'],
                        child: Text(lga['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLGA = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select your LGA';
                      }
                      return null;
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),

              // Health Information
              _buildSectionTitle('Health Information'),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Age Group',
                      value: _selectedAgeGroup,
                      items: _ageGroups.map((age) {
                        return DropdownMenuItem(
                          value: age,
                          child: Text(_formatAgeGroup(age)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAgeGroup = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your age group';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Gender',
                      value: _selectedGender,
                      items: _genders.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(_formatGender(gender)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              _buildDropdown(
                label: 'Blood Type (Optional)',
                value: _selectedBloodType,
                items: _bloodTypes.map((bloodType) {
                  return DropdownMenuItem(
                    value: bloodType,
                    child: Text(bloodType),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBloodType = value;
                  });
                },
              ),
              SizedBox(height: 32.h),

              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0a164d),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 16.sp,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        // Extract text from the child Text widget
        String displayText = '';
        if (item.child is Text) {
          final textWidget = item.child as Text;
          displayText = textWidget.data ?? '';
        } else {
          displayText = item.value ?? '';
        }

        return DropdownMenuItem<String>(
          value: item.value,
          child: Container(
            width: double.infinity,
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: 'Poppins',
                color: const Color(0xFF2C2C2E), // Black text color
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        fontSize: 16.sp,
        fontFamily: 'Poppins',
        color: const Color(0xFF2C2C2E), // Black text color
      ),
      dropdownColor: Colors.white, // White dropdown background
      isExpanded:
          true, // This is the key fix - makes dropdown expand to full width
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
          fontFamily: 'Poppins',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  String _formatAgeGroup(String ageGroup) {
    switch (ageGroup) {
      case 'infant_0_2':
        return 'Infant (0-2 years)';
      case 'child_2_12':
        return 'Child (2-12 years)';
      case 'adolescent_13_19':
        return 'Adolescent (13-19 years)';
      case 'adult_20_64':
        return 'Adult (20-64 years)';
      case 'elderly_65_plus':
        return 'Elderly (65+ years)';
      default:
        return ageGroup;
    }
  }

  String _formatGender(String gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }
}

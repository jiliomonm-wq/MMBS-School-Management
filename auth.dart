import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'localization.dart';
import 'theme_widgets.dart';
import 'main_screen.dart';

class SchoolApp extends StatefulWidget {
  const SchoolApp({super.key});

  @override
  State<SchoolApp> createState() => _SchoolAppState();
}

class _SchoolAppState extends State<SchoolApp> {
  String _lang = 'en';
  UserProfile? _currentUser;

  String t(String k) => _loc[_lang]?[k] ?? k;

  void toggleLang() {
    setState(() => _lang = _lang == 'en' ? 'mm' : 'en');
  }

  void onLogin(UserProfile u) {
    setState(() => _currentUser = u);
  }

  void onLogout() {
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg1,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        visualDensity: VisualDensity.compact,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
      ),
      home: _currentUser == null
          ? AuthScreen(
              lang: _lang,
              t: t,
              onToggleLang: toggleLang,
              onAuthSuccess: onLogin,
            )
          : MainScreen(
              user: _currentUser!,
              lang: _lang,
              t: t,
              onToggleLang: toggleLang,
              onLogout: onLogout,
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  final String lang;
  final String Function(String) t;
  final VoidCallback onToggleLang;
  final Function(UserProfile) onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.lang,
    required this.t,
    required this.onToggleLang,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  String _selectedRole = 'Student';

  String? _selectedGrade;
  String? _selectedTeacherGrade;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _pNameCtrl = TextEditingController();
  final _pPhoneCtrl = TextEditingController();

  final List<String> _grades = List.generate(12, (i) => 'Grade \${i + 1}');

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _snack('Please fill all fields');
      return;
    }

    if (!_isLogin && _nameCtrl.text.isEmpty) {
      _snack('Please enter your name');
      return;
    }

    if (!_isLogin && _selectedRole == 'Student' && _selectedGrade == null) {
      _snack(widget.t('grade_required'));
      return;
    }

    if (!_isLogin && _selectedRole == 'Teacher' && (_subjectCtrl.text.isEmpty || _selectedTeacherGrade == null)) {
      _snack('Please fill subject and grade');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      if (_isLogin) {
        // Query Firestore users collection for login
        final query = await firestore
            .collection('users')
            .where('email', isEqualTo: _emailCtrl.text.trim())
            .where('password', isEqualTo: _passCtrl.text.trim())
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final user = UserProfile.fromFirestore(doc.data(), doc.id);
          _snack(widget.t('login_success'), isSuccess: true);
          widget.onAuthSuccess(user);
          return;
        } else {
          // Fallback demo login if not yet in database
          String name = _emailCtrl.text.split('@')[0];
          if (_emailCtrl.text == 'owner@school.com') name = 'U Ba Ba';
          if (_emailCtrl.text == 'teacher@school.com') name = 'Daw Mya Mya';
          if (_emailCtrl.text == 'student@school.com') name = 'Aung Aung';

          final user = UserProfile(
            name: name,
            id: '\${_selectedRole.substring(0, 3).toUpperCase()}-\${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            role: _selectedRole,
            className: _selectedRole == 'Student' ? (_selectedGrade ?? 'Grade 8') : (_selectedRole == 'Teacher' ? 'Mathematics' : ''),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );
          _snack(widget.t('login_success'), isSuccess: true);
          widget.onAuthSuccess(user);
          return;
        }
      } else {
        // Register: Save new user to Firestore
        final docRef = firestore.collection('users').doc();
        final user = UserProfile(
          name: _nameCtrl.text.trim(),
          id: docRef.id,
          role: _selectedRole,
          className: _selectedRole == 'Student'
              ? (_selectedGrade ?? 'Grade 8')
              : (_selectedRole == 'Teacher' ? _subjectCtrl.text.trim() : ''),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          avatarUrl: _selectedRole == 'Student'
              ? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=100&q=80'
              : (_selectedRole == 'Teacher'
                  ? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80'
                  : 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=100&q=80'),
          age: int.tryParse(_ageCtrl.text) ?? 15,
          location: _locCtrl.text.trim(),
          contact: _contactCtrl.text.trim(),
          parentName: _selectedRole == 'Student' ? _pNameCtrl.text.trim() : '',
          parentPhone: _selectedRole == 'Student' ? _pPhoneCtrl.text.trim() : '',
          gradesTaught: _selectedRole == 'Teacher' ? (_selectedTeacherGrade ?? '') : '',
        );

        await docRef.set(user.toMap());
        _snack(widget.t('register_success'), isSuccess: true);
        widget.onAuthSuccess(user);
      }
    } catch (e) {
      _snack('Database error: \$e');
    }
  }

  void _snack(String m, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? AppColors.success : AppColors.danger,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LightBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: widget.onToggleLang,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(widget.t('lang'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.t('school_name'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(widget.t(_isLogin ? 'welcome_back' : 'create_new'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.t('select_role'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Student', 'Teacher', 'Owner'].map((role) {
                          final selected = _selectedRole == role;
                          final icons = {
                            'Student': Icons.school_outlined,
                            'Teacher': Icons.person_outline,
                            'Owner': Icons.admin_panel_settings_outlined,
                          };

                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: role == 'Owner' ? 0 : 6),
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = role),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: selected ? const LinearGradient(colors: [AppColors.primary, AppColors.purple]) : null,
                                    color: selected ? null : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(icons[role], color: selected ? Colors.white : AppColors.textSecondary, size: 20),
                                      const SizedBox(height: 4),
                                      Text(role, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (!_isLogin) _buildInputField(widget.t('name'), Icons.person_outline, _nameCtrl),
                      if (!_isLogin) const SizedBox(height: 10),
                      _buildInputField(widget.t('email'), Icons.email_outlined, _emailCtrl, keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 10),
                      _buildInputField(widget.t('password'), Icons.lock_outline, _passCtrl, obscure: true),
                      const SizedBox(height: 10),
                      if (!_isLogin) ...[
                        Row(
                          children: [
                            Expanded(child: _buildInputField(widget.t('age'), Icons.cake_outlined, _ageCtrl, keyboard: TextInputType.number)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInputField(widget.t('contact'), Icons.phone_outlined, _contactCtrl, keyboard: TextInputType.phone)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(widget.t('location'), Icons.location_on_outlined, _locCtrl),
                        const SizedBox(height: 10),
                      ],
                      if (!_isLogin && _selectedRole == 'Student') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _buildDecoration(widget.t('select_grade'), Icons.class_outlined),
                          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedGrade = v),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warn.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warn.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: AppColors.warn),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.lang == 'en' ? 'Parent Info (Owner Only)' : 'မိဘအချက်အလက် (Owner သာ)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildInputField(widget.t('parent_name'), Icons.person, _pNameCtrl, isDense: true),
                              const SizedBox(height: 8),
                              _buildInputField(widget.t('parent_phone'), Icons.phone, _pPhoneCtrl, keyboard: TextInputType.phone, isDense: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!_isLogin && _selectedRole == 'Teacher') ...[
                        _buildInputField(widget.t('subject'), Icons.book_outlined, _subjectCtrl),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedTeacherGrade,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _buildDecoration(widget.t('select_grade'), Icons.class_outlined),
                          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)))).toList(),
                          onChanged: (v) => setState(() => _selectedTeacherGrade = v),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _submit,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.purple]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.t(_isLogin ? 'login' : 'register'),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            widget.t(_isLogin ? 'no_account' : 'have_account'),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _buildInputField(String label, IconData icon, TextEditingController ctrl, {bool obscure = false, TextInputType? keyboard, bool isDense = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: isDense ? 18 : 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        isDense: isDense,
        contentPadding: isDense ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

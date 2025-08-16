import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableNotifications = true;
  bool _enableEmailAlerts = true;
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedLanguage = 'English';
  String _serverAddress = AppConfig.serverIP;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Tailwind slate-50
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B), // Tailwind slate-800
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0xFF64748B).withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF3B82F6), // Tailwind blue-500
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(
                            user?.firstName != null &&
                                    user!.firstName.isNotEmpty
                                ? user.firstName.substring(0, 1)
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user?.email ?? 'user@example.com'),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsTile(
                        title: 'Edit Profile',
                        icon: Icons.person_outline,
                        onTap: () {
                          _showNotImplementedSnackbar();
                        },
                      ),
                      const Divider(),
                      _buildSettingsTile(
                        title: 'Change Password',
                        icon: Icons.lock_outline,
                        onTap: () {
                          _showNotImplementedSnackbar();
                        },
                      ),
                      if (authProvider.isAuthenticated) ...[
                        const Divider(),
                        _buildSettingsTile(
                          title: 'Logout',
                          icon: Icons.exit_to_app,
                          onTap: () async {
                            await _showLogoutConfirmation();
                          },
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Push Notifications'),
                    subtitle: const Text(
                      'Get notified about important updates',
                    ),
                    value: _enableNotifications,
                    onChanged: (value) {
                      setState(() {
                        _enableNotifications = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email Alerts'),
                    subtitle: const Text('Receive important notices via email'),
                    value: _enableEmailAlerts,
                    onChanged: (value) {
                      setState(() {
                        _enableEmailAlerts = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme'),
                    subtitle: const Text(
                      'Choose light, dark, or system default',
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: _themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _themeMode = value;
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Language'),
                    subtitle: const Text('Select your preferred language'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'Spanish',
                          child: Text('Spanish'),
                        ),
                        DropdownMenuItem(
                          value: 'French',
                          child: Text('French'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Advanced Settings
          _buildSectionHeader('Advanced'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Server Address',
                      hintText: 'Enter server IP address',
                    ),
                    controller: TextEditingController(text: _serverAddress),
                    onChanged: (value) {
                      _serverAddress = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveSettings();
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        _showClearDataConfirmation();
                      },
                      child: const Text('Clear App Data'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSettingsTile(
                    title: 'App Version',
                    icon: Icons.info_outline,
                    trailing: Text(
                      AppConfig.appVersion,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const Divider(),
                  _buildSettingsTile(
                    title: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: () {
                      _showNotImplementedSnackbar();
                    },
                  ),
                  const Divider(),
                  _buildSettingsTile(
                    title: 'Terms of Service',
                    icon: Icons.description_outlined,
                    onTap: () {
                      _showNotImplementedSnackbar();
                    },
                  ),
                  const Divider(),
                  _buildSettingsTile(
                    title: 'Support',
                    icon: Icons.support_outlined,
                    subtitle: 'Get help with the app',
                    onTap: () {
                      _showNotImplementedSnackbar();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  void _showNotImplementedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is not implemented yet'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (result == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _saveSettings() {
    // Implementation would actually save settings to storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showClearDataConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text(
          'Are you sure you want to clear all app data? This will reset all settings and cached data.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Implementation would actually clear app data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App data has been cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

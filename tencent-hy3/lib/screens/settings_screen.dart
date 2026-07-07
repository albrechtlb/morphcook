import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'backup_restore_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSection('profile', [
            _buildSettingTile(
              'dietary preferences',
              Icons.restaurant,
              () {},
            ),
            _buildSettingTile(
              'calorie target',
              Icons.local_fire_department,
              () {},
            ),
            _buildSettingTile(
              'time budget',
              Icons.access_time,
              () {},
            ),
          ]),
          _buildSection('app', [
            _buildSettingTile(
              'language',
              Icons.language,
              () {},
            ),
            _buildSettingTile(
              'reduce motion',
              Icons.animation,
              () {},
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
          ]),
          _buildSection('data', [
            _buildSettingTile(
              'backup & restore',
              Icons.backup,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BackupRestoreScreen(),
                  ),
                );
              },
            ),
            _buildSettingTile(
              'shopping insights',
              Icons.insights,
              () {},
            ),
          ]),
          _buildSection('help', [
            _buildSettingTile(
              'FAQ & help center',
              Icons.help_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQScreen()),
                );
              },
            ),
            _buildSettingTile(
              'about MorphCook',
              Icons.info_outline,
              () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24, top: 24, bottom: 8),
          child: Text(
            '— $title —',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
        Divider(color: AppTheme.dashedBorder, height: 1),
      ],
    );
  }

  Widget _buildSettingTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.inkBlack),
      title: Text(
        title,
        style: GoogleFonts.jetBrainsMono(fontSize: 14),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: AppTheme.inkBlack),
      onTap: onTap,
    );
  }
}

class FAQScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'What is MorphCook?',
      'answer':
          'MorphCook is a recipe app that adapts to your dietary needs. Instead of filtering out recipes you can\'t eat, we provide complete alternative versions of every dish for different diets.',
      'category': 'general',
    },
    {
      'question': 'How do recipe variants work?',
      'answer':
          'Each dish has multiple complete recipes - one for each dietary preference. When you select "Vegan Döner", you get a fully-authored vegan recipe, not a modified version of the classic.',
      'category': 'features',
    },
    {
      'question': 'Can I use MorphCook offline?',
      'answer':
          'Yes! MorphCook is fully offline. All recipes are stored on your device. No internet connection is required after initial download.',
      'category': 'technical',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'FAQ & help',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(24),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return _buildFAQItem(context, faq);
        },
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, Map<String, dynamic> faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: AppTheme.polaroidCard,
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              faq['answer'],
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _usePassword = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'backup & restore',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _buildSectionHeader('export backup'),
          SizedBox(height: 16),
          _buildExportCard(),
          SizedBox(height: 32),
          _buildSectionHeader('import backup'),
          SizedBox(height: 16),
          _buildImportCard(),
          SizedBox(height: 32),
          _buildSectionHeader('backup options'),
          SizedBox(height: 16),
          _buildPasswordOption(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      '— $title —',
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppTheme.polaroidCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'save your data',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'exports profile, saved recipes, meal plans, and history',
            style: GoogleFonts.jetBrainsMono(fontSize: 12),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('export .json'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('export .json.gz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppTheme.polaroidCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'restore from backup',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'import previously exported data',
            style: GoogleFonts.jetBrainsMono(fontSize: 12),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: Text('choose file & import'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordOption() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: AppTheme.polaroidCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'password protection',
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              Switch(
                value: _usePassword,
                onChanged: (value) {
                  setState(() {
                    _usePassword = value;
                  });
                },
              ),
            ],
          ),
          if (_usePassword) ...[
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: GoogleFonts.jetBrainsMono(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'enter password',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'encrypts backup with AES-256-GCM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppTheme.dashedBorder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

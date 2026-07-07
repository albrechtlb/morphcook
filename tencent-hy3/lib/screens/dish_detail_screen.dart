import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/recipe.dart';
import '../models/dish.dart';

class DishDetailScreen extends StatefulWidget {
  final String dishId;

  DishDetailScreen({required this.dishId});

  @override
  _DishDetailScreenState createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  String? _selectedDiet = 'classic';
  String? _selectedEffort = 'easy';
  String? _selectedCalorieLevel = '≤600';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'Döner Kebab',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroImage(),
          ),
          SliverToBoxAdapter(
            child: _buildVariantSwitchers(),
          ),
          SliverToBoxAdapter(
            child: _buildIngredients(),
          ),
          SliverToBoxAdapter(
            child: _buildMethod(),
          ),
          SliverToBoxAdapter(
            child: _buildMacros(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 250,
      decoration: AppTheme.stripedPlaceholder(AppTheme.stripeCoral),
      child: Center(
        child: Text(
          'Döner Kebab',
          style: GoogleFonts.playfairDisplay(
            fontSize: 48,
            fontStyle: FontStyle.italic,
            color: AppTheme.inkBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildVariantSwitchers() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          _buildVariantRow(
            'diet',
            ['classic', 'vegan', 'keto', 'halal'],
            _selectedDiet,
            (value) => setState(() => _selectedDiet = value),
          ),
          SizedBox(height: 16),
          _buildVariantRow(
            'effort',
            ['easy', 'medium', 'hard'],
            _selectedEffort,
            (value) => setState(() => _selectedEffort = value),
          ),
          SizedBox(height: 16),
          _buildVariantRow(
            'calorie level',
            ['≤400', '≤600', '≤800', '>800'],
            _selectedCalorieLevel,
            (value) => setState(() => _selectedCalorieLevel = value),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantRow(
    String label,
    List<String> options,
    String? selectedValue,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '— $label —',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 16,
              color: AppTheme.inkBlack,
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          selectedValue ?? options.first,
          style: GoogleFonts.caveat(fontSize: 20),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(option);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIngredients() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ingredients',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          _buildIngredientItem('300g', 'beef chuck', 'Rindfleisch'),
          _buildIngredientItem('2 pcs', 'flatbread', 'Fladenbrot'),
          _buildIngredientItem('100g', 'yogurt', 'Joghurt'),
          _buildIngredientItem('200g', 'white cabbage', 'Weißkohl'),
          _buildIngredientItem('2 pcs', 'tomato', 'Tomate'),
          _buildIngredientItem('1 pc', 'onion', 'Zwiebel'),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String amount, String enName, String deName) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dashedBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            amount,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              '$enName ($deName)',
              style: GoogleFonts.jetBrainsMono(fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMethod() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'method',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          _buildStep(1, 'Slice the beef thinly and season with salt and paprika.'),
          _buildStep(2, 'Grill the meat until cooked through, about 5-7 minutes.'),
          _buildStep(3, 'Warm the flatbread and slice the vegetables.'),
          _buildStep(4, 'Assemble: bread, meat, vegetables, yogurt sauce.'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.inkBlack),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacros() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'macros per serving',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem('620', 'cal'),
              _buildMacroItem('35g', 'protein'),
              _buildMacroItem('45g', 'carbs'),
              _buildMacroItem('28g', 'fat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: AppTheme.dashedBorder,
          ),
        ),
      ],
    );
  }
}

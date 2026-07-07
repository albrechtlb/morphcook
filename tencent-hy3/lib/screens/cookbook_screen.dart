import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CookbookScreen extends StatefulWidget {
  @override
  _CookbookScreenState createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  final List<String> _savedRecipes = [
    'doener-vegan',
    'alfredo-classic',
    'padthai-classic',
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'your cookbook',
              style: GoogleFonts.playfairDisplay(
                fontSize: 36,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '${_savedRecipes.length} saved recipes',
              style: GoogleFonts.caveat(fontSize: 20),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildRecipeCard(context, index),
            childCount: _savedRecipes.length,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(BuildContext context, int index) {
    final recipeNames = ['Vegan Döner', 'Classic Alfredo', 'Classic Pad Thai'];
    final recipeName = recipeNames[index % recipeNames.length];
    final colors = [
      AppTheme.stripeCoral,
      AppTheme.stripeGold,
      AppTheme.stripeRose,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: AppTheme.polaroidCard,
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: AppTheme.stripedPlaceholder(color),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipeName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '25 min · 620 cal',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppTheme.dashedBorder,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.bookmark, color: AppTheme.inkBlack),
              onPressed: () {
                setState(() {
                  _savedRecipes.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

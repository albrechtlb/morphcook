import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSearchBar(),
        ),
        SliverToBoxAdapter(
          child: _buildFilterChips(),
        ),
        if (_isSearching)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_searchResults.isEmpty && _searchController.text.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildResultCard(context, index),
              childCount: _searchResults.length,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          _performSearch(value);
        },
        style: GoogleFonts.jetBrainsMono(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'search recipes, ingredients...',
          hintStyle: GoogleFonts.jetBrainsMono(
            color: AppTheme.dashedBorder,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.inkBlack),
          filled: true,
          fillColor: AppTheme.paperGrain,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: Text('vegan'),
            selected: false,
            onSelected: (selected) {},
          ),
          FilterChip(
            label: Text('quick'),
            selected: false,
            onSelected: (selected) {},
          ),
          FilterChip(
            label: Text('easy'),
            selected: false,
            onSelected: (selected) {},
          ),
          FilterChip(
            label: Text('≤30 min'),
            selected: false,
            onSelected: (selected) {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Text(
            'what are you craving?',
            style: GoogleFonts.caveat(
              fontSize: 32,
              color: AppTheme.inkBlack,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'search by recipe name,\ningredients, or tags',
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: AppTheme.dashedBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: AppTheme.polaroidCard,
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: AppTheme.stripedPlaceholder(AppTheme.stripeCoral),
        ),
        title: Text(
          'Döner Kebab',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        subtitle: Text(
          '25 min · 620 cal',
          style: GoogleFonts.jetBrainsMono(fontSize: 12),
        ),
        trailing: Icon(Icons.bookmark_border),
        onTap: () {},
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _searchResults = ['doener', 'alfredo', 'pad-thai'];
        _isSearching = false;
      });
    });
  }
}

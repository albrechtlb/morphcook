import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<ShoppingItem> _items = [
    ShoppingItem('Garlic', '3 cloves', 'produce', false),
    ShoppingItem('Tomato', '2 pcs', 'produce', false),
    ShoppingItem('Yogurt', '100g', 'dairy', false),
    ShoppingItem('Beef Chuck', '300g', 'meat', true),
    ShoppingItem('Flatbread', '2 pcs', 'bakery', false),
  ];

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<ShoppingItem>>{};
    for (final item in _items) {
      groupedItems.putIfAbsent(item.aisles, () => []).add(item);
    }

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'shopping list',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _items.clear();
              });
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '${_items.where((i) => i.isChecked).length}/${_items.length} items',
              style: GoogleFonts.caveat(fontSize: 24),
            ),
          ),
          ...groupedItems.entries.map((entry) {
            return _buildAisleSection(entry.key, entry.value);
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.inkBlack,
        child: Icon(Icons.add, color: AppTheme.paperCream),
        onPressed: () {},
      ),
    );
  }

  Widget _buildAisleSection(String aisle, List<ShoppingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            '— $aisle —',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map((item) => _buildShoppingItem(item)).toList(),
      ],
    );
  }

  Widget _buildShoppingItem(ShoppingItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dashedBorder, width: 0.5),
        ),
      ),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (value) {
          setState(() {
            item.isChecked = value ?? false;
          });
        },
        title: Text(
          item.name,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          item.amount,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: AppTheme.dashedBorder,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class ShoppingItem {
  final String name;
  final String amount;
  final String aisles;
  bool isChecked;

  ShoppingItem(this.name, this.amount, this.aisles, this.isChecked);
}

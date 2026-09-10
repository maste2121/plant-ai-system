// lib/features/market/presentation/market_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_mobile_app/core/api/dio_client.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _isLoading = true;
  bool _isAm = false;
  List<Map<String, dynamic>> _marketItems = [];

  @override
  void initState() {
    super.initState();
    _loadLanguageAndData();
  }

  Future<void> _loadLanguageAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'am';
    setState(() => _isAm = lang == 'am');

    try {
      final response = await DioClient().dio.get('/market/products');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw =
            response.data is List ? response.data : response.data['data'] ?? [];
        setState(() {
          _marketItems =
              raw
                  .map(
                    (item) => {
                      'id': item['id']?.toString() ?? '',
                      'name': item['name'] ?? item['title'] ?? 'Market Item',
                      'price':
                          item['price'] != null
                              ? "${item['price']} ETB"
                              : "Negotiable",
                      'category': item['category'] ?? 'General',
                      'seller': item['seller_name'] ?? 'Local Vendor',
                      'image': item['image_url'] ?? '',
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Market Fetch Error: $e");
      // Fallback local data if backend is offline
      setState(() {
        _marketItems = [
          {
            'id': '1',
            'name': _isAm ? 'ኦርጋኒክ ማዳበሪያ' : 'Organic Fertilizer',
            'price': '450 ETB',
            'category': _isAm ? 'ማዳበሪያ' : 'Fertilizers',
            'seller': 'Abebe Supplies',
            'image': '',
          },
          {
            'id': '2',
            'name': _isAm ? 'የበቆሎ ዘር (HYV)' : 'Hybrid Maize Seeds',
            'price': '1,200 ETB',
            'category': _isAm ? 'ዘር' : 'Seeds',
            'seller': 'Ethiopia Seed Enterprise',
            'image': '',
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3022),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isAm ? "የግብርና ገበያ" : "Agricultural Market",
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _marketItems.length,
                  itemBuilder: (context, index) {
                    final item = _marketItems[index];
                    return Card(
                      color: const Color(0xFF1B3022),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        title: Text(
                          item['name'],
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${item['category']} • ${item['seller']}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          item['price'],
                          style: GoogleFonts.notoSans(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

// lib/features/expert/presentation/expert_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_mobile_app/core/api/dio_client.dart';

class ExpertScreen extends StatefulWidget {
  const ExpertScreen({super.key});

  @override
  State<ExpertScreen> createState() => _ExpertScreenState();
}

class _ExpertScreenState extends State<ExpertScreen> {
  bool _isLoading = true;
  bool _isAm = false;
  List<Map<String, dynamic>> _experts = [];

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
      final response = await DioClient().dio.get('/experts');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw =
            response.data is List ? response.data : response.data['data'] ?? [];
        setState(() {
          _experts =
              raw
                  .map(
                    (e) => {
                      'id': e['id']?.toString() ?? '',
                      'name': e['name'] ?? 'Agricultural Expert',
                      'specialty': e['specialty'] ?? 'Crop Disease Specialist',
                      'phone': e['phone'] ?? '+251 900 000 000',
                      'available': e['is_available'] ?? true,
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Expert Fetch Error: $e");
      // Fallback local data if backend is offline
      setState(() {
        _experts = [
          {
            'id': '1',
            'name': _isAm ? 'ዶ/ር አለሙ ተሰማ' : 'Dr. Alemu Tessema',
            'specialty': _isAm ? 'የሰብል በሽታዎች ስፔሻሊስት' : 'Crop Pathologist',
            'phone': '+251 911 223 344',
            'available': true,
          },
          {
            'id': '2',
            'name': _isAm ? 'ኢንጂነር መስፍን ገብሬ' : 'Eng. Mesfin Gebre',
            'specialty': _isAm ? 'የአፈርና መስኖ ባለሙያ' : 'Soil & Irrigation Expert',
            'phone': '+251 922 334 455',
            'available': false,
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
          _isAm ? "የግብርና ባለሙያዎች" : "Agricultural Experts",
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _experts.length,
                  itemBuilder: (context, index) {
                    final expert = _experts[index];
                    return Card(
                      color: const Color(0xFF1B3022),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1565C0),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          expert['name'],
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          expert['specialty'],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () {
                            // Call or message trigger
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.call,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isAm ? "ደውል" : "Call",
                            style: const TextStyle(color: Colors.white),
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

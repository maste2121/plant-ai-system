import 'dart:io';

import 'package:flutter/material.dart';
import '../../shared/models/disease_model.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  const ResultScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: Member 3 (AI) will replace this later
    final mockResult = DiseaseResult(
      nameEn: "Late Blight",
      nameAm: "የቆየ ግርሻ",
      confidence: 0.92,
      treatmentOrganic: "Use copper-based sprays and remove infected leaves.",
      treatmentChemical: "Apply Mancozeb or Chlorothalonil fungicides.",
      prevention: "Ensure proper spacing and avoid overhead watering.",
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(title: const Text("Detection Result")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(image, height: 250, width: double.infinity, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence Gauge
                  Text("Confidence: ${(mockResult.confidence * 100).toInt()}%", style: const TextStyle(color: Colors.green)),
                  LinearProgressIndicator(value: mockResult.confidence, color: Colors.green),
                  
                  const SizedBox(height: 20),
                  Text(mockResult.nameAm, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(mockResult.nameEn, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  
                  const SizedBox(height: 30),
                  _buildAdvisoryCard("Organic Treatment", mockResult.treatmentOrganic, Colors.green),
                  _buildAdvisoryCard("Chemical Treatment", mockResult.treatmentChemical, Colors.orange),
                  _buildAdvisoryCard("Prevention", mockResult.prevention, Colors.blue),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryCard(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(content, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
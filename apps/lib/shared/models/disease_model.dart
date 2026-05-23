class DiseaseResult {
  final String nameEn;
  final String nameAm;
  final double confidence;
  final String treatmentOrganic;
  final String treatmentChemical;
  final String prevention;

  DiseaseResult({
    required this.nameEn,
    required this.nameAm,
    required this.confidence,
    required this.treatmentOrganic,
    required this.treatmentChemical,
    required this.prevention,
  });
}

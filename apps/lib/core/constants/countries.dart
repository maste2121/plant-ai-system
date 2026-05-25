class Country {
  final String name;
  final String flag;
  final String dialCode;
  final int minLength;
  final int maxLength; // Added for precise validation

  Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.minLength,
    required this.maxLength,
  });
}

final List<Country> countries = [
  Country(
    name: "Ethiopia",
    flag: "🇪🇹",
    dialCode: "+251",
    minLength: 9,
    maxLength: 9,
  ),
  Country(
    name: "Kenya",
    flag: "🇰🇪",
    dialCode: "+254",
    minLength: 9,
    maxLength: 10,
  ),
  Country(
    name: "USA",
    flag: "🇺🇸",
    dialCode: "+1",
    minLength: 10,
    maxLength: 10,
  ),
];

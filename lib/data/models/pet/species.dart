enum Species {
  DOG,
  CAT,
}

extension SpeciesExtension on Species {
  String get value {
    return toString().split('.').last;
  }

  static Species fromString(String value) {
    return Species.values.firstWhere(
          (e) => e.value == value,
      orElse: () => Species.DOG,
    );
  }
}
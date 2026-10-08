enum BiologicalSex {
  male,
  female;

  String get label => this == BiologicalSex.male ? 'Masculino' : 'Femenino';

  static BiologicalSex? fromStorage(String? value) {
    if (value == null) {
      return null;
    }
    for (final sex in BiologicalSex.values) {
      if (sex.name == value) {
        return sex;
      }
    }
    return null;
  }
}

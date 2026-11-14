class Validators {
  static bool isValidCpf(String? cpf) {
    if (cpf == null) return false;
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');

    if (cleanCpf.length != 11) return false;

    // Reject known invalid sequences (e.g., 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;

    // Calculate first check digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanCpf[i]) * (10 - i);
    }
    int firstRemainder = (sum * 10) % 11;
    if (firstRemainder == 10 || firstRemainder == 11) firstRemainder = 0;
    if (firstRemainder != int.parse(cleanCpf[9])) return false;

    // Calculate second check digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanCpf[i]) * (11 - i);
    }
    int secondRemainder = (sum * 10) % 11;
    if (secondRemainder == 10 || secondRemainder == 11) secondRemainder = 0;
    if (secondRemainder != int.parse(cleanCpf[10])) return false;

    return true;
  }

  static String formatCpf(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return '${digits.substring(0, 3)}.${digits.substring(3)}';
    if (digits.length <= 9) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
    }
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, digits.length > 11 ? 11 : digits.length)}';
  }

  static String formatPhone(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return digits;
    if (digits.length <= 7) return '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, digits.length > 11 ? 11 : digits.length)}';
  }

  static String formatCep(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5, digits.length > 8 ? 8 : digits.length)}';
  }
}


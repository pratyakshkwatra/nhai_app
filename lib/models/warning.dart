class Warning {
  final ValType valType;
  final double limit;
  final double recvValue;
  final String message;
  final bool checkedOff;

  Warning(this.valType, this.limit, this.recvValue, this.message, this.checkedOff);
}

enum ValType {
  roughness, rut, crack, ravelling
}
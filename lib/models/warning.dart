class Warning {
  final ValType valType;
  final double limit;
  final double recvValue;
  final String message;
  final Duration duration;
  bool checkedOff;

  Warning(this.valType, this.limit, this.recvValue, this.message, this.duration,
      this.checkedOff);

      @override
  bool operator ==(Object other) {
    return other is Warning &&
        other.valType == valType &&
        other.duration == duration;
  }

  @override
  int get hashCode => valType.hashCode ^ duration.hashCode;
}

enum ValType { roughness, rut, crack, ravelling }

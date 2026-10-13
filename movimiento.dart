class Movimiento {
  final String id;
  final String categoria;
  final int creado;
  final String cuentaId;
  final String fecha;
  final double monto;
  final String nota;
  final String tipo; // "ingreso" o "gasto"

  Movimiento({
    required this.id,
    required this.categoria,
    required this.creado,
    required this.cuentaId,
    required this.fecha,
    required this.monto,
    required this.nota,
    required this.tipo,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      creado: json['creado'] as int,
      cuentaId: json['cuentaId'] as String,
      fecha: json['fecha'] as String,
      monto: (json['monto'] as num).toDouble(),
      nota: json['nota'] as String? ?? '',
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria': categoria,
      'creado': creado,
      'cuentaId': cuentaId,
      'fecha': fecha,
      'monto': monto,
      'nota': nota,
      'tipo': tipo,
    };
  }

  bool get esIngreso => tipo == 'ingreso';
  bool get esGasto => tipo == 'gasto';

  Movimiento copyWith({
    String? id,
    String? categoria,
    int? creado,
    String? cuentaId,
    String? fecha,
    double? monto,
    String? nota,
    String? tipo,
  }) {
    return Movimiento(
      id: id ?? this.id,
      categoria: categoria ?? this.categoria,
      creado: creado ?? this.creado,
      cuentaId: cuentaId ?? this.cuentaId,
      fecha: fecha ?? this.fecha,
      monto: monto ?? this.monto,
      nota: nota ?? this.nota,
      tipo: tipo ?? this.tipo,
    );
  }
}

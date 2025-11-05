int _mmToDots(double mm, {int dpi = 203}) => (mm * dpi / 25.4).round();

/// TSPL básico. Algumas impressoras exigem FORM antes do PRINT.
/// Use includeForm=true para garantir.
String buildTspl({
  required double larguraMm,
  required double alturaMm,
  required double gapMm,
  required String texto,
  required String qrData,
  bool includeForm = true,
}) {
  final xTexto = _mmToDots(4);
  final yTexto = _mmToDots(6);
  final xQR    = _mmToDots(4);
  final yQR    = _mmToDots(14);

  final lines = <String>[
    'SIZE $larguraMm mm,$alturaMm mm',
    'GAP $gapMm mm,0',
    'CLS',
    'DENSITY 8',
    'DIRECTION 1',
    'REFERENCE 0,0',
    'TEXT $xTexto,$yTexto,"3",0,1,1,"$texto"',
    'QRCODE $xQR,$yQR,H,6,A,0,"$qrData"',
  ];
  if (includeForm) lines.add('FORM');
  lines.add('PRINT 1,1');
  return lines.join('\r\n');
}

/// CPCL “Hello World” genérico, útil para verificar pipeline.
String buildCpclHello({bool center = true, String text = 'HELLO'}) {
  final lines = <String>[
    '! 0 200 200 300 1',
    'PW 576',
    'SPEED 3',
    'DENSITY 7',
    if (center) 'CENTER',
    'TEXT 4 0 0 50 $text',
    'FORM',
    'PRINT',
  ];
  return lines.join('\r\n');
}

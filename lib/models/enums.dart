enum GrupoBiologico {
  peixes('PEIXES', 'Peixes'),
  aves('AVES', 'Aves'),
  felinos('FELINOS', 'Felinos'),
  plantas('PLANTAS', 'Plantas'),
  repteis('REPTEIS', 'Répteis'),
  mamiferos('MAMIFEROS', 'Mamíferos');

  const GrupoBiologico(this.code, this.displayName);

  final String code;
  final String displayName;

  // Método para obter metodologias por grupo
  List<String> getMetodologias() {
    switch (this) {
      case GrupoBiologico.peixes:
        return ['Puçá', 'Tarrafa', 'Rede de espera', 'Anzol', 'Picaré', 'Rede de arrasto'];
      case GrupoBiologico.aves:
        return ['Observação direta', 'Rede ornitológica', 'Playback', 'Captura', 'Fotografia'];
      case GrupoBiologico.felinos:
        return ['Pegadas', 'Armadilha fotográfica', 'Observação direta', 'Sinais indiretos'];
      case GrupoBiologico.plantas:
        return ['Coleta botânica', 'Fotografia', 'Herbário', 'Quadrantes', 'Transecto'];
      case GrupoBiologico.repteis:
        return ['Observação direta', 'Captura manual', 'Armadilha', 'Fotografia'];
      case GrupoBiologico.mamiferos:
        return ['Observação direta', 'Armadilha fotográfica', 'Pegadas', 'Captura'];
    }
  }
}

enum StatusPonto {
  aberto('ABERTO'),
  fechado('FECHADO');

  const StatusPonto(this.value);
  final String value;
}
enum GrupoBiologico {
  ictiofauna('ICTIOFAUNA', 'Ictiofauna'),
  herpetofauna('HERPETOFAUNA', 'Herpetofauna'),
  avifauna('AVIFAUNA', 'Avifauna'),
  mastofauna('MASTOFAUNA', 'Mastofauna'),
  entomofauna('ENTOMOFAUNA', 'Entomofauna'),
  macroinvertebrados('MACROINVERTEBRADOS', 'Macroinvertebrados Bentônicos'),
  flora('FLORA', 'Flora / Fitossociologia'),
  zooplancton('ZOOPLANCTON', 'Zooplâncton'),
  fitoplancton('FITOPLANCTON', 'Fitoplâncton');

  const GrupoBiologico(this.code, this.displayName);

  final String code;
  final String displayName;

  // Metodologias específicas por grupo (temporário - depois vamos fazer cadastro)
  List<String> getMetodologias() {
    switch (this) {
      case GrupoBiologico.ictiofauna:
        return ['Puçá', 'Tarrafa', 'Rede de espera', 'Anzol', 'Picaré', 'Rede de arrasto', 'Pesca elétrica'];
      case GrupoBiologico.avifauna:
        return ['Observação direta', 'Rede ornitológica', 'Playback', 'Captura', 'Fotografia', 'Transecto'];
      case GrupoBiologico.herpetofauna:
        return ['Busca ativa', 'Armadilha de interceptação', 'Observação direta', 'Captura manual'];
      case GrupoBiologico.mastofauna:
        return ['Observação direta', 'Armadilha fotográfica', 'Pegadas', 'Captura', 'Rede de neblina'];
      case GrupoBiologico.entomofauna:
        return ['Rede entomológica', 'Armadilha luminosa', 'Pitfall', 'Coleta manual', 'Guarda-chuva entomológico'];
      case GrupoBiologico.macroinvertebrados:
        return ['Rede D', 'Draga', 'Peneira', 'Coleta manual', 'Substrato artificial'];
      case GrupoBiologico.flora:
        return ['Coleta botânica', 'Fotografia', 'Herbário', 'Quadrantes', 'Transecto', 'Plotagem'];
      case GrupoBiologico.zooplancton:
        return ['Rede de plâncton', 'Garrafa de Niskin', 'Bomba de sucção', 'Coleta superficial'];
      case GrupoBiologico.fitoplancton:
        return ['Rede de fitoplâncton', 'Garrafa coletora', 'Coleta superficial', 'Filtração'];
    }
  }
}

enum StatusProjeto {
  aberto('ABERTO'),
  fechado('FECHADO');

  const StatusProjeto(this.value);
  final String value;
}

enum UserType {
  academicResearcher('Pesquisador Academico', 'Instituição'),
  independentConsultant('Consultor independente', 'Empresa'),
  companyEmployee('Funcionario da empresa', 'Empresa'),
  student('Estudante', 'Universidade'),
  other('Outro', 'Organização');

  const UserType(this.displayName, this.orgLabel);
  final String displayName;
  final String orgLabel;
}
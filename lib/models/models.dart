// lib/models/models.dart

class Client {
  final String id;
  String nom;
  String prenom;
  String telephone;
  String notes;
  String couleurCheveuxActuelle;
  DateTime? dateDerniereVisite;
  List<String> servicesHistorique;

  Client({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone = '',
    this.notes = '',
    this.couleurCheveuxActuelle = '',
    this.dateDerniereVisite,
    List<String>? servicesHistorique,
  }) : servicesHistorique = servicesHistorique ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'notes': notes,
        'couleurCheveuxActuelle': couleurCheveuxActuelle,
        'dateDerniereVisite': dateDerniereVisite?.toIso8601String(),
        'servicesHistorique': servicesHistorique,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        nom: json['nom'],
        prenom: json['prenom'],
        telephone: json['telephone'] ?? '',
        notes: json['notes'] ?? '',
        couleurCheveuxActuelle: json['couleurCheveuxActuelle'] ?? '',
        dateDerniereVisite: json['dateDerniereVisite'] != null
            ? DateTime.parse(json['dateDerniereVisite'])
            : null,
        servicesHistorique:
            List<String>.from(json['servicesHistorique'] ?? []),
      );

  String get nomComplet => '$prenom $nom';
  String get initiales =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
          .toUpperCase();
}

class RendezVous {
  final String id;
  String clientId;
  String clientNom;
  DateTime dateHeure;
  int dureeMins;
  String service;
  String notes;
  bool estConfirme;

  RendezVous({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.dateHeure,
    this.dureeMins = 60,
    required this.service,
    this.notes = '',
    this.estConfirme = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientNom': clientNom,
        'dateHeure': dateHeure.toIso8601String(),
        'dureeMins': dureeMins,
        'service': service,
        'notes': notes,
        'estConfirme': estConfirme,
      };

  factory RendezVous.fromJson(Map<String, dynamic> json) => RendezVous(
        id: json['id'],
        clientId: json['clientId'],
        clientNom: json['clientNom'],
        dateHeure: DateTime.parse(json['dateHeure']),
        dureeMins: json['dureeMins'] ?? 60,
        service: json['service'],
        notes: json['notes'] ?? '',
        estConfirme: json['estConfirme'] ?? false,
      );
}

class ProduitStock {
  final String id;
  String nom;
  String categorie;
  int quantite;
  int seuilAlerte;
  String unite;
  String marque;
  String notes;

  ProduitStock({
    required this.id,
    required this.nom,
    required this.categorie,
    this.quantite = 0,
    this.seuilAlerte = 2,
    this.unite = 'unité(s)',
    this.marque = '',
    this.notes = '',
  });

  bool get estEnAlerte => quantite <= seuilAlerte;
  bool get estEpuise => quantite == 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'categorie': categorie,
        'quantite': quantite,
        'seuilAlerte': seuilAlerte,
        'unite': unite,
        'marque': marque,
        'notes': notes,
      };

  factory ProduitStock.fromJson(Map<String, dynamic> json) => ProduitStock(
        id: json['id'],
        nom: json['nom'],
        categorie: json['categorie'],
        quantite: json['quantite'] ?? 0,
        seuilAlerte: json['seuilAlerte'] ?? 2,
        unite: json['unite'] ?? 'unité(s)',
        marque: json['marque'] ?? '',
        notes: json['notes'] ?? '',
      );
}

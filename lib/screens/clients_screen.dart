// lib/screens/clients_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await StorageService.loadClients();
    setState(() => _clients = clients);
  }

  List<Client> get _filtres {
    if (_recherche.isEmpty) return _clients;
    final q = _recherche.toLowerCase();
    return _clients
        .where((c) =>
            c.nom.toLowerCase().contains(q) ||
            c.prenom.toLowerCase().contains(q) ||
            c.telephone.contains(q))
        .toList();
  }

  void _openForm({Client? client}) async {
    final result = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientForm(client: client),
    );
    if (result != null) {
      setState(() {
        _clients.removeWhere((c) => c.id == result.id);
        _clients.add(result);
        _clients.sort((a, b) => a.nom.compareTo(b.nom));
      });
      await StorageService.saveClients(_clients);
    }
  }

  void _voirFiche(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FicheClientScreen(client: client)),
    );
  }

  Future<void> _supprimer(Client client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${client.nomComplet} ?', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text('La fiche client sera supprimée définitivement.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler', style: GoogleFonts.nunito(color: AppTheme.texteClair))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _clients.removeWhere((c) => c.id == client.id));
      await StorageService.saveClients(_clients);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text('Clients', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _recherche = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un client…',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.texteClair),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtres.length} client${_filtres.length > 1 ? 's' : ''}',
                style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.texteClair),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _filtres.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline_rounded, size: 56, color: AppTheme.rose.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _recherche.isEmpty ? 'Aucun client enregistré\nAjoutez votre premier client !' : 'Aucun résultat',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: 15, color: AppTheme.texteClair),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtres.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final client = _filtres[i];
                      return _ClientCard(
                        client: client,
                        onTap: () => _voirFiche(client),
                        onEdit: () => _openForm(client: client),
                        onDelete: () => _supprimer(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientCard({required this.client, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final couleurs = [AppTheme.roseFonce, AppTheme.dore, AppTheme.vert, const Color(0xFF7B8FD4)];
    final couleur = couleurs[client.nom.codeUnits.first % couleurs.length];

    return Dismissible(
      key: Key(client.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: AppTheme.rouge, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Supprimer ?', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler', style: GoogleFonts.nunito(color: AppTheme.texteClair))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge), child: const Text('Supprimer')),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.blanc,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppTheme.rose.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleur.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(client.initiales,
                      style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 16, color: couleur)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.nomComplet,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.texte)),
                    if (client.telephone.isNotEmpty)
                      Text(client.telephone,
                          style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.texteClair)),
                    if (client.couleurCheveuxActuelle.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.palette_rounded, size: 12, color: AppTheme.dore),
                          const SizedBox(width: 4),
                          Text(client.couleurCheveuxActuelle,
                              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.dore, fontWeight: FontWeight.w600)),
                        ],
                      ),
                  ],
                ),
              ),
              if (client.dateDerniereVisite != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dernière visite', style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.texteClair)),
                    Text(
                      '${client.dateDerniereVisite!.day}/${client.dateDerniereVisite!.month}',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.texte),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.texteClair),
            ],
          ),
        ),
      ),
    );
  }
}

class _FicheClientScreen extends StatelessWidget {
  final Client client;
  const _FicheClientScreen({required this.client});

  @override
  Widget build(BuildContext context) {
    final couleurs = [AppTheme.roseFonce, AppTheme.dore, AppTheme.vert, const Color(0xFF7B8FD4)];
    final couleur = couleurs[client.nom.codeUnits.first % couleurs.length];

    return Scaffold(
      appBar: AppBar(
        title: Text(client.nomComplet),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(client.initiales,
                    style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 28, color: couleur)),
              ),
            ),
            const SizedBox(height: 12),
            Text(client.nomComplet, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.texte)),
            if (client.telephone.isNotEmpty)
              Text(client.telephone, style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.texteClair)),

            const SizedBox(height: 24),

            // Infos
            _InfoCard(titre: 'Informations', items: [
              if (client.couleurCheveuxActuelle.isNotEmpty)
                _InfoItem(icon: Icons.palette_rounded, label: 'Couleur actuelle', valeur: client.couleurCheveuxActuelle, couleur: AppTheme.dore),
              if (client.dateDerniereVisite != null)
                _InfoItem(icon: Icons.event_rounded, label: 'Dernière visite',
                  valeur: '${client.dateDerniereVisite!.day}/${client.dateDerniereVisite!.month}/${client.dateDerniereVisite!.year}',
                  couleur: AppTheme.roseFonce),
            ]),

            if (client.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.blanc,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.rosePale, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sticky_note_2_rounded, color: AppTheme.dore, size: 18),
                      const SizedBox(width: 8),
                      Text('Notes', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.texte)),
                    ]),
                    const SizedBox(height: 8),
                    Text(client.notes, style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.texteClair)),
                  ],
                ),
              ),
            ],

            if (client.servicesHistorique.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.blanc,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.rosePale, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.history_rounded, color: AppTheme.roseFonce, size: 18),
                      const SizedBox(width: 8),
                      Text('Prestations réalisées', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.texte)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: client.servicesHistorique.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.rosePale, borderRadius: BorderRadius.circular(20)),
                        child: Text(s, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.roseFonce, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titre;
  final List<Widget> items;
  const _InfoCard({required this.titre, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.rosePale, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.texte)),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;
  final Color couleur;
  const _InfoItem({required this.icon, required this.label, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: couleur, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.texteClair)),
              Text(valeur, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.texte)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientForm extends StatefulWidget {
  final Client? client;
  const _ClientForm({this.client});

  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _couleurCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c != null) {
      _nomCtrl.text = c.nom;
      _prenomCtrl.text = c.prenom;
      _telCtrl.text = c.telephone;
      _couleurCtrl.text = c.couleurCheveuxActuelle;
      _notesCtrl.text = c.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.blanc,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.rosePale, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(
              widget.client == null ? 'Nouveau client' : 'Modifier la fiche',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.texte),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom *'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom *'))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telCtrl,
              decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.texteClair, size: 18)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _couleurCtrl,
              decoration: const InputDecoration(labelText: 'Couleur cheveux actuelle', prefixIcon: Icon(Icons.palette_rounded, color: AppTheme.texteClair, size: 18)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (allergies, préférences…)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_prenomCtrl.text.isEmpty && _nomCtrl.text.isEmpty) return;
                  final client = Client(
                    id: widget.client?.id ?? const Uuid().v4(),
                    nom: _nomCtrl.text.trim(),
                    prenom: _prenomCtrl.text.trim(),
                    telephone: _telCtrl.text.trim(),
                    couleurCheveuxActuelle: _couleurCtrl.text.trim(),
                    notes: _notesCtrl.text.trim(),
                    dateDerniereVisite: widget.client?.dateDerniereVisite,
                    servicesHistorique: widget.client?.servicesHistorique,
                  );
                  Navigator.pop(context, client);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.client == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/theme.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<ProduitStock> _stock = [];
  String _categorieFiltre = 'Tout';
  String _recherche = '';

  static const _categories = [
    'Tout', 'Couleurs', 'Shampooings', 'Soins', 'Coiffage', 'Outillage', 'Divers',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stock = await StorageService.loadStock();
    setState(() => _stock = stock);
  }

  List<ProduitStock> get _filtres {
    var liste = _stock;
    if (_categorieFiltre != 'Tout') {
      liste = liste.where((p) => p.categorie == _categorieFiltre).toList();
    }
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      liste = liste.where((p) =>
          p.nom.toLowerCase().contains(q) ||
          p.marque.toLowerCase().contains(q)).toList();
    }
    liste.sort((a, b) {
      if (a.estEpuise && !b.estEpuise) return -1;
      if (!a.estEpuise && b.estEpuise) return 1;
      if (a.estEnAlerte && !b.estEnAlerte) return -1;
      if (!a.estEnAlerte && b.estEnAlerte) return 1;
      return a.nom.compareTo(b.nom);
    });
    return liste;
  }

  int get _nbAlertes => _stock.where((p) => p.estEnAlerte).length;

  void _openForm({ProduitStock? produit}) async {
    final result = await showModalBottomSheet<ProduitStock>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockForm(produit: produit),
    );
    if (result != null) {
      setState(() {
        _stock.removeWhere((p) => p.id == result.id);
        _stock.add(result);
      });
      await StorageService.saveStock(_stock);
    }
  }

  Future<void> _ajusterQuantite(ProduitStock produit, int delta) async {
    final nouveau = (produit.quantite + delta).clamp(0, 9999);
    setState(() {
      final idx = _stock.indexWhere((p) => p.id == produit.id);
      if (idx != -1) _stock[idx].quantite = nouveau;
    });
    await StorageService.saveStock(_stock);
  }

  Future<void> _supprimer(ProduitStock produit) async {
    setState(() => _stock.removeWhere((p) => p.id == produit.id));
    await StorageService.saveStock(_stock);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                    if (_nbAlertes > 0)
                      Text('$_nbAlertes produit${_nbAlertes > 1 ? 's' : ''} à commander',
                          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.rouge, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ],
            ),
          ),

          // Recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _recherche = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher un produit…',
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.texteClair),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filtre catégories
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _categorieFiltre == cat;
                return GestureDetector(
                  onTap: () => setState(() => _categorieFiltre = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.roseFonce : AppTheme.blanc,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppTheme.roseFonce : AppTheme.rosePale),
                    ),
                    child: Text(cat,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? AppTheme.blanc : AppTheme.texteClair,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _filtres.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: AppTheme.rose.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          _recherche.isEmpty ? 'Aucun produit\nAjoutez vos produits !' : 'Aucun résultat',
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
                      final p = _filtres[i];
                      return _ProduitCard(
                        produit: p,
                        onEdit: () => _openForm(produit: p),
                        onDelete: () => _supprimer(p),
                        onAjout: () => _ajusterQuantite(p, 1),
                        onRetrait: () => _ajusterQuantite(p, -1),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProduitCard extends StatelessWidget {
  final ProduitStock produit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAjout;
  final VoidCallback onRetrait;

  const _ProduitCard({
    required this.produit,
    required this.onEdit,
    required this.onDelete,
    required this.onAjout,
    required this.onRetrait,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    if (produit.estEpuise) {
      statusColor = AppTheme.rouge;
      statusIcon = Icons.remove_shopping_cart_rounded;
    } else if (produit.estEnAlerte) {
      statusColor = AppTheme.dore;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppTheme.vert;
      statusIcon = Icons.check_circle_rounded;
    }

    return Dismissible(
      key: Key(produit.id),
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
          title: Text('Supprimer ${produit.nom} ?', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler', style: GoogleFonts.nunito(color: AppTheme.texteClair))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rouge), child: const Text('Supprimer')),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.blanc,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: produit.estEpuise
                  ? AppTheme.rouge.withOpacity(0.3)
                  : produit.estEnAlerte
                      ? AppTheme.dore.withOpacity(0.3)
                      : AppTheme.rosePale,
              width: 1.5,
            ),
            boxShadow: [BoxShadow(color: AppTheme.rose.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produit.nom,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.texte)),
                    Row(
                      children: [
                        if (produit.marque.isNotEmpty)
                          Text('${produit.marque} · ', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.texteClair)),
                        Text(produit.categorie, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.texteClair)),
                      ],
                    ),
                  ],
                ),
              ),
              // Contrôles quantité
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyBtn(icon: Icons.remove, onTap: onRetrait, enabled: produit.quantite > 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Text(
                          '${produit.quantite}',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: produit.estEpuise ? AppTheme.rouge : produit.estEnAlerte ? AppTheme.dore : AppTheme.texte,
                          ),
                        ),
                        Text(produit.unite,
                            style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.texteClair)),
                      ],
                    ),
                  ),
                  _QtyBtn(icon: Icons.add, onTap: onAjout, enabled: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _QtyBtn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.rosePale : AppTheme.rosePale.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: enabled ? AppTheme.roseFonce : AppTheme.texteClair.withOpacity(0.3), size: 18),
      ),
    );
  }
}

// ── Formulaire produit ─────────────────────────────────────────────────────────
class _StockForm extends StatefulWidget {
  final ProduitStock? produit;
  const _StockForm({this.produit});

  @override
  State<_StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<_StockForm> {
  final _nomCtrl = TextEditingController();
  final _marqueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _categorie = 'Divers';
  int _quantite = 0;
  int _seuil = 2;
  String _unite = 'unité(s)';

  static const _categories = ['Couleurs', 'Shampooings', 'Soins', 'Coiffage', 'Outillage', 'Divers'];
  static const _unites = ['unité(s)', 'flacon(s)', 'tube(s)', 'sac(s)', 'litre(s)', 'kg'];

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    if (p != null) {
      _nomCtrl.text = p.nom;
      _marqueCtrl.text = p.marque;
      _notesCtrl.text = p.notes;
      _categorie = p.categorie;
      _quantite = p.quantite;
      _seuil = p.seuilAlerte;
      _unite = p.unite;
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
              widget.produit == null ? 'Nouveau produit' : 'Modifier le produit',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.texte),
            ),
            const SizedBox(height: 20),

            TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom du produit *')),
            const SizedBox(height: 12),
            TextFormField(controller: _marqueCtrl, decoration: const InputDecoration(labelText: 'Marque')),
            const SizedBox(height: 16),

            // Catégorie
            Text('Catégorie', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final sel = _categorie == c;
                return GestureDetector(
                  onTap: () => setState(() => _categorie = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.roseFonce : AppTheme.rosePale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(c, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13, color: sel ? AppTheme.blanc : AppTheme.texte)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantité et unité
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantité', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _QtyBtn(icon: Icons.remove, onTap: () => setState(() { if (_quantite > 0) _quantite--; }), enabled: _quantite > 0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_quantite', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.texte)),
                          ),
                          _QtyBtn(icon: Icons.add, onTap: () => setState(() => _quantite++), enabled: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alerte si ≤', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _QtyBtn(icon: Icons.remove, onTap: () => setState(() { if (_seuil > 0) _seuil--; }), enabled: _seuil > 0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('$_seuil', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.dore)),
                          ),
                          _QtyBtn(icon: Icons.add, onTap: () => setState(() => _seuil++), enabled: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unité
            Text('Unité', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.rosePale, borderRadius: BorderRadius.circular(14)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _unite,
                  isExpanded: true,
                  items: _unites.map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.nunito(color: AppTheme.texte)))).toList(),
                  onChanged: (v) => setState(() => _unite = v!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _nomCtrl.text.trim().isEmpty ? null : () {
                  final p = ProduitStock(
                    id: widget.produit?.id ?? const Uuid().v4(),
                    nom: _nomCtrl.text.trim(),
                    categorie: _categorie,
                    quantite: _quantite,
                    seuilAlerte: _seuil,
                    unite: _unite,
                    marque: _marqueCtrl.text.trim(),
                    notes: _notesCtrl.text.trim(),
                  );
                  Navigator.pop(context, p);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.produit == null ? 'Enregistrer' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

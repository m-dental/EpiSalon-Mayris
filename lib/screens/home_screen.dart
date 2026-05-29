// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import 'rdv_screen.dart';
import 'clients_screen.dart';
import 'stock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    RdvScreen(),
    ClientsScreen(),
    StockScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.blanc,
          boxShadow: [
            BoxShadow(
              color: AppTheme.rose.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Accueil', index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Agenda', index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.people_rounded, label: 'Clients', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
                _NavItem(icon: Icons.inventory_2_rounded, label: 'Stock', index: 3, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.rosePale : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.roseFonce : AppTheme.texteClair, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.roseFonce : AppTheme.texteClair,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<RendezVous> _rdvs = [];
  List<Client> _clients = [];
  List<ProduitStock> _stock = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rdvs = await StorageService.loadRendezVous();
    final clients = await StorageService.loadClients();
    final stock = await StorageService.loadStock();
    setState(() {
      _rdvs = rdvs;
      _clients = clients;
      _stock = stock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final aujourd = _rdvs.where((r) =>
      r.dateHeure.year == now.year &&
      r.dateHeure.month == now.month &&
      r.dateHeure.day == now.day
    ).toList()..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));

    final alertes = _stock.where((s) => s.estEnAlerte).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.roseFonce,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour ! ✨',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.texte,
                            )),
                        Text(_formatDate(now),
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppTheme.texteClair,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.rose, AppTheme.roseFonce],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: AppTheme.blanc, size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _StatCard(
                    icon: Icons.calendar_today_rounded,
                    valeur: '${aujourd.length}',
                    label: 'RDV aujourd\'hui',
                    couleur: AppTheme.roseFonce,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.people_rounded,
                    valeur: '${_clients.length}',
                    label: 'Clients',
                    couleur: AppTheme.dore,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    valeur: '$alertes',
                    label: 'Alertes stock',
                    couleur: alertes > 0 ? AppTheme.rouge : AppTheme.vert,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text("Agenda d'aujourd'hui",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.texte,
                  )),
              const SizedBox(height: 12),

              if (aujourd.isEmpty)
                _EmptyCard(
                  icon: Icons.free_breakfast_rounded,
                  message: 'Aucun rendez-vous aujourd\'hui\nProfitez de votre journée ! ☕',
                )
              else
                ...aujourd.map((rdv) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RdvDashCard(rdv: rdv),
                    )),

              if (alertes > 0) ...[
                const SizedBox(height: 24),
                Text('⚠️ Produits à commander',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.texte,
                    )),
                const SizedBox(height: 12),
                ..._stock
                    .where((s) => s.estEnAlerte)
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AlerteStockCard(produit: s),
                        )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month - 1]} ${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String valeur;
  final String label;
  final Color couleur;

  const _StatCard({required this.icon, required this.valeur, required this.label, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.blanc,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: couleur.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: couleur, size: 20),
            ),
            const SizedBox(height: 10),
            Text(valeur,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.texte,
                )),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppTheme.texteClair,
                )),
          ],
        ),
      ),
    );
  }
}

class _RdvDashCard extends StatelessWidget {
  final RendezVous rdv;
  const _RdvDashCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final heure = '${rdv.dateHeure.hour.toString().padLeft(2, '0')}h${rdv.dateHeure.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.rosePale, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.rosePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(heure,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.roseFonce,
                  fontSize: 15,
                )),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rdv.clientNom,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.texte,
                    )),
                Text(rdv.service,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppTheme.texteClair,
                    )),
              ],
            ),
          ),
          Text('${rdv.dureeMins} min',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppTheme.texteClair,
              )),
        ],
      ),
    );
  }
}

class _AlerteStockCard extends StatelessWidget {
  final ProduitStock produit;
  const _AlerteStockCard({required this.produit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: produit.estEpuise ? AppTheme.rouge.withOpacity(0.4) : AppTheme.dore.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (produit.estEpuise ? AppTheme.rouge : AppTheme.dore).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              produit.estEpuise ? Icons.remove_shopping_cart_rounded : Icons.warning_amber_rounded,
              color: produit.estEpuise ? AppTheme.rouge : AppTheme.dore,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.texte)),
                Text(produit.marque.isNotEmpty ? produit.marque : produit.categorie,
                    style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.texteClair)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (produit.estEpuise ? AppTheme.rouge : AppTheme.dore).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              produit.estEpuise ? 'Épuisé' : '${produit.quantite} ${produit.unite}',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: produit.estEpuise ? AppTheme.rouge : AppTheme.dore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.blanc,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.rosePale, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.rose, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 15, color: AppTheme.texteClair),
          ),
        ],
      ),
    );
  }
}

// lib/screens/rdv_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';
import '../utils/theme.dart';
 
class RdvScreen extends StatefulWidget {
  const RdvScreen({super.key});
 
  @override
  State<RdvScreen> createState() => _RdvScreenState();
}
 
class _RdvScreenState extends State<RdvScreen> {
  List<RendezVous> _rdvs = [];
  List<Client> _clients = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
 
  @override
  void initState() {
    super.initState();
    _load();
  }
 
  Future<void> _load() async {
    final rdvs = await StorageService.loadRendezVous();
    final clients = await StorageService.loadClients();
    setState(() { _rdvs = rdvs; _clients = clients; });
  }
 
  List<RendezVous> get _rdvsJour => _rdvs
      .where((r) =>
          r.dateHeure.year == _selectedDay.year &&
          r.dateHeure.month == _selectedDay.month &&
          r.dateHeure.day == _selectedDay.day)
      .toList()
    ..sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
 
  List<RendezVous> _rdvsPourJour(DateTime day) => _rdvs
      .where((r) => r.dateHeure.year == day.year && r.dateHeure.month == day.month && r.dateHeure.day == day.day)
      .toList();
 
  Future<void> _supprimerRdv(RendezVous rdv) async {
    setState(() => _rdvs.removeWhere((r) => r.id == rdv.id));
    await StorageService.saveRendezVous(_rdvs);
  }
 
  void _openForm({RendezVous? rdv}) async {
    final result = await showModalBottomSheet<RendezVous>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RdvForm(
        clients: _clients,
        rdv: rdv,
        defaultDate: _selectedDay,
      ),
    );
    if (result != null) {
      setState(() {
        _rdvs.removeWhere((r) => r.id == result.id);
        _rdvs.add(result);
      });
      await StorageService.saveRendezVous(_rdvs);
      // Mettre à jour la date de visite du client
      final idx = _clients.indexWhere((c) => c.id == result.clientId);
      if (idx != -1) {
        _clients[idx].dateDerniereVisite = result.dateHeure;
        if (!_clients[idx].servicesHistorique.contains(result.service)) {
          _clients[idx].servicesHistorique.add(result.service);
        }
        await StorageService.saveClients(_clients);
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text('Agenda', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _clients.isEmpty ? null : () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
 
          // Calendrier
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _rdvsPourJour,
            onDaySelected: (selected, focused) {
              setState(() { _selectedDay = selected; _focusedDay = focused; });
            },
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.texte,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.roseFonce),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.roseFonce),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.rose.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.roseFonce,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.dore,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: GoogleFonts.nunito(color: AppTheme.roseFonce),
              defaultTextStyle: GoogleFonts.nunito(color: AppTheme.texte),
              outsideTextStyle: GoogleFonts.nunito(color: AppTheme.texteClair.withOpacity(0.4)),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.texteClair, fontSize: 12),
              weekendStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.rose, fontSize: 12),
            ),
          ),
 
          const Divider(height: 1, color: AppTheme.rosePale),
 
          // Liste des RDV du jour
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  _rdvsJour.isEmpty ? 'Aucun rendez-vous' : '${_rdvsJour.length} rendez-vous',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.texteClair, fontSize: 14),
                ),
              ],
            ),
          ),
 
          Expanded(
            child: _rdvsJour.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded, size: 48, color: AppTheme.rose.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('Journée libre !',
                            style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.texteClair)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _rdvsJour.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final rdv = _rdvsJour[i];
                      return _RdvCard(
                        rdv: rdv,
                        onEdit: () => _openForm(rdv: rdv),
                        onDelete: () => _supprimerRdv(rdv),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
 
class _RdvCard extends StatelessWidget {
  final RendezVous rdv;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
 
  const _RdvCard({required this.rdv, required this.onEdit, required this.onDelete});
 
  @override
  Widget build(BuildContext context) {
    final h = rdv.dateHeure.hour.toString().padLeft(2, '0');
    final m = rdv.dateHeure.minute.toString().padLeft(2, '0');
 
    return Dismissible(
      key: Key(rdv.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer le rendez-vous ?', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
            content: Text('Cette action est irréversible.', style: GoogleFonts.nunito()),
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
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.rouge,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.blanc,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.rose.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.roseFonce,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                children: [
                  Text('$h:$m', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.roseFonce)),
                  Text('${rdv.dureeMins}min', style: GoogleFonts.nunito(fontSize: 11, color: AppTheme.texteClair)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rdv.clientNom, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.texte)),
                    Text(rdv.service, style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.texteClair)),
                    if (rdv.notes.isNotEmpty)
                      Text(rdv.notes, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.texteClair, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Icon(Icons.edit_rounded, color: AppTheme.rose, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ── Formulaire RDV ─────────────────────────────────────────────────────────────
class _RdvForm extends StatefulWidget {
  final List<Client> clients;
  final RendezVous? rdv;
  final DateTime defaultDate;
 
  const _RdvForm({required this.clients, this.rdv, required this.defaultDate});
 
  @override
  State<_RdvForm> createState() => _RdvFormState();
}
 
class _RdvFormState extends State<_RdvForm> {
  late DateTime _date;
  late TimeOfDay _heure;
  int _duree = 60;
  Client? _client;
  String _service = '';
  String _notes = '';
 
  final _serviceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
 
  static const _services = [
    'Coupe femme', 'Coupe homme', 'Coupe enfant',
    'Couleur', 'Balayage', 'Mèches',
    'Brushing', 'Mise en plis', 'Lissage',
    'Permanente', 'Soin', 'Autre',
  ];
 
  @override
  void initState() {
    super.initState();
    final rdv = widget.rdv;
    if (rdv != null) {
      _date = rdv.dateHeure;
      _heure = TimeOfDay.fromDateTime(rdv.dateHeure);
      _duree = rdv.dureeMins;
      _service = rdv.service;
      _serviceCtrl.text = rdv.service;
      _notes = rdv.notes;
      _notesCtrl.text = rdv.notes;
      _client = widget.clients.firstWhere((c) => c.id == rdv.clientId, orElse: () => widget.clients.first);
    } else {
      _date = widget.defaultDate;
      _heure = TimeOfDay.now();
      _client = widget.clients.isNotEmpty ? widget.clients.first : null;
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.rosePale, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.rdv == null ? 'Nouveau rendez-vous' : 'Modifier le rendez-vous',
              style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.texte),
            ),
            const SizedBox(height: 20),
 
            // Cliente
            Text('Cliente', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.rosePale,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Client>(
                  value: _client,
                  isExpanded: true,
                  hint: Text('Choisir une cliente', style: GoogleFonts.nunito(color: AppTheme.texteClair)),
                  items: widget.clients.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.nomComplet, style: GoogleFonts.nunito(color: AppTheme.texte, fontWeight: FontWeight.w600)),
                      )).toList(),
                  onChanged: (v) => setState(() => _client = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
 
            // Date et heure
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.rosePale,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: AppTheme.roseFonce, size: 18),
                              const SizedBox(width: 8),
                              Text('${_date.day}/${_date.month}/${_date.year}',
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.texte)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heure', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: _heure);
                          if (t != null) setState(() => _heure = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.rosePale,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppTheme.roseFonce, size: 18),
                              const SizedBox(width: 8),
                              Text('${_heure.hour.toString().padLeft(2, '0')}h${_heure.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.texte)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
 
            // Durée
            Text('Durée', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30, 45, 60, 90, 120, 150, 180, 210, 240, 300].map((min) {
                final selected = _duree == min;
                String label;
                if (min < 60) {
                  label = '${min}min';
                } else if (min % 60 == 0) {
                  label = '${min ~/ 60}h';
                } else {
                  label = '${min ~/ 60}h${min % 60}';
                }
                return GestureDetector(
                  onTap: () => setState(() => _duree = min),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.roseFonce : AppTheme.rosePale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected ? AppTheme.blanc : AppTheme.texteClair,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
 
            // Service
            Text('Prestation', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.texteClair)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _services.map((s) {
                final selected = _service == s;
                return GestureDetector(
                  onTap: () => setState(() { _service = s; _serviceCtrl.text = s; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.roseFonce : AppTheme.rosePale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: selected ? AppTheme.blanc : AppTheme.texte,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
 
            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optionnel)'),
              maxLines: 2,
              onChanged: (v) => _notes = v,
            ),
            const SizedBox(height: 24),
 
            // Bouton enregistrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _client == null || _service.isEmpty ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.rdv == null ? 'Enregistrer le rendez-vous' : 'Mettre à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  void _save() {
    final dateHeure = DateTime(
      _date.year, _date.month, _date.day,
      _heure.hour, _heure.minute,
    );
    final rdv = RendezVous(
      id: widget.rdv?.id ?? const Uuid().v4(),
      clientId: _client!.id,
      clientNom: _client!.nomComplet,
      dateHeure: dateHeure,
      dureeMins: _duree,
      service: _service,
      notes: _notes,
    );
    Navigator.pop(context, rdv);
  }
}

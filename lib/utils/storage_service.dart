// lib/utils/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _clientsKey = 'clients';
  static const _rdvKey = 'rendez_vous';
  static const _stockKey = 'stock';

  // ── Clients ────────────────────────────────────────────────────────────────
  static Future<List<Client>> loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_clientsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Client.fromJson(e)).toList();
  }

  static Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientsKey, jsonEncode(clients.map((c) => c.toJson()).toList()));
  }

  // ── Rendez-vous ────────────────────────────────────────────────────────────
  static Future<List<RendezVous>> loadRendezVous() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_rdvKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => RendezVous.fromJson(e)).toList();
  }

  static Future<void> saveRendezVous(List<RendezVous> rdvs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rdvKey, jsonEncode(rdvs.map((r) => r.toJson()).toList()));
  }

  // ── Stock ──────────────────────────────────────────────────────────────────
  static Future<List<ProduitStock>> loadStock() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_stockKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ProduitStock.fromJson(e)).toList();
  }

  static Future<void> saveStock(List<ProduitStock> stock) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stockKey, jsonEncode(stock.map((s) => s.toJson()).toList()));
  }
}

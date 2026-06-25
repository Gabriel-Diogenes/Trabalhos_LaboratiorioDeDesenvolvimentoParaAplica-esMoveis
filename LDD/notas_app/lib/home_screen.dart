import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'note_service.dart';
import 'storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteService _noteService = NoteService();
  bool _showOnlyFavorites = false;

  Future<void> _signOut() async {
    // O signOut do Google pode falhar quando o login foi feito por
    // e-mail/senha (ou na web sem clientId). Ignoramos esse erro para
    // garantir que o signOut do Firebase sempre seja executado.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviando foto...')),
        );
      }

      final url = await StorageService().uploadProfilePicture(
        File(pickedFile.path),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              url != null
                  ? 'Foto atualizada com sucesso!'
                  : 'Erro ao enviar foto.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _showAddNoteDialog() async {
    final tituloController = TextEditingController();
    final conteudoController = TextEditingController();
    bool favorito = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Nova Nota'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                TextField(
                  controller: conteudoController,
                  decoration: const InputDecoration(labelText: 'Conteúdo'),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favorita'),
                  value: favorito,
                  onChanged: (v) => setStateDialog(() => favorito = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final titulo = tituloController.text.trim();
                final conteudo = conteudoController.text.trim();

                if (titulo.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('O título é obrigatório.')),
                  );
                  return;
                }

                try {
                  await _noteService.addNote(
                    titulo: titulo,
                    conteudo: conteudo,
                    favorito: favorito,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erro ao salvar nota: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota excluída.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Pessoais'),
        actions: [
          IconButton(
            tooltip: _showOnlyFavorites
                ? 'Mostrar todas'
                : 'Mostrar só favoritas',
            icon: Icon(
              _showOnlyFavorites ? Icons.star : Icons.star_border,
            ),
            onPressed: () =>
                setState(() => _showOnlyFavorites = !_showOnlyFavorites),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        tooltip: 'Adicionar nota',
        child: const Icon(Icons.add),
      ),
      body: user == null
          ? const Center(child: Text('Usuário não encontrado.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _noteService.notesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro ao carregar notas: ${snapshot.error}'),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final favoriteDocs = allDocs
                    .where((d) => (d.data()['favorito'] ?? false) == true)
                    .toList();
                final displayedDocs =
                    _showOnlyFavorites ? favoriteDocs : allDocs;

                return Column(
                  children: [
                    _ProfileHeader(
                      uid: user.uid,
                      email: user.email ?? '',
                      totalNotes: allDocs.length,
                      favoriteNotes: favoriteDocs.length,
                      onTapPhoto: _pickAndUploadPhoto,
                    ),
                    _WeeklyChart(docs: allDocs),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildNotesList(snapshot, displayedDocs),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildNotesList(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (docs.isEmpty) {
      return Center(
        child: Text(
          _showOnlyFavorites
              ? 'Nenhuma nota favorita ainda.'
              : 'Nenhuma nota. Toque em + para criar.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final titulo = data['titulo'] ?? '';
        final conteudo = data['conteudo'] ?? '';
        final favorito = (data['favorito'] ?? false) == true;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        return Dismissible(
          key: ValueKey(doc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteNote(doc.id),
          child: ListTile(
            title: Text(titulo),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (conteudo.toString().isNotEmpty) Text(conteudo),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            isThreeLine: conteudo.toString().isNotEmpty && createdAt != null,
            trailing: IconButton(
              icon: Icon(
                favorito ? Icons.star : Icons.star_border,
                color: favorito ? Colors.amber : null,
              ),
              onPressed: () =>
                  _noteService.toggleFavorite(doc.id, favorito),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

/// Cabeçalho de perfil com foto, nome, e-mail e estatísticas.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.uid,
    required this.email,
    required this.totalNotes,
    required this.favoriteNotes,
    required this.onTapPhoto,
  });

  final String uid;
  final String email;
  final int totalNotes;
  final int favoriteNotes;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = data?['name'] ?? 'Usuário';
        final photo = data?['photo'] ?? '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onTapPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: photo.toString().isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.toString().isEmpty
                              ? const Icon(Icons.person, size: 32)
                              : null,
                        ),
                        const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.camera_alt,
                              size: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, $name!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Notas',
                      value: totalNotes,
                      icon: Icons.note,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Favoritas',
                      value: favoriteNotes,
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras com a quantidade de notas por dia da semana (bônus).
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.docs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  static const _labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    // counts[0] = segunda ... counts[6] = domingo (DateTime.weekday: 1..7)
    final counts = List<int>.filled(7, 0);
    for (final doc in docs) {
      final ts = doc.data()['createdAt'] as Timestamp?;
      if (ts == null) continue;
      final weekday = ts.toDate().weekday; // 1 = seg ... 7 = dom
      counts[weekday - 1]++;
    }

    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount == 0 ? 1 : maxCount).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notas por dia da semana',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _labels[i],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[i].toDouble(),
                          width: 14,
                          color: Colors.blue,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

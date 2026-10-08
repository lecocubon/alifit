import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/text/text_normalize.dart';
import '../../domain/nutri_guide/nutri_guide.dart';
import '../../domain/nutri_guide/nutri_guide_providers.dart';
import '../common/medical_disclaimer_banner.dart';
import 'quality_badge.dart';

/// Guía de porciones de intercambio entregada por el nutricionista:
/// grupos de alimentos, medidas de una porción y la etiqueta de calidad /
/// índice glicémico de cada alimento.
class NutriGuideScreen extends ConsumerStatefulWidget {
  const NutriGuideScreen({super.key});

  @override
  ConsumerState<NutriGuideScreen> createState() => _NutriGuideScreenState();
}

class _NutriGuideScreenState extends ConsumerState<NutriGuideScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(nutriGuideProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guía del nutri')),
      body: SafeArea(
        child: guideAsync.when(
          data: (guide) => guide == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No hay una guía importada. Puedes importarla desde '
                      'Perfil → Mi plan del nutri.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar alimento en la guía...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    Expanded(
                      child: _query.trim().isEmpty
                          ? _GuideOverview(guide: guide)
                          : _SearchResults(guide: guide, query: _query),
                    ),
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _GuideOverview extends StatelessWidget {
  const _GuideOverview({required this.guide});

  final NutriGuide guide;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _IntroCard(guide: guide),
        const SizedBox(height: 8),
        const _LegendCard(),
        const SizedBox(height: 8),
        for (final group in guide.groups) _GroupTile(group: group),
        const SizedBox(height: 16),
        const MedicalDisclaimerBanner(),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.guide});

  final NutriGuide guide;

  @override
  Widget build(BuildContext context) {
    final date = guide.date;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guide.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              date == null
                  ? guide.source
                  : '${guide.source} · '
                        '${DateFormat('d MMM y', 'es').format(date)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final paragraph in guide.intro) ...[
              const SizedBox(height: 8),
              Text(paragraph),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: const Text('¿Qué significan las etiquetas?'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final quality in NutriQuality.values) ...[
            QualityBadge(quality: quality),
            const SizedBox(height: 4),
            Text(
              quality.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});

  final GuideGroup group;

  @override
  Widget build(BuildContext context) {
    final single = group.subgroups.length == 1 ? group.subgroups.first : null;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(group.name),
        subtitle: single?.portion == null
            ? null
            : Text('1 porción: ${single!.portion!.summary}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final subgroup in group.subgroups)
            _SubgroupSection(
              subgroup: subgroup,
              showPortionLine: single == null,
            ),
        ],
      ),
    );
  }
}

class _SubgroupSection extends StatelessWidget {
  const _SubgroupSection({
    required this.subgroup,
    required this.showPortionLine,
  });

  final GuideSubgroup subgroup;
  final bool showPortionLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subgroup.label != null) ...[
          const SizedBox(height: 8),
          Text(subgroup.label!, style: textTheme.titleSmall),
        ],
        if (showPortionLine && subgroup.portion != null)
          Text(
            '1 porción: ${subgroup.portion!.summary}',
            style: textTheme.bodySmall,
          ),
        if (subgroup.note != null) ...[
          const SizedBox(height: 2),
          Text(
            subgroup.note!,
            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        for (final block in subgroup.blocks) ...[
          const SizedBox(height: 10),
          QualityBadge(quality: block.quality),
          for (final food in block.foods) _FoodRow(food: food),
        ],
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food});

  final GuideFood food;

  @override
  Widget build(BuildContext context) {
    final detail = food.per100g?.summary ?? food.measureText;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: Text(food.name)),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              detail,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHit {
  const _SearchHit({
    required this.food,
    required this.quality,
    required this.groupLabel,
    required this.portion,
  });

  final GuideFood food;
  final NutriQuality quality;
  final String groupLabel;
  final PortionMacros? portion;
}

List<_SearchHit> _search(NutriGuide guide, String query) {
  final normalizedQuery = normalizeForSearch(query);
  final hits = <_SearchHit>[];
  for (final group in guide.groups) {
    for (final subgroup in group.subgroups) {
      final groupLabel = subgroup.label == null || group.name == 'Snacks'
          ? group.name
          : '${group.name} · ${subgroup.label}';
      for (final block in subgroup.blocks) {
        for (final food in block.foods) {
          if (normalizeForSearch(food.name).contains(normalizedQuery)) {
            hits.add(
              _SearchHit(
                food: food,
                quality: block.quality,
                groupLabel: groupLabel,
                portion: subgroup.portion,
              ),
            );
          }
        }
      }
    }
  }
  return hits;
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.guide, required this.query});

  final NutriGuide guide;
  final String query;

  @override
  Widget build(BuildContext context) {
    final hits = _search(guide, query);
    if (hits.isEmpty) {
      return const Center(child: Text('Sin resultados en la guía.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: hits.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final hit = hits[index];
        final per100g = hit.food.per100g;
        final lines = <String>[
          if (per100g == null && hit.food.measureText.isNotEmpty)
            hit.food.measureText,
          hit.groupLabel,
          if (per100g != null)
            'Por 100 g: ${per100g.summary}'
          else if (hit.portion != null)
            '1 porción: ${hit.portion!.summary}',
        ];
        return ListTile(
          title: Text(hit.food.name),
          subtitle: Text(lines.join('\n')),
          isThreeLine: lines.length >= 3,
          trailing: QualityBadge(quality: hit.quality),
        );
      },
    );
  }
}

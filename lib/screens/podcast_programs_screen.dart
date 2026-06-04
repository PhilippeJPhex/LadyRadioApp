import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../core/app_theme.dart';
import 'program_screen.dart';

class PodcastProgramsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> podcastPrograms;

  const PodcastProgramsScreen({super.key, required this.podcastPrograms});

  @override
  Widget build(BuildContext context) {
    final groupedPrograms = _groupProgramsByCategory(podcastPrograms);
    final hasCategories = groupedPrograms.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I nostri podcast'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: hasCategories
          ? _buildCategorizedList(context, groupedPrograms)
          : _buildFlatList(context, podcastPrograms),
    );
  }

  Widget _buildCategorizedList(
    BuildContext context,
    Map<String, List<Map<String, dynamic>>> groupedPrograms,
  ) {
    final categories = groupedPrograms.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        final programs = groupedPrograms[category] ?? [];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              iconColor: AppTheme.primaryColor,
              collapsedIconColor: AppTheme.primaryColor,
              title: Text(
                category,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                '${programs.length} podcast',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              children: programs
                  .map(
                    (program) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ProgramCard(
                        program: program,
                        imageBuilder: _buildProgramImage,
                        onTap: () => _openProgram(context, program),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlatList(
    BuildContext context,
    List<Map<String, dynamic>> programs,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: programs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final program = programs[index];
        return _ProgramCard(
          program: program,
          imageBuilder: _buildProgramImage,
          onTap: () => _openProgram(context, program),
        );
      },
    );
  }

  void _openProgram(BuildContext context, Map<String, dynamic> program) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProgramScreen(programData: program)),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupProgramsByCategory(
    List<Map<String, dynamic>> programs,
  ) {
    final categorized = programs
        .where((program) => _categoryFor(program).isNotEmpty)
        .toList();
    if (categorized.isEmpty) return {};

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final program in programs) {
      final category = _categoryFor(program);
      if (category.isEmpty) {
        grouped.putIfAbsent('Altri podcast', () => []).add(program);
      } else {
        grouped.putIfAbsent(category, () => []).add(program);
      }
    }

    return grouped;
  }

  String _categoryFor(Map<String, dynamic> program) {
    return (program['podcastCategory'] ?? '').toString().trim();
  }

  Widget _buildProgramImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        placeholder: (_, _) => const SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        errorWidget: (_, _, _) => Image.asset(
          AppConstants.logoAsset,
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
      );
    }

    return Image.asset(
      AppConstants.logoAsset,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final Widget Function(String? imageUrl) imageBuilder;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.imageBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBuilder(program['image']),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program['title'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ascolta le puntate disponibili',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class TasksScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const TasksScreen({super.key, this.onSearchTap});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilter = 0; // 0=All, 1=Voice, 2=Image, 3=Text

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onSearchTap ?? () => context.push('/tasks/empty'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Symbols.search, size: 22, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const TasksFiltersSheet(),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Symbols.tune, size: 22, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MintChip(
                  label: 'All 24',
                  isSelected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Voice 12',
                  isSelected: _selectedFilter == 1,
                  icon: Symbols.mic,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Image 7',
                  isSelected: _selectedFilter == 2,
                  icon: Symbols.photo_camera,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Text 5',
                  isSelected: _selectedFilter == 3,
                  icon: Symbols.text_fields,
                  onTap: () => setState(() => _selectedFilter = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section "High reward"
          Text(
            'High reward',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),

          // Highlight Card
          GestureDetector(
            onTap: () => context.push('/tasks/task-detail'),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Symbols.mic, size: 22, color: AppColors.ink),
                      ),
                      const MintTypePill(type: MintPillType.voice),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Say a short phrase in Yoruba',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '~30s · 124 spots left',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+0.50',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Section "All tasks"
          Text(
            'All tasks',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),

          _buildTaskRow(
            context,
            icon: Symbols.photo_camera,
            title: 'Photograph a street sign',
            subtitle: '~45s · 42 spots left',
            reward: '+0.35',
            iconBg: AppColors.peach,
            onTap: () => context.push('/tasks/photo/capture'),
          ),
          const SizedBox(height: 10),
          _buildTaskRow(
            context,
            icon: Symbols.text_fields,
            title: 'Translate 3 phrases to Pidgin',
            subtitle: '~1 min · 88 spots left',
            reward: '+0.40',
            iconBg: AppColors.sky,
            onTap: () => context.push('/tasks/text'),
          ),
          const SizedBox(height: 10),
          _buildTaskRow(
            context,
            icon: Symbols.mic,
            title: 'Pronounce 5 tech terms',
            subtitle: '~40s · 16 spots left',
            reward: '+0.30',
            iconBg: AppColors.butter,
            onTap: () => context.push('/tasks/voice/ready'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String reward,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 24, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                reward,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Tasks Filters Bottom Sheet
// ==========================================
class TasksFiltersSheet extends StatefulWidget {
  const TasksFiltersSheet({super.key});

  @override
  State<TasksFiltersSheet> createState() => _TasksFiltersSheetState();
}

class _TasksFiltersSheetState extends State<TasksFiltersSheet> {
  int _selectedType = 0;
  int _selectedTime = 0;
  bool _hideCompleted = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC9DFD4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Filter tasks',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),

          // Type
          Text(
            'Type',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MintChip(
                  label: 'All',
                  isSelected: _selectedType == 0,
                  onTap: () => setState(() => _selectedType = 0),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Voice',
                  icon: Symbols.mic,
                  isSelected: _selectedType == 1,
                  onTap: () => setState(() => _selectedType = 1),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Image',
                  icon: Symbols.photo_camera,
                  isSelected: _selectedType == 2,
                  onTap: () => setState(() => _selectedType = 2),
                ),
                const SizedBox(width: 8),
                MintChip(
                  label: 'Text',
                  icon: Symbols.text_fields,
                  isSelected: _selectedType == 3,
                  onTap: () => setState(() => _selectedType = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estimated time
          Text(
            'Estimated time',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          MintSegmentedControl(
            options: const ['Under 1 min', '1–3 min', 'Any'],
            selectedIndex: _selectedTime,
            onSelected: (i) => setState(() => _selectedTime = i),
          ),
          const SizedBox(height: 20),

          // Hide tasks done toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hide tasks I’ve done',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              Switch(
                value: _hideCompleted,
                activeColor: AppColors.mint,
                activeTrackColor: AppColors.ink,
                onChanged: (val) => setState(() => _hideCompleted = val),
              ),
            ],
          ),
          const SizedBox(height: 24),

          MintButton(
            label: 'Show 24 tasks',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

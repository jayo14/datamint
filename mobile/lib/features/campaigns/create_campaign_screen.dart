import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/providers/app_providers.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1 Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'AI & Machine Learning';
  String _selectedModality = 'TEXT';

  // Step 2 Controllers
  final _instructionsController = TextEditingController();
  final _minQualityScoreController = TextEditingController(text: '80');

  // Step 3 Controllers
  final _rewardController = TextEditingController(text: '0.50');
  final _submissionsTargetController = TextEditingController(text: '100');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _minQualityScoreController.dispose();
    _rewardController.dispose();
    _submissionsTargetController.dispose();
    super.dispose();
  }

  double get _totalBudget {
    final reward = double.tryParse(_rewardController.text) ?? 0.0;
    final count = int.tryParse(_submissionsTargetController.text) ?? 0;
    return reward * count;
  }

  Future<void> _handleSaveAndPublish({bool publishImmediately = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(campaignServiceProvider);
      final reward = double.tryParse(_rewardController.text) ?? 0.50;
      final target = int.tryParse(_submissionsTargetController.text) ?? 100;

      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'data_type': _selectedModality,
        'instructions': _instructionsController.text.trim(),
        'reward_per_submission': reward,
        'total_budget': _totalBudget,
        'min_submissions': 1,
        'max_submissions': target,
        'requirements': {
          'min_quality_score': int.tryParse(_minQualityScoreController.text) ?? 80,
        },
      };

      // 1. Create draft
      final draft = await service.createDraft(payload);

      // 2. Publish if requested
      if (publishImmediately) {
        await service.publishCampaign(draft.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publishImmediately
                  ? 'Campaign published to marketplace!'
                  : 'Campaign draft saved successfully.',
            ),
            backgroundColor: AppColors.mintActive,
          ),
        );

        // Reset
        setState(() {
          _currentStep = 0;
          _titleController.clear();
          _descriptionController.clear();
          _instructionsController.clear();
        });
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create campaign: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PillBadge(
                    text: 'Dataset Creation Portal',
                    icon: Icons.shield_outlined,
                  ),
                  Text(
                    'Step ${_currentStep + 1} of 3',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Create Dataset Campaign',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Request verified multi-modal AI data and fund audited escrow on Celo',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),

              // Stepper Progress Indicators
              Row(
                children: [
                  _buildStepPill(0, 'Fundamentals'),
                  const SizedBox(width: 6),
                  _buildStepPill(1, 'Rules & QA'),
                  const SizedBox(width: 6),
                  _buildStepPill(2, 'Escrow Budget'),
                ],
              ),
              const SizedBox(height: 18),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.mintBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) _buildStep1Basics(),
                    if (_currentStep == 1) _buildStep2Rules(),
                    if (_currentStep == 2) _buildStep3Budget(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      flex: 1,
                      child: DataMintButton(
                        label: 'Back',
                        isOutlined: true,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (_currentStep < 2) ...[
                    Expanded(
                      flex: 2,
                      child: DataMintButton(
                        label: 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _currentStep++);
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      flex: 2,
                      child: DataMintButton(
                        label: 'Fund Escrow & Publish',
                        icon: Icons.rocket_launch_rounded,
                        isLoading: _isLoading,
                        onPressed: () => _handleSaveAndPublish(publishImmediately: true),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPill(int stepIndex, String title) {
    final isSelected = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mint
              : (isDone ? AppColors.mintBg : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppColors.mintActive
                : (isDone ? AppColors.mintActive.withValues(alpha: 0.5) : AppColors.mintBorder),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone) ...[
              const Icon(Icons.check_rounded, size: 14, color: AppColors.mintActive),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.ink : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Basics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaign Fundamentals',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        const Text(
          'Campaign Title',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g., Diverse Conversational Speech Dataset',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
        ),
        const SizedBox(height: 16),

        // Description
        const Text(
          'Overview & Objective',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Explain the purpose and specific requirements for this AI dataset...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
        ),
        const SizedBox(height: 16),

        // Data Modality
        const Text(
          'Data Modality',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildModalityOption('TEXT', 'Text', Icons.text_snippet_rounded),
            const SizedBox(width: 10),
            _buildModalityOption('VOICE', 'Voice', Icons.mic_rounded),
            const SizedBox(width: 10),
            _buildModalityOption('IMAGE', 'Image', Icons.image_rounded),
          ],
        ),
        const SizedBox(height: 16),

        // Category Dropdown
        const Text(
          'Domain Category',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(),
          items: const [
            DropdownMenuItem(value: 'AI & Machine Learning', child: Text('AI & Machine Learning')),
            DropdownMenuItem(value: 'Speech & Audio', child: Text('Speech & Audio')),
            DropdownMenuItem(value: 'Computer Vision', child: Text('Computer Vision')),
            DropdownMenuItem(
                value: 'Natural Language Processing', child: Text('NLP & Linguistics')),
            DropdownMenuItem(value: 'Healthcare & Science', child: Text('Healthcare & Science')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ],
    );
  }

  Widget _buildModalityOption(String value, String label, IconData icon) {
    final isSelected = _selectedModality == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedModality = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mintBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.mintActive : AppColors.mintBorder,
              width: isSelected ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.mintActive : AppColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? AppColors.ink : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Rules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contributor Guidelines & AI Rules',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),

        // Instructions
        const Text(
          'Detailed Instructions for Contributors',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _instructionsController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Specify exact requirements (e.g., quiet background, accent, lighting, format)...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Instructions are required' : null,
        ),
        const SizedBox(height: 16),

        // Minimum AI Acceptance Score
        const Text(
          'Minimum AI Confidence Score Threshold (%)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _minQualityScoreController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '80',
            suffixText: '%',
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Budget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escrow Budget & Pricing',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),

        // Reward per Submission
        const Text(
          'Reward per Approved Submission (cUSD)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _rewardController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '0.50',
            prefixText: '\$ ',
            suffixText: 'cUSD',
          ),
        ),
        const SizedBox(height: 16),

        // Target Submissions
        const Text(
          'Target Number of Submissions',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _submissionsTargetController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '100',
            suffixText: 'submissions',
          ),
        ),
        const SizedBox(height: 20),

        // Budget Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.mintBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.mintBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Escrow Deposit:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${_totalBudget.toStringAsFixed(2)} cUSD',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: AppColors.mintBorder.withValues(alpha: 0.7)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppColors.mintActive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funds are locked securely in DataMint smart escrow on Celo and released instantly to contributors upon AI validation approval.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

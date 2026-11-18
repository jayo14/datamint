import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
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
            backgroundColor: AppColors.mintPrimary,
          ),
        );
        // Switch to campaigns list
        context.go('/home');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Wizard Progress Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'Basics'),
                    _buildStepDivider(),
                    _buildStepIndicator(1, 'Rules'),
                    _buildStepDivider(),
                    _buildStepIndicator(2, 'Budget'),
                  ],
                ),
              ),
              const Divider(),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildStep1Basics(),
                      _buildStep2Rules(),
                      _buildStep3Budget(),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: DataMintButton(
                          label: 'Back',
                          isOutlined: true,
                          onPressed: () => setState(() => _currentStep--),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DataMintButton(
                        label: _currentStep == 2 ? 'Publish Campaign' : 'Next Step',
                        isLoading: _isLoading,
                        onPressed: () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            _handleSaveAndPublish(publishImmediately: true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isPassed = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isPassed ? AppColors.mintPrimary : Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isPassed && !isCurrent
                ? const Icon(Icons.check, size: 14, color: Colors.black)
                : Text(
                    '${stepIndex + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isPassed ? AppColors.mintPrimary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return const Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Divider(thickness: 1.5),
      ),
    );
  }

  Widget _buildStep1Basics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1: Campaign Fundamentals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Title
        const Text('Campaign Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
        const Text('Overview & Objective', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Explain the goal of this dataset collection...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
        ),
        const SizedBox(height: 16),

        // Data Modality
        const Text('Data Modality', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
        const Text('Domain Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(),
          items: const [
            DropdownMenuItem(value: 'AI & Machine Learning', child: Text('AI & Machine Learning')),
            DropdownMenuItem(value: 'Speech & Audio', child: Text('Speech & Audio')),
            DropdownMenuItem(value: 'Computer Vision', child: Text('Computer Vision')),
            DropdownMenuItem(value: 'Natural Language Processing', child: Text('NLP & Linguistics')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedModality = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.mintPrimary.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.mintPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.mintPrimary : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? AppColors.mintPrimary : null,
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
        const Text(
          'Step 2: Contributor Guidelines & AI Rules',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Instructions
        const Text(
          'Detailed Instructions for Contributors',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _instructionsController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Specify exact requirements (e.g. background quietness, language accent, text length, lighting)...',
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Instructions are required' : null,
        ),
        const SizedBox(height: 16),

        // Minimum AI Acceptance Score
        const Text(
          'Minimum AI Confidence Score Threshold (%)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3: Escrow Budget & Pricing',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Reward per Submission
        const Text(
          'Reward per Approved Submission (cUSD)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
        const SizedBox(height: 24),

        // Budget Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Escrow Allocation:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${_totalBudget.toStringAsFixed(2)} cUSD',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mintPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.celoGold),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funds are held securely in DataMint DatasetEscrow on Celo and disbursed trustlessly via EIP-712 payout vouchers.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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

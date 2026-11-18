import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class SubmissionEditorScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final CampaignModel? campaign;

  const SubmissionEditorScreen({
    super.key,
    required this.campaignId,
    this.campaign,
  });

  @override
  ConsumerState<SubmissionEditorScreen> createState() => _SubmissionEditorScreenState();
}

class _SubmissionEditorScreenState extends ConsumerState<SubmissionEditorScreen> {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitializing = true;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String? _statusMessage;
  String? _errorMessage;

  String? _draftId;
  CampaignModel? _campaign;

  // Media state
  XFile? _selectedImage;
  String? _recordedAudioPath;
  bool _isRecording = false;
  bool _isPlayingAudio = false;
  int _recordDurationSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _initializeDraft();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeDraft() async {
    try {
      final submissionService = ref.read(submissionServiceProvider);
      // If campaign wasn't passed via routing extra, fetch it
      if (_campaign == null) {
        final marketplaceService = ref.read(marketplaceServiceProvider);
        _campaign = await marketplaceService.getCampaignDetails(widget.campaignId);
      }

      // Create initial draft on backend
      final draft = await submissionService.createDraft(widget.campaignId);
      _draftId = draft.id;
    } catch (e) {
      _errorMessage = 'Failed to initialize draft session: $e';
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  // Audio Recording Flow
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000);
        // Start recording to temporary path or stream
        await _audioRecorder.start(config, path: '');
        setState(() {
          _isRecording = true;
          _recordDurationSeconds = 0;
          _recordedAudioPath = null;
        });

        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordDurationSeconds >= AppConstants.maxAudioDurationSeconds) {
            _stopRecording();
          } else {
            setState(() => _recordDurationSeconds++);
          }
        });
      } else {
        setState(() => _errorMessage = 'Microphone permission denied.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedAudioPath = path;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error stopping recording: $e');
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_recordedAudioPath == null) return;

    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedAudioPath!));
      setState(() => _isPlayingAudio = true);
    }
  }

  // Image Selection Flow
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _selectedImage = file);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture image: $e');
    }
  }

  // Final Multi-step Submission Flow
  Future<void> _handleSubmit() async {
    if (_draftId == null) {
      setState(() => _errorMessage = 'Draft session not initialized');
      return;
    }

    final modality = DataModalityExt.fromString(_campaign?.dataType ?? 'TEXT');

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = 'Preparing submission...';
      _uploadProgress = 0.1;
    });

    try {
      final submissionService = ref.read(submissionServiceProvider);
      final apiClient = ref.read(apiClientProvider);

      if (modality == DataModality.text) {
        final text = _textController.text.trim();
        if (text.isEmpty) {
          throw const ValidationException(message: 'Submission text cannot be empty');
        }

        // 1. Update text draft
        setState(() => _statusMessage = 'Saving text content...');
        await submissionService.updateDraft(_draftId!, textContent: text);
        _uploadProgress = 0.6;
      } else if (modality == DataModality.voice) {
        if (_recordedAudioPath == null) {
          throw const ValidationException(message: 'Please record audio before submitting');
        }

        final audioBytes = await File(_recordedAudioPath!).readAsBytes();
        setState(() => _statusMessage = 'Requesting secure upload authorization...');

        // 1. Request presigned upload URL
        final uploadInfo = await submissionService.getUploadUrl(
          _draftId!,
          contentType: 'audio/m4a',
          fileName: 'submission.m4a',
        );

        final uploadUrl = uploadInfo['upload_url'] as String;
        final assetId = uploadInfo['asset_id'] as String;

        // 2. Upload binary payload
        setState(() => _statusMessage = 'Uploading audio payload...');
        await apiClient.uploadBinary(
          uploadUrl: uploadUrl,
          bytes: audioBytes,
          contentType: 'audio/m4a',
          onProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = 0.2 + (0.5 * (sent / total)));
            }
          },
        );

        // 3. Confirm upload
        setState(() => _statusMessage = 'Confirming asset storage...');
        await submissionService.confirmUpload(_draftId!, assetId: assetId);
        _uploadProgress = 0.8;
      } else if (modality == DataModality.image) {
        if (_selectedImage == null) {
          throw const ValidationException(message: 'Please select an image before submitting');
        }

        final imageBytes = await _selectedImage!.readAsBytes();
        setState(() => _statusMessage = 'Requesting secure upload authorization...');

        // 1. Request presigned upload URL
        final uploadInfo = await submissionService.getUploadUrl(
          _draftId!,
          contentType: 'image/jpeg',
          fileName: _selectedImage!.name,
        );

        final uploadUrl = uploadInfo['upload_url'] as String;
        final assetId = uploadInfo['asset_id'] as String;

        // 2. Upload binary payload
        setState(() => _statusMessage = 'Uploading image payload...');
        await apiClient.uploadBinary(
          uploadUrl: uploadUrl,
          bytes: imageBytes,
          contentType: 'image/jpeg',
          onProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = 0.2 + (0.5 * (sent / total)));
            }
          },
        );

        // 3. Confirm upload
        setState(() => _statusMessage = 'Confirming asset storage...');
        await submissionService.confirmUpload(_draftId!, assetId: assetId);
        _uploadProgress = 0.8;
      }

      // Final step: Submit for AI Validation & Queue Processing
      setState(() {
        _statusMessage = 'Submitting for AI validation pipeline...';
        _uploadProgress = 0.95;
      });

      final finalSubmission = await submissionService.submit(_draftId!);
      _uploadProgress = 1.0;

      if (mounted) {
        // Show success snackbar and navigate to submission detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission successful! AI validation started.'),
            backgroundColor: AppColors.mintPrimary,
          ),
        );
        context.go('/submissions/${finalSubmission.id}', extra: finalSubmission);
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Submission')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final modality = DataModalityExt.fromString(_campaign?.dataType ?? 'TEXT');

    return Scaffold(
      appBar: AppBar(
        title: Text('${_campaign?.title ?? "Campaign"} Submission'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions banner
            if (_campaign?.instructions != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.mintPrimary),
                        SizedBox(width: 6),
                        Text(
                          'Instructions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _campaign!.instructions!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Modality-Specific Input
            if (modality == DataModality.text) ...[
              _buildTextInputSection(),
            ] else if (modality == DataModality.voice) ...[
              _buildVoiceInputSection(),
            ] else if (modality == DataModality.image) ...[
              _buildImageInputSection(),
            ],

            const SizedBox(height: 28),

            // Upload Progress Bar
            if (_isSubmitting) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintPrimary),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusMessage ?? 'Processing...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submit Button
            DataMintButton(
              label: 'Submit for AI Verification',
              icon: Icons.send_rounded,
              width: double.infinity,
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Text Data Content',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLines: 10,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter high-quality text data adhering to campaign instructions...',
            alignLabelWithHint: true,
            helperText: '${_textController.text.length} characters',
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final minutes = (_recordDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDurationSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Timer display
          Text(
            '$minutes:$seconds',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isRecording ? AppColors.error : AppColors.mintPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Record / Stop Button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.mintPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? AppColors.error : AppColors.mintPrimary,
                  width: 2,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 40,
                color: _isRecording ? AppColors.error : AppColors.mintPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),

          if (_recordedAudioPath != null && !_isRecording) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  iconSize: 36,
                  color: AppColors.mintPrimary,
                  onPressed: _toggleAudioPlayback,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Preview Recording',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Re-record'),
                  onPressed: () {
                    setState(() {
                      _recordedAudioPath = null;
                      _recordDurationSeconds = 0;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageInputSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null) ...[
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb
                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedImage!.name,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                label: const Text('Change Image', style: TextStyle(color: AppColors.error)),
                onPressed: () => setState(() => _selectedImage = null),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Select or Capture Image',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supports JPG, PNG up to 10MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DataMintButton(
                      label: 'Take Photo',
                      icon: Icons.camera_alt_outlined,
                      isOutlined: true,
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 12),
                    DataMintButton(
                      label: 'Choose File',
                      icon: Icons.photo_library_outlined,
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

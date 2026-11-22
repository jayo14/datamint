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
      if (_campaign == null) {
        final marketplaceService = ref.read(marketplaceServiceProvider);
        _campaign = await marketplaceService.getCampaignDetails(widget.campaignId);
      }

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

        setState(() => _statusMessage = 'Saving text content...');
        await submissionService.updateDraft(_draftId!, textContent: text);
        _uploadProgress = 0.6;
      } else if (modality == DataModality.voice) {
        if (_recordedAudioPath == null) {
          throw const ValidationException(message: 'Please record audio before submitting');
        }

        final audioBytes = await File(_recordedAudioPath!).readAsBytes();
        setState(() => _statusMessage = 'Requesting secure upload authorization...');

        final uploadInfo = await submissionService.getUploadUrl(
          _draftId!,
          contentType: 'audio/m4a',
          fileName: 'submission.m4a',
        );

        final uploadUrl = uploadInfo['upload_url'] as String;
        final assetId = uploadInfo['asset_id'] as String;

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

        setState(() => _statusMessage = 'Confirming asset storage...');
        await submissionService.confirmUpload(_draftId!, assetId: assetId);
        _uploadProgress = 0.8;
      } else if (modality == DataModality.image) {
        if (_selectedImage == null) {
          throw const ValidationException(message: 'Please select an image before submitting');
        }

        final imageBytes = await _selectedImage!.readAsBytes();
        setState(() => _statusMessage = 'Requesting secure upload authorization...');

        final uploadInfo = await submissionService.getUploadUrl(
          _draftId!,
          contentType: 'image/jpeg',
          fileName: _selectedImage!.name,
        );

        final uploadUrl = uploadInfo['upload_url'] as String;
        final assetId = uploadInfo['asset_id'] as String;

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

        setState(() => _statusMessage = 'Confirming asset storage...');
        await submissionService.confirmUpload(_draftId!, assetId: assetId);
        _uploadProgress = 0.8;
      }

      setState(() {
        _statusMessage = 'Submitting for AI validation pipeline...';
        _uploadProgress = 0.95;
      });

      final finalSubmission = await submissionService.submit(_draftId!);
      _uploadProgress = 1.0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission successful! AI validation started.'),
            backgroundColor: AppColors.mintActive,
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
        backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('New Submission', style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mintActive)),
      );
    }

    final modality = DataModalityExt.fromString(_campaign?.dataType ?? 'TEXT');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${_campaign?.title ?? "Campaign"} Submission',
          style: const TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -40,
            child: FloatingCoinGlow(size: 160, color: AppColors.mintPrimary, opacity: 0.25),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions banner
                if (_campaign?.instructions != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.mintPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.mintActive),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _campaign!.instructions!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontFamily: 'Inter', color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Modality-Specific Input
                if (modality == DataModality.text) ...[
                  _buildTextInputSection(isDark),
                ] else if (modality == DataModality.voice) ...[
                  _buildVoiceInputSection(isDark),
                ] else if (modality == DataModality.image) ...[
                  _buildImageInputSection(isDark),
                ],

                const SizedBox(height: 28),

                // Upload Progress Bar
                if (_isSubmitting) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 8,
                      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintActive),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _statusMessage ?? 'Processing...',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Text Data Content',
          style: TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _textController,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter high-quality text data adhering to campaign instructions...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              helperText: '${_textController.text.length} characters',
              helperStyle: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputSection(bool isDark) {
    final minutes = (_recordDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDurationSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Timer display
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontFamily: 'Bricolage Grotesque',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: _isRecording ? AppColors.error : AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),

          // Record / Stop Button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppColors.error.withValues(alpha: 0.15)
                    : AppColors.mintPrimary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? AppColors.error : AppColors.mintActive,
                  width: 2.5,
                ),
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                size: 42,
                color: _isRecording ? AppColors.error : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted),
          ),

          if (_recordedAudioPath != null && !_isRecording) ...[
            const SizedBox(height: 20),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  iconSize: 38,
                  color: AppColors.mintActive,
                  onPressed: _toggleAudioPlayback,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Preview Recording',
                  style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Re-record', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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

  Widget _buildImageInputSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null) ...[
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                label: const Text('Change Image', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                onPressed: () => setState(() => _selectedImage = null),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mintPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_outlined, size: 36, color: AppColors.ink),
                ),
                const SizedBox(height: 14),
                Text(
                  'Select or Capture Image',
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supports JPG, PNG up to 10MB',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
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

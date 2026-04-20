import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/challenge_controller.dart';
import '../controllers/execution_controller.dart';
import '../widgets/challenge_execution_widgets.dart';

class ChallengeExecutionScreen extends StatefulWidget {
  const ChallengeExecutionScreen({
    super.key,
    required this.challengeController,
    required this.executionController,
    required this.challengeId,
  });

  final ChallengeController challengeController;
  final ExecutionController executionController;
  final String challengeId;

  @override
  State<ChallengeExecutionScreen> createState() => _ChallengeExecutionScreenState();
}

class _ChallengeExecutionScreenState extends State<ChallengeExecutionScreen> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final challenge = widget.challengeController.challengeById(widget.challengeId);
    if (challenge != null && challenge.submissionText.isNotEmpty) {
      _descriptionController.text = challenge.submissionText;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.challengeController, widget.executionController]),
      builder: (context, _) {
        final challenge = widget.challengeController.challengeById(widget.challengeId);
        final isLoading = widget.challengeController.isLoading(widget.challengeId) && challenge == null;
        final mutationLoading = widget.executionController.isLoading(widget.challengeId);
        final error = widget.executionController.errorFor(widget.challengeId) ?? widget.challengeController.errorFor(widget.challengeId);
        final uploadState = widget.executionController.uploadStateFor(widget.challengeId);

        if (isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('Выполнение')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (challenge == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('Выполнение')),
            body: const Center(child: Text('Челлендж не найден')),
          );
        }

        if (_descriptionController.text.isEmpty && challenge.submissionText.isNotEmpty) {
          _descriptionController.text = challenge.submissionText;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('Выполнение челленджа')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(error, style: const TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
              if (mutationLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ExecutionStatusBanner(challenge: challenge),
              const SizedBox(height: 14),
              ProgressSectionCard(
                challenge: challenge,
                onAdvance: () async {
                  try {
                    await widget.executionController.updateProgress(widget.challengeId, progressDelta: 20);
                  } catch (error) {
                    if (!context.mounted) return;
                    _showSnack(error.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              const SizedBox(height: 14),
              SubmissionComposerCard(
                challenge: challenge,
                descriptionController: _descriptionController,
                uploadState: uploadState,
                onPickImage: _pickImage,
                onSubmit: _submit,
                onRetry: () async {
                  await widget.executionController.retrySubmission(widget.challengeId);
                },
                onRetryUpload: () async {
                  try {
                    await widget.executionController.retryProofUpload(widget.challengeId);
                    if (!context.mounted) return;
                    _showSnack('Proof image успешно загружен. Можно отправлять выполнение.');
                  } catch (error) {
                    if (!context.mounted) return;
                    _showSnack(error.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              const SizedBox(height: 14),
              VerificationResultCard(
                challenge: challenge,
                onShare: () => _showSnack('Поделиться выполнением подключим следующим шагом'),
                onLikeCompletion: () => widget.executionController.likeCompletion(challenge.id),
              ),
              const SizedBox(height: 14),
              MedalCelebrationCard(challenge: challenge),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted || file == null) return;

    await widget.executionController.attachSubmissionImage(widget.challengeId, file.path);
    _showSnack('Фото добавлено. Перед отправкой мы загрузим его в storage.');
  }

  Future<void> _submit() async {
    final challenge = widget.challengeController.challengeById(widget.challengeId);
    if (challenge == null) return;

    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Добавь описание результата перед отправкой.');
      return;
    }

    try {
      await widget.executionController.submitExecution(
        challengeId: challenge.id,
        text: _descriptionController.text.trim(),
        imagePath: challenge.submissionImagePath,
      );
      if (!mounted) return;
      _showSnack('Выполнение отправлено на backend.');
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

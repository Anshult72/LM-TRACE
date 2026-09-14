import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/responsive/web_page_container.dart';
import 'inspections_controller.dart';
import 'widgets/inspection_details_form.dart';

class FinalizeInspectionScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const FinalizeInspectionScreen({super.key, required this.inspectionId});

  @override
  ConsumerState<FinalizeInspectionScreen> createState() => _FinalizeInspectionScreenState();
}

class _FinalizeInspectionScreenState extends ConsumerState<FinalizeInspectionScreen> {
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(inspectionsProvider).selectedInspection;
      if (current == null || current.id != widget.inspectionId) {
        setState(() => _isLoadingDetail = true);
        ref.read(inspectionsProvider.notifier).fetchInspectionDetail(widget.inspectionId).then((_) {
          if (mounted) setState(() => _isLoadingDetail = false);
        });
      }
    });
  }

  Future<void> _handleFinalize(InspectionFormData data) async {
    final controller = ref.read(inspectionsProvider.notifier);
    final ok = await controller.finalizeInspection(
      widget.inspectionId,
      finalizationData: data.toMap(),
    );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Inspection successfully finalized and sealed in immutable audit record.'),
          backgroundColor: AppColors.passGreen,
          duration: Duration(seconds: 4),
        ),
      );
      context.go('/inspections/${widget.inspectionId}');
    } else if (mounted) {
      final err = ref.read(inspectionsProvider).errorMessage ?? 'Finalization failed. Please verify required fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.violationRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionsProvider);
    final inspection = state.selectedInspection?.id == widget.inspectionId
        ? state.selectedInspection
        : state.inspections.where((i) => i.id == widget.inspectionId).firstOrNull;

    final isDesktop = ResponsiveLayout.isWebDesktop(context);

    if (_isLoadingDetail && inspection == null) {
      if (isDesktop) {
        return const WebPageContainer(
          maxWidth: 800,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Loading inspection details...', style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Finalise Inspection')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Loading inspection details...', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    final code = inspection?.inspectionCode ?? widget.inspectionId;

    Widget formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header badge row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.passGreen.withValues(alpha: 0.12),
                  borderRadius: AppRadii.sm,
                ),
                child: const Icon(Icons.verified_outlined, color: AppColors.passGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case File: $code',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inspection?.score != null
                          ? 'AI Compliance Score: ${inspection!.score!.toStringAsFixed(1)}%'
                          : 'Statutory Metrology Review Pending Finalisation',
                      style: TextStyle(
                        fontSize: 12,
                        color: inspection?.score != null ? AppColors.passGreen : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Shared details form
        InspectionDetailsForm(
          initialInspection: inspection,
          isFinalizing: true,
          isLoading: state.isLoading,
          submitButtonLabel: 'Submit & Finalize Inspection',
          onSubmit: _handleFinalize,
        ),
      ],
    );

    if (isDesktop) {
      return WebPageContainer(
        maxWidth: 800,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Return to Case File',
                  onPressed: () => context.go('/inspections/${widget.inspectionId}'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Finalise Inspection',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Case File: $code • Statutory Metrology Sealing',
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            formContent,
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Finalise Inspection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inspections/${widget.inspectionId}'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: formContent,
      ),
    );
  }
}

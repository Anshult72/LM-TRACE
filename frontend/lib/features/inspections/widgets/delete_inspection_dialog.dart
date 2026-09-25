import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_controller.dart';
import '../inspections_controller.dart';

/// Shows an explicit confirmation dialog for permanently deleting an inspection.
/// Strictly restricted to ADMIN role.
Future<bool> showDeleteInspectionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String inspectionId,
  required String inspectionCode,
  bool navigateToListOnSuccess = false,
}) async {
  // Strict frontend role verification before displaying dialog
  final user = ref.read(authProvider).user;
  if (user == null || !user.isAdmin) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access restricted: Only administrators can delete inspections.'),
        backgroundColor: AppColors.violationRed,
      ),
    );
    return false;
  }

  bool isDeleting = false;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.violationRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.violationRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete Inspection?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete this inspection ($inspectionCode) and its associated inspection data and evidence.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.neutral700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.violationRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.violationRed.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: AppColors.violationRed),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Destructive Operation: Inspection records, declarations, compliance checks, and evidence assets will be removed permanently.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.violationRed,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton(
                onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final success = await ref
                            .read(inspectionsProvider.notifier)
                            .deleteInspection(inspectionId);

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(success);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violationRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.delete_forever, size: 16),
                label: Text(
                  isDeleting ? 'Deleting...' : 'Delete Inspection',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Inspection $inspectionCode successfully deleted.'),
        backgroundColor: AppColors.passGreen,
        duration: const Duration(seconds: 4),
      ),
    );

    if (navigateToListOnSuccess) {
      context.go('/inspections');
    }
    return true;
  } else if (confirmed == false && ref.read(inspectionsProvider).errorMessage != null && context.mounted) {
    final err = ref.read(inspectionsProvider).errorMessage!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err),
        backgroundColor: AppColors.violationRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  return false;
}

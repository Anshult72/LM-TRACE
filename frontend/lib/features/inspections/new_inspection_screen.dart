import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/responsive/web_page_container.dart';
import 'inspections_controller.dart';
import 'widgets/inspection_details_form.dart';

class NewInspectionScreen extends ConsumerStatefulWidget {
  const NewInspectionScreen({super.key});

  @override
  ConsumerState<NewInspectionScreen> createState() => _NewInspectionScreenState();
}

class _NewInspectionScreenState extends ConsumerState<NewInspectionScreen> {
  Future<void> _handleCreate(InspectionFormData data) async {
    final controller = ref.read(inspectionsProvider.notifier);
    final inspection = await controller.createInspection(
      location: data.location,
      sellerName: data.sellerName,
      businessName: data.businessName,
      productCategory: data.productCategory,
      inspectionType: data.inspectionType,
      packageType: data.packageType,
      packageConstructionType: data.packageConstructionType,
      applicabilityContext: data.applicabilityContext,
      notes: data.notes,
    );

    if (inspection != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created inspection ${inspection.inspectionCode}'),
          backgroundColor: AppColors.compliant,
        ),
      );

      if (data.inspectionType == 'ONLINE_LISTING') {
        context.push('/online-listing?inspectionId=${inspection.id}');
      } else {
        context.go('/scanner?inspectionId=${inspection.id}');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize inspection. Please try again.'),
          backgroundColor: AppColors.violation,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionsProvider);

    if (ResponsiveLayout.isWebDesktop(context)) {
      return WebPageContainer(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Return to Registry',
                  onPressed: () => context.go('/inspections'),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Initiate New Inspection',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Record establishment particulars and select inspection channel',
                      style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            InspectionDetailsForm(
              isFinalizing: false,
              isLoading: state.isLoading,
              submitButtonLabel: 'Create & Proceed to Capture',
              onSubmit: _handleCreate,
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Initiate New Inspection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: InspectionDetailsForm(
          isFinalizing: false,
          isLoading: state.isLoading,
          submitButtonLabel: 'Create & Proceed to Capture',
          onSubmit: _handleCreate,
        ),
      ),
    );
  }
}

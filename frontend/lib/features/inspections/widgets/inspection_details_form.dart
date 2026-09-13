import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../inspections_controller.dart';

class InspectionFormData {
  final String location;
  final String? sellerName;
  final String businessName;
  final String productCategory;
  final String inspectionType;
  final String packageType;
  final String packageConstructionType;
  final String? notes;

  const InspectionFormData({
    required this.location,
    this.sellerName,
    required this.businessName,
    required this.productCategory,
    required this.inspectionType,
    required this.packageType,
    required this.packageConstructionType,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'location': location,
    'seller_name': sellerName,
    'business_name': businessName,
    'product_category': productCategory,
    'inspection_type': inspectionType,
    'package_type': packageType,
    'package_construction_type': packageConstructionType,
    'notes': notes,
  };
}

class InspectionDetailsForm extends StatefulWidget {
  final InspectionModel? initialInspection;
  final bool isFinalizing;
  final Future<void> Function(InspectionFormData data) onSubmit;
  final bool isLoading;
  final String? submitButtonLabel;

  const InspectionDetailsForm({
    super.key,
    this.initialInspection,
    this.isFinalizing = false,
    required this.onSubmit,
    this.isLoading = false,
    this.submitButtonLabel,
  });

  @override
  State<InspectionDetailsForm> createState() => _InspectionDetailsFormState();
}

class _InspectionDetailsFormState extends State<InspectionDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _locationController;
  late final TextEditingController _businessController;
  late final TextEditingController _sellerController;
  late final TextEditingController _notesController;

  late String _inspectionType;
  late String _category;
  late String _constructionType;
  late String _packageType;

  final List<String> _categories = [
    'Packaged Food',
    'Edible Oils & Fats',
    'Beverages & Juices',
    'Cosmetics & Toiletries',
    'Soaps & Detergents',
    'Baby Food & Milk Powder',
    'General Merchandise',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialInspection;

    String initialLoc = '';
    if (init != null) {
      if (init.location.isNotEmpty && !init.location.contains('Pending Finalisation')) {
        initialLoc = init.location;
      }
    } else {
      initialLoc = 'Khan Market, Shop 14, New Delhi';
    }

    String initialBiz = '';
    if (init != null) {
      initialBiz = init.businessName ?? '';
    } else {
      initialBiz = 'Heritage Fresh Supermarket';
    }

    String initialSeller = '';
    if (init != null) {
      initialSeller = init.sellerName ?? '';
    } else {
      initialSeller = 'Retail Traders Pvt Ltd';
    }

    String initialNotes = '';
    if (init != null && init.notes != null) {
      initialNotes = init.notes!.replaceAll(RegExp(r'\[DIRECT_SCAN\]\s*'), '');
    }

    _locationController = TextEditingController(text: initialLoc);
    _businessController = TextEditingController(text: initialBiz);
    _sellerController = TextEditingController(text: initialSeller);
    _notesController = TextEditingController(text: initialNotes);

    _inspectionType = init?.inspectionType ?? 'PHYSICAL';
    _category = 'Packaged Food';
    _constructionType = init?.packageConstructionType ?? 'NORMAL';
    _packageType = init?.packageType ?? 'RECTANGULAR';

    // If initialBiz is empty, attempt to prefill from detected manufacturer/brand
    if (initialBiz.isEmpty && init != null && init.declarations.isNotEmpty) {
      for (final dec in init.declarations) {
        if (dec is Map) {
          final fn = (dec['field_name'] ?? '').toString().toLowerCase();
          final val = (dec['verified_value'] ?? dec['ai_value'] ?? '').toString();
          if ((fn.contains('manufacturer') || fn.contains('brand') || fn.contains('packer')) && val.isNotEmpty) {
            _businessController.text = val;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _businessController.dispose();
    _sellerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = InspectionFormData(
      location: _locationController.text.trim(),
      sellerName: _sellerController.text.trim().isEmpty ? null : _sellerController.text.trim(),
      businessName: _businessController.text.trim(),
      productCategory: _category,
      inspectionType: _inspectionType,
      packageType: _packageType,
      packageConstructionType: _constructionType,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final isFinalizing = widget.isFinalizing;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contextual Information Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFinalizing ? AppColors.infoBg : AppColors.infoBg,
              borderRadius: AppRadii.sm,
              border: Border.all(color: AppColors.secondaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isFinalizing ? Icons.verified_user_outlined : Icons.info_outline,
                  color: AppColors.secondaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFinalizing
                        ? 'Complete the statutory establishment and location details below to finalize and seal this inspection record.'
                        : 'Inspections are governed by Legal Metrology (Packaged Commodities) Rules, 2011. Captured records are sealed with audit provenance.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Inspection Channel Selector
          const Text(
            'Inspection Channel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTypeRadio(
                  title: 'Physical Commodity',
                  subtitle: 'Retail shelf / Warehouse',
                  icon: Icons.inventory_2_outlined,
                  value: 'PHYSICAL',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeRadio(
                  title: 'E-Commerce Listing',
                  subtitle: 'Online Marketplace (Rule 2027)',
                  icon: Icons.language,
                  value: 'ONLINE_LISTING',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location & Trader Information
          _buildSectionTitle('Location & Trader Information'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _businessController,
            decoration: const InputDecoration(
              labelText: 'Establishment / Trader Name *',
              hintText: 'e.g. M/s Greenfield Retail Hub',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Establishment name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Inspection Location / Address *',
              hintText: 'Shop No., Market, District, State',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Inspection location address is required';
              }
              if (val.trim() == 'Field Scan (Pending Finalisation)') {
                return 'Please provide the physical inspection address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sellerController,
            decoration: const InputDecoration(
              labelText: 'Dealer / Seller Licensee (Optional)',
              hintText: 'e.g. Retail Traders Pvt Ltd',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Commodity & Package Characteristics
          _buildSectionTitle('Commodity Classification (Rule 6 & 7 Context)'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Commodity Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _category = val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _constructionType,
                  decoration: const InputDecoration(
                    labelText: 'Package Construction',
                    helperText: 'Rule 7 Table-I font scaling',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'NORMAL',
                      child: Text('Normal (Cardboard / Poly / Label)'),
                    ),
                    DropdownMenuItem(
                      value: 'BLOWN_FORMED_MOLDED',
                      child: Text('Blown / Formed / Molded (Glass/Plastic)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _constructionType = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _packageType,
            decoration: const InputDecoration(
              labelText: 'Package Geometry / Shape',
              helperText: 'Calculates Principal Display Panel (PDP) area',
            ),
            items: const [
              DropdownMenuItem(value: 'RECTANGULAR', child: Text('Rectangular (H × W)')),
              DropdownMenuItem(value: 'CYLINDRICAL', child: Text('Cylindrical (40% of H × Circumference)')),
              DropdownMenuItem(value: 'IRREGULAR', child: Text('Irregular / Other (40% Total Surface)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _packageType = val);
            },
          ),
          const SizedBox(height: 16),

          // Inspector Notes
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Preliminary Notes / Case Memo (Optional)',
              hintText: 'e.g. Spot audit based on consumer complaint regarding altered MRP',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Action
          AppButton(
            label: widget.submitButtonLabel ??
                (isFinalizing ? 'Confirm & Finalize Inspection' : 'Create & Proceed to Capture'),
            icon: isFinalizing ? Icons.lock_outline : Icons.camera_alt_outlined,
            size: AppButtonSize.lg,
            isFullWidth: true,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _handleSubmit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryNavy,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildTypeRadio({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _inspectionType == value;
    return InkWell(
      onTap: () => setState(() => _inspectionType = value),
      borderRadius: AppRadii.md,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.white,
          borderRadius: AppRadii.md,
          border: Border.all(
            color: isSelected ? AppColors.secondaryBlue : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.sm : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.secondaryBlue : AppColors.textMuted,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondaryBlue),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

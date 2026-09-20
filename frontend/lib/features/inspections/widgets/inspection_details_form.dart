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
  final Map<String, dynamic> applicabilityContext;
  final String? notes;

  const InspectionFormData({
    required this.location,
    this.sellerName,
    required this.businessName,
    required this.productCategory,
    required this.inspectionType,
    required this.packageType,
    required this.packageConstructionType,
    required this.applicabilityContext,
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
    'applicability_context': applicabilityContext,
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
  late String _marketScope;
  late String _originType;
  late String _packerApplicability;
  late String _shelfLifeApplicability;
  late String _dimensionsApplicability;
  late String _unitSalePriceApplicability;
  late bool _isMultiPiecePackage;
  late bool _electronicDeclarationsViaQr;
  late bool _hasOuterWrapper;
  late bool _outerWrapperTransparent;
  late bool _declarationReadThroughLiquid;

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
    }

    String initialBiz = '';
    if (init != null) {
      initialBiz = init.businessName ?? '';
    }

    String initialSeller = '';
    if (init != null) {
      initialSeller = init.sellerName ?? '';
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
    _category = init?.productCategory ?? 'Packaged Food';
    _constructionType = init?.packageConstructionType ?? 'NORMAL';
    _packageType = init?.packageType ?? 'RECTANGULAR';
    final applicability = init?.applicabilityContext ?? const <String, dynamic>{};
    _marketScope = (applicability['market_scope'] ?? 'RETAIL').toString();
    _originType = (applicability['origin_type'] ?? 'UNKNOWN').toString();
    String triState(dynamic value) => value is bool ? (value ? 'YES' : 'NO') : 'AUTO';
    _packerApplicability = triState(applicability['is_packer_distinct']);
    _shelfLifeApplicability = triState(applicability['shelf_life_declaration_required']);
    _dimensionsApplicability = triState(applicability['dimensions_declaration_required']);
    _unitSalePriceApplicability = triState(applicability['unit_sale_price_required']);
    _isMultiPiecePackage = applicability['is_multi_piece_package'] == true;
    _electronicDeclarationsViaQr = applicability['electronic_declarations_via_qr'] == true;
    _hasOuterWrapper = applicability['has_outer_wrapper'] == true;
    _outerWrapperTransparent = applicability['outer_wrapper_transparent'] == true;
    _declarationReadThroughLiquid = applicability['declaration_read_through_liquid'] == true;

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
      applicabilityContext: {
        'market_scope': _marketScope,
        'origin_type': _originType,
        'is_packer_distinct': _triStateValue(_packerApplicability),
        'shelf_life_declaration_required': _triStateValue(_shelfLifeApplicability),
        'dimensions_declaration_required': _triStateValue(_dimensionsApplicability),
        'unit_sale_price_required': _triStateValue(_unitSalePriceApplicability),
        'is_multi_piece_package': _isMultiPiecePackage,
        'electronic_declarations_via_qr': _electronicDeclarationsViaQr,
        'has_outer_wrapper': _hasOuterWrapper,
        'outer_wrapper_transparent': _outerWrapperTransparent,
        'declaration_read_through_liquid': _declarationReadThroughLiquid,
      },
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
              hintText: 'e.g. Registered Distributor or Packer',
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

          _buildSectionTitle('Declaration Applicability (Rule 6)'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _marketScope,
            decoration: const InputDecoration(
              labelText: 'Intended Consumer / Market Scope',
              helperText: 'Industrial and institutional packages may be outside retail declaration scope',
              prefixIcon: Icon(Icons.business_center_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'RETAIL', child: Text('Retail consumer package')),
              DropdownMenuItem(value: 'INDUSTRIAL', child: Text('Industrial consumer package')),
              DropdownMenuItem(value: 'INSTITUTIONAL', child: Text('Institutional consumer package')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _marketScope = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _originType,
            decoration: const InputDecoration(
              labelText: 'Commodity Origin',
              helperText: 'Importer and country-of-origin declarations activate for imported goods',
              prefixIcon: Icon(Icons.public_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'UNKNOWN', child: Text('Unknown — infer from package')),
              DropdownMenuItem(value: 'DOMESTIC', child: Text('Domestic')),
              DropdownMenuItem(value: 'IMPORTED', child: Text('Imported')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _originType = value);
            },
          ),
          const SizedBox(height: 8),
          _buildApplicabilityDropdown(
            label: 'Separate packer declaration',
            helper: 'Requires packer name and complete address when manufacturer and packer differ',
            value: _packerApplicability,
            onChanged: (value) => setState(() => _packerApplicability = value),
          ),
          _buildApplicabilityDropdown(
            label: 'Best Before / Use By declaration',
            helper: 'Applicable when the commodity may become unfit for human consumption',
            value: _shelfLifeApplicability,
            onChanged: (value) => setState(() => _shelfLifeApplicability = value),
          ),
          _buildApplicabilityDropdown(
            label: 'Commodity dimensions declaration',
            helper: 'Applicable to size-dependent commodities',
            value: _dimensionsApplicability,
            onChanged: (value) => setState(() => _dimensionsApplicability = value),
          ),
          _buildApplicabilityDropdown(
            label: 'Unit sale price declaration',
            helper: 'Rule 6(11) retail unit-price declaration',
            value: _unitSalePriceApplicability,
            onChanged: (value) => setState(() => _unitSalePriceApplicability = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Multi-piece / group / gift package', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Declarations must be checked on outer and constituent retail packages'),
            value: _isMultiPiecePackage,
            onChanged: (value) => setState(() => _isMultiPiecePackage = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Declarations provided through QR / electronic link', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Creates a mandatory review to open and capture the digital declarations'),
            value: _electronicDeclarationsViaQr,
            onChanged: (value) => setState(() => _electronicDeclarationsViaQr = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Package has an outside container / wrapper', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Capture the optional Outer Wrapper surface for Rule 9 placement checks'),
            value: _hasOuterWrapper,
            onChanged: (value) => setState(() {
              _hasOuterWrapper = value;
              if (!value) _outerWrapperTransparent = false;
            }),
          ),
          if (_hasOuterWrapper)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Outside wrapper is transparent', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Underlying declarations are clearly readable through it'),
              value: _outerWrapperTransparent,
              onChanged: (value) => setState(() => _outerWrapperTransparent = value),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Declarations must be read through liquid', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Rule 9(2) placement violation indicator'),
            value: _declarationReadThroughLiquid,
            onChanged: (value) => setState(() => _declarationReadThroughLiquid = value),
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

  bool? _triStateValue(String value) {
    if (value == 'YES') return true;
    if (value == 'NO') return false;
    return null;
  }

  Widget _buildApplicabilityDropdown({
    required String label,
    required String helper,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, helperText: helper),
        items: const [
          DropdownMenuItem(value: 'AUTO', child: Text('Auto-detect / officer confirmation')),
          DropdownMenuItem(value: 'YES', child: Text('Applicable')),
          DropdownMenuItem(value: 'NO', child: Text('Not applicable / exempt')),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
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

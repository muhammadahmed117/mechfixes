import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/data/vehicle_issue.dart';
import 'package:mechfixes/Mechanic/services/mechanic_skills_service.dart';

class AddSkillsServicesScreen extends StatefulWidget {
  const AddSkillsServicesScreen({
    super.key,
    required this.mechanicId,
    required this.specializations,
    this.initialSelectedServices = const [],
  });

  final String mechanicId;
  final List<String> specializations;
  final List<String> initialSelectedServices;

  @override
  State<AddSkillsServicesScreen> createState() =>
      _AddSkillsServicesScreenState();
}

class _AddSkillsServicesScreenState extends State<AddSkillsServicesScreen> {
  final Set<String> _selectedServices = {};
  bool _isSaving = false;

  List<VehicleIssue> get _allowedIssues =>
      VehicleIssueCatalog.forSpecializations(widget.specializations);

  @override
  void initState() {
    super.initState();
    final allowedTitles =
        _allowedIssues.map((issue) => issue.title).toSet();

    for (final service in widget.initialSelectedServices) {
      if (allowedTitles.contains(service)) {
        _selectedServices.add(service);
      }
    }
  }

  void _toggleService(String title) {
    setState(() {
      if (_selectedServices.contains(title)) {
        _selectedServices.remove(title);
      } else {
        _selectedServices.add(title);
      }
    });
  }

  Future<void> _saveServices() async {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one service to continue'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final selectedList = _selectedServices.toList()..sort();

    try {
      await MechanicSkillsService.instance.saveSelectedSkills(
        mechanicId: widget.mechanicId,
        selectedSkills: selectedList,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, selectedList);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedIssues = _allowedIssues;
    final categories = IssueCategory.fromProfileSpecialties(
      widget.specializations,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF1F3FAF),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Add Skills / Services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: allowedIssues.isEmpty
                  ? _emptySpecializationState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE4E7EC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your specialization',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.specializations.join(' · '),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF101828),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  categories.isEmpty
                                      ? 'No matching category found.'
                                      : 'Showing ${categories.map((c) => c.label).join(', ')} services only.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Select the services you specialize in',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101828),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Only issues related to your specialization are shown.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: allowedIssues.map((issue) {
                              final isSelected =
                                  _selectedServices.contains(issue.title);

                              return _ServiceChipTile(
                                title: issue.title,
                                isSelected: isSelected,
                                onTap: () => _toggleService(issue.title),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE4E7EC)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveServices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3FAF),
                      disabledBackgroundColor: const Color(0xFFBFD0FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Services (${_selectedServices.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySpecializationState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No specialization found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete your shop profile and choose a specialty first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceChipTile extends StatelessWidget {
  const _ServiceChipTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFE8F8EF),
                      Color(0xFFD1FADF),
                    ],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF12B76A)
                  : const Color(0xFFE4E7EC),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 18,
                color: isSelected
                    ? const Color(0xFF12B76A)
                    : const Color(0xFF98A2B3),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 90,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF027A48)
                        : const Color(0xFF667085),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

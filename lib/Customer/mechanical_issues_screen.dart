import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/Customer/nearby_mechanics_screen.dart';

class MechanicalIssuesScreen extends StatefulWidget {
  const MechanicalIssuesScreen({super.key});

  @override
  State<MechanicalIssuesScreen> createState() =>
      _MechanicalIssuesScreenState();
}

class _MechanicalIssuesScreenState extends State<MechanicalIssuesScreen> {
  final TextEditingController issueController = TextEditingController();
  final GlobalKey _guidanceKey = GlobalKey();

  int? selectedIssueIndex;

  final List<String> issues = [
    "Engine won't start",
    "Strange engine noise",
    "Transmission slipping",
    "Oil leak detected",
    "Overheating engine",
    "Check engine light on",
  ];

  // Placeholder guidance — replace with API data later.
  final Map<String, List<String>> _diyGuidance = {
    "Engine won't start": [
      "Check that the battery terminals are clean and securely connected.",
      "Listen for a clicking sound — this often indicates a weak battery.",
      "Verify the fuel level and that the vehicle is in Park or Neutral.",
      "Inspect fuses related to the ignition and fuel pump systems.",
      "If the issue persists, a professional diagnostic scan is recommended.",
    ],
    "Strange engine noise": [
      "Note when the noise occurs — idle, acceleration, or braking.",
      "Check engine oil level and top up if it is low.",
      "Listen for knocking, squealing, or rattling to help identify the source.",
      "Inspect the serpentine belt for wear or looseness.",
      "Unusual noises should be inspected promptly to prevent further damage.",
    ],
    "Transmission slipping": [
      "Check transmission fluid level and color using the dipstick.",
      "Low or burnt-smelling fluid often indicates a transmission problem.",
      "Avoid aggressive acceleration until the issue is diagnosed.",
      "Note if slipping occurs when shifting or while driving steadily.",
      "Transmission repairs typically require professional service.",
    ],
    "Oil leak detected": [
      "Park on a clean surface and look for fresh oil spots underneath.",
      "Check the oil level with the dipstick — do not drive if it is critically low.",
      "Inspect common leak points: oil pan, filter, valve cover, and drain plug.",
      "Tighten the oil filter or drain plug if they appear loose.",
      "Persistent leaks should be repaired to avoid engine damage.",
    ],
    "Overheating engine": [
      "Pull over safely and turn off the engine if the temperature gauge is in the red.",
      "Do not open the radiator cap while the engine is hot.",
      "Check coolant level once the engine has cooled completely.",
      "Inspect for visible leaks in hoses and the radiator.",
      "Repeated overheating requires immediate professional attention.",
    ],
    "Check engine light on": [
      "A steady light usually indicates a non-urgent emissions or sensor issue.",
      "A flashing light signals a serious problem — reduce driving immediately.",
      "Check that the fuel cap is tightened properly — a loose cap can trigger the light.",
      "Use an OBD-II scanner to read the stored fault code.",
      "Share the fault code with a mechanic for accurate diagnosis.",
    ],
  };

  @override
  void dispose() {
    issueController.dispose();
    super.dispose();
  }

  void _selectIssue(int index) {
    setState(() {
      selectedIssueIndex = index;
      issueController.text = issues[index];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _guidanceKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _findMechanics() {
    if (issueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your issue")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyMechanicsScreen(
          issueCategory: IssueCategory.mechanical,
          issueDescription: issueController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIssue = selectedIssueIndex != null
        ? issues[selectedIssueIndex!]
        : null;
    final guidanceSteps = selectedIssue != null
        ? _diyGuidance[selectedIssue] ?? const <String>[]
        : const <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
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
                          "Back",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Mechanical Issues",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: issueController,
                      onChanged: (_) {
                        if (selectedIssueIndex != null &&
                            issueController.text != issues[selectedIssueIndex!]) {
                          setState(() {
                            selectedIssueIndex = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Describe your issue in detail...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFD0D5DD)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Be as specific as possible for accurate diagnosis",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475467),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD0D5DD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF1F3FAF)),
                              SizedBox(width: 8),
                              Text(
                                "Common Mechanical Issues",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: issues.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                              childAspectRatio: 2.5,
                            ),
                            itemBuilder: (context, index) {
                              final isSelected = selectedIssueIndex == index;

                              return GestureDetector(
                                onTap: () => _selectIssue(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEAF0FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1F3FAF)
                                          : const Color(0xFFD0D5DD),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    issues[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: isSelected
                                          ? const Color(0xFF1F3FAF)
                                          : const Color(0xFF344054),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: selectedIssue == null
                          ? const SizedBox.shrink()
                          : Container(
                              key: _guidanceKey,
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD0D5DD),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF0FF),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.build_circle_outlined,
                                          color: Color(0xFF1F3FAF),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "DIY Guidance / Quick Fixes",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF101828),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              selectedIssue,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF667085),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...List.generate(
                                    guidanceSteps.length,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEAF0FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "${index + 1}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F3FAF),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              guidanceSteps[index],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                height: 1.45,
                                                color: Color(0xFF475467),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _findMechanics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F3FAF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Find Mechanics for This Issue",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Tip: Click on a common issue to auto-fill, or type your own description for a custom diagnosis.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1F3FAF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

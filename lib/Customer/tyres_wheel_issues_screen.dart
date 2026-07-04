import 'package:flutter/material.dart';
import 'package:mechfixes/Customer/issue_category.dart';
import 'package:mechfixes/Customer/nearby_mechanics_screen.dart';

class TyresWheelIssuesScreen extends StatefulWidget {
  const TyresWheelIssuesScreen({super.key});

  @override
  State<TyresWheelIssuesScreen> createState() => _TyresWheelIssuesScreenState();
}

class _TyresWheelIssuesScreenState extends State<TyresWheelIssuesScreen> {
  final TextEditingController issueController = TextEditingController();
  final GlobalKey _guidanceKey = GlobalKey();

  int? selectedIssueIndex;

  final List<String> issues = [
    "Flat tire or puncture",
    "Steering wheel vibration",
    "Low tire pressure",
    "Vehicle pulling to one side",
    "Uneven tire wear",
    "Bent or damaged rim",
  ];

  final Map<String, List<String>> _diyGuidance = {
    "Flat tire or puncture": [
      "Safely pull over on level ground and turn on hazard lights.",
      "Inspect the tire for nails, screws, or visible punctures.",
      "If you have a spare, use the jack and lug wrench to swap the tire.",
      "For small punctures, a tire repair kit or sealant may provide a temporary fix.",
      "Do not drive long distances on a spare — visit a mechanic promptly.",
    ],
    "Steering wheel vibration": [
      "Check that all lug nuts are tightened to the correct torque.",
      "Inspect tires for uneven wear, bulges, or flat spots.",
      "Wheel balance issues often cause vibration at highway speeds.",
      "Look for bent wheels or damaged suspension components.",
      "A professional wheel balance and alignment check is recommended.",
    ],
    "Low tire pressure": [
      "Use a tire pressure gauge when tires are cold for an accurate reading.",
      "Find the recommended PSI on the sticker inside the driver's door.",
      "Inflate tires at a gas station air pump to the correct pressure.",
      "Recheck pressure after a few days — slow leaks may need repair.",
      "TPMS warning light should reset after driving a short distance.",
    ],
    "Vehicle pulling to one side": [
      "Compare tire pressure on all four tires and equalize if needed.",
      "Check for uneven tread wear that could cause pulling.",
      "A stuck brake caliper can cause the car to pull under braking.",
      "Wheel alignment issues are a common cause of consistent pulling.",
      "Have alignment and suspension inspected if the pull persists.",
    ],
    "Uneven tire wear": [
      "Rotate tires every 5,000–8,000 miles to promote even wear.",
      "Check alignment if inner or outer edges wear faster than the center.",
      "Over- or under-inflation creates center or edge wear patterns.",
      "Worn suspension parts can cause cupping or scalloped tread.",
      "Replace tires once tread depth falls below 2/32 of an inch.",
    ],
    "Bent or damaged rim": [
      "Visually inspect the rim for dents, cracks, or curb damage.",
      "Listen for air leaks — a bent rim may cause slow tire deflation.",
      "Avoid driving on a severely damaged rim to prevent further harm.",
      "Minor bends can sometimes be repaired by a wheel specialist.",
      "Replace cracked rims immediately — they are a safety hazard.",
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
          issueCategory: IssueCategory.tyresAndWheels,
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
                    "Tyres & Wheel Issues",
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
                                "Common Tyres & Wheel Issues",
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

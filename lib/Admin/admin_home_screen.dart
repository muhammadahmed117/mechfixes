import 'package:flutter/material.dart';
import 'package:mechfixes/Admin/add_mechanic_dialog.dart';
import 'package:mechfixes/Admin/admin_ratings_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> mechanics = [
      {
        "name": "Elite Auto Service",
        "address": "123 Main St, San Francisco",
        "phone": "+1 234 567 8900",
        "specialty": "All Services",
        "status": "Active",
      },
      {
        "name": "Precision Motors",
        "address": "456 Oak Ave, San Francisco",
        "phone": "+1 234 567 8901",
        "specialty": "Engine & Transmission",
        "status": "Active",
      },
      {
        "name": "QuickFix Auto",
        "address": "789 Elm St, San Francisco",
        "phone": "+1 234 567 8902",
        "specialty": "Quick Service",
        "status": "Active",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              width: double.infinity,
              color: const Color(0xFF1F3FAF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Manage Mechanics",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _headerButton(
                        icon: Icons.bar_chart_outlined,
                        title: "View Ratings",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminRatingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _headerButton(
                        icon: Icons.logout,
                        title: "Logout",
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Search + Add button
                    // Row(
                    //   children: [
                    //     SizedBox(
                    //       child: Container(
                    //         height: 48,
                    //         decoration: BoxDecoration(
                    //           color: Colors.white,
                    //           border: Border.all(color: const Color(0xFFD7DDE8)),
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         child: const TextField(
                    //           decoration: InputDecoration(
                    //             border: InputBorder.none,
                    //             hintText: "Search mechanics...",
                    //             hintStyle: TextStyle(
                    //               color: Color(0xFF8A94A6),
                    //               fontSize: 14,
                    //             ),
                    //             prefixIcon: Icon(
                    //               Icons.search,
                    //               color: Color(0xFF8A94A6),
                    //             ),
                    //             contentPadding: EdgeInsets.symmetric(vertical: 14),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 16),
                    //     SizedBox(
                    //       height: 48,
                    //       child: ElevatedButton.icon(
                    //         onPressed: () {},
                    //         icon: const Icon(Icons.add, color: Colors.white),
                    //         label: const Text(
                    //           "Add Mechanic",
                    //           style: TextStyle(color: Colors.white),
                    //         ),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: const Color(0xFF1F3FAF),
                    //           elevation: 0,
                    //           padding: const EdgeInsets.symmetric(horizontal: 22),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //         ),
                    //       ),
                    //     )
                    //   ],
                    // ),
                    SizedBox(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD7DDE8)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search mechanics...",
                            hintStyle: TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF8A94A6),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const AddMechanicDialog(),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Add Mechanic",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F3FAF),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Stats cards
                    Row(
                      children: const [
                        Expanded(
                          child: _StatCard(
                            title: "Total Mechanics",
                            value: "3",
                            valueColor: Color(0xFF0E1B4D),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            title: "Active",
                            value: "3",
                            valueColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            title: "Average Rating",
                            value: "4.8",
                            valueColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: 900,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD7DDE8)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F9FB),
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFD7DDE8)),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _TableHeader("Name"),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _TableHeader("Address"),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _TableHeader("Phone"),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _TableHeader("Specialty"),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _TableHeader("Status"),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: _TableHeader("Actions"),
                                  ),
                                ],
                              ),
                            ),
                            ...List.generate(
                              mechanics.length,
                              (index) => _mechanicRow(
                                mechanics[index],
                                isLast: index == mechanics.length - 1,
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
          ],
        ),
      ),
    );
  }

  static Widget _headerButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(title, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _mechanicRow(Map<String, String> mechanic, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD7DDE8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              mechanic["name"] ?? "",
              style: const TextStyle(fontSize: 14, color: Color(0xFF0E1B4D)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              mechanic["address"] ?? "",
              style: const TextStyle(fontSize: 14, color: Color(0xFF43506A)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mechanic["phone"] ?? "",
              style: const TextStyle(fontSize: 14, color: Color(0xFF43506A)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              mechanic["specialty"] ?? "",
              style: const TextStyle(fontSize: 14, color: Color(0xFF43506A)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mechanic["status"] ?? "",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF43506A),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DDE8)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF43506A)),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0E1B4D),
      ),
    );
  }
}

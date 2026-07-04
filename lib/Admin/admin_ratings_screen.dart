import 'package:flutter/material.dart';

class AdminRatingsScreen extends StatelessWidget {
  const AdminRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mechanics = [
      {
        "name": "Elite Auto Service",
        "reviews": "245 total reviews",
        "rating": "4.9",
        "trend": "Trending up",
        "trendUp": true,
        "recent": ["5★", "5★", "4★", "5★", "5★"],
        "bars": [
          {"label": "5★", "value": 0.82},
          {"label": "4★", "value": 0.76},
          {"label": "3★", "value": 0.01},
          {"label": "2★", "value": 0.00},
          {"label": "1★", "value": 0.01},
        ]
      },
      {
        "name": "Master Tech Auto",
        "reviews": "312 total reviews",
        "rating": "4.9",
        "trend": "Trending up",
        "trendUp": true,
        "recent": ["5★", "5★", "5★", "4★", "5★"],
        "bars": [
          {"label": "5★", "value": 0.83},
          {"label": "4★", "value": 0.78},
          {"label": "3★", "value": 0.01},
          {"label": "2★", "value": 0.00},
          {"label": "1★", "value": 0.01},
        ]
      },
      {
        "name": "Precision Motors",
        "reviews": "189 total reviews",
        "rating": "4.8",
        "trend": "Trending up",
        "trendUp": true,
        "recent": ["5★", "4★", "5★", "5★", "4★"],
        "bars": [
          {"label": "5★", "value": 0.80},
          {"label": "4★", "value": 0.75},
          {"label": "3★", "value": 0.01},
          {"label": "2★", "value": 0.00},
          {"label": "1★", "value": 0.01},
        ]
      },
      {
        "name": "QuickFix Auto",
        "reviews": "198 total reviews",
        "rating": "4.7",
        "trend": "Trending down",
        "trendUp": false,
        "recent": ["4★", "5★", "3★", "5★", "4★"],
        "bars": [
          {"label": "5★", "value": 0.80},
          {"label": "4★", "value": 0.75},
          {"label": "3★", "value": 0.01},
          {"label": "2★", "value": 0.00},
          {"label": "1★", "value": 0.01},
        ]
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1F3FAF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 14),
                        SizedBox(width: 2),
                        Text(
                          "Back to Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Ratings Overview",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "All registered mechanics",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _TopStatCard(
                            title: "Average Rating",
                            value: "4.8",
                            trailingStar: true,
                            valueColor: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _TopStatCard(
                            title: "Total Reviews",
                            value: "902",
                            valueColor: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _TopStatCard(
                            title: "Top Rated",
                            value: "2",
                            valueColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _TopStatCard(
                            title: "Needs Attention",
                            value: "0",
                            valueColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD9E0EA)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "Sort by",
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          _sortButton("Highest Rating", true),
                          const SizedBox(width: 6),
                          _sortButton("Most Reviews", false),
                          const SizedBox(width: 6),
                          _sortButton("Name", false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(
                      mechanics.length,
                          (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ratingCard(
                          index + 1,
                          mechanics[index],
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

  static Widget _sortButton(String title, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1F3FAF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 8,
          color: selected ? Colors.white : const Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _ratingCard(int index, Map<String, dynamic> item) {
    final bars = item["bars"] as List<dynamic>;
    final recent = item["recent"] as List<dynamic>;
    final bool trendUp = item["trendUp"] as bool;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9E0EA)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F3FAF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    "#$index",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["name"],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item["reviews"],
                      style: const TextStyle(
                        fontSize: 8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        item["rating"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star,
                          color: Colors.amber, size: 14),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 10,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item["trend"],
                        style: TextStyle(
                          fontSize: 8,
                          color: trendUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent ratings",
              style: TextStyle(
                fontSize: 8,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              recent.length,
                  (i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  recent[i],
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              bars.length,
                  (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == bars.length - 1 ? 0 : 4),
                  child: Column(
                    children: [
                      Text(
                        bars[i]["label"],
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: bars[i]["value"],
                          widthFactor: 1,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F3FAF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${((bars[i]["value"] as double) * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 7,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final bool trailingStar;

  const _TopStatCard({
    required this.title,
    required this.value,
    required this.valueColor,
    this.trailingStar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9E0EA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              if (trailingStar) ...[
                const SizedBox(width: 2),
                const Icon(Icons.star, color: Colors.amber, size: 13),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
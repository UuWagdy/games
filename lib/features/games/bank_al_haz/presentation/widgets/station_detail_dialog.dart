import 'package:flutter/material.dart';
import '../../domain/entities/bank_al_haz_entities.dart';

class StationDetailDialog extends StatelessWidget {
  final Station station;
  final BankAlHazPlayer currentPlayer;
  final String? ownerName;
  final VoidCallback onBuy;
  final VoidCallback onJustBeAsked;
  final VoidCallback onCancel;

  const StationDetailDialog({
    super.key,
    required this.station,
    required this.currentPlayer,
    this.ownerName,
    required this.onBuy,
    required this.onJustBeAsked,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    bool isOwned = ownerName != null;
    bool isOwner = ownerName == currentPlayer.name;
    bool canBuy = !isOwned && currentPlayer.money >= station.buyPrice;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOwned)
                      Text(
                        "مالك المدينة: $ownerName",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (station.imagePath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          station.imagePath!,
                          height: 100,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.location_city,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.location_city,
                        size: 60,
                        color: Colors.blueGrey,
                      ),

                    const SizedBox(height: 24),

                    _buildStatRow(
                      Icons.payments,
                      "ثمن الشراء",
                      "${station.buyPrice} P",
                      Colors.green,
                    ),
                    const Divider(height: 20),
                    _buildStatRow(
                      Icons.home,
                      "الإيجار الأساسي",
                      "${station.baseRent} P",
                      Colors.orange,
                    ),

                    const SizedBox(height: 32),

                    if (isOwner)
                      const Text(
                        "أنت تمتلك هذه المدينة بالفعل!",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (isOwned)
                      Column(
                        children: [
                          const Text(
                            "ستدخل تحدي المار لتقليل الإيجار",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onJustBeAsked,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'بدء تحدي المار (سؤال)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: canBuy ? onBuy : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'شراء (سؤال مالك)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: onCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'مرور (بدون سؤال)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!canBuy && !isOwned)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "نقاطك لا تكفي للشراء",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 16),
                    if (isOwner)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text("إغلاق"),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

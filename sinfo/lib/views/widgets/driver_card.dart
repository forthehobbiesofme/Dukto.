import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nearby_service_app/models/driver.dart';
import 'package:nearby_service_app/providers/driver_provider.dart';
import 'package:nearby_service_app/providers/settings_provider.dart';
import 'package:nearby_service_app/providers/auth_provider.dart';

class DriverCard extends ConsumerWidget {
  final Driver driver;

  const DriverCard({super.key, required this.driver});

  // ── Design Tokens ──
  static const Color colorPaleOrange = Color(0xFFFFCDB7);
  static const Color colorOrange = Color(0xFFFF9F45);
  static const Color colorOutline = Color(0xFFEAA297);

  // ── Launchers ──
  Future<void> _launchWhatsApp(BuildContext context) async {
    final url = Uri.parse('https://wa.me/${driver.phone.replaceAll('+', '')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _launchCall(BuildContext context) async {
    final url = Uri.parse('tel:${driver.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Phone')),
        );
      }
    }
  }

  // ── Rating Dialog ──
  void _showRatingDialog(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authProvider);
    final userPhone = auth.phone;
    if (userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register with phone to rate')),
      );
      return;
    }

    final supabaseService = ref.read(supabaseServiceProvider);

    // Brief loading spinner while checking for existing rating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: colorOrange),
      ),
    );

    Map<String, dynamic>? existingRating;
    try {
      existingRating = await supabaseService.getUserRating(driver.id, userPhone);
    } catch (e) {
      debugPrint('Could not fetch existing rating: $e');
    }

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    int selectedStars = existingRating?['stars'] ?? 0;
    final TextEditingController commentController =
        TextEditingController(text: existingRating?['comment'] ?? '');
    final bool isUpdate = existingRating != null;
    final notifier = ref.read(settingsProvider.notifier);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color(0xFFEAA297), width: 3),
              ),
              backgroundColor: const Color(0xFFFFD1B2),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Stars Row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final filled = index < selectedStars;
                        return GestureDetector(
                          onTap: () => setState(() => selectedStars = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              filled ? Icons.star : Icons.star_border_rounded,
                              size: 44,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // ── Prompt Text ──
                    Text(
                      notifier.translate('Rate your experience.....'),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Input + Done Button Row ──
                    Row(
                      children: [
                        // Grey pill input
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBDBDBD),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.black54,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: notifier.translate('type something..'),
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.black54,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Actions
                        if (isUpdate)
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.pop(dialogCtx);
                                try {
                                  await ref.read(supabaseServiceProvider).deleteRating(
                                        driver.id,
                                        userPhone,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Rating deleted!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.black, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.delete, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        if (isUpdate) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              if (selectedStars == 0) {
                                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a star rating'),
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(dialogCtx);

                              try {
                                if (isUpdate) {
                                  await ref.read(supabaseServiceProvider).updateRating(
                                        driver.id,
                                        selectedStars,
                                        userPhone,
                                        comment: commentController.text,
                                      );
                                } else {
                                  await ref.read(supabaseServiceProvider).submitRating(
                                        driver.id,
                                        selectedStars,
                                        userPhone,
                                        comment: commentController.text,
                                      );
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isUpdate
                                            ? 'Rating updated!'
                                            : 'Rating submitted!',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE89E5B),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isUpdate ? 'Update' : notifier.translate('Done'),
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Card Build ──
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD1B2),
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Orange Profile Circle ──
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              color: const Color(0xFFE89E5B),
              shape: BoxShape.circle,
              image: driver.profileUrl != null
                  ? DecorationImage(
                      image: NetworkImage(driver.profileUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 20),

          // ── Right Column: Name → KL → Action Buttons ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  driver.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 4),

                // Green check + KL number
                Row(
                  children: [
                    Image.asset(
                      'Icons and assets/icons8-check-30.png',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      driver.numberPlate,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action buttons — spaced out under the name/KL area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-whatsapp-logo-48.png',
                      label: 'message',
                      onTap: () => _launchWhatsApp(context),
                      iconSize: 36,
                    ),
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-call-48.png',
                      label: 'Call',
                      onTap: () => _launchCall(context),
                      iconSize: 32,
                    ),
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-star-48.png',
                      label: 'rate',
                      onTap: () => _showRatingDialog(context, ref),
                      iconSize: 32,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Action Button ──
  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    double iconSize = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: iconSize, height: iconSize),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

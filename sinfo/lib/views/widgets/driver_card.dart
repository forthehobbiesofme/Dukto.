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
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: colorOutline, width: 2.5),
              ),
              backgroundColor: colorPaleOrange,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              filled ? Icons.star : Icons.star_border_rounded,
                              size: 40,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    // ── Prompt Text ──
                    Text(
                      notifier.translate('Rate your experience.....'),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Input + Done Button Row ──
                    Row(
                      children: [
                        // Grey pill input
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D9D9),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.black54,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: commentController,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: notifier.translate('type something..'),
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                                 const SizedBox(width: 10),

                        // Actions
                        if (isUpdate)
                          GestureDetector(
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
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.black54, width: 1),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.delete, color: Colors.white, size: 22),
                            ),
                          ),
                        if (isUpdate) const SizedBox(width: 10),
                        Expanded(
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
                              height: 44,
                              decoration: BoxDecoration(
                                color: colorOrange,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.black54,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isUpdate ? 'Update' : notifier.translate('Done'),
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
        color: colorPaleOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Orange Profile Circle ──
          Container(
            width: 85,
            height: 85,
            decoration: BoxDecoration(
              color: colorOrange,
              shape: BoxShape.circle,
              image: driver.profileUrl != null
                  ? DecorationImage(
                      image: NetworkImage(driver.profileUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 16),

          // ── Right Column: Name → KL → Action Buttons ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  driver.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
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
                    const SizedBox(width: 5),
                    Text(
                      driver.numberPlate,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action buttons — spaced out under the name/KL area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-whatsapp-logo-48.png',
                      label: 'message', // Exact label from image
                      onTap: () => _launchWhatsApp(context),
                      iconSize: 36,
                    ),
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-call-48.png',
                      label: 'Call', // Exact label from image
                      onTap: () => _launchCall(context),
                      iconSize: 32,
                    ),
                    _buildActionButton(
                      iconPath: 'Icons and assets/icons8-star-48.png',
                      label: 'rate', // Exact label from image
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

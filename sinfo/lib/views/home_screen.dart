import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nearby_service_app/providers/driver_provider.dart';
import 'package:nearby_service_app/providers/settings_provider.dart';
import 'package:nearby_service_app/views/widgets/driver_card.dart';
import 'package:nearby_service_app/views/landing_screen.dart';
import 'package:nearby_service_app/providers/auth_provider.dart';
import 'package:nearby_service_app/models/driver.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasRequested = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Future<List<Driver>>? _searchFuture;

  void _showSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    notifier.translate('Settings'),
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(notifier.translate('Language'), style: GoogleFonts.montserrat()),
                    trailing: DropdownButton<bool>(
                      value: settings.isMalayalam,
                      items: [
                        DropdownMenuItem(value: false, child: Text(notifier.translate('English'), style: GoogleFonts.montserrat())),
                        DropdownMenuItem(value: true, child: Text(notifier.translate('Malayalam'), style: GoogleFonts.montserrat())),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setLanguage(val);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(notifier.translate('Theme'), style: GoogleFonts.montserrat()),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode == ThemeMode.system
                          ? ThemeMode.system
                          : settings.themeMode,
                      items: [
                        DropdownMenuItem(value: ThemeMode.system, child: Text(notifier.translate('System'), style: GoogleFonts.montserrat())),
                        DropdownMenuItem(value: ThemeMode.light, child: Text(notifier.translate('Light Mode'), style: GoogleFonts.montserrat())),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text(notifier.translate('Dark Mode'), style: GoogleFonts.montserrat())),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setTheme(val);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(notifier.translate('My Details'), style: GoogleFonts.montserrat()),
                    onTap: () {
                      Navigator.pop(context);
                      _showUserDetails(context, ref, notifier);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      notifier.translate('Logout / Delete Account'),
                      style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmLogout(context, ref, notifier);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, WidgetRef ref, SettingsNotifier notifier) {
    final auth = ref.read(authProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notifier.translate('My Details'), style: GoogleFonts.montserrat()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${auth.name}', style: GoogleFonts.montserrat()),
              const SizedBox(height: 8),
              Text('Phone: ${auth.phone}', style: GoogleFonts.montserrat()),
              if (auth.numberPlate != null) ...[
                const SizedBox(height: 8),
                Text('KL Number: ${auth.numberPlate}', style: GoogleFonts.montserrat()),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(notifier.translate('Close'), style: GoogleFonts.montserrat()),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notifier.translate('Logout / Delete Account'), style: GoogleFonts.montserrat()),
          content: Text(notifier.translate('Are you sure you want to logout and delete your account?'), style: GoogleFonts.montserrat()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(notifier.translate('Cancel'), style: GoogleFonts.montserrat()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await ref.read(authProvider.notifier).logout();
                  
                  if (!context.mounted) return;
                  Navigator.pop(context); // close loading
                  
                  // Navigate back to LandingScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LandingScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context); // close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e', style: GoogleFonts.montserrat())),
                  );
                }
              },
              child: Text(notifier.translate('Confirm'), style: GoogleFonts.montserrat()),
            ),
          ],
        );
      },
    );
  }

  void _onSearchSubmitted(String value) {
    final q = value.trim();
    setState(() {
      _searchQuery = q;
      if (q.isNotEmpty) {
        _searchFuture = ref.read(supabaseServiceProvider).searchDrivers(q);
      } else {
        _searchFuture = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(settingsProvider.notifier);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5E5E5),
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFBDBDBD),
              shape: BoxShape.circle,
              image: auth.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(auth.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.montserrat(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search Name or KL...',
                  hintStyle: GoogleFonts.montserrat(color: Colors.black54),
                  border: InputBorder.none,
                ),
                onSubmitted: _onSearchSubmitted,
              )
            : const SizedBox(),
        actions: [
          IconButton(
            icon: Image.asset(
              'Icons and assets/icons8-search-50.png',
              width: 28,
              height: 28,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _searchFuture = null;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Image.asset(
              'Icons and assets/icons8-settings-48.png',
              width: 28,
              height: 28,
              color: Colors.black,
            ),
            onPressed: () => _showSettings(context, ref),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_hasRequested || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Search results for "$_searchQuery"'
                          : notifier.translate('showing nearby result'),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      'Icons and assets/icons8-down-arrow-50.png',
                      width: 16,
                      height: 16,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : (_hasRequested
                      ? _buildNearbyList()
                      : Center(
                          child: Text(
                            notifier.translate('Tap the button below to find autos near you.'),
                            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 16),
                          ),
                        )),
            ),
            if (!_hasRequested && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _hasRequested = true);
                      ref.invalidate(nearbyDriversProvider);
                    },
                    icon: const Icon(Icons.my_location),
                    label: Text(notifier.translate('Find Nearby Autos'), style: GoogleFonts.montserrat(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Driver>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.montserrat()));
        }
        final drivers = snapshot.data ?? [];
        if (drivers.isEmpty) {
          return Center(child: Text('No results found.', style: GoogleFonts.montserrat(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: drivers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => DriverCard(driver: drivers[index]),
        );
      },
    );
  }

  Widget _buildNearbyList() {
    final driversAsync = ref.watch(nearbyDriversProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return driversAsync.when(
      data: (drivers) {
        if (drivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(notifier.translate('No drivers found within 5km'), style: GoogleFonts.montserrat(color: Colors.black38)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: drivers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return DriverCard(driver: drivers[index]);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) {
        String errorMessage = err.toString().replaceAll('Exception: ', '');
        IconData errorIcon = Icons.error_outline;
        
        if (errorMessage.contains('Location permissions are denied') || errorMessage.contains('permanently denied') || errorMessage.contains('disabled')) {
          errorMessage = notifier.translate('Please turn on your location permissions to find nearby autos.');
          errorIcon = Icons.location_off;
        } else if (errorMessage.contains('SocketException') || errorMessage.contains('network') || errorMessage.contains('Failed host lookup')) {
          errorMessage = notifier.translate('Please check your internet connection.');
          errorIcon = Icons.wifi_off;
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(errorIcon, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.black54, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

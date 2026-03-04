import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _userName = '';
  String _userId = '';
  bool _isLoading = false;
  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _determinePosition();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Employee';
      _userId = prefs.getString('user_id_pegawai') ?? 'EMP-001';
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if(mounted) {
      setState(() {
        _currentPosition = pos;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    }
  }

  void _performAttendance(bool isCheckIn) async {
    setState(() => _isLoading = true);
    try {
      if (_currentPosition == null) {
        await _determinePosition();
      }
      if (_currentPosition == null) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot get GPS location. Please turn on GPS.')));
         return;
      }
      
      final response = isCheckIn 
      ? await _apiService.checkIn(_currentPosition!.latitude, _currentPosition!.longitude)
      : await _apiService.checkOut(_currentPosition!.latitude, _currentPosition!.longitude);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
    String formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profile
              Row(
                children: [
                   CircleAvatar(
                     radius: 24,
                     backgroundColor: Colors.grey[300],
                     child: Icon(Icons.person, color: Colors.grey[700], size: 28),
                   ),
                   SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                         Text('ID: $_userId', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                       ],
                     ),
                   ),
                   Container(
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white,
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2)),
                       ]
                     ),
                     child: IconButton(
                       icon: Icon(Icons.notifications_none, color: Colors.black87),
                       onPressed: () {},
                     ),
                   )
                ],
              ),
              SizedBox(height: 32),
              
              // Clock Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2)),
                  ]
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedTime, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                    SizedBox(height: 4),
                    Text(formattedDate, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 20),
                    
                    // Maps Area
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : LatLng(-6.200000, 106.816666),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                                userAgentPackageName: 'com.flutterabsen.workforceconnect',
                              ),
                              if (_currentPosition != null) ...[
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF135BEC).withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(Icons.location_on, color: Color(0xFF135BEC), size: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]
                            ],
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                              ),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                  SizedBox(width: 6),
                                  Text('GPS Active', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
               // Buttons
               _isLoading ? Center(child: CircularProgressIndicator(color: Color(0xFF135BEC))) :
               Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _performAttendance(true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2EBD6E), Color(0xFF1D8C4D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Color(0xFF2EBD6E).withOpacity(0.3), blurRadius: 15, offset: Offset(0, 5)),
                            ]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.login_rounded, size: 32, color: Colors.white),
                              SizedBox(height: 8),
                              Text('Check In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _performAttendance(false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5)),
                            ]
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.logout_rounded, size: 32, color: Colors.grey[600]),
                              SizedBox(height: 8),
                              Text('Check Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                // Today Stats Placeholder
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2)),
                    ]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('TOTAL HOURS', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('0h 0m', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: Column(
                          children: [
                            Text('ATTENDANCE', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('22 Days', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

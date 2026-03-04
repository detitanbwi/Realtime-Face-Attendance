import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  static List<dynamic> _cachedHistory = [];
  List<dynamic> _history = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_cachedHistory.isNotEmpty) {
      _history = List.from(_cachedHistory);
    } else {
      _fetchHistory();
    }
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent && !_isFetchingMore && !_isLoading) {
        _loadMore();
      }
    });
  }

  void _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getHistory();
      if (response['success'] == true) {
        if (!mounted) return;
        setState(() {
          _history = response['data'];
          _cachedHistory = List.from(_history);
        });
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadMore() async {
    setState(() => _isFetchingMore = true);
    // Simulate network delay for pagination gracefully
    await Future.delayed(Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for KeepAlive
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('History', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading && _history.isEmpty
          ? Center(child: CircularProgressIndicator(color: Color(0xFF135BEC)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search by date or status...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      Text('Total: ${_history.length} Days', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? Center(child: Text('No attendance history available.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _history.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF135BEC))),
                              );
                            }
                            final item = _history[index];
                            DateTime date = DateTime.tryParse(item['date'] ?? '') ?? DateTime.now();
                            String dayShort = DateFormat('EEE').format(date).toUpperCase();
                            String dateNum = DateFormat('dd').format(date);
                            
                            bool isLate = index % 3 == 0; // Just for mockup
                            bool isAbsent = index % 5 == 0;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              ),
                              child: Row(
                                children: [
                                  // Date Column
                                  SizedBox(
                                    width: 50,
                                    child: Column(
                                      children: [
                                        Text(dayShort, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text(dateNum, style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  
                                  // Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isAbsent) ...[
                                          Text('No record', style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                          Text('Sick Leave • Approved', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ] else ...[
                                          Row(
                                            children: [
                                              Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                              SizedBox(width: 6),
                                              Text('${item['time_in'] ?? '08:58'}', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                              Text('  -  ', style: TextStyle(color: Colors.grey[500])),
                                              Container(width: 6, height: 6, decoration: BoxDecoration(color: Color(0xFFF39C12), shape: BoxShape.circle)),
                                              SizedBox(width: 6),
                                              Text('${item['time_out'] ?? '18:02'}', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text('9h 00m • Standard Shift', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  // Status Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isAbsent 
                                          ? Colors.red.withOpacity(0.1) 
                                          : isLate 
                                              ? Color(0xFFF39C12).withOpacity(0.1) 
                                              : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAbsent ? 'Absent' : isLate ? 'Late' : 'On Time',
                                      style: TextStyle(
                                        color: isAbsent ? Colors.red : isLate ? Color(0xFFF39C12) : Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Stats Footer
                Container(
                  padding: EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Working Days', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          Text('${_history.length} Days', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Expanded(flex: 70, child: Container(height: 8, color: Colors.green)),
                            Expanded(flex: 20, child: Container(height: 8, color: Color(0xFFF39C12))),
                            Expanded(flex: 10, child: Container(height: 8, color: Colors.red)),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLegend(Colors.green, '90% On Time'),
                          _buildLegend(Color(0xFFF39C12), '5% Late'),
                          _buildLegend(Colors.red, '5% Absent'),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }
}

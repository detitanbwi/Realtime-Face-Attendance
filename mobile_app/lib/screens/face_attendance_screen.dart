import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/face_classifier.dart';
import '../services/api_service.dart';
import 'package:image/image.dart' as img;

class FaceAttendanceScreen extends StatefulWidget {
  @override
  _FaceAttendanceScreenState createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  CameraController? _cameraController;
  CameraLensDirection _cameraDirection = CameraLensDirection.front;
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  late FaceClassifier _faceClassifier;
  
  bool _isProcessing = false;
  bool _isInitializing = true;
  String _status = "Memulai sistem...";
  
  List<dynamic> _registeredFaces = [];

  // Debug states
  int _facesCount = 0;
  bool _isFaceDetected = false;
  bool _isEmbeddingGenerated = false;
  String _debugMessage = "";
  
  // Overlay states
  bool _showSuccessOverlay = false;
  String _matchedName = "";
  String _matchedNia = "";
  Timer? _overlayTimer;
  
  DateTime? _lastLogTime;
  int? _lastLogUserId;

  // TTS
  final FlutterTts _tts = FlutterTts();

  // GPS
  double? _latitude;
  double? _longitude;
  bool _isGpsReady = false;

  // Already attended state
  bool _showAlreadyAttended = false;
  String _alreadyAttendedTime = "";

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSystem();
    _initGps();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSystem() async {
    try {
      _faceClassifier = FaceClassifier();
      await _faceClassifier.loadModel();
      setState(() { _status = "Sinkronisasi data absensi..."; });
      
      final data = await ApiService().getSyncData().timeout(
        Duration(seconds: 10),
        onTimeout: () => {'error': 'Koneksi server timeout (10 detik)'},
      );
      if (data != null && data.containsKey('data')) {
        _registeredFaces = data['data'];
        setState(() { _status = "Membuka kamera..."; });
      } else {
        setState(() { 
          _status = "Gagal Server: ${data?['message'] ?? data?['error'] ?? 'Data gagal diurai.'} \n\nPastikan Anda mendaftarkan wajah terlebih dahulu."; 
          _isInitializing = false;
        });
        return;
      }

      await _initCamera(_cameraDirection);
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Error inisialisasi: $e";
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _initGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _debugMessage = "GPS ditolak permanen"; });
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .timeout(Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isGpsReady = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _debugMessage = "GPS Error: $e"; });
    }
  }

  Future<void> _initCamera(CameraLensDirection direction) async {
    try {
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == direction,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _status = "Posisikan wajah Anda";
      });

      _cameraController!.startImageStream((image) {
        if (!_isProcessing) {
          _processCameraImage(image);
        }
      });
    } catch(e) {
      if (mounted) {
        setState(() {
          _status = "Kamera error: $e";
        });
      }
    }
  }

  void _flipCamera() {
    _cameraDirection = _cameraDirection == CameraLensDirection.front 
        ? CameraLensDirection.back 
        : CameraLensDirection.front;
    setState(() {
      _isInitializing = true;
      _status = "Membalik kamera...";
    });
    _initCamera(_cameraDirection);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation;
    if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
        var rotationCompensation = 0;
        final deviceOrientation = _cameraController!.value.deviceOrientation;
        switch (deviceOrientation) {
          case DeviceOrientation.portraitUp: rotationCompensation = 0; break;
          case DeviceOrientation.landscapeLeft: rotationCompensation = 90; break;
          case DeviceOrientation.portraitDown: rotationCompensation = 180; break;
          case DeviceOrientation.landscapeRight: rotationCompensation = 270; break;
        }
        if (camera.lensDirection == CameraLensDirection.front) {
          rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
        } else {
          rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: image.planes[0].bytesPerRow,
        ),
    );
  }

  img.Image? _convertYUV420toImageColor(CameraImage image) {
      try {
          return img.Image.fromBytes(width: image.width, height: image.height, bytes: image.planes[0].bytes.buffer, format: img.Format.uint8, numChannels: 1, rowStride: image.planes[0].bytesPerRow);
      } catch(e) {
          return null;
      }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_registeredFaces.isEmpty) return;
    
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        if(mounted) setState(() { _debugMessage = "Gagal memproses Stream"; _isProcessing = false; });
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) setState(() {
          _facesCount = faces.length;
          _isFaceDetected = faces.isNotEmpty;
          if (_isFaceDetected) _debugMessage = "Mencari kecocokan...";
      });

      if (faces.isNotEmpty) {
        final face = faces.first;
        if (mounted) setState(() { _status = "Wajah terdeteksi. Menganalisis..."; });

        img.Image? convertedImage = _convertYUV420toImageColor(image);
        if (convertedImage != null) {
          if (Platform.isAndroid) {
            convertedImage = img.copyRotate(convertedImage, angle: _cameraController!.description.sensorOrientation);
          }
          final bbox = face.boundingBox;
          int x = bbox.left.toInt().clamp(0, convertedImage.width);
          int y = bbox.top.toInt().clamp(0, convertedImage.height);
          int w = bbox.width.toInt().clamp(0, convertedImage.width - x);
          int h = bbox.height.toInt().clamp(0, convertedImage.height - y);

          img.Image croppedFace = img.copyCrop(convertedImage, x: x, y: y, width: w, height: h);
          final embedding = _faceClassifier.getEmbedding(croppedFace);
          
          if(mounted) setState(() { _isEmbeddingGenerated = true; });
          
          await _matchFace(embedding);
        } else {
          if(mounted) setState(() { _debugMessage = "Gagal konversi Image"; });
        }
      } else {
        if (mounted) setState(() { 
          _status = "Posisikan wajah Anda"; 
          _isEmbeddingGenerated = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() { _debugMessage = "Error ML: $e"; });
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  Future<void> _matchFace(List<double> currentEmbedding) async {
    double minDistance = double.infinity;
    dynamic matchedUser;

    for (var registered in _registeredFaces) {
      List<double>? dbEmbedding;
      var faceEmbeddingData = registered['face_embedding'];
      
      if (faceEmbeddingData == null) continue;

      if (faceEmbeddingData is String) {
        dbEmbedding = List<double>.from(
            faceEmbeddingData.replaceAll('[', '').replaceAll(']', '').split(',').map((e) => double.parse(e.trim()))
        );
      } else if (faceEmbeddingData is List) {
        dbEmbedding = List<double>.from(faceEmbeddingData.map((e) => double.parse(e.toString())));
      }

      if (dbEmbedding != null) {
        double distance = _faceClassifier.calculateDistance(currentEmbedding, dbEmbedding);
        if (distance < minDistance) {
          minDistance = distance;
          matchedUser = registered;
        }
      }
    }

    if (minDistance < 0.8 && matchedUser != null) {
      if (_showSuccessOverlay && _matchedName == matchedUser['name']) {
           return; 
      }

      int userId = matchedUser['id'];
      
      // Prevent API spam if recognized within 10 seconds repeatedly
      if (_lastLogUserId == userId && _lastLogTime != null && DateTime.now().difference(_lastLogTime!).inSeconds < 10) {
           return; 
      }

      if (mounted) setState(() { _status = "Menyimpan absensi..."; });
      final result = await ApiService().logFaceAttendance(userId, latitude: _latitude, longitude: _longitude);
      
      if (!mounted) return;
      
      if (result != null) {
        _lastLogUserId = userId;
        _lastLogTime = DateTime.now();
        String name = matchedUser['name'];
        String nia = matchedUser['nia'] ?? '-';

        if (result['already_attended'] == true) {
          // Already attended today - yellow border
          setState(() {
              _showSuccessOverlay = true;
              _showAlreadyAttended = true;
              _matchedName = name;
              _matchedNia = nia;
              _alreadyAttendedTime = result['check_in_time'] ?? '';
              _status = "Sudah Absen";
          });
          _tts.speak('$name sudah absen');
        } else {
          // New attendance - green success
          setState(() {
              _showSuccessOverlay = true;
              _showAlreadyAttended = false;
              _matchedName = name;
              _matchedNia = nia;
              _status = "Sukses Absen";
          });
          _tts.speak('Halo $name');
        }

        _overlayTimer?.cancel();
        _overlayTimer = Timer(Duration(seconds: 4), () {
          if (mounted) setState(() { _showSuccessOverlay = false; _showAlreadyAttended = false; });
        });
      } else {
        setState(() { _status = "Gagal menyimpan jaringan."; });
      }
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _tts.stop();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Widget _buildChecklistItem(String title, bool isReady) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isReady ? Icons.check_circle : Icons.radio_button_unchecked, color: isReady ? Colors.green : Colors.grey, size: 16),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: isReady ? FontWeight.bold : FontWeight.normal, color: isReady ? Colors.black87 : Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Absensi Wajah'),
        backgroundColor: Color(0xFF135BEC),
        actions: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            IconButton(
              icon: Icon(Icons.flip_camera_android),
              onPressed: _flipCamera,
            )
        ],
      ),
      body: _isInitializing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(_status, style: TextStyle(color: Colors.white), textAlign: TextAlign.center)
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _cameraController != null && _cameraController!.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                                aspectRatio: 1 / _cameraController!.value.aspectRatio,
                                child: CameraPreview(_cameraController!),
                            ),
                            // Gradient glow from edges (green=success, amber=already attended)
                            if (_showSuccessOverlay)
                              ...[
                                // Top edge
                                Positioned(top: 0, left: 0, right: 0, height: 40, child: Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: [(_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0.4), (_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0)],
                                  )),
                                )),
                                // Bottom edge
                                Positioned(bottom: 0, left: 0, right: 0, height: 40, child: Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                    colors: [(_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0.4), (_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0)],
                                  )),
                                )),
                                // Left edge
                                Positioned(top: 0, bottom: 0, left: 0, width: 40, child: Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(
                                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                                    colors: [(_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0.4), (_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0)],
                                  )),
                                )),
                                // Right edge
                                Positioned(top: 0, bottom: 0, right: 0, width: 40, child: Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(
                                    begin: Alignment.centerRight, end: Alignment.centerLeft,
                                    colors: [(_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0.4), (_showAlreadyAttended ? Colors.amber : Colors.green).withOpacity(0)],
                                  )),
                                )),
                              ],
                            if (_showSuccessOverlay)
                              Positioned(
                                bottom: 40,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _showAlreadyAttended 
                                        ? Colors.amber.shade50.withOpacity(0.95) 
                                        : Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(30),
                                    border: _showAlreadyAttended 
                                        ? Border.all(color: Colors.amber, width: 2) 
                                        : null,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                                    ]
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _showAlreadyAttended ? Colors.amber : Colors.green,
                                        child: Icon(
                                          _showAlreadyAttended ? Icons.info_outline : Icons.check, 
                                          color: Colors.white
                                        ),
                                        radius: 18,
                                      ),
                                      SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_matchedName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(_matchedNia, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                          if (_showAlreadyAttended)
                                            Text('Sudah absen pukul $_alreadyAttendedTime', style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w500)),
                                        ],
                                      )
                                    ],
                                  )
                                )
                              )
                          ],
                        )
                      : Container(),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("DEBUG STATUS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                              _buildChecklistItem("GPS Aktif", _isGpsReady),
                              _buildChecklistItem("Menangkap Wajah ($_facesCount)", _isFaceDetected),
                              _buildChecklistItem("Algoritma Wajah", _isEmbeddingGenerated),
                            ],
                          ),
                          Expanded(
                            child: Text(
                              _debugMessage, 
                              style: TextStyle(color: Colors.orange, fontSize: 11, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                            ),
                          )
                        ],
                      ),
                      Divider(height: 24, thickness: 1),
                      Text(
                        _status,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Posisikan wajah Anda dengan jelas dalam sorotan lensa kamera.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}

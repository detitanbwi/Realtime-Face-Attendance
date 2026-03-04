import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/face_classifier.dart';
import '../services/api_service.dart';
import 'package:image/image.dart' as img;

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll('-', '');
    if (newText.length > 8) newText = newText.substring(0, 8);
    
    String formatted = '';
    for (int i = 0; i < newText.length; i++) {
        formatted += newText[i];
        if ((i == 1 || i == 3) && i != newText.length - 1) {
            formatted += '-';
        }
    }
    
    return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _niaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _isTokenVerified = false;
  bool _isVerifyingToken = false;
  bool _isRegistering = false;
  
  List<double>? _faceEmbedding;
  late FaceClassifier _faceClassifier;

  @override
  void initState() {
    super.initState();
    _initClassifier();
  }
  
  Future<void> _initClassifier() async {
    _faceClassifier = FaceClassifier();
    await _faceClassifier.loadModel();
  }

  void _verifyToken() async {
    setState(() => _isVerifyingToken = true);
    final success = await ApiService().verifyFaceToken(_tokenController.text);
    setState(() => _isVerifyingToken = false);

    if (success) {
      setState(() {
        _isTokenVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token Berhasil Diverifikasi!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Verifikasi Gagal, Token tidak ditemukan.'), backgroundColor: Colors.red),
      );
    }
  }

  void _submitRegistration() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _birthDateController.text.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Form Belum Lengkap',
        desc: 'Mohon lengkapi semua isian.',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    if (_faceEmbedding == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'Data Wajah Kosong',
        desc: 'Mohon ambil data wajah terlebih dahulu menggunakan tombol Kamera.',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _isRegistering = true);

    final parts = _birthDateController.text.split('-');
    String parsedDate = _birthDateController.text;
    if (parts.length == 3) {
      parsedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
    }

    try {
      final success = await ApiService().registerFace(
        token: _tokenController.text,
        name: _nameController.text,
        nia: _niaController.text,
        address: _addressController.text,
        birthDate: parsedDate,
        embedding: _faceEmbedding!,
      );

      setState(() => _isRegistering = false);

      if (success) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          title: 'Registrasi Berhasil',
          desc: 'Data wajah Anda telah disimpan ke sistem.',
          btnOkOnPress: () {
            Navigator.of(context).pop();
          },
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          title: 'Gagal',
          desc: 'Gagal menyimpan pendaftaran, periksa kembali data Anda.',
          btnOkOnPress: () {},
        ).show();
      }
    } catch (e) {
      setState(() => _isRegistering = false);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'Error Jaringan',
        desc: 'Tidak bisa menghubungi server: $e',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<void> _openCameraDialog() async {
    final embedded = await showDialog<List<double>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CameraCaptureDialog(faceClassifier: _faceClassifier),
    );
    if (embedded != null) {
      setState(() {
        _faceEmbedding = embedded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wajah berhasil direkam!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _nameController.dispose();
    _niaController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pendaftaran Wajah Baru'),
        backgroundColor: Color(0xFF135BEC),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isTokenVerified) ...[
              TextField(
                controller: _tokenController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                decoration: InputDecoration(
                   labelText: 'Token Unik',
                   border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF135BEC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isVerifyingToken ? null : _verifyToken,
                  child: _isVerifyingToken 
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Verifikasi Token', style: TextStyle(fontSize: 16)),
                ),
              ),
            ] else ...[
               Container(
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.green.shade50,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.green)
                 ),
                 child: Row(
                   children: [
                     Icon(Icons.check_circle, color: Colors.green),
                     SizedBox(width: 8),
                     Text("Token Berhasil Diverifikasi", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
               SizedBox(height: 16),
               TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
               ),
               SizedBox(height: 12),
               TextField(
                controller: _niaController,
                decoration: InputDecoration(labelText: 'NIA (Opsional)', border: OutlineInputBorder()),
               ),
               SizedBox(height: 12),
               TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()),
               ),
               SizedBox(height: 12),
               TextField(
                controller: _birthDateController,
                keyboardType: TextInputType.number,
                inputFormatters: [_DateInputFormatter()],
                decoration: InputDecoration(labelText: 'Tanggal Lahir (DD-MM-YYYY)', border: OutlineInputBorder()),
               ),
               SizedBox(height: 24),
               
               Container(
                 width: double.infinity,
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey.shade300),
                   borderRadius: BorderRadius.circular(12)
                 ),
                 child: Column(
                   children: [
                     Icon(
                       _faceEmbedding != null ? Icons.face_retouching_natural : Icons.face, 
                       size: 64, 
                       color: _faceEmbedding != null ? Colors.green : Colors.grey
                     ),
                     SizedBox(height: 8),
                     Text(
                       _faceEmbedding != null ? "Data Wajah Tersimpan" : "Wajah Belum Direkam",
                       style: TextStyle(fontWeight: FontWeight.bold, color: _faceEmbedding != null ? Colors.green : Colors.black87),
                     ),
                     SizedBox(height: 12),
                     OutlinedButton.icon(
                       icon: Icon(Icons.camera_alt),
                       label: Text(_faceEmbedding != null ? "Ulangi Ambil Wajah" : "Buka Kamera Perekam"),
                       onPressed: _openCameraDialog,
                     )
                   ],
                 ),
               ),
               
               SizedBox(height: 32),
               SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF135BEC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isRegistering ? null : _submitRegistration,
                  child: _isRegistering 
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Simpan Pendaftaran', style: TextStyle(fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _CameraCaptureDialog extends StatefulWidget {
  final FaceClassifier faceClassifier;
  _CameraCaptureDialog({required this.faceClassifier});

  @override
  __CameraCaptureDialogState createState() => __CameraCaptureDialogState();
}

class __CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  CameraController? _cameraController;
  CameraLensDirection _cameraDirection = CameraLensDirection.front;
  
  bool _isProcessingImage = false;
  String _statusMessage = "Membuka kamera...";
  int _facesCount = 0;
  bool _isFaceDetected = false;
  bool _isEmbeddingGenerated = false;
  String _debugMessage = "";

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initCamera(_cameraDirection);
  }

  Future<void> _initCamera(CameraLensDirection direction) async {
    try {
      if (_cameraController != null) {
        await _cameraController!.stopImageStream();
        await _cameraController!.dispose();
        _cameraController = null;
      }

      final cameras = await availableCameras();
      final camera = cameras.firstWhere((c) => c.lensDirection == direction, orElse: () => cameras.first);

      _cameraController = CameraController(
        camera, 
        ResolutionPreset.medium, 
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
          _statusMessage = "Posisikan wajah Anda\ndiantara frame";
      });

      _cameraController!.startImageStream((image) {
        if (!_isProcessingImage) {
          _processCameraImage(image);
        }
      });
    } catch(e) {
      if(mounted) setState(() { _statusMessage = "Kamera error: $e"; });
    }
  }

  void _flipCamera() {
    _cameraDirection = _cameraDirection == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;
    setState(() { _statusMessage = "Membalik kamera..."; });
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
    _isProcessingImage = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        if (mounted) setState(() { _debugMessage = "Gagal memproses Stream"; _isProcessingImage = false; });
        return;
      }
      
      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) setState(() {
          _facesCount = faces.length;
          _isFaceDetected = faces.isNotEmpty;
          if (_isFaceDetected) _debugMessage = "Mengekstrak matriks wajah...";
      });

      if (faces.isNotEmpty) {
        final face = faces.first;
        if (mounted) setState(() { _statusMessage = "Mengekstrak matriks wajah..."; });
        
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
          final embedding = widget.faceClassifier.getEmbedding(croppedFace);

          if (mounted) setState(() {
              _isEmbeddingGenerated = true;
          });
          
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
          }
          
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) Navigator.pop(context, embedding);
        } else {
            if (mounted) setState(() { _debugMessage = "Gagal konversi Image"; });
        }
      }
    } catch(e) {
      if (mounted) setState(() { _debugMessage = "Error ML: $e"; });
    } finally {
      if (mounted) _isProcessingImage = false;
    }
  }

  @override
  void dispose() {
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
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF135BEC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text("Ambil Wajah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   Row(
                     children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.flip_camera_android, color: Colors.white),
                          onPressed: _flipCamera,
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                     ],
                   )
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: _cameraController != null && _cameraController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: 1 / _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        )
                      : CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("DEBUG STATUS:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
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
                  Divider(height: 16, thickness: 1),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/face_classifier.dart';
import '../services/api_service.dart';
import 'package:image/image.dart' as img;

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _nameController = TextEditingController();
  final _niaController = TextEditingController();
  final _addressController = TextEditingController();
  final _birthDateController = TextEditingController();
  
  bool _isCameraReady = false;
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableContours: true, enableClassification: true));
  final FaceClassifier _faceClassifier = FaceClassifier();
  
  bool _tokenVerified = false;
  bool _isProcessingImage = false;
  bool _faceDetected = false;
  List<double>? _faceEmbedding;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  void _initializeClassifier() async {
    await _faceClassifier.loadModel();
  }

  void _verifyToken() async {
    if (_tokenController.text.isEmpty) return;
    
    // Simulate verifikasi ke Laravel
    // Idealnya call: await ApiService().verifyFaceToken(_tokenController.text)
    try {
      final isValid = await ApiService().verifyFaceToken(_tokenController.text);
      if (isValid) {
        setState(() {
          _tokenVerified = true;
        });
        _initializeCamera();
      } else {
        _showError("Token invalid atau sudah terpakai.");
      }
    } catch (e) {
      _showError("Terjadi kesalahan sistem, cek koneksi Anda.");
    }
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);

    await _cameraController!.initialize();
    setState(() => _isCameraReady = true);

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessingImage || _faceDetected) return;
      _isProcessingImage = true;

      try {
         final WriteBuffer allBytes = WriteBuffer();
         for (final Plane plane in image.planes) {
             allBytes.putUint8List(plane.bytes);
         }
         final bytes = allBytes.done().buffer.asUint8List();

         final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
         final imageRotation = InputImageRotationValue.fromRawValue(frontCamera.sensorOrientation) ?? InputImageRotation.rotation270deg;
         final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
         
         final planeData = image.planes.map((Plane plane) {
            return InputImagePlaneMetadata(
                bytesPerRow: plane.bytesPerRow,
                height: plane.height,
                width: plane.width,
            );
         }).toList();

         final inputImageData = InputImageData(
             size: imageSize,
             imageRotation: imageRotation,
             inputImageFormat: inputImageFormat,
             planeData: planeData,
         );

         final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

         final faces = await _faceDetector.processImage(inputImage);
         if (faces.isNotEmpty) {
            // Wajah terdeteksi -> Convert ke img.Image -> Vektor
            // Mock: Idealnya menggunakan konversi YUV420 ke RGB yang akurat.
            img.Image? convertedImage = _convertYUV420toImageColor(image);
            if(convertedImage != null) {
                _faceEmbedding = _faceClassifier.getEmbedding(convertedImage);
                setState(() {
                    _faceDetected = true;
                });
            }
         }
      } catch (e) {
          // ignore
      }

      _isProcessingImage = false;
    });
  }

  img.Image? _convertYUV420toImageColor(CameraImage image) {
      // Simplifikasi konversi untuk kebutuhan prototype
      try {
          return img.Image.fromBytes(width: image.width, height: image.height, bytes: image.planes[0].bytes.buffer, format: img.Format.uint8);
      } catch(e) {
          return null;
      }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_faceDetected || _faceEmbedding == null) {
      _showError("Rekam wajah belum berhasil. Harap arahkan wajah ke kamera.");
      return;
    }

    try {
        final success = await ApiService().registerFace(
            token: _tokenController.text,
            name: _nameController.text,
            nia: _niaController.text,
            address: _addressController.text,
            birthDate: _birthDateController.text,
            embedding: _faceEmbedding!
        );
        
        if (success) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.success,
              animType: AnimType.bottomSlide,
              title: 'Pendaftaran Berhasil',
              desc: 'Data dan wajah Anda telah berhasil didaftarkan.',
              btnOkOnPress: () {
                Navigator.pop(context);
              },
            ).show();
        } else {
            _showError("Gagal mendaftar. Kemungkinan token hangus atau NIA duplikat.");
        }
    } catch(e) {
        _showError("Timeout: Tidak dapat terhubung ke server.");
    }
  }

  void _showError(String message) {
      AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.bottomSlide,
          title: 'Error',
          desc: message,
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
      ).show();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pendaftaran Wajah")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: _tokenVerified ? _buildForm() : _buildTokenForm(),
      ),
    );
  }

  Widget _buildTokenForm() {
    return Column(
      children: [
        Text("Masukkan Token dari Admin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        TextField(
          controller: _tokenController,
          decoration: InputDecoration(labelText: 'Token Unik'),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _verifyToken,
          child: Text("Verifikasi Token"),
        )
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nama Lengkap'),
            validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _niaController,
            decoration: InputDecoration(labelText: 'NIA (Maks 7 Angka) - Opsional'),
            keyboardType: TextInputType.number,
            maxLength: 7,
            validator: (val) {
                if(val != null && val.isNotEmpty) {
                    if (val.length > 7) return 'Maks 7 Angka';
                    if (int.tryParse(val) == null) return 'Hanya boleh angka';
                }
                return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(labelText: 'Alamat'),
            validator: (val) => val!.isEmpty ? 'Alamat wajib diisi' : null,
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _birthDateController,
            decoration: InputDecoration(labelText: 'Tanggal Lahir (YYYY-MM-DD)'),
            validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
          ),
          SizedBox(height: 24),

          // Camera View
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.black,
            child: _isCameraReady ? CameraPreview(_cameraController!) : Center(child: CircularProgressIndicator()),
          ),
          
          SizedBox(height: 12),
          Text(_faceDetected ? "✅ Rekam wajah berhasil" : "Memindai wajah otomatis...", 
            style: TextStyle(
                color: _faceDetected ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16
            )),
          
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            child: Text("Submit Pendaftaran"),
          )
        ],
      ),
    );
  }
}

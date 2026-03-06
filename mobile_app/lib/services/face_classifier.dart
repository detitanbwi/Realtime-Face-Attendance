import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

class FaceClassifier {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/mobile_face_net.tflite');
  }

  // Pre-processing: resize 112x112 & normalize -1 to 1
  List<List<List<List<double>>>> preProcess(img.Image image) {
    img.Image resized = img.copyResize(image, width: 112, height: 112);
    var input = List.generate(1, (i) => List.generate(112, (y) => List.generate(112, (x) => List.filled(3, 0.0))));
    
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        var pixel = resized.getPixel(x, y);
        input[0][y][x][0] = (pixel.r - 127.5) / 127.5;
        input[0][y][x][1] = (pixel.g - 127.5) / 127.5;
        input[0][y][x][2] = (pixel.b - 127.5) / 127.5;
      }
    }
    return input;
  }

  // Generate 192-D Vector
  List<double> getEmbedding(img.Image faceImage) {
    var input = preProcess(faceImage);
    var output = List.generate(1, (i) => List.filled(192, 0.0));
    _interpreter?.run(input, output);
    return output[0];
  }

  // Cosine Similarity (Higher is better, 1.0 is exact match, 0.0 is orthogonal)
  double calculateSimilarity(List<double> emb1, List<double> emb2) {
    if (emb1.length != emb2.length) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
      norm1 += pow(emb1[i], 2);
      norm2 += pow(emb2[i], 2);
    }
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}

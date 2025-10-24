import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<String>> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String fullText = recognizedText.text;

      // Yazıyı virgül ve satır sonu ile ayırarak liste oluştur
      List<String> ingredients =
          fullText
              .split(RegExp(r'[,\n]')) // Virgül ve satır sonu ile böl
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e.length > 1)
              .toList();

      return ingredients;
    } catch (e) {
      print('OCR Hatası: $e');
      throw Exception('Fotoğraftan yazı çıkarılamadı: $e');
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}

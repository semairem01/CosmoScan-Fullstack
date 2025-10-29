import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../bottom_navbar.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/ocr_service.dart';
import '../../services/camera_service.dart';
import 'result_page.dart';
import '../../services/ingredient_normalizer.dart';

class CosmoscanHomePage extends StatefulWidget {
  const CosmoscanHomePage({super.key});

  @override
  _CosmoscanHomePageState createState() => _CosmoscanHomePageState();
}

class _CosmoscanHomePageState extends State<CosmoscanHomePage> {
  int _currentIndex = 0; // <-- Eklendi: Seçili tabı tutacak

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      // Burada index'e göre farklı sayfalara yönlendirme yapabilirsin istersen
    });
  }

  double _scale = 1.0;

  void _onCameraTap() async {
    final cameraService = CameraService();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fotoğraf Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Kamera ile Çek'),
              onTap: () async {
                Navigator.pop(context);
                final file = await cameraService.capturePhoto();
                if (file != null && mounted) {
                  _navigateToLoading(file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galeriden Seç'),
              onTap: () async {
                Navigator.pop(context);
                final file = await cameraService.pickFromGallery();
                if (file != null && mounted) {
                  _navigateToLoading(file);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLoading(File imageFile) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoadingPage(imageFile: imageFile),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Widget _buildTextBoxWithBorder(String text) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/border.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 8, 32, 168),
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  offset: Offset(3.0, 3.0),
                  color: Color.fromARGB(255, 31, 190, 218),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String assetPath, String text) {
    double boxWidth = MediaQuery.of(context).size.width * 0.35;
    return Container(
      width: boxWidth,
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4062BD).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A4A58),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Cosmoscan', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black87),
            onPressed: () {},
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer: Drawer(
        child: ListView(
          children: const <Widget>[
            DrawerHeader(child: Text('Menü')),
            ListTile(title: Text('Profil')),
            ListTile(title: Text('Ayarlar')),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _onCameraTap,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          AnimatedScale(
                            scale: _scale,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.blueAccent,
                                size: 65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextBoxWithBorder(
                      'İçerik listesini taramak için kamera simgesine tıklayın',
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildInfoBox(
                          'assets/icons/scanner.png',
                          'Kameranla ürününün içerik kısmının fotoğrafını çek.',
                        ),
                        _buildInfoBox(
                          'assets/icons/list.png',
                          'Ürünün içerik listesi senin için kontrol edilsin.',
                        ),
                        _buildInfoBox(
                          'assets/icons/toxic.png',
                          'Zararlı içeriklere hızlı bir şekilde ulaş.',
                        ),
                        _buildInfoBox(
                          'assets/icons/health.png',
                          'Kendin ve sevdiklerin için en doğru ürünü seç :)',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _onCameraTap,
            child: Container(
              width: 70, // Yuvarlak çerçeve boyutu
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, // Yuvarlak şekil
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A), // Daha koyu mavi
                    Color(0xFF3B82F6), // Daha parlak mavi
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/cameraa.png',
                  height: 30,
                  width: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4), // İkon ile yazı arasındaki mesafe
          const Text(
            "Scan", // Scan yazısı
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class LoadingPage extends StatefulWidget {
  final File imageFile;

  const LoadingPage({super.key, required this.imageFile});

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late OcrService _ocrService;
  late ApiService _apiService;
  String _statusMessage = 'Fotoğraf işleniyor...';

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    _apiService = ApiService();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() => _statusMessage = 'İçerik yazısı okunuyor...');

      final rawIngredients = await _ocrService.extractText(widget.imageFile);
      final ingredients =
          IngredientNormalizer.normalizeIngredients(rawIngredients);

      if (ingredients.isEmpty) {
        throw Exception(
          'Fotoğrafta geçerli içerik bulunamadı. Lütfen daha net bir fotoğraf çekin.',
        );
      }

      setState(() => _statusMessage = 'İçerikler analiz ediliyor...');

      // 2) API'ye gönder
      final result = await _apiService.analyzeIngredients(ingredients);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(analysisResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } finally {
      _ocrService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Geri tuşunu engelle
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5F1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/loading_animation.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  double _scale = 1.0;

  void _onCameraTap() {
    // Kamera butonuna tıklandığında yapılacak işlemi buraya ekleyebilirsiniz
    setState(() {
      // Animasyon için ölçeklendirme efekti
      _scale = 0.8;
    });

    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _scale =
            1.0; // Efektin bitmesi için tekrar başlangıç durumuna dönüyoruz
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            navItem(icon: Icons.home, label: "Home", index: 0),
            navItem(icon: Icons.search, label: "Search", index: 1),

            const SizedBox(width: 60), // Ortadaki kamera ikonu yerine boşluk

            navItem(icon: Icons.history, label: "History", index: 3),
            navItem(icon: Icons.person, label: "Profile", index: 4),
          ],
        ),
      ),
    );
  }

  Widget navItem({
    required dynamic icon, // IconData ya da görsel
    required String label,
    required int index,
  }) {
    bool isSelected = index == widget.currentIndex;
    return GestureDetector(
      onTap: () => widget.onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon is String
              ? Image.asset(icon, height: 30, width: 30)
              : Icon(
                icon,
                color:
                    isSelected
                        ? const Color.fromARGB(255, 72, 36, 202)
                        : Colors.grey,
              ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.deepPurple : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget cameraButton() {
    return GestureDetector(
      onTap: _onCameraTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Yuvarlak şekil
              gradient: LinearGradient(
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
            duration: Duration(milliseconds: 200),
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Yuvarlak şekil
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt, color: Colors.blueAccent, size: 65),
            ),
          ),
        ],
      ),
    );
  }
}

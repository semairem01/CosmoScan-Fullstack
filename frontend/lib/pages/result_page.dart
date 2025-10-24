import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> analysisResult;

  const ResultPage({super.key, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    List<dynamic> harmfulIngredients =
        analysisResult['harmful_ingredients'] ?? [];
    List<dynamic> safeIngredients = analysisResult['safe_ingredients'] ?? [];
    String overallRisk = analysisResult['overall_risk'] ?? 'UNKNOWN';
    int totalAnalyzed = analysisResult['total_analyzed'] ?? 0;

    Color riskColor;
    String riskText;

    if (overallRisk == 'HIGH') {
      riskColor = Colors.red;
      riskText = '⚠️ YÜKSEKTİR';
    } else if (overallRisk == 'MEDIUM') {
      riskColor = Colors.orange;
      riskText = '⚠️ ORTADADIR';
    } else {
      riskColor = Colors.green;
      riskText = '✓ DÜŞÜKTÜR';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Analiz Sonuçları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Color(0xFFF8F5F1),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Risk Level Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                border: Border.all(color: riskColor, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: riskColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Genel Risk Seviyesi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    riskText,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toplam $totalAnalyzed içerik analiz edildi',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Zararlı İçerikler
            if (harmfulIngredients.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Zararlı İçerikler (${harmfulIngredients.length})',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              ...harmfulIngredients.asMap().entries.map((entry) {
                int index = entry.key;
                var ingredient = entry.value;
                return _buildIngredientCard(
                  ingredient['name'] ?? 'Bilinmeyen',
                  ingredient['description'] ?? '',
                  Colors.red,
                  isHarmful: true,
                  index: index + 1,
                );
              }).toList(),
              SizedBox(height: 24),
            ] else ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Zararlı içerik bulunamadı!',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],

            // Güvenli İçerikler
            if (safeIngredients.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✓ Güvenli İçerikler (${safeIngredients.length})',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              ...safeIngredients.asMap().entries.map((entry) {
                int index = entry.key;
                var ingredient = entry.value;
                return _buildIngredientCard(
                  ingredient['name'] ?? 'Bilinmeyen',
                  ingredient['description'] ?? '',
                  Colors.green,
                  isHarmful: false,
                  index: index + 1,
                );
              }).toList(),
            ],

            SizedBox(height: 32),

            // Tekrar Tarama Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.camera_alt),
                label: Text('Yeni Tarama Yap'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(
    String name,
    String description,
    Color color, {
    required bool isHarmful,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                isHarmful ? Icons.warning : Icons.check_circle,
                color: color,
                size: 20,
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TrangKehoach(),
    );
  }
}

class Nhapgiatri extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String cleanText = newValue.text.replaceAll('.', '');

    if (cleanText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    int value = int.parse(cleanText);
    String formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TrangKehoach extends StatefulWidget {
  const TrangKehoach({super.key});

  @override
  State<TrangKehoach> createState() => _TrangKehoachState();
}

class _TrangKehoachState extends State<TrangKehoach> {
  final tienController = TextEditingController();
  final ngayController = TextEditingController();
  List<Map<String, dynamic>> keHoach = [];

  int currentIndex = 0;
  int tongTien = 0;
  int soNgay = 1;
  bool isVN = true;
  String t(String vn, String en) {
    return isVN ? vn : en;
  }

  String formatTien(int soTien) {
    return soTien.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  final Map<String, Map<String, String>> tenDanhMuc = {
    'meals': {'vn': 'Ăn uống', 'en': 'Meals'},
    'transport': {'vn': 'Đi lại', 'en': 'Transport'},
    'learning': {'vn': 'Học tập', 'en': 'Learning'},
    'games': {'vn': 'Giải trí', 'en': 'Games'},
    'savings': {'vn': 'Tiết kiệm', 'en': 'Savings'},
  };

  String tenTheoNgonNgu(String key) {
    return isVN ? tenDanhMuc[key]!['vn']! : tenDanhMuc[key]!['en']!;
  }

  double tongTiLe() {
    return keHoach.fold(0, (sum, item) => sum + item['tiLe']);
  }

  double tinhPhanTram(Map item) {
    final tong = tongTiLe();
    if (tong == 0) return 0;
    return item['tiLe'] / tong * 100;
  }

  void updateTiLeKhoan(Map<String, dynamic> changedItem, double newValue) {
    if (changedItem['locked']) return;

    setState(() {
      double tongKhoa = 0;
      for (var item in keHoach) {
        if (item['locked'] && item != changedItem) {
          tongKhoa += item['tiLe'];
        }
      }

      List<Map<String, dynamic>> coTheThayDoi =
          keHoach.where((item) =>
              item != changedItem && item['locked'] == false).toList();

      if (coTheThayDoi.isEmpty) {
        changedItem['tiLe'] = 100 - tongKhoa;
      } else {

        double maxAllowed = 100 - tongKhoa;
        if (newValue > maxAllowed) newValue = maxAllowed;

        changedItem['tiLe'] = newValue;

        double phanConLai = 100 - tongKhoa - newValue;

        double tongCu = 0;
        for (var item in coTheThayDoi) {
          tongCu += item['tiLe'];
        }

        for (var item in coTheThayDoi) {
          if (tongCu == 0) {
            item['tiLe'] = phanConLai / coTheThayDoi.length;
          } else {
            item['tiLe'] = (item['tiLe'] / tongCu) * phanConLai;
          }
        }
      }
      for (var item in keHoach) {
        item['tien'] = (tongTien * item['tiLe'] / 100).round();
      }
    });
  }

  void lapKeHoach() {
    setState(() {
      tongTien = int.tryParse(tienController.text.replaceAll('.', '')) ?? 0;
      soNgay = int.tryParse(ngayController.text) ?? 1;

      keHoach = [
        {
          'key': 'meals',
          'tiLe': 40,
          'tien': (tongTien * 0.4).toInt(),
          'icon': Icons.restaurant,
          'locked': false,
        },
        {
          'key': 'transport',
          'tiLe': 20,
          'tien': (tongTien * 0.2).toInt(),
          'icon': Icons.directions_bike,
          'locked': false,
        },
        {
          'key': 'learning',
          'tiLe': 15,
          'tien': (tongTien * 0.15).toInt(),
          'icon': Icons.school,
          'locked': false,
        },
        {
          'key': 'games',
          'tiLe': 10,
          'tien': (tongTien * 0.1).toInt(),
          'icon': Icons.sports_esports,
          'locked': false,
        },
        {
          'key': 'savings',
          'tiLe': 15,
          'tien': (tongTien * 0.15).toInt(),
          'icon': Icons.savings,
          'locked': false,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Kế hoạch chi tiêu', 'Expense Planner')),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              setState(() {
                isVN = !isVN;
              });
            },
          ),
        ],
      ),

      body: IndexedStack(
        index: currentIndex,
        children: [danhSachView(), pieChartView(), aboutMeView()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: t('Danh sách', 'List'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.pie_chart),
            label: t('Biểu đồ', 'Chart'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info),
            label: t('về tôi', 'About Me'),
          ),
        ],
      ),
    );
  }

  /// ================= TAB 1: DANH SÁCH =================
  Widget danhSachView() {
    int tienMoiNgay = soNgay > 0 ? tongTien ~/ soNgay : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: tienController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              Nhapgiatri(),
            ],
            decoration: InputDecoration(
              labelText: t('Tổng tiền (VNĐ)', 'Total (VND)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ngayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t('Số ngày', 'days'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: lapKeHoach,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
            child: Text(t('Lập kế hoạch', 'Create Plan')),
          ),

          const SizedBox(height: 20),

          if (keHoach.isNotEmpty)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    thongTin(
                      t('Tổng tiền', 'Total'),
                      '${formatTien(tongTien)} đ',
                    ),
                    thongTin(t('Số ngày', 'days'), '$soNgay'),
                    thongTin(
                      t('Mỗi ngày', 'Per day'),
                      '${formatTien(tienMoiNgay)} đ',
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          if (keHoach.isNotEmpty) ...[
            Text(
              t('📅 Hạn mức theo ngày', '📅 Daily limit'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 8),

          ...keHoach.map((item) {
            int tienNgay = soNgay > 0 ? item['tien'] ~/ soNgay : 0;

            return Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: Icon(item['icon'], color: Colors.blue),
                title: Text(tenTheoNgonNgu(item['key'])),
                trailing: Text(
                  '${formatTien(tienNgay)} đ',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          if (keHoach.isNotEmpty) ...[
            Text(
              t('📋 Định mức theo hạng mục', '📋 Standard rates by category'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 8),

          ...keHoach.map((item) {
            return Card(
              child: ListTile(
                leading: Icon(item['icon'], color: Colors.green),
                title: Text(tenTheoNgonNgu(item['key'])),
                trailing: Text(
                  '${formatTien(item['tien'])} đ',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ================= TAB 2: BIỂU ĐỒ =================
  Widget pieChartView() {
    if (keHoach.isEmpty) {
      return Center(
        child: Text(
          t('Chưa có dữ liệu để hiển thị biểu đồ', 'No data to display chart'),
        ),
      );
    }

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Biểu đồ phân bổ chi tiêu', 'Expense Allocation Chart'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          /// ===== BIỂU ĐỒ + CHÚ THÍCH =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                width: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: List.generate(keHoach.length, (i) {
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: keHoach[i]['tiLe'].toDouble(),
                        title: '${keHoach[i]['tiLe'].toStringAsFixed(0)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              /// CHÚ THÍCH
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(keHoach.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: colors[i % colors.length],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${tenTheoNgonNgu(keHoach[i]['key'])} (${formatTien(keHoach[i]['tien'])} đ)',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// ===== Chỉnh tỷ lệ =====
          Text(
            t('Điều chỉnh tỷ lệ chi tiêu', 'Adjust expense ratio'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: keHoach.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tenTheoNgonNgu(item['key'])} – ${item['tiLe'].toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          item['locked']
                              ? Icons.lock
                              : Icons.lock_open,
                          color: item['locked']
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            item['locked'] = !item['locked'];
                          });
                        },
                      ),
                    ],
                  ),
                  Slider(
                    min: 0,
                    max: 100,
                    divisions: 100,
                    value: item['tiLe'].clamp(0, 100).toDouble(),
                    onChanged: item['locked'] || 
                      keHoach.where((e) => e['locked'] == false).length == 1
                        ? null
                        : (double value) {
                            updateTiLeKhoan(item, value);
                          },
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// ================= TAB 3: VỀ TÔI =================
  Widget aboutMeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('imgs/logo-1-2024-11-23.png'),
            ),
            SizedBox(height: 16),
            Text(
              t(
                'Trường Công nghệ Thông Tin Phenikaa',
                'University of Information Technology Phenikaa',
              ),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              t(
                'Họ và Tên: Phạm Ngọc Đức - 23010074\nNhóm: 26\nGiảng viên hướng dẫn: Nguyễn Xuân Quế\nLớp: Lập trình cho thiết bị di động-1-2-25(N02)',
                'Full Name: Phạm Ngọc Đức - 23010074\nGroup: 26\nInstructor: Nguyễn Xuân Quế\nClass: Lập trình cho thiết bị di động-1-2-25(N02)',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget thongTin(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

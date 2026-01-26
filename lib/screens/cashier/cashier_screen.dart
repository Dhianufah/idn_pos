import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:idn_pos/models/product.dart';
import 'package:idn_pos/screens/cashier/components/checkout_panel.dart';
import 'package:idn_pos/screens/cashier/components/printer_selector.dart';
import 'package:idn_pos/screens/cashier/components/product_card.dart';
import 'package:idn_pos/screens/cashier/components/qr_result_modal.dart';
import 'package:idn_pos/utils/currency_format.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _initBluetooth();   
  }

  // logic inisialisasi bluetooth
  Future<void> _initBluetooth() async {
    // meminta izin lokasi dan bluetooth (wajib)
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    List<BluetoothDevice> devices = [
    // List ini akan otomatis terisi jika Bluetooth aktif dan ada device yang terhubung
    ];
    try {
      // Apakah bluetooth aktif?
      devices = await bluetooth.getBondedDevices(); // mendapatkan list device yang terhubung
    } catch (e) {
      debugPrint("Error Bluetothooth: $e");
    }
    if (mounted) {
      setState(() {
        _devices = devices; // simpan list device ke variabel _devices
      });
    }
    bluetooth.onStateChanged().listen((state) {
      // cek status koneksi
      if (mounted) {
        setState(() {
          _connected = state == BlueThermalPrinter.CONNECTED;
        });
      }
    });
  }

  // logic yang memikirkan, "abis connect mau ngapain?"
    void _connectToDevice(BluetoothDevice? device) {
    // nested if mirip sama widget tree (secara konsep)
    if (device != null) {
      // cek apakah device sudah terhubung
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == false) { 
          // jika tidak terhubung, tampilkan pesan error
          bluetooth.connect(device).catchError((error) {
            if (mounted) setState(() => _connected = false); // ini anak (karena nurut sama mama)
          });
          // simpan device yang terhubung
          // if ini adalah opsi terakhir
          // nilai true jika berhasil konek
        if (mounted) setState(() => _selectedDevice = device); 
        }
      });
    }
  }

  // logic untuk menambahkan produk ke keranjang (logika card)
  void _addToCart(Product product) {
    setState(() {
      _cart.update(product, 
      // jika produk sudah ada di keranjang, dan user klik + jumlahnya ditambah 1
      (value) => value + 1, 
      // jika belum ada perubahan (tambah/kurang), produk otomatis terisi dengan jumlah 1
      ifAbsent: () => 1);
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product) && _cart[product] ! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
    });
  }

  int _calculateTotal() {
    int total = 0;
    _cart.forEach((key, value) => total += (key.price * value));
    return total;
  }

  // logika printing
  void _handlePrint() async {
    int total = _calculateTotal();
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Keranjang masih kosong!")));
    }

    String trxId = "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    // ini tuh kode buat qr angka yang akan di hasilkan di struk pembelian nya
    String qrData = "PAY:$trxId:$total";
    bool isPrinting = false;

    // menyiapkan tanggal saat ini (current date)
    DateTime now = DateTime.now();
    // buat formating nya contoh :dd, my
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);

    // layouting struk
    if (_selectedDevice != null && await bluetooth.isConnected == true) {
      // header struk
      bluetooth.printNewLine();
      bluetooth.printCustom("IDN CAFE", 3, 1); // judul besar (center)
      bluetooth.printNewLine();
      bluetooth.printCustom("Jl. Bagus Dayeuh", 1, 1);

      // tanggal serta  id
      bluetooth.printNewLine();
      bluetooth.printLeftRight("Waktu:", formattedDate, 1);

      // daftar items
      bluetooth.printCustom("--------------------------------", 1, 1);
      _cart.forEach((product, qty){
        String priceTotal = formatRupiah(
          product.price * qty
        );
        // cetak nama barang di kali quantity
        bluetooth.printLeftRight("${product.name} x${qty}", priceTotal, 1);
      });
       bluetooth.printCustom("--------------------------------", 1, 1);

      //  total dan QR
      bluetooth.printLeftRight("TOTAL", formatRupiah(total), 3);
      bluetooth.printNewLine();
      bluetooth.printCustom("Scan QR Di Bawah:", 1, 1);
      bluetooth.printQRcode(qrData, 200, 200, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank You", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      isPrinting = true;
    }
    _showQRModal(qrData, total, isPrinting);
  }

  void _showQRModal(String qrData, int total, bool isPrinting){
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrResultModal(
        qrData: qrData, 
        total: total, 
        isPrinting: isPrinting, 
        onClose: ()=> Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Menu Kasir",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        centerTitle: true,
        // biar di tengah 
      ),
      // ini code buat isi menunya sama printernya (1 body)
      body: Column(
        children: [
          // DROPDOWN SELECT PRINTER
          PrinterSelector(
            devices: _devices, 
            selectedDevice: _selectedDevice,
            isConnected: _connected,
            onSelected: _connectToDevice,
          ),

          // Grid for product list
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 16
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 15,
                mainAxisExtent: 15,
                // spasi anatar grid asli 
                // cross = horizontal
              ),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final product = menus [index];
                final qty = _cart[product] ?? 0;

                // pembanggilan product list pada product card
                return ProductCard(
                  product: product, 
                  qty: qty, 
                  onAdd: () => _addToCart(product), 
                  onRemove: () => _removeFromCart(product),
                );
              },
            )
          ),

          // Bottom sheet panel
          CheckoutPanel(
            total: _calculateTotal(),
            onPressed: _handlePrint,
          )
        ],
      ),
    );
  }
}
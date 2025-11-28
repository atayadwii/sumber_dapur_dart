# 🔄 REVISI SISTEM PEMROSESAN PESANAN

## Flow Baru yang Telah Diimplementasikan

### 1. Checkout → Upload Bukti Pembayaran (Batas 1 Jam)
```
Pembeli checkout keranjang
         ↓
Status: menunggu_pembayaran
         ↓
Pembeli upload bukti pembayaran (batas 1 jam)
         ↓
Jika > 1 jam → Status: kadaluarsa (pesanan hangus)
Jika upload → Status: menunggu_konfirmasi
```

### 2. Penjual Validasi Pembayaran
```
Pesanan masuk ke penjual (dengan bukti pembayaran)
         ↓
Penjual lihat bukti pembayaran
         ↓
Penjual Terima → Status: proses
Penjual Tolak → Status: batal
```

### 3. Penyelesaian Pesanan dengan Rating & Review
```
Pesanan status: proses/dikirim
         ↓
Pembeli klik "Selesaikan Pesanan"
         ↓
Upload foto barang + rating + review
         ↓
Status: selesai
```

---

## ✅ Yang Sudah Diimplementasikan

### 1. **Update OrderStatus Enum**
```dart
enum OrderStatus {
  menunggu_pembayaran,  // Baru checkout, belum bayar
  menunggu_konfirmasi,  // Sudah upload bukti, tunggu penjual
  proses,               // Penjual terima, pesanan diproses
  dikirim,              // Pesanan dikirim
  selesai,              // Pesanan selesai dengan review
  batal,                // Dibatalkan
  kadaluarsa,           // Melebihi 1 jam
}
```

### 2. **Update Order Model**
Field baru:
- `String? buktiPembayaran` - Path foto bukti pembayaran dari pembeli
- `DateTime? paymentDeadline` - Batas waktu 1 jam dari checkout
- `bool isPaid` - Status pembayaran sudah dikonfirmasi penjual
- `double? rating` - Rating 1-5
- `String? review` - Review text
- `List<String>? reviewImages` - Foto barang yang diterima

Helper methods:
- `bool get isExpired` - Check apakah sudah melebihi 1 jam
- `Duration? get remainingTime` - Sisa waktu pembayaran

### 3. **PaymentScreen** (Baru)
File: `lib/screens/payment_screen.dart`

Features:
- ✅ Countdown timer 1 jam dengan animasi
- ✅ Upload bukti pembayaran (camera/gallery)
- ✅ Auto-redirect jika waktu habis
- ✅ Detail pesanan dan petunjuk pembayaran

### 4. **OrderService Methods** (Baru)
```dart
// Upload bukti pembayaran
Future<void> uploadPaymentProof(String orderId, XFile imageFile)

// Konfirmasi pembayaran oleh penjual (terima/tolak)
Future<void> confirmPayment(String orderId, bool isAccepted)

// Submit rating & review dengan foto
Future<void> submitReview(
  String orderId, 
  double rating, 
  String review, 
  List<XFile> images,
)

// Check expired orders dan update status
Future<void> checkExpiredOrders()
```

---

## 🔨 Yang Masih Perlu Dikerjakan

### 1. **Update CartScreen**
File: `lib/screens/cart_screen.dart`

Setelah checkout berhasil:
```dart
// SEBELUM:
await orderService.createOrder(...);
Navigator.pop(context);

// SESUDAH:
final order = await orderService.createOrder(...);
// Set payment deadline (1 jam dari sekarang)
order.paymentDeadline = DateTime.now().add(Duration(hours: 1));

// Navigate ke PaymentScreen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => PaymentScreen(order: order),
));
```

### 2. **Update OrderProcessingScreen**
File: `lib/screens/order_processing_screen.dart`

Perubahan:
- Filter pesanan: `order.isMenungguKonfirmasi` (bukan isPending)
- Tampilkan foto bukti pembayaran dari pembeli
- Tombol "Terima" dan "Tolak" pembayaran
- Tampilkan detail pembeli dan total pembayaran

```dart
// Di ListView orders
children: [
  // Tampilkan foto bukti pembayaran
  if (order.buktiPembayaran != null)
    Image.network(order.buktiPembayaran!, height: 150),
  
  // Tombol Terima/Tolak
  Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text('Terima'),
          onPressed: () => _confirmPayment(order.id, true),
        ),
      ),
      SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          icon: Icon(Icons.close),
          label: Text('Tolak'),
          onPressed: () => _confirmPayment(order.id, false),
        ),
      ),
    ],
  ),
]

Future<void> _confirmPayment(String orderId, bool isAccepted) async {
  await orderService.confirmPayment(orderId, isAccepted);
  // Show snackbar
}
```

### 3. **Buat CompleteOrderScreen**
File: `lib/screens/complete_order_screen.dart`

Features yang perlu:
- Upload foto barang yang diterima (multiple images)
- Rating bintang 1-5
- Form review/testimonial
- Submit ke backend

Template:
```dart
class CompleteOrderScreen extends StatefulWidget {
  final Order order;
  
  @override
  _CompleteOrderScreenState createState() => _CompleteOrderScreenState();
}

class _CompleteOrderScreenState extends State<CompleteOrderScreen> {
  double _rating = 5.0;
  final _reviewController = TextEditingController();
  List<XFile> _productImages = [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Selesaikan Pesanan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Rating stars
            RatingBar.builder(
              initialRating: 5,
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            
            // Review text field
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Review Produk',
                hintText: 'Bagaimana pengalaman Anda?',
              ),
              maxLines: 4,
            ),
            
            // Upload foto barang
            // Multiple image picker
            GridView.builder(...),
            
            // Submit button
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Selesaikan Pesanan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitReview() async {
    await orderService.submitReview(
      widget.order.id,
      _rating,
      _reviewController.text,
      _productImages,
    );
  }
}
```

### 4. **Update HomeScreen**
File: `lib/screens/home_screen.dart`

Di tab "Pesanan":
```dart
// Tampilkan tombol berbeda berdasarkan status

if (order.isMenungguPembayaran && !order.isExpired) {
  // Tampilkan countdown timer + tombol "Upload Bukti"
  ElevatedButton(
    child: Text('Upload Bukti Pembayaran (${order.remainingTime})'),
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => PaymentScreen(order: order),
      ));
    },
  );
}

if (order.isMenungguPembayaran && order.isExpired) {
  // Tampilkan "Pesanan Kadaluarsa"
  Chip(
    label: Text('Kadaluarsa'),
    backgroundColor: Colors.red,
  );
}

if (order.isMenungguKonfirmasi) {
  // Tampilkan "Menunggu konfirmasi penjual"
  Chip(
    label: Text('Menunggu Konfirmasi'),
    backgroundColor: Colors.orange,
  );
}

if (order.isProses || order.isDikirim) {
  // Tombol "Selesaikan Pesanan"
  ElevatedButton(
    child: Text('Selesaikan Pesanan'),
    onPressed: () {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => CompleteOrderScreen(order: order),
      ));
    },
  );
}

if (order.isSelesai) {
  // Tampilkan rating & review yang sudah diberikan
  Row(
    children: [
      RatingBarIndicator(rating: order.rating ?? 0),
      Text(order.review ?? ''),
    ],
  );
}
```

### 5. **Update ProducerScreen**
File: `lib/screens/producer_screen.dart`

Dashboard statistik:
```dart
// Update filter pesanan
final pendingPaymentOrders = orders.where(
  (o) => o.status == 'menunggu_konfirmasi'
).length;

// Update _getStatusColor untuk status baru
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'menunggu_pembayaran':
      return Colors.orange;
    case 'menunggu_konfirmasi':
      return Colors.blue;
    case 'proses':
      return Colors.cyan;
    case 'dikirim':
      return Colors.purple;
    case 'selesai':
      return Colors.green;
    case 'batal':
      return Colors.red;
    case 'kadaluarsa':
      return Colors.grey;
    default:
      return Colors.grey;
  }
}
```

### 6. **Background Job untuk Check Expired Orders**
Di `main.dart`:
```dart
void main() {
  runApp(MyApp());
  
  // Run background timer untuk check expired orders setiap 1 menit
  Timer.periodic(Duration(minutes: 1), (timer) {
    // Get OrderService instance
    // orderService.checkExpiredOrders();
  });
}
```

---

## 📡 Backend API yang Dibutuhkan

### 1. **Upload Bukti Pembayaran**
```
POST /api/pesanan/{id}/upload-bukti-pembayaran
Content-Type: multipart/form-data

Form Data:
- bukti_pembayaran: [file gambar]

Response:
{
  "message": "Bukti pembayaran berhasil diupload",
  "data": {
    "id": 1,
    "status": "menunggu_konfirmasi",
    "bukti_pembayaran": "path/to/image.jpg",
    "payment_deadline": "2025-11-28T12:00:00Z"
  }
}
```

### 2. **Konfirmasi Pembayaran (Penjual)**
```
POST /api/pesanan/{id}/konfirmasi-pembayaran
Content-Type: application/json

Body:
{
  "is_accepted": true  // atau false untuk tolak
}

Response:
{
  "message": "Pembayaran diterima",
  "data": {
    "id": 1,
    "status": "proses",  // atau "batal" jika ditolak
    "is_paid": true
  }
}
```

### 3. **Submit Review dengan Foto**
```
POST /api/pesanan/{id}/review
Content-Type: multipart/form-data

Form Data:
- rating: 5
- review: "Produk bagus sekali!"
- images[0]: [file gambar 1]
- images[1]: [file gambar 2]
- images[2]: [file gambar 3]

Response:
{
  "message": "Review berhasil disimpan",
  "data": {
    "id": 1,
    "status": "selesai",
    "rating": 5.0,
    "review": "Produk bagus sekali!",
    "review_images": ["path1.jpg", "path2.jpg", "path3.jpg"]
  }
}
```

### 4. **Check Expired Orders (Cron Job)**
```
POST /api/pesanan/check-expired
Authorization: Bearer {admin_token}

Response:
{
  "message": "5 pesanan telah kadaluarsa",
  "expired_orders": [1, 2, 3, 4, 5]
}
```

---

## 🗄️ Database Migration (Laravel)

```php
// Migration: add_payment_fields_to_pesanans_table
Schema::table('pesanans', function (Blueprint $table) {
    $table->string('bukti_pembayaran')->nullable()->after('status');
    $table->timestamp('payment_deadline')->nullable()->after('bukti_pembayaran');
    $table->boolean('is_paid')->default(false)->after('payment_deadline');
    
    $table->decimal('rating', 3, 2)->nullable()->after('is_paid');
    $table->text('review')->nullable()->after('rating');
    $table->json('review_images')->nullable()->after('review');
});
```

---

## 📝 Checklist Implementasi

### Flutter:
- [x] Update OrderStatus enum
- [x] Update Order model dengan field baru
- [x] Buat PaymentScreen dengan countdown timer
- [x] Update OrderService dengan method baru
- [ ] Update CartScreen untuk navigate ke PaymentScreen
- [ ] Update OrderProcessingScreen untuk terima/tolak pembayaran
- [ ] Buat CompleteOrderScreen untuk rating & review
- [ ] Update HomeScreen dengan kondisi status baru
- [ ] Update ProducerScreen dengan status color baru
- [ ] Implementasi background job check expired orders

### Backend (Laravel):
- [ ] Migration: tambah kolom bukti_pembayaran, payment_deadline, is_paid, rating, review, review_images
- [ ] Endpoint: Upload bukti pembayaran
- [ ] Endpoint: Konfirmasi pembayaran (terima/tolak)
- [ ] Endpoint: Submit review dengan multiple images
- [ ] Cron job: Check expired orders setiap menit
- [ ] Update PesananController dengan validasi baru
- [ ] Update authorization checks untuk setiap endpoint

---

## 🎯 Priority Implementation Order

1. **HIGH**: Complete CartScreen update (navigate ke PaymentScreen)
2. **HIGH**: Update OrderProcessingScreen (terima/tolak pembayaran)
3. **HIGH**: Backend endpoints untuk pembayaran
4. **MEDIUM**: Buat CompleteOrderScreen
5. **MEDIUM**: Update HomeScreen conditional rendering
6. **LOW**: Background job check expired orders
7. **LOW**: Update ProducerScreen styling

---

## ⚠️ Important Notes

1. **Timer 1 Jam**: Hitung dari `created_at` pesanan, bukan dari buka PaymentScreen
2. **Auto-Expire**: Perlu background job atau cron untuk auto-update status kadaluarsa
3. **Multiple Images**: Review bisa upload sampai 3-5 foto barang
4. **Notification**: Ideal ada push notification saat penjual terima/tolak pembayaran
5. **Rating System**: Pertimbangkan apakah rating per produk atau per pesanan

---

File dokumentasi ini berisi roadmap lengkap untuk implementasi sistem pembayaran baru. Prioritaskan yang HIGH terlebih dahulu! 🚀

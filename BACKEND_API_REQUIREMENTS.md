# Backend API Requirements untuk Sistem Pemrosesan Pesanan

## Status Pesanan yang Valid

Backend harus menggunakan status dengan **huruf kecil (lowercase)** sesuai konvensi:

- `pending` - Pesanan baru menunggu konfirmasi penjual
- `proses` - Pesanan sedang diproses oleh penjual  
- `dikirim` - Pesanan sedang dalam pengiriman
- `selesai` - Pesanan telah selesai/completed
- `batal` - Pesanan dibatalkan

## Endpoint yang Dibutuhkan

### 1. Update Status Pesanan (untuk Penjual)

**Endpoint:** `PUT /api/pesanan/{id}/status`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Request Body:**
```json
{
  "status": "proses"
}
```

**Validasi:**
- Status harus salah satu dari: `pending`, `proses`, `dikirim`, `selesai`, `batal`
- User harus penjual dari produk dalam pesanan (cek via `detail_pesanan` → `produk` → `user_id`)

**Response Success (200):**
```json
{
  "message": "Status pesanan berhasil diupdate",
  "data": {
    "id": 1,
    "user_id": 2,
    "total_harga": "50000.00",
    "status": "proses",
    "alamat_pengiriman": "Jl. Example No. 123",
    "catatan": null,
    "bukti_penerimaan": null,
    "created_at": "2025-11-27T10:30:00.000000Z",
    "updated_at": "2025-11-27T10:35:00.000000Z"
  }
}
```

**Response Error:**
- `403 Forbidden` - Jika bukan penjual dari pesanan
- `404 Not Found` - Pesanan tidak ditemukan
- `422 Unprocessable Entity` - Validasi gagal

---

### 2. Complete Order dengan Upload Bukti (untuk Pembeli)

**Endpoint:** `POST /api/pesanan/{id}/complete`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
Accept: application/json
```

**Request Body (Form Data):**
```
bukti_penerimaan: [file gambar]
```

**Validasi:**
- File `bukti_penerimaan` required, harus image (jpeg, png, jpg, gif), max 2MB
- Status pesanan harus `proses` (tidak bisa complete jika masih pending atau sudah selesai)
- User harus pembeli pesanan (user_id = pesanan->user_id)

**Response Success (200):**
```json
{
  "message": "Pesanan berhasil diselesaikan",
  "data": {
    "id": 1,
    "user_id": 2,
    "total_harga": "50000.00",
    "status": "selesai",
    "alamat_pengiriman": "Jl. Example No. 123",
    "catatan": null,
    "bukti_penerimaan": "bukti_pesanan/1732694123_bukti.jpg",
    "created_at": "2025-11-27T10:30:00.000000Z",
    "updated_at": "2025-11-27T10:40:00.000000Z"
  }
}
```

**Response Error:**
- `400 Bad Request` - Status pesanan bukan `proses`
- `403 Forbidden` - Jika bukan pembeli dari pesanan
- `404 Not Found` - Pesanan tidak ditemukan
- `422 Unprocessable Entity` - Validasi file gagal

---

## Implementasi di Laravel

### 1. Migration untuk Menambah Kolom bukti_penerimaan

```bash
php artisan make:migration add_bukti_penerimaan_to_pesanans_table
```

```php
public function up()
{
    Schema::table('pesanans', function (Blueprint $table) {
        $table->string('bukti_penerimaan')->nullable()->after('status');
    });
}

public function down()
{
    Schema::table('pesanans', function (Blueprint $table) {
        $table->dropColumn('bukti_penerimaan');
    });
}
```

### 2. Update Model Pesanan

```php
// app/Models/Pesanan.php

protected $fillable = [
    'user_id',
    'total_harga',
    'status',
    'alamat_pengiriman',
    'catatan',
    'bukti_penerimaan'
];

// Relasi
public function pembeli()
{
    return $this->belongsTo(User::class, 'user_id');
}

public function details()
{
    return $this->hasMany(DetailPesanan::class, 'pesanan_id');
}
```

### 3. Controller Methods

```php
// app/Http/Controllers/Api/PesananController.php

public function updateStatus(Request $request, $id)
{
    $request->validate([
        'status' => 'required|in:pending,proses,dikirim,selesai,batal'
    ]);

    $pesanan = Pesanan::with('details.produk')->findOrFail($id);
    
    // Authorization: Pastikan user adalah penjual
    $isPenjual = $pesanan->details->every(function ($detail) {
        return $detail->produk->user_id == auth()->id();
    });
    
    if (!$isPenjual) {
        return response()->json([
            'message' => 'Unauthorized. Anda bukan penjual dari pesanan ini.'
        ], 403);
    }
    
    $pesanan->status = $request->status;
    $pesanan->save();
    
    return response()->json([
        'message' => 'Status pesanan berhasil diupdate',
        'data' => $pesanan
    ]);
}

public function completeOrder(Request $request, $id)
{
    $request->validate([
        'bukti_penerimaan' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048'
    ]);

    $pesanan = Pesanan::findOrFail($id);
    
    // Authorization: Pastikan user adalah pembeli
    if ($pesanan->user_id != auth()->id()) {
        return response()->json([
            'message' => 'Unauthorized. Anda bukan pembeli dari pesanan ini.'
        ], 403);
    }
    
    // Validasi status harus 'proses'
    if ($pesanan->status !== 'proses') {
        return response()->json([
            'message' => 'Pesanan hanya bisa diselesaikan jika statusnya sedang diproses.'
        ], 400);
    }
    
    // Upload file
    if ($request->hasFile('bukti_penerimaan')) {
        $file = $request->file('bukti_penerimaan');
        $filename = time() . '_' . $file->getClientOriginalName();
        $path = $file->storeAs('bukti_pesanan', $filename, 'public');
        
        $pesanan->bukti_penerimaan = $path;
    }
    
    $pesanan->status = 'selesai';
    $pesanan->save();
    
    return response()->json([
        'message' => 'Pesanan berhasil diselesaikan',
        'data' => $pesanan
    ]);
}
```

### 4. Routes

```php
// routes/api.php

Route::middleware('auth:sanctum')->group(function () {
    // Update status pesanan (untuk penjual)
    Route::put('/pesanan/{id}/status', [PesananController::class, 'updateStatus']);
    
    // Complete order dengan bukti (untuk pembeli)
    Route::post('/pesanan/{id}/complete', [PesananController::class, 'completeOrder']);
});
```

### 5. Setup Storage

Pastikan storage link sudah dibuat:

```bash
php artisan storage:link
```

Konfigurasi di `config/filesystems.php`:

```php
'public' => [
    'driver' => 'local',
    'root' => storage_path('app/public'),
    'url' => env('APP_URL').'/storage',
    'visibility' => 'public',
],
```

---

## Testing Endpoints

### Test Update Status

```bash
curl -X PUT http://localhost:8000/api/pesanan/1/status \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"status": "proses"}'
```

### Test Complete Order

```bash
curl -X POST http://localhost:8000/api/pesanan/1/complete \
  -H "Authorization: Bearer {token}" \
  -F "bukti_penerimaan=@/path/to/image.jpg"
```

---

## Catatan Penting

1. **Status harus lowercase**: `pending`, `proses`, `selesai`, `batal` (BUKAN `Pending`, `Proses`, dll.)
2. **Authorization ketat**: Penjual hanya bisa update status, Pembeli hanya bisa complete dengan bukti
3. **File upload**: Simpan di `storage/app/public/bukti_pesanan/`
4. **Error handling**: Return proper HTTP status codes dan pesan error yang jelas
5. **Validasi**: Pastikan status transition yang valid (pending → proses → selesai)

---

## Flow Sistem

```
1. Pembeli checkout → Pesanan dibuat (status: 'pending')
                              ↓
2. Penjual lihat tab Pesanan → Klik "Proses Pesanan"
                              ↓
   PUT /api/pesanan/{id}/status dengan body {"status": "proses"}
                              ↓
3. Status berubah 'proses' → Terlihat di kedua akun
                              ↓
4. Pembeli klik "Selesaikan Pesanan" → Upload foto bukti
                              ↓
   POST /api/pesanan/{id}/complete dengan file bukti_penerimaan
                              ↓
5. Status berubah 'selesai' → Terlihat di kedua akun
```

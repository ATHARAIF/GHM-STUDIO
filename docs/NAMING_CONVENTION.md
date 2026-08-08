# Standar Penamaan (Naming Convention) Godot

Dokumen ini berisi panduan dan standar penamaan untuk proyek game ini. Tujuannya adalah untuk menjaga agar kode dan aset tetap rapi, konsisten, dan mudah dipelihara saat proyek semakin membesar.

## 1. Aturan Umum (File & Direktori)
Semua file dan folder di dalam proyek Godot **harus** menggunakan format `snake_case` (huruf kecil semua, dipisahkan oleh garis bawah).
- **Benar:** `card_data.gd`, `main_scene.tscn`, `ui/`
- **Salah:** `CardData.gd`, `MainScene.tscn`, `UI/`

> **Alasan:** Format `snake_case` mencegah masalah *case-sensitivity* ketika proyek dipindahkan antar sistem operasi (Windows vs Linux/Mac).

## 2. Aturan Penamaan Node (Scene Tree) & Class
Semua nama Node di dalam Godot Editor (Scene Tree) dan nama Class di dalam script harus menggunakan format `PascalCase` (diawali huruf besar, tanpa spasi).
- **Benar:** `MainHUD`, `CardHand`, `BtnConfirm`
- **Salah:** `main_hud`, `card hand`, `btn_confirm`

## 3. Aturan Penamaan UI (Antarmuka Pengguna)
Untuk membedakan fungsi visual dari file-file antarmuka, gunakan akhiran berikut pada nama file `.tscn` (serta `.gd` pasangannya):

| Akhiran | Fungsi & Deskripsi | Contoh |
| :--- | :--- | :--- |
| **`_popup`** | Jendela interaksi/notifikasi yang muncul di tengah layar dan menutupi permainan. Bisa ditutup (Cancel/Close). | `pruning_popup.tscn`, `harvest_method_popup.tscn` |
| **`_menu`** | Layar antarmuka besar atau *full-screen* yang memblokir semua aktivitas lain. | `main_menu.tscn`, `settings_menu.tscn` |
| **`_hud` / `_panel`** | Elemen UI statis yang terus menempel di pinggir/sudut layar selama permainan berjalan. | `main_hud.tscn`, `stats_panel.tscn` |
| **`_btn`** | (Khusus Node) Penamaan elemen tombol di Scene Tree. | `BtnConfirm`, `BtnClose` |

## 4. Aturan Penamaan Logika Utama (Core Logic)
Kata `_manager` atau `_controller` hanya boleh digunakan pada script (`.gd`) yang bekerja di latar belakang sebagai "otak" pengatur logika permainan, dan **tidak memiliki wujud visual mandiri** (bukan file scene `.tscn` berwujud UI).
- **Contoh:** `stage_manager.gd`, `event_manager.gd`, `deck_controller.gd`.

## 5. Keselarasan Scene dan Script (Pairing)
Jika sebuah script mengendalikan perilaku sebuah scene secara langsung (menempel di *root node* scene tersebut), maka nama script `.gd` **wajib sama persis** dengan nama scene `.tscn`-nya.
- **Benar:** `pruning_popup.tscn` dipasangkan dengan `pruning_popup.gd`.
- **Salah:** `pruning_popup.tscn` dipasangkan dengan `pruning_controller.gd` (Akan sulit dilacak nanti).

## 6. Penulisan Kode di dalam GDScript
- **Variabel & Fungsi:** Gunakan `snake_case`. (Contoh: `current_turn`, `calculate_yield()`)
- **Fungsi Sinyal / Event:** Awali dengan garis bawah `_on_`. (Contoh: `_on_btn_confirm_pressed()`, `_on_stage_changed()`)
- **Konstanta (Constants):** Gunakan huruf kapital semua `UPPER_SNAKE_CASE`. (Contoh: `MAX_BUDGET = 5000`)
- **Variabel Private (Internal):** Jika sebuah variabel tidak boleh diakses oleh script lain, awali dengan garis bawah `_`. (Contoh: `var _internal_counter = 0`)

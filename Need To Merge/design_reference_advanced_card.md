# Game Design Document (GDD) Reference
## Advanced Card Data Architecture & Mechanics

Dokumen ini disimpan sebagai referensi untuk pengembangan sistem inti (core mechanics) di masa mendatang, setelah target fase prototipe/demo selesai.

### 1. CoffeeVarietyData (Genetika Dasar)
Varietas kopi yang ditanam berfungsi sebagai *Baseline* (angka dasar) sebelum dimodifikasi oleh kartu.

**Contoh Arabika Kintamani:**
- `base_acidity`: 8 (Sangat Tinggi)
- `base_body`: 4 (Sedang)
- `base_bitterness`: 3 (Rendah)
- `base_aroma`: 7 (Tinggi)

**Contoh Robusta Dampit:**
- `base_acidity`: 1 (Sangat Rendah)
- `base_body`: 9 (Sangat Tinggi)
- `base_bitterness`: 8 (Tinggi)
- `base_aroma`: 5 (Sedang)

### 2. Sub-Class CardData (Pewarisan)
File `card_data.gd` lama yang mencampuradukkan semua efek akan dipecah menjadi 3 sub-kelas agar rapi di Godot Inspector:

#### A. FarmCardData (Weeding, Pruning, Suckering)
Efeknya berfokus pada ekosistem kebun, bukan rasa langsung.
- `soil_health_effect`: Mengurangi keasaman tanah/memperbaiki unsur hara. (Dikonversi ke Sweetness/Body saat panen).
- `plant_health_effect`: Meningkatkan ketahanan tanaman. (Dikonversi ke Aroma/Flavor saat panen).
- `pest_reduction`: Menurunkan kemungkinan hama (mencegah Defect).
- `disease_reduction`: Menurunkan kemungkinan penyakit.
- `yield_potential_effect`: Meningkatkan batas maksimal Kg buah ceri.

#### B. HarvestCardData (Panen)
- `harvest_method`: Selective, Strip, atau Mechanical.
- `yield_efficiency`: Berapa % buah yang berhasil dipetik.
- `defect_modifier`: Kerusakan biji akibat teknik petik (menambah Bitterness).
- `ripeness_modifier`: Akurasi buah merah/matang sempurna (meningkatkan Acidity).

#### C. ProcessCardData (Dry, Ferment, Roast)
- `effect_aroma`, `effect_acidity`, `effect_body`, dll.
- Digunakan untuk mengubah *Green Beans* yang ada di gudang secara langsung.

### 3. Rumus Konversi (Dari Kebun ke Rasa)
Perhitungan dilakukan saat pemain melakukan **Harvest**.
**[Cita Rasa Biji di Gudang]** = `Varietas Dasar` + `Status Lahan (Farm Cards)` + `Efisiensi Panen (Harvest Cards)`

*Contoh Kasus:*
Pemain menanam Kintamani (Acidity 8). Selama bermain, ia merawat tanah dengan baik (Soil +1 Sweetness). Namun saat panen ia memakai mesin yang kasar (Defect +2 Bitterness).
Maka biji kopi di gudangnya akan memiliki stat:
- Acidity: 8
- Sweetness: 1
- Bitterness: 5 (karena mesin)

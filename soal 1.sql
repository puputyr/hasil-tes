-- Ganti `lucid-course-462604-a7.technical_test_data` jika project atau dataset Anda berbeda
WITH
  -- 1. Agregasi data donasi harian
  daily_donations AS (
    SELECT
      CAST(created AS DATE) AS tanggal,
      campaign_id,
      COUNT(DISTINCT id) AS jumlah_donasi,
      SUM(amount) AS total_nominal_donasi
    FROM
      `lucid-course-462604-a7.technical_test_data.donation`
    GROUP BY
      1, 2
  ),

  -- 2. Agregasi data pageviews harian, digabungkan melalui campaign.url
  daily_pageviews AS (
    SELECT
      CAST(v.date_id AS DATE) AS tanggal,
      c.id AS campaign_id,
      SUM(v.pageview) AS jumlah_pageviews
    FROM
      `lucid-course-462604-a7.technical_test_data.visit` v
    JOIN
      `lucid-course-462604-a7.technical_test_data.campaign` c ON v.campaign_url = c.url
    GROUP BY
      1, 2
  ),

  -- 3. Agregasi data pengeluaran iklan harian, digabungkan melalui campaign.url
  daily_ad_spend AS (
    SELECT
      CAST(a.date_id AS DATE) AS tanggal,
      c.id AS campaign_id,
      SUM(a.spend) AS total_pengeluaran_iklan
    FROM
      `lucid-course-462604-a7.technical_test_data.ads_spent` a
    JOIN
      `lucid-course-462604-a7.technical_test_data.campaign` c ON a.short_url = c.url
    GROUP BY
      1, 2
  ),

  -- 4. Agregasi pengguna baru harian (FOKUS PERMINTAAN ANDA)
  daily_new_users AS (
    SELECT
      -- Menghitung pengguna baru berdasarkan tanggal mereka dibuat
      CAST(created AS DATE) AS tanggal,
      COUNT(id) AS jumlah_pengguna_baru
    FROM
      `lucid-course-462604-a7.technical_test_data.user`
    GROUP BY
      1
  ),

  -- 5. Buat daftar unik semua tanggal dan campaign_id dari semua sumber data
  all_dates_and_campaigns AS (
    SELECT tanggal, campaign_id FROM daily_donations
    UNION DISTINCT
    SELECT tanggal, campaign_id FROM daily_pageviews
    UNION DISTINCT
    SELECT tanggal, campaign_id FROM daily_ad_spend
  )

-- 6. Query final untuk menggabungkan semua data dan menampilkan laporan
SELECT
  ac.tanggal,
  cam.title AS nama_kampanye,
  COALESCE(don.jumlah_donasi, 0) AS jumlah_donasi,
  COALESCE(ads.total_pengeluaran_iklan, 0) AS pengeluaran_iklan,
  COALESCE(don.total_nominal_donasi, 0) AS total_donasi,
  COALESCE(pv.jumlah_pageviews, 0) AS pageview,
  -- Ini adalah kolom yang Anda butuhkan
  COALESCE(usr.jumlah_pengguna_baru, 0) AS total_pengguna_baru,

  -- Metrik kalkulasi:
  SAFE_DIVIDE(don.jumlah_donasi, pv.jumlah_pageviews) * 100 AS persentase_tingkat_konversi,
  SAFE_DIVIDE(ads.total_pengeluaran_iklan, don.total_nominal_donasi) * 100 AS persentase_pengeluaran_per_total_donasi,
  SAFE_DIVIDE(ads.total_pengeluaran_iklan, don.jumlah_donasi) AS biaya_per_donasi

FROM
  all_dates_and_campaigns ac
LEFT JOIN
  daily_donations don ON ac.tanggal = don.tanggal AND ac.campaign_id = don.campaign_id
LEFT JOIN
  daily_pageviews pv ON ac.tanggal = pv.tanggal AND ac.campaign_id = pv.campaign_id
LEFT JOIN
  daily_ad_spend ads ON ac.tanggal = ads.tanggal AND ac.campaign_id = ads.campaign_id
-- Menggabungkan data pengguna baru berdasarkan tanggal
LEFT JOIN
  daily_new_users usr ON ac.tanggal = usr.tanggal
LEFT JOIN
  `lucid-course-462604-a7.technical_test_data.campaign` cam ON ac.campaign_id = cam.id
ORDER BY
  ac.tanggal DESC,
  nama_kampanye;

-- CEK PENGUNA BARU BERDASARKAN KINERJA IKLAN
--   -- Ganti `lucid-course-462604-a7.technical_test_data` jika project atau dataset Anda berbeda
-- WITH
--   -- Langkah 1: Hitung total pengguna baru yang mendaftar setiap hari
--   daily_new_users AS (
--     SELECT
--       CAST(created AS DATE) AS tanggal,
--       COUNT(id) AS jumlah_pengguna_baru
--     FROM
--       `lucid-course-462604-a7.technical_test_data.user`
--     GROUP BY
--       1
--   ),

--   -- Langkah 2: Agregasi aktivitas (pageviews) setiap kampanye per hari
--   daily_campaign_activity AS (
--     SELECT
--       CAST(v.date_id AS DATE) AS tanggal,
--       c.title AS nama_kampanye,
--       SUM(v.pageview) AS jumlah_pageviews
--     FROM
--       `lucid-course-462604-a7.technical_test_data.visit` v
--     JOIN
--       `lucid-course-462604-a7.technical_test_data.campaign` c ON v.campaign_url = c.url
--     GROUP BY
--       1, 2
--   )

-- -- Langkah 3: Gabungkan data pengguna baru dengan data aktivitas kampanye berdasarkan tanggal
-- SELECT
--   act.tanggal,
--   usr.jumlah_pengguna_baru,
--   act.nama_kampanye,
--   act.jumlah_pageviews
-- FROM
--   daily_campaign_activity act
-- JOIN
--   daily_new_users usr ON act.tanggal = usr.tanggal
-- -- Filter untuk hanya menampilkan kampanye yang memiliki aktivitas
-- WHERE
--   act.jumlah_pageviews > 0
-- ORDER BY
--   act.tanggal DESC,
--   act.jumlah_pageviews DESC;
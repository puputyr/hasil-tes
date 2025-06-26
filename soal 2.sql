-- Kueri ini dirancang untuk membantu Agen Kebahagiaan (Happiness Agents) dengan menganalisis
-- bendera kampanye dan riwayat keluhan dari pembuat kampanye.
-- Ganti `lucid-course-462604-a7.technical_test_data` jika project atau dataset Anda berbeda.

WITH
  -- Langkah 1: Agregasi total jumlah donasi untuk setiap kampanye.
  campaign_donations AS (
    SELECT
      campaign_id,
      SUM(amount) AS total_donation_amount
    FROM
      `lucid-course-462604-a7.technical_test_data.donation`
    GROUP BY
      campaign_id
  ),

  -- Langkah 2: Agregasi data keluhan (tiket) untuk setiap pengguna.
  -- Ini akan menghitung jumlah total keluhan dan persentase tiket prioritas tinggi.
  user_complaints AS (
    SELECT
      user_id,
      COUNT(id) AS no_of_complain,
      -- Menghitung persentase tiket dengan prioritas 'high'.
      -- SAFE_DIVIDE digunakan untuk menghindari error pembagian dengan nol.
      SAFE_DIVIDE(
        COUNTIF(priority = 'high'), -- Asumsi nilai untuk prioritas tinggi adalah 'high'
        COUNT(id)
      ) * 100 AS percentage_of_high_priority_ticket
    FROM
      `lucid-course-462604-a7.technical_test_data.ticket`
    GROUP BY
      user_id
  )

-- Langkah 3: Gabungkan semua data menjadi laporan akhir.
-- Kita mulai dari tabel `campaign` sebagai dasar, lalu menggabungkan data lainnya.
SELECT
  c.id AS campaign_id,
  c.title AS campaign_name,
  COALESCE(cd.total_donation_amount, 0) AS total_donation_amount,
  -- PERBAIKAN: Menggunakan nama kolom 'flag' yang benar dari tabel campaign_flag.
  cf.flag AS campaign_flag,
  -- Membuat kolom boolean untuk menandakan apakah pembuat kampanye pernah membuat keluhan.
  CASE
    WHEN uc.no_of_complain > 0 THEN TRUE
    ELSE FALSE
  END AS is_complain,
  -- Menampilkan jumlah keluhan, atau 0 jika tidak ada.
  COALESCE(uc.no_of_complain, 0) AS no_of_complain,
  COALESCE(uc.percentage_of_high_priority_ticket, 0) AS percentage_of_high_priority_ticket
FROM
  `lucid-course-462604-a7.technical_test_data.campaign` c
-- Gabungkan dengan data donasi kampanye.
LEFT JOIN
  campaign_donations cd ON c.id = cd.campaign_id
-- Gabungkan dengan data bendera kampanye.
LEFT JOIN
  `lucid-course-462604-a7.technical_test_data.campaign_flag` cf ON c.id = cf.campaign_id
-- Gabungkan dengan data keluhan PENGGUNA (pembuat kampanye).
LEFT JOIN
  user_complaints uc ON c.user_id = uc.user_id
ORDER BY
  c.id;


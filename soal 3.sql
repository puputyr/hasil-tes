-- Kueri ini dirancang untuk menjadi sumber data utama bagi dasbor kesehatan perusahaan di Looker Studio.
-- Kueri ini menghitung semua metrik utama secara harian.
-- Ganti `lucid-course-462604-a7.technical_test_data` jika project atau dataset Anda berbeda.

WITH
  -- Menghitung donasi pertama untuk setiap pengguna untuk mengidentifikasi donatur pertama kali.
  first_time_donations AS (
    SELECT
      user_id,
      CAST(created AS DATE) AS first_donation_date,
      -- Memberi peringkat donasi setiap pengguna berdasarkan tanggal untuk menemukan yang pertama.
      ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY created ASC) as donation_rank
    FROM
      `lucid-course-462604-a7.technical_test_data.donation`
  ),

  -- Menghitung jumlah donatur pertama kali per hari.
  daily_first_time_donors AS (
    SELECT
      first_donation_date,
      COUNT(DISTINCT user_id) AS total_first_time_donors
    FROM
      first_time_donations
    WHERE
      donation_rank = 1
    GROUP BY
      1
  ),

  -- Menghitung total nilai donasi (GDV), jumlah donasi, dan pengguna unik yang berdonasi per hari.
  daily_donation_metrics AS (
    SELECT
      CAST(created AS DATE) AS tanggal,
      SUM(amount) AS total_gdv,
      COUNT(id) AS total_donations,
      COUNT(DISTINCT user_id) AS total_donating_users
    FROM
      `lucid-course-462604-a7.technical_test_data.donation`
    GROUP BY
      1
  ),

  -- Menghitung total pengguna baru per hari.
  daily_new_users AS (
    SELECT
      CAST(created AS DATE) AS tanggal,
      COUNT(id) AS total_new_users
    FROM
      `lucid-course-462604-a7.technical_test_data.user`
    GROUP BY
      1
  ),

  -- Menghitung total kampanye baru yang diluncurkan per hari.
  daily_campaigns_launched AS (
    SELECT
      CAST(created AS DATE) AS tanggal,
      COUNT(id) AS total_campaigns_launched
    FROM
      `lucid-course-462604-a7.technical_test_data.campaign`
    GROUP BY
      1
  ),
  
  -- Membuat daftar induk semua tanggal unik dari semua sumber data untuk memastikan tidak ada hari yang terlewat.
  all_dates AS (
    SELECT tanggal FROM daily_donation_metrics
    UNION DISTINCT
    SELECT tanggal FROM daily_new_users
    UNION DISTINCT
    SELECT tanggal FROM daily_campaigns_launched
    UNION DISTINCT
    SELECT first_donation_date AS tanggal FROM daily_first_time_donors
  )

-- Rakit laporan akhir dengan menggabungkan semua metrik harian.
SELECT
  d.tanggal,
  COALESCE(ddm.total_gdv, 0) AS total_gdv,
  COALESCE(ddm.total_donations, 0) AS total_donations,
  COALESCE(ddm.total_donating_users, 0) AS total_donating_users,
  COALESCE(dnu.total_new_users, 0) AS total_new_users,
  COALESCE(dcl.total_campaigns_launched, 0) AS total_campaigns_launched,
  COALESCE(dftd.total_first_time_donors, 0) AS total_first_time_donors
FROM
  all_dates d
LEFT JOIN
  daily_donation_metrics ddm ON d.tanggal = ddm.tanggal
LEFT JOIN
  daily_new_users dnu ON d.tanggal = dnu.tanggal
LEFT JOIN
  daily_campaigns_launched dcl ON d.tanggal = dcl.tanggal
LEFT JOIN
  daily_first_time_donors dftd ON d.tanggal = dftd.first_donation_date
ORDER BY
  d.tanggal DESC;

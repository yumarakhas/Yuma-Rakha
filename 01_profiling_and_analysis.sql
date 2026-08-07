use db_technical_test;

-- Profiling Data
SELECT*FROM data_dictionary;

-- Branches's Table
SELECT*FROM branches;
SELECT COUNT(*) AS total_baris FROM branches;
DESCRIBE branches;

-- doctors
SELECT*FROM doctors;
SELECT COUNT(*) AS total_baris FROM doctors;
DESCRIBE doctors;
SELECT doctor_id, primary_branch_id, COUNT(*) jumlah FROM doctors GROUP BY doctor_id, primary_branch_id HAVING COUNT(*)>1;
SELECT SUM(doctor_id IS NULL) AS doctor_id_null, SUM(primary_branch_id IS NULL) AS primary_branch_id_null, SUM(is_specialist IS NULL) AS is_specialist_null, SUM(is_delete IS NULL) AS is_delete_null FROM doctors;

-- patient_transaction_sequence
DESCRIBE patient_transaction_sequence;
SELECT*FROM patient_transaction_sequence;
SELECT COUNT(*) AS total_baris FROM patient_transaction_sequence;
SELECT SUM(transaction_key IS NULL) AS transaction_key_null, SUM(lifetime_transaction_number IS NULL) AS lifetime_transaction_number_null FROM patient_transaction_sequence;
SELECT transaction_key, COUNT(*) jumlah FROM patient_transaction_sequence GROUP BY transaction_key HAVING COUNT(*)>1;

-- patients_anonymized
DESCRIBE patients_anonymized;
SELECT COUNT(*) AS total_baris FROM patients_anonymized;
SELECT SUM(patient_key IS NULL) AS patient_key_null, SUM(has_phone IS NULL) AS has_phone_null, SUM(has_email IS NULL) AS has_email_null, SUM(is_active IS NULL) AS is_active_null, SUM(is_delete IS NULL) AS is_delete_null FROM patients_anonymized;
SELECT patient_key, COUNT(*) jumlah FROM patients_anonymized GROUP BY patient_key HAVING COUNT(*)>1;

--  payment_details
DESCRIBE payment_details;
SELECT COUNT(*) AS total_baris FROM payment_details;
SELECT SUM(payment_detail_key IS NULL) AS payment_detail_key_null, SUM(transaction_date IS NULL) AS transaction_date, SUM(payment_account_legacy_id IS NULL)AS payment_account_legacy_id_null, SUM(jenis_transaksi IS NULL) AS jenis_transaksi_null, SUM(payment_amount IS NULL) AS payment_amount_null FROM payment_details;
SELECT payment_detail_key, COUNT(*) jumlah FROM payment_details GROUP BY payment_detail_key HAVING COUNT(*)>1;

-- product_details
DESCRIBE product_details; 
SELECT*FROM product_details;
SELECT COUNT(*) FROM product_details;
SELECT SUM(product_detail_key IS NULL) AS product_detail_key_null, SUM(transaction_date IS NULL) AS transaction_date_null, SUM(source_detail_id IS NULL) AS source_detail_id_null, SUM(product_legacy_id IS NULL) AS product_legacy_id_null, SUM(quantity IS NULL) AS quantity_null, SUM(unit_price IS NULL) AS unit_price_null, SUM(item_discount IS NULL) AS item_discount_null, SUM(item_total_amount IS NULL) AS item_total_amount_null, SUM(allocated_header_discount IS NULL) AS allocated_header_disconut_null, SUM(item_final_amount IS NULL) AS item_final_amount_null, SUM(jenis_transaksi IS NULL) AS jenis_transaksi_null FROM product_details;
SELECT product_detail_key, COUNT(*) jumlah FROM product_details GROUP BY product_detail_key HAVING COUNT(*)>1;

-- Relasi antar tabel
-- doctors dengan branches
SELECT doctor_id, primary_branch_id FROM doctors WHERE primary_branch_id IS NULL;
SELECT d.doctor_id, d.primary_branch_id FROM doctors d LEFT JOIN branches b ON d.primary_branch_id = b.branch_id WHERE d.primary_branch_id IS NOT NULL AND b.branch_id IS NULL;

-- Product dengan Branches
SELECT product_detail_key, branch_id FROM product_details WHERE branch_id IS NULL;
SELECT p.product_detail_key, p.branch_id FROM product_details p LEFT JOIN branches b ON p.branch_id = b.branch_id WHERE p.branch_id IS NOT NULL AND b.branch_id IS NULL;

-- Patient transaction dengan branches
SELECT transaction_key, first_transaction_branch_id FROM patient_transaction_sequence WHERE first_transaction_branch_id IS NULL;
SELECT pts.transaction_key, pts.first_transaction_branch_id FROM patient_transaction_sequence pts LEFT JOIN branches b ON pts.first_transaction_branch_id = b.branch_id WHERE pts.first_transaction_branch_id IS NOT NULL AND b.branch_id IS NULL;
-- ditemukan 100 data dengan first_transaction_branch_id yang tidak terdapat pada tabel branches
SELECT DISTINCT first_transaction_branch_id FROM patient_transaction_sequence WHERE first_transaction_branch_id NOT IN ( SELECT branch_id FROM branches );
-- terdapat data yang melakukan refrensi ke cabang 5,6,7,8 kondisi di tabel branches hanya cabang 1,2,3,4
-- Penanganan dengan melakukan filtering data pada cabang 1,2,3,4 saja

-- Patients_anonymized dengan Branches 
SELECT patient_key, registered_branch_id FROM patients_anonymized WHERE registered_branch_id IS NULL;
SELECT p.patient_key, p.registered_branch_id FROM patients_anonymized p LEFT JOIN branches b ON p.registered_branch_id = b.branch_id WHERE p.registered_branch_id IS NOT NULL AND b.branch_id IS NULL;
-- ditemukan 103 data dengan registered_branch_id yang tidak terdapat pada tabel branches
SELECT DISTINCT registered_branch_id FROM patients_anonymized WHERE registered_branch_id NOT IN ( SELECT branch_id FROM branches );
-- terdapat data yang melakukan refrensi ke cabang 5,6,7,8 kondisi di tabel branches hanya cabang 1,2,3,4
-- Penanganan dengan melakukan filtering data pada cabang 1,2,3,4 saja

-- Payment_details dengan patient_transaction_sequence
SELECT payment_detail_key, transaction_key FROM payment_details WHERE transaction_key IS NULL;
SELECT pd.payment_detail_key, pd.transaction_key FROM payment_details pd LEFT JOIN patient_transaction_sequence pts ON pd.transaction_key = pts.transaction_key WHERE pd.transaction_key IS NOT NULL AND pts.transaction_key IS NULL;
-- ditemukan 106 data dengan transaction_key yang tidak terdapat pada tabel patient_transaction_sequence
-- penangananan dengan melakukan filtering agar tidak menggunakan 106 data tersebut
SELECT DISTINCT transaction_key FROM payment_details WHERE transaction_key NOT IN ( SELECT transaction_key FROM patient_transaction_sequence );

--  Product dengan Doctors
SELECT product_detail_key, doctor_id FROM product_details WHERE doctor_id IS NULL;
-- ditemukan 109 data dengan doctor_id kosong 
-- tetap menggunakan 109 data tersebut, karena ada kemungkinan pembelian product tanpa melewaati dokter
SELECT pd.product_detail_key, pd.doctor_id FROM product_details pd LEFT JOIN doctors d ON pd.doctor_id = d.doctor_id WHERE pd.doctor_id IS NOT NULL AND d.doctor_id IS NULL;
 
-- Patient_transaction_Sequance dengan patients_anonymized
SELECT transaction_key, patient_key FROM patient_transaction_sequence WHERE patient_key IS NULL;
SELECT pts.transaction_key, pts.patient_key FROM patient_transaction_sequence pts LEFT JOIN patients_anonymized p ON pts.patient_key = p.patient_key WHERE pts.patient_key IS NOT NULL AND p.patient_key IS NULL;
-- ditemukan 112 data riwayat transaksi yang yang mencatat id pasien yang tidak ada ditabel patients_anonymized
-- dilakukan filter untuk tidak menggunakan 112 data tersebut

-- Analisis Performa
SELECT
    DATE_FORMAT(pd.transaction_date,'%Y-%m') AS periode_bulan,
    pd.branch_id,
    b.branch_name,
    SUM(pd.payment_amount) AS total_revenue,
    COUNT(DISTINCT pd.transaction_key) AS total_invoice,
    COUNT(DISTINCT pts.patient_key) AS total_pasien_unik,
    SUM(pd.payment_amount) / COUNT(DISTINCT pd.transaction_key) AS atv

FROM payment_details pd
JOIN patient_transaction_sequence pts
    ON pd.transaction_key = pts.transaction_key
JOIN branches b
    ON pd.branch_id = b.branch_id

WHERE pd.transaction_date BETWEEN '2022-10-01' AND '2022-12-31'
    AND pd.branch_id IN (1,2,3,4)

GROUP BY
    periode_bulan,
    pd.branch_id,
    b.branch_name

ORDER BY
    periode_bulan,
    pd.branch_id;

-- Analisis Customer
SELECT
    DATE_FORMAT(pay.transaction_date,'%Y-%m') AS periode_bulan,
    pay.branch_id,
    b.branch_name,

    CASE
        WHEN trx.patient_key IS NULL
             OR pat.patient_key IS NULL
            THEN 'Non Member'
        WHEN trx.lifetime_transaction_number = 1
            THEN 'New Customer'
        WHEN trx.days_from_previous_transaction >= 90
            THEN 'Reactivated Customer'
        ELSE 'Repeat Customer'
    END AS kategori_customer,

    COUNT(DISTINCT trx.patient_key) AS jumlah_customer,
    SUM(pay.payment_amount) AS total_revenue

FROM payment_details pay

JOIN patient_transaction_sequence trx
ON pay.transaction_key = trx.transaction_key

LEFT JOIN patients_anonymized pat
ON trx.patient_key = pat.patient_key

JOIN branches b
ON pay.branch_id = b.branch_id

WHERE pay.transaction_date BETWEEN '2022-10-01' AND '2022-12-31'
AND pay.branch_id IN (1,2,3,4)

GROUP BY
    periode_bulan,
    pay.branch_id,
    b.branch_name,
    kategori_customer

ORDER BY
    periode_bulan,
    pay.branch_id,
    kategori_customer;

-- Analisis Produk dan Dokter
-- Top Product
SELECT
    DATE_FORMAT(pd.transaction_date,'%Y-%m') AS periode_bulan,
    pd.branch_id,
    b.branch_name,

    pd.product_name,
    pd.product_category_name,

    SUM(pd.quantity) AS total_qty,
    SUM(pd.item_final_amount) AS total_revenue

FROM product_details pd

JOIN branches b
ON pd.branch_id = b.branch_id

WHERE pd.transaction_date BETWEEN '2022-10-01' AND '2022-12-31'
AND pd.branch_id IN (1,2,3,4)

GROUP BY
    periode_bulan,
    pd.branch_id,
    b.branch_name,
    pd.product_name,
    pd.product_category_name

ORDER BY
    total_revenue DESC
LIMIT 10;

-- Performa Dokter
SELECT
    DATE_FORMAT(pd.transaction_date,'%Y-%m') AS periode_bulan,
    pd.branch_id,
    b.branch_name,

    CASE
        WHEN pd.doctor_id IS NULL
            THEN 'Tanpa Dokter / OTC'
        ELSE d.doctor_alias
    END AS nama_dokter,

    COUNT(DISTINCT pd.transaction_key) AS total_transaksi,
    SUM(pd.item_final_amount) AS total_revenue

FROM product_details pd

LEFT JOIN doctors d
ON pd.doctor_id = d.doctor_id

JOIN branches b
ON pd.branch_id = b.branch_id

WHERE pd.transaction_date BETWEEN '2022-10-01' AND '2022-12-31'
AND pd.branch_id IN (1,2,3,4)

GROUP BY
    periode_bulan,
    pd.branch_id,
    b.branch_name,
    nama_dokter

ORDER BY
    total_revenue DESC;
    
-- Analisis Cabang berdasarkan Revenue
SELECT
    DATE_FORMAT(pd.transaction_date, '%Y-%m') AS periode_bulan,
    pd.branch_id,
    b.branch_name,
    COUNT(*) AS jumlah_transaksi,
    SUM(pd.payment_amount) AS total_revenue,
    ROUND(AVG(pd.payment_amount),0) AS rata_rata_per_transaksi
FROM payment_details pd
JOIN branches b
ON pd.branch_id=b.branch_id
WHERE pd.transaction_date BETWEEN '2022-10-01' AND '2022-12-31'
    AND pd.branch_id IN (1,2,3,4)
GROUP BY
    DATE_FORMAT(pd.transaction_date,'%Y-%m'),
    pd.branch_id,
    b.branch_name
ORDER BY
    periode_bulan,
    pd.branch_id;

-- Berdasarkan hasil analisis, cabang yang membutuhkan perhatian adalah Sidoarjo
-- karena setiap bulannya memiliki total revenue paling rendah.
-- Meskipun mengalami peningkatan pada bulan Desember, jika dibandingkan dengan
-- cabang lain, Sidoarjo tetap menjadi cabang dengan total revenue,
-- rata-rata per transaksi, dan jumlah transaksi paling rendah.
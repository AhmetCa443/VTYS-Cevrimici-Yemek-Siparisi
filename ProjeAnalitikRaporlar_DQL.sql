-- ====================================================================
-- ADIM 4: İLERİ DÜZEY ANALİTİK SORGULAR (DQL)
-- ====================================================================
USE YemekSepetiDB;
GO

-- 1. JOIN SORGUSU (4 Tablolu INNER JOIN)
-- [Açıklama]: Bir müşterinin verdiği siparişin; Müşteri adı, Restoran adı, 
-- Sipariş edilen ürünlerin listesi (string_agg ile) ve Toplam Tutarı getirir.
SELECT 
    K.Ad + ' ' + K.Soyad AS MusteriAdi, 
    R.RestoranAdi, 
    STRING_AGG(U.UrunAdi, ', ') AS SiparisEdilenUrunler, 
    S.ToplamTutar
FROM Siparisler S
INNER JOIN Kullanicilar K ON S.KullaniciID = K.KullaniciID
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
INNER JOIN SiparisDetaylari SD ON S.SiparisID = SD.SiparisID
INNER JOIN Urunler U ON SD.UrunID = U.UrunID
GROUP BY K.Ad, K.Soyad, R.RestoranAdi, S.ToplamTutar, S.SiparisID;
GO

-- 2. AGREGASYON (GROUP BY & HAVING)
-- [Açıklama]: Son 1 ay içerisinde toplamda 5'ten fazla sipariş almış olan 
-- restoranların adlarını ve bu restoranların ortalama sipariş tutarlarını listeler.
SELECT 
    R.RestoranAdi, 
    COUNT(S.SiparisID) AS ToplamSiparisSayisi, 
    AVG(S.ToplamTutar) AS OrtalamaSiparisTutari
FROM Siparisler S
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
WHERE S.SiparisTarihi >= DATEADD(MONTH, -1, GETDATE())
GROUP BY R.RestoranAdi
HAVING COUNT(S.SiparisID) > 5;
GO

-- 3. SUBQUERY (NOT EXISTS)
-- [Açıklama]: Platformda aktif hesabı olan ancak bugüne kadar hiç 'Askıda Yemek' 
-- bağışı yapmamış (iyilik havuzuna katkı sağlamamış) müşterileri listeler.
SELECT 
    K.Ad, 
    K.Soyad, 
    K.Eposta, 
    K.Telefon
FROM Kullanicilar K
WHERE K.Rol = 'Müşteri' 
  AND K.IsActive = 1
  AND NOT EXISTS (
      SELECT 1 
      FROM AskidaBagislar B 
      WHERE B.KullaniciID = K.KullaniciID
  );
GO

-- 4. COMPLEX QUERY (TOP 3 ANALİZİ)
-- [Açıklama]: Mevcut 'Askıda Yemek' havuzundan (IsAskidaSiparis = 1) 
-- en çok yararlanan ilk 3 kullanıcının ismini ve yararlandıkları toplam tutarı getirir.
SELECT TOP 3 
    K.Ad + ' ' + K.Soyad AS IhtiyacSahibiAdi, 
    SUM(S.ToplamTutar) AS ToplamYararlanilanTutar,
    COUNT(S.SiparisID) AS FaydalanilanSiparisSayisi
FROM Siparisler S
INNER JOIN Kullanicilar K ON S.KullaniciID = K.KullaniciID
WHERE S.IsAskidaSiparis = 1 AND S.IsActive = 1
GROUP BY K.Ad, K.Soyad
ORDER BY SUM(S.ToplamTutar) DESC;
GO

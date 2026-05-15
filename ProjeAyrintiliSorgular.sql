USE YemekSepetiDB;
GO

-- ====================================================================
-- 1. GEÇMİŞ SİPARİŞLERİM EKRANI İÇİN: VIEW (JOIN) & INDEX
-- ====================================================================

-- [ZORUNLU TEKNİK İSTER]: En az 3 tabloyu JOIN ederek karmaşık sorguları basitleştiren View.
-- [MANTIK]: Siparişin normal mi yoksa Askıda mı (ücretsiz) olduğunu CASE ile belirler.
GO
CREATE OR ALTER VIEW vw_MusteriGecmisSiparisleri AS
SELECT 
    S.SiparisID,
    S.KullaniciID,
    R.RestoranAdi,
    K.Ad + ' ' + K.Soyad AS KuryeAdi,
    S.ToplamTutar,
    S.SiparisTarihi,
    S.Durum,
    CASE 
        WHEN S.IsAskidaSiparis = 1 THEN 'Askıda (Ücretsiz)' 
        ELSE 'Normal Ödeme' 
    END AS OdemeTipi
FROM Siparisler S
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
INNER JOIN Kuryeler Kur ON S.KuryeID = Kur.KuryeID
INNER JOIN Kullanicilar K ON Kur.KullaniciID = K.KullaniciID;
GO

-- [ZORUNLU TEKNİK İSTER]: Performans için KullaniciID kolonu üzerine NONCLUSTERED INDEX.
-- Zaten ana DDL'de bazı indexler oluşturduk, buraya da müşteri bazlı sorgu için ekleyelim.
CREATE NONCLUSTERED INDEX IX_Siparisler_KullaniciID 
ON Siparisler (KullaniciID);
GO

-- ====================================================================
-- 2. PROFİLİM VE SİSTEM EKRANI İÇİN: CONSTRAINTS (KISITLAMALAR)
-- ====================================================================

-- [ZORUNLU TEKNİK İSTER]: Urunler tablosunda Fiyat > 0 olacak. 
-- Bu DDL aşamasında (CHECK (Fiyat > 0)) eklendi.

-- [ZORUNLU TEKNİK İSTER]: Restoranlar tablosunda Puan BETWEEN 1 AND 5 olacak.
-- Bu DDL aşamasında (CHECK (Puan BETWEEN 1 AND 5)) eklendi.

-- [ZORUNLU TEKNİK İSTER]: Telefon ve Eposta alanları UNIQUE ve NOT NULL olmalı.
-- Kullanicilar tablosunda (Eposta NVARCHAR(100) NOT NULL UNIQUE, Telefon NVARCHAR(20) NOT NULL UNIQUE) olarak eklendi.

-- ====================================================================
-- 3. ANALİTİK İSTATİSTİKLER: AGREGASYON (GROUP BY & HAVING)
-- ====================================================================

-- [ZORUNLU TEKNİK İSTER]: SUM, COUNT, AVG barındıran ve HAVING ile filtrelenen analiz sorgusu.
-- [ŞART]: 1'den fazla siparişi olan müşterilerin ortalama sipariş tutarı ve toplam bağışları.
SELECT 
    K.KullaniciID,
    K.Ad + ' ' + K.Soyad AS MusteriAdi,
    COUNT(S.SiparisID) AS ToplamSiparis,
    AVG(S.ToplamTutar) AS OrtalamaSiparisTutari,
    ISNULL(SUM(B.Miktar), 0) AS ToplamBagisMiktari
FROM Kullanicilar K
LEFT JOIN Siparisler S ON K.KullaniciID = S.KullaniciID
LEFT JOIN AskidaBagislar B ON K.KullaniciID = B.KullaniciID AND B.BagisTuru = 'Bakiye'
WHERE K.Rol = 'Müşteri' AND K.IsActive = 1
GROUP BY K.KullaniciID, K.Ad, K.Soyad
HAVING COUNT(S.SiparisID) > 1;
GO

-- ====================================================================
-- 4. ÖZEL BİLDİRİM: SUBQUERY (ALT SORGU - NOT EXISTS)
-- ====================================================================

-- [ZORUNLU TEKNİK İSTER]: IN, EXISTS veya NOT EXISTS kullanarak mantıksal kontrol.
-- [ŞART]: Aktif siparişi olan ama hiç askıda bağış yapmamış müşterileri bul.
SELECT Ad, Soyad, Eposta 
FROM Kullanicilar K
WHERE Rol = 'Müşteri' 
  AND EXISTS (SELECT 1 FROM Siparisler S WHERE S.KullaniciID = K.KullaniciID) -- Siparişi var
  AND NOT EXISTS (SELECT 1 FROM AskidaBagislar B WHERE B.KullaniciID = K.KullaniciID); -- Bağış yapmamış
GO

-- ====================================================================
-- 5. CİRO/BAKİYE GÜNCELLEME: TRIGGER (TETİKLEYİCİ)
-- ====================================================================

-- [ZORUNLU TEKNİK İSTER]: Sipariş teslim edildiğinde restoran cirosunu otomatik artıran trigger.
-- YemekSepeti_DB.sql içinde "trg_SiparisTeslimCiroGuncelle" adıyla kullanıldı.

-- Ek Trigger: Yeni bir bağış yapıldığında kontrol sağlamak vb. için bir yapı.
GO
CREATE OR ALTER TRIGGER trg_AskidaBagisKontrol
ON AskidaBagislar
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Miktar DECIMAL(18,2);
    SELECT @Miktar = Miktar FROM inserted;
    
    -- Eğer gereksiz devasa bir meblağ girildiyse uyarı verebilir veya loglayabilir.
    IF @Miktar > 50000 
    BEGIN
        PRINT 'Dikkat: 50.000 TL üzeri tekil bağış sisteme kaydedildi.';
    END
END;
GO

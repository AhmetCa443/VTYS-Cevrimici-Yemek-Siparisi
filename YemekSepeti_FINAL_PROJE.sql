/*
====================================================================
PROJE ADI: Çevrimiçi Yemek Sipariş Platformu Veritabanı Yönetimi
DERS: Veritabanı Yönetim Sistemleri-1 (VTYS-1) Dönem Projesi
YAZAR: Ahmet Canöz
TARİH: 2026-05-15
====================================================================

--------------------------------------------------------------------
1. PROJE AMACI VE KAPSAMI
--------------------------------------------------------------------
Bu proje, modern bir yemek sipariş platformunun ihtiyaç duyduğu 
ilişkisel veritabanı altyapısını tasarlamayı amaçlar. Sistem; 
Müşteriler, Restoran sahipleri ve Kuryeler arasında köprü kurarken; 
"Askıda Yemek" sosyal yardımlaşma modülünü de içerisinde barındırır.

--------------------------------------------------------------------
2. MÜHENDİSLİK YAKLAŞIMI VE 3. NORMAL FORM (3NF) UYGUNLUĞU
--------------------------------------------------------------------
Veritabanı tasarımı, veri bütünlüğünü korumak ve tekrarları önlemek 
adına 3. Normal Form (3NF) kurallarına göre normalize edilmiştir:

- Müşteriler, Restoranlar ve Kuryeler NULL değer israfını önlemek 
  amacıyla 3 ayrı bağımsız tabloya (3NF) bölünmüştür.
- Puan, Fiyat ve Miktar gibi kritik alanlara CHECK kısıtlamaları eklenerek 
  veri kalitesi garanti altına alınmıştır.

--------------------------------------------------------------------
3. "ASKIDA YEMEK" MANTIK VE TEKNİK TASARIMI
--------------------------------------------------------------------
Askıda Yemek modülü, iyilik havuzu bakiyelerinin anlık yönetimi için:
- AskidaBagislari, AskidaHavuz ve AskidaKullanimlari olmak üzere 
  3 aşamalı tasarlanmıştır.
- Tetikleyiciler (Triggers) ve Transaction işlemleri ile bakiye 
  yönetimi otomatize edilmiştir.
====================================================================
*/

USE master;
GO

-- Veritabanı Varsa Sil ve Yeniden Oluştur
IF DB_ID('YemekSepetiDB') IS NOT NULL
BEGIN
    ALTER DATABASE YemekSepetiDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE YemekSepetiDB;
END
GO

CREATE DATABASE YemekSepetiDB;
GO

USE YemekSepetiDB;
GO

-- ==========================================
-- 1. DDL: TABLO YAPILARI (TABLES)
-- ==========================================

CREATE TABLE Musteriler (
    MusteriID        INT IDENTITY(1,1) PRIMARY KEY,
    Ad               NVARCHAR(50) NOT NULL,
    Soyad            NVARCHAR(50) NOT NULL,
    Eposta           NVARCHAR(100) NOT NULL UNIQUE,
    TelefonNumarasi  NVARCHAR(20) NOT NULL UNIQUE,
    SifreHash        NVARCHAR(256) NOT NULL,
    IhtiyacSahibiMi  BIT DEFAULT 0,
    AktifMi          BIT DEFAULT 1
);

CREATE TABLE Restoranlar (
    RestoranID       INT IDENTITY(1,1) PRIMARY KEY,
    RestoranAdi      NVARCHAR(100) NOT NULL,
    Adres            NVARCHAR(255),
    Puan             DECIMAL(3,2) CHECK (Puan BETWEEN 1 AND 5),
    ToplamCiro       DECIMAL(18,2) DEFAULT 0.0,
    AktifMi          BIT DEFAULT 1
);

CREATE TABLE MenuKategorileri (
    KategoriID       INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID       INT NOT NULL,
    KategoriAdi      NVARCHAR(50) NOT NULL,
    AktifMi          BIT DEFAULT 1,
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);

CREATE TABLE MenuUrunleri (
    UrunID           INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID       INT NOT NULL,
    KategoriID       INT NOT NULL,
    UrunAdi          NVARCHAR(100) NOT NULL,
    Aciklama         NVARCHAR(255),
    Fiyat            DECIMAL(10,2) CHECK (Fiyat > 0),
    AktifMi          BIT DEFAULT 1,
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    FOREIGN KEY (KategoriID) REFERENCES MenuKategorileri(KategoriID)
);

CREATE TABLE Kuryeler (
    KuryeID          INT IDENTITY(1,1) PRIMARY KEY,
    Ad               NVARCHAR(50) NOT NULL,
    Soyad            NVARCHAR(50) NOT NULL,
    TelefonNumarasi  NVARCHAR(20) NOT NULL UNIQUE,
    AktifMi          BIT DEFAULT 1
);

CREATE TABLE Siparisler (
    SiparisID        INT IDENTITY(1,1) PRIMARY KEY,
    MusteriID        INT NOT NULL,
    RestoranID       INT NOT NULL,
    KuryeID          INT NOT NULL,
    SiparisTarihi    DATETIME DEFAULT GETDATE(),
    ToplamTutar      DECIMAL(18,2) CHECK (ToplamTutar >= 0),
    SiparisDurumu    NVARCHAR(20) CHECK (SiparisDurumu IN ('Bekliyor', 'Hazırlanıyor', 'Yolda', 'Teslim Edildi', 'İptal')),
    AskidaSiparisMi  BIT DEFAULT 0,
    AktifMi          BIT DEFAULT 1,
    FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID),
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    FOREIGN KEY (KuryeID) REFERENCES Kuryeler(KuryeID)
);

CREATE TABLE SiparisDetaylari (
    SiparisDetayID   INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID        INT NOT NULL,
    UrunID           INT NOT NULL,
    Miktar           INT CHECK (Miktar > 0),
    BirimFiyat       DECIMAL(10,2) CHECK (BirimFiyat > 0),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    FOREIGN KEY (UrunID) REFERENCES MenuUrunleri(UrunID)
);

CREATE TABLE AskidaHavuz (
    HavuzID          INT IDENTITY(1,1) PRIMARY KEY,
    GuncelBakiye     DECIMAL(18,2) DEFAULT 0.0 CHECK (GuncelBakiye >= 0)
);

CREATE TABLE AskidaBagislari (
    BagisID          INT IDENTITY(1,1) PRIMARY KEY,
    MusteriID        INT NULL, -- Anonim bağış için Nullable
    AnonimMi         BIT DEFAULT 0,
    Miktar           DECIMAL(18,2) CHECK (Miktar > 0),
    BagisTarihi      DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID)
);

CREATE TABLE AskidaKullanimlari (
    KullanimID       INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID        INT NOT NULL UNIQUE,
    MusteriID        INT NOT NULL,
    KullanilanMiktar DECIMAL(18,2) CHECK (KullanilanMiktar > 0),
    KullanimTarihi   DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    FOREIGN KEY (MusteriID) REFERENCES Musteriler(MusteriID)
);

-- Raporlama için eklenmiş Siparis Log Tablosu
CREATE TABLE SiparisGecmisi (
    LogID            INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID        INT NOT NULL,
    EskiDurum        NVARCHAR(20),
    YeniDurum        NVARCHAR(20),
    DegisimTarihi    DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID)
);
GO

-- ==========================================
-- 2. GÖRÜNÜMLER VE İNDEKSLER (VIEWS & INDEXES)
-- ==========================================

CREATE VIEW vw_AktifRestoranMenuleri AS
SELECT R.RestoranAdi, R.Puan, K.KategoriAdi, U.UrunAdi, U.Fiyat
FROM Restoranlar R
INNER JOIN MenuKategorileri K ON R.RestoranID = K.RestoranID
INNER JOIN MenuUrunleri U ON K.KategoriID = U.KategoriID
WHERE R.AktifMi = 1 AND K.AktifMi = 1 AND U.AktifMi = 1;
GO

CREATE VIEW vw_AskidaHavuzDurumu AS
SELECT 
    H.GuncelBakiye AS MevcutNetBakiye,
    ISNULL((SELECT SUM(Miktar) FROM AskidaBagislari), 0) AS ToplamGirenBagis,
    ISNULL((SELECT SUM(KullanilanMiktar) FROM AskidaKullanimlari), 0) AS ToplamHarcanan
FROM AskidaHavuz H;
GO

CREATE NONCLUSTERED INDEX IX_Siparisler_Tarih ON Siparisler(SiparisTarihi DESC);
CREATE NONCLUSTERED INDEX IX_Musteriler_Eposta ON Musteriler(Eposta);
GO

-- ==========================================
-- 3. FONKSİYONLAR VE SAKLI YORDAMLAR (SP & FUNC)
-- ==========================================

CREATE PROCEDURE sp_BagisYap @Mid INT = NULL, @Miktar DECIMAL(18,2) AS
BEGIN
    DECLARE @Anonim BIT = 0;
    IF @Mid IS NULL SET @Anonim = 1;

    BEGIN TRANSACTION;
        INSERT INTO AskidaBagislari (MusteriID, AnonimMi, Miktar) VALUES (@Mid, @Anonim, @Miktar);
        UPDATE AskidaHavuz SET GuncelBakiye = GuncelBakiye + @Miktar WHERE HavuzID = 1;
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE sp_AskidaSiparisVer @Mid INT, @Rid INT, @KuId INT, @Uid INT AS
BEGIN
    DECLARE @Fiyat DECIMAL(10,2), @MevcutBakiye DECIMAL(18,2);
    SELECT @Fiyat = Fiyat FROM MenuUrunleri WHERE UrunID = @Uid;
    SELECT @MevcutBakiye = GuncelBakiye FROM AskidaHavuz WHERE HavuzID = 1;

    -- Havuzda yeterli para var mı kontrolü
    IF @MevcutBakiye >= @Fiyat
    BEGIN
        BEGIN TRANSACTION;
            -- 1. Sipariş Oluştur (AskidaSiparisMi = 1)
            INSERT INTO Siparisler (MusteriID, RestoranID, KuryeID, ToplamTutar, SiparisDurumu, AskidaSiparisMi)
            VALUES (@Mid, @Rid, @KuId, @Fiyat, 'Bekliyor', 1);
            
            DECLARE @YeniSiparisID INT = SCOPE_IDENTITY();
            
            -- 2. Sipariş Detayını Ekle
            INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) 
            VALUES (@YeniSiparisID, @Uid, 1, @Fiyat);
            
            -- 3. Kullanım Tablosuna Logla
            INSERT INTO AskidaKullanimlari (SiparisID, MusteriID, KullanilanMiktar) 
            VALUES (@YeniSiparisID, @Mid, @Fiyat);
            
            -- 4. Havuz Bakiyesini Düşür
            UPDATE AskidaHavuz SET GuncelBakiye = GuncelBakiye - @Fiyat WHERE HavuzID = 1;
        COMMIT TRANSACTION;
    END
END;
GO

-- ==========================================
-- 4. TETİKLEYİCİLER (TRIGGERS)
-- ==========================================

-- 1. Ciro Güncelleyici Tetikleyici
CREATE TRIGGER trg_SiparisTeslimCiroGuncelle ON Siparisler AFTER UPDATE AS
BEGIN
    IF UPDATE(SiparisDurumu)
        UPDATE R SET R.ToplamCiro = R.ToplamCiro + i.ToplamTutar
        FROM Restoranlar R INNER JOIN inserted i ON R.RestoranID = i.RestoranID
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.SiparisDurumu = 'Teslim Edildi' AND d.SiparisDurumu <> 'Teslim Edildi';
END;
GO

-- 2. Sipariş Durumu Geçmişi Kaydedici
CREATE TRIGGER trg_SiparisDurumLog ON Siparisler AFTER UPDATE AS
BEGIN
    IF UPDATE(SiparisDurumu)
        INSERT INTO SiparisGecmisi (SiparisID, EskiDurum, YeniDurum)
        SELECT i.SiparisID, d.SiparisDurumu, i.SiparisDurumu FROM inserted i 
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID WHERE i.SiparisDurumu <> d.SiparisDurumu;
END;
GO

-- ==========================================
-- 5. MOCK DATA (DML) - SAHTE VERİ GİRİŞİ
-- ==========================================

-- Başlangıç Havuzu
INSERT INTO AskidaHavuz (GuncelBakiye) VALUES (0.0);

-- Müşteriler (10 Adet)
INSERT INTO Musteriler (Ad, Soyad, Eposta, TelefonNumarasi, SifreHash, IhtiyacSahibiMi) VALUES 
('Ahmet', 'Canöz', 'ahmet@mail.com', '5551000001', 'hash1', 0), 
('Melek', 'Canöz', 'melek@mail.com', '5551000002', 'hash2', 1),
('Ali', 'Yılmaz', 'ali@mail.com', '5551000003', 'hash3', 0),
('Ayşe', 'Kaya', 'ayse@mail.com', '5551000004', 'hash4', 1),
('Fatma', 'Demir', 'fatma@mail.com', '5551000005', 'hash5', 1),
('Veli', 'Çelik', 'veli@mail.com', '5551000006', 'hash6', 0),
('Can', 'Polat', 'can@mail.com', '5551000007', 'hash7', 0),
('Eda', 'Gül', 'eda@mail.com', '5551000008', 'hash8', 1),
('Burak', 'Şahin', 'burak@mail.com', '5551000009', 'hash9', 0),
('Zeynep', 'Kurt', 'zeynep@mail.com', '5551000010', 'hash10', 1);

-- Restoranlar (5 Adet)
INSERT INTO Restoranlar (RestoranAdi, Adres, Puan) VALUES 
('Anadolu Lezzetleri', 'Van Merkez', 4.8), 
('Little Italy', 'İskele Cd.', 4.5), 
('Burger Station', 'Kampüs İçi', 4.2), 
('Tokyo Express', 'Maraş Cd.', 4.7), 
('Şekerci Mehmet', 'Cumhuriyet Cd.', 4.9);

-- Kuryeler (5 Adet)
INSERT INTO Kuryeler (Ad, Soyad, TelefonNumarasi) VALUES 
('Hasan', 'Hızlı', '5552000001'), 
('Kemal', 'Uçar', '5552000002'), 
('Murat', 'Kaçar', '5552000003'), 
('Selin', 'Rüzgar', '5552000004'), 
('Cem', 'Yaman', '5552000005');

-- Menü Kategorileri (10 Adet)
INSERT INTO MenuKategorileri (RestoranID, KategoriAdi) VALUES 
(1,'Kebaplar'), (1,'Dürümler'), (2,'Pizzalar'), (2,'Makarnalar'), 
(3,'Burgerler'), (3,'Yan Ürünler'), (4,'Sushi'), (4,'Noodle'), 
(5,'Tatlılar'), (5,'İçecekler');

-- Ürünler (50 Adet Otomatik Üretim)
DECLARE @i INT = 1; 
WHILE @i <= 50 
BEGIN 
    INSERT INTO MenuUrunleri (RestoranID, KategoriID, UrunAdi, Fiyat) 
    VALUES (((@i-1)/10)+1, ((@i-1)/5)+1, 'Ürün ' + CAST(@i AS VARCHAR(10)), 50.0 + (@i*2)); 
    SET @i = @i + 1; 
END;
GO

-- Bağışların Yapılması
EXEC sp_BagisYap @Mid = 1, @Miktar = 5000; -- Ahmet bağış yapar
EXEC sp_BagisYap @Mid = NULL, @Miktar = 2000; -- Gizli bağış
DECLARE @j INT = 1; 
WHILE @j <= 5 
BEGIN 
    EXEC sp_BagisYap @Mid = 3, @Miktar = 300; 
    SET @j = @j + 1; 
END;

-- Normal Siparişler (80 Adet)
DECLARE @cnt INT = 1;
WHILE @cnt <= 80
BEGIN
    INSERT INTO Siparisler (MusteriID, RestoranID, KuryeID, ToplamTutar, SiparisDurumu, SiparisTarihi)
    VALUES (
        (@cnt % 10) + 1,       -- Müşteri 1-10
        (@cnt % 5) + 1,        -- Restoran 1-5
        (@cnt % 5) + 1,        -- Kurye 1-5
        100.0 + @cnt, 
        'Teslim Edildi', 
        DATEADD(DAY, -@cnt, GETDATE())
    );
    INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) 
    VALUES (SCOPE_IDENTITY(), (@cnt % 50) + 1, 1, 100.0 + @cnt);
    SET @cnt = @cnt + 1;
END;
GO

-- Askıda Siparişler (20 Adet)
DECLARE @aknt INT = 1;
WHILE @aknt <= 20
BEGIN 
    -- 2, 4, 5, 8, 10 nolu müşteriler ihtiyaç sahibidir.
    DECLARE @IhtiyacliMusteri INT = CASE (@aknt % 5) WHEN 0 THEN 2 WHEN 1 THEN 4 WHEN 2 THEN 5 WHEN 3 THEN 8 ELSE 10 END;
    EXEC sp_AskidaSiparisVer @Mid = @IhtiyacliMusteri, @Rid = (@aknt % 5) + 1, @KuId = (@aknt % 5) + 1, @Uid = (@aknt % 50) + 1;
    SET @aknt = @aknt + 1;
END;
GO

-- ==========================================
-- 6. ANALİTİK SORGULAR (DQL) - İLERİ DÜZEY
-- ==========================================

-- 1. JOIN Analizi (En yüksek tutarlı sipariş fişleri)
SELECT TOP 5 
    M.Ad + ' ' + M.Soyad AS MusteriBilgisi, 
    R.RestoranAdi, 
    K.Ad AS KuryeAdi,
    S.ToplamTutar,
    S.SiparisDurumu
FROM Siparisler S
INNER JOIN Musteriler M ON S.MusteriID = M.MusteriID
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
INNER JOIN Kuryeler K ON S.KuryeID = K.KuryeID
ORDER BY S.ToplamTutar DESC;

-- 2. Gruplama ve Agregasyon (Restoranların Toplam Ciro ve Sipariş Analizi)
SELECT 
    R.RestoranAdi, 
    COUNT(S.SiparisID) AS ToplamSiparisSayisi,
    SUM(S.ToplamTutar) AS ToplamKazanilanCiro,
    AVG(S.ToplamTutar) AS OrtalamaSepetTutari
FROM Siparisler S 
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
WHERE S.SiparisDurumu = 'Teslim Edildi'
GROUP BY R.RestoranAdi
HAVING COUNT(S.SiparisID) > 5;
GO

-- 3. Alt Sorgu (Subquery) - Hiç bağış yapmamış ama sistemde aktif siparişi olan müşteriler
SELECT M.Ad, M.Soyad, M.Eposta
FROM Musteriler M
WHERE M.AktifMi = 1 
  AND NOT EXISTS (SELECT 1 FROM AskidaBagislari AB WHERE AB.MusteriID = M.MusteriID)
  AND EXISTS (SELECT 1 FROM Siparisler S WHERE S.MusteriID = M.MusteriID);
GO

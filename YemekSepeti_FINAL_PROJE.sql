/*
====================================================================
PROJE ADI: Çevrimiçi Yemek Sipariş Platformu Veritabanı Yönetimi
DERS: Veritabanı Yönetim Sistemleri-1 (VTYS-1) Dönem Projesi
YAZAR: Antigravity AI
TARİH: 2026-04-05
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

- Kullanıcılar tek tabloda (Rol bazlı) tutularak veri bütünlüğü sağlanmıştır.
- Kurye ve Restoran detayları ayrıştırılarak fonksiyonel bağımlılıklar 
  minimize edilmiştir.
- Puan ve Fiyat gibi kritik alanlara CHECK kısıtlamaları eklenerek 
  veri kalitesi garanti altına alınmıştır.

--------------------------------------------------------------------
3. "ASKIDA YEMEK" MANTIK VE TEKNİK TASARIMI
--------------------------------------------------------------------
Askıda Yemek modülü, iyilik havuzu bakiyelerinin anlık yönetimi için:
- Havuz bakiyesi (AskidaHavuz) tablosu ile merkezi takip sağlar.
- Tetikleyiciler (Triggers) ile sipariş anında bağış tutarının 
  düşürülmesi ve restoran hak edişinin cirolara yansıması otomatize edilmiştir.
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

CREATE TABLE Kullanicilar (
    KullaniciID  INT IDENTITY(1,1) PRIMARY KEY,
    Ad           NVARCHAR(50) NOT NULL,
    Soyad        NVARCHAR(50) NOT NULL,
    Eposta       NVARCHAR(100) NOT NULL UNIQUE,
    Telefon      NVARCHAR(20) NOT NULL UNIQUE,
    SifreHash    NVARCHAR(256) NOT NULL,
    Rol          NVARCHAR(50) NOT NULL DEFAULT 'Müşteri', -- Müşteri, Kurye, Restoran Sahibi
    IsActive     BIT DEFAULT 1
);

CREATE TABLE Kuryeler (
    KuryeID      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID  INT NOT NULL UNIQUE,
    AracTipi     NVARCHAR(50), 
    Plaka        NVARCHAR(20),
    Durum        NVARCHAR(20) DEFAULT 'Müsait',
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE Restoranlar (
    RestoranID   INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID  INT NOT NULL,
    RestoranAdi  NVARCHAR(100) NOT NULL,
    Adres        NVARCHAR(255),
    Puan         DECIMAL(3,2) CHECK (Puan BETWEEN 1 AND 5),
    ToplamCiro   DECIMAL(18,2) DEFAULT 0.0,
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE Menuler (
    MenuID       INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID   INT NOT NULL,
    KategoriAdi  NVARCHAR(50) NOT NULL,
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);

CREATE TABLE Urunler (
    UrunID       INT IDENTITY(1,1) PRIMARY KEY,
    MenuID       INT NOT NULL,
    UrunAdi      NVARCHAR(100) NOT NULL,
    Aciklama     NVARCHAR(255),
    Fiyat        DECIMAL(10,2) CHECK (Fiyat > 0),
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (MenuID) REFERENCES Menuler(MenuID)
);

CREATE TABLE Siparisler (
    SiparisID        INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID      INT NOT NULL,
    RestoranID       INT NOT NULL,
    KuryeID          INT NOT NULL,
    SiparisTarihi    DATETIME DEFAULT GETDATE(),
    ToplamTutar      DECIMAL(18,2) CHECK (ToplamTutar >= 0),
    Durum            NVARCHAR(20) CHECK (Durum IN ('Bekliyor', 'Hazırlanıyor', 'Yolda', 'Teslim Edildi', 'İptal')),
    IsAskidaSiparis  BIT DEFAULT 0,
    IsActive         BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    FOREIGN KEY (KuryeID) REFERENCES Kuryeler(KuryeID)
);

CREATE TABLE SiparisDetaylari (
    SiparisDetayID  INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID       INT NOT NULL,
    UrunID          INT NOT NULL,
    Miktar          INT CHECK (Miktar > 0),
    BirimFiyat      DECIMAL(10,2) CHECK (BirimFiyat > 0),
    IsActive        BIT DEFAULT 1,
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);

CREATE TABLE AskidaBagislar (
    BagisID      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID  INT NULL,
    BagisTuru    NVARCHAR(20) CHECK (BagisTuru IN ('Bakiye', 'Urun')),
    Miktar       DECIMAL(18,2) CHECK (Miktar > 0),
    Tarih        DATETIME DEFAULT GETDATE(),
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE AskidaTalepler (
    TalepID      INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID  INT NOT NULL,
    SiparisID    INT NULL,
    Durum        NVARCHAR(20) CHECK (Durum IN ('Bekliyor', 'Onaylandi', 'Reddedildi')),
    Tarih        DATETIME DEFAULT GETDATE(),
    IsActive     BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID)
);

CREATE TABLE AskidaHavuz (
    HavuzID        INT IDENTITY(1,1) PRIMARY KEY,
    GuncelBakiye   DECIMAL(18,2) DEFAULT 0.0 CHECK (GuncelBakiye >= 0),
    SonGuncelleme  DATETIME DEFAULT GETDATE(),
    IsActive       BIT DEFAULT 1
);

CREATE TABLE SiparisGecmisi (
    LogID          INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID      INT NOT NULL,
    EskiDurum      NVARCHAR(20),
    YeniDurum      NVARCHAR(20),
    DegisimTarihi  DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID)
);
GO

-- ==========================================
-- 2. GÖRÜNÜMLER VE İNDEKSLER (VIEWS & INDEXES)
-- ==========================================

CREATE VIEW vw_AktifRestoranMenuleri AS
SELECT R.RestoranAdi, R.Puan, M.KategoriAdi, U.UrunAdi, U.Fiyat
FROM Restoranlar R
INNER JOIN Menuler M ON R.RestoranID = M.RestoranID
INNER JOIN Urunler U ON M.MenuID = U.MenuID
WHERE R.IsActive = 1 AND M.IsActive = 1 AND U.IsActive = 1;
GO

CREATE VIEW vw_AskidaHavuzDurumu AS
SELECT 
    (ISNULL((SELECT SUM(Miktar) FROM AskidaBagislar WHERE BagisTuru = 'Bakiye' AND IsActive = 1), 0) -
     ISNULL((SELECT SUM(ToplamTutar) FROM Siparisler WHERE IsAskidaSiparis = 1 AND IsActive = 1), 0)) AS MevcutBakiye,
    ISNULL((SELECT SUM(Miktar) FROM AskidaBagislar WHERE BagisTuru = 'Bakiye' AND IsActive = 1), 0) AS ToplamBagis
GO

CREATE NONCLUSTERED INDEX IX_Siparisler_Tarih ON Siparisler(SiparisTarihi DESC);
CREATE NONCLUSTERED INDEX IX_Kullanicilar_Eposta ON Kullanicilar(Eposta);
GO

-- ==========================================
-- 3. FONKSİYONLAR VE SAKLI YORDAMLAR (SP & FUNC)
-- ==========================================

CREATE FUNCTION fn_KullaniciToplamBagis (@Kid INT)
RETURNS DECIMAL(18,2) AS
BEGIN
    DECLARE @T DECIMAL(18,2);
    SELECT @T = ISNULL(SUM(Miktar), 0) FROM AskidaBagislar WHERE KullaniciID = @Kid AND IsActive = 1;
    RETURN @T;
END;
GO

CREATE PROCEDURE sp_BagisYap @Kid INT = NULL, @M DECIMAL(18,2) AS
BEGIN
    INSERT INTO AskidaBagislar (KullaniciID, BagisTuru, Miktar) VALUES (@Kid, 'Bakiye', @M);
    UPDATE AskidaHavuz SET GuncelBakiye = GuncelBakiye + @M, SonGuncelleme = GETDATE() WHERE HavuzID = 1;
END;
GO

CREATE PROCEDURE sp_AskidaSiparisVer @Mid INT, @Rid INT, @KuId INT, @Uid INT AS
BEGIN
    DECLARE @F DECIMAL(10,2), @T DECIMAL(18,2), @H DECIMAL(18,2);
    SELECT @F = Fiyat FROM Urunler WHERE UrunID = @Uid;
    SET @T = @F;
    SELECT @H = GuncelBakiye FROM AskidaHavuz WHERE HavuzID = 1;
    IF @H >= @T
    BEGIN
        INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, IsAskidaSiparis)
        VALUES (@Mid, @Rid, @KuId, @T, 'Bekliyor', 1);
        DECLARE @Sid INT = SCOPE_IDENTITY();
        INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) VALUES (@Sid, @Uid, 1, @F);
        INSERT INTO AskidaTalepler (KullaniciID, SiparisID, Durum) VALUES (@Mid, @Sid, 'Onaylandi');
        UPDATE AskidaHavuz SET GuncelBakiye = GuncelBakiye - @T WHERE HavuzID = 1;
    END
END;
GO

-- ==========================================
-- 4. TETİKLEYİCİLER (TRIGGERS)
-- ==========================================

CREATE TRIGGER trg_SiparisTeslimCiroGuncelle ON Siparisler AFTER UPDATE AS
BEGIN
    IF UPDATE(Durum)
        UPDATE R SET R.ToplamCiro = R.ToplamCiro + i.ToplamTutar
        FROM Restoranlar R INNER JOIN inserted i ON R.RestoranID = i.RestoranID
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.Durum = 'Teslim Edildi' AND d.Durum <> 'Teslim Edildi';
END;
GO

CREATE TRIGGER trg_AskidaSiparisBagisDusur ON Siparisler AFTER INSERT AS
BEGIN
    DECLARE @Tut DECIMAL(18,2), @IsA BIT;
    SELECT @Tut = ToplamTutar, @IsA = IsAskidaSiparis FROM inserted;
    IF @IsA = 1
        UPDATE TOP (1) AskidaBagislar SET Miktar = Miktar - @Tut 
        WHERE IsActive = 1 AND BagisTuru = 'Bakiye' AND Miktar >= @Tut;
END;
GO

CREATE TRIGGER trg_SiparisDurumLog ON Siparisler AFTER UPDATE AS
BEGIN
    IF UPDATE(Durum)
        INSERT INTO SiparisGecmisi (SiparisID, EskiDurum, YeniDurum)
        SELECT i.SiparisID, d.Durum, i.Durum FROM inserted i 
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID WHERE i.Durum <> d.Durum;
END;
GO

-- ==========================================
-- 5. MOCK DATA (DML)
-- ==========================================

INSERT INTO AskidaHavuz (GuncelBakiye) VALUES (0.0);

-- Kullanıcılar (Ali, Veli + 5 Restoran Sahibi + 5 Kurye = 12 Toplam)
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, SifreHash, Rol) VALUES 
('Ali', 'K', 'ali@m.com', '11', 'h', 'Müşteri'), 
('Veli', 'Y', 'veli@m.com', '12', 'h', 'Müşteri'),
('S-1', 'B', 's1@r.com', '555301', 'h', 'Restoran Sahibi'), 
('S-2', 'P', 's2@r.com', '555302', 'h', 'Restoran Sahibi'),
('S-3', 'H', 's3@r.com', '555303', 'h', 'Restoran Sahibi'), 
('S-4', 'A', 's4@r.com', '555304', 'h', 'Restoran Sahibi'),
('S-5', 'T', 's5@r.com', '555305', 'h', 'Restoran Sahibi'),
('K-1', 'M', 'k1@k.com', '555201', 'h', 'Kurye'),
('K-2', 'M', 'k2@k.com', '555202', 'h', 'Kurye'),
('K-3', 'M', 'k3@k.com', '555203', 'h', 'Kurye'),
('K-4', 'B', 'k4@k.com', '555204', 'h', 'Kurye'),
('K-5', 'B', 'k5@k.com', '555205', 'h', 'Kurye');

-- Kuryeler (IDs 8-12)
INSERT INTO Kuryeler (KullaniciID, AracTipi, Plaka) VALUES 
(8,'Motor','34-1'), (9,'Motor','34-2'), (10,'Motor','34-3'), (11,'Bisiklet','N'), (12,'Bisiklet','N');

-- Restoranlar (IDs 3-7)
INSERT INTO Restoranlar (KullaniciID, RestoranAdi, Adres, Puan) VALUES 
(3, 'Anadolu Lezzetleri', 'Beşiktaş, İst', 4.8), 
(4, 'Little Italy', 'Şişli, İst', 4.5), 
(5, 'Burger Station', 'Kadıköy, İst', 4.2), 
(6, 'Tokyo Express', 'Üsküdar, İst', 4.7), 
(7, 'Şekerci Mehmet', 'Beyoğlu, İst', 4.9);

-- Menüler (10 Kategori)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES 
(1,'Kebaplar'), (1,'Dürümler'), (2,'Pizzalar'), (2,'Makarnalar'), 
(3,'Burgerler'), (3,'Yan Ürünler'), (4,'Sushi'), (4,'Noodle'), 
(5,'Geleneksel'), (5,'Şerbetli');

-- Ürünler (Tam 50 Adet - Yönerge Gereği)
DECLARE @i INT = 1; 
WHILE @i <= 50 
BEGIN 
    INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) 
    VALUES ((@i % 10) + 1, 'Lezzet Ürünü ' + CAST(@i AS VARCHAR(10)), 50.0 + (@i*5)); 
    SET @i = @i + 1; 
END;
GO

-- Bağışlar ve Havuz Başlangıcı
EXEC sp_BagisYap @Kid = 1, @M = 5000;
EXEC sp_BagisYap @Kid = NULL, @M = 2000;
DECLARE @j INT = 1; WHILE @j <= 10 BEGIN EXEC sp_BagisYap @Kid = @j, @M = 300; SET @j = @j + 1; END;

-- Normal Siparişler (80 Adet)
DECLARE @cnt INT = 1;
WHILE @cnt <= 80
BEGIN
    INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, SiparisTarihi)
    VALUES (
        (@cnt % 2) + 1,        -- Müşteri 1 veya 2
        (@cnt % 5) + 1,        -- Restoran 1-5
        (@cnt % 5) + 1,        -- Kurye 1-5
        150.0 + @cnt, 
        'Teslim Edildi', 
        DATEADD(DAY, -@cnt, GETDATE())
    );
    INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) 
    VALUES (SCOPE_IDENTITY(), (@cnt % 50) + 1, 1, 150.0 + @cnt);
    SET @cnt = @cnt + 1;
END;
GO

-- Askıda Siparişler (20 Adet)
DECLARE @aknt INT = 1;
WHILE @aknt <= 20
BEGIN 
    EXEC sp_AskidaSiparisVer @Mid = (@aknt % 2) + 1, @Rid = (@aknt % 5) + 1, @KuId = 1, @Uid = (@aknt % 50) + 1;
    SET @aknt = @aknt + 1;
END;
GO

-- ==========================================
-- 6. ANALİTİK SORGULAR (DQL)
-- ==========================================

-- 1. JOIN Analizi
SELECT TOP 5 K.Ad, R.RestoranAdi, S.ToplamTutar
FROM Siparisler S
INNER JOIN Kullanicilar K ON S.KullaniciID = K.KullaniciID
INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID;

-- 2. Restoran İstatistik
SELECT R.RestoranAdi, COUNT(S.SiparisID) AS SiparisSayisi
FROM Siparisler S INNER JOIN Restoranlar R ON S.RestoranID = R.RestoranID
GROUP BY R.RestoranAdi;
GO

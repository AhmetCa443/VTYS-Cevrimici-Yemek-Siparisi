-- ==========================================
-- VTYS-1 DÖNEM PROJESİ: ÇEVRİMİÇİ YEMEK SİPARİŞ PLATFORMU
-- Prompt 1 Gereksinimlerine Göre Yeniden Tasarlanmış Veritabanı
-- ==========================================

USE master;
GO
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
-- 1. DDL VE KISITLAMALAR (TABLES & CONSTRAINTS)
-- ==========================================

CREATE TABLE Kullanicilar (
    KullaniciID INT IDENTITY(1,1) PRIMARY KEY,
    Ad NVARCHAR(50) NOT NULL,
    Soyad NVARCHAR(50) NOT NULL,
    Eposta NVARCHAR(100) NOT NULL UNIQUE,
    Telefon NVARCHAR(20) NOT NULL UNIQUE,
    SifreHash NVARCHAR(256) NOT NULL,
    Rol NVARCHAR(50) NOT NULL DEFAULT 'Müşteri', -- Müşteri, Kurye, Restoran Sahibi
    IsActive BIT DEFAULT 1
);
-- Kuryeler hem rol hem de bağımsız araç/plaka tutan detay tablosu olarak işlev görüyor.
CREATE TABLE Kuryeler (
    KuryeID INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID INT NOT NULL UNIQUE,
    AracTipi NVARCHAR(50),  -- Motorsiklet, Bisiklet, Araba vb.
    Plaka NVARCHAR(20),
    Durum NVARCHAR(20) DEFAULT 'Müsait',
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE Restoranlar (
    RestoranID INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID INT NOT NULL, -- Restoran sahibinin KullaniciID'si
    RestoranAdi NVARCHAR(100) NOT NULL,
    Adres NVARCHAR(255),
    Puan DECIMAL(3,2) CHECK (Puan BETWEEN 1 AND 5),
    ToplamCiro DECIMAL(18,2) DEFAULT 0.0,
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE Menuler (
    MenuID INT IDENTITY(1,1) PRIMARY KEY,
    RestoranID INT NOT NULL,
    KategoriAdi NVARCHAR(50) NOT NULL,
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID)
);

CREATE TABLE Urunler (
    UrunID INT IDENTITY(1,1) PRIMARY KEY,
    MenuID INT NOT NULL,
    UrunAdi NVARCHAR(100) NOT NULL,
    Aciklama NVARCHAR(255),
    Fiyat DECIMAL(10,2) CHECK (Fiyat > 0),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (MenuID) REFERENCES Menuler(MenuID)
);

CREATE TABLE Siparisler (
    SiparisID INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID INT NOT NULL,  -- (Müşteri)
    RestoranID INT NOT NULL,
    KuryeID INT NOT NULL,
    SiparisTarihi DATETIME DEFAULT GETDATE(),
    ToplamTutar DECIMAL(18,2) CHECK (ToplamTutar >= 0),
    Durum NVARCHAR(20) CHECK (Durum IN ('Bekliyor', 'Hazırlanıyor', 'Yolda', 'Teslim Edildi', 'İptal')),
    IsAskidaSiparis BIT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    FOREIGN KEY (RestoranID) REFERENCES Restoranlar(RestoranID),
    FOREIGN KEY (KuryeID) REFERENCES Kuryeler(KuryeID)
);

CREATE TABLE SiparisDetaylari (
    SiparisDetayID INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID INT NOT NULL,
    UrunID INT NOT NULL,
    Miktar INT CHECK (Miktar > 0),
    BirimFiyat DECIMAL(10,2) CHECK (BirimFiyat > 0),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID),
    FOREIGN KEY (UrunID) REFERENCES Urunler(UrunID)
);

-- Askıda Yemek Formları:
CREATE TABLE AskidaBagislar (
    BagisID INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID INT NULL,  -- NULL olursa Anonim
    BagisTuru NVARCHAR(20) CHECK (BagisTuru IN ('Bakiye', 'Urun')),
    Miktar DECIMAL(18,2) CHECK (Miktar > 0),
    Tarih DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID)
);

CREATE TABLE AskidaTalepler (
    TalepID INT IDENTITY(1,1) PRIMARY KEY,
    KullaniciID INT NOT NULL, -- İhtiyaç sahibi müşteri
    SiparisID INT NULL, -- Talep onaylanıp siparişe dönüşürse
    Durum NVARCHAR(20) CHECK (Durum IN ('Bekliyor', 'Onaylandi', 'Reddedildi')),
    Tarih DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (KullaniciID) REFERENCES Kullanicilar(KullaniciID),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID)
);

-- Yeni Eklenen Tablolar (Adım 2):
CREATE TABLE AskidaHavuz (
    HavuzID INT IDENTITY(1,1) PRIMARY KEY,
    GuncelBakiye DECIMAL(18,2) DEFAULT 0.0 CHECK (GuncelBakiye >= 0),
    SonGuncelleme DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE TABLE SiparisGecmisi (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    SiparisID INT NOT NULL,
    EskiDurum NVARCHAR(20),
    YeniDurum NVARCHAR(20),
    DegisimTarihi DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (SiparisID) REFERENCES Siparisler(SiparisID)
);
GO

-- ==========================================
-- 2. GÖRÜNÜMLER (VIEWS - Backend'in Beklediği Format İçin API Katmanı)
-- ==========================================

-- Python backend API'nin beslendiği, eski yapıyla aynı çıktıyı veren view:
CREATE VIEW vw_AktifRestoranMenuleri AS
SELECT 
    R.RestoranAdi AS RestaurantName,
    R.Puan AS Rating,
    M.KategoriAdi AS CategoryName,
    U.UrunAdi AS MenuItemName,
    U.Fiyat AS Price
FROM Restoranlar R
INNER JOIN Menuler M ON R.RestoranID = M.RestoranID
INNER JOIN Urunler U ON M.MenuID = U.MenuID
WHERE R.IsActive = 1 AND M.IsActive = 1 AND U.IsActive = 1;
GO

CREATE VIEW vw_AskidaYemekHavuzDurumu AS
SELECT 
    (ISNULL((SELECT SUM(Miktar) FROM AskidaBagislar WHERE BagisTuru = 'Bakiye' AND IsActive = 1), 0) -
     ISNULL((SELECT SUM(ToplamTutar) FROM Siparisler WHERE IsAskidaSiparis = 1 AND IsActive = 1), 0)) AS MevcutBakiye,
    ISNULL((SELECT SUM(Miktar) FROM AskidaBagislar WHERE BagisTuru = 'Bakiye' AND IsActive = 1), 0) AS ToplamYapilanBagis,
    ISNULL((SELECT SUM(ToplamTutar) FROM Siparisler WHERE IsAskidaSiparis = 1 AND IsActive = 1), 0) AS ToplamKullanilanBakiye;
GO

-- ==========================================
-- 3. TETİKLEYİCİLER (TRIGGERS)
-- ==========================================

-- Siparis teslim edildiğinde Restoran Cirosunu artır.
CREATE TRIGGER trg_SiparisTeslimCiroGuncelle
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Durum)
    BEGIN
        UPDATE R
        SET R.ToplamCiro = R.ToplamCiro + i.ToplamTutar
        FROM Restoranlar R
        INNER JOIN inserted i ON R.RestoranID = i.RestoranID
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.Durum = 'Teslim Edildi' AND d.Durum <> 'Teslim Edildi';
    END
END;
GO

-- TRIGGER 2 (Prompt 2): Askıda bir sipariş girildiğinde (IsAskidaSiparis = 1), 
-- AskidaBagislar tablosundaki mevcut miktarı (en eski tarihliden başlayarak) azaltan tetikleyici.
CREATE TRIGGER trg_AskidaSiparisBagisDusur
ON Siparisler
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ToplamTutar DECIMAL(18,2);
    DECLARE @SiparisID INT;
    DECLARE @IsAskida BIT;

    SELECT @SiparisID = SiparisID, @ToplamTutar = ToplamTutar, @IsAskida = IsAskidaSiparis FROM inserted;

    IF @IsAskida = 1
    BEGIN
        -- İlk uygun bağışı bul ve miktarından düş. 
        -- (Mantık: FIFIO - İlk Giren İlk Çıkar bağışları tüketir)
        -- Not: Basitlik adına tek bir bağıştan düştüğünü varsayıyoruz. 
        -- Gerçek senaryoda döngü ile birden fazla bağış satırı tüketilebilir.
        UPDATE TOP (1) AskidaBagislar
        SET Miktar = Miktar - @ToplamTutar
        WHERE IsActive = 1 AND BagisTuru = 'Bakiye' AND Miktar >= @ToplamTutar;
    END
END;
GO

-- ==========================================
-- 4. İNDEKSLEME (INDEXING)
-- ==========================================

CREATE NONCLUSTERED INDEX IX_Siparisler_Tarih ON Siparisler(SiparisTarihi DESC);
CREATE NONCLUSTERED INDEX IX_Restoranlar_Puan ON Restoranlar(IsActive, Puan DESC);
CREATE NONCLUSTERED INDEX IX_Urunler_Fiyat ON Urunler(Fiyat ASC);

-- Prompt 2: Explicit Indexes
CREATE NONCLUSTERED INDEX IX_Kullanicilar_Eposta ON Kullanicilar(Eposta);
-- SiparisTarihi zaten yukarida (IX_Siparisler_Tarih) olarak eklendi.
GO

-- ==========================================
-- 5. MOCK DATA (DML - ÖRNEK VERİLER)
-- ==========================================

-- KULLANICILAR (Müşteri, Kurye, Sahip rolleri bir arada)
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, SifreHash, Rol) VALUES 
('Ali', 'Korkmaz', 'ali@musteri.com', '5551000001', 'hash', 'Müşteri'),
('Veli', 'Yılmaz', 'veli@musteri.com', '5551000002', 'hash', 'Müşteri'),
('Ahmet', 'Çelik', 'ahmet@kurye.com', '5552000001', 'hash', 'Kurye'),
('Ayşe', 'Demir', 'ayse@kurye.com', '5552000002', 'hash', 'Kurye'),
('Mehmet', 'Usta', 'mehmet@restoran.com', '5553000001', 'hash', 'Restoran Sahibi'),
('Fatma', 'Chef', 'fatma@restoran.com', '5553000002', 'hash', 'Restoran Sahibi');

-- KURYELER
INSERT INTO Kuryeler (KullaniciID, AracTipi, Plaka) VALUES
(3, 'Motorsiklet', '34 ABC 123'),
(4, 'Bisiklet', 'YOK');

-- RESTORANLAR
INSERT INTO Restoranlar (KullaniciID, RestoranAdi, Adres, Puan) VALUES 
(5, 'Burger King', 'Beşiktaş, İstanbul', 4.7),
(5, 'McDonalds', 'Şişli, İstanbul', 3.2),
(6, 'Kebapçı Celal', 'Kadıköy, İstanbul', 4.5),
(6, 'Domino''s Pizza', 'Üsküdar, İstanbul', 4.1);

-- MENULER VE ÜRÜNLER (Mock Data 15 Adet)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES 
(1, 'Burgerler'), (1, 'İçecekler'),
(2, 'Menüler'), (3, 'Kebaplar'), (4, 'Pizzalar');

INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(1, 'Whopper', 250.00), (1, 'Big King', 220.00), (1, 'Chicken Royale', 200.00),
(2, 'Kola (Kutu)', 45.00), (2, 'Ayran', 35.00),
(3, 'Big Mac Menü', 240.00), (3, 'McChicken Menü', 210.00),
(4, 'Adana Dürüm', 180.00), (4, 'Urfa Kebap', 200.00), (4, 'İskender', 350.00),
(5, 'Karışık Pizza', 280.00), (5, 'Margarita', 250.00), (5, 'Sucuksever', 270.00);

-- ASKİDA BAGIŞLAR (Müşteriler havuzu besliyor)
INSERT INTO AskidaBagislar (KullaniciID, BagisTuru, Miktar) VALUES 
(1, 'Bakiye', 500.00),
(NULL, 'Bakiye', 1000.00),  -- Anonim bağış
(2, 'Urun', 200.00); -- Ürün bağışı örneği

-- SİPARİŞLER & SİPARİŞ DETAYLARI
INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, IsAskidaSiparis)
VALUES 
(1, 1, 1, 295.00, 'Teslim Edildi', 0),
(2, 4, 2, 280.00, 'Teslim Edildi', 0),
(1, 3, 1, 350.00, 'Yolda', 0);

INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat)
VALUES
(1, 1, 1, 250.00), (1, 4, 1, 45.00),
(2, 11, 1, 280.00),
(3, 10, 1, 350.00);

-- ASKİDA TALEP (Askıdan yemek isteniyor)
-- Örnek 1: İhtiyaç sahibi Veli'ye (KullaniciID=2) bir askıda sipariş girilmiş.
INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, IsAskidaSiparis)
VALUES (2, 3, 2, 180.00, 'Hazırlanıyor', 1);

INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat)
VALUES (4, 8, 1, 180.00);

INSERT INTO AskidaTalepler (KullaniciID, SiparisID, Durum) VALUES (2, 4, 'Onaylandi');

-- HAVUZ BAŞLANGIÇ DEĞERİ
INSERT INTO AskidaHavuz (GuncelBakiye) VALUES (1500.00); -- Mock bagislardan gelen toplam
GO

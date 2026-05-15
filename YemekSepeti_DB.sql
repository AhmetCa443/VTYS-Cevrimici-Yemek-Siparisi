

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
            VALUES (@Mid, @Rid, @KuId, @Fiyat, 'Bekliyor

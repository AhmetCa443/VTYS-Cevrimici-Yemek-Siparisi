-- ==========================================
-- ADIM 2: SAKLI YORDAMLAR, FONKSİYONLAR VE GELİŞMİŞ MANTIK
-- ==========================================
USE YemekSepetiDB;
GO

-- 1. SCALAR FUNCTION: Bir kullanıcının toplam bağış miktarını döndürür.
CREATE OR ALTER FUNCTION fn_KullaniciToplamBagis (@KullaniciID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Toplam DECIMAL(18,2);
    SELECT @Toplam = ISNULL(SUM(Miktar), 0) FROM AskidaBagislar 
    WHERE KullaniciID = @KullaniciID AND IsActive = 1;
    RETURN @Toplam;
END;
GO

-- 2. TRIGGER: Sipariş durum değişimlerini SiparisGecmisi tablosuna loglar.
CREATE OR ALTER TRIGGER trg_SiparisDurumLog
ON Siparisler
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Durum)
    BEGIN
        INSERT INTO SiparisGecmisi (SiparisID, EskiDurum, YeniDurum)
        SELECT i.SiparisID, d.Durum, i.Durum
        FROM inserted i
        INNER JOIN deleted d ON i.SiparisID = d.SiparisID
        WHERE i.Durum <> d.Durum;
        
        -- Eğer Teslim Edildi olduysa ciro güncelleme tetiklenir (YemekSepeti_DB.sql'deki trg_SiparisTeslimCiroGuncelle)
    END
END;
GO

-- 3. STORED PROCEDURE: Bağış Yapma İşlemi (Havuz Bakiyesini Otomatik Günceller)
CREATE OR ALTER PROCEDURE sp_BagisYap
    @KullaniciID INT = NULL, -- NULL ise Anonim
    @BagisTuru NVARCHAR(20) = 'Bakiye',
    @Miktar DECIMAL(18,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            -- 3.1. Bağışı kaydet
            INSERT INTO AskidaBagislar (KullaniciID, BagisTuru, Miktar)
            VALUES (@KullaniciID, @BagisTuru, @Miktar);
            
            -- 3.2. Havuz bakiyesini güncelle (Sadece Bakiye bağışıysa havuz artar)
            IF @BagisTuru = 'Bakiye'
            BEGIN
                UPDATE AskidaHavuz 
                SET GuncelBakiye = GuncelBakiye + @Miktar, 
                    SonGuncelleme = GETDATE()
                WHERE HavuzID = 1; -- Varsayılan küresel havuz
            END
            
            COMMIT TRANSACTION
            PRINT 'Bağış işlemi başarıyla tamamlandı.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4. STORED PROCEDURE: Askıdan Yemek Siparişi Verme (Bakiye Kontrollü)
CREATE OR ALTER PROCEDURE sp_AskidaSiparisVer
    @MusteriID INT,
    @RestoranID INT,
    @KuryeID INT,
    @UrunID INT,
    @Miktar INT = 1
AS
BEGIN
    DECLARE @UrunFiyat DECIMAL(10,2);
    DECLARE @ToplamTutar DECIMAL(18,2);
    DECLARE @MevcutHavuzBakiye DECIMAL(18,2);
    
    -- 4.1. Ürün fiyatını al
    SELECT @UrunFiyat = Fiyat FROM Urunler WHERE UrunID = @UrunID;
    SET @ToplamTutar = @UrunFiyat * @Miktar;
    
    -- 4.2. Havuz bakiyesini kontrol et
    SELECT @MevcutHavuzBakiye = GuncelBakiye FROM AskidaHavuz WHERE HavuzID = 1;
    
    IF @MevcutHavuzBakiye < @ToplamTutar
    BEGIN
        RAISERROR('Hata: Askıda havuz bakiyesi bu sipariş için yetersiz.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION
            -- 4.3. Siparişi oluştur
            DECLARE @YeniSiparisID INT;
            INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, IsAskidaSiparis)
            VALUES (@MusteriID, @RestoranID, @KuryeID, @ToplamTutar, 'Bekliyor', 1);
            
            SET @YeniSiparisID = SCOPE_IDENTITY();
            
            -- 4.4. Sipariş detayını ekle
            INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat)
            VALUES (@YeniSiparisID, @UrunID, @Miktar, @UrunFiyat);
            
            -- 4.5. Talep kaydını oluştur
            INSERT INTO AskidaTalepler (KullaniciID, SiparisID, Durum)
            VALUES (@MusteriID, @YeniSiparisID, 'Onaylandi');
            
            -- 4.6. Havuz bakiyesini düşür
            UPDATE AskidaHavuz 
            SET GuncelBakiye = GuncelBakiye - @ToplamTutar,
                SonGuncelleme = GETDATE()
            WHERE HavuzID = 1;
            
            COMMIT TRANSACTION
            PRINT 'Askıda sipariş başarıyla oluşturuldu.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5. STORED PROCEDURE: Restoran Performans Raporu
CREATE OR ALTER PROCEDURE sp_RestoranRaporu
    @RestoranID INT
AS
BEGIN
    SELECT 
        R.RestoranAdi,
        R.Puan AS BasariPuani,
        R.ToplamCiro,
        (SELECT COUNT(*) FROM Siparisler WHERE RestoranID = R.RestoranID) AS ToplamSiparisSayisi,
        (SELECT COUNT(*) FROM Siparisler WHERE RestoranID = R.RestoranID AND IsAskidaSiparis = 1) AS AskidaSiparisSayisi,
        (SELECT COUNT(*) FROM Menuler WHERE RestoranID = R.RestoranID) AS KategoriSayisi
    FROM Restoranlar R
    WHERE R.RestoranID = @RestoranID;
END;
GO

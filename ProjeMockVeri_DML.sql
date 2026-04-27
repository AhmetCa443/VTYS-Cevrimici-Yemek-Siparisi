-- ==========================================
-- ADIM 3: GERÇEKÇİ MOCK DATA (DML)
-- ==========================================
USE YemekSepetiDB;
GO

-- 1. TEMİZLİK (İlişkili verileri ters sırada siliyoruz)
DELETE FROM AskidaTalepler;
DELETE FROM SiparisDetaylari;
DELETE FROM SiparisGecmisi;
DELETE FROM Siparisler;
DELETE FROM AskidaBagislar;
DELETE FROM Urunler;
DELETE FROM Menuler;
DELETE FROM Restoranlar;
DELETE FROM Kuryeler;
DELETE FROM AskidaHavuz;
DELETE FROM Kullanicilar;

-- Identity değerlerini sıfırla (İsteğe bağlı, temiz bir başlangıç için)
DBCC CHECKIDENT ('Kullanicilar', RESEED, 0);
DBCC CHECKIDENT ('Kuryeler', RESEED, 0);
DBCC CHECKIDENT ('Restoranlar', RESEED, 0);
DBCC CHECKIDENT ('Menuler', RESEED, 0);
DBCC CHECKIDENT ('Urunler', RESEED, 0);
DBCC CHECKIDENT ('Siparisler', RESEED, 0);
DBCC CHECKIDENT ('AskidaBagislar', RESEED, 0);
DBCC CHECKIDENT ('AskidaHavuz', RESEED, 0);
GO

-- 2. KULLANICILAR (30 Kayıt: 20 Müşteri, 5 Kurye, 5 Restoran Sahibi)
-- 20 Müşteri
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, SifreHash, Rol) VALUES 
('Ahmet', 'Yıldız', 'ahmet.yildiz@mail.com', '5551010101', 'hash123', 'Müşteri'),
('Burcu', 'Öztürk', 'burcu.ozturk@mail.com', '5551010102', 'hash123', 'Müşteri'),
('Can', 'Aksoy', 'can.aksoy@mail.com', '5551010103', 'hash123', 'Müşteri'),
('Deniz', 'Tekin', 'deniz.tekin@mail.com', '5551010104', 'hash123', 'Müşteri'),
('Ece', 'Güneş', 'ece.gunes@mail.com', '5551010105', 'hash123', 'Müşteri'),
('Fatih', 'Bulut', 'fatih.bulut@mail.com', '5551010106', 'hash123', 'Müşteri'),
('Gamze', 'Arslan', 'gamze.arslan@mail.com', '5551010107', 'hash123', 'Müşteri'),
('Hakan', 'Kılıç', 'hakan.kilic@mail.com', '5551010108', 'hash123', 'Müşteri'),
('Işıl', 'Koç', 'isil.koc@mail.com', '5551010109', 'hash123', 'Müşteri'),
('Jale', 'Eren', 'jale.eren@mail.com', '5551010110', 'hash123', 'Müşteri'),
('Kemal', 'Demir', 'kemal.demir@mail.com', '5551010111', 'hash123', 'Müşteri'),
('Lale', 'Gül', 'lale.gul@mail.com', '5551010112', 'hash123', 'Müşteri'),
('Murat', 'Can', 'murat.can@mail.com', '5551010113', 'hash123', 'Müşteri'),
('Nalan', 'Soylu', 'nalan.soylu@mail.com', '5551010114', 'hash123', 'Müşteri'),
('Oktay', 'Kurt', 'oktay.kurt@mail.com', '5551010115', 'hash123', 'Müşteri'),
('Pelin', 'Şahin', 'pelin.sahin@mail.com', '5551010116', 'hash123', 'Müşteri'),
('Rıza', 'Aydın', 'riza.aydin@mail.com', '5551010117', 'hash123', 'Müşteri'),
('Selin', 'Aktaş', 'selin.aktas@mail.com', '5551010118', 'hash123', 'Müşteri'),
('Tarık', 'Engin', 'tarik.engin@mail.com', '5551010119', 'hash123', 'Müşteri'),
('Umut', 'Yılmaz', 'umut.yilmaz@mail.com', '5551010120', 'hash123', 'Müşteri');

-- 5 Kurye (ID: 21-25)
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, SifreHash, Rol) VALUES 
('Kurye1', 'Hızlı', 'kurye1@yemek.com', '5552020201', 'kurye_hash', 'Kurye'),
('Kurye2', 'Pratik', 'kurye2@yemek.com', '5552020202', 'kurye_hash', 'Kurye'),
('Kurye3', 'Çevik', 'kurye3@yemek.com', '5552020203', 'kurye_hash', 'Kurye'),
('Kurye4', 'Atik', 'kurye4@yemek.com', '5552020204', 'kurye_hash', 'Kurye'),
('Kurye5', 'Dakik', 'kurye5@yemek.com', '5552020205', 'kurye_hash', 'Kurye');

-- 5 Restoran Sahibi (ID: 26-30)
INSERT INTO Kullanicilar (Ad, Soyad, Eposta, Telefon, SifreHash, Rol) VALUES 
('Sahip1', 'Kebap', 'kebap@owner.com', '5553030301', 'owner_hash', 'Restoran Sahibi'),
('Sahip2', 'Pizza', 'pizza@owner.com', '5553030302', 'owner_hash', 'Restoran Sahibi'),
('Sahip3', 'Burger', 'burger@owner.com', '5553030303', 'owner_hash', 'Restoran Sahibi'),
('Sahip4', 'Sushi', 'sushi@owner.com', '5553030304', 'owner_hash', 'Restoran Sahibi'),
('Sahip5', 'Tatlı', 'tatli@owner.com', '5553030305', 'owner_hash', 'Restoran Sahibi');

-- 3. KURYELER DETAY
INSERT INTO Kuryeler (KullaniciID, AracTipi, Plaka) VALUES
(21, 'Motorsiklet', '34 KRY 01'),
(22, 'Motorsiklet', '06 KRY 02'),
(23, 'Bisiklet', 'YOK-03'),
(24, 'Scooter', 'YOK-04'),
(25, 'Motorsiklet', '35 KRY 05');

-- 4. RESTORANLAR (5 Farklı Mutfak)
INSERT INTO Restoranlar (KullaniciID, RestoranAdi, Adres, Puan) VALUES 
(26, 'Anadolu Lezzetleri', 'Kadıköy, İstanbul', 4.8),  -- Kebab
(27, 'Little Italy', 'Beşiktaş, İstanbul', 4.5),      -- Pizza
(28, 'Burger Station', 'Şişli, İstanbul', 4.2),      -- Burger
(29, 'Tokyo Express', 'Kadıköy, İstanbul', 4.7),      -- Asian
(30, 'Şekerci Mehmet', 'Eminönü, İstanbul', 4.9);      -- Dessert

-- 5. MENULER VE ÜRÜNLER (50 Ürün)
-- Restoran 1: Anadolu Lezzetleri (ID: 1)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES (1, 'Kebaplar'), (1, 'Dürümler'), (1, 'Mezeler');
INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(1, 'Adana Kebap', 240.00), (1, 'Urfa Kebap', 230.00), (1, 'İskender', 360.00), (1, 'Beyti', 320.00),
(2, 'Adana Dürüm', 160.00), (2, 'Tavuk Dürüm', 130.00), (2, 'Ciğer Dürüm', 180.00),
(3, 'Haydari', 60.00), (3, 'Humus', 65.00), (3, 'Acılı Ezme', 55.00);

-- Restoran 2: Little Italy (ID: 2)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES (2, 'Pizzalar'), (2, 'Makarnalar');
INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(4, 'Margarita Pizza', 200.00), (4, 'Karışık Pizza', 280.00), (4, 'Pepperoni Pizza', 310.00), (4, 'Dört Peynirli', 330.00), (4, 'Vejetaryen Pizza', 260.00),
(5, 'Spaghetti Carbonara', 220.00), (5, 'Penne Arrabbiata', 190.00), (5, 'Fettuccine Alfredo', 240.00), (5, 'Lazanya', 350.00), (5, 'Mantı (İtalyan)', 210.00);

-- Restoran 3: Burger Station (ID: 3)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES (3, 'Burgerler'), (3, 'Yan Ürünler');
INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(6, 'Classic Burger', 180.00), (6, 'Cheeseburger', 210.00), (6, 'Bacon Burger', 260.00), (6, 'Texas BBQ Burger', 280.00), (6, 'Mushroom Burger', 250.00),
(7, 'Patates Kızartması', 60.00), (7, 'Soğan Halkası', 65.00), (7, 'Nugget 6lı', 80.00), (7, 'Cheddar Soslu Patates', 95.00), (7, 'Çıtır Tavuk', 120.00);

-- Restoran 4: Tokyo Express (ID: 4)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES (4, 'Sushi'), (4, 'Noodles');
INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(8, 'California Roll', 220.00), (8, 'Philadelphia Roll', 250.00), (8, 'Sake Maki', 180.00), (8, 'Ebi Tempura Roll', 280.00), (8, 'Dragon Roll', 320.00),
(9, 'Sebzeli Noodle', 160.00), (9, 'Tavuklu Noodle', 190.00), (9, 'Etli Noodle', 240.00), (9, 'Karidesli Noodle', 270.00), (9, 'Acılı Noodle', 170.00);

-- Restoran 5: Şekerci Mehmet (ID: 5)
INSERT INTO Menuler (RestoranID, KategoriAdi) VALUES (5, 'Geleneksel Tatlılar'), (5, 'Sütlü Tatlılar');
INSERT INTO Urunler (MenuID, UrunAdi, Fiyat) VALUES 
(10, 'Fıstıklı Baklava', 380.00), (10, 'Künefe', 160.00), (10, 'Katmer', 180.00), (10, 'Şekerpare', 90.00), (10, 'Tulumba', 80.00),
(11, 'Sütlaç', 85.00), (11, 'Kazandibi', 95.00), (11, 'Tavuk Göğsü', 95.00), (11, 'Keşkül', 90.00), (11, 'Profiterol', 110.00);

-- "Soft Delete" Testi için 2 pasif ürün
UPDATE Urunler SET IsActive = 0 WHERE UrunID IN (5, 15);
GO

-- 6. ASKIDA YEMEK HAVUZU VE BAĞIŞLAR (12 Bağış)
INSERT INTO AskidaHavuz (GuncelBakiye) VALUES (0.00); -- Başlangıç sıfır

INSERT INTO AskidaBagislar (KullaniciID, BagisTuru, Miktar) VALUES 
(1, 'Bakiye', 500.00), (2, 'Bakiye', 1000.00), (NULL, 'Bakiye', 2000.00),
(3, 'Bakiye', 250.00), (4, 'Bakiye', 300.00), (NULL, 'Bakiye', 1500.00),
(5, 'Bakiye', 100.00), (6, 'Bakiye', 400.00), (7, 'Bakiye', 600.00),
(NULL, 'Bakiye', 1000.00), (8, 'Bakiye', 500.00), (9, 'Bakiye', 300.00);

-- Havuzu manuel senkronize edelim (Trigger var ama toplu ins'de tetiklenmesi için)
UPDATE AskidaHavuz SET GuncelBakiye = (SELECT SUM(Miktar) FROM AskidaBagislar WHERE IsActive=1) WHERE HavuzID = 1;
GO

-- 7. SİPARİŞLER (100+ Kayıt)
-- Batch 1: Normal Siparişler (40 adet)
DECLARE @cnt INT = 1;
WHILE @cnt <= 40
BEGIN
    INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, SiparisTarihi, IsAskidaSiparis)
    VALUES (
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 20) + 1,
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 5) + 1,
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 5) + 1,
        200.00 + (@cnt * 2), 
        CASE WHEN @cnt % 8 = 0 THEN 'İptal' ELSE 'Teslim Edildi' END, 
        DATEADD(HOUR, -@cnt, GETDATE()), 0);
    INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat)
    VALUES (SCOPE_IDENTITY(), (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 50) + 1, 1, 200.00 + (@cnt * 2));
    SET @cnt = @cnt + 1;
END;
GO

-- Batch 2: Normal Siparişler (40 adet)
DECLARE @cnt INT = 1;
WHILE @cnt <= 40
BEGIN
    INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, SiparisTarihi, IsAskidaSiparis)
    VALUES (
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 20) + 1,
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 5) + 1,
        (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 5) + 1,
        150.00 + (@cnt * 3), 
        'Teslim Edildi', 
        DATEADD(DAY, -(@cnt % 15), GETDATE()), 0);
    INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat)
    VALUES (SCOPE_IDENTITY(), (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 50) + 1, 1, 150.00 + (@cnt * 3));
    SET @cnt = @cnt + 1;
END;
GO

-- Batch 3: Askıda Siparişler (20 adet)
DECLARE @cnt INT = 1;
WHILE @cnt <= 20
BEGIN
    DECLARE @UrunID INT = (ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 50) + 1;
    DECLARE @Fiyat DECIMAL(10,2) = 150.00;
    
    INSERT INTO Siparisler (KullaniciID, RestoranID, KuryeID, ToplamTutar, Durum, IsAskidaSiparis)
    VALUES ((ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 20) + 1, 1, 1, @Fiyat, 'Bekliyor', 1);
    
    DECLARE @Sid INT = SCOPE_IDENTITY();
    INSERT INTO SiparisDetaylari (SiparisID, UrunID, Miktar, BirimFiyat) VALUES (@Sid, @UrunID, 1, @Fiyat);
    INSERT INTO AskidaTalepler (KullaniciID, SiparisID, Durum) VALUES ((ABS(CAST(CAST(NEWID() AS BINARY(4)) AS INT)) % 20) + 1, @Sid, 'Onaylandi');
    SET @cnt = @cnt + 1;
END;
GO

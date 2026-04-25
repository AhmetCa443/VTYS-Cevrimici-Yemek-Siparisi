# VTYS-1 Projesi: İş Kuralları ve Sistem Mantığı

Bu belge, Çevrimiçi Yemek Sipariş Platformu'nun çalışacağı iş kurallarını (Business Rules) ve "Askıda Yemek" modülünün mantıksal tasarımını detaylandırmaktadır.

## Temel Varlıklar ve İş Kuralları

1. **Müşteriler (`Musteriler`)**
   - Müşteriler sisteme Ad, Soyad, E-posta ve Şifre ile kayıt olurlar. E-posta adresi benzersiz (UNIQUE) ve zorunlu (NOT NULL) olmalıdır. Ayrıca her müşterinin telefon numarası benzersiz olmalıdır.
   - İhtiyaç sahibi olarak doğrulanmış müşteriler (`IhtiyacSahibiMi = 1`), Askıda Yemek havuzundaki bakiyeyi kullanarak ücretsiz sipariş verebilirler.
   - Müşteriler fiziksel olarak silinmez, bunun yerine `AktifMi = 0` şeklinde pasife alınır (Soft Delete).

2. **Restoranlar (`Restoranlar`)**
   - Sistemde birden fazla restoran bulunabilir ve her restoranın bir adı (NOT NULL), adresi ve başarı puanı vardır. Puan 1 ile 5 arasında olmalıdır (CHECK Constraint).
   - Siparişler teslim edildiğinde, restoranın kazancını takip edebilmek için her restoranın bir `ToplamCiro` kaydedilir.
   - Restoranlar silindiğinde pasife alınır (`AktifMi = 0`).

3. **Menü Kategorileri ve Ürünler (`MenuKategorileri` & `MenuUrunleri`)**
   - Her restoranın kendine ait kategorileri ve ürünleri bulunur. Ürün fiyatı sıfırdan büyük olmalıdır (`Fiyat > 0`).
   - Bir ürün silindiğinde pasife alınır (Soft Delete).

4. **Kuryeler (`Kuryeler`)**
   - Sistemdeki teslimat süreçlerini yönetmek için kuryeler sisteme kaydedilir. Kuryelerin telefon numaraları benzersizdir.

5. **Siparişler (`Siparisler` & `SiparisDetaylari`)**
   - Bir sipariş tek bir müşteriye, tek bir restorana ve tek bir kuryeye aittir.
   - Siparişin bir durumu (`SiparisDurumu`: 'Bekliyor', 'Hazirlaniyor', 'Teslimatta', 'Teslim Edildi', 'Iptal Edildi') bulunur.
   - Siparişin toplam tutarı sıfır veya sıfırdan büyük olmalıdır (`ToplamTutar >= 0`). Eğer tamamen Askıda Havuz'dan karşılandıysa bu tutar 0 olabilir.
   - Sipariş detaylarında istenen ürünün miktarı ve satır birim fiyatı 0'dan büyük olmalıdır (`Miktar > 0`, `BirimFiyat > 0`).

## ÖZEL MODÜL: "Askıda Yemek" Mantığı

### Amaç ve Kapsam
Askıda Yemek modülü, iyiliksever insanların kimliklerini belli ederek veya anonim kalarak bir "İyilik Havuzu"na bakiye veya yemek bedeli bağışlamasını; ardından ihtiyaç sahibi olarak doğrulanmış kişilerin bu havuzdan yemek siparişi verebilmesini sağlayan sosyal bir sistemdir.

### Tablo Tasarımları

1. **`AskidaBagislari` (Askıda Bağışları Tablosu):**
   - Bu tablo, platformda müşterilerin yaptığı tüm maddi bağışları kayıt altına alır.
   - **Alanlar:** `BagisID`, `MusteriID` (NULL olabilir - Anonim), `AnonimMi`, `Miktar`, `BagisTarihi`.
   - Bağış miktarı kesinlikle `> 0` olmalıdır. Müşteri anonim olmak istemiyorsa `MusteriID` dolar ve sistemde bağışçı olarak bilinir.

2. **`AskidaHavuz` (Havuz Tablosu):**
   - Sistemin çekirdek hesap yönetim tablosudur. Yapılan tüm bağışların biriktiği ve harcandığı bakiye burada tutulur.
   - Tek bir satırdan oluşan genel sistem havuzu veya şehir/ilçe bazlı alt havuzlar için listelemedir (Bizim sistemimizde tek satırlı global bir havuz tasarlanmıştır).
   - **Alanlar:** `HavuzID` (PK, Identity = 1), `GuncelBakiye` (GuncelBakiye >= 0).

3. **`AskidaKullanimlari` (Kullanım Hareketleri):**
   - Askıda havuzdan faydalanan işlemlerin finansal kayıtlarını tutar.
   - İhtiyaç sahibi (`IhtiyacSahibiMi = 1`) bir sipariş verdiğinde bu tabloya kullanım miktarı girilir.
   - **Alanlar:** `KullanimID`, `SiparisID`, `MusteriID`, `KullanilanMiktar`, `KullanimTarihi`.

### Çalışma Mantığı (Senaryo)
1. **Bağış Süreci:** Müşteri 100 TL'lik bir öğün bağışı yaptı diyelim. `AskidaBagislari` tablosuna INSERT yapılır. Bu tabloda bir INSERT gerçekleştiğinde, **bir Trigger** devreye girer ve `AskidaHavuz` tablosundaki `GuncelBakiye` miktarını 100 TL artırır.
2. **Sipariş Verme:** Sisteme giren doğrulanmış bir üniversite öğrencisi veya ihtiyaç sahibi (`IhtiyacSahibiMi = 1`), sepete ürün ekler. Ödeme ekranında "Askıda Yemek Havuzunu Kullan" seçeneğine (sistemde `AskidaSiparisMi = 1`) tıklar.
3. **Bakiye Düşümü ve İşlem:** Sipariş onaylandığında (Trigger Devreye Girer):
   - Öncelikle `Siparisler` tablosunda işlem oluşturulur. Ancak `ToplamTutar` mazeretten veya özel bir indirim satırından ötürü havuzdan karşılanan kısmı silinerek 0'lanır veya hesaba aktarılır.
   - Bir **Tetikleyici (Trigger)**, havuzdaki (`AskidaHavuz`) mevcut bakiyenin bu tutarı karşılayıp karşılayamayacağını kontrol eder. Bakiye yeterliyse sipariş kabul edilir.
   - `AskidaHavuz` tablosundaki bakiye, sipariş tutarı kadar düşürülür (Trigger).
   - Bu hareket, şeffaflık adına `AskidaKullanimlari` tablosuna (Kim, Hangi Siparişte, Kaç TL Kullandı) INSERT edilir.
4. **Ciro Aktarımı:** Sipariş Kurye tarafından "Teslim Edildi" statüsüne (`SiparisDurumu = 'Teslim Edildi'`) alındığında, havuzdaki para restoran cirosuna eklenmelidir ki restoran hak edişini alsın (Başka bir Trigger).

Bu modül, veritabanında Referans Bütünlüğünün korunmasını sağlamakla kalmaz; aynı zamanda Triggers, Views ve Constraint yeteneklerini en gelişmiş seviyede sergiler.

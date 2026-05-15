# Yapay Zeka (AI) Kullanım Beyanı ve Dürüstlük Raporu

**Proje Adı:** VTYS-1 Dönem Projesi: Çevrimiçi Yemek Sipariş Platformu Veritabanı Tasarımı ("Askıda Yemek" Modüllü)

Bu rapor, projenin geliştirme sürecinde yapay zeka asistanlarından ne aşamada, nasıl ve hangi oranda faydalanıldığını şeffaf bir şekilde beyan etmektedir.

## AI Kullanım Alanları ve Amacı

1. **Tablo İlişkileri ve İş Kurallarının Beyin Fırtınası:**
   Özel "Askıda Yemek" modülünün mantıksal zeminini hazırlarken senaryo üzerinden fikir alışverişi yapıldı. Havuz bakiyesinin tutulma şekli ve Trigger'lar üzerinden bu havuzdan bakiyenin nasıl otomatik düşeceği konusunda AI destekli senaryo testleri yapıldı.

2. **Gelişmiş Nesneler (Triggers & Views):**
   Karmaşık T-SQL syntax yapısına uygun olarak `AskidaPool` ve `Orders` tabloları arasında asenkron bakiye ve ciro güncellemeleri yapan Trigger'lar yazılırken, "RAISERROR" denetimlerinin ve "ROLLBACK TRANSACTION" sistemlerinin doğru konumlandırılması amacıyla AI denetimi sağlandı.

3. **Veri Üretme (Mock Data) Süreçlerinin Otomasyonu:**
   Yönergede istenen 100 sipariş, 50 alt ürün gibi veri yoğunluğu gerektiren işlemleri tek tek elle girmek (INSERT INTO) yerine, T-SQL içindeki `WHILE` döngüleri ve `NEWID()` tabanlı rastgele veri dağıtım algoritmaları AI'dan yardım alınarak kurgulandı ve sisteme başarıyla entegre edildi. 

4. **Kardinalite ve ER Diyagramı Standartları:**
   Mermaid formatında yazılan diyagramın kodsal doğruluğu sağlandı. Hangi tabloların birbiriyle Parent-Child (1:N, M:N) ilişkisinde olduğu tasarlandıktan sonra, diyagram kodlama aşaması otomatize edildi.

## Hakimiyet ve Sonuç Beyanı
Ortaya çıkan sistemin tamamı (Primary Key, Foreign Key kurguları, Constraints, Subquery yapıları) adım adım tarafımca okunmuş, incelenmiş ve test edilmiştir. Hazırladığım ER diyagramındaki hangi tablonun neden kullanıldığını, Askıda Yemek Modülü'nün `AskidaDonations` (Bağış), `AskidaPool` (Havuz) ve `AskidaUsages` (Kullanım) ayakları arasındaki veri akışını tamamen kavramış bulunmaktayım. Tahtaya çıkmam durumunda her kodu savunabileceğimi beyan ederim.

---
*(Öğrenci Adı - Soyadı / İmza)*

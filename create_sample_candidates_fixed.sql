-- Önce auth.users tablosuna kayıtları ekle (Supabase auth sistemi için)
-- Sonra user_profiles tablosuna detaylı bilgileri ekle

-- 20 adet örnek aday kullanıcı oluştur
INSERT INTO user_profiles (
  email,
  full_name,
  role,
  age,
  gender,
  bio,
  interests,
  location,
  profession,
  image_url,
  phone,
  is_active,
  is_verified,
  created_at,
  updated_at,
  preferred_age_min,
  preferred_age_max,
  preferred_cities,
  preferred_interests,
  preferred_genders
) VALUES 
-- Kadın adaylar
('ayse.demir@email.com', 'Ayşe Demir', 'candidate', 25, 'female', 'Kitap okumayı ve müzik dinlemeyi seven, pozitif enerjili bir kişiyim.', ARRAY['Kitap', 'Müzik', 'Yürüyüş'], 'İstanbul', 'Öğretmen', 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400', '+90555123001', true, true, NOW(), NOW(), 23, 30, ARRAY['İstanbul', 'Ankara'], ARRAY['Kitap', 'Müzik'], ARRAY['male']),

('elif.kaya@email.com', 'Elif Kaya', 'candidate', 27, 'female', 'Sanatla ilgili her şeyi seven, yaratıcı ruha sahip biriyim.', ARRAY['Sanat', 'Resim', 'Sinema'], 'Ankara', 'Grafik Tasarımcı', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', '+90555123002', true, true, NOW(), NOW(), 25, 32, ARRAY['Ankara', 'İzmir'], ARRAY['Sanat', 'Sinema'], ARRAY['male']),

('fatma.ozturk@email.com', 'Fatma Öztürk', 'candidate', 24, 'female', 'Doğa yürüyüşlerini seven, aktif yaşam tarzına sahip biriyim.', ARRAY['Doğa', 'Yürüyüş', 'Fotoğrafçılık'], 'İzmir', 'Hemşire', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400', '+90555123003', true, true, NOW(), NOW(), 22, 28, ARRAY['İzmir', 'Antalya'], ARRAY['Doğa', 'Spor'], ARRAY['male']),

('zeynep.yilmaz@email.com', 'Zeynep Yılmaz', 'candidate', 26, 'female', 'Teknoloji ve yazılım dünyasına meraklı, sürekli öğrenmeyi seven biriyim.', ARRAY['Teknoloji', 'Yazılım', 'Kitap'], 'İstanbul', 'Yazılım Geliştirici', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', '+90555123004', true, true, NOW(), NOW(), 24, 30, ARRAY['İstanbul', 'Bursa'], ARRAY['Teknoloji', 'Kitab'], ARRAY['male']),

('merve.celik@email.com', 'Merve Çelik', 'candidate', 28, 'female', 'Mutfak sanatlarını seven, yemek yapmayı hobi edinmiş biriyim.', ARRAY['Yemek', 'Mutfak', 'Seyahat'], 'Bursa', 'Pazarlama Uzmanı', 'https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=400', '+90555123005', true, true, NOW(), NOW(), 26, 33, ARRAY['Bursa', 'İstanbul'], ARRAY['Yemek', 'Seyahat'], ARRAY['male']),

('seda.arslan@email.com', 'Seda Arslan', 'candidate', 23, 'female', 'Müzik ve dans etmeyi seven, enerjik ve sosyal biriyim.', ARRAY['Müzik', 'Dans', 'Sosyal'], 'Antalya', 'Müzik Öğretmeni', 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400', '+90555123006', true, true, NOW(), NOW(), 21, 27, ARRAY['Antalya', 'Muğla'], ARRAY['Müzik', 'Dans'], ARRAY['male']),

('gamze.kurt@email.com', 'Gamze Kurt', 'candidate', 29, 'female', 'Spor yapmayı seven, sağlıklı yaşam tarzını benimseyen biriyim.', ARRAY['Spor', 'Fitness', 'Yoga'], 'İzmir', 'Fizyoterapist', 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400', '+90555123007', true, true, NOW(), NOW(), 27, 34, ARRAY['İzmir', 'Ankara'], ARRAY['Spor', 'Sağlık'], ARRAY['male']),

('esra.duran@email.com', 'Esra Duran', 'candidate', 25, 'female', 'Film izlemeyi ve kitap okumayı seven, sakin karakterli biriyim.', ARRAY['Film', 'Kitap', 'Kafe'], 'Ankara', 'Kütüphaneci', 'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=400', '+90555123008', true, true, NOW(), NOW(), 23, 29, ARRAY['Ankara', 'Konya'], ARRAY['Film', 'Kitap'], ARRAY['male']),

('nihan.aydin@email.com', 'Nihan Aydın', 'candidate', 30, 'female', 'Seyahat etmeyi ve yeni kültürler keşfetmeyi seven macera tutkunu.', ARRAY['Seyahat', 'Kültür', 'Fotoğraf'], 'İstanbul', 'Turizm Rehberi', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400', '+90555123009', true, true, NOW(), NOW(), 28, 35, ARRAY['İstanbul', 'İzmir'], ARRAY['Seyahat', 'Kültür'], ARRAY['male']),

('cansu.ozkan@email.com', 'Cansu Özkan', 'candidate', 22, 'female', 'Genç ve enerjik, yeni deneyimlere açık, sosyal biriyim.', ARRAY['Sosyal', 'Eğlence', 'Müzik'], 'Bursa', 'Üniversite Öğrencisi', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400', '+90555123010', true, true, NOW(), NOW(), 20, 26, ARRAY['Bursa', 'İstanbul'], ARRAY['Sosyal', 'Müzik'], ARRAY['male']),

-- Erkek adaylar
('mehmet.koc@email.com', 'Mehmet Koç', 'candidate', 28, 'male', 'Spor yapmayı seven, aktif yaşam tarzına sahip mühendisim.', ARRAY['Spor', 'Teknoloji', 'Araştırma'], 'İstanbul', 'Makine Mühendisi', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', '+90555123011', true, true, NOW(), NOW(), 24, 30, ARRAY['İstanbul', 'Kocaeli'], ARRAY['Spor', 'Teknoloji'], ARRAY['female']),

('ali.yavuz@email.com', 'Ali Yavuz', 'candidate', 26, 'male', 'Müzik prodüksiyonu yapan, yaratıcı projeler geliştiren biriyim.', ARRAY['Müzik', 'Prodüksiyon', 'Yaratıcılık'], 'Ankara', 'Müzik Prodüktörü', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400', '+90555123012', true, true, NOW(), NOW(), 23, 28, ARRAY['Ankara', 'İstanbul'], ARRAY['Müzik', 'Sanat'], ARRAY['female']),

('burak.sahin@email.com', 'Burak Şahin', 'candidate', 31, 'male', 'Deneyimli doktor, hasta bakımına özen gösteren, empati kurabilen biriyim.', ARRAY['Tıp', 'Araştırma', 'Okuma'], 'İzmir', 'Doktor', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400', '+90555123013', true, true, NOW(), NOW(), 26, 33, ARRAY['İzmir', 'Ankara'], ARRAY['Bilim', 'Kitap'], ARRAY['female']),

('emre.cetin@email.com', 'Emre Çetin', 'candidate', 24, 'male', 'Grafik tasarım alanında çalışan, sanatsal projeler geliştiren biriyim.', ARRAY['Tasarım', 'Sanat', 'Teknoloji'], 'Bursa', 'Grafik Tasarımcı', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400', '+90555123014', true, true, NOW(), NOW(), 22, 27, ARRAY['Bursa', 'İstanbul'], ARRAY['Sanat', 'Tasarım'], ARRAY['female']),

('onur.bulut@email.com', 'Onur Bulut', 'candidate', 27, 'male', 'Yazılım geliştirme alanında uzman, teknolojiyi yakından takip eden biriyim.', ARRAY['Yazılım', 'Teknoloji', 'Oyun'], 'İstanbul', 'Yazılım Geliştirici', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400', '+90555123015', true, true, NOW(), NOW(), 23, 29, ARRAY['İstanbul', 'Ankara'], ARRAY['Teknoloji', 'Oyun'], ARRAY['female']),

('cem.ayhan@email.com', 'Cem Ayhan', 'candidate', 29, 'male', 'Fitness antrenörü, sağlıklı yaşam koçu, motivasyon uzmanıyım.', ARRAY['Spor', 'Fitness', 'Motivasyon'], 'Antalya', 'Fitness Antrenörü', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400', '+90555123016', true, true, NOW(), NOW(), 25, 32, ARRAY['Antalya', 'İzmir'], ARRAY['Spor', 'Sağlık'], ARRAY['female']),

('deniz.polat@email.com', 'Deniz Polat', 'candidate', 25, 'male', 'Denizcilik ve su sporları tutkunu, macera seven biriyim.', ARRAY['Denizcilik', 'Su Sporları', 'Macera'], 'İzmir', 'Gemi Mühendisi', 'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=400', '+90555123017', true, true, NOW(), NOW(), 22, 28, ARRAY['İzmir', 'Muğla'], ARRAY['Spor', 'Macera'], ARRAY['female']),

('kaan.erdogan@email.com', 'Kaan Erdoğan', 'candidate', 32, 'male', 'İşletme uzmanı, girişimcilik alanında deneyimli, liderlik vasfı olan biriyim.', ARRAY['İşletme', 'Girişimcilik', 'Liderlik'], 'İstanbul', 'İşletme Uzmanı', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400', '+90555123018', true, true, NOW(), NOW(), 27, 35, ARRAY['İstanbul', 'Ankara'], ARRAY['İş', 'Liderlik'], ARRAY['female']),

('murat.akgun@email.com', 'Murat Akgün', 'candidate', 26, 'male', 'Aşçılık tutkunu, mutfak sanatlarında uzman, yemek blogger''ıyım.', ARRAY['Yemek', 'Mutfak', 'Blog'], 'Bursa', 'Aşçı', 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?w=400', '+90555123019', true, true, NOW(), NOW(), 23, 29, ARRAY['Bursa', 'İstanbul'], ARRAY['Yemek', 'Yazı'], ARRAY['female']),

('tuncay.demir@email.com', 'Tuncay Demir', 'candidate', 30, 'male', 'Fotoğrafçılık ve görsel sanatlar alanında çalışan, estetik anlayışı gelişmiş biriyim.', ARRAY['Fotoğraf', 'Sanat', 'Estetik'], 'Ankara', 'Fotoğrafçı', 'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=400', '+90555123020', true, true, NOW(), NOW(), 25, 32, ARRAY['Ankara', 'İstanbul'], ARRAY['Sanat', 'Fotoğraf'], ARRAY['female']);
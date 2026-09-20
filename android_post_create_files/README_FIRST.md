# Network Security Config Setup (zaroori hai real backend HTTP ke liye)

Android 9 aur uske baad cleartext (plain http://) traffic by default block karta hai.
Hamari backend abhi https:// nahi, http:// par chal rahi hai (local testing ke liye),
to agar ye step skip kiya to APK install to ho jayegi lekin login karte waqt
"failed to connect" jaisa error aayega.

## Steps (Part 2.0 — flutter create — chalane ke BAAD karna):

1. Is folder ke andar wali file `app/src/main/res/xml/network_security_config.xml`
   ko copy karo aur apne (ab newly-created) `android/app/src/main/res/xml/` folder
   mein paste karo. (`xml` naam ka folder shayad already nahi hoga, bana lena.)

2. File ke andar jo IP address likha hai (`192.168.1.45`), usko apne laptop ke
   actual IP se replace karo — wahi IP jo tumne `api_constants.dart` mein bhi daala tha.

3. `android/app/src/main/AndroidManifest.xml` kholo, `<application` tag dhoondo
   (line kuch is tarah dikhegi):
   ```xml
   <application
        android:label="humraah"
        android:icon="@mipmap/ic_launcher">
   ```
   Isme ek attribute add karo:
   ```xml
   <application
        android:label="humraah"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="true">
   ```

4. Save kar ke `flutter build apk --release` dobara chalao.

## Agar backend ko HTTPS par deploy kar diya (Render/Railway wala Option B)
To ye step (network security config) bilkul skip kar sakte ho — HTTPS by default
allowed hai, koi extra config nahi chahiye. Sirf `usesCleartextTraffic` aur is
`network_security_config.xml` ko chodo, kuch add karne ki zaroorat nahi.

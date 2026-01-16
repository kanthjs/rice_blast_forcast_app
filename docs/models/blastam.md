# BLASTAM Model

## คำอธิบาย (Description)

BLASTAM พัฒนาโดย Koshimizu (1983) ใน Hiroshima Prefecture ใช้ empirical criteria เช่น wet duration >10-17 ชม. (ขึ้นกับ temp 15-25°C), precipitation >1 mm/hr, wind <2-4 m/s และ RH สูง เพื่อ classify เป็น favorable/semi/unfavorable conditions. เอกสารต้นฉบับคือ "A forecasting method for leaf blast outbreak by the use of AMeDAS data" ตีพิมพ์ใน Plant Protection 37:454-457 และปรับปรุงโดย Uehara et al. (1988) ในรูปแบบ computer model

## การพัฒนาและใช้งาน

ต่อมาปรับเป็น software บน PC โดย Yokouchi et al. (1986) และ integrate กับ BLASTL (Hashimoto et al. 1984) เพื่อ simulate progression. ในรีวิวปี 2019 ยืนยันว่า BLASTAM accurate สำหรับ leaf blast แต่ panicle blast ต้องปรับปรุง และ operational ที่ http://www.rei-gai.affrc.go.jp. ไทยมีอ้างในเอกสารกรมวิชาการเกษตร (Ishiguro et al. 1988) เปรียบกับ EPIBLA

เน้นการตรวจจับช่วงเวลาติดเชื้อ (Infection Period) เพื่อพยากรณ์การระบาด
ทำนายว่าจะเกิดการระบาดประมาณ 10 วันหลังการติดเชื้อ

## เงื่อนไขการติดเชื้อ (Infection Criteria)

การติดเชื้อเกิดขึ้นเมื่อ:

1. **ช่วงเปียก (Wet Period)**: RH ≥ 90% ต่อเนื่องกัน ≥ 10 ชั่วโมง
2. **อุณหภูมิต่ำสุด**: > 16°C ในช่วงที่เปียก

## การคำนวณ

```r
# ตรวจหาช่วงเปียกต่อเนื่อง 10+ ชั่วโมง
is_wet_period = (RH >= 90) สำหรับ 10 ชั่วโมงติดต่อกัน

# ตรวจอุณหภูมิต่ำสุด
min_temp_ok = min(temp) > 16 ในช่วง wet period

# Infection detected
infection = is_wet_period AND min_temp_ok

# High risk date = infection_date + 10 days
outbreak_prediction = infection_date + 10
```

## ผลลัพธ์

- **Infection Events Detected**: จำนวนวันที่ตรวจพบการติดเชื้อ
- **Future Outbreak Candidates**: จำนวนวันที่คาดว่าจะเกิดการระบาด

## แหล่งอ้างอิง

- [BLASTAM Paper](https://link.springer.com/article/10.1007/BF02980315)

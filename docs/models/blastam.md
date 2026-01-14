# BLASTAM Model

## คำอธิบาย (Description)

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

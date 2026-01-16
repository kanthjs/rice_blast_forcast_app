# Classic Model

## คำอธิบาย (Description)

โมเดลพื้นฐานที่บอกสภาวะแวดล้อมที่เหมาะสม (อุณหภูมิ ความชื้น และความเปียกใบ)
ของโรคไหม้ มากแค่ไหน

## เงื่อนไข (Conditions)

สภาพอากาศที่เอื้อต่อการเกิดโรค:

- **อุณหภูมิ**: 20-30°C (เหมาะสมที่สุด 25-28°C)
- **ความชื้นสัมพัทธ์**: > 90%
- **ความเปียกใบ**: > 6 ชั่วโมงต่อวัน

## การคำนวณ

```r
# ตรวจสอบชั่วโมงที่เอื้อต่อโรค
favorable_hours = จำนวนชั่วโมงที่ (temp >= 20 & temp <= 30) และ (humidity >= 90)

# คำนวณ risk score
risk_score = favorable_hours / 24 * 100
```

## ระดับความเสี่ยง

| Risk Score | Level  | ความหมาย                 |
| ---------- | ------ | ------------------------ |
| < 30%      | Low    | ความเสี่ยงต่ำ            |
| 30-60%     | Medium | เฝ้าระวัง                |
| > 60%      | High   | ความเสี่ยงสูง ควร Action |

## แหล่งอ้างอิง

- Padmanabhan, S.Y. (1965). "Epidemiology of rice blast and its influence on control strategies." ใน Proceedings of the Symposium on Rice Diseases and their Control.

- Kim, C.H. (1988). "Field testing a computerized forecasting system for rice blast disease development." Phytopathology, 78(7):931-935

- Koshimizu, M. (1983). "A forecasting method for leaf blast outbreak by the use of AMeDAS data." Plant Protection, 37:454-457

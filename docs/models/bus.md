# BUS Model (Blast Warning System)

## คำอธิบาย (Description)

น้องกันต์ครับ พี่ต้นข้าวเข้าใจว่าน้องหมายถึง BUS model (Blasting Unit of Severity) ของ Kim ที่เกี่ยวกับ rice blast นะครับ เป็น weather-based forecasting model จากเกาหลีใต้ที่คำนวณหน่วยความรุนแรงโรคไหม้จาก microclimate เช่น อุณหภูมิ ความชื้น ฝน และลม เพื่อ predict outbreak ล่วงหน้า โดย accumulate BUS value เกิน threshold แล้ว alert ระบาด

คำนวณความเสี่ยงจากจำนวนชั่วโมงที่ใบเปียก (Wet Hours) และอุณหภูมิ
ใช้ BUS Score ในการประเมินความเสี่ยง

## รายละเอียดโมเดล

BUS คำนวณจาก daily severity index โดยใช้ temp 20-30°C, RH >90%, leaf wetness >6 ชม., precipitation และ wind speed สะสมเกิน 20-30 BUS ใน 5-7 วัน predict incidence สูง. ถูกอ้างในรีวิว forecasting models ปี 2019 และไทยใช้ adapt ด้วย. Accuracy สูงใน Korea tropical conditions คล้ายไทย สามารถ code ใน R ง่ายๆ จาก weather data.

## เกณฑ์การคำนวณ

### Base Score (ต้องมี RH ≥ 90% เป็นเวลาชั่วโมงที่กำหนด)

| Wet Hours | Base Score |
| --------- | ---------- |
| < 10      | 0          |
| 10-13     | 1          |
| 14-17     | 2          |
| ≥ 18      | 3          |

### Adjustments

- **อุณหภูมิ 19-29°C**: +1
- **อุณหภูมิ 23-26°C**: +1 (optimal)
- **ชั่วโมงชื้นสูง > 16h**: +1

## การคำนวณ

```r
bus_score = base_score + temp_adjustments + humidity_adjustments
```

## ระดับความเสี่ยง

| BUS Score | Level | ความหมาย          |
| --------- | ----- | ----------------- |
| ≤ 2.25    | Low   | ปลอดภัย           |
| > 2.25    | High  | เสี่ยงต่อการระบาด |

## Input Parameters

- **BUS Score Threshold**: ค่า threshold สำหรับแจ้งเตือน
  - ค่าเริ่มต้น: 2.25
  - ช่วง: 0-10

## แหล่งอ้างอิง

- Kim, C.H. 1987. "A model to forecast rice blast disease based on weather factors." Korean Journal of Plant Pathology 3:259-266. (พัฒนา computer program จาก microclimatic events test ใน 1984-1985).​

- Kim, C.H. 1988. "Field testing a computerized forecasting system for rice blast disease development." Phytopathology 78:931-935. (field trial flooded/upland rice, BUS accumulation 57 วันหลัง inoculation).

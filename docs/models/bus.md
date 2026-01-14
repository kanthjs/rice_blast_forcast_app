# BUS Model (Blast Warning System)

## คำอธิบาย (Description)

คำนวณความเสี่ยงจากจำนวนชั่วโมงที่ใบเปียก (Wet Hours) และอุณหภูมิ
ใช้ BUS Score ในการประเมินความเสี่ยง

## เกณฑ์การคำนวณ

### Base Score (ต้องมี RH ≥ 90% เป็นเวลาชั่วโมงที่กำหนด)

| Wet Hours | Base Score |
|-----------|------------|
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

| BUS Score | Level | ความหมาย |
|-----------|-------|----------|
| ≤ 2.25    | Low   | ปลอดภัย |
| > 2.25    | High  | เสี่ยงต่อการระบาด |

## Input Parameters

- **BUS Score Threshold**: ค่า threshold สำหรับแจ้งเตือน
  - ค่าเริ่มต้น: 2.25
  - ช่วง: 0-10

## แหล่งอ้างอิง

- Blast Warning System for Rice

# EPIBLA Model

## คำอธิบาย (Description)

ประเมินความรุนแรง (Severity) ของโรค โดยพิจารณาความต้านทานของพันธุ์ข้าว
ช่วยในการตัดสินใจฉีดพ่นสารป้องกันเชื้อรา

## ปัจจัยที่ใช้

1. **Spore Estimation (X1)**: การประมาณปริมาณสปอร์
2. **Temperature (X2)**: อุณหภูมิต่ำสุด/ความชื้นสูงสุด
3. **Dew Duration (X3)**: ระยะเวลาน้ำค้าง
4. **Resistance Level**: ระดับความต้านทานของพันธุ์ข้าว

## การคำนวณ

### สำหรับพันธุ์อ่อนแอ (Susceptible)

```r
severity = f(total_spores, avg_min_temp, avg_dew_hours)
```

### สำหรับพันธุ์ต้านทาน (Resistant)

```r
severity = f(total_spores, avg_max_rh, avg_dew_hours)
```

## Input Parameters

- **Rice Resistance Level**: ระดับความต้านทาน
  - Susceptible Breed: พันธุ์อ่อนแอ
  - Resistant Breed: พันธุ์ต้านทาน

## ผลลัพธ์

- **7-Day Predicted Severity**: % ความรุนแรงที่คาดการณ์
- **High Risk Days (> 10%)**: จำนวนวันที่มีความเสี่ยงสูง

## ระดับความรุนแรง

| Severity | Level | คำแนะนำ |
|----------|-------|---------|
| < 5%     | Low   | ปกติ |
| 5-10%    | Medium| เฝ้าระวัง |
| > 10%    | High  | ฉีดพ่นสารป้องกันทันที |

## แหล่งอ้างอิง

- EPIBLA: Epidemiological Blast Assessment Model

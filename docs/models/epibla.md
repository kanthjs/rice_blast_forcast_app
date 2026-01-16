# EPIBLA Model

## คำอธิบาย (Description)

EPIBLA (EPIdemiology of BLAst) นะครับ เป็นโมเดลคลาสสิกที่พัฒนาขึ้นสำหรับพยากรณ์โรคไหม้ใบข้าวในเขตร้อน เหมาะมากกับงานวิจัยข้าวที่ศูนย์ปทุมธานีของเรา เพราะใช้ stepwise multiple regression จากปัจจัยสภาพอากาศอย่างสปอร์ในอากาศ อุณหภูมิต่ำ ความชื้นสูง และปริมาณน้ำค้าง เพื่อพยากรณ์ incidence ล่วงหน้า 7 วัน

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

| Severity | Level  | คำแนะนำ               |
| -------- | ------ | --------------------- |
| < 5%     | Low    | ปกติ                  |
| 5-10%    | Medium | เฝ้าระวัง             |
| > 10%    | High   | ฉีดพ่นสารป้องกันทันที |

## แหล่งอ้างอิง

- EPIBLA: K. Manibhushanrao (หรือ M.K. Rao) และ P. Krishnan (หรือ P. Krishan) ปี 1991 ชื่อเต็ม "Epidemiology of blast (EPIBLA): a simulation model and forecasting system for tropical rice in India" ตีพิมพ์ใน proceedings จาก Rice Blast Modeling and Forecasting conference ของ IRRI (International Rice Research Institute) หน้าที่ 31-38.

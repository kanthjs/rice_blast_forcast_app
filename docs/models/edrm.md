# EDRM Model (Epidemiological Disease Risk Model)

## คำอธิบาย (Description)

โมเดลขั้นสูงที่นำอายุข้าว (Rice Age) และปัจจัยความเปียกใบมาคำนวณร่วมกับอุณหภูมิ
ใช้ Beta function ในการคำนวณ

## ปัจจัยที่ใช้

1. **RcT (Temperature Factor)**: ปัจจัยอุณหภูมิ
2. **RcW (Wetness Factor)**: ปัจจัยความเปียกใบ
3. **RcA (Age Factor)**: ปัจจัยอายุข้าว

## การคำนวณ

```r
# Temperature factor
RcT = beta_function(temp, Tmin=10, Topt=25, Tmax=35)

# Wetness factor
RcW = hours_wet / 24

# Age factor (สำคัญที่สุดช่วง 0-40 วัน)
RcA = if (dat <= 40) 1.0
      else if (dat > 70) 0.1
      else 1.0 - (0.9 * (dat - 40) / 30)

# Combined Risk
daily_risk = RcT * RcW * RcA * 100
```

## ระดับความเสี่ยง

| Risk Score | Level  | คำแนะนำ            |
| ---------- | ------ | ------------------ |
| < 20%      | Low    | ปกติ               |
| 20-50%     | Medium | เฝ้าระวัง ตรวจแปลง |
| > 50%      | High   | ฉีดพ่นสารป้องกัน   |

## Input Parameters

- **Rice Age (Days After Sowing)**: อายุข้าว (วัน)
  - ค่าเริ่มต้น: 30 วัน
  - ช่วง: 1-120 วัน

## แหล่งอ้างอิง

- Kim, K.H., Jung, I., Park, D.S., & Lee, Y.H. (2020). "Development of a Daily Epidemiological Model of Rice Blast Tailored for Seasonal Disease Early Warning in South Korea." The Plant Pathology Journal, 36(5):406-417. DOI: 10.5423/PPJ.OA.09.2019.0232

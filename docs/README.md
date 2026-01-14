# Rice Blast Forecast App Documentation

ระบบพยากรณ์ความเสี่ยงโรคไหม้ในข้าว (Rice Blast Disease Risk Forecasting System)

## โครงสร้างโปรเจกต์

```
rice_blast_forcast_app/
├── app.R              # Rhino entry point
├── rhino.yml          # Rhino configuration
├── app/               # Application code
│   ├── main.R         # Main module
│   ├── view/          # UI modules
│   ├── logic/         # Business logic
│   └── styles/        # Sass styles
├── docs/              # Editable documentation
│   ├── models/        # Model descriptions
│   └── usage_guide.md # User guide
└── renv/              # Package management
```

## โมเดลที่ใช้

1. **Classic** - โมเดลพื้นฐาน
2. **EDRM** - โมเดลขั้นสูง
3. **BUS** - โมเดล BUS Score
4. **BLASTAM** - โมเดลตรวจจับการติดเชื้อ
5. **EPIBLA** - โมเดลประเมินความรุนแรง

## การใช้งาน

ดูรายละเอียดที่ [usage_guide.md](usage_guide.md)

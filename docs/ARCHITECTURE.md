# Finaper – Project State

## 🧱 Stack

* Flutter 3.x
* Dart 3.x
* SQLite (sqflite)
* Arquitectura: feature-based

---

## 🚀 Features implementadas

### ✅ Dashboard

* Balance dinámico desde SQLite
* KPI (Ingresos / Gastos)
* Últimas transacciones
* Gráfico de tendencia (fl_chart)
* UI con animaciones

### ✅ Transactions

* Listado de transacciones
* Filtros (All / Income / Expense)
* Búsqueda
* Creación de transacciones (BottomSheet)
* Persistencia SQLite funcionando

---

## 🗂️ Estructura

```id="afntc3"
lib/
  core/
    theme/
    enums/
  features/
    dashboard/
    transactions/
```

---

## 🧠 Decisiones técnicas

* ❌ Web descartado (sqflite no compatible)
* ✅ Android como plataforma principal
* ❌ Sin state management (por ahora)
* ✅ Estado local con setState
* ✅ Persistencia local SQLite

---

## 🧪 Problemas resueltos

* sqflite no funcionaba en web
* errores de rutas/imports
* filtros de transacciones
* persistencia no guardaba correctamente
* integración dashboard ↔ transactions

---

## 📌 Pendientes (backlog)

* Bottom Navigation (Dashboard / Transactions)
* Editar transacciones
* Eliminar transacciones
* Repository layer
* Separación UseCases
* Dark mode real
* Exportar datos
* Backend (futuro)

---

## 🎯 Estado actual

👉 MVP funcional
👉 Persistencia real
👉 UI moderna
👉 Base sólida para escalar

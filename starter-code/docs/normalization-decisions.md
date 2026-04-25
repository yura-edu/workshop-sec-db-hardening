# Decisiones de Normalización

Documenta aquí las decisiones que tomaste al normalizar el schema a 3NF.

## Por qué el schema original viola 3NF

### Violación de 1NF — order_history TEXT
[TODO: Explica por qué `order_history TEXT` viola la Primera Forma Normal y cómo lo resolviste]

### Violación de 2NF — preferences TEXT
[TODO: Explica la dependencia parcial de `preferences` y cómo la separaste]

### Violación de 3NF — city y country como VARCHAR
[TODO: Explica por qué city/country como VARCHAR libre viola 3NF y cómo las tablas
`countries` y `cities` resuelven la dependencia transitiva]

---

## Tablas creadas y su justificación 3NF

### countries
- **Clave primaria:** id
- **Dependencias funcionales:** id → name, id → code
- **Justificación 3NF:** [TODO: explica por qué está en 3NF]

### cities
- **Clave primaria:** id
- **Dependencias funcionales:** id → name, id → country_id
- **Justificación 3NF:** [TODO]

### customers (refactorizado)
- **Clave primaria:** id
- **Dependencias funcionales:** [TODO: lista las dependencias]
- **Justificación 3NF:** [TODO]

### customer_payment_methods
- **Justificación de separación:** [TODO: ¿por qué los datos de pago van en tabla separada?]
- **Relación con customers:** [TODO]

### customer_preferences
- **Justificación de separación:** [TODO]

---

## Decisiones de constraints ON DELETE / ON UPDATE

Documenta cada FK y la razón de la política elegida:

| FK | ON DELETE | ON UPDATE | Razón |
|---|---|---|---|
| cities.country_id → countries | [TODO] | [TODO] | [TODO] |
| customers.city_id → cities | [TODO] | [TODO] | [TODO] |
| customer_payment_methods.customer_id → customers | [TODO] | [TODO] | [TODO] |
| customer_preferences.customer_id → customers | [TODO] | [TODO] | [TODO] |

---

## Columnas PII identificadas y su tratamiento

| Columna | Tabla | Por qué es PII | Tratamiento |
|---|---|---|---|
| full_name | customers | Identifica a la persona | [TODO] |
| phone | customers | Dato de contacto personal | [TODO] |
| card_number | customer_payment_methods | Dato financiero regulado (PCI-DSS) | [TODO] |
| cvv | customer_payment_methods | Dato financiero muy sensible | [TODO] |
| card_expiry | customer_payment_methods | Dato financiero | [TODO] |

---

## Roles de BD y justificación de mínimo privilegio

### app_reader
- **Puede hacer:** [TODO]
- **No puede hacer:** [TODO]
- **Razón:** [TODO]

### app_writer
- **Puede hacer:** [TODO]
- **No puede hacer:** [TODO]
- **Razón:** [TODO]

### app_admin
- **Puede hacer:** [TODO]
- **Razón:** [TODO]

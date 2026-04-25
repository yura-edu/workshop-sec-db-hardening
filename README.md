# Hardening y Normalización de Base de Datos

> **Tipo:** CODE_QUALITY · **Duración estimada:** 240 min · **Nivel:** Intermedio · **Prerequisito:** SQL básico

## Objetivo

Refactorizar un schema PostgreSQL denormalizado a 3NF, agregar constraints de integridad referencial, cifrar las columnas PII con pgcrypto, crear roles de BD con mínimo privilegio, y documentar todo en migraciones versionadas.

## Contexto

Las bases de datos son el activo más valioso de la mayoría de las empresas. Sin embargo, es común encontrar schemas con datos PII sin cifrar, sin constraints de integridad, roles con acceso total, y sin historial de migraciones.

La normalización y el hardening de BD no son solo buenas prácticas: en muchos sectores son requisitos regulatorios (GDPR, HIPAA, PCI-DSS).

El starter provee `migrations/000_baseline.sql` con un schema deliberadamente problemático. Tu tarea es escribir las cuatro migraciones siguientes para llevarlo a un estado seguro y normalizado.

## Estructura del proyecto

```
├── migrations/
│   ├── 000_baseline.sql          # Schema de partida — PROVISTO, no modificar
│   ├── 001_normalize_3nf.sql     # CREAR — tablas countries, cities, customer_payment_methods, customer_preferences
│   ├── 002_add_constraints.sql   # CREAR — FK con ON DELETE/UPDATE, CHECK, UNIQUE
│   ├── 003_encrypt_pii.sql       # CREAR — pgcrypto para columnas PII
│   └── 004_roles.sql             # CREAR — app_reader, app_writer, app_admin
├── docs/
│   └── normalization-decisions.md  # CREAR — justificación de cada decisión 3NF
├── compose.yml                   # PostgreSQL con pgcrypto — PROVISTO
└── README.md
```

## Instrucciones

### 1. Levanta el entorno

```bash
git clone <url-de-tu-repositorio>
cd workshop-sec-db-hardening
docker compose up -d
```

El `compose.yml` levanta PostgreSQL con la extensión pgcrypto activada. Conéctate para verificar:

```bash
docker compose exec db psql -U postgres -d workshop -c "SELECT * FROM pg_extension WHERE extname = 'pgcrypto';"
```

### 2. Estudia el schema de partida

Lee `migrations/000_baseline.sql`. Identifica los problemas:

- `order_history TEXT` — array serializado como texto (viola 1NF)
- `preferences TEXT` — JSON serializado con dependencia parcial (viola 2NF)
- `city`, `country` como VARCHAR — datos repetidos sin tabla de referencia (viola 3NF)
- `credit_card_number`, `cvv`, `phone` — PII en texto plano
- Sin Primary Key declarada, sin constraints de integridad
- `created_at VARCHAR(50)` — tipo incorrecto para fechas

### 3. Migración 001 — Normalizar a 3NF

Crea `migrations/001_normalize_3nf.sql`. El schema objetivo:

```sql
-- 1. Tabla de países
CREATE TABLE countries (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code CHAR(2)      NOT NULL UNIQUE
);

-- 2. Tabla de ciudades (FK → countries)
CREATE TABLE cities (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    country_id INT          NOT NULL REFERENCES countries(id)
);

-- 3. Clientes normalizados (la PII será cifrada en migración 003)
CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    full_name  TEXT         NOT NULL,  -- cifrar en 003
    email      VARCHAR(255) NOT NULL UNIQUE,
    phone      TEXT,                   -- cifrar en 003
    city_id    INT          REFERENCES cities(id),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 4. Métodos de pago separados
CREATE TABLE customer_payment_methods (
    id          SERIAL PRIMARY KEY,
    customer_id INT     NOT NULL REFERENCES customers(id),
    card_number TEXT    NOT NULL,  -- cifrar en 003
    cvv         TEXT    NOT NULL,  -- cifrar en 003
    card_expiry TEXT    NOT NULL,  -- cifrar en 003
    is_primary  BOOLEAN NOT NULL DEFAULT false
);

-- 5. Preferencias separadas
CREATE TABLE customer_preferences (
    id                    SERIAL PRIMARY KEY,
    customer_id           INT     NOT NULL UNIQUE REFERENCES customers(id),
    theme                 VARCHAR(50),
    language              VARCHAR(10),
    notifications_enabled BOOLEAN NOT NULL DEFAULT true
);
```

Documenta cada decisión en `docs/normalization-decisions.md`.

### 4. Migración 002 — Constraints de integridad

Crea `migrations/002_add_constraints.sql`. Todos los FK deben tener `ON DELETE` y `ON UPDATE` explícitos:

```sql
-- Ejemplo de FK completa
ALTER TABLE cities
    ADD CONSTRAINT fk_cities_country
    FOREIGN KEY (country_id) REFERENCES countries(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

-- Ejemplo de CHECK
ALTER TABLE customers
    ADD CONSTRAINT chk_customers_email
    CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$');
```

Criterio: ≥ 90% de las FK tienen `ON DELETE` y `ON UPDATE` explícito.

### 5. Migración 003 — Cifrar PII con pgcrypto

Crea `migrations/003_encrypt_pii.sql`. Usa `pgp_sym_encrypt` para las columnas PII:

```sql
-- Activar extensión (si no está activa)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Modificar columnas a TEXT (pgp_sym_encrypt retorna bytea, pero puedes usar encode/decode)
-- Patrón: cifrar datos existentes y cambiar el tipo de columna

-- Ejemplo: cifrar full_name
ALTER TABLE customers ALTER COLUMN full_name TYPE BYTEA
    USING pgp_sym_encrypt(full_name, current_setting('app.encryption_key'));

-- Repite para: phone, card_number, cvv, card_expiry
```

> El grader verificará que `pgp_sym_encrypt` aparece en las migraciones para cada columna PII.

### 6. Migración 004 — Roles con mínimo privilegio

Crea `migrations/004_roles.sql` con tres roles:

```sql
-- Lector: solo SELECT, sin acceso a columnas cifradas
CREATE ROLE app_reader;
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT SELECT ON countries, cities, customer_preferences TO app_reader;
-- NO se otorga SELECT en columnas cifradas de customers o customer_payment_methods

-- Escritor: SELECT + INSERT + UPDATE, sin DELETE
CREATE ROLE app_writer;
GRANT USAGE ON SCHEMA public TO app_writer;
GRANT SELECT, INSERT, UPDATE ON customers, customer_payment_methods, customer_preferences TO app_writer;
GRANT SELECT ON countries, cities TO app_writer;

-- Administrador: todos los privilegios
CREATE ROLE app_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_admin;
```

### 7. Ejecuta las migraciones en orden

```bash
docker compose exec db psql -U postgres -d workshop \
    -f /migrations/000_baseline.sql \
    -f /migrations/001_normalize_3nf.sql \
    -f /migrations/002_add_constraints.sql \
    -f /migrations/003_encrypt_pii.sql \
    -f /migrations/004_roles.sql
```

Todas deben ejecutar sin errores.

### 8. Documenta las decisiones

Completa `docs/normalization-decisions.md` con:
- Por qué cada tabla está en 3NF (identifica la clave primaria, dependencias funcionales)
- Qué columnas son PII y por qué se cifraron
- Justificación de cada decisión `ON DELETE` / `ON UPDATE`

### 9. Abre el Pull Request

1. `git push origin feat/db-hardening`
2. Abre PR hacia `main`
3. Verifica que los Checks pasen

## Criterios de evaluación

| Métrica | Peso | Umbral |
|---|---|---|
| Integridad referencial | 25% | ≥ 90% de FK con `ON DELETE`/`ON UPDATE` explícito |
| PII cifrada | 20% | `pgp_sym_encrypt` detectado para todas las columnas PII |
| Roles de mínimo privilegio | 20% | Los 3 roles definidos con GRANTs específicos |
| Consultas parametrizadas | 15% | 100% de queries sin concatenación de strings |
| Schema válido | 10% | Migraciones ejecutan en orden sin error |
| Migraciones presentes | 10% | Los 4 archivos 001–004 existen |

## Recursos

- [PostgreSQL: pgcrypto](https://www.postgresql.org/docs/current/pgcrypto.html)
- [PostgreSQL: CREATE ROLE](https://www.postgresql.org/docs/current/sql-createrole.html)
- [PostgreSQL: Referential Integrity](https://www.postgresql.org/docs/current/ddl-constraints.html#DDL-CONSTRAINTS-FK)
- [OWASP: SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [GDPR: Pseudonymisation and Encryption](https://gdpr-info.eu/recitals/no-83/)
- [Flyway: Versioned Migrations](https://documentation.red-gate.com/fd/versioned-migrations-184127470.html)

-- ════════════════════════════════════════════════════════════════════════════
-- SCHEMA DE PARTIDA — DELIBERADAMENTE PROBLEMÁTICO
-- ════════════════════════════════════════════════════════════════════════════
-- Este archivo representa el estado actual de un sistema heredado con múltiples
-- problemas de diseño y seguridad. No modificar este archivo.
-- Tu tarea: escribir las migraciones 001 a 004 para arreglarlo.
--
-- Problemas identificados:
--  1. Sin Primary Key declarada (imposible identificar filas de forma única)
--  2. Sin UNIQUE en email (permite duplicados)
--  3. city, country como VARCHAR: datos repetidos, imposible hacer JOIN ni FK
--  4. order_history TEXT: array serializado en texto (viola 1NF)
--  5. preferences TEXT: JSON serializado con dependencia parcial (viola 2NF + 3NF)
--  6. credit_card_number, cvv, phone, full_name: PII en texto plano (violación GDPR)
--  7. created_at VARCHAR(50): tipo incorrecto para fechas (dificulta queries temporales)
--  8. address VARCHAR(1000): múltiples campos mezclados (calle, número, código postal)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE customers (
    id                  SERIAL,
    full_name           VARCHAR(500),
    email               VARCHAR(500),
    phone               VARCHAR(100),
    address             VARCHAR(1000),
    city                VARCHAR(200),
    country             VARCHAR(200),
    credit_card_number  VARCHAR(50),
    cvv                 VARCHAR(10),
    card_expiry         VARCHAR(20),
    order_history       TEXT,
    preferences         TEXT,
    created_at          VARCHAR(50)
);

-- Datos de ejemplo (problemáticos: PII en texto plano, duplicados posibles)
INSERT INTO customers VALUES
    (1, 'María García',    'maria@example.com',  '+52 55 1234 5678', 'Calle Reforma 123', 'Ciudad de México', 'México', '4111111111111111', '123', '12/26', '[1,2,3]', '{"theme":"dark"}', '2024-01-15'),
    (2, 'Carlos López',    'carlos@example.com', '+57 1 234 5678',   'Cra 7 # 32-16',     'Bogotá',          'Colombia','5500005555555559','456', '08/25', '[4,5]',   '{"lang":"es"}',   '2024-02-20'),
    (3, 'Ana Rodríguez',   'ana@example.com',    '+51 1 234 5678',   'Av. Arequipa 456',  'Lima',            'Perú',   '4000056655665556','789', '03/27', '[6,7,8]', '{"theme":"light"}','2024-03-10');

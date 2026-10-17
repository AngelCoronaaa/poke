-- Cuentas de entrenador y sesiones de la Pokédex.
-- El servidor ejecuta este archivo al arrancar; es idempotente.

CREATE TABLE IF NOT EXISTS entrenadores (
  id            SERIAL PRIMARY KEY,
  usuario       TEXT        NOT NULL UNIQUE,  -- nombre normalizado (minúsculas)
  nombre        TEXT        NOT NULL,         -- nombre como lo escribió
  password_hash TEXT        NOT NULL,         -- bcrypt, nunca la contraseña
  trainer_id    CHAR(5)     NOT NULL,
  companero     INTEGER     NOT NULL,         -- id del Pokémon compañero
  region        TEXT        NOT NULL,
  creado_en     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sesiones (
  token_hash    TEXT        PRIMARY KEY,      -- SHA-256 del token
  entrenador_id INTEGER     NOT NULL REFERENCES entrenadores (id) ON DELETE CASCADE,
  creada_en     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_en     TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS sesiones_entrenador_idx ON sesiones (entrenador_id);

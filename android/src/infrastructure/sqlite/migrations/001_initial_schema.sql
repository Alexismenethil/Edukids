-- 001: esquema inicial de la tablet.
-- Fuente: docs/03-diseno-de-software/modelo-de-datos.md
-- Fechas en ISO 8601 (UTC), identificadores UUID o códigos de paquete, booleanos como 0 y 1.
-- Las claves foráneas no borran en cascada: un estudiante con resultados se desactiva,
-- no se elimina (RN-07), y la base lo impide.

CREATE TABLE institution (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    modular_code TEXT,
    grade INTEGER NOT NULL DEFAULT 6 CHECK (grade BETWEEN 1 AND 6),
    school_year INTEGER NOT NULL,
    teacher_code TEXT CHECK (teacher_code IS NULL OR length(teacher_code) = 6)
);

CREATE TABLE teacher (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    pin_hash TEXT NOT NULL,
    pin_salt TEXT NOT NULL,
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TEXT
);

CREATE TABLE section (
    id TEXT PRIMARY KEY,
    institution_id TEXT NOT NULL REFERENCES institution (id),
    name TEXT NOT NULL,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);

CREATE TABLE student (
    id TEXT PRIMARY KEY,
    section_id TEXT NOT NULL REFERENCES section (id),
    name TEXT NOT NULL,
    code TEXT,
    pin_hash TEXT NOT NULL,
    pin_salt TEXT NOT NULL,
    avatar_json TEXT NOT NULL DEFAULT '{}',
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TEXT,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);
CREATE INDEX idx_student_section ON student (section_id);

CREATE TABLE package (
    id TEXT PRIMARY KEY,
    kind TEXT NOT NULL CHECK (kind IN ('module', 'challenge')),
    area TEXT NOT NULL CHECK (area IN ('math', 'language', 'science')),
    grade INTEGER NOT NULL,
    number INTEGER,
    chapter TEXT CHECK (chapter IS NULL OR chapter IN ('sierra', 'selva', 'costa')),
    title TEXT NOT NULL,
    version TEXT NOT NULL,
    size_bytes INTEGER NOT NULL DEFAULT 0,
    sha256 TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'installed' CHECK (status IN ('installed', 'archived')),
    install_path TEXT NOT NULL,
    installed_at TEXT NOT NULL
);

CREATE TABLE package_section (
    package_id TEXT NOT NULL REFERENCES package (id),
    section_id TEXT NOT NULL REFERENCES section (id),
    enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1)),
    final_enabled INTEGER NOT NULL DEFAULT 0 CHECK (final_enabled IN (0, 1)),
    PRIMARY KEY (package_id, section_id)
);

-- El id de un nivel incluye su paquete para ser único: "mod-math-6-01:L01".
CREATE TABLE level (
    id TEXT PRIMARY KEY,
    package_id TEXT NOT NULL REFERENCES package (id),
    kind TEXT NOT NULL CHECK (kind IN ('short', 'regular', 'final')),
    mechanic TEXT NOT NULL CHECK (mechanic IN ('chase', 'bridge', 'classic')),
    position INTEGER NOT NULL,
    title TEXT NOT NULL,
    estimated_minutes INTEGER
);
CREATE INDEX idx_level_package ON level (package_id, position);

CREATE TABLE attempt (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES student (id),
    level_id TEXT NOT NULL REFERENCES level (id),
    package_version TEXT NOT NULL,
    kind TEXT NOT NULL CHECK (kind IN ('practice', 'final')),
    status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed', 'game_over', 'closed')),
    started_at TEXT NOT NULL,
    finished_at TEXT,
    correct_count INTEGER NOT NULL DEFAULT 0,
    total_count INTEGER NOT NULL DEFAULT 0,
    percent REAL CHECK (percent IS NULL OR percent BETWEEN 0 AND 100),
    stars INTEGER CHECK (stars IS NULL OR stars BETWEEN 0 AND 3),
    cneb_grade TEXT CHECK (cneb_grade IS NULL OR cneb_grade IN ('AD', 'A', 'B', 'C')),
    lives_lost INTEGER NOT NULL DEFAULT 0,
    hints_used INTEGER NOT NULL DEFAULT 0,
    CHECK (cneb_grade IS NULL OR kind = 'final')
);
CREATE INDEX idx_attempt_student_level ON attempt (student_id, level_id);

CREATE TABLE answer (
    id TEXT PRIMARY KEY,
    attempt_id TEXT NOT NULL REFERENCES attempt (id),
    item_id TEXT NOT NULL,
    value_json TEXT NOT NULL,
    is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
    first_try INTEGER NOT NULL CHECK (first_try IN (0, 1)),
    with_hint INTEGER NOT NULL DEFAULT 0 CHECK (with_hint IN (0, 1)),
    time_ms INTEGER NOT NULL DEFAULT 0,
    answered_at TEXT NOT NULL
);
CREATE INDEX idx_answer_attempt ON answer (attempt_id);

CREATE TABLE reward (
    student_id TEXT NOT NULL REFERENCES student (id),
    kind TEXT NOT NULL CHECK (kind IN ('badge', 'card', 'accessory')),
    reward_id TEXT NOT NULL,
    earned_at TEXT NOT NULL,
    PRIMARY KEY (student_id, kind, reward_id)
);

CREATE TABLE resource_view (
    student_id TEXT NOT NULL REFERENCES student (id),
    resource_id TEXT NOT NULL,
    viewed_at TEXT NOT NULL
);
CREATE INDEX idx_resource_view_student ON resource_view (student_id, resource_id);

-- Ajustes de la tablet: escala AD/A/B/C, intentos, pausa y volumen (claves con prefijo).
CREATE TABLE setting (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

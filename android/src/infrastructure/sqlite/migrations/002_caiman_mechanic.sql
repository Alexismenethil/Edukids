-- rehace-tablas
-- Sprint 5: nueva mecánica «caiman» (Coco, el caimán glotón). SQLite no permite cambiar un
-- CHECK, así que la tabla level se vuelve a crear con los mismos datos. El migrador la aplica
-- con las claves foráneas apagadas y las comprueba antes de confirmar (procedimiento de SQLite).
CREATE TABLE level_new (
    id TEXT PRIMARY KEY,
    package_id TEXT NOT NULL REFERENCES package (id),
    kind TEXT NOT NULL CHECK (kind IN ('short', 'regular', 'final')),
    mechanic TEXT NOT NULL CHECK (mechanic IN ('chase', 'bridge', 'caiman', 'classic')),
    position INTEGER NOT NULL,
    title TEXT NOT NULL,
    estimated_minutes INTEGER
);
INSERT INTO level_new (id, package_id, kind, mechanic, position, title, estimated_minutes)
    SELECT id, package_id, kind, mechanic, position, title, estimated_minutes FROM level;
DROP TABLE level;
ALTER TABLE level_new RENAME TO level;
CREATE INDEX idx_level_package ON level (package_id, position);

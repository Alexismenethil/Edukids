# ADR-017: Tecnologías del backend y del panel

**Estado:** Propuesta (v3.0). Se confirma al iniciar el Sprint 8.

## Contexto

El backend sirve el catálogo público, gestiona las cuentas docentes y genera los paquetes; el panel permite crear y publicar retos. Ambos deben seguir Clean Architecture ([ADR-010](ADR-010-clean-architecture.md)) y tener un costo de operación bajo.

## Decisión propuesta

| Parte | Tecnología |
| --- | --- |
| Backend | Node.js (versión LTS) con TypeScript y Fastify |
| Validación | Zod |
| Persistencia | PostgreSQL con Prisma |
| Archivos de paquetes | Almacenamiento de objetos compatible con S3 y con descargas por rangos |
| Autenticación del panel | Contraseñas con hash robusto (Argon2id o bcrypt) y tokens de sesión de vida corta |
| Empaquetado | ZIP y SHA-256 generados por un caso de uso del backend |
| Panel docente | React con TypeScript y Vite; pdf.js para convertir PDF a imágenes en el navegador |
| Pruebas | Vitest |

**Razones:** el autor ya trabaja con TypeScript, Prisma y Zod; y con Clean Architecture, Fastify, Prisma y el almacenamiento son adaptadores que se pueden reemplazar sin tocar el dominio.

## Pendientes

- [POR CONFIRMAR: proveedor de hosting con plan gratuito o de bajo costo]
- [POR CONFIRMAR: dominio y certificado HTTPS]
- [POR CONFIRMAR: responsable de operar el servicio después del proyecto]

## Consecuencias

- El formato de paquete es el contrato entre el backend y el juego, y se versiona.
- La lógica de validación de retos puede compartirse entre el panel y el backend porque ambos usan TypeScript.

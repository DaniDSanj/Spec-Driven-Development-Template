# Protocolo de cambio de esquema

Se activa cuando una spec en desarrollo requiere crear, modificar o eliminar 
estructuras en el modelo de datos canónico.

## Pasos obligatorios

1. LECTURA: Consultar .specify/memory/data-model.md completo antes de proponer 
   cualquier estructura.

2. REUTILIZACIÓN: Si existe una entidad/columna que cubre la necesidad, 
   proponer su reutilización o extensión en lugar de crear una nueva. 
   Justificar explícitamente por qué se reutiliza o por qué no es viable.

3. IMPACTO: Si la propuesta modifica una estructura existente:
   - Localizar todas las specs listadas en "Specs que dependen de esta tabla"
   - Para cada una, leer su spec.md y plan.md
   - Determinar si su comportamiento actual sigue siendo válido
   - Si no, redactar la readaptación necesaria (qué cambia en su plan.md, 
     en las queries afectadas, o en el pipeline/informe correspondiente)

4. PRIORIDAD: Ante conflicto entre una spec antigua y la nueva necesidad, 
   la spec antigua se adapta a la nueva. Nunca al revés.

5. PROPUESTA AL HUMANO: Presentar en un único bloque:
   - Cambio propuesto en el modelo canónico
   - Lista de specs afectadas
   - Readaptación concreta propuesta para cada una
   - Esperar aprobación EXPLÍCITA antes de aplicar nada

6. APLICACIÓN: Solo tras aprobación:
   - Actualizar data-model.md canónico (entidad + changelog)
   - Aplicar las readaptaciones aprobadas en las specs afectadas
   - Actualizar el data-model.md LOCAL de la spec en curso
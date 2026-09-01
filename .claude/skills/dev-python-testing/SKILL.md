---
name: dev-python-testing
description: >
  Convenciones de testing en Python de este proyecto: pytest, estructura de
  tests/ como espejo de src/, mockeo de conexiones a base de datos,
  cobertura mínima objetivo y la regla de que ninguna tarea se cierra sin
  test. Úsalo antes de escribir o modificar tests — en el paso 4.1 del
  ciclo SDD junto a /speckit-implement, y en cualquier edición de tests
  fuera del ciclo.
---

# Convenciones de testing en Python

La **cobertura mínima objetivo** de este proyecto está en **Python → Cobertura mínima objetivo** de
`.claude/context/00_perfil_proyecto.md`. Es un campo **sin default seguro**: si sigue sin rellenar,
pregunta al humano antes de dar por buena una cifra — no la asumas.

Las convenciones del código bajo test (uv, layout, tipado, docstrings) están en `dev-python-coding`.

## Framework y estructura

- Framework: **pytest**. No uses `unittest` para tests nuevos, aunque el módulo bajo test lo importe.
- `tests/` refleja la estructura de `src/[paquete]/`: a `src/[paquete]/servicios/pedidos.py` le
  corresponde `tests/servicios/test_pedidos.py`.
- Un fichero de test por módulo. Si un fichero de test crece hasta ser inmanejable, la señal suele ser
  que el módulo bajo test hace demasiadas cosas — dilo en vez de partir el test en dos a ciegas.
- Fixtures compartidas en el `conftest.py` del nivel más bajo que las necesite, no en la raíz por
  defecto.

## Comando

```bash
uv run pytest -q
```

Corre también automáticamente en el hook `Stop` (`.claude/hooks/stop_run_tests.sh`), así que verás el
resultado antes de dar cualquier tarea por cerrada. Un `Stop` en rojo no se ignora.

## Mockeo de dependencias externas

- **Las conexiones a base de datos se mockean siempre** en los tests unitarios. Un test unitario nunca
  abre una conexión real ni depende de que haya una BD levantada.
- Lo mismo aplica a llamadas HTTP salientes, sistema de ficheros fuera de `tmp_path` y reloj del
  sistema.
- Si un escenario necesita una BD real para tener valor (integridad referencial, comportamiento del
  motor, una migración), no lo fuerces como unitario: es un test de integración, y su ejecución en CI
  depende de que el workflow lo soporte. Márcalo con un marker de pytest y dilo explícitamente.

## Criterio de cierre (regla dura)

**Todo endpoint o función de negocio nuevo requiere al menos un test antes de que su tarea se marque
como cerrada en `tasks.md`.** No hay excepción por trivialidad.

Esto es coherente con —y anterior a— la auditoría de la skill `critic-verifications` (paso 4.4 del
ciclo): que una tarea tenga test no basta para cerrarla si además exige UAT humana, pero que no lo
tenga sí basta para no cerrarla.

Al menos un caso por cada uno de estos tres, cuando apliquen a lo que estás probando:

1. El camino feliz declarado en el requisito.
2. El fallo esperado (entrada inválida, permiso denegado, recurso inexistente) y que devuelve el error
   correcto, no uno genérico.
3. El límite o caso frontera que la spec mencione (colección vacía, valor cero, concurrencia).

## Cobertura

- Objetivo: el valor del perfil del proyecto.
- La cobertura es un suelo, no una meta: no escribas tests que solo ejecutan líneas para subir el
  número. Si para llegar al objetivo hay que testear código sin valor de negocio, plantea si ese
  código debería existir.

# SAST Automation Engine: Static Application Security Testing

**Un motor de análisis estático de código de alta fidelidad, diseñado para la detección temprana de vulnerabilidades de seguridad y deuda técnica en el ciclo de vida de desarrollo (SDLC).**

## 1. Arquitectura y Mecanismo de Análisis

El **SAST Automation Engine** no es un simple _linter_ basado en expresiones regulares. Utiliza **Semgrep** como núcleo de análisis, lo que permite una comprensión semántica del código mediante **Árboles de Sintaxis Abstracta (AST)**.

### Diferenciación Técnica (Regex vs. AST)

|Capacidad|Búsqueda Tradicional (Grep/Regex)|SAST Engine (AST)|
|---|---|---|
|**Contexto**|Ignorante del contexto. Detecta texto plano.|Comprende variables, flujo de datos y alcance de funciones.|
|**Precisión**|Alta tasa de Falsos Positivos.|**Alta Fidelidad.** Reduce el ruido al entender la lógica del código.|
|**Detección**|Solo patrones textuales exactos.|Variaciones semánticas (ej. `x = 1; y = x` es igual a `y = 1`).|


### Cobertura de Riesgos (Ruleset Avanzado)

El motor implementa reglas de alta precisión para arquitecturas modernas (Cloud/Microservicios):

|Categoría|Patrones Detectados|
|---|---|
|**Secretos (CWE-798)**|Claves de AWS, Stripe, Slack, Google API y Private Keys (Regex Avanzado).|
|**Inyección SQL/NoSQL (CWE-89)**|Concatenación insegura en SQL y patrones vulnerables en consultas MongoDB/NoSQL.|
|**Riesgos Cloud/API (SSRF/XXE)**|Peticiones HTTP con URLs controladas por usuario (SSRF) y parseo XML inseguro (XXE).|
|**Deserialización (CWE-502)**|Uso peligroso de `pickle`, `yaml.load` o deserializadores que permiten RCE.|
|**Criptografía (CWE-327)**|Uso de algoritmos obsoletos (MD5, SHA1) y generadores aleatorios débiles.|
|**Configuración**|Modo `debug=True` en producción y verificación SSL deshabilitada.|

## 3. Guía de Despliegue y Ejecución

### 3.1. Ejecución Local (Developer Workstation)

Se recomienda la ejecución _pre-commit_ para sanear el código antes de enviarlo al repositorio remoto.

**Requisitos:**

- Python 3.7+
    
- `pip`
    

**Comando de Inicialización:** El _wrapper_ `scan-code.sh` gestiona la instalación efímera de dependencias si no se detectan en el sistema.

```
# Asignar permisos de ejecución
chmod +x scripts/sast/scan-code.sh

# Ejecutar análisis (Bloqueante ante errores)
./scripts/sast/scan-code.sh
```

### 3.2. Ejecución Dockerizada (Entornos Aislados)

Para entornos donde no se desee instalar Python/Semgrep en el host, utilice la imagen oficial:

```
docker run --rm -v "${PWD}:/src" returntocorp/semgrep \
    semgrep scan --config /src/scripts/sast/ruleset.yml --error
```

#### 🔴 Caso de Fallo (Bloqueo de Pipeline)
El motor detiene la ejecución si detecta riesgos críticos.

![Fallo en Terminal - Quality Gate](assets/dast_dirty.png)

#### 🟢 Caso de Éxito (Clean Code)
Si el código cumple con los estándares, el motor aprueba el paso.

![Código Limpio SAST](assets/dast_clean.png)

## 4. Integración en Pipeline CI/CD (Quality Gate)

El motor está diseñado para actuar como un **Quality Gate Bloqueante**. Retorna un código de salida `1` si detecta vulnerabilidades de severidad `ERROR`, deteniendo el despliegue a producción.

### GitHub Actions (Producción)

```
name: Security Audit (SAST)
on: [pull_request, push]

jobs:
  sast-analysis:
    name: Semgrep Security Scan
    runs-on: ubuntu-latest
    container:
      image: returntocorp/semgrep

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Ejecutar Motor SAST
        run: |
          semgrep scan \
            --config ./scripts/sast/ruleset.yml \
            --json --output sast-report.json \
            --error \
            .

      - name: Archivar Evidencia
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: sast-audit-report
          path: sast-report.json
```

## 5. Gestión de Hallazgos y Excepciones

### 5.1. Interpretación de Reportes

El motor genera evidencia en `./reports/` con formato JSON estándar, compatible con:

- **DefectDojo** (Gestión de Vulnerabilidades).
    
- **GitLab Security Dashboard**.
    
- **SonarQube** (vía plugin de importación genérico).
- 
    
### Detalle Técnico de Vulnerabilidades
El reporte incluye la línea de código exacta, la regla violada y la severidad:

![Detalle de Hallazgos SAST](assets/dast_dirty_details1.png)

### 5.2. Manejo de Falsos Positivos (Triage)

En ingeniería de seguridad, los falsos positivos son inevitables. Para suprimirlos de manera documentada:

**Opción A: Supresión en Código (Recomendada)** Agregue un comentario en la línea afectada explicando la justificación.

```
# nosemgrep: sql-injection-concatenation
query = "SELECT * FROM fixed_table" # Justificación: Tabla constante, no input de usuario
```

**Opción B: Ajuste de Reglas** Modifique `scripts/sast/ruleset.yml` para refinar el patrón o excluir rutas específicas (`paths: exclude: ...`).

## 6. Mantenimiento y Soporte

- **Actualización de Reglas:** El equipo de AppSec revisará trimestralmente el `ruleset.yml` para incorporar nuevos patrones de ataque (Zero-Days).
    
- **Soporte:** Para reportar reglas rotas o sugerir nuevas detecciones, abra un _Issue_ con la etiqueta `component:sast`.
    


**Departamento de Seguridad de Producto | Super App Security Kit**

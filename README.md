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

## 2. Inteligencia de Amenazas (Custom Ruleset)

El motor opera con una configuración de reglas personalizada (`ruleset.yml`) diseñada específicamente para mitigar riesgos en arquitecturas **Fintech**.

### Cobertura de Riesgos Críticos (Mapeo OWASP/CWE)

1. **Gestión de Secretos (CWE-798):**
    
    - Detección de patrones de alta entropía y prefijos de proveedores (AWS `AKIA`, Stripe `sk_live`).
        
    - Validación de entropía para detectar claves privadas RSA/PEM.
        
2. **Prevención de Inyección (OWASP A03):**
    
    - **SQLi:** Identificación de concatenación de cadenas no sanitizadas en drivers de base de datos (Python DB-API, JDBC, Node-PG).
        
    - **RCE:** Detección de uso de funciones de ejecución de sistema (`os.system`, `exec`, `eval`) con input no confiable.
        
3. **Criptografía y Autenticación (OWASP A02/A07):**
    
    - Bloqueo de primitivas criptográficas obsoletas (MD5, SHA1, DES).
        
    - Detección de generadores de números aleatorios no seguros (`math.random` vs `crypto.random`).
        
    - Validación de configuración JWT (algoritmo `None` prohibido).
        

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
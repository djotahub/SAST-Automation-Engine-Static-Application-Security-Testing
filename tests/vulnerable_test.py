import hashlib
import os
import subprocess
import random
import pickle
import yaml
import requests
from flask import Flask, request

app = Flask(__name__)

# ==============================================================================
# CATEGORÍA 1: SECRETOS HARDCODEADOS (CWE-798)
# ==============================================================================

# VIOLACIÓN: AWS Access Key
AWS_ACCESS_KEY = "AKIA1234567890ABCDEF"

# VIOLACIÓN: Stripe Live Key
STRIPE_KEY = "sk_live_51LbZbZbZbZbZbZbZbZbZbZb"

# VIOLACIÓN: Private Key Header
RSA_PRIVATE_KEY = """-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA3Tz2mr7SZiAMfQyuvBjM9Oi..
...
-----END RSA PRIVATE KEY-----"""

# VIOLACIÓN: Slack Token
SLACK_TOKEN = "xoxb-123456789012-1234567890123-AbCdEfGhIjKlMnOpQrStUvWx"


# ==============================================================================
# CATEGORÍA 2: INYECCIÓN (SQLi & RCE) (CWE-89, CWE-78)
# ==============================================================================

def login_user_unsafe(cursor, username):
    # VIOLACIÓN: Inyección SQL por concatenación directa
    query = "SELECT * FROM users WHERE name = '" + username + "'"
    cursor.execute(query)

def search_product_unsafe(cursor, product_id):
    # VIOLACIÓN: Inyección SQL por f-string
    query = f"SELECT * FROM products WHERE id = {product_id}"
    cursor.execute(query)

def system_maintenance():
    # VIOLACIÓN: Ejecución de comandos del SO (RCE)
    user_input = request.args.get('cmd')
    os.system("echo " + user_input)

def backup_database():
    # VIOLACIÓN: Subprocess con shell=True
    filename = request.args.get('file')
    subprocess.call(f"tar -czf {filename} /var/www/html", shell=True)

def dynamic_code_execution():
    # VIOLACIÓN: Uso de eval()
    code = request.args.get('code')
    eval(code)


# ==============================================================================
# CATEGORÍA 3: CRIPTOGRAFÍA DÉBIL (CWE-327)
# ==============================================================================

def check_integrity_weak(data):
    # VIOLACIÓN: Hashing Débil (MD5)
    return hashlib.md5(data.encode()).hexdigest()

def generate_token_weak():
    # VIOLACIÓN: Generador de números aleatorios no criptográfico
    # Se debería usar 'secrets' o 'os.urandom'
    token = random.random()
    return f"token-{token}"


# ==============================================================================
# CATEGORÍA 4: CONFIGURACIÓN INSEGURA Y EXPOSICIÓN DE DATOS
# ==============================================================================

def call_external_api():
    # VIOLACIÓN: Verificación SSL deshabilitada (MitM Risk)
    requests.get('https://api.example.com', verify=False)

def log_sensitive_data(password, credit_card):
    # VIOLACIÓN: Logging de información sensible (PII/Credenciales)
    print(f"User login attempt with password: {password}")
    app.logger.info(f"Processing payment for CC: {credit_card}")


# ==============================================================================
# CATEGORÍA 5: DESERIALIZACIÓN INSEGURA (CWE-502)
# ==============================================================================

def load_user_data(data):
    # VIOLACIÓN: Pickle permite ejecución arbitraria de código
    return pickle.loads(data)

def parse_config(yaml_data):
    # VIOLACIÓN: yaml.load es inseguro por defecto en versiones viejas
    # Se debe usar yaml.safe_load()
    return yaml.load(yaml_data, Loader=yaml.Loader)


if __name__ == '__main__':
    # VIOLACIÓN: Modo Debug activado en producción
    app.run(debug=True)

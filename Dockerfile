# =============================================
# DOCKERFILE VULNERABLE - LABORATORIO TRIVY
# =============================================
#
# OBJETIVO: Identificar y corregir los problemas de seguridad
# que detecta Trivy para que el escaneo pase sin errores.
#
# LISTADO DE ACCIONES A REALIZAR:
#
# [ ] 1. Cambiar la imagen base debian:10 (EOL) por debian:12-slim
#        → Elimina la mayoría de CVEs HIGH/CRITICAL
#
# [ ] 2. Unificar los RUN de apt-get en un solo comando encadenado
#        → apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*
#        → Menos capas, sin caché residual, imagen más ligera
#
# [ ] 3. Eliminar el secreto hardcodeado (SECRET_KEY=...)
#        → Los secretos nunca van en la imagen; usar variables de entorno en runtime
#
# [ ] 4. Activar el usuario no-root ya creado (appuser)
#        → Añadir USER appuser antes del CMD
#
# [ ] 5. Reemplazar el CMD con la backdoor de netcat
#        → Sustituir por un servidor legítimo, p.ej. python3 -m http.server
#
# =============================================

# === IMAGEN BASE ===
# Cambiar esta imagen base (debian:13-slim es más moderna y segura)
# FROM debian:11-slim
FROM debian:13-slim

# === INSTALACIÓN DE PAQUETES ===
# Cada RUN es una capa nueva → imagen más grande, cache ineficiente
# RUN apt-get update
# RUN apt-get install -y openssl
# Se han quitado estos paquetes inseguros (curl, wget) ya no pasan el escaneo de Trivy (CVE's críticas)
# RUN apt-get install -y curl
# RUN apt-get install -y wget
# RUN apt-get install -y netcat-traditional
# Sin rm -rf /var/lib/apt/lists/* → la caché de apt se queda en la imagen

# Un único RUN encadenado - limpieza de la caché de apt - menos capas, imagen más ligera
# Instalamos python3 porque lo vamos a usar en el CMD, aunque sea un punto opcional de la práctica, porque así el 
# comando de inicio será seguro. Ponemos --no-install-recommends oara no arrastrar paquetes extra que aumentan el tamaño
# y aumentan el riesgo de ataque
# No instalamos netcat, porque no lo vamos a usar
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 && \
    rm -rf /var/lib/apt/lists/*

# === USUARIO NO-ROOT ===
# Crear usuario no-root y cambiar a él
RUN useradd -m -u 1001 appuser


# === SECRETOS (MALÍSIMA PRÁCTICA) ===
# Eliminar completamente esta línea
# RUN echo 'SECRET_KEY=super_secret_key_123' > /root/.env

COPY index.html /var/www/html/index.html

# === INFORMACIÓN DEL SISTEMA ===
# Eliminar esta línea (no debe quedar rastro del host)
# RUN uname -a > /etc/banner.txt

# Exponemos el puerto 8080 porque los puertos por debejo de 1024 son piviliged y solo puede
# vincularlos root. El user appuser, a priori, no puedo usarlo
# EXPOSE 80
EXPOSE 8080

# === USUARIO NO-ROOT ANTES DEL CMD ===
USER appuser

# === COMANDO DE INICIO ===
# Reemplazar por un comando seguro
# CMD ["sh", "-c", "while true; do nc -l -p 80 -e /bin/bash; done"]
CMD ["python3", "-m", "http.server", "8080"]

# =============================================
# RESUMEN DE CAMBIOS RECOMENDADOS:
# - Imagen base moderna y mínima
# - Usuario no-root
# - Sin secretos en la imagen
# - Menos capas (mejor cache y seguridad)
# - CMD seguro
# =============================================

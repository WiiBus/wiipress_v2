#!/bin/sh

# Charger les paramètres
company=$(grep '"company"' /www/wiipress/params.json | cut -d':' -f2 | tr -d ' ",')
serialNumber=$(grep '"serialNumber"' /www/wiipress/params.json | cut -d':' -f2 | tr -d ' ",')
urlRedirect=$(grep '"urlRedirect"' /www/wiipress/params.json | cut -d':' -f2- | tr -d ' ",')

if [ -z "$company" ] || [ -z "$serialNumber" ] || [ -z "$urlRedirect" ]; then
    echo "HTTP/1.1 500 Internal Server Error"
    echo "Content-Type: text/plain"
    echo
    echo "Error: Unable to read params.json"
    exit 1
fi

# Générer le token
token=$(echo -n "$company|$serialNumber" | base64)

# Construire l'URL finale
finalURL="${urlRedirect}?control_param=${token}"

# Envoyer la réponse HTTP de redirection
echo "HTTP/1.1 302 Found"
echo "Location: $finalURL"
echo "Content-Type: text/html"
echo

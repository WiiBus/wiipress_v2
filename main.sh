-- Chemin vers le script shell
local shell_script = "/www/authenticate-requests-v2/main.sh"

-- Fonction pour exécuter le script shell
local function execute_shell(script)
    local handle = io.popen(script .. " 2>&1") -- Redirige les erreurs standard vers la sortie standard
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Fonction principale appelée par uhttpd
function handle_request(env)
    -- Exécuter le script shell
    local output = execute_shell(shell_script)
    
    -- Extraire l'URL de redirection depuis la sortie du script shell
    local redirect_url = output:match("Location: ([^\r\n]+)")
    if not redirect_url then
        -- Si l'URL de redirection n'est pas trouvée, afficher un message d'erreur
        uhttpd.send("Status: 500 Internal Server Error\r\n")
        uhttpd.send("Content-Type: text/plain\r\n\r\n")
        uhttpd.send("Failed to find redirection URL in script output.")
        return
    end

    -- Envoyer une redirection HTTP 302
    uhttpd.send("Status: 302 Found\r\n")
    uhttpd.send("Location: " .. redirect_url .. "\r\n")
    uhttpd.send("Content-Type: text/html\r\n\r\n")
    uhttpd.send("<html><body>You are being redirected to <a href='" .. redirect_url .. "'>" .. redirect_url .. "</a>.</body></html>")
end

root@WiiBus:/www/authenticate-requests-v2# cat main.
main.lua  main.sh
root@WiiBus:/www/authenticate-requests-v2# cat main.sh 
#!/bin/sh

# Charger les paramètres
company=$(grep '"company"' /www/authenticate-requests-v2/params.json | cut -d':' -f2 | tr -d ' ",')
serialNumber=$(grep '"serialNumber"' /www/authenticate-requests-v2/params.json | cut -d':' -f2 | tr -d ' ",')
urlRedirect=$(grep '"urlRedirect"' /www/authenticate-requests-v2/params.json | cut -d':' -f2- | tr -d ' ",')

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

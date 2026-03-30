#!/bin/bash

# ==============================================
# Script per il riavvio del router Netgear D7000
# Requisiti: curl
# ==============================================

# Configurazione IP del router, nome utente e password
ROUTER_IP="192.168.2.1"
USER="admin"
PASS="password"

# Controllo dipendenze
if ! command -v curl &> /dev/null; then
    echo -e "Errore: 'curl' non è installato."
    exit 1
fi

echo "--- Step 1: Ottenimento Session ID ---"
# Usiamo tr -d '\r' per pulire la stringa da caratteri invisibili
SESSION=$(curl -s -i --user "$USER:$PASS" "http://$ROUTER_IP/reboot.htm" \
    | grep -i "Set-Cookie" \
    | grep -o 'sessionid=[^;]*' \
    | tr -d '\r')

echo "Session ottenuta: [$SESSION]"

if [ -z "$SESSION" ]; then
    echo "Errore: nessun sessionid ricevuto"
    exit 1
fi

echo "--- Step 2: Estrazione Token ID ---"
# Puliamo anche l'ID per sicurezza
ID=$(curl -s --user "$USER:$PASS" -H "Cookie: $SESSION" "http://$ROUTER_IP/reboot.htm" \
    | grep -o 'setup.cgi?id=[^"]*' \
    | cut -d'=' -f2 \
    | tr -d '\r')

if [ -z "$ID" ]; then
    echo "Errore: Impossibile recuperare il token ID."
    exit 1
fi

echo "Token ID ottenuto: [$ID]"

echo "--- Step 3: Invio comando Reboot ---"
# Aggiungiamo esplicitamente il Content-Type e usiamo --data-binary per evitare manipolazioni
curl -v -w "\nHTTP status: %{http_code}\n" \
    --user "$USER:$PASS" \
    -H "Cookie: $SESSION" \
    -H "Referer: http://$ROUTER_IP/reboot.htm" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "todo=reboot&yes=Yes" \
    "http://$ROUTER_IP/setup.cgi?id=$ID"

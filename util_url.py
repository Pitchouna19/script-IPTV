from flask import Flask, redirect
import requests

app = Flask(__name__)

@app.route('/video/<video_id>', methods=['GET'])
def get_final_url(video_id):
    base_url = f"https://vavoo.to/play/{video_id}/index.m3u8"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    }

    try:
        response = requests.get(base_url, headers=headers, allow_redirects=True)

        # Vérifier le statut de la réponse
        if response.status_code == 200:
            # Rediriger vers l'URL finale
            return redirect(response.url, code=302)
        else:
            return f"Erreur : Code d'état {response.status_code}", response.status_code
    except Exception as e:
        return f"Une erreur est survenue : {e}", 500

if __name__ == '__main__':
    app.run(debug=True, port=5050)  # Exécuter le serveur sur le port 5000

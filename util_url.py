from flask import Flask, redirect
import requests

app = Flask(__name__)

# Dictionnaire pour stocker les liens de redirection et leur compteur
redirect_cache = {}

@app.route('/video/<video_id>', methods=['GET'])
def get_final_url(video_id):
    base_url = f"https://vavoo.to/play/{video_id}/index.m3u8"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    }

    # Vérifier si l'URL est déjà en cache
    if video_id in redirect_cache:
        # Incrémenter le compteur
        redirect_cache[video_id]['count'] += 1
        
        # Si le compteur est inférieur ou égal à 3, retourner l'URL en cache
        if redirect_cache[video_id]['count'] <= 3:
            print(f"Cache hit for video_id: {video_id}, URL: {redirect_cache[video_id]['url']}, Count: {redirect_cache[video_id]['count']}")
            return redirect(redirect_cache[video_id]['url'], code=302)

        else:
            # Si le compteur dépasse 3, supprimer l'entrée de cache
            print(f"Cache expired for video_id: {video_id}, removing from cache.")
            del redirect_cache[video_id]

    # Si l'URL n'est pas en cache ou si le compteur a dépassé 3, effectuer la requête
    try:
        print(f"Making a request for video_id: {video_id}")
        response = requests.get(base_url, headers=headers, allow_redirects=True)

        # Vérifier le statut de la réponse
        if response.status_code == 200:
            # Ajouter l'URL à la mémoire cache avec un compteur initialisé à 1
            redirect_cache[video_id] = {'url': response.url, 'count': 1}
            print(f"Response for video_id: {video_id}, URL: {response.url}, Count: 1 (cached)")
            return redirect(response.url, code=302)
        else:
            return f"Erreur : Code d'état {response.status_code}", response.status_code
    except Exception as e:
        return f"Une erreur est survenue : {e}", 500

if __name__ == '__main__':
    app.run(debug=True, port=5050)  # Exécuter le serveur sur le port 5050

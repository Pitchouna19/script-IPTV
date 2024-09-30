const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json());

app.post('/update', (req, res) => {
    const command = '/usr/local/bin/update_vavoo.sh'; // Commande à exécuter

    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.error(`Erreur lors de l'exécution: ${error}`);
            return res.status(500).send('Erreur lors de l\'exécution');
        }

        console.log(`Commande exécutée: ${stdout}`);
        res.send('Mise à jour réussie');
    });
});

// Nouveau point de terminaison pour obtenir la date de modification de 'channel.json'
app.get('/last-modified', (req, res) => {
    const filePath = path.join(__dirname, 'channel.json');

    fs.stat(filePath, (err, stats) => {
        if (err) {
            console.error('Erreur lors de la lecture du fichier:', err);
            return res.json({ message: 'Aucune information' });
        }

        res.json({ lastModified: stats.mtime });
    });
});

app.post('/save-xtream', (req, res) => {
    const { domaine, port } = req.body;

    if (!domaine || !port) {
        return res.status(400).send('Domaine ou port manquant');
    }

    const data = {
        domaine,
        port
    };

    const filePath = path.join(__dirname, 'xtream.json');

    fs.writeFile(filePath, JSON.stringify(data, null, 2), (err) => {
        if (err) {
            console.error('Erreur lors de l\'enregistrement du fichier:', err);
            return res.status(500).send('Erreur lors de l\'enregistrement des informations');
        }

        console.log('Informations enregistrées avec succès');
        res.status(200).send('Informations enregistrées avec succès');
    });
});

app.get('/nginx-info', (req, res) => {
    // Commande pour obtenir la version NGINX
    exec('nginx -V 2>&1', (error, stdout, stderr) => {
        if (error) {
            console.error('Erreur lors de la récupération de la version NGINX:', error);
            return res.status(500).send('Erreur lors de la récupération de la version NGINX');
        }

        // Récupérer la version depuis stderr
        const versionMatch = stderr.match(/nginx version:\s*(nginx\/\d+\.\d+\.\d+.*)/);
        const version = versionMatch ? versionMatch[1] : 'Version inconnue';

        // Chemin du fichier NGINX à vérifier
        const nginxFilePath = '/etc/nginx/sites-available/clients';

        // Récupérer la date de modification du fichier NGINX
        fs.stat(nginxFilePath, (err, stats) => {
            if (err) {
                console.error('Erreur lors de la lecture du fichier NGINX:', err);
                return res.status(500).send('Erreur lors de la récupération des informations NGINX');
            }

            res.json({ version, lastModified: stats.mtime });
        });
    });
});

// Démarrer le serveur sur le port 3000
app.listen(3000, () => {
    console.log('Serveur en écoute sur le port 3000');
});

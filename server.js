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

        // Exécution du script après la sauvegarde du fichier
        exec('/usr/local/bin/domaine_script.sh', (error, stdout, stderr) => {
            if (error) {
                console.error(`Erreur lors de l'exécution du script: ${error.message}`);
                console.error(`Détails supplémentaires: ${error.stack}`);
                return res.status(500).send(`Erreur lors de l'exécution du script : ${error.message}`);
            }

            if (stderr) {
                console.error(`Erreur dans le script: ${stderr}`);
            }

            console.log(`Script exécuté avec succès: ${stdout}`);
            res.status(200).send(`Informations enregistrées et script exécuté avec succès: ${stdout}`);
        });
    });
});

app.get('/nginx-info', (req, res) => {
    // Exécute la commande nginx -V et redirige le résultat vers nginx.conf
    exec('openresty -V 2>&1 | tee /var/www/html/nginx.conf', (error) => {
        if (error) {
            console.error('Erreur lors de la récupération de la version NGINX:', error);
            return res.status(500).send('Erreur lors de la récupération de la version NGINX');
        }

        // Lire le fichier nginx.conf pour extraire les informations nécessaires
        fs.readFile('/var/www/html/nginx.conf', 'utf8', (err, data) => {
            if (err) {
                console.error('Erreur lors de la lecture du fichier nginx.conf:', err);
                return res.status(500).send('Erreur lors de la lecture du fichier nginx.conf');
            }

            // Extraire la version, OpenSSL et TLS SNI support enabled
            const versionMatch = data.match(/nginx version: (.+)/);
            const opensslMatch = data.match(/built with OpenSSL (.+)/);
            const tlsSniMatch = data.includes('TLS SNI support enabled') ? 'TLS SNI support enabled' : '';

            const version = versionMatch ? versionMatch[1] : 'Version inconnue';
            const openssl = opensslMatch ? `built with OpenSSL ${opensslMatch[1]}` : '';
            const tlsSni = tlsSniMatch;

            // Chemin du fichier NGINX à vérifier
            const nginxFilePath = '/etc/openresty/sites-available/clients';

            // Récupérer la date de modification du fichier NGINX
            fs.stat(nginxFilePath, (err, stats) => {
                if (err) {
                    console.error('Erreur lors de la lecture du fichier NGINX:', err);
                    return res.status(500).send('Erreur lors de la récupération des informations NGINX');
                }

                res.json({ version: `${version}\n${openssl}\n${tlsSni}`, lastModified: stats.mtime });
            });
        });
    });
});

// Route to get the content of the 'clients' file
app.get('/nginx-client-config', (req, res) => {
    const nginxFilePath = '/etc/openresty/sites-available/clients';

    fs.readFile(nginxFilePath, 'utf8', (err, data) => {
        if (err) {
            console.error('Erreur lors de la lecture du fichier NGINX:', err);
            return res.status(500).send('Erreur lors de la récupération du fichier NGINX');
        }

        res.json({ content: data });
    });
});

// Route to save the content back to the 'clients' file
app.post('/save-nginx-client-config', (req, res) => {
    const { content } = req.body;
    const nginxFilePath = '/etc/openresty/sites-available/clients';

    fs.writeFile(nginxFilePath, content, 'utf8', (err) => {
        if (err) {
            console.error('Erreur lors de la sauvegarde du fichier NGINX:', err);
            return res.status(500).send('Erreur lors de la sauvegarde du fichier NGINX');
        }

        res.send('Fichier NGINX sauvegardé avec succès');
    });
});


// Démarrer le serveur sur le port 3000
app.listen(3000, () => {
    console.log('Serveur en écoute sur le port 3000');
});

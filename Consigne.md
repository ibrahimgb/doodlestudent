# Projet TLC: Ops et Cloud

Le but du projet est de mettre en place une chaîne de déploiement automatisée d'une application Web développée dans des technologies cloud-native sur une infrastructure que vous pilotez.

L'application est une application de type doodle like qui offre la possibilité de déployer aussi une intégration avec un service de type etherpad pour la prise de notes de réunions. Nous souhaitons que vous fassiez au minimum le travail pour:
- Faciliter son déploiement à l'aide de containers
- Faciliter sa configurabilité au déploiement (serveur smtp à utiliser, connexion à l'etherpad, ...)
- Faciliter sa sécurisation au moment du déploiement

>Voici le [repo de code source](https://github.com/barais/doodlestudent) de cette application. Vous pouvez regarder le code source, le *back* est développé en [quarkus.io](https://quarkus.io/) et le front en [angular](https://angular.io/).
> <details>
> <summary>Vidéos de présentation</summary>
>
> - [Présentation des fonctionnalités de l'application](https://drive.google.com/file/d/1IxQC6lq0UPP_-n4IGt2TGvTRIO9M8enn/view?usp=sharing)
> - [Présentation de l'architecture de l'application](https://drive.google.com/file/d/16gqFYmhwok8GWgiOskYjP-oTeP_sDwu-/view?usp=sharing)
> - [Revue de code de l'application](https://drive.google.com/file/d/10RLkHWjJxnLi1ltRmNDCIymW9eM7Tn87/view?usp=sharing)
> - [Compréhension du projet]()
>
> </details>

Les tâches 1 à 4 décrivent le minimum à faire pour ce projet.
Vous devez ensuite choisir au moins deux des aventures proposées pour aller plus loin.

## Aventures au choix

- **Aventure 1**: Mettre en place un mécanisme de déploiement continu qui permette de déployer la nouvelle version de l'application automatiquement si un nouveau commit est activé sur le back ou le front. L'idée de ce travail est d'explorer les liens entre pratique devops (intégration/déploiement continu) et outil de déploiement en mode cloud native.
- **Aventure 2**: Mettre en place des outils de monitoring avancés de cette application et des dashboards associés à ce monitoring.
- **Aventure 3**: Utiliser K8S comme orchestrateur pour le déploiement de nos containers.
- **Aventure 4**: Mettre en place un identity provider et/ou une passerelle d'API pour faire de l'accounting sur l'API de l'application.

# Modalités de rendu

Tous les rendus TLC se font à travers le gitlab de l'ISTIC : https://gitlab2.istic.univ-rennes1.fr/

Si vous ne l'avez pas déjà fait, créez sur Gitlab ISTIC un groupe nommé `TLC_2025_<votre_nom>_<votre_prenom>` 

Pour chaque TP, vous devrez créer un projet dans ce groupe (il est fortement conseillé de fork le repo du projet en le plaçant dans votre groupe gitlab), nommé `TP<numero>_<votre_nom>_<votre_prenom>` et le projet finale nommé `Projet_<votre_nom>_<votre_prenom>`

Pour chaque TP, vous devrez ajouter votre enseignant en tant que membre du projet avec le rôle de "Reporter" pour permettre la correction.

## Backlog du projet

### Niveau 1: minimum à faire

[//]: # (- **Tâche 0**: Créer une machine virtuelle &#40;https://vm.istic.univ-rennes1.fr/ séléctionner **ubuntu20** comme image de base&#41; et demandez l'accès externe vers le port *80* &#40;http&#41; et *443* &#40;https&#41; de votre machine virtuelle par le [helpdesk, catégorie ISTIC-ESIR - Tous problèmes informatiques]&#40;https://assistance.univ-rennes1.fr/&#41;, l'accès au port 22 se fera au travers du [VPN]&#40;https://istic.univ-rennes1.fr/intranet/services#section-4&#41;. Partager moi l'adresse IP de la machine et le sous domaine souhaité [ici]&#40;https://forms.gle/a7EfKraasGpTYAXa6&#41; &#40;sous domaine de *diverse-team.fr*&#41;. &#40;Je mets jour quand c'est fait le [google doc joint]&#40;https://docs.google.com/spreadsheets/d/14Yv-3ujq9OL0HuYkj4Wlp9Piw5075b6iEKSf-yJWytc/edit?usp=sharing&#41;&#41;)


- **Tâche 1**: Fournir un ou plusieurs Dockerfile(s) et un ou plusieurs docker-compose(s) pour cette application permettant de facilement déployer et configurer l'application. (Faites un fork du projet avant.)

<details>
<summary>Liens utiles</summary>

- [Synchroniser votre fork GitHub](https://nearsoft.com/blog/how-to-synchronize-your-github-fork/)
- [Documentation Docker Compose](https://docs.docker.com/compose/)
- [Documentation Dockerfile](https://docs.docker.com/engine/reference/builder/)

</details>

:warning: Vous aurez du mal à avoir un fonctionnement correct à cette étape-là. En effet, le code du front va faire ces requêtes *REST* à la même adresse que celui qui lui a fourni le code html, css et js pour éviter les problèmes de CORS. Il est donc nécessaire de se forcer à configurer le serveur nginx qui délivre le front pour faire *proxy_pass* quand il reçoit une requête sur la route */api* ou une sous-route de */api*. Ne vous inquiétez pas, on configure cela à l'étape suivante.

- **Tâche 2**: Configurer le serveur Web du Front pour qu'il soit capable de servir de point d'entrée à l'ensemble des requêtes puis qu'il les *route* vers le bon service de Back. Il est possible de mettre en place un serveur Web spécifique pour gérer ce routing (on le nomme alors la gateway d'API). On peut aussi dans notre cas se servir du fichier nginx du front pour router les requêtes.

<details>
<summary>Exemples de fichiers de configuration nginx</summary>

```txt
server {
    listen       80;
    listen  [::]:80;
    server_name  doodle.tlc.fr;

    location /api {
        proxy_pass http://api:8080/api;
        proxy_set_header Host $http_host;
    }

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        try_files $uri $uri/ /index.html?$args;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

```txt
server {
    listen       80;
    listen  [::]:80;
    server_name  myadmin.tlc.fr;

    location / {
        proxy_pass http://myadmin:80;
        proxy_set_header Host $http_host;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

```txt
server {
    listen       80;
    listen  [::]:80;
    server_name  pad.tlc.fr;

    location / {
        proxy_pass http://etherpad:9001;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP  $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

</details>

- **Tâche 3**: Déployer correctement une première fois votre application en configurant convenablement la partie DNS pour le reverse proxy, letsencrypt pour le certificat côté serveur et ufw pour le firewall sur votre machine virtuelle.

En gros, vous allez prendre votre fichier docker-compose, votre fichier de configuration nginx, votre front et mettre cela sur votre VM. Mettre les bonnes variables de configuration dans ces deux fichiers. Vous aurez besoin soit de builder les images sur la VM soit de pushé vos images sur le docker_hub afin de pouvoir les *puller* depuis votre VM.

- **Tâche 4**: Documenter, à l'aide d'un diagramme de déploiement UML ou autre notation, le déploiement réalisé pour le moment sur votre machine virtuelle.

<details>
<summary>Vidéos d'aide</summary>

- [Construction d'un DockerFile pour le front]()
- [Construction d'un DockerFile pour le back]()
- [Définition d'un docker-compose pour le déploiement de l'application]()
- [Déploiement de l'application avec K8S]() ([note de présentation]())

</details>

Vous pouvez maintenant choisir au minimum deux de ces 4 aventures :

### Aventure 1: Déploiement continu à l'aide de gitlabCI et déploiement à l'aide de Docker

- **Aventure 1**: Mettre en place un mécanisme de déploiement continu qui permette de déployer la nouvelle version de l'application automatiquement si un nouveau commit est activé sur le back ou le front. Vous pourrez mettre en place votre outil d'intégration continue sur la même VM même si c'est une pratique que nous ne suivrions pas pour un déploiement réel. Vous avez le choix pour l'outil d'intégration continue.

<details>
<summary>Outils d'intégration continue</summary>

- Vous pouvez utiliser gitlabCI de l'ISTIC si vous avez mis le code dans un repo du gitlab de l'ISTIC. Vous pouvez alors créer votre propre runner gitlab ci (https://docs.gitlab.com/runner/) ou utiliser travis sur github ou les runners de gitlab.com. Vous pouvez aussi déployer un jenkins sur votre machine si vous préférez.

</details>

### Aventure 2: Chaîne de monitoring de l'application en production

- **Aventure 2**: Mettre en place la chaîne de monitoring de l'application à l'aide de Promotheus et grafana comme front. Mettre en place le sous domaine et le certificat letsencrypt pour grafana. Mettre en place munin pour la surveillance de votre machine virtuelle.

<details>
<summary>Liens utiles</summary>

- [Monitoring Quarkus avec Prometheus](http://www.mastertheboss.com/soa-cloud/quarkus/monitoring-quarkus-with-prometheus)

</details>

### Aventure 3: Utilisation de K8S comme orchestrateur d'un petit cluster

> Pour cette étape, il est conseillé de se construire son infra avec Vagrant at microk8s. Le playbook réalisé dans le TP ansible peut vous aider à mettre en place l'environnement.

- **Aventure 3**: Utiliser kubernetes pour déployer l'ensemble des micro-services. Le but est de pouvoir comparer et comprendre les abstractions supplémentaires fournies par kubernetes par rapport à un simple déploiement d'une application sur un seul noeud à l'aide de docker et docker-compose. En particulier, on souhaite ajouter de la redondance pour la partie back de l'application (redondance uniquement sur ce micro-service là. Surtout pas sur la BD relationnelle, c'est plus compliqué et pas complètement transparent). Déployer donc microk8s sur votre VM. Utiliser kubernetes pour mettre en place un minimum de redondance pour le back de l'application (on ne clusterisera pas la BD dans un premier temps).

<details>
<summary>Liens utiles</summary>

- [Microk8s](https://microk8s.io/)
-  Notes sur microk8s : voir fichier k8s.pdf 
    
</details>

### Aventure 4: Mise en place d'un outil d'authentification et d'une passerelle d'API

- **Aventure 4**: Mettre en place [keycloak](https://www.keycloak.org/getting-started/getting-started-docker) pour un accès sécurisé à vos ressources Web et/ou une passerelle d'API pour faire de l'accounting sur l'API de l'application. Je vous propose l'utilisation d'[ambassador](https://www.getambassador.io/).

<details>
<summary>Liens utiles</summary>

- [Ambassador API Gateway avec microk8s](https://blog.getambassador.io/explore-the-ambassador-api-gateway-with-microk8s-f75a7a295113)

</details>


:warning: Il va falloir lire beaucoup de documentation, poser beaucoup de questions, faire des schémas pour comprendre ce que vous êtes en train de faire. Utilisez les tickets github dès que quelque chose ne marche pas comme vous le souhaitez.

## Rendu Projet

Pour le rendu, je propose d'utiliser le formulaire suivant: https://forms.gle/NsBtwLK81CtYBDsN7. Comme d'habitude, un petit readme à la racine des différents repos.

Pensez bien à ranger votre dépôt git, à mettre des commentaires dans vos fichiers de configuration, à bien documenter vos choix et à expliquer ce que vous avez fait.

Au minimum, il faut avoir dans votre git les rendus pour les tâches 1 à 4.
- Plusieurs Dockerfile(s) pour le front et le back. Les propositions de Dockerfile _light_ seront mieux évaluées.
- Un docker-compose pour le déploiement de toute la stack: front, back, etc.
- Un fichier de configuration nginx pour le front.
- Explication de la stack accompagnée d'un diagramme.

- Pour chaque aventure choisies, les fichiers de configuration et les scripts nécessaires.


### Date de rendu **16/02 23h59 ferme**

...

## Other relevant videos

<details>
<summary>Vidéos</summary>

- [What are cloud native apps](https://www.youtube.com/watch?v=fp9_ubiKqFU)
- [Cloud native applications](https://www.youtube.com/watch?v=nyQAkR84RHM&ab_channel=ParallelWireless)
- [Cloud Native DevOps Explained](https://www.youtube.com/watch?v=FzERTm_j2wE)
- [What are Microservices?](https://www.youtube.com/watch?v=CdBtNQZH8a4)
- [Advantages of Using OpenAPI to design APIs](https://www.youtube.com/watch?v=Fyuk50fFllM&ab_channel=SmartBear)
- [What is DevOps?](https://www.youtube.com/watch?v=_I94-tJlovg&ab_channel=RackspaceTechnology)
- [What is Continuous Integration?](https://www.youtube.com/watch?v=1er2cjUq1UI&frags=wn)
- [What is Continuous Delivery?](https://www.youtube.com/watch?v=2TTU5BB-k9U)
- [What is Infrastructure as Code?](https://www.youtube.com/watch?v=zWw2wuiKd5o&list=PLOspHqNVtKACSagAEeIY20NMVLNeQ1ZJx&index=3&ab_channel=IBMCloud)
- [Cloud-native Java for this decade with Quarkus](https://www.youtube.com/watch?v=KJZt0uc5OiM)
- [Principles of Antifragile Software](https://www.youtube.com/watch?v=FXGWSyRtipY&ab_channel=MartinMonperrus)
- [Mastering Chaos - A Netflix Guide to Microservices](https://www.youtube.com/watch?v=CZ3wIuvmHeM&ab_channel=InfoQ)
- [Getting started with Chaos Engineering](https://www.youtube.com/watch?v=3Oc4-cMkGJY&ab_channel=NDCConferences)

</details>

## References

<details>
<summary>Références</summary>

[1] BALALAIE, Armin, HEYDARNOORI, Abbas, et JAMSHIDI, Pooyan. Microservices architecture enables devops: Migration to a cloud-native architecture. Ieee Software, 2016, vol. 33, no 3, p. 42-52.

[2] https://www.redhat.com/en/resources/eight-steps-cloud-native-application-development-brief

[3] D. S. Linthicum, "Cloud-Native Applications and Cloud Migration: The Good, the Bad, and the Points Between," in IEEE Cloud Computing, vol. 4, no. 5, pp. 12-14, September/October 2017, doi: 10.1109/MCC.2017.4250932.

</details>

## Questions réponses

<details>
<summary>Liens utiles</summary>

- [Comprendre la notion de nom de domaine]()
- [Mettre en place un serveur Web](https://www.youtube.com/watch?v=cfJh8vdKuQU&list=PLjwdMgw5TTLUnvhOKLcpCG8ORQsfE7uB4&ab_channel=Grafikart.fr)
- [Configurer nginx](https://www.youtube.com/watch?v=YD_exb9aPZU&ab_channel=Grafikart.fr)
- [Nginx: Mettre en place letsencrypt](https://www.youtube.com/watch?v=NXyE3mayrtg&ab_channel=Grafikart.fr)
- [Nginx : Se protéger des attaques Flood](https://www.youtube.com/watch?v=ge768xOLQJs&list=PLjwdMgw5TTLUnvhOKLcpCG8ORQsfE7uB4&index=22&ab_channel=Grafikart.fr)
- [Fail2ban c'est quoi](https://www.youtube.com/watch?v=-rmK50PbqCY&ab_channel=Grafikart.fr)
- [un firewall c'est quoi: configuration de ufw](https://www.grafikart.fr/tutoriels/ufw-696), [vidéo](https://www.youtube.com/watch?v=XnfMAU3zIew&ab_channel=Grafikart.fr)
- [une autre présentation de docker](https://www.youtube.com/watch?v=XgKOC6X8W28&ab_channel=Grafikart.fr)
- [Pas mal de tutos assez bien fait](https://www.youtube.com/c/grafikart/playlists)
- [POC en local avec Docker et Traefik](https://www.youtube.com/watch?v=QF4ZF857m44&ab_channel=TechworldwithNana)

</details>


<details>
<summary>Appendix</summary>

- :warning: **Tâche 2 bis (NON Obligatoire, UNIQUEMENT pour ceux que cela intéressent)**,

Pour servir d'API Gwateway, il y a un super projet que j'adore qui s'appelle **bunkerweb**. C'est un container docker avec nginx qui se configure au travers de variable d'environement et qui inclus de base plein de mécanisme de sécurité pour nginx, la génération des certificats ... mais il entraine pas mal de doc à lire.

:warning: **UNIQUEMENT pour ceux que cela intéressent (j'insite )**

configurer convenablement https://github.com/bunkerity/bunkerweb au sein de votre docker-compose pour sécuriser votre application. Tester localement le déploiement de l'application.

**nginx bunkerity/bunkerweb** va jouer le rôle de passerelle d'API, c'est-à-dire que toutes les requêtes passent par lui et il a la charge de fournir les fichiers html, css et js du front, mais aussi de servir de proxy vers les autres services.

Pour cela, il est nécessaire de configurer finement ce serveur nginx qui tourne dans ce container. Il faudra *monter* ce fichier de configuration au moment du lancement de ce container. (voir https://github.com/bunkerity/bunkerized-nginx/blob/700dfc0184f8d12e15f3ca3d6e5ca08befccd561/examples/wordpress/docker-compose.yml#L14)

Vous trouverez ci-dessous un exemple de fichier de configuration nginx (fichier api.conf par exemple dans le répertoire *server-confs* là où se trouve votre docker-compose.yml).

```txt
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

# L'idée ici est que toute requête qui arrive sur /api ou une sous
# route d'API passe par ici et en gros on fait un if selon que cette
# requête est arrivé sur l'adresse IP en demandant à parler à
# doodle.diverse-team.fr ou à  phpmyadmin.diverse-team.fr ou à
# pad.diverse-team.fr
location /api {
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
     proxy_set_header Connection "upgrade";
 if ($host = doodle.diverse-team.fr) {
  proxy_pass http://doodleback:8080$request_uri;
 }
 if ($host = pad.diverse-team.fr) {

  proxy_pass http://etherpad:9001$request_uri;
 }
 if ($host = phpmyadmin.diverse-team.fr) {
  proxy_pass http://myadmin$request_uri;
 }
}

# L'idée ici est que toute requête qui arrive sur / ou une sous
# route de / qui n'a pas été traité avant passe par ici et en gros
# on fait un if selon que cette requête est arrivé sur l'adresse IP
# en demandant à parler à  phpmyadmin.diverse-team.fr ou à
# pad.diverse-team.fr et pour tout le reste on fourni les ressources
# statiques du front

location / {
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection "upgrade";
  proxy_redirect off;
  proxy_set_header X-Real-IP  $remote_addr;
  proxy_set_header X-Forwarded-For $remote_addr;

  if ($host = pad.diverse-team.fr) {

  proxy_pass http://etherpad:9001$request_uri;
  }
  if ($host = phpmyadmin.diverse-team.fr) {
  proxy_pass http://myadmin$request_uri;
  }
  try_files $uri $uri/ /index.html;

}
```

Il est aussi nécessaire de configurer finement les variables d'environement de ce container. Je vous met un exemple avec des explications

```txt
    environment:
    # Ensemble des endpoints pour lequel il générera des certificats
      - SERVER_NAME=doodle.<Your_Domain>.fr pad.<Your_Domain>.fr phpmyadmin.<Your_Domain>.fr
      - SERVE_FILES=yes
      - DISABLE_DEFAULT_SERVER=no
    # Transmission de l'IP publique vers les containers
      - PROXY_REAL_IP=yes
#      - MAX_CLIENT_SIZE=100m
#      - USE_ANTIBOT=captcha
# Configuration de letencrypt
      - AUTO_LETS_ENCRYPT=yes
# redirect du 80 vers 443 automatique
      - REDIRECT_HTTP_TO_HTTPS=yes
      - USE_LIMIT_REQ=no
# Désactivation http2
      - HTTP2=no
# Paramétrage des entêtes http
      - FEATURE_POLICY=accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'none'; camera 'none'; display-capture 'none'; document-domain 'none'; encrypted-media 'none'; fullscreen 'none'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; midi 'none'; payment 'none'; picture-in-picture 'none'; speaker 'none'; sync-xhr 'self'; usb 'none'; vibrate 'none'; vr 'none'
  myadmin:
    image: phpmyadmin
#    ports:
#      - "8082:80"
    environment:
    # pour phpmyadmin url externe
      - PMA_ABSOLUTE_URI=https://<YOUR_PHPMYADMIN_URL>
```

</details>

/*  Requêtes SQL à exécuter sur la base cabotage.sqlite
 Exécution : 
    – ouvrir la base sqlite avec DBeaver (créer une nouvelle connection et chercher la base de données à ouvrir sur le disque local : cabotage.sqlite)
    – dans le menu Editeur SQL ouvrir ou créer un 'scriptSQL'
*/

-- Chercher 100 lignes de la table 'navigations' à parir de la ligne 201
SELECT *
FROM navigations n 
LIMIT 100 OFFSET 200;

-- Première année, dernière année, nombre de navigations
SELECT min(nANNEE), max(nANNEE), count(*)
FROM navigations n ;



-- requête jointure entre la table navigations 
-- et deux fois la table escales afin de disposer des codes des régions
SELECT n.*, e1.eREGION AS region_depart, e2.eREGION AS region_arrivee 
FROM navigations n, escales e1 , escales e2
WHERE n.nDEPART = e1.eESCALE
AND n.nARRIVEE = e2.eESCALE;


-- Créer une vue, i.e. une requête stockée
DROP VIEW IF EXISTS v_navigations_avec_regions;
CREATE VIEW v_navigations_avec_regions AS
SELECT n.*, e1.eREGION AS region_depart, e2.eREGION AS region_arrivee 
FROM navigations n LEFT JOIN escales e1  ON n.nDEPART = e1.eESCALE
LEFT JOIN escales e2 ON n.nARRIVEE = e2.eESCALE;


-- Une fois créée la vue peut être directement interrogée

SELECT *
FROM v_navigations_avec_regions vnar
LIMIT 10;



--- Regrouper les trajets par bateau et année, avec lieu de départ, arrivée, nombre étapes et frets
WITH tw1 as (SELECT nDEPART, region_depart, nNOMBATEAU, nANNEE 
FROM v_navigations_avec_regions n
WHERE nNUMETAP = 1
),tw2 as (SELECT nDEPART, region_depart, nNOMBATEAU, nANNEE  
FROM v_navigations_avec_regions n
WHERE nNUMETAP = 100
), tw3 as (SELECT nNOMBATEAU, nANNEE, count(*) - 1 as eff_etapes,  group_concat(nFRET) as frets
FROM navigations n
GROUP BY  nNOMBATEAU , nANNEE
)
SELECT tw1.nDEPART AS depart, tw1.region_depart as reg_depart, tw2.nDEPART AS arrivee, tw2.region_depart as reg_arrivee, 
tw1.nANNEE, tw1.nNOMBATEAU, eff_etapes, frets
FROM tw1, tw2, tw3
WHERE tw1.nNOMBATEAU = tw2.nNOMBATEAU
AND tw1.nANNEE = tw2.nANNEE
AND tw3.nNOMBATEAU = tw2.nNOMBATEAU
AND tw3.nANNEE = tw2.nANNEE
GROUP BY tw1.nDEPART, tw2.nDEPART, tw1.nANNEE, tw1.nNOMBATEAU
ORDER BY tw1.nANNEE, tw1.nNOMBATEAU ;

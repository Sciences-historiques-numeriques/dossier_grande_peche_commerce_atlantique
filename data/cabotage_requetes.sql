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
SELECT min(aANNEE), max(a	ANNEE), count(*)
FROM activitesbateaux a ;


-- aucun bateau utilisé deux fois pour une année
SELECT aNOMBATEAU, aANNEE, count(*)
FROM activitesbateaux
GROUP BY aNOMBATEAU , aANNEE 
HAVING count(*) > 1 ;

-- les bateaux les plus utilisés
SELECT aNOMBATEAU, min(aANNEE), max(aANNEE), count(*) as eff
FROM activitesbateaux
GROUP BY aNOMBATEAU
ORDER BY eff DESC ;


-- les armateurs les plus actifs et leurs bateaux
SELECT aARMEMENT , min(aANNEE), max(aANNEE), count(*) as eff, (GROUP_CONCAT(DISTINCT aNOMBATEAU))
FROM activitesbateaux
--WHERE aNOMBATEAU = 'ST FRANÇOIS '
GROUP BY aARMEMENT 
ORDER BY eff DESC ;



-- requête jointure entre la table navigations 
-- et deux fois la table escales afin de disposer des codes des régions
SELECT n.*, e1.eREGION AS region_depart, e2.eREGION AS region_arrivee 
FROM navigations n, escales e1 , escales e2
WHERE n.nDEPART = e1.eESCALE
AND n.nARRIVEE = e2.eESCALE;


-- Créer une vue, i.e. une requête stockée
DROP VIEW IF EXISTS v_navigations_avec_regions;
CREATE VIEW v_navigations_avec_regions AS
SELECT n.*, e1.eREGION AS region_depart, e2.eREGION AS region_arrivee, f.fNATURE, n.nFRET 
FROM navigations n LEFT JOIN escales e1  ON n.nDEPART = e1.eESCALE
LEFT JOIN escales e2 ON n.nARRIVEE = e2.eESCALE
LEFT JOIN frets f ON f.fFRET = n.nFRET;


-- Une fois créée la vue peut être directement interrogée

SELECT *
FROM v_navigations_avec_regions vnar
LIMIT 10;



---- Requête jointure entre voyages 8appelés 'activitésbateaux' et étapes (appelées 'navigations')
--      Noter qu'il manque un lien direct dans le modèle et dans la base de données entre les voyages 
--         et les étapes de chaque voyage  
 
---   Création de la vue correspondante 
DROP VIEW IF EXISTS v_voyages_etapes ;
CREATE VIEW v_voyages_etapes AS
SELECT a.*, n.pk_navigations, n.nNUMETAP, n.nDEPART, n.region_depart, n.nARRIVEE, n.region_arrivee, n.fNATURE, n.nFRET
FROM activitesbateaux a, v_navigations_avec_regions n
WHERE a.aNOMBATEAU = n.nNOMBATEAU
AND a.aANNEE = n.nANNEE
ORDER BY a.aANNEE, a.aNOMBATEAU, n.nNUMETAP ; 


SELECT *
FROM v_voyages_etapes
LIMIT 50;


--- Regrouper trajets par bateau et année, avec lieu de départ, arrivée, nombre étapes et frets
WITH tw1 as (SELECT nDEPART, region_depart, aNOMBATEAU, aANNEE, aARMEMENT, fNATURE
FROM v_voyages_etapes n
WHERE nNUMETAP = 1
),tw2 as (SELECT nDEPART, region_depart, aNOMBATEAU, aANNEE  
FROM v_voyages_etapes n
WHERE nNUMETAP = 100
), tw3 as (SELECT aNOMBATEAU, aANNEE, count(*) - 1 as eff_etapes,  group_concat(nFRET) as frets
FROM v_voyages_etapes n
GROUP BY aNOMBATEAU , aANNEE
)
SELECT tw1.nDEPART AS depart, tw1.region_depart as reg_depart, tw2.nDEPART AS arrivee, tw2.region_depart as reg_arrivee, 
tw1.aANNEE, tw1.aNOMBATEAU, tw1.aARMEMENT, eff_etapes, fNATURE
FROM tw1, tw2, tw3
WHERE tw1.aNOMBATEAU = tw2.aNOMBATEAU
AND tw1.aANNEE = tw2.aANNEE
AND tw3.aNOMBATEAU = tw2.aNOMBATEAU
AND tw3.aANNEE = tw2.aANNEE
GROUP BY tw1.nDEPART, tw2.nDEPART, tw1.aANNEE, tw1.aNOMBATEAU
ORDER BY tw1.aANNEE, tw1.aNOMBATEAU ;


----  Requête pour exploitation dans notebook: 
--  Regrouper trajets par bateau et année, avec lieu de départ, arrivée, nombre étapes et frets ||| puis ajouter les escales


DROP VIEW IF EXISTS v_etapes_trajets ;
CREATE VIEW v_etapes_trajets AS
WITH tw1 as (SELECT nDEPART, region_depart, aNOMBATEAU, aANNEE, aARMEMENT, aACTIVITE, nFRET, fNATURE
FROM v_voyages_etapes n
WHERE nNUMETAP = 1
),tw2 as (SELECT nDEPART, region_depart, aNOMBATEAU, aANNEE  
FROM v_voyages_etapes n
WHERE nNUMETAP = 100
), tw3 as (SELECT aNOMBATEAU, aANNEE, count(*) - 1 as eff_etapes,  group_concat(nFRET) as frets
FROM v_voyages_etapes n
GROUP BY aNOMBATEAU , aANNEE
), tw4 AS (
SELECT tw1.nDEPART AS depart, tw1.region_depart as reg_depart, tw2.nDEPART AS arrivee, tw2.region_depart as reg_arrivee, 
tw1.aANNEE, tw1.aACTIVITE, tw1.nFRET, tw1.fNATURE, tw1.aNOMBATEAU, tw1.aARMEMENT, eff_etapes, frets
FROM tw1, tw2, tw3
WHERE tw1.aNOMBATEAU = tw2.aNOMBATEAU
AND tw1.aANNEE = tw2.aANNEE
AND tw3.aNOMBATEAU = tw2.aNOMBATEAU
AND tw3.aANNEE = tw2.aANNEE
GROUP BY tw1.nDEPART, tw2.nDEPART, tw1.aANNEE, tw1.aNOMBATEAU
ORDER BY tw1.aANNEE, tw1.aNOMBATEAU )
SELECT s.sSTATUT, tw4.*,  n2.nNUMETAP, n2.nDEPART, n2.nARRIVEE 
FROM tw4, navigations n2, statutsbateaux s 
WHERE n2.nNOMBATEAU = tw4.aNOMBATEAU
AND n2.nANNEE  = tw4.aANNEE
AND n2.nNUMETAP != 100
AND s.sNOMBATEAU = n2.nNOMBATEAU 
--- AND aNOMBATEAU = 'ST FRANÇOIS '
ORDER BY n2.nANNEE, n2.nNOMBATEAU , n2.nNUMETAP ;




SELECT *
FROM v_etapes_trajets
LIMIT 50;






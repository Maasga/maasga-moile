@# Offres de maintenance — MAASGA (v2 : tarification par équipement)

Le prix n'est plus fixe par carte. Il se calcule selon le nombre de climatiseurs du client, avec un tarif dégressif par unité. Ça évite qu'un client avec un gros parc paie le même prix qu'un client avec un seul climatiseur — et ça évite aussi qu'un tarif fixe devienne intenable sur un gros volume.

**Formule** : Prix total = Tarif unitaire dégressif × Nombre de climatiseurs × Nombre de visites/an

---

## Grille de tarif unitaire dégressif (par climatiseur, par visite)

| Nombre de climatiseurs | Tarif / unité / visite |
|---|---|
| 1 à 4 | 8 500 F |
| 5 à 8 | 7 500 F |
| 9 à 15 | 6 000 F |
| 16+ | 5 000 F (au-delà d'un seuil à définir : devis sur mesure) |

---

## Carte 1 — RÉSIDENTIEL

- **Tag fréquence** : Essentiel (1 visite/an) ou Confort (2 visites/an)
- **Cible** : 1 à 4 climatiseurs
- **Tarif unitaire applicable** : 8 500 F 
- **Exemple** : 2 climatiseurs, plan Confort (2 visites/an) → 8 500 × 2 × 2 = **34 000 F/an**(soit 17 000 F par visite globale)
- **Inclus** :
  - Nettoyage des filtres
  - Vérification complète du système
  - Contrôle des performances de refroidissement
  - Vérification du gaz réfrigérant
  - Diagnostic technique
- **Idéal pour** : logements et petits bureaux
- **CTA** : Simuler mon prix (champ : nombre de clim + fréquence)

---

## Carte 2 — PROFESSIONNEL / PME ⭐ RECOMMANDÉ

- **Tag fréquence** : Confort (2 visites/an) ou Pro (3 visites/an)
- **Cible** : 5 à 15 climatiseurs
- **Tarif unitaire applicable** : 7 500 F (5-8 clim) ou 6 000 F (9-15 clim)
- **Exemple** : 8 climatiseurs, plan Pro (3 visites/an) → 6 000 × 9 × 3 = **162 000 F/an** (soit 54 000 F par visite globale)
- **Inclus** :
  - Nettoyage complet unité intérieure + extérieure
  - Vérification du gaz réfrigérant
  - Diagnostic complet du système
  - Priorité sur les interventions
  - Conseils d'optimisation énergétique
- **Bonus client** : 1 diagnostic panne offert dans l'année
- **Idéal pour** : bureaux, commerces, petites entreprises
- **CTA** : Simuler mon prix

---

## Carte 3 — INDUSTRIEL 🏆 MEILLEUR CHOIX

- **Tag fréquence** : Pro (3 visites/an) ou contrat sur mesure
- **Cible** : 16 climatiseurs et plus
- **Tarif unitaire applicable** : 5 000 F/unité (dégressif supplémentaire possible selon volume réel)
- **Exemple** : 25 climatiseurs, 4 visites/an → 5 000 × 20 × 3 = **300 000 F/an** (soit 100 000 F par visite globale)
- **Inclus** :
  - Nettoyage complet professionnel
  - Vérification gaz et pression
  - Diagnostic complet du système
  - Intervention prioritaire
  - Suivi technique personnalisé
- **Avantages exclusifs** :
  - 1 recharge de gaz gratuite (si nécessaire)
  - 10% de réduction sur les réparations
  - Support prioritaire
- **Idéal pour** : usines, hôtels, sites à gros parc
- **CTA** : Demander un devis (formulaire : nombre de clim + site)
- **Note** : ne pas afficher de prix fixe publiquement pour ce segment — le tarif unitaire dégressif sert de base de négociation, pas de prix catalogue

---

## Carte 4 — SUR MESURE

- **Tag** : CONTRAT PERSONNALISÉ
- **Cible** : besoins hors grille standard — parc mixte (clim + chambres froides par exemple), plusieurs sites, exigences contractuelles spécifiques (SLA, pénalités, astreinte), ou client qui négocie ses propres conditions
- **Prix** : non affiché — "Sur devis, selon vos besoins"
- **Contenu de la carte** :
  - Pas de liste de prestations fixes ni de tarif unitaire affiché
  - Un court texte : "Votre parc ou vos exigences ne rentrent pas dans une formule standard ? Décrivez-nous votre besoin, on construit un contrat adapté."
  - Champs du formulaire de contact : nombre de sites, type d'équipements, fréquence souhaitée, exigences particulières (délai d'intervention garanti, astreinte, etc.)
- **Idéal pour** : multi-sites, parcs mixtes, entreprises avec cahier des charges propre
- **CTA** : Demander un contrat personnalisé (redirige vers formulaire ou WhatsApp, pas vers le simulateur des autres cartes)
- **Placement suggéré** : en 4e position après Industriel, avec un style visuel plus sobre (pas de badge coloré ni de "recommandé") pour bien marquer que c'est une porte de sortie plutôt qu'une formule concurrente aux 3 autres

---

## Intégration technique suggérée

Pour que "Choisissez votre formule" reste dynamique plutôt que 3 prix figés :
1. Champ input : nombre de climatiseurs
2. Sélecteur : fréquence (Essentiel / Confort / Pro)
3. Calcul en temps réel : tarif unitaire (selon palier de quantité) × nombre de clim × visites/an
4. Affichage du prix par visite ET du prix annuel total, comme dans les cartes actuelles

Ça garde l'aspect visuel des 3 cartes (Résidentiel / Professionnel-PME / Industriel), mais chaque carte devient un simulateur plutôt qu'un prix fixe. La carte Sur Mesure reste volontairement en dehors de ce calcul automatique — c'est une porte de sortie vers un contact humain, pas un 4e palier de prix.

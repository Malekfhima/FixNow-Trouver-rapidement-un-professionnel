#!/usr/bin/env node
/**
 * FixNow — migration des rôles admin vers les CUSTOM CLAIMS Firebase.
 *
 * Pourquoi : firestore.rules litait users/{uid}.role à CHAQUE évaluation de
 * règle (1 lecture Firestore par contrôle). Le custom claim `admin` est
 * porté par le jeton d'ID → vérification sans lecture.
 *
 * Usage :
 *   node tool/set_custom_claims.js <uid> [<uid> ...]        # poser le claim
 *   node tool/set_custom_claims.js --revoke <uid> [...]     # retirer le claim
 *   node tool/set_custom_claims.js --list <uid>              # afficher les claims
 *
 * Authentification (au choix) :
 *   GOOGLE_APPLICATION_CREDENTIALS=./tool/serviceAccount.json node tool/...
 *   # ou les identifiants applicatifs Google (ADC) déjà configurés.
 *
 * Procédure complète (ne casse AUCUN compte existant) :
 *   1) Lister les admins actuels :
 *        firebase firestore:query users --field role --op == --value admin
 *      (ou Console Firebase > Firestore > users où role == 'admin')
 *   2) node tool/set_custom_claims.js uid1 uid2 ...
 *   3) Vérifier : node tool/set_custom_claims.js --list uid1
 *   4) Basculer isAdmin() dans firestore.rules vers :
 *        function isAdmin() {
 *          return isAuth() && request.auth.token.get('admin', false) == true;
 *        }
 *      (le rôle legacy users.role reste en base : rien n'est perdu)
 *   5) Redéployer : firebase deploy --only firestore:rules
 *   6) Retirer progressivement le rôle legacy si souhaité (optionnel).
 *
 * NOTE : pose aussi le claim `pro` si users/{uid}.isPro == true, utile pour
 * une future migration de isPro() (même gain : 1 lecture en moins/règle).
 */
'use strict';

const admin = require('firebase-admin');

function usage() {
  console.log(
    [
      'Usage :',
      '  node tool/set_custom_claims.js <uid> [<uid> ...]',
      '  node tool/set_custom_claims.js --revoke <uid> [<uid> ...]',
      '  node tool/set_custom_claims.js --list <uid>',
      '',
      'Variable d\'environnement attendue :',
      '  GOOGLE_APPLICATION_CREDENTIALS=<chemin vers serviceAccount.json>',
    ].join('\n')
  );
  process.exit(1);
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) usage();

  const mode = ['--revoke', '--list'].includes(args[0]) ? args[0] : '--grant';
  const uids = mode === '--grant' ? args : args.slice(1);
  if (uids.length === 0) usage();

  admin.initializeApp();
  const auth = admin.auth();
  const db = admin.firestore();

  for (const uid of uids) {
    if (mode === '--list') {
      const user = await auth.getUser(uid);
      console.log(`uid=${uid} claims=${JSON.stringify(user.customClaims || {})}`);
      continue;
    }

    if (mode === '--revoke') {
      await auth.setCustomUserClaims(uid, null);
      console.log(`✔ claim admin retiré pour ${uid}`);
      continue;
    }

    // --grant : on conserve les claims existants et on ajoute `admin`.
    const [user, userDoc] = await Promise.all([
      auth.getUser(uid),
      db.collection('users').doc(uid).get(),
    ]);
    const claims = Object.assign({}, user.customClaims || {});
    claims.admin = true;
    // Compat : miroir du flag isPro existant (facultatif, sans risque).
    if (userDoc.exists && userDoc.data().isPro === true) claims.pro = true;
    await auth.setCustomUserClaims(uid, claims);
    console.log(
      `✔ claim admin posé pour ${uid} (role legacy=${
        userDoc.exists ? userDoc.data().role : 'n/a'
      }) → claims=${JSON.stringify(claims)}`
    );
  }

  console.log(
    '\nRappel : le jeton est rafraîchi à la prochaine reconnexion ' +
      '(ou forceRefresh en client). Voir la procédure en tête de fichier.'
  );
}

main().catch((err) => {
  console.error('Échec :', err.message);
  console.error(
    '(Vérifiez GOOGLE_APPLICATION_CREDENTIALS et que firebase-admin est installé : npm i -D firebase-admin)'
  );
  process.exit(1);
});

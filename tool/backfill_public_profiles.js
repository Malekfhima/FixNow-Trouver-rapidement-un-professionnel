#!/usr/bin/env node
/**
 * FixNow — migration publicProfiles (faille « users lisible par tous »).
 *
 * Les règles Firestore n'autorisent plus la lecture de users/{uid} aux
 * tiers : les écrans (chat, avis…) lisent désormais publicProfiles/{uid}.
 * Ce script copie, pour CHAQUE utilisateur existant :
 *   users/{uid}  →  publicProfiles/{uid} = { name, avatarUrl, role }
 * (Script Admin SDK : contourne les règles, exécutable une seule fois.)
 *
 * Usage :
 *   GOOGLE_APPLICATION_CREDENTIALS=./tool/serviceAccount.json \
 *     node tool/backfill_public_profiles.js [--dry-run]
 *
 * Idempotent : rejouable à volonté (set avec merge, écrase les champs
 * publics avec la dernière valeur de users/).
 */
'use strict';

const admin = require('firebase-admin');

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  admin.initializeApp();
  const db = admin.firestore();

  const users = await db.collection('users').get();
  console.log(`${users.size} profil(s) utilisateur(s) trouvé(s)`);

  let written = 0;
  // Lots de 400 écritures (limite Firestore = 500 par batch).
  let batch = db.batch();
  let pending = 0;

  for (const doc of users.docs) {
    const data = doc.data() || {};
    const publicFields = {
      name: typeof data.name === 'string' ? data.name : '',
      avatarUrl: typeof data.avatarUrl === 'string' ? data.avatarUrl : null,
      role: ['client', 'pro', 'admin'].includes(data.role)
        ? data.role
        : 'client',
    };

    if (dryRun) {
      console.log(`  [dry-run] publicProfiles/${doc.id} ←`, publicFields);
      continue;
    }

    batch.set(db.collection('publicProfiles').doc(doc.id), publicFields, {
      merge: true,
    });
    pending += 1;
    written += 1;
    if (pending >= 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (!dryRun && pending > 0) await batch.commit();
  console.log(
    dryRun
      ? 'Dry-run terminé — aucune écriture.'
      : `${written} publicProfiles écrits/mis à jour.`
  );
}

main().catch((err) => {
  console.error('Échec :', err.message);
  process.exit(1);
});

/**
 * Tests des règles Firestore de FixNow (émulateur requis).
 * Lancement : npm run test:rules
 */
const {
  assertSucceeds,
  assertFails,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const { setDoc, doc, getDoc, serverTimestamp } = require('firebase/firestore');

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'fixnow-rules-test',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

/** Creates an authenticated Firestore client for the given uid/role. */
function authedDb(uid, role) {
  return env.authenticatedContext(uid, { role }).firestore();
}

/** Seeds a user profile document (bypasses rules — test setup only). */
async function seedUser(uid, role) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users', uid), {
      role,
      name: `User ${uid}`,
      email: `${uid}@test.fr`,
      createdAt: serverTimestamp(),
    });
  });
}

describe('users : rôle invariant', () => {
  test("un utilisateur ne peut PAS modifier son propre role", async () => {
    await seedUser('u1', 'client');
    const db = authedDb('u1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'users', 'u1'), { name: 'Nouveau nom' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'users', 'u1'), { role: 'admin' }, { merge: true })
    );
  });

  test("auto-promotion client -> pro autorisée (isPro + role ensemble)", async () => {
    await seedUser('u7', 'client');
    const db = authedDb('u7', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'users', 'u7'), { isPro: true, role: 'pro' }, { merge: true })
    );
  });

  test("auto-promotion avec role admin refusée", async () => {
    await seedUser('u8', 'client');
    const db = authedDb('u8', 'client');
    await assertFails(
      setDoc(doc(db, 'users', 'u8'), { isPro: true, role: 'admin' }, { merge: true })
    );
  });

  test("isPro seul (sans role) refusé", async () => {
    await seedUser('u9', 'client');
    const db = authedDb('u9', 'client');
    await assertFails(
      setDoc(doc(db, 'users', 'u9'), { isPro: true }, { merge: true })
    );
  });

  test("un pro ne peut PAS se rétrograder lui-même", async () => {
    await seedUser('u10', 'pro');
    const db = authedDb('u10', 'pro');
    await assertFails(
      setDoc(doc(db, 'users', 'u10'), { isPro: false, role: 'client' }, { merge: true })
    );
  });

  test("un admin peut modifier n'importe quel rôle, y compris le sien", async () => {
    await seedUser('admin5', 'admin');
    const db = authedDb('admin5', 'admin');
    await assertSucceeds(
      setDoc(doc(db, 'users', 'admin5'), { isPro: false, role: 'client' }, { merge: true })
    );
  });

  test("un utilisateur peut modifier son profil sans toucher au rôle", async () => {
    await seedUser('u2', 'client');
    const db = authedDb('u2', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'users', 'u2'), { phone: '+33612345678' }, { merge: true })
    );
  });

  test("un admin peut modifier le rôle de quelqu'un d'autre", async () => {
    await seedUser('u3', 'client');
    await seedUser('admin1', 'admin');
    const db = authedDb('admin1', 'admin');
    await assertSucceeds(
      setDoc(doc(db, 'users', 'u3'), { role: 'pro' }, { merge: true })
    );
  });
});

describe('professionals : statut invariant', () => {
  test("un pro peut créer son profil", async () => {
    await seedUser('p1', 'pro');
    const db = authedDb('p1', 'pro');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'p1'), {
        categories: ['Plomberie'],
        bio: 'Pro de test',
        hourlyRate: 40,
        status: 'pending',
      })
    );
  });

  test("un pro ne peut PAS s'auto-valider (status)", async () => {
    await seedUser('p2', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'p2'), {
        categories: ['Plomberie'],
        bio: 'Pro de test',
        hourlyRate: 40,
        status: 'pending',
      });
    });
    const db = authedDb('p2', 'pro');
    await assertFails(
      setDoc(doc(db, 'professionals', 'p2'), { status: 'approved' }, { merge: true })
    );
  });

  test("un pro peut modifier son tarif mais pas ratingAvg", async () => {
    await seedUser('p3', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'p3'), {
        categories: ['Plomberie'],
        bio: 'Pro',
        hourlyRate: 40,
        ratingAvg: 0,
        ratingCount: 0,
        status: 'approved',
      });
    });
    const db = authedDb('p3', 'pro');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'p3'), { hourlyRate: 50 }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'professionals', 'p3'), { ratingAvg: 5 }, { merge: true })
    );
  });

  test("un admin peut valider un pro (status -> approved)", async () => {
    await seedUser('p4', 'pro');
    await seedUser('admin2', 'admin');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'p4'), {
        categories: ['Plomberie'],
        status: 'pending',
      });
    });
    const db = authedDb('admin2', 'admin');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'p4'), { status: 'approved' }, { merge: true })
    );
  });

  test("seed : un admin peut créer des pros de démo (ids demo-*), pas d'autres", async () => {
    await seedUser('admin4', 'admin');
    const db = authedDb('admin4', 'admin');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'demo-pro-1'), {
        name: '[DÉMO] Pro fictif',
        categories: ['Plomberie'],
        status: 'approved',
      })
    );
    await assertFails(
      setDoc(doc(db, 'professionals', 'vrai-pro'), {
        name: 'Pas une démo',
        categories: ['Plomberie'],
        status: 'approved',
      })
    );
  });
});

describe('chats : réservés aux participants', () => {
  test("un non-participant ne peut PAS lire une conversation", async () => {
    await seedUser('c1', 'client');
    await seedUser('p5', 'pro');
    await seedUser('intrus', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'chat1'), {
        clientId: 'c1',
        proId: 'p5',
        lastMessage: 'Bonjour',
      });
    });
    const db = authedDb('intrus', 'client');
    await assertFails(getDoc(doc(db, 'chats', 'chat1')));
  });

  test("un participant peut lire la conversation", async () => {
    await seedUser('c2', 'client');
    await seedUser('p6', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'chat2'), {
        clientId: 'c2',
        proId: 'p6',
        lastMessage: '',
      });
    });
    const db = authedDb('c2', 'client');
    await assertSucceeds(getDoc(doc(db, 'chats', 'chat2')));
  });

  test("création : le créateur doit être l'un des participants", async () => {
    await seedUser('c3', 'client');
    const db = authedDb('c3', 'client');
    await assertFails(
      setDoc(doc(db, 'chats', 'chat3'), { clientId: 'autre', proId: 'p6' })
    );
    await assertSucceeds(
      setDoc(doc(db, 'chats', 'chat3'), { clientId: 'c3', proId: 'p6' })
    );
  });
});

describe('reviews : prestation terminée + unicité', () => {
  test("on ne peut PAS noter une demande non terminée", async () => {
    await seedUser('c4', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'r1'), {
        clientId: 'c4',
        proId: 'p7',
        status: 'accepted',
      });
    });
    const db = authedDb('c4', 'client');
    await assertFails(
      setDoc(doc(db, 'reviews', 'r1'), {
        requestId: 'r1',
        clientId: 'c4',
        proId: 'p7',
        rating: 5,
        comment: 'Super',
      })
    );
  });

  test("avis autorisé : demande terminée, client = auteur, doc id = requestId", async () => {
    await seedUser('c5', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'r2'), {
        clientId: 'c5',
        proId: 'p8',
        status: 'completed',
      });
    });
    const db = authedDb('c5', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'reviews', 'r2'), {
        requestId: 'r2',
        clientId: 'c5',
        proId: 'p8',
        rating: 4,
        comment: 'Très bien',
      })
    );
  });

  test("impossible de noter pour quelqu'un d'autre", async () => {
    await seedUser('c6', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'r3'), {
        clientId: 'quelquun-dautre',
        proId: 'p9',
        status: 'completed',
      });
    });
    const db = authedDb('c6', 'client');
    await assertFails(
      setDoc(doc(db, 'reviews', 'r3'), {
        requestId: 'r3',
        clientId: 'c6',
        proId: 'p9',
        rating: 5,
      })
    );
  });
});

describe('notifications : réservées au destinataire', () => {
  test("un utilisateur peut créer une notification pour quelqu'un d'autre (actorId = soi)", async () => {
    await seedUser('n1', 'client');
    await seedUser('n2', 'pro');
    const db = authedDb('n1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'notifications', 'notif1'), {
        userId: 'n2',
        actorId: 'n1',
        type: 'newMessage',
        title: 'Nouveau message',
        body: 'Salut',
        read: false,
      })
    );
  });

  test("création sans actorId = soi refusée", async () => {
    await seedUser('n3', 'client');
    const db = authedDb('n3', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'notif2'), {
        userId: 'n4',
        actorId: 'quelquun-dautre',
        type: 'newMessage',
        title: 'x',
        body: 'y',
      })
    );
  });

  test("le destinataire peut lire et marquer comme lue, pas un autre", async () => {
    await seedUser('n5', 'client');
    await seedUser('n6', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'notifications', 'notif3'), {
        userId: 'n5',
        actorId: 'n6',
        type: 'generic',
        title: 't',
        body: 'b',
        read: false,
      });
    });
    const recipient = authedDb('n5', 'client');
    const intruder = authedDb('n6', 'client');
    await assertSucceeds(getDoc(doc(recipient, 'notifications', 'notif3')));
    await assertFails(getDoc(doc(intruder, 'notifications', 'notif3')));
    await assertSucceeds(
      setDoc(doc(recipient, 'notifications', 'notif3'), { read: true }, { merge: true })
    );
    await assertFails(
      setDoc(doc(intruder, 'notifications', 'notif3'), { read: true }, { merge: true })
    );
  });
});

describe('serviceRequests : acceptation de devis par le client', () => {
  test("le client peut passer quoted -> accepted", async () => {
    await seedUser('q1', 'client');
    await seedUser('q2', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'rq1'), {
        clientId: 'q1',
        proId: 'q2',
        status: 'quoted',
      });
    });
    const db = authedDb('q1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'serviceRequests', 'rq1'), { status: 'accepted' }, { merge: true })
    );
  });

  test("le client ne peut pas passer pending -> accepted directement", async () => {
    await seedUser('q3', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'rq2'), {
        clientId: 'q3',
        status: 'pending',
      });
    });
    const db = authedDb('q3', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'rq2'), { status: 'accepted' }, { merge: true })
    );
  });
});

describe('professionals : agrégation des notes', () => {
  test("un utilisateur authentifié peut écrire UNIQUEMENT ratingAvg/ratingCount", async () => {
    await seedUser('p10', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'p10'), {
        name: 'Pro',
        categories: ['Plomberie'],
        status: 'approved',
        ratingAvg: 0,
        ratingCount: 0,
      });
    });
    const db = authedDb('u1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'p10'), { ratingAvg: 4.5, ratingCount: 2 }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'professionals', 'p10'), { ratingAvg: 5, status: 'rejected' }, { merge: true })
    );
  });

  test("un pro ne peut PAS modifier sa propre note (auto-promotion)", async () => {
    await seedUser('p11', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'p11'), {
        name: 'Pro',
        categories: ['Plomberie'],
        status: 'approved',
        ratingAvg: 3,
        ratingCount: 5,
      });
    });
    const db = authedDb('p11', 'pro');
    await assertFails(
      setDoc(doc(db, 'professionals', 'p11'), { ratingAvg: 5, ratingCount: 99 }, { merge: true })
    );
  });
});

describe('categories : écriture admin uniquement', () => {
  test("un client ne peut pas créer de catégorie", async () => {
    await seedUser('c7', 'client');
    const db = authedDb('c7', 'client');
    await assertFails(setDoc(doc(db, 'categories', 'cat1'), { name: 'Test' }));
  });

  test("un admin peut créer une catégorie", async () => {
    await seedUser('admin3', 'admin');
    const db = authedDb('admin3', 'admin');
    await assertSucceeds(setDoc(doc(db, 'categories', 'cat2'), { name: 'Plomberie' }));
  });
});

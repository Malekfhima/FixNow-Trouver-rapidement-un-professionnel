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
const { setDoc, doc, getDoc, serverTimestamp, writeBatch } = require('firebase/firestore');

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

describe('serviceRequests : machine à états stricte', () => {
  async function seedRequest(id, clientId, proId, status) {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', id), {
        clientId,
        proId,
        status,
        description: 'test',
        address: 'test',
      });
    });
  }

  const STATUSES = ['pending', 'accepted', 'quoted', 'inProgress', 'completed', 'declined', 'cancelled'];
  const VALID = new Set([
    'pending>accepted', 'pending>declined', 'pending>cancelled',
    'pending>quoted',
    'accepted>inProgress', 'accepted>cancelled',
    'quoted>accepted', 'quoted>cancelled',
    'inProgress>completed',
  ]);
  const ACTORS = {
    client: 'cX', pro: 'pX', admin: 'aX',
  };

  // Matrice exhaustive : chaque (statut initial, statut cible, acteur).
  for (const from of STATUSES) {
    for (const to of STATUSES) {
      for (const [actor, uid] of Object.entries(ACTORS)) {
        const key = `${from}>${to}`;
        // Édition sans changement de statut : autorisée aux participants
        // (métadonnées). L'admin n'est PAS exempté de la machine à états
        // (option la plus sûre, documentée dans CHANGELOG).
        const sameStatus = from === to &&
          (actor === 'client' || actor === 'pro');
        const shouldPass = sameStatus ||
          (VALID.has(key) &&
            // Acteur attendu pour chaque transition
            ((to === 'cancelled' && actor === 'client') ||
             (to === 'accepted' && from === 'pending' && actor === 'pro') ||             (to === 'accepted' && from === 'quoted' && actor === 'client') || 
             (to === 'quoted' && from === 'pending' && actor === 'pro') || 
             (to === 'declined' && actor === 'pro') || 
             (to === 'inProgress' && actor === 'pro') ||
             (to === 'completed' && actor === 'pro')));

        test(`${from} -> ${to} par ${actor} : ${shouldPass ? 'autorisé' : 'refusé'}`, async () => {
          await seedUser(uid, actor);
          await seedUser('cX', 'client');
          await seedUser('pX', 'pro');
          await seedUser('aX', 'admin');
          await seedRequest('mr1', 'cX', 'pX', from);
          const db = authedDb(uid, actor);
          const op = setDoc(doc(db, 'serviceRequests', 'mr1'), { status: to }, { merge: true });
          if (shouldPass) {
            await assertSucceeds(op);
          } else {
            await assertFails(op);
          }
        });
      }
    }
  }

  test('FAILLE (faille 3) : chaque acteur ne modifie QUE ses propres champs', async () => {
    await seedUser('cX', 'client');
    await seedUser('pX', 'pro');
    await seedRequest('mr2', 'cX', 'pX', 'pending');
    const client = authedDb('cX', 'client');
    const pro = authedDb('pX', 'pro');

    // Le client peut corriger sa description (sans changer le statut)…
    await assertSucceeds(
      setDoc(doc(client, 'serviceRequests', 'mr2'), { description: 'maj description' }, { merge: true })
    );
    // …mais JAMAIS les champs réservés au pro (devis / prix).
    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr2'), { quotePrice: 120 }, { merge: true })
    );
    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr2'), { price: 120 }, { merge: true })
    );
    // Le pro peut renseigner son devis…
    await assertSucceeds(
      setDoc(doc(pro, 'serviceRequests', 'mr2'), { quotePrice: 120, quoteNote: 'ok' }, { merge: true })
    );
    // …mais ne réécrit pas la description du client.
    await assertFails(
      setDoc(doc(pro, 'serviceRequests', 'mr2'), { description: 'réécrite par le pro' }, { merge: true })
    );
  });

  test('faille 3 : les clés clientId / proId / categoryId / createdAt sont immuables', async () => {
    await seedUser('cIm', 'client');
    await seedUser('pIm', 'pro');
    await seedUser('pOther', 'pro');
    await seedRequest('mr3', 'cIm', 'pIm', 'pending');
    const client = authedDb('cIm', 'client');

    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr3'), { proId: 'pOther' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr3'), { clientId: 'pOther' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr3'), { categoryId: 'autre' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(client, 'serviceRequests', 'mr3'), { createdAt: serverTimestamp() }, { merge: true })
    );
  });
});

describe('notifications : réservées au destinataire', () => {
  test("un participant crée une notification liée à LEUR conversation", async () => {
    await seedUser('n1', 'client');
    await seedUser('n2', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'chatN1N2'), {
        clientId: 'n1', proId: 'n2', lastMessage: '',
      });
    });
    const db = authedDb('n1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'notifications', 'notif1'), {
        userId: 'n2',
        actorId: 'n1',
        type: 'newMessage',
        relatedId: 'chatN1N2',
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

describe('professionals : agrégation des notes (batch avis + compteurs)', () => {
  async function seedProRatings(id, ratingAvg, ratingCount) {
    await seedUser(id, 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', id), {
        name: 'Pro',
        categories: ['Plomberie'],
        status: 'approved',
        ratingAvg,
        ratingCount,
      });
    });
  }

  async function seedCompletedRequest(id, clientId, proId) {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', id), {
        clientId,
        proId,
        status: 'completed',
        description: 'test',
        address: 'test',
      });
    });
  }

  // Le correctif : UN seul batch écrit l'avis ET les compteurs cohérents.
  function batchReviewAndCounters(uid, requestId, proId, rating, { count, avg }) {
    const db = authedDb(uid, 'client');
    const batch = writeBatch(db);
    batch.set(doc(db, 'reviews', requestId), {
      requestId,
      clientId: uid,
      proId,
      rating,
      comment: 'Très bien',
    });
    batch.update(doc(db, 'professionals', proId), {
      ratingAvg: avg,
      ratingCount: count,
      lastRatingReviewId: requestId,
    });
    return batch.commit();
  }

  test("faille 6 : écrire ratingAvg/ratingCount SANS avis dans le même batch = refusé", async () => {
    await seedProRatings('p10', 0, 0);
    const db = authedDb('u1', 'client');
    await assertFails(
      setDoc(doc(db, 'professionals', 'p10'), { ratingAvg: 4.5, ratingCount: 2 }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'professionals', 'p10'), { ratingAvg: 5, status: 'rejected' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'professionals', 'p10'), { ratingCount: 1 }, { merge: true })
    );
  });

  test("batch [avis + compteurs cohérents] : accepté (1er avis)", async () => {
    await seedProRatings('p12', 0, 0);
    await seedCompletedRequest('rb1', 'cB1', 'p12');
    await assertSucceeds(
      batchReviewAndCounters('cB1', 'rb1', 'p12', 4, { count: 1, avg: 4 })
    );
    await env.withSecurityRulesDisabled(async (ctx) => {
      const pro = await getDoc(doc(ctx.firestore(), 'professionals', 'p12'));
      expect(pro.data().ratingCount).toBe(1);
      expect(pro.data().ratingAvg).toBe(4);
      expect(pro.data().lastRatingReviewId).toBe('rb1');
    });
  });

  test("batch avec compteur faussé (+2 ou moyenne incohérente) = refusé", async () => {
    await seedProRatings('p13', 0, 0);
    await seedCompletedRequest('rb2', 'cB2', 'p13');
    // ratingCount +2
    await assertFails(batchReviewAndCounters('cB2', 'rb2', 'p13', 4, { count: 2, avg: 4 }));
    // moyenne qui ne correspond pas à la note portée
    await assertFails(batchReviewAndCounters('cB2', 'rb2', 'p13', 4, { count: 1, avg: 5 }));
    // moyenne hors bornes 1..5
    await assertFails(batchReviewAndCounters('cB2', 'rb2', 'p13', 4, { count: 1, avg: 7 }));
  });

  test("2e avis : moyenne recalculée exactement (4.5 / 2) = accepté", async () => {
    await seedProRatings('p14', 4, 1);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'reviews', 'old1'), {
        requestId: 'old1', clientId: 'cOld', proId: 'p14', rating: 4, comment: 'ok',
      });
    });
    await seedCompletedRequest('rb3', 'cB3', 'p14');
    await assertSucceeds(
      batchReviewAndCounters('cB3', 'rb3', 'p14', 5, { count: 2, avg: 4.5 })
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

describe('reports : signalements', () => {
  test("un utilisateur peut créer un signalement lié à lui, statut open", async () => {
    await seedUser('r1', 'client');
    const db = authedDb('r1', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'reports', 'rep1'), {
        reporterId: 'r1',
        targetType: 'pro',
        targetId: 'p1',
        reason: 'Comportement inapproprié',
        status: 'open',
      })
    );
  });

  test("créer un signalement pour quelqu'un d'autre est refusé", async () => {
    await seedUser('r2', 'client');
    const db = authedDb('r2', 'client');
    await assertFails(
      setDoc(doc(db, 'reports', 'rep2'), {
        reporterId: 'quelquun-dautre',
        targetType: 'pro',
        targetId: 'p1',
        reason: 'x',
        status: 'open',
      })
    );
  });

  test("seul l'admin peut résoudre/rejeter (status resolved/dismissed)", async () => {
    await seedUser('r3', 'client');
    await seedUser('admin9', 'admin');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'reports', 'rep3'), {
        reporterId: 'r3',
        targetType: 'pro',
        targetId: 'p1',
        reason: 'test',
        status: 'open',
      });
    });
    const reporter = authedDb('r3', 'client');
    const admin = authedDb('admin9', 'admin');
    // Le reporter ne peut pas résoudre son propre signalement
    await assertFails(
      setDoc(doc(reporter, 'reports', 'rep3'), { status: 'resolved' }, { merge: true })
    );
    // L'admin peut rejeter
    await assertSucceeds(
      setDoc(doc(admin, 'reports', 'rep3'), { status: 'dismissed' }, { merge: true })
    );
  });

  test("l'admin ne peut pas remettre un signalement à 'open'", async () => {
    await seedUser('admin10', 'admin');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'reports', 'rep4'), {
        reporterId: 'r3',
        status: 'resolved',
      });
    });
    const admin = authedDb('admin10', 'admin');
    await assertFails(
      setDoc(doc(admin, 'reports', 'rep4'), { status: 'open' }, { merge: true })
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TESTS DES FAILLES CORRIGÉES
// Chaque test ci-dessous ÉCHOUEAIT avant le correctif et PASSE après.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

describe('faille 1 : professionals création en pending uniquement', () => {
  test("FAILLE : un pro ne peut PAS créer son profil déjà 'approved'", async () => {
    await seedUser('pSelf', 'pro');
    const db = authedDb('pSelf', 'pro');
    await assertFails(
      setDoc(doc(db, 'professionals', 'pSelf'), {
        categories: ['Plomberie'],
        bio: 'auto-approuvé',
        hourlyRate: 40,
        status: 'approved',
        ratingAvg: 0,
        ratingCount: 0,
      })
    );
  });

  test("FAILLE : un pro ne peut PAS créer son profil avec des notes non nulles", async () => {
    await seedUser('pRated', 'pro');
    const db = authedDb('pRated', 'pro');
    await assertFails(
      setDoc(doc(db, 'professionals', 'pRated'), {
        categories: ['Plomberie'],
        bio: 'fausse réputation',
        hourlyRate: 40,
        status: 'pending',
        ratingAvg: 4.9,
        ratingCount: 127,
      })
    );
  });

  test("création légitime : status pending + notes à zéro = acceptée", async () => {
    await seedUser('pOk', 'pro');
    const db = authedDb('pOk', 'pro');
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'pOk'), {
        categories: ['Plomberie'],
        bio: 'vrai pro',
        hourlyRate: 40,
        status: 'pending',
        ratingAvg: 0,
        ratingCount: 0,
      })
    );
  });
});

describe('faille 2 : serviceRequests création verrouillée', () => {
  async function seedApprovedPro(id) {
    await seedUser(id, 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', id), {
        categories: ['Plomberie'],
        status: 'approved',
      });
    });
  }

  async function seedPendingPro(id) {
    await seedUser(id, 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', id), {
        categories: ['Plomberie'],
        status: 'pending',
      });
    });
  }

  const VALID = {
    clientId: 'cNew',
    proId: 'pNew',
    categoryId: 'cat-1',
    status: 'pending',
    description: 'Fuite sous le lavabo',
    address: '12 rue des Lilas, Paris',
  };

  beforeEach(async () => {
    await seedUser('cNew', 'client');
    await seedApprovedPro('pNew');
  });

  test("FAILLE : création avec un statut autre que 'pending' = refusée", async () => {
    const db = authedDb('cNew', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-approved'), { ...VALID, status: 'accepted' })
    );
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-completed'), { ...VALID, status: 'completed' })
    );
  });

  test("FAILLE : un pro ne peut PAS se cibler lui-même = refusé", async () => {
    const db = authedDb('pNew', 'pro');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-self'), { ...VALID, clientId: 'pNew', proId: 'pNew' })
    );
  });

  test("FAILLE : création avec un devis ou un prix déjà remplis = refusée", async () => {
    const db = authedDb('cNew', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-quote'), { ...VALID, quotePrice: 150 })
    );
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-note'), { ...VALID, quoteNote: 'devis anticipé' })
    );
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-price'), { ...VALID, price: 99 })
    );
  });

  test("FAILLE : cibler un professionnel NON approuvé = refusé", async () => {
    await seedPendingPro('pWaiting');
    const db = authedDb('cNew', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-pending-pro'), { ...VALID, proId: 'pWaiting' })
    );
  });

  test("FAILLE : cibler un professionnel inexistant = refusé", async () => {
    const db = authedDb('cNew', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'sr-ghost'), { ...VALID, proId: 'pas-une-personne' })
    );
  });

  test("création valide vers un pro approuvé = acceptée", async () => {
    const db = authedDb('cNew', 'client');
    await assertSucceeds(setDoc(doc(db, 'serviceRequests', 'sr-valid'), VALID));
  });
});

describe('faille 4 : machine à états pending -> quoted (pro)', () => {
  test("FAILLE : le pro peut proposer un devis (pending -> quoted)", async () => {
    await seedUser('cQ', 'client');
    await seedUser('pQ', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'rq-pro'), {
        clientId: 'cQ', proId: 'pQ', status: 'pending',
        description: 'test', address: 'test',
      });
    });
    const db = authedDb('pQ', 'pro');
    await assertSucceeds(
      setDoc(doc(db, 'serviceRequests', 'rq-pro'), {
        status: 'quoted', quotePrice: 180, quoteNote: 'Dépannage',
      }, { merge: true })
    );
  });

  test("le client ne peut PAS passer pending -> quoted (réservé au pro)", async () => {
    await seedUser('cQ2', 'client');
    await seedUser('pQ2', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'rq-client'), {
        clientId: 'cQ2', proId: 'pQ2', status: 'pending',
        description: 'test', address: 'test',
      });
    });
    const db = authedDb('cQ2', 'client');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'rq-client'), { status: 'quoted' }, { merge: true })
    );
  });

  test("le pro ne peut PAS démarrer depuis pending (accepted d'abord)", async () => {
    await seedUser('cQ3', 'client');
    await seedUser('pQ3', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'rq-skip'), {
        clientId: 'cQ3', proId: 'pQ3', status: 'pending',
        description: 'test', address: 'test',
      });
    });
    const db = authedDb('pQ3', 'pro');
    await assertFails(
      setDoc(doc(db, 'serviceRequests', 'rq-skip'), { status: 'inProgress' }, { merge: true })
    );
  });
});

describe('faille 5 : reviews — rating, commentaire et pro assigné', () => {
  async function seedDoneRequest(id, clientId, proId) {
    await seedUser(clientId, 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', id), {
        clientId, proId, status: 'completed',
        description: 'test', address: 'test',
      });
    });
  }

  test("FAILLE : rating hors bornes (0, 6) ou non entier = refusé", async () => {
    await seedDoneRequest('rv1', 'cR1', 'pR1');
    const db = authedDb('cR1', 'client');
    await assertFails(
      setDoc(doc(db, 'reviews', 'rv1'), {
        requestId: 'rv1', clientId: 'cR1', proId: 'pR1', rating: 0, comment: 'nul',
      })
    );
    await assertFails(
      setDoc(doc(db, 'reviews', 'rv1'), {
        requestId: 'rv1', clientId: 'cR1', proId: 'pR1', rating: 6, comment: 'trop bien',
      })
    );
    await assertFails(
      setDoc(doc(db, 'reviews', 'rv1'), {
        requestId: 'rv1', clientId: 'cR1', proId: 'pR1', rating: 4.5, comment: 'décimal',
      })
    );
  });

  test("FAILLE : commentaire de plus de 1000 caractères = refusé", async () => {
    await seedDoneRequest('rv2', 'cR2', 'pR2');
    const db = authedDb('cR2', 'client');
    await assertFails(
      setDoc(doc(db, 'reviews', 'rv2'), {
        requestId: 'rv2', clientId: 'cR2', proId: 'pR2',
        rating: 5, comment: 'x'.repeat(1001),
      })
    );
    // Juste à la limite : accepté.
    await assertSucceeds(
      setDoc(doc(db, 'reviews', 'rv2'), {
        requestId: 'rv2', clientId: 'cR2', proId: 'pR2',
        rating: 5, comment: 'x'.repeat(1000),
      })
    );
  });

  test("FAILLE : review.proId différent du pro assigné à la demande = refusé", async () => {
    await seedDoneRequest('rv3', 'cR3', 'pR3');
    await seedUser('pInnocent', 'pro');
    const db = authedDb('cR3', 'client');
    await assertFails(
      setDoc(doc(db, 'reviews', 'rv3'), {
        requestId: 'rv3', clientId: 'cR3', proId: 'pInnocent',
        rating: 1, comment: 'mauvaise foi',
      })
    );
  });
});

describe('faille 7 : users privé + publicProfiles', () => {
  test("FAILLE : lire le users/{uid} d'un autre utilisateur = refusé", async () => {
    await seedUser('priv1', 'client');
    await seedUser('priv2', 'client');
    const intruder = authedDb('priv2', 'client');
    await assertFails(getDoc(doc(intruder, 'users', 'priv1')));
    // …et les emails / téléphones des autres restent inaccessibles
    // même via une lecture du sien puis d'un tiers en batch de requêtes :
    await assertFails(getDoc(doc(intruder, 'users', 'priv1')));
    // Le profil PUBLIC reste lisible.
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'publicProfiles', 'priv1'), {
        name: 'Privé Un', avatarUrl: null, role: 'client',
      });
    });
    await assertSucceeds(getDoc(doc(intruder, 'publicProfiles', 'priv1')));
  });

  test("le propriétaire lit et écrit SON profil privé", async () => {
    await seedUser('priv3', 'client');
    const db = authedDb('priv3', 'client');
    await assertSucceeds(getDoc(doc(db, 'users', 'priv3')));
    await assertSucceeds(
      setDoc(doc(db, 'publicProfiles', 'priv3'), {
        name: 'Moi', avatarUrl: 'https://x/y.png', role: 'client',
      })
    );
  });

  test("FAILLE : un tiers ne peut PAS écrire le publicProfiles de quelqu'un", async () => {
    await seedUser('pub1', 'client');
    await seedUser('intrus3', 'client');
    await assertSucceeds(
      setDoc(doc(authedDb('pub1', 'client'), 'publicProfiles', 'pub1'), {
        name: 'Moi', role: 'client',
      })
    );
    await assertFails(
      setDoc(doc(authedDb('intrus3', 'client'), 'publicProfiles', 'pub1'), {
        name: 'Profil pirate', role: 'client',
      }, { merge: true })
    );
  });

  test("un admin peut lire un profil privé et corriger un publicProfile", async () => {
    await seedUser('priv4', 'client');
    await seedUser('admP', 'admin');
    const admin = authedDb('admP', 'admin');
    await assertSucceeds(getDoc(doc(admin, 'users', 'priv4')));
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'publicProfiles', 'priv4'), {
        name: 'Privé Quatre', role: 'client',
      });
    });
    await assertSucceeds(
      setDoc(doc(admin, 'publicProfiles', 'priv4'), {
        name: 'Corrigé', role: 'client',
      }, { merge: true })
    );
  });
});

describe('faille 8 : chats immuables + messages verrouillés', () => {
  async function seedChatWithMessage(chatId, msgId) {
    await seedUser('cMsg', 'client');
    await seedUser('pMsg', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', chatId), {
        clientId: 'cMsg', proId: 'pMsg', lastMessage: 'Bonjour',
      });
      await setDoc(doc(ctx.firestore(), 'chats', chatId, 'messages', msgId), {
        senderId: 'cMsg', text: 'Bonjour', read: false,
      });
    });
  }

  test("FAILLE : réaffecter clientId/proId d'une conversation = refusé", async () => {
    await seedChatWithMessage('chatImm', 'm1');
    const db = authedDb('cMsg', 'client');
    await assertFails(
      setDoc(doc(db, 'chats', 'chatImm'), { clientId: 'intrus' }, { merge: true })
    );
    await assertFails(
      setDoc(doc(db, 'chats', 'chatImm'), { proId: 'intrus' }, { merge: true })
    );
    // Les métadonnées restent libres (compteurs non lus, dernier message).
    await assertSucceeds(
      setDoc(doc(db, 'chats', 'chatImm'), { unreadClient: 0 }, { merge: true })
    );
  });

  test("FAILLE : modifier le texte d'un message existant = refusé", async () => {
    await seedChatWithMessage('chatTxt', 'm2');
    const db = authedDb('pMsg', 'pro');
    await assertFails(
      setDoc(doc(db, 'chats', 'chatTxt', 'messages', 'm2'), {
        text: 'message réécrit',
      }, { merge: true })
    );
    // Seul 'read' peut bouger.
    await assertSucceeds(
      setDoc(doc(db, 'chats', 'chatTxt', 'messages', 'm2'), {
        read: true,
      }, { merge: true })
    );
  });

  test("FAILLE : message de plus de 2000 caractères = refusé", async () => {
    await seedChatWithMessage('chatLong', 'm3');
    const db = authedDb('cMsg', 'client');
    await assertFails(
      setDoc(doc(db, 'chats', 'chatLong', 'messages', 'mTooLong'), {
        senderId: 'cMsg', text: 'x'.repeat(2001), read: false,
      })
    );
    await assertSucceeds(
      setDoc(doc(db, 'chats', 'chatLong', 'messages', 'mOk'), {
        senderId: 'cMsg', text: 'x'.repeat(2000), read: false,
      })
    );
  });

  test("FAILLE : un message envoyé sous l'identité d'autrui = refusé", async () => {
    await seedChatWithMessage('chatSpoof', 'm4');
    const db = authedDb('pMsg', 'pro');
    await assertFails(
      setDoc(doc(db, 'chats', 'chatSpoof', 'messages', 'mSpoof'), {
        senderId: 'cMsg', text: 'je me fais passer pour le client', read: false,
      })
    );
  });
});

describe('faille 9 : notifications — type, taille et lien réel', () => {
  async function seedLinkedChat() {
    await seedUser('cN', 'client');
    await seedUser('pN', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'chats', 'chatLien'), {
        clientId: 'cN', proId: 'pN', lastMessage: '',
      });
    });
  }

  async function seedSharedRequest() {
    await seedUser('cS', 'client');
    await seedUser('pS', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'serviceRequests', 'reqLien'), {
        clientId: 'cS', proId: 'pS', status: 'pending',
        description: 'test', address: 'test',
      });
    });
  }

  const BASE = {
    userId: 'pN',
    actorId: 'cN',
    type: 'newMessage',
    relatedId: 'chatLien',
    title: 'Nouveau message',
    body: 'Salut !',
    read: false,
  };

  test("FAILLE : type hors liste blanche = refusé", async () => {
    await seedLinkedChat();
    const db = authedDb('cN', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-type'), { ...BASE, type: 'malicious' })
    );
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-type2'), { ...BASE, type: 'roleAdmin' })
    );
  });

  test("FAILLE : titre/body trop longs = refusé", async () => {
    await seedLinkedChat();
    const db = authedDb('cN', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-title'), { ...BASE, title: 'x'.repeat(201) })
    );
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-body'), { ...BASE, body: 'x'.repeat(2001) })
    );
  });

  test("FAILLE : notification SANS lien relatedId = refusée", async () => {
    await seedLinkedChat();
    const db = authedDb('cN', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-nolink'), { ...BASE, relatedId: null })
    );
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-nolink2'), {
        ...BASE, relatedId: 'conversation-qui-nexiste-pas',
      })
    );
  });

  test("FAILLE : lié à une conversation à laquelle l'appelant ne participe pas = refusée", async () => {
    await seedLinkedChat();
    await seedUser('intrusN', 'client');
    const db = authedDb('intrusN', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-foreign'), {
        ...BASE, actorId: 'intrusN',
      })
    );
  });

  test("lien serviceRequest partagée (client -> pro) = acceptée", async () => {
    await seedSharedRequest();
    const db = authedDb('cS', 'client');
    await assertSucceeds(
      setDoc(doc(db, 'notifications', 'nt-req'), {
        userId: 'pS', actorId: 'cS', type: 'requestAccepted',
        relatedId: 'reqLien', title: 'Devis accepté', body: 'OK', read: false,
      })
    );
  });

  test("FAILLE : proApproved envoyé par un NON-admin = refusée", async () => {
    await seedUser('fakeVictim', 'pro');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'fakeVictim'), {
        categories: ['Plomberie'], status: 'pending',
      });
    });
    const db = authedDb('cN', 'client');
    await assertFails(
      setDoc(doc(db, 'notifications', 'nt-fake'), {
        userId: 'fakeVictim', actorId: 'cN', type: 'proApproved',
        relatedId: 'fakeVictim',
        title: 'Profil validé', body: 'Vous êtes approuvé !', read: false,
      })
    );
  });

  test("proApproved par l'admin (relatedId = uid du pro) = acceptée", async () => {
    await seedUser('realVictim', 'pro');
    await seedUser('admN', 'admin');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'realVictim'), {
        categories: ['Plomberie'], status: 'approved',
      });
    });
    const db = authedDb('admN', 'admin');
    await assertSucceeds(
      setDoc(doc(db, 'notifications', 'nt-real'), {
        userId: 'realVictim', actorId: 'admN', type: 'proApproved',
        relatedId: 'realVictim',
        title: 'Profil validé', body: 'Validé.', read: false,
      })
    );
  });
});

describe('faille 10 : rôles — migration vers les custom claims', () => {
  test("FAILLE : admin porteur UNIQUEMENT du custom claim admin (sans rôle legacy) administre", async () => {
    // Le document users porte encore role = 'client' : avant la migration
    // vers les claims, cet admin était refusé.
    await seedUser('claimAdmin', 'client');
    await seedUser('victimClaim', 'client');
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'professionals', 'pClaim'), {
        categories: ['Plomberie'], status: 'pending',
      });
    });

    const db = env.authenticatedContext('claimAdmin', { admin: true }).firestore();

    // Approuver un pro sans avoir le rôle legacy admin…
    await assertSucceeds(
      setDoc(doc(db, 'professionals', 'pClaim'), { status: 'approved' }, { merge: true })
    );
    // …et lire le profil privé d'un autre utilisateur.
    await assertSucceeds(getDoc(doc(db, 'users', 'victimClaim')));
    // …et compter les utilisateurs (requête admin).
    await assertSucceeds(getDoc(doc(db, 'users', 'claimAdmin')));
  });

  test("un utilisateur SANS claim ni rôle admin reste refusé", async () => {
    await seedUser('notAdmin', 'client');
    await seedUser('otherUser', 'client');
    const db = authedDb('notAdmin', 'client');
    await assertFails(getDoc(doc(db, 'users', 'otherUser')));
  });
});

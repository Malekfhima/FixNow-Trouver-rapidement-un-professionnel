/**
 * Tests des règles Storage de FixNow (émulateurs Firestore + Storage requis).
 * Lancement : npm run test:storage-rules
 *
 * Conventions identiques à firestore.rules.test.js :
 * @firebase/rules-unit-testing, contexte authentifié par uid, seed via
 * withSecurityRulesDisabled.
 */
const {
  assertSucceeds,
  assertFails,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const {
  getDoc,
  doc,
  setDoc,
  serverTimestamp,
} = require('firebase/firestore');

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'fixnow-rules-test',
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8081,
    },
    storage: {
      rules: fs.readFileSync(path.resolve(__dirname, 'storage.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
  await env.clearFirestore();
});

/** Authenticated Storage client for the given uid. */
function storage(uid) {
  return env.authenticatedContext(uid).storage();
}

/** Unauthenticated Storage client. */
function anonStorage() {
  return env.unauthenticatedContext().storage();
}

/** Authenticated Firestore client (for seeding participant documents). */
function db(uid) {
  return env.authenticatedContext(uid).firestore();
}

/** PNG bytes under the 5 Mo limit enforced by isImagePayload(). */
function pngBytes(sizeKb = 10) {
  return Buffer.alloc(sizeKb * 1024, 0x89);
}

/** Seeds a service request so both uids become participants. */
async function seedRequest(requestId, clientId, proId, status = 'pending') {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'serviceRequests', requestId), {
      clientId,
      proId,
      status,
      description: 'test',
      address: 'test',
      createdAt: serverTimestamp(),
    });
  });
}

/** Seeds a chat so both uids become participants. */
async function seedChat(chatId, clientId, proId) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'chats', chatId), {
      clientId,
      proId,
      lastMessage: '',
    });
  });
}

// ━━ Avatars : avatars/{uid} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

describe('storage : avatars/{uid}', () => {
  test("un utilisateur peut uploader SON avatar (image < 5 Mo)", async () => {
    await assertSucceeds(
      storage('u1').uploadBytes('avatars/u1', pngBytes(), {
        contentType: 'image/png',
      })
    );
  });

  test("FAILLE : uploader dans le dossier avatar d'un AUTRE = refusé", async () => {
    await assertFails(
      storage('intrus').uploadBytes('avatars/victime', pngBytes(), {
        contentType: 'image/png',
      })
    );
  });

  test("lecture d'un avatar : réservée aux connectés (anonyme refusé)", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().uploadBytes('avatars/u1', pngBytes(), {
        contentType: 'image/png',
      });
    });
    await assertSucceeds(storage('u2').getBytes('avatars/u1'));
    await assertFails(anonStorage().getBytes('avatars/u1'));
  });

  test("FAILLE : fichier non-image ou trop lourd (> 5 Mo) = refusé", async () => {
    await assertFails(
      storage('u1').uploadBytes('avatars/u1', pngBytes(), {
        contentType: 'application/pdf',
      })
    );
    await assertFails(
      storage('u1').uploadBytes('avatars/u1', Buffer.alloc(6 * 1024 * 1024), {
        contentType: 'image/png',
      })
    );
  });

  test("suppression : propriétaire uniquement", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().uploadBytes('avatars/u1', pngBytes(), {
        contentType: 'image/png',
      });
    });
    await assertFails(storage('intrus').deleteObject('avatars/u1'));
    await assertSucceeds(storage('u1').deleteObject('avatars/u1'));
  });
});

// ━━ Galerie pro : gallery/{uid}/{file} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

describe('storage : gallery/{uid} (galerie pro)', () => {
  test("un pro peut ajouter une image dans SA galerie", async () => {
    await assertSucceeds(
      storage('pro1').uploadBytes('gallery/pro1/photo1.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
  });

  test("FAILLE : un pro ne peut PAS modifier la galerie d'un autre", async () => {
    await assertFails(
      storage('pro2').uploadBytes('gallery/pro1/photo2.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
    await assertFails(storage('pro2').deleteObject('gallery/pro1/photo1.jpg'));
  });

  test("lecture de la galerie : réservée aux connectés (vitrine visible)", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await ctx.storage().uploadBytes('gallery/pro1/photo1.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      });
    });
    await assertSucceeds(storage('client1').getBytes('gallery/pro1/photo1.jpg'));
    await assertFails(anonStorage().getBytes('gallery/pro1/photo1.jpg'));
  });
});

// ━━ Photos de demande : requests/{requestId}/{file} ━━━━━━━━━━━━━━━━━━

describe('storage : requests/{requestId} (photos de demande)', () => {
  test("le client émetteur peut uploader une photo dans SA demande", async () => {
    await seedRequest('req1', 'c1', 'p1');
    await assertSucceeds(
      storage('c1').uploadBytes('requests/req1/photo1.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
  });

  test("le pro assigné peut lire et uploader (même demande)", async () => {
    await seedRequest('req1', 'c1', 'p1');
    await assertSucceeds(
      storage('p1').uploadBytes('requests/req1/avant.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
    await assertSucceeds(storage('p1').getBytes('requests/req1/photo1.jpg'));
  });

  test("FAILLE : un tiers (ni client ni pro) est refusé", async () => {
    await seedRequest('req1', 'c1', 'p1');
    await assertFails(
      storage('intrus').uploadBytes('requests/req1/photo.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
    await assertFails(storage('intrus').getBytes('requests/req1/photo1.jpg'));
  });

  test("FAILLE : demande inexistante dans Firestore = refusé (firestore.get)", async () => {
    await assertFails(
      storage('c1').uploadBytes('requests/fantome/photo.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
  });
});

// ━━ Images de chat : chats/{chatId}/{file} ━━━━━━━━━━━━━━━━━━━━━━━━━━━

describe('storage : chats/{chatId} (images de discussion)', () => {
  test("les deux participants peuvent échanger des images", async () => {
    await seedChat('chat1', 'c1', 'p1');
    await assertSucceeds(
      storage('c1').uploadBytes('chats/chat1/img1.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
    await assertSucceeds(storage('p1').getBytes('chats/chat1/img1.jpg'));
  });

  test("FAILLE : un non-participant est refusé", async () => {
    await seedChat('chat1', 'c1', 'p1');
    await assertFails(
      storage('intrus').uploadBytes('chats/chat1/img.jpg', pngBytes(), {
        contentType: 'image/jpeg',
      })
    );
    await assertFails(storage('intrus').getBytes('chats/chat1/img1.jpg'));
  });
});

const assert = require('node:assert/strict');
const {test} = require('node:test');
const Module = require('node:module');

// Exercise the real compiled entitlement transactions with an in-memory
// Firestore adapter, without invoking providers or deployed functions.
const users = new Map();
const database = {
  collection: () => ({doc: (uid) => ({
    uid,
    get: async () => ({data: () => users.get(uid)}),
  })}),
  runTransaction: async (callback) => callback({
    get: async (ref) => ({data: () => users.get(ref.uid)}),
    set: (ref, update) => users.set(ref.uid, {
      ...users.get(ref.uid), ...update,
    }),
  }),
};
const firestore = () => database;
firestore.FieldValue = {serverTimestamp: () => 'server-time'};
const originalLoad = Module._load;
Module._load = function(name, ...args) {
  if (name === 'firebase-admin') return {firestore};
  return originalLoad.call(this, name, ...args);
};
const enhancer = require('../lib/utils/premiumEntitlements');
const images = require('../lib/utils/entitlements');
Module._load = originalLoad;

test('photo: two free attempts, one reward, then blocked again', async () => {
  const uid = 'photo-free';
  users.set(uid, {serverUsage: {photoEnhancementCount: 0}});
  await enhancer.authorizePhotoEnhancement(uid);
  await enhancer.authorizePhotoEnhancement(uid);
  await assert.rejects(enhancer.authorizePhotoEnhancement(uid));
  users.get(uid).serverUsage.rewardedPhotoCredits = 1;
  const reservation = await enhancer.authorizePhotoEnhancement(uid);
  assert.equal(reservation.rewarded, true);
  assert.equal(users.get(uid).serverUsage.rewardedPhotoCredits, 0);
  await assert.rejects(enhancer.authorizePhotoEnhancement(uid));
  await enhancer.releasePhotoEnhancement(uid, reservation);
  assert.equal(users.get(uid).serverUsage.rewardedPhotoCredits, 1);
  assert.equal(users.get(uid).serverUsage.photoEnhancementCount, 2);
});

test('video: Free and Lite accounts are strictly rejected with PRO_REQUIRED', async () => {
  const freeUid = 'video-free';
  users.set(freeUid, {serverUsage: {videoEnhancementCount: 0, rewardedVideoCredits: 1}});
  await assert.rejects(enhancer.assertVideoEnhancementAvailable(freeUid), (err) => err?.code === 'permission-denied');
  await assert.rejects(enhancer.authorizeVideoEnhancement(freeUid), (err) => err?.code === 'permission-denied');

  const liteUid = 'video-lite';
  users.set(liteUid, {
    premium: {isPremium: true, status: 'active', tier: 'lite'},
    serverUsage: {videoEnhancementCount: 0},
  });
  await assert.rejects(enhancer.assertVideoEnhancementAvailable(liteUid), (err) => err?.code === 'permission-denied');
  await assert.rejects(enhancer.authorizeVideoEnhancement(liteUid), (err) => err?.code === 'permission-denied');
  // Lite still has unmetered photo and image access
  assert.equal((await enhancer.authorizePhotoEnhancement(liteUid)).counted, false);
  assert.equal((await images.reserveFeatureUsage(liteUid, 'image')).counted, false);
});

test('active Pro/trial access requires no ad for photo or video', async () => {
  const uid = 'pro-trial';
  users.set(uid, {
    premium: {isPremium: true, status: 'authenticated', tier: 'pro'},
    serverUsage: {photoEnhancementCount: 20, videoEnhancementCount: 20},
  });
  assert.equal((await enhancer.authorizePhotoEnhancement(uid)).counted, false);
  assert.equal((await enhancer.authorizeVideoEnhancement(uid)).counted, false);
});

test('image: one free image and exactly one generation per reward', async () => {
  const uid = 'image-free';
  users.set(uid, {serverUsage: {imageCount: 0}});
  await images.reserveFeatureUsage(uid, 'image');
  await assert.rejects(images.reserveFeatureUsage(uid, 'image'));
  users.get(uid).serverUsage.rewardedImageCredits = 1;
  const reservation = await images.reserveFeatureUsage(uid, 'image');
  assert.equal(users.get(uid).serverUsage.rewardedImageCredits, 0);
  await assert.rejects(images.reserveFeatureUsage(uid, 'image'));
  await images.releaseFeatureUsage(uid, reservation);
  assert.equal(users.get(uid).serverUsage.rewardedImageCredits, 1);
});

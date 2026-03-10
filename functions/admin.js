// functions/admin.js
const functions = require("firebase-functions");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");

const FLIP_API_KEY = defineString("FLIP_API_KEY");
const FLIP_BASE_URL = "https://bigflip.id/big_sandbox_api/v3";

// db dipanggil di dalam function, bukan di level atas
// agar tidak error sebelum initializeApp() di index.js
const getDb = () => admin.firestore();

// Helper: cek apakah user adalah admin
async function isAdmin(uid) {
  const userDoc = await getDb().collection("users").doc(uid).get();
  return userDoc.data()?.role === "admin";
}

// ────────────────────────────────────────────────────────────
// 1. GET ALL TRANSACTIONS
// Ambil semua transaksi dari Firestore (bukan dari Flip)
// dipanggil dari halaman admin Flutter
// ────────────────────────────────────────────────────────────
exports.getTransactions = functions.https.onCall((request) => {
  // Gen2 format
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
  }

  return (async () => {
    if (!(await isAdmin(auth.uid))) {
      throw new functions.https.HttpsError("permission-denied", "Bukan admin.");
    }

    const { status, limit = 50 } = data;

    let query = getDb().collection("transactions")
      .orderBy("createdAt", "descending")
      .limit(limit);

    // Filter opsional berdasarkan status
    if (status) {
      query = query.where("status", "==", status);
    }

    const snap = await query.get();

    const transactions = snap.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate()?.toISOString() ?? null,
      paidAt: doc.data().paidAt?.toDate()?.toISOString() ?? null,
    }));

    return { transactions };
  })();
});


// ────────────────────────────────────────────────────────────
// 2. REFUND / BATALKAN PEMBAYARAN
// Cabut akses ujian + tandai transaksi sebagai refunded
// Flip sandbox tidak support refund API, jadi ini manual
// ────────────────────────────────────────────────────────────
exports.refundPayment = functions.https.onCall((request) => {
  // Gen2 format
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login dulu.");
  }

  return (async () => {
    if (!(await isAdmin(auth.uid))) {
      throw new functions.https.HttpsError("permission-denied", "Bukan admin.");
    }

    const { billLinkId, reason = "" } = data;
    if (!billLinkId) {
      throw new functions.https.HttpsError("invalid-argument", "billLinkId wajib diisi.");
    }

    // Ambil data transaksi
    const txRef = getDb().collection("transactions").doc(billLinkId);
    const txDoc = await txRef.get();

    if (!txDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Transaksi tidak ditemukan.");
    }

    const { userId, status } = txDoc.data();

    if (status === "refunded") {
      throw new functions.https.HttpsError("already-exists", "Transaksi sudah direfund.");
    }

    // Nonaktifkan bill di Flip agar tidak bisa dibayar lagi
    try {
      await axios.put(
        `${FLIP_BASE_URL}/pwf/${billLinkId}/bill`,
        { status: "INACTIVE" },
        {
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          auth: { username: FLIP_API_KEY.value(), password: "" },
        }
      );
    } catch (e) {
      // Lanjut meski gagal nonaktifkan di Flip (mungkin sudah expired)
      console.warn("Gagal nonaktifkan bill di Flip:", e.message);
    }

    // Update transaksi
    await txRef.update({
      status: "refunded",
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundedBy: auth.uid,
      refundReason: reason,
    });

    // Cabut akses ujian user
    await getDb().collection("users").doc(userId).update({
      isPaid: false,
      refundedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`🔄 Refund berhasil - billLinkId: ${billLinkId}, userId: ${userId}`);

    return { success: true, message: "Akses ujian dicabut dan transaksi ditandai refunded." };
  })();
});
const functions = require("firebase-functions");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const axios = require("axios");
const qs = require("querystring");
const { getTransactions, refundPayment } = require("./admin");

exports.getTransactions = getTransactions;
exports.refundPayment = refundPayment;

admin.initializeApp();
const db = admin.firestore();

const FLIP_API_KEY = defineString("FLIP_API_KEY");
const FLIP_VALIDATION_TOKEN = defineString("FLIP_VALIDATION_TOKEN");
const FLIP_BASE_URL = "https://bigflip.id/big_sandbox_api/v2"; // ganti ke https://bigflip.id/api/v2 saat production
const REDIRECT_URL = "https://lulusasn-e15a3.web.app/#/payment/success";

// ────────────────────────────────────────────────
// 1. CREATE BILL
// ────────────────────────────────────────────────
exports.createBill = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });

  const authHeader = req.headers.authorization || "";
  const idToken = authHeader.startsWith("Bearer ") ? authHeader.split("Bearer ")[1] : null;

  if (!idToken) {
    console.error("❌ No token provided");
    return res.status(401).json({ error: "Unauthorized" });
  }

  let userId, userEmail;
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    userId = decoded.uid;
    userEmail = decoded.email || "";
    console.log("✅ Token verified - uid:", userId);
  } catch (e) {
    console.error("❌ Token invalid:", e.message);
    return res.status(401).json({ error: "Token tidak valid." });
  }

  let { amount, tryoutId } = req.body;
  if (typeof amount === "string") amount = parseInt(amount, 10);
  if (!amount || isNaN(amount)) amount = 50000;
  tryoutId = tryoutId ?? "";

  console.log("📝 createBill:", { userId, userEmail, amount, tryoutId });

  try {
    const response = await axios.post(
      `${FLIP_BASE_URL}/pwf/bill`,
      qs.stringify({
        title: "Akses Try Out",
        amount: amount,
        type: "SINGLE",
        redirect_url: REDIRECT_URL,
        is_address_required: 0,
        sender_name: userEmail.split("@")[0] || "User",
        sender_email: userEmail || "user@example.com",
      }),
      {
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        auth: { username: FLIP_API_KEY.value(), password: "" },
      }
    );

    const bill = response.data;
    console.log("✅ Flip response:", bill);

    const linkId = String(bill.link_id);

    // Pastikan linkUrl selalu punya https://
    const rawUrl = bill.link_url || "";
    const linkUrl = rawUrl.startsWith("http") ? rawUrl : `https://${rawUrl}`;

    await db.collection("transactions").doc(linkId).set({
      userId,
      userEmail,
      tryoutId,
      amount,
      status: "pending",
      billLinkId: linkId,
      billLinkUrl: linkUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json({
      success: true,
      linkUrl: linkUrl,  // ← sudah pasti https://
      billLinkId: linkId,
    });

  } catch (err) {
    console.error("createBill error status :", err.response?.status);
    console.error("createBill error data   :", JSON.stringify(err.response?.data));
    console.error("createBill error message:", err.message);

    const msg =
      err.response?.data?.message ??
      err.response?.data?.errors?.[0]?.message ??
      err.message ??
      "Gagal membuat tagihan.";

    return res.status(500).json({ error: msg });
  }
});

// ────────────────────────────────────────────────
// 2. FLIP CALLBACK (Webhook)
// ────────────────────────────────────────────────
exports.flipCallback = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

  const token = req.headers["x-callback-token"];
  if (token !== FLIP_VALIDATION_TOKEN.value()) {
    console.warn("❌ Token tidak valid:", token);
    return res.status(403).send("Forbidden");
  }

  try {
    const raw = req.body?.data;
    if (!raw) return res.status(400).send("No data");

    const payload = JSON.parse(raw);
    console.log("📦 Flip callback payload:", payload);

    const { bill_link_id, status, amount } = payload;
    const linkId = String(bill_link_id);

    if (status === "SUCCESSFUL") {
      const txRef = db.collection("transactions").doc(linkId);
      const txDoc = await txRef.get();

      if (!txDoc.exists) {
        console.warn("⚠️ Transaksi tidak ditemukan:", linkId);
        return res.status(200).send("OK");
      }

      const { userId, tryoutId } = txDoc.data();

      await txRef.update({
        status: "success",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await db.collection("user_tryouts").doc(`${userId}_tryout_${tryoutId}`).set({
        userId,
        tryoutId,
        proofStatus: "paid",
        isActive: true,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        paidAmount: amount,
      }, { merge: true });

      await db.collection("users").doc(userId).set(
        {
          isPaid: true,
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          paidAmount: amount,
        },
        { merge: true }
      );

      console.log(`✅ Akses dibuka - userId: ${userId}, tryoutId: ${tryoutId}`);
    }

    return res.status(200).send("OK");

  } catch (err) {
    console.error("flipCallback error:", err.message);
    return res.status(200).send("OK");
  }
});
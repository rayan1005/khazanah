import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const AUTHENTICA_API_KEY =
  "$2y$10$4dEwMGaqU5ZGwKj5Ul6K8.4Mo9y59MnZidt.PR83EI.SOkUxjdQfu";
const AUTHENTICA_BASE_URL = "https://api.authentica.sa/api/sdk/v1";

// Test account bypass
const TEST_PHONE = "+966562726777";
const TEST_OTP = "7777";

/**
 * sendOTP - Sends OTP via Authentica API
 *
 * Called from Flutter: FirebaseFunctions.instance.httpsCallable('sendOTP')
 * Input: { phone: "+966XXXXXXXXX" }
 * Output: { success: true }
 */
export const sendOTP = functions.https.onCall(async (request) => {
  const phone = request.data?.phone as string;

  functions.logger.info(`sendOTP called with phone: ${phone}`);

  if (!phone || !phone.startsWith("+966") || phone.length !== 13) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "رقم الهاتف غير صالح. يجب أن يبدأ بـ +966 ويتكون من 9 أرقام."
    );
  }

  // Test account bypass — don't call Authentica API
  if (phone === TEST_PHONE) {
    functions.logger.info(`Test account OTP requested: ${phone}`);
    return {success: true};
  }

  try {
    const response = await axios.post(
      `${AUTHENTICA_BASE_URL}/sendOTP`,
      {
        phone: phone,
        method: "sms",
      },
      {
        headers: {
          "X-Authorization": AUTHENTICA_API_KEY,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      }
    );

    if (response.data && response.data.success) {
      return {success: true};
    } else {
      throw new functions.https.HttpsError(
        "internal",
        response.data?.message || "فشل إرسال رمز التحقق"
      );
    }
  } catch (error: unknown) {
    if (error instanceof functions.https.HttpsError) throw error;
    const axiosError = error as {response?: {data?: {message?: string}}};
    functions.logger.error("sendOTP error:", error);
    throw new functions.https.HttpsError(
      "internal",
      axiosError.response?.data?.message || "فشل إرسال رمز التحقق"
    );
  }
});

/**
 * verifyOTP - Verifies OTP and returns a custom Firebase Auth token
 *
 * Called from Flutter: FirebaseFunctions.instance.httpsCallable('verifyOTP')
 * Input: { phone: "+966XXXXXXXXX", otp: "1234" }
 * Output: { token: "firebase_custom_token", uid: "user_uid" }
 */
export const verifyOTP = functions.https.onCall(async (request) => {
  const phone = request.data?.phone as string;
  const otp = request.data?.otp as string;

  functions.logger.info(`verifyOTP called with phone: ${phone}, otp: ${otp}`);

  if (!phone || !otp) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "رقم الهاتف ورمز التحقق مطلوبان"
    );
  }

  // Test account bypass
  if (phone === TEST_PHONE && otp === TEST_OTP) {
    functions.logger.info(`Test account verified: ${phone}`);
    const uid = await getOrCreateUser(phone);
    const token = await admin.auth().createCustomToken(uid);
    return {success: true, token, uid};
  }

  try {
    const response = await axios.post(
      `${AUTHENTICA_BASE_URL}/verifyOTP`,
      {
        phone: phone,
        otp: otp,
      },
      {
        headers: {
          "X-Authorization": AUTHENTICA_API_KEY,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      }
    );

    if (response.data && response.data.success) {
      // OTP verified — create or get Firebase user & issue token
      const uid = await getOrCreateUser(phone);
      const token = await admin.auth().createCustomToken(uid);
      return {success: true, token, uid};
    } else {
      throw new functions.https.HttpsError(
        "unauthenticated",
        response.data?.message || "رمز التحقق غير صحيح"
      );
    }
  } catch (error: unknown) {
    if (error instanceof functions.https.HttpsError) throw error;
    const axiosError = error as {response?: {data?: {message?: string}}};
    functions.logger.error("verifyOTP error:", error);
    throw new functions.https.HttpsError(
      "unauthenticated",
      axiosError.response?.data?.message || "رمز التحقق غير صحيح"
    );
  }
});

/**
 * Get or create a Firebase Auth user by phone number.
 * Also creates the Firestore users document if it doesn't exist.
 * Returns the UID.
 */
async function getOrCreateUser(phone: string): Promise<string> {
  const db = admin.firestore();
  let uid: string;
  let isNewUser = false;

  try {
    // Try to find existing user by phone
    const existing = await admin.auth().getUserByPhoneNumber(phone);
    uid = existing.uid;
  } catch (_) {
    // User doesn't exist — create new one
    const newUser = await admin.auth().createUser({
      phoneNumber: phone,
    });
    uid = newUser.uid;
    isNewUser = true;
  }

  // Check if Firestore document exists, create if not
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists) {
    await db.collection("users").doc(uid).set({
      uid: uid,
      name: "",
      phone: phone,
      whatsapp: null,
      city: "",
      photoUrl: null,
      role: "user",
      isBanned: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info(
      `Created Firestore user document for ${phone} (uid: ${uid}, new: ${isNewUser})`
    );
  }

  return uid;
}

/**
 * Seed categories and brands data
 * Call once to populate the collections
 */
export const seedData = functions.https.onCall(async () => {
  const db = admin.firestore();

  // Categories with emoji icons (no external images needed)
  const categories = [
    {id: "dresses", name: "فساتين", icon: "👗", order: 1, sizeType: "clothes"},
    {id: "abayas", name: "عبايات", icon: "🧕", order: 2, sizeType: "abayas"},
    {id: "tops", name: "بلوزات", icon: "👚", order: 3, sizeType: "clothes"},
    {id: "pants", name: "بناطيل", icon: "👖", order: 4, sizeType: "clothes"},
    {id: "skirts", name: "تنانير", icon: "🥻", order: 5, sizeType: "clothes"},
    {id: "shoes", name: "أحذية", icon: "👠", order: 6, sizeType: "shoes"},
    {id: "bags", name: "حقائب", icon: "👜", order: 7, sizeType: "none"},
    {id: "accessories", name: "إكسسوارات", icon: "💍", order: 8, sizeType: "none"},
    {id: "kids", name: "أطفال", icon: "👶", order: 9, sizeType: "kids"},
    {id: "men", name: "رجالي", icon: "👔", order: 10, sizeType: "clothes"},
  ];

  // Brands (text only, no images)
  const brands = [
    {id: "zara", name: "زارا", order: 1},
    {id: "hm", name: "H&M", order: 2},
    {id: "mango", name: "مانجو", order: 3},
    {id: "shein", name: "شي إن", order: 4},
    {id: "stradivarius", name: "سترادفاريوس", order: 5},
    {id: "bershka", name: "بيرشكا", order: 6},
    {id: "pullbear", name: "بول آند بير", order: 7},
    {id: "massimo", name: "ماسيمو دوتي", order: 8},
    {id: "nike", name: "نايكي", order: 9},
    {id: "adidas", name: "أديداس", order: 10},
    {id: "gucci", name: "غوتشي", order: 11},
    {id: "lv", name: "لويس فيتون", order: 12},
    {id: "chanel", name: "شانيل", order: 13},
    {id: "puma", name: "بوما", order: 14},
    {id: "newbalance", name: "نيو بالانس", order: 15},
    {id: "skechers", name: "سكيتشرز", order: 16},
    {id: "other", name: "أخرى", order: 99},
  ];

  const batch = db.batch();

  // Add categories
  for (const cat of categories) {
    const ref = db.collection("categories").doc(cat.id);
    batch.set(ref, {
      name: cat.name,
      icon: cat.icon,
      sizeType: cat.sizeType,
      order: cat.order,
    });
  }

  // Add brands
  for (const brand of brands) {
    const ref = db.collection("brands").doc(brand.id);
    batch.set(ref, {
      name: brand.name,
      order: brand.order,
    });
  }

  await batch.commit();
  functions.logger.info("Seeded categories and brands");
  return {success: true, categories: categories.length, brands: brands.length};
});

/**
 * setAdminByPhone - Sets a user as admin by phone number
 */
export const setAdminByPhone = functions.https.onCall(async (request) => {
  const phone = request.data?.phone as string;
  const secret = request.data?.secret as string;

  // Simple security check
  if (secret !== "khazanah_admin_2026") {
    throw new functions.https.HttpsError("permission-denied", "Invalid secret");
  }

  if (!phone) {
    throw new functions.https.HttpsError("invalid-argument", "Phone required");
  }

  const db = admin.firestore();
  const usersRef = db.collection("users");
  const snapshot = await usersRef.where("phone", "==", phone).limit(1).get();

  if (snapshot.empty) {
    throw new functions.https.HttpsError("not-found", "User not found");
  }

  const userDoc = snapshot.docs[0];
  await userDoc.ref.update({role: "admin"});

  functions.logger.info(`Set user ${userDoc.id} as admin (phone: ${phone})`);
  return {success: true, uid: userDoc.id};
});

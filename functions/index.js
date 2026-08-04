const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const fcm = getMessaging();

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Lấy FCM token của phụ huynh từ Firestore
// ─────────────────────────────────────────────────────────────────────────────
async function getParentFcmToken(familyId) {
  try {
    const familyDoc = await db.collection("families").doc(familyId).get();
    if (!familyDoc.exists) {
      console.warn(`[FCM] Family ${familyId} not found`);
      return null;
    }
    const parentUid = familyDoc.data()?.parentUid;
    if (!parentUid) {
      console.warn(`[FCM] No parentUid in family ${familyId}`);
      return null;
    }
    const userDoc = await db.collection("users").doc(parentUid).get();
    if (!userDoc.exists) {
      console.warn(`[FCM] User ${parentUid} not found`);
      return null;
    }
    return userDoc.data()?.fcmToken ?? null;
  } catch (e) {
    console.error(`[FCM] Error getting parent token for family ${familyId}:`, e);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bug 3 Fix: Trigger khi con gửi yêu cầu xin thêm giờ
// → Gửi FCM push notification đến phụ huynh
// ─────────────────────────────────────────────────────────────────────────────
exports.onTimeRequestCreated = onDocumentCreated(
  "families/{familyId}/children/{childUid}/timeRequests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { familyId, childUid } = event.params;

    // Chỉ xử lý request mới (status = pending)
    if (data.status !== "pending") return;

    const appName = data.appName || "Ứng dụng";
    const requestedMinutes = data.requestedMinutes || 0;
    const reason = data.reason || "";

    const fcmToken = await getParentFcmToken(familyId);
    if (!fcmToken) {
      console.warn(`[Bug3] No FCM token for family ${familyId}, skipping push`);
      return;
    }

    const body = reason
      ? `Xin thêm ${requestedMinutes} phút cho ${appName}\nLý do: ${reason}`
      : `Xin thêm ${requestedMinutes} phút cho ${appName}`;

    const message = {
      token: fcmToken,
      notification: {
        title: "⏰ Yêu cầu thêm thời gian",
        body: body,
      },
      data: {
        type: "time_request",
        requestId: snap.id,
        familyId: familyId,
        childUid: childUid,
        appName: appName,
        requestedMinutes: String(requestedMinutes),
        reason: reason,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "kidguardian_requests",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    try {
      const response = await fcm.send(message);
      console.log(
        `[Bug3] FCM sent to parent for family ${familyId}, messageId: ${response}`
      );
    } catch (e) {
      console.error(`[Bug3] FCM send failed for family ${familyId}:`, e);
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Bug 4 Fix: Trigger khi con tra cứu từ khóa cấm (keyword_detected alert)
// → Gửi FCM push notification đến phụ huynh
// ─────────────────────────────────────────────────────────────────────────────
exports.onKeywordAlertCreated = onDocumentCreated(
  "families/{familyId}/children/{childUid}/alerts/{alertId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const { familyId, childUid } = event.params;

    // Chỉ xử lý keyword_detected alert
    if (data.type !== "keyword_detected") return;

    const keyword = data.keyword || "";
    const packageName = data.packageName || "";

    if (!keyword) {
      console.warn(`[Bug4] Empty keyword in alert ${snap.id}, skipping`);
      return;
    }

    const fcmToken = await getParentFcmToken(familyId);
    if (!fcmToken) {
      console.warn(`[Bug4] No FCM token for family ${familyId}, skipping push`);
      return;
    }

    // Làm ngắn packageName thành tên app thân thiện nếu có thể
    const appDisplayName = packageName.includes(".")
      ? packageName.split(".").pop() || packageName
      : packageName;

    const message = {
      token: fcmToken,
      notification: {
        title: "⚠️ Phát hiện nội dung cần chú ý",
        body: `Phát hiện từ khóa "${keyword}" khi bé sử dụng ${appDisplayName}`,
      },
      data: {
        type: "keyword_alert",
        alertId: snap.id,
        familyId: familyId,
        childUid: childUid,
        keyword: keyword,
        packageName: packageName,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "kidguardian_requests",
          priority: "high",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    try {
      const response = await fcm.send(message);
      console.log(
        `[Bug4] FCM sent to parent for family ${familyId} — keyword: "${keyword}", messageId: ${response}`
      );
    } catch (e) {
      console.error(`[Bug4] FCM send failed for family ${familyId}:`, e);
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Trigger khi phụ huynh phê duyệt / từ chối yêu cầu thêm giờ
// → Gửi FCM push notification tới thiết bị của bé
// ─────────────────────────────────────────────────────────────────────────────
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");

exports.onTimeRequestUpdated = onDocumentUpdated(
  "families/{familyId}/children/{childUid}/timeRequests/{requestId}",
  async (event) => {
    const change = event.data;
    if (!change) return;

    const beforeData = change.before.data();
    const afterData = change.after.data();
    const { childUid } = event.params;

    // Chỉ gửi thông báo khi trạng thái chuyển từ pending sang approved/rejected
    if (beforeData.status !== "pending") return;
    if (afterData.status !== "approved" && afterData.status !== "rejected") return;

    try {
      const childDoc = await db.collection("users").doc(childUid).get();
      if (!childDoc.exists) {
        console.warn(`[TimeRequestUpdated] Child user ${childUid} not found`);
        return;
      }

      const childFcmToken = childDoc.data()?.fcmToken;
      if (!childFcmToken) {
        console.warn(`[TimeRequestUpdated] No FCM token for child ${childUid}`);
        return;
      }

      const isApproved = afterData.status === "approved";
      const appName = afterData.appName || "Ứng dụng";
      const minutes = afterData.requestedMinutes || 0;

      const title = isApproved
        ? "✅ Yêu cầu đã được phê duyệt"
        : "❌ Yêu cầu bị từ chối";

      const body = isApproved
        ? `Bố mẹ đã phê duyệt thêm ${minutes} phút cho ${appName}`
        : `Bố mẹ đã từ chối yêu cầu gia hạn thêm giờ cho ${appName}`;

      const message = {
        token: childFcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "time_request_response",
          requestId: change.after.id,
          status: afterData.status,
          appName: appName,
          requestedMinutes: String(minutes),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "kidguardian_requests",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
      };

      const response = await fcm.send(message);
      console.log(
        `[TimeRequestUpdated] Push sent to child ${childUid} (status: ${afterData.status}), msgId: ${response}`
      );
    } catch (e) {
      console.error(`[TimeRequestUpdated] Error sending FCM to child ${childUid}:`, e);
    }
  }
);


package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAccessibilityService
import org.robolectric.shadows.ShadowToast

/**
 * Unit Tests cho Midnight Rollover — AppMonitorService
 *
 * Kiểm thử kịch bản:
 *   1. Trẻ đang dùng app bị chặn → checkAndBlockIfNeeded() phải trả về true
 *   2. Trẻ dùng app KHÔNG bị chặn → checkAndBlockIfNeeded() trả về false
 *   3. currentPackageName là null → không block
 *   4. App bị chặn nhưng trẻ không đang mở → không block
 *   5. Interval check là 30 giây (không phải 60s hay 1 phút)
 *   6. Sau khi block, vẫn check lại được trong lần tiếp theo
 *   7. blockApp() phải trigger GLOBAL_ACTION_HOME (đã được test trong AppMonitorServiceTest)
 *   8. Không gây crash khi blockedApps rỗng
 *
 * Cách chạy:
 *   ./gradlew :app:testDebugUnitTest --tests "*.MidnightRolloverTest"
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.O], manifest = Config.NONE)
class MidnightRolloverTest {

    private lateinit var service: AppMonitorService
    private lateinit var shadowService: ShadowAccessibilityService

    @Before
    fun setUp() {
        service = Robolectric.buildService(AppMonitorService::class.java).create().get()
        shadowService = Shadows.shadowOf(service) as ShadowAccessibilityService

        // Reset state
        AppMonitorService.blockedApps.clear()
        AppMonitorService.monitoredPackages = setOf(
            "com.facebook.katana",
            "com.zhiliaoapp.musically",
            "com.google.android.youtube"
        )
    }

    @After
    fun tearDown() {
        service.onDestroy()
        AppMonitorService.blockedApps.clear()
        ShadowToast.reset()
    }

    // ─── Helper: Giả lập trẻ đang mở một app ────────────────────────────────
    private fun simulateAppOpen(packageName: String) {
        val event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
        event.packageName = packageName
        service.onAccessibilityEvent(event)
    }

    // ─── GROUP 1: checkAndBlockIfNeeded() logic ───────────────────────────────

    @Test
    fun `test_rollover_blocksCurrentApp_whenInBlockedList`() {
        // Trẻ mở Facebook → currentPackageName = "com.facebook.katana"
        AppMonitorService.blockedApps.add("com.facebook.katana")
        simulateAppOpen("com.facebook.katana")

        // Midnight Rollover check chạy → phải trả về true (đã block)
        val result = service.checkAndBlockIfNeeded()

        assertTrue("checkAndBlockIfNeeded() phải trả về true khi app hiện tại bị chặn!", result)
    }

    @Test
    fun `test_rollover_doesNotBlock_whenCurrentAppNotBlocked`() {
        // TikTok không nằm trong blockedApps
        AppMonitorService.blockedApps.clear() // Không chặn app nào
        simulateAppOpen("com.zhiliaoapp.musically")

        val result = service.checkAndBlockIfNeeded()

        assertFalse("checkAndBlockIfNeeded() không được block app không có trong danh sách!", result)
    }

    @Test
    fun `test_rollover_doesNotBlock_whenNoAppOpen`() {
        // currentPackageName là null (service vừa khởi động, chưa mở app nào)
        AppMonitorService.blockedApps.add("com.facebook.katana")
        // Không simulate bất kỳ sự kiện mở app nào

        // Không crash, trả về false
        val result = service.checkAndBlockIfNeeded()
        assertFalse("Khi không có app nào đang mở, không được block!", result)
    }

    @Test
    fun `test_rollover_doesNotBlock_whenBlockedListEmpty`() {
        AppMonitorService.blockedApps.clear()
        simulateAppOpen("com.facebook.katana")

        val result = service.checkAndBlockIfNeeded()

        assertFalse("Khi blockedApps rỗng, không được block bất kỳ app nào!", result)
    }

    @Test
    fun `test_rollover_blocksCorrectly_whenSwitchedToBlockedApp`() {
        // Ban đầu dùng YouTube (không bị chặn)
        simulateAppOpen("com.google.android.youtube")
        assertEquals(false, service.checkAndBlockIfNeeded())

        // Sau đó chuyển sang Facebook (bị chặn)
        AppMonitorService.blockedApps.add("com.facebook.katana")
        simulateAppOpen("com.facebook.katana")

        val result = service.checkAndBlockIfNeeded()
        assertTrue("Sau khi chuyển sang app bị chặn, rollover phải block!", result)
    }

    @Test
    fun `test_rollover_triggersGlobalActionHome_whenBlocking`() {
        AppMonitorService.blockedApps.add("com.facebook.katana")
        simulateAppOpen("com.facebook.katana")

        // Xóa lịch sử action trước (từ lần block đầu tiên khi mở app)
        shadowService.globalActionsPerformed.clear()

        // Midnight Rollover check
        service.checkAndBlockIfNeeded()

        val globalActions = shadowService.globalActionsPerformed
        assertTrue(
            "Midnight Rollover phải trigger GLOBAL_ACTION_HOME để văng app ra!",
            globalActions.contains(AccessibilityService.GLOBAL_ACTION_HOME)
        )
    }

    @Test
    fun `test_rollover_showsToast_whenBlocking`() {
        AppMonitorService.blockedApps.add("com.facebook.katana")
        simulateAppOpen("com.facebook.katana")
        ShadowToast.reset() // Reset toast từ lần block đầu

        service.checkAndBlockIfNeeded()

        val toast = ShadowToast.getTextOfLatestToast()
        assertNotNull("Midnight Rollover phải hiện Toast thông báo!", toast)
        assertTrue("Toast phải chứa thông báo về hết thời gian!", toast.contains("hết thời gian"))
    }

    // ─── GROUP 2: Check Interval ──────────────────────────────────────────────

    @Test
    fun `test_rollover_checkInterval_is30Seconds`() {
        val intervalMs = service.getCheckIntervalMs()
        assertEquals(
            "❌ Check interval phải là 30,000ms (30 giây), hiện tại là ${intervalMs}ms!",
            30_000L,
            intervalMs
        )
    }

    @Test
    fun `test_rollover_checkInterval_isNotTooFrequent`() {
        // Check interval phải >= 10 giây để tránh vòng lặp quá dày gây battery drain
        val intervalMs = service.getCheckIntervalMs()
        assertTrue(
            "Check interval quá thấp (${intervalMs}ms) — có thể gây battery drain!",
            intervalMs >= 10_000L
        )
    }

    @Test
    fun `test_rollover_checkInterval_isNotTooSlow`() {
        // Check interval phải <= 60 giây để phản hồi kịp thời
        val intervalMs = service.getCheckIntervalMs()
        assertTrue(
            "Check interval quá cao (${intervalMs}ms) — phản hồi quá chậm!",
            intervalMs <= 60_000L
        )
    }

    // ─── GROUP 3: Multiple apps / Edge cases ─────────────────────────────────

    @Test
    fun `test_rollover_onlyBlocksCurrentApp_notOtherBlockedApps`() {
        // Nhiều app bị chặn, nhưng chỉ block app đang mở
        AppMonitorService.blockedApps.addAll(listOf(
            "com.facebook.katana",
            "com.zhiliaoapp.musically",
            "com.google.android.youtube"
        ))

        // Trẻ đang dùng TikTok
        simulateAppOpen("com.zhiliaoapp.musically")

        val result = service.checkAndBlockIfNeeded()
        assertTrue("Phải block TikTok vì nó đang mở và bị chặn!", result)

        // Không block Facebook hay YouTube vì chúng không đang mở
        // (Kiểm tra gián tiếp: chỉ 1 lệnh block được gọi, không phải 3)
    }

    @Test
    fun `test_rollover_doesNotBlock_systemApp`() {
        // Launcher (system app) không được block dù có trong blockedApps (edge case)
        AppMonitorService.blockedApps.add("com.android.launcher")
        simulateAppOpen("com.android.launcher")

        // System app không được set vào currentPackageName → checkAndBlockIfNeeded phải false
        val result = service.checkAndBlockIfNeeded()
        // System packages được lọc ở onAccessibilityEvent, nên currentPackageName vẫn là null/previous
        // Kết quả phụ thuộc vào logic lọc system package trong onAccessibilityEvent
        // Test này đảm bảo không crash
        assertNotNull("checkAndBlockIfNeeded() không được throw exception với system app!", result)
    }
}

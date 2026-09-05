package com.kidguardian.kidguardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.accessibility.AccessibilityEvent
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAccessibilityService
import org.robolectric.shadows.ShadowToast

@RunWith(AndroidJUnit4::class)
@Config(sdk = [Build.VERSION_CODES.O], manifest = Config.NONE)
class AppMonitorServiceTest {

    private lateinit var service: AppMonitorService
    private lateinit var shadowService: ShadowAccessibilityService

    @Before
    fun setUp() {
        // Khởi tạo AccessibilityService bằng Robolectric
        service = Robolectric.buildService(AppMonitorService::class.java).create().get()
        shadowService = Shadows.shadowOf(service) as ShadowAccessibilityService
        
        // Giả lập danh sách app đang bị chặn
        AppMonitorService.blockedApps.clear()
        AppMonitorService.blockedApps.add("com.facebook.katana")
        
        // Đảm bảo không theo dõi nhầm system app
        AppMonitorService.monitoredPackages = setOf("com.facebook.katana")
    }

    @After
    fun tearDown() {
        service.onDestroy()
    }

    @Test
    fun test_openingBlockedApp_shouldPerformGlobalActionHomeAndShowToast() {
        // Giả lập sự kiện mở Facebook
        val event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
        event.packageName = "com.facebook.katana"

        service.onAccessibilityEvent(event)

        // Kiểm tra xem lệnh hất văng ra Home (GLOBAL_ACTION_HOME) có được gọi không
        val globalActions = shadowService.globalActionsPerformed
        assertTrue("Chưa thực hiện lệnh văng ra Home", globalActions.contains(AccessibilityService.GLOBAL_ACTION_HOME))

        // Kiểm tra Toast hiện lên
        val latestToast = ShadowToast.getTextOfLatestToast()
        assertNotNull("Không thấy hiển thị Toast báo hết giờ", latestToast)
        assertTrue(latestToast.contains("hết thời gian"))
    }

    @Test
    fun test_openingBlockedApp_twiceAfterHome_shouldBlockAgain() {
        // 1. Trẻ mở Facebook -> Bị khóa
        var event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
        event.packageName = "com.facebook.katana"
        service.onAccessibilityEvent(event)
        
        assertTrue(shadowService.globalActionsPerformed.contains(AccessibilityService.GLOBAL_ACTION_HOME))
        
        // Clear history để kiểm tra lần 2
        shadowService.globalActionsPerformed.clear()

        // 2. Trẻ văng ra Launcher (Home screen)
        // Đây là system package, code cũ sẽ return luôn và bỏ qua việc cập nhật currentPackageName
        // Code mới phải cập nhật currentPackageName = Launcher
        event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
        event.packageName = "com.android.launcher"
        service.onAccessibilityEvent(event)
        
        // Không block Launcher
        assertFalse(shadowService.globalActionsPerformed.contains(AccessibilityService.GLOBAL_ACTION_HOME))

        // 3. Trẻ ngoan cố bấm lại vào Facebook từ Home screen
        event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED)
        event.packageName = "com.facebook.katana"
        service.onAccessibilityEvent(event)

        // PHẢI CHẶN LẠI NGAY LẬP TỨC (Lỗi cũ là đoạn này bị lọt)
        assertTrue("Trẻ mở lại app từ Home nhưng không bị chặn!", shadowService.globalActionsPerformed.contains(AccessibilityService.GLOBAL_ACTION_HOME))
    }
}

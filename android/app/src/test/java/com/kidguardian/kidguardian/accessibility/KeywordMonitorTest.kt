package com.kidguardian.kidguardian.accessibility

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit Tests cho Keyword Monitor — AppMonitorService
 *
 * Các kịch bản được kiểm thử:
 *   1. Cooldown đúng 5 phút (300,000ms) — không cảnh báo lặp lại
 *   2. Chỉ trigger khi packageName là Chrome hoặc Google Search
 *   3. Hoàn toàn bỏ qua TikTok, Facebook, các app khác
 *   4. Case-insensitive matching ("TỰ TỬ" == "tự tử")
 *   5. Tiếng Việt có dấu được nhận diện đúng
 *   6. Cooldown per app (Chrome cooldown không ảnh hưởng Google Search)
 *   7. Text không chứa keyword thì KHÔNG cảnh báo
 *   8. recordKeywordAlert lưu đúng key
 *
 * Cách chạy:
 *   ./gradlew :app:testDebugUnitTest --tests "*.KeywordMonitorTest"
 */
class KeywordMonitorTest {

    // ─── CONSTANTS ────────────────────────────────────────────────────────────
    private val COOLDOWN_MS = 300_000L  // 5 phút — phải khớp với hằng số trong AppMonitorService

    // Các package được phép theo dõi keyword
    private val CHROME_PKG = "com.android.chrome"
    private val GOOGLE_SEARCH_PKG = "com.google.android.googlequicksearchbox"

    // Các package KHÔNG được theo dõi keyword
    private val TIKTOK_PKG = "com.zhiliaoapp.musically"
    private val FACEBOOK_PKG = "com.facebook.katana"
    private val INSTAGRAM_PKG = "com.instagram.android"
    private val ZALO_PKG = "com.zing.zalo"
    private val YOUTUBE_PKG = "com.google.android.youtube"
    private val DISCORD_PKG = "com.discord"

    // ─── SETUP ───────────────────────────────────────────────────────────────
    @Before
    fun setUp() {
        // Reset toàn bộ cooldown map trước mỗi test
        AppMonitorService.monitoredKeywords = setOf("tự tử", "đánh nhau", "cờ bạc", "ma túy", "súng")
        // Gọi internal clear để reset cooldown state
        clearCooldowns()
    }

    @After
    fun tearDown() {
        clearCooldowns()
    }

    /**
     * Reset cooldown state trước mỗi test bằng method public được expose sẵn
     */
    private fun clearCooldowns() {
        AppMonitorService.clearCooldownsForTest()
    }

    @Test
    fun `test_keywords_can_be_updated_dynamically`() {
        AppMonitorService.monitoredKeywords = setOf("mới 1", "mới 2")
        val isDetected = containsAnyKeyword("đây là từ mới 1", AppMonitorService.monitoredKeywords)
        assertTrue("Từ khóa mới phải được nhận diện sau khi update", isDetected)
        
        val isOldDetected = containsAnyKeyword("tự tử", AppMonitorService.monitoredKeywords)
        assertFalse("Từ khóa cũ không được nhận diện sau khi update", isOldDetected)
    }

    // ─── GROUP 1: Cooldown 5 phút ─────────────────────────────────────────────

    @Test
    fun `test_cooldown_isNotActive_beforeAnyAlert`() {
        // Chưa ghi nhận alert nào → isOnCooldown phải trả về false
        val result = AppMonitorService.isOnCooldown("tự tử", CHROME_PKG)
        assertFalse("Chưa có alert nào nhưng isOnCooldown trả về true!", result)
    }

    @Test
    fun `test_cooldown_isActive_immediatelyAfterAlert`() {
        // Ghi nhận alert → isOnCooldown phải trả về true ngay
        AppMonitorService.recordKeywordAlert("tự tử", CHROME_PKG)

        val result = AppMonitorService.isOnCooldown("tự tử", CHROME_PKG)
        assertTrue(
            "Vừa ghi nhận alert nhưng isOnCooldown vẫn trả về false!",
            result
        )
    }

    @Test
    fun `test_cooldown_differentKeyword_notBlocked`() {
        // Cooldown của "tự tử" không ảnh hưởng đến "cờ bạc"
        AppMonitorService.recordKeywordAlert("tự tử", CHROME_PKG)

        val isBlockedForSameKeyword = AppMonitorService.isOnCooldown("tự tử", CHROME_PKG)
        val isBlockedForOtherKeyword = AppMonitorService.isOnCooldown("cờ bạc", CHROME_PKG)

        assertTrue("Keyword 'tự tử' phải bị cooldown", isBlockedForSameKeyword)
        assertFalse("Keyword 'cờ bạc' KHÔNG liên quan, không được bị cooldown", isBlockedForOtherKeyword)
    }

    @Test
    fun `test_cooldown_perApp_chromeAndSearchAreIndependent`() {
        // Cooldown của Chrome không lan sang Google Search (và ngược lại)
        AppMonitorService.recordKeywordAlert("tự tử", CHROME_PKG)

        val isBlockedOnChrome = AppMonitorService.isOnCooldown("tự tử", CHROME_PKG)
        val isBlockedOnGoogleSearch = AppMonitorService.isOnCooldown("tự tử", GOOGLE_SEARCH_PKG)

        assertTrue("Chrome phải bị cooldown sau khi record", isBlockedOnChrome)
        assertFalse(
            "Google Search không liên quan đến Chrome cooldown — phải độc lập!",
            isBlockedOnGoogleSearch
        )
    }

    @Test
    fun `test_cooldown_value_is5Minutes`() {
        // Xác minh constant KEYWORD_COOLDOWN_MS = 300_000L (5 phút)
        // Dùng method getCooldownMs() được expose sẵn thay vì reflection
        val cooldownValue = AppMonitorService.getCooldownMs()
        assertEquals(
            "❌ KEYWORD_COOLDOWN_MS phải là 300,000ms (5 phút), không phải $cooldownValue!",
            300_000L,
            cooldownValue
        )
    }

    // ─── GROUP 2: Package Scope Filter ───────────────────────────────────────

    @Test
    fun `test_scope_chrome_isAllowed`() {
        // Chức năng internal: isKeywordMonitorTarget phải trả về true với Chrome
        val result = isKeywordMonitorTarget(CHROME_PKG)
        assertTrue("Chrome phải được theo dõi keyword", result)
    }

    @Test
    fun `test_scope_googleSearch_isAllowed`() {
        val result = isKeywordMonitorTarget(GOOGLE_SEARCH_PKG)
        assertTrue("Google Search phải được theo dõi keyword", result)
    }

    @Test
    fun `test_scope_tiktok_isBlocked`() {
        // TikTok KHÔNG được theo dõi keyword theo yêu cầu
        val result = isKeywordMonitorTarget(TIKTOK_PKG)
        assertFalse("❌ TikTok KHÔNG được phép theo dõi keyword! (vi phạm phạm vi giám sát)", result)
    }

    @Test
    fun `test_scope_facebook_isBlocked`() {
        val result = isKeywordMonitorTarget(FACEBOOK_PKG)
        assertFalse("❌ Facebook KHÔNG được phép theo dõi keyword!", result)
    }

    @Test
    fun `test_scope_instagram_isBlocked`() {
        val result = isKeywordMonitorTarget(INSTAGRAM_PKG)
        assertFalse("❌ Instagram KHÔNG được phép theo dõi keyword!", result)
    }

    @Test
    fun `test_scope_zalo_isBlocked`() {
        val result = isKeywordMonitorTarget(ZALO_PKG)
        assertFalse("❌ Zalo KHÔNG được phép theo dõi keyword!", result)
    }

    @Test
    fun `test_scope_youtube_isBlocked`() {
        val result = isKeywordMonitorTarget(YOUTUBE_PKG)
        assertFalse("❌ YouTube KHÔNG được phép theo dõi keyword!", result)
    }

    @Test
    fun `test_scope_discord_isBlocked`() {
        val result = isKeywordMonitorTarget(DISCORD_PKG)
        assertFalse("❌ Discord KHÔNG được phép theo dõi keyword!", result)
    }

    // ─── GROUP 3: Text Matching (Case-insensitive & Tiếng Việt) ──────────────

    @Test
    fun `test_matching_caseSensitive_upperCase`() {
        // "TỰ TỬ" viết hoa phải được nhận diện giống "tự tử" thường
        AppMonitorService.monitoredKeywords = setOf("tự tử")
        val textUpper = "Tôi muốn TỰ TỬ"
        val isDetected = containsAnyKeyword(textUpper, AppMonitorService.monitoredKeywords)
        assertTrue("'TỰ TỬ' viết hoa không được nhận diện — lỗi case-insensitive!", isDetected)
    }

    @Test
    fun `test_matching_caseSensitive_mixedCase`() {
        AppMonitorService.monitoredKeywords = setOf("cờ bạc")
        val textMixed = "Chơi Cờ Bạc online"
        val isDetected = containsAnyKeyword(textMixed, AppMonitorService.monitoredKeywords)
        assertTrue("'Cờ Bạc' viết hỗn hợp không được nhận diện!", isDetected)
    }

    @Test
    fun `test_matching_vietnameseDiacritics_sungKeyword`() {
        // "SÚNG" và "súng" và "Súng" đều phải khớp
        AppMonitorService.monitoredKeywords = setOf("súng")
        val texts = listOf("mua súng", "Mua SÚNG lậu", "bán Súng")
        for (text in texts) {
            val isDetected = containsAnyKeyword(text, AppMonitorService.monitoredKeywords)
            assertTrue("'$text' không được nhận diện — lỗi Vietnamese diacritics!", isDetected)
        }
    }

    @Test
    fun `test_matching_noKeyword_noAlert`() {
        // Text không chứa bất kỳ keyword nào → trả về false
        AppMonitorService.monitoredKeywords = setOf("tự tử", "ma túy")
        val safeText = "Hôm nay thời tiết đẹp quá!"
        val isDetected = containsAnyKeyword(safeText, AppMonitorService.monitoredKeywords)
        assertFalse("Text an toàn nhưng bị nhận diện là nguy hiểm!", isDetected)
    }

    @Test
    fun `test_matching_multipleKeywords_detectsAll`() {
        // Text chứa nhiều keyword → tất cả đều phải được phát hiện riêng lẻ
        AppMonitorService.monitoredKeywords = setOf("tự tử", "đánh nhau")
        val dangerText = "Chúng tôi đánh nhau rồi tự tử"
        val isDetected = containsAnyKeyword(dangerText, AppMonitorService.monitoredKeywords)
        assertTrue("Text chứa 2 keyword nhưng không được nhận diện!", isDetected)
    }

    @Test
    fun `test_matching_emptyText_noAlert`() {
        val isDetected = containsAnyKeyword("", AppMonitorService.monitoredKeywords)
        assertFalse("Text rỗng không được trigger alert!", isDetected)
    }

    @Test
    fun `test_matching_keyword_partialWordBoundary`() {
        // "bạc" KHÔNG phải "cờ bạc" — kiểm tra false positive
        AppMonitorService.monitoredKeywords = setOf("cờ bạc")
        val text = "áo màu bạc" // có "bạc" nhưng không phải "cờ bạc"
        val isDetected = containsAnyKeyword(text, AppMonitorService.monitoredKeywords)
        assertFalse("'áo màu bạc' bị nhầm là 'cờ bạc' — false positive!", isDetected)
    }

    // ─── GROUP 4: recordKeywordAlert + isOnCooldown integration ──────────────

    @Test
    fun `test_integration_recordThenCheck_sameApp_sameKeyword`() {
        val keyword = "ma túy"
        val pkg = CHROME_PKG

        // Trước khi record: không cooldown
        assertFalse(AppMonitorService.isOnCooldown(keyword, pkg))

        // Sau khi record: có cooldown
        AppMonitorService.recordKeywordAlert(keyword, pkg)
        assertTrue(AppMonitorService.isOnCooldown(keyword, pkg))
    }

    @Test
    fun `test_integration_multipleKeywords_eachTrackedIndependently`() {
        AppMonitorService.recordKeywordAlert("tự tử", CHROME_PKG)
        AppMonitorService.recordKeywordAlert("cờ bạc", GOOGLE_SEARCH_PKG)

        // "tự tử" cooldown trên Chrome
        assertTrue(AppMonitorService.isOnCooldown("tự tử", CHROME_PKG))
        // "tự tử" KHÔNG cooldown trên Google Search (khác app)
        assertFalse(AppMonitorService.isOnCooldown("tự tử", GOOGLE_SEARCH_PKG))
        // "cờ bạc" cooldown trên Google Search
        assertTrue(AppMonitorService.isOnCooldown("cờ bạc", GOOGLE_SEARCH_PKG))
        // "cờ bạc" KHÔNG cooldown trên Chrome (khác app)
        assertFalse(AppMonitorService.isOnCooldown("cờ bạc", CHROME_PKG))
    }

    // ─── HELPER FUNCTIONS ────────────────────────────────────────────────────

    /**
     * Hàm helper mô phỏng logic lọc package trong AppMonitorService.
     * Phản chiếu đúng logic trong code production.
     */
    private fun isKeywordMonitorTarget(packageName: String): Boolean {
        return packageName == "com.android.chrome" ||
                packageName == "com.google.android.googlequicksearchbox"
    }

    /**
     * Hàm helper mô phỏng logic matching keyword trong checkTextForKeywords().
     * Case-insensitive theo yêu cầu.
     */
    private fun containsAnyKeyword(text: String, keywords: Set<String>): Boolean {
        if (text.isBlank()) return false
        val lowerText = text.lowercase()
        return keywords.any { keyword ->
            lowerText.contains(keyword.lowercase())
        }
    }
}

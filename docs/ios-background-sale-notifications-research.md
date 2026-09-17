# iOS 背景更新與最愛特價通知可行性研究

> 研究日期：2026-09-17。研究範圍：iOS app 不在前景時，抓取 GitHub Pages 型錄、讀取本機最愛，並以本地通知提醒新特價；不使用遠端推播。

## 結論

**可以做成 best-effort 背景功能，但 iOS 不保證 app 會在特定時間執行。** 合適的流程是用 `BGAppRefreshTask` 讓系統在合適時機短暫喚醒 app；喚醒後讀取舊型錄和最愛 ID、抓取較新的型錄，找出最愛遊戲從未特價變成特價的項目，再排入 `UNUserNotificationCenter` 的本地通知。Apple 將這類短時間內容更新列為 `BGAppRefreshTask` 的用途，單次工作最多約 30 秒，實際啟動時間由系統決定。[Apple：Choosing Background Strategies](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app)、[Apple：Using Background Tasks to Update Your App](https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app)

本地通知可在 app 不執行時由系統呈現，無須 APNs；但**偵測新折扣仍需要 app 曾獲得背景執行機會**。若「關閉」代表使用者從 App Switcher 強制結束，Apple DTS 表示 `BGAppRefreshTaskRequest` 不會重新啟動被強制結束的 app。若需求是 app 從未被喚醒時，仍由伺服器主動提示新折扣，就必須另加遠端推播機制；本研究限定的本地通知方案無法保證。即使使用推播，Apple 也不保證通知一定即時送達；另一種本地方案是先取得未來特價開始時間並預先排程通知。[Apple Developer Forums：DTS 對 force-quit 與 BGAppRefresh 的說明](https://developer.apple.com/forums/thread/793189)、[Apple：User Notifications](https://developer.apple.com/documentation/usernotifications)

## 目前專案狀態

- iOS app 從 `https://tom19830924.github.io/eshop-pulse/normalized/games.meta.json` 檢查版本，再需要時抓 `games.json`；本機型錄快取放在 Application Support。可見 [`LiveCatalogRepository.swift`](../apps/ios/eshop-pulse/eshop-pulse/Data/LiveCatalogRepository.swift) 與 [`CatalogCacheStore.swift`](../apps/ios/eshop-pulse/eshop-pulse/Data/CatalogCacheStore.swift)。
- 最愛 ID 以 `favoriteGameIDs` key 存在 `UserDefaults.standard`；價格資料已有 `isOnSale`、`saleStartsAt` 和 `saleEndsAt` 欄位。可見 [`GameListViewModel.swift`](../apps/ios/eshop-pulse/eshop-pulse/Features/GameList/GameListViewModel.swift) 與 [`GamePrice.swift`](../apps/ios/eshop-pulse/eshop-pulse/Models/GamePrice.swift)。Apple 說明 `UserDefaults.standard` 是 app 共用且持久的 defaults 儲存區，可由該 app 的背景工作讀取。[Apple：UserDefaults.standard](https://developer.apple.com/documentation/foundation/userdefaults/standard)
- 現有 app 只在 SwiftUI 畫面載入時呼叫資料載入；目前沒有 `BGTaskScheduler` 或 `UNUserNotificationCenter` 實作。可見 [`GameListView.swift`](../apps/ios/eshop-pulse/eshop-pulse/Features/GameList/GameListView.swift)。
- 型錄和價格已由 [`publish-catalog.yml`](../.github/workflows/publish-catalog.yml) 每日排程更新並部署到 GitHub Pages，排程為 18:23 UTC（台北時間 02:23）。依使用者補充，四個串行 job 通常到台北時間約 05:00 才完成；每日背景檢查應安排在其後，建議以 09:00 作為最早執行時間，留下約四小時緩衝。GitHub Pages 發佈靜態檔案；目前 GitHub Actions 負責擷取、整理和部署資料。GitHub 說明排程工作可能在高負載時延遲，甚至有工作被丟棄。[GitHub Pages：建立與發佈網站](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)、[GitHub Actions：schedule 事件](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)

因此整條提醒流程要等當天 GitHub Actions 完成發布，再等 iOS 獲得一次 opportunistic background wake；02:23 是資料更新流程的觸發時間，約 05:00 才是目前觀察到的完成時間。把背景工作的最早執行時間設在 09:00 可避免通常情況下讀到前一天的資料，但不保證 GitHub Actions 異常延遲時一定等到部署完成。

## 建議流程

1. 在 app 啟動時註冊 `BGAppRefreshTask`，並在每次工作結束後提交下一次請求。可按每日節奏提交，將下一次日期的 `earliestBeginDate` 設為台北時間 09:00。這只代表「不早於 09:00」，**不代表當天一定執行一次，也沒有 2–3 天內必跑的保證**；Apple 明確說系統不保證於指定日期啟動。不過 Apple 表示系統會參考 app 使用模式，常用 app 較常獲得排程，所以 2–3 天可作為最佳努力目標，不能當成硬性服務水準。[Apple：earliestBeginDate](https://developer.apple.com/documentation/backgroundtasks/bgtaskrequest/earliestbegindate)、[Apple：backgroundRefreshStatus](https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus)、[Apple WWDC25：Finish tasks in the background](https://developer.apple.com/videos/play/wwdc2025/227/)
2. 背景 handler 先讀取舊快取，再讀取 `UserDefaults.standard["favoriteGameIDs"]`，然後呼叫既有 repository 更新。repository 會在成功下載後覆寫快取，所以比較必須先保留舊型錄，再和新型錄比對。
3. 依遊戲 ID 配對新舊資料，只對「舊 `isOnSale == false`、新 `isOnSale == true`，且 ID 在最愛清單」的項目排通知。若是首次下載、沒有舊型錄，應先建立基準，不把所有現有特價誤報為新折扣。
4. 先取得使用者的通知授權，再以 `UNNotificationRequest` 排入本地通知。系統可在 app 不執行時呈現通知；使用者若拒絕通知授權，系統不會遞送提醒。[Apple：Scheduling a Notification Locally](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)、[Apple：通知授權狀態](https://developer.apple.com/documentation/usernotifications/unnotificationsettings/authorizationstatus)

## 主要限制

| 狀況 | 對這項功能的影響 |
| --- | --- |
| App 在背景或已被系統暫停 | 系統可能在背景啟動它執行 refresh，但時機不固定；`BGAppRefreshTask` 單次約有最多 30 秒。需實作到期取消與完成回報。 |
| 使用者從 App Switcher 強制結束 app | 不應依賴 `BGAppRefreshTask` 再啟動 app；新折扣可能要等使用者下次手動開啟才會被發現。Apple DTS 明確指出 `BGAppRefreshTaskRequest` 不會為已強制結束的 app 重新啟動。 |
| 連續 2–3 天沒有背景執行 | iOS 沒有可設定「最晚 72 小時內必須執行」的 BGTask 保證；系統可因 app 使用頻率、裝置狀態與資源而延後或略過。每日使用 app、Background App Refresh 開啟時較有利，但仍須視為 best-effort。 |
| 關閉 Background App Refresh 或低耗電模式 | 背景更新可能不可用或時間縮短。可檢查 `UIApplication.backgroundRefreshStatus`；Apple 文件也說低耗電模式會自動停用 Background App Refresh。[Apple：backgroundRefreshStatus](https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus) |
| GitHub Actions 或 iOS 背景排程延遲 | 09:00 的最早執行時間比目前約 05:00 的部署完成時間多留四小時緩衝；若 Actions 延遲超過緩衝，或 iOS 當天沒有喚醒 app，提醒仍可能延遲一天以上。 |
| 通知權限未授予 | 更新和比對仍可發生，但使用者不會收到 alert；應在功能設定頁說明用途並呈現目前權限狀態。 |

`BGProcessingTask` 是給可能需要數分鐘的處理工作；它的排程同樣由系統決定。Apple DTS 討論指出它在強制結束後的行為和 `BGAppRefreshTask` 不同，但屬於依系統／app 使用模式而變的行為，不能當成準時 refresh 的保證。因此這個短型錄更新應以 `BGAppRefreshTask` 為主，不用 `BGProcessingTask` 規避 force-quit 限制。[Apple：Choosing Background Strategies](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app)、[Apple Developer Forums](https://developer.apple.com/forums/thread/793189)

## 建議決策

如果產品接受「每天從 09:00 後嘗試更新一次，目標 2–3 天內檢查到，但實際可能更久或漏掉」，可以實作 `BGAppRefreshTask` + 本地通知，不需要更動 GitHub Pages 架構或新增遠端推播。實際使用時應在真機/TestFlight 記錄最後一次背景成功時間，觀察目標使用者是否通常能落在 2–3 天內；若不能接受偶爾超過 3 天，就需要其他觸發機制。建議通知把同次更新中上架特價的最愛合併成一則摘要，並用舊／新快取比對避免重複提醒。

若價格資料提供某款最愛遊戲的未來 `saleStartsAt`，也可在 app 正常開啟時先排程該開始時間的本地通知；這可涵蓋已知的未來特價，但不能取代背景抓取，因為新特價可能在下一次 app 背景執行前才被公布。現有資料模型保留 `saleStartsAt`，實際是否常有未來開始時間仍取決於上游價格回應。

## 一手來源

- [Apple：Choosing Background Strategies for Your App](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app)
- [Apple：Using Background Tasks to Update Your App](https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app)
- [Apple：earliestBeginDate](https://developer.apple.com/documentation/backgroundtasks/bgtaskrequest/earliestbegindate)
- [Apple：backgroundRefreshStatus](https://developer.apple.com/documentation/uikit/uiapplication/backgroundrefreshstatus)
- [Apple：UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
- [Apple：Scheduling a Notification Locally](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [Apple：User Notifications](https://developer.apple.com/documentation/usernotifications)（系統會盡力及時遞送，但不保證通知送達）
- [Apple：Asking Permission to Use Notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- [Apple WWDC25：Finish tasks in the background](https://developer.apple.com/videos/play/wwdc2025/227/)（系統依 app 使用模式與裝置條件安排背景工作；常用 app 較常獲得 `BGAppRefreshTask` 排程）
- [Apple DTS：BGProcessingTaskRequest 與 force-quit 討論（內含 BGAppRefresh 行為說明）](https://developer.apple.com/forums/thread/793189)
- [GitHub：Creating a GitHub Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site)
- [GitHub Actions：Events that trigger workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows)

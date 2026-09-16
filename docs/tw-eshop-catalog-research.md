# 台灣 eShop 型錄來源研究

## 結論

目前能可靠取得的是任天堂台灣網站的**主軟體列表**，不是經驗證的完整
eShop 商品型錄。

1. `https://www.nintendo.com/tw/api/software?sftab=all&spage=N` 可按頁取得它宣告的
   軟體列表。2026-09-15 即時來源回傳 **4,017** 筆（現有快照為稍早的 4,015 筆）；
   該快照中 **4,011** 筆是 `7001…` 遊戲本體，只有 **3** 筆 bundle 和 **1** 筆
   AOC（均為 `7007…`）。
   因此不能把這個 API 稱為「遊戲＋所有 DLC／套裝」的全站目錄。
2. 沒有找到台灣任天堂公開、可分頁列舉全站 DLC／AOC／bundle，並提供全域總數
   以驗證完整性的操作。`/api/software` 的 `sftab` 值也沒有公開的 DLC 全站分類。
3. 台灣 eShop 共用前端程式包含以**單一遊戲 NSUID**查詢 DLC 的
   `DlcItemList` GraphQL 操作，並以 `offsetInfo.total`／`offsetInfo.offset`
   支援單一遊戲的分頁。它不是全站商品
   搜尋；即使啟用，也需要對每款本體個別查詢。惟此環境開啟台灣 `/aocs` 頁面
   顯示錯誤 `9001-1633`（居住國家／地區無法使用），且直接重建 GraphQL 請求
   被服務以 400 拒絕，故不能聲稱已觀察到台灣商品的成功 DLC 回應。

台灣 v1 應保存並使用這份官方主軟體列表；暫不蒐集 DLC／套裝，且檔案／文件
應稱為「官方主軟體列表」，而非完整 eShop 商品型錄。

## 已驗證行為（2026-09-15）

| 項目 | 第一方證據 | 結果 |
|---|---|---|
| 主軟體列表與分頁 | [`/tw/api/software?sftab=all&spage=1`](https://www.nintendo.com/tw/api/software?sftab=all&spage=1) | 回傳 `total = 4,017` 與 `items`；每頁 24 筆，第 168 頁有 9 筆、第 169 頁為空。可完整取得目前的主軟體列表。現有 4,015 筆快照是稍早抓取，需下次刷新。 |
| 主列表商品類型 | 同一官方回應 | 快照中 4,011 筆 NSUID 為 `7001…`，3 筆為 bundle、1 筆為 AOC；這不可能代表所有台灣 eShop DLC。 |
| eShop 價格服務 | [`/v1/price?country=TW&lang=zh&ids=…`](https://api.ec.nintendo.com/v1/price?country=TW&lang=zh&ids=70010000046398,70070000029532) | 對本體 `70010000046398` 與主列表內 AOC `70070000029532` 都回傳 `sales_status` 與價格，證明台灣確有可查價的 eShop 商品資料面；它是按已知 ID 查價，不能列舉型錄。 |
| 共用 DLC 前端操作 | [台灣 eShop DLC 路由載入的 JS](https://ec.nintendo.com/_next/static/chunks/44-xmt-igwv-7.js) | 定義 `DlcItemList`，呼叫 `dlcItemsByApplicationItem(nsUid, offset, limit, publicStatuses, salesStatuses, isIncludeBundleItem)`，並讀取 `offsetInfo.total`／`offsetInfo.offset`。 |
| 台灣頁面可用性 | [`/TW/zh/titles/70010000046398/aocs`](https://ec.nintendo.com/TW/zh/titles/70010000046398/aocs) | 瀏覽器在本環境顯示錯誤 `9001-1633`（居住國家／地區無法使用）。因此未取得可引用的台灣 DLC 總數或成功 GraphQL 回應。 |
| 不存在 DLC 全站分類 | [`sftab=aoc`](https://www.nintendo.com/tw/api/software?sftab=aoc&spage=1) 與[未給 `sftab` 的預設列表](https://www.nintendo.com/tw/api/software?spage=1) | 回應內容相同；`aoc`、`bundle`、`dlc` 都不是可用的隱藏全站分類。 |

共用前端程式中的操作範圍為：

```text
item.dlcItemsByApplicationItem(
  nsUid, offset, limit,
  publicStatuses: [PUBLIC],
  salesStatuses: [ONSALE, PRE_ORDER],
  isIncludeBundleItem: true
)
```

這表示它在設計上是「已知本體遊戲底下的公開、可售／可預購 DLC 和關聯 bundle」
查詢；即使確認台灣可用，也不會是全站搜尋，且需對每個本體分別發請求。

## v1 建議

台灣 v1 只抓官方主軟體列表、忽略 DLC／套裝。台灣的前端程式可確認其 DLC 資料
模型，但本環境因地區限制未能驗證成功回應；即使未來可用，也需對每款本體個別
查詢，仍不適合每日工作。

若未來需要補強台灣 DLC，應先以少量樣本驗證實際 GraphQL 回應與限流，再評估
逐遊戲抓取的成本；不要直接對約四千款遊戲發送每日請求。

## 一手來源

- [台灣任天堂主軟體列表 API](https://www.nintendo.com/tw/api/software?sftab=all&spage=1)
- [台灣 eShop 價格 API 範例](https://api.ec.nintendo.com/v1/price?country=TW&lang=zh&ids=70010000046398,70070000029532)
- [台灣 eShop 商品頁測試](https://ec.nintendo.com/TW/zh/titles/70010000046398)
- [台灣 eShop 新增內容路由測試](https://ec.nintendo.com/TW/zh/titles/70010000046398/aocs)
- [台灣 eShop 所載入的共用 DLC 前端程式](https://ec.nintendo.com/_next/static/chunks/44-xmt-igwv-7.js)

# 台灣任天堂公開網站 API 資料面研究

> 研究日期：2026-09-16。本文只記錄任天堂台灣網站的公開前端在一般未登入
> 瀏覽情境下實際使用、且已小範圍驗證的資料端點；它們不是任天堂對第三方承諾
> 穩定的開發者 API。

## 結論

台灣網站至少有兩個用途不同的 `/tw/api/` 端點：

| 用途 | 已確認端點 | 適合做什麼 | 不適合做什麼 |
| --- | --- | --- | --- |
| 軟體型錄 | [`/tw/api/software?sftab=all&spage=N`](https://www.nintendo.com/tw/api/software?sftab=all&spage=1) | 依頁取得官方主軟體列表 | 依 NSUID 精確查詢、取得價格 |
| 網站文字搜尋 | [`/tw/api/search?k=monster%20hunter&directory=software&size=24`](https://www.nintendo.com/tw/api/search?k=monster%20hunter&directory=software&size=24) | 依關鍵字找遊戲、Q&A、文章或 amiibo | 當成完整可列舉型錄、以 NSUID 查單品 |

價格不在這兩個台灣網站端點中；它來自另一個 Nintendo eShop 價格服務，按已知
NSUID 查詢：

```text
GET https://api.ec.nintendo.com/v1/price?country=TW&lang=zh&ids={comma-separated-NSUIDs}
```

例如可使用[兩個已知 NSUID 的官方價格查詢](https://api.ec.nintendo.com/v1/price?country=TW&lang=zh&ids=70010000046398,70070000029532)。

## `/tw/api/search`：全站關鍵字搜尋

使用者提供的 URL 是有效的正常搜尋請求：

```text
GET /tw/api/search?k=monster%20hunter&directory=software&size=24
```

以該請求在研究當下取得的回應外層為：

```json
{
  "items": ["..."],
  "total": 6,
  "more": false
}
```

`directory=software` 的項目是遊戲樣式資料，範例項目包含 `title`、`nsuid`、
`releaseDate`、`softCode`、`imageHero`、`hardwareCategory`、`category`、
`publisher`、`developer`、`rating`、`supportedLanguages` 與 `pageLink`。這讓它
適合用來查核某個文字名稱的候選遊戲，但不能證明搜尋結果是全型錄。

### 已由官方前端程式確認的參數

台灣搜尋首頁載入的官方 JavaScript 在使用者輸入關鍵字後，會發出四個搜尋請求：

```text
/tw/api/search?k={keyword}&directory=software&size=8
/tw/api/search?k={keyword}&directory=qna&size=5
/tw/api/search?k={keyword}&directory=topics&size=8
/tw/api/search?k={keyword}&directory=amiibo&size=8
```

當使用者進入「遊戲軟體」完整搜尋頁時，同一份官方程式會使用：

```text
/tw/api/search?k={keyword}&p={one-based-page}&directory=software&size=24
```

因此已確認的搜尋參數及意義為：

| 參數 | 證據 | 意義 |
| --- | --- | --- |
| `k` | 前端將搜尋輸入值寫入 `k` | 關鍵字 |
| `directory` | 前端使用 `software`、`qna`、`topics`、`amiibo` | 搜尋的內容類型 |
| `size` | 首頁使用 8／5；完整列表使用 24 | 每次想取得的結果數 |
| `p` | 完整結果頁的 Pager 以 `p` 傳遞 | 一起使用時的 1 起算頁碼 |

沒有在正常網站前端請求或程式中發現 `nsuid` 作為 `/api/search` 的篩選參數。因此
不能假定 `&nsuid=...` 會被支援；已知商品應使用 eShop 價格端點查價，或走官方
商品頁路由。

### 一手程式證據

官方搜尋頁 [`/tw/search`](https://www.nintendo.com/tw/search) 載入的
[搜尋頁 JavaScript chunk](https://www.nintendo.com/tw/_next/static/chunks/0g55yjbuib6xy.js)
包含上述四個 `directory` 值、首頁數量（software/topics/amiibo 為 8、qna 為 5）
及組合 `/tw/api/search?...` 的程式。官方「遊戲軟體」搜尋頁
[`/tw/search/software`](https://www.nintendo.com/tw/search/software?k=monster%20hunter)
載入的[結果頁 JavaScript chunk](https://www.nintendo.com/tw/_next/static/chunks/0vg-ro4x4gtqk.js)
則組合 `k`、`p`、`directory`、`size=24`，並以 `total` 驅動分頁器。

## `/tw/api/software`：主軟體型錄

目前可可靠用於每日快照的是：

```text
GET /tw/api/software?sftab=all&spage={one-based-page}
```

它的回應外層為 `items` 與 `total`。已驗證第一頁為 24 筆，且 `total` 可用來計算
頁數；詳見既有的[台灣 eShop 型錄來源研究](tw-eshop-catalog-research.md)。

這個端點與 `/api/search` 的差別很重要：

- 型錄用 `spage` 分頁，搜尋用 `p` 分頁。
- 型錄目前的正式抓取方式是 `sftab=all&spage=N`；搜尋則必須給文字 `k`，結果由
  搜尋索引決定，不能當作完整型錄列舉。
- 型錄商品項目不含目前售價或特價；價格要用 NSUID 到 eShop 價格服務另查。

官方前端程式也列出了軟體頁 URL 可能保留的 UI 查詢鍵：`sftab`、`sfq`、`spage`、
`sfsort`、`k`、`p`、`directory`。這只證明網站 UI 會保留／傳遞這些鍵；本文只把
`sftab=all` 與 `spage=N` 視為已驗證且可依賴的型錄 API 參數，不把其他鍵宣稱為
已驗證的伺服器篩選能力。

## 安全的端點探勘方法

可以探勘，但不應掃描猜測路徑。建議只做以下來源驅動的流程：

1. 在一般瀏覽器開啟官方頁面，使用頁面原本提供的搜尋、篩選或換頁控制項。
2. 在開發者工具 Network 中，篩選 Fetch/XHR，記下實際成功的 request URL、方法、
   必要 header、回應結構與總數／分頁訊號。
3. 針對該頁已載入的官方 JavaScript，以明確字串搜尋 `api/`、`fetch`、
   `URLSearchParams`、GraphQL operation 名稱；只確認頁面程式已使用的路徑與參數。
4. 最多用少量正常 UI 等價請求重放，以驗證一頁回應與翻頁；記錄資料量與錯誤。

不建議列舉字典式 `/api/*` 路徑、測試大量任意參數、快速並行翻大量搜尋頁，或對
單一商品逐頁抓取。這些行為不會可靠地發現「全部端點」，反而更接近不正常流量。

## 對本專案的含義

- 每日原始台灣主軟體快照繼續使用 `/tw/api/software?sftab=all&spage=N`。
- 未來 App 若要提供文字搜尋，可選擇在本機資料上搜尋；不應依賴 `/api/search` 作為
  全型錄或跨區配對服務。
- 台灣價格與特價仍採「型錄取得 NSUID → eShop 批次價格 API 補價」的兩段方式。
- 若未來研究新端點，先以官方頁面實際請求作為證據，再加入 adapter；沒有公開契約
  的端點可能隨網站改版而失效。

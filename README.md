# Universal Hub v3.0

Script Roblox executor sử dụng **LinoriaLib GUI**, tích hợp đầy đủ các tính năng Movement, ESP, Combat, và Misc.

**Tác giả:** Bien  
**GUI Library:** [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib)

---

## Cài đặt & Sử dụng

Dán đoạn sau vào executor của bạn:

```lua
loadstring(game:HttpGet("URL_TO_SCRIPT"))()
```

> **Yêu cầu:** Executor phải hỗ trợ `HttpGet`, `Drawing API`, và các exploit API cơ bản (`setclipboard`, `fireproximityprompt`).

---

## Phím tắt mặc định

| Phím | Chức năng |
|------|-----------|
| `Right Shift` | Ẩn/hiện UI |
| `F` | Bật/tắt Fly |
| `N` | Bật/tắt Noclip |
| `P` | Bật/tắt Pull Players |
| `T` | Teleport đến vị trí chuột (khi bật Click Teleport) |

---

## Tính năng theo Tab

### Tab: Player

#### Movement (Di chuyển)
| Tính năng | Mô tả |
|-----------|-------|
| **Speed Boost** | Tăng tốc độ di chuyển. Hỗ trợ 3 phương pháp: `WalkSpeed`, `CFrame`, `Velocity` |
| **Boost Power** | Slider điều chỉnh tốc độ (16 – 500) |
| **Infinite Jump** | Nhảy không giới hạn lần |
| **Noclip** | Xuyên tường — tắt collision của toàn bộ body parts, khôi phục khi tắt |
| **Teleport To Mouse (T)** | Nhấn `T` để teleport đến vị trí chuột đang chỉ (dùng Raycast) |
| **Freeze Position** | Khóa nhân vật tại chỗ, ngăn mọi lực tác dụng |
| **Instant Interaction** | Đặt `HoldDuration = 0` cho tất cả `ProximityPrompt` trong Workspace |
| **Auto Pick Up Items** | Tự động trigger ProximityPrompt gần nhân vật theo bán kính (5 – 50 studs) |

#### Teleport (Dịch chuyển người chơi)
| Tính năng | Mô tả |
|-----------|-------|
| **Teleport To Player** | Dịch chuyển đến bên cạnh người chơi được chọn |
| **Spectate Player** | Chuyển camera sang nhân vật của người chơi đó |
| **Un Spectate** | Khôi phục camera về nhân vật của bản thân |
| **Refresh Player List** | Cập nhật danh sách người chơi |

#### Points (Điểm teleport đã lưu)
| Tính năng | Mô tả |
|-----------|-------|
| **Save Point** | Lưu vị trí hiện tại với tên tự động (`Point 1`, `Point 2`, ...) |
| **Teleport To Point** | Dịch chuyển đến điểm đã chọn |
| **Delete Point** | Xóa điểm đã chọn |
| **Refresh List** | Cập nhật dropdown |

#### Fly (Bay)
| Tính năng | Mô tả |
|-----------|-------|
| **Fly** | Bay tự do — điều hướng bằng `W/A/S/D`, lên bằng `Space`, xuống bằng `Left Shift` |
| **Fly Speed** | Tốc độ bay (10 – 200) |
| **Auto Climb** | Tự động bay lên bằng `BodyVelocity` |
| **Climb Speed** | Tốc độ leo (1 – 100) |
| **Anti-Wind** | Giới hạn velocity dọc trong khoảng `[-2, 2]`, ngăn bị thổi bay |
| **Float** | Giữ nhân vật lơ lửng tại chỗ (zero vertical velocity) |
| **Spin Player** | Xoay nhân vật liên tục. Điều chỉnh tốc độ bằng slider |

---

### Tab: Visual

#### Modern ESP
Hệ thống ESP vẽ overlay bằng **Drawing API** lên màn hình. Hỗ trợ cả bot/fake player.

| Thành phần | Mô tả |
|------------|-------|
| **Enable ESP Master** | Bật/tắt toàn bộ ESP |
| **Show Boxes** | Khung chữ nhật 2D quanh nhân vật |
| **Show Names** | Tên người chơi phía trên đầu |
| **Show Distance** | Khoảng cách (studs) đến mục tiêu |
| **Show Health Bars** | Thanh máu bên cạnh khung |
| **Show Tracers** | Đường thẳng từ cuối màn hình đến mục tiêu |
| **Show Chams (Highlight)** | Highlight toàn thân bằng `SelectionBox` |
| **Show Skeleton** | Vẽ khung xương (hỗ trợ R6 & R15) |
| **Show Weapon** | Hiển thị tên Tool đang cầm |
| **Team Check** | Bỏ qua đồng đội — hỗ trợ nhiều chế độ detect team |

**Team Check Modes:**
- Auto Detect
- Auto (Try All)
- Roblox Teams
- FactionType Attribute
- Team Attribute
- IntValue (Team)
- StringValue (Team)
- TeamColor

#### Lighting
| Tính năng | Mô tả |
|-----------|-------|
| **Fullbright** | Tăng Ambient, tắt GlobalShadows — nhìn rõ trong bóng tối |
| **No Fog** | Xóa sương mù, đặt `FogEnd = 1,000,000`, tắt Atmosphere/Bloom/Blur/SunRays |
| **Force Time** | Khóa giờ trong game theo slider (0 – 24h) |
| **FOV** | Điều chỉnh góc nhìn camera (30 – 120) |

---

### Tab: Combat

#### Client Pull
Kéo người chơi đến vị trí phía trước mặt (client-side). Có thể điều khiển qua chat bởi username được cấu hình.

| Tính năng | Mô tả |
|-----------|-------|
| **Pull Players** | Bật/tắt kéo người (phím `P`) |
| **Pull Radius** | Bán kính tìm mục tiêu |
| **Pull Distance** | Khoảng cách kéo đến |
| **Max Targets** | Số mục tiêu tối đa kéo cùng lúc |
| **Pull Offset X/Y** | Điều chỉnh vị trí kéo đến |
| **Control Username** | Tên người dùng được phép dùng `/stop` và `/next` qua chat để điều khiển Pull |

#### Aimbot
| Tính năng | Mô tả |
|-----------|-------|
| **Aimbot** | Tự động ngắm vào mục tiêu |
| **Hold to Aim** | Chỉ aimbot khi giữ nút |
| **Aim Part** | Chọn bộ phận ngắm (Head, Torso, v.v.) |
| **FOV** | Bán kính FOV aimbot (circle hiển thị trên màn hình) |
| **Smoothness** | Độ mượt khi xoay camera |
| **Visible Only** | Chỉ ngắm mục tiêu trong tầm nhìn |
| **Lock Target** | Khóa mục tiêu hiện tại |
| **Show FOV Circle** | Hiển thị vòng tròn FOV |
| **Show Target Info** | Hiển thị thông tin mục tiêu |

#### Weapon (Vũ khí)
| Tính năng | Mô tả |
|-----------|-------|
| **No Spread** | Xóa độ lệch đạn — patch NumberValue/ModuleScript trong Tool |
| **No Recoil** | Loại bỏ giật nòng |
| **Instant Reload** | Đặt reload time = 0 |
| **Rapid Fire** | Đặt fire rate/delay = 0 |

> Các tính năng weapon patch trực tiếp giá trị trong `NumberValue`, `IntValue`, và `ModuleScript` của Tool đang cầm. Tự động khôi phục khi bỏ Tool.

---

### Tab: Misc

#### Extra
| Tính năng | Mô tả |
|-----------|-------|
| **Anti-AFK** | Dùng `VirtualUser` để ngăn game kick do idle |
| **Anti-Blur** | Xóa toàn bộ `BlurEffect` và `DepthOfFieldEffect` trong Lighting |
| **Jerk Off (Give Tool)** | Thêm Tool vui vào backpack với animation lặp |

#### Chat
| Tính năng | Mô tả |
|-----------|-------|
| **Spam Chat** | Tự động gửi tin nhắn theo interval (1 – 30 giây) |
| **Spam Message** | Nội dung tin nhắn |
| **Spam Delay** | Khoảng thời gian giữa các lần gửi |

#### Server
| Tính năng | Mô tả |
|-----------|-------|
| **Server Hop** | Tìm server khác còn chỗ và tự teleport sang |
| **Rejoin Server** | Rejoin chính server hiện tại |
| **Copy Job ID** | Sao chép Job ID vào clipboard |
| **Join Job ID** | Teleport đến server theo Job ID nhập vào |

#### Bang Player
Phát animation lên người chơi khác (client-side), hỗ trợ điều chỉnh tốc độ animation.

---

### Tab: Settings

| Tính năng | Mô tả |
|-----------|-------|
| **Unload Script** | Dọn dẹp và tắt script |
| **Show Keybinds Menu** | Ẩn/hiện bảng keybind góc màn hình |
| **Theme Manager** | Đổi theme giao diện (do LinoriaLib cung cấp) |
| **Config/Save Manager** | Lưu và tải cấu hình. Tự load config `autoload` nếu tồn tại |

**Keybinds có thể chỉnh:**
- Fly (`F`)
- Noclip (`N`)
- Pull Players (`P`)

---

## Kiến trúc & Ghi chú kỹ thuật

### Quản lý state
- Mỗi tính năng có biến boolean riêng (`flyEnabled`, `noclipEnabled`, ...) được cập nhật qua callback `OnChanged` của LinoriaLib.
- Character spawn được bảo vệ bằng `suppressCharacterBugUntil` (1.5–2.5 giây) để tránh conflict khi respawn.

### Tool Patching System
- `patchedToolStates` lưu state riêng cho từng Tool.
- Khi Tool bị xóa (`AncestryChanged`), state tự động được dọn và giá trị gốc được khôi phục.
- Patch áp dụng cho cả `NumberValue/IntValue` trực tiếp lẫn bảng trả về từ `ModuleScript`.

### Smart Prompt Trigger (Auto Pickup)
Thử theo thứ tự ưu tiên:
1. `ProximityPromptService:InputHoldBegin/End` — tự nhiên nhất, ít bị detect
2. Teleport tạm gần prompt rồi về — không dùng exploit function
3. `fireproximityprompt` — fallback cuối cùng

### ESP Engine
- Mỗi người chơi có một `ESP_Cache` entry riêng với Drawing objects.
- Skeleton hỗ trợ cả **R6** và **R15**.
- Team check tự động phát hiện cơ chế team của game (attribute, IntValue, StringValue, TeamColor).

### Fly
Dùng `BodyVelocity` + `BodyGyro` gắn vào `HumanoidRootPart`. Camera direction làm basis vector điều hướng.

---

## Cấu trúc file Config

```
UniversalHub/
└── configs/
    ├── autoload.json   ← tự load khi khởi động nếu tồn tại
    └── [tên config].json
```

---

## Lưu ý

- Script chạy **client-side** hoàn toàn. Các tính năng như Pull, Bang, Aimbot chỉ hiện ở máy của bạn và không ảnh hưởng server (trừ khi game cho phép).
- Weapon patch hoạt động tốt nhất với game dùng `NumberValue`/`IntValue` hoặc `ModuleScript` trả về table — không đảm bảo với mọi game.
- Sử dụng script này trên game người khác có thể vi phạm ToS của Roblox.

# 28th6 Hub

Script Roblox sử dụng **LinoriaLib GUI** với ESP hiện đại, hỗ trợ đa tính năng.

> **Tác giả:** Bien  
> **GUI:** LinoriaLib  
> **Ngôn ngữ:** Lua  

---

## Cài đặt

Dán đoạn sau vào executor và nhấn **Execute (F9)**:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/buivanbien09/roblox-script/refs/heads/main/28th6"))()
```

> Yêu cầu executor hỗ trợ `HttpGet` và `Drawing` API (Synapse X, KRNL, Fluxus...).

---

## Phím tắt

| Phím | Tính năng |
|---|---|
| `F` | Bật / tắt Fly |
| `N` | Bật / tắt Noclip |
| `P` | Bật / tắt Pull Players |
| `RightShift` | Ẩn / hiện menu |
| `T` | Teleport tới chuột *(khi bật Click TP)* |

> Tất cả hotkey đồng bộ màu với toggle trong menu (xanh = đang bật).

---

## Tính năng

### Tab Player

#### Movement
| Tính năng | Mô tả |
|---|---|
| Speed Boost | Tăng tốc độ di chuyển (16–500) |
| Infinite Jump | Nhảy không giới hạn |
| Noclip | Xuyên tường, không va chạm |
| Teleport To Mouse | Nhấn `T` để teleport tới vị trí chuột |
| Freeze Position | Khóa vị trí nhân vật |
| Instant Interaction | ProximityPrompt tức thì (HoldDuration = 0) |
| Auto Pick Up Items | Tự nhặt item trong bán kính (5–50 studs) |

#### Fly
| Tính năng | Mô tả |
|---|---|
| Fly | Bay tự do, điều khiển bằng WASD + Space/Shift |
| Fly Speed | Tốc độ bay (10–200) |
| Auto Climb | Tự leo tường |
| Anti-Wind | Chống bị đẩy bởi gió |
| Float | Lơ lửng tại chỗ |
| Spin Player | Xoay nhân vật |

#### Teleport
- Teleport tới player bất kỳ
- Lưu & load điểm teleport thủ công

---

### Tab Visual

#### Modern ESP
| Tính năng | Mô tả |
|---|---|
| Enable ESP | Bật/tắt toàn bộ ESP |
| Boxes | Khung bao quanh nhân vật |
| Names | Hiển thị tên người chơi |
| Distance | Hiển thị khoảng cách |
| Health Bars | Thanh máu |
| Tracers | Đường kẻ từ màn hình tới nhân vật |
| Chams | Highlight nhân vật qua tường |
| Skeleton | Khung xương |
| Weapon | Tên vũ khí đang cầm |
| Team Check | Bỏ qua đồng đội |

#### Lighting
| Tính năng | Mô tả |
|---|---|
| Fullbright | Sáng tối đa, không bóng tối |
| No Fog | Xóa sương mù |
| Force Time | Khóa thời gian trong ngày (0–24) |
| FOV | Điều chỉnh góc nhìn camera (30–120) |

---

### Tab Combat

#### Client Pull
| Tính năng | Mô tả |
|---|---|
| Pull Players/Bots | Kéo nhân vật về phía mình (client-side) |
| Pull Radius | Bán kính tìm mục tiêu (10–1000) |
| Pull Distance | Khoảng cách giữ mục tiêu (2–15) |
| Pull X/Y Offset | Điều chỉnh vị trí mục tiêu |
| Max Pull Targets | Số mục tiêu tối đa (1–5) |

#### Aimbot
| Tính năng | Mô tả |
|---|---|
| Enable Aimbot | Bật aimbot |
| Require Right Mouse Hold | Chỉ aim khi giữ chuột phải |
| Aim FOV | Bán kính FOV aim (25–600) |
| Smoothness | Độ mượt khi aim (1–100) |
| Visible Only | Chỉ aim mục tiêu nhìn thấy được |
| Lock Target | Giữ nguyên mục tiêu cho đến khi invalid |
| Show FOV Circle | Hiển thị vòng tròn FOV |

#### Weapon
| Tính năng | Mô tả |
|---|---|
| No Spread | Không tản đạn |
| No Recoil | Không giật súng |
| Instant Reload | Reload tức thì |
| Rapid Fire | Bắn liên tục không delay |

---

### Tab Misc

| Tính năng | Mô tả |
|---|---|
| Anti-AFK | Chống bị kick do AFK |
| Spam Chat | Gửi tin nhắn tự động theo chu kỳ |
| Bang Player | Chạy animation đặc biệt lên player được chọn |
| Server Hop | Nhảy server |

---

### Tab Settings

| Tính năng | Mô tả |
|---|---|
| Show Keybinds Menu | Ẩn/hiện danh sách phím tắt trên màn hình |
| Theme | Tùy chỉnh giao diện màu sắc |
| Config | Lưu, load, xóa config |
| Autoload | Đặt config tự động load mỗi lần chạy script |

---

## Config & Autoload

Script hỗ trợ lưu trạng thái tất cả toggle/slider để tự động khôi phục lần sau:

1. Bật các tính năng muốn giữ
2. Vào tab **Settings → Config**
3. Đặt tên → nhấn **Save**
4. Nhấn **Set as Autoload**

Từ lần sau, script tự load lại toàn bộ cài đặt khi khởi động.

> Config được lưu tại: `28th6Hub/configs/` trên máy tính.

---

## Cấu trúc kỹ thuật

```
Script
├── safeLoad()           — Load LinoriaLib an toàn với pcall + kiểm tra HTML lỗi
├── State {}             — Bảng chứa toàn bộ biến trạng thái (tránh vượt giới hạn 200 local)
├── CombatState {}       — Biến trạng thái riêng cho combat/aimbot
├── ESP_Cache {}         — Cache Drawing objects theo character
├── Connections {}       — Track RunService connections để cleanup
└── fullCleanup()        — Dọn toàn bộ Drawing + connections khi unload
```

**Giới hạn local variables:** Lua giới hạn 200 locals/chunk. Script dùng `State` và `CombatState` table để gộp biến, hiện đang ở **140/200**.

---

## Lưu ý

- Script chạy **hoàn toàn client-side** — không ảnh hưởng server
- Pull Players là client-side pull, chỉ người dùng thấy hiệu ứng
- Weapon patches (No Spread, Rapid Fire...) chỉ hoạt động với tool có `NumberValue`/`ModuleScript` chứa các giá trị tương ứng
- Một số game có anti-cheat có thể phát hiện một số tính năng

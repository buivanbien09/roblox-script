# 28th6 Hub

Script Roblox universal dùng LinoriaLib GUI, hỗ trợ ESP hiện đại, movement hacks, combat tools và nhiều tiện ích khác.

---

## Cách dùng

Paste đoạn sau vào executor của bạn:

```lua
--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
loadstring(game:HttpGet("https://raw.githubusercontent.com/buivanbien09/roblox-script/refs/heads/main/28th6"))()
```

---

## Tính năng

### Player

| Tính năng | Mô tả |
|---|---|
| Speed Boost | Tăng tốc độ di chuyển, hỗ trợ 3 method: WalkSpeed / CFrame / Velocity |
| Infinite Jump | Nhảy vô hạn |
| Noclip | Xuyên tường |
| Fly | Bay tự do bằng WASD + Space/Shift, phím tắt `F` |
| Freeze Position | Đóng băng nhân vật tại chỗ |
| Teleport To Mouse | Nhấn `T` để teleport tới vị trí chuột đang trỏ |
| Click Teleport | Teleport đến player khác |
| Saved Points | Lưu và teleport tới các điểm cố định trong map |
| Auto Climb | Tự leo trèo |
| Anti Wind | Chống bị đẩy bởi gió/lực |
| Auto Pick Up | Tự động nhặt vật phẩm trong bán kính cài đặt |
| Instant Interact | Tương tác ProximityPrompt ngay lập tức, không cần giữ |

### World

| Tính năng | Mô tả |
|---|---|
| Fullbright | Làm sáng toàn bộ map |
| No Fog | Xóa sương mù |
| Force Time | Ép giờ trong game về giá trị tùy chọn |

### Combat

| Tính năng | Mô tả |
|---|---|
| No Spread | Xóa độ tản đạn |
| No Recoil | Xóa giật súng |
| Instant Reload | Reload vũ khí ngay lập tức |
| Rapid Fire | Tốc độ bắn tối đa |

### ESP (Visual)

| Tính năng | Mô tả |
|---|---|
| ESP Boxes | Vẽ hộp quanh người chơi |
| Names | Hiển thị tên |
| Distance | Hiển thị khoảng cách |
| Health | Hiển thị HP |
| Tracers | Vẽ đường thẳng từ màn hình tới người chơi |
| Chams | Highlight nhân vật qua tường |
| Skeleton | Vẽ khung xương |
| Team Check | Chỉ hiển thị ESP cho kẻ địch |
| Enemy Color | Tùy chỉnh màu ESP |
| Team Check Mode | Auto Detect hoặc chọn thủ công (Roblox Teams / FactionType / TeamColor / ...) |

### Misc

| Tính năng | Mô tả |
|---|---|
| Rejoin Server | Vào lại server hiện tại |
| Server Hop | Tìm và nhảy server ngẫu nhiên |
| Join Job ID | Vào server theo Job ID cụ thể |
| Copy Job ID | Sao chép Job ID server hiện tại |
| Spam Chat | Tự động gửi tin nhắn chat theo khoảng thời gian |
| Pull Players | Kéo tất cả người chơi về phía bạn (phím `P`) |
| Spin Player | Xoay nhân vật liên tục |
| Float | Bay lơ lửng tại chỗ |

### Settings

- Unload script
- Hiển thị / ẩn danh sách keybind trên màn hình
- Quản lý config (lưu / nạp / xóa / autoload)
- Theme tùy chỉnh (qua ThemeManager)
- Phím tắt tùy chỉnh cho Fly, Noclip, Pull Players

---

## Phím tắt mặc định

| Phím | Chức năng |
|---|---|
| `Right Shift` | Ẩn / hiện UI |
| `F` | Bật / tắt Fly |
| `N` | Bật / tắt Noclip |
| `T` | Teleport tới vị trí chuột (khi bật Click TP) |
| `P` | Bật / tắt Pull Players |

---

## Config

- Configs được lưu trong thư mục `28th6Hub/configs` trên máy (workspace executor).
- Hỗ trợ **autoload**: đặt tên config là `autoload` để tự động nạp mỗi lần mở script.
- Theme được lưu riêng trong thư mục `28th6Hub`.

---

## Yêu cầu

- Executor hỗ trợ `HttpGet`, `Drawing API`, và `getgenv`.
- Kết nối internet (để tải LinoriaLib từ GitHub).

---

## Thư viện sử dụng

- [LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) — GUI framework
- ThemeManager & SaveManager (addon đi kèm LinoriaLib)

---

## Tác giả

**Bien** — `28th6 Hub`

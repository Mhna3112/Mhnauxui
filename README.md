# ⚡ Mhnaa Hub & Roblox Scripts Collection

Repository chứa trọn bộ các Script tự động (Autofarm, Kill Aura, Dungeon Quest), thư viện giao diện **MhnaaUI** và Script chính **nhamnhi Hub [PRO-MULTI]** cho **[Bleach!] Legacy Piece** trên Roblox.

---

## 🚀 Quick Loadstrings (Chạy ngay trong Roblox Executor)

### 1. nhamnhi Hub - Legacy Piece (v1.0.3 Bypassed)
Tự động farm quái, farm boss & tự động triệu hồi boss qua cổng Portal chống rubberband, nhiệm vụ Fire Force, tự nhặt đồ & rương, Infinite Tower, combo kỹ năng qua Remote trực tiếp:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/Main_Project_UI.luau"))()
```

*(Hoặc link alias rút gọn)*:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/LegacyPiece.luau"))()
```

---

### 2. MhnaaUI (Thư viện UX/UI mã nguồn mở)
Thư viện UI hiện đại, mượt mà, hỗ trợ đa dạng component (Tab, Section, Toggle, Slider, Dropdown, Keybind, ColorPicker, Button):

```lua
local MhnaaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/MhnaaUI.luau"))()
```

---

### 3. Dungeon Quest AutoFarm
Hỗ trợ tự động chạy Dungeon, thu thập kinh nghiệm và phần thưởng:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/DungeonQuest_AutoFarm.luau"))()
```

---

### 4. Untitled Upgrade Tree AutoFarm (Mhnaa [PRO])
Tự động mua nâng cấp theo logic giá InfMaths, Turbo Auto Clicker, Auto Battle Stage, Auto Roll dừng theo tỷ lệ hiếm, tự động mở khóa điều kiện và Loop / Supernova / Bigbang:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/UntitledUpgradeTree.luau"))()
```

---

### 5. Kill Aura (Universal & Teleport)
Tự động tấn công kẻ địch xung quanh hoặc dịch chuyển liên tục:

```lua
-- Kill Aura thường
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/killaura.luau"))()

-- Kill Aura kèm Teleport
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mhna3112/Mhnauxui/main/killaura_tp.luau"))()
```

---

## 📂 Danh Sách Tệp Dự Án (Project Structure)

| Tên Tệp | Mô Tả |
|---|---|
| `UntitledUpgradeTree.luau` | Script tự động cày cuốc Untitled Upgrade Tree tích hợp MhnaaUI [PRO] |
| `UntitledUpgradeTree/` | Thư mục chứa mã nguồn riêng cho Untitled Upgrade Tree |
| `Main_Project_UI.luau` | Script chính Legacy Piece theo chuẩn nhamnhi Hub v1.0.3 (Obsidian UI) |
| `LegacyPiece.luau` | Bản alias của `Main_Project_UI.luau` |
| `MhnaaUI.luau` | Thư viện giao diện người dùng Mhnaa UI |
| `DungeonQuest_AutoFarm.luau` | Script tự động cày cuốc phó bản Dungeon Quest |
| `DungeonQuest_Mhnaa.luau` | Script Dungeon Quest tích hợp giao diện MhnaaUI |
| `DungeonQuest_raw.lua` | Mã nguồn gốc Dungeon Quest |
| `killaura.luau` | Script Kill Aura đa năng |
| `killaura_tp.luau` | Script Kill Aura kết hợp dịch chuyển tức thời |
| `autofarm.lua` | Script autofarm cơ bản |
| `autofarm_instantclick.luau` | Script autofarm chế độ nhấp tức thời |
| `autofarm_steal_egg.luau` | Script tự động trộm trứng (Steal Egg) |
| `autofarm_steal_egg_obf.luau`| Bản mã hóa của Steal Egg |
| `nhamnhi_legacy_piece_decompiled.luau` | Bản dịch ngược tái cấu trúc từ nhamnhi Hub v1.0.3 |
| `junkie_sdk.luau` | Module mô phỏng bypass Key System Junkie SDK |
| `Example_Template.luau` | Mẫu script khởi tạo giao diện |

---

## ✨ Tính Năng Nổi Bật

- ⚡ **Combat Network Trực Tiếp**: M1 và combo chiêu thức Z, X, C, V, E gửi thẳng qua Remote Server của game, không delay chuột.
- 🎯 **InstaKill Multi-Burst**: Xả $3\times$ đến $6\times$ chùm đòn đánh qua remote dứt điểm mục tiêu cực nhanh.
- 🗺️ **Cổng Teleport An Toàn**: Dịch chuyển giữa 14 hòn đảo bằng cổng chính thức, triệt tiêu 100% tình trạng giật lùi (rubberband).
- 🐉 **Auto Summon Boss**: Tự động bay đến NPC Whisperer / Sacrifice Table triệu hồi Boss và farm liên tục.
- 🚒 **Fire Force Quest**: Tự động tìm mèo, cứu con tin, hạ gục Infernal Ambusher.
- 📦 **Tự Nhặt Vật Phẩm & Rương**: Quét và nhặt tức thì mọi item / rương trên bản đồ.

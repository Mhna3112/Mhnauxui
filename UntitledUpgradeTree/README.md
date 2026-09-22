# Untitled Upgrade Tree - Mhnaa [PRO] AutoFarm

## Giới thiệu
Script tự động hóa toàn diện cho game **Untitled Upgrade Tree** trên Roblox, tích hợp giao diện hiện đại **Mhnaa [PRO] UI**.

## Cấu trúc thư mục
```
robloxscript/
├── UntitledUpgradeTree.luau   # Script chính Untitled Upgrade Tree (Root alias)
├── UntitledUpgradeTree/
│   ├── UntitledUpgradeTree.luau # Script chính chạy Mhnaa UI AutoFarm
│   ├── autofarm.luau          # Alias tương thích ngược
│   └── README.md              # Tài liệu hướng dẫn
├── DungeonQuest/
│   └── autofarm.luau      # Script Mhnaa UI cho Dungeon Quest
├── LegacyPiece/
│   └── autofarm.luau      # Script cho Legacy Piece
└── MhnaaUI.luau           # Thư viện giao diện Mhnaa UI chuẩn
```

## Các tính năng chính
- **Mhnaa UI [PRO] Hub**:
  - Giao diện Dark theme cao cấp, bo góc mượt mà, drag di chuyển và resize handle.
  - Phím tắt ẩn/hiện menu: `RightControl`.
  - Hỗ trợ thanh tìm kiếm tính năng thông minh (`Ctrl + K`).
- **Tab 1: Auto Farm**:
  - *Auto Clicker*: Tự động spam click chuột và click Space khi ở Space world.
  - *Smart Auto Upgrades*: Tự động tính toán giá tiền (`InfMaths`), kiểm tra điều kiện mở khóa và mua tất cả các nâng cấp hợp lệ theo thời gian thực.
  - *Auto Prestige & Resets*: Tùy chọn tự động Prestige, Evil, Dark Prestige, Supernova.
- **Tab 2: Combat & Drops**:
  - *Auto Battle Attack*: Tự động đánh boss qua các màn Battle Stage.
  - *Auto Collect*: Tự động nhặt Blocks và Rocks rơi ra trong map.
  - *Auto Roll & Claims*: Tự động Roll minigame, nhận Stars và Daily Reward.
- **Tab 3: Worlds & Teleport**:
  - Dịch chuyển tức thời giữa các thế giới (Spawn, Space, Void, Genesis, Tower, Bigbang, Supernova, Hell,...).
  - Kích hoạt các tiến trình Ascend, Cycle, Loop.
- **Tab 4: Player & Misc**:
  - Tùy chỉnh WalkSpeed, JumpPower, Infinite Jump, Noclip.
  - Anti-AFK chống văng game sau 20 phút không hoạt động.

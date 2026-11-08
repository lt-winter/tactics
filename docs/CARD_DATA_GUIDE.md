# Hướng dẫn dữ liệu lá bài

## Nguồn chính thức

Runtime và danh mục UI nạp **`res://data/cards_manifest.json`** qua một `CardDatabase` thống nhất. File `data/cards.json` cũ đã được thay thế; không có fallback hoặc bản sao legacy trong runtime.

```gdscript
var database: CardDatabase = CardDatabase.new()
if not database.load_from_file(CardDatabase.DEFAULT_MANIFEST_PATH):
	for message: String in database.get_errors():
		push_error(message)
```

Manifest có dạng:

```json
{
	"files": [
		"res://data/cards/basic.json",
		"res://data/cards/tools.json",
		"res://data/cards/equipment.json"
	]
}
```

Manifest hiện có 3 nhóm: cơ bản, công cụ và trang bị. AOE/hỗ trợ nằm trong `tools.json`; vũ khí/giáp/phụ kiện nằm trong `equipment.json`. Slot và effect vẫn phân biệt từng loại trang bị. Thứ tự file và thứ tự định nghĩa trong file quyết định thứ tự registry/danh mục, không quyết định thứ tự lượt hoặc giải quyết hiệu ứng. Lần gộp trang bị giữ nguyên thứ tự định nghĩa hiện tại. Mỗi file chỉ chứa root object `{"cards": [...]}`; không lồng manifest trong file nhóm.

## Chọn nhóm theo chức năng

| File | Chức năng hiện tại | ID hiện có | Số định nghĩa |
|---|---|---|---:|
| `basic.json` | Tấn công, phản ứng Né và hồi máu | `attack`, `dodge`, `heal` | 3 |
| `tools.json` | Hủy/Cướp bài, AOE và công cụ hỗ trợ | `discard`, `steal`, `gatling`, `indian`, `draw_2`, `exchange`, `saloon` | 7 |
| `equipment.json` | Vũ khí, giáp và phụ kiện Công/Thủ | `crossbow`, `butchers_knife`, `slingshot`, `pistol`, `rifle`, `black_shield`, `barrel`, `helmet`, `chainmail`, `scope`, `mustang` | 11 |

Tổng: **21**. Cả 7 lá công cụ giữ `category="tool"`; AOE và hỗ trợ vẫn được phân biệt bằng `effects`/`subcategory` hiện có. Gộp file không thay đổi hiệu ứng hoặc cách thực thi.

## Thêm hoặc sửa bài

1. Chọn đúng file theo chức năng và thêm một object vào mảng `cards`. Giữ schema hiện có: `id`, `name`, `category`, `subcategory`, `description`, `effects`; bổ sung metadata slot/range nếu thuộc trang bị.
2. Đặt ID duy nhất trên **toàn bộ các file**. Không khai báo lại cùng ID trong nhóm khác để ghi đè; loader sẽ từ chối cả lần nạp và chỉ rõ hai file/vị trí bị trùng.
3. Chỉ dùng effect/parameters mà engine đã hỗ trợ. Việc thêm JSON không tự tạo handler hay luật gameplay mới. Bài mới có cơ chế mới cần triển khai và kiểm thử riêng.
4. Khi chỉ thêm bài vào nhóm đang có, không cần sửa manifest. Nếu thêm nhóm mới đã được duyệt, thêm một đường dẫn `res://...json` vào `files`, tránh lặp đường dẫn. Manifest không được rỗng và không chứa đồng thời `files` với `cards`.
5. Chạy regression và UI smoke tests. Kiểm tra cả thông báo hoàn tất của từng suite và lỗi script; exit code 0 không đủ chứng minh PASS.
6. Định nghĩa không quyết định số bản sao trong deck. Chỉ chỉnh `data/decks/standard.json` khi được duyệt riêng; mỗi `copies` entry là một lá vật lý với suit/rank. Mã suit hiện tại: **Cơ 0, Rô 1, Chuồn 2, Bích 3**.

## Hành vi nạp và lỗi

- API `load_from_file(path) -> bool`, `get_definition`, `get_card`, `has_card`, `get_all_cards`, `get_card_count`, `get_errors` giữ nguyên. `DEFAULT_MANIFEST_PATH` tập trung đường dẫn chính thức.
- Các nhóm được validate rồi merge vào registry tạm; chỉ publish khi toàn bộ manifest và mọi nhóm hợp lệ. File thiếu, JSON sai, root/schema sai, file bị lặp hay ID trùng đều làm cả lần nạp thất bại.
- Theo hợp đồng cũ, bắt đầu nạp sẽ xoá registry/lỗi cũ. Sau thất bại, registry **rỗng**, không giữ dữ liệu cũ hoặc dữ liệu nạp dở. Lỗi có nguồn file; lỗi định nghĩa có thêm `cards[index]`, lỗi ID trùng chỉ rõ cả hai nguồn. Sửa file rồi nạp lại cùng object sẽ xoá lỗi cũ và tạo registry hoàn chỉnh.
- Các bản sao `CardDefinition` và `CardInstance` đã được tạo không bị loader sửa hoặc tái tạo. `get_card`/`get_all_cards`/`get_errors` vẫn trả bản sao như trước.
- Nạp trực tiếp một file `{"cards": [...]}` vẫn được hỗ trợ cho fixture/schema tooling và tương thích API. Runtime chỉ truyền manifest chính thức; không quét thư mục tự động hoặc âm thầm bỏ qua nhóm lỗi.

## Kiểm thử

Trong bản sao dự án riêng, bật `debug/gdscript/warnings/treat_warnings_as_errors=true`, sau đó dùng Godot CLI:

```text
godot --headless --path <project-copy> --editor --import --quit
godot --headless --path <project-copy> --script res://scripts/test/regression_runner.gd
godot --headless --path <project-copy> --script res://scripts/test/main_menu_smoke.gd
godot --headless --path <project-copy> --script res://scripts/test/playable_prototype_smoke.gd
```

Chạy thêm mọi script `*smoke.gd` trong `scripts/test/` để bao phủ các cửa sổ phản ứng và hiệu ứng. `CardManifestTest` kiểm tra merge/thứ tự, lỗi manifest/nhóm/schema, nguồn ID trùng, tính nguyên tử, sửa rồi nạp lại, tương thích file nhóm và việc giữ nguyên CardInstance có sẵn. Fixture được dọn sau khi kiểm thử thành công. Bằng chứng chạy thực tế được ghi trong `DEVELOPMENT_STATUS.md`.

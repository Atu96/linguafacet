# Prompt audit — 1.9.4

Date: 2026-08-24, Asia/Ho_Chi_Minh

## Cách chấm

Mỗi ca tối đa 10 điểm:

- Bảo toàn nghĩa và hàm ý thực dụng: 4 điểm.
- Đúng văn phong được chọn: 3 điểm.
- Tự nhiên trong ngôn ngữ đích: 2 điểm.
- Chỉ trả kết quả, không thêm nội dung/giải thích: 1 điểm.

Các lượt Groq được gửi qua chính app đã cài. App tự đọc key khi bắt đầu request; QA không đọc, xuất hoặc ghi key vào terminal/log.

## Kết quả live

| Preset / ca | Kết quả tiêu biểu | Điểm | Nhận xét |
| --- | --- | ---: | --- |
| Giao tiếp tự nhiên | `Are you free tonight? I want to tell you something, but it's not urgent.` | 9.5 | Tự nhiên, đúng quan hệ và độ khẩn; không tô thêm cảm xúc. |
| Học thuật — nghiên cứu quan sát | `This observational study identified a correlation… insufficient to infer…` | 9.8 | Giữ đúng tương quan, giới hạn dữ liệu và không nâng thành nhân quả. |
| Học thuật — pháp lý | `This clause may be applied… but does not automatically terminate the contract.` | 9.7 | Giữ chính xác `may` và `does not automatically`; đúng sắc thái pháp lý. |
| Công việc | `Please review the report by 4 p.m.; if that isn’t possible today, inform me by 3 p.m. so I can adjust.` | 9.7 | Lịch sự, rõ việc và deadline; không thêm chào hỏi, xin lỗi hay cam kết. |
| Bạn bè — không có lời chào, trước sửa | `Hey, are you free this afternoon? …` | 7.5 | Nghĩa chính đúng nhưng tự tạo một hành động xã hội mới ở đầu câu. Không đạt. |
| Bạn bè — không có lời chào, sau sửa | `You free this afternoon? Could you check this out for me? If you're busy, tomorrow works too.` | 9.8 | Không còn opener tự tạo; casualness thể hiện bên trong câu. |
| Bạn bè — nguồn có lời chào thật | `Hey, you free this afternoon? Can you check this out for me?` | 9.8 | Giữ đúng chức năng của `Chào cậu`; guard không lọc quá tay. |
| Bạn bè — hư từ/hành động chung, bản 1.9.4 | `Don't worry too much—there's still a way to sort it out. Let's go over each part together.` | 10.0 | Không thêm opener; giữ đúng lời trấn an và lời rủ cùng xem lại. |

Điểm trung bình của các ca đạt cuối cùng: **9.75/10**.

## Lỗi tìm thấy và cách sửa

Chỉ thêm câu cấm trong prompt chưa đủ ổn định: GPT-OSS đôi khi coi một opener rập khuôn là dấu hiệu bề mặt của giọng bạn bè, không phải nội dung mới.

1. Hợp đồng chung nay buộc mọi câu, mệnh đề, interjection, vocative và discourse marker phải có source span; đơn vị đầu ra đầu tiên phải tương ứng đơn vị nghĩa đầu tiên của nguồn.
2. Preset Bạn bè chỉ được tạo casualness bên trong đơn vị đã có. Nó giữ vị trí speech act đầu tiên, đại từ, chủ ngữ lược bỏ và interactional particle theo chức năng thực dụng.
3. `StyledTranslationOutputGuard` so nguồn, bản dịch nền và bản văn phong. Nó chỉ bỏ một opener mục tiêu đã nhận diện khi cả nguồn lẫn bản nền đều không có opener; phần còn lại của câu giữ nguyên.
4. Nếu nguồn có lời chào thật, candidate được giữ nguyên. Guard không quyết định phong cách và không viết lại bản dịch nói chung.

## Regression bắt buộc

- Prompt chung chứa discourse-unit alignment và opening-unit constraint.
- Prompt Bạn bè chứa quy tắc source-anchored casualness, shared suggestion và interactional particle.
- Không đưa các token lời chào tiếng Anh gây priming vào prompt Bạn bè đang hoạt động.
- Guard có ca English/Chinese, ca opener dài, ca nguồn có greeting thật và ca không có vi phạm.
- Default cũ được migrate bằng exact match; preset người dùng đã chỉnh không bị ghi đè.


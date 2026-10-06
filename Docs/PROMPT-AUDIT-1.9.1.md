# Prompt audit — 1.9.1

Date: 2026-08-24, Asia/Ho_Chi_Minh

## Kết luận trước khi sửa

Các prompt 1.9.0 đã có nhiều ràng buộc bảo toàn ý nghĩa, nhưng hiệu lực văn phong bị giảm bởi ba điểm:

1. Prompt hệ thống yêu cầu khôi phục cả “politeness” về bản dịch nền. Điều này xung đột trực tiếp với preset Công việc, vốn cần được phép thay **cách biểu đạt lịch sự** mà vẫn giữ nguyên lực của yêu cầu.
2. Preset Bạn bè liệt kê trực tiếp nhiều lời chào tiếng Anh trong quy tắc cấm. Việc lặp token có thể làm model ưu tiên chính các từ đó dù mục đích là ngăn chúng.
3. Một số preset mô tả tính từ phong cách nhưng chưa phân biệt rõ phần AI được phép suy luận, dấu hiệu ngôn ngữ phải thể hiện và ý nghĩa thực dụng không được đổi.

## Hợp đồng sau audit

Prompt hệ thống tách hai miền rõ ràng:

- **Bất biến:** dữ kiện, tham chiếu, số, ngày, phủ định, điều kiện, phạm vi logic, mức chắc chắn, lực lời nói, cấp bậc, trách nhiệm, cam kết, độ khẩn, khoảng cách xã hội và cảm xúc.
- **Được phép đổi:** register, diction, collocation, cú pháp, nhịp câu, discourse marker và phép lịch sự bề mặt theo quy ước ngôn ngữ đích.

Model phải tạo bản dịch nền, áp dụng style profile, rồi tự đối chiếu với cả nguồn và bản nền trong cùng một request JSON. Style profile có mức ưu tiên thấp hơn quy tắc bảo toàn; prompt tùy chỉnh không được đổi ngôn ngữ, format hoặc ý nghĩa.

## Độ phân biệt của preset mặc định

| Preset | Suy luận có điều kiện | Dấu hiệu đầu ra | Không được tự tạo |
| --- | --- | --- | --- |
| Giao tiếp tự nhiên | Hội thoại/chat/lời nhắn/văn xuôi | collocation, trật tự thông tin và nhịp bản ngữ | quan hệ, lời chào, slang, cảm xúc |
| Học thuật | ngành + thể loại tài liệu | thuật ngữ chuẩn, cú pháp kỷ luật, logic và hedging | chuyên ngành, dẫn chứng, giải thích, kết luận |
| Công việc | kênh + quan hệ người nhận | câu rõ việc, business collocation, lịch sự bề mặt | tiêu đề, xin lỗi, cảm ơn, hứa hẹn, nghĩa vụ |
| Bạn bè cùng lứa | quan hệ ngang hàng | khẩu ngữ nhẹ, đại từ/hư từ và nhịp ngắn phù hợp | opener rập khuôn, slang, meme, thân mật, phấn khích |

## Regression guards

`Tests/TranslationCoreSmoke.swift` kiểm tra:

- bốn prompt mặc định là bốn hợp đồng khác nhau và đủ chi tiết;
- prompt hệ thống cho phép đổi phép lịch sự bề mặt nhưng giữ speech-act force;
- preset Bạn bè không chứa các lời chào tiếng Anh từng gây lexical priming;
- prompt cũ mặc định được migrate, prompt cá nhân không bị ghi đè;
- ngữ cảnh/thuật ngữ chỉ đi vào request Văn phong, không đi vào Dịch nhanh;
- không có network call hoặc API-key read trong test.

## Giới hạn đánh giá

Prompt contract và migration được kiểm thử tự động. Chất lượng câu thực tế cần người dùng thử với Groq vì automated QA không đọc key thật hoặc tiêu quota. Hai preset cho cùng kết quả không tự động là lỗi: với câu rất ngắn hoặc đã đúng register, việc giữ nguyên có thể là lựa chọn an toàn nhất.

# Hướng dẫn tạo preset văn phong

Preset chỉ điều khiển **cách diễn đạt trong ngôn ngữ đích**. Quy tắc hệ thống của Translate Quick luôn giữ quyền ưu tiên cao hơn: không thêm/bớt dữ kiện, không đổi ngôn ngữ, không thay mức chắc chắn, quan hệ, trách nhiệm, thời hạn hoặc ý định giao tiếp.

## Một prompt có tác dụng rõ cần gì?

Tránh các câu quá chung như “dịch tự nhiên”, “dịch lịch sự” hoặc “dịch hay hơn”. Một prompt tốt nên mô tả bốn lớp:

1. **Tình huống được phép suy luận:** hội thoại, chat nội bộ, email đối tác, bài nghiên cứu, tài liệu kỹ thuật… Chỉ suy luận khi văn bản nguồn có dấu hiệu; nếu không rõ phải dùng lựa chọn trung tính.
2. **Dấu hiệu bề mặt cần thay đổi:** cách chọn từ, collocation, trật tự thông tin, nhịp câu, đại từ, contractions/hư từ, cú pháp hoặc quy ước lịch sự của ngôn ngữ đích.
3. **Ý nghĩa thực dụng phải giữ:** đề nghị hay mệnh lệnh, được phép hay bắt buộc, chắc chắn hay phỏng đoán, quan hệ ngang hàng hay cấp bậc, độ khẩn và cảm xúc.
4. **Điều tuyệt đối không tự tạo:** lời chào, xin lỗi, cảm ơn, cam kết, tiếng lóng, thân mật, dữ kiện, ví dụ hoặc giải thích mới.

## Bốn preset mặc định

### Giao tiếp tự nhiên

- Tự nhận diện hội thoại, chat, lời nhắn hoặc văn xuôi trung tính từ chính nguồn.
- Loại bỏ lối dịch bám cú pháp; ưu tiên collocation, trật tự từ và nhịp câu bản ngữ.
- Không mặc định biến mọi nội dung thành giọng bạn bè và không tự tạo lời mở đầu.

### Học thuật

- Tự nhận diện cả **ngành** và **thể loại tài liệu** từ thuật ngữ, ký hiệu, cấu trúc và kiểu lập luận.
- Hỗ trợ STEM, máy tính, kỹ thuật, y sinh, luật, kinh tế, giáo dục, khoa học xã hội, nhân văn và nội dung liên ngành.
- Giữ chặt mức độ bằng chứng: khả năng không thành kết luận; tương quan không thành nhân quả; quan sát không thành chứng minh.
- Giữ định nghĩa, phạm vi lượng từ, công thức, biến, đơn vị, trích dẫn, phương pháp và giới hạn.

### Công việc

- Tự nhận diện chat nội bộ, email, ghi chú họp và quan hệ đồng nghiệp/quản lý/khách hàng/đối tác khi nguồn có đủ dấu hiệu.
- Cho phép cách diễn đạt lịch sự theo quy ước ngôn ngữ đích, nhưng không đổi đề nghị thành mệnh lệnh hoặc tạo thêm nghĩa vụ.
- Không tự thêm tiêu đề, lời chào, xin lỗi, cảm ơn, hứa hẹn, phê duyệt, leo thang hay độ khẩn.

### Bạn bè cùng lứa

- Dùng khẩu ngữ nhẹ, đại từ/hư từ và nhịp câu phù hợp người ngang hàng khi quan hệ trong nguồn cho phép.
- Hiểu đại từ, chủ ngữ lược bỏ và hư từ tương tác theo chức năng: làm mềm, rủ cùng làm, xin đồng thuận hoặc giữ khoảng cách. Không biến lời rủ chung thành lời hứa đơn phương hay ngược lại.
- Nếu nguồn có lời chào thì dịch đúng chức năng xã hội; nếu không có thì đi thẳng vào nội dung.
- Không dùng một lời mở đầu rập khuôn để “chứng minh” giọng thân mật; không tự thêm tiếng lóng, meme, đùa cợt, emoji hoặc mức thân mật.

## Công thức cho preset cá nhân

```text
Infer [medium/audience/domain] only from evidence in the source; otherwise use [safe neutral fallback].
Use [specific target-language diction, syntax, rhythm, terminology, or discourse conventions].
Preserve [speech-act force, relationship, certainty, urgency, commitments, technical details].
Do not invent [greetings, apologies, promises, facts, emotion, slang, explanations].
```

Ví dụ cho “Tài liệu hướng dẫn phần mềm”:

```text
Infer whether the source is a procedure, reference, warning, or explanation, and preserve that document type. Use concise target-language technical-documentation conventions and one established equivalent per concept. Preserve code, identifiers, commands, paths, placeholders, prerequisites, warnings, ordered steps, and cross-references. Never add a step, fix, cause, recommendation, or explanation absent from the source.
```

## Cách kiểm tra preset

- Thử một câu trung tính có nhiều cách diễn đạt để kiểm tra preset có tạo dấu hiệu bề mặt riêng hay không.
- Thử câu có phủ định, điều kiện, số, thời hạn, yêu cầu và mức độ chắc chắn để kiểm tra bảo toàn ý nghĩa.
- So sánh với “Bản dịch nền” trong tab Văn phong AI.
- Hai preset **có thể cho cùng kết quả** khi câu quá ngắn, đã đúng văn phong hoặc không có cách đổi an toàn. Không ép khác biệt chỉ để nhìn thấy thay đổi.
- Nếu preset thường xuyên giống preset khác trên đoạn đủ dài, bổ sung dấu hiệu ngôn ngữ cụ thể thay vì chỉ tăng các tính từ như “hay”, “tự nhiên”, “lịch sự”.

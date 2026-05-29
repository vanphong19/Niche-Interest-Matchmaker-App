# Prompt: Code chức năng Hệ thống Uy tín - Reputation Score & Xử phạt "leo cây"

Tôi đang làm một đồ án web/app về tạo sự kiện đi chơi và kết nối mọi người.  
Hãy giúp tôi code chức năng **"Hệ thống Uy tín - Reputation Score & Xử phạt leo cây"**.

---

## 1. Mục tiêu

Xây dựng một hệ thống đánh giá độ uy tín của người dùng dựa trên:

- Lịch sử tham gia sự kiện.
- Check-in đúng giờ.
- Số lần hủy sát giờ.
- Số lần không tham gia nhưng không báo trước.
- Đánh giá từ host.

Hệ thống này giúp hạn chế tình trạng người dùng đăng ký tham gia sự kiện nhưng không đến, đồng thời giúp host đánh giá mức độ đáng tin cậy của người tham gia.

---

## 2. Yêu cầu chức năng

### 2.1. Reputation Score

Mỗi user có một **Reputation Score** từ `0` đến `100`.

Yêu cầu:

- User mới mặc định có `70` điểm.
- Điểm không được nhỏ hơn `0`.
- Điểm không được lớn hơn `100`.

---

### 2.2. Các yếu tố ảnh hưởng đến điểm uy tín

| Hành động | Điểm thay đổi |
|---|---:|
| Tham gia sự kiện và check-in đúng giờ | `+5` |
| Check-in trễ dưới 15 phút | `+2` |
| Check-in trễ trên 30 phút | `0` |
| Hủy tham gia trước 12 tiếng | `0` |
| Hủy sát giờ, dưới 12 tiếng trước khi sự kiện bắt đầu | `-5` |
| Không tham gia và không báo trước | `-15` |
| Được host đánh giá 5 sao | `+5` |
| Được host đánh giá từ 3 đến 4 sao | `+2` |
| Được host đánh giá dưới 3 sao | `-3` |

---

### 2.3. Phân loại cấp độ uy tín

| Điểm | Cấp độ uy tín |
|---|---|
| `90 - 100` | Người giữ lời vàng |
| `75 - 89` | Đồng đội đáng tin |
| `60 - 74` | Cần cố gắng thêm |
| `40 - 59` | Hay bốc hơi |
| Dưới `40` | Báo động leo cây |

---

## 3. Trust Dashboard

Tạo màn hình **"Trust Dashboard"** cho người dùng.

Giao diện cần:

- Màu sắc, kiểu chữ, phông chữ,... giống với các chức năng hiện tại.
- Hiện đại.
- Responsive.
- Có cảm giác game hóa.

### Thông tin cần hiển thị

- Avatar và tên người dùng.
- Reputation Score dạng vòng tròn progress.
- Cấp độ uy tín.
- Số sự kiện đã tham gia.
- Số lần check-in đúng giờ.
- Số lần hủy sát giờ.
- Số lần leo cây.
- Đánh giá trung bình từ host.
- Danh sách huy hiệu đã đạt.
- Nhiệm vụ phục hồi uy tín nếu điểm thấp.

---

## 4. Hệ thống Badge

Tạo hệ thống huy hiệu uy tín cho người dùng.

### Danh sách badge

| Badge | Điều kiện đạt được |
|---|---|
| Người đúng hẹn | Check-in đúng giờ ít nhất 5 lần |
| Chủ kèo năng nổ | Tạo ít nhất 3 sự kiện thành công |
| Không leo cây | 30 ngày gần nhất không có lần no-show nào |
| Bạn đồng hành vàng | Rating trung bình từ host >= 4.8 |
| Người giữ kèo | Tham gia ít nhất 10 sự kiện |

---

## 5. Modal Cam kết tham gia

Tạo modal **"Cam kết tham gia"** trước khi user đăng ký sự kiện.

### Modal cần hiển thị

- Tên sự kiện.
- Thời gian.
- Địa điểm.
- Quy định check-in.
- Cảnh báo nếu không tham gia và không báo trước sẽ bị trừ `15` điểm uy tín.
- Nút **"Đồng ý tham gia"**.
- Nút **"Hủy"**.

---

## 6. Chức năng Check-in

Tạo chức năng check-in cho sự kiện.

### Yêu cầu

- User có thể check-in sự kiện.
- Nếu check-in trong khoảng thời gian cho phép thì cập nhật trạng thái tham gia.
- Nếu check-in đúng giờ thì cộng điểm.
- Nếu check-in trễ thì xử lý theo logic điểm ở phần Reputation Score.

---

## 7. Chức năng Host Review

Tạo chức năng để host đánh giá người tham gia sau sự kiện.

### Yêu cầu

- Host có thể đánh giá từng người tham gia từ `1` đến `5` sao.
- Host có thể ghi nhận user có tham gia thật hay không.
- Sau khi host submit review, hệ thống cập nhật Reputation Score.

---

## 8. Logic xử phạt người hay leo cây

Tạo logic xử phạt người dùng thường xuyên no-show.

### Quy tắc xử phạt

- Nếu user no-show từ `2` lần trong `30` ngày thì hiển thị cảnh báo.
- Nếu user no-show từ `3` lần trong `30` ngày thì hạn chế đăng ký sự kiện trong `3` ngày.
- Nếu Reputation Score dưới `40` thì khi đăng ký sự kiện cần hiển thị cảnh báo rủi ro cho host.
- Host có quyền chấp nhận hoặc từ chối người có uy tín thấp.

---

## 9. Component UserTrustCard dành cho host

Tạo component hiển thị thông tin uy tín của user khi host duyệt người tham gia.

### Thông tin cần hiển thị

- Tên user.
- Avatar.
- Reputation Score.
- Cấp độ uy tín.
- Tỷ lệ tham gia.
- Số lần leo cây trong 30 ngày.
- Rating trung bình.
- Cảnh báo nếu người dùng có điểm thấp.

---

## 10. Yêu cầu giao diện

Giao diện cần có cảm giác giống một hệ thống:

> **Trust Passport - Hộ chiếu uy tín**

### Yêu cầu UI

- Thiết kế hiện đại, đẹp, responsive.
- Có thể dùng card, progress circle, badge, icon, màu gradient.
- Điểm cao dùng màu xanh lá hoặc xanh mint.
- Điểm trung bình dùng màu vàng hoặc cam.
- Điểm thấp dùng màu đỏ.
- UI rõ ràng, dễ nhìn, dễ demo trong đồ án.
- Có cảm giác game hóa nhẹ, không quá rối.

---

## 11. Yêu cầu code

Code cần đảm bảo:

- Sạch, dễ hiểu.
- Có chia component rõ ràng.
- Tách phần tính điểm Reputation Score thành một function hoặc service riêng.
- Không hard-code quá nhiều trong component UI.
- Có dữ liệu mock để demo nếu chưa có backend.
- Viết đầy đủ các component cần thiết.
- Có comment ở những đoạn logic quan trọng.

---

## 12. Kết quả cần tạo

Hãy tạo cho tôi đầy đủ các phần sau:

1. Cấu trúc folder đề xuất.
2. Model/interface dữ liệu cần dùng.
3. Function tính Reputation Score.
4. Component `TrustDashboard`.
5. Component `CommitmentModal`.
6. Component `CheckInButton`.
7. Component `HostReviewForm`.
8. Component `UserTrustCard` dành cho host.
9. Mock data để test giao diện.
10. Giải thích ngắn cách các component hoạt động với nhau.
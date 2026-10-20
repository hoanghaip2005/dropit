# Thiết kế 04 — Luồng & máy trạng thái

Giai đoạn 3 — Thiết kế. Ngày tạo: 2026-10-19.
Nguồn: `ba/srs/03-quy-tac.md` (§Phiên §2.1, §2.2, §3, §4; BR-82, BR-118; máy trạng thái NHÓM, KHIẾU NẠI), `ba/srs/05-tham-chieu-ky-thuat.md` (§1, §2, §5, §6 K-xx), `ba/srs/02-ep03-phien.md`, `02-ep04-thong-bao.md`, `02-ep08-bao-cao.md`, `ba/views/00-danh-muc-man.md`, `spike/t01-lifecycle/server/server.js`, `spike/t01-lifecycle/README.md`.
Ưu tiên: khi tệp này lệch `03-quy-tac.md` hoặc `02-so-quyet-dinh.md` thì hai tệp đó thắng. Tên trạng thái giữ **đúng** như `03-quy-tac.md` và enum `design/schema.sql`. Tên sự kiện socket và trường payload theo `design/03-api-socket.md` §3 (nguồn thắng; đã khớp lại 2026-10-19).
Chỗ quy tắc chưa đủ để vẽ: ghi `DQ-F..` (mục 4). Không tự chốt — mỗi DQ-F cần chuyển thành `Q-` khi đưa vào sổ quyết định.

Quy ước trong sơ đồ: **S** = server (EC2, Node + Socket.io), **C** = app thành viên, **CN** = app chủ nhóm, giờ đều là **giờ server** (BR-03). Tham số dùng mặc định (`grace_s = 3`, `countdown_s = 5`, `heartbeat_timeout_s = 10`, `disconnect_hold_s = 10`, `pause_max_min = 5`).

---

## 1. Máy trạng thái

### 1.1 Cấp PHIÊN (03 §2.1)

Không có FAILED. `forfeited` là **thuộc tính**, không phải trạng thái (BR-35).

```mermaid
stateDiagram-v2
    direction LR
    [*] --> SCHEDULED: Chủ nhóm đặt lịch (BR-01, BR-79)
    SCHEDULED --> COUNTDOWN: t = started_at − countdown_s (BR-04)
    SCHEDULED --> CANCELLED: Chủ nhóm hủy trước giờ (BR-29, OWNER_CANCEL) / giải tán (GROUP_DISSOLVED, BR-80) / khóa chủ nhóm (OWNER_LOCKED, BR-108)
    COUNTDOWN --> ACTIVE: t = started_at, đặt ends_at (BR-04)
    COUNTDOWN --> CANCELLED: Sự cố server, SERVER_OUTAGE (BR-22)
    ACTIVE --> COMPLETED: t = ends_at, chốt từng người (BR-23)
    ACTIVE --> CANCELLED: Sự cố server, SERVER_OUTAGE (BR-22, BR-68)
    ACTIVE --> CANCELLED: Hết hạn vào, không ai vào → ABSENT trước, cancel_reason = NO_ATTENDEE (BR-30)
    COMPLETED --> [*]
    CANCELLED --> [*]

    state ACTIVE {
        direction LR
        [*] --> ChuaMatThuong
        state "forfeited = false" as ChuaMatThuong
        state "forfeited = true (forfeited_at, forfeit_trigger_user_id)" as MatThuong
        ChuaMatThuong --> MatThuong: EXITED đầu tiên → MEMBER_EXITED kèm forfeited (gộp SESSION_FORFEITED, BR-35, BR-38)
        MatThuong --> MatThuong: EXITED tiếp theo → chỉ MEMBER_EXITED (BR-39)
        ChuaMatThuong --> ChuaMatThuong: LOST / WITHDRAWN / ABSENT (BR-36, D-19)
    }

    note right of COMPLETED
        Sau phiên: miễn trừ mọi EXITED → gỡ forfeited,
        khôi phục hồi tố (BR-87, BR-88). Phiên vẫn COMPLETED.
        Sự cố → CANCELLED gỡ forfeited (BR-22).
    end note
```

### 1.2 Cấp THÀNH VIÊN TRONG PHIÊN (03 §2.2, §3)

Chỉ áp cho **thành viên**; chủ nhóm không có trạng thái (D-25, BR-114). Trạng thái kết thúc là cuối cùng (BR-32); sự kiện mới bị bỏ qua (§3 #12).

```mermaid
stateDiagram-v2
    [*] --> INVITED: Phiên SCHEDULED, thành viên đã đồng ý (DQ-F01)

    INVITED --> WAITING: Vào phòng chờ, đã đồng ý, không ở phiên khác (BR-06, BR-09, BR-63)
    INVITED --> FOCUSING: Vào muộn, started_at ≤ t < started_at + late_join_max_min (BR-07, Should)
    INVITED --> ABSENT: t ≥ hạn vào (BR-08, BR-65)

    WAITING --> FOCUSING: Phiên → ACTIVE, đang ở app (BR-05)
    WAITING --> GRACE: Phiên → ACTIVE, đã rời app trong COUNTDOWN, trừ lượt (BR-64)
    WAITING --> ABSENT: Bấm "Rời phiên" + xác nhận trước started_at (BR-118 (2), Q-149)
    WAITING --> ABSENT: Mất kết nối, đến started_at chưa nối lại (Q-153)

    FOCUSING --> GRACE: Rời app, còn lượt, hẹn 3s (BR-11, BR-13)
    FOCUSING --> EXITED: Rời app, hết lượt (BR-13)
    FOCUSING --> FOCUSING: Khóa / tắt màn hình (BR-15, D-08)
    FOCUSING --> PAUSED: Tạm dừng + lý do, còn lượt, hẹn 5 phút (BR-16, BR-67)
    FOCUSING --> DISCONNECTED: t ≥ last_seen_at + 10s hoặc socket đóng, chưa báo khóa (BR-19, BR-66)

    GRACE --> FOCUSING: Quay lại, t < hạn → grace_recovered (BR-12)
    GRACE --> EXITED: t ≥ hạn 3s, kể cả khi đang mất mạng (BR-14, §3 #1, #29, #51)

    PAUSED --> FOCUSING: Bấm tiếp tục / hết 5 phút khi đang ở app (BR-16)
    PAUSED --> GRACE: Hết 5 phút khi không ở app, không trừ lượt (BR-18)
    PAUSED --> PAUSED: Rời app không tính (BR-16)
    PAUSED --> DISCONNECTED: Mất heartbeat / socket đóng (BR-19)

    DISCONNECTED --> FOCUSING: Nối lại + session_id, t < disconnected_at + 10s, trước đó FOCUSING (BR-20)
    DISCONNECTED --> PAUSED: Nối lại trong hạn, trước đó PAUSED (BR-20, DQ-F05)
    DISCONNECTED --> LOST: t ≥ disconnected_at + 10s (BR-19, BR-21, D-19)

    FOCUSING --> EXITED: "Rời phiên" + xác nhận, reason = USER_LEAVE (BR-118 (1), D-29)
    GRACE --> EXITED: "Rời phiên" + xác nhận, hủy hẹn 3s (BR-118, §3 #54, #55)
    PAUSED --> EXITED: "Rời phiên" + xác nhận, hủy hẹn 5 phút (BR-118)

    FOCUSING --> COMPLETED: t = ends_at (BR-23)
    PAUSED --> COMPLETED: t = ends_at (§3 #5)
    GRACE --> COMPLETED: t = ends_at, chưa quá hạn (§3 #6)
    DISCONNECTED --> COMPLETED: Nối lại trong hạn sau ends_at (§3 #7, Q-31)

    state "Mọi trạng thái chưa kết thúc" as ChuaKetThuc
    note right of ChuaKetThuc
        Rút đồng ý → WITHDRAWN (BR-26, ưu tiên mọi hạn, §3 #15)
        Quản trị khóa → WITHDRAWN reason = ACCOUNT_LOCKED (BR-108)
        Phiên CANCELLED (trừ BR-30) → VOID (BR-22, BR-63)
        Chủ nhóm xóa khỏi nhóm → không đổi, hiệu lực sau ends_at (BR-77)
    end note
    ChuaKetThuc --> WITHDRAWN
    ChuaKetThuc --> VOID

    COMPLETED --> [*]
    EXITED --> [*]
    LOST --> [*]
    ABSENT --> [*]
    WITHDRAWN --> [*]
    VOID --> [*]
```

Ghi chú vẽ:
- "Mọi trạng thái chưa kết thúc" = INVITED, WAITING, FOCUSING, GRACE, PAUSED, DISCONNECTED; là nút gom để sơ đồ đọc được, không phải trạng thái thật.
- GRACE **không** vào DISCONNECTED (§3 #1, 05 §5). DISCONNECTED **không** bấm "Rời phiên" được (BR-118 (3), §3 #56).
- Chỉ mũi tên vào EXITED kích hoạt BR-35 (BR-36).
- Spike T-01 có thêm `lock_reclassified` (GRACE → FOCUSING khi tín hiệu khóa đến trễ) — **không** vẽ vì chưa có BR (DQ-F07).

### 1.3 NHÓM (03 §Máy trạng thái NHÓM)

```mermaid
stateDiagram-v2
    state "HOẠT ĐỘNG (ACTIVE)" as HD
    state "TẠM NGƯNG LỊCH (SCHEDULE_SUSPENDED)" as TN
    state "CHỜ GIẢI TÁN (DISSOLVING)" as CGT
    state "ĐÃ GIẢI TÁN (DISSOLVED)" as DGT

    [*] --> HD: Tạo nhóm, chưa vượt max_groups_owned (BR-75, D-10)
    HD --> DGT: Giải tán / chủ nhóm xóa tài khoản, không có phiên COUNTDOWN/ACTIVE (BR-80, BR-72)
    HD --> CGT: Giải tán / chủ nhóm xóa tài khoản, có phiên COUNTDOWN/ACTIVE (BR-80)
    HD --> TN: Quản trị khóa chủ nhóm, SCHEDULED → CANCELLED (BR-108, Q-118)
    TN --> HD: Mở khóa chủ nhóm
    TN --> DGT: Quản trị giải tán (BR-109) / t ≥ suspended_at + lock_dissolve_days
    TN --> CGT: Giải tán khi có phiên COUNTDOWN/ACTIVE
    CGT --> DGT: Phiên đang chạy đến ends_at (BR-80)
    CGT --> CGT: Khóa chủ nhóm, giữ nguyên (giả định)
    DGT --> [*]

    note right of HD
        Dưới 4 thành viên không là trạng thái,
        chỉ cảnh báo (BR-74, Q-68)
    end note
```

### 1.4 KHIẾU NẠI (03 §Máy trạng thái KHIẾU NẠI)

```mermaid
stateDiagram-v2
    state "CHỜ XỬ LÝ (PENDING)" as CXL
    state "ĐANG XỬ LÝ (IN_REVIEW)" as DXL
    state "CHUYỂN QUẢN TRỊ (ESCALATED)" as CQT
    state "MIỄN TRỪ (EXEMPTED)" as MT
    state "BÁC (REJECTED)" as BAC

    [*] --> CXL: Gửi khiếu nại EXITED của mình, t < ends_at + appeal_window_h (BR-86)
    [*] --> CQT: Gửi kèm "nghi lỗi hệ thống" (suspect_system_error = true)
    CXL --> DXL: Chủ nhóm mở ca, ghi nhật ký truy cập (BR-73)
    CXL --> CQT: Chủ nhóm chọn "nghi lỗi hệ thống" / quá appeal_escalate_h / nhóm ĐÃ GIẢI TÁN / chủ nhóm bị khóa
    DXL --> CQT: Như trên (BR-110)
    DXL --> MT: Chấp nhận + lý do → BR-87, BR-88, EXEMPTION_GRANTED
    DXL --> BAC: Bác + lý do
    CQT --> MT: Quản trị chấp nhận + lý do (BR-110)
    CQT --> BAC: Quản trị bác + lý do
    MT --> MT: Quản trị "mở lại để xem", không đổi status
    BAC --> BAC: Quản trị "mở lại để xem", không đổi status
    MT --> [*]
    BAC --> [*]
```

Giải trình (BR-85) **không** có máy trạng thái riêng: một giải trình/sự kiện EXITED, sửa được trong `explanation_edit_h`, sau đó chỉ xem.

---

## 2. Luồng then chốt (sequenceDiagram)

### 2.1 Đăng ký + vào nhóm + đồng ý

```mermaid
sequenceDiagram
    autonumber
    actor U as Người dùng
    participant C as App
    participant Cog as Cognito
    participant S as Server
    participant DB as RDS
    U->>C: Nhập email, mật khẩu (V-02)
    C->>Cog: SignUp
    Cog-->>U: Email mã xác minh
    U->>C: Nhập mã
    C->>Cog: ConfirmSignUp, đăng nhập
    Cog-->>C: JWT (access + refresh)
    C->>S: Tạo hồ sơ (JWT)
    S->>DB: users (chưa thuộc nhóm nào)
    U->>C: Nhập mã nhóm 8 ký tự (V-04)
    C->>S: Kiểm tra mã
    alt Mã sai / hết hiệu lực
        S-->>C: Từ chối, đếm lượt sai (≥5 lần/15 phút → khóa 15 phút, BR-76)
    else Mã đúng
        S-->>C: Màn đồng ý: mục đích báo cáo, thời hạn lưu, quy tắc D-05 (V-05, BR-06)
        U->>C: Bấm "Đồng ý"
        C->>S: Đồng ý (consent_version)
        alt Đã là thành viên nhóm khác (BR-75a) / nhóm đủ 10 (BR-74) / là chủ nhóm này
            S-->>C: Từ chối kèm lý do, không tạo thành viên
        else Hợp lệ
            S->>DB: group_members (consent_version, consented_at, joined_at)
            S-->>C: Vào nhóm, thấy phiên kế tiếp (V-03)
        end
    end
```

### 2.2 Chủ nhóm đặt lịch → mở phiên → đếm ngược

```mermaid
sequenceDiagram
    autonumber
    actor CN as Chủ nhóm
    participant S as Server
    participant DB as RDS
    participant SNS as SNS
    participant C as App thành viên
    CN->>S: POST /groups/{id}/schedules {start_time, duration_min ∈ {25,50}} (V-44)
    alt Trùng phiên khác của nhóm (BR-78) / giờ < now + 1 phút (BR-79) / duration ∉ {25,50}
        S-->>CN: Từ chối kèm lý do
    else Hợp lệ
        S->>DB: sessions status = SCHEDULED, session_members INVITED (DQ-F01)
        S-->>CN: Đã lưu
    end
    S->>SNS: started_at − reminder_min: nhắc thành viên (BR-79, Should)
    SNS-->>C: Push nhắc (V-18)
    Note over S: started_at − lobby_open_min: mở phòng chờ (BR-63)
    C->>S: session:join {event_id, session_id} (JWT ở handshake)
    alt Chưa đồng ý bản mới (BR-06) / là chủ nhóm (BR-114) / trước giờ mở
        S-->>C: Từ chối kèm lý do
    else Hợp lệ
        S-->>C: WAITING, session:state (V-06)
    end
    Note over S: t = started_at − 5s: SCHEDULED → COUNTDOWN (BR-04)
    S-->>C: session:countdown {countdown_starts_at, started_at, server_ts} (V-07, không có nút "Rời phiên")
    Note over C: Rời app trong COUNTDOWN: không ghi (BR-64)
    Note over S: t = started_at: COUNTDOWN → ACTIVE, ends_at = started_at + duration
    Note over S: Dùng trạng thái tiền cảnh cuối nhận trong COUNTDOWN (member:left_app / member:returned) — không có sự kiện hỏi riêng (DQ-F03)
    alt Đang ở app
        S-->>C: session:state + member:state FOCUSING, bật chỉ báo "Phiên đang được ghi" (V-08, BR-05)
    else Không ở app / chưa báo
        S-->>C: member:grace {grace_deadline} — GRACE từ started_at, trừ lượt (BR-64)
    end
    Note over S: Thành viên còn INVITED tại hạn vào → ABSENT (BR-08)
```

### 2.3 Rời app → khoan hồng 3s → quay lại

```mermaid
sequenceDiagram
    autonumber
    participant C as App thành viên
    participant S as Server
    participant L as DynamoDB (log)
    Note over C: FOCUSING. Vào nền, chờ lockWaitMs 600ms, không có tín hiệu khóa → LEAVE
    C->>S: member:left_app {event_id, session_id, client_ts}
    S->>S: Bỏ client_ts, dùng giờ server (BR-03)
    alt Còn lượt khoan hồng
        S->>L: left_app (serverTs)
        S-->>C: member:grace {grace_deadline = now + 3000ms, server_ts} (chỉ người đó)
        Note over C: Mở lại app, thấy cảnh báo V-09
        C->>S: member:returned {event_id, session_id, client_ts}
        alt t < hạn (BR-65)
            S->>L: grace_recovered
            S-->>C: ack {ok, state: FOCUSING}
            Note over S: Không báo ai, không forfeited (BR-12)
        else t ≥ hạn (vd. đúng 3,000s)
            Note over S: Đã EXITED → xem 2.4
        end
    else Hết lượt (BR-13)
        Note over S: EXITED ngay → xem 2.4
    end
    opt Gửi lại cùng event_id
        C->>S: member:returned {event_id cũ}
        S-->>C: ack kết quả cũ, duplicate: true (BR-31)
    end
```

### 2.4 Rời app quá 3s → EXITED → MEMBER_EXITED (gộp SESSION_FORFEITED)

```mermaid
sequenceDiagram
    autonumber
    participant X as App người thoát
    participant S as Server
    participant DB as RDS / bộ nhớ
    participant T as App người trong phiên (chưa kết thúc)
    participant SNS as SNS
    participant N as Chủ nhóm + thành viên ngoài phiên + người đã kết thúc
    Note over S: GRACE, t ≥ grace_deadline (timer server)
    S->>DB: X → EXITED (serverTs)
    alt forfeited = false (EXITED đầu tiên)
        S->>DB: forfeited = true, forfeited_at, forfeit_trigger_user_id = X (BR-35)
        Note over S: Một MEMBER_EXITED có trường forfeited {display_name, at} = tên X, giờ server — gộp SESSION_FORFEITED (BR-38, D-22)
    else forfeited = true
        Note over S: Chỉ MEMBER_EXITED, không đổi người khởi phát (BR-39)
    end
    par Người trong phiên (BR-82)
        S-->>T: Socket MEMBER_EXITED {exited_display_name, exited_at, forfeited?}
        alt T ở tiền cảnh, màn hình mở
            Note over T: Banner V-11, tự ẩn, không âm thanh
        else T khóa màn hình / GRACE / PAUSED
            Note over T: Không push hệ thống, xếp hàng, hiện khi quay lại / mở khóa
        end
    and Người ngoài phiên (BR-27)
        S->>SNS: Push có tên X (≤ notify_latency_s = 5s, BR-28)
        SNS-->>N: Push + hộp thông báo (V-16)
    end
    S->>DB: Hộp thông báo cho mọi người nhận, trừ X (BR-81)
    S-->>X: member:state {my_state: EXITED, reason: GRACE_EXPIRED} → màn V-13 (lối vào giải trình V-15)
    Note over S,T: Phiên vẫn ACTIVE đến ends_at (D-05)
```

### 2.5 Khóa màn hình (không tính rời)

```mermaid
sequenceDiagram
    autonumber
    participant C as App thành viên
    participant S as Server
    Note over C: FOCUSING. Android SCREEN_OFF / iOS protectedDataWillBecomeUnavailable → LOCK
    C->>S: member:screen_locked {event_id, session_id, client_ts}
    S->>S: Cờ screenLocked = true, bỏ ngưỡng heartbeat, socket đóng không tính (BR-66)
    Note over C,S: Heartbeat có thể giảm/ngừng. Vẫn FOCUSING (BR-15, §3 #40)
    opt Có MEMBER_EXITED của người khác
        S-->>C: Xếp hàng, không push hệ thống (BR-82)
    end
    C->>S: member:screen_unlocked {event_id, session_id, client_ts}
    S->>S: last_seen_at = now, áp lại ngưỡng 10s (§3 #43)
    S-->>C: ack FOCUSING + giao MEMBER_EXITED đã xếp hàng (banner V-11)
    opt Mở khóa rồi rời app (§3 #17)
        C->>S: member:left_app
        Note over S: Theo 2.3 từ lúc rời app
    end
    opt member:returned mà không có screen_unlocked hợp lệ
        Note over S: Coi như rời app (05 §5, Q-61, chờ spike)
    end
```

### 2.6 Bấm "Rời phiên" (D-29, BR-118)

```mermaid
sequenceDiagram
    autonumber
    actor U as Thành viên
    participant C as App
    participant S as Server
    U->>C: Bấm "Rời phiên" (V-06 hoặc V-08, không có ở V-07)
    C-->>U: Hộp xác nhận nêu hệ quả (WAITING: "bạn sẽ bị ghi vắng")
    alt Hủy hộp
        C-->>U: Giữ nguyên, không gửi gì, hạn đang chạy vẫn chạy (§3 #57)
    else Xác nhận, không có mạng (DISCONNECTED)
        C-->>U: "Không có kết nối, chưa rời phiên", không xếp hàng gửi sau (§3 #56)
    else Xác nhận, có mạng
        C->>S: session:leave {event_id, session_id}
        alt Trạng thái lúc nhận = WAITING (trước started_at)
            S-->>C: ack ABSENT (end_reason = LOBBY_LEAVE), không MEMBER_EXITED, không D-05 (Q-149)
        else FOCUSING / GRACE / PAUSED (ACTIVE)
            S->>S: EXITED end_reason = USER_LEAVE, hủy hẹn GRACE/PAUSED, không trừ lượt
            S-->>C: ack EXITED → V-13
            Note over S: Thông báo như 2.4 (BR-27, BR-35)
        else Đã kết thúc / event_id trùng
            S-->>C: Bỏ qua, trả kết quả cũ (BR-31, BR-32)
        end
    end
    Note over S: session:leave và grace_timeout gần như cùng lúc → sự kiện server nhận trước thắng, một bản ghi (§3 #55)
```

### 2.7 Mất mạng → DISCONNECTED → LOST

```mermaid
sequenceDiagram
    autonumber
    participant C as App thành viên
    participant S as Server
    loop Mỗi 5s khi tiền cảnh, màn hình mở
        C->>S: heartbeat {session_id}
        S->>S: last_seen_at = now
    end
    Note over C: Mất Wi-Fi / 4G, heartbeat cuối lúc T
    Note over S: t = min(socket đóng, T + 10s) → DISCONNECTED, ghi disconnected_at, nhớ trạng thái trước (BR-19)
    S->>S: Hẹn LOST tại disconnected_at + 10s
    alt Nối lại trong hạn (t < disconnected_at + 10s)
        C->>S: session:resume {event_id, session_id, last_server_event_id}
        S-->>C: ack {ok, state} + session:state + phát lại S→C sau last_server_event_id (BR-20)
        opt Báo đã rời app lúc mất mạng (§3 #2)
            Note over S: Áp BR-11/BR-13 tính từ lúc nối lại
        end
    else t ≥ disconnected_at + 10s
        S->>S: LOST, end_reason = DISCONNECT_TIMEOUT, tách khỏi thoát (BR-21)
        Note over S: Không MEMBER_EXITED, không forfeited, không báo ai (D-19)
        C->>S: Nối lại muộn
        S-->>C: ack {ok:false, code: SESSION_LOST, state: LOST} → V-10, kết quả V-14
    end
    Note over S: Đang GRACE mà mất mạng: không DISCONNECTED, hạn 3s vẫn chạy → EXITED (§3 #1, #51)
```

### 2.8 Sự cố server → hủy phiên

```mermaid
sequenceDiagram
    autonumber
    participant S as Server
    participant DB as RDS
    participant SNS as SNS
    participant V as Thành viên chưa kết thúc
    participant E as Thành viên đã EXITED trước sự cố
    participant CN as Chủ nhóm
    alt ≥ 80% thành viên đang hoạt động mất kết nối trong 10s (BR-22, Q-28)
        S->>S: Phát hiện sự cố toàn server
    else Server khởi động lại giữa phiên (K-11)
        S->>DB: Đọc phiên COUNTDOWN/ACTIVE còn dở (DQ-F04)
    end
    S->>DB: Phiên → CANCELLED, cancel_reason = SERVER_OUTAGE, gỡ forfeited
    S->>DB: Mọi người chưa kết thúc → VOID, hủy hẹn GRACE/PAUSED/LOST (§3 #44)
    Note over S,DB: EXITED trước sự cố giữ EXITED + ngắt chuỗi, LOST trước giữ LOST (BR-68)
    S->>SNS: SESSION_CANCELLED_OUTAGE (không nêu cá nhân)
    SNS-->>V: Push / socket + hộp thông báo
    SNS-->>CN: Push + hộp thông báo
    S->>SNS: SESSION_CANCELLED_OUTAGE_EXITED
    SNS-->>E: "Lần rời app của bạn vẫn được ghi, chuỗi đã ngắt, có thể khiếu nại"
    Note over S: Không Coins, không vào báo cáo tháng (BR-58)
```

### 2.9 Kết thúc phiên → Coins sổ cái, điểm danh, chuỗi

```mermaid
sequenceDiagram
    autonumber
    participant S as Server
    participant DB as RDS
    participant C as App thành viên
    participant SNS as SNS
    Note over S: t = ends_at
    S->>S: FOCUSING/PAUSED/GRACE chưa quá hạn → COMPLETED. DISCONNECTED chờ hạn giữ chỗ (§3 #7)
    S->>DB: BEGIN transaction (05 §3.1)
    S->>DB: session_members.state (trạng thái cuối), end_reason = TIME_UP, focus_seconds (BR-32)
    alt forfeited = false
        loop Mỗi người COMPLETED
            S->>DB: coin_ledger SESSION_REWARD 10/25 (vào muộn tính tỉ lệ), cắt theo trần 100/ngày (BR-40, BR-42, BR-43)
            Note over DB: Khóa duy nhất (type, ref_id, user_id) chống ghi trùng (BR-45)
            S->>DB: Nhật ký thành tích CHECKIN, STREAK_INC nếu chưa +1 hôm nay (BR-46, BR-49, BR-92)
        end
    else forfeited = true
        S->>DB: Không dòng sổ cái nào (BR-41)
        S->>DB: CHECKIN cho người COMPLETED (BR-46), STREAK_BREAK cho phạm vi BR-37
    end
    S->>DB: EXITED → STREAK_BREAK (BR-47a). LOST, ABSENT, VOID, WITHDRAWN theo BR-48
    S->>DB: Phiên → COMPLETED, COMMIT
    S-->>C: SESSION_RESULT qua socket, chỉ chính người đó (V-12 / V-13 / V-14)
    S->>SNS: Push SESSION_RESULT cho người không mở app, gộp "mất thưởng — chuỗi bị ngắt" (BR-91, Q-93)
    S->>DB: Xét huy hiệu theo mốc, chỉ thông báo trong app (BR-52, Q-95)
```

### 2.10 Giải trình + khiếu nại + miễn trừ

```mermaid
sequenceDiagram
    autonumber
    actor X as Thành viên EXITED
    participant S as Server
    participant CN as Chủ nhóm
    participant QT as Quản trị
    participant DB as RDS
    X->>S: Gửi giải trình ≤ 500 ký tự, trong ends_at + 7 ngày (V-15, BR-85)
    S->>DB: Lưu (sửa được trong 24h, giữ bản cũ)
    S-->>CN: Thông báo trong app, không push (V-47)
    Note over S: Giải trình không đổi kết quả (BR-54)
    X->>S: Gửi khiếu nại, t < ends_at + 24h, một lần/sự kiện (BR-86, Should)
    alt Chọn "nghi lỗi hệ thống"
        S->>DB: appeals.status = ESCALATED
        S-->>QT: Hộp việc quản trị (V-63)
    else
        S->>DB: appeals.status = PENDING
        S-->>CN: Thông báo trong app
        CN->>S: Mở ca → IN_REVIEW, ghi access_logs (BR-73)
        opt Quá 72h chưa quyết / chủ nhóm chọn "nghi lỗi hệ thống"
            S->>DB: ESCALATED, báo người khiếu nại
        end
    end
    alt Bác + lý do
        S->>DB: REJECTED + decision_reason
        S-->>X: Báo kết quả
    else Chấp nhận + lý do
        S->>DB: EXEMPTED + decision_reason, session_members.exempted = true (không xóa EXITED, BR-32)
        alt Không còn EXITED chưa miễn trừ
            S->>DB: forfeited = false, khôi phục hồi tố: SESSION_REWARD reason = APPEAL_RESTORE theo trần ngày phiên, STREAK_RESTORE, huy hiệu (BR-88)
        else Còn EXITED khác
            S->>DB: Giữ forfeited, khởi phát = EXITED chưa miễn trừ sớm nhất (BR-87)
        end
        S-->>X: EXEMPTION_GRANTED
        S-->>CN: EXEMPTION_GRANTED bản đính chính, không Coins (đúng danh sách đã nhận MEMBER_EXITED, nêu tên, Q-138 Chờ)
        Note over S: Báo cáo tháng đã tạo không đổi, chỉ ghi chú trong app (BR-102)
    end
```

### 2.11 Báo cáo tháng (cron → bản chụp → email SES)

```mermaid
sequenceDiagram
    autonumber
    participant Cron as Cron EC2 (Must) / EventBridge + Lambda (Should)
    participant S as Server báo cáo
    participant DB as RDS
    participant SES as SES
    participant CN as Chủ nhóm
    participant QT as Quản trị
    Cron->>S: 02:00 ngày 1 (Asia/Ho_Chi_Minh, BR-56, Q-132)
    loop Mỗi nhóm (gồm nhóm giải tán trong tháng, BR-62)
        S->>DB: Đã có báo cáo (nhóm, kỳ)? (idempotent, BR-101)
        alt Đã có
            S->>S: Bỏ qua
        else Chưa có
            S->>DB: Lấy phiên COMPLETED của nhóm trong [ngày 1, ngày 1 tháng sau) (BR-55, BR-58)
            S->>S: Dòng mỗi thành viên (không dòng chủ nhóm, không Coins, không chuỗi — BR-53, BR-60)
            S->>S: Chỉ số nhóm + so với tháng trước, đếm sĩ số cho ngưỡng 5 (BR-104)
            S->>DB: Lưu bản chụp bất biến, tên hiển thị tại lúc tạo (BR-56, BR-97)
            S->>SES: Email tóm tắt: nhóm, kỳ, mục đích, số phiên, 2 tỉ lệ, số phiên mất thưởng, link mở app (BR-105)
            Note over SES: Không PDF, không dòng thành viên, không pixel/link theo dõi (BR-122)
            SES-->>CN: Email (V-50)
            opt Gửi lỗi
                S->>SES: Thử lại ≤ 3 lần trong 24h, sau đó chỉ còn bản trong app
            end
        end
    end
    opt Lần chạy lỗi
        Cron->>S: Thử lại mỗi 1h, ≤ 3 lần, không quá 06:00 (BR-101)
        S-->>QT: Quá hạn vẫn lỗi → cảnh báo hộp việc quản trị, chạy lại thủ công
    end
    CN->>S: Mở báo cáo trong app (V-48), ghi nhật ký truy cập (BR-73)
```

### 2.12 Chủ nhóm xem chi tiết phiên (kéo để làm mới, D-28)

```mermaid
sequenceDiagram
    autonumber
    actor CN as Chủ nhóm
    participant A as App chủ nhóm (V-46)
    participant S as Server
    participant DB as RDS
    CN->>A: Mở chi tiết phiên
    A->>S: GET /sessions/{id}/owner-detail (JWT)
    S->>S: Kiểm quyền: là chủ nhóm của nhóm (NFR-11)
    S->>DB: Ghi access_logs object_type = SESSION (BR-73)
    S->>DB: Chỉ dữ liệu đã xác nhận: trạng thái phiên, EXITED + giờ, forfeited + người khởi phát, giải trình/khiếu nại. Sau phiên: trạng thái cuối, vào muộn, số PAUSED + lý do (BR-116)
    S-->>A: Dữ liệu (không FOCUSING/GRACE/heartbeat thời gian thực, không chuỗi/Coins)
    A-->>CN: Danh sách người theo tên, danh sách sự kiện theo giờ server (BR-115)
    Note over S,A: Có MEMBER_EXITED mới: CN nhận push / hộp thông báo, nhưng V-46 KHÔNG tự đổi (BR-123)
    CN->>A: Kéo xuống để làm mới
    A->>S: GET /sessions/{id}/owner-detail
    S->>DB: Gộp access_logs.view_count trong 10 phút (BR-73)
    S-->>A: Dữ liệu mới
    Note over A: Màn chỉ-xem: không dừng, kéo dài, đuổi người (BR-116)
```

---

## 3. Bảng ánh xạ sơ đồ → BR, US, ca kiểm thử

K-xx theo `05` §6; S-xx là ca đo của spike T-01 (`spike/t01-lifecycle/README.md` §5). "—" = chưa có ca K tương ứng (DQ-F10).

| Sơ đồ | BR chính | US | Màn | K-xx / S-xx |
| --- | --- | --- | --- | --- |
| 1.1 Phiên | BR-01, BR-04, BR-22, BR-23, BR-29, BR-30, BR-35, BR-36, BR-39, BR-87 | US-02.10, US-02.11, US-03.02, US-03.08, US-03.10, US-03.12 | V-07, V-46 | K-01, K-02, K-09, K-11 |
| 1.2 Thành viên | BR-05…BR-09, BR-11…BR-21, BR-23, BR-26, BR-31, BR-32, BR-64…BR-66, BR-108, BR-118; §3 #1–#57 | US-03.01…US-03.07, US-03.10, US-03.11, US-01.07 | V-06…V-10, V-13, V-14 | K-02…K-08, K-10, K-16; S-01…S-15 |
| 1.3 Nhóm | BR-72, BR-74, BR-75, BR-80, BR-108, BR-109 | US-02.01, US-02.09, US-09.02, US-09.06 | V-41, V-42 | — |
| 1.4 Khiếu nại | BR-85, BR-86, BR-87, BR-110 | US-04.07, US-04.08, US-09.05 | V-63 | — |
| 2.1 Đăng ký + vào nhóm | BR-06, BR-71, BR-74, BR-75, BR-76 | US-01.01, US-01.05, US-02.03 | V-02, V-04, V-05 | K-14 |
| 2.2 Đặt lịch → đếm ngược | BR-02, BR-04, BR-05, BR-08, BR-63, BR-64, BR-78, BR-79, BR-114 | US-02.10, US-02.14, US-03.01, US-03.02, US-03.03 | V-44, V-18, V-06, V-07, V-08 | K-15 |
| 2.3 Khoan hồng 3s | BR-03, BR-11, BR-12, BR-13, BR-31, BR-65 | US-03.04, US-03.05 | V-08, V-09 | K-03, K-04, K-05, K-10; S-06, S-07, S-08 |
| 2.4 EXITED + thông báo | BR-14, BR-27, BR-28, BR-35, BR-38, BR-39, BR-81, BR-82 | US-03.08, US-03.09, US-04.01 | V-11, V-13, V-16 | K-02, K-09; S-01, S-02, S-05, S-18 |
| 2.5 Khóa màn hình | BR-15, BR-19, BR-66, BR-82, BR-34 | US-03.04 | V-08, V-11 | K-06, K-13; S-09…S-13, S-17 |
| 2.6 "Rời phiên" | BR-118, BR-31, BR-32, BR-33, BR-35; §3 #53–#57 | US-03.01, US-03.04 (AC-03.04.10) | V-06, V-08, V-13 | K-16 |
| 2.7 Mất mạng | BR-19, BR-20, BR-21, BR-65, BR-66; §3 #1, #2, #7, #41, #42 | US-03.07 | V-10, V-14 | K-07, K-08; S-14, S-15 |
| 2.8 Sự cố server | BR-22, BR-58, BR-68; §3 #8, #28, #44, #45, #52 | US-03.12, US-04.09 | V-16 | K-11 |
| 2.9 Kết thúc phiên | BR-23, BR-24, BR-37, BR-40…BR-49, BR-52, BR-91, BR-92 | US-03.10, US-05.01, US-05.03, US-05.05, US-06.01 | V-12, V-13, V-14, V-27 | K-01, K-02, K-09 |
| 2.10 Giải trình + khiếu nại | BR-54, BR-73, BR-85…BR-88, BR-102, BR-110 | US-04.05, US-04.06, US-04.07, US-04.08, US-09.05 | V-15, V-47, V-63 | — |
| 2.11 Báo cáo tháng | BR-53, BR-55…BR-62, BR-101, BR-104, BR-105, BR-122 | US-08.01, US-08.02, US-08.07, US-08.09 | V-48, V-50 | — |
| 2.12 Chi tiết phiên chủ nhóm | BR-73, BR-115, BR-116, BR-123 | US-08.10, US-04.06 | V-46 | K-14 |

---

## 4. Chỗ quy tắc chưa đủ để vẽ (DQ-F)

| Mã | Chỗ thiếu | Ảnh hưởng sơ đồ | Đề xuất (chưa chốt) |
| --- | --- | --- | --- |
| DQ-F01 | Không có BR nói **khi nào** tạo bản ghi INVITED (lúc đặt lịch, lúc COUNTDOWN hay lúc `started_at`) và ai được INVITED (thành viên tại lúc đặt lịch hay tại `started_at`). "Lượt dự kiến" (§Báo cáo §3) dùng "thành viên tại `started_at`". | 1.2 điểm vào, 2.2 bước lưu | (đề xuất) Tạo INVITED tại `started_at − lobby_open_min` cho thành viên đã đồng ý; chốt lại danh sách tại `started_at`. |
| DQ-F02 | Thành viên vào nhóm / đồng ý lại sau khi phiên đã SCHEDULED, hoặc chưa đồng ý lại (BR-71) — có INVITED không, hiện gì ở V-03? | 1.2, 2.1 | (đề xuất) Có INVITED nhưng vào bị chặn bởi BR-06; nếu chưa đồng ý lại thì đến hạn vào → ABSENT. |
| DQ-F03 | BR-64 "tại `started_at` server hỏi trạng thái tiền cảnh" — `05` §2 không có sự kiện S→C/C→S cho việc hỏi này, cũng không nói hết bao lâu thì coi là "chưa báo". | 2.2 bước hỏi tiền cảnh | (đề xuất) Server dùng trạng thái cuối nhận được trong COUNTDOWN (`left_app`/`returned`), không hỏi đồng bộ; thêm sự kiện vào `05` §2. |
| DQ-F04 | MVP 1 instance giữ trạng thái nóng trong bộ nhớ (05 §3.1). Khi server khởi động lại, ai/khi nào đặt CANCELLED và gửi `SESSION_CANCELLED_OUTAGE`? Danh sách người EXITED trước sự cố lấy từ đâu nếu chưa ghi xuống RDS? | 2.8 | (đề xuất) Ghi EXITED và `forfeited` xuống DB ngay khi xảy ra (không đợi `ends_at`); lúc khởi động quét phiên COUNTDOWN/ACTIVE còn dở → hủy. |
| DQ-F05 | DISCONNECTED từ PAUSED mà hạn tạm dừng hết trong lúc mất mạng (BR-20 "hạn tạm dừng vẫn chạy"): nối lại thì về PAUSED, FOCUSING hay GRACE? | 1.2 cạnh DISCONNECTED → PAUSED | (đề xuất) Áp BR-18 tại lúc nối lại: đang ở app → FOCUSING, không → GRACE không trừ lượt. |
| DQ-F06 | WAITING mất kết nối (Q-153): không có heartbeat bắt buộc ở WAITING (BR-05 không ghi sự kiện) nên server phát hiện bằng gì? Nối lại sau `started_at` nhưng trong hạn vào muộn thì ABSENT hay vào muộn? | 1.2 cạnh WAITING → ABSENT | (đề xuất) Chỉ dùng socket đóng; nếu US-03.11 đã làm thì xử lý như INVITED vào muộn. |
| DQ-F07 | Spike đề xuất `lock_reclassified` (tín hiệu khóa đến trong GRACE → FOCUSING, hoàn lượt) — chưa có BR, có rủi ro lách luật. | 1.2, 2.5 (không vẽ) | Chờ kết quả S-12; nếu cần thì tạo Q- và BR mới (README §7). |
| DQ-F08 | Tên sự kiện spike lệch `05` §2: spike dùng `member:join`, `session:end`, `clock:ping`; `05` dùng `session:join`, không có `session:end`. Spike phát `MEMBER_EXITED` cho **mọi** client, chưa phân kênh BR-82. | 2.2, 2.4 | Chuẩn hóa theo `05` §2 khi viết backend T-02; `clock:ping` thêm vào `05` §2 nếu giữ. |
| DQ-F09 | Hủy phiên SCHEDULED (BR-29, BR-80, BR-108) "thông báo thành viên" — không có mã sự kiện chuẩn (chỉ có `SESSION_CANCELLED_OUTAGE` cho sự cố). Kênh push hay chỉ hộp thông báo? | 1.1, 1.3 | (đề xuất) Thêm mã `SESSION_CANCELLED_BY_OWNER`, push + hộp thông báo cho thành viên. |
| DQ-F10 | `05` §6 chỉ có K-01…K-16, không có ca cho nhóm, khiếu nại, báo cáo tháng, đếm ngược/phòng chờ, tạm dừng (BR-16…BR-18), thông báo hủy sự cố khác bản EXITED. | Bảng mục 3 có "—" | (đề xuất) Bổ sung K-17+ cho PAUSED, BR-64, BR-30, máy trạng thái khiếu nại, BR-101 (idempotent báo cáo), BR-123. |
| DQ-F11 | `SESSION_RESULT` push (BR-91): gửi cho mọi người có trạng thái trong phiên hay chỉ người không mở app? Người ABSENT/VOID có nhận không? | 2.9 | (đề xuất) Socket cho người đang mở app; push cho người có trạng thái COMPLETED/EXITED/LOST không mở app; ABSENT không push. |
| DQ-F12 | Thứ tự trong transaction cuối phiên với DISCONNECTED chưa chốt tại `ends_at` (§3 #7): phải chờ tối đa 10s rồi mới chốt Coins cả phiên, hay chốt từng người? | 2.9 | (đề xuất) Chốt phiên tại `ends_at + disconnect_hold_s` khi còn DISCONNECTED; ghi rõ trong NFR-07. |
| DQ-F13 | Chi tiết phiên chủ nhóm (BR-116) khi phiên ACTIVE: số PAUSED kèm lý do có được thấy trước `ends_at` không (BR-116 liệt kê chung, §4 nói "chỉ thấy ở chi tiết phiên")? | 2.12 | (đề xuất) PAUSED/LOST/vào muộn chỉ hiện sau `ends_at`; trong phiên chỉ có trạng thái phiên + EXITED. |

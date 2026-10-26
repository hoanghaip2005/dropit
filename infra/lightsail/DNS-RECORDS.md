# Bản ghi DNS tại Tino

App: A `dropit.tutty-lab-demo.com` -> `54.254.61.215`, TTL300. Nếu record đã dùng cho dịch vụ khác, không ghi đè, chọn hostname khác và đổi config.

SES DKIM cho domain thông báo, tùy chọn sau:

| Type | Name | Target |
|---|---|---|
| CNAME | pgxbu4kt2eybto44ceactnf75iiybd5n._domainkey.notify.dropit.tutty-lab-demo.com | pgxbu4kt2eybto44ceactnf75iiybd5n.dkim.amazonses.com |
| CNAME | 6vcbx3a6f6jxj2fduxj66ytbjua4nkcj._domainkey.notify.dropit.tutty-lab-demo.com | 6vcbx3a6f6jxj2fduxj66ytbjua4nkcj.dkim.amazonses.com |
| CNAME | edqyxrhr5whnncfw4bwhytz77pl33beq._domainkey.notify.dropit.tutty-lab-demo.com | edqyxrhr5whnncfw4bwhytz77pl33beq.dkim.amazonses.com |

Các token DKIM là public DNS, không phải private key. Nếu giao diện tự thêm domain, nhập phần name tương đối để tránh lặp domain. Không thay MX/mail domain đang dùng. SES vẫn sandbox; DKIM success không tự cho gửi production hoặc triển khai sender.

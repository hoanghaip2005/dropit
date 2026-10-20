// Lỗi nghiệp vụ dạng RFC 9457 problem+json + `code` ổn định (03-api-socket P10).
export class AppError extends Error {
  constructor(
    public status: number,
    public code: string,
    public detail: string,
    public br?: string,
  ) {
    super(detail);
  }
  toProblem(requestId?: string) {
    return {
      type: `https://api.dropit.example/errors/${this.code.toLowerCase().replace(/_/g, '-')}`,
      title: this.code,
      status: this.status,
      code: this.code,
      detail: this.detail,
      ...(this.br ? { br: this.br } : {}),
      ...(requestId ? { request_id: requestId } : {}),
    };
  }
}

export const E = {
  validation: (detail: string) => new AppError(400, 'VALIDATION_FAILED', detail),
  unauth: (detail = 'Thiếu hoặc sai token') => new AppError(401, 'UNAUTHENTICATED', detail),
  expired: () => new AppError(401, 'TOKEN_EXPIRED', 'Token đã hết hạn'),
  forbiddenGroup: () => new AppError(403, 'FORBIDDEN_GROUP', 'Bạn không thuộc nhóm này', 'NFR-11'),
  notOwner: () => new AppError(403, 'NOT_GROUP_OWNER', 'Chỉ chủ nhóm được làm việc này', 'D-10'),
  notFound: (what = 'Không tìm thấy') => new AppError(404, 'NOT_FOUND', what),
};

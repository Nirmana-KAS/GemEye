"""Errors with a machine-readable code: {"status": "error", "code", "detail"}."""


class ApiError(Exception):
    def __init__(self, status_code, code, detail):
        super().__init__(code)
        self.status_code, self.code, self.detail = status_code, code, detail

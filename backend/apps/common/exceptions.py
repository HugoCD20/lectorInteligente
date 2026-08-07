class APIError(Exception):
    """Error controlado de la API con formato de respuesta consistente."""

    def __init__(self, message, errors=None, status_code=400):
        self.message = message
        self.errors = errors
        self.status_code = status_code
        super().__init__(message)

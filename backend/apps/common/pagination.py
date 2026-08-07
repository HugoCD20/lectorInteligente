from rest_framework.pagination import PageNumberPagination


class StandardPagination(PageNumberPagination):
    """Paginación consistente con el formato de respuestas del proyecto.

    La respuesta incluye metadatos (count, page, page_size, next, previous)
    y la lista de resultados en el campo ``results``.
    """

    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data):
        return {
            "count": self.page.paginator.count,
            "page": self.page.number,
            "page_size": self.get_page_size(self.request),
            "next": self.get_next_link(),
            "previous": self.get_previous_link(),
            "results": data,
        }

import posixpath
import re
import zipfile
import xml.etree.ElementTree as ET

from pypdf import PdfReader

from apps.common.exceptions import APIError

_BLOCK_TAGS = {
    "p",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "li",
    "div",
    "blockquote",
    "td",
    "th",
    "dd",
    "dt",
}

MAX_EXTRACTED_PAGES = 10000
MAX_EPUB_UNCOMPRESSED_BYTES = 200 * 1024 * 1024


def extract_pages(document):
    """Devuelve el texto de cada página del documento."""
    extension = (document.extension or "").lower()
    try:
        if extension == "pdf":
            return extract_pdf_pages(document.file)
        if extension == "epub":
            return extract_epub_pages(document.file)
    except APIError:
        raise
    except Exception as exc:
        raise APIError("No se pudo leer el contenido del documento.") from exc
    raise APIError(f"Formato no soportado para traducción: {extension}.")


def extract_pdf_pages(file_obj):
    """Extrae el texto de cada página de un PDF, limitando el total extraído."""
    reader = PdfReader(file_obj)
    pages = []
    for page in reader.pages:
        if len(pages) >= MAX_EXTRACTED_PAGES:
            raise APIError(
                f"El documento supera el límite de {MAX_EXTRACTED_PAGES} páginas."
            )
        pages.append(normalize_text(page.extract_text() or ""))
    return pages


def extract_epub_pages(file_obj):
    """Extrae el texto de un EPUB tratando cada elemento del spine como página.

    Antes de leer el contenido se valida el tamaño total descomprimido para
    prevenir bombas zip que agoten la memoria durante la extracción.
    """
    with zipfile.ZipFile(file_obj) as archive:
        if sum(info.file_size for info in archive.infolist()) > MAX_EPUB_UNCOMPRESSED_BYTES:
            raise APIError(
                "El EPUB supera el límite de contenido descomprimido permitido."
            )
        opf_path = _container_rootfile(archive.read("META-INF/container.xml"))
        manifest, spine = _parse_opf(archive.read(opf_path))
        base_dir = posixpath.dirname(opf_path)

        pages = []
        for itemref in spine:
            if len(pages) >= MAX_EXTRACTED_PAGES:
                raise APIError(
                    f"El documento supera el límite de {MAX_EXTRACTED_PAGES} páginas."
                )
            href = manifest.get(itemref)
            if href is None:
                continue
            try:
                content = archive.read(posixpath.join(base_dir, href))
            except KeyError:
                continue
            pages.append(normalize_text(_xhtml_to_text(content)))
    return pages


def _container_rootfile(container_bytes):
    root = ET.fromstring(container_bytes)
    for rootfile in root.iter():
        if _localname(rootfile.tag) == "rootfile":
            path = rootfile.attrib.get("full-path")
            if path:
                return path
    raise APIError("El EPUB no contiene una estructura válida.")


def _parse_opf(opf_bytes):
    root = ET.fromstring(opf_bytes)
    manifest = {}
    spine = []
    for elem in root.iter():
        tag = _localname(elem.tag)
        if tag == "item":
            manifest[elem.attrib.get("id")] = elem.attrib.get("href")
        elif tag == "itemref":
            spine.append(elem.attrib.get("idref"))
    return manifest, spine


def _xhtml_to_text(html_bytes):
    root = ET.fromstring(html_bytes)
    blocks = []
    for elem in root.iter():
        if _localname(elem.tag) in _BLOCK_TAGS:
            text = "".join(elem.itertext()).strip()
            if text:
                blocks.append(text)
    return "\n\n".join(blocks)


def _localname(tag):
    return tag.rsplit("}", 1)[-1]


def normalize_text(text):
    """Normaliza el texto de una página conservando los saltos de línea."""
    lines = []
    for line in text.splitlines():
        line = re.sub(r"\s+", " ", line).strip()
        if line:
            lines.append(line)
    return "\n".join(lines)

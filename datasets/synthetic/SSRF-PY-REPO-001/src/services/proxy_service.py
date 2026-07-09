from utils.http_utils import get_url


class ProxyService:
    def fetch_remote(self, url: str) -> str | None:
        return get_url(url)

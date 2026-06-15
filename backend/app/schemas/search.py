from pydantic import BaseModel
from typing import Optional, List


class SearchRequest(BaseModel):
    query: str
    search_type: Optional[str] = None


class SearchResult(BaseModel):
    type: str
    id: int
    title: str
    subtitle: Optional[str] = None


class SearchResponse(BaseModel):
    results: List[SearchResult]
    total_count: int

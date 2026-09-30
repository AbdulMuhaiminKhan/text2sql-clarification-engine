"""Pydantic contracts for everything the LLM returns."""
from typing import Literal, Optional
from pydantic import BaseModel, Field, model_validator


class Clarification(BaseModel):
    question: str = Field(description="One short question for the user")
    options: list[str] = Field(min_length=2, max_length=4)


class Analysis(BaseModel):
    status: Literal["ready", "clarification_needed"]
    sql: Optional[str] = None
    clarifications: list[Clarification] = Field(default_factory=list)
    reasoning: str = ""

    @model_validator(mode="after")
    def check_consistency(self):
        if self.status == "ready" and not (self.sql and self.sql.strip()):
            raise ValueError("status=ready requires sql")
        if self.status == "clarification_needed" and not self.clarifications:
            raise ValueError("status=clarification_needed requires clarifications")
        return self


class SQLFix(BaseModel):
    sql: str

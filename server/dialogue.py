"""Per-session conversational state for the live avatar."""

from dataclasses import dataclass, field
from threading import Lock


@dataclass
class Dialogue:
    persona: str = "友好、自然、简短地交流。"
    language: str = "zh-CN"
    voice: str = ""
    history: list[dict] = field(default_factory=list)
    turn: int = 0
    lock: Lock = field(default_factory=Lock)

    def configure(self, persona: str = "", language: str = "", voice: str = ""):
        with self.lock:
            if persona.strip():
                self.persona = persona.strip()
            if language.strip():
                self.language = language.strip()
            if voice.strip():
                self.voice = voice.strip()

    def system_prompt(self) -> str:
        return (
            f"你正在扮演以下数字人角色：{self.persona}\n"
            f"本轮优先使用 {self.language} 回复。回答自然、口语化且简洁。"
        )

    def begin(self, message: str, resume: bool) -> tuple[list[dict], int]:
        with self.lock:
            self.turn += 1
            if resume:
                message = "请从刚才被打断的位置继续回答；不要重复已经说过的内容。"
                prompt_history = [*self.history[-12:], {"role": "user", "content": message}]
            else:
                self.history.append({"role": "user", "content": message})
                prompt_history = self.history[-12:]
            return [{"role": "system", "content": self.system_prompt()}, *prompt_history], self.turn

    def interrupt(self):
        with self.lock:
            self.turn += 1

    def is_current(self, turn: int) -> bool:
        with self.lock:
            return self.turn == turn

    def finish(self, text: str):
        if not text:
            return
        with self.lock:
            self.history.append({"role": "assistant", "content": text})
            self.history = self.history[-12:]

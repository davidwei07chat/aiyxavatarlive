from server.dialogue import Dialogue


def test_dialogue_remembers_persona_and_resumes():
    dialogue = Dialogue()
    dialogue.configure("严谨的上海导游", "zh-CN", "zh-CN-XiaoxiaoNeural")
    messages, turn = dialogue.begin("介绍外滩", False)
    assert "上海导游" in messages[0]["content"]
    assert messages[-1]["content"] == "介绍外滩"
    dialogue.finish("外滩位于黄浦江畔。")
    resumed, resumed_turn = dialogue.begin("", True)
    assert "继续回答" in resumed[-1]["content"]
    assert not dialogue.is_current(turn)
    assert dialogue.is_current(resumed_turn)


if __name__ == "__main__":
    test_dialogue_remembers_persona_and_resumes()

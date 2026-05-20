from pathlib import Path
import os

def write_config_yaml(data: dict[str, str]) -> None:
    """Write Hermes config.yaml"""

    model = data.get("LLM_MODEL", "qwen3:latest")

    provider = data.get(
        "HERMES_INFERENCE_PROVIDER",
        os.environ.get("HERMES_INFERENCE_PROVIDER", "ollama")
    )

    config_path = Path(HERMES_HOME) / "config.yaml"
    config_path.parent.mkdir(parents=True, exist_ok=True)

    config_path.write_text(f"""
model:
  default: "{model}"
  provider: "{provider}"

auxiliary:
  vision:
    provider: "ollama"
    model: "{model}"
    timeout: 120

terminal:
  backend: "local"
  timeout: 60
  cwd: "/tmp"

agent:
  max_iterations: 50

data_dir: "{HERMES_HOME}"
""")

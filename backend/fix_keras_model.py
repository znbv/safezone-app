import json
import zipfile
import shutil
from pathlib import Path


OLD_MODEL = Path("TCN_model.keras")
NEW_MODEL = Path("TCN_model_fixed.keras")

BAD_KEYS = {
    "renorm",
    "renorm_clipping",
    "renorm_momentum",
}


def clean_config(obj):
    if isinstance(obj, dict):
        for key in list(obj.keys()):
            if key in BAD_KEYS:
                obj.pop(key)
            else:
                clean_config(obj[key])
    elif isinstance(obj, list):
        for item in obj:
            clean_config(item)


def fix_keras_model(old_path, new_path):
    if not old_path.exists():
        raise FileNotFoundError(f"Could not find {old_path}")

    shutil.copy(old_path, new_path)

    with zipfile.ZipFile(new_path, "r") as zin:
        files = {name: zin.read(name) for name in zin.namelist()}

    config = json.loads(files["config.json"].decode("utf-8"))
    clean_config(config)
    files["config.json"] = json.dumps(config).encode("utf-8")

    with zipfile.ZipFile(new_path, "w", compression=zipfile.ZIP_DEFLATED) as zout:
        for name, data in files.items():
            zout.writestr(name, data)

    print(f"Fixed model saved as: {new_path}")


if __name__ == "__main__":
    fix_keras_model(OLD_MODEL, NEW_MODEL)
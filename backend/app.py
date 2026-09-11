from flask import Flask, request, jsonify
import os
import numpy as np
import base64
from SafeZone_Integration_Final import run_safezone_integration

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


def convert(obj):
    if isinstance(obj, np.generic):
        return obj.item()
    if isinstance(obj, np.ndarray):
        return obj.tolist()
    return obj


def clean_dict(data):
    if isinstance(data, dict):
        return {k: clean_dict(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [clean_dict(i) for i in data]
    else:
        return convert(data)


@app.route("/", methods=["GET"])
def home():
    return "SafeZone API is running"


@app.route("/analyze", methods=["POST"])
def analyze_video():

    if "video" not in request.files:
        return jsonify({"error": "No video uploaded"}), 400

    video = request.files["video"]

    video_path = os.path.join(UPLOAD_FOLDER, video.filename)
    video.save(video_path)

    result = run_safezone_integration(video_path)

    # Optional: attach hazard image
    hazard_image_b64 = None
    hazard_info = result.get("hazard_detection")

    if hazard_info and hazard_info.get("hazard_detected"):
        hazards = hazard_info.get("detected_hazards", [])
        if hazards:
            img_path = hazards[0].get("saved_image")
            if img_path and os.path.exists(img_path):
                with open(img_path, "rb") as f:
                    hazard_image_b64 = base64.b64encode(f.read()).decode("utf-8")

    result["hazard_image_base64"] = hazard_image_b64

    return jsonify(clean_dict(result))


if __name__ == "__main__":
    app.run(debug=False, use_reloader=False, host="0.0.0.0", port=5000)
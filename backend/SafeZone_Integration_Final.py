#!/usr/bin/env python
# coding: utf-8

# ### 1. Imports and Environment Setup

# In[1]:


import os
import cv2
import torch
import numpy as np
import tensorflow as tf

from pathlib import Path
from PIL import Image

import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from tensorflow.keras.models import load_model
from tensorflow.keras.layers import BatchNormalization

from ultralytics import YOLO

class CompatibleBatchNormalization(BatchNormalization):
    def __init__(
        self,
        *args,
        renorm=None,
        renorm_clipping=None,
        renorm_momentum=None,
        **kwargs
    ):
        super().__init__(*args, **kwargs)

try:
    tf.config.set_visible_devices([], "GPU")
except Exception:
    pass


# ### 2. Paths Configuration

# In[2]:


CHILDSUN_MODEL_PATH = "swin_transformer_model.pth"
CHILDACT_MODEL_PATH = "TCN_model_fixed.keras"
CHILD_DETECTOR_MODEL_PATH = "child_detector.keras"

# Object Detection
YOLO_OBJECT_MODEL = "yolo11s.pt"

# Pose Estimation
YOLO_POSE_MODEL = "yolo11l-pose.pt"

VIDEO_PATH = "test_video.mp4"


# ### 3. General Configuration

# In[3]:


DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

IMG_SIZE = 224

MAX_LEN = 100
NUM_JOINTS = 17
NUM_COORDS = 2
NUM_FEATURES = NUM_JOINTS * NUM_COORDS

CHILDSUN_CLASSES = ["Safe", "Unsafe"]

CHILDACT_CLASSES = ["box", "clap", "go", "jog", "run", "walk", "wave"]

ACTION_GROUPS = {
    "run": "movement",
    "walk": "movement",
    "jog": "movement",
    "go": "movement",
    "clap": "gesture",
    "wave": "gesture",
    "box": "gesture",
}

SUPPORTED_HAZARD_OBJECTS = [
    "knife",
    "fork",
    "scissors"
]


# ### 4. ChildSUn Preprocessing

# In[4]:


childsun_transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.CenterCrop((IMG_SIZE, IMG_SIZE)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])


# ### 5. Load ChildSUn Model - Swin Transformer

# In[5]:


def load_childsun_model(model_path):
    """
    Load the trained ChildSUn Swin Transformer model.
    Output classes:
    0 = Safe
    1 = Unsafe
    """

    weights = models.Swin_T_Weights.IMAGENET1K_V1
    model = models.swin_t(weights=weights)

    num_features = model.head.in_features
    model.head = nn.Linear(num_features, 2)

    checkpoint = torch.load(model_path, map_location=DEVICE)
    model.load_state_dict(checkpoint["model_state_dict"])

    model = model.to(DEVICE)
    model.eval()

    print("ChildSUn Swin Transformer loaded successfully.")
    return model


# ### 6. Load ChildACT Model - TCN

# In[6]:


def load_childact_model(model_path):
    model = load_model(
        model_path,
        compile=False,
        safe_mode=False,
        custom_objects={
            "BatchNormalization": CompatibleBatchNormalization
        }
    )

    print("ChildACT TCN model loaded successfully.")
    return model


# ### 7. Load Child Detector Model

# In[7]:


def load_child_detector_model(model_path):
    model = load_model(
        model_path,
        compile=False,
        safe_mode=False,
        custom_objects={
            "BatchNormalization": CompatibleBatchNormalization
        }
    )

    print("Child Detector model loaded successfully.")
    return model

# ### 8. Load YOLO Models

# In[8]:


def load_yolo_object_model(model_name):
    model = YOLO(model_name)
    print("YOLO Object Detection model loaded successfully.")
    return model

def load_yolo_pose_model(model_name):
    model = YOLO(model_name)
    print("YOLO Pose model loaded successfully.")
    return model


# ### 9. ChildSUn Prediction on a Single Frame

# In[9]:


def predict_childsun_frame(model, frame):
    """
    Predict whether a video frame is Safe or Unsafe.
    """

    # Convert OpenCV BGR frame to RGB PIL image
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    image = Image.fromarray(frame_rgb)

    input_tensor = childsun_transform(image).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        outputs = model(input_tensor)
        probs = F.softmax(outputs, dim=1)[0]
        pred_idx = int(torch.argmax(probs).item())

    return {
        "prediction": CHILDSUN_CLASSES[pred_idx],
        "confidence": float(probs[pred_idx]),
        "unsafe_confidence": float(probs[1]),
        "safe_confidence": float(probs[0]),
        "probabilities": {
            CHILDSUN_CLASSES[i]: float(probs[i])
            for i in range(len(CHILDSUN_CLASSES))
        }
    }


# ### 10. Select Representative Frames for ChildSUn

# In[10]:


def sample_frames_for_childsun(video_path, num_frames=10):
    """
    Sample representative frames from the video for ChildSUn.
    Instead of classifying every frame, this reduces computation.
    """

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        raise IOError(f"Cannot open video: {video_path}")

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    if total_frames == 0:
        raise ValueError("Video contains no frames.")

    frame_indices = np.linspace(
        0,
        total_frames - 1,
        num=min(num_frames, total_frames),
        dtype=int
    )

    sampled_frames = []

    for idx in frame_indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ret, frame = cap.read()

        if ret:
            sampled_frames.append(frame)

    cap.release()

    return sampled_frames


# ### 11. Aggregate ChildSUn Predictions

# In[11]:


def predict_childsun_video(model, video_path, num_frames=10):
    frames = sample_frames_for_childsun(video_path, num_frames=num_frames)

    frame_results = []

    for frame in frames:
        result = predict_childsun_frame(model, frame)
        frame_results.append(result)

    unsafe_confidences = [
        r["probabilities"]["Unsafe"]
        for r in frame_results
    ]

    max_unsafe_conf = max(unsafe_confidences)
    avg_unsafe_conf = float(np.mean(unsafe_confidences))

    unsafe_frames = sum(
        1 for c in unsafe_confidences
        if c >= 0.60
    )

    unsafe_ratio = unsafe_frames / len(unsafe_confidences)

    if unsafe_ratio >= 0.50:
        final_prediction = "Unsafe"
        final_confidence = max_unsafe_conf
    else:
        final_prediction = "Safe"
        final_confidence = 1.0 - avg_unsafe_conf

    return {
        "prediction": final_prediction,
        "confidence": float(final_confidence),
        "max_unsafe_confidence": float(max_unsafe_conf),
        "avg_unsafe_confidence": float(avg_unsafe_conf),
        "unsafe_frames": unsafe_frames,
        "unsafe_ratio": float(unsafe_ratio),
        "frame_results": frame_results
    }


# ### 12. YOLO Pose: Extract COCO-17 Keypoints from Video

# In[12]:


def extract_yolo_coco17(video_path, yolo_model):
    """
    Extract COCO-17 pose keypoints from video using YOLO pose.

    Output shape:
    (T, 17, 3)

    where:
    T  = number of frames
    17 = COCO keypoints
    3  = x, y, confidence
    """

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        raise IOError(f"Cannot open video: {video_path}")

    frames_keypoints = []

    frames_read = 0
    frames_with_person = 0
    multi_person_frames = 0

    while True:
        ret, frame = cap.read()

        if not ret:
            break

        frames_read += 1

        results = yolo_model.predict(frame, verbose=False)

        if len(results) == 0:
            frames_keypoints.append(np.zeros((17, 3), dtype=np.float32))
            continue

        result = results[0]

        if result.keypoints is None or len(result.keypoints.xy) == 0:
            frames_keypoints.append(np.zeros((17, 3), dtype=np.float32))
            continue

        if len(result.keypoints.xy) > 1:
            multi_person_frames += 1

        kp_xy = result.keypoints.xy.cpu().numpy()
        kp_conf = result.keypoints.conf.cpu().numpy()

        # Select the person with the highest total keypoint confidence
        scores = kp_conf.sum(axis=1)
        best_idx = int(np.argmax(scores))

        best_person = np.concatenate(
            [kp_xy[best_idx], kp_conf[best_idx, :, None]],
            axis=1
        ).astype(np.float32)

        frames_keypoints.append(best_person)
        frames_with_person += 1

    cap.release()

    coco17_sequence = np.asarray(frames_keypoints, dtype=np.float32)

    meta = {
        "frames_read": frames_read,
        "frames_with_person": frames_with_person,
        "multi_person_frames": multi_person_frames,
        "shape": coco17_sequence.shape
    }

    if frames_with_person == 0:
        print("Warning: No person detected in the video.")

    return coco17_sequence, meta


# ### 13. ChildACT Preprocessing

# In[13]:


TORSO_JOINTS = [5, 6, 11, 12]
ANCHOR_CANDIDATES = [11, 12, 5, 6, 0]


def choose_anchor_xy(pose_xy, pose_conf, conf_thr=0.05):
    """
    Choose a stable anchor point for pose normalization.
    Prefer torso joints, then fallback to other visible joints.
    """

    torso_valid = [
        j for j in TORSO_JOINTS
        if j < len(pose_conf) and pose_conf[j] > conf_thr
    ]

    if len(torso_valid) >= 2:
        return pose_xy[torso_valid].mean(axis=0)

    for j in ANCHOR_CANDIDATES:
        if j < len(pose_conf) and pose_conf[j] > conf_thr:
            return pose_xy[j].copy()

    valid = np.where(pose_conf > conf_thr)[0]

    if len(valid) > 0:
        return pose_xy[int(valid[np.argmax(pose_conf[valid])])].copy()

    return None


def normalize_pose_sequence_xy(seq_xy, seq_conf, conf_thr=0.05):
    """
    Normalize pose coordinates by centering them around the body anchor
    and scaling them to a stable range.
    """

    seq_xy = np.asarray(seq_xy, dtype=np.float32).copy()
    seq_conf = np.asarray(seq_conf, dtype=np.float32)

    output = np.zeros_like(seq_xy, dtype=np.float32)
    xy_all = []

    for t in range(len(seq_xy)):
        xy = seq_xy[t].copy()
        conf = seq_conf[t]

        anchor_xy = choose_anchor_xy(xy, conf, conf_thr=conf_thr)

        if anchor_xy is None:
            continue

        valid = conf > conf_thr

        xy[valid] = xy[valid] - anchor_xy
        xy[~valid] = 0.0

        output[t] = xy

        if np.any(valid):
            xy_all.append(np.abs(xy[valid]))

    if len(xy_all) > 0:
        xy_all = np.concatenate(xy_all, axis=0)
        scale = np.max(xy_all)

        if scale > 1e-6:
            output = output / scale

    return output


def uniform_sample_sequence(sequence, max_len=100):
    """
    Uniformly sample or pad the pose sequence to a fixed length.
    """

    sequence = np.asarray(sequence, dtype=np.float32)

    if len(sequence) == 0:
        return np.zeros((max_len, NUM_JOINTS, NUM_COORDS), dtype=np.float32)

    if len(sequence) >= max_len:
        indices = np.linspace(0, len(sequence) - 1, max_len, dtype=int)
        sampled = sequence[indices]
    else:
        sampled = np.zeros((max_len, NUM_JOINTS, NUM_COORDS), dtype=np.float32)
        sampled[:len(sequence)] = sequence

    return sampled


def make_childact_tcn_input(coco17_xyc):
    """
    Convert YOLO COCO-17 output into TCN input.

    Input:
    coco17_xyc shape: (T, 17, 3)

    Output:
    TCN input shape: (1, 100, 34)
    """

    coco17_xyc = np.asarray(coco17_xyc, dtype=np.float32)

    seq_xy = coco17_xyc[:, :, :2]
    seq_conf = coco17_xyc[:, :, 2]

    normalized_xy = normalize_pose_sequence_xy(seq_xy, seq_conf)

    sampled_xy = uniform_sample_sequence(normalized_xy, max_len=MAX_LEN)

    x_flat = sampled_xy.reshape(MAX_LEN, NUM_FEATURES)

    childact_input = np.expand_dims(x_flat, axis=0).astype(np.float32)

    return childact_input


# ### 14. ChildACT Prediction

# In[14]:


def predict_childact_video(tcn_model, yolo_model, video_path, confidence_threshold=0.80):
    """
    Extract pose keypoints using YOLO, then classify action using ChildACT TCN.
    """

    coco17_xyc, meta = extract_yolo_coco17(video_path, yolo_model)

    pose_coverage = meta["frames_with_person"] / max(meta["frames_read"], 1)

    if pose_coverage < 0.20:

        return {
            "prediction": "unknown",
            "confidence": 0.0,
            "likely_action_type": "uncertain",
            "probabilities": {},
            "pose_meta": meta
        }

    childact_input = make_childact_tcn_input(coco17_xyc)

    probs = tcn_model.predict(childact_input, verbose=0)[0]

    pred_idx = int(np.argmax(probs))
    pred_class = CHILDACT_CLASSES[pred_idx]
    confidence = float(probs[pred_idx])

    if confidence < confidence_threshold:
        likely_action_type = "uncertain"
    else:
        likely_action_type = ACTION_GROUPS.get(pred_class, "unknown")

    return {
        "prediction": pred_class,
        "confidence": confidence,
        "likely_action_type": likely_action_type,
        "probabilities": {
            CHILDACT_CLASSES[i]: float(probs[i])
            for i in range(len(CHILDACT_CLASSES))
        },
        "pose_meta": meta
    }


# ### 15. Child Detection from Video

# In[15]:


def preprocess_child_crop(crop):

    crop_rgb = cv2.cvtColor(crop, cv2.COLOR_BGR2RGB)
    crop_resized = cv2.resize(crop_rgb, (224, 224))
    crop_array = np.expand_dims(crop_resized, axis=0)

    return crop_array


def predict_child_from_video(
    child_detector_model,
    video_path,
    num_frames=10
):

    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        raise IOError(f"Cannot open video: {video_path}")

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    frame_indices = np.linspace(
        0,
        max(total_frames - 1, 0),
        num=min(num_frames, max(total_frames, 1)),
        dtype=int
    )

    predictions = []

    for idx in frame_indices:

        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)

        ret, frame = cap.read()

        if not ret:
            continue

        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame_resized = cv2.resize(frame_rgb, (224, 224))

        input_array = np.expand_dims(frame_resized, axis=0)

        pred = child_detector_model.predict(
            input_array,
            verbose=0
        )[0][0]

        predictions.append(float(pred))

    cap.release()

    if len(predictions) == 0:
        return {
            "child_detected": False,
            "confidence": 0.0
        }

    avg_confidence = float(np.mean(predictions))

    return {
        "child_detected": avg_confidence >= 0.50,
        "confidence": avg_confidence
    }


# ### 16. Decision-Level Fusion

# In[16]:

def final_decision_logic(childsun_result, childact_result, child_result, hazard_result):
    child_detected = child_result["child_detected"]

    safety_label = childsun_result["prediction"]
    safety_conf = childsun_result["confidence"]

    unsafe_ratio = childsun_result.get("unsafe_ratio", 0.0)
    unsafe_frames = childsun_result.get("unsafe_frames", 0)
    max_unsafe_conf = childsun_result.get("max_unsafe_confidence", 0.0)

    action_name = childact_result["prediction"]
    action_conf = childact_result["confidence"]
    action_type = childact_result["likely_action_type"]
    action_percent = round(action_conf * 100, 2)

    hazard_detected = hazard_result["hazard_detected"]
    detected_hazards = hazard_result["detected_hazards"]

    # 1. No child detected
    if not child_detected:
        return {
            "final_status": "NO ALERT",
            "risk_level": "Low",
            "reason": "No child was detected in the video.",
            "recommended_action": "No alert is sent."
        }

    # Separate near and far hazards
    near_hazards = [
        h for h in detected_hazards
        if h.get("is_near_child") == True
    ]

    far_hazards = [
        h for h in detected_hazards
        if h.get("is_near_child") == False
    ]

    # 2. Hazard near child = ALERT
    if hazard_detected and len(near_hazards) > 0:
        hazard_names = list(set([h["object"] for h in near_hazards]))
        proximity = near_hazards[0].get("proximity", "Near")

        return {
            "final_status": "ALERT",
            "risk_level": "High",
            "reason": f"Hazardous object detected near the child: {', '.join(hazard_names)}. Proximity: {proximity}.",
            "recommended_action": "Send an alert notification to the parents' device immediately."
        }

    # 3. Hazard far from child = MONITOR
    if hazard_detected and len(far_hazards) > 0:
        hazard_names = list(set([h["object"] for h in far_hazards]))
        proximity = far_hazards[0].get("proximity", "Far")

        return {
            "final_status": "MONITOR",
            "risk_level": "Medium",
            "reason": f"Hazardous object detected in the scene, but it is not near the child: {', '.join(hazard_names)}. Proximity: {proximity}.",
            "recommended_action": "Continue monitoring the scene."
        }

    # 4. Unsafe scene + high-confidence movement = ALERT
    if unsafe_ratio >= 0.30 and action_type == "movement" and action_conf >= 0.70:
        return {
            "final_status": "ALERT",
            "risk_level": "High",
            "reason": f"High-confidence child movement detected: {action_name} ({action_percent}%) together with unsafe scene evidence.",
            "recommended_action": "Send an alert notification to the parents' device immediately."
        }

    # 5. Strong unsafe scene alone = ALERT
    if safety_label == "Unsafe" and unsafe_ratio >= 0.50 and safety_conf >= 0.60:
        return {
            "final_status": "ALERT",
            "risk_level": "High",
            "reason": f"ChildSUn classified the child scene as unsafe across {unsafe_frames} frames.",
            "recommended_action": "Send an alert notification to the parents' device immediately."
        }

    # 6. Partial unsafe scene evidence = MONITOR
    if unsafe_ratio > 0 and unsafe_ratio < 0.30:
        return {
            "final_status": "MONITOR",
            "risk_level": "Medium",
            "reason": "Possible unsafe evidence was detected by ChildSUn, but it was not strong enough for a high-risk alert.",
            "recommended_action": "Continue monitoring and send an alert if the unsafe condition persists."
        }

    # 7. High-confidence movement in safe scene = MONITOR
    if action_type == "movement" and action_conf >= 0.80:
        return {
            "final_status": "MONITOR",
            "risk_level": "Medium",
            "reason": f"High-confidence child movement detected: {action_name} ({action_percent}%), but no hazardous object or unsafe scene was detected.",
            "recommended_action": "Continue monitoring without sending an alert."
        }

    # 8. High-confidence gesture = NO ALERT
    if action_type == "gesture" and action_conf >= 0.80:
        return {
            "final_status": "NO ALERT",
            "risk_level": "Low",
            "reason": f"Child gesture detected: {action_name} ({action_percent}%), but no unsafe situation was found.",
            "recommended_action": "No alert is sent to the parents' device."
        }

    # 9. Low-confidence action = WAIT
    if action_type == "uncertain" or action_conf < 0.70:
        return {
            "final_status": "WAIT",
            "risk_level": "Unknown",
            "reason": f"ChildACT confidence is low for action prediction: {action_name} ({action_percent}%).",
            "recommended_action": "Wait for more frames before sending any alert."
        }

    # 10. Default safe result
    return {
        "final_status": "NO ALERT",
        "risk_level": "Low",
        "reason": "Child detected, but no unsafe situation was found.",
        "recommended_action": "No alert is sent to the parents' device."
    }

# ### 17. Hazard Object Detection

# In[17]:


def detect_hazard_objects(
    video_path,
    yolo_object_model,
    yolo_pose_model,
    num_frames=10,
    conf_threshold=0.15,
    near_threshold=0.35,
    save_folder="hazard_frames"
):
    os.makedirs(save_folder, exist_ok=True)

    frames = sample_frames_for_childsun(video_path, num_frames=num_frames)

    detected_hazards = []
    best_hazard = None

    for frame_index, frame in enumerate(frames):
        h, w = frame.shape[:2]
        frame_diagonal = float(np.sqrt(w ** 2 + h ** 2))

        pose_results = yolo_pose_model.predict(frame, verbose=False)
        person_center = None

        if len(pose_results) > 0:
            pose_result = pose_results[0]

            if pose_result.keypoints is not None and len(pose_result.keypoints.xy) > 0:
                kp_xy = pose_result.keypoints.xy.cpu().numpy()
                kp_conf = pose_result.keypoints.conf.cpu().numpy()

                scores = kp_conf.sum(axis=1)
                best_person_idx = int(np.argmax(scores))

                visible = kp_conf[best_person_idx] > 0.05

                if np.any(visible):
                    visible_points = kp_xy[best_person_idx][visible]
                    person_center = visible_points.mean(axis=0)

        object_results = yolo_object_model.predict(frame, verbose=False)

        for result in object_results:
            for box in result.boxes:
                cls_id = int(box.cls[0].cpu().numpy())
                conf = float(box.conf[0].cpu().numpy())
                object_name = yolo_object_model.names[cls_id]

                if object_name in SUPPORTED_HAZARD_OBJECTS and conf >= conf_threshold:
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy().astype(int)

                    object_center = np.array([
                        (x1 + x2) / 2,
                        (y1 + y2) / 2
                    ])

                    if person_center is None:
                        distance_to_child = None
                        normalized_distance = None
                        proximity = "Unknown"
                        is_near_child = False
                    else:
                        distance_to_child = float(
                            np.linalg.norm(object_center - person_center)
                        )

                        normalized_distance = float(
                            distance_to_child / frame_diagonal
                        )

                        if normalized_distance <= 0.20:
                            proximity = "Very Near"
                            is_near_child = True
                        elif normalized_distance <= near_threshold:
                            proximity = "Near"
                            is_near_child = True
                        elif normalized_distance <= 0.50:
                            proximity = "Moderate"
                            is_near_child = False
                        else:
                            proximity = "Far"
                            is_near_child = False

                    hazard_info = {
                        "object": object_name,
                        "confidence": conf,
                        "frame_index": frame_index,
                        "box": (int(x1), int(y1), int(x2), int(y2)),
                        "distance_to_child": distance_to_child,
                        "normalized_distance": normalized_distance,
                        "proximity": proximity,
                        "is_near_child": is_near_child,
                        "frame": frame.copy(),
                        "person_center": person_center,
                        "object_center": object_center
                    }

                    detected_hazards.append(hazard_info)

                    # Choose best hazard for the saved image.
                    # Priority: near hazards first, then highest confidence.
                    if best_hazard is None:
                        best_hazard = hazard_info
                    else:
                        if hazard_info["is_near_child"] and not best_hazard["is_near_child"]:
                            best_hazard = hazard_info
                        elif hazard_info["is_near_child"] == best_hazard["is_near_child"]:
                            if hazard_info["confidence"] > best_hazard["confidence"]:
                                best_hazard = hazard_info

    saved_image_path = None

    if best_hazard is not None:
        frame_with_box = best_hazard["frame"].copy()
        x1, y1, x2, y2 = best_hazard["box"]

        # Draw hazard object red bounding box
        cv2.rectangle(
            frame_with_box,
            (x1, y1),
            (x2, y2),
            (0, 0, 255),
            3
        )

        # Draw distance line between child center and hazard center if available
        if best_hazard["person_center"] is not None:
            child_x, child_y = best_hazard["person_center"].astype(int)
            obj_x, obj_y = best_hazard["object_center"].astype(int)

            cv2.circle(frame_with_box, (child_x, child_y), 6, (255, 0, 0), -1)
            cv2.circle(frame_with_box, (obj_x, obj_y), 6, (0, 0, 255), -1)

            cv2.line(
                frame_with_box,
                (child_x, child_y),
                (obj_x, obj_y),
                (0, 255, 255),
                2
            )

        # Label above the hazard box
        label = f"{best_hazard['object']} - {best_hazard['proximity']}"

        cv2.putText(
            frame_with_box,
            label,
            (x1, max(y1 - 10, 25)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 0, 255),
            2
        )

        saved_image_path = os.path.join(
            save_folder,
            f"hazard_frame_{best_hazard['frame_index']}.jpg"
        )

        cv2.imwrite(saved_image_path, frame_with_box)

    clean_hazards = []

    for hazard in detected_hazards:
        clean_hazards.append({
            "object": hazard["object"],
            "confidence": hazard["confidence"],
            "frame_index": hazard["frame_index"],
            "distance_to_child": hazard["distance_to_child"],
            "normalized_distance": hazard["normalized_distance"],
            "proximity": hazard["proximity"],
            "is_near_child": hazard["is_near_child"],
            "saved_image": saved_image_path if hazard is best_hazard else None
        })

    return {
        "hazard_detected": len(clean_hazards) > 0,
        "detected_hazards": clean_hazards
    }

# ### 18. Full Integrated Pipeline

# In[18]:


def run_safezone_integration(video_path):

    print("\n" + "=" * 60)
    print("SafeZone Integrated Inference Pipeline")
    print("=" * 60)

    # Load models
    childsun_model = load_childsun_model(CHILDSUN_MODEL_PATH)
    childact_model = load_childact_model(CHILDACT_MODEL_PATH)
    child_detector_model = load_child_detector_model(CHILD_DETECTOR_MODEL_PATH)
    yolo_object_model = load_yolo_object_model(YOLO_OBJECT_MODEL)
    yolo_pose_model = load_yolo_pose_model(YOLO_POSE_MODEL)

    print("\nRunning Child Detection prediction...")
    child_result = predict_child_from_video(
        child_detector_model=child_detector_model,
        video_path=video_path,
        num_frames=10
    )

    if not child_result["child_detected"]:
        final_output = {
            "final_status": "NO ALERT",
            "risk_level": "Low",
            "reason": "No child was detected in the video.",
            "recommended_action": "No alert is sent."
        }

        print("\nNo child detected. Skipping ChildSUn, Hazard Detection, and ChildACT.")

        return {
            "child_detection": child_result,
            "hazard_detection": None,
            "childsun": None,
            "childact": None,
            "final_decision": final_output
        }

    print("\nRunning Hazard Object Detection...")
    hazard_result = detect_hazard_objects(
        video_path=video_path,
        yolo_object_model=yolo_object_model,
        yolo_pose_model=yolo_pose_model,
        num_frames=10
    )

    print("\nRunning ChildSUn scene safety prediction...")
    childsun_result = predict_childsun_video(
        model=childsun_model,
        video_path=video_path,
        num_frames=10
    )

    print("\nRunning YOLO Pose + ChildACT action prediction...")
    childact_result = predict_childact_video(
        tcn_model=childact_model,
        yolo_model=yolo_pose_model,
        video_path=video_path,
        confidence_threshold=0.80
    )

    print("\nApplying final decision logic...")
    final_output = final_decision_logic(
        childsun_result=childsun_result,
        childact_result=childact_result,
        child_result=child_result,
        hazard_result=hazard_result
    )

    print("\n" + "=" * 60)
    print("Final Integrated Results")
    print("=" * 60)

    print("\nChild Detection Result:")
    print("Child Detected:", child_result["child_detected"])
    print("Confidence:", round(child_result["confidence"], 4))

    print("\nHazard Object Detection Result:")
    print("Hazard Detected:", hazard_result["hazard_detected"])
    print("Detected Hazards:", hazard_result["detected_hazards"])

    print("\nChildSUn Result:")
    print("Prediction:", childsun_result["prediction"])
    print("Confidence:", round(childsun_result["confidence"], 4))
    print("Max Unsafe Confidence:", round(childsun_result["max_unsafe_confidence"], 4))
    print("Unsafe Frames:", childsun_result["unsafe_frames"])
    print("Unsafe Ratio:", round(childsun_result["unsafe_ratio"], 4))

    print("\nChildACT Result:")
    print("Prediction:", childact_result["prediction"])
    print("Confidence:", round(childact_result["confidence"], 4))
    print("Likely Action Type:", childact_result["likely_action_type"])
    print("Pose Meta:", childact_result["pose_meta"])

    print("\nFinal Decision:")
    print("Status:", final_output["final_status"])
    print("Risk Level:", final_output["risk_level"])
    print("Reason:", final_output["reason"])
    print("Recommended Action:", final_output["recommended_action"])

    return {
        "child_detection": child_result,
        "hazard_detection": hazard_result,
        "childsun": childsun_result,
        "childact": childact_result,
        "final_decision": final_output
    }


# ### Run Example

# In[19]:


if __name__ == "__main__":

    print("\n\n===== SAFE VIDEO =====")
    run_safezone_integration("safe_video.mp4")

    print("\n\n===== UNSAFE VIDEO =====")
    run_safezone_integration("unsafe_video.mp4")


import os
import uuid
import joblib
import numpy as np
from PIL import Image
from skimage.feature import hog
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # ✅ allow Flutter Web / any origin

# --- LOAD MODELS ---
base_path = os.path.dirname(__file__)

crop_model_path = os.path.join(base_path, 'crop_model.pkl')
crop_scaler_path = os.path.join(base_path, 'crop_scaler.pkl')
crop_encoder_path = os.path.join(base_path, 'crop_encoder.pkl')

disease_model_path = os.path.join(base_path, 'disease_model.pkl')
disease_scaler_path = os.path.join(base_path, 'disease_scaler.pkl')
disease_encoder_path = os.path.join(base_path, 'disease_encoder.pkl')

crop_model = None
crop_scaler = None
crop_encoder = None

disease_model = None
disease_scaler = None
disease_encoder = None

try:
    crop_model = joblib.load(crop_model_path)
    crop_scaler = joblib.load(crop_scaler_path)
    crop_encoder = joblib.load(crop_encoder_path)

    disease_model = joblib.load(disease_model_path)
    disease_scaler = joblib.load(disease_scaler_path)
    disease_encoder = joblib.load(disease_encoder_path)

    print("✅ AI Brain: Scikit-Learn models loaded successfully with Joblib!")
except Exception as e:
    print(f"⚠️ AI Brain Warning: Could not load models ({e})")
    print("🚀 System may not be able to perform predictions.")


# --- ROOT / HEALTH ---
@app.route('/')
def home():
    return jsonify({
        "service": "KARE AI ML Service",
        "status": "Healthy",
        "models_loaded": disease_model is not None,
        "endpoints": ["/predict", "/health"],
    })

@app.route('/health')
def health():
    return jsonify({"status": "ok", "models_loaded": disease_model is not None}), 200


# --- FEATURE EXTRACTION ---
def extract_hog_features(image_path):
    with Image.open(image_path) as img:
        img = img.convert('L').resize((128, 128))

        features = hog(
            np.array(img),
            orientations=9,
            pixels_per_cell=(16, 16),
            cells_per_block=(2, 2),
            transform_sqrt=True,
        )

        target_length = 1764
        if len(features) < target_length:
            features = np.pad(features, (0, target_length - len(features)), 'constant')
        else:
            features = features[:target_length]

        return features


# --- PREDICT ---
@app.route('/predict', methods=['POST'])
def predict():
    if disease_model is None or disease_scaler is None or disease_encoder is None:
        return jsonify({"error": "ML models failed to load on start"}), 500

    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({"error": "Empty filename"}), 400

    file_path = f"temp_{uuid.uuid4().hex}.jpg"
    file.save(file_path)

    try:
        features = extract_hog_features(file_path)
        scaled_features = disease_scaler.transform([features])

        prediction_id = disease_model.predict(scaled_features)[0]
        disease_name = disease_encoder.inverse_transform([prediction_id])[0]
        confidence = float(np.max(disease_model.predict_proba(scaled_features)))

        # ✅ Return keys the Node backend expects
        disease_str = str(disease_name)
        is_healthy = "healthy" in disease_str.lower()

        return jsonify({
            "disease_id": int(prediction_id),
            "disease_en": disease_str,
            "disease_am": disease_str,   # replace with real Amharic map if you have one
            "result": disease_str,        # keep for backward-compat
            "status": "Healthy" if is_healthy else "Disease",
            "confidence": confidence,
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)


# --- START ---
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"🌍 ML Service started on port {port}")
    app.run(host='0.0.0.0', port=port)
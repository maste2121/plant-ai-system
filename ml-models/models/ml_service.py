import os
import joblib
import numpy as np
from flask import Flask, request, jsonify
from PIL import Image
from skimage.feature import hog

app = Flask(__name__)

# --- LOAD MODELS ---
base_path = os.path.dirname(__file__)

crop_model_path = os.path.join(base_path, 'crop_model.pkl')
crop_scaler_path = os.path.join(base_path, 'crop_scaler.pkl')
crop_encoder_path = os.path.join(base_path, 'crop_encoder.pkl')

disease_model_path = os.path.join(base_path, 'disease_model.pkl')
disease_scaler_path = os.path.join(base_path, 'disease_scaler.pkl')
disease_encoder_path = os.path.join(base_path, 'disease_encoder.pkl')

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


def extract_hog_features(image_path):
    with Image.open(image_path) as img:
        img = img.convert('L').resize((128, 128))

        features = hog(
            np.array(img),
            orientations=9,
            pixels_per_cell=(16, 16),
            cells_per_block=(2, 2),
            transform_sqrt=True
        )

        target_length = 1780

        if len(features) < target_length:
            features = np.pad(
                features,
                (0, target_length - len(features)),
                'constant'
            )
        else:
            features = features[:target_length]

        return features


@app.route('/predict', methods=['POST'])
def predict():

    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files['image']
    file_path = f"temp_{file.filename}"

    file.save(file_path)

    try:
        # Extract HOG features
        features = extract_hog_features(file_path)

        # Scale features
        scaled_features = disease_scaler.transform([features])

        # Predict disease
        prediction_id = disease_model.predict(scaled_features)[0]

        # Convert prediction ID to disease name
        disease_name = disease_encoder.inverse_transform(
            [prediction_id]
        )[0]

        # Calculate confidence
        confidence = float(
            np.max(
                disease_model.predict_proba(scaled_features)
            )
        )

        # Remove temporary image
        if os.path.exists(file_path):
            os.remove(file_path)

        return jsonify({
            "disease_id": int(prediction_id),
            "result": str(disease_name),
            "confidence": confidence
        })

    except Exception as e:

        if os.path.exists(file_path):
            os.remove(file_path)

        return jsonify({
            "error": str(e)
        }), 500


if __name__ == '__main__':
    print("🌍 ML Service started on http://127.0.0.1:5001")

    app.run(
        host='0.0.0.0',
        port=5001
    )
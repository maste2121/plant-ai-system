import os
import pickle
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app) # Allows Flutter Web/Mobile to connect

# --- LOAD MODEL ---
disease_model = None
base_path = os.path.dirname(__file__)
model_path = os.path.join(base_path, 'disease_model.pkl')

try:
    with open(model_path, 'rb') as f:
        disease_model = pickle.load(f)
    print("✅ AI Brain: Model loaded successfully!")
except Exception as e:
    print(f"⚠️ AI Brain Warning: Could not load the real model ({e})")
    print("🚀 System will now use 'Simulated Mode' for Frontend Testing.")

# --- PREDICTION ENDPOINT ---
@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Check if an image was sent
        if 'image' not in request.files:
            return jsonify({"error": "No image provided"}), 400
        
        # LOGIC FOR MEMBER 1 & 2:
        # If the real model loaded, we would process the image here.
        # Since we are testing the Monorepo connection, we return valid JSON.
        
        return jsonify({
            "disease_en": "Late Blight",
            "disease_am": "የቆየ ግርሻ",
            "confidence": 0.94,
            "treatments": {
                "organic": "ተክሉን በኒም ዘይት ይርጩ (Spray with neem oil).",
                "chemical": "በየ 7 ቀኑ ማንኮዜብ ይጠቀሙ (Apply Mancozeb every 7 days)."
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("🌍 ML Service started on http://127.0.0.1:5000")
    app.run(port=5000, host='0.0.0.0') # Allow connections from Wi-Fi
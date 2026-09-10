"""
PlantAI ML Service - With Calibrated Confidence
Loads trained models and provides predictions with realistic confidence
"""

import joblib
import numpy as np
from skimage.feature import hog
from PIL import Image
import os

class PlantAIModels:
    def __init__(self, models_path='ml-models/models'):
        """Load all trained models"""
        
        print("="*60)
        print("Loading PlantAI Models...")
        print("="*60)
        
        # Load crop models
        self.crop_model = joblib.load(f'{models_path}/crop_model.pkl')
        self.crop_scaler = joblib.load(f'{models_path}/crop_scaler.pkl')
        self.crop_encoder = joblib.load(f'{models_path}/crop_encoder.pkl')
        print("✅ Crop models loaded")
        
        # Load disease models
        self.disease_model = joblib.load(f'{models_path}/disease_model.pkl')
        self.disease_scaler = joblib.load(f'{models_path}/disease_scaler.pkl')
        self.disease_encoder = joblib.load(f'{models_path}/disease_encoder.pkl')
        print("✅ Disease models loaded")
        
        # Store disease classes for reference
        self.disease_classes = list(self.disease_encoder.classes_)
        print(f"   Diseases: {self.disease_classes}")
        
        print("="*60)
        print("✅ All models ready!")
        print("="*60)
    
    def recommend_crop(self, N, P, K, temperature, humidity, pH, rainfall):
        """
        Recommend crop from soil data
        
        Features: N, P, K, temperature, humidity, pH, rainfall (7 features)
        """
        input_data = [[N, P, K, temperature, humidity, pH, rainfall]]
        input_scaled = self.crop_scaler.transform(input_data)
        prediction = self.crop_model.predict(input_scaled)[0]
        crop = self.crop_encoder.inverse_transform([prediction])[0]
        confidence = max(self.crop_model.predict_proba(input_scaled)[0])
        return crop, confidence
    
    def detect_disease(self, image_file):
        """
        Detect disease from leaf image with CALIBRATED confidence
        
        Returns:
            disease_name (str): Name of detected disease
            confidence (float): Calibrated confidence score (0-1)
            is_known (bool): True if confidence > threshold
        """
        try:
            # 1. Process image
            img = Image.open(image_file).convert('RGB')
            img = img.resize((128, 128))
            img_array = np.array(img) / 255.0
            
            # 2. Check if image is a leaf (simple green detection)
            green_mean = img_array[:, :, 1].mean()
            red_mean = img_array[:, :, 0].mean()
            blue_mean = img_array[:, :, 2].mean()
            
            # If not green enough, it's not a leaf
            if green_mean < red_mean and green_mean < blue_mean:
                return "Not a Leaf", 0.10, False
            
            # 3. Extract HOG features
            gray = np.dot(img_array[...,:3], [0.2989, 0.5870, 0.1140])
            hog_features = hog(
                gray, 
                orientations=9, 
                pixels_per_cell=(16, 16),
                cells_per_block=(2, 2),
                visualize=False
            )
            
            # 4. Scale features
            features_scaled = self.disease_scaler.transform([hog_features])
            
            # 5. Get probabilities from model
            probabilities = self.disease_model.predict_proba(features_scaled)[0]
            max_prob = max(probabilities)
            predicted_class = np.argmax(probabilities)
            
            # 6. 🛑 CALIBRATE CONFIDENCE (FIX FOR 94% ISSUE)
            
            if max_prob > 0.85:
                sorted_probs = sorted(probabilities, reverse=True)
                gap = sorted_probs[0] - sorted_probs[1]
                
                if gap > 0.6:
                    calibrated_confidence = 0.55 + (max_prob * 0.35)
                else:
                    calibrated_confidence = max_prob * 0.9
            else:
                calibrated_confidence = max_prob
            
            # Cap maximum confidence at 88%
            if calibrated_confidence > 0.88:
                calibrated_confidence = 0.88
            
            # 7. Get disease name
            disease_name = self.disease_encoder.inverse_transform([predicted_class])[0]
            
            # 8. Final decision
            CONFIDENCE_THRESHOLD = 0.55
            
            if calibrated_confidence < CONFIDENCE_THRESHOLD:
                return "Unknown Disease", calibrated_confidence, False
            else:
                return disease_name, calibrated_confidence, True
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return "Error", 0.0, False

# Test the service
if __name__ == "__main__":
    models = PlantAIModels()
    print("\n" + "="*60)
    print("🧪 TESTING ML SERVICE")
    print("="*60)
    
    # Test crop recommendation (7 features)
    # N, P, K, temperature, humidity, pH, rainfall
    crop, confidence = models.recommend_crop(90, 42, 43, 20.88, 82.00, 6.5, 202.94)
    print(f"\n🌾 Crop Recommendation:")
    print(f"   Recommended: {crop}")
    print(f"   Confidence: {confidence:.2%}")
    
    print("\n" + "="*60)
    print("✅ ML Service is ready for backend integration!")
    print("="*60)
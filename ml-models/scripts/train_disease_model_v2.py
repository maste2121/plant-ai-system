"""
Train Disease Detection Model - Improved Version
Using HOG Features + Random Forest
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from PIL import Image
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib
import re
import warnings
warnings.filterwarnings('ignore')

print("="*60)
print("DISEASE DETECTION MODEL - IMPROVED VERSION")
print("="*60)

# ============================================
# 1. SETUP - Path to your dataset
# ============================================

# UPDATE THIS PATH to your dataset location
dataset_path = r"C:\Users\SOOQ ELASER\Documents\Machine L\Multi-Crop Disease Dataset\Multicrop Disease Dataset\Multicrop Disease Dataset"

train_path = os.path.join(dataset_path, 'train', 'images')
test_path = os.path.join(dataset_path, 'test', 'images')

print(f"Train path exists: {os.path.exists(train_path)}")
print(f"Test path exists: {os.path.exists(test_path)}")

# ============================================
# 2. EXTRACT DISEASE NAME FROM FILENAME
# ============================================

def clean_disease_name(name):
    """Clean and merge duplicate disease names"""
    name_lower = name.lower()
    
    # Merge duplicates
    if 'downy' in name_lower and 'mildew' in name_lower:
        return 'Downy_Mildew'
    if 'bract' in name_lower and 'mosaic' in name_lower:
        return 'Bract_Mosaic'
    if 'black_leaf_spot' in name_lower or 'black leaf spot' in name_lower:
        return 'Black_Leaf_Spot'
    if 'early_leaf_spot' in name_lower:
        return 'Early_Leaf_Spot'
    if 'bacterial_spot' in name_lower:
        return 'Bacterial_Spot'
    if 'anthracnose' in name_lower:
        return 'Anthracnose'
    if 'black_rot' in name_lower:
        return 'Black_Rot'
    if 'cordana' in name_lower:
        return 'Cordana'
    return name

def extract_disease_from_filename(filename):
    """Extract and clean disease name from Roboflow filename"""
    name = filename.replace('.jpg', '').replace('.png', '').replace('.jpeg', '')
    
    # Remove Roboflow hash
    if '.rf.' in name:
        name = name.split('.rf.')[0]
    
    # Remove trailing _jpg or _jpeg
    name = name.replace('-_jpg', '').replace('-_jpeg', '')
    
    # Remove number at end
    name = re.sub(r'-\d+$', '', name)
    
    # Replace underscores with spaces
    name = name.replace('_', ' ')
    
    # Clean and standardize
    return clean_disease_name(name)

# ============================================
# 3. HOG FEATURE EXTRACTION
# ============================================

from skimage.feature import hog

def extract_hog_features(image_array):
    """Extract HOG features from image"""
    # Convert to grayscale
    if len(image_array.shape) == 3:
        gray = np.dot(image_array[...,:3], [0.2989, 0.5870, 0.1140])
    else:
        gray = image_array
    
    # Extract HOG features
    features = hog(
        gray, 
        orientations=9, 
        pixels_per_cell=(16, 16),
        cells_per_block=(2, 2),
        visualize=False
    )
    return features

# ============================================
# 4. LOAD IMAGES AND EXTRACT FEATURES
# ============================================

def load_images_with_features(path, img_size=(128, 128), limit=None):
    """Load images and extract HOG features"""
    features = []
    labels = []
    
    files = [f for f in os.listdir(path) if f.lower().endswith(('.jpg', '.png', '.jpeg'))]
    
    if limit:
        files = files[:limit]
    
    print(f"  Found {len(files)} images...")
    
    for i, file in enumerate(files):
        if i % 500 == 0:
            print(f"    Progress: {i}/{len(files)}")
        
        disease = extract_disease_from_filename(file)
        if disease:
            try:
                img = Image.open(os.path.join(path, file)).convert('RGB')
                img = img.resize(img_size)
                img_array = np.array(img) / 255.0
                
                features.append(extract_hog_features(img_array))
                labels.append(disease)
            except Exception as e:
                pass
    
    return np.array(features), np.array(labels)

# ============================================
# 5. LOAD DATA
# ============================================

print("\n📂 Loading TRAIN images...")
X_train_features, y_train_raw = load_images_with_features(train_path, limit=3000)

print(f"\n📂 Loading TEST images...")
X_test_features, y_test_raw = load_images_with_features(test_path, limit=800)

print(f"\n✅ Loaded {len(X_train_features)} training samples")
print(f"✅ Loaded {len(X_test_features)} test samples")

# ============================================
# 6. CLEAN AND MERGE CLASSES
# ============================================

from collections import Counter

# Get class distribution
train_counts = Counter(y_train_raw)
test_counts = Counter(y_test_raw)

print("\n📊 Training Class Distribution:")
for cls, count in sorted(train_counts.items(), key=lambda x: -x[1])[:15]:
    print(f"  {cls}: {count}")

# Filter out classes with too few samples (less than 30)
min_samples = 30
keep_classes = [cls for cls, count in train_counts.items() if count >= min_samples]

train_mask = [y in keep_classes for y in y_train_raw]
test_mask = [y in keep_classes for y in y_test_raw]

X_train_filtered = X_train_features[train_mask]
y_train_filtered = y_train_raw[train_mask]
X_test_filtered = X_test_features[test_mask]
y_test_filtered = y_test_raw[test_mask]

print(f"\n✅ After filtering (min {min_samples} samples):")
print(f"  Train: {len(X_train_filtered)} samples")
print(f"  Test: {len(X_test_filtered)} samples")

# ============================================
# 7. ENCODE LABELS
# ============================================

encoder = LabelEncoder()
y_train_encoded = encoder.fit_transform(y_train_filtered)
y_test_encoded = encoder.transform(y_test_filtered)

print(f"\n📋 Classes: {list(encoder.classes_)}")

# ============================================
# 8. SPLIT TRAIN INTO TRAIN/VAL
# ============================================

X_train, X_val, y_train, y_val = train_test_split(
    X_train_filtered, y_train_encoded, test_size=0.2, 
    random_state=42, stratify=y_train_encoded
)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_val_scaled = scaler.transform(X_val)
X_test_scaled = scaler.transform(X_test_filtered)

print(f"\n📊 Data Split:")
print(f"  Train: {X_train.shape[0]} samples")
print(f"  Validation: {X_val.shape[0]} samples")
print(f"  Test: {X_test_filtered.shape[0]} samples")
print(f"  Feature dimension: {X_train.shape[1]}")

# ============================================
# 9. TRAIN RANDOM FOREST
# ============================================

print("\n🏋️ Training Random Forest with class weights...")

# Calculate class weights (inverse frequency)
class_weights = {}
for i, cls in enumerate(encoder.classes_):
    count = np.sum(y_train_filtered == cls)
    class_weights[i] = 1.0 / count
# Normalize
total = sum(class_weights.values())
class_weights = {k: v/total for k, v in class_weights.items()}

rf_model = RandomForestClassifier(
    n_estimators=150,
    max_depth=20,
    min_samples_split=5,
    class_weight=class_weights,
    random_state=42,
    n_jobs=-1
)

rf_model.fit(X_train_scaled, y_train)

# Validation
val_pred = rf_model.predict(X_val_scaled)
val_acc = accuracy_score(y_val, val_pred)
print(f"Validation Accuracy: {val_acc*100:.2f}%")

# Test
test_pred = rf_model.predict(X_test_scaled)
test_acc = accuracy_score(y_test_encoded, test_pred)
print(f"\n✅ Test Accuracy: {test_acc*100:.2f}%")

# Detailed report
print("\n📊 Classification Report:")
print(classification_report(y_test_encoded, test_pred, target_names=encoder.classes_))

# ============================================
# 10. SAVE MODELS
# ============================================

os.makedirs('ml-models/models', exist_ok=True)

joblib.dump(rf_model, 'ml-models/models/disease_model.pkl')
joblib.dump(scaler, 'ml-models/models/disease_scaler.pkl')
joblib.dump(encoder, 'ml-models/models/disease_encoder.pkl')

print("\n✅ Models saved to ml-models/models/")
print("   - disease_model.pkl")
print("   - disease_scaler.pkl")
print("   - disease_encoder.pkl")

# ============================================
# 11. FEATURE IMPORTANCE
# ============================================

print("\n📊 Top 20 Important Features:")
importances = rf_model.feature_importances_
top_indices = np.argsort(importances)[-20:][::-1]
for i, idx in enumerate(top_indices):
    print(f"   Feature {idx}: {importances[idx]:.4f}")

print("\n" + "="*60)
print("✅ DISEASE MODEL TRAINING COMPLETE!")
print("="*60)
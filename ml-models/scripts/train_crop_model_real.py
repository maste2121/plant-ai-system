"""
Train Crop Recommendation Model using Real Dataset
"""
import pandas as pd
import numpy as np
import joblib
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

print("="*60)
print("CROP RECOMMENDATION MODEL - REAL DATA")
print("="*60)

# Load dataset
df = pd.read_csv('ml-models/datasets/crop_recommendation.csv')
print(f"✅ Loaded {len(df)} samples")
print(f"Features: {df.columns.tolist()}")
print(f"\nCrops: {df['label'].nunique()} types")
print(df['label'].value_counts())

# Prepare features and target
features = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
X = df[features]
y = df['label']

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Encode labels
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y)

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
)

# Train Random Forest
print("\n🏋️ Training Random Forest...")
model = RandomForestClassifier(
    n_estimators=200,
    max_depth=15,
    min_samples_split=5,
    random_state=42,
    n_jobs=-1
)
model.fit(X_train, y_train)

# Evaluate
y_pred = model.predict(X_test)
accuracy = accuracy_score(y_test, y_pred)
print(f"\n✅ Test Accuracy: {accuracy*100:.2f}%")

# Classification report
print("\n📊 Classification Report:")
print(classification_report(y_test, y_pred, target_names=encoder.classes_))

# Feature importance
importance = pd.DataFrame({
    'feature': features,
    'importance': model.feature_importances_
}).sort_values('importance', ascending=False)

print("\n📊 Feature Importance:")
for _, row in importance.iterrows():
    print(f"   {row['feature']}: {row['importance']:.4f}")

# Save models
joblib.dump(model, 'ml-models/models/crop_model.pkl')
joblib.dump(scaler, 'ml-models/models/crop_scaler.pkl')
joblib.dump(encoder, 'ml-models/models/crop_encoder.pkl')

print("\n✅ Models saved to ml-models/models/")

# Test prediction
sample = [[90, 42, 43, 20.88, 82.00, 6.5, 202.94]]  # Example: rice
sample_scaled = scaler.transform(sample)
pred = model.predict(sample_scaled)[0]
crop = encoder.inverse_transform([pred])[0]
print(f"\n🧪 Test Prediction (Rice sample): {crop}")

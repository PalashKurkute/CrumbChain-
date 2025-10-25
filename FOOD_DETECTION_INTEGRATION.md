# Food Detection Integration Guide

## 🎯 Overview
This guide explains how to integrate your trained food detection model from the `image detection food 2/image detection 2` project into the CrumbChain backend.

## ✅ What's Already Done

### 1. Backend API Endpoint Created
- **File**: `backend/app.py`
- **Endpoint**: `/api/detect-food`
- **Method**: POST
- **Authentication**: Required (JWT token)
- **Current Status**: Returns mock data

### 2. Flutter Service Created
- **File**: `lib/services/food_detection_service.dart`
- **Function**: Sends image to backend and receives food name prediction
- **Features**: Error handling, timeout management, authentication

### 3. UI Integration Complete
- **File**: `lib/pages/create_listing_page.dart`
- **Behavior**: 
  - When user uploads image, `_analyzeImage()` is automatically called
  - Shows loading dialog during analysis
  - Auto-fills food name field with detected food
  - Shows confidence percentage
  - Handles errors gracefully

### 4. API Configuration Updated
- **File**: `lib/config/api_config.dart`
- **Added**: `detectFood` endpoint constant

## 🔧 How to Integrate Your Actual Model

### Step 1: Locate Your Model Files

From your `image detection food 2/image detection 2` project, you need:

1. **Trained Model File** (typically one of these):
   - `model.h5` (Keras/TensorFlow format)
   - `model.keras` (new Keras format)
   - `model.pt` (PyTorch format)
   - `model.pkl` (scikit-learn format)

2. **Class Labels File** (food names):
   - `labels.txt`
   - `classes.json`
   - Or hardcoded in your training script

3. **Model Configuration**:
   - Input image size (e.g., 224x224, 299x299)
   - Preprocessing requirements (normalization, etc.)
   - Model architecture details

### Step 2: Copy Model Files to Backend

```bash
# Create models directory in backend
mkdir backend/models

# Copy your model file
# Example:
cp "C:/Coding/PROJECTS/image detection food 2/image detection 2/model.h5" backend/models/

# Copy labels file if separate
cp "C:/Coding/PROJECTS/image detection food 2/image detection 2/labels.txt" backend/models/
```

### Step 3: Install Required Python Packages

Add to `backend/requirements.txt`:

```txt
# For TensorFlow/Keras models
tensorflow==2.15.0
Pillow==10.1.0
numpy==1.24.3

# OR for PyTorch models
# torch==2.1.0
# torchvision==0.16.0
# Pillow==10.1.0
# numpy==1.24.3
```

Install packages:
```bash
cd backend
pip install -r requirements.txt
```

### Step 4: Update the Backend Endpoint

Replace the mock code in `backend/app.py` at the `/api/detect-food` endpoint.

#### Example for TensorFlow/Keras Model:

```python
# At the top of app.py, add imports
from PIL import Image
import numpy as np
from tensorflow import keras
import io

# Load model globally (once when server starts)
FOOD_MODEL = None
FOOD_CLASSES = []

def load_food_detection_model():
    """Load the trained food detection model"""
    global FOOD_MODEL, FOOD_CLASSES
    
    try:
        model_path = os.path.join(os.path.dirname(__file__), 'models', 'model.h5')
        FOOD_MODEL = keras.models.load_model(model_path)
        
        # Load class labels
        labels_path = os.path.join(os.path.dirname(__file__), 'models', 'labels.txt')
        with open(labels_path, 'r') as f:
            FOOD_CLASSES = [line.strip() for line in f.readlines()]
        
        print(f"✅ Food detection model loaded with {len(FOOD_CLASSES)} classes")
    except Exception as e:
        print(f"❌ Failed to load food detection model: {e}")

# Call this after creating the Flask app
load_food_detection_model()

# Update the detect_food function
@app.route('/api/detect-food', methods=['POST'])
@token_required
def detect_food(current_user):
    """
    Detect food type from uploaded image using ML model
    """
    try:
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'message': 'No image file provided'
            }), 400
        
        image_file = request.files['image']
        
        if image_file.filename == '':
            return jsonify({
                'success': False,
                'message': 'No image selected'
            }), 400
        
        if FOOD_MODEL is None:
            return jsonify({
                'success': False,
                'message': 'Model not loaded'
            }), 500
        
        # Read and preprocess image
        img = Image.open(io.BytesIO(image_file.read()))
        
        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize to model input size (adjust based on your model)
        img = img.resize((224, 224))  # Change to your model's expected size
        
        # Convert to array and normalize
        img_array = np.array(img) / 255.0  # Normalize to 0-1
        img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
        
        # Make prediction
        predictions = FOOD_MODEL.predict(img_array, verbose=0)
        predicted_class_idx = int(np.argmax(predictions[0]))
        confidence = float(predictions[0][predicted_class_idx])
        
        # Get food name
        detected_food = FOOD_CLASSES[predicted_class_idx] if predicted_class_idx < len(FOOD_CLASSES) else "Unknown"
        
        print(f"✅ Detected: {detected_food} (confidence: {confidence:.2f})")
        
        return jsonify({
            'success': True,
            'data': {
                'foodName': detected_food,
                'confidence': round(confidence, 2),
                'message': 'Food detected successfully'
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error in food detection: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'message': f'Food detection failed: {str(e)}'
        }), 500
```

#### Example for PyTorch Model:

```python
# At the top of app.py
import torch
import torchvision.transforms as transforms
from PIL import Image
import io

# Load model globally
FOOD_MODEL = None
FOOD_CLASSES = []
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

def load_food_detection_model():
    """Load the trained PyTorch food detection model"""
    global FOOD_MODEL, FOOD_CLASSES
    
    try:
        model_path = os.path.join(os.path.dirname(__file__), 'models', 'model.pt')
        FOOD_MODEL = torch.load(model_path, map_location=DEVICE)
        FOOD_MODEL.eval()
        
        # Load class labels
        labels_path = os.path.join(os.path.dirname(__file__), 'models', 'labels.txt')
        with open(labels_path, 'r') as f:
            FOOD_CLASSES = [line.strip() for line in f.readlines()]
        
        print(f"✅ Food detection model loaded on {DEVICE}")
    except Exception as e:
        print(f"❌ Failed to load food detection model: {e}")

# Update detect_food function
@app.route('/api/detect-food', methods=['POST'])
@token_required
def detect_food(current_user):
    try:
        if 'image' not in request.files:
            return jsonify({'success': False, 'message': 'No image file'}), 400
        
        image_file = request.files['image']
        
        if FOOD_MODEL is None:
            return jsonify({'success': False, 'message': 'Model not loaded'}), 500
        
        # Preprocess image
        img = Image.open(io.BytesIO(image_file.read())).convert('RGB')
        
        transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                               std=[0.229, 0.224, 0.225])
        ])
        
        img_tensor = transform(img).unsqueeze(0).to(DEVICE)
        
        # Predict
        with torch.no_grad():
            outputs = FOOD_MODEL(img_tensor)
            probabilities = torch.nn.functional.softmax(outputs, dim=1)
            confidence, predicted = torch.max(probabilities, 1)
        
        predicted_idx = predicted.item()
        confidence_val = confidence.item()
        detected_food = FOOD_CLASSES[predicted_idx]
        
        return jsonify({
            'success': True,
            'data': {
                'foodName': detected_food,
                'confidence': round(confidence_val, 2),
                'message': 'Food detected successfully'
            }
        }), 200
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return jsonify({'success': False, 'message': str(e)}), 500
```

### Step 5: Test the Integration

1. **Start the backend server:**
   ```bash
   cd backend
   python app.py
   ```

2. **Run the Flutter app:**
   ```bash
   cd ..
   flutter run
   ```

3. **Test the flow:**
   - Open Create Listing page
   - Upload a food image
   - Wait for analysis
   - Verify food name is auto-filled
   - Check confidence percentage

### Step 6: Troubleshooting

#### Common Issues:

1. **Model not loading:**
   - Check model file path
   - Verify model format matches code
   - Check file permissions

2. **Prediction errors:**
   - Verify image preprocessing matches training
   - Check input dimensions
   - Ensure normalization is correct

3. **Low accuracy:**
   - Image quality issues
   - Model needs retraining
   - Wrong preprocessing

4. **Backend crashes:**
   - Check memory usage (model size)
   - Add error logging
   - Test with smaller images first

## 📊 Model Information Template

Please provide these details from your model:

```
Model Type: [TensorFlow/PyTorch/Other]
Input Size: [e.g., 224x224]
Number of Classes: [e.g., 50]
Accuracy: [e.g., 92%]
Training Dataset: [e.g., Food-101]
Preprocessing: [e.g., Normalize 0-1, RGB]
Special Requirements: [Any specific needs]
```

## 🚀 Optimization Tips

1. **Model Size Reduction:**
   - Use quantization
   - Prune unnecessary layers
   - Convert to TFLite for mobile

2. **Performance:**
   - Cache model in memory
   - Use async processing
   - Implement request queuing

3. **Accuracy Improvement:**
   - Add data augmentation
   - Use ensemble methods
   - Fine-tune on local food images

## 📝 Next Steps

1. Locate your model files in the image detection project
2. Copy them to `backend/models/`
3. Update the endpoint code with actual model loading
4. Test thoroughly with various food images
5. Monitor accuracy and adjust as needed

## ❓ Need Help?

If you have questions about:
- Model file locations
- Preprocessing requirements
- Integration issues

Please provide:
- Screenshot of your model directory
- Model training code snippet
- Any error messages you encounter

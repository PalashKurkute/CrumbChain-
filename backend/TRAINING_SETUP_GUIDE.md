# 🚀 RTX 4050 GPU Training Setup Guide
## Indian Food Detection Model - Complete Setup Instructions

---

## 📋 Overview

This guide will help you:
1. Set up PyTorch with CUDA for your RTX 4050 (6GB VRAM)
2. Prepare your Indian Food Images dataset (80 classes, 4000 images)
3. Train an optimized food detection model
4. Integrate it with your existing Flask backend

---

## 🖥️ System Requirements

- **GPU**: NVIDIA RTX 4050 (6GB VRAM)
- **OS**: Windows 11
- **Python**: 3.9 - 3.11 (recommended 3.10)
- **CUDA**: 12.1+ (will be installed with PyTorch)
- **RAM**: 16GB+ recommended
- **Storage**: 10GB free space

---

## 📁 Project Structure

```
CrumbChain-/backend/
├── check_gpu.py              # GPU detection and verification
├── prepare_dataset.py         # Dataset preparation script
├── train_model.py            # Main training script (RTX 4050 optimized)
├── convert_model.py          # PyTorch to TensorFlow conversion
├── finetune_tensorflow.py    # TensorFlow fine-tuning (auto-generated)
├── requirements.txt          # Python dependencies
├── dataset/                  # Prepared dataset (auto-generated)
│   ├── train/
│   ├── val/
│   ├── test/
│   ├── labels.txt
│   ├── class_mapping.json
│   └── dataset_config.json
├── models/                   # Saved models
│   ├── best_food_model.pth   # Best PyTorch model
│   ├── food_model.h5         # TensorFlow model (for Flask)
│   └── labels.txt            # Class labels for inference
└── training_logs/            # Training history and logs
```

---

## ⚡ STEP-BY-STEP SETUP

### **STEP 1: Open VS Code Terminal (PowerShell)**

Press `` Ctrl+` `` in VS Code to open terminal

---

### **STEP 2: Navigate to Backend Directory**

```powershell
cd "C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend"
```

---

### **STEP 3: Create Virtual Environment**

```powershell
# Create virtual environment
python -m venv venv_gpu

# Activate it
.\venv_gpu\Scripts\Activate.ps1
```

**If you get an execution policy error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\venv_gpu\Scripts\Activate.ps1
```

You should see `(venv_gpu)` in your terminal prompt.

---

### **STEP 4: Install PyTorch with CUDA 12.1 (for RTX 4050)**

```powershell
# Install PyTorch with CUDA support
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

This will download ~2GB. Wait for it to complete.

---

### **STEP 5: Install Other Dependencies**

```powershell
# Install TensorFlow and other packages
pip install tensorflow==2.15.0
pip install Pillow numpy flask flask-cors pymongo python-dotenv bcrypt pyjwt werkzeug requests
```

---

### **STEP 6: Verify GPU Setup**

```powershell
python check_gpu.py
```

**Expected output:**
```
============================================================
🔍 GPU AVAILABILITY CHECK
============================================================
✅ PyTorch version: 2.x.x+cu121

✅ CUDA Available: True

📊 GPU INFORMATION:
   GPU 0:
   • Name: NVIDIA GeForce RTX 4050 Laptop GPU
   • Total VRAM: 6.00 GB
   • Available VRAM: 5.95 GB

🧪 TESTING GPU WITH TENSOR OPERATION...
   ✅ GPU tensor operation successful!

============================================================
✅ YOUR RTX 4050 IS READY FOR TRAINING!
============================================================
```

**If CUDA is NOT available:**
- Update your NVIDIA GPU drivers (latest from nvidia.com)
- Restart your computer
- Re-run the PyTorch installation command
- Run `python check_gpu.py` again

---

### **STEP 7: Prepare Dataset**

```powershell
python prepare_dataset.py
```

**What this does:**
- Scans `Indian Food Images\Indian Food Images\` folder
- Creates 70/15/15 train/val/test split
- Organizes images into `backend/dataset/` folder
- Generates labels.txt and config files

**Expected output:**
```
============================================================
🍛 INDIAN FOOD DATASET PREPARATION
============================================================

📊 Found 80 food classes

📋 Splitting and copying images...
   Processed 80/80 classes...

✅ Dataset ready for training!

📁 Dataset Structure:
   • Total Classes: 80
   • Total Images: 4,000

📈 Split Distribution:
   • Training:   2,800 images (70.0%)
   • Validation: 600 images (15.0%)
   • Testing:    600 images (15.0%)
```

---

### **STEP 8: Start Training**

```powershell
python train_model.py
```

**Training Configuration (optimized for RTX 4050 6GB VRAM):**
- Batch Size: 16
- Mixed Precision: Enabled (FP16)
- Gradient Accumulation: 2 steps (effective batch size = 32)
- Model: EfficientNet-B0 (lightweight, efficient)
- Epochs: 50 (with early stopping)

**Expected training time:** 2-3 hours for 50 epochs

**What to expect:**
```
======================================================================
🍛 INDIAN FOOD DETECTION MODEL TRAINING
======================================================================

🖥️  Device: cuda
   GPU: NVIDIA GeForce RTX 4050 Laptop GPU
   💾 GPU Memory: 0.85GB allocated, 1.23GB reserved, 6.00GB total

📊 Dataset: 80 classes, 4000 images

🔄 Creating data loaders...
✅ Train batches: 175 | Val batches: 38
   Effective batch size: 32

🔨 Building model...
✅ Model created successfully!

======================================================================
🚀 STARTING TRAINING
======================================================================

📅 Epoch [1/50]
   Learning Rate: 0.001000

🏋️  Training...
   Batch [50/175] Loss: 3.2451 | Acc: 12.5%
   ...

🎯 Validating...

======================================================================
📊 Epoch 1 Summary:
   Train Loss: 2.8943 | Train Acc: 25.3%
   Val Loss:   2.4521 | Val Acc:   35.7%
   Time: 145.23s
   💾 GPU Memory: 3.24GB allocated, 4.12GB reserved, 6.00GB total
======================================================================
✅ Saved best model (Val Acc: 35.7%)
```

---

### **STEP 9: Monitor Training**

**Training will automatically:**
- Save best model when validation accuracy improves
- Save checkpoints every 5 epochs
- Stop early if no improvement for 10 epochs
- Clear GPU memory periodically

**To stop training:**
Press `Ctrl+C` (model will be saved)

---

### **STEP 10: After Training Completes**

Your trained model will be saved at:
```
backend/models/best_food_model.pth
```

**Training logs:**
```
backend/training_logs/training_history_YYYYMMDD_HHMMSS.json
```

---

## 🔄 INTEGRATING WITH YOUR FLASK BACKEND

You have **two options** to use your trained model:

### **Option 1: Use PyTorch Model Directly (Recommended)**

Modify `backend/app.py` to load PyTorch model instead of TensorFlow:

```python
# In app.py, replace the TensorFlow loading code with:

import torch
from torchvision import transforms, models
import torch.nn as nn

FOOD_MODEL = None
FOOD_CLASSES = []
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

def load_food_detection_model():
    global FOOD_MODEL, FOOD_CLASSES, DEVICE
    
    model_path = os.path.join(os.path.dirname(__file__), 'models', 'best_food_model.pth')
    labels_path = os.path.join(os.path.dirname(__file__), 'models', 'labels.txt')
    
    if not os.path.exists(model_path):
        print(f"⚠️  Model not found at {model_path}")
        return
    
    # Load checkpoint
    checkpoint = torch.load(model_path, map_location=DEVICE)
    num_classes = checkpoint['num_classes']
    
    # Create model
    FOOD_MODEL = models.efficientnet_b0(pretrained=False)
    num_features = FOOD_MODEL.classifier[1].in_features
    FOOD_MODEL.classifier[1] = nn.Linear(num_features, num_classes)
    
    # Load weights
    FOOD_MODEL.load_state_dict(checkpoint['model_state_dict'])
    FOOD_MODEL = FOOD_MODEL.to(DEVICE)
    FOOD_MODEL.eval()
    
    # Load labels
    with open(labels_path, 'r') as f:
        FOOD_CLASSES = [line.strip() for line in f.readlines()]
    
    print(f"✅ PyTorch model loaded ({num_classes} classes)")

# Update the detect-food endpoint
@app.route('/api/detect-food', methods=['POST'])
def detect_food():
    # ... existing code ...
    
    # Preprocess image for PyTorch
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])
    
    img_tensor = transform(image).unsqueeze(0).to(DEVICE)
    
    # Inference
    with torch.no_grad():
        outputs = FOOD_MODEL(img_tensor)
        probabilities = torch.nn.functional.softmax(outputs, dim=1)
        confidence, predicted_idx = torch.max(probabilities, 1)
    
    predicted_class = FOOD_CLASSES[predicted_idx.item()]
    confidence_score = confidence.item()
    
    # ... rest of the code ...
```

### **Option 2: Convert to TensorFlow (More Complex)**

```powershell
python convert_model.py
```

Then fine-tune with your dataset:
```powershell
python finetune_tensorflow.py
```

---

## 🔧 TROUBLESHOOTING

### **Problem: Out of Memory (OOM) Error**

**Solution:** Reduce batch size in `train_model.py`:

```python
GPU_CONFIG = {
    'batch_size': 8,  # Reduce from 16 to 8
    'accumulation_steps': 4,  # Increase from 2 to 4
    ...
}
```

### **Problem: Training Too Slow**

**Check:**
1. GPU is actually being used: `python check_gpu.py`
2. Task Manager → Performance → GPU shows activity
3. CUDA is enabled in PyTorch

### **Problem: CUDA Out of Memory During Inference**

**Solution:** Clear cache before inference:
```python
torch.cuda.empty_cache()
```

### **Problem: Model Accuracy is Low**

**Try:**
1. Train for more epochs
2. Increase image size (224 → 299)
3. Use data augmentation (already enabled)
4. Try different model (ResNet50, EfficientNet-B3)

---

## 📊 MONITORING TRAINING

### **Check GPU Usage in Real-Time**

Open another PowerShell terminal:
```powershell
# Install nvidia-smi wrapper
pip install nvitop

# Monitor GPU
nvitop
```

Or use Task Manager → Performance → GPU

---

## 🎯 EXPECTED RESULTS

**After 30-50 epochs:**
- Training Accuracy: 85-95%
- Validation Accuracy: 75-90%
- Training time: 2-3 hours
- Model size: ~15MB (PyTorch) or ~25MB (TensorFlow)

**Your expanded dataset (80 classes vs. original 20):**
- Better coverage of Indian cuisine
- More robust predictions
- Higher accuracy for region-specific dishes

---

## 📝 COMPLETE COMMAND SEQUENCE

**Copy-paste this entire sequence:**

```powershell
# Navigate to backend
cd "C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend"

# Create and activate virtual environment
python -m venv venv_gpu
.\venv_gpu\Scripts\Activate.ps1

# Install PyTorch with CUDA
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install other dependencies
pip install tensorflow==2.15.0 Pillow numpy flask flask-cors pymongo python-dotenv bcrypt pyjwt werkzeug requests

# Verify GPU
python check_gpu.py

# Prepare dataset
python prepare_dataset.py

# Start training
python train_model.py
```

---

## 🚀 NEXT STEPS AFTER TRAINING

1. **Test the model:**
   ```powershell
   python test_model.py  # (create this to test on random images)
   ```

2. **Update Flask backend:**
   - Modify `app.py` to use PyTorch model
   - Update inference code
   - Test with Flutter app

3. **Deploy:**
   - Copy `best_food_model.pth` to production
   - Ensure PyTorch is installed on server
   - Update API endpoints

---

## ❓ FAQ

**Q: Can I use the GPU for inference in Flask?**
A: Yes! PyTorch will automatically use GPU if available. For production, consider:
- CPU inference (slower but simpler deployment)
- GPU inference (faster but requires CUDA on server)

**Q: How do I update the labels in my Flutter app?**
A: Copy the new `labels.txt` file (80 classes) and update your food expiry mapping in `create_listing_page.dart`.

**Q: Can I add more images later?**
A: Yes! Add images to respective class folders, re-run `prepare_dataset.py`, then continue training from checkpoint.

**Q: What if I don't have 6GB VRAM?**
A: Reduce batch size to 4-8 and increase accumulation steps.

---

## 📞 Support

If you encounter issues:
1. Check GPU is detected: `python check_gpu.py`
2. Verify dataset structure: `ls dataset/train`
3. Check CUDA version: `python -c "import torch; print(torch.version.cuda)"`
4. Review training logs in `training_logs/` folder

---

## ✅ Summary Checklist

- [ ] Virtual environment created and activated
- [ ] PyTorch with CUDA installed
- [ ] GPU detected successfully
- [ ] Dataset prepared (train/val/test splits)
- [ ] Training started
- [ ] Model saved after training
- [ ] Flask backend updated
- [ ] Tested with Flutter app

---

**Happy Training! 🎉**

Your RTX 4050 is perfectly capable of training this model efficiently!

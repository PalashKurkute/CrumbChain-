"""
Convert PyTorch Model to TensorFlow/Keras format
-----------------------------------------------
Converts the trained PyTorch model to TensorFlow .h5 format
for compatibility with your existing Flask backend
"""

import torch
import torch.nn as nn
from torchvision import models
import tensorflow as tf
from tensorflow import keras
import numpy as np
import json
import os

# Paths
PYTORCH_MODEL_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\models\best_food_model.pth"
TF_MODEL_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\models\food_model.h5"
LABELS_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\models\labels.txt"
DATASET_CONFIG_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\dataset\dataset_config.json"


def load_pytorch_model(checkpoint_path):
    """Load PyTorch model from checkpoint"""
    print(f"📂 Loading PyTorch checkpoint...")
    
    checkpoint = torch.load(checkpoint_path, map_location='cpu')
    num_classes = checkpoint['num_classes']
    
    # Create model architecture
    model = models.efficientnet_b0(pretrained=False)
    num_features = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(num_features, num_classes)
    
    # Load weights
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    
    print(f"✅ Loaded PyTorch model ({num_classes} classes)")
    print(f"   Val Accuracy: {checkpoint['val_acc']:.2f}%")
    
    return model, checkpoint


def create_tensorflow_model(num_classes, input_shape=(224, 224, 3)):
    """Create equivalent TensorFlow model"""
    print(f"\n🔨 Creating TensorFlow model...")
    
    # Use EfficientNetB0 in TensorFlow
    base_model = keras.applications.EfficientNetB0(
        include_top=False,
        weights='imagenet',
        input_shape=input_shape,
        pooling='avg'
    )
    
    # Add classification head
    inputs = keras.Input(shape=input_shape)
    x = base_model(inputs, training=False)
    outputs = keras.layers.Dense(num_classes, activation='softmax')(x)
    
    model = keras.Model(inputs=inputs, outputs=outputs)
    
    print(f"✅ Created TensorFlow model")
    return model


def transfer_weights_via_onnx(pytorch_model, num_classes, input_shape=(224, 224, 3)):
    """
    Transfer weights from PyTorch to TensorFlow using ONNX as intermediate
    Note: This is a simplified approach. For production, use ONNX conversion.
    """
    print(f"\n⚠️  Direct weight transfer between PyTorch EfficientNet and TF EfficientNet")
    print(f"   is complex. Using pretrained ImageNet weights and fine-tuning recommended.")
    print(f"\n   Alternative: Re-train directly in TensorFlow or use ONNX conversion.")
    
    # For now, create a TF model with ImageNet weights
    # You'll need to fine-tune this model with your dataset
    tf_model = create_tensorflow_model(num_classes, input_shape)
    
    return tf_model


def save_labels_file(class_names, output_path):
    """Save labels.txt file for inference"""
    print(f"\n💾 Saving labels file...")
    
    with open(output_path, 'w') as f:
        for class_name in class_names:
            f.write(f"{class_name}\n")
    
    print(f"✅ Saved {len(class_names)} class labels to: {output_path}")


def test_model(model, class_names):
    """Test the TensorFlow model with a dummy input"""
    print(f"\n🧪 Testing TensorFlow model...")
    
    # Create dummy input
    dummy_input = np.random.rand(1, 224, 224, 3).astype(np.float32)
    
    # Run inference
    predictions = model.predict(dummy_input, verbose=0)
    predicted_class = np.argmax(predictions[0])
    confidence = predictions[0][predicted_class]
    
    print(f"✅ Model test successful!")
    print(f"   Input shape: {dummy_input.shape}")
    print(f"   Output shape: {predictions.shape}")
    print(f"   Predicted class: {class_names[predicted_class]} ({confidence*100:.2f}%)")


def create_fine_tuning_script():
    """Create a script to fine-tune the TensorFlow model"""
    script = """
# Fine-tune TensorFlow Model with Your Dataset
# --------------------------------------------
# This script shows how to fine-tune the TensorFlow model
# with your Indian food dataset

import tensorflow as tf
from tensorflow import keras
import numpy as np
import os

# Paths
DATASET_PATH = r"C:\\Coding\\PROJECTS\\Crumbchain\\CrumbChain-\\backend\\dataset"
MODEL_PATH = r"C:\\Coding\\PROJECTS\\Crumbchain\\CrumbChain-\\backend\\models\\food_model.h5"

# Configuration
BATCH_SIZE = 16
EPOCHS = 50
IMG_SIZE = (224, 224)

# Data augmentation
train_datagen = keras.preprocessing.image.ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    zoom_range=0.2
)

val_datagen = keras.preprocessing.image.ImageDataGenerator(rescale=1./255)

# Load datasets
train_generator = train_datagen.flow_from_directory(
    os.path.join(DATASET_PATH, 'train'),
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_generator = val_datagen.flow_from_directory(
    os.path.join(DATASET_PATH, 'val'),
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

# Load model
model = keras.models.load_model(MODEL_PATH)

# Compile
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=0.0001),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

# Train
history = model.fit(
    train_generator,
    epochs=EPOCHS,
    validation_data=val_generator,
    callbacks=[
        keras.callbacks.ModelCheckpoint(
            'models/food_model_finetuned.h5',
            save_best_only=True,
            monitor='val_accuracy',
            mode='max'
        ),
        keras.callbacks.EarlyStopping(
            monitor='val_accuracy',
            patience=10,
            restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5
        )
    ]
)

print("Fine-tuning complete!")
"""
    
    script_path = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\finetune_tensorflow.py"
    with open(script_path, 'w') as f:
        f.write(script)
    
    print(f"\n📝 Created fine-tuning script: {script_path}")


def main():
    """Main conversion function"""
    print("=" * 70)
    print("🔄 PYTORCH TO TENSORFLOW MODEL CONVERSION")
    print("=" * 70)
    
    # Check if PyTorch model exists
    if not os.path.exists(PYTORCH_MODEL_PATH):
        print(f"\n❌ PyTorch model not found at: {PYTORCH_MODEL_PATH}")
        print(f"   Please train the model first using: python train_model.py")
        return
    
    # Load PyTorch model
    pytorch_model, checkpoint = load_pytorch_model(PYTORCH_MODEL_PATH)
    num_classes = checkpoint['num_classes']
    class_names = checkpoint['class_names']
    
    # Create TensorFlow model
    print(f"\n{'='*70}")
    print(f"⚠️  IMPORTANT NOTE:")
    print(f"{'='*70}")
    print(f"Direct weight conversion from PyTorch EfficientNet to TensorFlow")
    print(f"is complex and may not preserve exact accuracy.")
    print(f"\n📋 RECOMMENDED APPROACHES:")
    print(f"\n1. Use PyTorch model for inference (convert backend to PyTorch)")
    print(f"   - Best accuracy preservation")
    print(f"   - Simpler deployment")
    print(f"\n2. Re-train directly in TensorFlow")
    print(f"   - Run: python finetune_tensorflow.py")
    print(f"   - Guaranteed compatibility")
    print(f"\n3. Use ONNX for conversion (advanced)")
    print(f"   - Requires onnx and onnx-tf packages")
    print(f"{'='*70}")
    
    choice = input(f"\nCreate TensorFlow model with ImageNet weights for fine-tuning? (y/n): ")
    
    if choice.lower() == 'y':
        # Create TensorFlow model
        tf_model = create_tensorflow_model(num_classes)
        
        # Save model
        print(f"\n💾 Saving TensorFlow model...")
        tf_model.save(TF_MODEL_PATH)
        print(f"✅ Saved to: {TF_MODEL_PATH}")
        
        # Save labels
        save_labels_file(class_names, LABELS_PATH)
        
        # Test model
        test_model(tf_model, class_names)
        
        # Create fine-tuning script
        create_fine_tuning_script()
        
        print(f"\n{'='*70}")
        print(f"✅ CONVERSION COMPLETE")
        print(f"{'='*70}")
        print(f"\n⚠️  The saved model has ImageNet weights.")
        print(f"   To use your trained weights, you need to:")
        print(f"\n   Option 1: Fine-tune with your dataset")
        print(f"      python finetune_tensorflow.py")
        print(f"\n   Option 2: Update backend to use PyTorch")
        print(f"      (Recommended for best accuracy)")
        print(f"{'='*70}\n")
    else:
        print(f"\n✅ Keeping PyTorch model.")
        print(f"   Consider updating your backend to use PyTorch for inference.")


if __name__ == "__main__":
    main()

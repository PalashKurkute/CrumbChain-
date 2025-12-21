"""
Train EfficientNet-B2 model with combined 93 food categories
Includes both popular foods (samosa, pizza, momos) and traditional Indian dishes
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models
from PIL import Image
import os
import random
import numpy as np
from tqdm import tqdm
import json
from datetime import datetime

# Set random seeds for reproducibility
def set_seed(seed=42):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

set_seed(42)

# Configuration
class Config:
    # Get script directory to make paths absolute
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    
    # Paths
    DATASET_ROOT = os.path.join(SCRIPT_DIR, 'dataset')
    LABELS_FILE = os.path.join(SCRIPT_DIR, 'models', 'labels_combined.txt')
    MODEL_SAVE_PATH = os.path.join(SCRIPT_DIR, 'models', 'best_food_model_combined.pth')
    CHECKPOINT_DIR = os.path.join(SCRIPT_DIR, 'models', 'checkpoints')
    
    # Training parameters
    BATCH_SIZE = 32  # Fastest speed for RTX 4050 (6GB VRAM)
    NUM_EPOCHS = 50
    LEARNING_RATE = 0.001
    WEIGHT_DECAY = 1e-4
    
    # Model parameters
    IMG_SIZE = 224
    NUM_WORKERS = 8  # Increased for better CPU utilization
    
    # Training split
    TRAIN_SPLIT = 0.8
    VAL_SPLIT = 0.2
    
    # Device
    DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    # Early stopping
    PATIENCE = 10
    MIN_DELTA = 0.001

# Create checkpoint directory
os.makedirs(Config.CHECKPOINT_DIR, exist_ok=True)

# Load labels
def load_labels(labels_file):
    """Load food category labels from file"""
    with open(labels_file, 'r') as f:
        labels = [line.strip() for line in f.readlines() if line.strip()]
    return labels

# Custom Dataset
class FoodDataset(Dataset):
    def __init__(self, image_paths, labels, transform=None):
        self.image_paths = image_paths
        self.labels = labels
        self.transform = transform
    
    def __len__(self):
        return len(self.image_paths)
    
    def __getitem__(self, idx):
        img_path = self.image_paths[idx]
        label = self.labels[idx]
        
        try:
            image = Image.open(img_path).convert('RGB')
            
            if self.transform:
                image = self.transform(image)
            
            return image, label
        except Exception as e:
            print(f"Error loading image {img_path}: {e}")
            # Return a black image if loading fails
            if self.transform:
                return self.transform(Image.new('RGB', (224, 224))), label
            return Image.new('RGB', (224, 224)), label

# Data preparation
def prepare_dataset(dataset_root, food_labels):
    """
    Prepare dataset by scanning the dataset folder for food categories
    Supports both flat and split structures:
    
    Flat structure:
    dataset/
        adhirasam/
            img1.jpg
        samosa/
            img1.jpg
    
    Split structure (will be used):
    dataset/
        train/
            adhirasam/
                img1.jpg
            samosa/
                img1.jpg
        val/
            adhirasam/
                img1.jpg
        test/
            adhirasam/
                img1.jpg
    """
    all_images_train = []
    all_labels_train = []
    all_images_val = []
    all_labels_val = []
    
    label_to_idx = {label: idx for idx, label in enumerate(food_labels)}
    
    print(f"\n🔍 Scanning dataset directory: {dataset_root}")
    print(f"📋 Looking for {len(food_labels)} food categories...")
    
    # Check if we have train/val/test structure
    train_dir = os.path.join(dataset_root, 'train')
    val_dir = os.path.join(dataset_root, 'val')
    test_dir = os.path.join(dataset_root, 'test')
    
    has_splits = os.path.exists(train_dir) and os.path.exists(val_dir)
    
    if has_splits:
        print("✓ Detected train/val/test split structure")
        
        # Process training data
        missing_categories = []
        found_categories = []
        
        for food_name in food_labels:
            food_train_dir = os.path.join(train_dir, food_name)
            food_val_dir = os.path.join(val_dir, food_name)
            
            if not os.path.exists(food_train_dir):
                missing_categories.append(food_name)
                continue
            
            # Get train images
            train_images = []
            for ext in ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG']:
                import glob
                train_images.extend(glob.glob(os.path.join(food_train_dir, ext)))
            
            # Get val images
            val_images = []
            if os.path.exists(food_val_dir):
                for ext in ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG']:
                    val_images.extend(glob.glob(os.path.join(food_val_dir, ext)))
            
            if len(train_images) == 0:
                missing_categories.append(food_name)
                continue
            
            found_categories.append(food_name)
            label_idx = label_to_idx[food_name]
            
            # Add to lists
            for img_path in train_images:
                all_images_train.append(img_path)
                all_labels_train.append(label_idx)
            
            for img_path in val_images:
                all_images_val.append(img_path)
                all_labels_val.append(label_idx)
            
            print(f"  ✓ {food_name}: {len(train_images)} train, {len(val_images)} val images")
        
        print(f"\n✅ Found {len(found_categories)} categories with images")
        print(f"❌ Missing {len(missing_categories)} categories")
        
        if missing_categories:
            print("\n⚠️  Missing categories (need to collect images):")
            for cat in missing_categories[:10]:
                print(f"    - {cat}")
            if len(missing_categories) > 10:
                print(f"    ... and {len(missing_categories) - 10} more")
        
        print(f"\n📊 Total training images: {len(all_images_train)}")
        print(f"📊 Total validation images: {len(all_images_val)}")
        
        if len(all_images_train) == 0:
            raise ValueError("No images found! Please check your dataset structure.")
        
        return (all_images_train, all_labels_train, 
                all_images_val, all_labels_val, label_to_idx)
    
    else:
        # Original flat structure handling
        all_images = []
        all_labels = []
        missing_categories = []
        found_categories = []
        
        for food_name in food_labels:
            food_dir = os.path.join(dataset_root, food_name)
            
            if not os.path.exists(food_dir):
                missing_categories.append(food_name)
                continue
            
            image_files = []
            for ext in ['*.jpg', '*.jpeg', '*.png', '*.JPG', '*.JPEG', '*.PNG']:
                import glob
                image_files.extend(glob.glob(os.path.join(food_dir, ext)))
            
            if len(image_files) == 0:
                missing_categories.append(food_name)
                continue
            
            found_categories.append(food_name)
            label_idx = label_to_idx[food_name]
            
            for img_path in image_files:
                all_images.append(img_path)
                all_labels.append(label_idx)
            
            print(f"  ✓ {food_name}: {len(image_files)} images")
        
        print(f"\n✅ Found {len(found_categories)} categories with images")
        print(f"❌ Missing {len(missing_categories)} categories")
        
        if missing_categories:
            print("\n⚠️  Missing categories (need to collect images):")
            for cat in missing_categories[:10]:
                print(f"    - {cat}")
            if len(missing_categories) > 10:
                print(f"    ... and {len(missing_categories) - 10} more")
        
        print(f"\n📊 Total images found: {len(all_images)}")
        
        if len(all_images) == 0:
            raise ValueError("No images found! Please check your dataset structure.")
        
        # Split into train/val
        from sklearn.model_selection import train_test_split
        train_idx, val_idx = train_test_split(
            range(len(all_images)), 
            test_size=Config.VAL_SPLIT, 
            random_state=42
        )
        
        all_images_train = [all_images[i] for i in train_idx]
        all_labels_train = [all_labels[i] for i in train_idx]
        all_images_val = [all_images[i] for i in val_idx]
        all_labels_val = [all_labels[i] for i in val_idx]
        
        return (all_images_train, all_labels_train, 
                all_images_val, all_labels_val, label_to_idx)

# Data transforms
def get_transforms(is_training=True):
    if is_training:
        return transforms.Compose([
            transforms.Resize((256, 256)),
            transforms.RandomCrop(224),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    else:
        return transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

# Model creation
def create_model(num_classes):
    """Create EfficientNet-B2 model with custom classifier"""
    model = models.efficientnet_b2(pretrained=True)
    
    # Get the number of features in the last layer
    num_features = model.classifier[1].in_features
    
    # Replace classifier
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.3, inplace=True),
        nn.Linear(num_features, 256),
        nn.BatchNorm1d(256, momentum=0.99, eps=0.001),
        nn.ReLU(inplace=True),
        nn.Dropout(p=0.45),
        nn.Linear(256, num_classes),
    )
    
    return model

# Training function
def train_epoch(model, dataloader, criterion, optimizer, device):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    progress_bar = tqdm(dataloader, desc='Training')
    
    for images, labels in progress_bar:
        images, labels = images.to(device), labels.to(device)
        
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        
        running_loss += loss.item()
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()
        
        progress_bar.set_postfix({
            'loss': running_loss / (progress_bar.n + 1),
            'acc': 100. * correct / total
        })
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc

# Validation function
def validate(model, dataloader, criterion, device):
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    with torch.no_grad():
        progress_bar = tqdm(dataloader, desc='Validation')
        
        for images, labels in progress_bar:
            images, labels = images.to(device), labels.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, labels)
            
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
            
            progress_bar.set_postfix({
                'loss': running_loss / (progress_bar.n + 1),
                'acc': 100. * correct / total
            })
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc

# Main training function
def main():
    print("=" * 80)
    print("🍕 Training Combined Food Recognition Model (93 Categories)")
    print("=" * 80)
    print(f"Device: {Config.DEVICE}")
    print(f"Batch size: {Config.BATCH_SIZE}")
    print(f"Learning rate: {Config.LEARNING_RATE}")
    print(f"Epochs: {Config.NUM_EPOCHS}")
    print("=" * 80)
    
    # Load labels
    food_labels = load_labels(Config.LABELS_FILE)
    num_classes = len(food_labels)
    print(f"\n📋 Loaded {num_classes} food categories")
    print(f"Includes: samosa, pizza, momos, burger, and 89 more dishes")
    
    # Prepare dataset (returns either split or flat data)
    result = prepare_dataset(Config.DATASET_ROOT, food_labels)
    train_images, train_labels, val_images, val_labels, label_to_idx = result
    
    print(f"\n📊 Dataset ready:")
    print(f"  Training: {len(train_images)} images")
    print(f"  Validation: {len(val_images)} images")
    
    # Create datasets
    train_dataset = FoodDataset(train_images, train_labels, get_transforms(is_training=True))
    val_dataset = FoodDataset(val_images, val_labels, get_transforms(is_training=False))
    
    # Create dataloaders
    train_loader = DataLoader(
        train_dataset, 
        batch_size=Config.BATCH_SIZE, 
        shuffle=True, 
        num_workers=Config.NUM_WORKERS,
        pin_memory=True,
        persistent_workers=True  # Keep workers alive between epochs
    )
    val_loader = DataLoader(
        val_dataset, 
        batch_size=Config.BATCH_SIZE, 
        shuffle=False, 
        num_workers=Config.NUM_WORKERS,
        pin_memory=True,
        persistent_workers=True  # Keep workers alive between epochs
    )
    
    # Create model
    print(f"\n🏗️  Creating EfficientNet-B2 model with {num_classes} classes...")
    model = create_model(num_classes)
    model = model.to(Config.DEVICE)
    
    # Loss and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=Config.LEARNING_RATE, weight_decay=Config.WEIGHT_DECAY)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.5, patience=5, verbose=True)
    
    # Training loop
    best_val_acc = 0.0
    patience_counter = 0
    training_history = []
    
    print("\n🚀 Starting training...\n")
    
    for epoch in range(Config.NUM_EPOCHS):
        print(f"\nEpoch {epoch + 1}/{Config.NUM_EPOCHS}")
        print("-" * 50)
        
        # Train
        train_loss, train_acc = train_epoch(model, train_loader, criterion, optimizer, Config.DEVICE)
        print(f"Train Loss: {train_loss:.4f} | Train Acc: {train_acc:.2f}%")
        
        # Validate
        val_loss, val_acc = validate(model, val_loader, criterion, Config.DEVICE)
        print(f"Val Loss: {val_loss:.4f} | Val Acc: {val_acc:.2f}%")
        
        # Learning rate scheduling
        scheduler.step(val_acc)
        
        # Save training history
        training_history.append({
            'epoch': epoch + 1,
            'train_loss': train_loss,
            'train_acc': train_acc,
            'val_loss': val_loss,
            'val_acc': val_acc
        })
        
        # Save checkpoint
        if val_acc > best_val_acc + Config.MIN_DELTA:
            print(f"✅ Validation accuracy improved from {best_val_acc:.2f}% to {val_acc:.2f}%")
            best_val_acc = val_acc
            patience_counter = 0
            
            # Save best model
            checkpoint = {
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_acc': val_acc,
                'val_loss': val_loss,
                'num_classes': num_classes,
                'food_labels': food_labels,
                'label_to_idx': label_to_idx
            }
            torch.save(checkpoint, Config.MODEL_SAVE_PATH)
            print(f"💾 Model saved to {Config.MODEL_SAVE_PATH}")
            
            # Also save a dated checkpoint
            checkpoint_path = os.path.join(
                Config.CHECKPOINT_DIR, 
                f"model_epoch{epoch+1}_acc{val_acc:.2f}.pth"
            )
            torch.save(checkpoint, checkpoint_path)
        else:
            patience_counter += 1
            print(f"⏳ No improvement. Patience: {patience_counter}/{Config.PATIENCE}")
        
        # Early stopping
        if patience_counter >= Config.PATIENCE:
            print(f"\n⏹️  Early stopping triggered after {epoch + 1} epochs")
            break
    
    # Save training history
    history_path = 'models/training_history_combined.json'
    with open(history_path, 'w') as f:
        json.dump(training_history, f, indent=2)
    
    print("\n" + "=" * 80)
    print("🎉 Training completed!")
    print(f"Best validation accuracy: {best_val_acc:.2f}%")
    print(f"Model saved to: {Config.MODEL_SAVE_PATH}")
    print(f"Training history saved to: {history_path}")
    print("=" * 80)
    
    # Print summary
    print("\n📊 Model Summary:")
    print(f"  Total food categories: {num_classes}")
    print(f"  Popular foods included: samosa, pizza, momos, burger, chai, pakode")
    print(f"  Traditional foods included: biryani, dosa, gulab jamun, etc.")
    print(f"  Total parameters: {sum(p.numel() for p in model.parameters()):,}")
    print(f"  Trainable parameters: {sum(p.numel() for p in model.parameters() if p.requires_grad):,}")

if __name__ == "__main__":
    main()

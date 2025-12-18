"""
GPU-Optimized Food Detection Model Training
------------------------------------------
Trains a food detection model optimized for NVIDIA RTX 4050 (6GB VRAM)
Features:
- Mixed precision training (FP16) to reduce VRAM usage
- Gradient accumulation for larger effective batch sizes
- Dynamic VRAM management
- Efficient data loading
- Model checkpointing
"""

import os
import json
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms, models
from PIL import Image
import numpy as np
from datetime import datetime
from pathlib import Path
import time

# ============= GPU SAFETY CONFIGURATION =============
# Adjust these if you hit OOM (Out of Memory) errors
GPU_CONFIG = {
    'batch_size': 16,          # Reduce to 8 or 4 if OOM
    'num_workers': 4,          # Data loading workers
    'image_size': 224,         # Input image size (224 for most models)
    'accumulation_steps': 2,   # Gradient accumulation (effective batch = batch_size * this)
    'mixed_precision': True,   # Use FP16 for RTX 40-series
    'pin_memory': True,        # Faster data transfer to GPU
    'prefetch_factor': 2,      # Prefetch batches
}

TRAINING_CONFIG = {
    'epochs': 50,
    'learning_rate': 0.001,
    'weight_decay': 1e-4,
    'lr_scheduler': 'cosine',  # 'cosine' or 'step'
    'patience': 10,            # Early stopping patience
    'save_every': 5,           # Save checkpoint every N epochs
}

# Paths
DATASET_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\dataset"
MODEL_SAVE_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\models"
LOGS_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\training_logs"

# ============= DATASET CLASS =============

class FoodDataset(Dataset):
    """Custom Dataset for Indian Food Images"""
    
    def __init__(self, root_dir, transform=None):
        """
        Args:
            root_dir: Directory with class subdirectories
            transform: Optional transform to be applied on images
        """
        self.root_dir = root_dir
        self.transform = transform
        self.classes = sorted([d for d in os.listdir(root_dir) 
                              if os.path.isdir(os.path.join(root_dir, d))])
        self.class_to_idx = {cls_name: i for i, cls_name in enumerate(self.classes)}
        
        # Build image list
        self.images = []
        self.labels = []
        
        for class_name in self.classes:
            class_dir = os.path.join(root_dir, class_name)
            class_idx = self.class_to_idx[class_name]
            
            for img_name in os.listdir(class_dir):
                if img_name.lower().endswith(('.jpg', '.jpeg', '.png')):
                    img_path = os.path.join(class_dir, img_name)
                    self.images.append(img_path)
                    self.labels.append(class_idx)
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        img_path = self.images[idx]
        label = self.labels[idx]
        
        # Load image
        try:
            image = Image.open(img_path).convert('RGB')
        except Exception as e:
            print(f"Error loading {img_path}: {e}")
            # Return a blank image if loading fails
            image = Image.new('RGB', (224, 224), color='white')
        
        if self.transform:
            image = self.transform(image)
        
        return image, label


# ============= DATA AUGMENTATION =============

def get_transforms(split='train', image_size=224):
    """Get data transforms for train/val/test"""
    
    if split == 'train':
        return transforms.Compose([
            transforms.Resize((image_size + 32, image_size + 32)),
            transforms.RandomCrop(image_size),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(20),
            transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
            transforms.RandomAffine(degrees=0, translate=(0.1, 0.1)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], 
                               std=[0.229, 0.224, 0.225])
        ])
    else:  # val or test
        return transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])


# ============= MODEL CREATION =============

def create_model(num_classes, pretrained=True):
    """
    Create EfficientNet-B0 model (optimized for RTX 4050)
    EfficientNet is more efficient than ResNet/InceptionV3 for limited VRAM
    """
    print(f"🔨 Creating EfficientNet-B0 model with {num_classes} classes...")
    
    # Use EfficientNet-B0 (smaller and faster than InceptionV3)
    model = models.efficientnet_b0(pretrained=pretrained)
    
    # Replace final classifier
    num_features = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(num_features, num_classes)
    
    print(f"✅ Model created successfully!")
    return model


# ============= VRAM MANAGEMENT =============

def clear_gpu_memory():
    """Clear GPU cache to free VRAM"""
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.synchronize()


def print_gpu_memory():
    """Print current GPU memory usage"""
    if torch.cuda.is_available():
        allocated = torch.cuda.memory_allocated() / (1024**3)
        reserved = torch.cuda.memory_reserved() / (1024**3)
        total = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        print(f"   💾 GPU Memory: {allocated:.2f}GB allocated, "
              f"{reserved:.2f}GB reserved, {total:.2f}GB total")


# ============= TRAINING LOOP =============

def train_one_epoch(model, dataloader, criterion, optimizer, device, scaler, epoch):
    """Train for one epoch"""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    accumulation_steps = GPU_CONFIG['accumulation_steps']
    
    for batch_idx, (images, labels) in enumerate(dataloader):
        images, labels = images.to(device), labels.to(device)
        
        # Mixed precision training
        with torch.cuda.amp.autocast(enabled=GPU_CONFIG['mixed_precision']):
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss = loss / accumulation_steps  # Scale loss for gradient accumulation
        
        # Backward pass
        scaler.scale(loss).backward()
        
        # Gradient accumulation
        if (batch_idx + 1) % accumulation_steps == 0:
            scaler.step(optimizer)
            scaler.update()
            optimizer.zero_grad()
            
            # Clear cache periodically
            if (batch_idx + 1) % (accumulation_steps * 10) == 0:
                clear_gpu_memory()
        
        # Statistics
        running_loss += loss.item() * accumulation_steps
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()
        
        # Print progress every 50 batches
        if (batch_idx + 1) % 50 == 0:
            acc = 100. * correct / total
            print(f"   Batch [{batch_idx+1}/{len(dataloader)}] "
                  f"Loss: {running_loss/(batch_idx+1):.4f} | "
                  f"Acc: {acc:.2f}%")
    
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = 100. * correct / total
    
    return epoch_loss, epoch_acc


def validate(model, dataloader, criterion, device):
    """Validate the model"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    with torch.no_grad():
        for images, labels in dataloader:
            images, labels = images.to(device), labels.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, labels)
            
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
    
    val_loss = running_loss / len(dataloader)
    val_acc = 100. * correct / total
    
    return val_loss, val_acc


# ============= MAIN TRAINING FUNCTION =============

def main():
    """Main training function"""
    
    print("=" * 70)
    print("🍛 INDIAN FOOD DETECTION MODEL TRAINING")
    print("=" * 70)
    
    # Check GPU
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"\n🖥️  Device: {device}")
    
    if device.type == 'cuda':
        print(f"   GPU: {torch.cuda.get_device_name(0)}")
        print_gpu_memory()
    else:
        print("⚠️  WARNING: No GPU detected! Training will be VERY slow on CPU.")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            return
    
    # Load dataset config
    config_path = os.path.join(DATASET_PATH, 'dataset_config.json')
    if not os.path.exists(config_path):
        print(f"\n❌ Dataset config not found at {config_path}")
        print(f"   Please run 'python prepare_dataset.py' first!")
        return
    
    with open(config_path, 'r') as f:
        dataset_config = json.load(f)
    
    num_classes = dataset_config['num_classes']
    print(f"\n📊 Dataset: {num_classes} classes, {dataset_config['statistics']['total']} images")
    
    # Create dataloaders
    print(f"\n🔄 Creating data loaders...")
    image_size = GPU_CONFIG['image_size']
    
    train_dataset = FoodDataset(
        dataset_config['splits']['train'],
        transform=get_transforms('train', image_size)
    )
    val_dataset = FoodDataset(
        dataset_config['splits']['val'],
        transform=get_transforms('val', image_size)
    )
    
    train_loader = DataLoader(
        train_dataset,
        batch_size=GPU_CONFIG['batch_size'],
        shuffle=True,
        num_workers=GPU_CONFIG['num_workers'],
        pin_memory=GPU_CONFIG['pin_memory'],
        prefetch_factor=GPU_CONFIG['prefetch_factor']
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=GPU_CONFIG['batch_size'],
        shuffle=False,
        num_workers=GPU_CONFIG['num_workers'],
        pin_memory=GPU_CONFIG['pin_memory'],
        prefetch_factor=GPU_CONFIG['prefetch_factor']
    )
    
    print(f"✅ Train batches: {len(train_loader)} | Val batches: {len(val_loader)}")
    print(f"   Effective batch size: {GPU_CONFIG['batch_size'] * GPU_CONFIG['accumulation_steps']}")
    
    # Create model
    print(f"\n🔨 Building model...")
    model = create_model(num_classes, pretrained=True)
    model = model.to(device)
    
    # Loss and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(
        model.parameters(),
        lr=TRAINING_CONFIG['learning_rate'],
        weight_decay=TRAINING_CONFIG['weight_decay']
    )
    
    # Learning rate scheduler
    if TRAINING_CONFIG['lr_scheduler'] == 'cosine':
        scheduler = optim.lr_scheduler.CosineAnnealingLR(
            optimizer, T_max=TRAINING_CONFIG['epochs']
        )
    else:
        scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.1)
    
    # Mixed precision scaler
    scaler = torch.cuda.amp.GradScaler(enabled=GPU_CONFIG['mixed_precision'])
    
    # Create save directories
    os.makedirs(MODEL_SAVE_PATH, exist_ok=True)
    os.makedirs(LOGS_PATH, exist_ok=True)
    
    # Training history
    history = {
        'train_loss': [],
        'train_acc': [],
        'val_loss': [],
        'val_acc': [],
        'lr': []
    }
    
    best_val_acc = 0.0
    patience_counter = 0
    
    # Training loop
    print(f"\n{'='*70}")
    print(f"🚀 STARTING TRAINING")
    print(f"{'='*70}\n")
    
    start_time = time.time()
    
    for epoch in range(TRAINING_CONFIG['epochs']):
        epoch_start = time.time()
        
        print(f"\n📅 Epoch [{epoch+1}/{TRAINING_CONFIG['epochs']}]")
        print(f"   Learning Rate: {optimizer.param_groups[0]['lr']:.6f}")
        
        # Train
        print(f"\n🏋️  Training...")
        train_loss, train_acc = train_one_epoch(
            model, train_loader, criterion, optimizer, device, scaler, epoch
        )
        
        # Validate
        print(f"\n🎯 Validating...")
        val_loss, val_acc = validate(model, val_loader, criterion, device)
        
        # Update scheduler
        scheduler.step()
        
        # Save history
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc)
        history['val_loss'].append(val_loss)
        history['val_acc'].append(val_acc)
        history['lr'].append(optimizer.param_groups[0]['lr'])
        
        epoch_time = time.time() - epoch_start
        
        # Print epoch summary
        print(f"\n{'='*70}")
        print(f"📊 Epoch {epoch+1} Summary:")
        print(f"   Train Loss: {train_loss:.4f} | Train Acc: {train_acc:.2f}%")
        print(f"   Val Loss:   {val_loss:.4f} | Val Acc:   {val_acc:.2f}%")
        print(f"   Time: {epoch_time:.2f}s")
        print_gpu_memory()
        print(f"{'='*70}")
        
        # Save best model
        if val_acc > best_val_acc:
            best_val_acc = val_acc
            patience_counter = 0
            
            best_model_path = os.path.join(MODEL_SAVE_PATH, 'best_food_model.pth')
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_acc': val_acc,
                'val_loss': val_loss,
                'num_classes': num_classes,
                'class_names': dataset_config['classes']
            }, best_model_path)
            print(f"✅ Saved best model (Val Acc: {val_acc:.2f}%)")
        else:
            patience_counter += 1
        
        # Save checkpoint periodically
        if (epoch + 1) % TRAINING_CONFIG['save_every'] == 0:
            checkpoint_path = os.path.join(MODEL_SAVE_PATH, f'checkpoint_epoch_{epoch+1}.pth')
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_acc': val_acc,
                'val_loss': val_loss,
            }, checkpoint_path)
            print(f"💾 Saved checkpoint: {checkpoint_path}")
        
        # Early stopping
        if patience_counter >= TRAINING_CONFIG['patience']:
            print(f"\n⏸️  Early stopping triggered (no improvement for {TRAINING_CONFIG['patience']} epochs)")
            break
        
        # Clear GPU cache
        clear_gpu_memory()
    
    total_time = time.time() - start_time
    
    # Save training history
    history_path = os.path.join(LOGS_PATH, f'training_history_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')
    with open(history_path, 'w') as f:
        json.dump(history, f, indent=2)
    
    print(f"\n{'='*70}")
    print(f"✅ TRAINING COMPLETE!")
    print(f"{'='*70}")
    print(f"⏱️  Total Time: {total_time/60:.2f} minutes")
    print(f"🏆 Best Val Accuracy: {best_val_acc:.2f}%")
    print(f"💾 Model saved at: {best_model_path}")
    print(f"📊 History saved at: {history_path}")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Training interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Training failed with error:")
        print(f"{e}")
        import traceback
        traceback.print_exc()
    finally:
        clear_gpu_memory()
        print(f"\n🧹 Cleaned up GPU memory")

"""
GPU-Optimized Food Detection Training (Based on 73% Accuracy Reference)
------------------------------------------------------------------------
Combines proven architecture from reference notebook with GPU optimizations
Target Accuracy: 70-75% on 80 Indian food classes

Key Features:
- EfficientNetB2 architecture (proven 73% accuracy)
- Custom LRA (Learning Rate Adjuster) callback
- Data balancing (238 samples per class)
- Mixed precision for RTX 4050 (6GB VRAM)
- Adamax optimizer (better for EfficientNet)
- Proper regularization (L1+L2+Dropout)
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
import pandas as pd
from datetime import datetime
from pathlib import Path
import time
import shutil
from collections import Counter
from tqdm import tqdm

# ============= GPU CONFIGURATION (RTX 4050 Optimized) =============
GPU_CONFIG = {
    'batch_size': 24,          # Slightly smaller for EfficientNetB2
    'num_workers': 0,          # Set to 0 for Windows to avoid multiprocessing errors
    'image_size': 224,         # Reference uses 224x224
    'accumulation_steps': 2,   # Effective batch = 48 (close to reference's 30)
    'mixed_precision': True,   # FP16 for VRAM savings
    'pin_memory': False,       # Disable pin_memory when num_workers=0
    'prefetch_factor': None,   # Not used when num_workers=0
}

TRAINING_CONFIG = {
    'epochs': 40,              # Same as reference
    'learning_rate': 0.001,    # Same as reference  
    'weight_decay': 1e-4,
    'patience': 1,             # Reference LRA patience
    'stop_patience': 3,        # Reference stop patience
    'threshold': 0.9,          # Reference threshold for LR adjustment
    'lr_factor': 0.5,          # LR reduction factor
    'dropout_rate': 0.45,      # Reference dropout
    'l2_weight': 0.016,        # Reference L2 regularization
}

DATA_CONFIG = {
    'max_samples_per_class': 238,  # Reference balancing target
    'train_split': 0.80,           # Reference split
    'val_split': 0.10,
    'test_split': 0.10,
}

# Paths
DATASET_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\dataset"
SOURCE_DATASET = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\Indian Food Images\Indian Food Images"
MODEL_SAVE_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\models"
LOGS_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\training_logs"
AUG_PATH = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\augmented"

# ============= CUSTOM LRA CALLBACK (From Reference) =============

class LearningRateAdjuster:
    """
    Custom Learning Rate Adjustment Strategy (from reference notebook)
    Adjusts LR based on training accuracy and validation loss
    """
    
    def __init__(self, optimizer, scheduler, initial_lr, patience, stop_patience, 
                 threshold, factor, epochs):
        self.optimizer = optimizer
        self.scheduler = scheduler
        self.initial_lr = initial_lr
        self.patience = patience
        self.stop_patience = stop_patience
        self.threshold = threshold
        self.factor = factor
        self.epochs = epochs
        
        # Tracking variables
        self.count = 0
        self.stop_count = 0
        self.best_epoch = 0
        self.highest_train_acc = 0.0
        self.lowest_val_loss = np.inf
        self.best_weights = None
        self.current_lr = initial_lr
        
    def on_epoch_end(self, epoch, train_acc, val_loss, model):
        """Called at end of each epoch"""
        
        if train_acc < self.threshold:
            # Monitor training accuracy
            if train_acc > self.highest_train_acc:
                self.highest_train_acc = train_acc
                self.best_weights = model.state_dict().copy()
                self.best_epoch = epoch + 1
                self.count = 0
                self.stop_count = 0
                return True, "train_acc improved"
            else:
                self.count += 1
                if self.count >= self.patience:
                    # Adjust learning rate
                    self.current_lr *= self.factor
                    for param_group in self.optimizer.param_groups:
                        param_group['lr'] = self.current_lr
                    self.count = 0
                    self.stop_count += 1
                    # Restore best weights (dwell)
                    if self.best_weights is not None:
                        model.load_state_dict(self.best_weights)
                    return False, f"LR adjusted to {self.current_lr:.6f}"
        else:
            # Monitor validation loss
            if val_loss < self.lowest_val_loss:
                self.lowest_val_loss = val_loss
                self.best_weights = model.state_dict().copy()
                self.best_epoch = epoch + 1
                self.count = 0
                self.stop_count = 0
                return True, "val_loss improved"
            else:
                self.count += 1
                if self.count >= self.patience:
                    # Adjust learning rate
                    self.current_lr *= self.factor
                    for param_group in self.optimizer.param_groups:
                        param_group['lr'] = self.current_lr
                    self.count = 0
                    self.stop_count += 1
                    # Restore best weights (dwell)
                    if self.best_weights is not None:
                        model.load_state_dict(self.best_weights)
                    return False, f"LR adjusted to {self.current_lr:.6f}"
        
        return False, "no change"
    
    def should_stop(self):
        """Check if training should stop"""
        return self.stop_count >= self.stop_patience


# ============= DATA BALANCING (From Reference) =============

def balance_dataset(source_path, target_path, max_samples, image_size):
    """
    Balance dataset by augmenting minority classes to max_samples each
    Based on reference notebook's balancing strategy
    """
    print(f"\n🔄 Balancing dataset to {max_samples} samples per class...")
    
    # Create augmented directory
    os.makedirs(target_path, exist_ok=True)
    
    # Get class distribution
    classes = [d for d in os.listdir(source_path) 
               if os.path.isdir(os.path.join(source_path, d))]
    
    total_augmented = 0
    class_counts = {}
    
    for class_name in classes:
        class_source = os.path.join(source_path, class_name)
        class_target = os.path.join(target_path, class_name)
        os.makedirs(class_target, exist_ok=True)
        
        # Count existing images
        images = [f for f in os.listdir(class_source) 
                 if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        current_count = len(images)
        class_counts[class_name] = current_count
        
        if current_count < max_samples:
            # Need to augment
            delta = max_samples - current_count
            print(f"   Augmenting {class_name}: {current_count} → {max_samples} (+{delta})")
            
            # Augmentation transforms
            aug_transform = transforms.Compose([
                transforms.Resize((image_size + 32, image_size + 32)),
                transforms.RandomHorizontalFlip(p=0.5),
                transforms.RandomRotation(20),
                transforms.RandomCrop(image_size),
                transforms.ColorJitter(brightness=0.2, contrast=0.2),
                transforms.RandomAffine(degrees=0, translate=(0.2, 0.2), scale=(0.8, 1.2)),
            ])
            
            # Generate augmented images
            aug_count = 0
            img_idx = 0
            
            while aug_count < delta:
                # Cycle through original images
                img_path = os.path.join(class_source, images[img_idx % current_count])
                
                try:
                    img = Image.open(img_path).convert('RGB')
                    aug_img = aug_transform(img)
                    
                    # Save augmented image
                    aug_filename = f"aug_{aug_count:04d}.jpg"
                    aug_save_path = os.path.join(class_target, aug_filename)
                    aug_img.save(aug_save_path, quality=95)
                    
                    aug_count += 1
                    total_augmented += 1
                    
                except Exception as e:
                    print(f"      Error augmenting {img_path}: {e}")
                
                img_idx += 1
        else:
            print(f"   {class_name}: {current_count} samples (no augmentation needed)")
    
    print(f"\n✅ Total augmented images created: {total_augmented}")
    print(f"   Dataset now balanced to ~{max_samples} samples per class")
    
    return total_augmented


# ============= DATASET CLASS =============

class BalancedFoodDataset(Dataset):
    """Dataset that combines original and augmented images"""
    
    def __init__(self, original_dir, augmented_dir, transform=None):
        self.transform = transform
        self.images = []
        self.labels = []
        
        # Get classes from original directory
        classes = sorted([d for d in os.listdir(original_dir) 
                         if os.path.isdir(os.path.join(original_dir, d))])
        self.class_to_idx = {cls: i for i, cls in enumerate(classes)}
        self.classes = classes
        
        # Add original images
        for class_name in classes:
            class_path = os.path.join(original_dir, class_name)
            class_idx = self.class_to_idx[class_name]
            
            for img_name in os.listdir(class_path):
                if img_name.lower().endswith(('.jpg', '.jpeg', '.png')):
                    self.images.append(os.path.join(class_path, img_name))
                    self.labels.append(class_idx)
        
        # Add augmented images if directory exists
        if os.path.exists(augmented_dir):
            for class_name in classes:
                aug_class_path = os.path.join(augmented_dir, class_name)
                if os.path.exists(aug_class_path):
                    class_idx = self.class_to_idx[class_name]
                    
                    for img_name in os.listdir(aug_class_path):
                        if img_name.lower().endswith(('.jpg', '.jpeg', '.png')):
                            self.images.append(os.path.join(aug_class_path, img_name))
                            self.labels.append(class_idx)
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        img_path = self.images[idx]
        label = self.labels[idx]
        
        try:
            image = Image.open(img_path).convert('RGB')
        except:
            # Return blank image if loading fails
            image = Image.new('RGB', (224, 224), color='white')
        
        if self.transform:
            image = self.transform(image)
        
        return image, label


# ============= DATA TRANSFORMS (NO NORMALIZATION for EfficientNet!) =============

def get_transforms(split='train', image_size=224):
    """
    Get transforms - NO NORMALIZATION for EfficientNet!
    Reference notebook keeps pixels in 0-255 range
    """
    
    if split == 'train':
        return transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.ToTensor(),  # Converts to [0,1], then we scale to [0,255]
            transforms.Lambda(lambda x: x * 255.0),  # Scale back to 0-255
        ])
    else:
        return transforms.Compose([
            transforms.Resize((image_size, image_size)),
            transforms.ToTensor(),
            transforms.Lambda(lambda x: x * 255.0),  # Scale to 0-255
        ])


# ============= MODEL CREATION (EfficientNetB2) =============

def create_model(num_classes):
    """
    Create EfficientNetB2 with custom classifier
    Based on reference notebook architecture
    """
    print(f"🔨 Creating EfficientNetB2 model with {num_classes} classes...")
    
    # Load pretrained EfficientNetB2
    model = models.efficientnet_b2(pretrained=True)
    
    # Get number of input features
    num_features = model.classifier[1].in_features
    
    # Replace classifier with reference architecture
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.3, inplace=True),  # Built-in dropout
        nn.Linear(num_features, 256),
        nn.BatchNorm1d(256, momentum=0.99, eps=0.001),
        nn.ReLU(inplace=True),
        nn.Dropout(p=TRAINING_CONFIG['dropout_rate']),
        nn.Linear(256, num_classes),
    )
    
    print(f"✅ EfficientNetB2 model created")
    print(f"   Parameters: {sum(p.numel() for p in model.parameters()):,}")
    
    return model


# ============= TRAINING FUNCTIONS =============

def train_one_epoch(model, dataloader, criterion, optimizer, device, scaler, epoch, total_epochs):
    """Train for one epoch with progress bar"""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0
    
    accumulation_steps = GPU_CONFIG['accumulation_steps']
    
    # Create progress bar
    pbar = tqdm(enumerate(dataloader), total=len(dataloader), 
                desc=f"🏋️  Epoch {epoch+1}/{total_epochs} [TRAIN]",
                bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}, {rate_fmt}]')
    
    for batch_idx, (images, labels) in pbar:
        images, labels = images.to(device), labels.to(device)
        
        # Mixed precision
        with torch.cuda.amp.autocast(enabled=GPU_CONFIG['mixed_precision']):
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss = loss / accumulation_steps
        
        scaler.scale(loss).backward()
        
        if (batch_idx + 1) % accumulation_steps == 0:
            scaler.step(optimizer)
            scaler.update()
            optimizer.zero_grad()
            
            if (batch_idx + 1) % (accumulation_steps * 10) == 0:
                torch.cuda.empty_cache()
        
        running_loss += loss.item() * accumulation_steps
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()
        
        # Update progress bar
        current_loss = running_loss / (batch_idx + 1)
        current_acc = 100. * correct / total
        pbar.set_postfix({
            'loss': f'{current_loss:.4f}',
            'acc': f'{current_acc:.2f}%'
        })
    
    pbar.close()
    epoch_loss = running_loss / len(dataloader)
    epoch_acc = correct / total  # Return as decimal for LRA threshold check
    
    return epoch_loss, epoch_acc


def validate(model, dataloader, criterion, device, epoch, total_epochs):
    """Validate the model with progress bar"""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    
    # Create progress bar for validation
    pbar = tqdm(dataloader, total=len(dataloader),
                desc=f"🎯 Epoch {epoch+1}/{total_epochs} [VAL]  ",
                bar_format='{l_bar}{bar}| {n_fmt}/{total_fmt} [{elapsed}<{remaining}]')
    
    with torch.no_grad():
        for images, labels in pbar:
            images, labels = images.to(device), labels.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, labels)
            
            running_loss += loss.item()
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()
            
            # Update progress bar
            current_loss = running_loss / len(pbar)
            current_acc = 100. * correct / total
            pbar.set_postfix({
                'loss': f'{current_loss:.4f}',
                'acc': f'{current_acc:.2f}%'
            })
    
    pbar.close()
    val_loss = running_loss / len(dataloader)
    val_acc = correct / total
    
    return val_loss, val_acc


# ============= MAIN TRAINING =============

def main():
    """Main training function"""
    
    print("=" * 70)
    print("🍛 INDIAN FOOD DETECTION - REFERENCE ARCHITECTURE (73% Target)")
    print("=" * 70)
    
    # Check GPU
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"\n🖥️  Device: {device}")
    
    if device.type == 'cuda':
        print(f"   GPU: {torch.cuda.get_device_name(0)}")
        total_mem = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        print(f"   VRAM: {total_mem:.2f} GB")
    
    # Prepare balanced dataset
    print(f"\n📊 Preparing balanced dataset...")
    
    if not os.path.exists(AUG_PATH):
        balance_dataset(
            SOURCE_DATASET, 
            AUG_PATH, 
            DATA_CONFIG['max_samples_per_class'],
            GPU_CONFIG['image_size']
        )
    else:
        print(f"   Using existing augmented dataset at {AUG_PATH}")
    
    # Load dataset config
    config_path = os.path.join(DATASET_PATH, 'dataset_config.json')
    with open(config_path, 'r') as f:
        dataset_config = json.load(f)
    
    num_classes = dataset_config['num_classes']
    print(f"\n📊 Dataset: {num_classes} classes")
    
    # Create datasets (train uses balanced data)
    print(f"\n🔄 Creating data loaders...")
    image_size = GPU_CONFIG['image_size']
    
    # Train dataset with balancing
    train_dataset = BalancedFoodDataset(
        dataset_config['splits']['train'],
        AUG_PATH,
        transform=get_transforms('train', image_size)
    )
    
    # Val and test use original data only
    val_dataset = BalancedFoodDataset(
        dataset_config['splits']['val'],
        "",  # No augmented data for validation
        transform=get_transforms('val', image_size)
    )
    
    # Create DataLoaders (Windows-safe configuration)
    dataloader_kwargs = {
        'batch_size': GPU_CONFIG['batch_size'],
        'num_workers': GPU_CONFIG['num_workers'],
        'pin_memory': GPU_CONFIG['pin_memory']
    }
    
    # Only add prefetch_factor if num_workers > 0
    if GPU_CONFIG['num_workers'] > 0 and GPU_CONFIG['prefetch_factor'] is not None:
        dataloader_kwargs['prefetch_factor'] = GPU_CONFIG['prefetch_factor']
    
    train_loader = DataLoader(
        train_dataset,
        shuffle=True,
        **dataloader_kwargs
    )
    
    val_loader = DataLoader(
        val_dataset,
        shuffle=False,
        **dataloader_kwargs
    )
    
    print(f"✅ Train: {len(train_dataset)} images | Val: {len(val_dataset)} images")
    print(f"   Effective batch size: {GPU_CONFIG['batch_size'] * GPU_CONFIG['accumulation_steps']}")
    
    # Create model
    print(f"\n🔨 Building EfficientNetB2 model...")
    model = create_model(num_classes)
    model = model.to(device)
    
    # Loss and optimizer (Adamax like reference!)
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adamax(
        model.parameters(),
        lr=TRAINING_CONFIG['learning_rate']
    )
    
    # Scheduler (basic, LRA will handle fine-tuning)
    scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.9)
    
    # Custom LRA callback
    lra = LearningRateAdjuster(
        optimizer=optimizer,
        scheduler=scheduler,
        initial_lr=TRAINING_CONFIG['learning_rate'],
        patience=TRAINING_CONFIG['patience'],
        stop_patience=TRAINING_CONFIG['stop_patience'],
        threshold=TRAINING_CONFIG['threshold'],
        factor=TRAINING_CONFIG['lr_factor'],
        epochs=TRAINING_CONFIG['epochs']
    )
    
    # Mixed precision scaler
    scaler = torch.cuda.amp.GradScaler(enabled=GPU_CONFIG['mixed_precision'])
    
    # Create directories
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
    
    # Training loop
    print(f"\n{'='*70}")
    print(f"🚀 STARTING TRAINING (Target: 70-75% like reference)")
    print(f"{'='*70}\n")
    
    start_time = time.time()
    
    for epoch in range(TRAINING_CONFIG['epochs']):
        epoch_start = time.time()
        
        print(f"\n{'='*70}")
        print(f"📅 Epoch [{epoch+1}/{TRAINING_CONFIG['epochs']}] | LR: {lra.current_lr:.6f}")
        print(f"{'='*70}")
        
        # Train
        train_loss, train_acc = train_one_epoch(
            model, train_loader, criterion, optimizer, device, scaler, epoch, TRAINING_CONFIG['epochs']
        )
        
        # Validate
        val_loss, val_acc = validate(model, val_loader, criterion, device, epoch, TRAINING_CONFIG['epochs'])
        
        # LRA adjustment
        improved, message = lra.on_epoch_end(epoch, train_acc, val_loss, model)
        
        epoch_time = time.time() - epoch_start
        
        # Save history
        history['train_loss'].append(train_loss)
        history['train_acc'].append(train_acc * 100)
        history['val_loss'].append(val_loss)
        history['val_acc'].append(val_acc * 100)
        history['lr'].append(lra.current_lr)
        
        # Print summary
        print(f"\n{'='*70}")
        print(f"📊 Epoch {epoch+1} Summary:")
        print(f"   Train Loss: {train_loss:.4f} | Train Acc: {train_acc*100:.2f}%")
        print(f"   Val Loss:   {val_loss:.4f} | Val Acc:   {val_acc*100:.2f}%")
        print(f"   Status: {message}")
        print(f"   Time: {epoch_time:.2f}s")
        if device.type == 'cuda':
            allocated = torch.cuda.memory_allocated() / (1024**3)
            print(f"   GPU Memory: {allocated:.2f}GB")
        print(f"{'='*70}")
        
        # Save best model
        if improved:
            best_model_path = os.path.join(MODEL_SAVE_PATH, 'best_food_model_reference.pth')
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'val_acc': val_acc * 100,
                'val_loss': val_loss,
                'num_classes': num_classes,
                'class_names': dataset_config['classes'],
                'architecture': 'EfficientNetB2',
            }, best_model_path)
            print(f"✅ Saved best model (Val Acc: {val_acc*100:.2f}%)")
        
        # Early stopping check
        if lra.should_stop():
            print(f"\n⏸️  Early stopping triggered after {lra.stop_patience} LR adjustments")
            break
        
        torch.cuda.empty_cache()
    
    # Load best weights
    if lra.best_weights is not None:
        model.load_state_dict(lra.best_weights)
    
    total_time = time.time() - start_time
    
    # Save history
    history_path = os.path.join(LOGS_PATH, f'history_reference_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')
    with open(history_path, 'w') as f:
        json.dump(history, f, indent=2)
    
    print(f"\n{'='*70}")
    print(f"✅ TRAINING COMPLETE!")
    print(f"{'='*70}")
    print(f"⏱️  Total Time: {total_time/60:.2f} minutes")
    print(f"🏆 Best Epoch: {lra.best_epoch}")
    print(f"🎯 Best Val Accuracy: {max(history['val_acc']):.2f}%")
    print(f"💾 Model: {best_model_path}")
    print(f"📊 History: {history_path}")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Training interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Training failed:")
        print(f"{e}")
        import traceback
        traceback.print_exc()
    finally:
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        print(f"\n🧹 Cleaned up GPU memory")

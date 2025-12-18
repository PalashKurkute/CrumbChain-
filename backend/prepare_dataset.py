"""
Dataset Preparation for Indian Food Detection
--------------------------------------------
Prepares the Indian Food Images dataset for training:
- Creates train/val/test splits (70/15/15)
- Organizes images into proper structure
- Generates labels and class mappings
- Creates data configuration file
"""

import os
import shutil
import random
from pathlib import Path
import json

# Configuration
SOURCE_DATASET = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\Indian Food Images\Indian Food Images"
TARGET_DATASET = r"C:\Coding\PROJECTS\Crumbchain\CrumbChain-\backend\dataset"
TRAIN_SPLIT = 0.70  # 70% for training
VAL_SPLIT = 0.15    # 15% for validation  
TEST_SPLIT = 0.15   # 15% for testing

random.seed(42)  # For reproducibility


def create_directory_structure(base_path):
    """Create train/val/test directory structure"""
    splits = ['train', 'val', 'test']
    
    for split in splits:
        split_path = os.path.join(base_path, split)
        os.makedirs(split_path, exist_ok=True)
        print(f"✅ Created directory: {split_path}")
    
    return splits


def get_all_food_classes(source_path):
    """Get all food class directories from source"""
    if not os.path.exists(source_path):
        print(f"❌ Source dataset not found: {source_path}")
        return []
    
    classes = [d for d in os.listdir(source_path) 
               if os.path.isdir(os.path.join(source_path, d))]
    classes.sort()
    
    print(f"\n📊 Found {len(classes)} food classes")
    return classes


def split_and_copy_images(source_path, target_path, food_classes):
    """Split images into train/val/test and copy to target"""
    
    stats = {
        'train': 0,
        'val': 0,
        'test': 0,
        'total': 0
    }
    
    class_distribution = {}
    
    for class_idx, food_class in enumerate(food_classes):
        source_class_path = os.path.join(source_path, food_class)
        
        # Get all images for this class
        image_extensions = ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG']
        images = [f for f in os.listdir(source_class_path)
                  if any(f.endswith(ext) for ext in image_extensions)]
        
        if not images:
            print(f"⚠️  No images found in {food_class}")
            continue
        
        # Shuffle images
        random.shuffle(images)
        
        # Calculate split indices
        total_images = len(images)
        train_end = int(total_images * TRAIN_SPLIT)
        val_end = train_end + int(total_images * VAL_SPLIT)
        
        # Split images
        train_images = images[:train_end]
        val_images = images[train_end:val_end]
        test_images = images[val_end:]
        
        # Create class directories in each split
        for split in ['train', 'val', 'test']:
            class_dir = os.path.join(target_path, split, food_class)
            os.makedirs(class_dir, exist_ok=True)
        
        # Copy images to respective splits
        for img in train_images:
            src = os.path.join(source_class_path, img)
            dst = os.path.join(target_path, 'train', food_class, img)
            shutil.copy2(src, dst)
            stats['train'] += 1
        
        for img in val_images:
            src = os.path.join(source_class_path, img)
            dst = os.path.join(target_path, 'val', food_class, img)
            shutil.copy2(src, dst)
            stats['val'] += 1
        
        for img in test_images:
            src = os.path.join(source_class_path, img)
            dst = os.path.join(target_path, 'test', food_class, img)
            shutil.copy2(src, dst)
            stats['test'] += 1
        
        stats['total'] += total_images
        class_distribution[food_class] = {
            'train': len(train_images),
            'val': len(val_images),
            'test': len(test_images),
            'total': total_images
        }
        
        # Progress indicator
        if (class_idx + 1) % 10 == 0:
            print(f"   Processed {class_idx + 1}/{len(food_classes)} classes...")
    
    return stats, class_distribution


def save_labels_file(food_classes, target_path):
    """Save labels.txt file"""
    labels_path = os.path.join(target_path, 'labels.txt')
    
    with open(labels_path, 'w') as f:
        for food_class in food_classes:
            f.write(f"{food_class}\n")
    
    print(f"✅ Saved labels to: {labels_path}")
    return labels_path


def save_class_mapping(food_classes, target_path):
    """Save class index to name mapping as JSON"""
    class_mapping = {idx: name for idx, name in enumerate(food_classes)}
    
    mapping_path = os.path.join(target_path, 'class_mapping.json')
    with open(mapping_path, 'w') as f:
        json.dump(class_mapping, f, indent=2)
    
    print(f"✅ Saved class mapping to: {mapping_path}")
    return mapping_path


def save_dataset_config(food_classes, stats, target_path):
    """Save dataset configuration as YAML"""
    config = {
        'dataset_name': 'Indian Food Detection',
        'num_classes': len(food_classes),
        'classes': food_classes,
        'splits': {
            'train': os.path.join(target_path, 'train'),
            'val': os.path.join(target_path, 'val'),
            'test': os.path.join(target_path, 'test')
        },
        'statistics': stats,
        'image_size': [224, 224],  # Standard input size
        'train_split': TRAIN_SPLIT,
        'val_split': VAL_SPLIT,
        'test_split': TEST_SPLIT
    }
    
    config_path = os.path.join(target_path, 'dataset_config.json')
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"✅ Saved dataset config to: {config_path}")
    return config_path


def print_summary(food_classes, stats, class_distribution):
    """Print dataset preparation summary"""
    print(f"\n{'='*60}")
    print(f"📊 DATASET PREPARATION COMPLETE")
    print(f"{'='*60}")
    print(f"\n📁 Dataset Structure:")
    print(f"   • Total Classes: {len(food_classes)}")
    print(f"   • Total Images: {stats['total']}")
    print(f"\n📈 Split Distribution:")
    print(f"   • Training:   {stats['train']:,} images ({stats['train']/stats['total']*100:.1f}%)")
    print(f"   • Validation: {stats['val']:,} images ({stats['val']/stats['total']*100:.1f}%)")
    print(f"   • Testing:    {stats['test']:,} images ({stats['test']/stats['total']*100:.1f}%)")
    
    print(f"\n🍛 Sample Classes:")
    for i, class_name in enumerate(food_classes[:10]):
        dist = class_distribution[class_name]
        print(f"   {i+1}. {class_name}: {dist['total']} images "
              f"(train:{dist['train']}, val:{dist['val']}, test:{dist['test']})")
    
    if len(food_classes) > 10:
        print(f"   ... and {len(food_classes) - 10} more classes")
    
    print(f"\n{'='*60}")
    print(f"✅ Dataset ready for training!")
    print(f"{'='*60}\n")


def main():
    """Main dataset preparation function"""
    print(f"{'='*60}")
    print(f"🍛 INDIAN FOOD DATASET PREPARATION")
    print(f"{'='*60}\n")
    
    # Check if source dataset exists
    if not os.path.exists(SOURCE_DATASET):
        print(f"❌ Source dataset not found at: {SOURCE_DATASET}")
        print(f"   Please verify the path and try again.")
        return False
    
    print(f"📂 Source Dataset: {SOURCE_DATASET}")
    print(f"📂 Target Dataset: {TARGET_DATASET}\n")
    
    # Create target directory structure
    print(f"🔨 Creating directory structure...")
    create_directory_structure(TARGET_DATASET)
    
    # Get all food classes
    print(f"\n🔍 Scanning food classes...")
    food_classes = get_all_food_classes(SOURCE_DATASET)
    
    if not food_classes:
        print(f"❌ No food classes found!")
        return False
    
    # Split and copy images
    print(f"\n📋 Splitting and copying images...")
    print(f"   Train: {TRAIN_SPLIT*100:.0f}% | Val: {VAL_SPLIT*100:.0f}% | Test: {TEST_SPLIT*100:.0f}%\n")
    stats, class_distribution = split_and_copy_images(
        SOURCE_DATASET, TARGET_DATASET, food_classes
    )
    
    # Save metadata files
    print(f"\n💾 Saving metadata files...")
    save_labels_file(food_classes, TARGET_DATASET)
    save_class_mapping(food_classes, TARGET_DATASET)
    save_dataset_config(food_classes, stats, TARGET_DATASET)
    
    # Print summary
    print_summary(food_classes, stats, class_distribution)
    
    return True


if __name__ == "__main__":
    success = main()
    
    if success:
        print(f"✅ Next step: Run 'python train_model.py' to start training on your RTX 4050!")
    else:
        print(f"❌ Dataset preparation failed. Please check the errors above.")

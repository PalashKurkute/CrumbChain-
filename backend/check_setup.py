"""
Check if your setup is ready for training the combined model
Validates dataset structure, dependencies, and provides guidance
"""

import os
import sys

def check_labels_file():
    """Check if labels file exists and is valid"""
    print("\n📋 Checking labels file...")
    labels_path = 'models/labels_combined.txt'
    
    if not os.path.exists(labels_path):
        print(f"   ❌ Labels file not found: {labels_path}")
        return False, 0
    
    with open(labels_path, 'r') as f:
        labels = [line.strip() for line in f.readlines() if line.strip()]
    
    print(f"   ✅ Labels file found: {len(labels)} categories")
    
    # Check for popular foods
    popular = ['samosa', 'pizza', 'burger', 'momos', 'chai']
    found = [f for f in popular if f in labels]
    if found:
        print(f"   ✅ Includes popular foods: {', '.join(found)}")
    
    return True, len(labels)

def check_dataset_structure(num_categories):
    """Check if dataset folder structure is correct"""
    print("\n📁 Checking dataset structure...")
    
    if not os.path.exists('dataset'):
        print("   ❌ Dataset folder not found!")
        print("   📝 Create: backend/dataset/")
        return False, 0, 0
    
    # Count subdirectories
    folders = [d for d in os.listdir('dataset') if os.path.isdir(os.path.join('dataset', d))]
    
    if len(folders) == 0:
        print("   ❌ No food category folders found!")
        print(f"   📝 Create {num_categories} folders (one per food)")
        return False, 0, 0
    
    print(f"   ✅ Found {len(folders)} category folders")
    
    # Count images
    total_images = 0
    categories_with_images = 0
    
    for folder in folders:
        folder_path = os.path.join('dataset', folder)
        images = [f for f in os.listdir(folder_path) 
                 if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        if len(images) > 0:
            categories_with_images += 1
            total_images += len(images)
    
    print(f"   ✅ Categories with images: {categories_with_images}/{len(folders)}")
    print(f"   ✅ Total images: {total_images}")
    
    if total_images < 1000:
        print(f"   ⚠️  Need more images! (Have: {total_images}, Recommend: 10,000+)")
    
    return True, categories_with_images, total_images

def check_dependencies():
    """Check if required Python packages are installed"""
    print("\n📦 Checking dependencies...")
    
    required = {
        'torch': 'PyTorch',
        'torchvision': 'TorchVision',
        'PIL': 'Pillow',
        'tqdm': 'tqdm',
        'numpy': 'NumPy'
    }
    
    missing = []
    installed = []
    
    for package, name in required.items():
        try:
            __import__(package)
            installed.append(name)
            print(f"   ✅ {name}")
        except ImportError:
            missing.append(name)
            print(f"   ❌ {name}")
    
    if missing:
        print(f"\n   📝 Install missing packages:")
        print(f"      pip install {' '.join(missing).lower()}")
        return False
    
    return True

def check_training_script():
    """Check if training script exists"""
    print("\n🎯 Checking training script...")
    
    if not os.path.exists('train_combined_model.py'):
        print("   ❌ Training script not found!")
        return False
    
    print("   ✅ Training script ready")
    return True

def check_gpu():
    """Check if GPU is available"""
    print("\n🖥️  Checking GPU availability...")
    
    try:
        import torch
        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            print(f"   ✅ GPU available: {gpu_name}")
            return True
        else:
            print("   ⚠️  No GPU detected - training will be SLOW on CPU")
            print("   💡 Consider using Google Colab with free GPU")
            return False
    except ImportError:
        print("   ⚠️  Cannot check GPU (PyTorch not installed)")
        return False

def main():
    print("=" * 80)
    print("🔍 Combined Food Model - Setup Checker")
    print("=" * 80)
    
    # Change to backend directory if needed
    if not os.path.exists('models') and os.path.exists('backend'):
        print("\n📂 Changing to backend directory...")
        os.chdir('backend')
    
    # Run checks
    labels_ok, num_categories = check_labels_file()
    dataset_ok, categories_with_images, total_images = check_dataset_structure(num_categories)
    deps_ok = check_dependencies()
    script_ok = check_training_script()
    gpu_ok = check_gpu()
    
    # Summary
    print("\n" + "=" * 80)
    print("📊 Summary")
    print("=" * 80)
    
    checks_passed = sum([labels_ok, dataset_ok, deps_ok, script_ok])
    total_checks = 4
    
    print(f"\n✓ Passed: {checks_passed}/{total_checks} required checks")
    
    if not labels_ok:
        print("\n❌ Labels file missing!")
        print("   Fix: The file should already exist. Check if you're in the right directory.")
    
    if not dataset_ok:
        print("\n❌ Dataset not ready!")
        print("   Fix: Create backend/dataset/ folder with subfolders for each food")
        print("   Example structure:")
        print("   dataset/")
        print("     samosa/")
        print("       img001.jpg")
        print("       img002.jpg")
        print("     pizza/")
        print("       img001.jpg")
    
    if not deps_ok:
        print("\n❌ Dependencies missing!")
        print("   Fix: Run installation command shown above")
    
    if not script_ok:
        print("\n❌ Training script missing!")
        print("   Fix: The file should already exist. Check if you're in the right directory.")
    
    if dataset_ok and categories_with_images < num_categories:
        missing = num_categories - categories_with_images
        print(f"\n⚠️  Missing images for {missing} categories")
        print("   You can either:")
        print("   1. Collect images for missing categories, OR")
        print("   2. Remove them from labels_combined.txt")
    
    if total_images > 0:
        avg_per_category = total_images / max(categories_with_images, 1)
        print(f"\n📊 Average images per category: {avg_per_category:.1f}")
        
        if avg_per_category < 100:
            print("   ⚠️  Need more images! Target: 100-200 per category")
        elif avg_per_category >= 200:
            print("   ✅ Good amount of data!")
    
    # Recommendations
    print("\n" + "=" * 80)
    print("💡 Recommendations")
    print("=" * 80)
    
    if checks_passed == total_checks and categories_with_images > 30:
        print("\n🎉 You're ready to train!")
        print("\n   Next steps:")
        print("   1. Make sure you have 2-4 hours available")
        print("   2. Close other applications to free up RAM")
        if gpu_ok:
            print("   3. Run: python train_combined_model.py")
        else:
            print("   3. Consider using Google Colab for faster training")
            print("   4. Or run: python train_combined_model.py (will be slow)")
        print("\n   Training will save:")
        print("   - models/best_food_model_combined.pth (best model)")
        print("   - models/checkpoints/ (training checkpoints)")
        print("   - models/training_history_combined.json (metrics)")
    
    elif checks_passed < total_checks:
        print("\n⚠️  Not ready to train yet!")
        print("\n   Fix the issues above first, then run this script again.")
    
    elif categories_with_images < 30:
        print("\n⚠️  Need more data!")
        print(f"\n   You have images for {categories_with_images} categories")
        print("   Minimum needed: 30 categories")
        print("   Recommended: All 93 categories")
        print("\n   Options:")
        print("   1. Collect more data (recommended)")
        print("   2. Train with fewer categories (edit labels_combined.txt)")
        print("   3. Use existing 80-class model for now")
    
    # Quick tips
    print("\n" + "=" * 80)
    print("📚 Quick Tips")
    print("=" * 80)
    print("\n1. Data Collection:")
    print("   - Kaggle: Search 'Indian food dataset'")
    print("   - Google Images: Use image scraping tools")
    print("   - Your photos: Take pictures of real food")
    
    print("\n2. During Training:")
    print("   - Monitor accuracy (target: 70%+)")
    print("   - Watch for overfitting")
    print("   - Be patient (3-5 hours)")
    
    print("\n3. After Training:")
    print("   - Restart backend (will auto-load new model)")
    print("   - Test with different food images")
    print("   - Check startup logs for confirmation")
    
    print("\n" + "=" * 80)
    
    if checks_passed == total_checks and categories_with_images >= 30:
        print("✅ Ready to train! Run: python train_combined_model.py")
    else:
        print("⚠️  Please fix the issues above before training")
    
    print("=" * 80 + "\n")

if __name__ == "__main__":
    main()
